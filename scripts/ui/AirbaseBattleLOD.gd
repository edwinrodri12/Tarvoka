extends Node
class_name TarvokaAirbaseBattleLOD

# Runtime Android-friendly camera LOD: the V16-derived close tactical
# material/geometry is built only when a REAL airbase fills the screen.
const Airbase=preload("res://scripts/ui/AirbaseBattle3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const INTERVAL:float=0.25
const PENDING_INTERVAL:float=0.05
const MAX_CHANGED_PER_STEP:int=1
const ENTER_CLOSE_PX:float=115.0
const EXIT_CLOSE_PX:float=85.0
var _sites:Array[Node3D]=[]
var _elapsed:float=0.0
var _pending_transition:bool=false
var transitions:int=0
var last_step_ms:float=0.0
var peak_step_ms:float=0.0

func register(site:Node3D) -> bool:
    if site==null or not is_instance_valid(site):
        return false
    if str(site.get_meta("site_kind",""))!=Airbase.SITE_KIND:
        return false
    if site not in _sites:
        _sites.append(site)
    return true

func registered_count() -> int:
    return _sites.size()

static func choose_detail(pixels:float,previous:int) -> int:
    # 30-pixel hysteresis band avoids oscillation near a zoom threshold.
    var projected:float=maxf(pixels,0.0)
    if previous==Airbase.PROFILE_CLOSE:
        return Airbase.PROFILE_DISTANT if projected<=EXIT_CLOSE_PX \
            else Airbase.PROFILE_CLOSE
    return Airbase.PROFILE_CLOSE if projected>=ENTER_CLOSE_PX \
        else Airbase.PROFILE_DISTANT

func _desired(site:Node3D,camera:Camera3D) -> int:
    var center:Vector3=site.global_position+Vector3(0,0.53,0)
    return choose_detail(Policy.projected_width(
        camera,center,2.13),int(site.get_meta(
        "airbase_lod_profile",Airbase.PROFILE_DISTANT)))

func update_budgeted(camera:Camera3D) -> int:
    if camera==null or not is_instance_valid(camera):
        return 0
    var began:int=Time.get_ticks_usec()
    var changed:int=0
    var pending:bool=false
    for site in _sites:
        if not is_instance_valid(site) or not site.is_inside_tree() or \
                not site.is_visible_in_tree():
            continue
        var old:int=int(site.get_meta("airbase_lod_profile",
            Airbase.PROFILE_DISTANT))
        var desired:int=_desired(site,camera)
        if desired==old:
            continue
        if changed>=MAX_CHANGED_PER_STEP:
            pending=true
            continue
        if Airbase.set_runtime_detail(site,desired):
            changed+=1
    _pending_transition=pending
    transitions+=changed
    last_step_ms=float(Time.get_ticks_usec()-began)/1000.0
    peak_step_ms=maxf(peak_step_ms,last_step_ms)
    return changed

func _process(delta:float) -> void:
    _elapsed+=maxf(0.0,delta)
    var interval:float=PENDING_INTERVAL if _pending_transition else INTERVAL
    if _elapsed<interval:
        return
    _elapsed=fmod(_elapsed,interval)
    var camera:Camera3D=get_viewport().get_camera_3d()
    if camera!=null:
        update_budgeted(camera)
