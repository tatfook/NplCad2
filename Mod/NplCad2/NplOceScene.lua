--[[
Title: NplOceScene
Author(s): leio
Date: 2019/1/14
Desc: 
use the lib:
------------------------------------------------------------
local NplOceScene = NPL.load("Mod/NplCad2/NplOceScene.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Encoding = commonlib.gettable("System.Encoding");

local NplOceScene = NPL.export();

function NplOceScene.getXml(scene)
    if(not scene)then
        return;
    end
    local s = "<scene>"
    NplOceScene.visit(scene, function(node)
        local attr = "";
        local matrix = commonlib.serialize(node:getMatrix());
        attr = attr .. string.format([[ matrix="%s" ]],matrix); 

        local color = node:getTag("_color") or "";
        if(color ~= "nil" and color ~= "" )then
            attr = attr .. string.format([[ _color="%s" ]],color); 
        end
        local op = node:getTag("_boolean_op") or "";
        if(op ~= "nil" and op ~= "" )then
            attr = attr .. string.format([[ _boolean_op="%s" ]],op); 
        end
        s = string.format([[%s<node id="%s" %s>]],s,node:getId(),attr);
        local model = node:getDrawable();
        if(model)then
            s = s .. "<model>"
            local shape = model:getShape();
            if(shape)then
                local box = commonlib.serialize(shape:getBndBox());
                local matrix = commonlib.serialize(shape:getMatrix());
                attr = attr .. string.format([[ matrix="%s" ]],matrix); 
                s = s.. string.format([[ <shape box="%s" matrix="%s"/>]],box,matrix); 
            end
            s = s .. "</model>"
        end
    end, function(node)
        s = s .. "</node>"
    end)
    s = s .. "</scene>"
    return s;
end
-- depth first traversal 
-- @param {NplOce.Scene} scene: which will be visited
-- @param preVisitMethod: callback function to be called for each node before child callback invocations. can be nil.
-- @param postVisitMethod: callback function to be called for each node after child callback invocations. can be nil. 

function NplOceScene.visit(scene, preVisitMethod, postVisitMethod)
    if(not scene)then
        return;
    end
    local node = scene:getFirstNode();
	NplOceScene.visitNode(node,preVisitMethod, postVisitMethod);
end

-- depth first traversal, visiting a single node. 
-- @param {NplOce.Scene} node: which will be visited
-- @param preVisitMethod: callback function to be called for each node before child callback invocations. can be nil. 
-- @param postVisitMethod: callback function to be called for each node after child callback invocations. can be nil. 
function NplOceScene.visitNode(node,preVisitMethod, postVisitMethod)
	if(not node)then
		return;
	end
	if(preVisitMethod)then
		preVisitMethod(node);
	end
	local child = node:getFirstChild();
	while(child) do
		NplOceScene.visitNode(child,preVisitMethod, postVisitMethod);
		child = child:getNextSibling();
	end
	if(postVisitMethod)then
		postVisitMethod(node);
	end
end
-- recursively find tag value in all of its parent 
-- @return tagValue, sceneNode: if nothing is found, the sceneNode is the rootNode.
function NplOceScene.findExternalTagValue(node,name)
	if(not node)then
		return
	end
	local p = node;
	local lastNode;
	while(p) do
        if(p:hasTag(name))then
            local v = p:getTag(name);
			return v,p;
        end
		lastNode = p;
		p = p:getParent();
	end
	return nil, lastNode;
end
-- run boolean oprations at world matrix with top_node
-- @param {string} op - the boolean oprations: "union" or "difference" or "intersection" 
-- @param {NplOce.Node} top_node - the owner of world matrix
-- @param {array} drawable_nodes - an array whose item will be boolean oprations one be one, drawable is NplOce.TopoModel
-- @return {NplOce.TopoModel} result_node
function NplOceScene.runOpSequence(op, top_node, drawable_nodes)
    local topo_model_array = {};
    local top_drawable = top_node:getDrawable();
    local has_model;
    if(top_drawable)then
        table.insert(topo_model_array,top_drawable)
        has_model = true;
    end
    local k;
    for k = 1, #drawable_nodes do
        table.insert(topo_model_array,drawable_nodes[k])
    end
    local len = #topo_model_array;

	if(len == 0)then
		return;
	end

	local first_node = topo_model_array[1];
	if(len == 1) then
        local child_model = topo_model_array[1];
        if(not has_model)then
            local w_matrix = NplOceScene.drawableTransform(child_model,top_node)

            -- clone a new model from node
            local child_model_parent = child_model:getNode();
            local clone_node = child_model_parent:clone();
            child_model_parent:setDrawable(nil);
            child_model = clone_node:getDrawable();

            top_node:setDrawable(child_model);
            local shape = child_model:getShape();
            local shape_matrix = shape:getMatrix();
             
            shape:setMatrix(shape_matrix * w_matrix);

        end
        return
	end

	local result_model =  topo_model_array[1];;
	for i=2, len do
        local drawable = drawable_nodes[i];
        if(op == "none")then
            op = NplOceScene.findExternalTagValue(drawable:getNode(),"_boolean_op") or "union";
        end
		result_model = NplOceScene.operateTwoNodes(result_model, drawable, op, top_node);
	end

    top_node:setDrawable(result_model);
end

function NplOceScene.operateTwoNodes(pre_drawable_node,cur_drawable_node,op,top_node)
	if(pre_drawable_node and cur_drawable_node)then
        local w_matrix_1 = NplOceScene.drawableTransform(pre_drawable_node,top_node);
        local w_matrix_2 = NplOceScene.drawableTransform(cur_drawable_node,top_node);
        local shape_1 = pre_drawable_node:getShape();
        local shape_2 = cur_drawable_node:getShape();
        local shape_1_matrix = shape_1:getMatrix();
        local shape_2_matrix = shape_2:getMatrix();

        shape_1:setMatrix(shape_1_matrix * w_matrix_1);
        shape_2:setMatrix(shape_2_matrix * w_matrix_2);
        
        -- create a new shape
        local shape;
        if(op == "union")then
            shape = NplOce.union(shape_1,shape_2);
        elseif(op == "difference")then
            shape = NplOce.difference(shape_1,shape_2);
        elseif(op == "intersection")then
            shape = NplOce.intersection(shape_1,shape_2);
        end

        -- remove drawable from pre node
        local pre_node = pre_drawable_node:getNode();
        if(pre_node)then
            pre_node:setDrawable(nil);
        end

        -- remove drawable from cur node
        local cur_node = cur_drawable_node:getNode();
        if(cur_node)then
            cur_node:setDrawable(nil);
        end
        local top_node_color = NplOce._getColor(top_node);
        local pre_color = pre_drawable_node:getColor();
        local color = top_node_color or NplOceScene.arrayToColor(pre_color) or { r = 1, g = 0, b = 0, a = 1 };
        local model = NplOce.TopoModel.create(shape,color.r,color.g,color.b,color.a);

        return model
    end

end

-- running boolean opration in scene if op is found on node
function NplOceScene.run(scene,bUnionAll)
    if(not scene)then
        return
    end
--    local scene_first_node = scene:getFirstNode();
--    if(bUnionAll)then
--        NplOce._setOp(scene_first_node,"union");
--    end
--    NplOceScene.visit(scene,function(node)
--        local drawable = node:getDrawable();
--        if(drawable)then
--            local actionName, actionNode = NplOceScene.findExternalTagValue(node,"_op");
--            if(actionName and actionNode and node ~= actionNode)then
--                actionNode:_pushActionParam(drawable);
--            end
--        end
--    end,function(node)
--        
--		local actionName = NplOce._getOp(node);
--        if(actionName)then
--            local action_params = node:_popAllActionParams() or {};
--            NplOceScene.runOpSequence(actionName,node, action_params)
--        end
--    end)
    return scene;
end

function NplOceScene.drawableTransform(drawable,top_node)
    local operationWorldMatrix = Matrix4:new(top_node:getWorldMatrix());
    local node = drawable:getNode();
	if(node and operationNode ~= node) then
		local myWorldMatrix = Matrix4:new(node:getWorldMatrix());
		local operationInverseMatrix = operationWorldMatrix:inverse();
		local transformMatrix = Matrix4.__mul(myWorldMatrix,operationInverseMatrix);
		return transformMatrix,operationWorldMatrix;
	end
	return Matrix4.IDENTITY,operationWorldMatrix;
end

function NplOceScene.arrayToColor(arr)
    return {
        r = arr[1],
        g = arr[2],
        b = arr[3],
        a = arr[4],
    }
end
function NplOceScene.saveSceneToParaX(filename,scene)
    if(not scene)then 
        return
    end
    NplOceScene.run(scene,false);
    local s = NplOce.exportToParaX(scene,true);
    ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
        local len = string.len(s);
		file:write(s,len);
		file:close();
	end
    return s;
end