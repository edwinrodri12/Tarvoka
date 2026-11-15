extends RefCounted
class_name TarvokaBastionVisualRig3D

# P06 native procedural animation. No edits to turn state, combat balance,
# ammunition, HP or saves. Godot 4.3 compatible. Call pose() from the viewer
# or battlefield presentation with normalized progress 0..1.
const Damage = preload("res://scripts/ui/BastionDamage3D.gd")
const REST_POSITION := "tarvoka_bastion_rest_position"
const REST_YAW := "tarvoka_bastion_rest_yaw"
const HULL := "Bastion_P06_Casco"
const TURRET := "TorretaRemotaP06"
const GUN := "ElevacionArmaP06"
const MOVE_DURATION := 0.55
const ATTACK_DURATION := 0.72
const HIT_BULLET_DURATION := 0.32
const HIT_EXPLOSIVE_DURATION := 0.78
const WHEEL_BASE_Y := 0.355
const GUN_BASE_Z := -0.06
const TURRET_BASE := Vector3(0.17,1.55,0.08)

static func has_rig(model: Node3D) -> bool:
    return model != null and model.find_child(HULL,true,false) is Node3D \
        and model.find_child(TURRET,true,false) is Node3D \
        and model.find_child(GUN,true,false) is Node3D \
        and model.find_child("GiroRuedaP06_-1_0",true,false) is Node3D \
        and model.find_child("GiroRuedaP06_1_2",true,false) is Node3D

static func heading_yaw(direction: Vector2i) -> float:
    if direction == Vector2i.ZERO:
        return 0.0
    # The authored nose points toward -Z, matching the MBT 3D renderer.
    return rad_to_deg(atan2(-float(direction.x),-float(direction.y)))

static func _initialize_rest(model: Node3D) -> void:
    if not model.has_meta(REST_POSITION):
        model.set_meta(REST_POSITION,model.position)
    if not model.has_meta(REST_YAW):
        model.set_meta(REST_YAW,model.rotation_degrees.y)

static func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

static func _reset(model: Node3D) -> void:
    model.position = model.get_meta(REST_POSITION) as Vector3
    model.rotation_degrees.x = 0.0
    model.rotation_degrees.y = float(model.get_meta(REST_YAW,0.0))
    model.rotation_degrees.z = 0.0
    var hull := _find(model,HULL)
    var turret := _find(model,TURRET)
    var gun := _find(model,GUN)
    hull.rotation_degrees = Vector3.ZERO
    turret.position = TURRET_BASE
    turret.rotation_degrees = Vector3.ZERO
    gun.position = Vector3(0.13,0.42,GUN_BASE_Z)
    gun.rotation_degrees = Vector3.ZERO
    for side in [-1,1]:
        for axle in range(3):
            var pivot := _find(model,"DireccionP06_%s_%d" % [side,axle])
            var spinner := _find(model,"GiroRuedaP06_%s_%d" % [side,axle])
            if pivot != null:
                pivot.position.y = WHEEL_BASE_Y
                pivot.rotation_degrees = Vector3.ZERO
            if spinner != null:
                spinner.rotation_degrees = Vector3.ZERO
    for label in ["EfectoFogonazoP06","EfectoHumoDisparoP06","EfectoPolvoRuedasP06",
            "ImpactoP06_Balas","ImpactoP06_Explosivo"]:
        var effect := _find(model,label)
        if effect != null:
            effect.visible = false
            effect.scale = Vector3.ONE

static func pose(model: Node3D, kind: String, progress: float,
        target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_rig(model):
        return false
    _initialize_rest(model)
    _reset(model)
    var t: float = clampf(progress,0.0,1.0)
    var hull: Node3D = _find(model,HULL)
    var turret: Node3D = _find(model,TURRET)
    var gun: Node3D = _find(model,GUN)
    var muzzle: Node3D = _find(model,"EfectoFogonazoP06")
    var smoke: Node3D = _find(model,"EfectoHumoDisparoP06")
    var dust: Node3D = _find(model,"EfectoPolvoRuedasP06")
    var destroyed: bool = Damage.current_stage(model) >= 4
    match kind:
        "move":
            if destroyed:
                return true
            # A full tile advances the tyres by two physical revolutions.
            # Independent left/right phase gives six-wheel suspension travel.
            var phase: float = t * TAU * 2.0
            var steering: float = clampf(-float(target_heading.x),-1.0,1.0)
            for side in [-1,1]:
                for axle in range(3):
                    var pivot: Node3D = _find(model,
                        "DireccionP06_%s_%d" % [side,axle])
                    var spinner: Node3D = _find(model,
                        "GiroRuedaP06_%s_%d" % [side,axle])
                    var oscillation: float = sin(phase+float(axle)*1.42+float(side)*0.27)
                    pivot.position.y = WHEEL_BASE_Y+oscillation*0.025
                    if axle == 0:
                        pivot.rotation_degrees.y = steering * 13.0 * sin(t*PI)
                    elif axle == 2:
                        pivot.rotation_degrees.y = -steering * 5.0 * sin(t*PI)
                    spinner.rotation_degrees.x = 720.0*t
            hull.rotation_degrees.x = sin(phase+0.45)*0.62
            hull.rotation_degrees.z = sin(phase*0.5)*0.48
            model.position.y -= absf(sin(phase))*0.022
            turret.rotation_degrees.z = -hull.rotation_degrees.z*0.30
            if dust != null:
                dust.visible = t > 0.05 and t < 0.94
                dust.scale = Vector3.ONE*(0.75+0.50*t)
        "attack":
            if destroyed:
                return true
            var yaw: float = heading_yaw(target_heading) - model.rotation_degrees.y
            var aim: float = clampf(t/0.30,0.0,1.0)
            aim = aim*aim*(3.0-2.0*aim)
            turret.rotation_degrees.y = wrapf(yaw,-180.0,180.0)*aim
            gun.rotation_degrees.x = aim*5.0
            # Chamber recoil: rapid backward travel and damped return,
            # completely independent of hull motion or terrain movement.
            var fire_window: float = clampf((t-0.27)/0.23,0.0,1.0)
            gun.position.z = GUN_BASE_Z+0.125*sin(fire_window*PI)
            turret.position.y = TURRET_BASE.y-0.009*sin(fire_window*PI)
            if muzzle != null:
                muzzle.visible = t >= 0.27 and t < 0.43
                muzzle.scale = Vector3.ONE*(1.18-0.62*fire_window)
            if smoke != null:
                smoke.visible = t >= 0.35 and t < 0.88
                smoke.scale = Vector3.ONE*(0.55+0.68*t)
        "bullet", "hit_bullet":
            Damage.pose_impact(model,"bullet",t)
        "explosive", "hit_explosive", "damaged":
            Damage.pose_impact(model,"explosive",t)
        "idle":
            pass
        _:
            return false
    return true

static func restore(model: Node3D) -> void:
    if has_rig(model):
        pose(model,"idle",1.0)
