extends RefCounted
class_name TarvokaG11RunningGearV32

# V32: reversible visual running-gear motion for the EXISTING G11 models.
# All wheel/track instances, meshes, suspension and faction materials remain
# those approved in V19-V30; never create or remove vehicle geometry.
const FLAG := "tarvoka_g11_v32_running_gear_pose"
const REST_ANGLE := "tarvoka_g11_v32_original_rotation"
const SLOPE := "tarvoka_g11_v32_visual_elevation_delta"
const WHEEL_BATCH := "G11Mobile_Lote12Ruedas"
const WHEEL_COUNT := 12
const BOUNCE_LIMIT: float = 0.009
const HERO_LINK_TRAVEL: float = 2.15
const HERO_WHEEL_DEGREES: float = 720.0
const MOBILE_WHEEL_DEGREES: float = 720.0
const MAX_PITCH_DEG: float = 4.0
const MAX_ROLL_DEG: float = 0.55
const MAX_TURN_DEG: float = 4.6
const DIFFERENTIAL: float = 0.34
const MOBILE_WHEEL_X: float = 0.912
const MOBILE_WHEEL_Y: float = 0.330
const MOBILE_FIRST_Z: float = -1.0
const MOBILE_WHEEL_STEP: float = 0.40
const MOBILE_INNER_TRACK_RADIUS: float = 0.184
const MOBILE_WHEEL_RADIUS: float = 0.160
const MOBILE_BELT_CLEARANCE: float = MOBILE_INNER_TRACK_RADIUS-(
    MOBILE_WHEEL_RADIUS+BOUNCE_LIMIT)
const FinishV2 = preload("res://scripts/ui/G11FinishV2.gd")
const JointsV22 = preload("res://scripts/ui/G11SuspensionJointsV22.gd")

static func turn_ratio(heading: Vector2i)->float:
    # Pure forward/backward moves are straight. A sideways component
    # introduces different left/right track speeds while the original
    # tactical destination, movement cost and actual hull stay untouched.
    var travel: float=float(absi(heading.x)+absi(heading.y))
    if travel<1.0:
        return 0.0
    return clampf(float(heading.x)/travel,-1.0,1.0)*DIFFERENTIAL

static func wheel_safe()->bool:
    return MOBILE_BELT_CLEARANCE>=0.014

static func _movement_pose(t: float,heading: Vector2i,
        incline: float)->Vector3:
    var p: float=clampf(t,0.0,1.0)
    var envelope: float=sin(PI*p)
    var pitch: float=clampf(rad_to_deg(atan2(incline,2.4)),
        -MAX_PITCH_DEG,MAX_PITCH_DEG)*envelope
    var yaw: float=MAX_TURN_DEG*(turn_ratio(heading)/DIFFERENTIAL)*envelope
    var roll: float=MAX_ROLL_DEG*sin(TAU*2.0*p)*envelope
    return Vector3(pitch,yaw,roll)

static func _mobile_wheels(model: Node3D,t: float,
        heading: Vector2i)->bool:
    var batch:=model.find_child(WHEEL_BATCH,true,false) as MultiMeshInstance3D
    # LOD8 intentionally has NO wheel instances; do not create any while
    # moving or forcibly unhide the LOD10 batch when zoomed out.
    if batch==null or not batch.visible:
        return true
    if batch.multimesh==null or batch.multimesh.instance_count!=WHEEL_COUNT:
        return false
    var n: int=0
    var phase: float=clampf(t,0.0,1.0)
    var differential: float=turn_ratio(heading)
    for side in [-1,1]:
        for axle in range(6):
            var speed: float=1.0+float(side)*differential
            var angle: float=deg_to_rad(MOBILE_WHEEL_DEGREES*phase*speed)
            # Original wheel cylinder's Y axis was rotated onto X.
            var basis: Basis=Basis(Vector3.FORWARD,PI*0.5)*Basis(Vector3.UP,angle)
            var bounce: float=BOUNCE_LIMIT*sin(
                phase*TAU*2.0+float(axle)*0.68+float(side)*0.30)*sin(
                PI*phase)
            batch.multimesh.set_instance_transform(n,Transform3D(
                basis,Vector3(float(side)*MOBILE_WHEEL_X,
                    MOBILE_WHEEL_Y+bounce,
                    MOBILE_FIRST_Z+MOBILE_WHEEL_STEP*float(axle))))
            n+=1
    return true

static func pose_mobile(model: Node3D,t: float,
        heading: Vector2i, incline: float)->bool:
    if model==null or not wheel_safe() or (
            not bool(model.get_meta("tarvoka_g11_tactical_readability_v24",
            false))):
        return false
    if not model.has_meta(REST_ANGLE):
        model.set_meta(REST_ANGLE,model.rotation_degrees)
    var rest: Vector3=model.get_meta(REST_ANGLE)
    model.rotation_degrees=rest+_movement_pose(t,heading,incline)
    if not _mobile_wheels(model,t,heading):
        return false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g11_v32_turn_ratio",turn_ratio(heading))
    return true

static func restore_mobile(model: Node3D)->bool:
    if model==null or not model.has_meta(REST_ANGLE):
        return false
    var rest: Vector3=model.get_meta(REST_ANGLE)
    model.rotation_degrees=rest
    if not _mobile_wheels(model,0.0,Vector2i.ZERO):
        return false
    model.remove_meta(FLAG)
    model.remove_meta(REST_ANGLE)
    model.remove_meta("tarvoka_g11_v32_turn_ratio")
    model.remove_meta(SLOPE)
    return true

static func pose_hero(model: Node3D,t: float,
        heading: Vector2i, incline: float)->bool:
    if model==null or not bool(model.get_meta(
            "tarvoka_g11_track_finish_v19",false)):
        return false
    var turn: float=turn_ratio(heading)
    for side in [-1,1]:
        var track:=model.find_child(
            "G11V2_OrugaAnimada_%d" % side,true,false) as MultiMeshInstance3D
        if track==null or track.multimesh==null or (
                track.multimesh.instance_count!=46):
            return false
        var speed: float=1.0+float(side)*turn
        FinishV2._update_side(track.multimesh,side,
            clampf(t,0.0,1.0)*HERO_LINK_TRAVEL*speed)
        for axle in range(6):
            var pivot:=model.find_child(
                "G11_RuedaPivot_%d_%d" % [side,axle],
                true,false) as Node3D
            if pivot==null:
                return false
            pivot.rotation_degrees.x=HERO_WHEEL_DEGREES*clampf(
                t,0.0,1.0)*speed
    # The approved 0.008m V23 wheel travel and its spring/clevis
    # relationship are preserved, rather than making the suspension
    # penetrate its already-closed V19 track belt.
    if bool(model.get_meta(JointsV22.FLAG,false)):
        JointsV22.update_pose(model)
    var delta: Vector3=_movement_pose(t,heading,incline)
    model.rotation_degrees+=delta
    model.set_meta(FLAG,true)
    return true
