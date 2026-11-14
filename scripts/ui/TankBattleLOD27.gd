extends RefCounted
class_name TarvokaG09BattleLOD27

# Pure (no scene mutation) Android-friendly G09 art budget for the ACTUAL
# Battle3D map. One full V25 tank maximum, only when the selected tank is
# close; several V10 tanks at mid zoom; distant units stay lightweight V6.
# All tiers share the same authoritative unit IDs, faction and fog filtering.
const FAR := 0
const MEDIUM := 1
const HERO := 2
const FAR_ART := 6
const MEDIUM_ART := 10
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

static func tank_art_level(camera_size: float,selected: bool,
        allow_hero: bool,hero_used: int,medium_used: int) -> int:
    var band: int = tier(camera_size)
    if band == HERO and selected and allow_hero and hero_used<MAX_HERO_TANKS:
        return HERO_ART
    if band >= MEDIUM and medium_used<MAX_MEDIUM_TANKS:
        return MEDIUM_ART
    return FAR_ART

static func accept_hero(role: String,faction: int,selected: bool,
        art_level: int) -> bool:
    # G09 can be inspected in combat on either team, but only when the
    # commander selected that LEGITIMATELY VISIBLE unit; no fog bypass.
    return role=="tank" and faction>=0 and selected and art_level==HERO_ART

static func description(art: int) -> String:
    match art:
        HERO_ART:
            return "G09 V25 · PBR completo"
        MEDIUM_ART:
            return "G09 V10 · batalla"
        _:
            return "G09 V6 · optimizado"
