--[[
Title: NplOceSceneDoc
Author(s): leio
Date: 2018/12/5
Desc: The documnet of NplOce 
use the lib:
--]]
local NplOce = {};
NplOce.NPL_TopoDS_Shape = {};
NplOce.Mesh = {};
NplOce.Model = {};
NplOce.Scene = {};
NplOce.Node = {};


-- Create a scene
-- @param {string} [id = ""]
-- @return {NplOce.Scene} scene
-- @example
-- --export a scene
--  local filename = "test/cube.json";
--  local cube = NplOce.cube();
--  local mesh = NplOce.Mesh.create(cube);
--  local model = NplOce.Model.create(mesh);
--  local scene = NplOce.Scene.create();
--  local node = scene:addNode("cube");
--  node:setDrawable(model);
--  local s = scene:toJson(4);

--	ParaIO.CreateDirectory(filename);
--  local file = ParaIO.open(filename, "w");
--	if(file:IsValid()) then
--		file:WriteString(s);
--		file:close();
--	end
function NplOce.Scene.create(id)
end

-- Create a node 
-- @param {string} [id = ""]
-- @return {NplOce.Node} node
function NplOce.Scene:addNode(id)
end

-- Export the scene to json string
-- @param {number} [indent = -1]
-- @return {string} v
function NplOce.Scene:toJson(indent)
end

-- Get the next child
-- @return {NplOce.Node}
function NplOce.Scene:getNext()
end

-- Get the number of nodes at the root level of the scene.
-- @return {number}
function NplOce.Scene:getNodeCount()
end

-- Get the first child
-- @return {NplOce.Node}
function NplOce.Scene:getFirstNode()
end

-- Create a node
-- @param {string} [id = ""]
-- @return {NplOce.Node} node
function NplOce.Node.create(id)
end

-- Get the parent node
-- @param {NplOce.Node}
function NplOce.Node:getParent()
end

-- Add a child node
-- @param {NplOce.Node} child
function NplOce.Node:addChild(child)
end

-- Remove a child node
-- @param {NplOce.Node} child
function NplOce.Node:removeChild(child)
end

-- Attach the model object
-- @param {NplOce.TopoModel} model
function NplOce.Node:setDrawable(model)
end

-- Get the model object 
-- @return {NplOce.TopoModel} model
function NplOce.Node:getDrawable()
end

-- Sets the translation node to the specified values
-- @param {number} [x = 0]
-- @param {number} [y = 0]
-- @param {number} [z = 0]
function NplOce.Node:setTranslation(x,y,z)
end

-- Translates this node's translation by the given values along each axis
-- @param {number} [tx = 0]
-- @param {number} [ty = 0]
-- @param {number} [tz = 0]
function NplOce.Node:translate(tx,ty,tz)
end

-- Rotate the node
-- @param {number} [x = 0] - The axis x value
-- @param {number} [y = 0] - The axis y value
-- @param {number} [z = 0] - The axis z value
-- @param {number} [angle = 0] - in radians
function NplOce.Node:setRotation(x,y,z,angle)
end

-- Rotates this node's rotation by the given rotation
-- @param {number} [x = 0] - The axis x value
-- @param {number} [y = 0] - The axis y value
-- @param {number} [z = 0] - The axis z value
-- @param {number} [angle = 0] - in radians
function NplOce.Node:rotate(x,y,z,angle)
end

-- Scale the node
-- @param {number} [x = 1]
-- @param {number} [y = 1]
-- @param {number} [z = 1]
function NplOce.Node:setScale(x,y,z)
end

-- Scales this node's scale by the given factors along each axis
-- @param {number} [x = 1]
-- @param {number} [y = 1]
-- @param {number} [z = 1]
function NplOce.Node:scale(x,y,z)
end

-- Get the first child for this node
-- @return {NplOce.Node}
function NplOce.Node:getFirstChild()
end

-- Get the id of this node
-- @return {string}
function NplOce.Node:getId()
end

-- Set the id for this node
-- @param {string} id
function NplOce.Node:setId(id)
end



-- Get the number of child of this node
-- @return {number}
function NplOce.Node:getChildCount()
end

-- Get the number of child of this node
-- @return {number}
function NplOce.Node:getChildCount()
end

-- Create a model
-- @param {NplOce.Mesh} mesh
-- @return {NplOce.Model} model
function NplOce.Model.create(mesh)
end

-- Create a mesh with shape and color
-- @param {NPL_TopoDS_Shape} shape
-- @param {number} [r = 0] - The value of red, the range is [0-1]
-- @param {number} [g = 0] - The value of green, the range is [0-1]
-- @param {number} [b = 0] - The value of blue, the range is [0-1]
-- @param {number} [a = 0] - The value of alpha, the range is [0-1]
-- @return {NplOce.Mesh} mesh
function NplOce.Mesh.create(shape,r,g,b,a)
end

-- Create a topo model
-- @param {NPL_TopoDS_Shape} shape
-- @param {number} [r = 0] - The value of red, the range is [0-1]
-- @param {number} [g = 0] - The value of green, the range is [0-1]
-- @param {number} [b = 0] - The value of blue, the range is [0-1]
-- @param {number} [a = 0] - The value of alpha, the range is [0-1]
-- @return {NplOce.TopoModel} model
function NplOce.TopoModel.create(shape,r,g,b,a)
end

-- Generate a mesh
-- @return {NplOce.Mesh} mesh
function NplOce.TopoModel:generateMesh()
end

-- Set shape
-- @param {NPL_TopoDS_Shape} shape
function NplOce.TopoModel:setShape(shape)
end

-- Get shape
-- @return {NPL_TopoDS_Shape} shape
function NplOce.TopoModel:getShape()
end

-- Set color
-- @param {number} [r = 0] - The value of red, the range is [0-1]
-- @param {number} [g = 0] - The value of green, the range is [0-1]
-- @param {number} [b = 0] - The value of blue, the range is [0-1]
-- @param {number} [a = 0] - The value of alpha, the range is [0-1]
function NplOce.TopoModel:setColor(r,g,b,a)
end

