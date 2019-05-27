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
    TestScene.Test_Skin();
end);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");

local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");

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
function TestScene.Test_ShapeNode_Rotation()
    local node = NplOce.ShapeNode.create();
    local angle = 90 * math.pi * (1.0 / 180.0);
    node:setRotation(1.0,0.0,0.0,angle)
    node:translate(0.15,0,0)
    local matrix = node:getMatrix();

    local matrix_lua = Matrix4.rotationX(90)
    matrix_lua:setTrans(0.15,0,0)
    local shape = NplOce.cube();
    shape:setMatrix(matrix_lua);
    local matrix_shape = shape:getMatrix();
    echo("==================angle");
    echo(string.format("%.25f",angle));
    echo("==================pi");
    echo(string.format("%.25f",math.pi));
    echo(string.format("%.18f",math.pi));
    echo(string.format("%.17f",math.pi));
    echo("==================test");
    for k=1,16 do
        local s = string.format("%d:%.18f %.18f %.18f",k,matrix[k],matrix_lua[k],matrix_shape[k]);
        echo(s);
    end
    
end
function TestScene.Test_MirrorNode()
    local SceneHelper = NPL.load("Mod/NplCad2/SceneHelper.lua");

    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");
    local node = NplOce.ShapeNodeBox.create("node1");
    node:setValue(1,1,1);
    cur_node:addChild(node);

    local model = node:getDrawable();
    local shape = model:getShape();
    local pos = {0,0,0};
    local xy_plane = {0,0,1};

    local mirror_shape = NplOce.mirror(shape, pos, xy_plane);

    local mirror_node = NplOce.ShapeNode.create();
    local mirror_model = NplOce.ShapeModel.create();
    mirror_model:setShape(mirror_shape);
    mirror_node:setDrawable(mirror_model);
    cur_node:addChild(mirror_node);


    TestScene.SaveFile("test/Test_MirrorNode.x",NplOce.exportToParaX(scene,true))
end
function TestScene.Test_Skin()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");
    local node = NplOce.ShapeNodeBox.create("node1");
    node:setValue(1,1,1);
    cur_node:addChild(node);

    echo("==================node:getTypeName()");
    echo(node:getTypeName());
    local model = node:getDrawable();

    local joint = NplOce.Joint.create("test_joint");
    echo("==================joint:getTypeName()");
    echo(joint:getTypeName());
    cur_node:addChild(joint);
    local skin = NplOce.MeshSkin.create();
    model:setSkin(skin);

    skin:setJointCount(1);
    skin:setJoint(joint,0);

    local cnt = skin:getJointCount();
    echo("==================skin:getJointCount()");
    echo(cnt);
    for k = 0,cnt-1 do
        local t_joint = skin:getJoint(k);
        echo("==========t_joint:getId()");
        echo({k,t_joint:getId(),skin:getJointIndex(t_joint)});
    end

    TestScene.SaveFile("test/Test_Skin.xml",SceneHelper.getXml(scene));
end