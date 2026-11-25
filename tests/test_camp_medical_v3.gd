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
    check(camp.get_meta("medical_art_v3", 0) == 3 and camp.get_meta("medical_art_revision", "") == "3.5" and camp.get_meta("no_gameplay_effects", false), "Art only")
    check(camp.get_meta("builder_role", "") == "infantry_medic", "Medic identity")
    var core: Node3D = camp.get_node_or_null("EquipamientoDesplegable/" + Medical.CORE) as Node3D
    if damage == 3:
        check(core == null and camp.has_node("V3_MedicalWreck/V3_FallenRoof_1"), "Collapsed roof, no standing clinic")
        var fallen: MeshInstance3D = camp.get_node("V3_MedicalWreck/V3_FallenRoof_1") as MeshInstance3D
        var low: float = INF
        for vertex in fallen.mesh.get_faces():
            low = minf(low, (fallen.transform * vertex).y)
        check(absf(low - 0.012) < 0.001, "Rotated wreck roof rests on platform")
        check(not Sculpt.inspect_interior(camp, true), "Destroyed clinic cannot open")
        check(camp.has_node("V3_MedicalWreck/V34_CollapsedTrolley") and camp.has_node("V3_MedicalWreck/V34_BrokenMonitor") and camp.has_node("V3_MedicalWreck/V34_FallenIV"), "Recognizable clinical wreckage")
    else:
        check(core != null, "Clinic present")
        if core != null:
            var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
            check(core.has_node("V3_ClinicalDeck/V3_SanitaryFloor") and tent.has_node("V3_Post_-1_105"), "Supported shelter and clinical floor")
            var left: Node3D = tent.get_node("V2_CubiertaArticulada_-1") as Node3D
            var roof: MeshInstance3D = left.get_node("PanelLonaRefuerzo") as MeshInstance3D
            check(roof.mesh is ArrayMesh and _closed(roof.mesh), "Closed fabric geometry")
            var size: Vector3 = roof.mesh.get_aabb().size
            var hinge: Node3D = left.get_node("V35_SecondaryRoofHinge") as Node3D
            var inner: MeshInstance3D = hinge.get_node("V35_InnerRoof") as MeshInstance3D
            check(_closed(inner.mesh), "Closed inner roof leaf")
            check(Art.pose_deploy(camp, 0.0) and absf(left.rotation_degrees.z - 80.0) < 0.01, "Raised rigid transport pose")
            check(absf(hinge.rotation_degrees.z - 180.0) < 0.01, "Folded secondary leaf")
            var packed_tip: Vector3 = left.transform * (hinge.transform * Vector3(1.075, -0.145, 0))
            check(packed_tip.y < 2.55, "Secondary leaf returns toward eave, not upright")
            check(Art.pose_deploy(camp, 1.0) and absf(hinge.rotation_degrees.z) < 0.01 and absf(left.rotation_degrees.z - 23.0) < 0.01 and roof.mesh.get_aabb().size == size, "Rigid roof restores")
            if damage < 2:
                var right: Node3D = tent.get_node("V2_CubiertaArticulada_1") as Node3D
                var right_hinge: Node3D = right.get_node("V35_SecondaryRoofHinge") as Node3D
                var tip_l: Vector3 = left.transform * (hinge.transform * Vector3(1.075, -0.145, 0))
                var tip_r: Vector3 = right.transform * (right_hinge.transform * Vector3(-1.075, -0.145, 0))
                check(tip_l.distance_to(tip_r) < 0.01, "Roof leaves meet at ridge")
                check(Sculpt.inspect_interior(camp, true) and absf(left.rotation_degrees.z - 112.0) < 0.01, "Interior roof opens")
                check(Sculpt.inspect_interior(camp, false) and absf(left.rotation_degrees.z - 23.0) < 0.01, "Interior roof closes")
                for side in [-1, 1]:
                    var foot: MeshInstance3D = tent.get_node("V3_Foot_%d_105" % side) as MeshInstance3D
                    check(absf(foot.position.y - foot.mesh.get_aabb().size.y * 0.5) < 0.001, "Footplate meets platform")
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
            var cabinet: Node3D = core.get_node("V2_ModuloMedicamentos") as Node3D
            for i in range(3):
                check(cabinet.has_node("V32_Drawer_%d" % i) and cabinet.has_node("V32_DrawerGrip_%d" % i), "Clinical drawer and attached handle")
            check(cabinet.has_node("V32_UpperDoor") and cabinet.has_node("V32_EmblemPlate"), "Cabinet identity")
            var iv: Node3D = core.get_node("V2_SoporteSueros") as Node3D
            for i in range(4):
                var pad: MeshInstance3D = iv.get_node("V32_IVPad_%d" % i) as MeshInstance3D
                check(absf(pad.position.y - (pad.mesh as CylinderMesh).height * 0.5) < 0.001, "IV feet touch platform")
            for side in [-1, 1]:
                check(iv.has_node("V32_IVPouch_%d" % side) == (damage < 2), "No intact IV pouch at D2")
            var monitor: Node3D = core.get_node("V2_MonitorPortatil") as Node3D
            check(monitor.has_node("V32_DisplayPivot/V32_OpaqueScreen") and monitor.has_node("V32_PowerSocket") and monitor.has_node("V32_PowerLead_2"), "Enclosed monitor with terminated lead")
            check(monitor.has_node("V32_DisplayPivot/V32_DisplayStatus_0") == (damage < 2), "Disabled monitor indication at D2")
            check(monitor.has_node("V32_SealedInstrument_0") == (lod == 13 and damage < 2), "Instrument detail follows LOD and damage")
            for side in [-1, 1]:
                for end in [-1, 1]:
                    check(monitor.has_node("V32_CartCaster_%d_%d" % [side, end]), "Four cart casters at both LODs")
            var upper: MeshInstance3D = iv.get_node("V32_IVUpperMast") as MeshInstance3D
            var lower: MeshInstance3D = iv.get_node("V32_IVLowerMast") as MeshInstance3D
            var upper_size: Vector3 = upper.mesh.get_aabb().size
            var extended_y: float = upper.position.y
            var display: Node3D = monitor.get_node("V32_DisplayPivot") as Node3D
            for progress in [0.0, 0.25, 0.5, 0.75, 1.0]:
                check(Art.pose_deploy(camp, progress), "Staged deployment sample")
                var lower_top: float = lower.position.y + (lower.mesh as CylinderMesh).height * 0.5
                var upper_bottom: float = upper.position.y - (upper.mesh as CylinderMesh).height * 0.5
                check(lower_top >= upper_bottom and upper.mesh.get_aabb().size == upper_size and upper.scale == Vector3.ONE, "IV telescopes without gap or scaling")
                if progress < 0.99:
                    check(not Sculpt.monitor_frame(camp, 0.25), "Monitor inactive in transit")
                if progress == 0.0:
                    check(upper.position.y < extended_y - 0.20 and absf(display.rotation_degrees.x - 26.0) < 0.01, "Equipment transport pose")
            check(absf(upper.position.y - extended_y) < 0.001, "IV returns to same pose")
            check(Sculpt.monitor_frame(camp, 0.25) == (damage < 2), "Monitor cycle available only when intact")
            check(Art.pose_deploy(camp, 1.0), "Restore standard pose after monitor cycle")
    if core != null:
        check(core.has_node("V2_CarpaDesmontable/V34_SurfaceWear") == (damage >= 1), "D1 physical wear")
        check(core.has_node("V2_CarpaDesmontable/V34_BentBraceLow") == (damage >= 2), "D2 bent frame")
        check(core.has_node("V2_MonitorPortatil/V32_DisplayPivot/V34_ScreenFracture") == (damage >= 2), "D2 broken display")
    var fx: Node3D = camp.get_node(Sculpt.FX_ROOT) as Node3D
    check(fx != null and fx.get_meta("presentation_only", false), "Dedicated visual effect rig")
    if fx != null:
        check(Sculpt.damage_fx_pose(camp, "bullet", 0.07) == (damage < 3), "Bullet effect damage guard")
        if damage < 3:
            check(fx.get_node("Flash").visible, "Impact flash")
            check(Sculpt.damage_fx_pose(camp, "blast", 0.30), "Explosion pose")
            check(fx.get_node("Chips/Chip_0").visible, "Solid fragments")
        check(Sculpt.damage_fx_pose(camp, "clear", 0.0), "Clear effects")
        check(not fx.get_node("Flash").visible and not fx.get_node("Smoke/Puff_0").visible, "No residual particles after clear")
        check(Sculpt.damage_fx_pose(camp, "idle", 0.34), "Restore persistent damage")
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
                        Sculpt.inspect_interior(camp, true)
                        camera.size = 3.5
                        camera.position = Vector3(-5.4, 3.4, -4.2)
                        camera.look_at(Vector3(-2.62, 1.0, -1.34), Vector3.UP)
                        await _capture(viewport, "medical_v32_cabinet.png")
                        camera.position = Vector3(-3.5, 4.0, -1.0)
                        camera.look_at(Vector3(-0.85, 0.9, 1.80), Vector3.UP)
                        await _capture(viewport, "medical_v32_monitor.png")
                        camera.position = Vector3(4.0, 3.4, -4.0)
                        camera.look_at(Vector3(1.39, 1.12, -0.95), Vector3.UP)
                        await _capture(viewport, "medical_v32_iv.png")
                        Sculpt.inspect_interior(camp, false)
                        camera.size = 11.5
                        Art.pose_deploy(camp, 0.0)
                        camera.position = Vector3(-10.0, 5.0, 10.4)
                        camera.look_at(Vector3(0, 1.2, 0), Vector3.UP)
                        await _capture(viewport, "medical_v35_folded_rear.png")
                        Art.pose_deploy(camp, 0.42)
                        camera.position = VIEWS[0]
                        camera.look_at(Vector3(0, 1.5, 0), Vector3.UP)
                        await _capture(viewport, "medical_v35_hinge_midpoint.png")
                        Art.pose_deploy(camp, 1.0)
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
                    camera.position = VIEWS[0]
                    camera.look_at(Vector3(0, 1.10, 0), Vector3.UP)
                    Sculpt.damage_fx_pose(camp, "bullet", 0.07)
                    await _capture(viewport, "medical_v34_bullet.png")
                    Sculpt.damage_fx_pose(camp, "blast", 0.30)
                    await _capture(viewport, "medical_v34_blast.png")
                    Sculpt.damage_fx_pose(camp, "clear", 0.0)
                    stage.remove_child(camp)
                camp.free()
    check(audits == 72, "Exact 72 faction, LOD and damage variants")
    check(screenshots == 35,
        "16 diagonal + 4 packed + 3 damage + 1 overhead + 2 interiors + 2 trolley + 3 equipment + 2 impact + 2 roof PNG")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL MEDICAL CAMP V3 NATIVE: %d failures" % failures)
        quit(1)
        return
    print("PASS MEDICAL CAMP V3 NATIVE: 72 audits, 35 PNGs")
    quit(0)
