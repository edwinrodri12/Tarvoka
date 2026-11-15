extends RefCounted
class_name TarvokaG11VisualRig3D

# Reversible G11 visual animation, independent of turns/HP/ammo.
const Art = preload("res://scripts/ui/G11Art3D.gd")
const FinishV2 = preload("res://scripts/ui/G11FinishV2.gd")
const GeometryV4 = preload("res://scripts/ui/G11GeometryV4.gd")
const MechanicsV5 = preload("res://scripts/ui/G11MechanicsV5.gd")
const AtmosphereV7 = preload("res://scripts/ui/G11DamageAtmosphereV7.gd")
const SalvoV8 = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const ExhaustV9 = preload("res://scripts/ui/G11ExhaustV9.gd")
const REST := "tarvoka_g11_rest_position"
const REST_YAW := "tarvoka_g11_rest_yaw"
const MOVE_DURATION := 0.62
const SHOT_DURATION := 1.05
const IMPACT_DURATION := 0.65
const BASE_PLATFORM := Vector3(0,1.14,0.46)
const BASE_LAUNCHER := Vector3(0,0.39,0.08)

static func has_rig(model: Node3D) -> bool:
    return Art.has_model(model) and model.find_child(
        "G11_RuedaPivot_-1_0",true,false) != null and model.find_child(
        "G11_RuedaPivot_1_5",true,false) != null

static func _node(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func _reset(model: Node3D) -> void:
    model.position = model.get_meta(REST) as Vector3
    model.rotation_degrees = Vector3(0,float(model.get_meta(REST_YAW,0.0)),0)
    var platform := _node(model,Art.TURRET)
    var launcher := _node(model,Art.ELEVATION)
    platform.position = BASE_PLATFORM
    platform.rotation_degrees = Vector3.ZERO
    FinishV2.pose_tracks(model,0.0)
    launcher.position = BASE_LAUNCHER
    launcher.rotation_degrees = Vector3(20,0,0)
    GeometryV4.update_actuators(model)
    for side in [-1,1]:
        for axle in range(6):
            var wheel := _node(model,"G11_RuedaPivot_%d_%d" % [side,axle])
            if wheel != null:
                wheel.rotation_degrees = Vector3.ZERO
                wheel.position.y = 0.26
    MechanicsV5.update_running_gear(model,0.0)
    SalvoV8.reset(model)
    ExhaustV9.reset(model)
    for name in ["G11_EfectoFogonazo","G11_EfectoHumoDisparo",
            "G11_EfectoPolvoMarcha","G11_ImpactoBalas",
            "G11_ImpactoExplosivo"]:
        var effect := _node(model,name)
        if effect != null:
            effect.visible = false
            effect.scale = Vector3.ONE

static func heading_yaw(direction: Vector2i) -> float:
    if direction == Vector2i.ZERO:
        return 0.0
    return rad_to_deg(atan2(-float(direction.x),-float(direction.y)))

static func pose(model: Node3D, kind: String, progress: float,
        target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_rig(model):
        return false
    if not model.has_meta(REST):
        model.set_meta(REST,model.position)
        model.set_meta(REST_YAW,model.rotation_degrees.y)
    _reset(model)
    var t: float = clampf(progress,0.0,1.0)
    var platform := _node(model,Art.TURRET)
    var launcher := _node(model,Art.ELEVATION)
    var destroyed: bool = Art.stage(model) >= 4
    match kind:
        "move":
            if destroyed:
                return true
            var phase: float = t * TAU * 2.0
            for side in [-1,1]:
                for axle in range(6):
                    var wheel := _node(model,"G11_RuedaPivot_%d_%d" % [side,axle])
                    if wheel != null:
                        wheel.rotation_degrees.x = 720.0*t
                        wheel.position.y = 0.26+0.015*sin(phase+float(axle))
            model.position.y -= absf(sin(phase))*0.018
            model.rotation_degrees.z = sin(phase)*0.34
            # Both tread belts scroll physically around the idlers.
            FinishV2.pose_tracks(model,t)
            MechanicsV5.update_running_gear(model,t)
            _node(model,"G11_EfectoPolvoMarcha").visible = t > 0.02 and t < 0.95
        "attack", "fire":
            if destroyed:
                return true
            var aim: float = clampf(t/0.24,0.0,1.0)
            aim = aim*aim*(3.0-2.0*aim)
            platform.rotation_degrees.y = wrapf(
                heading_yaw(target_heading)-model.rotation_degrees.y,
                -180.0,180.0)*aim
            launcher.rotation_degrees.x = 20.0+18.0*aim
            var recoil: float = maxf(0.0,sin(
                clampf((t-0.28)/0.30,0,1)*PI))
            launcher.position.z = BASE_LAUNCHER.z+0.13*recoil
            platform.position.y = BASE_PLATFORM.y-0.025*recoil
            _node(model,"G11_EfectoFogonazo").visible = t >= 0.28 and t < 0.44
            var haze := _node(model,"G11_EfectoHumoDisparo")
            haze.visible = t >= 0.37 and t < 0.91
            haze.scale = Vector3.ONE*(0.70+0.45*t)
            GeometryV4.update_actuators(model)
            SalvoV8.pose(model,t)
            ExhaustV9.pose(model,t)
        "bullet", "hit_bullet":
            var impact := _node(model,"G11_ImpactoBalas")
            impact.visible = t < 0.42
            model.rotation_degrees.z = sin(t*PI)*0.45
        "explosive", "hit_explosive", "damaged":
            var blast := _node(model,"G11_ImpactoExplosivo")
            blast.visible = t < 0.80
            blast.scale = Vector3.ONE*(0.80+0.23*t)
            model.rotation_degrees.z = sin(t*PI)*2.4
            model.position.y += sin(t*PI)*0.045
        "idle":
            pass
        _:
            return false
    AtmosphereV7.animate(model,kind,t)
    return true

static func restore(model: Node3D) -> void:
    if has_rig(model):
        pose(model,"idle",1.0)
