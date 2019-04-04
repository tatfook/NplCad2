--[[
Title: SceneHelper
Author(s): leio
Date: 2019/4/2
Desc: 
use the lib:
------------------------------------------------------------
local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Encoding = commonlib.gettable("System.Encoding");

local SceneHelper = NPL.export();
SceneHelper.traversal_nodes_map = {};
function SceneHelper._clearNodesMap()
    SceneHelper.traversal_nodes_map = {};
end
-- for storing temporary node parameter during scene traversal.
function SceneHelper._pushActionParam(node,param)
    if(not node)then
        return;
    end

	local action_params_ = SceneHelper.traversal_nodes_map[node] or {};
	table.insert(action_params_, param);

    SceneHelper.traversal_nodes_map[node] = action_params_;
end

-- return all action params as array or nil, and clear them all.
function SceneHelper._popAllActionParams(node)
    if(not node)then
        return;
    end
	local params = SceneHelper.traversal_nodes_map[node];
	SceneHelper.traversal_nodes_map[node] = nil;
	return params;
end
function SceneHelper.matrixToString(matrix)
    local r = {};
    for k = 1,16 do
        r[k] = matrix[k];
    end
    return commonlib.serialize(r);
end
function SceneHelper.getXml(scene)
    if(not scene)then
        return;
    end
    local s = "<scene>"
    SceneHelper.visit(scene, function(node)
        local attr = "";
        local matrix = commonlib.serialize(node:getMatrix());
        attr = attr .. string.format([[ matrix="%s" ]],matrix); 
        if(node.getOp)then
            local _op = node:getOp();
            if(_op ~= "" and _op ~= "nil" and  _op ~= nil )then
                attr = attr .. string.format([[ op="%s" ]],_op); 
            end
        end
        if(node.getColor)then
            local color = node:getColor() or "";
            if(color ~= "nil" and color ~= "" )then
                attr = attr .. string.format([[ color="%s" ]],commonlib.serialize(color)); 
            end
        end
        if(node.getOpEnabled)then
            local _boolean_op = node:getOpEnabled() or "";
            if(_boolean_op ~= "nil" and _boolean_op ~= "" )then
                attr = attr .. string.format([[ op_enabled="%s" ]],_boolean_op); 
            end
        end
        local world_matrix ;
        if(node.getWorldMatrix)then
            world_matrix = node:getWorldMatrix()
            --attr = attr .. string.format([[ world_matrix="%s" ]],commonlib.serialize(world_matrix)); 
        end
        s = string.format([[%s<node id="%s" %s>]],s,node:getId(),attr);
        local model = node:getDrawable();
        if(model)then
            s = s .. "<model>"
            local shape = model:getShape();
            if(shape)then
                local box = shape:getBndBox();
                local matrix = shape:getMatrix();
                if(world_matrix)then
                    matrix = Matrix4:new(matrix);
                    world_matrix = Matrix4:new(world_matrix);
                    world_matrix = matrix * world_matrix;
                end
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


                s = s.. string.format([[ <shape size="%s" box="%s" matrix="%s" world_matrix="%s" />]],commonlib.serialize(size), commonlib.serialize(box),commonlib.serialize(matrix),SceneHelper.matrixToString(world_matrix)); 
            end
            s = s .. "</model>"
        end
    end, function(node)
        s = s .. "</node>"
    end)
    s = s .. "</scene>"
    return s;
end
function SceneHelper.visit(scene, preVisitMethod, postVisitMethod)
    if(not scene)then
        return;
    end
    local node = scene:getFirstNode();
	SceneHelper.visitNode(node,preVisitMethod, postVisitMethod);
end

-- depth first traversal, visiting a single node. 
function SceneHelper.visitNode(node,preVisitMethod, postVisitMethod)
	if(not node)then
		return;
	end
	if(preVisitMethod)then
		preVisitMethod(node);
	end
	local child = node:getFirstChild();
	while(child) do
		SceneHelper.visitNode(child,preVisitMethod, postVisitMethod);
		child = child:getNextSibling();
	end
	if(postVisitMethod)then
		postVisitMethod(node);
	end
end
-- running boolean opration in scene if op is found on node
function SceneHelper.run(scene,bUnionAll)
    if(not scene)then
        return
    end
    SceneHelper._clearNodesMap();
    local scene_first_node = scene:getFirstNode();
    if(bUnionAll)then
        scene_first_node:setOpEnabled(true);
    end
    SceneHelper.visit(scene,function(node)
        local drawable = node:getDrawable();
        if(drawable)then
            local parent = SceneHelper.findParentOpEnabled(node);
            if(parent)then
                SceneHelper._pushActionParam(parent,drawable);
            end
        end
    end,function(node)
        local action_params = SceneHelper._popAllActionParams(node) or {};
        SceneHelper.runOpSequence(node, action_params)
    end)
    return scene;
end

function SceneHelper.findParentOpEnabled(node)
	if(not node)then
		return
	end
	local p = node:getParent();
	local lastNode;
	while(p) do
        if(p.getOpEnabled and p:getOpEnabled())then
            return p;
        end
		p = p:getParent();
	end
	return nil;
end
-- run boolean sequence in node
function SceneHelper.runOpSequence(node, action_params)
    if(not node or not action_params)then
        return
    end
    local len = #action_params;
    if(len == 0)then
        return
    end
    local result_shape;
    if(len == 1)then
        local model = action_params[1];
        local shape = model:getShape();
        local w_matrix = SceneHelper.drawableTransform(model,node);
        local matrix_shape = Matrix4:new(shape:getMatrix());

        --  clone a new shape
        result_shape = shape:clone();
        result_shape:setMatrix(matrix_shape * w_matrix);
    else
        local model = action_params[1];
        for k = 2, len do
            local next_model = action_params[k];
            model = SceneHelper.operateTwoNodes(model,next_model,node)
        end
        result_shape = model:getShape();
    end
    if(result_shape)then
        -- clear children
        node:removeAllChildren();
        -- set a new model
        local model = NplOce.ShapeModel.create(result_shape);
        node:setDrawable(model);
    end
end
function SceneHelper.drawableTransform(drawable,top_node)
    local operationWorldMatrix = Matrix4:new(top_node:getWorldMatrix());
    local node = drawable:getNode();
	if(node and top_node ~= node) then
		local myWorldMatrix = Matrix4:new(node:getWorldMatrix());
		local operationInverseMatrix = operationWorldMatrix:inverse();
		local transformMatrix = Matrix4.__mul(myWorldMatrix,operationInverseMatrix);
		return transformMatrix,operationWorldMatrix;
	end
	return Matrix4.IDENTITY,operationWorldMatrix;
end

function SceneHelper.operateTwoNodes(model,next_model,top_node)
	if(model and next_model)then
        local next_node = next_model:getNode();
        local op = "union";
        if(next_node and next_node.getOp)then
            op = next_node:getOp();
        end
        local w_matrix_1 = SceneHelper.drawableTransform(model,top_node);
        local w_matrix_2 = SceneHelper.drawableTransform(next_model,top_node);
        local shape_1 = model:getShape();
        local shape_2 = next_model:getShape();

        local matrix_shape_1 = Matrix4:new(shape_1:getMatrix());
        local matrix_shape_2 = Matrix4:new(shape_2:getMatrix());

        -- clone new shape to boolean op
        local clone_shape_1 = shape_1:clone();
        local clone_shape_2 = shape_2:clone();
        clone_shape_1:setMatrix(matrix_shape_1 * w_matrix_1);
        clone_shape_2:setMatrix(matrix_shape_2 * w_matrix_2);
        
        -- create a new shape
        local shape;
        if(op == "union")then
            shape = NplOce.union(clone_shape_1,clone_shape_2);
        elseif(op == "difference")then
            shape = NplOce.difference(clone_shape_1,clone_shape_2);
        elseif(op == "intersection")then
            shape = NplOce.intersection(clone_shape_1,clone_shape_2);
        else
	        LOG.std(nil, "error", "NplCad2", "unsupported op: %s", op);
        end
        if(not shape or not shape:IsTessellated())then
	        LOG.std(nil, "error", "NplCad2", "the result of boolean is null");
            return
        end
        local result = NplOce.ShapeModel.create(shape);
        --TODO:destroy model
        return result;
    end
end
function SceneHelper.saveSceneToParaX(filename,scene)
    if(not scene)then 
        return
    end
    SceneHelper.run(scene,false);
    local s = NplOce.exportToParaX(scene,true) or "";
    local len = string.len(s);
    local result = false;
    if(len > 0)then
        ParaIO.CreateDirectory(filename);
        local file = ParaIO.open(filename, "w");
	    if(file:IsValid()) then
		    file:write(s,len);
		    file:close();
            result = true;
	    end
    end
    return result;
end
function SceneHelper.replaceChildrenNodeId(top_node)
    SceneHelper.visitNode(top_node,function(node)
        local id = node:getId() or "";
        if(id ~= "")then
            node:setId(ParaGlobal.GenerateUniqueID());
        end
    end)
end
