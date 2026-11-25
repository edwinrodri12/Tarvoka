extends SceneTree

# TARVOKA real Godot 4.3 native geometry QA for the final specialist camp.
# 8 factions x 2 LOD x 4 damage states = 64 variants; 24 genuine PNGs.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Medical = preload("res://scripts/ui/CampMedicalFinishV2.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const OUTPUT := "res://build/qa/medical-camp-v2"
const VIEWS := [
    Vector3(10.0, 8.2, -10.4),
    Vector3(-10.0, 8.2, -10.4),
    Vector3(10.0, 8.2, 10.4),
    Vector3(-10.0, 8.2, 10.4)
]
var failures: int = 0
var audits: int = 0
var screenshots: int = 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("MEDICAL CAMP V2: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, parts: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        parts.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, parts)

func _audit(faction: int, lod: int, damage: int) -> Node3D:
    var camp: Node3D = Art.build("medico", faction, lod, damage, true, true, true, false)
    check(camp != null, "Medical model builds")
    if camp == null:
        return null
    audits += 1
    check(camp.get_meta("art_only", false) == true
        and camp.get_meta("no_gameplay_effects", false) == true
        and camp.get_meta("temporary_structure", false) == true
        and camp.get_meta("no_unit_or_credit_production", false) == true,
        "No healing/resource/AI change in art")
    check(str(camp.get_meta("builder_role", "")) == "infantry_medic"
        and Roster.camp_for("infantry_medic") == "medico",
        "Only approved infantry medic constructs camp")
    check(int(camp.get_meta("medical_art_v2", -1)) == 2
        and camp.get_meta("medical_no_gameplay_changes", false) == true,
        "Native medical finish is mounted")
    check(camp.get_meta("medical_fictional_teal_symbol", false) == true
        if damage < 3 else
        int(camp.get_meta("medical_art_v2", -1)) == 2,
        "Fictional turquoise first aid emblem")
    var core: Node3D = camp.get_node_or_null(
        "EquipamientoDesplegable/" + Medical.CORE) as Node3D
    check((core != null) == (damage < 3),
        "D3 contains rubble, never standing medical equipment")
    if core != null:
        var tent: Node3D = core.get_node_or_null(
            "V2_CarpaDesmontable") as Node3D
        var bed: Node3D = core.get_node_or_null(
            "V2_CamillaClinica") as Node3D
        var meds: Node3D = core.get_node_or_null(
            "V2_ModuloMedicamentos") as Node3D
        var iv: Node3D = core.get_node_or_null(
            "V2_SoporteSueros") as Node3D
        var monitor: Node3D = core.get_node_or_null(
            "V2_MonitorPortatil") as Node3D
        check(tent != null and bed != null and meds != null
            and iv != null and monitor != null,
            "Five distinct clinical geometry groups, not fake props")
        check(core.get_node_or_null("V2_AccesoSanitarioFaccion") != null,
            "Visible access and bold faction paint")
        if tent != null:
            check(tent.get_node_or_null(
                "V2_InsigniaSanitaria_CruzTurquesaVertical") != null
                and tent.get_node_or_null(
                "V2_InsigniaSanitaria_CruzTurquesaHorizontal") != null,
                "Raised solid fictional turquoise first aid mark")
            check(tent.get_node_or_null("V2_CubiertaArticulada_-1") != null,
                "Left roof is substantial and articulated")
            check((tent.get_node_or_null(
                "V2_CubiertaArticulada_1") != null) == (damage < 2),
                "D2 missing right roof and a fallen damaged panel")
        if bed != null:
            check(bed.get_node_or_null("ColchonClinico") != null
                and bed.get_node_or_null("RespaldoAjustable") != null,
                "Clinical stretcher not transparent or empty")
        if meds != null:
            check(meds.get_node_or_null(
                "BotiquinTurquesaVertical") != null,
                "Medical cabinet has readable front symbol")
        if iv != null:
            check(iv.get_node_or_null("MastilSueros") != null,
                "Solid IV pole")
        if monitor != null:
            check(monitor.get_node_or_null(
                "IndicadorTacticoOpaco") != null,
                "Opaque monitor rather than thin transparent sprite")
        check(Art.pose_deploy(camp, 0.0), "Roof folds")
        if tent != null:
            var left: Node3D = tent.get_node_or_null(
                "V2_CubiertaArticulada_-1") as Node3D
            if left != null:
                check(absf(left.rotation_degrees.z + 72.0) < 0.01,
                    "Real left hinge rotates to packed position")
        check(Art.pose_deploy(camp, 1.0), "Roof unfolds")
        if tent != null:
            var left: Node3D = tent.get_node_or_null(
                "V2_CubiertaArticulada_-1") as Node3D
            if left != null:
                check(absf(left.rotation_degrees.z - 23.0) < 0.01,
                    "Real left hinge rotates to deployed position")
    else:
        check(Art.pose_deploy(camp, 0.0) and Art.pose_deploy(camp, 1.0),
            "Destroyed state stays stable without rebuilding roof")
    var parts: Array[MeshInstance3D] = []
    _meshes(camp, parts)
    check(parts.size() >= (9 if damage == 3 else 42),
        "Actual closed 3D mesh volume in every state")
    var painted: int = 0
    var used_teal: int = 0
    var forbidden_red_cross: int = 0
    for part in parts:
        check(part.mesh is BoxMesh or part.mesh is CylinderMesh,
            "No open single-sided mesh: " + str(part.name))
        if part.mesh != null:
            var size: Vector3 = part.mesh.get_aabb().size
            check(minf(size.x, minf(size.y, size.z)) > 0.003,
                "Every model part has thickness")
        check(part.material_override is StandardMaterial3D,
            "Native opaque PBR on each piece")
        if part.material_override is StandardMaterial3D:
            var material: StandardMaterial3D = part.material_override as StandardMaterial3D
            check(material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
                and material.cull_mode == BaseMaterial3D.CULL_BACK,
                "No back-face/transparent medical walls")
            if material.albedo_color == Style.faction_color(faction):
                painted += 1
            if material.albedo_color == Medical.TEAL:
                used_teal += 1
            if (part.name.begins_with("CruzRoja") or
                    part.name.begins_with("RedCross")):
                forbidden_red_cross += 1
    check(painted >= (3 if damage == 3 else 10),
        "Recognizable faction paint from small map LOD")
    if damage < 3:
        check(used_teal >= 3, "Fictional aid mark stays teal")
    check(forbidden_red_cross == 0,
        "Never depict protected red cross")
    return camp

func _capture(viewport: SubViewport, filename: String) -> void:
    await process_frame
    await process_frame
    await process_frame
    var image: Image = viewport.get_texture().get_image()
    check(image != null and not image.is_empty(),
        "Genuine Godot screenshot: " + filename)
    if image == null or image.is_empty():
        return
    var visible: int = 0
    for y in range(105, 525, 28):
        for x in range(135, 705, 28):
            if image.get_pixel(x, y).get_luminance() > 0.29:
                visible += 1
    check(visible > 10, "Rendered native geometry is visible")
    check(image.save_png(ProjectSettings.globalize_path(
        OUTPUT + "/" + filename)) == OK, "PNG written")
    screenshots += 1

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUTPUT)) == OK,
        "Medical renderer directory")
    var viewport := SubViewport.new()
    viewport.name = "MedicalCampGodotV2RealRender"
    viewport.size = Vector2i(800, 600)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var stage := Node3D.new()
    viewport.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#23363D")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#E8F3EC")
    env.environment.ambient_light_energy = 0.68
    stage.add_child(env)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-51, -33, 0)
    light.light_energy = 1.70
    stage.add_child(light)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 11.5
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
                    for view in range(4):
                        camera.position = VIEWS[view]
                        camera.look_at(Vector3(0, 1.10, 0), Vector3.UP)
                        await _capture(viewport,
                            "medical_f%02d_lod%d_view%d.png" %
                            [faction, lod, view])
                    check(Art.pose_deploy(camp, 0.0),
                        "Packed camp state for visual inspection")
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 1.10, 0), Vector3.UP)
                    await _capture(viewport,
                        "medical_f%02d_lod%d_packed.png" %
                        [faction, lod])
                    stage.remove_child(camp)
                elif faction == 0 and lod == 13 and damage in [1, 2, 3]:
                    stage.add_child(camp)
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 1.10, 0), Vector3.UP)
                    await _capture(viewport,
                        "medical_damage%d.png" % damage)
                    stage.remove_child(camp)
                if faction == 0 and lod == 13 and damage == 0:
                    stage.add_child(camp)
                    camera.position = Vector3(0, 12.5, -0.12)
                    camera.look_at(Vector3(0, 0, 0), Vector3(0, 0, -1))
                    await _capture(viewport, "medical_top_down.png")
                    stage.remove_child(camp)
                camp.free()
    check(audits == 64, "Exact 64 faction, LOD and damage variants")
    check(screenshots == 24,
        "16 diagonal + 4 packed + 3 damage + 1 overhead PNG")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL MEDICAL CAMP V2 NATIVE: %d failures" % failures)
        quit(1)
        return
    print("PASS MEDICAL CAMP V2 NATIVE: 64 audits, 24 PNGs")
    quit(0)
