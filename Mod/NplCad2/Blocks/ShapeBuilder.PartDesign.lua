--[[
Title: ShapeBuilder extended for PartDesign
Author(s): leio
Date: 2021/6/14
Desc: 
NOTE: don't include this file
------------------------------------------------------------
NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.PartDesign.lua");
------------------------------------------------------------
--]]
local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
local PartDesignTypes = NPL.load("Mod/NplCad2/Blocks/PartDesignTypes.lua");

--[[
local types = { "edges", "faces", "shells", "solids", }
local lineDeflection = 0.5
local angularDeflection = 0.5

cube("union",1,"#ffc658")
findAllToposByName(nil, types, lineDeflection, angularDeflection)
cylinder("union",1,10,"#ffc658")
findAllToposByName(nil, types, lineDeflection, angularDeflection)
--]]
function ShapeBuilder.findAllToposByName(name, types, lineDeflection, angularDeflection)
	local node;
	if(not name)then
		node = ShapeBuilder.getSelectedNode();
	else
		node = ShapeBuilder.getRootNode():findNode(name);
	end
	return ShapeBuilder.findAllTopos_Node(node, types, lineDeflection, angularDeflection);
end
-- find all topology data which is a serialized json object
-- @param node: a ShapeNode which attached a topo_shape
-- @param types: a table which hold "edges|wires|faces|shells|solids"
-- @param lineDeflection: default value is 0.5
-- @param angularDeflection: default value is 0.5
function ShapeBuilder.findAllTopos_Node(node, types, lineDeflection, angularDeflection)
	if(not node)then
		return
	end
	types = types or { "edges", "faces", "shells", "solids", };
	if(lineDeflection == nil)then
		lineDeflection = 0.5;
	end
	if(angularDeflection == nil)then
		angularDeflection = 0.5;
	end
	local model = node:getDrawable();
	if (model ~= nil) then
		local shape = model:getShape();
		if (shape ~= nil) then
			local s = NplOce.TopoExplorer_findAllToposToString(shape, types, lineDeflection, angularDeflection);
			
			local out={};
			if(NPL.FromJson(s, out)) then
				commonlib.echo("================findAllToposToJson");
				commonlib.echo(out,true);
				return out;
			end
		end
	end
end
----------------------------------------------------------onExtrude
function ShapeBuilder.onExtrude(input, color)
	local node = ShapeBuilder.getSelectedNode();
	return ShapeBuilder.onExtrude_Node(node, input, color);
end
function ShapeBuilder.onExtrude_Node(node, input, color)
	if(not node)then
		return
	end
	if(type(input) == "string")then
		local out={};
		if(NPL.FromJson(json, out)) then
			input = out;
		end	
	end
	input = input or {};
	input.type = input.type or PartDesignTypes.ExtrudeType.solid_add;
	if(input.type == PartDesignTypes.ExtrudeType.solid_add)then
		return ShapeBuilder.onExtrudeToSolid_Node(node, input, color)
	elseif(input.type == PartDesignTypes.ExtrudeType.surface_new)then
		return ShapeBuilder.onExtrudeToSurface_Node(node, input, color)
	end
end
function ShapeBuilder.onExtrudeToSolid_Node(node, input)
	if(not node)then
		return
	end
	input = input or {};
	local faces = input.faces;
	local depth = input.depth;
	local direction = input.direction;
	local opposite = input.opposite;
end
function ShapeBuilder.onExtrudeToSurface_Node(node, input)
end
----------------------------------------------------------onExtrude
--[[
-- extrude by face id and orientation
cube("union",1,"#ffc658")
local topos = findAllToposByName()
onExtrude(
{
    type = "solid_add",
    faces = {
		topos.faces[1],
    },
	depth = 3, 
	direction = "blind",

},"#ff0000")
move(0,3,0)

-- extrude by face index
cube("union",1,"#ffc658")
local topos = findAllToposByName()
onExtrude(
{
    type = "solid_add",
    faces = {
		{index = 1,},
    },
	depth = 3, 
	direction = "blind",

},"#ff0000")
move(0,3,0)
--]]
-- chamfer shape
-- @param input: string or table
-- @param color: color for new shape
function ShapeBuilder.onExtrude(input, color)
	local node = ShapeBuilder.getSelectedNode();
	return ShapeBuilder.TopoOperation_onRun("onExtrude", node, input, color);
end

--[[
-- chamfer by edge id and orientation
cube("union",1,"#ffc658")
local topos = findAllToposByName()
onChamfer(
{
    type = "two_distances",
    edges = {
		topos.edges[1],
		topos.edges[5],
		topos.edges[6],
    },
    distance1 = 0.2,
    distance2 = 0.2,
},"#ff0000")
move(0,3,0)


-- chamfer by edge index
cube("union",1,"#ffc658")
onChamfer(
{
    type = "two_distances",
    edges = {
		{ index = 1, },
		{ index = 5, },
		{ index = 6, },
    },
    distance1 = 0.2,
    distance2 = 0.2,
},"#ff0000")
move(0,3,0)

--]]
-- chamfer shape
-- @param input: string or table
-- @param color: color for new shape
function ShapeBuilder.onChamfer(input, color)
	local node = ShapeBuilder.getSelectedNode();
	return ShapeBuilder.TopoOperation_onRun("onChamfer", node, input, color);
end

--[[
-- fillet by edge id and orientation
cube("union",1,"#ffc658")
local topos = findAllToposByName()
onFillet(
{
    type = "edge_circular",
    edges = {
		topos.edges[1],
		topos.edges[5],
		topos.edges[6],
    },
    radius = 0.2,
},"#ff0000")
move(0,3,0)


-- fillet by edge index
cube("union",1,"#ffc658")
onFillet(
{
    type = "edge_circular",
    edges = {
		{ index = 1, },
		{ index = 5, },
		{ index = 6, },
    },
    radius = 0.2,
},"#ff0000")
move(0,3,0)

--]]
-- chamfer shape
-- @param input: string or table
-- @param color: color for new shape
function ShapeBuilder.onFillet(input, color)
	local node = ShapeBuilder.getSelectedNode();
	return ShapeBuilder.TopoOperation_onRun("onFillet", node, input, color);
end

function ShapeBuilder.TopoOperation_onRun(action, node, input, color)
	if(not node or not input)then
		return
	end
	if(type(input) == "table")then
		input = NPL.ToJson(input)
	end

	local model = node:getDrawable();
	if (model ~= nil) then
		local shape = model:getShape();
		local shape_result = NplOce.TopoOperation_onRun(action, shape, input);
		local node_result = ShapeBuilder.createNodeByTopoShape(shape_result);
		if(node_result)then
			return ShapeBuilder.addShapeNode(node_result, nil, color);
		end
	end
end

function ShapeBuilder.createNodeByTopoShape(shape)
	if(not shape)then
		return
	end
	 local node = NplOce.ShapeNode.create();
    local model = NplOce.ShapeModel.create();
	model:setShape(shape);
    node:setDrawable(model);
	return node;
end