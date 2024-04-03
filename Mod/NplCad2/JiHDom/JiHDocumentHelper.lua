--[[
Title: JiHDocumentHelper
Author(s): leio
Date: 2023/6/12
Desc: helper function for running JiHDocument
use the lib:
------------------------------------------------------------
local JiHDocumentHelper = NPL.load("Mod/NplCad2/JiHDom/JiHDocumentHelper.lua");
------------------------------------------------------------
--]]
local JiHDocumentHelper = NPL.export();
NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

JiHDocumentHelper.JiHPlaneType = {
    All = "xyz",
	x = "x",
	y = "y",
	z = "z",
	xy = "xy",
	xz = "xz",
	zy = "zy",
	yz = "yz",
}
JiHDocumentHelper.GeomTypes = {
	JiHGeom_Point = "JiHGeom_Point",
    JiHGeom_Line = "JiHGeom_Line",
    JiHGeom_Arc = "JiHGeom_Arc",
    JiHGeom_Circle = "JiHGeom_Circle",
    JiHGeom_Ellipse = "JiHGeom_Ellipse",
    JiHGeom_BSpline = "JiHGeom_BSpline",
}

JiHDocumentHelper.defaultNodeColor = "#ffc658";
JiHDocumentHelper.defaultNodeColor_arr = { 255/255, 198/255, 88/255, 1, };

JiHDocumentHelper.JiHComponentNames = {
	JiHBaseComponent = "JiHBaseComponent",
    JiHInfoComponent = "JiHInfoComponent",
    JiHColorComponent = "JiHColorComponent",
    JiHMaterialComponent = "JiHMaterialComponent",
    JiHMeshComponent = "JiHMeshComponent",
    JiHShapeComponent = "JiHShapeComponent",
    JiHTransformComponent = "JiHTransformComponent",
    JiHBooleanComponent = "JiHBooleanComponent",
}
JiHDocumentHelper.runningNodeTypes = {
	pushStage = "pushStage",
    pushNode = "pushNode",
    is_sketch = "is_sketch",
}

JiHDocumentHelper.opType = {
	union = "union",
    difference = "difference",
    intersection = "intersection",
}

JiHDocumentHelper.ShapeDirection = {
	x = "x", 
    y = "y", 
    z = "z", 
}

JiHDocumentHelper.PlaneType = {
	xy = "xy",
	xz = "xz",
	zy = "zy",
}

JiHDocumentHelper.AxisType = {
	x = "x", 
    y = "y", 
    z = "z", 
}

 JiHDocumentHelper.traversal_nodes_map = {};
 JiHDocumentHelper.theLinDeflection = 0.5;
 JiHDocumentHelper.theAngDeflection = 0.5;
JiHDocumentHelper.Precision_Confusion = 0.0000001

function JiHDocumentHelper.findParentSketchPlane(cur_node)
     if (not cur_node) then
        return;
    end
    local plane;
    local is_sketch = JiHDocumentHelper.isSketchNode(cur_node);
    if (is_sketch) then
        local sketch_plane = JiHDocumentHelper.getPlane(cur_node);
        if (sketch_plane and sketch_plane ~= "") then
            local out = {};
	        if(NPL.FromJson(sketch_plane, out)) then
                -- found sketch's plane
                plane = out;
	        end
            
        end
    end
    return plane;

end
-- @param value: 1 or "1,2,3" or [1,2,3]
function JiHDocumentHelper.convertValueToArray(value)
    if (type (value) == "number") then
        value = {value}; -- one index
    elseif (type (value) == "string") then
        local input_value = value;
        value = {};
        local section
		for section in string.gfind(input_value, "[^,]+") do
			index = tonumber(section);
			table.insert(value,index);
		end
    end
    return value;
end
-- @param direction: "x|y|z" or {dir_x, dir_y, dir_z}
-- @return {dir_x, dir_y, dir_z}

