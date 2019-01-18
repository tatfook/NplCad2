--[[
Title: NplOceDoc
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

-- Create a cube
-- @param {number} [x = 10]
-- @param {number} [y = 10]
-- @param {number} [z = 10]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.cube(x,y,z) 
end

-- Create a cylinder
-- @param {number} [radius = 2]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.cylinder(radius,height,angle) 
end

-- Create a sphere
-- @param {number} [radius = 5]
-- @param {number} [angle1 = -90]
-- @param {number} [angle2 = 90]
-- @param {number} [angle3 = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.sphere(radius,angle1,angle2,angle3)
end
-- Create a cone
-- @param {number} [radius1 = 2]
-- @param {number} [radius2 = 4]
-- @param {number} [height = 10]
-- @param {number} [angle = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.cone(radius1,radius2,height,angle)
end

-- Create a torus
-- @param {number} [radius1 = 10]
-- @param {number} [radius2 = 2]
-- @param {number} [angle1 = -180]
-- @param {number} [angle2 = 180]
-- @param {number} [angle3 = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.torus(radius1,radius2,angle1,angle2,angle3)
end
-- Create a point
-- @param {number} [x = 0]
-- @param {number} [y = 0]
-- @param {number} [z = 0]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.point(x,y,z)
end
-- Create a line
-- @param {number} [x1 = 0]
-- @param {number} [y1 = 0]
-- @param {number} [z1 = 0]
-- @param {number} [x2 = 0]
-- @param {number} [y2 = 0]
-- @param {number} [z2 = 1]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.line(x1,y1,z1,x2,y2,z2)
end
-- Create a plane
-- @param {number} [length = 100]
-- @param {number} [width = 100]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.plane(length,width)
end

-- Create a circle
-- @param {number} [radius = 2]
-- @param {number} [angle0 = 0]
-- @param {number} [angle1 = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.circle(radius,angle0,angle1)
end

-- Create an ellipse
-- @param {number} [majorRadius = 4]
-- @param {number} [minorRadius = 4]
-- @param {number} [angle0 = 0]
-- @param {number} [angle1 = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.ellipse(majorRadius,minorRadius,angle0,angle1)
end

-- Create a polygon
-- @param {number} [polygon = 6]
-- @param {number} [circumradius = 2]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.polygon(polygon,circumradius)
end

-- Create a helix
-- @param {number} [pitch = 1]
-- @param {number} [height = 2]
-- @param {number} [radius = 1]
-- @param {number} [angle = 0]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.helix(pitch,height,radius,angle)
end

-- Create a spiral
-- @param {number} [growth = 1]
-- @param {number} [rotations = 2]
-- @param {number} [radius = 1]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.spiral(growth,rotations,radius)
end

-- Create a prism
-- @param {number} [polygon = 6]
-- @param {number} [circumradius = 2]
-- @param {number} [height = 10]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.prism(polygon,circumradius,height)
end

-- Create a wedge
-- @param {number} [xmin = 0]
-- @param {number} [ymin = 0]
-- @param {number} [zmin = 0]
-- @param {number} [x2min = 2]
-- @param {number} [z2min = 2]
-- @param {number} [xmax = 10]
-- @param {number} [ymax = 10]
-- @param {number} [zmax = 10]
-- @param {number} [x2max = 8]
-- @param {number} [z2max = 8]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.wedge(xmin,ymin,zmin,x2min,z2min,xmax,ymax,zmax,x2max,z2max)
end

-- Create an ellipsoid
-- @param {number} [radius1 = 2]
-- @param {number} [radius2 = 4]
-- @param {number} [radius3 = 0]
-- @param {number} [angle1 = -90]
-- @param {number} [angle2 = 90]
-- @param {number} [angle3 = 360]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.ellipsoid(radius1,radius2,radius3,angle1,angle2,angle3)
end

-- Create an edge from vertex
-- @param {NPL_TopoDS_Shape} shape1
-- @param {NPL_TopoDS_Shape} shape2
-- @return {NPL_TopoDS_Shape} shape
function NplOce.edge(shape1,shape2)
end

-- Create a face from edge
-- @param {number} dim
-- @param {array} shapes - the array of NPL_TopoDS_Shape
-- @param {boolean} [planar = false]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.face(dim,shapes,planar)
end

-- Create a shell from face
-- @param {number} dim
-- @param {array} shapes - the array of NPL_TopoDS_Shape
-- @param {boolean} [refine = false]
-- @param {boolean} [all = false]
-- @return {NPL_TopoDS_Shape} shape
function NplOce.shell(dim,shapes,refine,all)
end

-- Create a solid from shell
-- @param {NPL_TopoDS_Shape} shape
-- @return {NPL_TopoDS_Shape} shape
function NplOce.solid(shape)
end

-- Make union with two shapes
-- @param {NPL_TopoDS_Shape} shape1
-- @param {NPL_TopoDS_Shape} shape2
-- @return {NPL_TopoDS_Shape} shape
function NplOce.union(shape1,shape2)
end

-- Make difference with two shapes
-- @param {NPL_TopoDS_Shape} shape1
-- @param {NPL_TopoDS_Shape} shape2
-- @return {NPL_TopoDS_Shape} shape
function NplOce.difference(shape1,shape2)
end

-- Make intersection with two shapes
-- @param {NPL_TopoDS_Shape} shape1
-- @param {NPL_TopoDS_Shape} shape2
-- @return {NPL_TopoDS_Shape} shape
function NplOce.intersection(shape1,shape2)
end

-- Make section with two shapes
-- @param {NPL_TopoDS_Shape} shape1
-- @param {NPL_TopoDS_Shape} shape2
-- @return {NPL_TopoDS_Shape} shape
function NplOce.section(shape1,shape2)
end
-- TODO extrude
function NplOce.extrude()
end
-- TODO revolve
function NplOce.revolve()
end
-- Mirror a shape
-- @param {NPL_TopoDS_Shape} shape
-- @param {array} points - the array of point
-- @param {array} normals - the array of normal
-- @return {NPL_TopoDS_Shape} shape
function NplOce.mirror(shape,points,normals)
end
-- TODO fillet
function NplOce.fillet()
end
-- TODO chamfer
function NplOce.chamfer()
end
-- TODO surface
function NplOce.surface()
end
-- TODO loft
function NplOce.loft()
end
-- TODO sweep
function NplOce.sweep()
end
-- TODO offset
function NplOce.offset()
end
-- TODO thickness
function NplOce.thickness()
end
-- Create a shape with brep string
-- @param {string} s - the source of brep file
-- @return {NPL_TopoDS_Shape} shape
function NplOce.import(s)
end


