extends SceneTree

# 11 native Godot 4.3 A01 V6 renders for real human 360-degree art QA.
# No AI generated art, no imported screenshot and no mobile FPS claims.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Cabin=preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
var captures: int=0
var failures: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V6 REVIEW: "+description)

func _save(viewport: SubViewport,path: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img: Image=viewport.get_texture().get_image()
    _check(img!=null and not img.is_empty(),"real rendered frame "+path)
    if img!=null and not img.is_empty():
        var result: Error=img.save_png(path)
        _check(result==OK,"write actual native PNG")
        if result==OK:
            captures+=1

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var output: String=OS.get_environment("A01_CAPTURE_DIR")
    if output.is_empty():
        output="/tmp/tarvoka-a01-v6-native-review"
    _check(DirAccess.make_dir_recursive_absolute(output)==OK,
        "create capture folder")
    var viewport:=SubViewport.new()
    viewport.size=Vector2i(960,720)
    viewport.own_world_3d=true
    viewport.msaa_3d=Viewport.MSAA_2X
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var camera:=Camera3D.new()
    camera.current=true
    camera.fov=45
    viewport.add_child(camera)
    var atmosphere:=Environment.new()
    atmosphere.background_mode=Environment.BG_COLOR
    atmosphere.background_color=Color("#253541")
    atmosphere.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    atmosphere.ambient_light_color=Color("#b2c3cc")
    atmosphere.ambient_light_energy=0.85
    var world:=WorldEnvironment.new()
    world.environment=atmosphere
    viewport.add_child(world)
    var key:=DirectionalLight3D.new()
    key.rotation_degrees=Vector3(-52,-33,0)
    key.light_energy=1.65
    key.shadow_enabled=true
    viewport.add_child(key)
    var fill:=OmniLight3D.new()
    fill.position=Vector3(-3.0,3.2,-2.1)
    fill.omni_range=14
    fill.light_energy=0.45
    viewport.add_child(fill)
    var base:=MeshInstance3D.new()
    var board:=PlaneMesh.new()
    board.size=Vector2(14,14)
    base.mesh=board
    # V5 skids rest close to the capture ground plane.
    base.position.y=-0.04
    var boardmat:=StandardMaterial3D.new()
    boardmat.albedo_color=Color("#46555b")
    base.material_override=boardmat
    viewport.add_child(base)
    var model: Node3D=Models.build("attack_heli",0,true,14)
    _check(model!=null,"full helicopter model loads")
    if model==null:
        quit(1)
        return
    viewport.add_child(model)
    _check(Cabin.has_model(model),"actual A01 V6 sculpt loaded")
    var distance: float=7.2
    for n in range(8):
        var angle: float=TAU*float(n)/8.0
        camera.position=Vector3(sin(angle)*distance,3.30,
            cos(angle)*distance)
        camera.look_at(Vector3(0,0.97,0),Vector3.UP)
        await _save(viewport,output.path_join("a01_v6_360_%02d.png" % n))
    # Inspect functional shock sleeves with their attachment pins.
    camera.position=Vector3(1.63,0.98,-0.63)
    camera.look_at(Vector3(0.41,0.37,-0.51),Vector3.UP)
    await _save(viewport,output.path_join("a01_v6_amortiguador_bisagra.png"))
    # Verify four short skid pads, rail collars and rounded end protection.
    camera.position=Vector3(1.45,0.56,0.32)
    camera.look_at(Vector3(0.51,0.03,0.10),Vector3.UP)
    await _save(viewport,output.path_join("a01_v6_abrazadera_patines.png"))
    # Inspect real seam where engine saddles meet the nacelle and hull.
    camera.position=Vector3(1.68,1.92,0.84)
    camera.look_at(Vector3(0.32,1.09,0.49),Vector3.UP)
    await _save(viewport,output.path_join("a01_v6_union_motor.png"))
    _check(captures==11,"eight 360-degree views and 3 V6 shock/pad/engine joint details")
    if failures>0:
        push_error("A01 V6: failed %d renders" % failures)
        quit(1)
        return
    print("PASS A01 V6 CAPTURE: 11 native Godot 4.3 frames with 8 orbital views and 3 shock, rail and engine joint macros")
    quit(0)
