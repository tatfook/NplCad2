--[[
Title: SvgParser
Author(s): leio
Date: 2020/11/2
Desc:  
svg moveto:
https://www.w3.org/TR/2011/REC-SVG11-20110816/paths.html#PathDataMovetoCommands

svg parser:
https://github.com/globalcitizen/svglover/blob/master/svglover.lua

https://css-tricks.com/svg-path-syntax-illustrated-guide/

svg editor:
https://github.com/SVG-Edit/svgedit

svg viewer:
https://www.svgviewer.dev/

svg arc:
http://xahlee.info/js/svg_path_ellipse_arc.html
http://xahlee.info/js/svg_circle_arc.html
http://xahlee.info/SpecialPlaneCurves_dir/Ellipse_dir/ellipse.html
Use Lib:
-------------------------------------------------------
local SvgParser = NPL.load("Mod/NplCad2/Svg/SvgParser.lua");
local svg_parser = SvgParser:new();
svg_parser:ParseFile("Mod/NplCad2/Svg/SvgLibs/arrow_u_turn.svg.xml");
svg_parser:Dump();

local SvgPathLibs = NPL.load("Mod/NplCad2/Svg/SvgPathLibs.lua");
local path_data = SvgPathLibs.GetSvgByName("basic","arrow_u_turn");

local SvgParser = NPL.load("Mod/NplCad2/Svg/SvgParser.lua");
local svg_parser = SvgParser:new();
svg_parser:ParseString(path_data);
svg_parser:Dump();

--]]
NPL.load("(gl)script/ide/XPath.lua");
local SvgParser = commonlib.inherit(nil,NPL.export());

function SvgParser:ctor()
end
function SvgParser:ParseFile(filename)
    if(not filename)then
        return
    end
    local xmlDoc = ParaXML.LuaXML_ParseFile(filename);
    self:ParseXmlDoc(xmlDoc);
end
function SvgParser:ParseString(content)
    local xmlDoc = ParaXML.LuaXML_ParseString(content);
    self:ParseXmlDoc(xmlDoc);
end
function SvgParser:ParseXmlDoc(xmlDoc)
    if(not xmlDoc)then
        return
    end
    local root_node = commonlib.XPath.selectNode(xmlDoc, "//svg");
    SvgParser.Tags_Callback_svg(self,root_node);
end
function SvgParser:Tags_Callback_svg(xmlNode)
    if(not xmlNode)then
        return
    end
    self.result = {};
    local name = xmlNode.name;
    local len = #xmlNode;
    for k = 1, len do
        local childNode = xmlNode[k];
        local name = childNode.name;
        local key = string.format("Tags_Callback_%s",name);
        if(SvgParser[key])then
           SvgParser[key](self,childNode);
        end
    end
end
function SvgParser:Dump()
    local result = self:GetResult();
    echo("=========SvgParser:Dump")
    for k,v in ipairs(result) do
        echo(v)
    end
end
function SvgParser:GetResult()
    local result = self.result;
    return result;
end
function SvgParser:PushLineNode(result, from_x, from_y, to_x, to_y, bClosed)
    table.insert(result,{
        type = "line",
        bClosed = bClosed,
        out_data = {
            from_x = from_x,
            from_y = from_y,
            to_x = to_x,
            to_y = to_y,
        }
    });
end
-- push data for bezier curve
-- @param result: input table
-- @param {table} poles: example
--    {
--        { 0, 0, 0 },
--        { 1.1, 0, 3 },
--        { 2.1, 0, 0 },
--        { 3.1, 0, 3 },
--        { 4.1, 0, 0 },
--        { 5.1, 0, 5 },
--    }
function SvgParser:PushBezierCurveNode(result, poles)
    table.insert(result,{
        type = "bezier_curve",
        out_data = poles,
    });
end
function SvgParser:PushCode(result,code)
    if(not result)then
        return
    end
     table.insert(result,{
        type = "unknown",
        out_data = code,
    });
