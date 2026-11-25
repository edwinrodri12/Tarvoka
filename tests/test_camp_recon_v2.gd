extends SceneTree

# Offline Godot 4.3 regression for the genuine 3D reconnaissance camp.
# 8 factions x 2 LOD x 4 damage = 64 builds and 25 real rendered images.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Recon = preload("res://scripts/ui/CampReconFinishV2.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const OUT := "res://build/qa/recon-camp-v2"
const VIEWS := [
    Vector3(9.8, 8.8, -10.5),
    Vector3(-9.8, 8.8, -10.5),
    Vector3(9.8, 8.8, 10.5),
    Vector3(-9.8, 8.8, 10.5)
]
var failures: int = 0
var audits: int = 0
var screenshots: int = 0

func check(valid: bool, message: String) -> void:
    if not valid:
        failures += 1
        push_error("RECON CAMP V2: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, list: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        list.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, list)

func _audit(faction: int, lod: int, damage: int) -> Node3D:
    var camp: Node3D = Art.build("reconocimiento", faction, lod, damage, true, false)
    check(camp != null, "Camp builds")
    if camp == null:
        return null
    audits += 1
    check(camp.get_meta("art_only", false) == true
        and camp.get_meta("temporary_structure", false) == true
        and camp.get_meta("no_gameplay_effects", false) == true
        and camp.get_meta("no_unit_or_credit_production", false) == true,
        "Pure visual camp, never modifies gameplay")
    check(str(camp.get_meta("builder_role", "")) == "infantry_sniper"
        and Roster.camp_for("infantry_sniper") == "reconocimiento",
        "Approved builder exclusively sniper")
    check(int(camp.get_meta("recon_art_v2", -1)) == 2
        and camp.get_meta("recon_art_only", false) == true,
        "Native 3D recon finish is active")
    var core: Node3D = camp.get_node_or_null(
        "EquipamientoDesplegable/" + Recon.CORE) as Node3D
    var has_building: bool = damage < 3
    check((core != null) == has_building,
        "Demolished camp D3 must not contain intact tower")
    if core != null:
        var station: Node3D = core.get_node_or_null(
            "V2_CentroControl") as Node3D
        var tower: Node3D = core.get_node_or_null(
            "V2_TorreTripode") as Node3D
        check(station != null and tower != null,
            "Control station and tower are present")
        check(core.get_node_or_null("V2_BandaRutaFaccion") != null,
            "Faction signal on front approach")
        check(core.get_node_or_null("V2_EstabilizadorSensor_-1") != null
            and core.get_node_or_null("V2_EstabilizadorSensor_1") != null,
            "Symmetric ground antenna stations")
        if station != null:
            check(station.get_node_or_null(
                "PantallaTacticaOpaca") != null,
                "Solid nontransparent control screen")
        if tower != null:
            var mast: Node3D = tower.get_node_or_null(
                "V2_MastilDesplegable") as Node3D
            check((mast != null) == (damage < 2),
                "D2 breaks telescopic mast instead of restoring it")
            check(tower.get_node_or_null(
                "PlataformaCabezalMaciza") != null,
                "Strong physical tower body")
            if damage >= 2:
                check(tower.get_node_or_null("MastilRotoFijo") != null,
                    "Distinct broken mast state")
            elif mast != null:
                var head: Node3D = mast.get_node_or_null(
                    "V2_CabezalOpticoGiratorio") as Node3D
                check(head != null, "Rotating optical head")
                if head != null:
                    for side in [-1, 1]:
                        check(head.get_node_or_null(
                            "V2_PanelAntenaAbatible_%d" % side) != null,
                            "Physical deployable antenna panel")
                    check(head.get_node_or_null("OpticaCircular_-1") != null
                        and head.get_node_or_null("OpticaCircular_1") != null,
                        "Two physically closed lenses")
                    check(Art.pose_deploy(camp, 0.0), "Packed visual pose")
                    check(absf(mast.scale.y - 0.45) < 0.01,
                        "Actual mast telescoping down")
                    check(Art.pose_deploy(camp, 1.0), "Deployed visual pose")
                    check(absf(mast.scale.y - 1.0) < 0.01,
                        "Actual mast telescoping up")
                    check(Recon.pose_scan(camp, 45.0),
                        "Purely visual optical head sweep")
                    check(absf(head.rotation_degrees.y - 45.0) < 0.01,
                        "Optical sweep rotates physical head")
                    check(Recon.pose_scan(camp, 0.0),
                        "Restore neutral optical pose")
        if damage >= 2:
            check(not Recon.pose_scan(camp, 120.0),
                "Destroyed optic cannot visually scan")
    var parts: Array[MeshInstance3D] = []
    _meshes(camp, parts)
    check(parts.size() >= (9 if damage == 3 else 40),
        "Closed volumetric parts count appropriate to damage")
    var accent: Color = Style.faction_color(faction)
    var painting: int = 0
    for part in parts:
        check(part.mesh is BoxMesh or part.mesh is CylinderMesh,
            "All parts are genuine closed meshes: " + str(part.name))
        check(part.material_override is StandardMaterial3D,
            "Physical PBR material: " + str(part.name))
        if part.material_override is StandardMaterial3D:
            var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
            check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,
                "No transparent mesh walls")
            check(mat.cull_mode == BaseMaterial3D.CULL_BACK,
                "Correct exterior face culling")
            if mat.albedo_color == accent:
                painting += 1
        var bounds: Vector3 = part.mesh.get_aabb().size
        check(minf(bounds.x, minf(bounds.y, bounds.z)) > 0.003,
            "Nonzero closed physical volume: " + str(part.name))
    check(painting >= (3 if damage == 3 else 9),
        "Faction color clearly visible on station + tower")
    return camp

