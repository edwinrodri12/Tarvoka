extends RefCounted
class_name TarvokaDomains

# A unit's battlefield domain is independent from its combat role. Existing
# unit saves omit both new fields and must stay ground-only for targeting.
const GROUND := "ground"
const AIR := "air"
const NAVAL := "naval"
const TYPES := [GROUND, AIR, NAVAL]

static func valid_domain(value: Variant) -> bool:
    return value is String and value in TYPES

static func domain(unit: Dictionary) -> String:
    var value: Variant = unit.get("domain", GROUND)
    return str(value) if valid_domain(value) else ""

static func targets(unit: Dictionary) -> Array:
    # Empty means a noncombat role; legacy attackers can hit ground only.
    return unit.get("target_domains", [GROUND]) if unit.get("target_domains", [GROUND]) is Array else []

static func valid_targets(value: Variant) -> bool:
    if not value is Array or value.size() > TYPES.size():
        return false
    var seen: Dictionary = {}
    for target in value:
        if not valid_domain(target) or seen.has(target):
            return false
        seen[target] = true
    return true

static func can_attack(attacker: Dictionary, defender: Dictionary) -> bool:
    var source := domain(attacker)
    var destination := domain(defender)
    if source.is_empty() or destination.is_empty():
        return false
    var allowed = attacker.get("target_domains", [GROUND])
    return valid_targets(allowed) and destination in allowed

static func layer(unit: Dictionary) -> String:
    # Aircraft fly above the surface; ships and soldiers share the surface
    # occupancy plane but have different terrain passability.
    return AIR if domain(unit) == AIR else "surface"
