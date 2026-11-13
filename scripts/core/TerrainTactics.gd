extends RefCounted
class_name TarvokaTerrainTactics

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")

# Original positional rules. A tile is not an RPG level and never changes
# permanent unit stats. Everything is recalculated on EACH attack, including
# the defender's one legal counter-shot.
const COVER := {"plain":0,"road":0,"forest":1,"mountain":2,"water":0}
const HIGH_GROUND_BONUS := 1
const FLANK_BONUS := 1
const CITY_COVER := 1

static func tile_at(terrain: Array, cell: Vector2i) -> String:
    # Terrain bonuses must work at every coordinate in 10x8, 24x18
    # and 40x30 maps, not only within the legacy compact board.
    if not Rules.inside(cell,terrain):
        return ""
    if not terrain[cell.y] is Array or cell.x >= terrain[cell.y].size():
        return ""
    return str(terrain[cell.y][cell.x])

static func height_of(kind: String) -> int:
    return 1 if kind == "mountain" else 0

static func city_at(economy: Dictionary, cell: Vector2i) -> bool:
    for site in economy.get("sites",[]):
        if site is Dictionary and str(site.get("kind","")) == "city" and site.get("pos",null) == cell:
            return true
    return false

static func flanks(attacker: Dictionary, defender: Dictionary, units: Array) -> bool:
    if Domains.domain(attacker) != Domains.GROUND or Domains.domain(defender) != Domains.GROUND:
        return false
    var attacking_role: String = str(attacker.get("role",""))
    if Doctrine.valid(attacking_role) and str(Doctrine.profile(attacking_role).get("style","")) not in ["direct","guided"]:
        return false
    var attack_pos = attacker.get("pos",null)
    var defender_pos = defender.get("pos",null)
    if not attack_pos is Vector2i or not defender_pos is Vector2i:
        return false
    var side: Vector2i = attack_pos - defender_pos
    if absi(side.x)+absi(side.y) != 1:
        return false
    var opposite: Vector2i = defender_pos - side
    for other in units:
        if not other is Dictionary or str(other.get("id","")) == str(attacker.get("id","")):
            continue
        if int(other.get("hp",0)) > 0 and int(other.get("faction",-1)) == int(attacker.get("faction",-2)) and Domains.domain(other) == Domains.GROUND and other.get("pos",null) == opposite:
            return true
    return false

static func modifiers(attacker: Dictionary, defender: Dictionary, terrain: Array, economy: Dictionary = {}, units: Array = []) -> Dictionary:
    var result := {"attack_bonus":0,"defense_cover":0,"height_delta":0,"flanked":false,"city":false,"terrain":""}
    var a_pos = attacker.get("pos",null)
    var d_pos = defender.get("pos",null)
    if not a_pos is Vector2i or not d_pos is Vector2i:
        return result
    var attack_tile: String = tile_at(terrain,a_pos)
    var defend_tile: String = tile_at(terrain,d_pos)
    if attack_tile.is_empty() or defend_tile.is_empty():
        return result
    result["terrain"] = defend_tile
    # Ground cover cannot protect an aircraft flying over the same square
    # or an offshore ship. Air-to-ground attacks do respect the target cover.
    if Domains.domain(defender) == Domains.GROUND:
        result["defense_cover"] = int(COVER.get(defend_tile,0))
        if city_at(economy,d_pos):
            result["city"] = true
            result["defense_cover"] += CITY_COVER
    if Domains.domain(attacker) == Domains.GROUND and Domains.domain(defender) == Domains.GROUND:
        var differential: int = height_of(attack_tile)-height_of(defend_tile)
        result["height_delta"] = differential
        result["attack_bonus"] = clampi(differential,-HIGH_GROUND_BONUS,HIGH_GROUND_BONUS)
        if flanks(attacker,defender,units):
            result["flanked"] = true
            result["attack_bonus"] += FLANK_BONUS
    return result

static func defensive_description(unit: Dictionary, terrain: Array, economy: Dictionary = {}) -> String:
    var position = unit.get("pos",null)
    if not position is Vector2i:
        return ""
    var kind: String = tile_at(terrain,position)
    if kind.is_empty():
        return ""
    if Domains.domain(unit) != Domains.GROUND:
        return "Sin cobertura terrestre (unidad %s)." % Domains.domain(unit)
    var cover: int = int(COVER.get(kind,0))
    var urban: bool = city_at(economy,position)
    if urban:
        cover += CITY_COVER
    var position_name := "altura" if kind == "mountain" else ("bosque" if kind == "forest" else ("carretera" if kind == "road" else "llanura"))
    return "Posicion %s: +%d cobertura%s." % [position_name,cover," (ciudad +1)" if urban else ""]
