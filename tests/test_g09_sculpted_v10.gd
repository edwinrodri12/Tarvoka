extends SceneTree

# Scene-independent production QA for the V10 tank users actually see.
# Uses the same build path as Android combat and the native WebGL studio.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _key(v: Vector3) -> String:
    return "%d,%d,%d" % [roundi(v.x*10000.0),roundi(v.y*10000.0),
        roundi(v.z*10000.0)]

static func _edge(a: Vector3,b: Vector3) -> String:
    var x: String = _key(a)
    var y: String = _key(b)
    return x+"|"+y if x<y else y+"|"+x

static func _closed(mesh: Mesh, min_vertices: int = 180, min_edges: int = 60) -> bool:
    var faces: Dictionary = {}
    if mesh == null or mesh.get_surface_count() != 1:
        return false
    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices := PackedInt32Array()
    if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
        indices = arrays[Mesh.ARRAY_INDEX]
    var n: int = indices.size() if indices.size() > 0 else vertices.size()
    if n < min_vertices or n % 3 != 0:
        return false
    for i in range(0,n,3):
        var a: Vector3 = vertices[indices[i]] if indices.size()>0 else vertices[i]
        var b: Vector3 = vertices[indices[i+1]] if indices.size()>0 else vertices[i+1]
        var c: Vector3 = vertices[indices[i+2]] if indices.size()>0 else vertices[i+2]
        if (b-a).cross(c-a).length_squared() <= 0.00000001:
            return false
        for e in [[a,b],[b,c],[c,a]]:
            var edge_id: String = _edge(e[0],e[1])
            faces[edge_id] = int(faces.get(edge_id,0))+1
    if faces.size() < min_edges:
        return false
    for count in faces.values():
        if int(count) != 2:
            return false
    return true

func _run() -> void:
    var old: Node3D = Models.build("tank",0,true,9)
    var new_model: Node3D = Models.build("tank",0,true,10)
    assert(old != null and new_model != null)
    assert(not old.get_meta("tarvoka_mbt_sculpted_v10",false))
    assert(new_model.get_meta("tarvoka_mbt_sculpted_v10",false))
    assert(int(new_model.get_meta("tarvoka_mbt_sculpted_v10_pbr_count",0)) >= 30)
    var old_body: MeshInstance3D = old.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var new_body: MeshInstance3D = new_model.find_child(
        "CorazaSoldadaHermeticaV7",true,false) as MeshInstance3D
    var old_turret: MeshInstance3D = old.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    var new_turret: MeshInstance3D = new_model.find_child(
        "TorreBajaSoldadaV7",true,false) as MeshInstance3D
    assert(old_body != null and new_body != null and old_turret != null and new_turret != null)
    assert(old_body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() <
        new_body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size())
    assert(old_turret.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() <
        new_turret.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size())
    assert(_closed(new_body.mesh) and _closed(new_turret.mesh))
    assert(new_body.visible and new_turret.visible)
    var body_mat: StandardMaterial3D = new_body.material_override as StandardMaterial3D
    var head_mat: StandardMaterial3D = new_turret.material_override as StandardMaterial3D
    assert(body_mat != null and head_mat != null)
    assert(body_mat.albedo_color != head_mat.albedo_color)
    assert(body_mat.normal_enabled and body_mat.roughness_texture != null)
    assert(Models.paintable_count(new_model) == 14)
    assert(Models.paintable_count(old) == 14)
    for side in [-1,1]:
        var cheek := new_model.find_child(
            "G09V10MejillaCompuesta_%s" % side,true,false) as MeshInstance3D
        var wing := new_model.find_child(
            "G09V10BlindajeLateral_%s" % side,true,false) as MeshInstance3D
        var engine := new_model.find_child(
            "G09V10HombroFaldon_%s" % side,true,false) as MeshInstance3D
        assert(cheek != null and wing != null and engine != null)
        assert(cheek.visible and wing.visible and engine.visible)
        assert(cheek.mesh is ArrayMesh and wing.mesh is ArrayMesh)
        assert(_closed(cheek.mesh,72,24))
    assert(not new_model.find_child("ModuloBlindajeCeramicoV7_1",true,false).visible)
    assert(not new_model.find_child("G09PlacaCentralGlacisV9",true,false).visible)
    var damage_cheek: Node3D = new_model.find_child(
        "G09V10MejillaCompuesta_1",true,false) as Node3D
    var turret_service: Node3D = new_model.find_child(
        "G09V10PanelServicioTecho",true,false) as Node3D
    assert(Damage.apply_stage(new_model,3))
    assert(not damage_cheek.visible and turret_service.visible)
    assert(Damage.apply_stage(new_model,4))
    assert(not turret_service.visible and new_body.visible and new_turret.visible)
    assert(Damage.apply_stage(new_model,0))
    assert(damage_cheek.visible and turret_service.visible)
    assert(not new_model.find_child("ModuloBlindajeCeramicoV7_1",true,false).visible)
    for faction in range(8):
        assert(Models.apply_faction_palette(new_model,faction) == 14)
    assert(new_model.find_child("OrugaArticuladaG09V7_1",true,false) != null)
    assert(new_model.find_child("MantleteConjuntoV7",true,false).get_parent().name == Models.TANK_BARREL_PIVOT)
    old.free()
    new_model.free()
    print("PASS G09 V10: 7/8-ring closed hull/turret, actual silhouette changed, connected 3D ceramic cheeks, PBR, 14 colors, 5 HP stages")
    quit(0)
