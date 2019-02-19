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

        local _op = node:getTag("_op");
        if(_op ~= "" and _op ~= "nil" and  _op ~= nil )then
            attr = attr .. string.format([[ _op="%s" ]],_op); 
        end
        local color = node:getTag("_color") or "";
        if(color ~= "nil" and color ~= "" )then
            attr = attr .. string.format([[ _color="%s" ]],color); 
        end
        local _boolean_op = node:getTag("_boolean_op") or "";
        if(_boolean_op ~= "nil" and _boolean_op ~= "" )then
            attr = attr .. string.format([[ _boolean_op="%s" ]],_boolean_op); 
        end
        s = string.format([[%s<node id="%s" %s>]],s,node:getId(),attr);
        local model = node:getDrawable();
        if(model)then
            s = s .. "<model>"
            local shape = model:getShape();
            if(shape)then
                local box = shape:getBndBox();
                local matrix = commonlib.serialize(shape:getMatrix());
                attr = attr .. string.format([[ matrix="%s" ]],matrix); 
                local min_x = box[1];
                local min_y = box[2];
                local min_z = box[3];
                local max_x = box[4];
                local max_y = box[5];
                local max_z = box[6];
                local w = max_x - min_x;
                local l = max_y - min_y;
                local d = max_z - min_z;
                local size = { w,l,d };
                s = s.. string.format([[ <shape size="%s" box="%s" matrix="%s"/>]],commonlib.serialize(size), commonlib.serialize(box),matrix); 
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
    local len = #drawable_nodes;
    if(top_drawable and len == 0)then
        return
    end

    if(top_drawable)then
        table.insert(topo_model_array,top_drawable)
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
--        local child_model = topo_model_array[1];
--        local w_matrix = NplOceScene.drawableTransform(child_model,top_node)
--
--        -- clone a new model from node
--        local child_model_parent = child_model:getNode();
--        local clone_node = child_model_parent:clone();
--        child_model = clone_node:getDrawable();
--        child_model_parent:setDrawable(nil);
--
--        top_node:setDrawable(child_model);
--        local shape = child_model:getShape();
--        local shape_matrix = shape:getMatrix();
--        local box_arr = shape:getBndBox();
--            
--        shape:setMatrix(Matrix4:new():identity());
--        -- set world matrix
--        top_node:setMatrix(w_matrix);
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

    NplOceScene.centerShape(top_node,result_model);
end

function NplOceScene.operateTwoNodes(pre_drawable_node,cur_drawable_node,op,top_node)
	if(pre_drawable_node and cur_drawable_node)then
        local w_matrix_1 = NplOceScene.drawableTransform(pre_drawable_node,top_node);
        local w_matrix_2 = NplOceScene.drawableTransform(cur_drawable_node,top_node);
        local shape_1 = pre_drawable_node:getShape();
        local shape_2 = cur_drawable_node:getShape();

        local matrix_shape_1 = Matrix4:new(shape_1:getMatrix());
        local matrix_shape_2 = Matrix4:new(shape_2:getMatrix());
        shape_1:setMatrix(matrix_shape_1 * w_matrix_1);
        shape_2:setMatrix(matrix_shape_2 * w_matrix_2);
        

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
function NplOceScene.centerShape(cur_node,model)
    if(not cur_node or not model)then
        return
    end
    local shape = model:getShape();
    if(shape)then

        local box_arr = shape:getBndBox();
        local min_x = box_arr[1];
        local min_y = box_arr[2];
        local min_z = box_arr[3];

        local max_x = box_arr[4];
        local max_y = box_arr[5];
        local max_z = box_arr[6];

        local width = max_x - min_x;
        local height = max_y - min_y;
        local depth = max_z - min_z;

        local pos_x = min_x + width / 2;
        local pos_y = min_y + height / 2;
        local pos_z = min_z + depth / 2;

        local matrix = Matrix4:new():identity();
        matrix:setTrans(-pos_x,-pos_y,-pos_z);
        shape:setMatrix(matrix);

        
        cur_node:removeAllChildren();
        local child_node = NplOce.Node.create(ShapeBuilder.generateId());
        cur_node:addChild(child_node);

        local cur_node_matrix = Matrix4:new();
        cur_node_matrix:makeTrans(pos_x,pos_y,pos_z);
        child_node:setMatrix(cur_node_matrix);
        child_node:setDrawable(model);
        cur_node:setDrawable(nil);
    end
end

function NplOceScene.cloneNode(node,color,op)
    if(node)then
        local cloned_node = node:clone();
        local id = ShapeBuilder.generateId();
        cloned_node:setId(id);
        color = ShapeBuilder.converColorToRGBA(color) or { r = 1, g = 0, b = 0, a = 1 };

        NplOce._setBooleanOp(cloned_node,op)
        NplOce._setColor(cloned_node,color)
        
        NplOceScene.visitNode(cloned_node,function(node)
            ShapeBuilder.setColor(node,color)
        end)

        NplOceScene.groupNode(cloned_node, color);
        ShapeBuilder.cur_node:addChild(cloned_node)
        return cloned_node
    end
end
-- running boolean op in cur_node
function NplOceScene.groupNode(cur_node, color)

    local function for_each(node,callback)
        local child = node:getFirstChild();
	    while(child) do
            callback(child)
		    child = child:getNextSibling();
	    end
    end
    local nodes = {};
    for_each(cur_node,function(child)
        NplOceScene.visitNode(child,function(node)
            if(child ~= node)then
                local drawable = node:getDrawable();
                if(drawable)then
                    child:_pushActionParam(drawable);
                end
            end
        end, function(child)
            local drawable_nodes = child:_popAllActionParams() or {}
            NplOceScene.runOpSequence("union", child, drawable_nodes)

            local drawable = child:getDrawable();
            if(drawable)then
                table.insert(nodes,drawable);
            end
        end)
        
    end)
    NplOceScene.runOpSequence("none", cur_node, nodes);

end
-- running boolean opration in scene if op is found on node
function NplOceScene.run(scene,bUnionAll)
    if(not scene)then
        return
    end
    local scene_first_node = scene:getFirstNode();
    if(bUnionAll)then
        NplOce._setOp(scene_first_node,"true");
    end
    NplOceScene.visit(scene,function(node)
--        local drawable = node:getDrawable();
--        if(drawable)then
--            local actionName, actionNode = NplOceScene.findExternalTagValue(node,"_op");
--            if((actionName == "true" or actionName == "True" or actionName == true ) 
--                and node ~= actionNode )then
--                actionNode:_pushActionParam(drawable);
--            end
--        end
    end,function(node)
		local bOp = NplOce._getOp(node);
        if(bOp == "true" or bOp == "True" or bOp == true)then
--            local action_params = node:_popAllActionParams() or {};
--            NplOceScene.runOpSequence("none",node, action_params)
--            NplOceScene.centerShape(node);

            local color = commonlib.LoadTableFromString(NplOceScene.findExternalTagValue(node,"_color"));
            NplOceScene.groupNode(node, color);
        end
    end)
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