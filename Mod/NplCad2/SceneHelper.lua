﻿--[[
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
NPL.load("(gl)script/ide/serialization.lua");
NPL.load("(gl)script/ide/Json.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Encoding = commonlib.gettable("System.Encoding");

local SceneHelper = NPL.export();
SceneHelper.traversal_nodes_map = {};
SceneHelper.brep_shapes_cache = {};
function SceneHelper._clearNodesMap()
	SceneHelper.traversal_nodes_map = {};
end
-- for storing temporary node parameter during scene traversal.
function SceneHelper._pushActionParam(node,param)
	if(not node)then
		return;
	end

	local action_params_ = SceneHelper.traversal_nodes_map[node] or {};
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
		s = string.format([[%s<node id="%s" type="%s" %s>]],s,node:getId(),node:getTypeName(),attr);
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

			local skin = model:getSkin();
			if(skin)then
				s = s .. "<joints>"
				local cnt = skin:getJointCount();
				for k = 0, cnt-1 do
					local joint = skin:getJoint(k);
					local joint_id = joint:getId();
					s = s .. string.format([[<joint id="%s"/>]],joint_id);
				end
				s = s .. "</joints>"
			end
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
	SceneHelper.runNode(scene_first_node);
	SceneHelper.bindJoints(scene_first_node,scene.joints_map);
	SceneHelper.combineBoneName(scene_first_node, scene.bone_name_constraint, scene.joints_map)
	return scene;
end
function SceneHelper.runNode(top_node)
	if(not top_node)then
		return
	end
	local function push_nodes(node)
		local drawable = node:getDrawable();
		if(drawable)then
			local parent = SceneHelper.findParentOpEnabled(node);
			if(parent)then
				SceneHelper._pushActionParam(parent,drawable);
			end
		end
	end
	local function pop_nodes(node)
		local action_params = SceneHelper._popAllActionParams(node) or {};
		SceneHelper.runOpSequence(node, action_params)
		node:setOpEnabled(false);
	end
	SceneHelper.visitNode(top_node,function(node)
		push_nodes(node);
	end,function(node)
		-- running boolean op
		pop_nodes(node)
		-- check if parent has op enabled
		push_nodes(node);
	end)
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
		-- normallized transform is better?
		-- transformed shape can't set color when export to step
		result_shape:setMatrix(matrix_shape * w_matrix);
	else
		local model = action_params[1];
		for k = 2, len do
			local next_model = action_params[k];
			model = SceneHelper.operateTwoNodes(model,next_model,node)
		end
		if(model)then
			result_shape = model:getShape();
		else
			LOG.std(nil, "error", "NplCad2", "the model is nil");
		end
	end
	if(result_shape)then
		-- clear children
		node:removeAllChildren();
		-- set a new model
		local model = NplOce.ShapeModel.create(result_shape);
		node:setDrawable(model);
		node:setOpEnabled(false);
	end
end

function SceneHelper.getTranformMatrixFrom(from,to)
	if(not from or not to)then
		return
	end
	local m = Matrix4:new(from:getMatrix());
	if(from == to)then
		return m;
	end
	local parent = from:getParent();
	while(parent)do
		m = m * Matrix4:new(parent:getMatrix());
		if(parent == to)then
			return m
		end
		parent = parent:getParent();
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

		w_matrix_1 = matrix_shape_1 * w_matrix_1;
		w_matrix_2 = matrix_shape_2 * w_matrix_2;
		clone_shape_1:setMatrix(w_matrix_1);
		clone_shape_2:setMatrix(w_matrix_2);
		
	   
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
		if(not shape or shape:IsNull())then
			LOG.std(nil, "error", "NplCad2", "the result of boolean is null");
			return
		end
		local result = NplOce.ShapeModel.create(shape);
		--TODO:destroy model
		return result;
	end
end
-- binding joints at last
-- each node binding one joint
function SceneHelper.bindJoints(root_node, joints_map)
	if(not root_node or not joints_map)then
		return
	end
	for joint,node_name in pairs(joints_map) do
		if(node_name and node_name ~= "")then
			local top_node = root_node:findNode(node_name);
			SceneHelper.visitNode(top_node,function(node)
				local model = node:getDrawable();
				if(model)then
					local skin = model:getSkin();
					if(not skin)then
						skin = NplOce.MeshSkin.create();
						-- only 1 joint can be bound
						skin:setJointCount(1);
						model:setSkin(skin);
					end
					skin:setJoint(joint,0);
				end
			end)
		end
	end
end
function SceneHelper.combineBoneName(root_node, bone_name_constraint, joints_map)
	if(not root_node or not bone_name_constraint or not joints_map)then
		return
	end
	for joint,node_name in pairs(joints_map) do
		local bone_name = joint:getId();
		bone_name = SceneHelper.getBoneCombineName(bone_name,bone_name_constraint)
		if(bone_name)then
			joint:setId(bone_name);
		end
	end
end
function SceneHelper.saveSceneToStl(filename, scene, bRun, exportCoordinateType, bBinary, bEncodeBase64, bIncludeColor, liner, angular)
	if(not scene)then 
		return
	end
	if(bRun)then
		SceneHelper.run(scene,false);
	end

	-- set liner and angular deflection
	if (liner and angular) then
		NplOce.deflection(liner, angular);
	end
	local content = scene:toStl_String(exportCoordinateType, bBinary, bEncodeBase64, bIncludeColor);
	if(bEncodeBase64)then
	content = Encoding.unbase64(content);
	end
	return SceneHelper.saveFile(filename,content);
end
function SceneHelper.saveSceneToIGES(filename, scene, bRun, swapYZ, bBinary, bEncodeBase64, bIncludeColor)
	if(not scene)then 
		return
	end
	if(bRun)then
		SceneHelper.run(scene,false);
	end

	return scene:toIGES_File(filename);
end
function SceneHelper.saveSceneToStep(filename, scene, bRun, swapYZ, bBinary, bEncodeBase64, bIncludeColor)
	if(not scene)then 
		return
	end
	if(bRun)then
		SceneHelper.run(scene,false);
	end

	return scene:toStep_File(filename);
end
-- export scene to file by exporter
-- @param filename: the path and name of file
-- @param scene: 3d scene
-- @param bRun:  ture to run scene before export
-- @param formatStr: "fbxa" or "fbx" or "obj"
-- @param exportCoordinateType: NplOce.ExporterConfig.to_left_hand_y_up or NplOce.ExporterConfig.to_right_hand_y_up
-- @param targetCount: if targetCount > 0 the simplification of mesh will be enabled
function SceneHelper.exportSceneToFile(filename, scene, bRun, formatStr, exportCoordinateType, targetCount)
	if(not scene)then 
		return
	end
	if(bRun)then
		SceneHelper.run(scene,false);
	end
	local result = scene:exportByExporter(formatStr, exportCoordinateType, targetCount);
	if(result)then
		local cnt = result[1]
		local content = result[2]
		local isBase64 = result[3]
		if(isBase64)then
			content = Encoding.unbase64(content);
		end
		return SceneHelper.saveFile(filename, content);
	end
	
end

function SceneHelper.saveSceneToGltf(filename, scene, bRun, exportCoordinateType, liner, angular)
	if(not scene)then 
		return
	end
	if(bRun)then
		SceneHelper.run(scene,false);
	end
	-- set liner and angular deflection
	if (liner and angular) then
		NplOce.deflection(liner, angular);
	end
	local content = scene:toGltf_String(exportCoordinateType);
	return SceneHelper.saveFile(filename,content);
end
function SceneHelper.toParaX(scene, liner, angular)
	if(not scene)then 
		return
	end
	-- set liner and angular deflection
	if (liner and angular) then
		NplOce.deflection(liner, angular);
	end
	--NplOce.deflection(2.0, 45);

	local max_triangle_cnt = scene.max_triangle_cnt or 0;
	local data = scene:toParaX(max_triangle_cnt);
	return SceneHelper.unionParaXTemplate(data, true);
end
function SceneHelper.saveSceneToParaX(filename, scene, liner, angular)
	if(not scene)then 
		return
	end
	SceneHelper.run(scene,false);
	local content = SceneHelper.toParaX(scene, liner, angular) or "";
	return SceneHelper.saveFile(filename,content);
end
function SceneHelper.unionParaXTemplate(content, isBase64)
	local template = SceneHelper.loadParaXTemplateFromDisc();
	if (template ~= "") then
		if(content ~= nil)then
			local Encoding = commonlib.gettable("System.Encoding");
			if(isBase64)then
				content = Encoding.unbase64(content);
			end
			content = template..content;
			return content;
		end
	end
end
function SceneHelper.saveFile(filename, content)
	local result = false;
	if(content)then
		local len = string.len(content);
		if(len > 0)then
			ParaIO.CreateDirectory(filename);
			local file = ParaIO.open(filename, "w");
			if(file:IsValid()) then
				file:write(content,len);
				file:close();
				result = true;
			end
		end
	end
	return result;
end
function SceneHelper.clearNodesId(top_node)
	SceneHelper.visitNode(top_node,function(node)
		node:setId("");
	end)
end

function SceneHelper.installMethods(codeAPI, shape)
	for func_name, func in pairs(shape) do
		if(type(func_name) == "string" and type(func) == "function") then
			codeAPI[func_name] = function(...)
				return func(...);
			end
		end
	end
end
function SceneHelper.readFile(filename,forced_load)
	if(not filename)then
		return
	end
	local node = SceneHelper.brep_shapes_cache[filename] or {};
	if(not forced_load and node.loaded)then
		return node.content;
	end
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		node.content = file:GetText();
		file:close();
	end
	node.loaded = true;
	SceneHelper.brep_shapes_cache[filename] = node;
	return node.content
end

function SceneHelper.LoadPlugin(callback)
	local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
	if(not NplOceConnection)then
		return
	end
    local platform = System.os.GetPlatform();
	local plugin_path;
	local debug = ParaEngine.GetAppCommandLineByParam("nplcad_debug", false);
	if(debug)then
        if(platform == "windows")then
		    plugin_path = "plugins/nploce_d.dll";
        else
		    plugin_path = "plugins/libnploce_d.so";
        end
	else
        if(platform == "windows")then
		    plugin_path = "plugins/nploce.dll";
        else
		    plugin_path = "plugins/libnploce.so";
        end
	end
	NplOceConnection.load({ npl_oce_dll = plugin_path, activate_callback = "Mod/NplCad2/NplOceConnection.lua", },callback);
end

function SceneHelper.getBoneNameConstraint(bone_name,bone_name_constraint)
	if(not bone_name or not bone_name_constraint)then
		return
	end
	local result = {};
	-- union all properties to one table
	for k,v in pairs(bone_name_constraint) do
		local names = v.names; 
		local values = v.values; 
		for kk,vv in pairs(names) do
			if(bone_name == vv)then
				for kkk,vvv in pairs(values) do
					result[kkk] = vvv;
				end
			end
		end
	end
	return result;
end
function SceneHelper.getBoneCombineName(bone_name,bone_name_constraint)
	local constraint = SceneHelper.getBoneNameConstraint(bone_name,bone_name_constraint);
	if(constraint)then
		bone_name = string.format("%s %s",bone_name,commonlib.serialize(constraint));
	end
	return bone_name;
end
-- load parax template 
function SceneHelper.loadParaXTemplateFromDisc()
	local parax_template_data = SceneHelper.parax_template_data;
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
	SceneHelper.parax_template_data = parax_template_data;
	return parax_template_data;
end
-- create polygon
-- this is in right-hand coordinate
-- @param plane: "xy" or "yz" or "xz"


-- @param sides: the number of edge
-- @param center_h: horizontal axis
-- @param center_v: vertical axis
-- @param radius: 
-- @return pointList
--[[
            z
            *
            *      y
            *     *
            *   *
            * *
            * * * * * * * x

--]]
function SceneHelper.createRegularPolygonPointsInPlane(plane, sides, center_h, center_v, radius)
    local result = SceneHelper.createRegularPolygonPoints(sides, center_h, center_v, radius);
    local x = 0;
    local y = 0;
    local z = 0;
    local temp = {};
    local pointList = {};
    for k,pos in ipairs(result) do
        local h = pos.h; 
        local v = pos.v; 

        x,y,z = SceneHelper.convert_xy_to_xyz(plane, h, v);

        table.insert(temp,{
            x = x,
            y = y,
            z = z,
        })
    end
    for k=1, sides-1 do
        local from_pos = temp[k];
        local to_pos = temp[k+1];
        table.insert(pointList,{
            from_pos = from_pos,
            to_pos = to_pos,
        })
    end
    table.insert(pointList,{
        from_pos = temp[sides],
        to_pos = temp[1],
    })
    return pointList
end
-- create polygon
-- this is in right-hand coordinate
-- @param sides: the number of edge
-- @param center_h: horizontal axis
-- @param center_v: vertical axis
-- @param radius: 
-- @return pointList
function SceneHelper.createRegularPolygonPoints(sides, center_h, center_v, radius)
    sides = sides or 3;
    if(sides < 3)then
        sides = 3;    
    end
    if(radius < 0)then
        radius = 1;
    end
    local angular_diff = 2 * math.pi/ sides;
    local pointList = {};
    for k = 1, sides do
        local cos_v = math.cos(angular_diff * (k - 1));
        local sin_v = math.sin(angular_diff * (k - 1));
        local h = center_h + radius * cos_v;
        local v = center_v + radius * sin_v;
        table.insert(pointList, { h = h, v = v });
    end
    return pointList;
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
function SceneHelper.convert_xy_to_xyz(plane, x, y)
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