extends RefCounted
class_name TarvokaIntegratedBalanceBattleV16

# BALANCE LAB: three experimental systems over legitimate BattleSession
# actions. Cities >4 are a SIDECAR ledger, never injected into core Economy.
# Real movement/attack/purchase and turn upkeep remain authoritative.
# This is NOT a playable/saveable Android ruleset or production AI.
const City = preload("res://scripts/experiments/CityDensityV14.gd")
const XP = preload("res://scripts/experiments/UnitVeterancyV14.gd")
const Tier = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")

const HOLD_PHASES := 2
const XP_HIT := 9
const XP_KILL := 12
const XP_COUNTER := 5
const XP_CAPTURE := 15
const STRATEGIES := ["mass","technology"]

static func setup(map_id: int, size: Vector2i, cities: int, first: int) -> Dictionary:
    if first not in [0,1] or cities not in City.CITY_COUNTS:
        return {"valid":false}
    var terrain: Array = Scenarios.terrain(map_id,size)
    if not Rules.valid_terrain(terrain):
        return {"valid":false}
    var layout: Dictionary = City.layout(terrain,cities)
    if not bool(layout.get("valid",false)):
        return {"valid":false}
    var army: Array = []
    for side in [0,1]:
        var flank: int = 1 if side == 0 else size.x-2
        var second: int = 2 if side == 0 else size.x-3
        var units: Array = [
            {"role":"line","pos":Vector2i(flank,Scenarios.scale_y(2,size))},
            {"role":"scout","pos":Vector2i(flank,Scenarios.scale_y(4,size))},
            {"role":"piercer","pos":Vector2i(second,Scenarios.scale_y(5,size))}
        ]
        for index in range(units.size()):
            var cell: Vector2i = units[index]["pos"]
            if not Rules.inside(cell,terrain) or Rules.movement_cost(str(terrain[cell.y][cell.x])) < 0:
                return {"valid":false}
            army.append(Roles.make_unit("S%d-%d" % [side,index],
                side,cell,str(units[index]["role"])))
    var state: Dictionary = Session.start(army,terrain,first,false,false,true,true,false)
    if not state.has("economy") or not Economy.valid(state["economy"],terrain):
        return {"valid":false}
    return {"valid":true,"state":state,"cities":layout["economy"].duplicate(true),
        "city_count":cities,"tiers":{},"xp":{},"holds":{},
        "metrics":{"attacks":0,"damage":0,"kills":0,"promotions":0,
            "captures":0,"capture_interruptions":0,"production":0,
            "upgrades":0,"research":0,"spent":0,"actions":0,
            "moves":0,"income":[0,0],"turns":0,
            "purchases_mass":0,"purchases_advanced":0}}

static func _find(units: Array, target: String) -> Dictionary:
    for unit in units:
        if unit is Dictionary and str(unit.get("id","")) == target:
            return unit
    return {}

static func level(xp_value: int) -> int:
    var result := 0
    for i in range(1,4):
        if xp_value >= XP.next_xp(i):
            result = i
    return result

static func _grant(battle: Dictionary, identifier: String, points: int) -> void:
    if points <= 0 or identifier.is_empty():
        return
    var unit: Dictionary = _find(battle["state"]["units"],identifier)
    if unit.is_empty() or int(unit.get("hp",0)) <= 0:
        return
    var role: String = str(unit.get("role",""))
    if not XP.available(role):
        return
    var previous: int = int(battle["xp"].get(identifier,0))
    var updated: int = mini(80,previous+points)
    battle["xp"][identifier] = updated
    var before: int = level(previous)
    var after: int = level(updated)
    if after <= before:
        return
    var current: Dictionary = XP.totals(role,after)
    var last: Dictionary = XP.totals(role,before)
    for key in XP.FIELDS:
        var gain: int = int(current[key])-int(last[key])
        if gain > 0:
            unit[key] = int(unit[key])+gain
    battle["metrics"]["promotions"] += after-before

