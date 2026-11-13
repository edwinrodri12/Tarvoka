extends SceneTree

# Visual QA for the next MBT production art pass. Uses real native Godot
# meshes, the real OpenGL inspector, all eight official faction palettes and
# a four-view turntable rather than a concept sketch.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Finish = preload("res://scripts/ui/TankFinish3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Inspector = preload("res://scripts/ui/Unit3DInspector.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tank: Node3D = Models.build("tank",0)
    assert(tank != null)
    assert(tank.get_meta("tarvoka_mbt_finish_v3",false))
    assert(tank.get_meta("tarvoka_mbt_production_v4",false))
    assert(tank.get_meta("tarvoka_mbt_silhouette_v5",false))
    assert(tank.get_meta("tarvoka_mbt_art_v6",false))
    assert(tank.get_meta("tarvoka_pbr_applied",false))
    assert(Models.paintable_count(tank) == 14)
    assert(Models.inspect_meshes(tank) >= 190)
    var hull: Node3D = tank.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = tank.find_child("TorretaGiratoria",true,false) as Node3D
    var finish_root: Node3D = tank.find_child(Finish.ROOT,true,false) as Node3D
    assert(hull != null and turret != null and finish_root != null)
    assert(hull.find_child("AcabadoChasis",false,false) != null)
    assert(turret.find_child("AcabadoTorreta",false,false) != null)
    var angular_hull: MeshInstance3D = tank.find_child("CorazaCascoAngular",true,false) as MeshInstance3D
    var angular_turret: MeshInstance3D = tank.find_child("CorazaTorreFacetada",true,false) as MeshInstance3D
    assert(angular_hull != null and angular_turret != null)
    assert(angular_hull.mesh is ArrayMesh and angular_turret.mesh is ArrayMesh)
    assert(angular_hull.visible and angular_turret.visible)
    var sealed_hull: MeshInstance3D = tank.find_child("CascoHermeticoV5",true,false) as MeshInstance3D
    var sealed_turret: MeshInstance3D = tank.find_child("TorreHermeticaV5",true,false) as MeshInstance3D
    var closed_back: MeshInstance3D = tank.find_child("PortonTraseroHermeticoV5",true,false) as MeshInstance3D
    var mantlet: MeshInstance3D = tank.find_child("MantleteMonoliticoV5",true,false) as MeshInstance3D
    var new_cheek: MeshInstance3D = tank.find_child("MejillaPrincipalV5_1",true,false) as MeshInstance3D
    assert(sealed_hull != null and sealed_turret != null and closed_back != null)
    assert(mantlet != null and new_cheek != null)
    assert(sealed_hull.visible and sealed_turret.visible and closed_back.visible)
    assert(sealed_hull.mesh is ArrayMesh and sealed_turret.mesh is ArrayMesh)
    assert(sealed_hull.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 120)
    assert(sealed_turret.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() >= 120)
    assert(mantlet.get_parent().name == Models.TANK_BARREL_PIVOT)
    var prototype_hull: MeshInstance3D = tank.find_child("MonocascoBlindajeCompuesto",true,false) as MeshInstance3D
    var prototype_turret: MeshInstance3D = tank.find_child("TorreBlindada",true,false) as MeshInstance3D
    assert(prototype_hull != null and prototype_turret != null)
    assert(not prototype_hull.visible and not prototype_turret.visible)
    assert(not Finish.apply(tank)) # No accidental duplicate draw calls.
    var cheek: MeshInstance3D = tank.find_child("MejillaCeramicaBiselada1",true,false) as MeshInstance3D
    var glacis: MeshInstance3D = tank.find_child("ModuloGlacisBiselado-1",true,false) as MeshInstance3D
    var sight: MeshInstance3D = tank.find_child("CristalPanoramicoFrontal",true,false) as MeshInstance3D
    var tow_cable: MeshInstance3D = tank.find_child("CableRemolque1_A",true,false) as MeshInstance3D
    assert(cheek != null and glacis != null and sight != null and tow_cable != null)
    assert(cheek.mesh is ArrayMesh and glacis.mesh is ArrayMesh)
    assert(cheek.material_override.normal_enabled and sight.material_override.normal_enabled)
    assert(sight.material_override.roughness < glacis.material_override.roughness)
    var bolts: MultiMeshInstance3D = tank.find_child("PernosFaldones",true,false) as MultiMeshInstance3D
    var rivets: MultiMeshInstance3D = tank.find_child("PernosCorazaTorre",true,false) as MultiMeshInstance3D
    assert(bolts != null and rivets != null)
    assert(bolts.multimesh.instance_count == 20)
    assert(rivets.multimesh.instance_count == 12)
    # Validate the final mechanical pass and its three cheap draw batches.
    var airduct: MultiMeshInstance3D = tank.find_child("AletasRejillaMotor",true,false) as MultiMeshInstance3D
    var anti_slip: MultiMeshInstance3D = tank.find_child("RelieveAntideslizanteCasco",true,false) as MultiMeshInstance3D
    var hubs: MultiMeshInstance3D = tank.find_child("RemachesBujesRodaje",true,false) as MultiMeshInstance3D
    assert(airduct != null and anti_slip != null and hubs != null)
    assert(airduct.multimesh.instance_count == 28)
    assert(anti_slip.multimesh.instance_count == 48)
    assert(hubs.multimesh.instance_count == 42)
    var bore: MeshInstance3D = tank.find_child("InteriorOscuroCanon",true,false) as MeshInstance3D
    var lens: MeshInstance3D = tank.find_child("LenteTermicoPrincipal",true,false) as MeshInstance3D
    var era: MeshInstance3D = tank.find_child("ERACompuestaBiselada1_1",true,false) as MeshInstance3D
    assert(bore != null and lens != null and era != null)
    assert(bore.get_parent().name == Models.TANK_BARREL_PIVOT)
    assert(lens.material_override.normal_enabled)
    assert(era.mesh is ArrayMesh)
    for f in range(8):
        assert(Models.apply_faction_palette(tank,f) == 14)
        assert(Models.paintable_count(tank) == 14)
        assert(tank.get_meta("tarvoka_mbt_finish_v3",false))
    # Damage still detaches and restores actual chassis/track/barrel meshes.
    assert(Damage.apply_stage(tank,4))
    assert(Damage.current_stage(tank) == 4)
    assert(not bore.visible and not lens.visible and not era.visible)
    assert(Damage.apply_stage(tank,0))
    assert(Damage.current_stage(tank) == 0)
    var new_optic: MeshInstance3D = tank.find_child("VentanaOpticaPanoramicaV6",true,false) as MeshInstance3D
    var new_armor: MeshInstance3D = tank.find_child("MejillaMonoliticaV6_1",true,false) as MeshInstance3D
    var new_mantlet: MeshInstance3D = tank.find_child("BastidorCanonIntegradoV6",true,false) as MeshInstance3D
    assert(new_optic != null and new_armor != null and new_mantlet != null)
    assert(bore.visible and not lens.visible and not sight.visible)
    assert(not era.visible and not cheek.visible and not new_cheek.visible)
    assert(new_armor.visible and new_optic.visible and new_mantlet.visible)
    assert(Damage.apply_stage(tank,3))
    assert(not new_armor.visible)
    assert(Damage.apply_stage(tank,0))
    assert(new_armor.visible and not new_cheek.visible and not era.visible)
    tank.free()

    var inspector = Inspector.new()
    root.add_child(inspector)
    inspector.show_role("tank")
    inspector.set_faction_paint(0)
    inspector.open_viewer()
    for i in range(5):
        await process_frame
    var tile_width := 384
    var tile_height := 270
    var output := Image.create(tile_width*4,tile_height,false,Image.FORMAT_RGBA8)
    output.fill(Color("#142533"))
    var unique: Dictionary = {}
    for i in range(4):
        inspector.rotate_model(90.0 if i > 0 else 0.0)
        for tick in range(4):
            await process_frame
        var photo: Image = inspector.preview.get_texture().get_image()
        assert(photo != null and not photo.is_empty())
        photo.resize(tile_width,tile_height,Image.INTERPOLATE_LANCZOS)
        assert(not unique.has(hash(photo.get_data())))
        unique[hash(photo.get_data())] = true
        output.blit_rect(photo,Rect2i(Vector2i.ZERO,Vector2i(tile_width,tile_height)),
            Vector2i(i*tile_width,0))
    assert(unique.size() == 4)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(output.save_png("res://artifacts/tarvoka_mbt_detail_turntable.png") == OK)
    inspector.hide()
    inspector.queue_free()
    print("PASS MBT art detail: fully sealed V5 chassis and turret, protected mantlet, 14 paint zones, 5 reversible 3D damage stages, 4 OpenGL views")
    quit(0)
