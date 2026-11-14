extends RefCounted
class_name TarvokaMoveRiskComparison

# Advisory-only BEFORE confirming a legal move. Reuse the existing visible-
# enemy threat inspector and real terrain cover; this is not a prediction of
# hidden enemy orders or guaranteed future damage.
const Rules = preload("res://scripts/core/Rules.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Threat = preload("res://scripts/ui/ThreatAwarenessData.gd")

static func evaluate(state: Dictionary, pending: Dictionary,
        viewer: int = 0, vs_ai: bool = false) -> Dictionary:
    var invalid: Dictionary = {"valid":false}
    if str(pending.get("kind","")) != "move" or viewer not in [0,1]:
        return invalid
    if not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]):
        return invalid
    if int(state.get("winner",-1)) != -1 or int(state.get("faction",-1)) != viewer:
        return invalid
    if vs_ai and viewer != 0:
        return invalid
    var unit_id: String = str(pending.get("unit_id",""))
    var destination = pending.get("cell",null)
    if unit_id.is_empty() or not destination is Vector2i or not Rules.inside(destination,state["terrain"]):
        return invalid
    # Confirmations can become stale after a restored save or another action.
    # Never describe an illegal destination as if it were reachable.
    var legal_moves: Dictionary = Hints.for_unit(state,unit_id).get("moves",{})
    if not legal_moves.has(destination):
        return invalid
    var source: Vector2i = Vector2i(-1,-1)
    for unit in state.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == unit_id and int(unit.get("faction",-1)) == viewer and int(unit.get("hp",0)) > 0:
            source = unit.get("pos",Vector2i(-1,-1))
            break
    if not Rules.inside(source,state["terrain"]) or source == destination:
        return invalid
    # This calculation intentionally works without enabling the optional
    # full-map "Riesgo" overlay. The panel is shown only for a pending move.
    var risk: Dictionary = Threat.preview(state,unit_id,viewer,vs_ai)
    var cells: Dictionary = risk.get("cells",{})
    if not bool(risk.get("valid",false)) or not cells.has(source) or not cells.has(destination):
        return invalid
    var current: Dictionary = cells[source]
    var target: Dictionary = cells[destination]
    var current_threats: int = int(current.get("threats",0))
    var next_threats: int = int(target.get("threats",0))
    var current_cover: int = int(current.get("cover",0))
    var next_cover: int = int(target.get("cover",0))
    var threat_delta: int = next_threats-current_threats
    var cover_delta: int = next_cover-current_cover
    var tier := "same"
    var headline := "EXPOSICIÓN CONOCIDA SIN CAMBIOS"
    if threat_delta > 0:
        tier = "higher"
        headline = "MAYOR EXPOSICIÓN A ENEMIGOS VISIBLES"
    elif threat_delta < 0:
        tier = "lower"
        headline = "MENOR EXPOSICIÓN CONOCIDA"
    elif cover_delta > 0:
        tier = "cover_up"
        headline = "COBERTURA DEFENSIVA MEJORADA"
    elif cover_delta < 0:
        tier = "cover_down"
        headline = "PIERDES COBERTURA DEFENSIVA"
    var caveat: String = ("Cálculo teórico: no se conoce la munición ni las órdenes del rival. "
        + ("La niebla puede ocultar otras amenazas." if bool(risk.get("fog",false))
            else "No garantiza que la casilla sea segura."))
    return {
        "valid":true,"unit_id":unit_id,"from":source,"to":destination,
        "move_cost":int(legal_moves[destination]),
        "threat_before":current_threats,"threat_after":next_threats,
        "threat_delta":threat_delta,"cover_before":current_cover,
        "cover_after":next_cover,"cover_delta":cover_delta,
        "tier":tier,"headline":headline,"caveat":caveat,
        "contacts":int(risk.get("contacts",0)),
        "fog":bool(risk.get("fog",false))
    }