static func attack(battle: Dictionary, shooter: String, target: String) -> Dictionary:
    var source: Dictionary = battle["state"]
    var current: Dictionary = _find(source["units"],target)
    var old_hp: int = int(current.get("hp",0))
    var action: Dictionary = Tier.attack(source,battle["tiers"],shooter,target)
    if not bool(action.get("valid",false)):
        return {"valid":false,"battle":battle}
    var result: Dictionary = battle.duplicate(true)
    result["state"] = action["state"]
    result["metrics"]["attacks"] += 1
    result["metrics"]["actions"] += 1
    result["metrics"]["damage"] += int(action.get("damage",0))
    var killed: bool = old_hp > 0 and int(_find(result["state"]["units"],target).get("hp",0)) == 0
    if killed:
        result["metrics"]["kills"] += 1
    _grant(result,shooter,XP_HIT+(XP_KILL if killed else 0))
    if int(action.get("counter_damage",0)) > 0:
        _grant(result,target,XP_COUNTER)
    return {"valid":true,"battle":result,"action":"attack",
        "damage":int(action.get("damage",0)),"killed":killed}

static func _update_capture(battle: Dictionary, old_active_side: int) -> void:
    var holding: Dictionary = battle["holds"]
    for city in battle["cities"]["sites"]:
        if str(city.get("kind","")) != "city":
            continue
        var cell: Vector2i = city["pos"]
        var key: String = "%d:%d" % [cell.x,cell.y]
        var soldier: Dictionary = {}
        for u in battle["state"]["units"]:
            if int(u.get("faction",-1)) == old_active_side and u.get("pos") == cell and Economy.can_capture(u):
                soldier = u
                break
        if soldier.is_empty() or int(city.get("owner",-1)) == old_active_side:
            # The opposing side's HALF-TURN must not reset a capturer's
            # pending 2-OWN-phase occupation merely by passing its turn.
            # A defender re-occupying a contested town does interrupt it.
            if holding.has(key):
                var pending: Dictionary = holding[key]
                if int(pending.get("side",-1)) == old_active_side or                         (not soldier.is_empty() and int(city.get("owner",-1)) == old_active_side):
                    holding.erase(key)
                    battle["metrics"]["capture_interruptions"] += 1
            continue
        var progress: Dictionary = holding.get(key,{})
        var old_points: int = 0
        if str(progress.get("unit_id","")) == str(soldier["id"]) and int(progress.get("side",-1)) == old_active_side:
            old_points = int(progress.get("points",0))
        elif not progress.is_empty():
            battle["metrics"]["capture_interruptions"] += 1
        var points: int = old_points+1
        if points >= HOLD_PHASES:
            city["owner"] = old_active_side
            holding.erase(key)
            battle["metrics"]["captures"] += 1
            _grant(battle,str(soldier["id"]),XP_CAPTURE)
        else:
            holding[key] = {"side":old_active_side,"unit_id":str(soldier["id"]),"points":points}

static func advance(battle: Dictionary) -> Dictionary:
    var source: Dictionary = battle["state"]
    if int(source.get("winner",-1)) in [0,1]:
        return {"valid":false,"battle":battle}
    var side: int = int(source["faction"])
    var incoming: int = 1-side
    var incoming_cash: int = int(source["economy"]["credits"][incoming])
    var result: Dictionary = battle.duplicate(true)
    # Resolve extra cities and award XP before checking the next turn.
    _update_capture(result,side)
    var ended: Dictionary = Tier.end_turn(result["state"],result["tiers"])
    if not bool(ended.get("valid",false)):
        return {"valid":false,"battle":battle}
    result["state"] = ended["state"]
    result["tiers"] = ended["progress"]
    result["metrics"]["turns"] += 1
    if int(result["state"].get("winner",-1)) in [0,1]:
        return {"valid":true,"battle":result}
    # The official end_turn gave 250 per base city. Replace that amount
    # instead of ADDING distributed income, preventing hidden inflation.
    var distributed: int = City.income(result["cities"],incoming,int(result["city_count"]))
    var money: int = mini(Economy.MAX_CREDITS,incoming_cash+distributed)
    result["state"]["economy"]["credits"][incoming] = money
    result["metrics"]["income"][incoming] += money-incoming_cash
    # The four official cities are only a compatibility proxy. Enforce the
    # same owner as the sidecar's 2-own-turn capture model. Do not add extra
    # city sites to the core state (MAX_SITES validator must stay intact).
    for site in result["state"]["economy"]["sites"]:
        if str(site.get("kind","")) != "city":
            continue
        for lab_site in result["cities"]["sites"]:
            if str(lab_site.get("kind","")) == "city" and lab_site["pos"] == site["pos"]:
                site["owner"] = int(lab_site["owner"])
                break
    if not Economy.valid(result["state"]["economy"],result["state"]["terrain"]):
        return {"valid":false,"battle":battle}
    return {"valid":true,"battle":result}

