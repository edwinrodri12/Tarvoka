extends SceneTree

# Offline Godot 4.3 native-art regression, no mocked SVG/2D models.
const Art = preload("res://scripts/ui/CampModels3DV1.gd")
const Roster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const OUT := "res://build/qa/camps-v1"

func _initialize() -> void:
    call_deferred("_run")

func _meshes(node: Node, found: Array[MeshInstance3D]) -> void:
    if node is MeshInstance3D:
        found.append(node as MeshInstance3D)
    for child in node.get_children():
        _meshes(child, found)

func _audit(kind: String, faction: int, lod: int, damage: int) -> Node3D:
    var model: Node3D = Art.build(kind, faction, lod, damage, false, false, false, false)
    assert(model != null, "Camp failed to build")
    assert(str(model.get_meta("camp_kind")) == kind)
    assert(str(model.get_meta("builder_role")) == str(Art.BUILDERS[kind]))
    assert(Roster.camp_for(str(Art.BUILDERS[kind])) == kind)
    assert(model.get_meta("art_only", false) == true)
    assert(model.get_meta("no_gameplay_effects", false) == true)
    assert(model.get_meta("temporary_structure", false) == true)
    assert(model.get_meta("no_unit_or_credit_production", false) == true)
    assert(int(model.get_meta("visual_lod")) == lod)
    var found: Array[MeshInstance3D] = []
    _meshes(model, found)
    assert(found.size() >= 9, "Camp needs real mesh geometry")
    var accent: Color = Style.faction_color(faction)
    var found_accent := false
    for part in found:
        assert(part.mesh is PrimitiveMesh, "Art must use closed primitive geometry")
        assert(part.material_override is StandardMaterial3D)
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        assert(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED)
        assert(mat.cull_mode == BaseMaterial3D.CULL_BACK)
        if mat.albedo_color == accent:
            found_accent = true
        var mesh_aabb: AABB = part.mesh.get_aabb()
        assert(mesh_aabb.size.x > 0.001 and mesh_aabb.size.y > 0.001 and mesh_aabb.size.z > 0.001)
    assert(found_accent, "Faction paint is missing")
    assert(Art.pose_deploy(model, 0.2))
    assert(is_equal_approx(float(model.get_meta("visual_deploy_progress")), 0.2))
    assert(Art.pose_deploy(model, 1.0))
    assert((model.get_node("EquipamientoDesplegable") as Node3D).visible)
    return model

func _run() -> void:
    var out_abs: String = ProjectSettings.globalize_path(OUT)
    assert(DirAccess.make_dir_recursive_absolute(out_abs) == OK)
    var viewport := SubViewport.new()
    viewport.name = "CampNativeRender"
    viewport.size = Vector2i(640, 480)
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    get_root().add_child(viewport)
    var stage := Node3D.new()
    viewport.add_child(stage)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#1D2932")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color.WHITE
    env.environment.ambient_light_energy = 0.75
    stage.add_child(env)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-54, -35, 0)
    key.light_energy = 1.55
    stage.add_child(key)
    var camera := Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 10.5
    camera.position = Vector3(10.8, 9.4, 12.5)
    stage.add_child(camera)
    camera.look_at(Vector3(0, 0.9, 0))
    camera.current = true

    var audits := 0
    var screenshots := 0
    for kind in Art.CAMPS:
        for faction in range(8):
            for lod in [8, 13]:
                for damage in range(4):
                    var model: Node3D = _audit(kind, faction, lod, damage)
                    audits += 1
                    if faction in [0, 1] and damage == 0:
                        stage.add_child(model)
                        await process_frame
                        await process_frame
                        await process_frame
                        var image: Image = viewport.get_texture().get_image()
                        assert(image != null and not image.is_empty())
                        var filename: String = "%s/%s_f%02d_lod%d.png" % [
                            OUT, kind, faction, lod]
                        assert(image.save_png(ProjectSettings.globalize_path(filename)) == OK)
                        screenshots += 1
                        stage.remove_child(model)
                    elif faction == 0 and lod == 13 and damage == 3:
                        stage.add_child(model)
                        await process_frame
                        await process_frame
                        await process_frame
                        var image: Image = viewport.get_texture().get_image()
                        assert(image != null and not image.is_empty())
                        var filename: String = "%s/%s_ruinas.png" % [OUT, kind]
                        assert(image.save_png(ProjectSettings.globalize_path(filename)) == OK)
                        screenshots += 1
                        stage.remove_child(model)
                    model.free()
    assert(audits == 256, "4 camps x 8 factions x 2 LODs x 4 damage stages")
    assert(screenshots == 20, "16 intact views and 4 ruined previews")
    print("PASS CAMPS V1 NATIVE 3D: %d audits, %d PNGs" % [audits, screenshots])
    viewport.queue_free()
    quit(0)
