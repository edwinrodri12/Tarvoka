extends RefCounted
class_name TarvokaOpeningBonusPolicyV367

# Research harness only. Not referenced by playable scenes or engine rules.
# This accepts a recommendation from the *same* AI after three legal moves.
# It never manufactures an action, reads private enemies or modifies state.
static func eligible(variant: String, action: String) -> bool:
    match variant:
        "4":
            return action in ["move","attack","produce","resupply"]
        "3plus_move":
            return action == "move"
        "3plus_support":
            return action in ["move","produce","resupply"]
        _:
            return false
