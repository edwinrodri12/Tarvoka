extends RefCounted
class_name TarvokaDestinationComparison

# Pure read-only comparison of up to three legal endpoints for ONE friendly
# unit. Enemy intelligence uses current sight and NEVER hidden orders, ammo,
# fuel, last-known positions or units that may be revealed only after moving.
const Rules = preload("res://scripts/core/Rules.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Threat = preload("res://scripts/ui/ThreatAwarenessData.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

const MAX_CANDIDATES := 3

static func compare(state: Dictionary, unit_id: String, candidates: Array,
        viewer: int = 0, vs_ai: bool = false) -> Dictionary:
    var empty := {"valid":false,"unit_id":"","rows":[],"count":0,
        "source":Vector2i(-1,-1),"fog":false}
    if candidates.is_empty() or candidates.size() > MAX_CANDIDATES or unit_id.is_empty() or viewer not in [0,1]:
        return empty
    if not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]) or not state.get("units") is Array:
        return empty
    if int(state.get("winner",-1)) != -1 or int(state.get("faction",-1)) != viewer or (vs_ai and viewer != 0):
        return empty
    var friendly: Dictionary = {}
    for unit in state["units"]:
        if unit is Dictionary and str(unit.get("id","")) == unit_id and int(unit.get("hp",0)) > 0 and int(unit.get("faction",-1)) == viewer:
            friendly = unit
            break
    if friendly.is_empty() or not Turns.can_act(friendly,viewer):
        return empty
    var source = friendly.get("pos",null)
    if not source is Vector2i or not Rules.inside(source,state["terrain"]):
        return empty
    var legal: Dictionary = Hints.for_unit(state,unit_id).get("moves",{})
    var risk: Dictionary = Threat.preview(state,unit_id,viewer,vs_ai)
    if not bool(risk.get("valid",false)):
        return empty
    var cells: Dictionary = risk.get("cells",{})
    if not cells.has(source):
        return empty
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if fog else {}
    var observed: Array = []
    for enemy in state["units"]:
        if not enemy is Dictionary or int(enemy.get("hp",0)) <= 0 or int(enemy.get("faction",-1)) == viewer:
            continue
        var position = enemy.get("pos",null)
        if position is Vector2i and (not fog or visible.has(position)):
            observed.append(enemy)
    var original: Dictionary = cells[source]
    var rows: Array[Dictionary] = []
    var chosen: Dictionary = {}
    for i in range(candidates.size()):
        var cell = candidates[i]
        if not cell is Vector2i or chosen.has(cell) or not legal.has(cell) or not cells.has(cell):
            return empty
        chosen[cell] = true
        var point: Dictionary = cells[cell]
        var armed := int(friendly.get("attack",0)) > 0 and Logistics.can_fire(friendly)
        var fire_targets := 0
        if armed:
            # Legally reachable post-move position, but *currently visible*
            # targets only. Future sight after movement is unknown by design.
            var projected: Dictionary = friendly.duplicate()
            projected["pos"] = cell
            for enemy in observed:
                if Domains.can_attack(projected,enemy) and Turns.in_attack_range(projected,enemy):
                    fire_targets += 1
        rows.append({
            "slot":i+1,"pos":cell,
            "cost":int(legal[cell]),
            "threats":int(point.get("threats",0)),
            "threat_delta":int(point.get("threats",0))-int(original.get("threats",0)),
            "cover":int(point.get("cover",0)),
            "cover_delta":int(point.get("cover",0))-int(original.get("cover",0)),
            "visible_targets":fire_targets
        })
    return {
        "valid":true,"unit_id":unit_id,"rows":rows,"count":rows.size(),
        "source":source,"current_threats":int(original.get("threats",0)),
        "current_cover":int(original.get("cover",0)),"fog":fog,
        "note":("Riesgo teórico de enemigos visibles. La niebla oculta más amenazas posibles."
            if fog else "Riesgo teórico de enemigos visibles; no asegura casillas seguras.")
    }
