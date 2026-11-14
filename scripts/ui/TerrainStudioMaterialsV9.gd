extends RefCounted
class_name TarvokaTerrainStudioMaterialsV9

# A terrain-art finish, not a new game renderer. Shade EXISTING vertex
# colors using measured geometric slope, facet orientation and deterministic
# world-space mineral grain. No textures, shader variants or new draw calls.
# The camera keeps seeing the same canonical 120 tactical study cells.
static func _grain(position: Vector3) -> float:
    var outer := sin(position.x*3.29+position.z*2.13+position.y*4.09)
    var inner := cos(position.z*7.31-position.x*5.83+position.y*1.93)
    return outer*inner

static func rock_color(base: Color, pos: Vector3, slope: Vector2,
        scene: int) -> Color:
    # Prefer dark exposed faces and sun-facing chamfers to uniformly
    # bright mineral bands. Facet orientation comes from REAL mesh heights.
    var normal := Vector3(-slope.x,1.0,-slope.y).normalized()
    var light := Vector3(-0.68,0.72,0.28).normalized()
    var sun: float = clampf(normal.dot(light),0.0,1.0)
    var steep: float = clampf(slope.length()/1.55,0.0,1.0)
    var shade: float = clampf(0.83+sun*0.18-steep*0.10,0.69,1.02)
    var mineral: Color = (
        Color("#51676a") if scene == 0 else
        Color("#867368") if scene == 1 else
        Color("#647876"))
    var result: Color = base.lerp(mineral,steep*0.16)
    # Fine-scale cross-bedding and fissures are visible at gameplay
    # distance; the break pattern doesn't restart at each cell boundary.
    var grain: float = _grain(pos)
    var crease: float = pow(absf(sin(pos.x*6.1+pos.z*7.0-pos.y*4.3)),11.0)
    var grain_factor: float = 1.0+grain*0.075-crease*0.065
    result = result*clampf(shade*grain_factor,0.68,1.07)
    # Weathered foothills become slightly warmer and less bright.
    if pos.y < 0.80:
        var weather: float = (0.80-pos.y)*0.025
        result = result.lerp(Color("#6c7163"),clampf(weather,0.0,0.09))
    result.a = 1.0
    return result

static func edge_color(base: Color, pos: Vector3, scene: int,
        woody: bool) -> Color:
    # Smaller undergrowth receives gentle variation, making biomes read
    # as blends instead of isolated saturated markers in the distance.
    var grain: float = _grain(pos+Vector3(2.7,0.3,-1.4))
    var factor: float = (0.88+grain*0.11) if woody else (0.90+grain*0.095)
    var earth := Color("#77775f") if scene == 1 else Color("#617264")
    return (base*clampf(factor,0.74,1.0)).lerp(earth,0.07 if woody else 0.05)

static func daylight_profile(setting: int, improved: bool) -> Dictionary:
    # The legacy presets and their saved selection stay unchanged.
    # This V13 profile supplies just subtle, controlled directional relief:
    # lower ambient and fill, a more grazing key and softer shadows.
    var sun_color: Color = (
        Color("#f5b98b") if setting == 1 else
        Color("#e3edf4") if setting == 2 else Color("#fff6dd"))
    if not improved:
        return {
            "key": 0.89 if setting == 0 else 0.76 if setting == 1 else 0.62,
            "fill": 0.20 if setting == 1 else 0.30 if setting == 2 else 0.26,
            "ambient":0.37 if setting == 1 else 0.53 if setting == 2 else 0.46,
            "sun":sun_color,
            "rotation":Vector3(-27,-52,0) if setting == 1 else Vector3(-46,-32,0),
            "blur":1.18}
    return {
        "key":0.83 if setting == 0 else 0.72 if setting == 1 else 0.61,
        "fill":0.15 if setting == 1 else 0.22 if setting == 2 else 0.17,
        "ambient":0.34 if setting == 1 else 0.43 if setting == 2 else 0.38,
        "sun":sun_color,
        "rotation":Vector3(-31,-67,0) if setting == 1 else
            Vector3(-37,-47,0) if setting == 0 else Vector3(-49,-50,0),
        "blur":1.75}
