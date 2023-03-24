--[[
Title: ShapeBuilder
Author(s): leio
Date: 2018/12/6
Desc: Create shapes for blockly, the opened functions have same definitions with NplOceDoc.lua, which include a scene graph for renderering mesh
use the lib:
------------------------------------------------------------
-- export shape to json
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce/nploce_d.dll", activate_callback = "Mod/NplCad2/NplOceConnection.lua", },function(msg)
	local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
	ShapeBuilder.create();
	local cube = ShapeBuilder.cube();
	ShapeBuilder.createShape(cube);
	local s = ShapeBuilder.toJson();
	echo(s);
end);
------------------------------------------------------------
--]]
NPL.load("(gl)script/apps/Aries/Creator/Game/Common/Files.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/vector.lua");
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local SvgParser = NPL.load("Mod/NplCad2/Svg/SvgParser.lua");
local Color = commonlib.gettable("System.Core.Color");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");
local Quaternion = commonlib.gettable("mathlib.Quaternion");
local vector3d = commonlib.gettable("mathlib.vector3d");
local Files = commonlib.gettable("MyCompany.Aries.Game.Common.Files");
local Encoding = commonlib.gettable("System.Encoding");


local ShapeBuilder = NPL.export();
ShapeBuilder.Precision_Confusion = 0.0000001
ShapeBuilder.scene = nil;
ShapeBuilder.root_node = nil; 
ShapeBuilder.cur_node = nil; -- for boolean/add node
ShapeBuilder.selected_node = nil; -- for transforming node
ShapeBuilder.root_joint = nil; -- for binding bones
ShapeBuilder.cur_joint = nil; -- for binding bones
ShapeBuilder.export_file_context = nil; -- for exporting .stl/.gltf file
ShapeBuilder.cur_animation = nil; 
ShapeBuilder.cur_channel_config = {}; 
ShapeBuilder.liner = 0.5;
ShapeBuilder.angular = 28.5;

ShapeBuilder.default_red_color = { 1, 0, 0, 1, };
ShapeBuilder.default_color = { 255/255, 198/255, 88/255, 1, };

ShapeBuilder.runningNodeTypes = { 
	pushStage = "pushStage", 
	pushNode = "pushNode", 
	createNode = "createNode", 
};

function ShapeBuilder.exportFile(type)
	if(not type)then
		return
	end
	local export_file_context =  ShapeBuilder.export_file_context or {};
	for k,v in ipairs(export_file_context) do
		if(type == v.type)then
			return
		end
	end
	table.insert(export_file_context,{
		type = type,
		binary = true,
	});
	ShapeBuilder.export_file_context = export_file_context;
end
function ShapeBuilder.runExportFiles(filename)
	local export_file_context =  ShapeBuilder.export_file_context;
	if(not filename or not export_file_context)then
		return
	end
	filename = string.match(filename, [[(.+).(.+)$]]);
	for k,v in ipairs(export_file_context) do
		local type = v.type;
		local binary = v.binary;
		if(type == "stl")then
			SceneHelper.saveSceneToStl(filename .. ".stl",ShapeBuilder.scene,false, false,binary, false, false, ShapeBuilder.liner, ShapeBuilder.angular);
		elseif(type == "gltf")then
			SceneHelper.saveSceneToGltf(filename .. ".gltf",ShapeBuilder.scene, false, ShapeBuilder.liner, ShapeBuilder.angular);
		end
	end
end
-- create a animation
function ShapeBuilder.createAnimation(name,is_enabled)
	local name = name or ShapeBuilder.generateId();
	local animation_manager = NplOce.AnimationManager.getInstance();
	local animation = animation_manager:createAnimation(name);
	is_enabled = ShapeBuilder.getBoolean(is_enabled);
	animation:setEnabled(is_enabled);
	ShapeBuilder.cur_animation = animation; 
end
-- create a config table before add a channel to cur_animation
function ShapeBuilder.addChannel(name,curve_type)
	curve_type = ShapeBuilder.getCurveType(curve_type)
	ShapeBuilder.cur_channel_config = {
		name = name,
		curve_type = curve_type,
		timeValues = {},
	}; 
end
-- create a really channel with the cur_channel_config
function ShapeBuilder.endChannel()
	local cur_channel_config = ShapeBuilder.cur_channel_config;
	local cur_animation = ShapeBuilder.cur_animation; 
	if(cur_channel_config and cur_animation)then
		-- get target 
		local name = cur_channel_config.name;
		local node = ShapeBuilder.getCurStage():findNode(name);
		if(node)then
			local curve_type = cur_channel_config.curve_type;
			local timeValues = cur_channel_config.timeValues or {};

			local key_values_map = {};
			for k,v in ipairs(timeValues) do
				local propertyId = v.propertyId;
				local key_values = key_values_map[propertyId];
				-- filter time/value by propertyId which value is ANIMATE_TRANSLATE or ANIMATE_SCALE or ANIMATE_ROTATE
				if(not key_values)then
					key_values = {};
					key_values_map[propertyId] = key_values;
				end
				table.insert(key_values,v);
			end
	
			for propertyId,data in pairs (key_values_map) do
				-- sort by time
				table.sort(data,function(a,b)
					return a.time < b.time;
				end)
				local keyTimes = {};
				local keyValues = {};
				for __,v in ipairs (data) do
					local time = v.time;
					local value = v.value;
					table.insert(keyTimes,time);

					-- converte table to array
					for __,vv in ipairs(value) do
						table.insert(keyValues,vv);
					end
				end
				local cnt = #keyTimes;
				cur_animation:addChannel(node,propertyId,cnt,keyTimes,keyValues,curve_type);
			end
		end
	end
	-- clear cur_channel_config
	ShapeBuilder.cur_channel_config = {};
end
function ShapeBuilder.getCurveType(type)
	local curve_type;
	if(type == "linear")then
		curve_type = NplOce.Curve_Enum.LINEAR;
	elseif(type == "step")then
		curve_type = NplOce.Curve_Enum.STEP;
	end
	return curve_type;
end
-- get property id
-- @param {string} [transform_type = "translate"] - the type of transformation, "translate" or "scale" or "rotate"
function ShapeBuilder.getPropertyId(transform_type)
	local propertyId;
	if(transform_type == "translate")then
		propertyId = NplOce.Transform_Enum.ANIMATE_TRANSLATE;
	elseif(transform_type == "scale")then
		propertyId = NplOce.Transform_Enum.ANIMATE_SCALE;
	elseif(transform_type == "rotate")then
		propertyId = NplOce.Transform_Enum.ANIMATE_ROTATE;
	end
	return propertyId;
end
-- insert time,value to a table of current channel with translation
-- @param {string} [time = "0"] - key time
-- @param {table} value - key value
function ShapeBuilder.setAnimationTimeValue(transform_type, time, value)
	local propertyId = ShapeBuilder.getPropertyId(transform_type);
	local cur_channel_config = ShapeBuilder.cur_channel_config;
	if(cur_channel_config and cur_channel_config.timeValues)then
		local timeValues = cur_channel_config.timeValues;
		table.insert(timeValues,{propertyId = propertyId, time = time, value = value })
	end
	
end
function ShapeBuilder.setAnimationTimeValue_Translate(time,x,y,z)
	local value = {x,y,z};
	ShapeBuilder.setAnimationTimeValue("translate", time, value);
end
function ShapeBuilder.setAnimationTimeValue_Scale(time,x,y,z)
	local value = {x,y,z};
	ShapeBuilder.setAnimationTimeValue("scale", time, value);
end
function ShapeBuilder.setAnimationTimeValue_Rotate(time,axis,angle)
	local x,y,z;
	angle = angle or 0;
	angle = angle * math.pi * (1.0 / 180.0);
	if(axis == "x")then
		x = 1;
		y = 0;
		z = 0;
	end
	if(axis == "y")then
		x = 0;
		y = 1;
		z = 0;
	end
	if(axis == "z")then
		x = 0;
		y = 0;
		z = 1;
	end
	local rkAxis = vector3d:new(x,y,z)
	local q = Quaternion:new():FromAngleAxis(angle, rkAxis);
	local value = { q[1], q[2], q[3], q[4] }
	ShapeBuilder.setAnimationTimeValue("rotate", time,value);
end
function ShapeBuilder.createJointRoot(name, is_enabled, x, y, z)
	local name = name or ShapeBuilder.generateId();
	local joint = NplOce.Joint.create(name);
	x = x or 0;
	y = y or 0;
	z = z or 0;
	is_enabled = ShapeBuilder.getBoolean(is_enabled)
	joint:setEnabled(is_enabled);
	ShapeBuilder.setTranslation(joint,x,y,z) 

	ShapeBuilder.getRootNode():addChild(joint)
	ShapeBuilder.root_joint = joint;
	ShapeBuilder.cur_joint = joint;

end
function ShapeBuilder.createJoint(name,x,y,z)
	local name = name or ShapeBuilder.generateId();
	local joint = NplOce.Joint.create(name);
	ShapeBuilder.cur_joint:addChild(joint);

	ShapeBuilder.setTranslation(joint,x,y,z) 
	ShapeBuilder.cur_joint = joint;
	-- only map joint for bone constraint name
	ShapeBuilder.scene.joints_map[joint] = "";
end
function ShapeBuilder.endJoint()
	local cur_joint = ShapeBuilder.cur_joint;
	local parent;
	if(cur_joint)then
		parent = cur_joint:getParent();
	end
	ShapeBuilder.cur_joint = parent or ShapeBuilder.root_joint;
end
function ShapeBuilder.bindNodeByName(name)
	local cur_joint = ShapeBuilder.cur_joint;
	if(not cur_joint)then
		return
	end
	-- only 1 joint can be bound
	-- ignore checking node existed
	-- binding joints at last
	ShapeBuilder.scene.joints_map[cur_joint] = name;
end
function ShapeBuilder.rotateJoint(axis,angle)
	ShapeBuilder.multiRotationToNode(ShapeBuilder.cur_joint,axis,angle)
