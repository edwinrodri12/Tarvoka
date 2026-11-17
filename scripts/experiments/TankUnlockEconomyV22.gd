extends RefCounted
class_name TarvokaTankUnlockEconomyV22

# Experimental A/B only. The two-mode comparison uses authentic V19
# tactical moves, purchases, capture, cost and turns as in V21. A facility
# LEVEL II is a separate experiment-only ledger keyed to POSITION+OWNER.
# This NEVER modifies commercial progression, saves, camps or Android code.
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Progression = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const MODES := ["instant","level2"]
const UPGRADE_MIN_RESERVE := 150

static func _key(pos: Vector2i) -> String:
    return "%d:%d" % [pos.x,pos.y]

static func _cost() -> int:
    return int(Progression.UPGRADE_COSTS["armor_plant"][2])

static func begin(map_id: int, size: Vector2i, first: int) -> Dictionary:
    var b: Dictionary = Lab.start(map_id,size,first)
    if not bool(b.get("valid",false)):
        return {}
    b["unlock_lab"] = {
        "levels":{},
        "upgrades":[0,0],
        "upgrade_spent":[0,0],
        "upgrade_halfturn":[-1,-1],
        "first_tank_halfturn":[-1,-1]
    }
    return b

static func level_for(b: Dictionary, site: Dictionary) -> int:
    var tag: String = _key(site["pos"])
    var record: Dictionary = b["unlock_lab"]["levels"].get(tag,{})
    if int(record.get("owner",-99)) != int(site.get("owner",-1)):
        return 1
    return int(record.get("level",1))

static func _levels_for_side(b: Dictionary, side: int) -> Dictionary:
    var levels: Dictionary = {}
    for site in b["session"]["world"]["layout"]["sites"]:
        if int(site.get("owner",-1)) != side or str(site["kind"]) != "armor_plant":
            continue
        levels[_key(site["pos"])] = level_for(b,site)
    return levels

static func _has_upgraded_plant(b: Dictionary, side: int) -> bool:
    for site in b["session"]["world"]["layout"]["sites"]:
        if str(site["kind"]) == "armor_plant" and \
                int(site.get("owner",-1)) == side and level_for(b,site) >= 2:
            return true
    return false

static func _upgrade(b: Dictionary, side: int) -> Dictionary:
    if _has_upgraded_plant(b,side):
        return {"valid":false}
    var session: Dictionary = b["session"]
    var state: Dictionary = session["world"]["state"]
    var money: int = int(state["economy"]["credits"][side])
    var price: int = _cost()
    if price <= 0 or money < price+UPGRADE_MIN_RESERVE:
        return {"valid":false}
    for site in session["world"]["layout"]["sites"]:
        if str(site["kind"]) != "armor_plant" or \
                int(site.get("owner",-1)) != side or level_for(b,site) >= 2:
            continue
        if int(site.get("produced_turn",-1)) == int(state["economy"]["turn"]):
            continue
        var next: Dictionary = b.duplicate(true)
        next["session"]["world"]["state"]["economy"]["credits"][side] -= price
        var found := false
        for altered in next["session"]["world"]["layout"]["sites"]:
            if altered["pos"] != site["pos"]:
                continue
            altered["produced_turn"] = int(state["economy"]["turn"])
            found = true
            break
        assert(found)
        next["unlock_lab"]["levels"][_key(site["pos"])] = {
            "owner":side,"level":2}
        next["unlock_lab"]["upgrades"][side] += 1
        next["unlock_lab"]["upgrade_spent"][side] += price
        next["stats"]["orders"][side] += 1
        if int(next["unlock_lab"]["upgrade_halfturn"][side]) == -1:
            next["unlock_lab"]["upgrade_halfturn"][side] = \
                int(next["stats"]["turns"][0])+int(next["stats"]["turns"][1])+1
        assert(Economy.valid(next["session"]["world"]["state"]["economy"],
            next["session"]["world"]["state"]["terrain"]))
        return {"valid":true,"battle":next}
    return {"valid":false}

