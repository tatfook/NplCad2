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
    local charArray = jihengine.JiHCharArray:new();
    for k=1,#str do
        local char = str[k];
        local char_code = string.byte(char);
        charArray:pushValue(char_code);
    end
    return charArray;
end
function JiHDocumentHelper.charArrayToString(charArray)
    if(not charArray)then
        return
    end
    local s = "";
    local cnt = charArray:getCount();
    for k = 1, cnt do
        local index = k - 1;
        local char_code = charArray:getValue(index);
        s = s .. string.char(char_code);
    end
    return s;
end
function JiHDocumentHelper.run(scene_node, bUnionAll)
	commonlib.echo("===================run");
	if(not scene_node)then
		return
	end
	local cnt = scene_node:numChildren();
	commonlib.echo("===================cnt");
	commonlib.echo(cnt);
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
        materialComponent:setDiffuseColor(doubleArray);
    end
end
function JiHDocumentHelper.getColor(jih_node)
    local materialComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHMaterialComponent);
    if (materialComponent) then
        local doubleArray = materialComponent:getDiffuseColor();
        return {doubleArray:getValue(0), doubleArray:getValue(1), doubleArray:getValue(2), doubleArray:getValue(3)};
    end
end
function JiHDocumentHelper.setOpEnabled(jih_node, v)
    local booleanComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent);
    if (booleanComponent) then
        booleanComponent:setOpEnabled(v);
    end
end
function JiHDocumentHelper.getOpEnabled(jih_node)
    local booleanComponent = JiHDocumentHelper.getComponentByName(jih_node, JiHDocumentHelper.JiHComponentNames.JiHBooleanComponent);
    if (booleanComponent) then
        local v = booleanComponent:getOpEnabled();
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
