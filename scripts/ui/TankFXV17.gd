extends RefCounted
class_name TarvokaTankFXV17

# G09 V17 — smoke/fire art pass with a low-end Android profile.
# One deterministic procedural smoke atlas is shared by ALL tanks and all
# damage stages. There are no particle systems, extra lights, or frame-time
# texture uploads. This works with Godot 4.3 WebGL and GLES3/Android.
const ROOT := "G09V17HumoEstratificado"
const SMOKE_LABELS := [
    "HumoGrisMotor","VahoMotor","HumoNegroCritico",
    "HumoElevado","ColumnaHumo","HumoSuperior"
]
const STAGE_LABELS := [2,2,3,3,4,4]
const SMOKE_ECO := [0,2,4]
const FIRE_ECO := [0,1,3]
const FIRE_COUNT := 5
const SMOKE_COUNT := 6
const TEXTURE_W := 96
const TEXTURE_H := 128
static var _atlas: ImageTexture

static func _smoke_atlas() -> ImageTexture:
    if _atlas != null:
        return _atlas
    var pixels := Image.create(TEXTURE_W,TEXTURE_H,false,Image.FORMAT_RGBA8)
    # The upper irregular scallops, several superposed lobes and soft
    # internal density make this look like flowing smoke instead of
    # the old, circular billboard discs.
    for y in range(TEXTURE_H):
        var v: float = (float(y)+0.5)/float(TEXTURE_H)
        var center: float = 0.054*sin(v*9.0+0.4)+0.025*sin(v*18.5+0.9)
        var width: float = 0.28+0.075*sin(v*11.8)+0.036*cos(v*23.0)
        for x in range(TEXTURE_W):
            var u: float = (float(x)+0.5)/float(TEXTURE_W)-0.5
            var t: float = absf(u-center)/maxf(width,0.10)
            var edge: float = 1.0-smoothstep(0.69,1.04,t)
            var band: float = 0.84+0.12*sin(u*39.0+v*35.0)*cos(u*23.0-v*41.0)
            var lobes: float = 0.90+0.10*cos(u*17.0+v*19.0)
            var y_fade: float = smoothstep(0.0,0.13,v)*(1.0-smoothstep(0.78,1.0,v))
            var opacity: float = clampf(edge*band*lobes*y_fade*0.79,0.0,0.85)
            var shade: float = 0.78+0.12*sin(v*13.0+u*7.0)
            pixels.set_pixel(x,y,Color(shade,shade,shade,opacity))
    _atlas = ImageTexture.create_from_image(pixels)
    return _atlas

static func _copy_smoke(model: Node3D, index: int) -> bool:
    var original: MeshInstance3D = model.find_child(
        SMOKE_LABELS[index],true,false) as MeshInstance3D
    if original == null or not (original.mesh is QuadMesh):
        return false
    var parent: Node3D = original.get_parent() as Node3D
    if parent == null:
        return false
    var source_quad: QuadMesh = original.mesh as QuadMesh
    var cloud := MeshInstance3D.new()
    cloud.name = "G09V17Humo_%02d" % index
    var mesh := QuadMesh.new()
    var scale_factor: float = 1.12 if index % 2 == 0 else 1.20
    mesh.size = source_quad.size*scale_factor
    cloud.mesh = mesh
    cloud.position = original.position+Vector3(
        (float(index%3)-1.0)*0.06,0.04*float(index%2),0.0)
    var material := StandardMaterial3D.new()
    material.albedo_texture = _smoke_atlas()
    if index == 0:
        material.albedo_color = Color(0.40,0.43,0.45,0.54)
    elif index == 1:
        material.albedo_color = Color(0.54,0.57,0.59,0.34)
    elif index == 2 or index == 4:
        material.albedo_color = Color(0.19,0.21,0.24,0.72)
    else:
        material.albedo_color = Color(0.29,0.32,0.34,0.51)
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    material.emission_enabled = false
    cloud.material_override = material
    cloud.set_meta("tarvoka_fx_v17_home",cloud.position)
    parent.add_child(cloud)
    original.visible = false
    return true

