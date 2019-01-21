--[[
Title: NplOceConnection
Author(s): leio
Date: 2018/9/28
Desc: Connect "nploce.dll" 
use the lib:
------------------------------------------------------------
--using nploce_d.dll
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce/nploce_d.dll", activate_callback = "Mod/NplCad2/NplOceConnection.lua", },function(msg)
	local cube = NplOce.cube(1,2,3);
    commonlib.echo(cube:IsNull());
    commonlib.echo(cube:ShapeType());
end);

--using nploce.dll
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce/nploce.dll", activate_callback = "Mod/NplCad2/NplOceConnection.lua", },function(msg)
    local NplOceScene = NPL.load("Mod/NplCad2/NplOceScene.lua");
    local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
    ShapeBuilder.create();
    ShapeBuilder.cube(1,1,1);
    NplOceScene.saveSceneToParaX("test/test.cube.x",ShapeBuilder.getScene());
end);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/math/bit.lua");

local NplOceConnection = NPL.export();
NplOceConnection.is_loaded = false;
-- Install dll
-- @param {table} options
-- @param {string} [options.npl_oce_dll = "plugins/nploce/nploce_d.dll"] - the location of dll
-- @param {string} [options.activate_callback = "Mod/NplOce/NplOceConnection.lua"] - the location of be actived
function NplOceConnection.load(options,callback)
    if(NplOceConnection.is_loaded)then
        if(callback)then
            callback(true);
        end
        return
    end
	NplOceConnection.callback = callback;
    local npl_oce_dll = options.npl_oce_dll or "plugins/nploce/nploce_d.dll"
	local activate_callback = options.activate_callback or "Mod/NplCad2/NplOceConnection.lua";
    local lua_state = NPL.GetLuaState("",{});
    local high = lua_state.high or 0;
    local low = lua_state.low or 0;
    local value = mathlib.bit.lshift(high, 32);
    value = mathlib.bit.bor(value, low);
	if(value == 0)then
		LOG.std(nil, "error", "NplOceConnection", "lua state is wrong.\n");
		return
	end
	NPL.activate(npl_oce_dll, { lua_state = value, callback = activate_callback});
end
local function activate()
	if(msg and msg.successful)then
        if(not NplOceConnection.is_loaded)then
            NplOceConnection.is_loaded = true;

            NPL.load("Mod/NplCad2/NplOce_Internal.lua");

            if(NplOceConnection.callback)then
                NplOceConnection.callback(true);
            end
		end
	end
end
NPL.this(activate);