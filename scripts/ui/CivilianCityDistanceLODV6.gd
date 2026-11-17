extends Node
class_name TarvokaCivilianCityDistanceLODV6

# TARVOKA V6 - native 3D city art distance LOD, designed for Android.
# No impostors, no ownership queries, no gameplay state mutations.
# Only the original pre-placed, publicly observed city meshes are managed.
const City=preload("res://scripts/ui/CivilianCityBattle3D.gd")
const INTERVAL: float=0.25
# Hysteresis avoids continuously rebuilding buildings during pinch-zoom.
const NEAR_ENTER: float=56.0
const NEAR_EXIT: float=38.0
const MEDIUM_ENTER: float=20.0
const MEDIUM_EXIT: float=13.0
const LEVEL_HEIGHTS=[5.3,8.2,12.1]
var cities: Array[Node3D]=[]
var _elapsed: float=0.0
var transitions: int=0

func register(city: Node3D) -> void:
    if city==null or not is_instance_valid(city):
        return
    if str(city.get_meta("site_kind",""))!="city":
        return
    if int(city.get_meta("approved_art_version",-1))!=City.ART_VERSION:
        return
    if not cities.has(city):
        cities.append(city)

static func preferred_detail(pixels: float,previous: int) -> int:
    var p: float=maxf(0.0,pixels)
    match previous:
        0:
            if p<NEAR_EXIT:
                return 2 if p<=MEDIUM_EXIT else 1
            return 0
        1:
            if p>=NEAR_ENTER:
                return 0
            if p<=MEDIUM_EXIT:
                return 2
            return 1
        2:
            if p>=NEAR_ENTER:
                return 0
            if p>=MEDIUM_ENTER:
                return 1
            return 2
    return 2

static func pixel_height(city: Node3D,camera: Camera3D,
        viewport_height: float) -> float:
    if city==null or camera==null or viewport_height<=1.0:
        return 0.0
    var tier: int=clampi(int(city.get_meta("visual_level",1)),1,3)
    var world_height: float=LEVEL_HEIGHTS[tier-1]*(
        city.global_transform.basis.y.length())
    if camera.projection==Camera3D.PROJECTION_ORTHOGONAL:
        return world_height*viewport_height/maxf(0.05,camera.size)
    var relative: Vector3=camera.to_local(city.global_position)
    var depth: float=maxf(0.05,-relative.z)
    return world_height*viewport_height/(
        2.0*depth*maxf(0.05,tan(deg_to_rad(camera.fov)*0.5)))

func update_now(camera: Camera3D,viewport_height: float) -> int:
    if camera==null or viewport_height<=1.0:
        return 0
    var changes: int=0
    for city in cities:
        if not is_instance_valid(city):
            continue
        var current: int=int(city.get_meta("city_lod",2))
        var desired: int=preferred_detail(
            pixel_height(city,camera,viewport_height),current)
        if desired!=current and City.set_runtime_detail(city,desired):
            changes+=1
    transitions+=changes
    return changes

func _process(delta: float) -> void:
    _elapsed+=maxf(0.0,delta)
    if _elapsed<INTERVAL:
        return
    _elapsed=fmod(_elapsed,INTERVAL)
    var camera: Camera3D=get_viewport().get_camera_3d()
    if camera==null:
        return
    update_now(camera,float(get_viewport().get_visible_rect().size.y))