end
function ShapeBuilder.rotateJointQuaternion(x,y,z,w)
	ShapeBuilder.setRotationQuaternionToNode(ShapeBuilder.cur_joint,x,y,z,w);
end

function ShapeBuilder.startBoneNameConstraint()
	local name = ShapeBuilder.generateId();
	ShapeBuilder.scene.bone_name_constraint[name] = {};    
	ShapeBuilder.scene.cur_bone_name_constraint = ShapeBuilder.scene.bone_name_constraint[name];
end
function ShapeBuilder.endBoneNameConstraint()
	if(ShapeBuilder.scene.cur_bone_name_constraint)then
		ShapeBuilder.scene.cur_bone_name_constraint = nil;
	end
end
-- bind a bone name
function ShapeBuilder.setBoneConstraint_Name(name)
	if(not ShapeBuilder.scene.cur_bone_name_constraint)then   
		return
	end
	local names = ShapeBuilder.scene.cur_bone_name_constraint.names or {};
	names[name] = name;
	ShapeBuilder.scene.cur_bone_name_constraint.names = names;
end
function ShapeBuilder.setBoneConstraint(name,value)
	if(not ShapeBuilder.scene.cur_bone_name_constraint)then   
		return
	end
	if(name == "min" or name == "max" or name == "servoOffset")then
		value = value * 3.1415926 / 180;
	end
	local values = ShapeBuilder.scene.cur_bone_name_constraint.values or {};
	values[name] = value;
	ShapeBuilder.scene.cur_bone_name_constraint.values = values;
end
function ShapeBuilder.getCurStage()
	return ShapeBuilder.cur_stage;
end
-- the stage node is in top of a single document
function ShapeBuilder.pushStage(op,name,color,bOp)
	local node = ShapeBuilder.pushNode(op,name,color,bOp)
    node:setTag("runningNodeType", ShapeBuilder.runningNodeTypes.pushStage);
	ShapeBuilder.pre_stage = ShapeBuilder.cur_stage;
	ShapeBuilder.cur_stage = node;

	return node;
end
function ShapeBuilder.popStage()
	ShapeBuilder.popNode()
	ShapeBuilder.cur_stage = ShapeBuilder.pre_stage;
	ShapeBuilder.pre_stage = nil;
end
function ShapeBuilder.pushNode(op,name,color,bOp)
	local name = name or ShapeBuilder.generateId();
	local node = NplOce.ShapeNode.create(name);
	node:setOp(op);
	node:setOpEnabled(bOp);
	node:setColor(ShapeBuilder.converColorToRGBA(color));
    node:setTag("runningNodeType", ShapeBuilder.runningNodeTypes.pushNode);

	local parent = ShapeBuilder.cur_node or ShapeBuilder.getRootNode();
	parent:addChild(node)
	ShapeBuilder.cur_node = node;
	ShapeBuilder.selected_node = node;

	table.insert(ShapeBuilder.scene.pushed_node_list,node);
	return node
end
function ShapeBuilder.popNode()
	local len = #ShapeBuilder.scene.pushed_node_list;
	local node = ShapeBuilder.scene.pushed_node_list[len];
	local parent = node:getParent() or ShapeBuilder.getRootNode();

	table.remove(ShapeBuilder.scene.pushed_node_list,len);
	ShapeBuilder.cur_node = parent;
	ShapeBuilder.selected_node = node;
	
end
function ShapeBuilder.getNode(name)
    if(not name or name == "")then
        return ShapeBuilder.getRootNode();
    end
	local node = ShapeBuilder.getCurStage():findNode(name);
    return node
end
function ShapeBuilder.getChildCount(name)
	local node = ShapeBuilder.getNode(name);
    if(node)then
        return node:getChildCount();
    end
    return -1
end

function ShapeBuilder.createNode(name,color,bOp)
	local name = name or ShapeBuilder.generateId();
	local node = NplOce.ShapeNode.create(name);
	node:setOpEnabled(bOp);
	node:setColor(ShapeBuilder.converColorToRGBA(color));
    node:setTag("runningNodeType", ShapeBuilder.runningNodeTypes.createNode);
	
	local cur_node = ShapeBuilder.cur_node;
	local parent;
	if(cur_node)then
		local type = cur_node:getTag("runningNodeType");
		if(type == ShapeBuilder.runningNodeTypes.createNode)then
			-- get parent
			parent = cur_node:getParent();
		elseif(type == ShapeBuilder.runningNodeTypes.pushNode or type == ShapeBuilder.runningNodeTypes.pushStage)then
			-- set cur_node as parent
			parent = cur_node;
		end
	end
	parent = parent or ShapeBuilder.getCurStage() or ShapeBuilder.getRootNode();
	parent:addChild(node)
	ShapeBuilder.cur_node = node;
	ShapeBuilder.selected_node = node;
	return node
end
function ShapeBuilder.cloneNodeByName(op,name,color)
	if(ShapeBuilder.isEmpty(name))then
		return
	end
	local node = ShapeBuilder.getCurStage():findNode(name);
	return ShapeBuilder._cloneNode(node,op,color)
end
function ShapeBuilder.cloneNode(op,color)
	return ShapeBuilder._cloneNode(ShapeBuilder.selected_node,op,color)
end
function ShapeBuilder._cloneNode(node,op,color)
	if(not node)then
		return
	end
	local cloned_node = node:clone();
	cloned_node:setOp(op);
	cloned_node:setColor(ShapeBuilder.converColorToRGBA(color));
	SceneHelper.clearNodesId(cloned_node)

	ShapeBuilder.cur_node:addChild(cloned_node);
	ShapeBuilder.selected_node = cloned_node;
	return cloned_node
end
function ShapeBuilder.deleteNode(name)
	if(ShapeBuilder.isEmpty(name))then
		return
	end
	local node = ShapeBuilder.getCurStage():findNode(name);
	if(node)then
		if(node == ShapeBuilder.cur_node or node == ShapeBuilder.selected_node )then
			return
		end
		local parent = node:getParent();
		parent:removeChild(node);
	end
end

function ShapeBuilder.setDeltaMatrix(matrix_arr)
	local node = ShapeBuilder.getSelectedNode();
	node:setDeltaMatrix(matrix_arr);
end
function ShapeBuilder.setDeltaMatrix_Node(name,matrix_arr)
	if(ShapeBuilder.isEmpty(name))then
		return
	end
	local node = ShapeBuilder.getCurStage():findNode(name);
	if(node)then
		node:setDeltaMatrix(matrix_arr);
	end
end

--function ShapeBuilder.setLocalPivotMatrix(matrix_arr)
--	ShapeBuilder.setDeltaMatrix(matrix_arr)
--end
--function ShapeBuilder.setLocalPivotMatrix_Node(name,matrix_arr)
--	ShapeBuilder.setDeltaMatrix_Node(name,matrix_arr)
--end
--
--function ShapeBuilder.setLocalPivot(x,y,z)
--	local node = ShapeBuilder.getSelectedNode();
--	node:setLocalPivot(x,y,z);
--end
--function ShapeBuilder.setLocalPivot_Node(name,x,y,z)
--	if(ShapeBuilder.isEmpty(name))then
--		return
--	end
--	local node = ShapeBuilder.getCurStage():findNode(name);
--	if(node)then
--		node:setLocalPivot(x,y,z);
--	end
--end
--
--function ShapeBuilder.setLocalPivotOffset(x,y,z)
--	local node = ShapeBuilder.getSelectedNode();
--	node:setLocalPivot(-x,-y,-z);
--end
--function ShapeBuilder.setLocalPivotOffset_Node(name,x,y,z)
--	if(ShapeBuilder.isEmpty(name))then
--		return
--	end
--	local node = ShapeBuilder.getCurStage():findNode(name);
--	if(node)then
--		node:setLocalPivot(-x,-y,-z);
--	end
--end

function ShapeBuilder.move(x,y,z)
	local node = ShapeBuilder.getSelectedNode();
	ShapeBuilder.translate(node,x,y,z);
end
function ShapeBuilder.moveNode(name,x,y,z)
	if(ShapeBuilder.isEmpty(name))then
		return
	end
	local node = ShapeBuilder.getCurStage():findNode(name);
	if(node)then
		ShapeBuilder.translate(node,x,y,z);
	end
end

function ShapeBuilder.scale(x,y,z)
	local node = ShapeBuilder.getSelectedNode();
	ShapeBuilder.setScale(node,x,y,z);
end
function ShapeBuilder.scaleNode(name,x,y,z)
	local node = ShapeBuilder.getCurStage():findNode(name);
	ShapeBuilder.setScale(node,x,y,z);
end

function ShapeBuilder.rotate(axis,angle)
	ShapeBuilder.multiRotationToNode(ShapeBuilder.getSelectedNode(),axis,angle);
end
function ShapeBuilder.rotateNode(name,axis,angle)
	if(ShapeBuilder.isEmpty(name))then
		return
	end
	local node = ShapeBuilder.getCurStage():findNode(name);
	if(node)then
		ShapeBuilder.multiRotationToNode(node,axis,angle);
	end
end
-- Set rotation
-- @param {NplOce.ShapeNode} node
-- @param {string} axis - "x" or "y" or "z"
-- @param {number} angle -degree
function ShapeBuilder.setRotationToNode(node,axis,angle)
	if(not node)then
		return
	end
	local x,y,z;
	angle = angle or 0;
	angle = angle * math.pi * (1.0 / 180.0);
	if(axis == "x")then
		x = 1;
		y = 0;
		z = 0;
	end
	if(axis == "y")then
		x = 0;
		y = 1;
		z = 0;
	end
	if(axis == "z")then
		x = 0;
		y = 0;
		z = 1;
	end
	node:setRotation(x,y,z,angle)
