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
    basis_spline = "basis_spline",
    catmullrom_spline = "catmullrom_spline",
}



function BSplineObject:ctor()
	
end
--@param {string} name:
--@param {Array<{x,y,z}>} positions:
--@param {number} degree:
--@param {boolean} closed:
--@param {string} color:
--@param {BSplineObject.CurveTypes} curveType:

function BSplineObject:onInit(name, positions, degree, closed, color, curveType)
	self.name = name;
	self.positions = positions or {};
	self.degree = degree;
	self.closed = closed;
	self.color = color;
	self.curveType = curveType;
    return self;
end
function BSplineObject:addPosition(x, y, z)
	table.insert(self.positions, {x = x ,y = y, z = z})
end
function BSplineObject:create_JiHGeomBSplineCurve()
    local bspline_params = BSplineObject.createJiHGeomBSplineParams(self.positions, self.closed, 3)
    local geom_component = jihengine.JiHShapeMaker:geom_bspline(bspline_params.poles_arr, 
                                                                bspline_params.weights_arr, 
                                                                bspline_params.knots_arr, 
                                                                bspline_params.multiplicities_arr, 
                                                                bspline_params.degree, 
                                                                false, 
                                                                true,
                                                                self.curveType);
    return geom_component;
end
function BSplineObject.clamp_number(value, min, max)
    return math.max(min, math.min(max, value));
end
function BSplineObject.getKnots(degree, poles_cnt, is_closed)
    local knots = {};
    if(is_closed)then
        poles_cnt = poles_cnt + 1;
    end
    if(poles_cnt <= degree)then
         degree = poles_cnt - 1;
    end
    
    local knots_cnt = poles_cnt - degree + 1;

   
    for i = 0, knots_cnt - 1 do
        local knot = i / (knots_cnt - 1);
        table.insert(knots, BSplineObject.clamp_number(knot, 0, 1));
    end
    local p = {
        knots = knots,
        degree = degree,
    }
    return p;
end
--[[
 -- @parma poles: { {x = x, y = y, z = z, }, {x = x, y = y, z = z, }, }
 -- @return result = {
        poles_arr = poles_arr,
        weights_arr = weights_arr,
        knots_arr = knots_arr,
        multiplicities_arr = multiplicities_arr,
        degree = degree,
        closed = closed,
    }
]]

function BSplineObject.createJiHGeomBSplineParams(poles, closed, degree)
    poles = poles or {};
    if(#poles < 2)then
        poles = {
             { x = 0, y = 0, z = 0 },
             { x = 1, y = 1, z = 0 },
        }
    end
    degree = degree or 3;
    local knots_params = BSplineObject.getKnots(degree, #poles, closed);
    local knots = knots_params.knots;
    degree = knots_params.degree;

    local poles_arr = jihengine.JiHDataVector3Array:new();
    local weights_arr = jihengine.JiHDoubleArray:new(); 
    local knots_arr = jihengine.JiHDoubleArray:new(); 
    local multiplicities_arr = jihengine.JiHIntArray:new();

    local input_poles = {};
    local input_multiplicities = {};
    for k,v in ipairs(poles) do
        table.insert(input_poles, v);
    end
    if(closed)then
        table.insert(input_poles, poles[1]);
    end

    local input_poles_cnt = #input_poles;
    
    -- set poles_arr
    for k,pole in ipairs(input_poles) do
        local value = jihengine.JiHDataVector3:new();
        if(pole.x == nil)then
            value:set(pole[1], pole[2], pole[3]);
        else
            value:set(pole.x, pole.y, pole.z);
        end
        poles_arr:pushValue(value);

        -- set weights_arr
        weights_arr:pushValue(1);
    end
    -- set knots_arr
    for k, knot in ipairs(knots) do
        knots_arr:pushValue(knot);

        table.insert(input_multiplicities, 1);
    end
     -- set multiplicities_arr
    input_multiplicities[1] = degree + 1;
    input_multiplicities[#input_multiplicities] = degree + 1;
    for k, v in ipairs(input_multiplicities) do
        multiplicities_arr:pushValue(v);
    end

    --[[
    commonlib.echo("========================createJiHGeomBSplineParams");
    commonlib.echo({
        input_poles = input_poles,
        knots = knots,
        input_multiplicities = input_multiplicities,
        degree = degree,
    })
    ]]
    
    local result = {
        poles_arr = poles_arr,
        weights_arr = weights_arr,
        knots_arr = knots_arr,
        multiplicities_arr = multiplicities_arr,
        degree = degree,
        closed = closed,
    }
    return result;
end