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

NPL.load("(gl)script/ide/System/Core/Color.lua");
local Color = commonlib.gettable("System.Core.Color");

local ShapeBuilder = NPL.export();

ShapeBuilder.scene = nil;

-- Create a new node and set the current level to it
function ShapeBuilder.beginNode()
    local cur_node = ShapeBuilder.getCurNode();
    if(cur_node)then
        local node = NplOce.Node.create(ShapeBuilder.generateId());
        cur_node:addChild(node)
        ShapeBuilder.cur_node = node;
        return node
    end
end
-- Get back the parent node
function ShapeBuilder.endNode()
    local node = ShapeBuilder.getCurNode();
    if(node)then
        if(node.getParent)then
            local parent = node:getParent();
            ShapeBuilder.cur_node = parent 
        end
    end
end
-- Get the current level node
function ShapeBuilder.getCurNode()
    return ShapeBuilder.cur_node;
end
-- Create a scene
function ShapeBuilder.create()
    ShapeBuilder.scene = NplOce.Scene.create();
    ShapeBuilder.cur_node = ShapeBuilder.scene:addNode(ShapeBuilder.generateId());
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

-- Export the scene to brep
-- @return {string} v
function ShapeBuilder.toBrep()
    local brep = "brep";
    return brep;
end

-- Export the scene to json string
-- @param {number} [indent = -1]
-- @return {string} v
function ShapeBuilder.toJson(indent)
    local json = ShapeBuilder.scene:toJson(4);
    return json;
end

function ShapeBuilder.toParaX()
    local json = ShapeBuilder.scene:toParaX();
    return json;
end


-- Generate an unique id
-- @return {string} id;
function ShapeBuilder.generateId()
    return ParaGlobal.GenerateUniqueID();
end
-- Add a shape to scene
-- @param {NPL_TopoDS_Shape} shape
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.addShape(shape,color) 
    if(not shape)then
        return
    end
    local cur_node = ShapeBuilder.getCurNode();
    if(cur_node)then
        color = ShapeBuilder.converColorToRGBA(color);
        color = color or { r = 1, g = 0, b = 0, a = 1 };
        local model = NplOce.TopoModel.create(shape,color.r,color.g,color.b,color.a);
        local node = NplOce.Node.create(ShapeBuilder.generateId());
        node:setDrawable(model);
        cur_node:addChild(node);
        return node;
    end
    
end
-- Create a cube
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cube(x,y,z,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.cube(x,y,z),color) 
end
function ShapeBuilder.cube(size,color) 
    ShapeBuilder._cube(size,size,size,color) 
end
-- Create a cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cylinder(radius,height,angle,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.cylinder(radius,height,angle),color) 
end
function ShapeBuilder.cylinder(radius,height,color) 
    ShapeBuilder._cylinder(radius,height,360,color);
end

