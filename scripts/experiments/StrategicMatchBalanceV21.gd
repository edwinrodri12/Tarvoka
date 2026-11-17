extends RefCounted
class_name TarvokaStrategicMatchBalanceV21

# HONEST STRATEGY LAB: deterministic two-side hot-seat simulation using
# V19's real battle orders, city income, fixed-base capture and purchases.
# It does not enact commander buffs, veteran XP, building-tier unlocks,
# operational camp effects or the real eight-faction multiplayer.
# Three experimental command policies are compared in mirrored positions.
const Orders = preload("res://scripts/experiments/FixedSiteOrdersV19.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")

const STRATEGIES := ["expansion","pressure","armor"]
const MAX_ARMY_PER_SIDE := 12
const MAX_ORDERS_PER_HALF_TURN := 8

static func _dist(a: Vector2i, b: Vector2i) -> int:
    return absi(a.x-b.x)+absi(a.y-b.y)

static func _find(units: Array, uid: String) -> Dictionary:
    for u in units:
        if u is Dictionary and str(u.get("id","")) == uid:
            return u
    return {}

static func _open_cell(terrain: Array, sites: Array, used: Dictionary,
        side: int, preferred_y: int, preferred_x: int) -> Vector2i:
    var size: Vector2i = Rules.map_size(terrain)
    var picked: Vector2i = Vector2i(-1,-1)
    var best := 99999
    for y in range(1,size.y-1):
        for x in range(1,size.x-1):
            var pos := Vector2i(x,y)
            if used.has(pos) or Rules.movement_cost(str(terrain[y][x])) < 0:
                continue
            var blocked := false
            for site in sites:
                if site["pos"] == pos or site.get("capture_pos",site["pos"]) == pos:
                    blocked = true
                    break
            if blocked:
                continue
            # Strict mirror symmetry if terrain itself is mirrored.
            var mirror := Vector2i(size.x-1-x,y)
            if Rules.movement_cost(str(terrain[mirror.y][mirror.x])) < 0 or used.has(mirror):
                continue
            var score: int = absi(x-preferred_x)*8+absi(y-preferred_y)*3
            if score < best:
                best = score
                picked = pos
    return picked

static func start(map_id: int, size: Vector2i, first: int) -> Dictionary:
    if first not in [0,1]:
        return {}
    var terrain: Array = Scenarios.terrain(map_id,size)
    var layout: Dictionary = Sites.layout(terrain)
    if not bool(layout.get("valid",false)):
        return {}
    var army: Array = []
    var used: Dictionary = {}
    var base_roles := ["line","scout","piercer","engineer"]
    var ys := [2,4,5,3]
    var xs := [1,1,2,2]
    for i in range(base_roles.size()):
        var west := _open_cell(terrain,layout["sites"],used,0,
            Scenarios.scale_y(ys[i],size),xs[i])
        if west.x < 0:
            return {}
        var east := Vector2i(size.x-1-west.x,west.y)
        used[west] = true
        used[east] = true
        army.append(Roles.make_unit("A-%d"%i,0,west,str(base_roles[i])))
        army.append(Roles.make_unit("B-%d"%i,1,east,str(base_roles[i])))
    var session: Dictionary = Orders.start(map_id,size,first,army)
    if not bool(session.get("valid",false)):
        return {}
    var original: Dictionary = session.duplicate(true)
    return {"valid":true,"session":session,"original":original,
        "stats":{"turns":[0,0],"orders":[0,0],"moves":[0,0],
            "attacks":[0,0],"damage":[0,0],"kills":[0,0],
            "purchases":[0,0],"recruits_cost":[0,0],
            "purchases_by_role":[{},{}],"captures_city":[0,0],
            "captures_base":[0,0],"income":[0,0],
            "contact_turns":[0,0],"idle_turns":[0,0],
            "factory_turns_blocked":[0,0],"initial_cash":[2500,2500],
            "starting_cities":int(layout["starting_cities_each"]),
            "starting_city_income":int(layout["starting_income_each"]),
            "initial_neutral_cities":int(layout["neutral_cities"]),
            "initial_neutral_bases":int(layout["neutral_producers"])}
    }

static func _count_active(state: Dictionary, side: int) -> int:
    var n := 0
    for u in state["units"]:
        if int(u.get("hp",0)) > 0 and int(u.get("faction",-1)) == side:
            n += 1
    return n

