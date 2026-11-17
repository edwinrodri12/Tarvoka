extends SceneTree

# 11 native Godot 4.3 A01 V12 renders for real human 360-degree art QA.
# No AI generated art, no imported screenshot and no mobile FPS claims.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Cabin=preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
var captures: int=0
var failures: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        failures+=1
        push_error("A01 V12 REVIEW: "+description)

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
        output="/tmp/tarvoka-a01-v12-native-review"
    _check(DirAccess.make_dir_recursive_absolute(output)==OK,
        "create capture folder")
    var viewport:=SubViewport.new()
    # 320x180 native resolution is a real smartphone 16:9 readability test.
    viewport.size=Vector2i(320,180)
    viewport.own_world_3d=true
    viewport.msaa_3d=Viewport.MSAA_2X
    viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var camera:=Camera3D.new()
    camera.current=true
    camera.fov=48
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
    _check(Cabin.has_model(model),"actual A01 V12 sculpt loaded")
    # Frame at tactical camera scale; V12 geometry must remain readable
    # while the full fuselage and rotor clear the camera edges.
    var distance: float=5.6
    # Keep exactly the same native 320x180 rendered pixels for the V6 control.
    var v10_reference: Dictionary={}
    for n in range(8):
        var angle: float=TAU*float(n)/8.0
        camera.position=Vector3(sin(angle)*distance,3.30,
            cos(angle)*distance)
        camera.look_at(Vector3(0,0.97,0),Vector3.UP)
        await _save(viewport,output.path_join("a01_v12_360_%02d.png" % n))
        if n%2==0:
            v10_reference[n]=viewport.get_texture().get_image().duplicate()
    # Four identical in-scene V11 baseline shots at 320x180, same lighting,
    # camera, pose and faction. A true comparison: hide ONLY V12 geometry.
    _check(Cabin.set_enabled(model,false),"disable V12 for four comparison frames")
    var changed_pixels: int=0
    var sample_pixels: int=0
    for idx in [0,2,4,6]:
        var angle: float=TAU*float(idx)/8.0
        camera.position=Vector3(sin(angle)*distance,3.30,
            cos(angle)*distance)
        camera.look_at(Vector3(0,0.97,0),Vector3.UP)
        await _save(viewport,output.path_join("a01_v12_baseline_v11_%02d.png" % idx))
        var previous: Image=viewport.get_texture().get_image()
        var finished: Image=v10_reference.get(idx) as Image
        _check(finished!=null and previous!=null and
            finished.get_size()==Vector2i(320,180) and
            previous.get_size()==Vector2i(320,180),
            "real original and new 320x180 framebuffer sizes match")
        if finished!=null and previous!=null:
            for yy in range(180):
                for xx in range(320):
                    var a: Color=finished.get_pixel(xx,yy)
                    var b: Color=previous.get_pixel(xx,yy)
                    sample_pixels+=1
                    var difference: float=maxf(absf(a.r-b.r),
                        maxf(absf(a.g-b.g),absf(a.b-b.b)))
                    if difference>0.085:
                        changed_pixels+=1
    print("A01 V12 VS V11 NATIVE 320p: %d changed out of %d sampled pixels" % [
        changed_pixels,sample_pixels])
    _check(changed_pixels>12,
        "V12 frontal silhouette details visible at 320p beyond subpixels")
    _check(changed_pixels<sample_pixels*0.08,
        "V12 preserves original silhouette and faction enamel")
    _check(Cabin.set_enabled(model,true),"restore V12 before physical detail macros")
    # True closeups at the earlier full-resolution native Godot setting.
    viewport.size=Vector2i(960,720)
    # Use model-to-world coordinates (the attack helicopter is scaled to
    # 0.77 and lowered 0.11 in UnitModels3D). Previous V12 closeups aimed
    # at raw model coordinates, cutting off the gearbox and rotor ring.
    # Camera probes use actual scaled A01 node-to-global transforms.
    var nose_focus: Vector3=model.to_global(Vector3(0,0.94,-1.53))
    camera.position=nose_focus+Vector3(0.28,0.43,-2.85)
    camera.look_at(nose_focus,Vector3.UP)
    await _save(viewport,output.path_join("a01_v12_morro_frontal.png"))
    var cheek_focus: Vector3=model.to_global(Vector3(0.38,1.055,-1.16))
    camera.position=cheek_focus+Vector3(2.15,0.65,-1.43)
    camera.look_at(cheek_focus,Vector3.UP)
    await _save(viewport,output.path_join("a01_v12_blindaje_lateral.png"))
    var gimbal_focus: Vector3=model.to_global(Vector3(0.215,0.57,-1.33))
    camera.position=gimbal_focus+Vector3(2.0,0.46,-1.78)
    camera.look_at(gimbal_focus,Vector3.UP)
    await _save(viewport,output.path_join("a01_v12_cardan_canon.png"))
    var muzzle_focus: Vector3=model.to_global(Vector3(0,0.57,-1.79))
    camera.position=muzzle_focus+Vector3(0.38,0.18,-2.25)
    camera.look_at(muzzle_focus,Vector3.UP)
    await _save(viewport,output.path_join("a01_v12_boca_canon.png"))
    _check(captures==16,"eight V12 320x180 orbital, four same-scene V11 reference and four full-resolution nose/gun views")
    if failures>0:
        push_error("A01 V12: failed %d renders" % failures)
        quit(1)
        return
    print("PASS A01 V12 CAPTURE: 16 native Godot frames, 8 V12 tactical 320x180, 4 exact V11 references and 4 high-res front armour/gimbal/gun macros")
    quit(0)