function JiHDocumentHelper.convertDirectionToArray(direction)
    local dir_x = 0;
    local dir_y = 1;
    local dir_z = 0;

    if (direction and type(direction) == "string") then
        if (direction == JiHDocumentHelper.ShapeDirection.x) then
            dir_x = 1;
            dir_y = 0;
            dir_z = 0;
        elseif (direction == JiHDocumentHelper.ShapeDirection.y) then
            dir_x = 0;
            dir_y = 1;
            dir_z = 0;
        elseif (direction == JiHDocumentHelper.ShapeDirection.z) then
            dir_x = 0;
            dir_y = 0;
            dir_z = 1;
        end
    end
    if (direction and type(direction) == "table") then
        local len = #direction;
        if(len >= 6)then
            dir_x = direction[4];
            dir_y = direction[5];
            dir_z = direction[6];
        else
            dir_x = direction[1];
            dir_y = direction[2];
            dir_z = direction[3];
        end
        
    end
    return {dir_x, dir_y, dir_z};
end

-- @param plane_dir: "x|y|z" or {dir_x, dir_y, dir_z} or {x, y, z, dir_x, dir_y, dir_z}
-- @return {x, y, z, dir_x, dir_y, dir_z}
function JiHDocumentHelper.convertPlaneToArray(plane_dir)
    local x = 0;
    local y = 0;
    local z = 0;
    local dir_x = 0;
    local dir_y = 1;
    local dir_z = 0;

    if (plane_dir and type(plane_dir) == "string") then
        local dir_arr = JiHDocumentHelper.convertDirectionToArray(plane_dir);
        if (dir_arr) then
            dir_x = dir_arr[1];
            dir_y = dir_arr[2];
            dir_z = dir_arr[3];
        end
    end
    if (plane_dir and type(plane_dir) == "table") then
        local len = #plane_dir;
        if(len == 3)then
            dir_x = plane_dir[1];
            dir_y = plane_dir[2];
            dir_z = plane_dir[3];
        elseif(len >= 6)then
            x = plane_dir[1];
            y = plane_dir[2];
            z = plane_dir[3];
            dir_x = plane_dir[4];
            dir_y = plane_dir[5];
            dir_z = plane_dir[6];
        end
        
    end

    return {x, y, z, dir_x, dir_y, dir_z};
end
function JiHDocumentHelper.transformPointByPlane( 
        x, y, z,
        dir_x, dir_y, dir_z,
        plane_center_x, plane_center_y, plane_center_z,
        plane_dir_x, plane_dir_y, plane_dir_z)

        local input = jihengine.Vector3:new(x, y, z);
        local input_dir = jihengine.Vector3:new(dir_x, dir_y, dir_z);
        jihengine.MathUtil:vector3_normalize(input_dir);

        
        local plane_dir = jihengine.Vector3:new(plane_dir_x, plane_dir_y, plane_dir_z);
        jihengine.MathUtil:vector3_normalize(plane_dir);

        local angle = jihengine.Vector3:angle(input_dir, plane_dir);

        -- scale
        local scale = jihengine.Vector3:new(1, 1, 1);
        -- rotation
        local q = jihengine.Quaternion:new();
        local axis = jihengine.Vector3:new();
        jihengine.MathUtil:vector3_cross(input_dir, plane_dir, axis);
        jihengine.Quaternion:createFromAxisAngle(axis, angle, q);
        -- translation
        local translation = jihengine.Vector3:new(plane_center_x, plane_center_y, plane_center_z);

        local matrix = jihengine.Matrix:new();
        jihengine.Matrix:compose(scale, q, translation, matrix);

        local result = jihengine.Vector3:new(0, 0, 0);
        jihengine.MathUtil:vector3_multiply_matrix(input, matrix, result);
        return {result:getX(), result:getY(), result:getZ()};

end
function JiHDocumentHelper.convert_xy_to_xyz_by_plane(plane_arr, x, y)
    local plane_arr = plane_arr or {0, 0, 0, 0, 1, 0};

    local result = JiHDocumentHelper.transformPointByPlane(x, 0, y,
        0, 1, 0,
        plane_arr[1], plane_arr[2], plane_arr[3],
        plane_arr[4], plane_arr[5], plane_arr[6]
    )
    return result[1], result[2], result[3];   
