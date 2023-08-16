--[[
Title: Sketch
Author(s): leio
Date: 2023/8/16
Desc: sketch and constraint
use the lib:
------------------------------------------------------------
local Sketch = NPL.load("Mod/NplCad2/JiHDom/Sketch.lua");
Sketch.test();
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local Encoding = commonlib.gettable("System.Encoding");
local Sketch = commonlib.inherit(nil,NPL.export());

Sketch.ConstraintType = {
    None = 0,
    Coincident = 1,
    Horizontal = 2,
    Vertical = 3,
    Parallel = 4,
    Tangent = 5,
    Distance = 6,
    DistanceX = 7,
    DistanceY = 8,
    Angle = 9,
    Perpendicular = 10,
    Radius = 11,
    Equal = 12,
    PointOnObject = 13,
    Symmetric = 14,
    InternalAlignment = 15,
    SnellsLaw = 16,
    Block = 17,
    Diameter = 18,
    Weight = 19,
    -- NumConstraintTypes // must be the last item!
}

Sketch.InternalAlignmentType = {
    Undef = 0,
    EllipseMajorDiameter = 1,
    EllipseMinorDiameter = 2,
    EllipseFocus1 = 3,
    EllipseFocus2 = 4,
    HyperbolaMajor = 5,
    HyperbolaMinor = 6,
    HyperbolaFocus = 7,
    ParabolaFocus = 8,
    BSplineControlPoint = 9,
    BSplineKnotPoint = 10,
    ParabolaFocalAxis = 11,
    -- NumInternalAlignmentType // must be the last item!
}
Sketch.PointPos = {
    ["none"]   = 0,    -- Edge of a geometry
    ["start"]   = 1,    -- Starting point of a geometry
    ["end"]     = 2,    -- End point of a geometry
    ["mid"]     = 3     -- Mid point of a geometry
}
function Sketch:ctor()
	 self.sketchObject = jihengine.SketchObject:new();
     self.geoms = {};
     self.constraints = {};
end
function Sketch:solve()
    self.sketchObject:solve();
end
-- add_point
function Sketch:add_point(name, pos_arr)
    pos_arr =  pos_arr or { 0, 0, 0 };
    local geom = jihengine.JiHGeom_Point:new();
    geom:setId(name);
    geom:set(jihengine.Vector3:new(pos_arr[1],pos_arr[2],pos_arr[3]));
    local geom_id = self.sketchObject:addGeometry(geom:to_JiHGeom_Base());
    table.insert(self.geoms, geom_id);
    return geom_id;
end
-- add_line
function Sketch:add_line(name, from_pos_arr, to_pos_arr, direction_arr)
    local geom = jihengine.JiHGeom_Line:new();
    local startPoint = jihengine.Vector3:new(from_pos_arr[1], from_pos_arr[2], from_pos_arr[3]);
    local endPoint = jihengine.Vector3:new(to_pos_arr[1], to_pos_arr[2], to_pos_arr[3]);
    local direction = jihengine.Vector3:new(direction_arr[1], direction_arr[2], direction_arr[3]);
    geom:setId(name);
    geom:set(startPoint, endPoint, direction);
    local geom_id = self.sketchObject:addGeometry(geom:to_JiHGeom_Base());
    table.insert(self.geoms, geom_id);
    return geom_id;
end
-- add_circle
function Sketch:add_circle(name, center_arr, radius, direction_arr)
    local geom = jihengine.JiHGeom_Circle:new();
    local centerPoint = jihengine.Vector3:new(center_arr[1], center_arr[2], center_arr[3]);
    local direction = jihengine.Vector3:new(direction_arr[1], direction_arr[2], direction_arr[3]);
    geom:setId(name);
    geom:set(centerPoint, radius, direction);
    local geom_id = self.sketchObject:addGeometry(geom:to_JiHGeom_Base());
    table.insert(self.geoms, geom_id);
    return geom_id;
end
-- add_arc
function Sketch:add_arc(name, center_arr, radius, startAngle, endAngle, direction_arr)
    local geom = jihengine.JiHGeom_Arc:new();
    local centerPoint = jihengine.Vector3:new(center_arr[1], center_arr[2], center_arr[3]);
    local direction = jihengine.Vector3:new(direction_arr[1], direction_arr[2], direction_arr[3]);
    geom:setId(name);
    geom:set(centerPoint, radius, startAngle, endAngle, direction);
    local geom_id = self.sketchObject:addGeometry(geom:to_JiHGeom_Base());
    table.insert(self.geoms, geom_id);
    return geom_id;
end
-- constraint_point_coincident
function Sketch:add_constraint_point_coincident(to_geom_point_id, from_geom_point_id)
    local constraint = {
        Type = Sketch.ConstraintType.Coincident,
        First = to_geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = from_geom_point_id,
        SecondPos = Sketch.PointPos["end"],
    }
    return self:add_constraint(constraint);
end
-- constraint_distance_point_to_point
function Sketch:add_constraint_distance_point_to_point(from_geom_point_id, to_geom_point_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Distance,
        First = from_geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = to_geom_point_id,
        SecondPos = Sketch.PointPos["end"],
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_distance_line
function Sketch:add_constraint_distance_line(geom_line_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Distance,
        First = geom_line_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_distance_point_to_line
function Sketch:add_constraint_distance_point_to_line(geom_point_id, geom_line_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Distance,
        First = geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = geom_line_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_distance_circle_to_circle
function Sketch:add_constraint_distance_circle_to_circle(from_geom_circle_id, to_geom_circle_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Distance,
        First = from_geom_circle_id,
        Second = to_geom_circle_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_distance_x_line
function Sketch:add_constraint_distance_x_line(geom_line_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.DistanceX,
        First = geom_line_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_distance_x_point_to_point
function Sketch:add_constraint_distance_x_point_to_point(from_geom_point_id, to_geom_point_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.DistanceX,
        First = from_geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = to_geom_point_id,
        SecondPos = Sketch.PointPos["end"],
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_distance_x_point_on_x
function Sketch:add_constraint_distance_x_point_on_x(geom_point_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.DistanceX,
        First = geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_distance_y_line
function Sketch:add_constraint_distance_y_line(geom_line_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.DistanceY,
        First = geom_line_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_distance_y_point_to_point
function Sketch:add_constraint_distance_y_point_to_point(from_geom_point_id, to_geom_point_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.DistanceY,
        First = from_geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = to_geom_point_id,
        SecondPos = Sketch.PointPos["end"],
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_distance_y_point_on_y
function Sketch:add_constraint_distance_y_point_on_y(geom_point_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.DistanceY,
        First = geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_radius to circle or arc
function Sketch:add_constraint_radius(geom_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Radius,
        First = geom_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_diameter to circle or arc
function Sketch:add_constraint_diameter(geom_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Diameter,
        First = geom_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end

-- constraint_h_line
function Sketch:add_constraint_h_line(geom_line_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Horizontal,
        First = geom_line_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_h_point_to_point
function Sketch:add_constraint_h_point_to_point(from_geom_point_id, to_geom_point_id)
    local constraint = {
        Type = Sketch.ConstraintType.Horizontal,
        First = from_geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = to_geom_point_id,
        SecondPos = Sketch.PointPos["end"],
    }
    return self:add_constraint(constraint);
end
-- constraint_v_line
function Sketch:add_constraint_v_line(geom_line_id, value)
    local constraint = {
        Type = Sketch.ConstraintType.Vertical,
        First = geom_line_id,
        Value = value,
    }
    return self:add_constraint(constraint);
end
-- constraint_v_point_to_point
function Sketch:add_constraint_v_point_to_point(from_geom_point_id, to_geom_point_id)
    local constraint = {
        Type = Sketch.ConstraintType.Vertical,
        First = from_geom_point_id,
        FirstPos = Sketch.PointPos.start,
        Second = to_geom_point_id,
        SecondPos = Sketch.PointPos["end"],
    }
    return self:add_constraint(constraint);
end
-- constraint_parallel_line_to_line
function Sketch:add_constraint_parallel_line_to_line(from_geom_line_id, to_geom_line_id)
    local constraint = {
        Type = Sketch.ConstraintType.Parallel,
        First = from_geom_line_id,
        Second = to_geom_line_id,
    }
    return self:add_constraint(constraint);
end

function Sketch:add_constraint(constraint)
    constraint = constraint or {};
    commonlib.echo("==================constraint");
    commonlib.echo(constraint);

    local constraint_obj = jihengine.ConstraintObject:new();

    if (constraint.Value ~= nil)                    then constraint_obj:setValue(constraint.Value);                                     end
    if (constraint.Type ~= nil)                     then constraint_obj:setType(constraint.Type);                                       end
    if (constraint.AlignmentType ~= nil)            then constraint_obj:setAlignmentType(constraint.AlignmentType);                     end
    if (constraint.Name ~= nil)                     then constraint_obj:setName(constraint.Name);                                       end
    if (constraint.First ~= nil)                    then constraint_obj:setFirst(constraint.First);                                     end
    if (constraint.FirstPos ~= nil)                 then constraint_obj:setFirstPos(constraint.FirstPos);                               end
    if (constraint.Second ~= nil)                   then constraint_obj:setSecond(constraint.Second);                                   end
    if (constraint.SecondPos ~= nil)                then constraint_obj:setSecondPos(constraint.SecondPos);                             end
    if (constraint.Third ~= nil)                    then constraint_obj:setThird(constraint.Third);                                     end
    if (constraint.ThirdPos ~= nil)                 then constraint_obj:setThirdPos(constraint.ThirdPos);                               end
    if (constraint.LabelDistance ~= nil)            then constraint_obj:setLabelDistance(constraint.LabelDistance);                     end
    if (constraint.LabelPosition ~= nil)            then constraint_obj:setLabelPosition(constraint.LabelPosition);                     end
    if (constraint.isDriving ~= nil)                then constraint_obj:setDriving(constraint.isDriving);                               end
    if (constraint.InternalAlignmentIndex ~= nil)   then constraint_obj:setInternalAlignmentIndex(constraint.InternalAlignmentIndex);   end
    if (constraint.isInVirtualSpace ~= nil)         then constraint_obj:setInVirtualSpace(constraint.isInVirtualSpace);                 end
    if (constraint.isActive ~= nil)                 then constraint_obj:setActive(constraint.isActive);                                 end
    if (constraint.mId ~= nil)                      then constraint_obj:setId(constraint.mId);                                          end


    local constraint_id = self.sketchObject:addConstraint(constraint_obj);
    table.insert(self.constraints, constraint_id);
    return constraint_id;
end
function Sketch:dump()
    local geom_array = self.sketchObject:getCompleteGeometryArray();
    commonlib.echo("==================geom_array");
    for k = 0, geom_array:getCount()-1 do
        local geom = geom_array:getValue(k);
        local id = geom:getId();
        local name = geom:getName();
        commonlib.echo("==================id");
        commonlib.echo({id = id, name = name});
        if(name == "JiHGeom_Point")then
            local geom_point = jihengine.JiHTypeConverter:to_JiHGeom_Point(geom);
            local pos = geom_point:getPoint();
            commonlib.echo({pos:getX(), pos:getY(), pos:getZ(), });
        elseif(name == "JiHGeom_Line")then
            local geom_line = jihengine.JiHTypeConverter:to_JiHGeom_Line(geom);
            local pos_start = geom_line:getStartPoint();
            local pos_end = geom_line:getEndPoint();
            commonlib.echo({pos_start:getX(), pos_start:getY(), pos_start:getZ(), });
            commonlib.echo({pos_end:getX(), pos_end:getY(), pos_end:getZ(), });
        elseif(name == "JiHGeom_Circle")then
            local geom_circle = jihengine.JiHTypeConverter:to_JiHGeom_Circle(geom);
            local center = geom_circle:getCenter();
            local radius = geom_circle:getRadius();
            commonlib.echo({center:getX(), center:getY(), center:getZ(), radius, });
        elseif(name == "JiHGeom_Arc")then
            local geom_arc = jihengine.JiHTypeConverter:to_JiHGeom_Arc(geom);
            local center = geom_arc:getCenter();
            local radius = geom_arc:getRadius();
            local startAngle = geom_arc:getStartAngle();
            local endAngle = geom_arc:getEndAngle();
            commonlib.echo({center:getX(), center:getY(), center:getZ(), radius, startAngle, endAngle, });
        end
    end
end
function Sketch:test_constraint_point_coincident()
    local geom_id_1 = self:add_point("geom_id_1", { 0, 0, 0 });
    local geom_id_2 = self:add_point("geom_id_2", { 10, 0, 0 });

    self:add_constraint_point_coincident(geom_id_1, geom_id_2)

    commonlib.echo("==================test_constraint_point_coincident");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_point_coincident solved");
    self:dump();
end
function Sketch:test_constraint_distance_point_to_point()
    local geom_id_1 = self:add_point("geom_id_1", { 20, 0, 0 });
    local geom_id_2 = self:add_point("geom_id_2", { 30, 0, 0 });

    self:add_constraint_distance_point_to_point(geom_id_1, geom_id_2, 20);
    commonlib.echo("==================test_constraint_distance_point_to_point");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_point_to_point solved");
    self:dump();
end
function Sketch:test_constraint_distance_line()
    local geom_id_line = self:add_line("geom_id_line", { 0, 0, 0 }, { 10, 0, 0 }, { 0, 0, 1 });

    self:add_constraint_distance_line(geom_id_line, 20);
    commonlib.echo("==================test_constraint_distance_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_line solved");
    self:dump();
end
function Sketch:test_constraint_distance_point_to_line()
    local geom_id_point = self:add_point("geom_id_point", { 0, 0, 0 });
    local geom_id_line = self:add_line("geom_id_line", { 0, 0, 0 }, { 10, 0, 0 }, { 0, 0, 1 });

    self:add_constraint_distance_point_to_line(geom_id_point, geom_id_line, 20);
    commonlib.echo("==================test_constraint_distance_point_to_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_point_to_line  solved");
    self:dump();
end
function Sketch:test_constraint_distance_circle_to_circle()
    local geom_id_circle_1 = self:add_circle("geom_id_circle_1", { 0, 0, 0 }, 10, { 0, 0, 1 });
    local geom_id_circle_2 = self:add_circle("geom_id_circle_2", { 10, 0, 0 }, 10, { 0, 0, 1 });

    self:add_constraint_distance_circle_to_circle(geom_id_circle_1, geom_id_circle_2, 20);
    commonlib.echo("==================test_constraint_distance_circle_to_circle");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_circle_to_circle solved");
    self:dump();
end
function Sketch:test_constraint_distance_x_line()
    local geom_id_line = self:add_line("geom_id_line", { 0, 0, 0 }, { 10, 0, 0 }, { 0, 0, 1 });

    self:add_constraint_distance_x_line(geom_id_line, 20);
    commonlib.echo("==================test_constraint_distance_x_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_x_line solved");
    self:dump();
end
function Sketch:test_constraint_distance_x_point_to_point()
    local geom_id_1 = self:add_point("geom_id_1", { 20, 0, 0 });
    local geom_id_2 = self:add_point("geom_id_2", { 30, 0, 0 });

    self:add_constraint_distance_x_point_to_point(geom_id_1, geom_id_2, 20);
    commonlib.echo("==================test_constraint_distance_x_point_to_point");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_x_point_to_point solved");
    self:dump();
end

function Sketch:test_constraint_distance_x_point_on_x()
    local geom_id_1 = self:add_point("geom_id_1", { 10, 0, 0 });

    self:add_constraint_distance_x_point_on_x(geom_id_1, 20);
    commonlib.echo("==================test_constraint_distance_x_point_on_x");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_x_point_on_x solved");
    self:dump();
end
function Sketch:test_constraint_distance_y_line()
    local geom_id_line = self:add_line("geom_id_line", { 0, 0, 0 }, { 10, 0, 0 }, { 0, 0, 1 });

    self:add_constraint_distance_y_line(geom_id_line, 20);
    commonlib.echo("==================test_constraint_distance_y_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_y_line solved");
    self:dump();
end

function Sketch:test_constraint_distance_y_point_to_point()
    local geom_id_1 = self:add_point("geom_id_1", { 20, 0, 0 });
    local geom_id_2 = self:add_point("geom_id_2", { 30, 0, 0 });

    self:add_constraint_distance_y_point_to_point(geom_id_1, geom_id_2, 20);
    commonlib.echo("==================test_constraint_distance_y_point_to_point");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_y_point_to_point solved");
    self:dump();
end
function Sketch:test_constraint_distance_y_point_on_y()
    local geom_id_1 = self:add_point("geom_id_1", { 10, 0, 0 });

    self:add_constraint_distance_y_point_on_y(geom_id_1, 20);
    commonlib.echo("==================test_constraint_distance_y_point_on_y");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_distance_y_point_on_y solved");
    self:dump();
end

function Sketch:test_constraint_radius()
    local geom_id_circle_1 = self:add_circle("geom_id_circle_1", { 0, 0, 0 }, 10, { 0, 0, 1 });
    self:add_constraint_radius(geom_id_circle_1, 20);

    local geom_id_arc_1 = self:add_arc("geom_id_arc_1", { 0, 0, 0 }, 10, 0, 1.57, { 0, 0, 1 });
    self:add_constraint_radius(geom_id_arc_1, 30);

    commonlib.echo("==================test_constraint_radius");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_radius solved");
    self:dump();
end

function Sketch:test_constraint_diameter()
    local geom_id_circle_1 = self:add_circle("geom_id_circle_1", { 0, 0, 0 }, 10, { 0, 0, 1 });
    self:add_constraint_diameter(geom_id_circle_1, 20);

    local geom_id_arc_1 = self:add_arc("geom_id_arc_1", { 0, 0, 0 }, 10, 0, 1.57, { 0, 0, 1 });
    self:add_constraint_diameter(geom_id_arc_1, 30);

    commonlib.echo("==================test_constraint_diameter");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_diameter solved");
    self:dump();
end
function Sketch:test_constraint_h_line()
    local geom_id_line = self:add_line("geom_id_line", { 0, 0, 0 }, { 10, 10, 0 }, { 0, 0, 1 });

    self:add_constraint_h_line(geom_id_line);
    commonlib.echo("==================test_constraint_h_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_h_line solved");
    self:dump();
end
function Sketch:test_constraint_h_point_to_point()
    local geom_id_1 = self:add_point("geom_id_1", { 20, 0, 0 });
    local geom_id_2 = self:add_point("geom_id_2", { 30, 10, 0 });

    self:add_constraint_h_point_to_point(geom_id_1, geom_id_2);
    commonlib.echo("==================test_constraint_h_point_to_point");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_h_point_to_point solved");
    self:dump();
end
function Sketch:test_constraint_v_line()
    local geom_id_line = self:add_line("geom_id_line", { 0, 0, 0 }, { 10, 10, 0 }, { 0, 0, 1 });

    self:add_constraint_v_line(geom_id_line);
    commonlib.echo("==================test_constraint_v_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_v_line solved");
    self:dump();
end
function Sketch:test_constraint_v_point_to_point()
    local geom_id_1 = self:add_point("geom_id_1", { 20, 0, 0 });
    local geom_id_2 = self:add_point("geom_id_2", { 30, 10, 0 });

    self:add_constraint_v_point_to_point(geom_id_1, geom_id_2);
    commonlib.echo("==================test_constraint_v_point_to_point");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_v_point_to_point solved");
    self:dump();
end
function Sketch:test_constraint_parallel_line_to_line()
    local geom_id_line_1 = self:add_line("geom_id_line_1", { 0, 0, 0 }, { 10, 0, 0 }, { 0, 0, 1 });
    local geom_id_line_2 = self:add_line("geom_id_line_2", { 0, 5, 0 }, { 10, 10, 0 }, { 0, 0, 1 });

    self:add_constraint_parallel_line_to_line(geom_id_line_1, geom_id_line_2);
    commonlib.echo("==================test_constraint_parallel_line_to_line");
    self:dump();
    self:solve();
    commonlib.echo("==================test_constraint_parallel_line_to_line solved");
    self:dump();
end
function Sketch.test()
    local sketch = Sketch:new();
    sketch:test_constraint_point_coincident();

    sketch = Sketch:new();
    sketch:test_constraint_distance_point_to_point();

    sketch = Sketch:new();
    sketch:test_constraint_distance_line();

    sketch = Sketch:new();
    sketch:test_constraint_distance_point_to_line();

    sketch = Sketch:new();
    sketch:test_constraint_distance_circle_to_circle();

    sketch = Sketch:new();
    sketch:test_constraint_distance_x_line();

    sketch = Sketch:new();
    sketch:test_constraint_distance_x_point_to_point();

    sketch = Sketch:new();
    sketch:test_constraint_distance_x_point_on_x();

    sketch = Sketch:new();
    sketch:test_constraint_distance_y_line();

    sketch = Sketch:new();
    sketch:test_constraint_distance_y_point_to_point();

    sketch = Sketch:new()
    sketch:test_constraint_distance_y_point_on_y();

    sketch = Sketch:new()
    sketch:test_constraint_radius();

    sketch = Sketch:new()
    sketch:test_constraint_diameter();

    sketch = Sketch:new();
    sketch:test_constraint_h_line();

    sketch = Sketch:new();
    sketch:test_constraint_h_point_to_point()

    sketch = Sketch:new();
    sketch:test_constraint_v_line();

    sketch = Sketch:new();
    sketch:test_constraint_v_point_to_point()

    sketch = Sketch:new();
    sketch:test_constraint_parallel_line_to_line()
end