end
function SvgParser:Tags_Callback_path(xmlNode)
    if(not xmlNode)then
        return
    end
    local name = xmlNode.name;
    local d = xmlNode.attr.d;

    local result = self.result;

    local start_x = 0
    local start_y = 0
    local cpx = 0
    local cpy = 0
    local new_x = 0
    local new_y = 0
    local prev_ctrlx = 0
    local prev_ctrly = 0

    for op, strargs in string.gmatch(d, "%s*([MmLlHhVvCcSsQqTtAaZz])%s*([^MmLlHhVvCcSsQqTtAaZz]*)%s*") do
        local args = {}

        -- parse command arguments
        if strargs ~= nil and #strargs > 0 then
            for arg in string.gmatch(strargs, "[%-%.]?[^%s,%-]+") do
                table.insert(args, 1, tonumber(arg,10))
            end
        end
        -- move to
        if op == "M" then
            start_x = table.remove(args)
            start_y = table.remove(args)
            cpx = start_x
            cpy = start_y

            while #args >= 2 do
                cpx = table.remove(args)
                cpy = table.remove(args)

            end
        -- move to (relative)
        elseif op == "m" then
            start_x = cpx + table.remove(args)
            start_y = cpy + table.remove(args)
            cpx = start_x
            cpy = start_y


            while #args >= 2 do
                cpx = cpx + table.remove(args)
                cpy = cpy + table.remove(args)
            end
        -- line to
        elseif op == "L" then
            while #args >= 2 do
                new_x = table.remove(args)
                new_y = table.remove(args)

                self:PushLineNode(result,cpx,cpy,new_x,new_y);

                cpx = new_x;
                cpy = new_y;
            end
        -- line to (relative)
        elseif op == "l" then
            while #args >= 2 do
                new_x = cpx + table.remove(args)
                new_y = cpy + table.remove(args)


                self:PushLineNode(result, cpx, cpy, new_x, new_y);

                cpx = new_x;
                cpy = new_y;

            end
        -- line to (horizontal)
        elseif op == "H" then
            while #args >= 1 do
                new_x = table.remove(args)

                self:PushLineNode(result,cpx,cpy,new_x,new_y);
                cpx = new_x;
            end
        -- line to (horizontal, relative)
        elseif op == "h" then
            while #args >= 1 do
                new_x = cpx + table.remove(args)
                new_y = cpy
                self:PushLineNode(result,cpx,cpy,new_x,new_y);
                cpx = new_x;
            end
        -- line to (vertical)
        elseif op == "V" then
            while #args >= 1 do
                new_y = table.remove(args)
                self:PushLineNode(result,cpx,cpy,new_x,new_y);
                cpy = new_y;
            end
        -- line to (vertical, relative)
        elseif op == "v" then
            while #args >= 1 do
                new_x = cpx
                new_y = cpy + table.remove(args)
                self:PushLineNode(result, cpx, cpy, new_x, new_y);
                cpy = new_y;
            end
        -- cubic bezier curve
        elseif op == "C" then
            while #args >= 6 do
                local x1 = table.remove(args)
                local y1 = table.remove(args)
                local x2 = table.remove(args)
                local y2 = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)


                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x2, y2 },
                     {x, y }
                 })
                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end
        -- cubic bezier curve (relative)
        elseif op == "c" then
            while #args >= 6 do
                local x1 = cpx + table.remove(args)
                local y1 = cpy + table.remove(args)
                local x2 = cpx + table.remove(args)
                local y2 = cpy + table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                
                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x2, y2 },
                     {x, y }
                 })
                


                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end

        -- smooth cubic Bézier curve
        elseif op == "S" then
            while #args >= 4 do
                local x2 = table.remove(args)
                local y2 = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)

                -- calculate the start control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x2, y2 },
                     {x, y }
                 })
                

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end
        -- smooth cubic Bézier curve (relative)
        elseif op == "s" then
            while #args >= 4 do
                local x2 = cpx + table.remove(args)
                local y2 = cpy + table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                -- calculate the start control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly


                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x2, y2 },
                     {x, y }
                 })

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x2
                prev_ctrly = y2
            end

        -- quadratic Bézier curve
        elseif op == "Q" then
            while #args >= 4 do
                local x1 = table.remove(args)
                local y1 = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)


                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x, y }
                 })


                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end
        -- quadratic Bézier curve (relative)
        elseif op == "q" then
            while #args >= 4 do
                local x1 = cpx + table.remove(args)
                local y1 = cpy + table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x, y }
                 })
                

                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end
        -- smooth quadratic Bézier curve
        elseif op == "T" then
            while #args >= 2 do
                local x = table.remove(args)
                local y = table.remove(args)

                -- calculate the control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly


                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x, y }
                 })

                
                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end
        -- smooth quadratic Bézier curve (relative)
        elseif op == "t" then
            while #args >= 2 do
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                -- calculate the control point
                local x1 = cpx + cpx - prev_ctrlx
                local y1 = cpy + cpy - prev_ctrly

                self:PushBezierCurveNode(result, {
                     {cpx, cpy},
                     {x1, y1 },
                     {x, y }
                 })


                -- move the current point
                cpx = x
                cpy = y

                -- remember the end control point for the next command
                prev_ctrlx = x1
                prev_ctrly = y1
            end

        -- arc to
        elseif op == "A" then
            while #args >= 7 do
                local rx = table.remove(args)
                local ry = table.remove(args)
                local angle = table.remove(args)
                local large_arc_flag = table.remove(args)
                local sweep_flag = table.remove(args)
                local x = table.remove(args)
                local y = table.remove(args)

                self:PushCode(result,string.format("svgarc(%f,%f,%f,%f,%f,%f,%f);\n",rx, ry, angle, large_arc_flag, sweep_flag, x, y));


                cpx = x
                cpy = y

                table.insert(vertices, cpx)
                table.insert(vertices, cpy)
            end
        -- arc to (relative)
        elseif op == "a" then
            while #args >= 7 do
                local rx = table.remove(args)
                local ry = table.remove(args)
                local angle = table.remove(args)
                local large_arc_flag = table.remove(args)
                local sweep_flag = table.remove(args)
                local x = cpx + table.remove(args)
                local y = cpy + table.remove(args)

                self:PushCode(result,string.format("svgarc(%f,%f,%f,%f,%f,%f,%f);\n",rx, ry, angle, large_arc_flag, sweep_flag, x, y));

                cpx = x
                cpy = y
            end
        -- close shape (relative and absolute are the same)
        elseif op == "Z" or op == "z" then

            self:PushLineNode(result,cpx,cpy,start_x,start_y, true);

            cpx = start_x
            cpy = start_y
        end

        -- if the command wasn't a curve command, set prev_ctrlx and prev_ctrly to cpx and cpy
        if not string.match(op, "[CcSsQqTt]") then
            prev_ctrlx = cpx
            prev_ctrly = cpy
        end
    end
end