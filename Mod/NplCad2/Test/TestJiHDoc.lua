--[[
Title: TestJiHDoc
Author(s): leio
Date: 2022/12/10
Desc: 
use the lib:
------------------------------------------------------------
local TestJiHDoc = NPL.load("Mod/NplCad2/Test/TestJiHDoc.lua");
TestJiHDoc.test_LoadStepFile("test/servo.step", "test/out_servo.step");
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/Encoding.lua");
local Encoding = commonlib.gettable("commonlib.Encoding");
local JiHDocumentHelper = NPL.load("Mod/NplCad2/JiHDom/JiHDocumentHelper.lua");

local TestJiHDoc = NPL.export();

--[[
function TestJiHDoc.helloWorld()
	commonlib.echo(NplOcct.helloWorld());
	local npl_occt_node = NplOcct.NplOcctNode.create();
end
function TestJiHDoc.test_NplOcctCharArray()
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

]]

function TestJiHDoc.test_LoadStepFile(filename, out_filename)
	local step_importer = jihengine.JiHImporterXCAF:new()
	local jih_char_array = jihengine.JiHCharArray:new();

	local file = ParaIO.open(filename,"r");
    if(file:IsValid()) then
        local content = file:GetText(0,-1);
		local len = #content;
		jih_char_array:set(content, len);
        file:close();
    end
	local jih_root_node = step_importer:loadFromCharArray("test/temp.step", jih_char_array, 0.5, 0.5, false);
	local shape_cnt = step_importer:getTotalShapesCnt();
	commonlib.echo("==============shape_cnt");
	commonlib.echo(shape_cnt);
	commonlib.echo("==============jih_root_node numChildren");
	commonlib.echo(jih_root_node:numChildren());
	local step_exporter = jihengine.JiHExporterXCAF:new();
	local out_char_array = step_exporter:exportStep(jih_root_node);
	JiHDocumentHelper.jiHCharArrayToFile(out_filename, out_char_array)
	
end
