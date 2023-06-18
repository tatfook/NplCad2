--[[
Title: BezierObject
Author(s): leio
Date: 2023/6/12
Desc: save bezier info for create JiHGeomBezierCurve component in JiHDocumnet
use the lib:
------------------------------------------------------------
local BezierObject = NPL.load("Mod/NplCad2/JiHDom/BezierObject.lua");

------------------------------------------------------------
--]]

local BezierObject = commonlib.inherit(nil,NPL.export());
BezierObject.CurveTypes = {
    bezier = "bezier",
    bspline = "bspline",
}
function BezierObject:ctor()
	
end

function BezierObject:onInit(name, curveType, color, poles)
	self.name = name;
	self.curveType = curveType;
	self.color = color;
	self.poles = poles or {};
    self.maxDegree = 25;
    return self;
end
function BezierObject:addPole(x, y, z)
	table.insert(self.poles, {x = x ,y = y, z = z})
end
function BezierObject:getPolesArray()
    local poles_arr = jihengine.JiHDataVector3Array:new();
    local len = #(self.poles);
    if (len < 2) then
        -- set default poles
        local pole_1 = { x = 0, y = 0, z = 0 };
        local pole_2 = { x = 1, y = 1, z = 0 };
        self.poles = {pole_1, pole_2};

        len = 2;
    end
    for k = 1, len do
        if (k < (self.maxDegree + 1 + 1)) then
            local value = jihengine.JiHDataVector3:new();
            local pole = self.poles[k];
            value:set(pole.x, pole.y, pole.z);

            poles_arr:pushValue(value);
        end
    end
            
    return poles_arr;
end
function BezierObject:create_JiHGeomBezierCurve()
    local poles_arr = self:getPolesArray();
    local weights_arr = jihengine.JiHDoubleArray:new(); -- empty array

    local geom_component = jihengine.JiHShapeMaker:geom_bezier(poles_arr, weights_arr);
    return geom_component;
end
function BezierObject:create_JiHGeomBSplineCurve()
    local poles_arr = self:getPolesArray();
    local weights_arr = jihengine.JiHDoubleArray:new(); 
    local knots = jihengine.JiHDoubleArray:new(); 
    local multiplicities = jihengine.JiHIntArray:new();
    local degree = 3;
    local periodic = true;
    local checkrational = false;

    local number_of_poles = poles_arr:getCount();
    local number_of_knots = number_of_poles + 1;

    if (number_of_poles <= degree) then
        degree = number_of_poles - 1;
    end

    for i = 1,number_of_poles do
        weights_arr:pushValue(1);
    end
    for k = 1, number_of_knots do
        multiplicities:pushValue(1);
        knots:pushValue((k - 1) / (number_of_knots - 1)); -- uniform knot
    end

    local geom_component = jihengine.JiHShapeMaker:geom_bspline(poles_arr, weights_arr, knots, multiplicities, degree, periodic, checkrational);
    return geom_component;
end