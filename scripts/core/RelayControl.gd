extends RefCounted
class_name TarvokaRelayControl

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const DEFAULT_TARGET := 5
const MAX_TARGET := 20
const MAX_NODES := 8
const MAX_FAIR_SCORE := 100000

# Optional, original prototype objective: secure communications relays.
# A living unit captures the relay under it only when its faction ENDS a turn.
# Each relay owned after that capture earns one signal point per completed turn.
# No extra actions, economy, production, buffs, or hidden RNG.
static func create(terrain: Array, target: int = DEFAULT_TARGET, fair_round: bool = false, first_faction: int = 0) -> Dictionary:
    if target < 2 or target > MAX_TARGET or terrain.size() != Rules.HEIGHT:
        return {}
    for row in terrain:
        if not row is Array or row.size() != Rules.WIDTH:
            return {}
    # Classic games keep the original two diagonal relays. Modern tactical
    # battles use two mirrored pairs: neither side gains a nearer *capturable*
    # signal from the fixed opening line/scout formation.
    var locations := [Vector2i(4, 2), Vector2i(5, 5)]
    if fair_round:
        locations = [
            Vector2i(4, 2), Vector2i(5, 2),
            Vector2i(4, 5), Vector2i(5, 5)
        ]
    var nodes: Array = []
    for position in locations:
        if Rules.movement_cost(str(terrain[position.y][position.x])) < 0:
            return {}
        nodes.append({"pos": position, "owner": -1})
    var control := {"nodes": nodes, "scores": [0, 0], "target": target, "turns": 0}
    if fair_round:
        if first_faction not in [0, 1]:
            return {}
        # Modern battles settle score victories only after both sides have
        # completed one equal opportunity to respond.
        control["fair_round"] = true
        control["first_faction"] = first_faction
        # Both sides earn signal at the SAME round boundary, instead of
        # the starter collecting a permanent extra tick each cycle.
        # Optional marker keeps existing v1 saves on original scoring.
        control["round_scoring"] = true
    return control

# Immutable and deterministic. Scoring happens BEFORE faction switches.
static func finish_turn(state: Dictionary) -> Dictionary:
    var result: Dictionary = state.duplicate(true)
    if not result.has("control") or not result["control"] is Dictionary:
        return result
    var objectives: Dictionary = result["control"]
    if not valid(objectives, result.get("terrain", [])):
        return result
    var faction: int = int(result.get("faction", -1))
    if faction not in [0, 1]:
        return result
    for node in objectives["nodes"]:
        for unit in result.get("units", []):
            if unit is Dictionary and int(unit.get("hp", 0)) > 0 and int(unit.get("faction", -1)) == faction and Domains.domain(unit) == Domains.GROUND and unit.get("pos") == node["pos"]:
                node["owner"] = faction
                break
    objectives["turns"] = int(objectives["turns"]) + 1
    var cap: int = MAX_FAIR_SCORE if bool(objectives.get("fair_round",false)) else int(objectives["target"])
    if bool(objectives.get("round_scoring",false)):
        # Owner capture still happens on the correct side's end turn.
        # Signal is deposited only after BOTH players have completed a
        # full turn. Symmetric captures made in the same round score equally.
        if int(objectives["turns"]) % 2 == 0:
            for side in [0,1]:
                var owned := 0
                for node in objectives["nodes"]:
                    if int(node["owner"]) == side:
                        owned += 1
                objectives["scores"][side] = mini(cap,int(objectives["scores"][side]) + owned)
    else:
        # Legacy saved games and classic mode retain exact old rules.
        var owned := 0
        for node in objectives["nodes"]:
            if int(node["owner"]) == faction:
                owned += 1
        objectives["scores"][faction] = mini(cap,int(objectives["scores"][faction]) + owned)
    var earned_victory: int = score_winner(objectives)
    if earned_victory != -1:
        result["winner"] = earned_victory
    return result

static func valid(control: Dictionary, terrain: Array) -> bool:
    if terrain.size() != Rules.HEIGHT:
        return false
    for row in terrain:
        if not row is Array or row.size() != Rules.WIDTH:
            return false
    if not control.get("nodes") is Array or control["nodes"].is_empty() or control["nodes"].size() > MAX_NODES:
        return false
    var unique: Dictionary = {}
    for node in control["nodes"]:
        if not node is Dictionary or not node.get("pos") is Vector2i or not node.get("owner") is int:
            return false
        var cell: Vector2i = node["pos"]
        if not Rules.inside(cell) or unique.has(cell) or Rules.movement_cost(str(terrain[cell.y][cell.x])) < 0:
            return false
        if node["owner"] not in [-1, 0, 1]:
            return false
        unique[cell] = true
    if not control.get("scores") is Array or control["scores"].size() != 2:
        return false
    if not control.get("target") is int or control["target"] < 2 or control["target"] > MAX_TARGET:
        return false
    if control.has("fair_round"):
        if control["fair_round"] != true or not control.get("first_faction") is int or int(control["first_faction"]) not in [0, 1]:
            return false
    elif control.has("first_faction"):
        return false
    if control.has("round_scoring"):
        if not control["round_scoring"] is bool or control["round_scoring"] != true or not bool(control.get("fair_round",false)):
            return false
    var ceiling: int = MAX_FAIR_SCORE if bool(control.get("fair_round",false)) else int(control["target"])
    for score in control["scores"]:
        if not score is int or score < 0 or score > ceiling:
            return false
    if not control.get("turns") is int or control["turns"] < 0 or control["turns"] > 100000:
        return false
    return true

static func score_winner(control: Dictionary) -> int:
    if not control.has("scores") or not control.get("scores") is Array or control["scores"].size() != 2:
        return -1
    var target: int = int(control.get("target", DEFAULT_TARGET))
    if bool(control.get("fair_round",false)):
        # Nobody wins halfway through a round: even the opening faction must
        # allow its opponent one equally scored turn. If both reach the target
        # at the same time and tie, play continues until someone pulls ahead.
        if int(control.get("turns",0)) % 2 != 0:
            return -1
        var blue: int = int(control["scores"][0])
        var red: int = int(control["scores"][1])
        if maxi(blue,red) < target or blue == red:
            return -1
        return 0 if blue > red else 1
    for faction in [0, 1]:
        if int(control["scores"][faction]) >= target:
            return faction
    return -1
