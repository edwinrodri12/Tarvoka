extends RefCounted
class_name TarvokaBattleTurnReadout

# This is presentation only: it neither grants movement nor simulates attacks.
# All ready flags come from the actual turn and logistics rules. In single
# player, opponent counts and selected enemy internals are never inspected.
const Turns = preload("res://scripts/core/Turns.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

const GOLD := Color("#F8D078")
const GREEN := Color("#75DFB0")
const RED := Color("#FF978B")
const MUTED := Color("#A5BBCB")

static func snapshot(state: Dictionary, selected_id: String,
        pending: Dictionary, vs_ai: bool) -> Dictionary:
    var side: int = int(state.get("faction",-1))
    var winner: int = int(state.get("winner",-1))
    var result := {
        "title":"ESPERANDO PARTIDA", "detail":"", "turn_text":"", "tint":MUTED,
        "ready":0, "total":0, "selected":"", "state":"inactive"
    }
    if side not in [0,1] or not state.get("units") is Array:
        return result
    if winner in [0,1]:
        result["title"] = "BATALLA FINALIZADA"
        result["turn_text"] = "Victoria: %s" % Identity.name_for(state,winner)
        result["detail"] = "Abre resultados para ver el informe."
        result["tint"] = GOLD
        result["state"] = "finished"
        return result
    if vs_ai and side == 1:
        # No enemy army totals, supply states, selected-unit stats or
        # "ready" counts: those may be concealed by fog of war.
        result["title"] = "TURNO DEL RIVAL"
        result["turn_text"] = "La IA está actuando"
        result["detail"] = "Espera a que termine el turno enemigo."
        result["tint"] = RED
        result["state"] = "enemy"
        return result

    var faction_name: String = Identity.name_for(state,side)
    result["title"] = "TU TURNO" if vs_ai or side == 0 else "TURNO JUGADOR 2"
    result["turn_text"] = faction_name
    result["tint"] = Identity.color_for(state,side).lightened(0.26)
    result["state"] = "active"
    var can_order: bool = Opening.can_order(state)
    var chosen: Dictionary = {}
    for candidate in state["units"]:
        if not candidate is Dictionary or int(candidate.get("faction",-1)) != side or int(candidate.get("hp",0)) <= 0:
            continue
        result["total"] = int(result["total"]) + 1
        if can_order and Turns.can_act(candidate,side):
            result["ready"] = int(result["ready"]) + 1
        if str(candidate.get("id","")) == selected_id:
            chosen = candidate
    var count_text := "%d/%d unidades listas" % [int(result["ready"]),int(result["total"])]
    if not can_order:
        result["detail"] = "APERTURA COMPLETADA · Termina el turno."
        result["tint"] = GOLD
        result["state"] = "opening_finished"
    elif not pending.is_empty():
        var order_type: String = "ATAQUE" if str(pending.get("kind","")) == "attack" else "MOVIMIENTO"
        result["detail"] = "%s SIN CONFIRMAR · Confirma o cancela." % order_type
        result["tint"] = GOLD
        result["state"] = "pending"
    elif chosen.is_empty():
        result["detail"] = "%s · Selecciona una unidad." % count_text
    else:
        var unit_id: String = str(chosen.get("id",""))
        var role: String = str(chosen.get("role",""))
        var role_label: String = Roles.label(role) if Roles.valid(role) else "Unidad"
        result["selected"] = unit_id
        if not Turns.can_act(chosen,side):
            result["detail"] = "%s %s · ACCIONES TERMINADAS · %s" % [role_label,unit_id,count_text]
            result["state"] = "used"
            result["tint"] = MUTED
        else:
            var ability: String = "MOVIMIENTO SIN USAR" if Turns.can_move(chosen,side) and Logistics.movement_budget(chosen) > 0 else "MOVIMIENTO AGOTADO"
            var fire: String = "ARMA PREPARADA" if Logistics.can_fire(chosen) else "SIN DISPARO"
            result["detail"] = "%s %s · %s · %s" % [role_label,unit_id,ability,fire]
            result["state"] = "selected"
            result["tint"] = GREEN
    return result
