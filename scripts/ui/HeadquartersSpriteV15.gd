extends RefCounted
class_name TarvokaHeadquartersSpriteV15

# VISUAL-ONLY presentation of offline Godot-baked HQ V13 models. Source
# geometry remains in the art branch; Android battle loads only PNGs.
# Exactly one approved atlas-derived faction crest is baked into each sprite.
# A neutral/dark-fog site uses a crest-free grey sprite, never a guessed team.
const ASSET_ROOT := "res://assets/buildings/hq_v15"
const MIN_HALF_WIDTH := 15.0
const MAX_VARIANTS := 9
const SPRITE_EDGE := 384

static var _cache: Dictionary = {}

static func asset_path(faction: int) -> String:
    if faction == -1:
        return ASSET_ROOT + "/hq_neutral.png"
    if faction < 0 or faction > 7:
        return ""
    return "%s/hq_%d.png" % [ASSET_ROOT,faction]

static func sprite(faction: int) -> Texture2D:
    var path: String = asset_path(faction)
    if path.is_empty():
        return null
    if _cache.has(path):
        return _cache[path] as Texture2D
    if not ResourceLoader.exists(path):
        return null
    var image: Texture2D = ResourceLoader.load(path) as Texture2D
    if image == null or image.get_width()!=SPRITE_EDGE or image.get_height()!=SPRITE_EDGE:
        return null
    _cache[path] = image
    return image

static func prefer(high_width: float,battery_saver: bool) -> bool:
    # Fewer draw calls and zero texture sample cost when zoomed too far out
    # or when the user selects Android battery saver.
    return not battery_saver and high_width >= MIN_HALF_WIDTH

static func draw_iso(canvas: CanvasItem,center: Vector2,half_width: float,
        faction: int,battery_saver: bool = false) -> bool:
    if canvas == null or not prefer(half_width,battery_saver):
        return false
    var image: Texture2D = sprite(faction)
    if image == null:
        return false
    # Model's isometric ground contact stays centered on the original city
    # tile; no new collision shape or false tactical hitbox.
    var span: float = half_width*1.54
    var rect := Rect2(center-Vector2(span*0.50,span*0.77),
        Vector2(span,span))
    canvas.draw_texture_rect(image,rect,false)
    return true

static func cache_size() -> int:
    return _cache.size()