end
function JiHDocumentHelper.setMatrix(shape, matrix, forceUpdate)
    if(not shape)then
        return
    end
    shape:setMatrix(matrix, forceUpdate);
end
function JiHDocumentHelper.jihnode_is_equal(jihNode_1, jihNode_2)
    if(jihNode_1 and jihNode_2 and (jihNode_1 == jihNode_2))then
        return true;
    end
    return false;
end
function JiHDocumentHelper.inverseMatrix(matrix)
    local matrix_invert = jihengine.Matrix:new();
    jihengine.MathUtil:invert_matrix(matrix, matrix_invert);
    return matrix_invert;
end
function JiHDocumentHelper.multiplyMatrix(matrix1, matrix2)
    local matrix = jihengine.Matrix:new();
    jihengine.MathUtil:multiply_matrix(matrix1, matrix2, matrix);
    return matrix;
end
function JiHDocumentHelper.setNodeMatrix(jih_node, matrix)
    if (not jih_node or not matrix) then
        return;
    end
    local transformComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHTransformComponent);
    if (transformComponent) then
        local position = jihengine.Vector3:new();
        local scale = jihengine.Vector3:new();
        local q = jihengine.Quaternion:new();

        matrix:decompose(scale, q, position);

        transformComponent:set_x(position:getX());
        transformComponent:set_y(position:getY());
        transformComponent:set_z(position:getZ());

        transformComponent:set_scale_x(scale:getX());
        transformComponent:set_scale_y(scale:getY());
        transformComponent:set_scale_z(scale:getZ());

        transformComponent:set_q_x(q:getX());
        transformComponent:set_q_y(q:getY());
        transformComponent:set_q_z(q:getZ());
        transformComponent:set_q_w(q:getW());
    end
end
function JiHDocumentHelper.getNodeMatrix(jih_node)
    if (not jih_node) then
        return;
    end
    local matrix = jihengine.Matrix:new();
    local transformComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHTransformComponent);
    if (transformComponent) then
        local position = jihengine.Vector3:new();
        local scale = jihengine.Vector3:new();
        local q = jihengine.Quaternion:new();

        position:setX(transformComponent:get_x());
        position:setY(transformComponent:get_y());
        position:setZ(transformComponent:get_z());

        scale:setX(transformComponent:get_scale_x());
        scale:setY(transformComponent:get_scale_y());
        scale:setZ(transformComponent:get_scale_z());

        q:setX(transformComponent:get_q_x());
        q:setY(transformComponent:get_q_y());
        q:setZ(transformComponent:get_q_z());
        q:setW(transformComponent:get_q_w());

        jihengine.Matrix:compose(scale, q, position, matrix);
    end
    return matrix;
end
function JiHDocumentHelper.getWorldMatrix(jih_node, top_node)
        if (not jih_node) then
            return;
        end
        local m = JiHDocumentHelper.getNodeMatrix(jih_node);
        local parent = jih_node:getParent();
        while (parent) do
            if (JiHDocumentHelper.jihnode_is_equal(parent, top_node)) then
                return m
            end
            local p_m = JiHDocumentHelper.getNodeMatrix(parent);
            m = JiHDocumentHelper.multiplyMatrix(m, p_m);
            parent = parent:getParent();

            
        end
        return m;
end
function JiHDocumentHelper.clearNodesMap()
	JiHDocumentHelper.traversal_nodes_map = {};
end

-- for storing temporary node parameter during scene traversal.
function JiHDocumentHelper._pushActionParam(node,param)
	if(not node)then
		return;
	end

	local action_params_ = JiHDocumentHelper.traversal_nodes_map[node] or {};
	local bIncluded = false;
	for __, v in ipairs(action_params_) do
		if(v == param)then
			bIncluded = true;
			break;
		end
	end
	if(not bIncluded)then
		table.insert(action_params_, param);
	end
	JiHDocumentHelper.traversal_nodes_map[node] = action_params_;
end

-- return all action params as array or nil, and clear them all.
function JiHDocumentHelper._popAllActionParams(node)
	if(not node)then
		return;
	end
	local params = JiHDocumentHelper.traversal_nodes_map[node];
	JiHDocumentHelper.traversal_nodes_map[node] = nil;
	return params;
