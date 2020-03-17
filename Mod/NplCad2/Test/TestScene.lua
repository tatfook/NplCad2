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
    TestScene.Test_setLocalPivotMatrix()
    --TestScene.Test_ShapeNodeChamferBox()
    --TestScene.Test_ShapeNodeFilletBox();
    --TestScene.Test_setRotationQuaternion();
	--TestScene.Test_setLocalPivot();
    --TestScene.Test_CreateAnimation();
    --TestScene.Test_ExportStl();
    --TestScene.Test_ExportGltf();
end);
------------------------------------------------------------
--]]
NPL.load("(gl)script/ide/math/Quaternion.lua");
NPL.load("(gl)script/ide/math/Matrix4.lua");
local Matrix4 = commonlib.gettable("mathlib.Matrix4");
local Quaternion = commonlib.gettable("mathlib.Quaternion");

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

            local s = SceneHelper.toParaX(scene) or "";
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
    TestScene.SaveFile("test/CustomShapeNode.before.x",SceneHelper.toParaX(scene))
    SceneHelper.run(scene,true)
    TestScene.SaveFile("test/CustomShapeNode.xml",SceneHelper.getXml(scene))
    TestScene.SaveFile("test/CustomShapeNode.x",SceneHelper.toParaX(scene))
    
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


    TestScene.SaveFile("test/Test_MirrorNode.x",SceneHelper.toParaX(scene))
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
function TestScene.Test_LeftHandCoordinate()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");

    local pos_value = 8;
    -- create center
    local node = NplOce.ShapeNodeSphere.create();
    -- create topo_shape with default value
    node:setValue(1);
    node:setTranslation(0,0,0);
    node:setColor({0,0,0,1});
    cur_node:addChild(node);

    --create axes
    -- x red
    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    node:setTranslation(pos_value,0,0)
    node:setColor({1,0,0,1});
    cur_node:addChild(node);

    -- y green
    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    node:setTranslation(0,pos_value,0)
    node:setColor({0,1,0,1});
    cur_node:addChild(node);

    -- z blue
    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    node:setTranslation(0,0,pos_value)
    node:setColor({0,0,1,1});
    cur_node:addChild(node);


    -- check offset
    local node = NplOce.ShapeNodeCylinder.create("node1");
    node:setValue(1);
    -- z is 10
    node:setTranslation(10,0,10);
    node:setColor({0,1,1,1});
    cur_node:addChild(node);
    
    local path_x = "test/LeftHandCoordinate.x";
    local path_gltf = "test/LeftHandCoordinate.gltf";
    TestScene.SaveFile(path_x,SceneHelper.toParaX(scene));
    TestScene.SaveFile(path_gltf,scene:toGltf_String(false));

    local msg = string.format("save to: %s %s",path_x,path_gltf);
    _guihelper.MessageBox(msg);
end
function TestScene.Test_XValue()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");

--    -- create center
--    local node = NplOce.ShapeNodeSphere.create();
--    -- create topo_shape with default value
--    node:setValue(1);
--    node:setTranslation(0,0,0);
--    node:setColor({0,0,0,1});
--    cur_node:addChild(node);

    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    node:setTranslation(10,0,0)
    node:setColor({1,0,0,1});
    cur_node:addChild(node);

    local path_x = "test/XValue.x";
    local path_gltf = "test/XValue.gltf";
    TestScene.SaveFile(path_x,SceneHelper.toParaX(scene));
    --TestScene.SaveFile(path_gltf,scene:toGltf_String(false));

    local msg = string.format("save to: %s %s",path_x,path_gltf);
    _guihelper.MessageBox(msg);
end
function TestScene.Test_CreateAnimation()
    local animation_manager = NplOce.AnimationManager.getInstance();
    animation_manager:clear();
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");
    local joint = NplOce.Joint.create("test_joint");
    cur_node:addChild(joint);

    local joint_node = cur_node:findNode("test_joint");
    if(joint_node)then
        commonlib.echo("===========found joint_node");
    end

    local animation_manager = NplOce.AnimationManager.getInstance();
    local animation = animation_manager:createAnimation("anim1");

    commonlib.echo("===========animation_manager:getCnt()");
    commonlib.echo(animation_manager:getCnt());

    commonlib.echo("===========animation:getChannelCnt() 111");
    commonlib.echo(animation:getChannelCnt());

    animation:addChannel(joint,NplOce.Transform_Enum.ANIMATE_TRANSLATE,3,{0,100,4000},{
        0,0,0,
        0,10,0,
        0,20,0,
    },NplOce.Curve_Enum.LINEAR);


    commonlib.echo("===========animation:getChannelCnt() 222");
    commonlib.echo(animation:getChannelCnt());
    commonlib.echo("===========animation:getDuration()");
    commonlib.echo(animation:getDuration());

    local clip_1 = animation:addClip("idle",100,1000);
    commonlib.echo(clip_1:getId());
    local clip_2 = animation:addClip("run",1000,4000);
    commonlib.echo(clip_2:getId());

    commonlib.echo("===========animation:getClipCount()");
    commonlib.echo(animation:getClipCount());

