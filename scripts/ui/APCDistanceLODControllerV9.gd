extends Node
class_name TarvokaAPCDistanceLODControllerV9

# Runtime pixel-height LOD for a 3D battle: no image-based impostors.
# Runs at 4 Hz, not every frame, and never mutates combat state or fog.
const Tactical = preload("res://scripts/ui/APCTacticalLOD8.gd")
const INTERVAL := 0.25
var units: Array[Node3D]=[]
var _elapsed: float=0.0
var _last_camera_id: int=0
var _last_view_height: float=0.0

func register(model: Node3D) -> void:
    if model!=null and Tactical.has_model(model):
        units.append(model)

func pixel_height(model: Node3D,camera: Camera3D,
        viewport_height: float) -> float:
    if model==null or camera==null or viewport_height<=1.0:
        return 0.0
    var height: float=Tactical.VISUAL_HEIGHT*model.global_transform.basis.y.length()
    if camera.projection==Camera3D.PROJECTION_ORTHOGONAL:
        return height*viewport_height/maxf(0.05,camera.size)
    # Perspective camera uses the positive depth on its local forward (-Z).
    var relative: Vector3=camera.to_local(model.global_position)
    var depth: float=maxf(0.05,-relative.z)
    var fov: float=deg_to_rad(camera.fov)
    return height*viewport_height/(2.0*depth*maxf(0.05,tan(fov*0.5)))

func update_now(camera: Camera3D,viewport_height: float) -> int:
    if camera==null or viewport_height<=1.0:
        return 0
    var changed: int=0
    for model in units:
        if not is_instance_valid(model) or not Tactical.has_model(model):
            continue
        var before: int=Tactical.detail_tier(model)
        Tactical.set_detail_from_pixels(model,
            pixel_height(model,camera,viewport_height))
        if before!=Tactical.detail_tier(model):
            changed+=1
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
