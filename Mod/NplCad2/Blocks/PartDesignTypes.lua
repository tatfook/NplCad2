--[[
Title: PartDesignTypes
Author(s): leio
Date: 2021/6/14
Desc: 
use the lib:
------------------------------------------------------------
local PartDesignTypes = NPL.load("Mod/NplCad2/Blocks/PartDesignTypes.lua");
------------------------------------------------------------
--]]
local PartDesignTypes = NPL.export();

PartDesignTypes.ExtrudeType = {
	solid_new = "solid_new",
    solid_add = "solid_add",
    solid_remove = "solid_remove",
    solid_intersect = "solid_intersect",

    surface_new = "surface_new",
    surface_add = "surface_add",
}

PartDesignTypes.ExtrudeDirection = {
	blind = "blind",
    symmetric = "symmetric",
    throughall = "throughall"
}

PartDesignTypes.SketchPlane = {
	front = "front",
    back = "back",
    top = "top",
    bottom = "bottom",
    left = "left",
    right = "right",
}


PartDesignTypes.ChamferDistanceType = {
	equal_distance = "equal_distance",
	two_distances = "two_distances",
    distance_and_angle = "distance_and_angle",
}

PartDesignTypes.TopAbs_Orientation = {
	TopAbs_FORWARD = 0,
    TopAbs_REVERSED = 1,
    TopAbs_INTERNAL = 2,
    TopAbs_EXTERNAL = 3
}