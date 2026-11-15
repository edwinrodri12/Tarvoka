extends RefCounted
class_name TarvokaAPCVisualRigV1

# 6x6 wheeled P06 native animation. Entirely cosmetic; it never changes
# passenger capacity, HP, movement rules or the G09's finalized rig.
const Burst = preload("res://scripts/ui/APCMachineGunV7.gd")
const MOVE_DURATION := 0.65
const SHOT_DURATION := 1.12 # Machinegun: six discrete muzzle pulses
const RAMP_DURATION := 1.05
const ROOF := "EstacionRemotaP06"
const RAMP := "BisagraRampaP06"
const WHEELS := "RuedaMotorizadaP06_"
const REST_POSITION := "tarvoka_apc_v1_rest"
const PHASE := "tarvoka_apc_v1_phase"
const MOVE_ACTIVE := "tarvoka_apc_v1_move_active"
const MOVE_START := "tarvoka_apc_v1_move_start"
const WHEEL_TRAVEL := TAU*1.7

static func _ease(t: float) -> float:
    var x: float=clampf(t,0.0,1.0)
    return x*x*(3.0-2.0*x)

static func _root(model: Node3D) -> Node3D:
    if model==null or not model.get_meta("tarvoka_apc_sculpt_v1",false):
        return null
    return model.find_child("APC_P06_V1_Blindado6x6",true,false) as Node3D

static func _wheels(model: Node3D,phase: float,
        steer: float=0.0,travel_t: float=0.0) -> void:
    var hull: Node3D=_root(model)
    if hull==null:
        return
    for side in [-1,1]:
        for i in range(3):
            var wheel: Node3D=hull.find_child(
                "RuedaMotorizadaP06_%d_%d" % [side,i],false,false) as Node3D
            if wheel!=null:
                wheel.rotation_degrees.x=phase*WHEEL_TRAVEL*57.29578
                # Only the steering axle pivots; all 6 wheels rotate. The
                # tires, hub bolts and tread batches are wheel descendants.
                wheel.rotation_degrees.y=steer if i==0 else 0.0
                var oscillation: float=sin(
                    TAU*(travel_t*2.15+float(i)*0.17+
                        (0.0 if side<0 else 0.13)))
                wheel.position.y=0.43-0.010*maxf(0.0,oscillation)*
                    sin(PI*travel_t)

static func pose(model: Node3D,kind: String,t: float,
        yaw_degrees: float=35.0) -> bool:
    var base: Node3D=_root(model)
    if base==null:
        return false
    t=clampf(t,0.0,1.0)
    if not model.has_meta(REST_POSITION):
        model.set_meta(REST_POSITION,model.position)
    var rest: Vector3=model.get_meta(REST_POSITION,model.position)
    model.position=rest
    model.rotation_degrees.z=0.0
    var turret: Node3D=base.find_child(ROOF,false,false) as Node3D
    var gun: Node3D=base.find_child("ArmaEstabilizadaP06",true,false) as Node3D
    var ramp: Node3D=base.find_child(RAMP,false,false) as Node3D
    var flash: MeshInstance3D=base.find_child(
        "FogonazoArmaP06",true,false) as MeshInstance3D
    if turret==null or gun==null or ramp==null or flash==null:
        return false
    turret.rotation_degrees.y=0.0
    gun.rotation_degrees.x=0.0
    ramp.rotation_degrees.x=78.0 if model.get_meta("tarvoka_apc_ramp_open",false) else 8.0
    flash.visible=false
    flash.scale=Vector3.ONE
    if kind!="attack" and Burst.has(model):
        Burst.restore(model)

    var progress: float=float(model.get_meta(PHASE,0.0))
    if kind in ["move","move_turn"]:
        if not bool(model.get_meta(MOVE_ACTIVE,false)):
            model.set_meta(MOVE_START,progress)
            model.set_meta(MOVE_ACTIVE,true)
        progress=fposmod(float(model.get_meta(MOVE_START,progress))+0.34*t,1.0)
        model.set_meta(PHASE,progress)
        var envelope: float=sin(PI*t)
        model.position.y-=0.020*absf(sin(TAU*t*2.0))*envelope
        model.rotation_degrees.z=(
            -0.82*envelope if kind=="move_turn" else
            0.36*sin(TAU*t*2.0)*envelope)
    else:
        model.set_meta(MOVE_ACTIVE,false)
    _wheels(model,progress,
        12.0*sin(PI*t) if kind=="move_turn" else 0.0,
        t if kind in ["move","move_turn"] else 0.0)

    match kind:
        "turn_turret":
            turret.rotation_degrees.y=lerpf(0.0,yaw_degrees,_ease(t))
        "attack":
            var aim: float=_ease(t/0.20)
            var settle: float=1.0-_ease((t-0.87)/0.13)
            # Keep the remote station on target throughout six individual
            # automatic shots, then return smoothly to its rest direction.
            turret.rotation_degrees.y=yaw_degrees*aim*settle
            if Burst.has(model):
                Burst.pose(model,t)
                model.rotation_degrees.z=0.10*Burst.recoil(t)
            else:
                # Backwards compatibility with early P06 V1-V5 art levels.
                var impulse: float=_ease((t-0.39)/0.08)*(
                    1.0-_ease((t-0.50)/0.23))
                gun.rotation_degrees.x=-1.7*impulse
                model.rotation_degrees.z=0.25*sin(t*PI*6.0)*impulse
                flash.visible=t>=0.40 and t<0.56
                flash.scale=Vector3.ONE*(0.90+0.28*impulse)
        "open_ramp":
            ramp.rotation_degrees.x=8.0+70.0*_ease(t)
        "close_ramp":
            ramp.rotation_degrees.x=78.0-70.0*_ease(t)
        "hit":
            model.rotation_degrees.z=sin(PI*t*5.0)*0.8*(1.0-t)
        "hit_bullet":
            # Light lateral jolt and return; no geometry or HP mutation.
            model.rotation_degrees.z=sin(PI*t*8.0)*0.46*(1.0-t)
        "hit_explosive":
            # Heavy blast rocks the 6x6 and compresses its suspension.
            model.rotation_degrees.z=sin(PI*t*4.0)*2.15*(1.0-t)
            model.position.y-=0.052*sin(PI*t)
        _:
            pass
    if t>=1.0 and kind=="open_ramp":
        model.set_meta("tarvoka_apc_ramp_open",true)
    elif t>=1.0 and kind=="close_ramp":
        model.set_meta("tarvoka_apc_ramp_open",false)
    model.set_meta("tarvoka_apc_v1_last_pose",kind)
    return true

static func restore(model: Node3D) -> void:
    pose(model,"idle",0.0)
