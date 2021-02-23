--[[
Title: NplOceConnection
Author(s): leio
Date: 2018/9/28
Desc: Connect "nploce.dll" 
use the lib:
------------------------------------------------------------
--using nploce_d.dll
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce_d.dll", activate_callback = "Mod/NplCad2/NplOceConnection.lua", },function(msg)
	local cube = NplOce.cube(1,2,3);
    commonlib.echo(cube:IsNull());
    commonlib.echo(cube:ShapeType());
end);

--using nploce.dll
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce.dll", activate_callback = "Mod/NplCad2/NplOceConnection.lua", },function(msg)
    
end);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/math/bit.lua");
NPL.load("(gl)script/ide/System/os/os.lua");

local function NplOce_StaticLoad()

	local function check_C_func(func_name)
		local func = loadstring([[local ffi = require("ffi"); local func = ffi.C.]]..func_name);
		if(func) then
			local result, msg = pcall(func);
			if(result) then
				return true;
			end
		end
	end

	if jit and jit.version then
		local ffi = require("ffi");
		ffi.cdef([[
			bool NplOce_StaticLoad(void* pLuaState);
			void* ParaGlobal_GetLuaState(const char* name);
		]]);
		
		if check_C_func("NplOce_StaticLoad") then
			return ffi.C.NplOce_StaticLoad(ffi.C.ParaGlobal_GetLuaState(""));
		end
	end
	
	return false;
end


local NplOceConnection = NPL.export();
NplOceConnection.is_loaded = false;
-- Install dll
-- @param {table} options
-- @param {string} [options.npl_oce_dll = "plugins/nploce_d.dll"] - the location of dll
-- @param {string} [options.activate_callback = "Mod/NplOce/NplOceConnection.lua"] - the location of be actived
function NplOceConnection.load(options,callback)
    if(NplOceConnection.is_loaded)then
        if(callback)then
            callback(true);
        end
        return
    end
    
   
	NplOceConnection.callback = callback;
    local npl_oce_dll = options.npl_oce_dll or "plugins/nploce_d.dll"
	local activate_callback = options.activate_callback or "Mod/NplCad2/NplOceConnection.lua";
	
    local platform = System.os.GetPlatform();
    if(platform == "linux" or platform == "android")then
        npl_oce_dll = "plugins/libnploce.so"
    end

	if NplOce_StaticLoad() then
		NplOce.StaticInit(function()
			if(not NplOceConnection.is_loaded)then
				NplOceConnection.is_loaded = true;

				NPL.load("Mod/NplCad2/NplOce_Internal.lua");

				if(NplOceConnection.callback)then
					NplOceConnection.callback(true);
				end
			end
		end);
	else
		if(not NplOceConnection.OsSupported())then
			LOG.std(nil, "info", "NplOceConnection", "nplcad isn't supported on %s",System.os.GetPlatform());
			return
		end
		
		if(not NPL.GetLuaState)then
			LOG.std(nil, "error", "NplOceConnection", "can't find the function of NPL.GetLuaState.\n");
			return
		end

		local lua_state = NPL.GetLuaState("",{});
		LOG.std(nil, "info", "NplOceConnection lua_state", lua_state);

		local high = lua_state.high or 0;
		local low = lua_state.low or 0;
		local value = mathlib.bit.lshift(high, 32);
		value = mathlib.bit.bor(value, low);
		if(value == 0)then
			LOG.std(nil, "error", "NplOceConnection", "lua state is wrong.\n");
			return
		end
		LOG.std(nil, "info", "NplOceConnection", "lua state is %s.\n", tostring(value));
        if(platform == "linux")then
            value = lua_state.value;
        end
		NPL.activate(npl_oce_dll, { lua_state = value, callback = activate_callback});
	end
end
function NplOceConnection.OsSupported()
    local platform = System.os.GetPlatform();
    if(platform == "linux" or platform == "android")then
        return true
    end
	local is_supported = (System.os.GetPlatform()=="win32" and not System.os.Is64BitsSystem());
    return is_supported;
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