end

function JiHDocumentHelper.convertDirectionToArray(direction)
    local dir_x = 0;
    local dir_y = 1;
    local dir_z = 0;

    if( direction and type(direction) == "string" )then
        if (direction == JiHDocumentHelper.ShapeDirection.x) then
        dir_x = 1;
        dir_y = 0;
        dir_z = 0;
        elseif (direction == JiHDocumentHelper.ShapeDirection.y) then
            dir_x = 0;
            dir_y = 1;
            dir_z = 0;
        elseif (direction == JiHDocumentHelper.ShapeDirection.z) then
            dir_x = 0;
            dir_y = 0;
            dir_z = 1;
        end
    end
    if( direction and type(direction) == "table" )then
        local len = #direction;
        if(len >= 6)then
            dir_x = direction[4];
            dir_y = direction[5];
            dir_z = direction[6];
        else
            dir_x = direction[1];
            dir_y = direction[2];
            dir_z = direction[3];
        end
    end
    return {dir_x, dir_y, dir_z};
end

function JiHDocumentHelper.is_equal_with_precision(a,b)
    if(type(a) == "number" and type(b) == "number" )then
        local diff = math.abs(a - b);
        if(diff < JiHDocumentHelper.Precision_Confusion)then
            return true
        end
	end
end

 function JiHDocumentHelper.is_equal_pos(start_x, start_y, start_z, end_x, end_y, end_z)
    if( JiHDocumentHelper.is_equal_with_precision(start_x, end_x) and 
        JiHDocumentHelper.is_equal_with_precision(start_y, end_y) and
        JiHDocumentHelper.is_equal_with_precision(start_z, end_z) 
    )then
        return true;
    end
end

 --[[
	 * x y coordinate is:
     * ----------> X
     * |
     * |
     * |
     * |
     * Y
     * convert to right hand axis and y up
     * on plane xz : [x, y] => [x, 0, y]
     * on plane xy : [x, y] => [x, -y, 0]
     * on plane zy : [x, y] => [0, -y, x]

]]
function JiHDocumentHelper.convert_xy_to_xyz(plane, x, y)
    local out = {}
    if(plane == "xy")then
		out = {x, -y, 0};
    elseif(plane == "yz" or plane == "zy" )then
		out = {0, -y, x};
    elseif(plane == "xz")then
		out = {x, 0, y};
    end
    return out[1], out[2], out[3]
    
end
function JiHDocumentHelper.hexToRgb(color)
    local default_color = JiHDocumentHelper.defaultNodeColor_arr;
	if(not color)then
		return default_color;
	end
	if(color == "" or color == "none" or color == "nil")then
		return default_color;
	end
	if(type(color) == "table")then
		return color;
	end
	if(type(color) == "string")then
		local colorFloats = {};
		Color.ColorStrToValues(color, colorFloats)
		local r = colorFloats[1] or 255;
		local g = colorFloats[2] or 255;
		local b = colorFloats[3] or 255;
		local a = colorFloats[4] or 255;

		r = r / 255;
		g = g / 255;
		b = b / 255;
		a = a / 255;

		local v = { r, g, b, a }
		return v;
	end
	return default_color;
end
-- Generate an unique id
-- @return {string} id;
function JiHDocumentHelper.generateId()
	return ParaGlobal.GenerateUniqueID();
end
function JiHDocumentHelper.stringToJiHCharArray(str)
    str = str or "";
    local len = #str
    local charArray = jihengine.JiHCharArray:new();
    for k = 1, len do
        local char = str:sub(k,k)
        local char_code = string.byte(char);
        charArray:pushValue(char_code);
    end
    return charArray;
end
function JiHDocumentHelper.charArrayToString(charArray)
    if(not charArray)then
        return
    end
    local list = {};
    local cnt = charArray:getCount();
    for k = 1, cnt do
        local index = k - 1;
        local char_code = charArray:getValue(index);
        -- convert to unsigned char code
        if(char_code < 0)then
            char_code = char_code + 256;
        end
        local char = string.char(char_code);
        table.insert(list, char);
    end
    local result = table.concat(list);
    return result;
