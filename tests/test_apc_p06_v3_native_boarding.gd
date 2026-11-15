extends SceneTree

const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V3=preload("res://scripts/ui/APCBoardingV3.gd")
const OriginalRig=preload("res://scripts/ui/APCVisualRigV1.gd")
const Studio=preload("res://scripts/ui/UnitArtStudioWeb.gd")
const OUT: String="res://artifacts/apc-p06-v3"

func _initialize() -> void:
    call_deferred("_run")

func _close(a: float,b: float,delta: float=0.025) -> bool:
    return absf(a-b) <= delta

func _snap(viewport: SubViewport, camera: Camera3D,model: Node3D,
        at: Vector3,filename: String) -> Image:
    camera.position=at
    camera.look_at(Vector3(0,0.72,0.72),Vector3.UP)
    for i in range(6):
        await process_frame
    var screenshot: Image=viewport.get_texture().get_image()
    assert(screenshot!=null and not screenshot.is_empty())
    screenshot.convert(Image.FORMAT_RGBA8)
    assert(screenshot.save_png("%s/%s.png" % [OUT,filename])==OK)
    return screenshot

func _run() -> void:
    var modern: Node3D=Models.build("apc",0,true,12)
    assert(modern!=null)
    assert(modern.get_meta("tarvoka_apc_sculpt_v1",false))
    assert(modern.get_meta("tarvoka_apc_armor_v2",false))
    var base_meshes: int=Models.inspect_meshes(modern)
    assert(not V3.pose(modern,"embark",0.0)) # Explicit native rig setup.
    assert(V3.prepare(modern,0))
    assert(modern.get_meta("tarvoka_apc_boarding_v3",false))
    var enhanced_meshes: int=Models.inspect_meshes(modern)
    assert(enhanced_meshes>=base_meshes+35)
    assert(enhanced_meshes<=base_meshes+85)
    assert(V3.prepare(modern,0))
    assert(Models.inspect_meshes(modern)==enhanced_meshes)
    var hull: Node3D=modern.find_child(V3.ART_ROOT,true,false) as Node3D
    assert(hull!=null)
    var hinge: Node3D=modern.find_child(V3.HINGE,true,false) as Node3D
    var troops: Node3D=hull.find_child(V3.RIG_ROOT,false,false) as Node3D
    var moving: Node3D=troops.find_child(V3.MOVING,false,false) as Node3D
    var left: Node3D=troops.find_child("SoldadoSentadoP06V3_0",false,false) as Node3D
    var right: Node3D=troops.find_child("SoldadoSentadoP06V3_1",false,false) as Node3D
    assert(hinge!=null and troops!=null and moving!=null)
    assert(left!=null and right!=null and not left.visible and not right.visible)
    assert(not moving.visible and V3.occupants(modern)==0)
    assert(not V3.pose(modern,"disembark",0.0))
    assert(not V3.set_occupants(modern,3))
    assert(V3.set_occupants(modern,0))

    # Real mesh doors stay attached to the original correct 3D hinge; a
    # soldier with arms and legs walks from the world into its cargo floor.
    assert(V3.pose(modern,"embark",0.0))
    assert(moving.visible and _close(moving.position.z,V3.START.z))
    assert(_close(hinge.rotation_degrees.x,V3.CLOSED_DEGREES))
    assert(V3.pose(modern,"embark",0.30))
    assert(_close(hinge.rotation_degrees.x,V3.OPEN_DEGREES))
    assert(V3.pose(modern,"embark",0.55))
    assert(moving.position.z<V3.START.z and moving.position.z>V3.INSIDE.z)
    assert(moving.position.y>V3.START.y and moving.position.y<V3.INSIDE.y+0.04)
    var limb: Node3D=moving.find_child("PiernaArticuladaP06V3_1",false,false) as Node3D
    assert(limb!=null)
    assert(absf(limb.rotation_degrees.x)>0.1)
    assert(V3.pose(modern,"embark",1.0))
    assert(V3.occupants(modern)==1 and left.visible and not right.visible)
    assert(_close(hinge.rotation_degrees.x,V3.CLOSED_DEGREES))
    assert(not moving.visible)
    assert(V3.pose(modern,"embark",1.0))
    assert(V3.occupants(modern)==1) # No duplicate on repeated final tick.
    V3.restore(modern)
    assert(V3.occupants(modern)==1 and left.visible)
    assert(V3.pose(modern,"embark",0.0))
    assert(V3.pose(modern,"embark",1.0))
    assert(V3.occupants(modern)==2 and left.visible and right.visible)
    V3.restore(modern)
    assert(not V3.pose(modern,"embark",0.0)) # Full.
    assert(V3.occupants(modern)==2)
    assert(V3.pose(modern,"disembark",0.0))
    assert(V3.pose(modern,"disembark",0.50))
    assert(_close(hinge.rotation_degrees.x,V3.OPEN_DEGREES))
    assert(moving.position.z>V3.INSIDE.z and moving.position.z<V3.START.z)
    assert(moving.visible and left.visible and not right.visible)
    assert(V3.pose(modern,"disembark",1.0))
    assert(V3.occupants(modern)==1 and not moving.visible and left.visible)
    V3.restore(modern)
    assert(V3.pose(modern,"disembark",0.0))
    assert(V3.pose(modern,"disembark",1.0))
    assert(V3.occupants(modern)==0 and not left.visible and not right.visible)
    V3.restore(modern)
    assert(not V3.pose(modern,"disembark",0.0))

    # V1/V2 legacy animation and PBR repaint still work after V3 seats.
    assert(OriginalRig.pose(modern,"open_ramp",1.0))
    assert(_close(hinge.rotation_degrees.x,78.0))
    OriginalRig.restore(modern)
    assert(_close(hinge.rotation_degrees.x,78.0))
    assert(OriginalRig.pose(modern,"close_ramp",1.0))
    OriginalRig.restore(modern)
    assert(_close(hinge.rotation_degrees.x,8.0))
    assert(Models.apply_faction_palette(modern,3)>0)
    assert(Models.inspect_meshes(modern)==enhanced_meshes)
    assert(Studio!=null)

    # True mesh render evidence at the exact rear 3/4 camera, not mockup.
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    var stage:=SubViewport.new()
    stage.size=Vector2i(500,360)
    stage.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    stage.own_world_3d=true
    root.add_child(stage)
    var world:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#1b2935")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#cfdeea")
    env.ambient_light_energy=0.9
    world.environment=env
    stage.add_child(world)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-44,-24,0)
    sun.light_energy=1.75
    stage.add_child(sun)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.0
    stage.add_child(camera)
    camera.current=true
    stage.add_child(modern)
    var angle:=Vector3(3.50,2.12,5.10)
    var images: Array[Image]=[]
    images.append(await _snap(stage,camera,modern,angle,"01_cerrado"))
    assert(V3.pose(modern,"embark",0.0))
    assert(V3.pose(modern,"embark",0.35))
    images.append(await _snap(stage,camera,modern,angle,"02_rampa_abierta"))
    assert(V3.pose(modern,"embark",0.60))
    images.append(await _snap(stage,camera,modern,angle,"03_soldado_subiendo"))
    assert(V3.pose(modern,"embark",1.0))
    V3.restore(modern)
    images.append(await _snap(stage,camera,modern,angle,"04_soldado_dentro"))
    assert(V3.pose(modern,"disembark",0.0))
    assert(V3.pose(modern,"disembark",0.56))
    images.append(await _snap(stage,camera,modern,angle,"05_soldado_bajando"))
    var contact:=Image.create(500*5,360,false,Image.FORMAT_RGBA8)
    contact.fill(Color("#203140"))
    for index in range(images.size()):
        contact.blit_rect(images[index],Rect2i(0,0,500,360),
            Vector2i(index*500,0))
    assert(contact.save_png("%s/00_filmstrip_real_3d.png" % OUT)==OK)
    assert(V3.pose(modern,"disembark",1.0))
    assert(V3.occupants(modern)==0)
    stage.queue_free()

    # Faction colors are a skin of the original P06; the V3 rig does not
    # alter 8 painted variants or final G09 mesh and damage controller.
    var opponent: Node3D=Models.build("apc",1,true,12)
    assert(V3.prepare(opponent,1))
    assert(V3.occupants(opponent)==0 and V3.set_occupants(opponent,2))
    assert(V3.occupants(modern)==0 and V3.occupants(opponent)==2)
    opponent.free()
    var tank: Node3D=Models.build("tank",0,true,10)
    assert(tank!=null and not V3.prepare(tank,0))
    tank.free()
    print("PASS APC P06 V3 native boarding: real articulated 3D soldiers, physical pivot ramp, 0/1/2 seats, 5 rendered frames, 8 faction skin intact and G09 isolated")
    quit(0)