static func _owned(session: Dictionary, side: int, kind: String) -> int:
    var total := 0
    for s in session["world"]["layout"]["sites"]:
        if int(s["owner"]) == side and (kind == "any" or \
                (kind == "city" and str(s["kind"]) == "city") or \
                (kind == "base" and str(s["kind"]) != "city")):
            total += 1
    return total

static func _neutral(session: Dictionary, kind: String) -> int:
    return _owned(session,-1,kind)

static func _record_captures(stats: Dictionary, before: Array,
        after: Array) -> void:
    assert(before.size() == after.size())
    for i in range(before.size()):
        var former: Dictionary = before[i]
        var present: Dictionary = after[i]
        assert(former["pos"] == present["pos"])
        if int(former["owner"]) == int(present["owner"]):
            continue
        var new_owner: int = int(present["owner"])
        if new_owner not in [0,1]:
            continue
        var category: String = "captures_city" if str(present["kind"]) == "city" else "captures_base"
        stats[category][new_owner] += 1

static func _attack(battle: Dictionary, side: int, policy: String) -> Dictionary:
    var session: Dictionary = battle["session"]
    var state: Dictionary = session["world"]["state"]
    var best := {}
    var top := -999999
    for ally in state["units"]:
        if int(ally.get("faction",-1)) != side or not Turns.can_act(ally,side) or \
                not Logistics.can_fire(ally) or int(ally.get("attack",0)) <= 0:
            continue
        for foe in state["units"]:
            if int(foe.get("faction",-1)) == side or int(foe.get("hp",0)) <= 0 or \
                    not Turns.in_attack_range(ally,foe):
                continue
            var impact: Dictionary = Battle.preview_exchange(
                ally,foe,true,state["terrain"],state["economy"],state["units"])
            if not bool(impact.get("valid",false)):
                continue
            var value: int = int(impact["damage"])*12-int(impact["counter_damage"])*7
            if bool(impact["defeated"]):
                value += 140+int(foe.get("attack",0))*3
            if int(ally.get("hp",0)) <= int(impact["counter_damage"]):
                value -= 35
            if policy == "pressure":
                value += 15
            if value > top:
                top = value
                best = {"attacker":str(ally["id"]),"target":str(foe["id"]),
                    "old_hp":int(foe["hp"])}
    if best.is_empty():
        return {"valid":false}
    var hit: Dictionary = Orders.attack(session,str(best["attacker"]),str(best["target"]))
    if not bool(hit.get("valid",false)):
        return {"valid":false}
    var updated: Dictionary = battle.duplicate(true)
    updated["session"] = hit["session"]
    updated["stats"]["orders"][side] += 1
    updated["stats"]["attacks"][side] += 1
    updated["stats"]["damage"][side] += int(hit.get("damage",0))
    var target: Dictionary = _find(updated["session"]["world"]["state"]["units"],str(best["target"]))
    if int(best["old_hp"]) > 0 and int(target.get("hp",0)) == 0:
        updated["stats"]["kills"][side] += 1
    return {"valid":true,"battle":updated,"action":"attack"}

static func _occupied(state: Dictionary, ally: Dictionary) -> Dictionary:
    var blocked: Array[Vector2i] = []
    var transit: Array[Vector2i] = []
    for other in state["units"]:
        if int(other.get("hp",0)) <= 0 or str(other.get("id","")) == str(ally["id"]) or \
                Domains.layer(other) != Domains.layer(ally):
            continue
        if int(other.get("faction",-1)) == int(ally["faction"]):
            transit.append(other["pos"])
        else:
            blocked.append(other["pos"])
    return {"blocked":blocked,"transit":transit}

static func _holding_site(session: Dictionary, ally: Dictionary, side: int) -> bool:
    if not Economy.can_capture(ally):
        return false
    for s in session["world"]["layout"]["sites"]:
        if int(s["owner"]) != side and \
                s.get("capture_pos",s["pos"]) == ally["pos"]:
            return true
    return false

