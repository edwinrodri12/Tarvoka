extends SceneTree

# Offline Godot 4.3 regression for the genuine 3D reconnaissance camp.
# Eight factions plus neutral x 2 LOD x 4 damage = 72 builds, 27 native images.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Recon = preload("res://scripts/ui/CampReconFinishV2.gd")
const ReconV3 = preload("res://scripts/ui/CampReconSculptV3.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const OUT := "res://build/qa/recon-camp-v3"
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
        push_error("RECON CAMP V3: " + message)

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, list: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        list.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, list)

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
    var camp: Node3D = Art.build("reconocimiento", faction, lod, damage)
    check(camp != null, "Build V3")
    if camp == null:
        return null
    audits += 1
    check(camp.get_meta("recon_art_v3", 0) == 3 and camp.get_meta("recon_art_revision", "") == "3.2" and camp.get_meta("no_gameplay_effects", false), "V3.2 art only")
    var core: Node3D = camp.get_node_or_null("EquipamientoDesplegable/" + Recon.CORE) as Node3D
    if damage == 3:
        check(core == null and camp.has_node("V3_ReconWreck"), "Closed wreck, no intact tower")
        check(not ReconV3.station_pose(camp, 0.25), "D3 electronics cannot animate")
    else:
        check(core != null, "Actual tower and station")
        if core != null:
            check(core.has_node("V2_CentroControl/V3_RearHatch_1") and core.has_node("V31_StationTowerConduit"), "Detailed station and connected cable")
            var station: Node3D = core.get_node("V2_CentroControl") as Node3D
            var instrument: Node3D = station.get_node("V32_InstrumentDeck") as Node3D
            check(instrument.has_node("V32_RadioHousing_1") and instrument.has_node("V32_Display/V32_ScopePivot"), "Physical comms and monitor")
            var led: MeshInstance3D = instrument.get_node("V32_RadioLED_1") as MeshInstance3D
            check((led.material_override as StandardMaterial3D).emission_enabled == (damage < 2), "D2 radio unpowered")
            if damage < 2:
                var fixture: OmniLight3D = station.get_node("V32_StationLight") as OmniLight3D
                check(fixture.visible == (lod == 13) and station.has_node("V32_CanopyRib_30"), "Supported canopy and bounded mobile light")
                check(ReconV3.station_pose(camp, 0.25), "Animated station")
                var scope: Node3D = instrument.get_node("V32_Display/V32_ScopePivot") as Node3D
                check(absf(scope.rotation_degrees.z + 90.0) < 0.01, "Physical animated scope")
                check(ReconV3.station_pose(camp, 0.0), "Reset station")
            else:
                check(not station.has_node("V32_StationLight") and station.has_node("V32_FallenCanopy"), "Broken roof and no live light")
                check(not ReconV3.station_pose(camp, 0.25), "D2 electronics cannot animate")
            var tower: Node3D = core.get_node("V2_TorreTripode") as Node3D
            check(tower.has_node("V3_FootSocket_-1_-1"), "Anchored supports")
            if damage < 2:
                var mast: Node3D = tower.get_node("V2_MastilDesplegable") as Node3D
                var shaft: MeshInstance3D = mast.get_node("V3_SlidingShaft") as MeshInstance3D
                var head: Node3D = mast.get_node("V2_CabezalOpticoGiratorio") as Node3D
                check(head.has_node("V3_OpaqueLens_1") and head.has_node("V3_YawBearing") and head.has_node("V31_OpticalHeadCable") and head.has_node("V31_OpticBrow_1"), "Closed optics and attached hardware")
                var head_size: Vector3 = (head.get_node("CarcasaSensorCerrada") as MeshInstance3D).mesh.get_aabb().size
                var length: float = (shaft.mesh as CylinderMesh).height
                var extended: float = head.position.y
                check(Art.pose_deploy(camp, 0.0), "Pack")
                check(mast.scale == Vector3.ONE and absf(head.position.y - extended) > 0.55, "Rigid shaft translates")
                check(absf((shaft.mesh as CylinderMesh).height - length) < 0.001 and (head.get_node("CarcasaSensorCerrada") as MeshInstance3D).mesh.get_aabb().size == head_size, "Head and shaft dimensions unchanged")
                check(Art.pose_deploy(camp, 1.0) and absf(head.position.y - extended) < 0.01, "Restored")
                check(Recon.pose_scan(camp, 45.0) and absf(head.rotation_degrees.y - 45.0) < 0.01, "Optical yaw")
                Recon.pose_scan(camp, 0.0)
            else:
                check(not tower.has_node("V2_MastilDesplegable") and not Recon.pose_scan(camp, 85.0), "D2 disabled optics")
    var parts: Array[MeshInstance3D] = []
    _meshes(camp, parts)
    var sculpted: int = 0
    var mapped: int = 0
    var paint: int = 0
    var accent: Color = Art.STEEL if faction < 0 else Style.faction_color(faction)
    for part in parts:
        var material: StandardMaterial3D = part.material_override as StandardMaterial3D
        check(material != null and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and material.cull_mode == BaseMaterial3D.CULL_BACK, "Opaque mesh")
        if material != null and material.albedo_color == accent:
            paint += 1
        if material != null and material.has_meta("recon_v31_finish"):
            check(material.albedo_texture is ImageTexture and material.uv1_triplanar, "Native grain finish")
            mapped += 1
        if part.mesh is ArrayMesh:
            sculpted += 1
            check(_closed(part.mesh), "Closed custom topology " + str(part.name))
    check(sculpted >= (3 if damage == 3 else 24), "Substantial 3D sculpture")
    check(mapped >= (3 if damage == 3 else 18), "Distinct industrial material finish")
    check(paint >= (3 if damage == 3 else 9), "Faction/neutral color retained")
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
    viewport.name = "ReconV3NativeGodotRender"
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
    for faction in range(-1, 8):
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
                        camera.size = 4.7
                        camera.position = Vector3(0.5, 3.2, -5.5)
                        camera.look_at(Vector3(-1.55, 1.15, 1.0), Vector3.UP)
                        ReconV3.station_pose(camp, 0.25)
                        await _shot(viewport, "recon_v32_console_close.png")
                        camera.position = Vector3(-7.0, 4.2, 6.4)
                        camera.look_at(Vector3(-1.55, 1.1, 1.38), Vector3.UP)
                        await _shot(viewport, "recon_v32_canopy_rear.png")
                        ReconV3.station_pose(camp, 0.0)
                        camera.size = 12.8
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
    check(audits == 72, "72 model audits including neutral")
    check(screenshots == 27,
        "25 existing views plus 2 station closeups")
    viewport.queue_free()
    await process_frame
    if failures > 0:
        printerr("FAIL RECON CAMP V3 NATIVE: %d issues" % failures)
        quit(1)
        return
    print("PASS RECON CAMP V3 NATIVE: 72 audits, 27 PNGs")
    quit(0)