func _shot(viewport: SubViewport, name: String) -> void:
    await process_frame
    await process_frame
    await process_frame
    var picture: Image = viewport.get_texture().get_image()
    check(picture != null and not picture.is_empty(),
        "Native image exists: " + name)
    if picture == null or picture.is_empty():
        return
    var illuminated: int = 0
    for y in range(85, 530, 29):
        for x in range(120, 700, 29):
            if picture.get_pixel(x, y).get_luminance() > 0.27:
                illuminated += 1
    check(illuminated > 10, "Actual model visible: " + name)
    check(picture.save_png(ProjectSettings.globalize_path(
        OUT + "/" + name)) == OK, "Write native PNG: " + name)
    screenshots += 1

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT)) == OK, "Output path")
    var viewport := SubViewport.new()
    viewport.name = "ReconV2NativeGodotRender"
    viewport.size = Vector2i(800, 600)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var stage := Node3D.new()
    viewport.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#1E2C36")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#E5F3F0")
    env.environment.ambient_light_energy = 0.74
    stage.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-49, -32, 0)
    light.light_energy = 1.70
    stage.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 12.8
    camera.current = true
    stage.add_child(camera)
    for faction in range(8):
        for lod in [8, 13]:
            for damage in range(4):
                var camp: Node3D = _audit(faction, lod, damage)
                if camp == null:
                    continue
                if faction in [0, 1] and damage == 0:
                    stage.add_child(camp)
                    check(Art.pose_deploy(camp, 1.0),
                        "Render in fully deployed state")
                    for view in range(4):
                        camera.position = VIEWS[view]
                        camera.look_at(Vector3(0, 1.63, 0), Vector3.UP)
                        await _shot(viewport, "recon_f%02d_lod%d_view%d.png"
                            % [faction, lod, view])
                    check(Art.pose_deploy(camp, 0.0),
                        "Render in packed visual state")
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 1.63, 0), Vector3.UP)
                    await _shot(viewport, "recon_f%02d_lod%d_packed.png"
                        % [faction, lod])
                    if faction == 0 and lod == 13:
                        check(Art.pose_deploy(camp, 1.0),
                            "Return to operational art pose")
                        check(Recon.pose_scan(camp, -85.0), "Scan left")
                        await _shot(viewport, "recon_sensor_scan_left.png")
                        check(Recon.pose_scan(camp, 85.0), "Scan right")
                        await _shot(viewport, "recon_sensor_scan_right.png")
                    stage.remove_child(camp)
                elif faction == 0 and lod == 13 and damage in [2, 3]:
                    stage.add_child(camp)
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 1.63, 0), Vector3.UP)
                    await _shot(viewport, "recon_damage_%d.png" % damage)
                    stage.remove_child(camp)
                if faction == 0 and lod == 13 and damage == 1:
                    stage.add_child(camp)
                    camera.position = Vector3(0.2, 14.0, -0.2)
                    camera.look_at(Vector3(0, 0, 0), Vector3(0, 0, -1))
                    await _shot(viewport, "recon_top_down_d1.png")
                    stage.remove_child(camp)
                camp.free()
    check(audits == 64, "Exact 64 model audits")
    check(screenshots == 25,
        "16 angles + 4 packed + 2 scans + 2 damage + 1 overhead")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL RECON CAMP V2 NATIVE: %d issues" % failures)
        quit(1)
        return
    print("PASS RECON CAMP V2 NATIVE: 64 audits, 25 PNGs")
    quit(0)
