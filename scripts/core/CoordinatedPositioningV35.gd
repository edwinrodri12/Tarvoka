extends RefCounted
class_name TarvokaCoordinatedPositioningV35

# Choose ONE legal position that creates a 2/3-unit lethal salvo on a
# CURRENTLY VISIBLE target. The move is not a free attack: the next
# BasicAI.step must issue attacks via BattleSession one at a time.
# Planning uses ONLY Visibility.observed_state and public damage previews.
# Do not call the authoritative Session while evaluating candidate cells:
# probing hidden occupancy would be a fog-of-war information leak.
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const FireTeam = preload("res://scripts/core/CoordinatedFireV34.gd")
const Missions = preload("res://scripts/core/MultiTurnObjectivesV33.gd")

const MAX_MOVERS := 4
const MAX_TARGETS := 4
const MAX_POSITIONS := 4

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x-b.x)+abs(a.y-b.y)

static func _normalized(cell: Vector2i, side: int,
        width: int) -> String:
    var x: int = cell.x if side == 0 else width-1-cell.x
    return "%04d:%04d" % [x,cell.y]

static func _vacant(knowledge: Dictionary, cell: Vector2i,
        mover: Dictionary) -> bool:
    for u in knowledge.get("units",[]):
        if u is Dictionary and int(u.get("hp",0)) > 0 and \
                str(u.get("id","")) != str(mover["id"]) and \
                Domains.layer(u) == Domains.layer(mover) and \
                u.get("pos") == cell:
            return false
    return true

static func _routes(knowledge: Dictionary, mover: Dictionary) -> Dictionary:
    var blocked: Array[Vector2i] = []
    var allied: Array[Vector2i] = []
    for u in knowledge.get("units",[]):
        if not u is Dictionary or int(u.get("hp",0)) <= 0 or \
                u.get("id") == mover.get("id") or \
                Domains.layer(u) != Domains.layer(mover):
            continue
        if int(u.get("faction",-1)) == int(mover.get("faction",-2)):
            allied.append(u["pos"])
        else:
            blocked.append(u["pos"])
    return Rules.reachable(mover["pos"],
        Logistics.movement_budget(mover),knowledge["terrain"],blocked,
        Domains.domain(mover),Logistics.road_fast(mover),allied,
        Weather.from_state(knowledge),Weather.traction(mover))

static func _must_hold(knowledge: Dictionary, mover: Dictionary,
        goals: Dictionary) -> bool:
    if Economy.can_capture(mover):
        for site in knowledge.get("economy",{}).get("sites",[]):
            if site is Dictionary and site.get("pos") == mover["pos"] and \
                    int(site.get("owner",-2)) != int(mover["faction"]):
                return true # do not interrupt a capture for an attack.
    var assignment: Dictionary = Missions.for_unit(goals,str(mover["id"]))
    if str(assignment.get("task","")) == "defend" and \
            _distance(mover["pos"],Vector2i(
                int(assignment["x"]),int(assignment["y"]))) <= 1:
        return true
    return false

static func _safe_against_others(knowledge: Dictionary, mover: Dictionary,
        target_id: String) -> bool:
    for foe in knowledge.get("units",[]):
        if not foe is Dictionary or \
                int(foe.get("faction",-1)) == int(mover["faction"]) or \
                int(foe.get("hp",0)) <= 0 or \
                str(foe.get("id","")) == target_id:
            continue
        if int(mover.get("attack_min_range",1)) > 1 and \
                _distance(foe["pos"],mover["pos"]) <= 1:
            return false # Artillery cannot shoot adjacent enemies.
        if not Turns.in_attack_range(foe,mover):
            continue
        var incoming: Dictionary = Battle.public_preview_exchange(
            foe,mover,knowledge["terrain"],
            knowledge.get("economy",{}),knowledge["units"])
        if bool(incoming.get("valid",false)) and \
                bool(incoming.get("defeated",false)):
            return false # No suicidal position against other enemies.
    return true

