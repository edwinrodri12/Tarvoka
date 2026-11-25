extends SceneTree

# Real Godot 4.3 native regression. 9 factions x 2 LOD x 4 damage = 72
# scenes; 24 authentic PNG views including 360°, deployment and damage.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Defense = preload("res://scripts/ui/CampDefenseFinishV2.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const DEST := "res://build/qa/defense-camp-v3"
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
        push_error("DEFENSE CAMP V3: " + label)

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
    var camp: Node3D = Art.build("defensivo", faction, lod, damage)
    check(camp != null, "Build V3")
    if camp == null:
        return null
    audits += 1
    check(camp.get_meta("defense_art_v3", 0) == 3 and camp.get_meta("defense_art_revision", "") == "3.1" and camp.get_meta("no_gameplay_effects", false), "V3.1 visual only")
    check(camp.get_meta("builder_role", "") == "infantry_engineer", "Engineer identity")
    var core: Node3D = camp.get_node_or_null("EquipamientoDesplegable/" + Defense.CORE) as Node3D
    if damage == 3:
        check(core == null and camp.has_node("V3_DefenseWreck"), "No intact fort in D3")
    else:
        check(core != null, "Fort present")
        if core != null:
            var bag: MeshInstance3D = core.get_node("V2_MurallaTrasera/V2_SacoPosterior_0_0/LonaArenaSellada") as MeshInstance3D
            check(bag.mesh is ArrayMesh and _closed(bag.mesh), "Rounded closed bag")
            check(core.has_node("V2_MurallaTrasera/V3_FasciaBeam") and core.has_node("V3_DeckPanel_1"), "Supported fascia and deck")
            var left: Node3D = core.get_node("V2_BarreraArticulada_-1") as Node3D
            check(core.has_node("V3_FixedHingeAxle_-1_-105"), "Fixed physical axle")
            check(left.has_node("V31_InnerArmorPad_93") and left.has_node("V31_OuterInset_64") and left.has_node("V31_UpperLock_123"), "Detailed armor on both sides")
            var brace: Node3D = core.get_node("V31_Brace_-1_91") as Node3D
            check(brace.has_node("Middle") and brace.has_node("Shaft"), "Three-stage physical support")
            var original: Vector3 = left.position
            check(CampPose(camp, 0.0) and absf(left.rotation_degrees.z + 78.0) < 0.01 and absf(left.rotation_degrees.y) < 0.01, "Fold along real axle")
            check(CampPose(camp, 0.5) and absf(left.rotation_degrees.z + 39.0) < 0.01, "Intermediate pose")
            check(left.position == original and left.scale == Vector3.ONE, "Fixed hinge, rigid panel")
            check(CampPose(camp, 1.0) and absf(left.rotation_degrees.z) < 0.01, "Restored deployed")
            for p in [0.0, 0.25, 0.5, 0.75, 1.0]:
                check(CampPose(camp, p), "Support motion")
                var span: float = float(brace.get_meta("span"))
                var tip: Vector3 = brace.transform * Vector3(0, span, 0)
                var anchor: Vector3 = left.transform * Vector3(brace.get_meta("wall_anchor"))
                check(tip.distance_to(anchor) < 0.001 and brace.position == Vector3(brace.get_meta("base_anchor")), "Both support ends stay connected")
                check(span >= 0.42 and span <= 1.23, "Rigid nested support length")
                var middle: Node3D = brace.get_node("Middle") as Node3D
                var shaft: Node3D = brace.get_node("Shaft") as Node3D
                check(middle.position.y - 0.21 <= 0.40 and shaft.position.y - 0.21 <= middle.position.y + 0.21, "No gap between telescoping sections")
            check(core.has_node("V2_BarreraArticulada_1") == (damage < 2), "D2 no intact right wall")
            var parts: Array[MeshInstance3D] = []
            _meshes(core, parts)
            for part in parts:
                var pos: Vector3 = _part_position_in_core(part, core)
                if absf(pos.x) < 1.0 and absf(pos.z) < 1.0:
                    check(pos.y <= 0.14, "Clear standing center")
    var parts: Array[MeshInstance3D] = []
    _meshes(camp, parts)
    var closed: int = 0
    var paint: int = 0
    var accent: Color = Art.STEEL if faction < 0 else Style.faction_color(faction)
    for part in parts:
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque closed part")
        if mat != null and mat.albedo_color == accent:
            paint += 1
        if part.mesh is ArrayMesh:
            closed += 1
            check(_closed(part.mesh), "Watertight custom geometry " + str(part.name))
    check(closed >= (3 if damage == 3 else 35), "Substantial native sculpt")
    check(paint >= (3 if damage == 3 else 9), "Faction identity")
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
    viewport.name = "DefenseCampV3NativeGodot"
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
    for faction in range(-1, 8):
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
                    if faction == 0 and lod == 13:
                        camera.size = 4.4
                        camera.position = Vector3(0.0, 3.2, -5.3)
                        camera.look_at(Vector3(-2.05, 0.85, -0.42), Vector3.UP)
                        await _capture(viewport, "defense_v31_inner_brace.png")
                        camera.position = Vector3(-6.8, 3.1, -4.2)
                        camera.look_at(Vector3(-2.32, 0.85, -0.42), Vector3.UP)
                        await _capture(viewport, "defense_v31_outer_armor.png")
                        camera.size = 10.9
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
    check(audits == 72, "9 factions x 2 LOD x 4 damages = 72")
    check(screenshots == 26,
        "24 base captures plus 2 armor closeups")
    viewport.queue_free()
    await process_frame
    if errors > 0:
        printerr("FAIL DEFENSE CAMP V3 NATIVE: %d issues" % errors)
        quit(1)
        return
    print("PASS DEFENSE CAMP V3 NATIVE: 72 audits, 26 PNGs")
    quit(0)
