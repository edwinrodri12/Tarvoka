extends RefCounted
class_name TarvokaMultiTurnObjectivesV33

# V33: small, reproducible multi-turn plan. The ONLY input for choices
# is the faction-observed snapshot produced by Visibility.observed_state.
# No unseen enemy state, no hidden treasury, no bonuses, no free orders.
# Goals survive a turn in the optional v1 save field "ai_objectives".
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

const MAX_CAPTURE_ORDERS := 2
const MAX_ESCORT_ORDERS := 2
const MAX_ASSIGNMENTS := 4
const MAX_TARGETS := 3
const VALID_TASKS := ["capture","escort","defend"]

static func _site_at(sites: Array, cell: Vector2i) -> Dictionary:
    for site in sites:
        if site is Dictionary and site.get("pos") == cell:
            return site
    return {}

static func _cell(g: Dictionary) -> Vector2i:
    return Vector2i(int(g.get("x",-1)),int(g.get("y",-1)))

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x-b.x)+abs(a.y-b.y)

static func _route_cost(knowledge: Dictionary, unit: Dictionary,
        target: Vector2i, cache: Dictionary) -> int:
    var terrain: Array = knowledge.get("terrain",[])
    if not Rules.inside(target,terrain):
        return 999999
    var id: String = str(unit["id"])
    if not cache.has(id):
        # One weighted Dijkstra per assigned ally, NOT per city. The
        # 40x30 Android map could have many contested objectives.
        var size: Vector2i = Rules.map_size(terrain)
        cache[id] = Rules.reachable(unit["pos"],
            size.x*size.y*4,terrain,[],Domains.domain(unit),
            Logistics.road_fast(unit),[],
            Weather.from_state(knowledge),Weather.traction(unit))
    return int(cache[id].get(target,999999))

static func _known_objectives(knowledge: Dictionary, side: int) -> Array:
    var out: Array = []
    var e: Dictionary = knowledge.get("economy",{})
    for site in e.get("sites",[]):
        if not site is Dictionary:
            continue
        if int(site.get("owner",-2)) in [side,-2]:
            continue # -2 = site ownership hidden by fog, not neutral.
        if not site.get("pos") is Vector2i:
            continue
        if str(site.get("kind","")) == "shipyard":
            continue # Water-bound port cannot be captured by infantry.
        var cell: Vector2i = site["pos"]
        if Rules.movement_cost_for(str(knowledge["terrain"][cell.y][cell.x]),
                Domains.GROUND) < 0:
            continue
        out.append({"kind":str(site["kind"]),"pos":cell})
    return out

# X is measured in the direction of advance. The mirrored right-side
# player has the same local coordinates as the left-side player.
static func _local_x(cell: Vector2i, side: int, width: int) -> int:
    return cell.x if side == 0 else width-1-cell.x

static func _unit_before(a: Dictionary, b: Dictionary, side: int,
        width: int) -> bool:
    var ap: Vector2i = a["pos"]
    var bp: Vector2i = b["pos"]
    if ap.y != bp.y:
        return ap.y < bp.y
    var ax: int = _local_x(ap,side,width)
    var bx: int = _local_x(bp,side,width)
    if ax != bx:
        return ax < bx
    if str(a.get("role","")) != str(b.get("role","")):
        return str(a.get("role","")) < str(b.get("role",""))
    return str(a["id"]) < str(b["id"])

static func _prefer_equal_score_cell(candidate: Vector2i,
        incumbent: Vector2i, side: int, width: int) -> bool:
    if incumbent.x < 0:
        return true
    var a: int = _local_x(candidate,side,width)
    var b: int = _local_x(incumbent,side,width)
    if a != b:
        return a < b
    return candidate.y < incumbent.y

static func _alive_allies(knowledge: Dictionary, side: int) -> Array:
    var result: Array = []
    for u in knowledge.get("units",[]):
        if u is Dictionary and int(u.get("faction",-1)) == side and \
                int(u.get("hp",0)) > 0:
            result.append(u)
    # Stable ordering from each faction's local perspective.
    # IDs are a final fallback only when position/role cannot distinguish units.
    var width: int = Rules.map_size(knowledge["terrain"]).x
    result.sort_custom(func(a,b):
        return _unit_before(a,b,side,width))
    return result

static func _visible_hostiles(knowledge: Dictionary, side: int) -> Array:
    var result: Array = []
    for u in knowledge.get("units",[]):
        if u is Dictionary and int(u.get("faction",-1)) == 1-side and \
                int(u.get("hp",0)) > 0:
            result.append(u)
    return result

