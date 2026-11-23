extends SceneTree

# Real Godot 4.3 native regression. 8 factions x 2 LOD x 4 damage = 64
# scenes; 24 authentic PNG views including 360°, deployment and damage.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Defense = preload("res://scripts/ui/CampDefenseFinishV2.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const DEST := "res://build/qa/defense-camp-v2"
const VIEWS := [
    Vector3(10.5, 8.7, -10.0),
    Vector3(-10.5, 8.7, -10.0),
    Vector3(10.5, 8.7, 10.0),
    Vector3(-10.5, 8.7, 10.0)
]
var errors: int = 0
var audits: int = 0
var screenshots: int = 0

func check(condition: bool, label: String) -> void:
    if not condition:
        errors += 1
        push_error("DEFENSE CAMP V2: " + label)

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, output: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        output.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, output)

func _part_position_in_core(part: Node3D, core: Node3D) -> Vector3:
    # Built sculptures are intentionally not inside SceneTree until capture.
    # Using global_position here logs engine errors and produces false (0,0,0).
    var full_transform := Transform3D.IDENTITY
    var current: Node3D = part
    while current != null and current != core:
        full_transform = current.transform * full_transform
        current = current.get_parent() as Node3D
    return full_transform.origin

func _audit(faction: int, lod: int, damage: int) -> Node3D:
    var camp: Node3D = Art.build("defensivo", faction, lod, damage)
    check(camp != null, "A defensive camp must build")
    if camp == null:
        return null
    audits += 1
    check(camp.get_meta("art_only", false) == true
        and camp.get_meta("no_gameplay_effects", false) == true
        and camp.get_meta("temporary_structure", false) == true
        and camp.get_meta("no_unit_or_credit_production", false) == true,
        "No tactical or production changes")
    check(str(camp.get_meta("builder_role", "")) == "infantry_engineer",
        "Only engineer builds the fort")
    check(Roster.camp_for("infantry_engineer") == "defensivo",
        "Existing six-infantry roster is unchanged")
    check(int(camp.get_meta("defense_art_v2", -1)) == 2
        and camp.get_meta("defense_center_clear", false) == true,
        "V2 fort with occupiable center is used")
    var core: Node3D = camp.get_node_or_null(
        "EquipamientoDesplegable/" + Defense.CORE) as Node3D
    check((core != null) == (damage < 3),
        "D3 is actual rubble, never standing wall")
    if core != null:
        check(core.get_node_or_null("V2_MurallaTrasera") != null,
            "Solid layered rear sandbags")
        check(core.get_node_or_null("V2_SueloCentralOcupable") != null,
            "Clear platform floor in the center")
        check(core.get_node_or_null("V2_GuiaEntrada_-1") != null
            and core.get_node_or_null("V2_GuiaEntrada_1") != null,
            "Clear open entrance, no center gate")
        check(core.get_node_or_null("V2_CimentacionBarrera_-1") != null
            and core.get_node_or_null("V2_CimentacionBarrera_1") != null,
            "Barrier anchors exist on both flanks")
        check(core.get_node_or_null("V2_BarreraArticulada_-1") != null,
            "Left solid barrier survives D2")
        check((core.get_node_or_null("V2_BarreraArticulada_1") != null)
            == (damage < 2),
            "Right barrier is damaged correctly at D2")
        check((core.get_node_or_null("V2_SeccionBarreraCaida") != null)
            == (damage >= 2),
            "Fallen barrier replaces intact barrier at D2")
        check(CampPose(camp, 0.0), "Fully folded pose")
        var left: Node3D = core.get_node_or_null(
            "V2_BarreraArticulada_-1") as Node3D
        if left != null:
            check(absf(left.rotation_degrees.y + 78.0) < 0.01,
                "Left physical panel folds by 78 degrees")
        check(CampPose(camp, 1.0), "Unfolded defensive pose")
        if left != null:
            check(absf(left.rotation_degrees.y) < 0.01,
                "Left wall returned to normal position")
        # Validate a genuinely free center at standing height; no hidden
        # weapons, barriers or automatic turret in the infantry footprint.
        var parts: Array[MeshInstance3D] = []
        _meshes(core, parts)
        for item in parts:
            if (item.name == "V2_SueloCentralOcupable" or
                    item.name == "V2_DelimitacionCentroFaccion" or
                    item.name.begins_with("V2_UnionPiso_")):
                continue
            var core_pos: Vector3 = _part_position_in_core(item, core)
            if absf(core_pos.x) < 1.0 and absf(core_pos.z) < 1.0:
                check(core_pos.y < 0.14,
                    "No tall object blocks central occupiable footprint")
    else:
        check(CampPose(camp, 0.0), "Destroyed rubble pose stable")
        check(CampPose(camp, 1.0), "Destroyed rubble stays stable")
    var meshes: Array[MeshInstance3D] = []
    _meshes(camp, meshes)
    check(meshes.size() >= (9 if damage == 3 else 45),
        "Native closed hard-surface sculpt has solid geometry")
    var painted: int = 0
    var allowed: bool = true
    for part in meshes:
        if not (part.mesh is BoxMesh or part.mesh is CylinderMesh):
            check(false, "Closed primitive mesh required: " + str(part.name))
            allowed = false
        if part.material_override is StandardMaterial3D:
            var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
            check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED,
                "Must never show see-through wall")
            check(mat.cull_mode == BaseMaterial3D.CULL_BACK,
                "No incorrect backface-only panels")
            if mat.albedo_color == Style.faction_color(faction):
                painted += 1
        else:
            check(false, "Part missing opaque material: " + str(part.name))
        if part.mesh != null:
            var bounds: Vector3 = part.mesh.get_aabb().size
            check(minf(bounds.x, minf(bounds.y, bounds.z)) > 0.003,
                "Mesh must have true volume")
    check(allowed, "All geometry is solid")
    check(painted >= (3 if damage == 3 else 11),
        "Faction color readable from four angles in either LOD")
    return camp