end
function TestScene.Test_ExportStl()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");


    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    cur_node:addChild(node);

    local filename = "test/test.stl";
    SceneHelper.saveSceneToStl(filename,scene,true)

    local filename = "test/test.binary.stl";
    SceneHelper.saveSceneToStl(filename,scene,true,true)

    local msg = string.format("save to: %s",filename);
    _guihelper.MessageBox(msg);
end

function TestScene.Test_ExportGltf()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");


    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    cur_node:addChild(node);

    local filename = "test/test.gltf";
    SceneHelper.saveSceneToGltf(filename,scene,true)

    local msg = string.format("save to: %s",filename);
    _guihelper.MessageBox(msg);
end
function TestScene.Test_setLocalPivot()
	local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");
	local pivot = cur_node:getLocalPivot();
	commonlib.echo("===========Test_setLocalPivot");
	commonlib.echo({pivot[1],pivot[2],pivot[3]});
	cur_node:setLocalPivot(1,1,1);
	local pivot = cur_node:getLocalPivot();
	commonlib.echo("===========Test_setLocalPivot 222");
	commonlib.echo(pivot);
end

function TestScene.Test_setRotationQuaternion()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");

    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    cur_node:addChild(node);

    local node2 = NplOce.ShapeNodeBox.create();
    node2:setValue(1,1,1);
    node2:setColor({1,1,0,1});
    cur_node:addChild(node2);

    local matrix = Matrix4.rotationX(45)
    local q = Quaternion:new();
    q:FromRotationMatrix(matrix);
    local v = {q[1],q[2],q[3],q[4]}
    commonlib.echo("=============setRotationQuaternion");
    commonlib.echo(v);
    node2:setRotationQuaternion(v);
    
    local result = node2:getRotationQuaternion();
    commonlib.echo("=============getRotationQuaternion");
    commonlib.echo(result);
    local filename = "test/Test_setRotationQuaternion.gltf";
    SceneHelper.saveSceneToGltf(filename,scene,true)

    local msg = string.format("save to: %s",filename);
    _guihelper.MessageBox(msg);
    
end

function TestScene.Test_ShapeNodeFilletBox()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");

    local node = NplOce.ShapeNodeFilletBox.create();
    local len = 12;
    local edges = {}
    local radius = {}
    for k = 1,len do
        table.insert(edges,k);
        table.insert(radius,0.2);
    end
    node:setValue(1,1,1,len,edges,radius);
    cur_node:addChild(node);
    


    local filename = "test/Test_ShapeNodeFilletBox.gltf";
    SceneHelper.saveSceneToGltf(filename,scene,true)

    local msg = string.format("save to: %s",filename);
    _guihelper.MessageBox(msg);
    
end

function TestScene.Test_ShapeNodeChamferBox()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");

    local node = NplOce.ShapeNodeChamferBox.create();
    local len = 12;
    local edges = {}
    local values = {}
    for k = 1,len do
        table.insert(edges,k);
        table.insert(values,0.1);
    end
    node:setValue(1,1,1,len,edges,values);
    cur_node:addChild(node);
    


    local filename = "test/ShapeNodeChamferBox.gltf";
    SceneHelper.saveSceneToGltf(filename,scene,true)

    local msg = string.format("save to: %s",filename);
    _guihelper.MessageBox(msg);
    

end

function TestScene.Test_setLocalPivotMatrix()
    local scene = NplOce.Scene.create();
    local cur_node = scene:addNode("root");

    local node = NplOce.ShapeNodeBox.create();
    node:setValue(1,1,1);
    cur_node:addChild(node);
    
    local node = NplOce.ShapeNodeBox.create();
    node:setColor({0,1,0,1});
    node:setValue(1,1,1);
    cur_node:addChild(node);


    local matrix = Matrix4:new():identity();
    matrix:setTrans(5,0,0);
    node:setLocalPivotMatrix(matrix);
    local result = node:getLocalPivotMatrix();
    commonlib.echo("============result");
    commonlib.echo(result);

    local filename = "test/setLocalPivotMatrix.gltf";
    SceneHelper.saveSceneToGltf(filename,scene,true)

    local msg = string.format("save to: %s",filename);
    _guihelper.MessageBox(msg);
    
end