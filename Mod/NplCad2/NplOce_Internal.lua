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


NplOce.Transform_Enum = {
    ANIMATE_SCALE_UNIT = 0,
    ANIMATE_SCALE = 1,
    ANIMATE_SCALE_X = 2,
    ANIMATE_SCALE_Y = 3,
    ANIMATE_SCALE_Z = 4,
    ANIMATE_ROTATE = 8,
    ANIMATE_TRANSLATE = 9,
    ANIMATE_TRANSLATE_X = 10,
    ANIMATE_TRANSLATE_Y = 11,
    ANIMATE_TRANSLATE_Z = 12,
    ANIMATE_ROTATE_TRANSLATE = 16,
    ANIMATE_SCALE_ROTATE_TRANSLATE = 17,
    ANIMATE_SCALE_TRANSLATE = 18,
    ANIMATE_SCALE_ROTATE = 19,

}
local curve_value = -1;
local function get_next_value()
    curve_value = curve_value + 1;
    return curve_value;
end
        
NplOce.Curve_Enum = {
        BEZIER = get_next_value(),
        BSPLINE = get_next_value(),
        FLAT = get_next_value(),
        HERMITE = get_next_value(),
        LINEAR = get_next_value(), -- 4
        SMOOTH = get_next_value(),
        STEP = get_next_value(), -- 6
        QUADRATIC_IN = get_next_value(),
        QUADRATIC_OUT = get_next_value(),
        QUADRATIC_IN_OUT = get_next_value(),
        QUADRATIC_OUT_IN = get_next_value(),
        CUBIC_IN = get_next_value(),
        CUBIC_OUT = get_next_value(),
        CUBIC_IN_OUT = get_next_value(), -- 13
        CUBIC_OUT_IN = get_next_value(),
        QUARTIC_IN = get_next_value(),
        QUARTIC_OUT = get_next_value(),
        QUARTIC_IN_OUT = get_next_value(),
        QUARTIC_OUT_IN = get_next_value(),
        QUINTIC_IN = get_next_value(),
        QUINTIC_OUT = get_next_value(),
        QUINTIC_IN_OUT = get_next_value(),
        QUINTIC_OUT_IN = get_next_value(),
        SINE_IN = get_next_value(),
        SINE_OUT = get_next_value(),
        SINE_IN_OUT = get_next_value(),
        SINE_OUT_IN = get_next_value(),
        EXPONENTIAL_IN = get_next_value(),
        EXPONENTIAL_OUT = get_next_value(),
        EXPONENTIAL_IN_OUT = get_next_value(),
        EXPONENTIAL_OUT_IN = get_next_value(),
        CIRCULAR_IN = get_next_value(),
        CIRCULAR_OUT = get_next_value(),
        CIRCULAR_IN_OUT = get_next_value(),
        CIRCULAR_OUT_IN = get_next_value(),
        ELASTIC_IN = get_next_value(),
        ELASTIC_OUT = get_next_value(),
        ELASTIC_IN_OUT = get_next_value(),
        ELASTIC_OUT_IN = get_next_value(),
        OVERSHOOT_IN = get_next_value(),
        OVERSHOOT_OUT = get_next_value(),
        OVERSHOOT_IN_OUT = get_next_value(),
        OVERSHOOT_OUT_IN = get_next_value(),
        BOUNCE_IN = get_next_value(),
        BOUNCE_OUT = get_next_value(),
        BOUNCE_IN_OUT = get_next_value(),
        BOUNCE_OUT_IN = get_next_value(),
}
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

function NplOce.exportToParaX(scene)
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
	local template = WriteTemplate() or "";
	local data = scene:toParaX();
	if (template ~= "") then
        if(data ~= nil)then
            local Encoding = commonlib.gettable("System.Encoding");
		    data = Encoding.unbase64(data);
		    template = template..data;
            return template;
        end
	end
end


-- for storing temporary node parameter during scene traversal.
function NplOce.ShapeNode:_pushActionParam(param)
	self.action_params_ = self.action_params_ or {};
	table.insert(self.action_params_, param);
end

-- return all action params as array or nil, and clear them all.
function NplOce.ShapeNode:_popAllActionParams()
	local params = self.action_params_;
	self.action_params_ = nil;
	return params;
end

-- Set operator identifier on this node
-- @param {NplOce.Node} node
-- @param {string} op - "true" or "false"
function NplOce._setOp(node, op)
    node:setTag("_op",op);
end
function NplOce._getOp(node)
    return node:getTag("_op");
end

-- Set color on this node
-- @param {NplOce.Node} node
-- @param {object} color
-- @param {number} color.r - range[0,1]
-- @param {number} color.g - range[0,1]
-- @param {number} color.b - range[0,1]
-- @param {number} color.a - range[0,1]
function NplOce._setColor(node,color)
    node:setTag("_color",commonlib.serialize(color));
end
function NplOce._getColor(node)
    if(node:hasTag("_color"))then
        return commonlib.LoadTableFromString(node:getTag("_color"));
    end
end
-- Set operator on this node
-- @param {NplOce.Node} node
-- @param {string} op - "union" or "difference" or "intersection"
function NplOce._setBooleanOp(node,v)
    node:setTag("_boolean_op",v);
end
function NplOce._getBooleanOp(node)
    return node:getTag("_boolean_op");
end

function NplOce._setOpWorldMatrix(node,v)
    node:setTag("_op_world_matrix",v);
end
function NplOce._getOpWorldMatrix(node)
    return node:getTag("_op_world_matrix");
end