end
function JiHDocumentHelper.visit(scene, preVisitMethod, postVisitMethod)
	if(not scene)then
		return;
	end
	local node = scene:getChildAt(0);
	JiHDocumentHelper.visitNode(node,preVisitMethod, postVisitMethod);
end

-- depth first traversal, visiting a single node. 
function JiHDocumentHelper.visitNode(node,preVisitMethod, postVisitMethod)
	if(not node)then
		return;
	end
	if(preVisitMethod)then
		preVisitMethod(node);
	end
    for k = 1,node:numChildren() do
        local child = node:getChildAt(k-1);
        if(child)then
		    JiHDocumentHelper.visitNode(child,preVisitMethod, postVisitMethod);
        end
    end
	
	if(postVisitMethod)then
		postVisitMethod(node);
	end
end

function JiHDocumentHelper.run(scene_node, bUnionAll)
	if(not scene_node)then
		return
	end
	JiHDocumentHelper.clearNodesMap();
    local scene_first_node = scene_node:getChildAt(0);
    JiHDocumentHelper.setOpEnabled(scene_first_node, bUnionAll);
    JiHDocumentHelper.runNode(scene_first_node);
    return scene_node;
end

function JiHDocumentHelper.runNode(top_node)
	if(not top_node)then
		return
	end
	local function push_nodes(node)
		local topoShape = JiHDocumentHelper.getShape(node);
		if(topoShape)then
			local parent = JiHDocumentHelper.findParentOpEnabled(node);
			if(parent)then
                local drawable = node;
				JiHDocumentHelper._pushActionParam(parent,drawable);
			end
		end
	end
	local function pop_nodes(node)
		local action_params = JiHDocumentHelper._popAllActionParams(node) or {};
		JiHDocumentHelper.runOpSequence(node, action_params)
        --JiHDocumentHelper.setOpEnabled(node, false);
	end
	JiHDocumentHelper.visitNode(top_node,function(node)
		push_nodes(node);
	end,function(node)
		-- running boolean op
		pop_nodes(node)
		-- check if parent has op enabled
		--push_nodes(node);
	end)
end
function JiHDocumentHelper.findParentOpEnabled(node)
	if(not node)then
		return
	end
	--local p = node:getParent();
	local p = node;
	local lastNode;
	while(p) do
        local enabled = JiHDocumentHelper.getOpEnabled(p);
		if(enabled)then
			return p;
		end
		p = p:getParent();
	end
	return nil;
end

-- run boolean sequence in node
function JiHDocumentHelper.runOpSequence(node, action_params)
    if(not node or not action_params)then
		return
	end
	local len = #action_params;
	if(len == 0)then
		return
	end
	local result_shape;
	if(len == 1)then
		local model_node = action_params[1];
		local shape = JiHDocumentHelper.getShape(model_node);
        local w_matrix = JiHDocumentHelper.getWorldMatrix(model_node, node);
        --clone a new shape
        result_shape = shape:clone();
        JiHDocumentHelper.setMatrix(result_shape, w_matrix, false)
	else
		local model = action_params[1];
		for k = 2, len do
			local next_model = action_params[k];
			model = JiHDocumentHelper.operateTwoNodes(model,next_model,node)
		end
		if(model)then
			result_shape = JiHDocumentHelper.getShape(model);
		else
			LOG.std(nil, "error", "jihengine", "the model is nil");
		end
	end
	if(result_shape and (not result_shape:isNull()))then
        --TODO:destroy model node
		-- clear children
		node:removeAllChildren();
        JiHDocumentHelper.setShape(node, result_shape:clone());
	end
