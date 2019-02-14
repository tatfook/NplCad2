--[[
Title: TestScene
Author(s): leio
Date: 2018/10/30
Desc: 
use the lib:
------------------------------------------------------------
local TestScene = NPL.load("Mod/NplCad2/Test/TestScene.lua");
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce/nploce_d.dll" },function(msg)
    NPL.load("Mod/NplCad2/NplOce_Internal.lua");
    --TestScene.Test_FindNode();
    --TestScene.Test_CloneNode();
    TestScene.Test_VisitNode2();
    --TestScene.Test1("test/test.json");
    --TestScene.Test_toParaX("test/test.x");

    --TestScene.Test_VisitNode("test/test_union_children.x");
    --TestScene.Test_VisitNodeTransform("test/test_tranform.json")
end);
------------------------------------------------------------
--]]
local NplOceScene = NPL.load("Mod/NplCad2/NplOceScene.lua");
local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
local TestScene = NPL.export();
function TestScene.TestCreateCube(filename)
    local s = NplOce.TestCreateCube(2);
	ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
end

function TestScene.Test1(filename)
    local cube = NplOce.cube();
    local mesh = NplOce.Mesh.create(cube);
    local model = NplOce.Model.create(mesh);
    local scene = NplOce.Scene.create();
    local node = scene:addNode("cube");
    node:setDrawable(model);
    local s = scene:toJson(4);

    local t = node:getWorldMatrix();
    commonlib.echo("==================a");
    commonlib.echo(t);
    cube:transform2(t);

	ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
end
function TestScene.Test_toParaX(filename)
    local cube = NplOce.cube(1,1,1);
   
    local mesh = NplOce.Mesh.create(cube,1,0,0,1);
    NplOce.exportToParaX(mesh, filename)
end

function TestScene.Test_VisitNode(filename)
    ShapeBuilder.create();
    ShapeBuilder.beginBoolean("union") 
        ShapeBuilder.cube(1);
        ShapeBuilder.cylinder(1);
        ShapeBuilder.sphere(1);

        ShapeBuilder.beginBoolean("union") 
            ShapeBuilder.beginNode()
                ShapeBuilder.cone(1,2,3);
                ShapeBuilder.torus(5,1);
            ShapeBuilder.endNode()
        ShapeBuilder.endBoolean() 
    ShapeBuilder.endBoolean() 

    local scene = ShapeBuilder.getScene();
    local shape = NplOceScene.unionToOneShape(scene);
    if(shape)then
        local mesh = NplOce.Mesh.create(shape,1,0,0,1);
        NplOce.exportToParaX(mesh, filename)
    end
end
function TestScene.Test_VisitNode2()
    ShapeBuilder.create();
    local cur_node = ShapeBuilder.getCurNode();
    local node = NplOce.Node.create("node1_1");
    cur_node:addChild(node)

    node:addChild(NplOce.Node.create("node1_1_1"))

    local node = NplOce.Node.create("node1_2");
    cur_node:addChild(node)

    cur_node = node;
    local node = NplOce.Node.create("node1_2_1");
    cur_node:addChild(node)

    local node = NplOce.Node.create("node1_2_2");
    cur_node:addChild(node)

    local function run_op(node)
        if(not node)then    
            return
        end
        commonlib.echo("=========run op");
        commonlib.echo(node:getId());
        commonlib.echo("=========begin");
        local child = node:getFirstChild();
	    while(child) do
            commonlib.echo(child:getId());
		    child = child:getNextSibling();
	    end
        commonlib.echo("=========end");

    end
    NplOceScene.visit(ShapeBuilder.getScene(),function(node)
        --commonlib.echo("=========push");
        --commonlib.echo(node:getId());
    end,function(node)
        run_op(node);
        commonlib.echo("=========post");
        commonlib.echo(node:getId());
    end)
end
function TestScene.Test_VisitNodeTransform(filename)
    ShapeBuilder.create();
    ShapeBuilder.beginBoolean("difference") 
        ShapeBuilder.beginTranslation(0,1,0);
            ShapeBuilder.sphere(1);
        ShapeBuilder.endTranslation();
            ShapeBuilder.beginNode()
                ShapeBuilder.cube(1,1,1);
            ShapeBuilder.endNode()
    ShapeBuilder.endBoolean() 

    local scene = ShapeBuilder.getScene();
    scene = NplOceScene.run(scene);

    --local s = scene:toParaX();
    local s = scene:toJson(4);
    ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:WriteString(s);
		file:close();
	end
--    if(shape)then
--        local mesh = NplOce.Mesh.create(shape,1,0,0,1);
--        NplOce.exportToParaX(mesh, filename)
--    end
end
function TestScene.Test_FindNode()
    ShapeBuilder.create();
    local cur_node = ShapeBuilder.getCurNode();
    local node = NplOce.Node.create("test");
    cur_node:addChild(node)
    local name = "object1"
    local node2 = NplOce.Node.create(name);
    node:addChild(node2)

    local v = cur_node:findNode(name);
    if(v)then
        commonlib.echo("=====found");
        commonlib.echo(v:getId());
    end
end
function TestScene.Test_CloneNode()
    ShapeBuilder.create();
    ShapeBuilder.cube(0,0,0,"#ff0000","difference") 
    local cur_node = ShapeBuilder.getCurNode();
    local cloned_node = cur_node:clone();
    local child = cloned_node:getFirstChild();

    local model = child:getDrawable();
    local v = NplOce._getBooleanOp(child);
    commonlib.echo("=====_getBooleanOp");
    commonlib.echo(v);
end