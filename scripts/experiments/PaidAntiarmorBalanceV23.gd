extends RefCounted
class_name TarvokaPaidAntiarmorBalanceV23

# ISOLATED BALANCE LAB; NEVER A SHIPPING RULE OR A SAVE MIGRATION.
# Tank owners pay 650 to unlock their armor plant LII (V22). Pressure
# owners optionally pay for LII (650), LIII (1050), and antiarmor
# research (450) on the SAME captured/owned plant. Research consumes that
# plant's production opportunity; the globally researched +2 is applied
# ONLY to a piercer initiating a LEGAL hit on a LAND VEHICLE in the
# explicit RoleSpecializationV08 whitelist. Actual attack and counter
# fire use authoritative BattleSession and spend real ammunition.
const Tank = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Tier = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const V08 = preload("res://scripts/experiments/RoleSpecializationV08.gd")

const MODES := ["control","researched"]
const TECH := "antiarmor_v1"
const MIN_RESERVE := 150

static func _key(cell: Vector2i) -> String:
    return Tank._key(cell)

static func _price_for_level(level: int) -> int:
    return int(Tier.UPGRADE_COSTS["armor_plant"].get(level,0))

static func start(map_id: int, size: Vector2i, first: int) -> Dictionary:
    var b: Dictionary = Tank.begin(map_id,size,first)
    if not bool(b.get("valid",false)):
        return {}
    b["antiarmor_lab"] = {
        "researched":[false,false],
        "spent":[0,0],
        "research_count":[0,0],
        "research_halfturn":[-1,-1],
        "level3_upgrades":[0,0],
        "saving_turns":[0,0]
    }
    b["stats"]["tech_attacks"] = [0,0]
    b["stats"]["tech_bonus_damage"] = [0,0]
    b["stats"]["tech_ammo_spent"] = [0,0]
    b["stats"]["tech_counters_taken"] = [0,0]
    return b

static func _owned_plant(b: Dictionary, side: int) -> Dictionary:
    for site in b["session"]["world"]["layout"]["sites"]:
        if str(site.get("kind","")) == "armor_plant" and \
                int(site.get("owner",-1)) == side:
            return site
    return {}

static func _can_spend(b: Dictionary, side: int, site: Dictionary, price: int) -> bool:
    var state: Dictionary = b["session"]["world"]["state"]
    return side == int(state["faction"]) and price > 0 and \
        int(state["economy"]["credits"][side]) >= price+MIN_RESERVE and \
        int(site.get("produced_turn",-1)) != int(state["economy"]["turn"])

static func _pay_and_lock(b: Dictionary, side: int, site: Dictionary, price: int) -> Dictionary:
    var result: Dictionary = b.duplicate(true)
    var cash: int = int(result["session"]["world"]["state"]["economy"]["credits"][side])
    assert(cash >= price+MIN_RESERVE)
    result["session"]["world"]["state"]["economy"]["credits"][side] = cash-price
    var locked := false
    for owned in result["session"]["world"]["layout"]["sites"]:
        if owned["pos"] == site["pos"] and \
                str(owned["kind"]) == "armor_plant" and int(owned["owner"]) == side:
            owned["produced_turn"] = int(result["session"]["world"]["state"]["economy"]["turn"])
            locked = true
            break
    assert(locked)
    result["stats"]["orders"][side] += 1
    return result

static func _develop(b: Dictionary, side: int) -> Dictionary:
    if bool(b["antiarmor_lab"]["researched"][side]):
        return {"valid":false}
    var plant: Dictionary = _owned_plant(b,side)
    if plant.is_empty():
        return {"valid":false}
    var level: int = Tank.level_for(b,plant)
    if level == 1:
        # Reuses the already audited paid upgrade; this is not a
        # fabricated tier-two level with no building downtime.
        var first: Dictionary = Tank._upgrade(b,side)
        if not bool(first.get("valid",false)):
            return {"valid":false}
        return {"valid":true,"battle":first["battle"],"action":"level2"}
    if level == 2:
        var price: int = _price_for_level(3)
        if not _can_spend(b,side,plant,price):
            return {"valid":false}
        var improved: Dictionary = _pay_and_lock(b,side,plant,price)
        improved["unlock_lab"]["levels"][_key(plant["pos"])] = {
            "owner":side,"level":3}
        improved["unlock_lab"]["upgrades"][side] += 1
        improved["unlock_lab"]["upgrade_spent"][side] += price
        improved["antiarmor_lab"]["level3_upgrades"][side] += 1
        return {"valid":true,"battle":improved,"action":"level3"}
    if level == 3:
        var price: int = int(Tier.TECH_COSTS[TECH])
        if not _can_spend(b,side,plant,price):
            return {"valid":false}
        var learned: Dictionary = _pay_and_lock(b,side,plant,price)
        learned["antiarmor_lab"]["researched"][side] = true
        learned["antiarmor_lab"]["spent"][side] += price
        learned["antiarmor_lab"]["research_count"][side] += 1
        learned["antiarmor_lab"]["research_halfturn"][side] = \
            int(learned["stats"]["turns"][0])+int(learned["stats"]["turns"][1])+1
        return {"valid":true,"battle":learned,"action":"research"}
    return {"valid":false}

