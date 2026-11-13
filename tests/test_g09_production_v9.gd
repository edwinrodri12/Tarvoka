extends SceneTree

# Production QA: this is instantiated through the exact Android/Web Godot
# unit builder. Not a standalone unrelated concept object.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var old_model: Node3D = Models.build("tank",0,true,8)
    var tank: Node3D = Models.build("tank",0,true,9)
    assert(old_model != null and tank != null)
    assert(not old_model.get_meta("tarvoka_mbt_production_v9",false))
    assert(tank.get_meta("tarvoka_mbt_production_v9",false))
    assert(int(tank.get_meta("tarvoka_mbt_production_v9_painted",0)) >= 10)
    assert(Models.paintable_count(tank) == 14)
    var tires: MultiMeshInstance3D = tank.find_child("G09NeumaticosRuedasV9",true,false) as MultiMeshInstance3D
    var nuts: MultiMeshInstance3D = tank.find_child("G09TornillosRuedasV9",true,false) as MultiMeshInstance3D
    assert(tires != null and nuts != null)
    assert(tires.multimesh.instance_count == 14)
    assert(nuts.multimesh.instance_count == 84)
    assert(tires.multimesh.mesh is TorusMesh)
    var roof: MeshInstance3D = tank.find_child("G09PanelTechoDelanteroV9_1",true,false) as MeshInstance3D
    var optic: MeshInstance3D = tank.find_child("G09LenteSensorLateralV9_1",true,false) as MeshInstance3D
    var glacis: MeshInstance3D = tank.find_child("G09PlacaCentralGlacisV9",true,false) as MeshInstance3D
    var hatch: MeshInstance3D = tank.find_child("G09PanelServicioTorreV9",true,false) as MeshInstance3D
    assert(roof != null and optic != null and glacis != null and hatch != null)
    assert(roof.mesh is ArrayMesh and roof.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > 25)
    assert(roof.material_override.albedo_texture != null)
    assert(roof.material_override.normal_enabled)
    assert(roof.material_override.roughness_texture != null)
    var compact_optic := tank.find_child("G09CabezalPanoramicoCompactoV9",true,false) as MeshInstance3D
    var remote_station := tank.find_child("G09EstacionArmaRasanteV9",true,false) as MeshInstance3D
    assert(compact_optic != null and remote_station != null)
    assert(compact_optic.visible and remote_station.visible)
    assert(not tank.find_child("CabezalPanoramicoG09V7",true,false).visible)
    assert(not tank.find_child("EstacionRemotaBlindadaV7",true,false).visible)
    assert(remote_station.get_parent().name == "ArmaSecundariaEstabilizada")
    assert(roof.get_parent().name == "TorretaGiratoria")
    assert(glacis.get_parent().name == "ChasisBlindado")
    assert(not tank.find_child("CascoHermeticoV5",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(tank,faction) == 14)
    assert(Damage.apply_stage(tank,3))
    assert(not roof.visible and not optic.visible)
    assert(Damage.apply_stage(tank,4))
    assert(not hatch.visible and not tires.visible)
    assert(not compact_optic.visible and not remote_station.visible)
    assert(Damage.apply_stage(tank,0))
    assert(roof.visible and optic.visible and hatch.visible and tires.visible)
    assert(compact_optic.visible and remote_station.visible)
    assert(not tank.find_child("MejillaMonoliticaV6_1",true,false).visible)
    old_model.free()
    tank.free()
    print("PASS G09 production V9: 14 wheel tires, 84 batched wheel lugs, closed roof and glacis armor, eight factions, reversible HP details")
    quit(0)
