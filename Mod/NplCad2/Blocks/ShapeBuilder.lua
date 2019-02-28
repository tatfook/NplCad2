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
local NplOceScene = NPL.load("Mod/NplCad2/NplOceScene.lua");
NPL.load("(gl)script/ide/System/Core/Color.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Color = commonlib.gettable("System.Core.Color");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");

local ShapeBuilder = NPL.export();
ShapeBuilder.Precision_Confusion = 0.0000001
ShapeBuilder.scene = nil;
ShapeBuilder.root_node = nil; 
ShapeBuilder.cur_node = nil; -- for boolean/add node
ShapeBuilder.selected_node = nil; -- for transforming node
ShapeBuilder.y_up = nil; 
ShapeBuilder.print_dialog = nil; 

function ShapeBuilder.print3d(v)
    ShapeBuilder.print_dialog = v; 
end
function ShapeBuilder.getPrint3d()
    return ShapeBuilder.print_dialog;
end
function ShapeBuilder.setYUp(v)
    ShapeBuilder.y_up = v; 
end
function ShapeBuilder.swapYZ(y,z)
    if(ShapeBuilder.y_up)then
        return z,y;
    else
        return y,z;
    end
end
function ShapeBuilder.createNode(name,color,bOp)
    local name = name or ShapeBuilder.generateId();
    local node = NplOce.Node.create(name);
    NplOce._setOp(node, tostring(bOp))
    local color = ShapeBuilder.converColorToRGBA(color) or { r = 1, g = 0, b = 0, a = 1 };
    NplOce._setColor(node,color)

    ShapeBuilder.getRootNode():addChild(node)
    ShapeBuilder.cur_node = node;
    return node
end
function ShapeBuilder.cloneNodeByName(op,name,color)
    local node = ShapeBuilder.getRootNode():findNode(name);
    if(node)then
        local cloned_node = NplOceScene.cloneNode(node,color,op)
        ShapeBuilder.selected_node = cloned_node;
        return cloned_node
    end
end
function ShapeBuilder.cloneNode(op,color)
    local node = ShapeBuilder.selected_node;
    if(node)then
        local cloned_node = NplOceScene.cloneNode(node,color,op)
        ShapeBuilder.selected_node = cloned_node;
        return cloned_node
    end
end
function ShapeBuilder.deleteNode(name)
    local node = ShapeBuilder.getRootNode():findNode(name);
    if(node)then
        if(node == ShapeBuilder.cur_node or node == ShapeBuilder.selected_node )then
            return
        end
        local parent = node:getParent();
        parent:removeChild(node);
    end
end

function ShapeBuilder.move(x,y,z)
    local node = ShapeBuilder.getSelectedNode();
    local child = node:getFirstChild();

    ShapeBuilder.translate(child,x,y,z);
end

function ShapeBuilder.rotate(axis,angle)
    ShapeBuilder.setRotation(ShapeBuilder.getSelectedNode(),axis,angle)
end
function ShapeBuilder.rotateFromPivot(axis,angle,pivot_x,pivot_y,pivot_z)
    ShapeBuilder.setRotation(ShapeBuilder.getSelectedNode(),axis,angle,pivot_x or 0,pivot_y or 0,pivot_z or 0)
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
function ShapeBuilder.create(zup)
    ShapeBuilder.scene = NplOce.Scene.create();
    ShapeBuilder.setYUp(not zup)
    ShapeBuilder.cur_node = ShapeBuilder.scene:addNode(ShapeBuilder.generateId());
    ShapeBuilder.root_node = ShapeBuilder.cur_node; 
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
function ShapeBuilder.addShape(shape,color,op) 
    if(not shape)then
        return
    end
    local cur_node = ShapeBuilder.getCurNode();
    if(cur_node)then
        color = ShapeBuilder.converColorToRGBA(color);
        color = color or { r = 1, g = 0, b = 0, a = 1 };
        local model = NplOce.TopoModel.create(shape,color.r,color.g,color.b,color.a);
        local child_node = NplOce.Node.create(ShapeBuilder.generateId());
        child_node:setDrawable(model);

        local node = NplOce.Node.create(ShapeBuilder.generateId());
        node:addChild(child_node);

        NplOce._setColor(node,color)
        NplOce._setBooleanOp(node,op)
        cur_node:addChild(node);
        ShapeBuilder.selected_node = node;
        return node;
    end
    
