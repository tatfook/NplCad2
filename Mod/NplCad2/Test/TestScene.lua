--[[
Title: TestScene
Author(s): leio
Date: 2018/10/30
Desc: 
use the lib:
------------------------------------------------------------
local TestScene = NPL.load("Mod/NplCad2/Test/TestScene.lua");
local NplOceConnection = NPL.load("Mod/NplCad2/NplOceConnection.lua");
NplOceConnection.load({ npl_oce_dll = "plugins/nploce_d.dll" },function(msg)
    NPL.load("Mod/NplCad2/NplOce_Internal.lua");
    TestScene.Test_ShapePlus("test/test.x");
end);
------------------------------------------------------------
--]]
local NplOceScene = NPL.load("Mod/NplCad2/NplOceScene.lua");
local ShapeBuilder = NPL.load("Mod/NplCad2/Blocks/ShapeBuilder.lua");
local TestScene = NPL.export();

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
    cube:transform(t);

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
function TestScene.Test_VisitNodeTransform()
     ShapeBuilder.create();
    local cur_node = ShapeBuilder.getCurNode();
    local node = NplOce.Node.create("node1_1");
    node:translate(10,20,30);
    local matrix = node:getMatrix();
    local world_matrix = node:getWorldMatrix();
    commonlib.echo("=========matrix");
    commonlib.echo(matrix);
    commonlib.echo("=========world_matrix");
    commonlib.echo(world_matrix);
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
function TestScene.Test_ShapePlus()
    local shapes = {
        "ShapeNodeBox",
        "ShapeNodeCylinder",
        "ShapeNodeSphere",
        "ShapeNodeCone",
        "ShapeNodeTorus",
        "ShapeNodePrism",
        "ShapeNodeEllipsoid",
        "ShapeNodeWedge",
    }
    for k,name in ipairs(shapes) do

        local func = NplOce[name]
        if(func and func.create)then
            filename = string.format("test/%s.x",name);
            local node = func.create();
            node:setColor({0,0,1,1});
            node:setValue();
            local scene = NplOce.Scene.create();
            local cur_node = scene:addNode("root");
            cur_node:addChild(node);

            local s = NplOce.exportToParaX(scene,true) or "";
            local len = string.len(s);
            if(len > 0)then
                ParaIO.CreateDirectory(filename);
                local file = ParaIO.open(filename, "w");
	            if(file:IsValid()) then
		            file:write(s,len);
		            file:close();
	            end
            end
        end
        
    end
    _guihelper.MessageBox("done");
end
function TestScene.Test_CustomShapeNode()

    local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");

    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");
    local node = NplOce.ShapeNode.create("node1");
    cur_node:addChild(node);

    local node = NplOce.ShapeNode.create("node2");
    node:setOpEnabled(true);
    cur_node:addChild(node);

    local box_node = NplOce.ShapeNodeBox.create();
    box_node:setValue(1,1,1);
    node:addChild(box_node);

    local sphere_node = NplOce.ShapeNodeSphere.create();
    sphere_node:setValue(0.6);
    sphere_node:setOp("difference");
    node:addChild(sphere_node);

    

    TestScene.SaveFile("test/CustomShapeNode.before.xml",SceneHelper.getXml(scene))
    TestScene.SaveFile("test/CustomShapeNode.before.x",NplOce.exportToParaX(scene,true))
    SceneHelper.run(scene,true)
    TestScene.SaveFile("test/CustomShapeNode.xml",SceneHelper.getXml(scene))
    TestScene.SaveFile("test/CustomShapeNode.x",NplOce.exportToParaX(scene,true))
    
    _guihelper.MessageBox("done");
end
function TestScene.SaveFile(filename,s)
    local len = string.len(s);
    ParaIO.CreateDirectory(filename);
    local file = ParaIO.open(filename, "w");
	if(file:IsValid()) then
		file:write(s,len);
		file:close();
	end
end