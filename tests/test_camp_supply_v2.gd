extends SceneTree

# Independent genuine Godot 4.3 3D test for the first high-detail camp.
# Exhaustive 8 faction x 2 LOD x 4 damage = 64 solid geometry audits.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Supply = preload("res://scripts/ui/CampSupplyFinishV2.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const DEST := "res://build/qa/supply-camp-v2"
var failures: int = 0
var audits: int = 0
var shots: int = 0

func check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error("SUPPLY CAMP V2: " + why)

func _initialize() -> void:
    call_deferred("_run")

func _collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        meshes.append(node as MeshInstance3D)
    for child in node.get_children():
        _collect(child, meshes)

func _model(faction: int, lod: int, damage: int) -> Node3D:
    var camp: Node3D = Art.build("suministros", faction, lod, damage)
    check(camp != null, "Native supply V2 exists")
    if camp == null:
        return null
    audits += 1
    check(int(camp.get_meta("suministros_art_v2", -1)) == 2,
        "V2 art layer loaded")
    check(camp.get_meta("temporary_structure", false) == true,
        "Not permanent building")
    check(camp.get_meta("no_gameplay_effects", false) == true,
        "No tactical effects")
    check(camp.get_meta("no_unit_or_credit_production", false) == true,
        "Cannot produce money or units")
    check(str(camp.get_meta("builder_role", "")) == "infantry_logistic",
        "Only infantry logistic constructs this art")
    var rig: Node3D = camp.get_node_or_null(
        "EquipamientoDesplegable/" + Supply.CORE) as Node3D
    check((rig != null) == (damage < 3), "Damage destroys entire rig at D3")
    if damage < 3 and rig != null:
        check(rig.get_node_or_null("V2_EstacionBombeo") != null,
            "Protected fuel pump")
        check(rig.get_node_or_null("V2_MangueraArticulada") != null,
            "Articulated six-part hose")
        check(rig.get_node_or_null("V2_DepositoCombustibleSellado_0") != null,
            "Closed fuel reservoir")
        check(rig.get_node_or_null("V2_DepositoCombustibleSellado_1") != null,
            "Second fuel reservoir")
        check(rig.get_node_or_null("V2_CajaMunicionEstanca_0") != null,
            "Closed ammo crate")
        check(rig.get_node_or_null("V2_ArticulacionCubierta_-1") != null,
            "Physical roof hinge")
        check(rig.get_node_or_null("V2_ArticulacionCubierta_1") != null
            if damage < 2 else
            rig.get_node_or_null("V2_ArticulacionCubierta_1") == null,
            "Right roof wing removed only for severe damage")
    var meshes: Array[MeshInstance3D] = []
    _collect(camp, meshes)
    check(meshes.size() >= 18, "Physical closed meshes exist")
    var painted: int = 0
    for part in meshes:
        check(part.mesh is BoxMesh or part.mesh is CylinderMesh,
            "Only closed native meshes: " + part.name)
        if part.material_override is StandardMaterial3D:
            var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
            check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,
                "Opaque geometry: " + part.name)
            check(mat.cull_mode == BaseMaterial3D.CULL_BACK,
                "Solid outward faces: " + part.name)
            if mat.albedo_color == Style.faction_color(faction):
                painted += 1
        else:
            check(false, "Native material missing: " + part.name)
        var size: Vector3 = part.mesh.get_aabb().size
        check(size.x > 0.003 and size.y > 0.003 and size.z > 0.003,
            "No zero-thickness surfaces: " + part.name)
    check(painted >= 3, "Faction paint across platform, fuel and roof")
    if damage < 3 and rig != null:
        var left: Node3D = rig.get_node_or_null(
            "V2_ArticulacionCubierta_-1") as Node3D
        check(Art.pose_deploy(camp, 0.0), "Can stow camp")
        if left != null:
            check(absf(left.rotation_degrees.z + 70.0) < 0.01,
                "Real folded roof hinge angle")
        check(Art.pose_deploy(camp, 1.0), "Can deploy camp")
        if left != null:
            check(absf(left.rotation_degrees.z - 25.0) < 0.01,
                "Real deployed roof hinge angle")
    return camp

func _visible(img: Image) -> bool:
    if img == null or img.is_empty():
        return false
    var count: int = 0
    for y in range(95, img.get_height() - 90, 24):
        for x in range(125, img.get_width() - 120, 24):
            if img.get_pixel(x, y).get_luminance() > 0.30:
                count += 1
    return count > 12

func _difference(a: Image, b: Image) -> int:
    if a == null or b == null:
        return 0
    var count: int = 0
    for y in range(100, a.get_height() - 100, 20):
        for x in range(130, a.get_width() - 130, 20):
            var aa: Color = a.get_pixel(x, y)
            var bb: Color = b.get_pixel(x, y)
            if absf(aa.r - bb.r) + absf(aa.g - bb.g) + absf(aa.b - bb.b) > 0.16:
                count += 1
    return count

func _shot(viewport: SubViewport, filename: String) -> Image:
    await process_frame
    await process_frame
    await process_frame
    var image: Image = viewport.get_texture().get_image()
    check(_visible(image), "Camp is visible in " + filename)
    if image != null and not image.is_empty():
        check(image.save_png(ProjectSettings.globalize_path(DEST + "/" + filename)) == OK,
            "Saved authentic Godot PNG: " + filename)
        shots += 1
    return image

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(DEST)) == OK, "Native screenshot directory")
    var viewport := SubViewport.new()
    viewport.name = "SupplyCampV2TrueNativeViewport"
    viewport.size = Vector2i(800, 600)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var stage := Node3D.new()
    viewport.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#20343E")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#DCE6E3")
    env.environment.ambient_light_energy = 0.62
    stage.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-44, -26, 0)
    light.light_energy = 1.80
    stage.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 10.8
    camera.position = Vector3(9.4, 8.5, -10.5)
    stage.add_child(camera)
    camera.look_at(Vector3(0, 0.95, 0), Vector3.UP)
    camera.current = true
    for faction in range(8):
        for lod in [8, 13]:
            for damage in range(4):
                var camp: Node3D = _model(faction, lod, damage)
                if camp == null:
                    continue
                var should_shoot: bool = (damage == 0 or
                    (faction == 0 and lod == 13 and damage == 2))
                if should_shoot:
                    stage.add_child(camp)
                    check(Art.pose_deploy(camp, 1.0), "Visual deployment works")
                    var suffix: String = ("f%02d_lod%d_d%d" %
                        [faction, lod, damage])
                    if damage == 0 and lod == 13:
                        check(Art.pose_deploy(camp, 0.0), "Roof folds")
                        var folded: Image = await _shot(
                            viewport, "supply_" + suffix + "_folded.png")
                        check(Art.pose_deploy(camp, 1.0), "Roof opens")
                        var deployed: Image = await _shot(
                            viewport, "supply_" + suffix + "_deployed.png")
                        check(_difference(folded, deployed) > 10,
                            "Hinge animation changes rendered pixels: " + suffix)
                    else:
                        await _shot(viewport, "supply_" + suffix + ".png")
                    stage.remove_child(camp)
                camp.free()
    check(audits == 64, "64 combinations audited")
    check(shots == 25, "8x2 intact + 8 folded + 1 damaged screenshot")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL SUPPLY CAMP V2 NATIVE 3D: %d issues" % failures)
        quit(1)
        return
    print("PASS SUPPLY CAMP V2 NATIVE 3D: 64 audits, 25 PNGs")
    quit(0)
