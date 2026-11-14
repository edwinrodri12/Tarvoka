extends SceneTree

# Verify only the geometry/materials actually used by the main game.
# This script runs under Godot OpenGL3, not a conceptual image generator.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")
const Inspector = preload("res://scripts/ui/Unit3DInspector.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var model: Node3D = Models.build("tank",0,true,8)
    assert(model != null and model.get_meta("tarvoka_mbt_premium_finish_v8",false))
    assert(Models.paintable_count(model) == 14)
    var hull := model.find_child("CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var turret := model.find_child("TorreBajaSoldadaV7",true,false) as MeshInstance3D
    var ceramic := model.find_child("ModuloBlindajeCeramicoV7_1",true,false) as MeshInstance3D
    assert(hull != null and turret != null and ceramic != null)
    assert(hull.visible and turret.visible and ceramic.visible)
    var hull_mat := hull.material_override as StandardMaterial3D
    var ceramic_mat := ceramic.material_override as StandardMaterial3D
    assert(hull_mat != null and ceramic_mat != null)
    assert(hull_mat.albedo_texture != null and hull_mat.albedo_texture.get_size() == Vector2(256,256))
    assert(hull_mat.normal_enabled and hull_mat.normal_texture != null)
    assert(hull_mat.roughness_texture != null)
    assert(hull_mat.albedo_texture == ceramic_mat.albedo_texture)
    assert(hull_mat.albedo_color != ceramic_mat.albedo_color)
    assert(hull_mat.albedo_color.b >= hull_mat.albedo_color.g)
    assert(hull_mat.roughness >= 0.65 and hull_mat.metallic <= 0.35)
    for side in [-1,1]:
        var track := model.find_child("OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(track != null and track.multimesh.instance_count == 84)
        assert(track.multimesh.mesh is ArrayMesh)
        assert(track.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > 120)
        var rest_track: Transform3D = track.multimesh.get_instance_transform(0)
        assert(Rig.pose(model,"move",0.37,Vector2i(1,0)))
        var active_track: Transform3D = track.multimesh.get_instance_transform(0)
        assert(rest_track.origin.distance_to(active_track.origin) > 0.04)
        Rig.restore(model)
        assert(rest_track.origin.distance_to(
            track.multimesh.get_instance_transform(0).origin) < 0.001)
        var front := model.find_child("LuzFrontalG09_%s" % side,true,false) as MeshInstance3D
        var rear := model.find_child("LuzTraseraG09_%s" % side,true,false) as MeshInstance3D
        assert(front != null and rear != null)
        assert(front.material_override.emission_enabled)
        assert(rear.material_override.emission_enabled)
        assert(front.get_parent().name == "ChasisBlindado")
        assert(rear.get_parent().name == "ChasisBlindado")
        assert(model.find_child("CubiertaCompuestaFrontalG09_%s" % side,true,false) != null)
        assert(model.find_child("SoporteFaroBlindadoG09_%s" % side,true,false) != null)
        for end in [-1,1]:
            var drive: MeshInstance3D = model.find_child(
                "RuedaMotrizG09_%s_%s" % [side,end],true,false) as MeshInstance3D
            assert(drive != null and drive.visible and drive.mesh is CylinderMesh)
    var sprocket_teeth := model.find_child(
        "DientesCoronasMotricesG09",true,false) as MultiMeshInstance3D
    assert(sprocket_teeth != null)
    assert(sprocket_teeth.multimesh.instance_count == 48)
    var mantlet := model.find_child("MantleteConjuntoV7",true,false) as MeshInstance3D
    assert(mantlet != null and mantlet.get_parent().name == Models.TANK_BARREL_PIVOT)
    for faction in range(8):
        assert(Models.apply_faction_palette(model,faction) == 14)
    for stage in [0,1,2,3,4,0]:
        assert(Damage.apply_stage(model,stage))
        assert(Damage.current_stage(model) == stage)
    assert(hull.visible and turret.visible)
    assert(ceramic.visible)
    assert(not model.find_child("MejillaMonoliticaV6_1",true,false).visible)
    model.free()

    # Real engine output, used to inspect visual quality of new PBR surfaces.
    var inspector := Inspector.new()
    root.add_child(inspector)
    inspector.show_role("tank")
    inspector.set_faction_paint(0)
    inspector.open_viewer()
    for _i in range(7):
        await process_frame
    var sample: Image = inspector.preview.get_texture().get_image()
    assert(sample != null and not sample.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sample.save_png("res://artifacts/tarvoka_g09_premium_v8_engine.png") == OK)
    inspector.hide()
    inspector.queue_free()
    print("PASS G09 premium V8: graphite armor, independent ceramic pigments, 256px PBR, 168 sculpted tracks, LED/tail lamps, all factions and five damage stages")
    quit(0)
