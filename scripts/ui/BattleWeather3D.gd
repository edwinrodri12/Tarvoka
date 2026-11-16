extends Node3D
class_name TarvokaBattleWeather3D

# Native 3D precipitation. Visual-only camera-local mesh batching:
# no changes to terrain, movement, line of sight, or match saves.
const Weather = preload("res://scripts/core/Weather.gd")
const FIELD_RADIUS := 18.0
const CEILING := 7.2
const MIN_HEIGHT := 0.7
const FRAME_INTERVAL := 1.0 / 18.0
var _drops: MultiMesh = null
var _positions: Array[Vector3] = []
var _speed: float = 0.0
var _wind: float = 0.0
var _accum: float = 0.0

func configure(mode: String) -> bool:
    if mode not in [Weather.RAIN,Weather.SNOW]:
        set_process(false)
        return false
    var raining: bool = mode == Weather.RAIN
    var shape: Mesh
    var shade: Color
    if raining:
        var streak := CylinderMesh.new()
        streak.top_radius = 0.011
        streak.bottom_radius = 0.011
        streak.height = 0.48
        streak.radial_segments = 4
        shape = streak
        shade = Color(0.74,0.85,0.98,0.64)
    else:
        var flake := SphereMesh.new()
        flake.radius = 0.052
        flake.height = 0.104
        flake.radial_segments = 6
        flake.rings = 3
        shape = flake
        shade = Color(0.94,0.98,1.0,0.90)
    var material := StandardMaterial3D.new()
    material.albedo_color = shade
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    shape.material = material
    var mesh_batch := MultiMesh.new()
    mesh_batch.transform_format = MultiMesh.TRANSFORM_3D
    mesh_batch.mesh = shape
    var count: int = 520 if raining else 390
    mesh_batch.instance_count = count
    _positions.clear()
    for i in range(count):
        var px: float = (float(posmod(i*127,997))/997.0*2.0-1.0)*FIELD_RADIUS
        var pz: float = (float(posmod(i*389+137,991))/991.0*2.0-1.0)*FIELD_RADIUS
        var py: float = MIN_HEIGHT+float(posmod(i*271+83,983))/983.0*(CEILING-MIN_HEIGHT)
        var location := Vector3(px,py,pz)
        _positions.append(location)
        mesh_batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,location))
    var cloud := MultiMeshInstance3D.new()
    cloud.name = "Precipitacion3DNativa"
    cloud.multimesh = mesh_batch
    cloud.rotation_degrees.z = -10.0 if raining else 0.0
    add_child(cloud)
    _drops = mesh_batch
    _speed = 8.2 if raining else 1.20
    _wind = -0.45 if raining else 0.19
    set_meta("tarvoka_visual_weather",mode)
    set_meta("tarvoka_weather_visual_only",true)
    set_process(true)
    return true

func _process(delta: float) -> void:
    if _drops == null:
        return
    _accum += minf(delta,0.12)
    if _accum < FRAME_INTERVAL:
        return
    var step: float = minf(_accum,0.15)
    _accum = 0.0
    for i in range(_positions.size()):
        var at: Vector3 = _positions[i]
        at.y -= step*_speed
        at.x += step*_wind
        if at.y < MIN_HEIGHT:
            at.y += CEILING-MIN_HEIGHT
        if at.x < -FIELD_RADIUS:
            at.x += 2.0*FIELD_RADIUS
        elif at.x > FIELD_RADIUS:
            at.x -= 2.0*FIELD_RADIUS
        _positions[i] = at
        _drops.set_instance_transform(i,Transform3D(Basis.IDENTITY,at))