end
function JiHDocumentHelper.operateTwoNodes(model,next_model,top_node)
        if (model and next_model) then
            local next_node = next_model;
            local op = JiHDocumentHelper.opType.union;
            if (next_node) then
                op = JiHDocumentHelper.getOp(next_node);
            end
            local w_matrix_1 = JiHDocumentHelper.getWorldMatrix(model, top_node);
            local w_matrix_2 = JiHDocumentHelper.getWorldMatrix(next_model, top_node);
            local shape_1 = JiHDocumentHelper.getShape(model);
            local shape_2 = JiHDocumentHelper.getShape(next_model);


            -- clone new shape to boolean op
            local clone_shape_1 = shape_1:clone();
            local clone_shape_2 = shape_2:clone();

            JiHDocumentHelper.setMatrix(clone_shape_1, w_matrix_1, false);
            JiHDocumentHelper.setMatrix(clone_shape_2, w_matrix_2, false);

            -- create a new shape
            local shape;
            if (op == JiHDocumentHelper.opType.union) then
                shape = JiHDocumentHelper.union(clone_shape_1, clone_shape_2);
            elseif (op == JiHDocumentHelper.opType.difference) then

                shape = JiHDocumentHelper.difference(clone_shape_1, clone_shape_2);
            elseif (op == JiHDocumentHelper.opType.intersection) then
                shape = JiHDocumentHelper.intersection(clone_shape_1, clone_shape_2);
            else
                console.error("jihengine", "unsupported op: %s", op);
            end
            if (not shape or shape:isNull()) then
                console.error("jihengine", "the result of boolean is null");
                return
            end
            local result_node = JiHDocumentHelper.createJiHNode("", shape);
            return result_node;
        end
end

function JiHDocumentHelper.union(shape_1, shape_2)
    if(shape_1 and shape_2)then
        return jihengine.JiHShapeMaker:fuse(shape_1, shape_2);
    end
end
function JiHDocumentHelper.difference(shape_1, shape_2)
    if(shape_1 and shape_2)then
        return jihengine.JiHShapeMaker:cut(shape_1, shape_2);
    end
end
function JiHDocumentHelper.intersection(shape_1, shape_2)
    if(shape_1 and shape_2)then
        return jihengine.JiHShapeMaker:common(shape_1, shape_2);
    end
end
function JiHDocumentHelper.createJiHNode(id, shape, color, op)
	local jih_node = jihengine.JiHNode:new(id);
	jih_node:addComponent(jihengine.JiHInfoComponent:new():toBase());
    jih_node:addComponent(jihengine.JiHMaterialComponent:new():toBase());
    jih_node:addComponent(jihengine.JiHTransformComponent:new():toBase());
    jih_node:addComponent(jihengine.JiHBooleanComponent:new():toBase());
    jih_node:addComponent(jihengine.JiHShapeComponent:new():toBase());
	if (shape) then
        JiHDocumentHelper.setShape(jih_node, shape);
    end
    JiHDocumentHelper.setColor(jih_node, color);
    JiHDocumentHelper.setOp(jih_node, op);
	return jih_node;
end
function JiHDocumentHelper.getComponentByName(jih_node, name)
    if(not jih_node)then
        return
    end
    local component = jih_node:getComponentByName(name);
    if (component) then
        if (name == JiHDocumentHelper.JiHComponentNames.JiHInfoComponent) then
            return jihengine.JiHComponentUtil:find_JiHInfoComponent(jih_node);
        elseif (name == JiHDocumentHelper.JiHComponentNames.JiHMaterialComponent) then
            return jihengine.JiHComponentUtil:find_JiHMaterialComponent(jih_node);
        elseif (name == JiHDocumentHelper.JiHComponentNames.JiHShapeComponent) then
            return jihengine.JiHComponentUtil:find_JiHShapeComponent(jih_node);
        elseif (name == JiHDocumentHelper.JiHComponentNames.JiHMeshComponent) then
            return jihengine.JiHComponentUtil:find_JiHMeshComponent(jih_node);
        elseif (name == JiHDocumentHelper.JiHComponentNames.JiHTransformComponent) then
            return jihengine.JiHComponentUtil:find_JiHTransformComponent(jih_node);
        elseif (name == JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent) then
            return jihengine.JiHComponentUtil:find_JiHBooleanComponent(jih_node);
        end
    end
end
function JiHDocumentHelper.isSketchNode(jih_node)
    local tag = JiHDocumentHelper.getTag(jih_node);
    if (tag == JiHDocumentHelper.runningNodeTypes.is_sketch) then
        return true;
    end
    return false;
