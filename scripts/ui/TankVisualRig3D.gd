extends RefCounted
class_name TarvokaTankVisualRig3D

# G09 V32 final animation pass. Pure visual rig: BattleSession, HP, firing
# rules, save data and faction palettes are authoritative elsewhere.
# Important: the 0.422-wide V31 inboard tracks never revert or jump when a
# movement finishes, a shot starts, an impact completes, or a pose is reset.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const FinalTracksV29 = preload("res://scripts/ui/TankFinalTracksV29.gd")
const HitV30 = preload("res://scripts/ui/TankHitReactionV30.gd")
const V14 = preload("res://scripts/ui/TankDetailV14.gd")
const LegacyRig = preload("res://scripts/ui/TankLegacyRigV31.gd")

const REST_META := "tarvoka_tank_rest_position"
const TURRET_NAME := "TorretaGiratoria"
const CANNON_NAME := "ElevacionCanon"
const HULL_NAME := "ChasisBlindado"
const SHOT_DURATION := 0.88
const MOVE_DURATION := 0.32
const SHOT_TRIGGER := 0.37
const MOVE_BELT_ADVANCE := 0.31
const ROAD_WHEEL_RADIUS := 0.164
const TRACK_PHASE_META := "tarvoka_v32_track_phase"
const TRACK_START_META := "tarvoka_v32_track_start_phase"
const MOVE_ACTIVE_META := "tarvoka_v32_move_active"
const WHEEL_CACHE_META := "tarvoka_v32_wheel_nodes"

static func has_rig(model: Node3D) -> bool:
    return model!=null and (
        model.find_child(TURRET_NAME,true,false) is Node3D) and (
        model.find_child(CANNON_NAME,true,false) is Node3D) and (
        model.find_child(HULL_NAME,true,false) is Node3D)

static func heading_yaw(heading: Vector2i) -> float:
    if heading==Vector2i.ZERO:
        return 0.0
    return rad_to_deg(atan2(-float(heading.x),-float(heading.y)))

static func _ease(t: float) -> float:
    var x: float = clampf(t,0.0,1.0)
    return x*x*(3.0-2.0*x)

static func _rest_position(model: Node3D) -> Vector3:
    if not model.has_meta(REST_META):
        model.set_meta(REST_META,model.position)
    return model.get_meta(REST_META) as Vector3

static func _phase(model: Node3D,kind: String,t: float) -> float:
    var current: float = float(model.get_meta(TRACK_PHASE_META,0.0))
    if kind=="move":
        if not bool(model.get_meta(MOVE_ACTIVE_META,false)):
            model.set_meta(TRACK_START_META,current)
            model.set_meta(MOVE_ACTIVE_META,true)
        var start: float = float(model.get_meta(TRACK_START_META,current))
        current=fposmod(start+MOVE_BELT_ADVANCE*t,1.0)
        model.set_meta(TRACK_PHASE_META,current)
    else:
        model.set_meta(MOVE_ACTIVE_META,false)
    return current

static func _wheel_nodes(model: Node3D) -> Array:
    var result: Array = model.get_meta(WHEEL_CACHE_META,[])
    if not result.is_empty():
        return result
    for side in [-1,1]:
        for index in range(7):
            for prefix in ["RuedaG09V7","BujeG09V7"]:
                var wheel: MeshInstance3D = model.find_child(
                    "%s_%s_%02d" % [prefix,side,index],
                    true,false) as MeshInstance3D
                if wheel!=null:
                    result.append(wheel)
    model.set_meta(WHEEL_CACHE_META,result)
    return result

static func _animate_running_gear(model: Node3D,phase: float) -> void:
    # All visible parts use the same cumulative travelled belt distance.
    # No UV mutation: material resources can be SHARED across G09 instances.
    # The running gear retains its last position at idle and after recoil.
    if model.get_meta("tarvoka_mbt_track_final_v29",false):
        FinalTracksV29.slide_tracks(model,phase)
    elif model.get_meta("tarvoka_mbt_hero_v7",false):
        Hero.slide_tracks(model,phase)
    var angular: float = phase*FinalTracksV29.PERIMETER/ROAD_WHEEL_RADIUS
    if model.get_meta("tarvoka_mbt_silhouette_v14",false):
        V14.animate_wheels(model,angular/(TAU*1.7))
    for item in _wheel_nodes(model):
        var wheel: MeshInstance3D = item as MeshInstance3D
        if wheel!=null:
            wheel.rotation_degrees=Vector3(0.0,0.0,90.0)
            wheel.rotate_object_local(Vector3.UP,angular)

