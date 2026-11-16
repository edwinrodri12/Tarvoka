extends RefCounted
class_name TarvokaFactionPowerBalanceV17

# DESIGN LAB ONLY. No commander bonuses exist in core BattleActions, and
# 8 visual faction IDs are not eight real combat sides. The percentages
# below transcribe the *discussion's v0.1 candidates* for sensitivity tests,
# NOT executable/applied game rules, not a replacement for approved source art.
# Exact duration, activation, rounding, stacking, eligibility and exclusions
# must be validated before any production balance claim.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Veterans = preload("res://scripts/experiments/UnitVeterancyV14.gd")
const Tech = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

const ROUNDING := ["floor","nearest","ceil"]
const STACKING := ["replace","add"] # Boundaries for analysis only; no final rule.
const TERRAIN_TYPES := ["plain","forest","mountain"]
const PROFILES := {
    "alianza_norte":{"passive_accuracy":5,"power_accuracy":10,"status":"not_supported_in_deterministic_combat"},
    "pacto_escarlata":{"passive_attack":8,"power_attack":15,"counter_vulnerability":5,
        "status":"forward_damage_projection_only"},
    "union_verde":{"passive_scout_move":1,"power_ground_move":1,"status":"movement_not_combat_damage"},
    "confederacion_solar":{"passive_cost_reduction":5,"power_cost_reduction":15,
        "status":"illustrative_cost_ceiling_exclusions_undecided"},
    "sindicato_violeta":{"passive_ew":10,"power_indirect_range":1,
        "status":"ew_not_implemented_range_eligibility_test_only"},
    "legion_ambar":{"passive_damage_reduction":8,"power_damage_reduction":15,
        "status":"incoming_damage_projection_only"},
    "dominio_turquesa":{"passive_naval_attack":8,"power_naval_attack":15,
        "power_naval_defense":15,"status":"naval_only_damage_projection"},
    "orden_onix":{"passive_concealment":true,"power_concealment":true,
        "status":"concealment_not_implemented"}
}

static func roles() -> Array:
    var all: Array = Roles.ORDER.duplicate()
    all.append_array(Arsenal.ORDER)
    return all

static func faction_keys() -> Array:
    var result: Array = []
    for faction in Style.FACTIONS:
        result.append(str(faction["key"]))
    return result

static func terrain_at(kind: String, cell: Vector2i = Vector2i(3,3)) -> Array:
    var tiles: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        tiles.append(row)
    if kind in TERRAIN_TYPES:
        tiles[cell.y][cell.x] = kind
    return tiles

static func soldier(role: String, side: int, cell: Vector2i, level: int) -> Dictionary:
    if role in Veterans.CONSUMABLE:
        level = 0 # no fictitious XP on self-destructing ammunition.
    return Veterans.unit(role,side,cell,level)

static func exchange(attacker_role: String, defender_role: String,
        attack_level: int, defense_level: int, kind: String) -> Dictionary:
    if not Roles.valid(attacker_role) or not Roles.valid(defender_role) or kind not in TERRAIN_TYPES:
        return {"valid":false}
    var attacker: Dictionary = soldier(attacker_role,0,Vector2i(2,3),attack_level)
    if attacker.is_empty():
        return {"valid":false}
    var dist: int = int(attacker["attack_min_range"])
    var defending_at := Vector2i(2+dist,3)
    var defender: Dictionary = soldier(defender_role,1,defending_at,defense_level)
    if defender.is_empty():
        return {"valid":false}
    var tiles: Array = terrain_at(kind,defending_at)
    var preview: Dictionary = Battle.preview_exchange(attacker,defender,true,tiles,{},[attacker,defender])
    if not bool(preview.get("valid",false)):
        return {"valid":false}
    var modifiers: Dictionary = Terrain.modifiers(attacker,defender,tiles,{},[attacker,defender])
    var attack: int = int(attacker["attack"])+int(modifiers["attack_bonus"])
    var raw: int = Combat.damage(attack+Roles.role_bonus(attacker,defender),
        int(defender["defense"]),int(modifiers["defense_cover"]))
    return {
        "valid":true,"attacker":attacker,"defender":defender,
        "terrain":kind,"preview":preview,"raw_damage":raw,
        "actual_damage":int(preview["damage"]),
        "target_hp":int(defender["hp"]),
        "counter_damage":int(preview["counter_damage"]),
        "role_bonus":Roles.role_bonus(attacker,defender),
        "cover":int(modifiers["defense_cover"])
    }

static func rounded(value: float, policy: String) -> int:
    match policy:
        "floor":
            return floori(value+0.000001)
        "nearest":
            return floori(value+0.500001)
        "ceil":
            return ceili(value-0.000001)
    return -1

static func modified_damage(raw: int, percent: int, policy: String) -> int:
    if raw <= 0 or policy not in ROUNDING:
        return 0
    # Never introduce zero damage by rounding small active attacks.
    return maxi(1,rounded(float(raw)*(100.0+float(percent))/100.0,policy))

