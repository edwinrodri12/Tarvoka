extends RefCounted
class_name TarvokaUnitRoles

const Combat = preload("res://scripts/core/Combat.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")

# Original TARVOKA experimental combined-arms lineup.
# These are combat roles, NOT purchasable units or a campaign progression.
# Legacy v1 soldiers have no role key and retain identical combat values.
const PROFILES := {
    "line": {"label":"Guardia","hp":10,"move_points":3,"attack":5,"defense":0,"vision":3,"attack_min_range":1,"attack_range":1,"symbol":"G"},
    "scout": {"label":"Rastreador","hp":6,"move_points":4,"attack":2,"defense":0,"vision":5,"attack_min_range":1,"attack_range":1,"symbol":"R"},
    "bulwark": {"label":"Baluarte","hp":12,"move_points":2,"attack":3,"defense":2,"vision":3,"attack_min_range":1,"attack_range":1,"symbol":"B"},
    "piercer": {"label":"Rompedor","hp":8,"move_points":3,"attack":4,"defense":0,"vision":3,"attack_min_range":1,"attack_range":1,"symbol":"P"},
    "artillery": {"label":"Lanzador","hp":7,"move_points":2,"attack":6,"defense":0,"vision":3,"attack_min_range":2,"attack_range":2,"symbol":"L"}
}

const ORDER := ["line", "scout", "bulwark", "piercer", "artillery"]

# Explicit counterplay, not invisible bonuses against all units:
# scouts can threaten the exposed ranged platform, while specialized
# piercers defeat front-line armor. The same rules apply to either faction.
const BONUSES := {
    "scout": {"artillery":3},
    "piercer": {"bulwark":4}
}

static func valid(role: String) -> bool:
    return PROFILES.has(role) or Arsenal.valid(role)

static func label(role: String) -> String:
    if not valid(role):
        return "Soldado"
    return str(PROFILES[role]["label"]) if PROFILES.has(role) else str(Arsenal.profile(role)["label"])

static func symbol(role: String) -> String:
    if PROFILES.has(role):
        return str(PROFILES[role]["symbol"])
    return str(Arsenal.profile(role).get("symbol", ""))

static func counter_description(role: String) -> String:
    match role:
        "scout":
            return "Especialista contra Lanzador (+3 ATQ)."
        "piercer":
            return "Especialista contra Baluarte (+4 ATQ)."
        "bulwark":
            return "Blindaje 2; avanza despacio."
        "artillery":
            return "Dispara a 2 casillas, no a adyacentes."
        "line":
            return "Fuerza flexible de corto alcance."
        _:
            return str(Arsenal.profile(role).get("note", ""))

static func make_unit(id: String, faction: int, pos: Vector2i, role: String) -> Dictionary:
    if not valid(role) or id.is_empty() or faction not in [0, 1]:
        return {}
    var profile: Dictionary = PROFILES[role] if PROFILES.has(role) else Arsenal.profile(role)
    var unit: Dictionary = {
        "id": id, "faction": faction, "hp": int(profile["hp"]),
        "pos": pos, "move_points": int(profile["move_points"]),
        "attack": int(profile["attack"]), "defense": int(profile["defense"]),
        "cover": 0, "vision": int(profile["vision"]),
        "attack_min_range": int(profile["attack_min_range"]),
        "attack_range": int(profile["attack_range"]),
        "acted": false, "role": role
    }
    # Never add extra fields to the five original role saves.
    if Arsenal.valid(role):
        unit["domain"] = str(profile["domain"])
        unit["target_domains"] = profile["target_domains"].duplicate()
    return unit

static func role_bonus(attacker: Dictionary, defender: Dictionary) -> int:
    var attack_role: String = str(attacker.get("role", ""))
    var defense_role: String = str(defender.get("role", ""))
    if not valid(attack_role) or not valid(defense_role):
        return 0
    return int(BONUSES.get(attack_role, {}).get(defense_role, 0))

static func resolve(attacker: Dictionary, defender: Dictionary) -> Dictionary:
    return Combat.resolve(
        int(attacker.get("hp", 0)), int(defender.get("hp", 0)),
        int(attacker.get("attack", 0)) + role_bonus(attacker, defender),
        int(defender.get("defense", 0)), int(defender.get("cover", 0))
    )

static func is_specialized(units: Array) -> bool:
    for unit in units:
        if unit is Dictionary and valid(str(unit.get("role", ""))):
            return true
    return false

# Mirrored, valid positions on all three current maps. Optional fog mode
# relies on the existing scout role rather than spawning extra S/Z units.
static func experimental_armies(symmetric: bool = true) -> Array:
    var units: Array = []
    var ids_blue := ["A","B","C","D","E"]
    var ids_red := ["X","Y","Z","W","V"]
    for i in range(ORDER.size()):
        units.append(make_unit(ids_blue[i], 0, Vector2i(1, i + 1), ORDER[i]))
        var enemy: Dictionary = make_unit(ids_red[i], 1, Vector2i(8, i + 1), ORDER[i])
        if not symmetric:
            # The explicit "Entrenamiento" setup makes the enemy weaker,
            # exactly as the older infantry practice preset did.
            enemy["hp"] = maxi(1, int(enemy["hp"]) - 2)
            enemy["attack"] = maxi(1, int(enemy["attack"]) - 1)
        units.append(enemy)
    return units
