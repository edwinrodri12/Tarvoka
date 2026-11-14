extends Node3D
class_name TarvokaHeadquartersSmokeV23

# Studio / close camera only: soft, animated pseudo-volumes.
# Three layered ellipsoids per source are submitted in ONE MultiMesh draw.
# Uses mobile-compatible 3D noise shader, no GPUParticles or OmniLights.
const STAGE_NAME := "HumoVolumetricoComercialHQV23"
const SHADER: Shader = preload("res://assets/shaders/hq_volumetric_smoke_v23.gdshader")
const LAYERS := 3

var damage_stage := 0
var _smoke_batch: MultiMeshInstance3D
var _sources := 0
var _seconds := 0.0
var _distant := false
var _mobile_quality := false
var _active := false

static func build(stage: int) -> TarvokaHeadquartersSmokeV23:
    var node := TarvokaHeadquartersSmokeV23.new()
    node.name = STAGE_NAME
    node.damage_stage = clampi(stage,0,4)
    node.set_meta("tarvoka_visual_only",true)
    node.set_meta("tarvoka_hq_v23_smoke_stage",stage)
    return node

func _ready() -> void:
    if damage_stage not in [2,3]:
        set_process(false)
        visible = false
        return
    _active = true
    _sources = 3 if damage_stage == 2 else 5
    var sphere := SphereMesh.new()
    sphere.radius = 0.5
    sphere.height = 1.0
    sphere.radial_segments = 10
    sphere.rings = 6
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_custom_data = true
    mm.mesh = sphere
    mm.instance_count = _sources*LAYERS
    for i in range(mm.instance_count):
        mm.set_instance_transform(i,Transform3D(
            Basis().scaled(Vector3(0.001,0.001,0.001)),Vector3.ZERO))
        mm.set_instance_custom_data(i,Color(
            fposmod(float(i)*0.173,1.0),0.0,0.0,0.0))
    _smoke_batch = MultiMeshInstance3D.new()
    _smoke_batch.name = "VolutasHumoEnUnLoteV23"
    _smoke_batch.multimesh = mm
    _smoke_batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var material := ShaderMaterial.new()
    material.shader = SHADER
    material.set_shader_parameter("smoke_tint",
        Color(0.35,0.39,0.42,0.45) if damage_stage == 2
        else Color(0.23,0.27,0.30,0.54))
    material.set_shader_parameter("drift_speed",0.11)
    material.set_shader_parameter("turbulence",1.0)
    _smoke_batch.material_override = material
    add_child(_smoke_batch)
    set_process(true)
    advance(0.03)

func advance(delta: float) -> void:
    if not _active or _distant:
        return
    _seconds += maxf(0.0,delta)
    for plume in range(_sources):
        var left: bool = damage_stage == 3 and plume < 3
        var base := Vector3(-4.18,2.26,-3.25) if left else Vector3(4.04,2.43,-3.25)
        for shell in range(LAYERS):
            var i: int = shell*_sources+plume
            var phase: float = fposmod(_seconds*(0.19+float(plume%3)*0.036)
                +float(plume)*0.229+float(shell)*0.173,1.0)
            var drift := Vector3(
                sin(_seconds*(0.55+float(plume)*0.07)+float(shell)*2.13)*0.25,
                0.28+phase*(2.22 if damage_stage==3 else 1.62),
                cos(_seconds*0.37+float(plume)*1.3+float(shell))*0.20)
            var center := base + drift + Vector3(
                float(shell-1)*0.28,float(shell)*0.44,-float(shell)*0.19)
            var diameter: float = 0.65+phase*1.14+float(shell)*0.15
            var basis := Basis(Vector3.UP,
                0.13*sin(_seconds*0.45+float(plume)+float(shell)*0.8))
            basis = basis.scaled(Vector3(diameter,diameter*1.28,diameter*0.91))
            _smoke_batch.multimesh.set_instance_transform(i,
                Transform3D(basis,center))
            _smoke_batch.multimesh.set_instance_custom_data(i,
                Color(fposmod(float(i)*0.173,1.0),phase,0.0,0.0))

func _process(delta: float) -> void:
    if _active and not _distant:
        advance(delta)

func set_distant(distant: bool) -> void:
    _distant = distant
    visible = _active and not distant
    set_process(_active and not distant)

func set_mobile_quality(enabled: bool) -> void:
    _mobile_quality = enabled
    if _smoke_batch != null:
        # Shell-major ordering preserves ALL smoke origins when low-end
        # Android limits the number of shells to two per plume.
        _smoke_batch.multimesh.visible_instance_count = (
            _sources*2 if enabled else _sources*LAYERS)

func is_animating() -> bool:
    return _active and visible and is_processing()

func active_draw_batches() -> int:
    return 1 if is_animating() else 0

func current_instance_count() -> int:
    if _smoke_batch == null:
        return 0
    return (_smoke_batch.multimesh.visible_instance_count
        if _smoke_batch.multimesh.visible_instance_count >= 0
        else _smoke_batch.multimesh.instance_count)

func source_count() -> int:
    return _sources
