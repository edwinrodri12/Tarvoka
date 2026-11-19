extends RefCounted
class_name TarvokaRecruitReserveV403

# Research-only decision discipline, NEVER a monetary bonus:
# reserve 7 turns of existing city income during the first two turns
# of either faction, but waive the reserve when a currently OBSERVED
# enemy is already within immediate reach of an owned city or our unit.
# No hidden opponent funds, unseen units, new credits, or turn tweaks.
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const RESERVE_INCOME_CYCLES := 7
const OPENING_HALF_TURNS := 4
const EMERGENCY_MANHATTAN := 4

static func _near_visible_threat(knowledge: Dictionary,
        side: int) -> bool:
    if side not in [0,1]:
        return false
    var exposed: Array = []
    for own in knowledge.get("units",[]):
        if own is Dictionary and \
                int(own.get("faction",-1)) == side and \
                int(own.get("hp",0)) > 0 and \
                own.get("pos") is Vector2i:
            exposed.append(own["pos"])
    for site in knowledge.get("economy",{}).get("sites",[]):
        if site is Dictionary and str(site.get("kind","")) == "city" \
                and int(site.get("owner",-2)) == side and \
                site.get("pos") is Vector2i:
            exposed.append(site["pos"])
    for enemy in knowledge.get("units",[]):
        if not enemy is Dictionary or \
                int(enemy.get("faction",-1)) != 1-side or \
                int(enemy.get("hp",0)) <= 0 or \
                not enemy.get("pos") is Vector2i:
            continue
        var target: Vector2i = enemy["pos"]
        for owned in exposed:
            var difference: Vector2i = target-owned
            if absi(difference.x)+absi(difference.y) <= EMERGENCY_MANHATTAN:
                return true
    return false

static func assess(state: Dictionary, knowledge: Dictionary,
        candidate: Dictionary) -> Dictionary:
    var result := {
        "defer":false,"reason":"no_reserve_required",
        "cost":int(candidate.get("cost",0)),
        "reserve":0,"remaining":-1,"visible_emergency":false
    }
    if not bool(candidate.get("valid",false)) or \
            str(candidate.get("action","")) != "produce" or \
            not state.get("economy") is Dictionary or \
            not knowledge.get("economy") is Dictionary:
        return result
    var side: int = int(state.get("faction",-1))
    if side not in [0,1]:
        return result
    var economy: Dictionary = state["economy"]
    var phase: int = int(economy.get("turn",999))
    var income: int = Economy.income_for(knowledge["economy"],side)
    var money: int = int(economy.get("credits",[0,0])[side])
    var cost: int = int(candidate.get("cost",0))
    result["remaining"] = money-cost
    result["reserve"] = RESERVE_INCOME_CYCLES*income
    if phase >= OPENING_HALF_TURNS or income<=0 or cost<=0:
        return result
    # Preserve current combat safety. This uses only VISIBLE enemies
    # and friendly owned/occupied territory in observed_state.
    if _near_visible_threat(knowledge,side):
        result["visible_emergency"] = true
        result["reason"] = "visible_tactical_emergency"
        return result
    if money >= cost and money-cost < int(result["reserve"]):
        result["defer"] = true
        result["reason"] = "future_recruitment_liquidity_buffer"
    return result
