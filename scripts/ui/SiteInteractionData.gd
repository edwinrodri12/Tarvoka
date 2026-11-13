extends RefCounted
class_name TarvokaSiteInteractionData

const SiteOverlays = preload("res://scripts/ui/SiteOverlayData.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Rules = preload("res://scripts/core/Rules.gd")

# This is an intelligence-limited, read-only view of a selected site.
# It only lists friendly capturers; never schedules movement or spends money.
# Manhattan distance is a sorting heuristic, NOT a travel-time estimate.
const MAX_VISIBLE_CAPTURERS := 8

static func describe(state: Dictionary, cell: Vector2i, viewer: int = 0) -> Dictionary:
    if viewer not in [0,1] or not state.get("terrain") is Array or not Rules.inside(cell,state["terrain"]):
        return {}
    var marker: Dictionary = {}
    for candidate in SiteOverlays.snapshots(state,viewer):
        if candidate is Dictionary and candidate.get("pos",null) == cell:
            marker = candidate
            break
    if marker.is_empty():
        return {} # Undiscovered site, even if the underlying state contains it.
    var site_kind: String = str(marker.get("kind",""))
    var owner: int = int(marker.get("owner",-2))
    var names := {
        "city":"Ciudad","factory":"Taller","armor_plant":"Fábrica blindada",
        "artillery_depot":"Centro artillero","drone_center":"Centro de drones",
        "airbase":"Aeródromo","shipyard":"Astillero"
    }
    var owner_label := "sin confirmar"
    match owner:
        0:
            owner_label = "aliado" if viewer == 0 else "enemigo"
        1:
            owner_label = "aliado" if viewer == 1 else "enemigo"
        -1:
            owner_label = "neutral"
    var detail: String = "Propietario %s." % owner_label
    if site_kind == "city":
        detail += " +%d créditos para su propietario al iniciar turno." % int(marker.get("income",0))
    elif owner == viewer:
        detail += " %s." % str(marker.get("caption","Base propia"))
    else:
        detail += " Instalación militar."
    if bool(marker.get("capture_pending",false)):
        detail += " Captura pendiente: se resuelve al terminar turno."
    var cap_units: Array = []
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("faction",-1)) != viewer:
            continue
        if not Economy.can_capture(unit):
            continue
        var position = unit.get("pos",null)
        if not position is Vector2i:
            continue
        cap_units.append({
            "id":str(unit.get("id","")),
            "role":str(unit.get("role","")),
            "label":Roles.label(str(unit.get("role",""))),
            "pos":position,
            "distance":absi(position.x-cell.x)+absi(position.y-cell.y),
            "at_site":position == cell,
            "reachable_now":false,
            "ready":not bool(unit.get("moved",false)) and not bool(unit.get("acted",false))
        })
    cap_units.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        if int(a["distance"]) != int(b["distance"]):
            return int(a["distance"]) < int(b["distance"])
        return str(a["id"]) < str(b["id"])
    )
    var total: int = cap_units.size()
    if total > MAX_VISIBLE_CAPTURERS:
        cap_units.resize(MAX_VISIBLE_CAPTURERS)
    # The authoritative tactical hints validate terrain, road discounts,
    # occupancy, fog, remaining movement and turn ownership.
    if int(state.get("faction",-1)) == viewer and int(state.get("winner",-1)) == -1:
        for unit in cap_units:
            if not bool(unit["at_site"]):
                var legal: Dictionary = Hints.for_unit(state,str(unit["id"]))
                unit["reachable_now"] = legal.get("moves",{}).has(cell)
    return {
        "valid":true,"pos":cell,"kind":site_kind,
        "title":str(names.get(site_kind,"Instalación")),
        "owner":owner, "owner_known":bool(marker.get("owner_known",false)),
        "detail":detail,"income":int(marker.get("income",0)),
        "status":str(marker.get("status","unknown")),
        "capture_pending":bool(marker.get("capture_pending",false)),
        "production":site_kind != "city" and owner == viewer,
        "capturers":cap_units,"capturer_count":total
    }
