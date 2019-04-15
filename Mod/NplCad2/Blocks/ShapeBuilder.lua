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
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Color = commonlib.gettable("System.Core.Color");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");

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
    local node = NplOce.ShapeNode.create(name);
    node:setOpEnabled(bOp);
    node:setColor(ShapeBuilder.converColorToRGBA(color));

    ShapeBuilder.getRootNode():addChild(node)
    ShapeBuilder.cur_node = node;
    ShapeBuilder.selected_node = node;
    return node
end
function ShapeBuilder.cloneNodeByName(op,name,color)
    if(ShapeBuilder.isEmpty(name))then
        return
    end
    local node = ShapeBuilder.getRootNode():findNode(name);
    return ShapeBuilder._cloneNode(node,op,color)
end
function ShapeBuilder.cloneNode(op,color)
    return ShapeBuilder._cloneNode(ShapeBuilder.selected_node,op,color)
end
function ShapeBuilder._cloneNode(node,op,color)
    if(not node)then
        return
    end
    local cloned_node = node:clone();
    cloned_node:setOp(op);
    cloned_node:setColor(ShapeBuilder.converColorToRGBA(color));
    SceneHelper.clearNodesId(cloned_node)

    ShapeBuilder.cur_node:addChild(cloned_node);
    ShapeBuilder.selected_node = cloned_node;
    return cloned_node
end
function ShapeBuilder.deleteNode(name)
    if(ShapeBuilder.isEmpty(name))then
        return
    end
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
    ShapeBuilder.translate(node,x,y,z);
end
function ShapeBuilder.moveNode(name,x,y,z)
    if(ShapeBuilder.isEmpty(name))then
        return
    end
    local node = ShapeBuilder.getRootNode():findNode(name);
    if(node)then
        ShapeBuilder.translate(node,x,y,z);
    end
end

function ShapeBuilder.scale(x,y,z)
    local node = ShapeBuilder.getSelectedNode();
    ShapeBuilder.setScale(node,x,y,z);
end

function ShapeBuilder.rotate(axis,angle)
    ShapeBuilder.setRotationFromNode(ShapeBuilder.getSelectedNode(),axis,angle);
end
function ShapeBuilder.rotateNode(name,axis,angle)
    if(ShapeBuilder.isEmpty(name))then
        return
    end
    local node = ShapeBuilder.getRootNode():findNode(name);
    if(node)then
        ShapeBuilder.setRotationFromNode(node,axis,angle);
    end
end
-- Set rotation
-- @param {NplOce.ShapeNode} node
-- @param {string} axis - "x" or "y" or "z"
-- @param {number} angle -degree
function ShapeBuilder.setRotationFromNode(node,axis,angle)
    if(not node)then
        return
    end
    local x,y,z;
    angle = angle or 0;
    angle = angle * math.pi * (1.0 / 180.0);
    if(axis == "x")then
        x = 1;
        y = 0;
        z = 0;
    end
    if(axis == "y")then
        if(ShapeBuilder.y_up)then
            x = 0;
            y = 0;
            z = 1;
        else
            x = 0;
            y = 1;
            z = 0;
        end
    end
    if(axis == "z")then
        if(ShapeBuilder.y_up)then
            x = 0;
            y = 1;
            z = 0;
        else
            x = 0;
            y = 0;
            z = 1;
        end
    end
    node:setRotation(x,y,z,angle)
end
function ShapeBuilder.rotateFromPivot(axis,angle,pivot_x,pivot_y,pivot_z)
    ShapeBuilder.SetRotationFromPivot(ShapeBuilder.getSelectedNode(),axis,angle,pivot_x or 0,pivot_y or 0,pivot_z or 0)
end
function ShapeBuilder.rotateNodeFromPivot(name,axis,angle,pivot_x,pivot_y,pivot_z)
    if(ShapeBuilder.isEmpty(name))then
        return
    end
    local node = ShapeBuilder.getRootNode():findNode(name);
    if(node)then
        ShapeBuilder.SetRotationFromPivot(node,axis,angle,pivot_x or 0,pivot_y or 0,pivot_z or 0)
    end
end
-- Set rotation 
-- @param {NplOce.ShapeNode} node
-- @param {string} axis - "x" or "y" or "z"
-- @param {number} [angle = 0] - degree
-- @param {number} [pivot_x = 0]
-- @param {number} [pivot_y = 0]
-- @param {number} [pivot_z = 0]
function ShapeBuilder.SetRotationFromPivot(node,axis,angle,pivot_x,pivot_y,pivot_z)
    if(not node)then
        return
    end
    angle = angle or 0;
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
    local world_matrix = Matrix4:new(node:getWorldMatrix());
    local matrix_1 = Matrix4.translation({-pivot_x,-pivot_y,-pivot_z})
    local matrix_2 = Matrix4.translation({pivot_x,pivot_y,pivot_z})
    local world_transform_matrix = world_matrix * matrix_1 * rotate_matrix * matrix_2;

    local transform_matrix = world_transform_matrix;
    local parent = node:getParent();
    if(parent)then
        local parent_world_matrix = Matrix4:new(parent:getWorldMatrix());
        local inverse_matrix = parent_world_matrix:inverse();
		transform_matrix = Matrix4.__mul(world_transform_matrix,inverse_matrix);
    end
    node:setMatrix(transform_matrix);
