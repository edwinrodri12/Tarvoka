extends RefCounted
class_name TarvokaInfantryEngineerOuterArmorV17

# Real 3D organic hard-surface art pass over V16's closed anatomical core.
# Replace existing mesh resources and positions, never add a new renderable.
# Unchanged: arm/leg pivots, animation contacts, faction paints, hit boxes,
# AI, damage, captures and tactical slot count.
const V13=preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const V14=preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const V16=preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const FLAG: String="tarvoka_engineer_outer_armor_v17"
const OLD: String="tarvoka_engineer_outer_armor_v17_original"
const NEW: String="tarvoka_engineer_outer_armor_v17_sculpt"
const FRONT: String="V8_PetoDelanteroContinuo"
const SHOULDER: String="V8_HombreraAnatomica"
const INSIGNIA: String="V8_EscudoTecnicoPecho"
const KNEE: String="Rodillera"
const POCKET: String="BolsilloPierna"
const SOLE: String="V2_Suela"
const TOE: String="V2_PunteraProtegida"
const CASE: String="V12_EstucheDorsalContorneado"

static func _find(model: Node3D, name: String) -> MeshInstance3D:
    return model.find_child(name,true,false) as MeshInstance3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _find(model,FRONT)!=null and
        _find(model,SHOULDER+"_-1")!=null and
        _find(model,SHOULDER+"_1")!=null)

static func _change(model: Node3D, name: String,
        new_mesh: Mesh, new_scale: Vector3,
        new_pos: Vector3) -> bool:
    var part: MeshInstance3D=_find(model,name)
    if part==null or new_mesh==null:
        return false
    part.set_meta(OLD,{
        "mesh":part.mesh,
        "scale":part.scale,
        "position":part.position})
    part.set_meta(NEW,{
        "mesh":new_mesh,
        "scale":new_scale,
        "position":new_pos})
    part.mesh=new_mesh
    part.scale=new_scale
    part.position=new_pos
    return true

static func _place(model: Node3D, name: String,
        new_position: Vector3) -> bool:
    var part: MeshInstance3D=_find(model,name)
    if part==null:
        return false
    return _change(model,name,part.mesh,part.scale,new_position)

static func show_finish(model: Node3D, enabled: bool) -> bool:
    if not has_model(model):
        return false
    for item in model.find_children("*","MeshInstance3D",true,false):
        var part: MeshInstance3D=item as MeshInstance3D
        if not part.has_meta(OLD) or not part.has_meta(NEW):
            continue
        var data: Dictionary=part.get_meta(NEW if enabled else OLD)
        part.mesh=data["mesh"]
        part.scale=data["scale"]
        part.position=data["position"]
    model.set_meta("tarvoka_engineer_v17_visible",enabled)
    return true

