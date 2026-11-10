extends RefCounted
class_name TarvokaCombat

# Pure deterministic combat rules; no scene, animation or RNG dependency.
static func damage(attack: int, defense: int, terrain_cover: int = 0) -> int:
    if attack <= 0:
        return 0
    return max(1, attack - max(0, defense) - max(0, terrain_cover))

static func resolve(attacker_hp: int, defender_hp: int, attack: int, defense: int, terrain_cover: int = 0) -> Dictionary:
    if attacker_hp <= 0 or defender_hp <= 0:
        return {"valid": false, "damage": 0, "defender_hp": max(0, defender_hp), "defeated": false}
    var dealt: int = min(defender_hp, damage(attack, defense, terrain_cover))
    var remaining: int = max(0, defender_hp - dealt)
    return {"valid": true, "damage": dealt, "defender_hp": remaining, "defeated": remaining == 0}
