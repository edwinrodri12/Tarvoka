extends SceneTree

# A mesh-by-mesh topology guard for the 3D redesign. A shiny material with
# disabled culling is NOT enough: both shapes must have physically closed
# triangle edges so that Android and WebGL cannot see through their bodies.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")

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
    var hull: MeshInstance3D = finished.find_child("CascoHermeticoV5",true,false) as MeshInstance3D
    var turret: MeshInstance3D = finished.find_child("TorreHermeticaV5",true,false) as MeshInstance3D
    var stern: MeshInstance3D = finished.find_child("PortonTraseroHermeticoV5",true,false) as MeshInstance3D
    var mantlet: MeshInstance3D = finished.find_child("MantleteMonoliticoV5",true,false) as MeshInstance3D
    assert(hull != null and turret != null and stern != null and mantlet != null)
    assert(_watertight(hull.mesh))
    assert(_watertight(turret.mesh))
    assert(hull.material_override.normal_enabled)
    assert(turret.material_override.normal_enabled)
    assert(mantlet.get_parent().name == Models.TANK_BARREL_PIVOT)
    assert(Models.paintable_count(finished) == 14)
    assert(Models.inspect_meshes(finished) > Models.inspect_meshes(base))
    var old_cheek: MeshInstance3D = finished.find_child("MejillaCeramicaBiselada1",true,false) as MeshInstance3D
    var new_cheek: MeshInstance3D = finished.find_child("MejillaPrincipalV5_1",true,false) as MeshInstance3D
    assert(old_cheek != null and new_cheek != null)
    assert(not old_cheek.visible and new_cheek.visible)
    assert(Damage.apply_stage(finished,3))
    assert(not new_cheek.visible)
    assert(Damage.apply_stage(finished,0))
    assert(not old_cheek.visible and new_cheek.visible)
    assert(Damage.apply_stage(finished,4))
    assert(not finished.find_child("AroSelladoCanonV5",true,false).visible)
    assert(Damage.apply_stage(finished,0))
    assert(finished.find_child("AroSelladoCanonV5",true,false).visible)
    base.free()
    finished.free()
    print("PASS G09 V5: closed top/side/bottom hull and turret topology, no restored old armor, full faction and damage compatibility")
    quit(0)
