extends RefCounted
class_name TarvokaOpeningBalance

# A deliberately SMALL, public, one-turn deployment constraint for the side
# choosing initiative. No HP/weapon/money/vision bonus for either faction.
# The same initial unit roster produces the same cap for Blue or Red.
const MAX_FIRST_ORDERS := 6
const MAX_VALID_LIMIT := 6

static func create(units: Array, starter: int) -> Dictionary:
    if starter not in [0,1]:
        return {}
    var active: int = 0
    for unit in units:
        if unit is Dictionary and int(unit.get("faction",-1)) == starter and int(unit.get("hp",0)) > 0:
            active += 1
    if active < 1:
        return {}
    return {"starter":starter, "limit":mini(MAX_FIRST_ORDERS,active), "used":0}

static func valid(data: Dictionary) -> bool:
    return data.get("starter",null) is int and int(data["starter"]) in [0,1] and data.get("limit",null) is int and int(data["limit"]) >= 1 and int(data["limit"]) <= MAX_VALID_LIMIT and data.get("used",null) is int and int(data["used"]) >= 0 and int(data["used"]) <= int(data["limit"])

static func can_order(state: Dictionary) -> bool:
    if not state.has("opening"):
        return true
    var opening = state["opening"]
    if not opening is Dictionary or not valid(opening):
        return false
    return int(state.get("faction",-1)) == int(opening["starter"]) and int(opening["used"]) < int(opening["limit"])

static func record(next_state: Dictionary) -> void:
    if next_state.has("opening") and next_state["opening"] is Dictionary:
        next_state["opening"]["used"] = mini(int(next_state["opening"]["limit"]),int(next_state["opening"]["used"])+1)

static func remaining(state: Dictionary) -> int:
    if not state.has("opening") or not state["opening"] is Dictionary or not valid(state["opening"]):
        return -1
    return maxi(0,int(state["opening"]["limit"])-int(state["opening"]["used"]))
