extends RefCounted
class_name TarvokaEngineerSupport

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Repair = preload("res://scripts/core/EngineerRepair.gd")
const TerrainTactics = preload("res://scripts/core/TerrainTactics.gd")

# Opt-in, deterministic SUPPORT route, not an extra repair entitlement:
# a moved engineer can still REPAIR this same phase if the engine says it
# has not acted. Never move toward wounded allies without an economic reason.
const MIN_REPAIR_HP := 2
const MIN_NET_CREDITS := 25
const MAX_ROUTE_COST := 6 # On foot: at most three 2-point phases.
const MIN_SAFE_HP := 3

static func plan(state: Dictionary, observed: Dictionary, engineer: Dictionary) -> Dictionary:
    var none := {"valid":false}
    var side: int = int(state.get("faction",-1))
    if side not in [0,1] or int(state.get("winner",-1)) != -1:
        return none
    if not observed.get("economy") is Dictionary or not observed.get("terrain") is Array:
        return none
    if not bool(observed["economy"].get("modern",false)):
        return none
    if str(engineer.get("role","")) != "engineer" or not Turns.can_move(engineer,side):
        return none
    if bool(engineer.get("moved",true)) or int(engineer.get("hp",0)) < MIN_SAFE_HP:
        return none
    var origin = engineer.get("pos",null)
    var terrain: Array = observed["terrain"]
    if not origin is Vector2i or not Rules.inside(origin,terrain):
        return none
    var credits: int = int(observed["economy"]["credits"][side])
    if credits < Repair.CREDITS_PER_HP*MIN_REPAIR_HP:
        return none
    # Do not abandon an uncaptured city or factory: holding that tile captures
    # it at phase end and can create far more value than a one-off repair.
    for site in observed["economy"].get("sites",[]):
        if site is Dictionary and site.get("pos",null) == origin and int(site.get("owner",-1)) != side:
            return none
    if observed.has("control"):
        for node in observed["control"].get("nodes",[]):
            if node is Dictionary and node.get("pos",null) == origin and int(node.get("owner",-1)) != side:
                return none
    var enemies: Array = []
    var blocked: Array[Vector2i] = []
    var friendly_cells: Array[Vector2i] = []
    var allies: Array = []
    for unit in observed.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        if str(unit.get("id","")) == str(engineer.get("id","")):
            continue
        if int(unit.get("faction",-1)) == side:
            allies.append(unit)
            if Domains.layer(unit) == Domains.layer(engineer):
                friendly_cells.append(unit["pos"])
        else:
            enemies.append(unit)
            if Domains.layer(unit) == Domains.layer(engineer):
                blocked.append(unit["pos"])
    var reach: Dictionary = Rules.reachable(
        origin,Logistics.movement_budget(engineer),terrain,blocked,
        Domains.GROUND,false,friendly_cells,Weather.from_state(observed),
        Weather.traction(engineer))
    if reach.size() < 2:
        return none
    var fog: bool = Visibility.enabled(observed)
    var visible: Dictionary = Visibility.visible_cells(observed,side) if fog else {}
    var best: Dictionary = none
    var best_score := -99999999
    for ally in allies:
        var role: String = str(ally.get("role",""))
        if role not in Repair.REPAIRABLE_CHASSIS or Domains.domain(ally) != Domains.GROUND:
            continue
        var maximum: int = Repair.maximum_hp(role)
        var missing: int = maximum-int(ally.get("hp",0))
        var restored: int = mini(Repair.MAX_HP_PER_ACTION,
            mini(missing,int(credits/Repair.CREDITS_PER_HP)))
        if restored < MIN_REPAIR_HP:
            continue
        var expense: int = restored*Repair.CREDITS_PER_HP
        var replacement_value: int = int(round(
            float(Economy.cost(role))*float(restored)/float(maximum)))
        var margin: int = replacement_value-expense
        if margin < MIN_NET_CREDITS:
            continue
        var target: Vector2i = ally["pos"]
        var straight: int = absi(origin.x-target.x)+absi(origin.y-target.y)
        if straight <= 1 or straight-1 > MAX_ROUTE_COST:
            continue # Direct repairs are handled by BasicAI before planning.
        # Reverse shortest route to ANY empty orthogonal service square.
        # The unit itself is a transit-only cell, never a movement endpoint.
        var goals: Array[Vector2i] = []
        for direction in Rules.DIRECTIONS:
            var stage: Vector2i = target+direction
            if not Rules.inside(stage,terrain) or stage in blocked or stage in friendly_cells:
                continue
            if Rules.entry_cost_half(str(terrain[stage.y][stage.x]),
                    Domains.GROUND,false,Weather.from_state(observed),
                    Weather.traction(engineer)) < 0:
                continue
            goals.append(stage)
        if goals.is_empty():
            continue
        var path_remaining: Dictionary = _reverse_costs(
            terrain,goals,blocked,Weather.from_state(observed),
            Weather.traction(engineer))
        if not path_remaining.has(origin):
            continue
        var original_distance: int = int(path_remaining[origin])
        if original_distance > MAX_ROUTE_COST:
            continue
        for destination in reach:
            var cell: Vector2i = destination
            if cell == origin or not path_remaining.has(cell) or (fog and not visible.has(cell)):
                continue
            var remaining: int = int(path_remaining[cell])
            if remaining >= original_distance:
                continue # No oscillating/sacrificial movement without progress.
            if _exposed(cell,engineer,enemies,observed):
                continue
            var spent: int = int(reach[cell])
            var score: int = margin*10 + restored*6 - remaining*26 - spent*4
            # Prefer a safe arrival that can actually repair this same turn;
            # after a partial move, retain the opportunity for the next phase.
            if remaining == 0:
                score += 90
            if score > best_score or (score == best_score and _prefer(
                    cell,target,best,side,Rules.map_size(terrain).x)):
                best_score = score
                best = {
                    "valid":true,"engineer_id":str(engineer["id"]),
                    "target_id":str(ally["id"]),"target_pos":target,
                    "destination":cell,
                    "remaining_cost":remaining,"route_cost":original_distance,
                    "estimated_repair_hp":restored,
                    "estimated_repair_cost":expense,"net_value":margin
                }
    return best

