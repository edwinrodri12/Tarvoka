extends "res://scripts/ui/AirbaseDamageFXV3.gd"
class_name TarvokaAirbaseDamageFXV4

# V4 preserves all V3 source positions, damage stages and mobile draw budgets.
# Replaces the solid-looking volume and cone shading with original soft
# cloud/fire shaders without adding new MeshInstance3D, particles or lights.
const SOFT_SMOKE: Shader = preload("res://assets/shaders/airbase_soft_smoke_v4.gdshader")
const SOFT_FIRE: Shader = preload("res://assets/shaders/airbase_soft_flame_v4.gdshader")

static func build(stage: int) -> TarvokaAirbaseDamageFXV4:
    var rig := TarvokaAirbaseDamageFXV4.new()
    rig.name = STAGE_NAME
    rig.damage_stage = clampi(stage,0,4)
    rig.set_meta("tarvoka_visual_only",true)
    rig.set_meta("tarvoka_airbase_v4_soft_vfx",true)
    return rig

func _ready() -> void:
    super._ready()
    if _smoke != null:
        var cloud := ShaderMaterial.new()
        cloud.shader = SOFT_SMOKE
        cloud.set_shader_parameter("smoke_tint",
            Color(0.34,0.38,0.41,0.47) if damage_stage == 2
            else Color(0.22,0.25,0.28,0.56))
        cloud.set_shader_parameter("drift_speed",0.15)
        cloud.set_shader_parameter("edge_breakup",1.17)
        _smoke.material_override = cloud
        _smoke.name = "HumoSuaveV4_UnLote"
        _smoke.set_meta("tarvoka_v4_soft_contour",true)
    if _fire != null:
        var flame := ShaderMaterial.new()
        flame.shader = SOFT_FIRE
        flame.set_shader_parameter("flame_tint",Color(1,0.48,0.10,0.85))
        flame.set_shader_parameter("flicker_speed",7.6)
        _fire.material_override = flame
        _fire.name = "FuegoSuaveV4_UnLote"
        _fire.set_meta("tarvoka_v4_soft_flame",true)
    set_meta("tarvoka_airbase_v4_soft_ready",true)

func draw_batch_budget() -> int:
    return (1 if _smoke != null else 0)+(1 if _fire != null else 0)

func is_soft_version() -> bool:
    return bool(get_meta("tarvoka_airbase_v4_soft_ready",false))