static func _same_target(g: Dictionary, item: Dictionary) -> bool:
    return _cell(g) == item["pos"] and str(g.get("kind","")) == str(item["kind"])

static func _goal(unit: Dictionary, task: String, site: Dictionary) -> Dictionary:
    var cell: Vector2i = site["pos"]
    return {"unit_id":str(unit["id"]),"task":task,
        "kind":str(site["kind"]),"x":cell.x,"y":cell.y}

static func _persisted_capture(previous: Dictionary,
        unit: Dictionary, knowledge: Dictionary,
        sites: Array, chosen: Dictionary, side: int) -> Dictionary:
    for g in previous.get("assignments",[]):
        if str(g.get("task","")) != "capture" or \
                str(g.get("unit_id","")) != str(unit["id"]):
            continue
        var cell: Vector2i = _cell(g)
        if chosen.has(cell):
            continue
        for s in sites:
            if _same_target(g,s):
                return g.duplicate(true)
        # Previously SEEN objectives remain actionable stale leads when
        # the fog covers them again. A distant unseen owner is -2: it
        # cannot reveal that the enemy secretly captured the site.
        for s in knowledge.get("economy",{}).get("sites",[]):
            if s.get("pos") != cell or \
                    str(s.get("kind","")) != str(g["kind"]) or \
                    int(s.get("owner",-2)) != -2:
                continue
            if Rules.inside(cell,knowledge["terrain"]) and \
                    Rules.movement_cost_for(str(
                        knowledge["terrain"][cell.y][cell.x]),
                        Domains.GROUND) >= 0:
                return g.duplicate(true)
    return {}

static func _target_count(assignments: Array) -> int:
    var found: Dictionary = {}
    for g in assignments:
        found[_cell(g)] = true
    return found.size()

static func refresh(knowledge: Dictionary, side: int,
        previous: Dictionary = {}, strategic: Dictionary = {}) -> Dictionary:
    if side not in [0,1] or not Rules.valid_terrain(knowledge.get("terrain",[])):
        return {}
    var own: Array = _alive_allies(knowledge,side)
    var candidates: Array = _known_objectives(knowledge,side)
    var chosen: Dictionary = {}
    var route_cache: Dictionary = {} # bounded by current friendly units
    var width: int = Rules.map_size(knowledge["terrain"]).x
    var assigned_ids: Dictionary = {}
    var tasks: Array = []
    var capturers: Array = []
    for u in own:
        if Economy.can_capture(u):
            capturers.append(u)
    # Keep valid previous orders stable through enemy turns / changes in
    # troop enumeration. Reassign only if a site became owned, unit died,
    # target is unavailable, or a new task is urgently required.
    for u in capturers:
        if tasks.size() >= MAX_CAPTURE_ORDERS:
            break
        var old: Dictionary = _persisted_capture(previous,u,
            knowledge,candidates,chosen,side)
        if old.is_empty():
            continue
        tasks.append(old)
        chosen[_cell(old)] = true
        assigned_ids[str(u["id"])] = true
    # Distinct capturers spread across distinct city/factory objectives,
    # not a line of infantry all racing for the same city.
    for u in capturers:
        if tasks.size() >= MAX_CAPTURE_ORDERS:
            break
        if assigned_ids.has(str(u["id"])):
            continue
        var best: Dictionary = {}
        var best_score := -999999
        for site in candidates:
            var cell: Vector2i = site["pos"]
            if chosen.has(cell):
                continue
            var cost: int = _route_cost(knowledge,u,cell,route_cache)
            if cost >= 999999:
                continue
            var score: int = (1400 if str(site["kind"]) == "city" else 850) - cost*20
            if str(strategic.get("style","")) == "expansion" and \
                    str(site["kind"]) == "city":
                score += 400
            if score > best_score or (score == best_score and \
                    (best.is_empty() or _prefer_equal_score_cell(
                        cell,best["pos"],side,width))):
                best = site
                best_score = score
        if best.is_empty():
            continue
        tasks.append(_goal(u,"capture",best))
        chosen[best["pos"]] = true
        assigned_ids[str(u["id"])] = true
    # Support: concentrate mobile combat troops around the advancing
    # capturers; do NOT move to the occupied capture tile itself.
    var enemies: Array = _visible_hostiles(knowledge,side)
    var defense: Dictionary = {}
    var nearest_threat := 999999
    for site in knowledge.get("economy",{}).get("sites",[]):
        if not site is Dictionary or int(site.get("owner",-2)) != side:
            continue
        if str(site.get("kind","")) == "shipyard":
            continue
        for enemy in enemies:
            var dist: int = _manhattan(site["pos"],enemy["pos"])
            if dist <= 3 and dist < nearest_threat:
                nearest_threat = dist
                defense = {"kind":str(site["kind"]),"pos":site["pos"]}
    var escorts := 0
    var all_targets: Dictionary = chosen.duplicate()
    for u in own:
        if escorts >= MAX_ESCORT_ORDERS or tasks.size() >= MAX_ASSIGNMENTS:
            break
        if assigned_ids.has(str(u["id"])) or Economy.can_capture(u) or \
                int(u.get("attack",0)) <= 0 or Domains.domain(u) != Domains.GROUND:
            continue
        var target: Dictionary = defense
        var task: String = "defend"
        if target.is_empty() and not tasks.is_empty():
            var capture: Dictionary = tasks[0]
            target = {"kind":str(capture["kind"]),"pos":_cell(capture)}
            task = "escort"
        if target.is_empty():
            continue
        if all_targets.size() >= MAX_TARGETS and \
                not all_targets.has(target["pos"]):
            continue
        var cost: int = _route_cost(knowledge,u,target["pos"],route_cache)
        if cost >= 999999:
            continue
        tasks.append(_goal(u,task,target))
        all_targets[target["pos"]] = true
        assigned_ids[str(u["id"])] = true
        escorts += 1
    return {
        "side":side,
        "style":str(strategic.get("style","balanced")),
        "assignments":tasks
    }

