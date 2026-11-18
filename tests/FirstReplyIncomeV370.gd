extends RefCounted
class_name TarvokaFirstReplyIncomeV370

const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

# RESEARCH ONLY: both conditions use normal BattleSession.end_turn.
# At the first handoff, that authoritative method gives the responder
# an immediate city payout. This pure wrapper records that payout and,
# for the "skip" condition only, removes exactly those newly credited
# funds AFTER BattleSession.end_turn has completed. All future turns
# are left untouched. Not imported by playable screens/core.
static func compare_first_handoff(before: Dictionary, outcome: Dictionary,
        first_faction: int, skip_payout: bool) -> Dictionary:
    var invalid := {"valid":false,"state":{},
        "reason":"invalid_handoff","original_payout":-1,"deducted":-1,
        "responder":1-first_faction}
    if not bool(outcome.get("valid",false)) or \
            not outcome.get("state") is Dictionary or \
            first_faction not in [0,1]:
        return invalid
    var after: Dictionary = outcome["state"]
    var responder: int = 1-first_faction
    if int(before.get("faction",-1)) != first_faction or \
            int(after.get("faction",-1)) != responder or \
            not before.has("economy") or not after.has("economy"):
        return invalid
    if int(before["economy"].get("turn",-1)) != 0 or \
            int(after["economy"].get("turn",-1)) != 1:
        return invalid
    var credits_before: int = int(before["economy"]["credits"][responder])
    var credits_after: int = int(after["economy"]["credits"][responder])
    var income: int = Economy.income_for(after["economy"],responder)
    if credits_after - credits_before != income or income <= 0:
        return invalid
    var patched: Dictionary = after.duplicate(true)
    var removed: int = income if skip_payout else 0
    if skip_payout:
        patched["economy"]["credits"][responder] = credits_before
    if not Economy.valid(patched["economy"],patched["terrain"]) or \
            Codec.encode(patched).is_empty():
        return invalid
    assert(int(patched["economy"]["credits"][responder]) == \
        credits_after-removed)
    assert(before["economy"]["credits"] is Array)
    assert(outcome["state"] == after) # never mutate original transition
    return {"valid":true,"state":patched,"reason":"skipped" if skip_payout else "retained",
        "original_payout":income,"deducted":removed,"responder":responder,
        "credits_before":credits_before,
        "credits_after":int(patched["economy"]["credits"][responder])}