func CampPose(root: Node3D, progress: float) -> bool:
    return Art.pose_deploy(root, progress)

func _capture(viewport: SubViewport, name: String) -> void:
    await process_frame
    await process_frame
    await process_frame
    var image: Image = viewport.get_texture().get_image()
    check(image != null and not image.is_empty(), "Genuine PNG " + name)
    if image == null or image.is_empty():
        return
    var visible: int = 0
    for y in range(105, 535, 28):
        for x in range(135, 715, 28):
            if image.get_pixel(x, y).get_luminance() > 0.27:
                visible += 1
    check(visible > 9, "Rendered building visible: " + name)
    check(image.save_png(ProjectSettings.globalize_path(
        DEST + "/" + name)) == OK, "Save PNG " + name)
    screenshots += 1

func _run() -> void:
    check(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(DEST)) == OK, "Output directory")
    var viewport := SubViewport.new()
    viewport.name = "DefenseCampV2NativeGodot"
    viewport.size = Vector2i(800, 600)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var stage := Node3D.new()
    viewport.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#23323A")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#E6EEE8")
    env.environment.ambient_light_energy = 0.72
    stage.add_child(env)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -28, 0)
    key.light_energy = 1.66
    stage.add_child(key)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 10.9
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
                        camera.look_at(Vector3(0, 0.83, 0), Vector3.UP)
                        await _capture(viewport,
                            "defense_f%02d_lod%d_view%d.png" %
                            [faction, lod, view])
                    check(CampPose(camp, 0.0), "Fold barriers in place")
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 0.83, 0), Vector3.UP)
                    await _capture(viewport,
                        "defense_f%02d_lod%d_folded.png" % [faction, lod])
                    stage.remove_child(camp)
                elif faction == 0 and lod == 13 and damage in [1, 2, 3]:
                    stage.add_child(camp)
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 0.83, 0), Vector3.UP)
                    await _capture(viewport, "defense_damage%d.png" % damage)
                    stage.remove_child(camp)
                if faction == 0 and lod == 13 and damage == 0:
                    stage.add_child(camp)
                    camera.position = Vector3(0.0, 12.0, -0.1)
                    camera.look_at(Vector3(0, 0, 0), Vector3(0, 0, -1))
                    await _capture(viewport, "defense_overhead_occupiable.png")
                    stage.remove_child(camp)
                camp.free()
    check(audits == 64, "8 factions x 2 LOD x 4 damages = 64")
    check(screenshots == 24,
        "4 angles x 2 factions x 2 LOD + 4 folded + 3 damage + top")
    viewport.queue_free()
    await process_frame
    if errors > 0:
        printerr("FAIL DEFENSE CAMP V2 NATIVE: %d issues" % errors)
        quit(1)
        return
    print("PASS DEFENSE CAMP V2 NATIVE: 64 audits, 24 PNGs")
    quit(0)
