extends RefCounted
class_name TarvokaArmoredWorkshopLODPolicy

# Screen-space size policy for TARVOKA Android building art.
# Designed for future integration AFTER art approval: no gameplay code touched.
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const ENTER_TACTICAL_PX:float=152.0
const EXIT_TACTICAL_PX:float=112.0

static func choose_mobile(projected_width_px:float,
        previous:int=Mobile.PROFILE_DISTANT) -> int:
    # Keep mobile profiles separate from HERO. Invalid/negative pixel extents
    # have no visible footprint and use the cheapest available representation.
    if projected_width_px<=0.0:
        return Mobile.PROFILE_DISTANT
    if previous==Mobile.PROFILE_TACTICAL:
        return Mobile.PROFILE_DISTANT if projected_width_px<=EXIT_TACTICAL_PX \
            else Mobile.PROFILE_TACTICAL
    return Mobile.PROFILE_TACTICAL if projected_width_px>=ENTER_TACTICAL_PX \
        else Mobile.PROFILE_DISTANT

static func projected_width(camera:Camera3D,
        world_center:Vector3,nominal_width_m:float) -> float:
    if camera==null or nominal_width_m<=0.0:
        return 0.0
    if camera.is_position_behind(world_center):
        return 0.0
    # Camera right on the focal plane makes the estimate independent of
    # the target building's rotation, and works with perspective/orthographic.
    var screen_center:Vector2=camera.unproject_position(world_center)
    var right_world:Vector3=world_center+\
        camera.global_transform.basis.x.normalized()*nominal_width_m
    var screen_right:Vector2=camera.unproject_position(right_world)
    return screen_center.distance_to(screen_right)

static func nominal_width(level:int) -> float:
    if level==1:
        return 9.5
    if level==2:
        return 15.0
    if level==3:
        return 20.5
    return 0.0
