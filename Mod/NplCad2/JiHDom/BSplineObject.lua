--[[
Title: BSplineObject
Author(s): leio
Date: 2023/6/12
Desc: save curve info for creating bspline
use the lib:
------------------------------------------------------------
local BSplineObject = NPL.load("Mod/NplCad2/JiHDom/BSplineObject.lua");

------------------------------------------------------------
--]]

local BSplineObject = commonlib.inherit(nil,NPL.export());

BSplineObject.CurveTypes = {
    bezier = "bezier",
    bspline = "bspline",
}

BSplineObject.PositionTypes = {
    pole = "pole",
    point = "point",
}

function BSplineObject:ctor()
	
end
--@param {string} name:
--@param {Array<{x,y,z}>} positions:
--@param {BSplineObject.CurveTypes} curveType:
--@param {BSplineObject.PositionTypes} positionType:
--@param {boolean} closed:
--@param {string} color:

function BSplineObject:onInit(name, curveType, positionType, closed, color, positions)
	self.name = name;
	self.curveType = curveType;
	self.positionType = positionType;
	self.color = color;
	self.positions = positions or {};
	self.closed = closed;
    return self;
end
function BSplineObject:addPosition(x, y, z)
	table.insert(self.positions, {x = x ,y = y, z = z})
end
function BSplineObject:getPolesArray()
    local positions_arr = jihengine.JiHDataVector3Array:new();
    local len = #(self.positions);
    if (len < 2) then
        -- set default positions
        local position_1 = { x = 0, y = 0, z = 0 };
        local position_2 = { x = 1, y = 0, z = 0 };
        self.positions = {position_1, position_2};

        len = 2;
    end
    for k = 1, len do
        local value = jihengine.JiHDataVector3:new();
        local position = self.positions[k];
        value:set(position.x, position.y, position.z);

        positions_arr:pushValue(value);
    end
            
    return positions_arr;
end
function BSplineObject:create_JiHGeomBezierCurve()
    local poles_arr = self:getPolesArray();
    local geom_component = jihengine.JiHShapeMaker:geom_bezier(poles_arr);
    return geom_component;
end
function BSplineObject:create_JiHGeomBSplineCurve()
    local poles_arr = self:getPolesArray();
    local weights_arr = jihengine.JiHDoubleArray:new(); 
    local knots = jihengine.JiHDoubleArray:new(); 
    local multiplicities = jihengine.JiHIntArray:new();
    local closed = self.closed;
    local checkrational = true;

    local degree = 3;
    local poles_cnt = poles_arr:getCount();
    local knots_cnt = 0
    if(closed)then
        if(poles_cnt <= degree)then
            degree = poles_cnt;
        end
        knots_cnt = poles_cnt +  1;
    else
        if(poles_cnt <= degree)then
            degree = poles_cnt - 1;
        end
        knots_cnt = poles_cnt - degree +  1;
    end
    

    for i = 1,poles_cnt do
        weights_arr:pushValue(1);
    end
    local multi = {};
    for k = 1, knots_cnt do
        knots:pushValue((k - 1) / (knots_cnt - 1)); -- uniform knot
        multi[k] = 1;
    end
    if(not closed)then
        multi[1] = degree +  1;
        multi[knots_cnt] = degree +  1;
    end
    for k = 1, knots_cnt do
        local v = multi[k];
        multiplicities:pushValue(v);
    end

    local geom_component = jihengine.JiHShapeMaker:geom_bspline(poles_arr, weights_arr, knots, multiplicities, degree, closed, checkrational);
    return geom_component;
end