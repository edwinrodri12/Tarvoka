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

static func emblem_texture(index: int) -> Texture2D:
    var path: String = emblem_path(index)
    if path.is_empty() or not ResourceLoader.exists(path):
        return null
    return ResourceLoader.load(path) as Texture2D

static func terrain_color(kind: String, x: int, y: int) -> Color:
    var base: Color = Color.html(str(TERRAIN_COLORS.get(kind, TERRAIN_COLORS["plain"])))
    # Inexpensive deterministic light variation; never affects movement cost.
    return base.lightened(0.055) if (x + y) % 2 == 0 else base.darkened(0.055)

static func movement_fill() -> Color:
    return MOVE_FILL

static func attack_fill() -> Color:
    return ATTACK_FILL
