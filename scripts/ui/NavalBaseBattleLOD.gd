extends Node
class_name TarvokaNavalBaseBattleLOD

# Exactly the two real marine production tiles are camera-managed.
# No simulations, network reads, capture changes or sea rule updates.
const Naval=preload("res://scripts/ui/NavalBaseBattle3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const INTERVAL:float=0.25
const FAST_INTERVAL:float=0.05
const ENTER_CLOSE_PX:float=116.0
const EXIT_CLOSE_PX:float=85.0
const MAX_CHANGED_PER_STEP:int=1
var _sites:Array[Node3D]=[]
var _elapsed:float=0.0
var _pending:bool=false
var transitions:int=0
var last_step_ms:float=0.0
var peak_step_ms:float=0.0

func register(root:Node3D) -> bool:
    if root==null or not is_instance_valid(root):
        return false
    if str(root.get_meta("site_kind",""))!=Naval.SITE_KIND:
        return false
    if root not in _sites:
        _sites.append(root)
    return true

func registered_count() -> int:
    return _sites.size()

static func choose(pixels:float,old:int) -> int:
    if old==Naval.PROFILE_CLOSE:
        return Naval.PROFILE_DISTANT if pixels<=EXIT_CLOSE_PX \
            else Naval.PROFILE_CLOSE
    return Naval.PROFILE_CLOSE if pixels>=ENTER_CLOSE_PX \
        else Naval.PROFILE_DISTANT

func update_budgeted(camera:Camera3D) -> int:
    if camera==null or not is_instance_valid(camera):
        return 0
    var tick:int=Time.get_ticks_usec()
    var switched:int=0
    var pending:bool=false
    for site in _sites:
        if not is_instance_valid(site) or not site.is_inside_tree() or \
                not site.is_visible_in_tree():
            continue
        var px:float=Policy.projected_width(camera,
            site.global_position+Vector3(0,0.47,0),2.13)
        var old:int=int(site.get_meta("naval_mobile_profile",
            Naval.PROFILE_DISTANT))
        var required:int=choose(px,old)
        if required==old:
            continue
        if switched>=MAX_CHANGED_PER_STEP:
            pending=true
            continue
        if Naval.set_runtime_detail(site,required):
            switched+=1
    _pending=pending
    transitions+=switched
    last_step_ms=float(Time.get_ticks_usec()-tick)/1000.0
    peak_step_ms=maxf(peak_step_ms,last_step_ms)
    return switched

func _process(delta:float) -> void:
    _elapsed+=maxf(delta,0.0)
    var duration:float=FAST_INTERVAL if _pending else INTERVAL
    if _elapsed<duration:
        return
    _elapsed=fmod(_elapsed,duration)
    var camera:Camera3D=get_viewport().get_camera_3d()
    if camera!=null:
        update_budgeted(camera)
