extends SceneTree

# TARVOKA real Godot 4.3 native geometry QA for the final specialist camp.
# 8 factions x 2 LOD x 4 damage states = 64 variants; 24 genuine PNGs.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Medical = preload("res://scripts/ui/CampMedicalFinishV2.gd")
const Sculpt = preload("res://scripts/ui/CampMedicalSculptV3.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const OUTPUT := "res://build/qa/medical-camp-v3"
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
        push_error("MEDICAL CAMP V3: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, parts: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        parts.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, parts)

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
    var camp: Node3D = Art.build("medico", faction, lod, damage)
    check(camp != null, "Medical V3 builds")
    if camp == null:
        return null
    audits += 1
    check(camp.get_meta("medical_art_v3", 0) == 3 and camp.get_meta("medical_art_revision", "") == "3.1" and camp.get_meta("no_gameplay_effects", false), "Art only")
    check(camp.get_meta("builder_role", "") == "infantry_medic", "Medic identity")
    var core: Node3D = camp.get_node_or_null("EquipamientoDesplegable/" + Medical.CORE) as Node3D
    if damage == 3:
        check(core == null and camp.has_node("V3_MedicalWreck/V3_FallenRoof_1"), "Collapsed roof, no standing clinic")
        check(not Sculpt.inspect_interior(camp, true), "Destroyed clinic cannot open")
    else:
        check(core != null, "Clinic present")
        if core != null:
            var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
            check(core.has_node("V3_ClinicalDeck/V3_SanitaryFloor") and tent.has_node("V3_Post_-1_105"), "Supported shelter and clinical floor")
            var left: Node3D = tent.get_node("V2_CubiertaArticulada_-1") as Node3D
            var roof: MeshInstance3D = left.get_node("PanelLonaRefuerzo") as MeshInstance3D
            check(roof.mesh is ArrayMesh and _closed(roof.mesh), "Closed fabric geometry")
            var size: Vector3 = roof.mesh.get_aabb().size
            check(Art.pose_deploy(camp, 0.0) and absf(left.rotation_degrees.z - 72.0) < 0.01, "Raised rigid transport pose")
            check(Art.pose_deploy(camp, 1.0) and absf(left.rotation_degrees.z - 23.0) < 0.01 and roof.mesh.get_aabb().size == size, "Rigid roof restores")
            if damage < 2:
                var right: Node3D = tent.get_node("V2_CubiertaArticulada_1") as Node3D
                var tip_l: Vector3 = left.transform * Vector3(2.15, 0, 0)
                var tip_r: Vector3 = right.transform * Vector3(-2.15, 0, 0)
                check(tip_l.distance_to(tip_r) < 0.01, "Roof leaves meet at ridge")
                check(Sculpt.inspect_interior(camp, true) and absf(left.rotation_degrees.z - 112.0) < 0.01, "Interior roof opens")
                check(Sculpt.inspect_interior(camp, false) and absf(left.rotation_degrees.z - 23.0) < 0.01, "Interior roof closes")
            else:
                check(not tent.has_node("V2_CubiertaArticulada_1") and not Sculpt.inspect_interior(camp, true), "D2 missing right roof")
            var bed: Node3D = core.get_node("V2_CamillaClinica") as Node3D
            var back: Node3D = bed.get_node("V31_BackrestPivot") as Node3D
            var mattress: MeshInstance3D = bed.get_node("V31_FixedMattress") as MeshInstance3D
            check(_closed(mattress.mesh), "Volumetric sealed mattress")
            for side in [-1, 1]:
                for end in [-1, 1]:
                    var tire: MeshInstance3D = bed.get_node("V31_CasterTire_%d_%d" % [side, end]) as MeshInstance3D
                    check(tire.mesh is CylinderMesh and absf(tire.position.y - (tire.mesh as CylinderMesh).top_radius - 0.11) < 0.001, "Four casters rest on clinical floor")
            var rail: Node3D = bed.get_node("V31_RailPivot_1") as Node3D
            var back_size: Vector3 = (back.get_node("V31_BackrestCushion") as MeshInstance3D).mesh.get_aabb().size
            check(Art.pose_deploy(camp, 0.0) and absf(back.rotation_degrees.x) < 0.01 and absf(rail.rotation_degrees.z + 65.0) < 0.01, "Rigid trolley joints fold")
            check(Art.pose_deploy(camp, 1.0), "Restore trolley")
            var limit: float = 0.35 if damage >= 2 else 1.0
            check(absf(back.rotation_degrees.x + 28.0 * limit) < 0.01 and absf(rail.rotation_degrees.z + 65.0 * (1.0 - limit)) < 0.01, "Backrest and rail respect damage")
            check((back.get_node("V31_BackrestCushion") as MeshInstance3D).mesh.get_aabb().size == back_size and back.scale == Vector3.ONE and rail.scale == Vector3.ONE, "No stretching of clinical equipment")
    var parts: Array[MeshInstance3D] = []
    _meshes(camp, parts)
    var count: int = 0
    var paint: int = 0
    var accent: Color = Art.STEEL if faction < 0 else Style.faction_color(faction)
    for part in parts:
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        check(mat != null and mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and mat.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque mesh")
        if mat != null and mat.albedo_color == accent:
            paint += 1
        if part.mesh is ArrayMesh:
            count += 1
            check(_closed(part.mesh), "Closed custom mesh " + str(part.name))
    check(count >= (5 if damage == 3 else 25), "Substantial sculpture")
    check(paint >= (3 if damage == 3 else 10), "Faction color")
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
    viewport.name = "MedicalCampGodotV3RealRender"
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
                        camera.look_at(Vector3(0, 1.10, 0), Vector3.UP)
                        await _capture(viewport,
                            "medical_f%02d_lod%d_view%d.png" %
                            [faction, lod, view])
                    if faction == 0 and lod == 13:
                        Sculpt.inspect_interior(camp, true)
                        camera.position = Vector3(7.0, 7.8, -8.0)
                        camera.look_at(Vector3(0, 1.0, 0.8), Vector3.UP)
                        await _capture(viewport, "medical_v3_interior.png")
                        camera.position = Vector3(-7.0, 5.0, 7.5)
                        camera.look_at(Vector3(0, 1.1, 1.4), Vector3.UP)
                        await _capture(viewport, "medical_v3_frame_rear.png")
                        camera.size = 3.4
                        camera.position = Vector3(3.2, 4.0, -3.1)
                        camera.look_at(Vector3(1.18, 0.82, 0.67), Vector3.UP)
                        await _capture(viewport, "medical_v31_trolley_raised.png")
                        Sculpt.inspect_interior(camp, false)
                        Art.pose_deploy(camp, 0.0)
                        Sculpt.inspect_interior(camp, true)
                        await _capture(viewport, "medical_v31_trolley_folded.png")
                        Sculpt.inspect_interior(camp, false)
                        Art.pose_deploy(camp, 1.0)
                        camera.size = 11.5
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
    check(audits == 72, "Exact 72 faction, LOD and damage variants")
    check(screenshots == 28,
        "16 diagonal + 4 packed + 3 damage + 1 overhead + 2 interiors + 2 trolley PNG")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL MEDICAL CAMP V3 NATIVE: %d failures" % failures)
        quit(1)
        return
    print("PASS MEDICAL CAMP V3 NATIVE: 72 audits, 28 PNGs")
    quit(0)