end
function ShapeBuilder.mirrorNodeByName(name,axis_plane,x,y,z,color) 
    local node = ShapeBuilder.getRootNode():findNode(name);
    ShapeBuilder._mirrorNode(node,axis_plane,x,y,z,color);
end
function ShapeBuilder.mirrorNode(axis_plane,x,y,z,color) 
    local node = ShapeBuilder.getSelectedNode();
    ShapeBuilder._mirrorNode(node,axis_plane,x,y,z,color);
end
-- Mirror all of shapes in node
function ShapeBuilder._mirrorNode(node,axis_plane,x,y,z,color) 
    if(not node)then
        return
    end
    local dir_x,dir_y,dir_z = 0,0,0;
    if(axis_plane == "xy")then
        dir_x = 1;
        dir_y = 1;
    elseif(axis_plane == "xz")then
        dir_x = 1;
        dir_z = 1;
    elseif(axis_plane == "yz")then
        dir_y = 1;
        dir_z = 1;
    end
    y,z = ShapeBuilder.swapYZ(y,z);
    dir_y,dir_z = ShapeBuilder.swapYZ(dir_y,dir_z);

    local cloned_node = node:clone();
    cloned_node:setColor(ShapeBuilder.converColorToRGBA(color));
    SceneHelper.clearNodesId(cloned_node)
     SceneHelper.visitNode(cloned_node,function(node)
        local model = node:getDrawable();
        if(model)then
            local shape = model:getShape();
            if(shape)then
                shape = NplOce.mirror(shape, {x,y,z}, {dir_x,dir_y,dir_z})
                model:setShape(shape);
            end
        end
    end)

    ShapeBuilder.cur_node:addChild(cloned_node);
    ShapeBuilder.selected_node = cloned_node;
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

function ShapeBuilder.addShapeNode(node,op,color) 
    if(not node)then
        return
    end
    local cur_node = ShapeBuilder.getCurNode();
    if(cur_node)then
        node:setOp(op);
        node:setColor(ShapeBuilder.converColorToRGBA(color));
        cur_node:addChild(node);

        ShapeBuilder.selected_node = node;
    end
    return node;
end
-- Create a cube
function ShapeBuilder.cube(op,size,color) 
    local node = NplOce.ShapeNodeBox.create();
    node:setValue(size,size,size);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
end
-- Create a box
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.box(op,x,y,z,color) 
    local node = NplOce.ShapeNodeBox.create();
    node:setValue(x,y,z);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
end

-- Create a cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder._cylinder(op,radius,height,angle,color) 
    local node = NplOce.ShapeNodeCylinder.create();
    node:setValue(radius,height,angle);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
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
    local node = NplOce.ShapeNodeSphere.create();
    node:setValue(radius,angle1,angle2,angle3);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
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
    local node = NplOce.ShapeNodeCone.create();
    node:setValue(top_radius,bottom_radius,height,angle);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
end
function ShapeBuilder.cone(op,top_radius,bottom_radius,height,color) 
    ShapeBuilder._cone(op,top_radius,bottom_radius,height,360,color);
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
    local node = NplOce.ShapeNodeTorus.create();
    node:setValue(radius1,radius2,angle1,angle2,angle3);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
end
function ShapeBuilder.torus(op,radius1,radius2,color) 
    ShapeBuilder._torus(op,radius1,radius2,-180,180,360,color);
end

-- Create a prism
-- @param {number} [edges = 6]
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {object} [color = {r = 1, g = 0, b = 0, a = 1,}] - the range is [0-1]
-- @return {NplOce.Node} node
function ShapeBuilder.prism(op,edges, radius, height,color) 
    local node = NplOce.ShapeNodePrism.create();
    node:setValue(edges, radius, height);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
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


    local node = NplOce.ShapeNodeWedge.create();
    node:setValue(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
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
    local node = NplOce.ShapeNodeWedge.create();
    node:setValue(x1, y1, z1, x3, z3, x2, y2, z2, x4, z4);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
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
    local node = NplOce.ShapeNodeEllipsoid.create();
    node:setValue(r1, r2, r3, a1, a2, a3);
    ShapeBuilder.addShapeNode(node,op,color) 
    return node;
end
function ShapeBuilder.ellipsoid(op,r1, r2, r3, color) 
    ShapeBuilder._ellipsoid(op,r1, r2, r3, -90, 90, 360,color) 
end


-- Convert from color string to rgba table, if the type of color is table return color directly
-- @param {string} color - can be "#ffffff" or "#ffffffff" with alpha
-- @return {object} color
-- @return {number} color[1] - [0-1]
-- @return {number} color[2] - [0-1]
-- @return {number} color[3] - [0-1]
-- @return {number} color[4] - [0-1]
function ShapeBuilder.converColorToRGBA(color) 
    local default_color = {1,0,0,1};
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
        local dword = Color.ColorStr_TO_DWORD(color);
        local r, g, b, a = Color.DWORD_TO_RGBA(dword);
        r = r/255;
        g = g/255;
        b = b/255;
        a = a/255;

        local v = { r,g,b,a
        }
        return v;
    end
    return default_color;
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

-- TODO
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
function ShapeBuilder.isEmpty(s)
    if(s == nil or s == "")then
        return true;
    end
    return false;
end