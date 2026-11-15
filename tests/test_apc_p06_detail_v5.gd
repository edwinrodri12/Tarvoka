extends SceneTree

# P06 Bastion V5: inspect REAL editable Godot geometry, not illustration.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Finish=preload("res://scripts/ui/APCFinishV3.gd")
const Detail=preload("res://scripts/ui/APCDetailV5.gd")
const SCREEN: Vector2i=Vector2i(720,480)

func _initialize() -> void:
    call_deferred("_run")

func _capture(vp: SubViewport) -> Image:
    for i in range(7):
        await process_frame
    var image: Image=vp.get_texture().get_image()
    assert(not image.is_empty())
    return image

func _run() -> void:
    var old: Node3D=Models.build("apc",2,true,12)
    var unit: Node3D=Models.build("apc",2,true,13)
    assert(old!=null and unit!=null)
    assert(not old.get_meta(Detail.FLAG,false))
    assert(unit.get_meta("tarvoka_apc_finish_v3",false))
    assert(unit.get_meta(Detail.FLAG,false))
    assert(unit.get_meta("tarvoka_apc_v5_bolt_count",0)==36)
    assert(unit.get_meta("tarvoka_apc_v5_visual_meshes",0)==7)
    var panel: Node3D=unit.find_child(Detail.ROOT,true,false) as Node3D
    var roof: Node3D=unit.find_child(Detail.ROOF,true,false) as Node3D
    var turret: Node3D=unit.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    var sensor: Node3D=unit.find_child(
        "P06V5_SensoresEnTorreta",true,false) as Node3D
    var paint: MeshInstance3D=unit.find_child(
        "P06V5_TapasTechoEnrasadas",true,false) as MeshInstance3D
    var rim: MeshInstance3D=unit.find_child(
        "P06V5_BordesHatchYJuntas",true,false) as MeshInstance3D
    var screws: MultiMeshInstance3D=unit.find_child(
        Detail.BOLTS,true,false) as MultiMeshInstance3D
    assert(panel!=null and roof!=null and sensor!=null)
    assert(sensor.get_parent()==turret)
    assert(paint!=null and paint.mesh is ArrayMesh)
    assert(rim!=null and rim.mesh is ArrayMesh)
    assert(screws!=null and screws.multimesh.instance_count==36)
    assert(Detail.set_enabled(unit,false))
    assert(not panel.visible and not sensor.visible)
    assert(Detail.set_enabled(unit,true))
    assert(panel.visible and sensor.visible)
    var meshes: int=Models.inspect_meshes(unit)
    assert(meshes>Models.inspect_meshes(old))
    assert(Models.apply_faction_palette(unit,1)>15)
    var blue: Color=(paint.material_override as StandardMaterial3D).albedo_color
    assert(Models.apply_faction_palette(unit,2)>15)
    var green: Color=(paint.material_override as StandardMaterial3D).albedo_color
    assert(blue!=green)
    assert(Models.inspect_meshes(unit)==meshes)
    assert(Finish.set_tactical_lod(unit,true)>0)
    assert(not rim.visible and not screws.visible)
    assert(paint.visible)
    assert(Finish.set_tactical_lod(unit,false)>0)
    assert(rim.visible and screws.visible)
    assert(Finish.apply_stage(unit,4))
    assert(not roof.visible)
    assert(Finish.apply_stage(unit,0))
    assert(roof.visible)
    assert(Models.inspect_meshes(unit)==meshes)
    assert(Finish.animate_impact(unit,"hit_explosive",0.22))

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var vp:=SubViewport.new()
    vp.size=SCREEN
    vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    vp.own_world_3d=true
    root.add_child(vp)
    vp.add_child(unit)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.5
    camera.position=Vector3(4.6,3.0,5.8)
    vp.add_child(camera)
    camera.look_at(Vector3(0,0.53,0),Vector3.UP)
    camera.current=true
    var sunlight:=DirectionalLight3D.new()
    sunlight.rotation_degrees=Vector3(-52,-38,0)
    sunlight.light_energy=1.8
    vp.add_child(sunlight)
    var env_node:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#172630")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#C5D8E7")
    env.ambient_light_energy=0.78
    env_node.environment=env
    vp.add_child(env_node)

    assert(Detail.set_enabled(unit,false))
    var v3: Image=await _capture(vp)
    assert(Detail.set_enabled(unit,true))
    var v5: Image=await _capture(vp)
    camera.position=Vector3(-4.7,3.3,-5.4)
    camera.look_at(Vector3(0,0.53,0),Vector3.UP)
    var rear: Image=await _capture(vp)
    assert(Finish.apply_stage(unit,4))
    var wreck: Image=await _capture(vp)
    assert(Finish.apply_stage(unit,0))
    assert(roof.visible)

    var comparison:=Image.create(
        SCREEN.x*4,SCREEN.y,false,Image.FORMAT_RGBA8)
    for i in range(4):
        var img: Image=[v3,v5,rear,wreck][i]
        if img.get_format()!=Image.FORMAT_RGBA8:
            img.convert(Image.FORMAT_RGBA8)
        comparison.blit_rect(img,Rect2i(Vector2i.ZERO,SCREEN),
            Vector2i(i*SCREEN.x,0))
    assert(comparison.save_png(
        "res://artifacts/tarvoka_apc_p06_v3_v5_real_godot_views.png")==OK)
    vp.queue_free()
    old.free()
    print("PASS TARVOKA APC P06 V5 REAL MODEL: 7 sculpted meshes, 36 instanced bolts, faction paint, roof wreck/repair, LOD and V3/V5 Studio comparison")
    quit(0)
