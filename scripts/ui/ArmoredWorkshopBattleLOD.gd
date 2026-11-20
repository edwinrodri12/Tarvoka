extends Node
class_name TarvokaArmoredWorkshopBattleLOD

# Low-frequency camera LOD for existing modern armor production sites.
# No extra terrain cells, no signals to game logic and no battle changes.
const Workshop=preload("res://scripts/ui/ArmoredWorkshopBattle3D.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const INTERVAL:float=0.25

var _sites:Array[Node3D]=[]
var _elapsed:float=0.0

func register(root:Node3D) -> bool:
    if root==null or not is_instance_valid(root):
        return false
    if str(root.get_meta("site_kind",""))!=Workshop.SITE_KIND:
        return false
    if root not in _sites:
        _sites.append(root)
    return true

func registered_count() -> int:
    return _sites.size()

func refresh(camera:Camera3D) -> int:
    if camera==null or not is_instance_valid(camera):
        return 0
    var changed:int=0
    for site in _sites:
        if site==null or not is_instance_valid(site):
            continue
        # Read only geometry present on this public player's 3D board.
        if not site.is_inside_tree() or not site.is_visible_in_tree():
            continue
        var bounds_center:Vector3=site.global_position+Vector3(0,0.43,0)
        var width_pixels:float=Policy.projected_width(
            camera,bounds_center,2.24)
        var old:int=int(site.get_meta("workshop_lod_profile",
            Mobile.PROFILE_TACTICAL))
        var desired:int=Policy.choose_mobile(width_pixels,old)
        if desired!=old and Workshop.set_runtime_detail(site,desired):
            changed+=1
    return changed

func _process(delta:float) -> void:
    _elapsed+=delta
    if _elapsed<INTERVAL:
        return
    _elapsed=0.0
    var camera:Camera3D=get_viewport().get_camera_3d()
    if camera!=null:
        refresh(camera)
