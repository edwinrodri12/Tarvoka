extends RefCounted
class_name TarvokaRelayScreensV399

# Optional research v3.9.9: occupy an ACTUAL narrow terrain crossing
# to slow a VISIBLE ground opponent on the way to an ALREADY GARRISONED,
# owned relay. Uses only the observed snapshot, never hidden enemies,
# private treasury, extra orders or inferred future attacks.
const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const MAX_FORECAST_TURNS := 4
const MIN_ROUTE_DELAY := 3
const INFINITE_COST := 999999

static func _blocked(terrain: Array, cell: Vector2i) -> bool:
    if not Rules.inside(cell,terrain):
        return true
    return Rules.movement_cost_for(str(terrain[cell.y][cell.x]),
        Domains.GROUND) < 0

static func _is_narrow(terrain: Array, cell: Vector2i) -> bool:
    if _blocked(terrain,cell):
        return false
    # Only physical choke tiles with two opposite impassable sides.
    # A forest, plain or merely expensive mountain is NOT a bottleneck.
    var north := _blocked(terrain,cell+Vector2i.UP)
    var south := _blocked(terrain,cell+Vector2i.DOWN)
    var west := _blocked(terrain,cell+Vector2i.LEFT)
    var east := _blocked(terrain,cell+Vector2i.RIGHT)
    return (north and south) or (west and east)

static func _routing(terrain: Array, target: Vector2i,
        barrier: Array[Vector2i], unit: Dictionary,
        weather: String) -> Dictionary:
    var cost: Dictionary = {}
    if not Rules.valid_terrain(terrain) or \
            not Rules.inside(target,terrain) or target in barrier:
        return cost
    var traction: String = Weather.traction(unit)
    var motorized: bool = Logistics.road_fast(unit)
    if Rules.entry_cost_half(str(terrain[target.y][target.x]),
            Domains.GROUND,motorized,weather,traction) < 0:
        return cost
    # Reverse weighted flood: edge cost is entering the current
    # cell in forward movement, matching the authoritative Rules.
    cost[target] = 0
    var frontier: Array[Vector2i] = [target]
    var cursor := 0
    while cursor < frontier.size():
        var now: Vector2i = frontier[cursor]
        cursor += 1
        var entered: int = Rules.entry_cost_half(
            str(terrain[now.y][now.x]),Domains.GROUND,motorized,
            weather,traction)
        for direction in Rules.DIRECTIONS:
            var prior: Vector2i = now + direction
            if prior in barrier or _blocked(terrain,prior):
                continue
            var candidate: int = int(cost[now]) + entered
            if cost.has(prior) and int(cost[prior]) <= candidate:
                continue
            cost[prior] = candidate
            frontier.append(prior)
    # Convert half-point costs to real whole movement-budget units.
    for cell in cost:
        cost[cell] = ceili(float(cost[cell])/2.0)
    return cost

static func _has_ally_on_relay(units: Array,
        side: int, cell: Vector2i) -> bool:
    for unit in units:
        if unit is Dictionary and int(unit.get("faction",-1)) == side \
                and int(unit.get("hp",0)) > 0 \
                and Domains.domain(unit) == Domains.GROUND \
                and unit.get("pos") == cell:
            return true
    return false

static func _occupied(units: Array, cell: Vector2i) -> bool:
    for unit in units:
        if unit is Dictionary and int(unit.get("hp",0)) > 0 \
                and Domains.domain(unit) == Domains.GROUND \
                and unit.get("pos") == cell:
            return true
    return false

static func _committed(knowledge: Dictionary,
        side: int, unit: Dictionary) -> bool:
    for relay in knowledge.get("control",{}).get("nodes",[]):
        if relay is Dictionary and relay.get("pos") == unit.get("pos") \
                and int(relay.get("owner",-2)) == side:
            return true
    # A capturable city is scored/owned when the turn ends, so do not
    # abandon that site to pursue a speculative screen.
    for site in knowledge.get("economy",{}).get("sites",[]):
        if site is Dictionary and site.get("pos") == unit.get("pos") \
                and int(site.get("owner",-2)) != side \
                and Economy.can_capture(unit):
            return true
    return false

static func _prefer(cell: Vector2i, previous: Vector2i,
        side: int, width: int) -> bool:
    if previous.x < 0:
        return true
    # Mirror-invariant ordering on 40x30, not the legacy 10x8 WIDTH.
    var x: int = cell.x if side == 0 else width-1-cell.x
    var previous_x: int = previous.x if side == 0 else width-1-previous.x
    if x != previous_x:
        return x > previous_x
    return cell.y < previous.y

