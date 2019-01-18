--[[
Title: NplOce_Internal
Author(s): leio
Date: 2018/11/7
Desc: append functions to global object of NplOce, load this file after activated nploce.dll
use the lib:
------------------------------------------------------------
NPL.load("Mod/NplCad2/NplOce_Internal.lua");
------------------------------------------------------------
--]]
local NplOce = NplOce;
-- Export the scene to json string
-- @param {NplOce.Scene} scene
-- @return {string} s
function NplOce.export(scene)
	NplOce.export_scene_value = nil;
	if(scene and scene.toJson)then
		local s = scene:toJson();
		NplOce.export_scene_value = s;
		return s;
	end
end

-- Export the shape to json string with specified position and color
-- @param {NPL_TopoDS_Shape} shape
-- @param {table} [position = {0,0,0}]
-- @param {table} [color = {1,0,0,1}]
-- @return {string} s
function NplOce.exportSingleShape(shape,position,color)
	if(not shape)then
		return
	end
	color = color or {1,0,0,1};
	position = position or {0,0,0};
	local mesh = NplOce.Mesh.create(shape,color[1],color[2],color[3],color[4]);
	local model = NplOce.Model.create(mesh);
	local scene = NplOce.Scene.create();
	local node = scene:addNode(filename);
	node:setTranslation(position[1],position[2],position[3])
	node:setDrawable(model);
	return NplOce.export(scene)
end

function NplOce.exportToParaX(scene, isYUp)
	if (scene == nil) then
		return false;
	end

	local function WriteTemplate()
		local templateName = "Mod/NplCad2/template.txt";
		if(ParaIO.DoesFileExist(templateName, true)) then
			local template_file = ParaIO.open(templateName, "r");
			if(template_file:IsValid()) then
				local template_data = template_file:GetText(0, -1);
				template_file:close();
				return template_data
			end
		end
	end

	local template = WriteTemplate();
	local data = scene:toParaX(isYUp);
	if (template ~= nil and data ~= nil) then
		local Encoding = commonlib.gettable("System.Encoding");
		data = Encoding.unbase64(data);
		local res = template..data;
		return res;
	end
end

-- Set operator on this node
-- this is an external method for NplOce.Node
-- @param {string} op - "union" or "difference" or "intersection"
function NplOce.Node:_setOp(op)
    self._op = op;
end
function NplOce.Node:_getOp()
    return self._op;
end
-- for storing temporary node parameter during scene traversal.
function NplOce.Node:_pushActionParam(param)
	self.action_params_ = self.action_params_ or {};
	table.insert(self.action_params_, param);
end

-- return all action params as array or nil, and clear them all.
function NplOce.Node:_popAllActionParams()
	local params = self.action_params_;
	self.action_params_ = nil;
	return params;
end
-- Set color on this node
-- this is an external method for NplOce.Node
-- @param {object} color
-- @param {number} color.r - range[0,1]
-- @param {number} color.g - range[0,1]
-- @param {number} color.b - range[0,1]
-- @param {number} color.a - range[0,1]
function NplOce.Node:_setColor(color)
    self._color = color;
end
function NplOce.Node:_getColor()
    return self._color;
end