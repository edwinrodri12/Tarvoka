extends RefCounted
class_name TarvokaTacticalAlertsData

# Battlefield attention queue, never a tactical oracle. Every row is sourced
# from a friendly unit or a publicly observable site/relay. Navigation is
# advisory only; no move, capture, production or end-turn action is issued.
const Rules = preload("res://scripts/core/Rules.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const SiteOverlays = preload("res://scripts/ui/SiteOverlayData.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Radar = preload("res://scripts/ui/ObjectivesRadarData.gd")

const MAX_ROWS := 24
const MAX_OBJECTIVES := 6

static func _add(rows: Array[Dictionary], category: String, id: String,
        pos: Vector2i, title: String, description: String, priority: int) -> void:
    rows.append({
        "kind":category,"id":id,"pos":pos,"label":title,
        "status":description,"urgency":priority
    })

static func build(state: Dictionary, viewer: int = 0, vs_ai: bool = false) -> Dictionary:
    var output := {
        "valid":false,"active":false,"total":0,"urgent":0,"supplies":0,
        "ready_units":0,"ready_bases":0,"objectives":0,"capture_pending":0,
        "rows":[],"overflow":0
    }
    if viewer not in [0,1] or not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]) or not state.get("units") is Array:
        return output
    output["valid"] = true
    # A solo player's screen must never display enemy logistics or actions,
    # including in the short period when the AI owns the active phase.
    if int(state.get("winner",-1)) != -1 or (vs_ai and int(state.get("faction",-1)) != viewer):
        return output
    output["active"] = true
    var rows: Array[Dictionary] = []
    var can_order: bool = int(state.get("faction",-1)) == viewer and Opening.can_order(state)
    for unit in state["units"]:
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0 or int(unit.get("faction",-1)) != viewer:
            continue
        var pos = unit.get("pos",null)
        if not pos is Vector2i or not Rules.inside(pos,state["terrain"]):
            continue
        var uid: String = str(unit.get("id",""))
        var role: String = str(unit.get("role",""))
        var title: String = "%s · %s" % [uid,Roles.label(role)]
        var supply: String = Logistics.alert(unit)
        var hp: int = int(unit.get("hp",0))
        if not supply.is_empty() or hp <= 5:
            var parts: Array[String] = []
            if hp <= 3:
                parts.append("VIDA CRÍTICA: %d HP" % hp)
            elif hp <= 5:
                parts.append("Vida baja: %d HP" % hp)
            if not supply.is_empty():
                parts.append(supply)
                output["supplies"] = int(output["supplies"]) + 1
            var critical: bool = hp <= 3 or supply.contains("AGOTADA") or supply.contains("SIN COMBUSTIBLE")
            _add(rows,"unit",uid,pos,title," · ".join(parts),0 if critical else 1)
            if critical:
                output["urgent"] = int(output["urgent"]) + 1
        if can_order and Turns.can_act(unit,viewer):
            output["ready_units"] = int(output["ready_units"]) + 1
            var note := "Movimiento ya usado; ataque posible si el arma lo permite" if bool(unit.get("moved",false)) else "Aún sin orden de este turno"
            _add(rows,"unit",uid,pos,title,note,3)

    var site_rows: Array = SiteOverlays.snapshots(state,viewer)
    for site in site_rows:
        if not site is Dictionary:
            continue
        var pos = site.get("pos",null)
        if not pos is Vector2i:
            continue
        var kind: String = str(site.get("kind",""))
        var side: int = int(site.get("owner",-2))
        if bool(site.get("capture_pending",false)):
            output["capture_pending"] = int(output["capture_pending"]) + 1
            _add(rows,"site","",pos,
                "Captura pendiente (%d,%d)" % [pos.x+1,pos.y+1],
                "Se resolverá al finalizar el turno; no es una captura instantánea",2)
        if can_order and side == viewer and kind != "city" and str(site.get("status","")) == "ready":
            output["ready_bases"] = int(output["ready_bases"]) + 1
            _add(rows,"site","",pos,
                "%s (%d,%d)" % [Radar._site_name(kind),pos.x+1,pos.y+1],
                "Producción disponible; entra en Producción para elegir unidad",1)

    # Objective pins are filtered by CURRENT visibility. A remembered site
    # with an unknown owner is never labeled "enemy-controlled" or "neutral".
    var objective_count := 0
    for site in site_rows:
        if objective_count >= MAX_OBJECTIVES:
            break
        if not site is Dictionary:
            continue
        var side: int = int(site.get("owner",-2))
        if side == viewer or side == -2:
            continue
        var pos: Vector2i = site["pos"]
        var what: String = "Ciudad" if str(site.get("kind","")) == "city" else Radar._site_name(str(site.get("kind","")))
        _add(rows,"site","",pos,
            "%s (%d,%d)" % [what,pos.x+1,pos.y+1],
            "Instalación neutral por capturar" if side == -1 else "Instalación rival conocida",5)
        objective_count += 1
        output["objectives"] = int(output["objectives"]) + 1
    if state.get("control") is Dictionary:
        var fogged: bool = Visibility.enabled(state)
        var visible: Dictionary = Visibility.visible_cells(state,viewer) if fogged else {}
        for point in state["control"].get("nodes",[]):
            if objective_count >= MAX_OBJECTIVES:
                break
            if not point is Dictionary or not point.get("pos") is Vector2i:
                continue
            var pos: Vector2i = point["pos"]
            if fogged and not visible.has(pos):
                continue
            var owner: int = int(point.get("owner",-1))
            if owner == viewer:
                continue
            _add(rows,"relay","",pos,
                "Relé (%d,%d)" % [pos.x+1,pos.y+1],
                "Relé neutral visible" if owner == -1 else "Relé rival visible",4)
            objective_count += 1
            output["objectives"] = int(output["objectives"]) + 1

    # Tie-breaking by location then ID makes a 40x30 battle stable while
    # scrolling; crucial shortages always precede idle-unit reminders.
    rows.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        if int(a["urgency"]) != int(b["urgency"]):
            return int(a["urgency"]) < int(b["urgency"])
        var pa: Vector2i = a["pos"]
        var pb: Vector2i = b["pos"]
        if pa.y != pb.y:
            return pa.y < pb.y
        if pa.x != pb.x:
            return pa.x < pb.x
        return str(a.get("id","")) < str(b.get("id",""))
    )
    output["total"] = rows.size()
    output["overflow"] = maxi(0,rows.size()-MAX_ROWS)
    if rows.size() > MAX_ROWS:
        rows.resize(MAX_ROWS)
    output["rows"] = rows
    return output
