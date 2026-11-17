extends RefCounted
class_name TarvokaNextTurnThreatV36

# A bounded, conservative NEXT-ENEMY-TURN threat envelope.
# Read only Visibility.observed_state. Assume known enemies regain
# movement on their next turn; never read enemy private ammo/fuel/reaction.
# This is a threat estimate, NOT a guarantee of what a rival will do.
# Move orders are validated once by the authoritative BattleSession in AI.
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Positioning = preload("res://scripts/core/CoordinatedPositioningV35.gd")

const MAX_ALLIES := 5
const MAX_ENEMIES := 6
const MAX_DESTINATIONS := 9

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x-b.x)+abs(a.y-b.y)

static func _nearest(cell: Vector2i, units: Array) -> int:
    var best := 999999
    for u in units:
        if u is Dictionary and u.get("pos") is Vector2i:
            best = mini(best,_distance(cell,u["pos"]))
    return best

static func _side_key(cell: Vector2i, side: int, width: int) -> String:
    var x: int = cell.x if side == 0 else width-1-cell.x
    return "%04d:%04d" % [x,cell.y]

static func _attackers(known: Dictionary, side: int) -> Array:
    var foes: Array = []
    var allies: Array = []
    for u in known.get("units",[]):
        if not u is Dictionary or int(u.get("hp",0)) <= 0:
            continue
        if int(u.get("faction",-1)) == side:
            allies.append(u)
        elif int(u.get("faction",-1)) == 1-side and \
                int(u.get("attack",0)) > 0 and \
                u.get("pos") is Vector2i:
            foes.append(u)
    var width: int = Rules.map_size(known["terrain"]).x
    foes.sort_custom(func(a,b):
        var da: int = _nearest(a["pos"],allies)
        var db: int = _nearest(b["pos"],allies)
        if da != db:
            return da < db
        return _side_key(a["pos"],side,width) < \
            _side_key(b["pos"],side,width))
    if foes.size() > MAX_ENEMIES:
        foes.resize(MAX_ENEMIES)
    return foes

static func _route_for_enemy(known: Dictionary,
        enemy: Dictionary, ignore_own_blockers: bool = false) -> Dictionary:
    # Do not use privately tracked enemy fuel or movement readiness.
    # A rival can move again next turn even if it moved/acted this turn.
    var blocked: Array[Vector2i] = []
    var transit: Array[Vector2i] = []
    for u in known.get("units",[]):
        if not u is Dictionary or int(u.get("hp",0)) <= 0 or \
                str(u.get("id","")) == str(enemy["id"]) or \
                Domains.layer(u) != Domains.layer(enemy):
            continue
        if int(u.get("faction",-1)) == int(enemy["faction"]):
            transit.append(u["pos"])
        elif not ignore_own_blockers:
            blocked.append(u["pos"])
        # In a NEXT-TURN destination risk check, the endangered ally
        # may vacate its current tile. For safety, allow the foe to pass
        # through any friendly tile, an upper bound on enemy mobility.
    var route: Dictionary = Rules.reachable(
        enemy["pos"],int(enemy.get("move_points",0)),
        known["terrain"],blocked,Domains.domain(enemy),
        Logistics.road_fast(enemy),transit,
        Weather.from_state(known),Weather.traction(enemy))
    # The current position remains a potential firing point even if
    # there are obstacles on the way to other firing points.
    route[enemy["pos"]] = 0
    return route

static func _records(known: Dictionary, side: int,
        ignore_own_blockers: bool = false) -> Array:
    var result: Array = []
    for enemy in _attackers(known,side):
        var public_unit: Dictionary = enemy.duplicate(true)
        public_unit.erase("ammo")
        public_unit.erase("fuel")
        public_unit.erase("reacted")
        public_unit.erase("acted")
        public_unit.erase("moved")
        result.append({
            "unit":public_unit,
            "positions":_route_for_enemy(known,public_unit,
                ignore_own_blockers)
        })
    return result

static func _max_strike(known: Dictionary,
        defender: Dictionary, record: Dictionary) -> int:
    var foe: Dictionary = record["unit"]
    var highest := 0
    var seen: int = 0
    for pos in record["positions"]:
        var attacker: Dictionary = foe.duplicate(true)
        attacker["pos"] = pos
        if not Turns.in_attack_range(attacker,defender):
            continue
        # The authoritative attack preview recomputes terrain cover,
        # elevation and domain. No speculative attack is executed.
        var preview: Dictionary = Battle.public_preview_exchange(
            attacker,defender,known["terrain"],
            known.get("economy",{}),known["units"])
        if bool(preview.get("valid",false)):
            highest = maxi(highest,int(preview.get("damage",0)))
            seen += 1
            if highest >= int(defender["hp"]):
                break
    return highest

