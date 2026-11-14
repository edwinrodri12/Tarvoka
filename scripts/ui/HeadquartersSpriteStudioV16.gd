extends RefCounted
class_name TarvokaHeadquartersSpriteStudioV16

# REAL Android sprite source, previewed inside the real Godot 3D showroom.
# The billboard is a FLAT Sprite3D with a V15 pre-baked PNG, NOT a fake
# reconstructed HQ model. Keep the full V12 and V13 physical 3D models intact.
const BASE := "res://assets/buildings/hq_v15"
const NAMES := [
    "Alianza Norte", "Pacto Escarlata", "Unión Verde",
    "Confederación Solar", "Sindicato Violeta", "Legión Ámbar",
    "Dominio Turquesa", "Orden Ónix"
]
const NATIVE_SIZE := 384
const ZOOM_LABELS := [
    "100% · Inspección de sprite",
    "65% · Distancia táctica",
    "38% · Zoom lejano (V14 en Android)"
]
const ZOOM_PIXELS := [188,124,74]

static var _cache: Dictionary = {}

static func path_for(faction: int) -> String:
    if faction == -1:
        return "%s/hq_neutral.png" % BASE
    if faction < 0 or faction >= NAMES.size():
        return ""
    return "%s/hq_%d.png" % [BASE,faction]

static func texture_for(faction: int) -> Texture2D:
    var path: String = path_for(faction)
    if path.is_empty():
        return null
    if _cache.has(path):
        return _cache[path] as Texture2D
    if not ResourceLoader.exists(path):
        return null
    var texture: Texture2D = ResourceLoader.load(path) as Texture2D
    if texture == null or texture.get_width() != NATIVE_SIZE or texture.get_height() != NATIVE_SIZE:
        return null
    _cache[path] = texture
    return texture

static func available() -> bool:
    if texture_for(-1) == null:
        return false
    for faction in range(8):
        if texture_for(faction) == null:
            return false
    return true

static func build_billboard(faction: int,original_selection: int = 0) -> Node3D:
    # A camera-facing card intentionally makes the baked 2D-vs-real-3D
    # distinction visible and testable in the SAME Godot camera.
    var texture: Texture2D = texture_for(faction)
    if texture == null:
        return null
    var root := Node3D.new()
    root.name = "CuartelGeneralSpriteV15EnEstudio3D"
    root.set_meta("tarvoka_hq_v15_sprite_card",true)
    root.set_meta("tarvoka_hq_offline_baked",true)
    root.set_meta("tarvoka_hq_sprite_faction",faction)
    root.set_meta("visual_faction",original_selection)
    root.set_meta("visual_level",2)
    root.set_meta("visual_condition","operativo")
    root.set_meta("tarvoka_building_kind","headquarters")
    var sprite := Sprite3D.new()
    sprite.name = "Sprite3DOriginalAndroid384"
    sprite.texture = texture
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite.pixel_size = 0.038
    sprite.shaded = false
    sprite.position = Vector3(0,4.0,-0.4)
    sprite.double_sided = true
    root.add_child(sprite)
    return root

static func cache_size() -> int:
    return _cache.size()