static func half_turn(b: Dictionary, policy: String, mode: String) -> Dictionary:
    if not bool(b.get("valid",false)) or mode not in MODES or \
            policy not in Lab.STRATEGIES:
        return {"valid":false}
    var current: Dictionary = b.duplicate(true)
    var side: int = int(current["session"]["world"]["state"]["faction"])
    var prior_tanks: int = int(
        current["stats"]["purchases_by_role"][side].get("tank",0))
    var skip := false
    if mode == "level2" and policy == "armor":
        var upgraded: Dictionary = _upgrade(current,side)
        if bool(upgraded.get("valid",false)):
            current = upgraded["battle"]
            skip = true
    var opts: Dictionary = {}
    if mode == "level2":
        opts = {"gate_armor_level2":true,
            "armor_levels":_levels_for_side(current,side),
            "skip_purchase":skip}
    var action: Dictionary = Lab.play_half_turn(current,policy,opts)
    if not bool(action.get("valid",false)):
        return {"valid":false}
    current = action["battle"]
    var new_tanks: int = int(
        current["stats"]["purchases_by_role"][side].get("tank",0))
    assert(new_tanks >= prior_tanks)
    if new_tanks > prior_tanks:
        # A tank may be produced only at an owned level-II facility,
        # never by fabricating the role without its site prerequisite.
        if mode == "level2":
            assert(_has_upgraded_plant(current,side))
        if int(current["unlock_lab"]["first_tank_halfturn"][side]) == -1:
            current["unlock_lab"]["first_tank_halfturn"][side] = \
                int(current["stats"]["turns"][0])+int(current["stats"]["turns"][1])
    return {"valid":true,"battle":current}

static func duel(map_id: int, size: Vector2i, first: int, policies: Array,
        mode: String, limit: int = 42) -> Dictionary:
    if policies.size() != 2 or first not in [0,1] or mode not in MODES or \
            limit < 2 or str(policies[0]) not in Lab.STRATEGIES or \
            str(policies[1]) not in Lab.STRATEGIES:
        return {"valid":false}
    var b: Dictionary = begin(map_id,size,first)
    if not bool(b.get("valid",false)):
        return {"valid":false,"reason":"startup"}
    for half in range(limit):
        if int(b["session"]["world"]["state"].get("winner",-1)) in [0,1]:
            break
        var side: int = int(b["session"]["world"]["state"]["faction"])
        var step: Dictionary = half_turn(b,str(policies[side]),mode)
        if not bool(step.get("valid",false)):
            return {"valid":false,"reason":"illegal_state","halfturn":half}
        b = step["battle"]
    var report: Dictionary = Lab.snapshot(b,policies,first)
    report["mode"] = mode
    report["valid"] = true
    report["map_id"] = map_id
    report["map_size"] = "%dx%d" % [size.x,size.y]
    report["limit"] = limit
    for side in [0,1]:
        var item: Dictionary = report["sides"][str(side)]
        item["upgrade_count"] = int(b["unlock_lab"]["upgrades"][side])
        item["upgrade_spent"] = int(b["unlock_lab"]["upgrade_spent"][side])
        item["upgrade_halfturn"] = int(b["unlock_lab"]["upgrade_halfturn"][side])
        item["first_tank_halfturn"] = \
            int(b["unlock_lab"]["first_tank_halfturn"][side])
        item["total_spent"] = int(item["spent"])+int(item["upgrade_spent"])
        assert(int(item["cash"]) == Economy.MODERN_START_CREDITS+
            int(item["income"])-int(item["total_spent"]))
        if mode == "level2" and int(item["purchases_by_role"].get("tank",0)) > 0:
            assert(int(item["upgrade_count"]) >= 1)
            assert(int(item["first_tank_halfturn"]) > \
                int(item["upgrade_halfturn"]))
    return report