static func _risk(known: Dictionary,
        defender: Dictionary, records: Array) -> Dictionary:
    var greatest := 0
    var second := 0
    var threatening := 0
    for record in records:
        var damage: int = _max_strike(known,defender,record)
        if damage > 0:
            threatening += 1
        if damage >= greatest:
            second = greatest
            greatest = damage
        elif damage > second:
            second = damage
    return {"one":greatest,"two":greatest+second,
        "threats":threatening}

static func forecast(known: Dictionary, side: int,
        unit_id: String) -> Dictionary:
    if side not in [0,1] or not Rules.valid_terrain(
            known.get("terrain",[])):
        return {}
    var records: Array = _records(known,side)
    for u in known.get("units",[]):
        if u is Dictionary and str(u.get("id","")) == unit_id and \
                int(u.get("faction",-1)) == side and int(u.get("hp",0)) > 0:
            return _risk(known,u,records)
    return {}

static func _worth(unit: Dictionary, known: Dictionary,
        side: int) -> int:
    var score: int = maxi(100,Economy.cost(str(unit.get("role",""))))
    if int(unit.get("attack_min_range",1)) >= 2:
        score += 500 # Protect artillery/indirect weapons.
    if str(unit.get("role","")) in ["logistics","uav_recon"]:
        score += 380 # Preserve non-combat support investments.
    if Economy.can_capture(unit):
        for site in known.get("economy",{}).get("sites",[]):
            if site.get("pos") == unit["pos"] and \
                    int(site.get("owner",-2)) != side:
                score += 700 # Valuable, but not worth certain death.
                break
    return score

static func _destinations(known: Dictionary,side: int,
        unit: Dictionary, enemies: Array,
        keep_near_front: bool = false) -> Array:
    var reachable: Dictionary = Positioning._routes(known,unit)
    var filtered: Array = []
    var visible: Dictionary = Visibility.visible_cells(known,side) if \
        Visibility.enabled(known) else {}
    var size: Vector2i = Rules.map_size(known["terrain"])
    for cell in reachable:
        if cell == unit["pos"] or not Positioning._vacant(
                known,cell,unit) or \
                (Visibility.enabled(known) and not visible.has(cell)):
            continue
        var cover: int = int(Terrain.COVER.get(
            Terrain.tile_at(known["terrain"],cell),0))
        var site_cover := 0
        for site in known.get("economy",{}).get("sites",[]):
            if site.get("pos") == cell and \
                    str(site.get("kind","")) == "city":
                site_cover = 1
                break
        var score: int = (cover+site_cover)*155 + \
            mini(10,_nearest(cell,enemies))*35 - \
            int(reachable[cell])*18
        if keep_near_front:
            # A rescue should not be a cross-map withdrawal when a legal
            # nearby safe cell can preserve pressure at the objective.
            score = (cover+site_cover)*155 - \
                int(reachable[cell])*105 - \
                _distance(cell,unit["pos"])*65 - \
                mini(10,_nearest(cell,enemies))*10
        filtered.append({"cell":cell,"estimate":score,
            "movement_cost":int(reachable[cell])})
    filtered.sort_custom(func(a,b):
        if int(a["estimate"]) != int(b["estimate"]):
            return int(a["estimate"]) > int(b["estimate"])
        return _side_key(a["cell"],side,size.x) < \
            _side_key(b["cell"],side,size.x))
    if filtered.size() > MAX_DESTINATIONS:
        filtered.resize(MAX_DESTINATIONS)
    return filtered

# Optional 3.6.1 research filter. A conservative potential kill by TWO
# different foes is not equivalent to a forced real-life double attack.
# Preserve specialists and genuinely wounded capturers; give healthy
# front-line troops a chance to retain useful offensive pressure.
static func _critical_specialist(unit: Dictionary) -> bool:
    return int(unit.get("attack_min_range",1)) >= 2 or \
        str(unit.get("role","")) in ["logistics","uav_recon","ew","sam","mlrs"]

static func _has_valuable_shot(known: Dictionary,side: int,
        unit: Dictionary,foes: Array) -> bool:
    if not Turns.can_act(unit,side) or not Logistics.can_fire(unit):
        return false
    for foe in foes:
        if not Turns.in_attack_range(unit,foe):
            continue
        var preview: Dictionary = Battle.public_preview_exchange(
            unit,foe,known["terrain"],
            known.get("economy",{}),known["units"])
        if not bool(preview.get("valid",false)):
            continue
        var inflicted: int = int(preview.get("damage",0))
        if int(preview.get("attacker_hp",0)) > 0 and \
                inflicted >= maxi(3,ceili(float(foe["hp"])*0.5)):
            return true
    return false

