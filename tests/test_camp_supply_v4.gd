extends SceneTree
const Camp = preload("res://scripts/ui/CampModels3DV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const OUT := "res://build/qa/camps-supply-v4"
const ANGLES := [Vector3(9.8, 8.1, -10), Vector3(-9.8, 8.1, -10),
    Vector3(9.8, 8.1, 10), Vector3(-9.8, 8.1, 10)]
var failures: int = 0
var audits: int = 0
var captures: int = 0
func check(ok: bool, description: String) -> void:
    if not ok:
        failures += 1
        push_error("CAMP V4: " + description)
func _initialize() -> void:
    call_deferred("_run")
func _collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        meshes.append(node as MeshInstance3D)
    for child in node.get_children():
        _collect(child, meshes)
func _key(p: Vector3) -> String:
    return "%d,%d,%d" % [roundi(p.x * 100000.0), roundi(p.y * 100000.0), roundi(p.z * 100000.0)]
func _closed(mesh: Mesh) -> bool:
    var tris: PackedVector3Array = mesh.get_faces()
    if tris.size() < 12 or tris.size() % 3 != 0:
        return false
    var edges: Dictionary = {}
    for i in range(0, tris.size(), 3):
        if (tris[i + 1] - tris[i]).cross(tris[i + 2] - tris[i]).length_squared() < 0.000000000001:
            return false
        for side in range(3):
            var a: String = _key(tris[i + side])
            var b: String = _key(tris[i + (side + 1) % 3])
            var key: String = a + "|" + b if a < b else b + "|" + a
            edges[key] = int(edges.get(key, 0)) + 1
    for key in edges:
        if edges[key] != 2:
            return false
    return true
func _audit(faction: int, lod: int, damage: int) -> Node3D:
    var model: Node3D = Camp.build("suministros", faction, lod, damage)
    check(model != null, "V4 builds")
    if model == null:
        return null
    audits += 1
    check(int(model.get_meta("suministros_art_v4", 0)) == 4, "V4 metadata")
    check(model.get_meta("no_gameplay_effects", false) and model.get_meta("temporary_structure", false), "Art-only temporary structure")
    var meshes: Array[MeshInstance3D] = []
    _collect(model, meshes)
    var sculpted: int = 0
    var faction_count: int = 0
    for p in meshes:
        var mat: StandardMaterial3D = p.material_override as StandardMaterial3D
        check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque material " + str(p.name))
        if mat != null and faction >= 0 and mat.albedo_color == Style.faction_color(faction):
            faction_count += 1
        if p.get_meta("supply_v4_closed", false) and p.mesh is ArrayMesh:
            sculpted += 1
            check(_closed(p.mesh), "Watertight triangle edge topology " + str(p.name))
    check(sculpted >= 1 if damage == 3 else sculpted >= 25, "Substantial custom sculpture")
    check(faction_count >= 3 if damage == 3 else faction_count >= 15, "Faction paint")
    var core: Node3D = model.get_node_or_null("EquipamientoDesplegable/SupplyV2_PremiumRig/SupplyV4_IndustrialSculpt") as Node3D
    if damage == 3:
        check(core == null, "Destroyed camp cannot resurrect")
    else:
        check(core != null, "V4 built within V2 original hierarchy")
        if core != null:
            var rear: Node3D = core.get_node("V4_RearGablePivot") as Node3D
            check(rear.has_node("V4_GableClosedPanel"), "Actual rear closure")
            check(Camp.pose_deploy(model, 0.0) and absf(rear.rotation_degrees.x) > 80.0, "Gable folds")
            check(Camp.pose_deploy(model, 1.0) and absf(rear.rotation_degrees.x) < 0.01, "Gable reopens")
        check(model.has_node("EquipamientoDesplegable/SupplyV2_PremiumRig/V2_MangueraArticulada/V4_ContinuousHose"), "Continuous hose in moving rig")
        check(model.has_node("EquipamientoDesplegable/SupplyV2_PremiumRig/V2_DepositoCombustibleSellado_0/V4_TankPressureShell"), "Curved tank shell")
    return model
func _shot(viewport: SubViewport, name: String) -> void:
    for i in range(5):
        await process_frame
    var image: Image = viewport.get_texture().get_image()
    check(image != null and not image.is_empty(), "Native image")
    if image == null or image.is_empty():
        return
    var lit: int = 0
    for y in range(75, image.get_height() - 55, 20):
        for x in range(90, image.get_width() - 90, 20):
            if image.get_pixel(x, y).get_luminance() > 0.29:
                lit += 1
    check(lit > 14, "Visible sculpture " + name)
    check(image.save_png(ProjectSettings.globalize_path(OUT + "/" + name + ".png")) == OK, "Saved " + name)
    captures += 1
func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) == OK, "Output")
    var viewport := SubViewport.new()
    viewport.size = Vector2i(960, 720)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var stage := Node3D.new()
    viewport.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#1C2C37")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#E6F0EA")
    env.environment.ambient_light_energy = 0.74
    stage.add_child(env)
    var lamp := DirectionalLight3D.new()
    lamp.rotation_degrees = Vector3(-51, -35, 0)
    lamp.light_energy = 1.67
    stage.add_child(lamp)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 10.4
    stage.add_child(camera)
    camera.current = true
    for faction in range(-1, 8):
        for lod in [8, 13]:
            for damage in range(4):
                var model: Node3D = _audit(faction, lod, damage)
                if model == null:
                    continue
                if faction == 0 and damage == 0:
                    stage.add_child(model)
                    for i in range(4):
                        camera.size = 10.4
                        camera.position = ANGLES[i]
                        camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
                        await _shot(viewport, "v4_lod%d_angle%d" % [lod, i])
                    if lod == 13:
                        camera.size = 5.7
                        camera.position = Vector3(9, 5.3, -9)
                        camera.look_at(Vector3(-2.0, 0.8, -1.5), Vector3.UP)
                        await _shot(viewport, "v4_close_service")
                        camera.position = Vector3(8, 4.3, 10)
                        camera.look_at(Vector3(1.0, 1.65, 2.35), Vector3.UP)
                        await _shot(viewport, "v4_close_rear")
                        camera.size = 10.4
                        camera.position = ANGLES[0]
                        camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
                        Camp.pose_deploy(model, 0.0)
                        await _shot(viewport, "v4_folded")
                    stage.remove_child(model)
                elif faction == 0 and lod == 13 and damage in [1, 2, 3]:
                    stage.add_child(model)
                    camera.size = 10.4
                    camera.position = ANGLES[0]
                    camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
                    await _shot(viewport, "v4_damage%d" % damage)
                    stage.remove_child(model)
                model.free()
    var baseline: Node3D = Camp.build("suministros", 0, 13, 0, false)
    check(baseline != null and not baseline.has_meta("suministros_art_v4"), "V3 preserved for direct comparison")
    if baseline != null:
        stage.add_child(baseline)
        camera.size = 10.4
        for i in [0, 2]:
            camera.position = ANGLES[i]
            camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
            await _shot(viewport, "v3_reference_angle%d" % i)
        stage.remove_child(baseline)
        baseline.free()
    check(audits == 72, "8 factions plus neutral x LOD x damage")
    check(captures == 16, "16 actual Godot images")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL SUPPLY CAMP V4 NATIVE: %d" % failures)
        quit(1)
        return
    print("PASS SUPPLY CAMP V4 NATIVE: 72 variants, closed sculpt meshes, 16 images")
    quit(0)