end
-- Create a cube
function ShapeBuilder.cube(op,size,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    local shape = NplOce.cube(size,size,size);
    local node = ShapeBuilder.addShape(shape,color,op) 
    shape:translate(-size/2,-size/2,-size/2);
    return node;
end
-- Create a box
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.box(op,x,y,z,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    local shape = NplOce.cube(x,y,z);
    local node = ShapeBuilder.addShape(shape,color,op) 
    shape:translate(-x/2,-y/2,-z/2);
    return node;
end

-- Create a cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cylinder(op,radius,height,angle,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    radius = math.max(radius,ShapeBuilder.Precision_Confusion);
    local shape = NplOce.cylinder(radius,height,angle);
    shape:translate(0,0,-height/2);
    return ShapeBuilder.addShape(shape,color,op) 
end
function ShapeBuilder.cylinder(op,radius,height,color) 
    ShapeBuilder._cylinder(op,radius,height,360,color);
end

-- Create a sphere
-- @param {number} [radius = 5]
-- @param {number} [angle1 = -90]
-- @param {number} [angle2 = 90]
-- @param {number} [angle3 = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._sphere(op,radius,angle1,angle2,angle3,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    radius = math.max(radius,ShapeBuilder.Precision_Confusion);
    local shape = NplOce.sphere(radius,angle1,angle2,angle3);
    shape:translate(0,0,0);
    return ShapeBuilder.addShape(shape,color,op) 
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
    color = ShapeBuilder.converColorToRGBA(color);
    top_radius = math.max(top_radius,ShapeBuilder.Precision_Confusion);
    bottom_radius = math.max(bottom_radius,ShapeBuilder.Precision_Confusion);
    local shape = NplOce.cone(top_radius,bottom_radius,height,angle);
    shape:translate(0,0,-height/2);
    return ShapeBuilder.addShape(shape,color,op) 
end
function ShapeBuilder.cone(op,top_radius,bottom_radius,height,color,op) 
    ShapeBuilder._cone(op,top_radius,bottom_radius,height,360,color,op);
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
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.torus(radius1,radius2,angle1,angle2,angle3),color,op) 
end
function ShapeBuilder.torus(op,radius1,radius2,color) 
    ShapeBuilder._torus(op,radius1,radius2,-180,180,360,color);
end

-- Create a prism
-- @param {number} [p = 6]
-- @param {number} [c = 2]
-- @param {number} [h = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.prism(op,p,c,h,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    p = math.max(p,3);
    local shape = NplOce.prism(p,c,h);
    shape:translate(0,0,-h/2);
    return ShapeBuilder.addShape(shape,color,op) 
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
    local z4 = ShapeBuilder.Precision_Confusion;

    color = ShapeBuilder.converColorToRGBA(color);
    local shape = NplOce.wedge(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
    shape:translate(-x/2,-h/2,-z/2);
    return ShapeBuilder.addShape(shape,color,op);
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
    color = ShapeBuilder.converColorToRGBA(color);
    local shape = NplOce.wedge(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
    return ShapeBuilder.addShape(shape,color,op) 
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
function ShapeBuilder._ellipsoid(op,r1, r2, r3, a1, a2, a3,color) 
    color = ShapeBuilder.converColorToRGBA(color);
    return ShapeBuilder.addShape(NplOce.ellipsoid(r1, r2, r3, a1, a2, a3),color,op) 
end
function ShapeBuilder.ellipsoid(op,r1, r2, r3, color) 
    ShapeBuilder._ellipsoid(op,r1, r2, r3, -90, 90, 360,color) 
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
    local shape = NplOce.plane(l,w);
    shape:translate(-l/2,-w/2,0);
    return ShapeBuilder.addShape(shape,color) 
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
    if(color == "" or color == "none" or color == "nil")then
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
        y,z = ShapeBuilder.swapYZ(y,z);
        node:setTranslation(x,y,z);
    end
end

-- Translates this node's translation by the given values along each axis
-- @param {number} [tx = 0]
-- @param {number} [ty = 0]
-- @param {number} [tz = 0]
function ShapeBuilder.translate(node,tx,ty,tz)
    if(node)then
        ty,tz = ShapeBuilder.swapYZ(ty,tz);
        node:translate(tx,ty,tz);
    end
end

-- Scale the node
-- @param {NplOce.Node} node
-- @param {number} [x = 1]
-- @param {number} [y = 1]
-- @param {number} [z = 1]
function ShapeBuilder.setScale(node,x,y,z)
    if(node)then
        y,z = ShapeBuilder.swapYZ(y,z);
        node:setScale(x,y,z);
    end
end


-- Rotate the node
-- @param {NplOce.Node} node
-- @param {string} axis - "x" or "y" or "z"
-- @param {number} [angle = 0] - degree
-- @param {number} [pivot_x = 0]
-- @param {number} [pivot_y = 0]
-- @param {number} [pivot_z = 0]
function ShapeBuilder.setRotation(node,axis,angle,pivot_x,pivot_y,pivot_z)
    if(node)then

        angle = angle or 0;
        local from_pivot = true;
        if(pivot_x == nil and pivot_y == nil and pivot_z == nil)then
            from_pivot = false;
        end
        
        pivot_y,pivot_z = ShapeBuilder.swapYZ(pivot_y,pivot_z);
        local rotate_matrix;
        if(axis == "x")then
            rotate_matrix = Matrix4.rotationX(angle);
        end
        if(axis == "y")then
            if(ShapeBuilder.y_up)then
                rotate_matrix = Matrix4.rotationZ(angle);
            else
                rotate_matrix = Matrix4.rotationY(angle);
            end
        end
        if(axis == "z")then
            if(ShapeBuilder.y_up)then
                rotate_matrix = Matrix4.rotationY(angle);
            else
                rotate_matrix = Matrix4.rotationZ(angle);
            end
        end

        NplOceScene.visitNode(node,function(child)
            local drawable = child:getDrawable();
            if(drawable)then

                local shape = drawable:getShape();
                if(shape)then
                    if(from_pivot)then

                        local w_matrix = NplOceScene.drawableTransform(drawable,node);
                        local pos_x = pivot_x - w_matrix[13];
                        local pos_y = pivot_y - w_matrix[14];
                        local pos_z = pivot_z - w_matrix[15];

                        local shape_matrix = Matrix4:new(shape:getMatrix());
                        local matrix_1 = Matrix4.translation({-pos_x,-pos_y,-pos_z})
                        local matrix_2 = Matrix4.translation({pos_x,pos_y,pos_z})

                        local transformMatrix = shape_matrix * matrix_1 * rotate_matrix * matrix_2;
                        shape:setMatrix(transformMatrix);

                    else
                        local shape_matrix = Matrix4:new(shape:getMatrix());
                        local transformMatrix = shape_matrix * rotate_matrix;
                        shape:setMatrix(transformMatrix);
                        
                    end
                    

                end
            end
        end)
    end
end