end
-- Set rotation
-- @param {NplOce.ShapeNode} node
-- @param {string} axis - "x" or "y" or "z"
-- @param {number} angle -degree
function ShapeBuilder.multiRotationToNode(node,axis,angle)
	if(not node)then
		return
	end
	angle = angle or 0;
	angle = angle * math.pi * (1.0 / 180.0);
	local x = nil;
    local y = nil;
    local z = nil;

	if(axis == "x")then
		x = 1;
		y = 0;
		z = 0;
	end
	if(axis == "y")then
		x = 0;
		y = 1;
		z = 0;
	end
	if(axis == "z")then
		x = 0;
		y = 0;
		z = 1;
	end
	local rkAxis = vector3d:new(x,y,z)
	local q_input = Quaternion:new():FromAngleAxis(angle, rkAxis);
	local matrix = Matrix4:new(node:getRotationMatrix());
	local q = Quaternion:new();
	q:FromRotationMatrix(matrix);
	q = q_input * q;
	matrix = q:ToRotationMatrix();
	
	node:setRotationMatrix(matrix)
	--[[
	-- for text shape node, all letters are sibling
	local next = node:getNextSibling();
	while (next) do
		next:setRotationMatrix(matrix);
		next = next:getNextSibling();
	end
	]]
end
function ShapeBuilder.setRotationQuaternion(x,y,z,w)
	local node = ShapeBuilder.getSelectedNode();
	ShapeBuilder.setRotationQuaternionToNode(node,x,y,z,w);
end
function ShapeBuilder.setRotationQuaternionToNode(node,x,y,z,w)
	if(not node)then
		return
	end
	node:setRotationQuaternion({x,y,z,w});
end
function ShapeBuilder.rotateFromPivot(axis,angle,pivot_x,pivot_y,pivot_z)
	ShapeBuilder.SetRotationFromPivot(ShapeBuilder.getSelectedNode(),axis,angle,pivot_x or 0,pivot_y or 0,pivot_z or 0)
end
function ShapeBuilder.rotateNodeFromPivot(name,axis,angle,pivot_x,pivot_y,pivot_z)
	if(ShapeBuilder.isEmpty(name))then
		return
	end
	local node = ShapeBuilder.getCurStage():findNode(name);
	if(node)then
		ShapeBuilder.SetRotationFromPivot(node,axis,angle,pivot_x or 0,pivot_y or 0,pivot_z or 0)
	end
end
-- Set rotation 
-- @param {NplOce.ShapeNode} node
-- @param {string} axis - "x" or "y" or "z"
-- @param {number} [angle = 0] - degree
-- @param {number} [pivot_x = 0]
-- @param {number} [pivot_y = 0]
-- @param {number} [pivot_z = 0]
function ShapeBuilder.SetRotationFromPivot(node,axis,angle,pivot_x,pivot_y,pivot_z)
	if(not node)then
		return
	end
	angle = angle or 0;
	local rotate_matrix;
	if(axis == "x")then
		rotate_matrix = Matrix4.rotationX(angle);
	end
	if(axis == "y")then
		rotate_matrix = Matrix4.rotationY(angle);
	end
	if(axis == "z")then
		rotate_matrix = Matrix4.rotationZ(angle);
	end

	local matrix = Matrix4:new(node:getMatrix());

	local matrix_1 = Matrix4.translation({-pivot_x,-pivot_y,-pivot_z})
	local matrix_2 = Matrix4.translation({pivot_x,pivot_y,pivot_z})
	local transform_matrix = matrix * matrix_1 * rotate_matrix * matrix_2;
	node:setMatrix(transform_matrix)
	--[[
	-- for text shape node, all letters are sibling
	local next = node:getNextSibling();
	while (next) do
		next:setMatrix(transform_matrix);
		next = next:getNextSibling();
	end
	]]
end

-- make fillet
-- @param {number} [radius = 0.1]
-- @param {axis_axis_plane} xyz|xy|xz|yz
-- @param {select_all} true|false 
function ShapeBuilder.fillet(axis_axis_plane, radius)
	local node = ShapeBuilder.getSelectedNode();
	if (node ~= nil) then
		ShapeBuilder._fillet(node, axis_axis_plane, radius)
	end
end

function ShapeBuilder.filletNode(name, axis_axis_plane, radius)
	local node = ShapeBuilder.getCurStage():findNode(name);
	if (node ~= nil) then
		ShapeBuilder._fillet(node, axis_axis_plane, radius)
	end
end

