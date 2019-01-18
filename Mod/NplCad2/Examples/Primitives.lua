--[[
Title: Test making primitives
Author(s): leio
Date: 2018/11/8
Desc: 
use the lib:
------------------------------------------------------------
local Primitives = NPL.load("Mod/NplCad2/Examples/Primitives.lua");
Primitives.cube();
------------------------------------------------------------
--]]
local Primitives = NPL.export();
function Primitives.saveToFile(filename,content)
    ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(content);
		file:close();
	end
end
function Primitives.saveShape(shape,position,color,filename)
    if(not shape or not filename)then
        return
    end
   
    local s = NplOce.exportSingleShape(shape,position,color)
    Primitives.saveToFile(string.format("nploce_test/%s.json",filename),s)

    local brep_str = shape:export()
    Primitives.saveToFile(string.format("nploce_test/%s.brep",filename),brep_str)
end
function Primitives.cube()
	local shape = NplOce.cube();
    Primitives.saveShape(shape,position,color,"cube")
end

