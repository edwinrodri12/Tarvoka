extends RefCounted
class_name TarvokaAPCBatchingV4

# APC P06 — low-risk static BoxMesh batching for 8-player battle scenes.
# Dynamic wheels, turret, cannon, ramp, hull/armor, paintable surfaces and
# damage-stage meshes are EXCLUDED. The exact authored geometry stays in
# the scene for editability, but eligible static boxes become two-sided
# 3D instances in a few GPU batches rather than dozens of draw calls.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const ORIGINAL_META: String="tarvoka_apc_v4_batched_original"
const BATCH_ROOT: String="APC_P06_V4_BatchesEstaticos"
const BATCH_PREFIX: String="APCV4Box_"

# Only static V1 direct children; no animated ancestors.
const MICRO_PREFIXES: Array[String]=[
    "BrazoSuspension_","CerrojoEscotillaLateral_",
    "TiradorEscotilla_","EscaleraAntideslizante_",
    "SoporteAntena_","PuertoOpticoConductor_",
    "MarcoPuertoConductor_","RejillaRefrigeracion_",
    "BancoTropas_","RespaldoBanco_",
    "ParedInterior","PisoAntideslizanteCompartimento",
    "MontanteRampa_","DintelRampaSuperior","UmbralRampaInferior",
    "PeliculaAntideslizanteRampa"
]
const FIXTURE_PREFIXES: Array[String]=[
    "BlindajeJuntaDelantera_","FaroRecessed_",
    "MarcoFrontalReforzado","ParrillaFrontal","GanchoRemolque"
]

static func _is_prefix(name_text: String,prefixes: Array[String]) -> bool:
    for prefix in prefixes:
        if name_text.begins_with(prefix):
            return true
    return false

static func apply(model: Node3D) -> int:
    if model==null or not model.get_meta("tarvoka_apc_armor_v2",false):
        return 0
    if model.get_meta("tarvoka_apc_v4_static_boxes",false):
        return 0
    var base: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if base==null:
        return 0
    var groups: Dictionary={}
    for child in base.get_children():
        var part: MeshInstance3D=child as MeshInstance3D
        if part==null or not part.visible or not (part.mesh is BoxMesh):
            continue
        if part.material_override==null or part.has_meta(V1.PAINT_META):
            continue
        var part_name: String=str(part.name)
        var category: String=""
        if _is_prefix(part_name,MICRO_PREFIXES):
            category="micro"
        elif _is_prefix(part_name,FIXTURE_PREFIXES):
            category="fixture"
        if category.is_empty():
            continue
        var mat_id: int=part.material_override.get_instance_id()
        var key: String="%s_%d" % [category,mat_id]
        if not groups.has(key):
            groups[key]=[]
        groups[key].append(part)
    var root:=Node3D.new()
    root.name=BATCH_ROOT
    base.add_child(root)
    var packed: int=0
    var groups_count: int=0
    for key in groups:
        var parts: Array=groups[key]
        # A singleton would cost the same draw call, so leave it untouched.
        if parts.size()<2:
            continue
        var instanced_mesh:=BoxMesh.new()
        instanced_mesh.size=Vector3.ONE
        var mm:=MultiMesh.new()
        mm.transform_format=MultiMesh.TRANSFORM_3D
        mm.mesh=instanced_mesh
        mm.instance_count=parts.size()
        var batch:=MultiMeshInstance3D.new()
        batch.name=BATCH_PREFIX+str(groups_count)
        batch.multimesh=mm
        batch.material_override=(parts[0] as MeshInstance3D).material_override
        var is_micro: bool=str(key).begins_with("micro_")
        batch.set_meta("tarvoka_apc_v4_micro",is_micro)
        root.add_child(batch)
        for index in range(parts.size()):
            var part: MeshInstance3D=parts[index] as MeshInstance3D
            var shape: BoxMesh=part.mesh as BoxMesh
            # The unit box is scaled to the authored original's dimensions;
            # all V1 candidate boxes are children of the same static root.
            mm.set_instance_transform(index,
                part.transform*Transform3D(Basis().scaled(shape.size),
                Vector3.ZERO))
            part.visible=false
            part.set_meta(ORIGINAL_META,true)
            packed+=1
        groups_count+=1
    model.set_meta("tarvoka_apc_v4_static_boxes",true)
    model.set_meta("tarvoka_apc_v4_box_count",packed)
    model.set_meta("tarvoka_apc_v4_batch_count",groups_count)
    return packed

static func set_tactical_lod(model: Node3D,reduced: bool) -> int:
    if model==null or not model.get_meta("tarvoka_apc_v4_static_boxes",false):
        return 0
    var root: Node3D=model.find_child(BATCH_ROOT,true,false) as Node3D
    if root==null:
        return 0
    var changed: int=0
    for node in root.get_children():
        var batch: MultiMeshInstance3D=node as MultiMeshInstance3D
        if batch!=null and batch.get_meta("tarvoka_apc_v4_micro",false):
            batch.visible=not reduced
            changed+=1
    return changed