static func _objectives(session: Dictionary, ally: Dictionary,
        side: int, policy: String) -> Array:
    var items: Array = []
    var can_take: bool = Economy.can_capture(ally)
    if can_take:
        for s in session["world"]["layout"]["sites"]:
            if int(s["owner"]) == side:
                continue
            var at: Vector2i = s.get("capture_pos",s["pos"])
            var importance := 0
            if str(s["kind"]) == "city":
                importance = 25 if policy == "expansion" else 11
            else:
                importance = 21 if policy == "expansion" else 15
                if policy == "armor" and str(s["kind"]) == "armor_plant":
                    importance += 10
            items.append({"pos":at,"weight":importance,"kind":"site"})
    for foe in session["world"]["state"]["units"]:
        if int(foe.get("faction",-1)) == side or int(foe.get("hp",0)) <= 0:
            continue
        if Domains.can_attack(ally,foe) and int(ally.get("attack",0)) > 0:
            var priority := 22 if policy == "pressure" else (16 if policy == "armor" else 6)
            items.append({"pos":foe["pos"],"weight":priority,"kind":"enemy",
                "foe":foe})
    return items

static func _move(battle: Dictionary, side: int, policy: String) -> Dictionary:
    var session: Dictionary = battle["session"]
    var state: Dictionary = session["world"]["state"]
    var best: Dictionary = {}
    var best_score := -999999
    for ally in state["units"]:
        if int(ally.get("faction",-1)) != side or not Turns.can_move(ally,side):
            continue
        if _holding_site(session,ally,side):
            continue
        var goals: Array = _objectives(session,ally,side,policy)
        if goals.is_empty():
            continue
        var occ: Dictionary = _occupied(state,ally)
        var possible: Dictionary = Rules.reachable(ally["pos"],
            Logistics.movement_budget(ally),state["terrain"],
            occ["blocked"],Domains.domain(ally),Logistics.road_fast(ally),
            occ["transit"],Weather.from_state(state),Weather.traction(ally))
        for endpoint in possible:
            if endpoint == ally["pos"]:
                continue
            for objective in goals:
                var at: Vector2i = objective["pos"]
                var original_dist: int = _dist(ally["pos"],at)
                var new_dist: int = _dist(endpoint,at)
                var improvement: int = original_dist-new_dist
                var range_factor := 0
                if str(objective["kind"]) == "enemy":
                    var proxy: Dictionary = ally.duplicate(true)
                    proxy["pos"] = endpoint
                    if Turns.in_attack_range(proxy,objective["foe"]) and \
                            not bool(ally.get("acted",false)):
                        range_factor = 110
                elif endpoint == at:
                    range_factor = 140
                if improvement <= 0 and range_factor <= 0:
                    continue
                var value: int = (improvement*16-new_dist+
                    int(objective["weight"])+range_factor)
                if str(objective["kind"]) == "site" and policy == "expansion":
                    value += 45
                if str(objective["kind"]) == "enemy" and policy == "pressure":
                    value += 45
                # Keep artillery from pushing adjacent to a foe merely to
                # increase distance; a valid firing lane is preferable.
                if str(objective["kind"]) == "enemy" and \
                        not Turns.in_attack_range(ally,objective["foe"]) and \
                        range_factor == 0 and int(ally["attack_min_range"]) > 1:
                    value -= 8
                if value > best_score:
                    best_score = value
                    best = {"unit":str(ally["id"]),"cell":endpoint}
    if best.is_empty():
        return {"valid":false}
    var moved: Dictionary = Orders.move(session,str(best["unit"]),best["cell"])
    if not bool(moved.get("valid",false)):
        return {"valid":false}
    var updated: Dictionary = battle.duplicate(true)
    updated["session"] = moved["session"]
    updated["stats"]["orders"][side] += 1
    updated["stats"]["moves"][side] += 1
    return {"valid":true,"battle":updated,"action":"move"}

static func _wishlist(policy: String, kind: String) -> Array:
    if kind == "factory":
        if policy == "expansion":
            return ["line","scout","assault"]
        return ["assault","line","engineer"]
    if kind == "armor_plant":
        match policy:
            "expansion": return ["apc","piercer"]
            "pressure": return ["piercer","ifv"]
            "armor": return ["tank","ifv","piercer"]
    if kind == "artillery_depot":
        return ["artillery","spg"] if policy == "expansion" else ["spg","artillery"]
    if kind == "drone_center":
        return ["uav_recon"] if policy == "expansion" else ["fpv"]
    if kind == "airbase":
        return ["attack_heli"] if policy != "expansion" else ["uav_recon"]
    if kind == "shipyard":
        return ["patrol","missile_boat"]
    return []