static func propose(known: Dictionary,side: int,
        level: int = 10, offensive_discipline: bool = false,
        critical_rescue: bool = false) -> Dictionary:
    if side not in [0,1] or not Rules.valid_terrain(
            known.get("terrain",[])) or level < 8:
        return {}
    var foes: Array = _attackers(known,side)
    if foes.is_empty():
        return {}
    var records: Array = _records(known,side)
    # Potential retreat vacates an allied chokepoint. Use conservative
    # future travel without the stale blockers; otherwise a destination
    # can look safe only because the planner left a ghost ally behind.
    var future_records: Array = _records(known,side,true)
    var allies: Array = []
    for u in known.get("units",[]):
        if u is Dictionary and int(u.get("faction",-1)) == side and \
                Turns.can_move(u,side) and u.get("pos") is Vector2i and \
                int(u.get("hp",0)) > 0:
            allies.append(u)
    var dimensions: Vector2i = Rules.map_size(known["terrain"])
    allies.sort_custom(func(a,b):
        var da: int = _nearest(a["pos"],foes)
        var db: int = _nearest(b["pos"],foes)
        if da != db:
            return da < db
        return _side_key(a["pos"],side,dimensions.x) < \
            _side_key(b["pos"],side,dimensions.x))
    if allies.size() > MAX_ALLIES:
        allies.resize(MAX_ALLIES)
    var best: Dictionary = {}
    var count := 0
    for unit in allies:
        var hp: int = int(unit["hp"])
        var current: Dictionary = _risk(known,unit,records)
        var danger: int = int(current["two"] if level >= 11 \
            else current["one"])
        if critical_rescue:
            # A second attack is an upper bound, not an inevitable
            # coordinated enemy turn. Require ONE visible lethal hit.
            danger = int(current["one"])
        if danger < hp:
            continue # Don't flee just because something is nearby.
        if critical_rescue:
            var designated: bool = _critical_specialist(unit) or hp <= 4
            if not designated and Economy.can_capture(unit) and hp <= 6:
                for site in known.get("economy",{}).get("sites",[]):
                    if site is Dictionary and str(site.get("kind","")) == "city" and \
                            site.get("pos") == unit["pos"] and \
                            int(site.get("owner",-2)) != side:
                        designated = true
                        break
            if not designated:
                continue
            # An immediately useful legal shot has first claim on a turn,
            # including one by a specialist; do not abandon it for a
            # conservative next-turn hypothetical.
            if _has_valuable_shot(known,side,unit,foes):
                continue
        if offensive_discipline and not _critical_specialist(unit):
            # Protect real offensive opportunities from a risk envelope
            # that assumes the rival optimally chooses to attack us.
            if _has_valuable_shot(known,side,unit,foes):
                continue
            # The level-11/12 two-enemy SUM is an upper bound, not an
            # established forced double strike. Healthy combat platforms
            # should not flee solely on that pessimistic assumption.
            if level >= 11 and hp >= 8 and int(current["one"]) < hp:
                continue
        var value: int = _worth(unit,known,side)
        for entry in _destinations(known,side,unit,foes,critical_rescue):
            var shifted: Dictionary = unit.duplicate(true)
            var pos: Vector2i = entry["cell"]
            shifted["pos"] = pos
            var next: Dictionary = _risk(known,shifted,future_records)
            count += 1
            var future: int = int(next["two"] if level >= 11 \
                else next["one"])
            if critical_rescue:
                future = int(next["one"])
            if future >= hp or future >= danger:
                continue # Only reposition if survival genuinely improves.
            var cover: int = int(Terrain.COVER.get(
                Terrain.tile_at(known["terrain"],pos),0))
            var score: int = 15000 + value*2 + \
                (danger-future)*220 + cover*90 - \
                int(entry["movement_cost"])*40 + \
                mini(8,_nearest(pos,foes))*20
            if critical_rescue:
                # Minimize lost ground after FIRST ensuring actual safety.
                score = 15000 + value*2 + (danger-future)*110 + \
                    cover*70 - int(entry["movement_cost"])*155 - \
                    _distance(unit["pos"],pos)*55
            if best.is_empty() or score > int(best["score"]) or \
                    (score == int(best["score"]) and \
                    _side_key(pos,side,dimensions.x) < \
                    _side_key(best["destination"],side,dimensions.x)):
                best = {
                    "valid":true,
                    "unit_id":str(unit["id"]),
                    "destination":pos,
                    "reason":"anticipatory_defense",
                    "expected_damage_before":danger,
                    "expected_damage_after":future,
                    "unit_hp":hp,
                    "score":score,
                    "terrain":Terrain.tile_at(known["terrain"],pos),
                    "risk_model":"visible_enemy_next_turn"
                }
    if not best.is_empty():
        best["evaluated"] = count
    return best
