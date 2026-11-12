extends RefCounted
class_name TarvokaBattleActions

const Turns = preload("res://scripts/core/Turns.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")

# These guided munitions ARE the projectile, not reusable weapon platforms.
const ONE_WAY_ROLES := ["fpv", "loitering", "usv"]

# One deterministic defense shot per assault, never a counter-counterattack.
# A damaged defender reacts only if alive, armed, able to reach the attacker
# and NOT a disposable one-way projectile. Reaction is independent of the
# defender's active-turn flag, but it spends one real round of ammunition.
# Its reduced damage accounts for the defender's POST-HIT strength.
const RESPONSE_PERCENT := 50

static func _maximum_hp(unit: Dictionary) -> int:
    var role: String = str(unit.get("role", ""))
    if Roles.PROFILES.has(role):
        return maxi(1,int(Roles.PROFILES[role]["hp"]))
    if Arsenal.valid(role):
        return maxi(1,int(Arsenal.profile(role)["hp"]))
    # Legacy soldiers have no HP template. Their live HP is the only
    # available reference; never add a new save-file field.
    return maxi(1,int(unit.get("hp",1)))

static func preview_exchange(attacker: Dictionary, defender: Dictionary) -> Dictionary:
    var empty := {"valid":false,"damage":0,"defender_hp":maxi(0,int(defender.get("hp",0))),"counter_damage":0,"attacker_hp":maxi(0,int(attacker.get("hp",0))),"counter_spent":false}
    if int(attacker.get("hp",0)) <= 0 or int(defender.get("hp",0)) <= 0:
        return empty
    if not Logistics.can_fire(attacker) or not Turns.in_attack_range(attacker,defender):
        return empty
    var forward: Dictionary = Roles.resolve(attacker,defender)
    if not bool(forward.get("valid",false)):
        return empty
    var dealt: int = int(forward["damage"])
    var remaining: int = int(forward["defender_hp"])
    var return_hit := 0
    var can_answer: bool = remaining > 0 and str(attacker.get("role","")) not in ONE_WAY_ROLES
    can_answer = can_answer and str(defender.get("role","")) not in ONE_WAY_ROLES
    can_answer = can_answer and int(defender.get("attack",0)) > 0 and Logistics.can_fire(defender)
    if can_answer:
        var surviving: Dictionary = defender.duplicate(true)
        surviving["hp"] = remaining
        if Turns.in_attack_range(surviving,attacker):
            var retaliation: Dictionary = Roles.resolve(surviving,attacker)
            if bool(retaliation.get("valid",false)) and int(retaliation.get("damage",0)) > 0:
                var original_max: int = _maximum_hp(defender)
                # Round up to keep a weak but armed defender dangerous,
                # while still giving the initiating strike a clear advantage.
                var scaled: int = ceili(float(int(retaliation["damage"]) * remaining * RESPONSE_PERCENT) / float(original_max * 100))
                return_hit = mini(int(attacker["hp"]),maxi(1,scaled))
    return {
        "valid":true,"damage":dealt,"defender_hp":remaining,
        "counter_damage":return_hit,
        "attacker_hp":maxi(0,int(attacker["hp"]) - return_hit),
        "counter_spent":return_hit > 0,
        "defeated":remaining == 0
    }

# Pure adjacent attack action; never mutates the supplied unit array.
static func attack(units: Array, attacker_id: String, defender_id: String, faction: int) -> Dictionary:
    var result: Array = units.duplicate(true)
    # Reject ambiguous identifiers before resolving any combat action.
    var seen_ids := {}
    for unit in result:
        if not (unit is Dictionary):
            return {"valid": false, "units": units.duplicate(true)}
        var uid = unit.get("id", null)
        if not (uid is String) or uid.is_empty() or seen_ids.has(uid):
            return {"valid": false, "units": units.duplicate(true)}
        seen_ids[uid] = true
    var attacker_index := -1
    var defender_index := -1
    for i in range(result.size()):
        var unit = result[i]
        if not (unit is Dictionary):
            continue
        if str(unit.get("id", "")) == attacker_id:
            attacker_index = i
        if str(unit.get("id", "")) == defender_id:
            defender_index = i
    if attacker_index < 0 or defender_index < 0 or attacker_index == defender_index:
        return {"valid": false, "units": units.duplicate(true)}
    var attacker: Dictionary = result[attacker_index]
    var defender: Dictionary = result[defender_index]
    if not Turns.can_act(attacker, faction) or not Logistics.can_fire(attacker) or int(defender.get("hp", 0)) <= 0:
        return {"valid": false, "units": units.duplicate(true)}
    if int(defender.get("faction", -1)) == faction:
        return {"valid": false, "units": units.duplicate(true)}
    var a_pos = attacker.get("pos", Vector2i(-999, -999))
    var d_pos = defender.get("pos", Vector2i(-999, -999))
    if not (a_pos is Vector2i) or not (d_pos is Vector2i):
        return {"valid": false, "units": units.duplicate(true)}
    # Reject off-board combat even when two invalid coordinates are adjacent.
    if not _inside_board(a_pos) or not _inside_board(d_pos):
        return {"valid": false, "units": units.duplicate(true)}
    if not Turns.in_attack_range(attacker, defender):
        return {"valid": false, "units": units.duplicate(true)}
    var exchange: Dictionary = preview_exchange(attacker, defender)
    if not bool(exchange["valid"]):
        return {"valid": false, "units": units.duplicate(true)}
    defender["hp"] = int(exchange["defender_hp"])
    attacker["hp"] = int(exchange["attacker_hp"])
    Logistics.consume_attack(attacker)
    if bool(exchange["counter_spent"]):
        Logistics.consume_attack(defender)
    attacker["acted"] = true
    var consumed: bool = str(attacker.get("role", "")) in ONE_WAY_ROLES
    if consumed:
        # An executed one-way attack removes its own platform even if the
        # target survives. Dead units keep their ID for old save compatibility.
        attacker["hp"] = 0
    return {
        "valid": true, "units": result, "damage": int(exchange["damage"]),
        "counter_damage": int(exchange["counter_damage"]),
        "counter_spent": bool(exchange["counter_spent"]),
        "consumed_unit_id": attacker_id if consumed else "",
        "winner": Turns.winner(result)
    }

static func _inside_board(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.x < 10 and pos.y >= 0 and pos.y < 8