static func _purchase(battle: Dictionary, side: int, policy: String,
        options: Dictionary = {}) -> Dictionary:
    var session: Dictionary = battle["session"]
    var state: Dictionary = session["world"]["state"]
    if _count_active(state,side) >= MAX_ARMY_PER_SIDE:
        return {"valid":false}
    var money: int = int(state["economy"]["credits"][side])
    var candidates: Array = []
    var occupied: Dictionary = {}
    for unit in state["units"]:
        if int(unit.get("hp",0)) > 0 and Domains.layer(unit) == "surface":
            occupied[unit["pos"]] = true
    for site in session["world"]["layout"]["sites"]:
        if str(site["kind"]) == "city" or int(site["owner"]) != side or \
                int(site.get("produced_turn",-1)) == int(state["economy"]["turn"]):
            continue
        for role in _wishlist(policy,str(site["kind"])):
            if Economy.producer_for(str(role),true) != str(site["kind"]):
                continue
            # Optional v22 LAB restriction: tank/IFV require level II on this
            # exact owned armor plant. The legacy v21 default remains open.
            if bool(options.get("gate_armor_level2",false)) and \
                    str(site["kind"]) == "armor_plant" and str(role) in ["tank","ifv"]:
                var cell: Vector2i = site["pos"]
                var key: String = "%d:%d" % [cell.x,cell.y]
                var levels: Dictionary = options.get("armor_levels",{})
                if int(levels.get(key,1)) < 2:
                    continue
            var cost: int = Economy.cost(str(role))
            if cost > money:
                continue
            var keep: int = 150 if policy == "armor" else 50
            if cost+keep > money:
                continue
            var bonus := 0
            if policy == "expansion" and Economy.can_capture(Roles.make_unit(
                    "PLANNED",side,site["pos"],str(role))):
                bonus += 40
            if policy == "armor" and str(role) == "tank":
                bonus += 50
            if policy == "pressure" and str(role) == "piercer":
                bonus += 35
            # Prefer a facility that is farther toward the front; no fake
            # constructed producers or free access to an enemy's base.
            var dims: Vector2i = Rules.map_size(state["terrain"])
            var forward := int(site["pos"].x) if side == 0 else dims.x-1-int(site["pos"].x)
            candidates.append({"pos":site["pos"],"role":str(role),
                "score":bonus+forward+cost/50,"cost":cost})
            break
    if candidates.is_empty():
        return {"valid":false}
    candidates.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        return int(a["score"]) > int(b["score"]))
    for candidate in candidates:
        var order: Dictionary = Orders.purchase(session,candidate["pos"],str(candidate["role"]))
        if not bool(order.get("valid",false)):
            continue
        var result: Dictionary = battle.duplicate(true)
        result["session"] = order["session"]
        result["stats"]["orders"][side] += 1
        result["stats"]["purchases"][side] += 1
        result["stats"]["recruits_cost"][side] += int(order["cost"])
        var by_role: Dictionary = result["stats"]["purchases_by_role"][side]
        var role: String = str(candidate["role"])
        by_role[role] = int(by_role.get(role,0))+1
        return {"valid":true,"battle":result,"action":"purchase"}
    return {"valid":false}

static func play_half_turn(battle: Dictionary, policy: String,
        options: Dictionary = {}) -> Dictionary:
    if not bool(battle.get("valid",false)) or policy not in STRATEGIES:
        return {"valid":false}
    var current: Dictionary = battle.duplicate(true)
    var side: int = int(current["session"]["world"]["state"]["faction"])
    if int(current["session"]["world"]["state"]["winner"]) != -1:
        return {"valid":false}
    var initial_attacks: int = int(current["stats"]["attacks"][side])
    var initial_orders: int = int(current["stats"]["orders"][side])
    if not bool(options.get("skip_purchase",false)):
        var taken: Dictionary = _purchase(current,side,policy,options)
        if bool(taken.get("valid",false)):
            current = taken["battle"]
    for i in range(MAX_ORDERS_PER_HALF_TURN):
        if int(current["session"]["world"]["state"]["winner"]) != -1:
            break
        var hit: Dictionary = _attack(current,side,policy)
        if bool(hit.get("valid",false)):
            current = hit["battle"]
            continue
        var moved: Dictionary = _move(current,side,policy)
        if bool(moved.get("valid",false)):
            current = moved["battle"]
            continue
        break
    if int(current["stats"]["attacks"][side]) > initial_attacks:
        current["stats"]["contact_turns"][side] += 1
    if int(current["stats"]["orders"][side]) == initial_orders:
        current["stats"]["idle_turns"][side] += 1
    # A lethal Session.attack can decide the match DURING this phase. Do not
    # call Session.end_turn after victory; its authoritative API rejects it.
    if int(current["session"]["world"]["state"].get("winner",-1)) in [0,1]:
        current["stats"]["turns"][side] += 1
        return {"valid":true,"battle":current}
    var before: Array = current["session"]["world"]["layout"]["sites"].duplicate(true)
    var next_side: int = 1-side
    var cash_next: int = int(current["session"]["world"]["state"]["economy"]["credits"][next_side])
    var ended: Dictionary = Orders.end_turn(current["session"])
    if not bool(ended.get("valid",false)):
        return {"valid":false}
    current["session"] = ended["session"]
    current["stats"]["turns"][side] += 1
    _record_captures(current["stats"],before,
        current["session"]["world"]["layout"]["sites"])
    var after_cash: int = int(current["session"]["world"]["state"]["economy"]["credits"][next_side])
    if after_cash > cash_next:
        current["stats"]["income"][next_side] += after_cash-cash_next
    return {"valid":true,"battle":current}

