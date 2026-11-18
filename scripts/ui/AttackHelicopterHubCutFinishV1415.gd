extends RefCounted
class_name TarvokaAttackHelicopterHubCutFinishV1415

# HAT-29 V14.15 — solid broken-metal cut faces, built from the two
# ORIGINAL V14.14 fragmented V14.13 crown meshes. No duplicated debris,
# no changes to V13 physics/animation, no tactical LOD content.
const BASE=preload("res://scripts/ui/AttackHelicopterHubWreckV1414.gd")
const FLAG="tarvoka_a01_hub_cut_finish_v1415"
const ENABLED="tarvoka_a01_hub_cut_finish_v1415_enabled"
const BEFORE="a01_v1415_original_fragment_mesh"
const BEFORE_MATERIAL="a01_v1415_original_fragment_material"
const AFTER="a01_v1415_finished_fragment_mesh"
const AFTER_MATERIAL="a01_v1415_finished_fragment_material"
const CENTER_RADIUS=0.012
const CENTER_HEIGHT=-0.005
const KEY_SCALE=100000.0
const BODY_TINT=[Color(0.72,0.78,0.80),Color(0.88,0.89,0.90)]
const CUT_TINT=Color(1.0,0.94,0.79)

static func _piece(model: Node3D,index: int) -> MeshInstance3D:
    var wreck: Node3D=model.find_child(BASE.V13.WRECK,true,false) as Node3D
    if wreck==null:
        return null
    var part: MeshInstance3D=wreck.find_child(
        BASE.PREFIX+str(index),false,false) as MeshInstance3D
    return part if part!=null and part.get_parent()==wreck else null

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not BASE.has_model(model):
        return false
    for i in range(2):
        var part: MeshInstance3D=_piece(model,i)
        if part==null or not (part.get_meta(BEFORE) is ArrayMesh):
            return false
        if not (part.get_meta(AFTER) is ArrayMesh):
            return false
    return true

static func _point_key(p: Vector3) -> String:
    return "%d,%d,%d" % [
        roundi(p.x*KEY_SCALE),roundi(p.y*KEY_SCALE),
        roundi(p.z*KEY_SCALE)]

static func _edge_key(a: Vector3,b: Vector3) -> String:
    var aa: String=_point_key(a)
    var bb: String=_point_key(b)
    return aa+"|"+bb if aa<bb else bb+"|"+aa

static func _register_edge(edges: Dictionary,a: Vector3,b: Vector3) -> void:
    var key: String=_edge_key(a,b)
    if edges.has(key):
        var entry: Dictionary=edges[key]
        entry["count"]=int(entry["count"])+1
        edges[key]=entry
    else:
        edges[key]={"count":1,"start":a,"end":b}

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,tint: Color) -> void:
    st.set_color(tint)
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _closed_fragment(source: ArrayMesh,index: int) -> ArrayMesh:
    var vertices: PackedVector3Array=(
        source.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            as PackedVector3Array)
    var edges: Dictionary={}
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Reuse every existing V14.14 fragment triangle, with its real
    # jagged tessellated perimeter and the exact same outer silhouette.
    for tri in range(vertices.size()/3):
        var i: int=tri*3
        var a: Vector3=vertices[i]
        var b: Vector3=vertices[i+1]
        var c: Vector3=vertices[i+2]
        _tri(st,a,b,c,BODY_TINT[index])
        _register_edge(edges,a,b)
        _register_edge(edges,b,c)
        _register_edge(edges,c,a)
    # On a torn sector, the original mesh has ONE open boundary loop.
    # Each open oriented edge receives its opposite cut triangle into a
    # common physically embedded inner witness point. This closes the
    # entire 2-manifold without adding a second visible surface shell.
    # The inner point is slightly radially offset to prevent any
    # zero-area top-to-bottom seam at the rotor axis.
    var window: Vector2=BASE.CUT_SECTORS[index]
    var mid: float=(window.x+window.y)*0.5
    var buried:=Vector3(CENTER_RADIUS*cos(mid),CENTER_HEIGHT,
        CENTER_RADIUS*sin(mid))
    for entry in edges.values():
        if int(entry["count"])!=1:
            continue
        var a: Vector3=entry["start"] as Vector3
        var b: Vector3=entry["end"] as Vector3
        # Inverse of the existing exposed edge: watertight, outward
        # normals after SurfaceTool regenerates them.
        _tri(st,b,a,buried,CUT_TINT)
    st.generate_normals()
    return st.commit()

static func _material(original: Material) -> StandardMaterial3D:
    var base: StandardMaterial3D=original as StandardMaterial3D
    var finish: StandardMaterial3D=base.duplicate() as StandardMaterial3D
    finish.albedo_color=Color("#8c989d")
    finish.vertex_color_use_as_albedo=true
    finish.metallic=0.29
    finish.roughness=0.72
    finish.cull_mode=BaseMaterial3D.CULL_DISABLED
    return finish

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    for i in range(2):
        var piece: MeshInstance3D=_piece(model,i)
        if enabled:
            piece.mesh=piece.get_meta(AFTER) as Mesh
            piece.material_override=piece.get_meta(AFTER_MATERIAL) as Material
        else:
            piece.mesh=piece.get_meta(BEFORE) as Mesh
            piece.material_override=piece.get_meta(BEFORE_MATERIAL) as Material
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D) -> bool:
    if not BASE.has_model(model):
        return false
    if has_model(model):
        return set_enabled(model,true)
    # All-or-nothing preparation. The two V13-attached parts remain
    # untouched unless the FULL native cut finish successfully builds.
    var parts: Array[MeshInstance3D]=[]
    var finishes: Array[ArrayMesh]=[]
    var materials: Array[StandardMaterial3D]=[]
    for i in range(2):
        var piece: MeshInstance3D=_piece(model,i)
        if piece==null or not (piece.mesh is ArrayMesh):
            return false
        if not (piece.material_override is StandardMaterial3D):
            return false
        if not bool(piece.get_meta("a01_v1414_from_original_crown",false)):
            return false
        var original: ArrayMesh=piece.mesh as ArrayMesh
        if original.get_surface_count()!=1:
            return false
        var result: ArrayMesh=_closed_fragment(original,i)
        if result==null or result.get_surface_count()!=1:
            return false
        if result.get_faces().size()<=original.get_faces().size():
            return false
        parts.append(piece)
        finishes.append(result)
        materials.append(_material(piece.material_override))
    for i in range(2):
        var piece: MeshInstance3D=parts[i]
        piece.set_meta(BEFORE,piece.mesh)
        piece.set_meta(BEFORE_MATERIAL,piece.material_override)
        piece.set_meta(AFTER,finishes[i])
        piece.set_meta(AFTER_MATERIAL,materials[i])
    model.set_meta(FLAG,true)
    return set_enabled(model,true)