static func attack_percent(faction: String, attacker: Dictionary,
        empowered: bool, stack: String = "replace") -> int:
    if not PROFILES.has(faction) or stack not in STACKING:
        return 0
    var f: Dictionary = PROFILES[faction]
    var passive := 0
    var power := 0
    if faction == "pacto_escarlata":
        passive = int(f["passive_attack"])
        power = int(f["power_attack"])
    if faction == "dominio_turquesa" and str(attacker.get("domain","ground")) == "naval":
        passive = int(f["passive_naval_attack"])
        power = int(f["power_naval_attack"])
    return passive if not empowered else (passive+power if stack == "add" else maxi(passive,power))

static func defense_percent(faction: String, defender: Dictionary,
        empowered: bool, stack: String = "replace") -> int:
    if not PROFILES.has(faction) or stack not in STACKING:
        return 0
    var f: Dictionary = PROFILES[faction]
    var passive := 0
    var power := 0
    if faction == "legion_ambar":
        passive = int(f["passive_damage_reduction"])
        power = int(f["power_damage_reduction"])
    elif faction == "dominio_turquesa" and str(defender.get("domain","ground")) == "naval":
        # Only a naval defense POWER was described; no unapproved passive.
        power = int(f["power_naval_defense"])
    return -passive if not empowered else -(passive+power if stack == "add" else maxi(passive,power))

static func project_duel(situation: Dictionary, faction: String, empowered: bool,
        rounding: String, stack: String = "replace", tech_enabled: bool = false) -> Dictionary:
    if not bool(situation.get("valid",false)) or not PROFILES.has(faction) or rounding not in ROUNDING:
        return {"valid":false}
    var attacker: Dictionary = situation["attacker"]
    var defender: Dictionary = situation["defender"]
    var technology_bonus: int = Tech.armor_bonus(attacker,defender,2) if tech_enabled else 0
    var raw: int = int(situation["raw_damage"])
    if technology_bonus > 0:
        var upgraded: Dictionary = attacker.duplicate(true)
        upgraded["attack"] = int(upgraded["attack"])+technology_bonus
        var modifiers: Dictionary = Terrain.modifiers(upgraded,defender,
            terrain_at(str(situation["terrain"]),defender["pos"]),{},[upgraded,defender])
        raw = Combat.damage(int(upgraded["attack"])+int(modifiers["attack_bonus"])+
            Roles.role_bonus(upgraded,defender),int(defender["defense"]),
            int(modifiers["defense_cover"]))
    var pct_attack: int = attack_percent(faction,attacker,empowered,stack)
    var pct_defense: int = defense_percent(faction,defender,empowered,stack)
    # Separate attack-owner and defense-owner comparisons; do not combine
    # unrelated opposing faction bonuses into one artificial duel.
    var outgoing: int = mini(int(defender["hp"]),modified_damage(raw,pct_attack,rounding))
    var incoming: int = mini(int(defender["hp"]),modified_damage(raw,pct_defense,rounding))
    return {"valid":true,"offense":outgoing,"defense":incoming,"raw":raw,
        "tech_bonus":technology_bonus,"attack_pct":pct_attack,
        "defense_pct":pct_defense,
        "base":mini(int(defender["hp"]),raw),
        "target_hp":int(defender["hp"])}

static func buy_cost(role: String, faction: String, empowered: bool,
        rounding: String, stack: String = "replace") -> Dictionary:
    if not Roles.valid(role) or faction != "confederacion_solar" or rounding not in ROUNDING:
        return {"valid":false}
    var reduction: int = int(PROFILES[faction]["passive_cost_reduction"])
    if empowered:
        var power: int = int(PROFILES[faction]["power_cost_reduction"])
        reduction = reduction+power if stack == "add" else maxi(reduction,power)
    var base: int = Economy.cost(role)
    var discounted: int = rounded(float(base)*(100.0-float(reduction))/100.0,rounding)
    return {"valid":true,"base":base,"discounted":discounted,
        "saving":base-discounted,"reduction_pct":reduction,"eligibility":"unknown"}

static func range_gain(role: String, faction: String, empowered: bool) -> Dictionary:
    if not Roles.valid(role) or faction != "sindicato_violeta":
        return {"valid":false}
    var profile: Dictionary = Roles.PROFILES[role] if Roles.PROFILES.has(role) else Arsenal.profile(role)
    var indirect: bool = role in ["artillery","spg","mlrs"]
    var prior: int = int(profile["attack_range"])
    var increase: int = 1 if empowered and indirect and prior < 8 else 0
    var sample: Dictionary = soldier(role,0,Vector2i(2,3),0)
    var target: Dictionary = soldier("line",1,Vector2i(2+prior+increase,3),0)
    var legal: bool = not sample.is_empty() and not target.is_empty() and Turns.in_attack_range(sample,target)
    if increase > 0:
        sample["attack_range"] = prior+increase
    return {"valid":true,"role":role,"indirect":indirect,
        "before":prior,"after":prior+increase,
        "extra_distance":increase,
        "can_attack_new_distance":increase > 0 and Turns.in_attack_range(sample,target),
        "would_attack_without_power":legal}