static func pose(model: Node3D,kind: String,progress: float,
        target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_rig(model):
        return false
    # Only the completed G09 V31/32 adopts cumulative tread phase and
    # delayed cannon recoil. Historic V7–V30 models keep THEIR original
    # authoring/QA animations and reversible UV behaviour.
    if not model.get_meta("tarvoka_mbt_tracks_inboard_v31",false):
        return LegacyRig.pose(model,kind,progress,target_heading)
    var t: float = clampf(progress,0.0,1.0)
    var turret: Node3D = model.find_child(TURRET_NAME,true,false) as Node3D
    var gun: Node3D = model.find_child(CANNON_NAME,true,false) as Node3D
    var hull: Node3D = model.find_child(HULL_NAME,true,false) as Node3D
    model.position=_rest_position(model)
    model.rotation_degrees.z=0.0
    hull.rotation_degrees.x=0.0
    turret.position.y=1.11
    turret.rotation_degrees.y=0.0
    gun.rotation_degrees.x=0.0
    gun.position.z=-0.56

    var muzzle: Node3D = model.find_child("EfectoFogonazoCanon",true,false) as Node3D
    var smoke: Node3D = model.find_child("EfectoHumoCanon",true,false) as Node3D
    var dust: Node3D = model.find_child("EfectoPolvoOrugas",true,false) as Node3D
    var impact: Node3D = model.find_child("EfectoImpactoBlindaje",true,false) as Node3D
    if model.get_meta("tarvoka_hit_v30",false):
        HitV30.pose(model,kind,t)
    for effect in [muzzle,smoke,dust,impact]:
        if effect!=null:
            effect.visible=false
            effect.scale=Vector3.ONE

    match kind:
        "move":
            # Start and finish precisely at the tank's rest pose.
            var cycle: float = t*TAU*2.0
            var envelope: float = sin(PI*t)
            model.position.y -= absf(sin(cycle))*0.036*envelope
            model.rotation_degrees.z=sin(cycle)*0.65*envelope
            hull.rotation_degrees.x=sin(cycle+PI*0.25)*0.58*envelope
            turret.position.y=1.11+sin(cycle)*0.011*envelope
            if dust!=null:
                dust.visible=t>0.06 and t<0.91
                dust.scale=Vector3.ONE*(0.82+0.35*t)
        "attack":
            # Aim first; the actual muzzle flash and cannon recoil happen
            # AFTER the gun reaches its target, never at animation frame 0.
            var aim: float = _ease(t/0.25)
            var return_to_idle: float = 1.0-_ease((t-0.73)/0.27)
            var hold: float = aim*return_to_idle
            var yaw: float = heading_yaw(target_heading)-model.rotation_degrees.y
            turret.rotation_degrees.y=wrapf(yaw,-180.0,180.0)*hold
            var recoil_on: float = _ease((t-SHOT_TRIGGER)/0.07)
            var recoil_off: float = 1.0-_ease((t-0.46)/0.35)
            var recoil: float = recoil_on*recoil_off
            gun.position.z=-0.56+0.30*recoil
            gun.rotation_degrees.x=5.0*hold+1.5*recoil
            turret.position.y=1.11-0.022*recoil
            hull.rotation_degrees.x=-0.50*recoil
            if muzzle!=null:
                muzzle.visible=t>=SHOT_TRIGGER and t<0.54
                muzzle.scale=Vector3.ONE*(0.92+0.58*recoil)
            if smoke!=null:
                smoke.visible=t>=SHOT_TRIGGER+0.04 and t<0.92
                smoke.scale=Vector3.ONE*(0.76+0.60*_ease(
                    (t-SHOT_TRIGGER-0.04)/0.38))
        "hit_bullet":
            # Fast, small-calibre ricochet, no implausible chassis jump.
            model.rotation_degrees.z=sin(t*PI*9.0)*0.54*(1.0-t)
            turret.position.y=1.11-0.009*sin(PI*t)
        "hit_explosion":
            # Heavy HE/bomb/rocket shock absorbs through hull suspension.
            model.rotation_degrees.z=sin(t*PI*3.2)*3.7*pow(1.0-t,1.6)
            hull.rotation_degrees.x=sin(t*PI*2.7)*2.9*(1.0-t)
            model.position.y-=0.085*sin(PI*t)
            turret.position.y=1.11-0.068*sin(PI*t)
        "damaged":
            var jolt: float = sin(PI*t)
            model.rotation_degrees.z=sin(t*PI*2.0)*2.1*(1.0-t)
            gun.rotation_degrees.x=2.0*jolt
            turret.position.y=1.11-0.030*jolt
            if impact!=null:
                impact.visible=t>=0.04 and t<0.89
                impact.scale=Vector3.ONE*(0.85+0.38*_ease(t))
        _:
            pass
    _animate_running_gear(model,_phase(model,kind,t))
    return true

static func restore(model: Node3D) -> void:
    if model==null:
        return
    if not model.get_meta("tarvoka_mbt_tracks_inboard_v31",false):
        LegacyRig.restore(model)
        return
    # Preserve the FINAL V32 model's last track phase; only stop FX.
    pose(model,"idle",0.0)
