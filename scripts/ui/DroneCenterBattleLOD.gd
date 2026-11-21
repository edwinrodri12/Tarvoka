extends Node
class_name TarvokaDroneCenterBattleLOD

# Android: max ONE real camera-triggered building mesh replacement per tick.
const Model=preload("res://scripts/ui/DroneCenterBattle3D.gd")
const Projected=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const ENTER_PX:float=118.0
const EXIT_PX:float=85.0
const INTERVAL:float=0.25
const PENDING_INTERVAL:float=0.05
const MAX_CHANGED:int=1
var _sites:Array[Node3D]=[]
var _elapsed:float=0.0
var _pending:bool=false
var transitions:int=0
var last_step_ms:float=0.0
var peak_step_ms:float=0.0

func register(site:Node3D) -> bool:
    if site==null or not is_instance_valid(site) or \
            str(site.get_meta("site_kind",""))!=Model.SITE_KIND:
        return false
    if site not in _sites:
        _sites.append(site)
    return true

func registered_count() -> int:
    return _sites.size()

static func choose(pixels:float,prior:int) -> int:
    var width:float=maxf(0.0,pixels)
    if prior==Model.CLOSE:
        return Model.DISTANT if width<=EXIT_PX else Model.CLOSE
    return Model.CLOSE if width>=ENTER_PX else Model.DISTANT

func update_budgeted(camera:Camera3D) -> int:
    if camera==null or not is_instance_valid(camera):
        return 0
    var began:int=Time.get_ticks_usec()
    var count:int=0
    var pending:bool=false
    for site in _sites:
        if not is_instance_valid(site) or not site.is_inside_tree() or \
                not site.is_visible_in_tree():
            continue
        var projected:float=Projected.projected_width(camera,
            site.global_position+Vector3(0,0.46,0),2.11)
        var old:int=int(site.get_meta("drone_center_lod",Model.DISTANT))
        var desired:int=choose(projected,old)
        if desired==old:
            continue
        if count>=MAX_CHANGED:
            pending=true
            continue
        if Model.set_runtime_detail(site,desired):
            count+=1
    _pending=pending
    transitions+=count
    last_step_ms=float(Time.get_ticks_usec()-began)/1000.0
    peak_step_ms=maxf(peak_step_ms,last_step_ms)
    return count

func _process(delta:float) -> void:
    _elapsed+=maxf(delta,0.0)
    var delay:float=PENDING_INTERVAL if _pending else INTERVAL
    if _elapsed<delay:
        return
    _elapsed=fmod(_elapsed,delay)
    var camera:Camera3D=get_viewport().get_camera_3d()
    if camera!=null:
        update_budgeted(camera)
