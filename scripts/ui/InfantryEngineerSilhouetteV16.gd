extends RefCounted
class_name TarvokaInfantryEngineerSilhouetteV16

# Real 3D anatomical proportion pass on the ORIGINAL engineer meshes.
# V13/V14/V15 already smoothed armor/hardware, but the underlying humanoid
# body remained a set of cylindrical segments with a rounded-box waist.
# V16 replaces only existing torso, pelvis and leg meshes with continuous
# tapered closed shells; no extra nodes, rig pivots, animations or stats.
const V13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const V15=preload("res://scripts/ui/InfantryEngineerGearV15.gd")
const FLAG: String="tarvoka_engineer_silhouette_v16"
const OLD: String="tarvoka_engineer_silhouette_v16_old"
const NEW: String="tarvoka_engineer_silhouette_v16_new"
const CORE: String="PetoBase"
const PELVIS: String="CinturaEquipo"
const THIGH: String="V2_MusloTaper"
const SHIN: String="V2_PantorrillaTaper"
const BOOT: String="V2_BotaMoldeada"

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(CORE,true,false) is MeshInstance3D)

static func _part(model: Node3D, name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func _morph(model: Node3D, name: String, mesh: Mesh,
        scale: Vector3=Vector3.ONE,
        offset: Vector3=Vector3.ZERO) -> bool:
    var part: MeshInstance3D=_part(model,name)
    if part==null or part.mesh==null or mesh==null:
        return false
    # Save true materials/transforms and old geometry for V15/V16 A/B QA.
    # The scene tree and respective articulated rig remain unchanged.
    part.set_meta(OLD,{
        "mesh":part.mesh,"scale":part.scale,"position":part.position})
    part.set_meta(NEW,{
        "mesh":mesh,"scale":scale,"position":part.position+offset})
    part.mesh=mesh
    part.scale=scale
    part.position+=offset
    return true

static func _round(model: Node3D, name: String,
        size: Vector3, offset: Vector3=Vector3.ZERO) -> bool:
    var part: MeshInstance3D=_part(model,name)
    if part==null or not part.mesh is SphereMesh:
        return false
    var original: SphereMesh=part.mesh as SphereMesh
    var improved: SphereMesh=original.duplicate() as SphereMesh
    improved.radial_segments=maxi(original.radial_segments,16)
    improved.rings=maxi(original.rings,10)
    return _morph(model,name,improved,size,offset)

static func show_contours(model: Node3D, refined: bool) -> bool:
    if not has_model(model):
        return false
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if part.has_meta(OLD) and part.has_meta(NEW):
            var restore: Dictionary=part.get_meta(NEW if refined else OLD)
            part.mesh=restore["mesh"]
            part.scale=restore["scale"]
            part.position=restore["position"]
    model.set_meta("tarvoka_engineer_v16_visible",refined)
    return true

static func apply(model: Node3D, hero: bool) -> bool:
    if model==null or has_model(model) or not V15.has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!="infantry_engineer":
        return false
    var torso: Node3D=model.find_child(
        "TorsoRig",true,false) as Node3D
    var pelvis: Node3D=model.find_child(
        "CaderaRig",true,false) as Node3D
    if torso==null or pelvis==null:
        return false

    # Same original torso anchor, now anatomical inverted triangle:
    # soft shoulder/chest volume curves into a narrower waist and smoothly
    # overlaps the pelvis. Closed top + bottom caps prevent hollow views.
    var torso_rings: Array=[
        Vector3(0.180,-0.477,0.126),
        Vector3(0.265,-0.405,0.178),
        Vector3(0.317,-0.252,0.198),
        Vector3(0.370,-0.046,0.235),
        Vector3(0.398,0.155,0.259),
        Vector3(0.356,0.323,0.228),
        Vector3(0.188,0.435,0.149)
    ]
    if _part(model,CORE)==null or _part(model,CORE).get_parent()!=torso:
        return false
    if not _morph(model,CORE,V13._lathe(torso_rings,hero)):
        return false

    # Anatomical pelvis spans the waist/hip seam with an opaque taper.
    # Leg rigs stay exactly where Godot expects them for movement and idle.
    var pelvic_rings: Array=[
        Vector3(0.175,-0.188,0.102),
        Vector3(0.275,-0.125,0.178),
        Vector3(0.322,0.008,0.205),
        Vector3(0.298,0.117,0.182),
        Vector3(0.160,0.176,0.102)
    ]
    if _part(model,PELVIS)==null or _part(model,PELVIS).get_parent()!=pelvis:
        return false
    if not _morph(model,PELVIS,V13._lathe(pelvic_rings,hero)):
        return false

    for side in [-1,1]:
        var suffix: String="_%d"%side
        var leg: Node3D=model.find_child(
            "PiernaRig"+suffix,true,false) as Node3D
        if leg==null or leg.get_parent()!=pelvis:
            return false
        for name in [THIGH+suffix,SHIN+suffix,BOOT+suffix]:
            var part: MeshInstance3D=_part(model,name)
            if part==null or part.get_parent()!=leg or (
                    not part.mesh is ArrayMesh):
                return false
        # A real taper from hip/hamstring to knee replaces the pinched
        # V2 almost-cylindrical leg. Closed mesh is kept UNDER the
        # additional opaque kneecaps and LOD8 faction knee marker.
        var thigh: Array=[
            Vector3(0.107,-0.537,0.119),
            Vector3(0.150,-0.464,0.157),
            Vector3(0.175,-0.352,0.183),
            Vector3(0.194,-0.192,0.201),
            Vector3(0.192,-0.038,0.191),
            Vector3(0.116,0.082,0.131)
        ]
        var calf: Array=[
            Vector3(0.094,-0.913,0.123),
            Vector3(0.126,-0.829,0.142),
            Vector3(0.149,-0.677,0.159),
            Vector3(0.155,-0.562,0.161),
            Vector3(0.112,-0.435,0.119)
        ]
        var boot: Array=[
            Vector3(0.105,-0.921,0.143),
            Vector3(0.134,-0.863,0.189),
            Vector3(0.137,-0.781,0.197),
            Vector3(0.105,-0.663,0.135)
        ]
        for spec in [[THIGH,thigh],[SHIN,calf],[BOOT,boot]]:
            var label: String=str(spec[0])+suffix
            if not _morph(model,label,V13._lathe(spec[1],hero),
                    Vector3.ONE):
                return false

        # Lighter knee pads, stronger continuous calf-to-boot overlap.
        # Native spherical caps are closed; keeping them beneath the mesh
        # avoids any reintroduction of see-through seams in Android LOD8.
        if not _round(model,"V8_JuntaRodillaCerrada"+suffix,
                Vector3(0.292,0.300,0.376)):
            return false
        if not _round(model,"V8_CantoneraRodillaPosterior"+suffix,
                Vector3(0.240,0.226,0.130)):
            return false
        if not _round(model,"V8_PantorrillaContinua"+suffix,
                Vector3(0.273,0.412,0.304)):
            return false
        # The additional sealed hip and boot connectors from V12.3 stay
        # untouched and continue moving with their corresponding leg rigs.

    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v16_visible",true)
    model.set_meta("tarvoka_engineer_v16_hero",hero)
    return true