static func propose(knowledge: Dictionary, side: int) -> Dictionary:
    if side not in [0,1] or not knowledge.get("control") is Dictionary \
            or not knowledge.get("units") is Array \
            or not Rules.valid_terrain(knowledge.get("terrain",[])):
        return {}
    var units: Array = knowledge["units"]
    var terrain: Array = knowledge["terrain"]
    var width: int = Rules.map_size(terrain).x
    var weather: String = Weather.from_state(knowledge)
    var enemies: Array = []
    var guards: Array = []
    for unit in units:
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0 \
                or Domains.domain(unit) != Domains.GROUND:
            continue
        if int(unit.get("faction",-1)) == 1-side:
            if Logistics.movement_budget(unit) > 0:
                enemies.append(unit)
        elif int(unit.get("faction",-1)) == side \
                and not bool(unit.get("moved",false)) \
                and not bool(unit.get("acted",false)) \
                and Logistics.movement_budget(unit) > 0 \
                and not _committed(knowledge,side,unit):
            guards.append(unit)
    if enemies.is_empty() or guards.is_empty():
        return {}
    # No explicit opponent memory. Under fog this array contains ONLY
    # opponents from Visibility.observed_state.
    var best_score := -999999999
    var best_cell := Vector2i(-1,-1)
    var best_unit := ""
    var best_target := Vector2i(-1,-1)
    var best_delay := 0
    var best_enemy_eta := 0
    for relay in knowledge["control"].get("nodes",[]):
        if not relay is Dictionary or int(relay.get("owner",-2)) != side \
                or not relay.get("pos") is Vector2i:
            continue
        var target: Vector2i = relay["pos"]
        if not _has_ally_on_relay(units,side,target):
            continue
        for screen in guards:
            var unit_id: String = str(screen["id"])
            var movement: int = Logistics.movement_budget(screen)
            var enemy_blockers: Array[Vector2i] = []
            var allies_transit: Array[Vector2i] = []
            for unit in units:
                if str(unit.get("id","")) == unit_id \
                        or int(unit.get("hp",0)) <= 0 \
                        or Domains.domain(unit) != Domains.GROUND:
                    continue
                if int(unit.get("faction",-1)) == side:
                    allies_transit.append(unit["pos"])
                else:
                    enemy_blockers.append(unit["pos"])
            var reachable: Dictionary = Rules.reachable(
                screen["pos"],movement,terrain,enemy_blockers,
                Domains.GROUND,Logistics.road_fast(screen),
                allies_transit,weather,Weather.traction(screen))
            for cell in reachable:
                if cell == screen["pos"] or cell == target \
                        or _occupied(units,cell) \
                        or not _is_narrow(terrain,cell):
                    continue
                # Because a relay guard is behind this chokepoint,
                # physically occupying it should force an opponent
                # to detour. Verify the detour using the SAME terrain.
                var barrier: Array[Vector2i] = [cell]
                for enemy in enemies:
                    var speed: int = Logistics.movement_budget(enemy)
                    var original: Dictionary = _routing(
                        terrain,target,[],enemy,weather)
                    if not original.has(enemy["pos"]):
                        continue
                    var before: int = int(original[enemy["pos"]])
                    var eta: int = ceili(float(before)/float(speed))
                    if eta > MAX_FORECAST_TURNS:
                        continue
                    var cut: Dictionary = _routing(
                        terrain,target,barrier,enemy,weather)
                    var after: int = int(cut.get(enemy["pos"],INFINITE_COST))
                    var delay: int = after-before
                    if delay < MIN_ROUTE_DELAY:
                        continue
                    var score: int = mini(60,delay)*100 \
                        - eta*100 - int(reachable[cell])*2
                    # Maximize real path delay while keeping this
                    # garrisoned relay and all city captures intact.
                    if score > best_score or (score == best_score and \
                            _prefer(cell,best_cell,side,width)):
                        best_score = score
                        best_cell = cell
                        best_unit = unit_id
                        best_target = target
                        best_delay = delay
                        best_enemy_eta = eta
    if best_unit.is_empty():
        return {}
    return {
        "unit_id":best_unit,
        "destination":best_cell,
        "protected_relay":best_target,
        "public_path_delay":best_delay,
        "visible_enemy_eta":best_enemy_eta,
        "reason":"relay_narrow_screen_v399"
    }
