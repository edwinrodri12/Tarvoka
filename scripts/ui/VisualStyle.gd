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
    # Temperate palette follows the approved Operacion Rio Azul landscape.
    # Faction color is applied separately and never tints this geography.
    "plain":"#587F4B",
    "forest":"#27583C",
    "road":"#807259",
    "mountain":"#78858A",
    "water":"#216D91"
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

static func emblem_texture(index: int) -> Texture2D:
    var path: String = emblem_path(index)
    if path.is_empty() or not ResourceLoader.exists(path):
        return null
    return ResourceLoader.load(path) as Texture2D

static func _terrain_noise(x: int, y: int) -> float:
    # Small integer-valued noise field: no random generator or state,
    # stable at every zoom and after loading a saved battle.
    var hashed: int = posmod(
        x*127+y*313+x*y*541+x*x*47+y*y*91+421,997)
    return float(hashed)/997.0

static func terrain_color(kind: String, x: int, y: int) -> Color:
    var base: Color = Color.html(str(TERRAIN_COLORS.get(
        kind,TERRAIN_COLORS["plain"])))
    # Bilinear low-frequency noise gives broad material color zones.
    # The old alternating +/-5.5% checkerboard created visible seams.
    var gx: float = float(x)/4.0
    var gy: float = float(y)/4.0
    var ax: int = floori(gx)
    var ay: int = floori(gy)
    var tx: float = gx-float(ax)
    var ty: float = gy-float(ay)
    tx = tx*tx*(3.0-2.0*tx)
    ty = ty*ty*(3.0-2.0*ty)
    var north: float = lerpf(_terrain_noise(ax,ay),
        _terrain_noise(ax+1,ay),tx)
    var south: float = lerpf(_terrain_noise(ax,ay+1),
        _terrain_noise(ax+1,ay+1),tx)
    var variation: float = (lerpf(north,south,ty)-0.5)*0.16
    return base.lightened(variation) if variation >= 0.0 else (
        base.darkened(-variation))

static func movement_fill() -> Color:
    return MOVE_FILL

static func attack_fill() -> Color:
    return ATTACK_FILL

static func weapon_coverage_fill() -> Color:
    return WEAPON_COVERAGE_FILL

static func weapon_coverage_outline() -> Color:
    return WEAPON_COVERAGE_OUTLINE