static func for_unit(objectives: Dictionary, unit_id: String) -> Dictionary:
    for g in objectives.get("assignments",[]):
        if str(g.get("unit_id","")) == unit_id:
            return g
    return {}

static func capture_bonus(objectives: Dictionary, unit_id: String,
        site_pos: Vector2i) -> int:
    var g: Dictionary = for_unit(objectives,unit_id)
    if g.is_empty() or str(g.get("task","")) != "capture":
        return 0
    return 28000 if _cell(g) == site_pos else -12000

static func valid(objectives: Dictionary, state: Dictionary) -> bool:
    if not objectives is Dictionary or objectives.size() != 3 or \
            not objectives.get("side") is int or \
            int(objectives["side"]) not in [0,1] or \
            not objectives.get("style") is String or \
            objectives["style"].length() > 32 or \
            not objectives.get("assignments") is Array or \
            objectives["assignments"].size() > MAX_ASSIGNMENTS:
        return false
    var units: Dictionary = {}
    for u in state.get("units",[]):
        # A previously assigned soldier may die on the human turn;
        # the save must remain loadable until the AI replans.
        if int(u.get("faction",-1)) == int(objectives["side"]):
            units[str(u["id"])] = u
    var used: Dictionary = {}
    var distinct: Dictionary = {}
    var captures: Dictionary = {}
    for g in objectives["assignments"]:
        if not g is Dictionary or g.size() != 5 or \
                not g.get("unit_id") is String or \
                not g.get("task") is String or \
                not g.get("kind") is String or \
                not g.get("x") is int or not g.get("y") is int:
            return false
        var id: String = str(g["unit_id"])
        if id.is_empty() or id.length() > 64 or \
                not units.has(id) or used.has(id) or \
                not (str(g["task"]) in VALID_TASKS) or \
                str(g["kind"]) not in Economy.MODERN_PRODUCERS + ["city"]:
            return false
        var cell: Vector2i = _cell(g)
        if not Rules.inside(cell,state.get("terrain",[])):
            return false
        if str(state["terrain"][cell.y][cell.x]) == "water":
            return false
        if Visibility.enabled(state) and \
                not Visibility.explored_cells(state,
                    int(objectives["side"])).has(cell):
            return false # A forged goal in unexplored fog is not memory.
        # A goal must correspond to an ACTUAL public objective, even if its
        # owner changed since last turn. Save loading cannot forge targets.
        var site_ok := false
        for site in state.get("economy",{}).get("sites",[]):
            if site.get("pos") == cell and str(site.get("kind","")) == \
                    str(g["kind"]):
                site_ok = true
                break
        if not site_ok:
            return false
        if str(g["task"]) == "capture":
            if (int(units[id].get("hp",0)) > 0 and \
                    not Economy.can_capture(units[id])) or captures.has(cell):
                return false
            captures[cell] = true
        else:
            if (Economy.can_capture(units[id]) and \
                    int(units[id].get("hp",0)) > 0) or \
                    int(units[id].get("attack",0)) <= 0 or \
                    Domains.domain(units[id]) != Domains.GROUND:
                return false
        used[id] = true
        distinct[cell] = true
    return distinct.size() <= MAX_TARGETS
