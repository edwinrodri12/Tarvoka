extends SceneTree

# A mesh-by-mesh topology guard for the 3D redesign. A shiny material with
# disabled culling is NOT enough: both shapes must have physically closed
# triangle edges so that Android and WebGL cannot see through their bodies.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Rig = preload("res://scripts/ui/TankVisualRig3D.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _key(v: Vector3) -> String:
    return "%d,%d,%d" % [
        roundi(v.x*10000.0),roundi(v.y*10000.0),roundi(v.z*10000.0)]

static func _pair(a: Vector3,b: Vector3) -> String:
    var x: String = _key(a)
    var y: String = _key(b)
    return x+"|"+y if x < y else y+"|"+x

static func _watertight(mesh: Mesh) -> bool:
    if mesh == null or mesh.get_surface_count() != 1:
        return false
    var arrays: Array = mesh.surface_get_arrays(0)
    var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    # Non-indexed SurfaceTool triangles expose a null index slot in Godot 4.
    var faces := PackedInt32Array()
    if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
        faces = arrays[Mesh.ARRAY_INDEX]
    var edges: Dictionary = {}
    var count: int = faces.size() if faces.size() > 0 else positions.size()
    if count < 60 or count % 3 != 0:
        return false
    for i in range(0,count,3):
        var va: Vector3 = positions[faces[i]] if faces.size() > 0 else positions[i]
        var vb: Vector3 = positions[faces[i+1]] if faces.size() > 0 else positions[i+1]
        var vc: Vector3 = positions[faces[i+2]] if faces.size() > 0 else positions[i+2]
        if (vb-va).cross(vc-va).length_squared() <= 0.00000001:
            return false
        for endpoints in [[va,vb],[vb,vc],[vc,va]]:
            var edge: String = _pair(endpoints[0],endpoints[1])
            edges[edge] = int(edges.get(edge,0))+1
    if edges.size() < 30:
        return false
    for multiplicity in edges.values():
        if int(multiplicity) != 2:
            return false
    return true

func _run() -> void:
    var base: Node3D = Models.build("tank",0,false)
    var finished: Node3D = Models.build("tank",0,true)
    assert(base != null and finished != null)
    assert(not base.get_meta("tarvoka_mbt_silhouette_v5",false))
    assert(finished.get_meta("tarvoka_mbt_silhouette_v5",false))
    assert(finished.get_meta("tarvoka_mbt_art_v6",false))
    assert(finished.get_meta("tarvoka_mbt_hero_v7",false))
    assert(int(finished.get_meta("tarvoka_mbt_hero_v7_textured",0)) >= 14)
    var hull: MeshInstance3D = finished.find_child("CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var turret: MeshInstance3D = finished.find_child("TorreBajaSoldadaV7",true,false) as MeshInstance3D
    var mantlet: MeshInstance3D = finished.find_child("MantleteConjuntoV7",true,false) as MeshInstance3D
    var glacis: MeshInstance3D = finished.find_child("GlacisCeramicoV7_1",true,false) as MeshInstance3D
    var cheek: MeshInstance3D = finished.find_child("ModuloBlindajeCeramicoV7_1",true,false) as MeshInstance3D
    assert(hull != null and turret != null and glacis != null and cheek != null and mantlet != null)
    # The actual hero geometry (not old hidden prototypes) has no open edges.
    assert(_watertight(hull.mesh))
    assert(_watertight(turret.mesh))
    assert(hull.visible and turret.visible and cheek.visible and mantlet.visible)
    assert(not finished.find_child("CascoHermeticoV5",true,false).visible)
    assert(not finished.find_child("TorreHermeticaV5",true,false).visible)
    assert(not finished.find_child("MejillaMonoliticaV6_1",true,false).visible)
    assert(mantlet.get_parent().name == Models.TANK_BARREL_PIVOT)
    var coat: StandardMaterial3D = hull.material_override as StandardMaterial3D
    var turret_coat: StandardMaterial3D = turret.material_override as StandardMaterial3D
    assert(coat != null and turret_coat != null)
    assert(coat.albedo_texture != null)
    assert(coat.albedo_texture.get_size() == Vector2(256,256))
    assert(coat.albedo_texture == turret_coat.albedo_texture)
    assert(Models.paintable_count(finished) == 14)
    assert(Models.inspect_meshes(finished) > Models.inspect_meshes(base))
    for side in [-1,1]:
        var track: MultiMeshInstance3D = finished.find_child(
            "OrugaArticuladaG09V7_%s" % side,true,false) as MultiMeshInstance3D
        assert(track != null and track.multimesh != null)
        assert(track.multimesh.instance_count == 84)
        for wheel in range(7):
            assert(finished.find_child("RuedaG09V7_%s_%02d" % [side,wheel],true,false) != null)
    var wheel: MeshInstance3D = finished.find_child("RuedaG09V7_1_00",true,false) as MeshInstance3D
    var rest: Basis = wheel.transform.basis
    assert(Rig.pose(finished,"move",0.27,Vector2i(1,0)))
    assert(not rest.is_equal_approx(wheel.transform.basis))
    Rig.restore(finished)
    # Five physical damage stages are still reversible, with superseded
    # armor permanently hidden even after full repair.
    assert(Damage.apply_stage(finished,3))
    assert(not cheek.visible)
    assert(Damage.apply_stage(finished,4))
    assert(not mantlet.visible)
    assert(Damage.apply_stage(finished,0))
    assert(cheek.visible and mantlet.visible)
    assert(not finished.find_child("MejillaMonoliticaV6_1",true,false).visible)
    assert(not finished.find_child("BastidorCanonIntegradoV6",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(finished,faction) == 14)
    base.free()
    finished.free()
    print("PASS G09 V7: watertight hero hull and turret, 256px shared PBR, 168 linked track shoes, wheels, all 8 factions and 5 HP states")
    quit(0)
