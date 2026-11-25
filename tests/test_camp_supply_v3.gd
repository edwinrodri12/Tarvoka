extends SceneTree

# Real native Godot renders for Suministros V3: 360 camera, 8 faction paints,
# 2 LODs and 4 visual damage stages; no tactical gameplay hooks.
const CAMP = preload("res://scripts/ui/CampModels3DV1.gd")
const V2 = preload("res://scripts/ui/CampSupplyFinishV2.gd")
const V3 = preload("res://scripts/ui/CampSupplyReadabilityV3.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const DIR := "res://build/qa/camps-supply-v3"
const CAMERA_POINTS := [
    Vector3(9.8, 8.1, -10.0),
    Vector3(-9.8, 8.1, -10.0),
    Vector3(9.8, 8.1, 10.0),
    Vector3(-9.8, 8.1, 10.0)
]
var fails: int = 0
var count: int = 0
var screenshots: int = 0

func verify(ok: bool, info: String) -> void:
    if not ok:
        fails += 1
        push_error("CAMP SUPPLY V3: " + info)

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, parts: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        parts.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, parts)

func _audit(faction: int, lod: int, damage: int) -> Node3D:
    var camp: Node3D = CAMP.build("suministros", faction, lod, damage, false)
    verify(camp != null, "Build required camp")
    if camp == null:
        return null
    count += 1
    verify(str(camp.get_meta("builder_role")) == "infantry_logistic",
        "Exact approved specialist only")
    verify(camp.get_meta("no_gameplay_effects", false) == true
        and camp.get_meta("temporary_structure", false) == true
        and camp.get_meta("no_unit_or_credit_production", false) == true,
        "Art-only invariant")
    verify(int(camp.get_meta("suministros_art_v3", -1)) == 3
        and camp.get_meta("suministros_v3_no_gameplay_changes", false) == true,
        "Latest supply finish is mounted")
    var v2: Node3D = camp.get_node_or_null(
        "EquipamientoDesplegable/" + V2.CORE) as Node3D
    if damage < 3:
        verify(v2 != null, "Intact v2 model preserved")
        if v2 != null:
            var v3: Node3D = v2.get_node_or_null(V3.CORE) as Node3D
            verify(v3 != null, "V3 mounted inside same rig")
            var pallet: MeshInstance3D = v2.get_node_or_null(
                "PlataformaMunicion") as MeshInstance3D
            verify(pallet != null and pallet.position.z < -1.5,
                "Ammo shelf visible at front, never hidden behind tent")
            for i in range(2):
                var crate: Node3D = v2.get_node_or_null(
                    "V2_CajaMunicionEstanca_" + str(i)) as Node3D
                verify(crate != null and crate.position.z < -1.9,
                    "Genuine V2 ammo crates relocated, not duplicated")
            if v3 != null:
                for node_name in ["V3_PlacaMunicionFrontal",
                    "V3_EscudoLateralFaccion_-1",
                    "V3_EscudoLateralFaccion_1",
                    "V3_BancoInterior", "V3_PantallaInteriorOpaca",
                    "V3_ProteccionExternaTanque_0",
                    "V3_ProteccionExternaTanque_1",
                    "V3_FranjaServicioBomba"]:
                    verify(v3.get_node_or_null(node_name) != null,
                        "Actual solid component: " + node_name)
    else:
        verify(v2 == null,
            "Destroyed camp has rubble only and no intact visual rig")
    var parts: Array[MeshInstance3D] = []
    _meshes(camp, parts)
    var color_count: int = 0
    for part in parts:
        verify(part.mesh is BoxMesh or part.mesh is CylinderMesh,
            "All camp meshes physically closed: " + str(part.name))
        if part.material_override is StandardMaterial3D:
            var material: StandardMaterial3D = part.material_override
            verify(material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
                and material.cull_mode == BaseMaterial3D.CULL_BACK,
                "No transparent or back-face-only model part")
            if material.albedo_color == Style.faction_color(faction):
                color_count += 1
        else:
            verify(false, "Material must exist")
        var aabb: AABB = part.mesh.get_aabb()
        verify(minf(aabb.size.x, minf(aabb.size.y, aabb.size.z)) > 0.003,
            "No zero-thickness geometry: " + str(part.name))
    verify(color_count >= 3 if damage >= 3 else color_count >= 15,
        "Color is readable at both LODs")
    if damage < 3:
        verify(CAMP.pose_deploy(camp, 0.0), "Roof may fold")
        verify(CAMP.pose_deploy(camp, 1.0), "Roof may unfold")
    return camp

func _shot(viewport: SubViewport, file: String) -> void:
    await process_frame
    await process_frame
    await process_frame
    var image: Image = viewport.get_texture().get_image()
    verify(image != null and not image.is_empty(), "Render exists")
    if image == null or image.is_empty():
        return
    var changed: int = 0
    for y in range(90, 540, 26):
        for x in range(130, 700, 26):
            var c: Color = image.get_pixel(x, y)
            if c.get_luminance() > 0.29:
                changed += 1
    verify(changed > 10, "Visible lit geometry: " + file)
    verify(image.save_png(ProjectSettings.globalize_path(
        DIR + "/" + file)) == OK, "PNG written: " + file)
    screenshots += 1

func _run() -> void:
    verify(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(DIR)) == OK, "Output folder")
    var viewport := SubViewport.new()
    viewport.size = Vector2i(800, 600)
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
    camera.size = 11.2
    stage.add_child(camera)
    camera.current = true
    for faction in range(8):
        for lod in [8, 13]:
            for damage in range(4):
                var camp: Node3D = _audit(faction, lod, damage)
                if camp == null:
                    continue
                if damage == 0 and faction in [0, 1]:
                    stage.add_child(camp)
                    for view in range(4):
                        camera.position = CAMERA_POINTS[view]
                        camera.look_at(Vector3(0, 1.05, 0), Vector3.UP)
                        await _shot(viewport, "supply_v3_f%02d_lod%d_view%d.png"
                            % [faction, lod, view])
                    stage.remove_child(camp)
                elif faction == 0 and lod == 13 and damage in [2, 3]:
                    stage.add_child(camp)
                    camera.position = CAMERA_POINTS[0]
                    camera.look_at(Vector3(0, 1.05, 0), Vector3.UP)
                    await _shot(viewport, "supply_v3_damage%d.png" % damage)
                    stage.remove_child(camp)
                camp.free()
    verify(count == 64, "8 factions x 2 LOD x 4 damages = 64")
    verify(screenshots == 18, "4 angles x 2 factions x 2 LOD + D2 + D3")
    viewport.queue_free()
    await process_frame
    if fails > 0:
        printerr("FAIL SUPPLY CAMP V3 NATIVE QA: %d failures" % fails)
        quit(1)
        return
    print("PASS SUPPLY CAMP V3 NATIVE QA: 64 audits, 18 views")
    quit(0)