end
function JiHDocumentHelper.setPlane(jih_node, plane)
    local infoComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHInfoComponent);
    if (infoComponent) then
        infoComponent:setPlane(plane);
    end
end
function JiHDocumentHelper.getPlane(jih_node)
    local infoComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHInfoComponent);
    if (infoComponent) then
        local plane = infoComponent:getPlane();
        return plane;
    end
end

function JiHDocumentHelper.setTag(jih_node, tag)
    local infoComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHInfoComponent);
    if (infoComponent) then
        infoComponent:setTag(tag);
    end
end
function JiHDocumentHelper.getTag(jih_node)
    local infoComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHInfoComponent);
    if (infoComponent) then
        local tag = infoComponent:getTag();
        return tag;
    end
end

function JiHDocumentHelper.setPosition(jih_node, x, y, z)
    local transfomrComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHTransformComponent);
    if (transfomrComponent) then
        transfomrComponent:set_x(x);
        transfomrComponent:set_y(y);
        transfomrComponent:set_z(z);
    end
end

function JiHDocumentHelper.setScale(jih_node, x, y, z)
    local transfomrComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHTransformComponent);
    if (transfomrComponent) then
        transfomrComponent:set_scale_x(x);
        transfomrComponent:set_scale_y(y);
        transfomrComponent:set_scale_z(z);
    end
end

function JiHDocumentHelper.setQuaternion(jih_node, x, y, z, w)
    local transfomrComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHTransformComponent);
    if (transfomrComponent) then
        transfomrComponent:set_q_x(x);
        transfomrComponent:set_q_y(y);
        transfomrComponent:set_q_z(z);
        transfomrComponent:set_q_w(w);
    end
end

function JiHDocumentHelper.setShape(jih_node, shape)
    local shapeComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHShapeComponent);
    if (shapeComponent) then
        shapeComponent:setJiHTopoShape(shape);
    end
end
function JiHDocumentHelper.getShape(jih_node)
    local shapeComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHShapeComponent);
    if (shapeComponent) then
        local shape = shapeComponent:getJiHTopoShape();
        return shape;
    end
end
function JiHDocumentHelper.setColor(jih_node, color)
    local materialComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHMaterialComponent);
    if (materialComponent) then
         local arr = JiHDocumentHelper.hexToRgb(color);
        local doubleArray = jihengine.JiHDoubleArray:new();
        local r = arr[1];
        local g = arr[2];
        local b = arr[3];
        local a = arr[4];
        doubleArray:pushValue(r);
        doubleArray:pushValue(g);
        doubleArray:pushValue(b);
        doubleArray:pushValue(a);
        materialComponent:setBaseColor(doubleArray);
    end
end
function JiHDocumentHelper.getColor(jih_node)
    local materialComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHMaterialComponent);
    if (materialComponent) then
        local doubleArray = materialComponent:getBaseColor();
        return {doubleArray:getValue(0), doubleArray:getValue(1), doubleArray:getValue(2), doubleArray:getValue(3)};
    end
end
function JiHDocumentHelper.setOpEnabled(jih_node, v)
    local booleanComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent);
    if (booleanComponent) then
        booleanComponent:setEnabled(v);
    end
end
function JiHDocumentHelper.getOpEnabled(jih_node)
    local booleanComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent);
    if (booleanComponent) then
        local v = booleanComponent:getEnabled();
        return v;
    end
end

function JiHDocumentHelper.setOp(jih_node, op)
    local booleanComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent);
    if (booleanComponent) then
        booleanComponent:setOp(op);
    end
end
function JiHDocumentHelper.getOp(jih_node)
    local booleanComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent);
    if (booleanComponent) then
        local op = booleanComponent:getOp();
        return op;
    end
end

function JiHDocumentHelper.toGltf(scene_node, theLinDeflection, theAngDeflection, writeFace, writeEdge)
    if(not scene_node)then
        return
    end
    local exporter = jihengine.JiHExporterGltf:new(scene_node, theLinDeflection, theAngDeflection, writeFace, writeEdge, true);
    local charArray = exporter:exportToCharArray();
    return charArray;
