extends Node3D
class_name TarvokaAirbaseDamageFXV3

# V3 native Godot ambient damage VFX, never modifies battle HP.
# Soft pseudo-volumetric smoke shares HQ V23 shader, 1 smoke draw batch.
# Critical fire is 1 additional MultiMesh draw batch; no per-instance lights.
const STAGE_NAME := "HumoFuegoProgresivoBaseAereaV3"
const SHADER: Shader = preload("res://assets/shaders/hq_volumetric_smoke_v23.gdshader")
const LAYERS := 3
const FIRE_INSTANCES := 9
const PALETTE := [Color("#ffb13d"),Color("#ff7926"),Color("#ffcf62")]

var damage_stage := 0
var _sources := 0
var _time := 0.0
var _distant := false
var _mobile := false
var _active := false
var _smoke: MultiMeshInstance3D
var _fire: MultiMeshInstance3D

static func build(stage: int) -> TarvokaAirbaseDamageFXV3:
    var node := TarvokaAirbaseDamageFXV3.new()
    node.name = STAGE_NAME
    node.damage_stage = clampi(stage,0,4)
    node.set_meta("tarvoka_visual_only",true)
    return node

func _ready() -> void:
    _active = damage_stage in [2,3]
    if not _active:
        visible = false
        set_process(false)
        return
    _sources = 2 if damage_stage==2 else 4
    var sphere := SphereMesh.new()
    sphere.radius = 0.5
    sphere.height = 1.0
    sphere.radial_segments = 9
    sphere.rings = 6
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_custom_data = true
    mm.mesh = sphere
    mm.instance_count = _sources*LAYERS
    for i in range(mm.instance_count):
        mm.set_instance_transform(i,Transform3D(
            Basis().scaled(Vector3(0.001,0.001,0.001)),Vector3.ZERO))
        mm.set_instance_custom_data(i,Color(0,0,0,0))
    _smoke = MultiMeshInstance3D.new()
    _smoke.name = "HumoBaseAereaUnSoloLoteV3"
    _smoke.multimesh = mm
    _smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material := ShaderMaterial.new()
    material.shader = SHADER
    material.set_shader_parameter("smoke_tint",
        Color(0.37,0.41,0.45,0.48) if damage_stage==2
        else Color(0.23,0.25,0.27,0.58))
    material.set_shader_parameter("drift_speed",0.11)
    material.set_shader_parameter("turbulence",0.96)
    _smoke.material_override = material
    add_child(_smoke)

    if damage_stage==3:
        var cone := CylinderMesh.new()
        cone.top_radius = 0.055
        cone.bottom_radius = 0.32
        cone.height = 1.0
        cone.radial_segments = 7
        var flames := MultiMesh.new()
        flames.transform_format = MultiMesh.TRANSFORM_3D
        flames.use_colors = true
        flames.mesh = cone
        flames.instance_count = FIRE_INSTANCES
        for i in range(FIRE_INSTANCES):
            flames.set_instance_transform(i,Transform3D(
                Basis().scaled(Vector3(0.001,0.001,0.001)),Vector3.ZERO))
            flames.set_instance_color(i,PALETTE[i%PALETTE.size()])
        var fire_mat := StandardMaterial3D.new()
        fire_mat.albedo_color = Color(1,1,1,0.90)
        fire_mat.vertex_color_use_as_albedo = true
        fire_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        fire_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        fire_mat.emission_enabled = true
        fire_mat.emission = Color("#ee6c26")
        fire_mat.emission_energy_multiplier = 1.55
        _fire = MultiMeshInstance3D.new()
        _fire.name = "LlamasCriticasHangarUnLoteV3"
        _fire.multimesh = flames
        _fire.material_override = fire_mat
        _fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(_fire)
    set_process(true)
    advance(0.035)

func _origin(index: int) -> Vector3:
    if damage_stage==2:
        return Vector3(-2.32,3.07,-1.26)+Vector3(index*0.38,0,index*0.28)
    if index==0:
        return Vector3(-4.03,2.73,-2.27)
    if index==1:
        return Vector3(-3.32,3.10,-1.48)
    if index==2:
        return Vector3(-2.16,2.80,-0.79)
    return Vector3(4.17,4.27,-2.20)

func _flame_origin(index: int) -> Vector3:
    if index<7:
        return Vector3(-3.33,2.70,-1.40)+Vector3(
            -0.70+float(index%4)*0.45,0.12,-0.38+float(index/4)*0.32)
    return Vector3(4.17,4.13,-2.20)+Vector3(
        float(index-7)*0.22,0,0)

func advance(delta: float) -> void:
    if not _active or _distant or _smoke == null:
        return
    _time += maxf(0.0,delta)
    for shell in range(LAYERS):
        for src in range(_sources):
            var idx: int = shell*_sources+src
            var phase: float = fposmod(
                _time*(0.17+float(src%3)*0.035)
                +float(src)*0.233+float(shell)*0.167,1.0)
            var origin: Vector3 = _origin(src)
            var drift := Vector3(
                sin(_time*0.43+float(src)*1.71+float(shell))*0.23,
                0.29+phase*(1.62 if damage_stage==2 else 2.15),
                cos(_time*0.37+float(src)+float(shell))*0.19)
            var size: float = 0.70+phase*1.29+float(shell)*0.18
            var center := origin+drift+Vector3(
                float(shell-1)*0.16,float(shell)*0.30,-float(shell)*0.12)
            var basis := Basis(Vector3.UP,0.15*sin(_time*0.45+float(idx)))
            basis = basis.scaled(Vector3(size,size*1.30,size*0.95))
            _smoke.multimesh.set_instance_transform(idx,
                Transform3D(basis,center))
            _smoke.multimesh.set_instance_custom_data(idx,
                Color(fposmod(float(idx)*0.173,1.0),phase,0,0))
    if _fire != null:
        for i in range(FIRE_INSTANCES):
            var center: Vector3 = _flame_origin(i)
            var flicker: float = 1.0+0.24*sin(_time*8.1+float(i)*1.41)
            var basis := Basis(Vector3.UP,0.14*sin(_time*3.1+float(i)))
            basis = basis.scaled(Vector3(
                0.32+float(i%3)*0.065,1.46*flicker,
                0.31+float(i%2)*0.07))
            _fire.multimesh.set_instance_transform(i,Transform3D(
                basis,center+Vector3(0,0.61*flicker,0)))

func _process(delta: float) -> void:
    advance(delta)

func set_mobile_quality(low: bool) -> void:
    _mobile = low
    if _smoke != null:
        _smoke.multimesh.visible_instance_count = (
            _sources*2 if low else _sources*LAYERS)

func set_distant(distant: bool) -> void:
    _distant = distant
    visible = _active and not distant
    set_process(_active and not distant)

func is_active() -> bool:
    return _active and not _distant

func smoke_instance_count() -> int:
    if _smoke==null:
        return 0
    return _sources*2 if _mobile else _sources*LAYERS

func flame_batch_count() -> int:
    return 1 if _fire!=null else 0