static func half_turn(b: Dictionary, policies: Array, mode: String) -> Dictionary:
    if mode not in MODES or policies.size() != 2 or \
            not bool(b.get("valid",false)):
        return {"valid":false}
    var current: Dictionary = b.duplicate(true)
    var side: int = int(current["session"]["world"]["state"]["faction"])
    var policy: String = str(policies[side])
    if policy not in Lab.STRATEGIES:
        return {"valid":false}
    var used_producer := false
    if policy == "pressure" and mode == "researched" and \
            not bool(current["antiarmor_lab"]["researched"][side]):
        var order: Dictionary = _develop(current,side)
        if bool(order.get("valid",false)):
            current = order["battle"]
            used_producer = true
        elif not _owned_plant(current,side).is_empty():
            # Explicit research-minded AI can save credits rather than
            # reinvesting those same credits immediately in new piercers.
            current["antiarmor_lab"]["saving_turns"][side] += 1
            used_producer = true
    var options: Dictionary = {"skip_purchase":used_producer,
        "antiarmor_enabled":bool(current["antiarmor_lab"]["researched"][side])}
    var played: Dictionary = Tank.half_turn(current,policy,"level2",options)
    if not bool(played.get("valid",false)):
        return {"valid":false}
    current = played["battle"]
    assert(int(current["stats"]["tech_ammo_spent"][side]) == \
        int(current["stats"]["tech_attacks"][side]))
    return {"valid":true,"battle":current}

static func duel(map_id: int, size: Vector2i, first: int,
        policies: Array, mode: String, limit: int = 42) -> Dictionary:
    if mode not in MODES or policies.size() != 2 or \
            first not in [0,1] or limit < 2:
        return {"valid":false}
    var b: Dictionary = start(map_id,size,first)
    if not bool(b.get("valid",false)):
        return {"valid":false,"reason":"startup"}
    for half in range(limit):
        if int(b["session"]["world"]["state"].get("winner",-1)) in [0,1]:
            break
        var played: Dictionary = half_turn(b,policies,mode)
        if not bool(played.get("valid",false)):
            return {"valid":false,"reason":"failed_order","halfturn":half}
        b = played["battle"]
    var result: Dictionary = Lab.snapshot(b,policies,first)
    result["mode"] = mode
    result["valid"] = true
    result["map_id"] = map_id
    result["limit"] = limit
    result["size"] = "%dx%d" % [size.x,size.y]
    for side in [0,1]:
        var summary: Dictionary = result["sides"][str(side)]
        summary["plant_upgrades"] = int(b["unlock_lab"]["upgrades"][side])
        summary["plant_upgrade_cost"] = int(b["unlock_lab"]["upgrade_spent"][side])
        summary["tier3_upgrades"] = int(b["antiarmor_lab"]["level3_upgrades"][side])
        summary["research_count"] = int(b["antiarmor_lab"]["research_count"][side])
        summary["research_cost"] = int(b["antiarmor_lab"]["spent"][side])
        summary["research_halfturn"] = int(b["antiarmor_lab"]["research_halfturn"][side])
        summary["tech_active"] = bool(b["antiarmor_lab"]["researched"][side])
        summary["tech_attacks"] = int(b["stats"]["tech_attacks"][side])
        summary["tech_bonus_damage"] = int(b["stats"]["tech_bonus_damage"][side])
        summary["tech_ammo_spent"] = int(b["stats"]["tech_ammo_spent"][side])
        summary["tech_counter_damage"] = int(b["stats"]["tech_counters_taken"][side])
        summary["saving_turns"] = int(b["antiarmor_lab"]["saving_turns"][side])
        summary["total_spent"] = int(summary["spent"])+ \
            int(summary["plant_upgrade_cost"])+int(summary["research_cost"])
        assert(int(summary["cash"]) == Economy.MODERN_START_CREDITS+ \
            int(summary["income"])-int(summary["total_spent"]))
        assert(int(summary["research_cost"]) == \
            int(Tier.TECH_COSTS[TECH])*int(summary["research_count"]))
        assert(int(summary["tech_attacks"]) == int(summary["tech_ammo_spent"]))
        if bool(summary["tech_active"]):
            assert(int(summary["research_count"]) == 1)
            assert(int(summary["plant_upgrades"]) >= 2)
            assert(int(summary["research_halfturn"]) >= 3)
        if mode == "control":
            assert(not bool(summary["tech_active"]))
            assert(int(summary["tech_attacks"]) == 0)
    return result
