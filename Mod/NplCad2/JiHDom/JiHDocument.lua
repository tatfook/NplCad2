--[[
Title: JiHDocument
Author(s): leio
Date: 2023/6/12
Desc: build shapes in JiHDocument
use the lib:
------------------------------------------------------------
local JiHDocument = NPL.load("Mod/NplCad2/JiHDom/JiHDocument.lua");

local jih_doc = JiHDocument:new();
jih_doc.box("union", 1, 1, 1);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/System/Encoding/base64.lua");
local Encoding = commonlib.gettable("System.Encoding");
local JiHDocumentHelper = NPL.load("Mod/NplCad2/JiHDom/JiHDocumentHelper.lua");
local SvgParser = NPL.load("Mod/NplCad2/Svg/SvgParser.lua");

local JiHDocument = commonlib.inherit(nil,NPL.export());
function JiHDocument:ctor()
    commonlib.echo("=============create jih document");
	self.scene_node = JiHDocumentHelper.createJiHNode("scene");
    local cur_node = JiHDocumentHelper.createJiHNode("root");
    self.scene_node:addChild(cur_node);
    self.cur_node = cur_node;
    self.selected_node = self.cur_node;
    self.cur_stage = self.cur_node;

    self.pushed_node_list = {};
    self.pushed_sketch_node_list = {};
end

function JiHDocument:getCurStage()
    return self.cur_stage;
end

function JiHDocument:getSelectedNode()
    return self.selected_node;
end
function JiHDocument:getRootNode()
    return self.scene_node;
end
function JiHDocument:getCurNode()
    return self.cur_node;
end
function JiHDocument:addJiHNode(op, color, shape)
	color = color or JiHDocumentHelper.defaultNodeColor;
    local jih_node = JiHDocumentHelper.createJiHNode("", shape, color, op)

    local cur_node = self:getCurNode();
    if (cur_node)then
        local node = jih_node;
        cur_node:addChild(node);
        self.selected_node = node;
    end
    return jih_node;
end
function JiHDocument:pushStage(op, name, color, bOp)
    local node = self:pushNode(op, name, color, bOp)
    JiHDocumentHelper.setTag(node, JiHDocumentHelper.runningNodeTypes.pushStage);

    self.pre_stage = self.cur_stage;
    self.cur_stage = node;
    return node;
end
function JiHDocument:popStage()
    self:popNode()
    self.cur_stage = self.pre_stage;
    self.pre_stage = nil;
end
function JiHDocument:pushNode(op, name, color, bOp)
    name = name or JiHDocumentHelper.generateId();
    local jih_node = JiHDocumentHelper.createJiHNode(name, nil, color, op);
    JiHDocumentHelper.setOpEnabled(jih_node, bOp);
    JiHDocumentHelper.setTag(jih_node, JiHDocumentHelper.runningNodeTypes.pushNode);


    local parent = self.cur_node;
    if (not parent) then
        parent = self:getRootNode();
    end
    parent:addChild(jih_node)
    self.cur_node = jih_node;
    self.selected_node = jih_node;

    table.insert(self.pushed_node_list, jih_node);
    return jih_node
end
function JiHDocument:popNode()
    local len = #self.pushed_node_list;
	local node = self.pushed_node_list[len];
	local parent = node:getParent() or self.getRootNode();

	table.remove(self.pushed_node_list,len);
	self.cur_node = parent;
	self.selected_node = node;
end
function JiHDocument:box(op, x, y, z, color)
	local jihTopoShape = jihengine.JiHShapeMaker:box(x, y, z);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("box_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:sphere(op, radius, color)
    local jihTopoShape = jihengine.JiHShapeMaker:sphere(radius, -90, 90, 360);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("sphere_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:cylinder(op, radius, height, color)
    local jihTopoShape = jihengine.JiHShapeMaker:cylinder(radius, height, 360);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("cylinder_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:cone(op, top_radius, bottom_radius, height, color)
    local jihTopoShape = jihengine.JiHShapeMaker:cone(top_radius, bottom_radius, height, 360);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("cone_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:torus(op, radius1, radius2, color)
    local jihTopoShape = jihengine.JiHShapeMaker:torus(radius1, radius2, -180, 180, 360);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("torus_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:prism(op, edges, radius, height, color)
    local jihTopoShape = jihengine.JiHShapeMaker:prism(edges, radius, height);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("prism_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:ellipsoid(op, r_x, r_y, r_z, color)
    local jihTopoShape = jihengine.JiHShapeMaker:ellipsoid(r_x, r_y, r_z, -90, 90, 360);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("ellipsoid_" ..  JiHDocumentHelper.generateId());
end
function JiHDocument:wedge(op, x, z, h, color)
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
    local jihTopoShape = jihengine.JiHShapeMaker:wedge(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("wedge_" ..  JiHDocumentHelper.generateId());
end

function JiHDocument:trapezoid(op, top_w, bottom_w, hight, depth, color)
    local xmin = 0;
    local ymin = 0;
    local zmin = 0;
    local w = (bottom_w - top_w) / 2;
    local x2min = w;
    local z2min = 0;
    local xmax = bottom_w;
    local ymax = hight;
    local zmax = depth;
    local x2max = x2min + top_w;
    local z2max = depth;

    local jihTopoShape = jihengine.JiHShapeMaker:wedge(xmin, ymin, zmin, x2min, z2min, xmax, ymax, zmax, x2max, z2max);
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("trapezoid_" ..  JiHDocumentHelper.generateId());
end

function JiHDocument:import_step_str(op, step_data, color, isBase64)
    if (isBase64) then
        --decode base64
        step_data = atob(step_data);
    end
    local jihEasyStep = jihengine.JiHEasyStep:new();
    local jihTopoShape = jihEasyStep:readCharArrayToShape(JiHDocumentHelper.stringToJiHCharArray(step_data));
    local jih_node = self:addJiHNode(op, color, jihTopoShape);
    jih_node:setId("step_" + JiHDocumentHelper.generateId());
end
function JiHDocument:createSketch(name, plane)
    name = name or JiHDocumentHelper.generateId();
    local  node = JiHDocumentHelper.createJiHNode(name)
    JiHDocumentHelper.setPlane(node, plane);
    JiHDocumentHelper.setTag(node, JiHDocumentHelper.runningNodeTypes.is_sketch);

    local parent = self.cur_node;
    if (not parent) then
        parent = self:getRootNode();
    end
    parent:addChild(node)
    self.cur_node = node;
    self.selected_node = node;
    table.insert(self.pushed_sketch_node_list, node);
end
function JiHDocument:endSketch()
    local len = #self.pushed_sketch_node_list;
    local node = self.pushed_sketch_node_list[len];
    local parent = node:getParent()
    if (not parent) then
        parent = self:getRootNode();
    end
	table.remove(self.pushed_sketch_node_list,len);
    self.cur_node = parent;
    self.selected_node = node;
end
function JiHDocument:geom_point(x, y, z, color)
    local geom_component = jihengine.JiHShapeMaker:geom_point(x, y, z);
    local jihTopoShape = geom_component:toShape();
    local jih_node = self:addJiHNode(JiHDocumentHelper.opType.union, color, jihTopoShape);
    jih_node:addComponent(geom_component:toBase());
    jih_node:setId("geom_point_" .. JiHDocumentHelper.generateId());
end
function JiHDocument:geom_line_segment(start_x, start_y, start_z, end_x, end_y, end_z, color)
    local geom_component = jihengine.JiHShapeMaker:geom_line_segment(start_x, start_y, start_z, end_x, end_y, end_z);
    local jihTopoShape = geom_component:toShape();
    local jih_node = self:addJiHNode(JiHDocumentHelper.opType.union, color, jihTopoShape);
    jih_node:addComponent(geom_component:toBase());
    jih_node:setId("geom_line_segment_" .. JiHDocumentHelper.generateId());
end
function JiHDocument:geom_circle(x, y, z, r, color, dir)
    dir = dir or JiHDocumentHelper.ShapeDirection.y;
    local geom_component = jihengine.JiHShapeMaker:geom_circle(x, y, z, r, dir);
    local jihTopoShape = geom_component:toShape();
    local jih_node = self:addJiHNode(JiHDocumentHelper.opType.union, color, jihTopoShape);
    jih_node:addComponent(geom_component:toBase());
    jih_node:setId("geom_circle_" .. JiHDocumentHelper.generateId());
end
function JiHDocument:geom_ellipse(x, y, z, major_r, minor_r, color, dir)
    dir = dir or JiHDocumentHelper.ShapeDirection.y;
    local geom_component = jihengine.JiHShapeMaker:geom_ellipse(x, y, z, major_r, minor_r, dir);
    local jihTopoShape = geom_component:toShape();
    local jih_node = self:addJiHNode(JiHDocumentHelper.opType.union, color, jihTopoShape);
    jih_node:addComponent(geom_component:toBase());
    jih_node:setId("geom_ellipse_" .. JiHDocumentHelper.generateId());
end
function JiHDocument:geom_bezier(poles, color)
    poles =  poles or {}
    local poles_arr = jihengine.JiHDataVector3Array:new();
    for i = 1, #poles do
        local vector = jihengine.JiHDataVector3:new();
        vector:set(poles[i][1], poles[i][2], poles[i][3]);
        poles_arr:pushValue(vector);
    end

    local weights_arr = jihengine.JiHDoubleArray:new(); -- empty array
    local geom_component = jihengine.JiHShapeMaker:geom_bezier(poles_arr, weights_arr);
    local jihTopoShape = geom_component:toShape();
    local jih_node = self:addJiHNode(JiHDocumentHelper.opType.union, color, jihTopoShape);
    jih_node:addComponent(geom_component:toBase());
    jih_node:setId("geom_bezier_" .. JiHDocumentHelper.generateId());
end
function JiHDocument:geom_svg_file(filename, scale, color, plane)
    if (global_resource) then
        local str = global_resource(filename)
        self:geom_svg_string(str, scale, color, plane, false);
    end
end

function JiHDocument:geom_svg_string(str, scale, color, plane, bBase64)
    local is_sketch = JiHDocumentHelper.isSketchNode(self:getCurNode());
    if (is_sketch) then
        local sketch_plane = JiHDocumentHelper.getPlane(self:getCurNode());
        if (plane ~= sketch_plane) then
            if (sketch_plane == JiHDocumentHelper.PlaneType.xy or sketch_plane == JiHDocumentHelper.PlaneType.xz or sketch_plane == JiHDocumentHelper.PlaneType.zy) then
                -- auto change sketch's plane
                plane = sketch_plane;
            end
        end
            
    end
    self:geom_svg_string_(str, scale, color, 1, plane, bBase64);
end

function JiHDocument:geom_svg_string_(str, scale, color, hInvert, plane, bBase64)
    scale = scale or 1;
    local svg_parser = SvgParser:new()
	if(bBase64)then
		str = Encoding.unbase64(str);
	end
    svg_parser:ParseString(str);
    local result = svg_parser:GetResult();
    self:run_svg_codes(result, scale, color, hInvert, plane);
end
function JiHDocument:run_svg_codes(result, scale, color, hInvert, plane)
    --commonlib.echo("=====================result");
    --commonlib.echo(result);
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

                local from_x,from_y,from_z = JiHDocumentHelper.convert_xy_to_xyz(plane, input_from_x, input_from_y);
                local to_x,to_y,to_z = JiHDocumentHelper.convert_xy_to_xyz(plane, input_to_x, input_to_y);

                local bEqual = JiHDocumentHelper.is_equal_pos(from_x, from_y, from_z, to_x, to_y, to_z);
                if(not bEqual)then
                    self:geom_line_segment(
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

                    local x, y, z = JiHDocumentHelper.convert_xy_to_xyz(plane, input_x, input_y);
                    table.insert(result,{x, y , z});
                end
                self:geom_bezier(result, color, bAttach, plane);
            end
        end
    end
end

-- features 

function JiHDocument:feature_position(x, y, z)
    local node = self:getSelectedNode();
    JiHDocumentHelper.setPosition(node, x, y, z)
end
function JiHDocument:feature_rotate(axix, angle)
    local axis_x = 0;
    local axis_y = 0;
    local axis_z = 0;
    if (axix == JiHDocumentHelper.AxisType.x) then
        axis_x = 1;
    elseif (axix == JiHDocumentHelper.AxisType.y) then
        axis_y = 1;
    elseif (axix == JiHDocumentHelper.AxisType.z) then
        axis_z = 1;
    end
    self:feature_rotate_(axis_x, axis_y, axis_z, angle);
end

function JiHDocument:feature_rotate_(axis_x, axis_y, axis_z, angle_degree)
    local node = self:getSelectedNode();
    if (not node) then
        return
    end
    local q = jihengine.Quaternion:new();
    local axis = jihengine.Vector3:new(axis_x, axis_y, axis_z);
    local angle = angle_degree * math.pi * (1.0 / 180.0);
    jihengine.Quaternion:createFromAxisAngle(axis, angle, q);
    JiHDocumentHelper.setQuaternion(node, q:getX(), q:getY(), q:getZ(), q:getW());
end

function JiHDocument:feature_scale(x, y, z)
    local node = self:getSelectedNode();
    JiHDocumentHelper.setScale(node, x, y, z)
end
--[[
    /**
     * 
     * @param op
     * @param input_type: "chamfer" or "fillet"
     * @param length
     * @param edges: 1 or "1,2,3" or [1,2,3]
     * @param color
     */
]]
function JiHDocument:feature_chamfer_or_fillet(op, input_type, length, edges, color)
    local jihNode = self:getSelectedNode();
    if (type (edges) == "number") then
        edges = {edges}; -- one index
    elseif (type (edges) == "string") then
        local input_edges = edges;
        edges = {};
        local section
		for section in string.gfind(input_edges, "[^,]+") do
			index = tonumber(section);
			table.insert(edges,index);
		end
    end
    self:feature_chamfer_or_fillet_(input_type, jihNode, op, length, edges, color);
end
function JiHDocument:feature_chamfer_or_fillet_(input_type, jihNode, op, length, edge_array, color)
    if(not jihNode)then 
        return 
    end
    local shape = JiHDocumentHelper.getShape(jihNode);
    if (shape and (not shape:isNull())) then
        local edge_arr = jihengine.JiHIntArray:new();
        for k = 1, #edge_array do
            edge_arr:pushValue(edge_array[k]);
        end
        local parent_node = jihNode:getParent();
        local result_shape = nil;
        if (input_type == "chamfer") then
            result_shape = jihengine.JiHShapeMaker:chamfer(shape, length, edge_arr);
        elseif (input_type == "fillet") then
            result_shape = jihengine.JiHShapeMaker:fillet(shape, length, edge_arr);
        end
        if (result_shape and (not result_shape:isNull())) then
            local chamfer_node = JiHDocumentHelper.createJiHNode(input_type .. "_" .. JiHDocumentHelper.generateId(), result_shape, color, op);
            parent_node:addChild(chamfer_node);
            self.selected_node = chamfer_node;

            -- remove node
            parent_node = jihNode:getParent();
            parent_node:removeChild(jihNode);
        end
    end
end
function JiHDocument:feature_extrude_by_face(op, length, face_index, direction, color, bSolid)
    local jihNode = self:getSelectedNode();
    local dir_array = JiHDocumentHelper.convertDirectionToArray(direction);
    local dir_x = dir_array[1];
    local dir_y = dir_array[2];
    local dir_z = dir_array[3];
    self:feature_extrude_by_face_(jihNode, op, length, face_index, dir_x, dir_y, dir_z, color, bSolid);
end
function JiHDocument:feature_extrude_by_face_(jihNode, op, length, face_index, dir_x, dir_y, dir_z, color, bSolid)
    if (not jihNode) then
        return
    end
    local shape = JiHDocumentHelper.getShape(jihNode);
    if (shape and (not shape:isNull())) then
        local parent_node = jihNode:getParent();
        local extrude_shape = jihengine.JiHShapeMaker:extrude(shape, length, face_index, dir_x, dir_y, dir_z, bSolid);
        if (extrude_shape and (not extrude_shape:isNull())) then
            local extrude_node = JiHDocumentHelper.createJiHNode("extrude_" .. JiHDocumentHelper.generateId(), extrude_shape, color, op);
            parent_node:addChild(extrude_node);

            self.selected_node = extrude_node;
        end
    end
end
function JiHDocument:feature_extrude(op, length, direction, color, bSolid)
    local dir_array = JiHDocumentHelper.convertDirectionToArray(direction);
    local dir_x = dir_array[1];
    local dir_y = dir_array[2];
    local dir_z = dir_array[3];
    self:feature_extrude_internal(op, length, color, dir_x, dir_y, dir_z, bSolid)
end

function JiHDocument:feature_extrude_internal(op, length, color, dir_x, dir_y, dir_z, bSolid)
    -- check if this is a sketch node
        local sketch_node = self:getSelectedNode();
        if (sketch_node) then
            local tag = JiHDocumentHelper.getTag(sketch_node);
            if (tag == "is_sketch") then
                local parent_node = sketch_node:getParent();
                local shape = jihengine.JiHShapeMaker:to_wires_shape(sketch_node);
                if (shape and (not shape:isNull())) then
                    local extrude_shape = jihengine.JiHShapeMaker:extrude_shape(shape, length, dir_x, dir_y, dir_z, bSolid);
                    if (extrude_shape and (not extrude_shape:isNull())) then

                        local extrude_node = JiHDocumentHelper.createJiHNode("extrude_" .. JiHDocumentHelper.generateId(), extrude_shape, color, op);
                        parent_node:addChild(extrude_node);

                        self.selected_node = extrude_node;

                        -- remove sketch node
                        parent_node = sketch_node:getParent();
                        parent_node:removeChild(sketch_node);
                    end
                end
            end
        end
end

function JiHDocument:feature_revolve(op, angle, axis, color, bSolid)
    self:feature_revolve_internal(op, angle, axis, color, bSolid);
end

function JiHDocument:feature_revolve_internal(op, angle, axis, color, bSolid)
    local axis_x = 0;
    local axis_y = 0;
    local axis_z = 0;
    local dir_x = 0;
    local dir_y = 0;
    local dir_z = 0;
    if (axis == JiHDocumentHelper.AxisType.x) then
        dir_x = 1;
    elseif (axis == JiHDocumentHelper.AxisType.y) then
        dir_y = 1;
    elseif (axis == JiHDocumentHelper.AxisType.z) then
        dir_z = 1;
    else
        -- invalid param, axis
        return
    end
    -- check if this is a sketch node
    local sketch_node = self:getSelectedNode();
    if (sketch_node) then
        local tag = JiHDocumentHelper.getTag(sketch_node);
        if (tag == "is_sketch") then
            local parent_node = sketch_node:getParent();
            local shape = jihengine.JiHShapeMaker:to_wires_shape(sketch_node);
            if (shape and (not shape:isNull())) then
                local revolve_shape = jihengine.JiHShapeMaker:revolve_shape(shape, angle, axis_x, axis_y, axis_z, dir_x, dir_y, dir_z, bSolid);
                if (revolve_shape and (not revolve_shape:isNull())) then

                    local revolve_node = JiHDocumentHelper.createJiHNode("revolve_" .. JiHDocumentHelper.generateId(), revolve_shape, color, op);
                    parent_node:addChild(revolve_node);

                    self.selected_node = revolve_node;
                    -- remove sketch node
                    parent_node = sketch_node:getParent();
                    parent_node:removeChild(sketch_node);
                end
            end
        end
    end
end

function JiHDocument:feature_sweep(op, pathSketch_name, profileSketch_name, color, bSolid)
    local parent_node = self:getCurNode() or self:getCurStage();
        if (not parent_node) then
            return
        end
        local pathSketch_node = self:getCurStage():getChildById(pathSketch_name, true);
        local profileSketch_node = self:getCurStage():getChildById(profileSketch_name, true);
        if (pathSketch_node and profileSketch_node) then
            local pathSketch_tag = JiHDocumentHelper.getTag(pathSketch_node);
            local profileSketch_tag = JiHDocumentHelper.getTag(profileSketch_node);
            if (pathSketch_tag == "is_sketch" and profileSketch_tag == "is_sketch") then

                local profileSketch_shape = jihengine.JiHShapeMaker:to_wires_shape(profileSketch_node);
                local pathSketch_shape = jihengine.JiHShapeMaker:to_wires_shape(pathSketch_node);

                local sweep_shape = jihengine.JiHShapeMaker:sweep_shape(pathSketch_shape, profileSketch_shape, bSolid);
                if (sweep_shape and (not sweep_shape:isNull())) then

                    local sweep_node = JiHDocumentHelper.createJiHNode("sweep_" .. JiHDocumentHelper.generateId(), sweep_shape, color, op);
                    parent_node:addChild(sweep_node);

                    self.selected_node = sweep_node;


                    -- remove sketch node
                    parent_node = profileSketch_node:getParent();
                    parent_node:removeChild(profileSketch_node);

                    parent_node = pathSketch_node:getParent();
                    parent_node:removeChild(pathSketch_node);
                end
            end
        end
end

