extends Node3D
class_name TarvokaHeadquartersImpactV21

# Two real-time, bounded Godot 3D hit reactions on the existing HQ model.
# BULLET: short puncture / sparks; EXPLOSIVE: shock flash, flying masonry,
# lingering smoke. 0 extra OmniLights, no gameplay/HP mutations.
const BULLET := "bullet"
const EXPLOSIVE := "explosive"
const STAGE_NAME := "ImpactosAnimadosHQV21"
const BULLET_DURATION := 0.62
const EXPLOSIVE_DURATION := 1.75
const SPARK_COUNT := 12
const DEBRIS_COUNT := 18

var _sparks: MultiMeshInstance3D
var _debris: MultiMeshInstance3D
var _flash: MeshInstance3D
var _shock: MeshInstance3D
var _smoke: Array[MeshInstance3D] = []
var _elapsed := 0.0
var _duration := 0.0
var _kind := ""
var _running := false
var _hit := Vector3(4.03,2.04,-3.55)
var _rng := RandomNumberGenerator.new()

static func _material(tint: Color,glow: float = 0.0,
        transparent: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = 0.10
    mat.roughness = 0.72
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if glow > 0.0:
        mat.emission_enabled = true
        mat.emission = tint
        mat.emission_energy_multiplier = glow
    if transparent:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
    return mat

static func _batch(name: String,count: int,color: Color,
        glow: float = 0.0) -> MultiMeshInstance3D:
    var node := MultiMeshInstance3D.new()
    node.name = name
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.mesh = box
    mesh.instance_count = count
    for i in range(count):
        mesh.set_instance_transform(i,Transform3D(Basis().scaled(
            Vector3(0.001,0.001,0.001)),Vector3.ZERO))
    node.multimesh = mesh
    node.material_override = _material(color,glow)
    node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    node.visible = false
    return node

func _ready() -> void:
    name = STAGE_NAME
    set_meta("tarvoka_visual_only",true)
    _sparks = _batch("ChispasBalasUnLoteV21",SPARK_COUNT,Color("#ffc871"),2.2)
    _debris = _batch("FragmentosExplosionUnLoteV21",DEBRIS_COUNT,Color("#8a928c"))
    add_child(_sparks)
    add_child(_debris)
    _flash = MeshInstance3D.new()
    _flash.name = "DestelloVolumetricoExplosionHQV21"
    var sphere := SphereMesh.new()
    sphere.radius = 0.65
    sphere.height = 1.30
    sphere.radial_segments = 12
    sphere.rings = 7
    _flash.mesh = sphere
    _flash.material_override = _material(Color("#ffc881"),2.5,true)
    _flash.visible = false
    _flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    add_child(_flash)
    _shock = MeshInstance3D.new()
    _shock.name = "OndaDeChoqueVisibleHQV21"
    var ring := TorusMesh.new()
    ring.inner_radius = 0.80
    ring.outer_radius = 0.94
    ring.rings = 12
    ring.ring_segments = 16
    _shock.mesh = ring
    _shock.material_override = _material(Color(0.96,0.69,0.38,0.64),1.5,true)
    _shock.visible = false
    _shock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    _shock.rotation_degrees = Vector3(84,0,0)
    add_child(_shock)
    for i in range(3):
        var puff := MeshInstance3D.new()
        puff.name = "VolutaHumoExplosionV21_%d" % i
        var orb := SphereMesh.new()
        orb.radius = 0.5
        orb.height = 1.0
        orb.radial_segments = 10
        orb.rings = 5
        puff.mesh = orb
        puff.material_override = _material(Color(0.24,0.25,0.27,0.63),0.0,true)
        puff.visible = false
        puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(puff)
        _smoke.append(puff)
    set_process(false)

func trigger(kind: String,hit: Vector3 = Vector3(4.03,2.04,-3.55)) -> bool:
    if kind not in [BULLET,EXPLOSIVE]:
        return false
    _kind = kind
    _hit = hit
    _elapsed = 0.0
    _duration = BULLET_DURATION if kind == BULLET else EXPLOSIVE_DURATION
    _running = true
    # Fixed procedural seed for reproducible screenshots and Android profiling.
    _rng.seed = 120713 if kind == BULLET else 120714
    _sparks.visible = kind == BULLET
    _debris.visible = kind == EXPLOSIVE
    _flash.visible = kind == EXPLOSIVE
    _shock.visible = kind == EXPLOSIVE
    for puff in _smoke:
        puff.visible = kind == EXPLOSIVE
    set_process(true)
    _animate(0.001)
    return true

func stop() -> void:
    _running = false
    _kind = ""
    set_process(false)
    if _sparks != null:
        _sparks.visible = false
    if _debris != null:
        _debris.visible = false
    if _flash != null:
        _flash.visible = false
    if _shock != null:
        _shock.visible = false
    for puff in _smoke:
        puff.visible = false

func is_running() -> bool:
    return _running

func current_kind() -> String:
    return _kind

func _process(delta: float) -> void:
    if not _running:
        return
    _elapsed += maxf(delta,0.0)
    if _elapsed >= _duration:
        stop()
        return
    _animate(_elapsed)

func _animate(time: float) -> void:
    var progress: float = clampf(time/_duration,0.0,1.0)
    if _kind == BULLET:
        # Shallow, focused spall + quick expanding spark burst.
        for i in range(SPARK_COUNT):
            var direction: float = TAU*float(i)/float(SPARK_COUNT)
            var radius: float = progress*(0.86+float(i%3)*0.16)
            var pos := _hit+Vector3(
                cos(direction)*radius,
                sin(direction)*radius*0.75-progress*progress*0.15,
                -0.12-progress*0.39)
            var fade: float = maxf(0.014,1.0-progress)
            var scale := Vector3(0.076*fade,0.056+0.16*fade,0.044*fade)
            _sparks.multimesh.set_instance_transform(i,
                Transform3D(Basis().scaled(scale),pos))
    elif _kind == EXPLOSIVE:
        # One impulse produces a fast pressure wave followed by heavy,
        # gravity-led debris and several rising smoke volumes.
        var flash: float = clampf(1.0-time/0.28,0.0,1.0)
        _flash.visible = flash > 0.02
        _flash.position = _hit+Vector3(0.0,0.06,-0.45)
        _flash.scale = Vector3.ONE*(0.38+2.25*sqrt(maxf(0.0,1.0-flash)))
        _flash.transparency = 1.0-flash
        var wave: float = clampf(time/0.47,0.0,1.0)
        _shock.visible = wave < 0.99
        _shock.position = _hit+Vector3(0,0,-0.33)
        _shock.scale = Vector3.ONE*(0.24+3.15*wave)
        _shock.transparency = wave
        for i in range(DEBRIS_COUNT):
            var dir: float = TAU*float(i)/float(DEBRIS_COUNT)
            var speed: float = 1.4+float(i%5)*0.27
            var travel: float = minf(time,1.35)
            var pos := _hit+Vector3(
                cos(dir)*speed*travel,
                sin(dir)*speed*travel*0.52+0.45*travel-2.3*travel*travel,
                -0.28-0.5*travel)
            var scale := Vector3(
                0.13+float(i%3)*0.052,
                0.09+float(i%4)*0.048,
                0.10+float(i%2)*0.07)*maxf(0.015,1.0-progress*0.72)
            var rotation := Basis(Vector3.UP,time*(1.0+float(i%5)))
            _debris.multimesh.set_instance_transform(i,
                Transform3D(rotation.scaled(scale),pos))
        for i in range(_smoke.size()):
            var puff: MeshInstance3D = _smoke[i]
            var offset: float = float(i)*0.29
            puff.position = _hit+Vector3((-1.0+float(i))*0.35,
                0.28+time*(0.97+offset),
                -0.42-float(i%2)*0.27)
            puff.scale = Vector3.ONE*(0.22+time*(0.99+float(i)*0.23))
            puff.transparency = clampf(0.23+progress*0.78,0.0,1.0)
            puff.visible = progress < 0.97

func active_mesh_batches() -> int:
    if not _running:
        return 0
    if _kind == BULLET:
        return 1
    # 1 debris MultiMesh, 1 flash, 1 ring and 3 smoke spheres.
    return 6
