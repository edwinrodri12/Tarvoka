extends Node3D
class_name TarvokaHeadquartersFireV22

# Permanent, reversible, GPU-budgeted V22 damage ambiance. A moderate HQ
# smolders; a critical HQ burns. Not a combat/HP/temperature simulation.
# All nodes are built once and animated in local HQ coordinates.
const STAGE_NAME := "HumoYFuegoProgresivosHQV22"
const MAX_FLAMES := 10
const MAX_SMOKE := 5
const DARK_SMOKE := Color(0.14,0.16,0.18,0.79)
const MODERATE_SMOKE := Color(0.21,0.25,0.27,0.73)
const FLAME_COLORS := [
    Color("#ff952e"), Color("#ffca43"), Color("#ee5424"), Color("#ffb937")]

var damage_stage: int = 0
var _fire: MultiMeshInstance3D
var _smoke: Array[MeshInstance3D] = []
var _time := 0.0
var _animated := false
var _distant := false
var _smoke_replaced := false

static func build(stage: int) -> TarvokaHeadquartersFireV22:
    var node := TarvokaHeadquartersFireV22.new()
    node.name = STAGE_NAME
    node.damage_stage = clampi(stage,0,4)
    node.set_meta("tarvoka_visual_only",true)
    node.set_meta("tarvoka_hq_v22_fire_stage",stage)
    return node

func _ready() -> void:
    if damage_stage < 2 or damage_stage > 3:
        set_process(false)
        visible = false
        return
    _animated = true
    var material := StandardMaterial3D.new()
    material.albedo_color = MODERATE_SMOKE if damage_stage == 2 else DARK_SMOKE
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
    var count: int = 3 if damage_stage == 2 else MAX_SMOKE
    for i in range(count):
        var puff := MeshInstance3D.new()
        puff.name = "HumoAnimadoV22_%d" % i
        var shape := SphereMesh.new()
        shape.radius = 0.52
        shape.height = 1.04
        shape.radial_segments = 9
        shape.rings = 5
        puff.mesh = shape
        puff.material_override = material.duplicate()
        puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(puff)
        _smoke.append(puff)
    if damage_stage == 3:
        # 10 flames, one shared geometry/one draw batch, no individual lights.
        var cone := CylinderMesh.new()
        cone.top_radius = 0.03
        cone.bottom_radius = 0.30
        cone.height = 1.0
        cone.radial_segments = 7
        var instances := MultiMesh.new()
        instances.transform_format = MultiMesh.TRANSFORM_3D
        instances.use_colors = true
        instances.mesh = cone
        instances.instance_count = MAX_FLAMES
        for i in range(MAX_FLAMES):
            instances.set_instance_transform(i,Transform3D(
                Basis().scaled(Vector3(0.01,0.01,0.01)),Vector3.ZERO))
            instances.set_instance_color(i,FLAME_COLORS[i%FLAME_COLORS.size()])
        var orange := StandardMaterial3D.new()
        orange.albedo_color = Color(1,1,1,0.92)
        orange.vertex_color_use_as_albedo = true
        orange.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        orange.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        orange.emission_enabled = true
        orange.emission = Color("#ff7c28")
        orange.emission_energy_multiplier = 1.65
        orange.cull_mode = BaseMaterial3D.CULL_DISABLED
        _fire = MultiMeshInstance3D.new()
        _fire.name = "LlamasCriticasUnSoloLoteV22"
        _fire.multimesh = instances
        _fire.material_override = orange
        _fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(_fire)
    set_process(true)
    advance(0.001)

func _process(delta: float) -> void:
    if not _animated or _distant:
        return
    advance(delta)

func advance(delta: float) -> void:
    if not _animated or _distant:
        return
    _time += maxf(0.0,delta)
    if not _smoke_replaced:
        for i in range(_smoke.size()):
            var puff: MeshInstance3D = _smoke[i]
            var phase: float = fposmod(_time*0.35+float(i)*0.23,1.0)
            var left: bool = damage_stage == 3 and i < 3
            var origin := Vector3(-4.35,2.18,-3.27) if left else Vector3(3.91,2.54,-3.25)
            var drift := Vector3(sin(_time*0.72+float(i))*0.32,
                phase*2.15,cos(_time*0.46+float(i)*1.5)*0.19)
            puff.position = origin+drift+Vector3(float(i%3)*0.20,0,0)
            puff.scale = Vector3.ONE*(0.61+phase*(1.52 if damage_stage==3 else 1.18))
            puff.transparency = clampf(0.08+phase*0.70,0.0,0.97)
    if _fire != null:
        for i in range(MAX_FLAMES):
            var is_left: bool = i < 8
            var center := Vector3(-4.20,1.62,-3.22) if is_left else Vector3(3.88,2.30,-3.16)
            var angle: float = TAU*float(i%8)/8.0
            var scale_y: float = (1.00+0.35*sin(_time*7.0+float(i)*1.73))
            var size_xz: float = 0.35+float(i%3)*0.095
            var pos := center+Vector3(cos(angle)*0.38,
                0.54*scale_y,
                sin(angle)*0.34)
            var basis := Basis(Vector3.UP,0.11*sin(_time*3.2+float(i)))
            basis = basis.scaled(Vector3(size_xz,1.65*scale_y,size_xz))
            _fire.multimesh.set_instance_transform(i,Transform3D(basis,pos))

func set_smoke_replaced(replaced: bool) -> void:
    # Keep the existing V22 flame batch; V23 provides all smoke.
    _smoke_replaced = replaced
    for puff in _smoke:
        puff.visible = not replaced

func set_distant(distant: bool) -> void:
    _distant = distant
    visible = not distant and _animated
    set_process(_animated and not distant)

func is_animating() -> bool:
    return _animated and not _distant and is_processing()

func flame_batches() -> int:
    return 1 if _fire != null and visible and is_processing() else 0

func smoke_count() -> int:
    return _smoke.size()
