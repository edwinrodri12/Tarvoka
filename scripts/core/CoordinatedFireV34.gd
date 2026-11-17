extends RefCounted
class_name TarvokaCoordinatedFireV34

# V34 opt-in tactical AI, not a combat-rule change. Plans a legal salvo
# of two (levels 7-9) or three (levels 10-12) CURRENTLY in-range attackers.
# Only public observed_state is accepted; no hidden ammo, location,
# reaction readiness, damage bonuses or simulated free actions.
# Session.attack remains the authoritative executor of EACH shot.
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Domains = preload("res://scripts/core/Domains.gd")

const MAX_ATTACKERS_PER_TARGET := 8
const MAX_VISIBLE_TARGETS := 10
const MAX_DEPTH := 3

static func _distance(a: Vector2i, b: Vector2i) -> int:
    return abs(a.x-b.x)+abs(a.y-b.y)

static func _priority(knowledge: Dictionary, side: int,
        foe: Dictionary) -> int:
    var score := 0
    var target: Vector2i = foe["pos"]
    for ally in knowledge.get("units",[]):
        if not ally is Dictionary or int(ally.get("faction",-1)) != side or \
                int(ally.get("hp",0)) <= 0:
            continue
        var range: int = _distance(ally["pos"],target)
        if range > 3:
            continue
        if Economy.can_capture(ally):
            for site in knowledge.get("economy",{}).get("sites",[]):
                if site.get("pos") == ally["pos"] and \
                        int(site.get("owner",-2)) != side:
                    score += 2200 # Protect an ACTIVE capture, not anyone.
                    break
        if int(ally.get("attack_min_range",1)) >= 2:
            score += 600 # Protect fragile ranged platforms.
    for site in knowledge.get("economy",{}).get("sites",[]):
        if int(site.get("owner",-2)) == side and \
                _distance(target,site["pos"]) <= 2:
            score += 400 # Threat to a currently owned facility.
    return mini(score,5000)

static func _candidate_key(unit: Dictionary, side: int,
        width: int) -> String:
    var x: int = int(unit["pos"].x)
    if side == 1:
        x = width-1-x
    return "%s|%04d|%04d|%s" % [
        str(unit.get("role","")),x,int(unit["pos"].y),str(unit["id"])]

static func _shooters(knowledge: Dictionary, side: int,
        target: Dictionary) -> Array:
    var candidates: Array = []
    for ally in knowledge.get("units",[]):
        if not ally is Dictionary or int(ally.get("faction",-1)) != side or \
                not Turns.can_act(ally,side) or \
                not Logistics.can_fire(ally) or \
                not Turns.in_attack_range(ally,target):
            continue
        var preview: Dictionary = BattleActions.public_preview_exchange(
            ally,target,knowledge["terrain"],
            knowledge.get("economy",{}),knowledge["units"])
        if bool(preview.get("valid",false)) and \
                int(preview.get("damage",0)) > 0:
            candidates.append(ally)
    var size: Vector2i = Rules.map_size(knowledge["terrain"])
    candidates.sort_custom(func(a,b):
        return _candidate_key(a,side,size.x) < _candidate_key(b,side,size.x))
    if candidates.size() > MAX_ATTACKERS_PER_TARGET:
        candidates.resize(MAX_ATTACKERS_PER_TARGET)
    return candidates

static func _simulate(squad: Array, foe: Dictionary,
        knowledge: Dictionary, side: int) -> Dictionary:
    var remaining: int = int(foe.get("hp",0))
    var risk := 0
    var projected_damage := 0
    var losses := 0
    var sequence: Array = []
    var used: Dictionary = {}
    for unit in squad:
        if used.has(str(unit["id"])) or remaining <= 0:
            return {}
        used[str(unit["id"])] = true
        var future: Dictionary = foe.duplicate(true)
        future["hp"] = remaining
        var preview: Dictionary = BattleActions.public_preview_exchange(
            unit,future,knowledge["terrain"],
            knowledge.get("economy",{}),knowledge["units"])
        if not bool(preview.get("valid",false)) or \
                int(preview.get("damage",0)) <= 0:
            return {}
        # A one-way projectile may be spent as ammunition; do not pretend
        # its platform will survive. Other units must survive predicted
        # retaliation to count as a prudent coordinated attack.
        var expendable: bool = str(unit.get("role","")) in BattleActions.ONE_WAY_ROLES
        if int(preview["attacker_hp"]) <= 0 and not expendable:
            return {}
        risk += int(preview["counter_damage"])
        if expendable:
            risk += 5 + int(Economy.cost(str(unit.get("role","")))/200)
            losses += 1
        projected_damage += int(preview["damage"])
        remaining = int(preview["defender_hp"])
        sequence.append(str(unit["id"]))
    if remaining > 0:
        return {} # Only commit a volley that KILLS the target.
    var score: int = 15000 + \
        int(foe.get("attack",0))*35 + \
        int(foe.get("hp",0))*25 + \
        _priority(knowledge,side,foe) - \
        squad.size()*260 - risk*110 - losses*700
    return {"valid":true,"first_attacker":sequence[0],
        "target_id":str(foe["id"]),"attackers":sequence,
        "shots":sequence.size(),"projected_damage":projected_damage,
        "expected_counter":risk,"estimated_losses":losses,
        "score":score}

static func propose(knowledge: Dictionary, side: int,
        max_shots: int = 2) -> Dictionary:
    if side not in [0,1] or \
            not Rules.valid_terrain(knowledge.get("terrain",[])):
        return {}
    var limit: int = clampi(max_shots,2,MAX_DEPTH)
    var candidates: Array = []
    for foe in knowledge.get("units",[]):
        if foe is Dictionary and int(foe.get("faction",-1)) == 1-side and \
                int(foe.get("hp",0)) > 0 and foe.get("pos") is Vector2i:
            candidates.append(foe)
    candidates.sort_custom(func(a,b):
        return str(a["id"]) < str(b["id"]))
    if candidates.size() > MAX_VISIBLE_TARGETS:
        candidates.resize(MAX_VISIBLE_TARGETS)
    var best: Dictionary = {}
    var explored := 0
    for foe in candidates:
        var shooters: Array = _shooters(knowledge,side,foe)
        if shooters.size() < 2:
            continue
        for i in range(shooters.size()):
            for j in range(shooters.size()):
                if j == i:
                    continue
                var pair: Array = [shooters[i],shooters[j]]
                var plan: Dictionary = _simulate(pair,foe,knowledge,side)
                explored += 1
                if not plan.is_empty() and (best.is_empty() or \
                        int(plan["score"]) > int(best["score"])):
                    best = plan
                if limit < 3:
                    continue
                for k in range(shooters.size()):
                    if k == i or k == j:
                        continue
                    var triple: Array = [shooters[i],shooters[j],shooters[k]]
                    plan = _simulate(triple,foe,knowledge,side)
                    explored += 1
                    if not plan.is_empty() and (best.is_empty() or \
                            int(plan["score"]) > int(best["score"])):
                        best = plan
    if not best.is_empty():
        best["searched_seqs"] = explored
    return best