end
function JiHDocumentHelper.toStep(scene_node)
    if(not scene_node)then
        return
    end
    local exporter = jihengine.JiHExporterXCAF:new();
    local charArray = exporter:exportStep(scene_node);
    return charArray;
end
function JiHDocumentHelper.toParax(scene_node, theLinDeflection, theAngDeflection)
    if(not scene_node)then
        return
    end
    local exporter = jihengine.JiHExporterParaX:new(scene_node, theLinDeflection, theAngDeflection, false, 1.0);
    local charArray = exporter:exportToCharArray();
    local content = JiHDocumentHelper.charArrayToString(charArray)
	local template = JiHDocumentHelper.loadParaXTemplateFromDisc();
	content = template .. content;
    return content
end
-- load parax template 
function JiHDocumentHelper.loadParaXTemplateFromDisc()
	local parax_template_data = JiHDocumentHelper.parax_template_data;
	if(parax_template_data)then
		return parax_template_data;
	end
	local templateName = "Mod/NplCad2/template.txt";
	if(ParaIO.DoesFileExist(templateName, true)) then
		local template_file = ParaIO.open(templateName, "r");
		if(template_file:IsValid()) then
			parax_template_data = template_file:GetText(0, -1);
			template_file:close();
		end
	end
	JiHDocumentHelper.parax_template_data = parax_template_data;
	return parax_template_data;
end
function JiHDocumentHelper.generateNodeIds(jihNode)
    if(not jihNode)then
        return
    end
    JiHDocumentHelper.visitNode(jihNode,function(node)
        if(node)then
            node:setId(JiHDocumentHelper.generateId())
        end
    end)
end
function JiHDocumentHelper.fileToJiHCharArray(filename)
    if(ParaIO.DoesFileExist(filename, true)) then
		local template_file = ParaIO.open(filename, "r");
		if(template_file:IsValid()) then
			local data = template_file:GetText(0, -1);
			template_file:close();
            return JiHDocumentHelper.stringToJiHCharArray(data);
		end
	end
end
function JiHDocumentHelper.jiHCharArrayToFile(filename, jih_char_array)
	local template_file = ParaIO.open(filename, "w");
	if(template_file:IsValid()) then
        local content = JiHDocumentHelper.charArrayToString(jih_char_array)
        template_file:write(content, #content);
		template_file:close();
	end
end
function JiHDocumentHelper.getMainParamDefaultValues(mainParameterDefinitions)
    if(not mainParameterDefinitions)then
        return
    end
    local params = {};
    for k,v in ipairs(mainParameterDefinitions) do
        local name = v.name or "";
        local value = v.initial;
        params[name] = value;
    end
    return params;
end

function JiHDocumentHelper.convertJiHPlaneTypeToArr(jiHPlaneType)
        local axis_x = 0;
		local axis_y = 0;
		local axis_z = 0;

		local dir_x = 0;
		local dir_y = 0;
		local dir_z = 0;

		if (jiHPlaneType == "xyz") then
			axis_x = 1;
			axis_y = 1;
			axis_z = 1;
		elseif (jiHPlaneType == "x") then
			axis_x = 1;
		elseif (jiHPlaneType == "y") then
			axis_y = 1;
		elseif (jiHPlaneType == "z") then
			axis_z = 1;
		elseif (jiHPlaneType == "xy") then
			dir_z = 1;
		elseif (jiHPlaneType == "xz") then
			dir_y = 1;
		elseif (jiHPlaneType == "yz" or jiHPlaneType == "zy") then
			dir_x = 1;
        end

		local axisList = jihengine.JiHDoubleArray:new();
		axisList:pushValue(axis_x);
		axisList:pushValue(axis_y);
		axisList:pushValue(axis_z);

		local dirList = jihengine.JiHDoubleArray:new();
		dirList:pushValue(dir_x);
		dirList:pushValue(dir_y);
		dirList:pushValue(dir_z);

		return {
			axisList = axisList ,
			dirList = dirList,
		};
end
function JiHDocumentHelper.getNodeByNodeId(stage, objName)
    return stage:getChildById(objName, true);
end