static func _tune_fire(model: Node3D) -> int:
    var adjusted: int = 0
    for i in range(FIRE_COUNT):
        var flame: MeshInstance3D = model.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        if flame == null:
            continue
        var previous: StandardMaterial3D = flame.material_override as StandardMaterial3D
        if previous == null:
            continue
        var material: StandardMaterial3D = previous.duplicate(true) as StandardMaterial3D
        # Amber core, warm outer edges, no nuclear-white emissions. Values
        # are stable during animation (no material churn every frame).
        material.albedo_color = Color(1.0,0.87+0.02*float(i%2),0.77,0.85)
        material.emission = Color(0.91,0.29+0.036*float(i%3),0.045)
        material.emission_energy_multiplier = 0.11+0.012*float(i%3)
        flame.material_override = material
        adjusted+=1
    return adjusted

static func set_quality(model: Node3D, eco: bool) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_fx_v17",false):
        return false
    # Exactly 11 transparent cards in normal mode, 6 in eco mode. The
    # same arrays are reused, no instantiation/deletion during gameplay.
    for i in range(SMOKE_COUNT):
        var smoke: MeshInstance3D = model.find_child(
            "G09V17Humo_%02d" % i,true,false) as MeshInstance3D
        if smoke != null:
            smoke.visible = not eco or i in SMOKE_ECO
    for i in range(FIRE_COUNT):
        var fire: MeshInstance3D = model.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        if fire != null:
            fire.visible = not eco or i in FIRE_ECO
    model.set_meta("tarvoka_mbt_fx_v17_eco",eco)
    return true

static func count_transparent_cards(model: Node3D) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_fx_v17",false):
        return 0
    var count: int = 0
    for i in range(SMOKE_COUNT):
        var smoke: Node3D = model.find_child(
            "G09V17Humo_%02d" % i,true,false) as Node3D
        if smoke != null and smoke.visible:
            count+=1
    for i in range(FIRE_COUNT):
        var fire: Node3D = model.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as Node3D
        if fire != null and fire.visible:
            count+=1
    return count

static func animate_effects(model: Node3D,elapsed: float) -> void:
    if model == null or not model.get_meta("tarvoka_mbt_fx_v17",false):
        return
    # Animate only active layers. No GPU/CPU particle allocation.
    var stage: int = int(model.get_meta("tarvoka_visual_damage_stage",0))
    for i in range(SMOKE_COUNT):
        if stage < STAGE_LABELS[i]:
            continue
        var smoke: Node3D = model.find_child(
            "G09V17Humo_%02d" % i,true,false) as Node3D
        if smoke == null or not smoke.visible:
            continue
        var home: Vector3 = smoke.get_meta("tarvoka_fx_v17_home",smoke.position)
        var phase: float = elapsed*(0.86+0.12*float(i%3))+float(i)*1.53
        smoke.position = home+Vector3(
            0.073*sin(phase*0.63),
            0.083*sin(phase*0.88+0.7),
            0.026*cos(phase*0.55))
        smoke.scale = Vector3(
            1.0+0.07*sin(phase*0.62),
            1.0+0.06*sin(phase*0.52+1.2),1.0)
    if stage != 4:
        return
    for i in range(FIRE_COUNT):
        var flame: MeshInstance3D = model.find_child(
            "G09V16FuegoLamina_%02d" % i,true,false) as MeshInstance3D
        if flame == null or not flame.visible:
            continue
        var origin: Vector3 = flame.get_meta("tarvoka_v16_fire_rest",flame.position)
        var phase: float = elapsed*(2.2+0.19*float(i%2))+float(i)*1.47
        flame.position = origin+Vector3(
            0.031*sin(phase),0.036*sin(phase*1.23),0.015*cos(phase*0.7))
        flame.scale = Vector3(
            0.97+0.07*sin(phase*0.84),
            0.96+0.10*sin(phase*1.41),1.0)

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_finish_v16",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    for label in SMOKE_LABELS:
        if model.find_child(label,true,false) == null:
            return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    var smoke_count: int = 0
    for i in range(SMOKE_COUNT):
        if _copy_smoke(model,i):
            smoke_count+=1
    var fire_count: int = _tune_fire(model)
    model.set_meta("tarvoka_mbt_fx_v17",true)
    model.set_meta("tarvoka_mbt_fx_v17_smoke_count",smoke_count)
    model.set_meta("tarvoka_mbt_fx_v17_fire_count",fire_count)
    set_quality(model,false)
    return smoke_count == SMOKE_COUNT and fire_count == FIRE_COUNT