function ShapeBuilder._fillet(node, axis_axis_plane, radius) 
	local axis_x, axis_y, axis_z = 0, 0, 0;
	local dir_x, dir_y, dir_z = 0, 0, 0;
	local edges = {};
	if (axis_axis_plane == "xyz") then
		axis_x, axis_y, axis_z = 1, 1, 1;
	elseif(axis_axis_plane == "x")then
		axis_x = 1;
	elseif(axis_axis_plane == "y")then
		axis_y = 1;
	elseif(axis_axis_plane == "z")then
		axis_z = 1;
	elseif(axis_axis_plane == "xy")then
		dir_z = 1;
	elseif(axis_axis_plane == "xz")then
		dir_y = 1;
	elseif(axis_axis_plane == "yz" or axis_axis_plane == "zy" )then
		dir_x = 1;
	elseif(type(axis_axis_plane) == "number") then
		edges[1] = axis_axis_plane
	elseif(type(axis_axis_plane) == "table") then
		edges = axis_axis_plane;
	else
		-- invalid param, axis_axis_plane
		return;
	end

	SceneHelper.runNode(node);
	local model = node:getDrawable();
	if (model ~= nil) then
		local shape = model:getShape();
		if (shape ~= nil) then
			local fillet_shape = NplOce.fillet(shape, radius, {axis_x, axis_y, axis_z}, {dir_x, dir_y, dir_z}, #edges, edges);
			if (not fillet_shape:IsNull()) then
				model:setShape(fillet_shape);
			end
		end
	end
end

-- make chamfer
-- @param {number} [radius = 0.1]
-- @param {axis_axis_plane} xyz|xy|xz|yz
-- @param {select_all} true|false 
function ShapeBuilder.chamfer(axis_axis_plane, radius)
	local node = ShapeBuilder.getSelectedNode();
	if (node ~= nil) then
		ShapeBuilder._chamfer(node, axis_axis_plane, radius)
	end
end

function ShapeBuilder.chamferNode(name, axis_axis_plane, radius)
	local node = ShapeBuilder.getCurStage():findNode(name);
	if (node ~= nil) then
		ShapeBuilder._chamfer(node, axis_axis_plane, radius)
	end
end

function ShapeBuilder._chamfer(node, axis_axis_plane, radius) 
	local axis_x, axis_y, axis_z = 0, 0, 0;
	local dir_x, dir_y, dir_z = 0, 0, 0;
	local edges = {};
	if (axis_axis_plane == "xyz") then
		axis_x, axis_y, axis_z = 1, 1, 1;
	elseif(axis_axis_plane == "x")then
		axis_x = 1;
	elseif(axis_axis_plane == "y")then
		axis_y = 1;
	elseif(axis_axis_plane == "z")then
		axis_z = 1;
	elseif(axis_axis_plane == "xy")then
		dir_z = 1;
	elseif(axis_axis_plane == "xz")then
		dir_y = 1;
	elseif(axis_axis_plane == "yz" or axis_axis_plane == "zy" )then
		dir_x = 1;
	elseif(type(axis_axis_plane) == "number") then
		edges[1] = axis_axis_plane
	elseif(type(axis_axis_plane) == "table") then
		edges = axis_axis_plane;
	else
		-- invalid param, axis_axis_plane
		return;
	end

	SceneHelper.runNode(node);
	local model = node:getDrawable();
	if (model ~= nil) then
		local shape = model:getShape();
		if (shape ~= nil) then
			local fillet_shape = NplOce.chamfer(shape, radius, {axis_x, axis_y, axis_z}, {dir_x, dir_y, dir_z}, #edges, edges);
			if (not fillet_shape:IsNull()) then
				model:setShape(fillet_shape);
			end
		end
	end
end

-- extrude
-- @param {number} height
function ShapeBuilder.extrude(height)
	local node = ShapeBuilder.getSelectedNode();
	if (node ~= nil) then
		SceneHelper.runNode(node);
		local model = node:getDrawable();
		if (model ~= nil) then
			local shape = model:getShape();
			if (shape ~= nil) then
				local extrude_shape = NplOce.extrude(shape, height);
				if (not extrude_shape:IsNull()) then
					model:setShape(extrude_shape);
				end
			end
		end
	end
end

-- revolve
-- @param {string} axis
-- @param {number} angle
function ShapeBuilder.revolve(axis, angle)
	local axis_x, axis_y, axis_z = 0, 0, 0;
	if(axis == "x")then
		axis_x = 1;
	elseif(axis == "y")then
		axis_y = 1;
	elseif(axis == "z")then
		axis_z = 1;
	else
		-- invalid param, axis
		return;
	end

	local node = ShapeBuilder.getSelectedNode();
	if (node ~= nil) then
		SceneHelper.runNode(node);
		local model = node:getDrawable();
		if (model ~= nil) then
			local shape = model:getShape();
			if (shape ~= nil) then
				local w_matrix = SceneHelper.getTranformMatrixFrom(node, node);
				local matrix_shape = Matrix4:new(shape:getMatrix());
				local clone_shape = shape:clone();
				clone_shape:setMatrix(matrix_shape * w_matrix);
				local extrude_shape = NplOce.revolve(clone_shape, axis_x, axis_y, axis_z, angle);
				if (not extrude_shape:IsNull()) then
					model:setShape(extrude_shape);
					node:setMatrix(Matrix4:new():identity());
				end
			end
		end
	end
end

function ShapeBuilder.mirrorNode(name,axis_plane,x,y,z) 
	local node = ShapeBuilder.getCurStage():findNode(name);
	ShapeBuilder._mirrorNode(node,axis_plane,x,y,z);
end
function ShapeBuilder.mirror(axis_plane,x,y,z) 
	local node = ShapeBuilder.getSelectedNode();
	ShapeBuilder._mirrorNode(node,axis_plane,x,y,z);
end
-- Mirror all of shapes in node
function ShapeBuilder._mirrorNode(node,axis_plane,x,y,z) 
	if(not node)then
		return
	end
	local dir_x,dir_y,dir_z = 0,0,0;
	if(axis_plane == "xy")then
		dir_z = 1;
	elseif(axis_plane == "xz")then
		dir_y = 1;
	elseif(axis_plane == "yz" or axis_plane == "zy" )then
		dir_x = 1;
	end
	local parent = node:getParent();
	if(not parent)then
		return
	end
	local mirror_node_root = NplOce.ShapeNode.create();
	local top_node = node:clone();
	SceneHelper.runNode(top_node);
	SceneHelper.visitNode(top_node,function(node)
		local model = node:getDrawable();
		if(model)then
			local shape = model:getShape();
			if(shape)then
				local w_matrix = SceneHelper.drawableTransform(model, parent)
				local matrix_shape = Matrix4:new(shape:getMatrix());
				w_matrix = matrix_shape * w_matrix;

				shape:setMatrix(w_matrix);
				-- use world matrix on top_node to mirror
				local mirror_shape = NplOce.mirror(shape, {x,y,z}, {dir_x,dir_y,dir_z})


				local mirror_model = NplOce.ShapeModel.create();
				mirror_model:setShape(mirror_shape);

				local mirror_node = NplOce.ShapeNode.create();
				mirror_node:setColor(node:getColor());
				mirror_node:setOp(node:getOp());
				mirror_node:setDrawable(mirror_model);
				mirror_node_root:addChild(mirror_node);

				--TODO:destroy shape
			end
		end
	end)

	ShapeBuilder.cur_node:addChild(mirror_node_root);
	ShapeBuilder.selected_node = mirror_node_root;
end


function ShapeBuilder.getSelectedNode()
	return ShapeBuilder.selected_node;
end
-- Get the current level node
function ShapeBuilder.getCurNode()
	return ShapeBuilder.cur_node;
end
function ShapeBuilder.getRootNode()
	return ShapeBuilder.root_node;
end
-- Create a scene
function ShapeBuilder.create()
	local animation_manager = NplOce.AnimationManager.getInstance();
	animation_manager:clear();
	ShapeBuilder.scene = NplOce.Scene.create(ShapeBuilder.generateId());
	ShapeBuilder.scene.max_triangle_cnt = 0;
	ShapeBuilder.cur_node = ShapeBuilder.scene:addNode(ShapeBuilder.generateId());
	ShapeBuilder.root_node = ShapeBuilder.cur_node; 
	ShapeBuilder.selected_node = ShapeBuilder.cur_node;
	ShapeBuilder.cur_stage = ShapeBuilder.cur_node;
	-- save binding relation temporarily before running boolean op in scene
	ShapeBuilder.scene.joints_map = {}; 
	-- clear export file context
	ShapeBuilder.export_file_context = nil;

	ShapeBuilder.scene.bone_name_constraint = {}; 

	ShapeBuilder.scene.pushed_node_list = {};
	ShapeBuilder.scene.pushed_sketch_node_list = {};
end
-- Set a scene for holding shapes
-- @param {NplOce.Scene} scene
function ShapeBuilder.setScene(scene)
	ShapeBuilder.scene = scene;
end

-- Get the scene
-- @return {NplOce.Scene} scene
function ShapeBuilder.getScene()
	return ShapeBuilder.scene;
end


-- Export the scene to json string with gltf format
-- @param exportCoordinateType: {number} 
-- @return {string} v
function ShapeBuilder.toJson(exportCoordinateType)
	local json = ShapeBuilder.scene:toGltf_String(exportCoordinateType);
	return json;
end

function ShapeBuilder.toStl(exportCoordinateType, bBinary, bEncodeBase64, bIncludeColor)
	local content = ShapeBuilder.scene:toStl_String(exportCoordinateType, bBinary, bEncodeBase64, bIncludeColor);
	return content;
end

function ShapeBuilder.toParaX()
	return SceneHelper.toParaX(ShapeBuilder.scene)
end

function ShapeBuilder.TestToGltf()
	if(ShapeBuilder.scene.toGltf_File)then
		local filename = ParaIO.GetCurDirectory(0).."test/test_string.gltf";
		filename = string.gsub(filename, "/", "\\");
		ParaIO.CreateDirectory(filename);
		local json = ShapeBuilder.scene:toGltf_String();

		local file = ParaIO.open(filename, "w");
		if(file:IsValid()) then
			file:write(json,#json);
			file:close();
		end


		local filename = ParaIO.GetCurDirectory(0).."test/test.gltf";
		filename = string.gsub(filename, "/", "\\");
		ShapeBuilder.scene:toGltf_File(filename,false,true,true,true,false);

		local filename = ParaIO.GetCurDirectory(0).."test/test.glb";
		filename = string.gsub(filename, "/", "\\");
		ShapeBuilder.scene:toGltf_File(filename,false,false,false,false,true);

		local filename = ParaIO.GetCurDirectory(0).."test/test2.glb";
		filename = string.gsub(filename, "/", "\\");
		ShapeBuilder.scene:toGltf_File(filename,false,true,true,false,true);
	end
end

-- Generate an unique id
-- @return {string} id;
function ShapeBuilder.generateId()
	return ParaGlobal.GenerateUniqueID();
end

function ShapeBuilder.addShapeNode(node,op,color) 
	if(not node)then
		return
	end
    op = op or "union"
	local cur_node = ShapeBuilder.getCurNode();
	if(cur_node)then
		node:setOp(op);
		node:setColor(ShapeBuilder.converColorToRGBA(color));
		cur_node:addChild(node);

		ShapeBuilder.selected_node = node;
		--[[
		if (node:getDrawable()) then
			node:setOp(op);
			node:setColor(ShapeBuilder.converColorToRGBA(color));
			cur_node:addChild(node);

			ShapeBuilder.selected_node = node;
		else
			local child = node:getFirstChild();
			if (child) then
				ShapeBuilder.selected_node = child;
			end
			while (child) do
				local next = child:getNextSibling();
				child:setOp(op);
				child:setColor(ShapeBuilder.converColorToRGBA(color));
				cur_node:addChild(child);
				child = next;
			end
		end
		]]
	end
	return node;
end


-- Import stl file
function ShapeBuilder.importStlFromStr(op, color, swapYZ, isBase64, data) 
	if(isBase64)then
		data = Encoding.unbase64(data);
	end
	local shape = NplOce.importStlBuffer(data,#data,swapYZ);
	local node = NplOce.ShapeNode.create();
	local model = NplOce.ShapeModel.create();
	model:setShape(shape);
	node:setDrawable(model);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.importStl(op,filename,color,swapYZ) 
	if(not filename)then
		return
	end
	filename = Files.GetFilePath(filename) or filename;
	local content;
	local file = ParaIO.open(filename, "r");
	if(file:IsValid()) then
		content = file:GetText(0,-1);
	end
	return ShapeBuilder.importStlFromStr(op, color, swapYZ, false, content);
end

-- Import step file
function ShapeBuilder.importSTEPFromStr(op, color, isBase64, data) 
	if(isBase64)then
		data = Encoding.unbase64(data);
	end
	local shape = NplOce.importSTEPBuffer("step_name_1", data);
	local node = NplOce.ShapeNode.create();
	local model = NplOce.ShapeModel.create();
	model:setShape(shape);
	node:setDrawable(model);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Import brep file
function ShapeBuilder.importBREPFromStr(op, color, isBase64, data) 
	if(isBase64)then
		data = Encoding.unbase64(data);
	end
	local shape = NplOce.importBREPFromStr(data);
	local node = NplOce.ShapeNode.create();
	local model = NplOce.ShapeModel.create();
	model:setShape(shape);
	node:setDrawable(model);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a cube
function ShapeBuilder.cube(op,size,color) 
	local node = NplOce.ShapeNodeBox.create();
	size = ShapeBuilder.checkPrecision(size);
	node:setValue(size,size,size);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
-- Create a box
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.box(op,x,y,z,color) 
	local node = NplOce.ShapeNodeBox.create();
	x = ShapeBuilder.checkPrecision(x);
	y = ShapeBuilder.checkPrecision(y);
	z = ShapeBuilder.checkPrecision(z);
	node:setValue(x,y,z);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a fillet box
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @param {table} edges
-- @param {values} values
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node

function ShapeBuilder.box_fillet(op, x, y, z, edges, values, color) 
	local node = NplOce.ShapeNodeFilletBox.create();
	x = ShapeBuilder.checkPrecision(x);
	y = ShapeBuilder.checkPrecision(y);
	z = ShapeBuilder.checkPrecision(z);
	edges = edges or {};
	local len = #edges;
	node:setValue(x,y,z,len,edges,values);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a chamfer box
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @param {table} edges
-- @param {values} values
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node

function ShapeBuilder.box_chamfer(op, x, y, z, edges, values, color) 
	local node = NplOce.ShapeNodeChamferBox.create();
	x = ShapeBuilder.checkPrecision(x);
	y = ShapeBuilder.checkPrecision(y);
	z = ShapeBuilder.checkPrecision(z);
	edges = edges or {};
	local len = #edges;
	node:setValue(x,y,z,len,edges,values);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end



-- Create a cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cylinder(op,radius,height,angle,color) 
	local node = NplOce.ShapeNodeCylinder.create();
	radius = ShapeBuilder.checkPrecision(radius);
	height = ShapeBuilder.checkPrecision(height);
	node:setValue(radius,height,angle);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.cylinder(op,radius,height,color) 
	ShapeBuilder._cylinder(op,radius,height,360,color);
end

-- Create a fillet cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {table} edges
-- @param {values} values
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.cylinder_fillet(op, radius, height, edges, values, color) 
	local node = NplOce.ShapeNodeFilletCylinder.create();
	radius = ShapeBuilder.checkPrecision(radius);
	height = ShapeBuilder.checkPrecision(height);
	edges = edges or {};
	local len = #edges;
	node:setValue(radius,height,360,len,edges,values);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a chamfer cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {table} edges
-- @param {values} values
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.cylinder_chamfer(op, radius, height, edges, values, color) 
	local node = NplOce.ShapeNodeChamferCylinder.create();
	radius = ShapeBuilder.checkPrecision(radius);
	height = ShapeBuilder.checkPrecision(height);
	edges = edges or {};
	local len = #edges;
	node:setValue(radius,height,360,len,edges,values);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a sphere
-- @param {number} [radius = 5]
-- @param {number} [angle1 = -90]
-- @param {number} [angle2 = 90]
-- @param {number} [angle3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._sphere(op,radius,angle1,angle2,angle3,color) 
	local node = NplOce.ShapeNodeSphere.create();
	radius = ShapeBuilder.checkPrecision(radius);
	node:setValue(radius,angle1,angle2,angle3);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.sphere(op,radius,color) 
	ShapeBuilder._sphere(op,radius,-90,90,360,color);
end
-- Create a cone
-- @param {number} [top_radius = 2]
-- @param {number} [bottom_radius = 4]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cone(op,top_radius,bottom_radius,height,angle,color) 
	local node = NplOce.ShapeNodeCone.create();
	top_radius = ShapeBuilder.checkPrecision(top_radius);
	bottom_radius = ShapeBuilder.checkPrecision(bottom_radius);
	height = ShapeBuilder.checkPrecision(height);
	node:setValue(top_radius,bottom_radius,height,angle);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.cone(op,top_radius,bottom_radius,height,color) 
	ShapeBuilder._cone(op,top_radius,bottom_radius,height,360,color);
end

-- Create a fillet cone
-- @param {number} [top_radius = 2]
-- @param {number} [bottom_radius = 4]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {table} edges
-- @param {values} values
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node

function ShapeBuilder.cone_fillet(op, top_radius, bottom_radius, height, edges, values, color) 
	local node = NplOce.ShapeNodeFilletCone.create();
	top_radius = ShapeBuilder.checkPrecision(top_radius);
	bottom_radius = ShapeBuilder.checkPrecision(bottom_radius);
	height = ShapeBuilder.checkPrecision(height);
	edges = edges or {};
	local len = #edges;
	node:setValue(top_radius,bottom_radius,height,360,len,edges,values);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a chamfer cone
-- @param {number} [top_radius = 2]
-- @param {number} [bottom_radius = 4]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {table} edges
-- @param {values} values
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node

function ShapeBuilder.cone_chamfer(op, top_radius, bottom_radius, height, edges, values, color) 
	local node = NplOce.ShapeNodeChamferCone.create();
	top_radius = ShapeBuilder.checkPrecision(top_radius);
	bottom_radius = ShapeBuilder.checkPrecision(bottom_radius);
	height = ShapeBuilder.checkPrecision(height);
	edges = edges or {};
	local len = #edges;
	node:setValue(top_radius,bottom_radius,height,360,len,edges,values);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create a torus
-- @param {number} [radius1 = 10]
-- @param {number} [radius2 = 2]
-- @param {number} [angle1 = -180]
-- @param {number} [angle2 = 180]
-- @param {number} [angle3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._torus(op,radius1,radius2,angle1,angle2,angle3,color) 
	local node = NplOce.ShapeNodeTorus.create();
	radius1 = ShapeBuilder.checkPrecision(radius1);
	radius2 = ShapeBuilder.checkPrecision(radius2);
	node:setValue(radius1,radius2,angle1,angle2,angle3);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.torus(op,radius1,radius2,color) 
	ShapeBuilder._torus(op,radius1,radius2,-180,180,360,color);
end

-- Create a prism
-- @param {number} [edges = 6]
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.prism(op,edges, radius, height,color) 
	local node = NplOce.ShapeNodePrism.create();
	radius = ShapeBuilder.checkPrecision(radius);
	height = ShapeBuilder.checkPrecision(height);
	node:setValue(edges, radius, height);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.wedge_full(op,x1, y1, z1, x3, z3, x2, y2, z2, x4, z4,color) 
	local node = NplOce.ShapeNodeWedge.create();
	node:setValue(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
-- ����
function ShapeBuilder.trapezoid(op,top_w,bottom_w,hight,depth,color) 
	local xmin,ymin,zmin = 0,0,0;
	local w = (bottom_w - top_w)/2;
	local x2min = w;
	local z2min = 0;
	local xmax = bottom_w;
	local ymax = hight;
	local zmax = depth;
	local x2max = x2min + top_w;
	local z2max = depth;

	local node = NplOce.ShapeNodeWedge.create();
	node:setValue(xmin,ymin,zmin,x2min,z2min,xmax,ymax,zmax,x2max,z2max);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.wedge(op,x, z, h, color) 
	local x1 = 0;
	local z1 = 0;

	local x2 = x;
	local z2 = z;

	local y1 = 0;
	local y2 = h;

	local x3 = 0;
	local z3 = 0;

	local x4 = x;
	local z4 = 0;


	local node = NplOce.ShapeNodeWedge.create();
	node:setValue(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
-- Create a wedge
-- @param {number} [x1 = 0]
-- @param {number} [y1 = 0]
-- @param {number} [z1 = 0]
-- @param {number} [x3 = 2]
-- @param {number} [z3 = 2]
-- @param {number} [x2 = 10]
-- @param {number} [y2 = 10]
-- @param {number} [z2 = 10]
-- @param {number} [x4 = 8]
-- @param {number} [z4 = 8]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._wedge(op,x1, y1, z1, x3, z3, x2, y2, z2, x4, z4,color) 
	local node = NplOce.ShapeNodeWedge.create();
	node:setValue(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

-- Create an ellipsoid
-- @param {number} [y = 2]
-- @param {number} [x = 4]
-- @param {number} [z = 0]
-- @param {number} [a1 = -90]
-- @param {number} [a2 = 90]
-- @param {number} [a3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._ellipsoid(op,y, x, z, a1, a2, a3,color) 
	local node = NplOce.ShapeNodeEllipsoid.create();
	node:setValue(y, x, z, a1, a2, a3);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end
function ShapeBuilder.ellipsoid(op,r_x, r_z, r_y, color) 
	ShapeBuilder._ellipsoid(op,r_y, r_x, r_z, -90, 90, 360,color) 
end

function ShapeBuilder.createFromBrep_test(op,color) 
	local brep = SceneHelper.readFile("Mod/NplCad2/BrepShapes/sphere.brep",true);
	return ShapeBuilder.createFromBrep(op,brep,color)
end
function ShapeBuilder.createFromBrep(op,brep,color) 
	if(not brep)then
		return
	end
	local node = NplOce.ShapeNodeBrep.create();
	node:setValue(brep);
	ShapeBuilder.addShapeNode(node,op,color) 
	return node;
end

function ShapeBuilder.line(op, x1, y1, z1, x2, y2, z2, color)
	local node = NplOce.ShapeNodeLine.create();
	node:setValue(x1, y1, z1, x2, y2, z2);
	ShapeBuilder.addShapeNode(node, op, color);
	return node;
end

function ShapeBuilder.plane(op, length, width, color)
	local node = NplOce.ShapeNodePlane.create();
	node:setValue(length, width);
	ShapeBuilder.addShapeNode(node, op, color);
	return node;
end

function ShapeBuilder.circle(op, radius, a0, a1, color)
	local node = NplOce.ShapeNodeCircle.create();
	node:setValue(radius, a0, a1);
	ShapeBuilder.addShapeNode(node, op, color);
	return node;
end

function ShapeBuilder.ellipse(op, radius1, radius2, a0, a1, color)
	local node = NplOce.ShapeNodeEllipse.create();
	node:setValue(radius1, radius2, a0, a1);
	ShapeBuilder.addShapeNode(node, op, color);
	return node;
end

function ShapeBuilder.regularPolygon(op, p, r, color)
	local node = NplOce.ShapeNodeRegularPolygon.create();
	node:setValue(p, r);
	ShapeBuilder.addShapeNode(node, op, color);
	return node;
end

function ShapeBuilder.polygon(op, p, color)
	if(not p or type(p) ~= "table")then
		p = {0,0,0, 1,0,0, 1,1,0};
	end
	local node = NplOce.ShapeNodePolygon.create();
	node:setValue(p);
	ShapeBuilder.addShapeNode(node, op, color);
	return node;
end

-- Create text
-- @param {string} text
-- @param {string} font
-- @param {number} size
-- @param {number} height
-- @param {string} color
-- @return {NplOce.ShapeNodeText} node
function ShapeBuilder.text3d(op, text, font, size, height, color) 
	local node = NplOce.ShapeNodeText.create();
	if (type(font) == "string") then
		local font_path = Files.GetFilePath(font);
		if (not font_path) then
			local font_files = {
				SIMHEI = "C:/WINDOWS/FONTS/simhei.ttf",
				MSYH = "C:/WINDOWS/FONTS/MSYH.TTC",
				SIMSUN = "C:/WINDOWS/FONTS/SIMSUN.TTC",
				SIMFANG = "C:/WINDOWS/FONTS/SIMFANG.TTF",
				SIMKAI = "C:/WINDOWS/FONTS/SIMKAI.TTF"};
			font_path = font_files[font];
		end
		if (font_path) then
			node:setValue(text, font_path, size, height);
			ShapeBuilder.addShapeNode(node,op,color) 
		end
	end
	return node;
end
--[[

--]]
-- Create text with fontMemory
-- @param {string} text
-- @param {number} size
-- @param {number} height
-- @param {string} color
-- @param {string} fontBufferBase64: base64 string for font
-- @param {number} fontBufferSize： the size of fontBuffer which is unbase64
-- @return {NplOce.ShapeNodeTextMemory} node
function ShapeBuilder.text3dMemory(op, text, size, height, color, fontBufferBase64, fontBufferSize)
	local node = NplOce.ShapeNodeTextMemory.create();
	if (fontBufferBase64 and type(fontBufferBase64) == "string" and fontBufferSize > 0) then
		node:setValue(text, size, height, fontBufferBase64, fontBufferSize, true);
		ShapeBuilder.addShapeNode(node, op, color);
	end
	return node;
end
--[[
text3dMemory_test("union", "Paracraft", 1, 1, "#ff0000", "SIMHEI");
--]]
function ShapeBuilder.text3dMemory_test(op, text, size, height, color, font) 
	local font_path = Files.GetFilePath(font);
	if (not font_path) then
		local font_files = {
			SIMHEI = "C:/WINDOWS/FONTS/simhei.ttf",
			MSYH = "C:/WINDOWS/FONTS/MSYH.TTC",
			SIMSUN = "C:/WINDOWS/FONTS/SIMSUN.TTC",
			SIMFANG = "C:/WINDOWS/FONTS/SIMFANG.TTF",
			SIMKAI = "C:/WINDOWS/FONTS/SIMKAI.TTF"};
		font_path = font_files[font];

		
	end
	local file = ParaIO.open(font_path, "r");
	if(file:IsValid()) then
		local fontBuffer = file:GetText(0, -1)
		file:close();
		local fontBufferSize = #fontBuffer;
		local fontBufferBase64 = Encoding.base64(fontBuffer);
		ShapeBuilder.text3dMemory(op, text, size, height, color, fontBufferBase64, fontBufferSize);
	end
end
-- Convert from color string to rgba table, if the type of color is table return color directly
-- NOTE: the color isn't supported alpha  in nploce 
-- @param {string} color - can be "#ffffff" or "#ffffffff" with alpha
-- @return {object} color
-- @return {number} color[1] - [0-1]
-- @return {number} color[2] - [0-1]
-- @return {number} color[3] - [0-1]
-- @return {number} color[4] - [0-1]
function ShapeBuilder.converColorToRGBA(color) 
	local default_color = ShapeBuilder.default_color;
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

-- Sets the translation node to the specified values
-- @param {NplOce.Node} node
-- @param {number} [x = 0]
-- @param {number} [y = 0]
-- @param {number} [z = 0]
function ShapeBuilder.setTranslation(node,x,y,z) 
	if(node)then
		node:setTranslation(x,y,z);
	end
end

-- Translates this node's translation by the given values along each axis
-- @param {number} [tx = 0]
-- @param {number} [ty = 0]
-- @param {number} [tz = 0]
function ShapeBuilder.translate(node,tx,ty,tz)
	if(node)then
		node:translate(tx,ty,tz);
		--[[
		-- for text shape node, all letters are sibling
		local next = node:getNextSibling();
		while (next) do
			next:translate(tx, ty, tz);
			next = next:getNextSibling();
		end
		]]
	end
end

-- TODO
-- Scale the node
-- @param {NplOce.Node} node
-- @param {number} [x = 1]
-- @param {number} [y = 1]
-- @param {number} [z = 1]
function ShapeBuilder.setScale(node,x,y,z)
	if(node)then
		node:setScale(x,y,z);
		--[[
		-- for text shape node, all letters are sibling
		local next = node:getNextSibling();
		while (next) do
			next:setScale(x,y,z);
			next = next:getNextSibling();
		end
		]]
	end
end

 -- parse json string to lua object 
function ShapeBuilder.jsonToObj(json_str)
	if(not json_str)then
		return
	end
	commonlib.echo(json_str)
	local out = {};
	if(NPL.FromJson(json_str, out)) then
		return out;
	end
end
 -- parse lua object to json string 
function ShapeBuilder.objToJson(obj)
	if(not obj)then
		return
	end
	return NPL.ToJson(obj, true)
end

function ShapeBuilder.isEmpty(s)
	if(s == nil or s == "")then
		return true;
	end
	return false;
end
function ShapeBuilder.getBoolean(v)
	if(ShapeBuilder.isEmpty(v))then
		return false
	end
	if(type(v) == "string")then
		if(string.lower(v) == "false")then
			return false;
		else    
			return true;
		end
	end
	return v;
end
-- limit triangle number for exporting model
function ShapeBuilder.setMaxTrianglesCnt(v)
	if(v < 0)then
		v = 0;
	end
	ShapeBuilder.scene.max_triangle_cnt = v;
end
 
function ShapeBuilder.getEdgeCount()
	local node = ShapeBuilder.getSelectedNode();
	if (node ~= nil and node:getDrawable() ~= nil) then
		local shape = node:getDrawable():getShape();
		if (shape ~= nil) then
			return shape:getEdgeCount();
		end
	end
	return 0;
end

function ShapeBuilder.deflection(liner, angular)
	ShapeBuilder.liner = math.max(liner, 0.001);
	ShapeBuilder.liner = math.min(ShapeBuilder.liner, 10);
	ShapeBuilder.angular = math.max(angular, 1.0);
	ShapeBuilder.angular = math.min(ShapeBuilder.angular, 180);
end

--[[
test codes

local len = 3;
-- draw points
geom_point(len,len,0,"#ff0000",true)

-- draw lines
geom_lineSegment(0,0,0,len,0,0,"#ff0000",true);
geom_lineSegment(0,0,0,0,len,0,"#00ff00",true);
geom_lineSegment(0,0,0,0,0,len,"#0000ff",true);
sphere("union",0.1,"#ffc658")

geom_arcOfCircle( 0, 0, 0, 2, 0, 3.14, false, "#ff0000", true);
geom_circle( 0, 0, 0, 2, "#ff0000", true);
geom_arcOfEllipse( 0, 0, 0, 3, 1, 0, 3.14, false, "#ff0000", true);
geom_ellipse( 0, 0, 0, 3, 1, "#ff0000", true);
geom_arcOfHyperbola( 0, 0, 0, 3, 1, 0, 1.57, false, "#ff0000", true);
geom_arcOfParabola( 0, 0, 0, 0.5, -1.57, 1.57, false, "#ff0000", true);

-- draw rectangle
local w = 3;
local h = 1;
geom_lineSegment(0,0,0,w,0,0,"#ff0000",true);
geom_lineSegment(w,0,0,w,0,h,"#ff0000",true);
geom_lineSegment(w,0,h,0,0,h,"#ff0000",true);
geom_lineSegment(0,0,h,0,0,0,"#ff0000",true);

-- extrude rectangle
createSketch()
    local w = 3;
    local h = 1;
    geom_lineSegment(0,0,0,w,0,0,"#ff0000");
    geom_lineSegment(w,0,0,w,0,h,"#ff0000");
    geom_lineSegment(w,0,h,0,0,h,"#ff0000");
    geom_lineSegment(0,0,h,0,0,0,"#ff0000");
endSketch()
sketch_extrude("union",1);
move(0,1,0)





geom_circle( 0, 0, 0, 1, "#ff0000", true);
createSketch()
    geom_circle( 0, 0, 0, 1, "#ff0000");
endSketch()
sketch_extrude("union", 1);

geom_circle( 0, 0, 0, 1, "#ff0000", true);
createSketch()
    geom_circle( 0, 0, 0, 1, "#ff0000");
    geom_circle( 0, 0, 0, 2, "#ff0000");
    geom_circle( 1, 0, 1, 0.3, "#ff0000");
    geom_ellipse( 1.5, 0, 0, 1, 0.3, "#ff0000");
endSketch()
sketch_extrude("union", 1);


geom_arcOfCircle( 0, 0, 0, 2, 0, 3.14, true, "#ff0000", true);
createSketch()
    geom_arcOfCircle( 0, 0, 0, 2, 0, 3.14, true, "#ff0000");
endSketch()
sketch_extrude_wire("union",2,"#ff0000",0,1,0,false);

-- test direction
cube("union", 1,"#ffc658")
move(3,0,0)
cube("union",1,"#ff0000")
move(0,3,0)
cube("union",1,"#00ff00")
move(0,0,3)

geom_circle( 0, 0, 0, 1, "#ffff00", true);

createSketch()
    geom_circle( 0, 0, 0, 1, "#ff0000");
endSketch()
sketch_extrude("union",1);
move(0,0.5,0)


createSketch("", "xz")
    geom_circle(3, 0, 0, 1, "#ff0000");
endSketch()
sketch_revolve("union", 180, "z");

createSketch("", "xz")
    geom_svg_string("", 1, "#ff0000");
endSketch()
sketch_revolve("union", 180, "z");

--]]

function ShapeBuilder.createSketch(name, plane)
    local name = name or ShapeBuilder.generateId();
    plane = plane or "xz";
	local node = NplOce.SketchNode.create(name);
	node:setOpEnabled(false);
    node:setPlaneString(plane)
	local parent = ShapeBuilder.getCurNode();
	parent:addChild(node)
	ShapeBuilder.cur_node = node;
	ShapeBuilder.selected_node = node;

	table.insert(ShapeBuilder.scene.pushed_sketch_node_list,node);

	return node
end
function ShapeBuilder.endSketch()
    local len = #ShapeBuilder.scene.pushed_sketch_node_list;
	local node = ShapeBuilder.scene.pushed_sketch_node_list[len];
	local parent = node:getParent() or ShapeBuilder.getRootNode();

	table.remove(ShapeBuilder.scene.pushed_sketch_node_list,len);
	ShapeBuilder.cur_node = parent;
	ShapeBuilder.selected_node = node;
	
end

function ShapeBuilder.geom_point(x, y, z, color, bAttach)
    local node = NplOce.GeomPointNode.create();
	node:setValue(x, y, z);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_lineSegment(start_x, start_y, start_z, end_x, end_y, end_z, color, bAttach)
    local node = NplOce.GeomLineSegmentNode.create();
    plane = plane or ShapeBuilder.get_sketch_plane();
	node:setValue(start_x, start_y, start_z, end_x, end_y, end_z, plane);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_arcOfCircle(x, y, z, r, u, v, emulateCCWXY, color, bAttach, dir)
    local node = NplOce.GeomArcOfCircleNode.create();
	dir = dir or "";
	node:setValue(x, y, z, r, u, v, emulateCCWXY, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_circle(x, y, z, r, color, bAttach, dir)
    local node = NplOce.GeomCircleNode.create();
	dir = dir or "";
	node:setValue(x, y, z, r, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_arcOfEllipse(x, y, z, major_r, minor_r, u, v, emulateCCWXY, color, bAttach, dir)
    local node = NplOce.GeomArcOfEllipseNode.create();
	dir = dir or "";
	node:setValue(x, y, z, major_r, minor_r, u, v, emulateCCWXY, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_ellipse(x, y, z, major_r, minor_r, color, bAttach, dir)
    local node = NplOce.GeomEllipseNode.create();
	dir = dir or "";
	node:setValue(x, y, z, major_r, minor_r, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_arcOfHyperbola(x, y, z, major_r, minor_r, u, v, emulateCCWXY, color, bAttach, dir)
    local node = NplOce.GeomArcOfHyperbolaNode.create();
	dir = dir or "";
	node:setValue(x, y, z, major_r, minor_r, u, v, emulateCCWXY, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end
function ShapeBuilder.geom_arcOfParabola(x, y, z, focal, u, v, emulateCCWXY, color, bAttach, dir)
    local node = NplOce.GeomArcOfParabolaNode.create();
	dir = dir or "";
	node:setValue(x, y, z, focal, u, v, emulateCCWXY, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end

--[[
local poles = {
    { 0, 0, 0 },
    { 0, 0, 3 },
    { 2, 0, 3 },
    { 2, 0, 0 },
}
geom_bezier( poles, "#ff0000", true);
--]]

function ShapeBuilder.geom_bezier(poles, color, bAttach, dir)
    local node = NplOce.GeomBezierCurveNode.create();
    local weights = {};

	node:setValue(poles, weights, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;

end
--[[
local poles = {
        { 0, 0, 0 },
        { 1.1, 0, 3 },
        { 2.1, 0, 0 },
        { 3.1, 0, 3 },
        { 4.1, 0, 0 },
        { 5.1, 0, 5 },
    }
local degree = 3;
geom_bspline( poles, degree, "#ff0000", true);
--]]
function ShapeBuilder.geom_bspline(poles, degree, color, bAttach, dir)
    local node = NplOce.GeomBSplineCurveNode.create();
    degree = degree or 3;
    
    local number_of_poles = #poles;

    local number_of_knots;
    if (number_of_poles <= degree) then
        degree = number_of_poles-1;
    end
    number_of_knots = number_of_poles - degree + 1;

    local weights = {};
    local multiplicities = {};
    local knots = {};
    for k = 1, number_of_poles do
        table.insert(weights, 1);
    end
    for k = 1, number_of_knots do
        table.insert(multiplicities, 1);
        table.insert(knots, (k - 1) / (number_of_knots - 1));
    end
    local periodic = false;
    local checkrational = true;
    local len_multi = #multiplicities;
    if(not periodic and len_multi > 0)then
        multiplicities[1] = degree + 1;
        multiplicities[len_multi] = degree + 1;
    end
	node:setValue(poles, weights, knots, multiplicities, degree, periodic, checkrational, dir);
    if(bAttach)then
        node:attachGeometry();
    end
	ShapeBuilder.addShapeNode(node, nil, color);
	return node;
end

--[[
geom_regularPolygon(3, 0, 0, 2, "#ff0000", true);

createSketch("","xy")
    geom_regularPolygon( 3, 0, 0, 2, "#ff0000");
endSketch()
sketch_extrude("union",1);
]]
function ShapeBuilder.geom_regularPolygon(sides, center_h, center_v, radius, color, bAttach, plane)
    plane = plane or ShapeBuilder.get_sketch_plane();
    local pointList = SceneHelper.createRegularPolygonPointsInPlane(plane, sides, center_h, center_v, radius)
    for k,v in ipairs(pointList) do
        local from_pos = v.from_pos;
        local to_pos = v.to_pos;
        if(from_pos and to_pos)then
            local node = NplOce.GeomLineSegmentNode.create();
	        node:setValue(from_pos.x, from_pos.y, from_pos.z, to_pos.x, to_pos.y, to_pos.z, plane);
            if(bAttach)then
                node:attachGeometry();
            end  
	        ShapeBuilder.addShapeNode(node, nil, color);
        end
    end
end

-- revolve shapes in sketch
-- @param op : "union" ...
-- @param angle: rotation in degree
-- @param {string} axis: "x" or "y" or "z"
-- @param color: hex string "#ff0000"
-- @param {boolean} bSolid: true to revolve by faces, false to reolve by wires 
function ShapeBuilder.sketch_revolve(op, angle, axis, color, bSolid)
    ShapeBuilder.sketch_revolve_internal(op, angle, axis, color, bSolid)
end

-- internal function for revolve
-- @param op: "union" ...
-- @param angle: rotation in degree
-- @param {string} axis: "x" or "y" or "z"
-- @param color: hex string "#ff0000"
-- @param {boolean} bSolid: true to revolve by faces, false to reolve by wires 
function ShapeBuilder.sketch_revolve_internal(op, angle, axis, color, bSolid)
    local axis_x, axis_y, axis_z = 0, 0, 0;
    local dir_x, dir_y, dir_z = 0, 0, 0;

	if(axis == "x")then
		dir_x = 1;
	elseif(axis == "y")then
		dir_y = 1;
	elseif(axis == "z")then
		dir_z = 1;
	else
		-- invalid param, axis
		return;
	end
    -- this is a sketch node
	local node = ShapeBuilder.getSelectedNode();
	if (node and node.toShape and node.getTypeName) then
        local type_name = node:getTypeName();
        if(type_name == "Sketch")then
            local parent = node:getParent();
            local shape = node:toShape();
		    if (shape ~= nil) then
                local revolve_shape = NplOce.revolveShape(shape, angle, axis_x, axis_y, axis_z, dir_x, dir_y, dir_z, bSolid);
				if (not revolve_shape:IsNull()) then
					local model = NplOce.ShapeModel.create(revolve_shape);
                    local revolve_node = NplOce.ShapeNode.create();
		            revolve_node:setDrawable(model);
                    parent:addChild(revolve_node);

	                revolve_node:setOpEnabled(true);
                    revolve_node:setOp(op);
                    revolve_node:setColor(ShapeBuilder.converColorToRGBA(color));

	                ShapeBuilder.selected_node = revolve_node;


                    -- remove sketch node
                    local parent = node:getParent();
		            parent:removeChild(node);
				end
		    end
        end
        
	end
end
--[[
createSketch("svg","xz")
    geom_svg_string('<svg xmlns="http://www.w3.org/2000/svg" width="50.116001498495805" height="317.2835372767141" viewBox="-30 -22.28353727671411 50.116001498495805 317.2835372767141" ><path d="M-30,295z" fill="none" stroke="#000000"  stroke-width="1" /><path d="M0,-12.5916284468c8.2937303789,-23.7934887919 40.788837929,0 0,30.5916284468c-40.788837929,-30.5916284468 -8.2937303789,-54.3851172387 0,-30.5916284468z" fill="none" stroke="#000000"  stroke-width="1" /></svg>', 1, '#FFC658FF', -1)
endSketch()
sketch_extrude("union", 1, nil, "#FFC658FF", true)

createSketch("svg","xy")
    geom_svg_string('<svg xmlns="http://www.w3.org/2000/svg" width="50.116001498495805" height="317.2835372767141" viewBox="-30 -22.28353727671411 50.116001498495805 317.2835372767141" ><path d="M-30,295z" fill="none" stroke="#000000"  stroke-width="1" /><path d="M0,-12.5916284468c8.2937303789,-23.7934887919 40.788837929,0 0,30.5916284468c-40.788837929,-30.5916284468 -8.2937303789,-54.3851172387 0,-30.5916284468z" fill="none" stroke="#000000"  stroke-width="1" /></svg>', 1, '#FFC658FF', -1)
endSketch()
sketch_extrude("union", 1, "z", "#FFC658FF", true)

--]]
-- extrude shapes in sketch
-- @param op : "union" ...
-- @param length: value to extrude
-- @param {string}  color: hex string "#ff0000"
-- @param {string}  direction: nil to auto check by sketch plane normal, 
-- @param {boolean} bSolid: true to extrude by faces, false to extrude by wires 
function ShapeBuilder.sketch_extrude(op, length, direction, color, bSolid)
	local bAutoCheckDir = false;
	local dir_x, dir_y, dir_z = 0, 1, 0;
	if(not direction)then
		bAutoCheckDir = true;
	else
		if(direction == "x")then
			dir_x = 1;
			dir_y = 0;
			dir_z = 0;
		elseif(direction == "y")then
			dir_x = 0;
			dir_y = 1;
			dir_z = 0;
		elseif(direction == "z")then
			dir_x = 0;
			dir_y = 0;
			dir_z = 1;
		end
	end
    ShapeBuilder.sketch_extrude_internal(op, length, color, bAutoCheckDir, dir_x, dir_y, dir_z, bSolid)
end

-- extrude shapes in sketch
-- @param op : "union" ...
-- @param length: value to extrude 
-- @param color: hex string "#ff0000"
-- @param {boolean} bAutoCheckDir: true to find direction by sketch plane normal
-- @param {number} dir_x: 1 is on x direction, valid if bAutoCheckDir is true
-- @param {number} dir_y: 1 is on y direction, valid if bAutoCheckDir is true
-- @param {number} dir_z: 1 is on z direction, valid if bAutoCheckDir is true
-- @param {boolean} bSolid: true to extrude by faces, false to extrude by wires 
function ShapeBuilder.sketch_extrude_internal(op, length, color, bAutoCheckDir, dir_x, dir_y, dir_z, bSolid)
    -- this is a sketch node
	local node = ShapeBuilder.getSelectedNode();
	if (node and node.toShape and node.getTypeName) then
        local type_name = node:getTypeName();
        if(type_name == "Sketch")then
            local parent = node:getParent();
            local shape = node:toShape();
		    if (shape ~= nil) then
			    local extrude_shape = NplOce.extrudeShape(shape, length, bAutoCheckDir, dir_x, dir_y, dir_z, bSolid);
			    if (not extrude_shape:IsNull()) then
                        local model = NplOce.ShapeModel.create(extrude_shape);
                        local extrude_node = NplOce.ShapeNode.create();
		                extrude_node:setDrawable(model);
                        parent:addChild(extrude_node);

	                    extrude_node:setOpEnabled(true);
                        extrude_node:setOp(op);
                        extrude_node:setColor(ShapeBuilder.converColorToRGBA(color));

	                    ShapeBuilder.selected_node = extrude_node;


                        -- remove sketch node
                        local parent = node:getParent();
		                parent:removeChild(node);

			    end
		    end
        end
        
	end
end
function ShapeBuilder.get_sketch_plane()
    local cur_node = ShapeBuilder.cur_node;
    if(cur_node and cur_node.getPlaneString)then
        return cur_node:getPlaneString();
    end
    return "xz";
end
--[[
geom_svg_file( "Mod/NplCad2/Svg/SvgLibs/heart.svg.xml", 0.1, "#ff0000", true)

createSketch("","xz")
    geom_svg_file( "Mod/NplCad2/Svg/SvgLibs/heart.svg.xml", 0.1, "#ff0000")
endSketch()
sketch_extrude("union", 1, "#ffff00");

createSketch("","xz")
    geom_svg_file( "Mod/NplCad2/Svg/SvgLibs/diamond.svg.xml", 0.1, "#ff0000")
endSketch()
sketch_extrude("union", 1);
--]]
function ShapeBuilder.geom_svg_file(filename, scale, color, bAttach, plane)
    plane = plane or ShapeBuilder.get_sketch_plane();
    scale = scale or 1;
    local svg_parser = SvgParser:new();
    svg_parser:ParseFile(filename);
    local result = svg_parser:GetResult();
    ShapeBuilder.run_svg_codes(result, scale, color, bAttach, plane);
end

--[[
-- show wires
geom_svg_string('<svg  xmlns="http://www.w3.org/2000/svg" width="50.116001498495805" height="317.2835372767141" viewBox="-30 -22.28353727671411 50.116001498495805 317.2835372767141" ><path d="M-30,295z" fill="none" stroke="#000000"  stroke-width="1" /><path d="M0,-12.5916284468c8.2937303789,-23.7934887919 40.788837929,0 0,30.5916284468c-40.788837929,-30.5916284468 -8.2937303789,-54.3851172387 0,-30.5916284468z" fill="none" stroke="#000000"  stroke-width="1" /></svg>', 1, '#FFC658FF', -1, true)
--]]

--[[
-- extrude svg as faces
createSketch("svg","xz")
    geom_svg_string('<svg xmlns="http://www.w3.org/2000/svg" width="50.116001498495805" height="317.2835372767141" viewBox="-30 -22.28353727671411 50.116001498495805 317.2835372767141" ><path d="M-30,295z" fill="none" stroke="#000000"  stroke-width="1" /><path d="M0,-12.5916284468c8.2937303789,-23.7934887919 40.788837929,0 0,30.5916284468c-40.788837929,-30.5916284468 -8.2937303789,-54.3851172387 0,-30.5916284468z" fill="none" stroke="#000000"  stroke-width="1" /></svg>', 1, '#FFC658FF', -1)
endSketch()
sketch_extrude("union", 1, "#FFC658FF", true)
--]]
-- create wires by svg string
-- @param {string} str: svg string like "<svg><path d='' /><path d='' /></svg>"
-- @param {number} scale: scaling unit, default vlaue is 1
-- @param {string} color: 
-- @param {number} hInvert: invert h value
-- @param {boolean} bAttach: true to be attached by ShapeNode, false to be invoked by sketch
-- @param {string} plane: "xy" or "xz" or "yz"
function ShapeBuilder.geom_svg_string(str, scale, color, hInvert, bAttach, plane)
    plane = plane or ShapeBuilder.get_sketch_plane();
    scale = scale or 1;
    local svg_parser = SvgParser:new()
    svg_parser:ParseString(str);
    local result = svg_parser:GetResult();
    --commonlib.echo(svg_parser:Dump());
    ShapeBuilder.run_svg_codes(result, scale, color, hInvert, bAttach, plane);
end
function ShapeBuilder.run_svg_codes(result, scale, color, hInvert, bAttach, plane)
    if(result)then
		hInvert = hInvert or 1;
        for k,v in ipairs(result) do
            local type = v.type;
            local out_data = v.out_data;
            if(type == "line")then
				local input_from_x = out_data.from_x * scale;
				local input_from_y = out_data.from_y * scale * hInvert;

				local input_to_x = out_data.to_x * scale;
				local input_to_y = out_data.to_y * scale * hInvert;

                local from_x,from_y,from_z = SceneHelper.getPosition_HVInPlane(plane, input_from_x, input_from_y);
                local to_x,to_y,to_z = SceneHelper.getPosition_HVInPlane(plane, input_to_x, input_to_y);

                local bEqual = ShapeBuilder.is_equal_pos(from_x, from_y, from_z, to_x, to_y, to_z);
                if(not bEqual)then
                    ShapeBuilder.geom_lineSegment(
                        from_x,
                        from_y,
                        from_z,

                        to_x,
                        to_y,
                        to_z,
                        color, bAttach, plane);
                else
                    commonlib.echo("===================found equal position to line");
                    commonlib.echo(k);
                    commonlib.echo(v);
                    commonlib.echo({from_x, from_y, from_z, to_x, to_y, to_z});
                end
            elseif(type == "bezier_curve")then
                local poles = out_data;
                local result = {};
                for __,pole in ipairs(poles) do
					local input_x = pole[1] * scale;
					local input_y = pole[2] * scale * hInvert;

                    local x, y, z = SceneHelper.getPosition_HVInPlane(plane, input_x, input_y);
                    table.insert(result,{x, y , z});
                end
                ShapeBuilder.geom_bezier(result, color, bAttach, plane);
            end
        end
    end
end
function ShapeBuilder.is_equal_with_precision(a,b)
    if(type(a) == "number" and type(b) == "number" )then
        local diff = math.abs(a - b);
        if(diff < ShapeBuilder.Precision_Confusion)then
            return true
        end
	end
end
function ShapeBuilder.is_equal_pos(start_x, start_y, start_z, end_x, end_y, end_z)
    if( ShapeBuilder.is_equal_with_precision(start_x, end_x) and 
        ShapeBuilder.is_equal_with_precision(start_y, end_y) and
        ShapeBuilder.is_equal_with_precision(start_z, end_z) 
    )then
        return true;
    end
end
function ShapeBuilder.checkPrecision(v, defaultValue) 
	if(type(v) == "number")then
		if(v < ShapeBuilder.Precision_Confusion)then
			return defaultValue or 1;
		end
	end
	return v;
end

--[[
createSketch("svg","xz")
    geom_svg_string('<svg xmlns="http://www.w3.org/2000/svg" width="50.116001498495805" height="317.2835372767141" viewBox="-30 -22.28353727671411 50.116001498495805 317.2835372767141" ><path d="M-30,295z" fill="none" stroke="#000000"  stroke-width="1" /><path d="M0,-12.5916284468c8.2937303789,-23.7934887919 40.788837929,0 0,30.5916284468c-40.788837929,-30.5916284468 -8.2937303789,-54.3851172387 0,-30.5916284468z" fill="none" stroke="#000000"  stroke-width="1" /></svg>', 1, '#FFC658FF', -1)
endSketch()
local profileSketch = getSelectedNode();

createSketch("svg","xz")
    geom_svg_string('<svg xmlns="http://www.w3.org/2000/svg" width="50.116001498495805" height="317.2835372767141" viewBox="-30 -22.28353727671411 50.116001498495805 317.2835372767141" ><path d="M-30,295z" fill="none" stroke="#000000"  stroke-width="1" /><path d="M0,-12.5916284468c8.2937303789,-23.7934887919 40.788837929,0 0,30.5916284468c-40.788837929,-30.5916284468 -8.2937303789,-54.3851172387 0,-30.5916284468z" fill="none" stroke="#000000"  stroke-width="1" /></svg>', 1, '#FFC658FF', -1)
endSketch()
local pathSketch = getSelectedNode();

sketch_sweep("union", "#ff0000", profileSketch, pathSketch)
--]]
function ShapeBuilder.sketch_sweep(op, color, profileSketch, pathSketch, tol, fillMode)
	commonlib.echo("=====================sweep 1");
	if(not profileSketch or not pathSketch)then
		return
	end
	commonlib.echo("=====================sweep 2");
	ShapeBuilder.sweep(op, color, profileSketch:toShape(), pathSketch:toShape(), tol, fillMode);
end
function ShapeBuilder.sweep(op, color, profileShape, pathShape, tol, fillMode)
	if(not profileShape or not pathShape)then
		return
	end
	commonlib.echo("=====================sweep 3");
	tol = tol or 0.01;
	if(fillMode == nil or fillMode == false)then
		fillMode = 0;
	end
	local sweep_shape = NplOce.sweepShape(profileShape, pathShape, tol, fillMode);

	local node = NplOce.ShapeNode.create();
	local model = NplOce.ShapeModel.create();
	model:setShape(sweep_shape);
	node:setDrawable(model);
	ShapeBuilder.addShapeNode(node, op, color);
end

NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.PartDesign.lua");
