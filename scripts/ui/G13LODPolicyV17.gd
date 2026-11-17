extends RefCounted
class_name TarvokaG13LODPolicyV17

# Authoring/performance choice for the G13. G13 remains ART-only until it
# is registered in battle rules; this is NOT a gameplay unit registry.
# Android / dense formations always use the approved cheap LOD8.
const MOBILE_ART_LEVEL := 8
const HERO_ART_LEVEL := 13
const ENTER_HERO_DISTANCE := 6.5
const EXIT_HERO_DISTANCE := 8.0
const MAX_HERO_FLEET := 2

static func choose(camera_distance: float,visible_g13_count: int,
        is_android: bool,inspection: bool=false,
        previous_art_level: int=MOBILE_ART_LEVEL)->int:
    if is_android:
        return MOBILE_ART_LEVEL
    # The standalone inspection viewer deliberately displays the final
    # approved 3D hero with all eight faction variants (not an Android battle).
    if inspection:
        return HERO_ART_LEVEL
    if visible_g13_count>MAX_HERO_FLEET:
        return MOBILE_ART_LEVEL
    if visible_g13_count<1 or not is_finite(camera_distance):
        return MOBILE_ART_LEVEL
    # Hysteresis avoids 8/13 rebuilding every frame at the distance boundary.
    var threshold:float=EXIT_HERO_DISTANCE if (
        previous_art_level==HERO_ART_LEVEL) else ENTER_HERO_DISTANCE
    return HERO_ART_LEVEL if camera_distance<=threshold else MOBILE_ART_LEVEL

static func recommended_for_formation(visible_g13_count:int,
        is_android:bool=false)->int:
    # A formation overview should not allocate 13,584 triangles per bus.
    return choose(100.0,visible_g13_count,is_android,false,MOBILE_ART_LEVEL)