-- Create a sphere
-- @param {number} [radius = 5]
-- @param {number} [angle1 = -90]
-- @param {number} [angle2 = 90]
-- @param {number} [angle3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._sphere(radius,angle1,angle2,angle3,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.sphere(radius,angle1,angle2,angle3),color) 
end
function ShapeBuilder.sphere(radius,color) 
    ShapeBuilder._sphere(radius,-90,90,360,color);
end
-- Create a cone
-- @param {number} [radius1 = 2]
-- @param {number} [radius2 = 4]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cone(radius1,radius2,height,angle,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.cone(radius1,radius2,height,angle),color) 
end
function ShapeBuilder.cone(radius1,radius2,height,color) 
    ShapeBuilder._cone(radius1,radius2,height,360,color);
end
-- Create a torus
-- @param {number} [radius1 = 10]
-- @param {number} [radius2 = 2]
-- @param {number} [angle1 = -180]
-- @param {number} [angle2 = 180]
-- @param {number} [angle3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._torus(radius1,radius2,angle1,angle2,angle3,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.torus(radius1,radius2,angle1,angle2,angle3),color) 
end
function ShapeBuilder.torus(radius1,radius2,color) 
    ShapeBuilder._torus(radius1,radius2,-180,180,360,color);
end
-- Create a point
-- @param {number} [x = 0]
-- @param {number} [y = 0]
-- @param {number} [z = 0]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.point(x,y,z,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.point(x,y,z),color) 
end

-- Create a line
-- @param {number} [x1 = 0]
-- @param {number} [y1 = 0]
-- @param {number} [z1 = 0]
-- @param {number} [x2 = 0]
-- @param {number} [y2 = 0]
-- @param {number} [z2 = 0]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.line(x1,y1,z1,x2,y2,z2,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.line(x1,y1,z1,x2,y2,z2),color) 
end

-- Create a plane
-- @param {number} [l = 100]
-- @param {number} [w = 100]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.plane(l,w,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.plane(l,w),color) 
end

-- Create a circle
-- @param {number} [r = 0]
-- @param {number} [a0 = 0]
-- @param {number} [a1 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._circle(r,a0,a1,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.circle(r,a0,a1),color) 
end
function ShapeBuilder.circle(r,a0,a1,color) 
    ShapeBuilder._circle(r,0,360,color) 
end
-- Create an ellipse
-- @param {number} [r1 = 0]
-- @param {number} [r2 = 0]
-- @param {number} [a0 = 0]
-- @param {number} [a1 = 0]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._ellipse(r1,r2,a0,a1,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.ellipse(r1,r2,a0,a1),color) 
end
function ShapeBuilder.ellipse(r1,r2,color) 
    ShapeBuilder._ellipse(r1,r2,0,360,color) 
end
-- Create a helix
-- @param {number} [p = 0]
-- @param {number} [h = 0]
-- @param {number} [r = 0]
-- @param {number} [a = 0]
-- @param {number} [l = false]
-- @param {number} [s = false]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.helix(p,h,r,a,l,s,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.helix(p,h,r,a,l,s),color) 
end

-- Create a spiral
-- @param {number} [g = 0]
-- @param {number} [c = 0]
-- @param {number} [r = 0]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.spiral(g,c,r,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.spiral(g,c,r),color) 
end

-- Create a polygon
-- @param {number} [p = 6]
-- @param {number} [c = 2]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.polygon(p,c,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.polygon(p,c),color) 
end

-- Create a prism
-- @param {number} [p = 6]
-- @param {number} [c = 2]
-- @param {number} [h = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.prism(p,c,h,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.prism(p,c,h),color) 
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
function ShapeBuilder.wedge(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.wedge(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4),color) 
end

-- Create an ellipsoid
-- @param {number} [r1 = 2]
-- @param {number} [r2 = 4]
-- @param {number} [r3 = 0]
-- @param {number} [a1 = -90]
-- @param {number} [a2 = 90]
-- @param {number} [a3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._ellipsoid(r1, r2, r3, a1, a2, a3,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.ellipsoid(r1, r2, r3, a1, a2, a3),color) 
end
function ShapeBuilder.ellipsoid(r1, r2, r3, color) 
    ShapeBuilder._ellipsoid(r1, r2, r3, -90, 90, 360,color) 
end
-- Run boolean operator between two nodes
-- @param {NplOce.Node} node_1
-- @param {string} type - union|difference|intersection|section
-- @param {NplOce.Node} node_2
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
function ShapeBuilder.boolean(node_1,type,node_2,color) 
    if(not node_1 or not node_2)then
        return
    end
    type = type or "union"
    local model_1 = node_1:getDrawable();
    local model_2 = node_2:getDrawable();
    local shape_1 = model_1:getShape();
    local shape_2 = model_2:getShape();
    -- create a new shape
    local shape;
    if(type == "union")then
        shape = NplOce.union(shape_1,shape_2);
    elseif(type == "difference")then
        shape = NplOce.difference(shape_1,shape_2);
    elseif(type == "intersection")then
        shape = NplOce.intersection(shape_1,shape_2);
    elseif(type == "section")then
        shape = NplOce.section(shape_1,shape_2);
    end
    
    local parent_1 = node_1:getParent();
    parent_1:removeChild(node_1);
    local parent_2 = node_2:getParent();
    parent_2:removeChild(node_2);
    ShapeBuilder.addShape(shape,color);
end

-- Mirror a node
-- @param {number} [x = 0]
-- @param {number} [y = 0]
-- @param {number} [z = 0]
-- @param {number} [dir_x = 0]
-- @param {number} [dir_y = 0]
-- @param {number} [dir_z = 0]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.mirror(node,x,y,z,dir_x,dir_y,dir_z,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    local model = node:getDrawable();
    local shape = model:getShape();
    return ShapeBuilder.addShape(NplOce.mirror(shape, {x,y,z}, {dir_x,dir_y,dir_z}),color) 
end

-- Set node's color
-- @param {NplOce.Node} node
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
function ShapeBuilder.setColor(node,color)
    if(not node)then
        return
    end 
    color = color or {r = 1, g = 0, b = 0, a = 1,}
    local model = node:getDrawable();
    if(model and model.setColor)then
        color = ShapeBuilder.converColorToRGBA(color);
        model:setColor(color.r,color.g,color.b,color.a);
    end
end
-- Convert from color string to rgba table, if the type of color is table return color directly
-- @param {string} color - can be "#ffffff" or "#ffffffff" with alpha
-- @return {object} color
-- @return {number} color.r - [0-1]
-- @return {number} color.g - [0-1]
-- @return {number} color.b - [0-1]
-- @return {number} color.a - [0-1]
function ShapeBuilder.converColorToRGBA(color) 
    if(not color)then
        return
    end
    if(type(color) == "table")then
        return color;
    end
    if(type(color) == "string")then
        local dword = Color.ColorStr_TO_DWORD(color);
        local r, g, b, a = Color.DWORD_TO_RGBA(dword);
        r = r/255;
        g = g/255;
        b = b/255;
        a = a/255;

        local v = {
            r = r,
            g = g,
            b = b,
            a = a,
        }
        return v;
    end
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
        node:translate(x,y,z);
    end
end

-- Scale the node
-- @param {NplOce.Node} node
-- @param {number} [x = 1]
-- @param {number} [y = 1]
-- @param {number} [z = 1]
function ShapeBuilder.setScale(node,x,y,z)
    if(node)then
        node:setScale(x,y,z);
    end
end

-- Scales this node's scale by the given factors along each axis
-- @param {number} [x = 1]
-- @param {number} [y = 1]
-- @param {number} [z = 1]
function ShapeBuilder.scale(node,x,y,z)
    if(node)then
        node:scale(x,y,z);
    end
end

-- Rotate the node
-- @param {NplOce.Node} node
-- @param {number} [x = 0]
-- @param {number} [y = 0]
-- @param {number} [z = 0]
-- @param {number} [angle = 0] - degree
function ShapeBuilder.setRotation(node,x,y,z,angle)
    if(node)then
        angle = 3.1415926* angle/180
        node:setRotation(x,y,z,angle);
    end
end

-- fake function to make code readable on block
function ShapeBuilder.createShape(node)
 
end


function ShapeBuilder.beginTranslation(x,y,z) 
    local node = ShapeBuilder.beginNode();
    ShapeBuilder.setTranslation(node,x,y,z) 
end
function ShapeBuilder.endTranslation() 
    ShapeBuilder.endNode();
end
function ShapeBuilder.beginScale(x,y,z) 
    local node = ShapeBuilder.beginNode();
    ShapeBuilder.setScale(node,x,y,z) 
end
function ShapeBuilder.endScale() 
    ShapeBuilder.endNode();
end
function ShapeBuilder.beginRotation(x,y,z,angle) 
    local node = ShapeBuilder.beginNode();
    ShapeBuilder.setRotation(node,x,y,z,angle) 
end
function ShapeBuilder.endRotation() 
    ShapeBuilder.endNode();
end

-- Create a new node on current level and set operation
-- @param {string} op - "union" or "difference" or "intersection"
-- @param {string} - "#f0000"
function ShapeBuilder.beginBoolean(op,color) 
    local node = ShapeBuilder.beginNode();
    node:_setOp(op);
    if(color)then
        color = ShapeBuilder.converColorToRGBA(color);
        node:_setColor(color);
    end
end
function ShapeBuilder.endBoolean() 
    ShapeBuilder.endNode();
end