static func _plant(battle: Dictionary, side: int) -> Vector2i:
    for site in battle["state"]["economy"]["sites"]:
        if str(site.get("kind","")) == "armor_plant" and int(site.get("owner",-1)) == side:
            return site["pos"]
    return Vector2i(-1,-1)

static func _unblock_plant(battle: Dictionary, cell: Vector2i, side: int) -> Dictionary:
    var occupant: Dictionary = {}
    for unit in battle["state"]["units"]:
        if int(unit.get("hp",0)) > 0 and unit.get("pos") == cell and Domains.layer(unit) == "ground":
            occupant = unit
            break
    if occupant.is_empty() or int(occupant.get("faction",-1)) != side or not Turns.can_move(occupant,side):
        return {"valid":false,"battle":battle}
    var destination: Vector2i = cell+Vector2i(1 if side == 0 else -1,0)
    var action: Dictionary = Session.move(battle["state"],str(occupant["id"]),destination)
    if not bool(action.get("valid",false)):
        return {"valid":false,"battle":battle}
    var changed: Dictionary = battle.duplicate(true)
    changed["state"] = action["state"]
    changed["metrics"]["moves"] += 1
    changed["metrics"]["actions"] += 1
    return {"valid":true,"battle":changed,"action":"clear_producer"}

static func _apply_economy(battle: Dictionary, order: Dictionary) -> Dictionary:
    if not bool(order.get("valid",false)):
        return {"valid":false,"battle":battle}
    var updated: Dictionary = battle.duplicate(true)
    updated["state"] = order["state"]
    updated["tiers"] = order["progress"]
    updated["metrics"]["spent"] += int(order.get("cost",0))
    updated["metrics"]["actions"] += 1
    match str(order.get("action","")):
        "upgrade":
            updated["metrics"]["upgrades"] += 1
        "research":
            updated["metrics"]["research"] += 1
        _:
            updated["metrics"]["production"] += 1
    return {"valid":true,"battle":updated,"action":str(order.get("action",""))}

static func producer_action(battle: Dictionary, policy: String) -> Dictionary:
    if policy not in STRATEGIES:
        return {"valid":false,"battle":battle}
    var side: int = int(battle["state"]["faction"])
    var plant: Vector2i = _plant(battle,side)
    if plant.x < 0:
        return {"valid":false,"battle":battle}
    var state: Dictionary = battle["state"]
    var trail: Dictionary = battle["tiers"]
    var level_now: int = Tier.level_for(state,trail,plant)
    if policy == "mass":
        if Tier.can_recruit(state,trail,plant,"apc"):
            return _apply_economy(battle,Tier.recruit(state,trail,plant,"apc"))
        return _unblock_plant(battle,plant,side)
    if level_now == 1 and Tier.can_upgrade(state,trail,plant):
        return _apply_economy(battle,Tier.upgrade(state,trail,plant))
    if level_now == 2:
        var tank_count := 0
        for unit in state["units"]:
            if int(unit.get("faction",-1)) == side and int(unit.get("hp",0)) > 0 and str(unit.get("role","")) == "tank":
                tank_count += 1
        if tank_count == 0:
            if Tier.can_recruit(state,trail,plant,"tank"):
                return _apply_economy(battle,Tier.recruit(state,trail,plant,"tank"))
            return _unblock_plant(battle,plant,side)
        if Tier.can_upgrade(state,trail,plant):
            return _apply_economy(battle,Tier.upgrade(state,trail,plant))
    if level_now == 3 and not Tier.has_tech(trail,side,"antiarmor_v1"):
        if Tier.can_research(state,trail,plant,"antiarmor_v1"):
            return _apply_economy(battle,Tier.research(state,trail,plant,"antiarmor_v1"))
    if level_now == 3 and Tier.can_recruit(state,trail,plant,"piercer"):
        return _apply_economy(battle,Tier.recruit(state,trail,plant,"piercer"))
    return _unblock_plant(battle,plant,side)

