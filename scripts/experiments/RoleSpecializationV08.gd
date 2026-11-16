extends RefCounted
class_name TarvokaRoleSpecializationV08

# Opt-in balance LAB. Neither the shipping AI nor live BattleSession calls
# this wrapper. No permanent attack buffs or save schema changes.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")

# Only vehicle-class ground armor, not all ground units, not aircraft/ships.
# A bulwark keeps its already-implemented +4 counter.
const ANTI_ARMOR_ROLES := ["apc","ifv","tank","spg","mlrs","mobile_aa","sam","ew","logistics"]
const REPAIRABLE_ROLES := ["apc","ifv","tank","spg","mlrs","mobile_aa","sam","ew","logistics"]

# Candidate studies, not approved production costs or damage values.
const ARMOR_BONUSES := [0,2,3]
const REPAIR_PACKS := {
    "small":{"hp":2,"credits":60},
    "field":{"hp":3,"credits":100}
}

static func max_hp(unit: Dictionary) -> int:
    var role: String = str(unit.get("role",""))
    if Roles.PROFILES.has(role):
        return int(Roles.PROFILES[role]["hp"])
    if Arsenal.valid(role):
        return int(Arsenal.profile(role)["hp"])
    return 0

static func _find_unit(units: Array, identifier: String) -> Dictionary:
    var matching: Dictionary = {}
    for unit in units:
        if not unit is Dictionary:
            continue
        if str(unit.get("id","")) == identifier:
            if not matching.is_empty():
                return {}
            matching = unit
    return matching

static func _live(state: Dictionary) -> bool:
    return state.has("units") and state["units"] is Array and state.has("terrain") and state["terrain"] is Array and Rules.valid_terrain(state["terrain"]) and state.get("faction",-1) in [0,1] and int(state.get("winner",-1)) == -1

static func armor_bonus(attacker: Dictionary, defender: Dictionary, value: int) -> int:
    if value not in ARMOR_BONUSES:
        return 0
    if str(attacker.get("role","")) != "piercer" or str(defender.get("role","")) not in ANTI_ARMOR_ROLES:
        return 0
    return value

static func preview_antiarmor(attacker: Dictionary, defender: Dictionary,
        value: int, terrain: Array, economy: Dictionary = {},
        units: Array = []) -> Dictionary:
    if value not in ARMOR_BONUSES:
        return {"valid":false}
    var soldier: Dictionary = attacker.duplicate(true)
    soldier["attack"] = int(soldier.get("attack",0))+armor_bonus(attacker,defender,value)
    var visible_units: Array = units.duplicate(true)
    for unit in visible_units:
        if unit is Dictionary and str(unit.get("id","")) == str(attacker.get("id","")):
            unit["attack"] = int(soldier["attack"])
    return Battle.preview_exchange(soldier,defender,true,terrain,economy,visible_units)

# Uses authoritative Session.attack on a disposable copy. The experimental
# attack bonus is removed immediately afterward, so later attacks, saves,
# opponents, armor, money and recruitment still use original rules.
static func attack_antiarmor(state: Dictionary, attacker_id: String,
        defender_id: String, value: int) -> Dictionary:
    var refused := {"valid":false,"state":state.duplicate(true)}
    if value not in ARMOR_BONUSES or not _live(state):
        return refused
    var shooter: Dictionary = _find_unit(state["units"],attacker_id)
    var target: Dictionary = _find_unit(state["units"],defender_id)
    if shooter.is_empty() or target.is_empty():
        return refused
    var plus: int = armor_bonus(shooter,target,value)
    var proposal: Dictionary = state.duplicate(true)
    if plus > 0:
        for unit in proposal["units"]:
            if str(unit.get("id","")) == attacker_id:
                unit["attack"] = int(unit["attack"])+plus
                break
    var result: Dictionary = Session.attack(proposal,attacker_id,defender_id)
    if not bool(result.get("valid",false)):
        return refused
    if plus > 0:
        for unit in result["state"]["units"]:
            if str(unit.get("id","")) == attacker_id:
                unit["attack"] = int(shooter["attack"])
                break
    result["action"] = "attack"
    result["reason"] = "experimental_antivehicle"
    result["temporary_bonus"] = plus
    return result

# Valid, intentionally narrow action: a field engineer gives up its attack
# action to repair an adjacent FRIENDLY damaged GROUND VEHICLE. Two price/HP
# candidates compete with recruiting a replacement. Engineers do not yet
# repair buildings: building hit points are not modeled in UrbanEconomy.
static func field_repair(state: Dictionary, engineer_id: String,
        patient_id: String, pack: String = "small") -> Dictionary:
    var refused := {"valid":false,"state":state.duplicate(true)}
    if not _live(state) or not state.has("economy") or not Economy.valid(state["economy"],state["terrain"]) or not Opening.can_order(state) or not REPAIR_PACKS.has(pack):
        return refused
    var side: int = int(state["faction"])
    var engineer: Dictionary = _find_unit(state["units"],engineer_id)
    var target: Dictionary = _find_unit(state["units"],patient_id)
    if engineer.is_empty() or target.is_empty() or engineer_id == patient_id:
        return refused
    if str(engineer.get("role","")) != "engineer" or not Turns.can_act(engineer,side):
        return refused
    if int(target.get("faction",-1)) != side or int(target.get("hp",0)) <= 0 or str(target.get("role","")) not in REPAIRABLE_ROLES:
        return refused
    if not engineer.get("pos") is Vector2i or not target.get("pos") is Vector2i or not Rules.inside(engineer["pos"],state["terrain"]) or not Rules.inside(target["pos"],state["terrain"]):
        return refused
    var distance: int = absi(engineer["pos"].x-target["pos"].x)+absi(engineer["pos"].y-target["pos"].y)
    if distance != 1:
        return refused
    var limit: int = max_hp(target)
    if limit <= 0 or int(target["hp"]) >= limit:
        return refused
    var plan: Dictionary = REPAIR_PACKS[pack]
    var cost: int = int(plan["credits"])
    if int(state["economy"]["credits"][side]) < cost:
        return refused
    var next: Dictionary = state.duplicate(true)
    var restored: int = mini(int(plan["hp"]),limit-int(target["hp"]))
    for unit in next["units"]:
        if str(unit.get("id","")) == engineer_id:
            unit["acted"] = true
        if str(unit.get("id","")) == patient_id:
            unit["hp"] = int(unit["hp"])+restored
    next["economy"]["credits"][side] = int(next["economy"]["credits"][side])-cost
    # A repair never changes unit coordinates, ownership or fog. It is an
    # action that consumes money and the engineer's remaining attack.
    Opening.record(next)
    return {"valid":true,"state":next,"action":"repair",
        "reason":"experimental_engineer_repair","engineer_id":engineer_id,
        "patient_id":patient_id,"hp_restored":restored,"cost":cost,
        "pack":pack}
