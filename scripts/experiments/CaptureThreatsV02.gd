extends RefCounted
class_name TarvokaCaptureThreatsV02

# DIAGNOSTIC: conservative risk only from CURRENTLY OBSERVED units.
# Enemy ammunition/reaction readiness is not consulted; pretend a visible
# opponent is armed, without reading any private remaining-ammo quantity.
const BattleActions = preload("res://scripts/core/BattleActions.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Domains = preload("res://scripts/core/Domains.gd")

static func _public_enemy(unit: Dictionary) -> Dictionary:
    var guess: Dictionary = unit.duplicate(true)
    if guess.has("ammo"):
        guess["ammo"] = 1
    guess["reacted"] = false
    return guess

static func incoming_damage(knowledge: Dictionary, enemy: Dictionary,
        target: Dictionary, units: Array = []) -> int:
    var attacker: Dictionary = _public_enemy(enemy)
    if not Turns.in_attack_range(attacker,target):
        return 0
    var lineup: Array = units if not units.is_empty() else knowledge["units"]
    var strike: Dictionary = BattleActions.public_preview_exchange(
        attacker,target,knowledge["terrain"],knowledge.get("economy",{}),lineup
    )
    return int(strike.get("damage",0)) if bool(strike.get("valid",false)) else 0

static func risk_for_cell(knowledge: Dictionary, helper: Dictionary,
        destination: Vector2i) -> Dictionary:
    var placed: Dictionary = helper.duplicate(true)
    placed["pos"] = destination
    var lineup: Array = knowledge["units"].duplicate(true)
    for unit in lineup:
        if str(unit.get("id","")) == str(helper.get("id","")):
            unit["pos"] = destination
            break
    var side: int = int(helper.get("faction",-1))
    var direct_max := 0
    var nearby := 0
    for enemy in knowledge["units"]:
        if not enemy is Dictionary or int(enemy.get("hp",0)) <= 0:
            continue
        if int(enemy.get("faction",-1)) == side:
            continue
        var threat: int = incoming_damage(knowledge,enemy,placed,lineup)
        direct_max = maxi(direct_max,threat)
        # This is only a proximity HEURISTIC, not a claim of a guaranteed
        # attack or legal enemy path. The opponent may move before shooting.
        if Domains.can_attack(enemy,placed):
            var reach: int = int(enemy.get("move_points",0))+int(enemy.get("attack_range",1))
            var dist: int = absi(enemy["pos"].x-destination.x)+absi(enemy["pos"].y-destination.y)
            if dist <= reach:
                nearby += 1
    return {"immediate_lethal":direct_max >= int(placed.get("hp",0)),
        "immediate_damage":direct_max,
        "nearby_visible_threats":nearby,
        "penalty":direct_max*600+nearby*40}