static func _candidate_cells(knowledge: Dictionary, side: int,
        mover: Dictionary, target: Dictionary,
        visible: Dictionary) -> Array:
    var route: Dictionary = _routes(knowledge,mover)
    var cells: Array = []
    var size: Vector2i = Rules.map_size(knowledge["terrain"])
    for cell in route:
        if cell == mover["pos"] or \
                not _vacant(knowledge,cell,mover) or \
                (Visibility.enabled(knowledge) and \
                not visible.has(cell)):
            continue
        var shifted: Dictionary = mover.duplicate(true)
        shifted["pos"] = cell
        shifted["moved"] = true
        if not Turns.in_attack_range(shifted,target):
            continue
        if not _safe_against_others(knowledge,shifted,str(target["id"])):
            continue
        var preview: Dictionary = Battle.public_preview_exchange(
            shifted,target,knowledge["terrain"],
            knowledge.get("economy",{}),knowledge["units"])
        if not bool(preview.get("valid",false)) or \
                int(preview.get("damage",0)) <= 0 or \
                int(preview.get("attacker_hp",0)) <= 0:
            continue
        var kind: String = Terrain.tile_at(knowledge["terrain"],cell)
        var cover: int = int(Terrain.COVER.get(kind,0))
        # Quality of the ACTUAL shot and defense after repositioning.
        var score: int = int(preview["damage"])*135 + cover*100 + \
            int(preview.get("height_delta",0))*90 - \
            int(preview["counter_damage"])*115 - int(route[cell])*20
        if bool(preview.get("flanked",false)):
            score += 110
        cells.append({"cell":cell,"score":score,
            "route_cost":int(route[cell])})
    cells.sort_custom(func(a,b):
        if int(a["score"]) != int(b["score"]):
            return int(a["score"]) > int(b["score"])
        return _normalized(a["cell"],side,size.x) < \
            _normalized(b["cell"],side,size.x))
    if cells.size() > MAX_POSITIONS:
        cells.resize(MAX_POSITIONS)
    return cells

static func propose(knowledge: Dictionary, side: int,
        max_shots: int = 2, goals: Dictionary = {}) -> Dictionary:
    if side not in [0,1] or not Rules.valid_terrain(
            knowledge.get("terrain",[])):
        return {}
    var depth: int = clampi(max_shots,2,3)
    var own: Array = []
    var foes: Array = []
    for u in knowledge.get("units",[]):
        if not u is Dictionary or int(u.get("hp",0)) <= 0:
            continue
        if int(u.get("faction",-1)) == side and \
                Turns.can_move(u,side) and Logistics.can_fire(u) and \
                not _must_hold(knowledge,u,goals):
            own.append(u)
        elif int(u.get("faction",-1)) == 1-side and \
                u.get("pos") is Vector2i:
            foes.append(u)
    var dimensions: Vector2i = Rules.map_size(knowledge["terrain"])
    own.sort_custom(func(a,b):
        return "%s|%s" % [
            str(a.get("role","")),
            _normalized(a["pos"],side,dimensions.x)] < \
            "%s|%s" % [
            str(b.get("role","")),
            _normalized(b["pos"],side,dimensions.x)])
    foes.sort_custom(func(a,b):
        return str(a["id"]) < str(b["id"]))
    if own.size() > MAX_MOVERS:
        own.resize(MAX_MOVERS)
    if foes.size() > MAX_TARGETS:
        foes.resize(MAX_TARGETS)
    var observed_visible: Dictionary = Visibility.visible_cells(
        knowledge,side) if Visibility.enabled(knowledge) else {}
    var best: Dictionary = {}
    var examined := 0
    for foe in foes:
        # Position a second/third gun to complete an EXISTING threat,
        # not send a lone unit deep into enemy territory.
        var has_support := false
        for other in knowledge.get("units",[]):
            if other is Dictionary and \
                    int(other.get("faction",-1)) == side and \
                    int(other.get("hp",0)) > 0 and \
                    Turns.can_act(other,side) and \
                    Logistics.can_fire(other) and \
                    Turns.in_attack_range(other,foe):
                has_support = true
                break
        if not has_support:
            continue
        for mover in own:
            if Turns.in_attack_range(mover,foe):
                continue # its immediate shot is already available.
            for candidate in _candidate_cells(knowledge,side,
                    mover,foe,observed_visible):
                var cell: Vector2i = candidate["cell"]
                var hypothetical: Dictionary = knowledge.duplicate(true)
                for friendly in hypothetical["units"]:
                    if str(friendly.get("id","")) == str(mover["id"]):
                        friendly["pos"] = cell
                        friendly["moved"] = true
                        break
                if Visibility.enabled(hypothetical) and \
                        not Visibility.is_unit_visible(hypothetical,
                            side,str(foe["id"])):
                    continue
                var salvo: Dictionary = FireTeam.propose(
                    hypothetical,side,depth,str(foe["id"]))
                examined += 1
                if salvo.is_empty() or \
                        not salvo["attackers"].has(str(mover["id"])) or \
                        int(salvo.get("estimated_losses",0)) > 1:
                    continue
                var quality: int = int(salvo["score"]) + \
                    int(candidate["score"]) - \
                    int(candidate["route_cost"])*15
                if best.is_empty() or quality > int(best["score"]) or \
                        (quality == int(best["score"]) and \
                        _normalized(cell,side,dimensions.x) < \
                        _normalized(best["destination"],side,dimensions.x)):
                    best = {
                        "valid":true,"unit_id":str(mover["id"]),
                        "destination":cell,"target_id":str(foe["id"]),
                        "planned_shots":int(salvo["shots"]),
                        "score":quality,"terrain":str(
                            Terrain.tile_at(knowledge["terrain"],cell)),
                        "counter_risk":int(salvo["expected_counter"])
                    }
    if not best.is_empty():
        best["evaluated_positions"] = examined
    return best
