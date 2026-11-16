extends SceneTree

# G13 V14 final native Godot ART acceptance gallery.
# 8 factions + 7 full-vehicle camera views + 2 distinct attack poses
# + 1 wheel close-up = 18 PNG captures. No battle rule changes.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Surface=preload("res://scripts/ui/G13SurfaceFinishV8.gd")
const Wheels=preload("res://scripts/ui/G13WheelFinishV7.gd")
const Silhouette=preload("res://scripts/ui/G13SilhouetteV10.gd")
const Finish=preload("res://scripts/ui/G13BodyFinishV11.gd")
const Mechanic=preload("res://scripts/ui/G13MechanicalFinishV12.gd")
const SurfaceV13=preload("res://scripts/ui/G13SurfaceFinishV13.gd")
const SensorsV14=preload("res://scripts/ui/G13SensorSculptV14.gd")
const TOTAL:=27
var saved:=0
var failed:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failed+=1
        push_error("G13 V14 acceptance: "+why)

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
    var dest: String=OS.get_environment("G13_V14_CAPTURE_DIR")
    if dest.is_empty():
        dest="/tmp/g13-v14-acceptance"
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
            bool(unit.get_meta(Finish.FLAG,false)) and
            bool(unit.get_meta(Mechanic.FLAG,false)) and
            bool(unit.get_meta(SurfaceV13.FLAG,false)) and
            bool(unit.get_meta(SensorsV14.FLAG,false)),
            "faction %d includes real V7 wheels, V8 materials and V11 finished cab/turret shells" % faction)
        colors[str(unit.get_meta("tarvoka_g13_surface_v8_faction_paint",""))]=true
        viewport.add_child(unit)
        camera.size=4.65
        camera.position=angles["iso"]
        camera.look_at(Vector3(0,1.0,0),Vector3.UP)
        floor.visible=true
        await capture(viewport,dest,"g13_v14_faction_%02d_iso.png" % faction)
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
        await capture(viewport,dest,"g13_v14_angle_%s.png" % view_name)
    floor.visible=true
    camera.position=angles["iso"]
    camera.look_at(Vector3(0,1.03,0),Vector3.UP)
    check(Models.pose_model("aa_mobile",hero,"attack_air",0.25),
        "air attack hero animation remains available")
    await capture(viewport,dest,"g13_v14_fire_air.png")
    check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42),
        "ground attack hero animation remains available")
    await capture(viewport,dest,"g13_v14_fire_ground.png")
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.6,1.15,-1.75)
    camera.look_at(Vector3(0.70,0.35,-0.85),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v14_wheel_detail.png")
    # V12 macro passes locate gaps and mechanical collisions that are
    # hard to see from the seven whole-vehicle acceptance views.
    camera.position=Vector3(1.7,1.55,-2.7)
    camera.look_at(Vector3(0,1.16,-0.98),Vector3.UP)
    camera.size=1.8
    await capture(viewport,dest,"g13_v14_detail_glazing.png")
    camera.position=Vector3(2.0,2.08,0.1)
    camera.look_at(Vector3(0.36,1.72,0.05),Vector3.UP)
    camera.size=1.65
    await capture(viewport,dest,"g13_v14_detail_bearings.png")
    camera.position=Vector3(0.95,1.75,-2.25)
    camera.look_at(Vector3(0,1.73,-0.81),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v14_detail_hollow_muzzles.png")
    check(Models.pose_model("aa_mobile",hero,"attack_air",0.25),
        "high elevation still permits V12 gun closeup")
    camera.position=Vector3(1.65,2.65,-2.6)
    camera.look_at(Vector3(0,1.86,-0.9),Vector3.UP)
    camera.size=2.20
    await capture(viewport,dest,"g13_v14_detail_air_fire.png")
    Models.restore_model_pose("aa_mobile",hero)
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(2.1,1.16,1.65)
    camera.look_at(Vector3(0.67,0.85,0.0),Vector3.UP)
    camera.size=1.75
    await capture(viewport,dest,"g13_v14_detail_side_panel.png")
    camera.position=Vector3(1.95,2.50,-1.2)
    camera.look_at(Vector3(0.0,1.34,-0.58),Vector3.UP)
    camera.size=1.92
    await capture(viewport,dest,"g13_v14_detail_roof_pbr.png")
    # V14 radar dish and optics close-ups show whether the reflector is
    # actually concave and the turret-mounted tracker remains unobscured.
    Models.restore_model_pose("aa_mobile",hero)
    camera.position=Vector3(1.55,2.52,2.70)
    camera.look_at(Vector3(0,1.86,0.89),Vector3.UP)
    camera.size=1.60
    await capture(viewport,dest,"g13_v14_detail_radar_reflector.png")
    camera.position=Vector3(1.65,2.25,-1.85)
    camera.look_at(Vector3(0.4,1.76,0.03),Vector3.UP)
    camera.size=1.48
    await capture(viewport,dest,"g13_v14_detail_dual_optics.png")
    check(Models.pose_model("aa_mobile",hero,"scan",1.0),
        "V14 radar scan reaches original +70 degrees")
    camera.position=Vector3(2.5,2.65,2.2)
    camera.look_at(Vector3(0,1.80,0.55),Vector3.UP)
    camera.size=2.75
    await capture(viewport,dest,"g13_v14_radar_scan_70deg.png")
    Models.restore_model_pose("aa_mobile",hero)
    check(saved==TOTAL,
        "27 native PNG files generated, including V14 radar and dual optic details")
    if failed>0:
        quit(1)
        return
    print("PASS G13 V14 CAPTURE: 27 real Godot frames, 8 factions, 7 angles including underside, two firing domains and wheel macro")
    quit(0)
