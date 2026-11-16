extends RefCounted
class_name TarvokaNavalInspectionV13

# V13 is a corrective, reversible inspection pass rather than another
# decorative layer. Fixes washed-out steel chain finish and micro-link
# legibility while preserving every V12 joint/anchor and all naval rules.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V11=preload("res://scripts/ui/NavalContactFinishV11.gd")
const V12=preload("res://scripts/ui/NavalFinalContactV12.gd")

const STAGE_NAME: String="RevisionVisual360MaterialesYEncuadresV13"
const LINKS_SUBSTRING="CurvaCadena"
const METALLIC: float=0.53
const ROUGHNESS_INTACT: float=0.66
const ROUGHNESS_DAMAGED: float=0.82
const TUBE_CORRECTION: float=0.0032
static var _mesh: ArrayMesh
static var _materials: Dictionary={}

static func _legible_chain_mesh() -> ArrayMesh:
    if _mesh!=null:
        return _mesh
    var original: ArrayMesh=V11._chain_link_mesh()
    var arrays: Array=original.surface_get_arrays(0)
    var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    # Inflate the actual tube surface by 3.2 mm along its existing normal,
    # preserving centreline, size of oval and V12's real end coordinates.
    for i in range(vertices.size()):
        vertices[i]=vertices[i]+normals[i]*TUBE_CORRECTION
    arrays[Mesh.ARRAY_VERTEX]=vertices
    var corrected:=ArrayMesh.new()
    corrected.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    _mesh=corrected
    return corrected

static func _chain_material(damage: int) -> StandardMaterial3D:
    if _materials.has(damage):
        return _materials[damage] as StandardMaterial3D
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color("#607981") if damage<=1 else Color("#94745c")
    m.metallic=METALLIC
    m.roughness=ROUGHNESS_DAMAGED if damage>=2 else ROUGHNESS_INTACT
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    _materials[damage]=m
    return m

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V12.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    var changed: int=0
    # Only update the V12 curved-chain geometry: V11 remains available
    # when the V13 checkbox is unchecked and rebuilds the base.
    var v12_stage: Node3D=model.get_node(V12.STAGE_NAME)
    for node in v12_stage.get_node("AcabadosCercanosV12").get_children():
        if not node is MultiMeshInstance3D:
            continue
        var links: MultiMeshInstance3D=node as MultiMeshInstance3D
        if not str(links.name).begins_with(LINKS_SUBSTRING):
            continue
        if links.multimesh==null:
            continue
        links.multimesh.mesh=_legible_chain_mesh()
        links.material_override=_chain_material(damage)
        changed+=1
    stage.set_meta("naval_v13_improved_chains",changed)
    stage.set_meta("naval_v13_faction",faction)
    stage.set_meta("naval_v13_level",level)
    stage.set_meta("naval_v13_damage",damage)
    stage.set_meta("naval_v13_preserves_anchor_coordinates",true)
    stage.set_meta("naval_v13_materials_corrected",true)
    return true
