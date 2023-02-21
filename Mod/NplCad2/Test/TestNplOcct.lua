--[[
Title: TestNplOcct
Author(s): leio
Date: 2022/12/10
Desc: 
use the lib:
------------------------------------------------------------
local TestNplOcct = NPL.load("Mod/NplCad2/Test/TestNplOcct.lua");
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce_d.dll" },function(msg)
	--TestNplOcct.helloWorld()
	--TestNplOcct.test_NplOcctCharArray()
	TestNplOcct.test_NplOcctImporterXCAF("test/cube.step")
end);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/Encoding.lua");
local Encoding = commonlib.gettable("commonlib.Encoding");

local TestNplOcct = NPL.export();

function TestNplOcct.helloWorld()
	commonlib.echo(NplOcct.helloWorld());
	local npl_occt_node = NplOcct.NplOcctNode.create();
end
function TestNplOcct.test_NplOcctCharArray()
	local npl_occt_chararray = NplOcct.NplOcctCharArray.create();
	local content = "abc123中文";
	local len = #content;
	local len2 = ParaMisc.GetUnicodeCharNum(content);
	commonlib.echo("===========len");
	commonlib.echo(len);
	commonlib.echo("===========len2");
	commonlib.echo(len2);
	npl_occt_chararray:set(content, len);
	local output = {}
	for k = 1,len do
		local v = npl_occt_chararray:getValue(k-1);
		local char_code = string.byte(v);
		commonlib.echo("===========char_code");
		commonlib.echo(char_code);
		table.insert(output, string.char(char_code))
	end
	commonlib.echo("===========output");
	commonlib.echo(output);

	local s = table.concat(output);
	commonlib.echo("=======================utf8 string container");
	commonlib.echo(s);
	local s = Encoding.Utf8ToDefault(s)
	commonlib.echo("=======================string");
	commonlib.echo(s);
end
function TestNplOcct.test_NplOcctImporterXCAF(filename)
	local npl_occt_importer_xcaf = NplOcct.NplOcctImporterXCAF.create();
	local charArray = NplOcct.NplOcctCharArray.create();
	filename = filename or "test/as1_pe_203.stp";

	 local file = ParaIO.open(filename,"r");
    if(file:IsValid()) then
        local content = file:GetText(0,-1);
		local len = #content;
		charArray:set(content, len);
        file:close();
    end
	local nplOcctNode = npl_occt_importer_xcaf:loadFromCharArray("test.step", charArray, 0.5, 0.5, false);
	local exporter = NplOcct.NplOcctExporterXCAF.create();
	exporter:exportStep(nplOcctNode);
end
