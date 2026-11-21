extends RefCounted
class_name TarvokaVisualStyle

# Visual-only catalog. Faction IDs and artwork are deliberately NOT battle-state
# values: no changes to rules, save format, initiative, or approved balance v0.1.
# Names, ordering, colors and approved icon motifs are fixed references.
const FACTIONS = [
    {"key":"alianza_norte","name":"Alianza Norte","color":"#2375F3","motif":"Aguila blanca y laureles"},
    {"key":"pacto_escarlata","name":"Pacto Escarlata","color":"#E52932","motif":"Leon blanco coronado"},
    {"key":"union_verde","name":"Unión Verde","color":"#34C742","motif":"Arbol blanco en engranaje"},
    {"key":"confederacion_solar","name":"Confederación Solar","color":"#F3BE26","motif":"Sol radiante"},
    {"key":"sindicato_violeta","name":"Sindicato Violeta","color":"#A34BEC","motif":"Tres hexagonos"},
    {"key":"legion_ambar","name":"Legión Ámbar","color":"#ED851D","motif":"Dragon blanco"},
    {"key":"dominio_turquesa","name":"Dominio Turquesa","color":"#19BDD3","motif":"Tridente y olas"},
    {"key":"orden_onix","name":"Orden Ónix","color":"#AEB5C2","motif":"Insignia alada plateada"}
]
const TERRAIN_COLORS = {
    "plain":"#3C5D46",
    "forest":"#1E4931",
    "road":"#76644B",
    "mountain":"#606D7A",
    "water":"#195476"
}
# Movement is blue and attack is red, independent of faction colors.
const MOVE_FILL = Color(0.17, 0.53, 0.98, 0.38)
const ATTACK_FILL = Color(0.94, 0.20, 0.16, 0.40)
# Outline for POTENTIAL weapon range; red remains reserved for an actual legal target.
const WEAPON_COVERAGE_FILL = Color(1.0, 0.62, 0.16, 0.14)
const WEAPON_COVERAGE_OUTLINE = Color(1.0, 0.70, 0.24, 0.86)

static func faction_info(index: int) -> Dictionary:
    if index < 0 or index >= FACTIONS.size():
        return {}
    return FACTIONS[index].duplicate()

static func faction_color(index: int) -> Color:
    if index < 0 or index >= FACTIONS.size():
        return Color.WHITE
    return Color.html(str(FACTIONS[index]["color"]))

static func emblem_path(index: int) -> String:
    if index < 0 or index >= FACTIONS.size():
        return ""
    return "res://assets/factions/%s.png" % str(FACTIONS[index]["key"])

# Original approved atlas sheets are the source of truth when individual
# PNG files are not present in the Web studio branch. Match main runtime.
const FIRST_FOUR_ATLAS := "res://assets/factions/official_first_four_atlas.webp"
const LAST_FOUR_ATLAS := "res://assets/factions/official_last_four_atlas.webp"
const ATLAS_CREST_EDGE := 160
const ATLAS_COMMANDER_HEIGHT := 113

static func emblem_texture(index: int) -> Texture2D:
    var path: String = emblem_path(index)
    if path.is_empty():
        return null
    if ResourceLoader.exists(path):
        var png: Texture2D = ResourceLoader.load(path) as Texture2D
        if png != null:
            return png
    # This is NOT a substitute crest: it crops the real approved original
    # image for precisely the same one of eight faction identities.
    var atlas_path: String = FIRST_FOUR_ATLAS if index < 4 else LAST_FOUR_ATLAS
    var sheet: Texture2D = null
    if ResourceLoader.exists(atlas_path):
        sheet = ResourceLoader.load(atlas_path) as Texture2D
    if sheet == null:
        return null
    if sheet.get_width() != ATLAS_CREST_EDGE*4:
        return null
    if sheet.get_height() != ATLAS_CREST_EDGE+ATLAS_COMMANDER_HEIGHT:
        return null
    var texture := AtlasTexture.new()
    texture.atlas = sheet
    texture.region = Rect2((index%4)*ATLAS_CREST_EDGE,
        0,ATLAS_CREST_EDGE,ATLAS_CREST_EDGE)
    texture.filter_clip = true
    return texture

static func terrain_color(kind: String, x: int, y: int) -> Color:
    var base: Color = Color.html(str(TERRAIN_COLORS.get(kind, TERRAIN_COLORS["plain"])))
    # Inexpensive deterministic light variation; never affects movement cost.
    return base.lightened(0.055) if (x + y) % 2 == 0 else base.darkened(0.055)

static func movement_fill() -> Color:
    return MOVE_FILL

static func attack_fill() -> Color:
    return ATTACK_FILL

static func weapon_coverage_fill() -> Color:
    return WEAPON_COVERAGE_FILL

static func weapon_coverage_outline() -> Color:
    return WEAPON_COVERAGE_OUTLINE
