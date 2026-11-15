extends RefCounted
class_name TarvokaBalanceProposalV05

# EXPERIMENT ONLY. These functions are never called by BattleSession or
# BasicAI in the shipping game. A/B harness invokes them deliberately.
# No persistent fields or changed role stats are added to existing saves.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const SupplyStrategy = preload("res://scripts/core/SupplyStrategy.gd")

const DEFERRED_CORE_SUPPORT := ["engineer", "ew", "transport_heli", "landing_ship"]
# Engineer repair already lives in separate draft PR #320 with +3 HP
# and 35 credits/HP, followed by AI paths in dependent draft #323.
# Do not buy engineer based on a duplicate, newly invented repair action.

static func _unit(state: Dictionary, uid: String) -> Dictionary:
    for unit in state.get("units", []):
        if unit is Dictionary and str(unit.get("id", "")) == uid:
            return unit
    return {}

# Proposed Asaltante identity: ignore just the +1 CITY cover on a
# defending ground unit. Native forest/mountain cover remains untouched.
# Temporarily add +1 attack in a throwaway state only during this attack,
# then restore the original stat even for the successful result.
static func urban_assault_attack(state: Dictionary, attacker_id: String,
        defender_id: String) -> Dictionary:
    var attacker: Dictionary = _unit(state, attacker_id)
    var defender: Dictionary = _unit(state, defender_id)
    var eligible: bool = (
        not attacker.is_empty() and not defender.is_empty()
        and str(attacker.get("role", "")) == "assault"
        and Domains.domain(defender) == Domains.GROUND
        and Terrain.city_at(state.get("economy", {}), defender.get("pos", Vector2i(-1,-1)))
    )
    if not eligible:
        var ordinary: Dictionary = Session.attack(state, attacker_id, defender_id)
        ordinary["experimental_urban_pierce"] = false
        return ordinary
    var modified: Dictionary = state.duplicate(true)
    var candidate: Dictionary = _unit(modified, attacker_id)
    candidate["attack"] = int(candidate["attack"]) + 1
    var result: Dictionary = Session.attack(modified, attacker_id, defender_id)
    if not bool(result.get("valid", false)):
        return {"valid":false,"state":state.duplicate(true),"experimental_urban_pierce":false}
    var resulting_unit: Dictionary = _unit(result["state"], attacker_id)
    resulting_unit["attack"] = int(attacker["attack"])
    result["experimental_urban_pierce"] = true
    return result

# Advisor used solely for A/B, not automatically installed into BasicAI.
# Avoid expensive support roles whose ONLY core ability is not implemented.
# Maintain fog-safe enemy knowledge, actual production rules and spending caps.
static func purchase_proposal(state: Dictionary, site_pos: Vector2i) -> Dictionary:
    var none := {"valid":false,"reason":"no_legal_experimental_purchase"}
    if int(state.get("winner",-1)) != -1 or not Opening.can_order(state):
        return none
    var side: int = int(state.get("faction",-1))
    if side not in [0,1] or not state.get("economy") is Dictionary:
        return none
    var site: Dictionary = Economy.site_at(state["economy"],site_pos)
    if site.is_empty() or int(site.get("owner",-1)) != side or str(site.get("kind","")) == "city":
        return none
    var knowledge: Dictionary = Visibility.observed_state(state,side)
    var known_enemies: Array = []
    var counts: Dictionary = {}
    var city_defended_by_enemy := false
    for u in knowledge.get("units",[]):
        if not u is Dictionary or int(u.get("hp",0)) <= 0:
            continue
        if int(u.get("faction",-1)) == side:
            var role: String = str(u.get("role",""))
            counts[role] = int(counts.get(role,0))+1
        else:
            known_enemies.append(u)
            if Terrain.city_at(knowledge.get("economy",{}),u.get("pos",Vector2i(-1,-1))):
                if absi(u["pos"].x-site_pos.x)+absi(u["pos"].y-site_pos.y) <= 6:
                    city_defended_by_enemy = true
    var air_threat := false
    var tank_threat := false
    var bulwark_threat := false
    for enemy in known_enemies:
        air_threat = air_threat or Domains.domain(enemy) == Domains.AIR
        tank_threat = tank_threat or str(enemy.get("role","")) in ["tank","ifv"]
        bulwark_threat = bulwark_threat or str(enemy.get("role","")) == "bulwark"
    var order: Array = []
    match str(site["kind"]):
        "factory":
            if city_defended_by_enemy:
                order = ["assault","line","scout","logistics"]
            else:
                order = ["line","scout","assault","logistics"]
        "armor_plant":
            if bulwark_threat and not tank_threat:
                order = ["piercer","tank","ifv","bulwark","apc"]
            else:
                order = ["tank","ifv","piercer","bulwark","apc"]
        "artillery_depot":
            order = ["mobile_aa","sam","spg","artillery","mlrs"] if air_threat else [
                "spg","artillery","mobile_aa","sam","mlrs"]
        "drone_center":
            order = ["fpv","uav_recon","loitering"]
        "airbase":
            order = ["fighter","attack_heli","ucav","bomber"] if air_threat else [
                "attack_heli","ucav","fighter","bomber"]
        "shipyard":
            order = ["patrol","missile_boat","corvette","frigate",
                "destroyer","submarine","usv"]
        _:
            return none
    var strategy: Dictionary = SupplyStrategy.assess(knowledge,side)
    # A preexisting ground logistics need outranks extra infantry purchases.
    if str(site["kind"]) == "factory" and bool(strategy.get("need_truck",false)):
        order = ["logistics"] + order
    for role in order:
        if role in DEFERRED_CORE_SUPPORT:
            continue
        if not SupplyStrategy.can_spend_on_recruitment(state,side,role,Economy.cost(role),strategy):
            continue
        if not Economy.can_purchase(state,site_pos,role):
            continue
        return {"valid":true,"role":role,"cost":Economy.cost(role),
            "facility":str(site["kind"]),"reason":"experimental_utility_first"}
    return none

static func purchase_experimental(state: Dictionary, site_pos: Vector2i) -> Dictionary:
    var candidate: Dictionary = purchase_proposal(state,site_pos)
    if not bool(candidate.get("valid",false)):
        return {"valid":false,"state":state.duplicate(true),"reason":"hold_resources"}
    var result: Dictionary = Session.purchase(state,site_pos,str(candidate["role"]))
    if bool(result.get("valid",false)):
        result["experimental_reason"] = str(candidate["reason"])
    return result
