extends RefCounted
class_name TarvokaG09BattleLOD27

# Compatibility tier interface used by the live 3D battle camera.
# V28 intentionally NEVER swaps tank models. All three bands use G09 V25.
# Actual CPU/GPU work reduction is handled by TankAdaptiveV28.gd.
const FAR := 0
const MEDIUM := 1
const HERO := 2
const FAR_ART := 25
const MEDIUM_ART := 25
const HERO_ART := 25
const MEDIUM_CUTOFF := 36.0
const HERO_CUTOFF := 17.5
const MAX_HERO_TANKS := 1
const MAX_MEDIUM_TANKS := 4

static func tier(camera_size: float) -> int:
    if camera_size <= HERO_CUTOFF:
        return HERO
    if camera_size <= MEDIUM_CUTOFF:
        return MEDIUM
    return FAR

static func tank_art_level(_camera_size: float,_selected: bool,
        _allow_hero: bool,_hero_used: int,_medium_used: int) -> int:
    return HERO_ART

static func accept_hero(role: String,faction: int,selected: bool,
        art_level: int) -> bool:
    return role=="tank" and faction>=0 and selected and art_level==HERO_ART

static func description(_art: int) -> String:
    return "G09 V25 · misma silueta en todas las distancias"
