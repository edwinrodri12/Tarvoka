extends Node
class_name TarvokaG11BattleLODControllerV25

# Dynamic visual-only camera LOD on the REAL BattleTerrain3D scene.
# The G11 retains one logical unit, one original body, two original tracks.
# Sampling at 4Hz mirrors the existing P06 controller, avoids visual churn
# through hysteresis, and NEVER touches game state / fog / attack properties.
const Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const IdentityV28 = preload("res://scripts/ui/G11CameraIdentityV28.gd")
const INTERVAL: float=0.25
const NEAR_ON_PIXELS: float=86.0
const FAR_OFF_PIXELS: float=64.0
const VISIBLE_MODEL_HEIGHT: float=2.05
var units: Array[Node3D]=[]
var _elapsed: float=0.0

func register(model: Node3D) -> void:
    if model!=null and bool(model.get_meta(Tactical.FLAG,false)) and (
            not units.has(model)):
        units.append(model)
        IdentityV28.bind(model,Tactical.active_level(model))

func pixel_height(model: Node3D,camera: Camera3D,
        viewport_height: float) -> float:
    if model==null or camera==null or viewport_height<=1.0:
        return 0.0
    var height: float=VISIBLE_MODEL_HEIGHT*model.global_transform.basis.y.length()
    if camera.projection==Camera3D.PROJECTION_ORTHOGONAL:
        return height*viewport_height/maxf(0.05,camera.size)
    var relative: Vector3=camera.to_local(model.global_position)
    var depth: float=maxf(0.05,-relative.z)
    var fov: float=deg_to_rad(camera.fov)
    return height*viewport_height/(
        2.0*depth*maxf(0.05,tan(fov*0.5)))

func preferred_level(pixels: float,current: int) -> int:
    # A near object must shrink below FAR_OFF before reverting. Likewise
    # a far object must exceed NEAR_ON before adding the wheel batch.
    if current==Tactical.LOD_NEAR:
        return Tactical.LOD_FAR if pixels<=FAR_OFF_PIXELS else Tactical.LOD_NEAR
    return Tactical.LOD_NEAR if pixels>=NEAR_ON_PIXELS else Tactical.LOD_FAR

func update_now(camera: Camera3D,viewport_height: float) -> int:
    if camera==null or viewport_height<=1.0:
        return 0
    var changed: int=0
    for model in units:
        if not is_instance_valid(model) or (
                not bool(model.get_meta(Tactical.FLAG,false))):
            continue
        var current: int=Tactical.active_level(model)
        var needed: int=preferred_level(
            pixel_height(model,camera,viewport_height),current)
        if needed!=current:
            if Tactical.set_level(model,needed):
                changed+=1
                IdentityV28.set_detail(model,needed)
        else:
            IdentityV28.set_detail(model,current)
    return changed

func _process(delta: float) -> void:
    _elapsed+=maxf(0.0,delta)
    if _elapsed<INTERVAL:
        return
    _elapsed=fmod(_elapsed,INTERVAL)
    var camera: Camera3D=get_viewport().get_camera_3d()
    if camera==null:
        return
    update_now(camera,float(get_viewport().get_visible_rect().size.y))
