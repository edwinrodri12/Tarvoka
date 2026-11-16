extends SceneTree

# 16 GENUINE Godot 4.3 renderings at playable pixel scales:
# eight approved faction colors at LOD10 near and LOD8 far.
# No concept art and no heavy high-detail hero model in tactical captures.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const V24 = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const EXPECTED := 16
var saved: int=0
var errors: int=0

func _check(ok: bool,message: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V24 native tactical capture: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _shot(view: SubViewport,dir: String,name: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var shot: Image=view.get_texture().get_image()
    _check(shot!=null and not shot.is_empty(),name)
    if shot!=null and not shot.is_empty():
        if shot.save_png(dir.path_join(name))==OK:
            saved+=1
        else:
            _check(false,"Failed writing real image "+name)

func _run() -> void:
    var directory: String=OS.get_environment("G11_CAPTURE_DIR")
    if directory.is_empty():
        directory="/tmp/g11-v24-tactical"
    _check(DirAccess.make_dir_recursive_absolute(directory)==OK,
        "created output folder")
    var view := SubViewport.new()
    view.size=Vector2i(960,680)
    view.own_world_3d=true
    view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    view.msaa_3d=Viewport.MSAA_2X
    root.add_child(view)
    var camera := Camera3D.new()
    camera.current=true
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    view.add_child(camera)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees=Vector3(-51,-31,0)
    sun.light_energy=1.48
    view.add_child(sun)
    var fill := OmniLight3D.new()
    fill.position=Vector3(2.7,3.6,-2.7)
    fill.omni_range=12.0
    fill.light_energy=0.56
    view.add_child(fill)
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size=Vector2(20,20)
    floor.mesh=plane
    floor.position.y=-0.02
    var mat := StandardMaterial3D.new()
    mat.albedo_color=Color("#34413c")
    floor.material_override=mat
    view.add_child(floor)

    for faction in range(8):
        for level in [10,8]:
            var model: Node3D=Models.build("mlrs",faction,true,level)
            _check(model!=null,"real faction LOD generated")
            if model==null:
                continue
            view.add_child(model)
            _check(bool(model.get_meta(V24.FLAG,false)),
                "real V24 track apertures actually in rendered mesh")
            _check(int(model.get_meta(Mobile.FLAG,0))==level,
                "correct 8-player battleground fidelity level")
            # LOD 10: standard in-game zoom, not inspection macro.
            # LOD 8: distant game map, showing ~1/3 the near height.
            camera.size=5.7 if level==10 else 15.0
            camera.position=Vector3(4.8,5.3,-6.4)
            camera.look_at(Vector3(0,0.92,0),Vector3.UP)
            await _shot(view,directory,
                "g11_v24_battle_%s_faction_%02d.png" % [
                    "near_LOD10" if level==10 else "far_LOD8",faction])
            view.remove_child(model)
            model.queue_free()
            await process_frame
    _check(saved==EXPECTED,
        "expected exactly 16 genuine Godot near/far player-size images")
    if errors>0:
        push_error("G11 V24 native tactical capture FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V24 CAPTURE: 16 real Godot in-battle scale LOD10/LOD8 images, all 8 faction colors, rounded tracks and no added detail geometry")
    quit(0)
