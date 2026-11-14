extends RefCounted
class_name TarvokaQuickUnitNavigation

# Read-only navigation queue for actual friendly units. Never guesses enemy
# positions, alters movement, spends resources or changes turn bookkeeping.
# Always derive from the full army, not the capped 24-row alert drawer.
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

static func _compare(a: Dictionary, b: Dictionary) -> bool:
    if int(a["priority"]) != int(b["priority"]):
        return int(a["priority"]) < int(b["priority"])
    var first: Vector2i = a["pos"]
    var second: Vector2i = b["pos"]
    if first.y != second.y:
        return first.y < second.y
    if first.x != second.x:
        return first.x < second.x
    return str(a["id"]) < str(b["id"])

static func queues(state: Dictionary, viewer: int = 0, vs_ai: bool = false) -> Dictionary:
    var empty := {"ready":[],"attention":[],"valid":false}
    if viewer not in [0,1] or not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]) or not state.get("units") is Array:
        return empty
    if int(state.get("winner",-1)) != -1 or int(state.get("faction",-1)) != viewer:
        return empty
    if vs_ai and viewer != 0:
        return empty
    var available: Array[Dictionary] = []
    var needs_attention: Array[Dictionary] = []
    var may_order: bool = Opening.can_order(state)
    for unit in state["units"]:
        if not unit is Dictionary or int(unit.get("faction",-1)) != viewer or int(unit.get("hp",0)) <= 0:
            continue
        var pos = unit.get("pos",null)
        if not pos is Vector2i or not Rules.inside(pos,state["terrain"]):
            continue
        var id: String = str(unit.get("id",""))
        if id.is_empty():
            continue
        if may_order and Turns.can_act(unit,viewer):
            available.append({"id":id,"pos":pos,"priority":0})
        var hp: int = int(unit.get("hp",0))
        var supply: String = Logistics.alert(unit)
        if hp <= 5 or not supply.is_empty():
            var severity := 0 if hp <= 3 or supply.contains("AGOTADA") or supply.contains("SIN COMBUSTIBLE") else 1
            needs_attention.append({"id":id,"pos":pos,"priority":severity})
    available.sort_custom(_compare)
    needs_attention.sort_custom(_compare)
    return {"ready":available,"attention":needs_attention,"valid":true}

static func next_unit(queues_data: Dictionary, mode: String, current_id: String = "") -> Dictionary:
    if not bool(queues_data.get("valid",false)) or mode not in ["ready","attention"]:
        return {}
    var candidates: Array = queues_data.get(mode,[])
    if candidates.is_empty():
        return {}
    var index := -1
    for i in range(candidates.size()):
        if str(candidates[i].get("id","")) == current_id:
            index = i
            break
    var next_index: int = (index+1)%candidates.size()
    var result: Dictionary = candidates[next_index].duplicate()
    result["index"] = next_index+1
    result["total"] = candidates.size()
    return result
