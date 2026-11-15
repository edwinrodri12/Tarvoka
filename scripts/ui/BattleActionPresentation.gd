extends RefCounted
class_name TarvokaBattleActionPresentation

# Read-only description of an already prepared board order.
# Never calls Session, does not inspect hidden enemy units, and cannot spend
# money, ammunition or turns. Main's existing handlers own all commitments.
static func snapshot(state: Dictionary, selected_id: String,
        pending_order: Dictionary) -> Dictionary:
    if int(state.get("winner",-1)) != -1:
        return {
            "kind":"results",
            "title":"BATALLA FINALIZADA",
            "detail":"Consulta los resultados de la batalla.",
            "confirm":"RESULTADOS",
            "cancel":"CANCELAR",
            "pending":false
        }
    var kind: String = str(pending_order.get("kind",""))
    var cell = pending_order.get("cell",null)
    if kind == "move" and cell is Vector2i:
        return {
            "kind":"move",
            "title":"MOVIMIENTO PENDIENTE",
            "detail":"Destino (%d,%d) · aún no ejecutado" % [cell.x+1,cell.y+1],
            "confirm":"CONFIRMAR MOV.",
            "cancel":"CANCELAR ORDEN",
            "pending":true
        }
    if kind == "attack":
        var target_id: String = str(pending_order.get("target_id",""))
        return {
            "kind":"attack",
            "title":"ATAQUE PENDIENTE",
            "detail":"Objetivo %s · aún no ejecutado" % (
                target_id if not target_id.is_empty() else "seleccionado"),
            "confirm":"CONFIRMAR ATAQUE",
            "cancel":"CANCELAR ORDEN",
            "pending":true
        }
    if not selected_id.is_empty():
        return {
            "kind":"selected",
            "title":"UNIDAD SELECCIONADA",
            "detail":"Toca un destino o un enemigo visible para preparar una orden.",
            "confirm":"CONFIRMAR",
            "cancel":"CANCELAR",
            "pending":false
        }
    return {
        "kind":"idle",
        "title":"ORDENES DE BATALLA",
        "detail":"Selecciona una unidad propia para ver sus acciones.",
        "confirm":"CONFIRMAR",
        "cancel":"CANCELAR",
        "pending":false
    }
