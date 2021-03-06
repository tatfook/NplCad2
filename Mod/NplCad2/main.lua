﻿--[[
Title: 
Author(s): leio
Date: 2019/1/18
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/NplCad2/main.lua");
------------------------------------------------------------
]]
local CmdParser = commonlib.gettable("MyCompany.Aries.Game.CmdParser");	

local NplCad2 = commonlib.inherit(commonlib.gettable("Mod.ModBase"),commonlib.gettable("Mod.NplCad2"));

function NplCad2:ctor()
end

-- virtual function get mod name
function NplCad2:GetName()
	return "NplCad2"
end

-- virtual function get mod description 
function NplCad2:GetDesc()
	return "NplCad2 is a plugin in paracraft"
end

function NplCad2:init()
	LOG.std(nil, "info", "NplCad2", "plugin initialized");

	-- register a new block item, id < 10512 is internal items, which is not recommended to modify. 
	GameLogic.GetFilters():add_filter("block_types", function(xmlRoot) 
		local blocks = commonlib.XPath.selectNode(xmlRoot, "/blocks/");
		if(blocks) then
            -- NPL CAD v2.0 with Code Block
			NPL.load("(gl)Mod/NplCad2/ItemCADCodeBlock.lua");
			blocks[#blocks+1] = {name="block", attr={ name="NPLCADCodeBlock",
				id = 10513, item_class="ItemCADCodeBlock", text=L"npl block cad 代码模型",
				icon = "Mod/NplCad2/textures/icon.png",
			}}
			LOG.std(nil, "info", "NplCad2", "npl block cad  is registered");
            
		end
		return xmlRoot;
	end)

	-- add block to category list to be displayed in builder window (E key)
	GameLogic.GetFilters():add_filter("block_list", function(xmlRoot) 
		for node in commonlib.XPath.eachNode(xmlRoot, "/blocklist/category") do
			if(node.attr.name == "tool" or node.attr.name == "character") then
				node[#node+1] = {name="block", attr={name="NPLCADCodeBlock"} };
			end
		end
		return xmlRoot;
	end)
end

function NplCad2:OnLogin()
end
-- called when a new world is loaded. 

function NplCad2:OnWorldLoad()
end
-- called when a world is unloaded. 

function NplCad2:OnLeaveWorld()
end

function NplCad2:OnDestroy()
end