# Reverse weighted shortest-path search on OBSERVED terrain only.
# For foot units each forward entry cost is integral; a reverse edge
# adds the cost of ENTERING its current cell, not its previous neighbor.
static func _reverse_costs(terrain: Array,goals: Array[Vector2i],
        blocked: Array[Vector2i],weather: String,traction: String) -> Dictionary:
    var distance: Dictionary = {}
    var queue: Array[Vector2i] = []
    for goal in goals:
        distance[goal] = 0
        queue.append(goal)
    var cursor := 0
    while cursor < queue.size():
        var current: Vector2i = queue[cursor]
        cursor += 1
        var cost_half: int = Rules.entry_cost_half(
            str(terrain[current.y][current.x]),Domains.GROUND,false,weather,traction)
        if cost_half < 0:
            continue
        var cost: int = int(cost_half/2)
        for direction in Rules.DIRECTIONS:
            var previous: Vector2i = current+direction
            if not Rules.inside(previous,terrain) or previous in blocked:
                continue
            if Rules.entry_cost_half(str(terrain[previous.y][previous.x]),
                    Domains.GROUND,false,weather,traction) < 0:
                continue
            var next_distance: int = int(distance[current])+cost
            if distance.has(previous) and int(distance[previous]) <= next_distance:
                continue
            distance[previous] = next_distance
            queue.append(previous)
    return distance

# Protect scarce engineers from observed attacks, including obvious
# move+shoot threats. Evaluate using PUBLIC enemy chassis/ranges/ATK only:
# never read enemy ammo, fuel, readiness, orders, or anything not in observed.
static func _exposed(cell: Vector2i,engineer: Dictionary,
        enemies: Array,observed: Dictionary) -> bool:
    var terrain: Array = observed["terrain"]
    var cover: int = int(TerrainTactics.COVER.get(
        str(terrain[cell.y][cell.x]),0))
    if TerrainTactics.city_at(observed.get("economy",{}),cell):
        cover += TerrainTactics.CITY_COVER
    for enemy in enemies:
        if Domains.GROUND not in Domains.targets(enemy):
            continue
        var attack: int = int(enemy.get("attack",0))
        if attack <= 0:
            continue
        var dist: int = absi(enemy["pos"].x-cell.x)+absi(enemy["pos"].y-cell.y)
        var low: int = maxi(1,int(enemy.get("attack_min_range",1)))
        var high: int = maxi(low,int(enemy.get("attack_range",1)))
        var mobility: int = maxi(0,int(enemy.get("move_points",0)))
        if dist > high+mobility:
            continue
        if dist+mobility < low:
            continue
        var likely_damage: int = maxi(1,attack-int(engineer.get("defense",0))-cover)
        if (dist >= low and dist <= high) or likely_damage >= maxi(2,ceili(float(engineer.get("hp",0))*0.5)):
            return true
    return false

static func _prefer(destination: Vector2i,target: Vector2i,
        prior: Dictionary,side: int,width: int) -> bool:
    if not prior.get("valid",false):
        return true
    var old: Vector2i = prior["destination"]
    var x: int = destination.x if side == 0 else width-1-destination.x
    var old_x: int = old.x if side == 0 else width-1-old.x
    if x != old_x:
        return x > old_x
    if destination.y != old.y:
        return destination.y < old.y
    # Do not use faction-specific autogenerated unit IDs as tie breakers.
    var old_target: Vector2i = prior.get("target_pos",Vector2i(-1,-1))
    var ax: int = target.x if side == 0 else width-1-target.x
    var bx: int = old_target.x if side == 0 else width-1-old_target.x
    return ax > bx if ax != bx else target.y < old_target.y