static func apply(model: Node3D, hero: bool) -> bool:
    if model==null or has_model(model) or not V16.has_model(model):
        return false
    if str(model.get_meta("tarvoka_infantry_role",""))!="infantry_engineer":
        return false
    var torso: Node3D=model.find_child(
        "TorsoRig",true,false) as Node3D
    var pelvis: Node3D=model.find_child(
        "CaderaRig",true,false) as Node3D
    if torso==null or pelvis==null:
        return false

    # Exterior replaces the previously almost-flat V8 chest plate.
    # A strongly tapered, double-sided-volume 360 shell follows shoulders
    # into abdomen, physically wrapping V16's narrower waist.
    var breast: MeshInstance3D=_find(model,FRONT)
    if breast==null or breast.get_parent()!=torso:
        return false
    var chest_rings: Array=[
        Vector3(0.093,-0.272,0.024),
        Vector3(0.174,-0.221,0.039),
        Vector3(0.252,-0.132,0.051),
        Vector3(0.327,0.024,0.074),
        Vector3(0.334,0.143,0.079),
        Vector3(0.244,0.236,0.060),
        Vector3(0.093,0.271,0.027)
    ]
    if not _change(model,FRONT,V13._lathe(chest_rings,hero),
            Vector3.ONE,
            Vector3(0.0,-0.023,-0.407)):
        return false

    # Faction medallion has to remain on the NEW front surface, not buried
    # inside the chest armor. Its original real material is preserved.
    var chest_mark: MeshInstance3D=_find(model,INSIGNIA)
    if chest_mark==null or chest_mark.get_parent()!=torso:
        return false
    if not _place(model,INSIGNIA,
            Vector3(0.0,0.128,-0.495)):
        return false

    # The V14 rounded shoulder was physically undersized and looked like
    # an isolated ball. New deltoids cover arm roots and descend toward
    # the biceps. Still a CLOSED continuous solid on each original arm rig.
    # Broad sloped deltoid armor, NOT the oversize sphere revealed by
    # the first 5-angle V17 native render. The shoulder has a flatter
    # upper crest, defined sidewall and a narrower bicep contact.
    var shoulder_rings: Array=[
        Vector3(0.072,-0.470,0.077),
        Vector3(0.177,-0.415,0.184),
        Vector3(0.298,-0.266,0.310),
        Vector3(0.431,-0.070,0.396),
        Vector3(0.430,0.109,0.395),
        Vector3(0.356,0.252,0.340),
        Vector3(0.184,0.415,0.207),
        Vector3(0.085,0.497,0.104)
    ]
    for side in [-1,1]:
        var suffix: String="_%d"%side
        var arm: Node3D=model.find_child(
            "BrazoRig"+suffix,true,false) as Node3D
        if arm==null or arm.get_parent()!=torso:
            return false
        var shoulder: MeshInstance3D=_find(model,SHOULDER+suffix)
        if shoulder==null or shoulder.get_parent()!=arm:
            return false
        if not _change(model,SHOULDER+suffix,
                V13._lathe(shoulder_rings,hero),
                Vector3(0.68,0.55,0.65),
                Vector3(0.0,-0.083,-0.065)):
            return false
        # Place existing painted faction shoulder strip ON the outer
        # contour; otherwise a larger real shoulder would swallow it.
        var stripe: MeshInstance3D=_find(model,
            "V8_FaccionHombrera"+suffix)
        if stripe==null or stripe.get_parent()!=arm:
            return false
        if not _place(model,stripe.name,
                Vector3(float(side)*0.298,-0.074,-0.091)):
            return false

        var leg: Node3D=model.find_child(
            "PiernaRig"+suffix,true,false) as Node3D
        if leg==null or leg.get_parent()!=pelvis:
            return false
        # The ORIGINAL V1 kneecap was still a hard rectangular block on top
        # of V16's organic leg. Replace the actual source node, not an
        # unrigged visual overlay. Both faces and sidewalls are closed.
        var pad: MeshInstance3D=_find(model,KNEE+suffix)
        if pad==null or pad.get_parent()!=leg:
            return false
        if not _change(model,KNEE+suffix,
                V13._rounded_press(0.282,0.196,0.083,0.072,
                    0.016,hero),
                Vector3.ONE,
                Vector3(0,-0.476,-0.165)):
            return false

        # Remove the impression of square pouches and blocky soles.
        # These are original scene nodes, still tracking leg movement.
        var pocket: MeshInstance3D=_find(model,POCKET+suffix)
        if pocket==null or pocket.get_parent()!=leg:
            return false
        if not _change(model,POCKET+suffix,
                V13._rounded_press(0.116,0.214,0.177,0.044,
                    0.018,hero),Vector3.ONE,
                Vector3(float(side)*0.145,-0.266,-0.011)):
            return false
        var sole: MeshInstance3D=_find(model,SOLE+suffix)
        if sole==null or sole.get_parent()!=leg:
            return false
        if not _change(model,SOLE+suffix,
                V13._lathe([
                    Vector3(0.099,-0.045,0.194),
                    Vector3(0.130,-0.028,0.226),
                    Vector3(0.132,0.014,0.229),
                    Vector3(0.116,0.043,0.210)
                ],hero),Vector3.ONE,
                Vector3(0,-0.930,-0.128)):
            return false

        # Replace the isolated sphere at the toe with a low, reinforced
        # closed boot cap that overlaps the boot and the actual outsole.
        var toe: MeshInstance3D=_find(model,TOE+suffix)
        if toe==null or toe.get_parent()!=leg:
            return false
        if not _change(model,TOE+suffix,V13._lathe([
                    Vector3(0.091,-0.066,0.074),
                    Vector3(0.119,-0.042,0.105),
                    Vector3(0.120,0.006,0.112),
                    Vector3(0.093,0.043,0.093),
                    Vector3(0.049,0.061,0.052)
                ],hero),Vector3.ONE,Vector3(0,-0.850,-0.300)):
            return false

        # Existing rear case gets a more structured rounded housing,
        # keeping its lids, latches, paint and the original torso rig.
        var case_part: MeshInstance3D=_find(model,CASE+suffix)
        if case_part==null or case_part.get_parent()!=torso:
            return false
        if not _change(model,CASE+suffix,V13._lathe([
                    Vector3(0.066,-0.174,0.078),
                    Vector3(0.101,-0.148,0.116),
                    Vector3(0.115,-0.097,0.128),
                    Vector3(0.119,0.090,0.127),
                    Vector3(0.108,0.144,0.115),
                    Vector3(0.070,0.174,0.080)
                ],hero),case_part.scale,case_part.position):
            return false

        # Keep existing tactical LOD8 identity on the outside of the
        # new pad, not inside it. No faction material is recreated.
        if not hero:
            var marker: MeshInstance3D=_find(model,
                "V3_IdentidadRodillaMapa"+suffix)
            if marker==null or marker.get_parent()!=leg:
                return false
            if not _place(model,marker.name,
                    Vector3(0,-0.485,-0.227)):
                return false

    # No new MeshInstance3D; all faction materials and collision bodies stay.
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_engineer_v17_visible",true)
    model.set_meta("tarvoka_engineer_v17_hero",hero)
    return true
