extends SceneTree

# G13 V10 final native Godot ART acceptance gallery.
# 8 factions + 7 full-vehicle camera views + 2 distinct attack poses
# + 1 wheel close-up = 18 PNG captures. No battle rule changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Surface=preload("res://scripts/ui/G13SurfaceFinishV8.gd")
const Wheels=preload("res://scripts/ui/G13WheelFinishV7.gd")
const Silhouette=preload("res://scripts/ui/G13SilhouetteV10.gd")
const CabRear=preload("res://scripts/ui/G13CabRearFinishV11.gd")
const BodyFinish=preload("res://scripts/ui/G13BodyFinishV11.gd")
const TOTAL:=18
var saved:=0
var failed:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failed+=1
        push_error("G13 V11 acceptance: "+why)

func capture(view: SubViewport,dir: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var picture: Image=view.get_texture().get_image()
    var ok: bool=picture!=null and not picture.is_empty()
    if ok:
        ok=picture.save_png(dir.path_join(name))==OK
    check(ok,"save native 3D frame "+name)
    if ok:
        saved+=1

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var dest: String=OS.get_environment("G13_V11_CAPTURE_DIR")
    if dest.is_empty():
        dest="/tmp/g13-v11-acceptance"
    check(DirAccess.make_dir_recursive_absolute(dest)==OK,
        "create capture directory")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(1080,720)
    viewport.own_world_3d=true
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#25343d")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#ccd5dd")
    env.ambient_light_energy=0.66
    environment.environment=env
    viewport.add_child(environment)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-43,-30,0)
    key.light_energy=1.3
    viewport.add_child(key)
    var fill:=DirectionalLight3D.new()
    fill.rotation_degrees=Vector3(-27,132,0)
    fill.light_energy=0.46
    fill.shadow_enabled=false
    viewport.add_child(fill)
    var floor:=MeshInstance3D.new()
    var plane:=PlaneMesh.new()
    plane.size=Vector2(8,8)
    floor.mesh=plane
    var floor_mat:=StandardMaterial3D.new()
    floor_mat.albedo_color=Color("#505d59")
    floor.material_override=floor_mat
    floor.position.y=-0.005
    viewport.add_child(floor)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.size=4.65
    camera.current=true
    viewport.add_child(camera)
    var angles: Dictionary={
        "iso":Vector3(3.8,3.0,4.2),
        "front":Vector3(0.25,1.7,-5.0),
        "rear":Vector3(0.25,1.7,5.0),
        "left":Vector3(-5.0,1.8,0.15),
        "right":Vector3(5.0,1.8,0.15),
        "top":Vector3(0.40,6.0,0.80),
        "under":Vector3(2.5,-2.3,3.5)
    }
    var colors: Dictionary={}
    for faction in range(8):
        var unit:=Models.build("aa_mobile",faction,true,13)
        check(unit!=null and G13.has_model(unit),
            "high-quality G13 generated for faction %d" % faction)
        if unit==null:
            continue
        check(bool(unit.get_meta(Surface.FLAG,false)) and
            bool(unit.get_meta(Wheels.FLAG,false)) and
            bool(unit.get_meta(Silhouette.FLAG,false)) and
            bool(unit.get_meta(CabRear.FLAG,false)) and
            bool(unit.get_meta(BodyFinish.FLAG,false)),
            "faction %d includes real V7 wheels, V8 materials, V10 shell and V11 roof/rear panels" % faction)
        colors[str(unit.get_meta("tarvoka_g13_surface_v8_faction_paint",""))]=true
        viewport.add_child(unit)
        camera.size=4.65
        camera.position=angles["iso"]
        camera.look_at(Vector3(0,1.0,0),Vector3.UP)
        floor.visible=true
        await capture(viewport,dest,"g13_v11_faction_%02d_iso.png" % faction)
        viewport.remove_child(unit)
        unit.free()
    check(colors.size()==8,"eight faction colors are distinct")

    var hero:=Models.build("aa_mobile",0,true,13)
    check(hero!=null,"inspection hero exists")
    if hero==null:
        quit(1)
        return
    viewport.add_child(hero)
    for view_name in ["iso","front","rear","left","right","top","under"]:
        Models.restore_model_pose("aa_mobile",hero)
        floor.visible=view_name!="under"
        camera.size=4.65
        camera.position=angles[view_name]
        camera.look_at(Vector3(0,0.91 if view_name=="under" else 1.03,0),
            Vector3.UP)
        await capture(viewport,dest,"g13_v11_angle_%s.png" % view_name)
    floor.visible=true
    camera.position=angles["iso"]
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    check(Models.pose_model("aa_mobile",hero,"attack_air",0.25),
        "air attack hero animation remains available")
    await capture(viewport,dest,"g13_v11_fire_air.png")
    check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
        "ground attack hero animation remains available")
    await capture(viewport,dest,"g13_v11_fire_ground.png")
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.6,1.15,-1.75)
    camera.look_at(Vector3(0.70,0.35,-0.85),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v11_wheel_detail.png")
    check(saved==TOTAL,
        "18 native PNG files generated, covering every requested view")
    if failed>0:
        quit(1)
        return
    print("PASS G13 V11 CAPTURE: 18 real Godot frames, 8 factions, 7 angles including underside, two firing domains and wheel macro")
    quit(0)
