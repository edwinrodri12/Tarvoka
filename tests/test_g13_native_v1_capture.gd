extends SceneTree

# Visual-only Godot proof: 8 original faction G13 models plus 4 model
# angles and four real articulation states in the 3D studio geometry.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const TOTAL=16
var saved: int=0
var errors: int=0

func _check(ok: bool,why: String)->void:
    if not ok:
        errors+=1
        push_error("G13 V1 native image validation: "+why)

func _capture(view: SubViewport,path: String,name: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img:=view.get_texture().get_image()
    if img!=null and not img.is_empty() and (
            img.save_png(path.path_join(name))==OK):
        saved+=1
    else:
        _check(false,"real GL image cannot be saved "+name)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var dest:=OS.get_environment("G13_V1_CAPTURE_DIR")
    if dest.is_empty():
        dest="/tmp/g13-aa-v1"
    _check(DirAccess.make_dir_recursive_absolute(dest)==OK,
        "create real Godot screenshot folder")
    var view:=SubViewport.new()
    view.size=Vector2i(1080,720)
    view.own_world_3d=true
    view.msaa_3d=Viewport.MSAA_2X
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var environment:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#263a47")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce6df")
    env.ambient_light_energy=0.64
    environment.environment=env
    view.add_child(environment)
    var sun:=DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-43,-28,0)
    sun.light_energy=1.20
    view.add_child(sun)
    var floor:=MeshInstance3D.new()
    floor.name="G13_VisualFloor"
    var plane:=PlaneMesh.new()
    plane.size=Vector2(8,8)
    floor.mesh=plane
    floor.material_override=StandardMaterial3D.new()
    (floor.material_override as StandardMaterial3D).albedo_color=Color("#55605c")
    floor.position.y=-0.005
    view.add_child(floor)
    var cam:=Camera3D.new()
    cam.projection=Camera3D.PROJECTION_ORTHOGONAL
    cam.size=4.6
    cam.current=true
    view.add_child(cam)
    var offsets: Array[Vector3]=[
        Vector3(3.9,3.05,4.0),
        Vector3(0.40,2.15,-5.1),
        Vector3(5.0,2.2,0.15),
        Vector3(1.5,2.0,5.4)
    ]
    for faction in range(8):
        var g13:=Models.build("aa_mobile",faction,true,13)
        _check(g13!=null and G13.has_model(g13),
            "real G13 approved class exists in all faction previews")
        if g13==null:
            continue
        view.add_child(g13)
        cam.position=offsets[0]
        cam.look_at(Vector3(0,0.88,0),Vector3.UP)
        await _capture(view,dest,"g13_v1_faction_%d_threequarter.png" % faction)
        view.remove_child(g13)
        g13.queue_free()
        await process_frame
    var model:=Models.build("aa_mobile",0,true,13)
    view.add_child(model)
    for i in range(4):
        Models.restore_model_pose("aa_mobile",model)
        cam.position=offsets[i]
        cam.look_at(Vector3(0,0.90,0),Vector3.UP)
        await _capture(view,dest,"g13_v1_view_%d.png" % i)
    var modes: Array[String]=["scan","aim","move","idle"]
    cam.position=offsets[0]
    cam.look_at(Vector3(0,0.91,0),Vector3.UP)
    for mode in modes:
        Models.pose_model("aa_mobile",model,mode,0.72)
        await _capture(view,dest,"g13_v1_pose_%s.png" % mode)
    _check(saved==TOTAL,
        "16 actual G13 native 3D screenshots: 8 factions, 4 views, 4 poses")
    model.queue_free()
    if errors>0:
        push_error("G13 V1 native screenshot generation FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G13 V1 CAPTURE: 16 real Godot 3D screenshots, eight factions, four views and four animations")
    quit(0)
