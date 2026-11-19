extends SceneTree

# G15 original *native Godot* geometry QA; does not touch tactical rules.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const EW = preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("G15 ART V1: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1024,768)
    var stage := Node3D.new()
    root.add_child(stage)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 5.8
    camera.position = Vector3(4.7,4.0,5.7)
    stage.add_child(camera)
    camera.look_at(Vector3(0,1.55,0))
    camera.current = true
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48,-31,0)
    key.light_energy = 1.9
    stage.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-26,132,0)
    fill.light_energy = 0.84
    fill.light_color = Color("#b6cfe1")
    stage.add_child(fill)
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#26333d")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#a7b7c6")
    env.ambient_light_energy = 0.70
    world.environment = env
    stage.add_child(world)
    var capture_dir := ProjectSettings.globalize_path("res://build/qa/g15-v1")
    DirAccess.make_dir_recursive_absolute(capture_dir)
    var swatches: Array[Color] = []
    for faction in range(8):
        var vehicle := Models.build("ew_mobile",faction,true,13)
        check(vehicle != null, "faction %d native model built" % faction)
        if vehicle == null:
            continue
        stage.add_child(vehicle)
        check(EW.has_model(vehicle), "faction %d has original G15 rig" % faction)
        check(bool(vehicle.get_meta("tarvoka_g15_art_only",false)),
            "no fictional EW combat ability is registered")
        var wheels := vehicle.find_child(EW.WHEEL_GROUP,true,false)
        check(wheels != null and wheels.get_child_count() == 6,
            "G15 has six genuine wheel pivots")
        var tire := vehicle.find_child("G15_RubberTire_-1_0",true,false) as MeshInstance3D
        var rim := vehicle.find_child("G15_Rim_-1_0",true,false) as MeshInstance3D
        var panel := vehicle.find_child("G15_SidePaint_-1",true,false) as MeshInstance3D
        check(tire != null and rim != null and panel != null,
            "PBR tire, metal wheel rim and faction panel exist")
        if tire != null:
            var rubber := tire.material_override as StandardMaterial3D
            check(rubber != null and rubber.metallic == 0.0 and rubber.roughness > 0.85,
                "tires are MATTE RUBBER and not glossy metal")
        if rim != null:
            var machined := rim.material_override as StandardMaterial3D
            check(machined != null and machined.metallic >= 0.8,
                "rim genuinely uses machined-metal PBR")
        if panel != null:
            var paint := panel.material_override as StandardMaterial3D
            if paint != null:
                swatches.append(paint.albedo_color)
            check(paint != null and paint.clearcoat_enabled,
                "faction enamel genuinely has separate clearcoat")
        check(vehicle.find_child(EW.MAST,true,false) != null and
            vehicle.find_child(EW.ROTOR,true,false) != null,
            "real mast pivot and independent directional antenna exist")
        check(vehicle.find_child("G13_Autocannon_-1",true,false) == null,
            "G15 never inherits antiaircraft cannons")
        check(Models.pose_model("ew_mobile",vehicle,"move",0.45),
            "6-wheel rolling pose is available")
        if wheels != null:
            check(absf((wheels.get_child(0) as Node3D).rotation.x) > 0.1,
                "physical tire rotates when vehicle drives")
        check(Models.pose_model("ew_mobile",vehicle,"deploy",0.0),
            "antenna starts stowed")
        var mast := vehicle.find_child(EW.MAST,true,false) as Node3D
        if mast != null:
            check(absf(mast.rotation_degrees.x+58.0) < 0.01,
                "mast folding angle -58 deg")
        check(Models.pose_model("ew_mobile",vehicle,"scan",0.50),
            "directional antenna scans")
        check(Models.pose_model("ew_mobile",vehicle,"jam",0.50),
            "visual interference demonstration exists")
        var pulse := vehicle.find_child(EW.PULSE,true,false) as MeshInstance3D
        check(pulse != null and pulse.visible, "non-gameplay signal preview visible")
        Models.restore_model_pose("ew_mobile",vehicle)
        check(str(vehicle.get_meta("tarvoka_g15_visual_pose","")) == "idle",
            "all poses restore without reconstructing meshes")
        if mast != null:
            check(mast.rotation == Vector3.ZERO, "mast restores exactly")
        if pulse != null:
            check(not pulse.visible, "signal preview disappears when idle")
        for angle in range(2):
            camera.position = (
                Vector3(4.7,4.0,5.7) if angle == 0 else
                Vector3(-5.8,2.4,1.6))
            camera.look_at(Vector3(0,1.55,0))
            await process_frame
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            var path := capture_dir.path_join("g15_f%02d_view%d.png" % [faction,angle])
            check(image != null and image.get_width() >= 512 and
                image.save_png(path) == OK,
                "real Godot camera PNG "+path)
        stage.remove_child(vehicle)
        vehicle.free()
    check(swatches.size() == 8, "all 8 original faction paints are inspected")
    if swatches.size() == 8:
        for i in range(8):
            for j in range(i+1,8):
                check(swatches[i] != swatches[j],
                    "all eight original faction colors must differ")
    var mobile := Models.build("ew_mobile",0,false,8)
    check(mobile != null and EW.has_model(mobile), "light Android LOD8 retains 3D silhouette")
    if mobile != null:
        check(mobile.find_child(EW.MAST,true,false) != null,
            "Android LOD8 preserves EW identity")
        mobile.free()
    stage.queue_free()
    await process_frame
    if failures > 0:
        print("FAIL G15 V1 3D: %d assertions" % failures)
        quit(1)
    else:
        print("PASS G15 V1 NATIVE 3D: 8 factions, 16 PNG, six rubber tires, antenna poses, LOD8")
        quit(0)
