extends RefCounted
class_name TarvokaG11FinalAuditV33

# The G11 is in art LOCKDOWN: verify finished V30-V32 geometry/materials
# rather than adding unproven armor, boxes, meshes or shader passes.
# All checks are presentation-only; no changes to game-state or units.
const FLAG := "tarvoka_g11_v33_art_audited"
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Rear = preload("res://scripts/ui/G11RearUndercarriageV30.gd")
const Track = preload("res://scripts/ui/G11TrackFinishV19.gd")

static func _mesh(model: Node3D,name: String)->MeshInstance3D:
    if model==null:
        return null
    return model.find_child(name,true,false) as MeshInstance3D

static func _batch(model: Node3D,name: String)->MultiMeshInstance3D:
    if model==null:
        return null
    return model.find_child(name,true,false) as MultiMeshInstance3D

static func verify_tactical_model(model: Node3D,detail: int)->bool:
    if model==null or detail not in [8,10] or (
            not Mobile.has_model(model)) or (
            not bool(model.get_meta(Tactical.FLAG,false))) or (
            not bool(model.get_meta(Rear.FLAG,false))) or (
            int(model.get_meta(Mobile.FLAG,-1))!=detail):
        return false
    # In-place corrections: old full-size underbody box MUST be gone.
    var hull:=_mesh(model,"ChasisLanzacohetes")
    if hull==null or not hull.mesh is ArrayMesh:
        return false
    for side in [-1,1]:
        var track:=_mesh(model,"G11Mobile_Oruga_%d" % side)
        if track==null or not track.mesh is ArrayMesh:
            return false
    var tubes:=_batch(model,"G11Mobile_Lote12Tubos")
    if tubes==null or tubes.multimesh==null or (
            tubes.multimesh.instance_count!=12):
        return false
    var wheels:=_batch(model,"G11Mobile_Lote12Ruedas")
    if detail==10 and (wheels==null or wheels.multimesh==null or (
            wheels.multimesh.instance_count!=12)):
        return false
    if detail==8 and wheels!=null:
        return false
    # Distinct neutral steel, rubber and faction enamel EXIST ALREADY.
    var roof:=_mesh(model,"G11Mobile_Techo")
    var badge:=_mesh(model,"G11Mobile_InsigniaFrontal")
    var windshield:=_mesh(model,"G11Mobile_Parabrisas")
    if roof==null or badge==null or windshield==null or (
            roof.material_override==null or (
            badge.material_override==null) or (
            windshield.material_override==null)):
        return false
    var rubber:=_mesh(model,"G11Mobile_Oruga_-1")
    if rubber.material_override==null or (
            rubber.material_override==badge.material_override):
        return false
    return true

static func verify_hero(model: Node3D)->bool:
    if model==null or not bool(model.get_meta(
            "tarvoka_g11_joint_finish_v23",false)) or (
            not bool(model.get_meta(Rear.FLAG,false))):
        return false
    if _mesh(model,"G11_ProteccionInferior")!=null or (
            _mesh(model,"G11_RampaPosteriorCerrada")!=null):
        return false
    var shell:=_mesh(model,"G11V2_CascoOctogonalCerrado")
    if shell==null or not shell.mesh is ArrayMesh:
        return false
    if not bool(model.get_meta(Track.FLAG,false)):
        return false
    for side in [-1,1]:
        var shoes:=_batch(model,"G11V2_OrugaAnimada_%d" % side)
        if shoes==null or shoes.multimesh==null or (
                shoes.multimesh.instance_count!=46):
            return false
        for axle in range(6):
            if model.find_child("G11_RuedaPivot_%d_%d" % [
                    side,axle],true,false)==null:
                return false
    return true

static func inspect(model: Node3D,detail: int)->Dictionary:
    var ok: bool=(verify_hero(model) if detail==13 else
        verify_tactical_model(model,detail))
    var wheel_count: int=(12 if detail in [10,13] else 0)
    return {
        "passed":ok,
        "tier":detail,
        "approved_wheels":wheel_count,
        "track_shoes":92 if detail==13 else 0,
        "rear_square_removed":bool(model.get_meta(
            "tarvoka_g11_v30_redundant_rear_square_removed",false)
            ) if model!=null else false,
        "geometry_added_by_v33":0,
        "shader_passes_added_by_v33":0
    }