static func snapshot(battle: Dictionary, policies: Array, first: int) -> Dictionary:
    var session: Dictionary = battle["session"]
    var state: Dictionary = session["world"]["state"]
    var score: Dictionary = {}
    for side in [0,1]:
        score[str(side)] = {
            "policy":str(policies[side]),
            "moves":int(battle["stats"]["moves"][side]),
            "attacks":int(battle["stats"]["attacks"][side]),
            "damage":int(battle["stats"]["damage"][side]),
            "kills":int(battle["stats"]["kills"][side]),
            "purchases":int(battle["stats"]["purchases"][side]),
            "purchases_by_role":battle["stats"]["purchases_by_role"][side].duplicate(true),
            "spent":int(battle["stats"]["recruits_cost"][side]),
            "city_captures":int(battle["stats"]["captures_city"][side]),
            "base_captures":int(battle["stats"]["captures_base"][side]),
            "cities":_owned(session,side,"city"),
            "bases":_owned(session,side,"base"),
            "live_units":_count_active(state,side),
            "cash":int(state["economy"]["credits"][side]),
            "income":int(battle["stats"]["income"][side]),
            "turns":int(battle["stats"]["turns"][side]),
            "contact_turns":int(battle["stats"]["contact_turns"][side]),
            "idle_turns":int(battle["stats"]["idle_turns"][side])
        }
    var winner: int = int(state.get("winner",-1))
    return {"winner":winner,"first":first,"decided":winner in [0,1],
        "censored":winner == -1,"halfturns":int(battle["stats"]["turns"][0])+int(battle["stats"]["turns"][1]),
        "initial_cities_each":int(battle["stats"]["starting_cities"]),
        "initial_income_each":int(battle["stats"]["starting_city_income"]),
        "neutral_cities_start":int(battle["stats"]["initial_neutral_cities"]),
        "neutral_bases_start":int(battle["stats"]["initial_neutral_bases"]),
        "neutral_cities_end":_neutral(session,"city"),
        "neutral_bases_end":_neutral(session,"base"),
        "sides":score}

static func duel(map_id: int, size: Vector2i, first: int,
        policies: Array, halfturn_limit: int = 40) -> Dictionary:
    if policies.size() != 2 or str(policies[0]) not in STRATEGIES or \
            str(policies[1]) not in STRATEGIES or halfturn_limit < 2:
        return {"valid":false}
    var current: Dictionary = start(map_id,size,first)
    if not bool(current.get("valid",false)):
        return {"valid":false,"reason":"startup_failed"}
    for i in range(halfturn_limit):
        if int(current["session"]["world"]["state"].get("winner",-1)) in [0,1]:
            break
        var side: int = int(current["session"]["world"]["state"]["faction"])
        var result: Dictionary = play_half_turn(current,str(policies[side]))
        if not bool(result.get("valid",false)):
            return {"valid":false,"reason":"illegal_action_or_turn","halfturn":i}
        current = result["battle"]
    var report: Dictionary = snapshot(current,policies,first)
    report["valid"] = true
    report["map_id"] = map_id
    report["map_size"] = "%dx%d" % [size.x,size.y]
    report["limit"] = halfturn_limit
    return report
