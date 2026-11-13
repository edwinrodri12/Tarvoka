extends RefCounted
class_name TarvokaObjectivesRadarData

const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const SiteOverlays = preload("res://scripts/ui/SiteOverlayData.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

const MAX_ALERT_ROWS := 12

# Read-only operational radar. No fictitious victory conditions, invisible
# enemies, live enemy property changes, fuel/ammo guesses or hidden routes.
# "Main mission" is derived from the active mode's actual win condition.
static func build(state: Dictionary, viewer: int = 0) -> Dictionary:
    var empty := {"valid":false,"heading":"","summary":"","objective":"","details":"",
        "sites":[],"relays":[],"alerts":[],"income":0,"owned_cities":0,
        "owned_bases":0,"alert_count":0}
    if viewer not in [0,1] or not state.get("terrain") is Array or state["terrain"].is_empty():
        return empty
    var data: Dictionary = empty.duplicate(true)
    data["valid"] = true
    data["heading"] = "RADAR DE OBJETIVOS"
    var game_finished: bool = int(state.get("winner",-1)) != -1
    var economy: Dictionary = state.get("economy",{})
    var funds: Array = economy.get("credits",[])
    var credits: String = str(funds[viewer]) if funds.size() > viewer else "—"
    var own_count := 0
    for unit in state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == viewer and int(unit.get("hp",0)) > 0:
            own_count += 1
    data["summary"] = "%s unidades · %s créditos" % [own_count,credits]
    if state.has("control"):
        var control: Dictionary = state["control"]
        var scores: Array = control.get("scores",[])
        if scores.size() == 2:
            var my_signal: int = int(scores[viewer])
            var target: int = int(control.get("target",0))
            data["objective"] = "Señal táctica: %d / %d" % [my_signal,target]
            data["details"] = "Controla relés y suma señal hasta el objetivo. La puntuación respeta las reglas de turnos del escenario."
        else:
            data["objective"] = "Control de relés"
            data["details"] = "Asegura los objetivos del mapa."
        var fog: bool = Visibility.enabled(state)
        var visible: Dictionary = Visibility.visible_cells(state,viewer) if fog else {}
        for node in control.get("nodes",[]):
            if not node is Dictionary or not node.get("pos") is Vector2i:
                continue
            var position: Vector2i = node["pos"]
            # Relay positions are public objectives; owner is observable only
            # under current line of sight in fog, never from private state.
            var owner_known: bool = not fog or visible.has(position)
            var owner: int = int(node.get("owner",-1)) if owner_known else -2
            data["relays"].append({"pos":position,"owner":owner,
                "label":"Relé (%d,%d)" % [position.x+1,position.y+1],
                "status":_owner_label(owner,viewer)})
    else:
        data["objective"] = "Neutralizar el ejército rival"
        data["details"] = "Objetivo principal: derrotar las fuerzas enemigas. La conquista de ciudades no sustituye la condición de victoria."
    if game_finished:
        data["details"] = ("Victoria conseguida." if int(state["winner"]) == viewer else "Batalla terminada.") + " " + data["details"]

    var sites: Array = SiteOverlays.snapshots(state,viewer)
    var modern: bool = bool(economy.get("modern",false))
    for site in sites:
        if not site is Dictionary:
            continue
        var kind: String = str(site.get("kind",""))
        var pos: Vector2i = site.get("pos",Vector2i(-1,-1))
        var owner: int = int(site.get("owner",-2))
        var category: String = "Ciudad" if kind == "city" else _site_name(kind)
        var status: String = _owner_label(owner,viewer)
        if kind == "city" and owner == viewer:
            data["owned_cities"] += 1
        elif kind != "city" and owner == viewer:
            data["owned_bases"] += 1
        if bool(site.get("capture_pending",false)):
            status = "Captura al finalizar turno"
        elif owner == viewer and kind != "city":
            status = _factory_status(str(site.get("status","")))
        var row := {
            "pos":pos, "kind":kind,"label":"%s (%d,%d)" % [category,pos.x+1,pos.y+1],
            "status":status,"owner":owner,
            "income":int(site.get("income",0)) if kind == "city" else 0,
            "capture_pending":bool(site.get("capture_pending",false)),
            "priority":0 if bool(site.get("capture_pending",false)) else (
                1 if owner in [-1,1-viewer] else (2 if owner == -2 else 3))
        }
        data["sites"].append(row)
    data["sites"].sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        if int(a["priority"]) != int(b["priority"]):
            return int(a["priority"]) < int(b["priority"])
        if str(a["kind"]) == "city" and str(b["kind"]) != "city":
            return true
        if str(a["kind"]) != "city" and str(b["kind"]) == "city":
            return false
        return int(a["pos"].y*10000+a["pos"].x) < int(b["pos"].y*10000+b["pos"].x))
    if not economy.is_empty():
        data["income"] = Economy.income_for(economy,viewer)
        data["summary"] += " · %d ciudades (+%d/turno)" % [int(data["owned_cities"]),int(data["income"])]
    # Read only friendly unit supplies; never infer enemy ammo, HP or fuel from
    # unseen combatants. Alerts are symptoms, not fictitious danger predictions.
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0 or int(unit.get("faction",-1)) != viewer:
            continue
        var hp: int = int(unit.get("hp",0))
        var role: String = str(unit.get("role",""))
        var condition := ""
        var urgency := 3
        if hp <= 3:
            condition = "Vida crítica (%d HP)" % hp
            urgency = 0
        elif hp <= 5:
            condition = "Unidad dañada (%d HP)" % hp
            urgency = 2
        var supplies: String = Logistics.alert(unit)
        if not supplies.is_empty():
            if not condition.is_empty():
                condition += " · "
            condition += supplies
            if supplies.contains("AGOTADA") or supplies.contains("SIN COMBUSTIBLE"):
                urgency = 0
            else:
                urgency = mini(urgency,1)
        if condition.is_empty():
            continue
        var position = unit.get("pos",null)
        if not position is Vector2i:
            continue
        data["alerts"].append({
            "id":str(unit.get("id","")),"pos":position,"role":role,
            "label":"%s · %s" % [str(unit.get("id","")),Roles.label(role)],
            "status":condition,"urgency":urgency
        })
    data["alerts"].sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        if int(a["urgency"]) != int(b["urgency"]):
            return int(a["urgency"]) < int(b["urgency"])
        return str(a["id"]) < str(b["id"]))
    data["alert_count"] = data["alerts"].size()
    if data["alerts"].size() > MAX_ALERT_ROWS:
        data["alerts"].resize(MAX_ALERT_ROWS)
    return data

static func _owner_label(owner: int, viewer: int) -> String:
    if owner == viewer:
        return "Aliada"
    if owner == 1-viewer:
        return "Enemiga"
    if owner == -1:
        return "Neutral"
    return "Control sin confirmar"

static func _site_name(kind: String) -> String:
    return str({
        "factory":"Taller","armor_plant":"Fábrica blindada",
        "artillery_depot":"Centro de artillería","drone_center":"Centro de drones",
        "airbase":"Aeródromo","shipyard":"Astillero"
    }.get(kind,"Instalación"))

static func _factory_status(value: String) -> String:
    return str({
        "ready":"Producción disponible","used":"Ya produjo este turno",
        "wait":"Esperando turno","funds":"Fondos insuficientes",
        "blocked":"Producción bloqueada"
    }.get(value,"Instalación aliada"))