static func combat_action(battle: Dictionary) -> Dictionary:
    var state: Dictionary = battle["state"]
    var side: int = int(state["faction"])
    var best := {}
    var score := -99999
    for ally in state["units"]:
        if int(ally.get("faction",-1)) != side or not Turns.can_act(ally,side) or not Logistics.can_fire(ally):
            continue
        for enemy in state["units"]:
            if int(enemy.get("faction",-1)) == side or int(enemy.get("hp",0)) <= 0 or not Turns.in_attack_range(ally,enemy):
                continue
            var hit: Dictionary = Battle.preview_exchange(ally,enemy,true,
                state["terrain"],state["economy"],state["units"])
            if not bool(hit.get("valid",false)):
                continue
            var points: int = int(hit["damage"])*10-int(hit["counter_damage"])*5
            if bool(hit.get("defeated",false)):
                points += 200
            if points > score:
                score = points
                best = {"attacker":str(ally["id"]),"defender":str(enemy["id"])}
    if best.is_empty():
        return {"valid":false,"battle":battle}
    return attack(battle,str(best["attacker"]),str(best["defender"]))

static func city_action(battle: Dictionary) -> Dictionary:
    var state: Dictionary = battle["state"]
    var side: int = int(state["faction"])
    var best := {}
    var score := -99999
    var occupied: Array[Vector2i] = []
    for unit in state["units"]:
        if int(unit.get("hp",0)) > 0 and Domains.layer(unit) == "ground":
            occupied.append(unit["pos"])
    for ally in state["units"]:
        if int(ally.get("faction",-1)) != side or not Economy.can_capture(ally) or not Turns.can_move(ally,side):
            continue
        var origin: Vector2i = ally["pos"]
        var others: Array[Vector2i] = occupied.duplicate()
        others.erase(origin)
        var reachable: Dictionary = Rules.reachable(origin,int(ally["move_points"]),
            state["terrain"],others)
        for city in battle["cities"]["sites"]:
            if str(city.get("kind","")) != "city" or int(city.get("owner",-1)) == side:
                continue
            var target: Vector2i = city["pos"]
            # Holding position for two successive OWN phases is required.
            if origin == target:
                continue
            var original_distance: int = absi(origin.x-target.x)+absi(origin.y-target.y)
            for cell in reachable:
                if cell == origin or cell in others:
                    continue
                var next_distance: int = absi(cell.x-target.x)+absi(cell.y-target.y)
                if next_distance >= original_distance:
                    continue
                var points: int = (original_distance-next_distance)*30-next_distance*3
                if cell == target:
                    points += 400
                if points > score:
                    best = {"unit":str(ally["id"]),"cell":cell}
                    score = points
    if best.is_empty():
        return {"valid":false,"battle":battle}
    var move: Dictionary = Session.move(state,str(best["unit"]),best["cell"])
    if not bool(move.get("valid",false)):
        return {"valid":false,"battle":battle}
    var changed: Dictionary = battle.duplicate(true)
    changed["state"] = move["state"]
    changed["metrics"]["moves"] += 1
    changed["metrics"]["actions"] += 1
    return {"valid":true,"battle":changed,"action":"advance_to_city"}

static func turn(battle: Dictionary, policy: String, actions: int = 6) -> Dictionary:
    if policy not in STRATEGIES or actions < 1 or actions > 20:
        return {"valid":false,"battle":battle}
    var current: Dictionary = battle.duplicate(true)
    # Only once per phase may this policy attempt to invest. Subsequent
    # actions prioritize real combat and cities, not unlimited production.
    var invested: Dictionary = producer_action(current,policy)
    if bool(invested.get("valid",false)):
        current = invested["battle"]
        # Clearing an occupied plant makes one additional legal purchase
        # available, but never more than one producer slot per phase.
        if str(invested.get("action","")) == "clear_producer":
            var follow: Dictionary = producer_action(current,policy)
            if bool(follow.get("valid",false)):
                current = follow["battle"]
    for i in range(actions):
        if int(current["state"].get("winner",-1)) >= 0:
            break
        var combat: Dictionary = combat_action(current)
        if bool(combat.get("valid",false)):
            current = combat["battle"]
            continue
        var city_move: Dictionary = city_action(current)
        if bool(city_move.get("valid",false)):
            current = city_move["battle"]
            continue
        break
    return advance(current)
