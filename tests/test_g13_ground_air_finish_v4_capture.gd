extends SceneTree

# 8 authentic Godot 4.3 frames: two faction paint variants, ground
# aiming vs ground salvo, and elevated air aiming vs air burst.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Dual=preload("res://scripts/ui/G13GroundAirFinishV4.gd")
const EXPECTED: int=8
var saved: int=0
var failures: int=0

func _check(ok: bool,label: String)->void:
    if not ok:
        failures+=1
        push_error("G13 V4 real 3D ground/air render: "+label)

func _shot(view: SubViewport,dir: String,label: String)->void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var frame:=view.get_texture().get_image()
    if frame!=null and not frame.is_empty() and (
            frame.save_png(dir.path_join(label))==OK):
        saved+=1
    else:
        _check(false,"native frame missing "+label)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var folder:=OS.get_environment("G13_V4_CAPTURE_DIR")
    if folder.is_empty():
        folder="/tmp/g13-v2-two-attack-modes"
    _check(DirAccess.make_dir_recursive_absolute(folder)==OK,
        "create Godot V2 render gallery")
    var view:=SubViewport.new()
    view.own_world_3d=true
    view.size=Vector2i(1080,720)
    view.msaa_3d=Viewport.MSAA_2X
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var sky:=WorldEnvironment.new()
    var env:=Environment.new()
    env.background_mode=Environment.BG_COLOR
    env.background_color=Color("#293f49")
    env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color=Color("#dce5e9")
    env.ambient_light_energy=0.61
    sky.environment=env
    view.add_child(sky)
    var sunlight:=DirectionalLight3D.new()
    sunlight.rotation_degrees=Vector3(-50,-32,0)
    sunlight.light_energy=1.20
    view.add_child(sunlight)
    var floor:=MeshInstance3D.new()
    var plane:=PlaneMesh.new()
    plane.size=Vector2(8,8)
    floor.mesh=plane
    var dirt:=StandardMaterial3D.new()
    dirt.albedo_color=Color("#54645c")
    floor.material_override=dirt
    floor.position.y=-0.005
    view.add_child(floor)
    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    camera.current=true
    camera.size=4.50
    camera.position=Vector3(3.7,2.85,-4.4)
    view.add_child(camera)
    camera.look_at(Vector3(0,1.0,0),Vector3.UP)
    for faction in [0,6]:
        var model:=Models.build("aa_mobile",faction,true,13)
        _check(model!=null and G13.has_model(model),
            "actual G13 hull loads with faction material")
        if model==null:
            continue
        view.add_child(model)
        for kind in ["attack_ground","attack_air"]:
            var short: String="ground" if kind=="attack_ground" else "air"
            _check(Models.pose_model("aa_mobile",model,kind,0.5),
                "real guns aim in selected domain")
            await _shot(view,folder,
                "g13_v4_faction_%d_%s_01_targeting.png" % [faction,short])
            var frame_t: float=0.42 if kind=="attack_ground" else 0.25
            _check(Models.pose_model("aa_mobile",model,kind,frame_t),
                "real twin muzzle burst triggers in "+short)
            var gun:=model.find_child(G13.GUNS,true,false) as Node3D
            var flashes:=gun.find_child("G13_MuzzleFlash_-1",
                true,false) as Node3D
            var opposite:=gun.find_child("G13_MuzzleFlash_1",
                true,false) as Node3D
            _check(flashes!=null and opposite!=null and (flashes.visible!=opposite.visible),
                "short pooled muzzle flash visible in native image")
            await _shot(view,folder,
                "g13_v4_faction_%d_%s_02_firing.png" % [faction,short])
        view.remove_child(model)
        model.queue_free()
        await process_frame
    _check(saved==EXPECTED,"eight real Godot render captures saved")
    if failures>0:
        push_error("G13 V4 real air/ground image QA FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G13 V4 CAPTURE: eight native 3D images with two faction colors and distinct terrestrial/air aim and muzzle flash modes")
    quit(0)
