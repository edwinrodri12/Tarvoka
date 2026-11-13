extends RefCounted
class_name TarvokaSiteOverlayData

const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# Read-only snapshot for classic/isometric map badges. Only confirmed sight
# can disclose an enemy or neutral site's CURRENT owner. Previously explored
# sites remain visible with an unknown owner, never a stale "enemy" flag.
# No production details belonging to the enemy are included in the snapshot.

static func snapshots(state: Dictionary, viewer: int = 0) -> Array:
    var result: Array = []
    if viewer not in [0,1] or not state.has("economy"):
        return result
    var economy: Dictionary = state["economy"]
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if fog else {}
    var explored: Dictionary = Visibility.explored_cells(state,viewer) if fog else {}
    var modern: bool = bool(economy.get("modern",false))
    var revenue: int = Economy.MODERN_CITY_INCOME if modern else Economy.CITY_INCOME
    for site in economy.get("sites",[]):
        if not site is Dictionary or not site.get("pos") is Vector2i:
            continue
        var cell: Vector2i = site["pos"]
        var real_owner: int = int(site.get("owner",-1))
        if fog and not explored.has(cell) and real_owner != viewer:
            continue
        var owner_known: bool = not fog or visible.has(cell) or real_owner == viewer
        var public_owner: int = real_owner if owner_known else -2
        var kind: String = str(site.get("kind",""))
        var item: Dictionary = {
            "pos":cell, "kind":kind, "owner":public_owner,
            "owner_known":owner_known,"income":revenue if kind == "city" else 0,
            "status":"city" if kind == "city" else "unknown",
            "caption":"", "capture_pending":false
        }
        # Only a friendly occupying capturer can create a capture hint. Capture
        # happens on end_turn, not gradually and not on the first tap.
        if kind == "city" and real_owner != viewer:
            for unit in state.get("units",[]):
                if unit is Dictionary and int(unit.get("hp",0)) > 0 and int(unit.get("faction",-1)) == viewer and unit.get("pos") == cell and Economy.can_capture(unit):
                    item["capture_pending"] = true
                    item["caption"] = "Captura al finalizar turno"
                    item["status"] = "capture"
                    break
        elif kind != "city" and real_owner == viewer:
            item["status"] = _own_factory_status(state,site,viewer,modern)
            match str(item["status"]):
                "ready":
                    item["caption"] = "Producción disponible"
                "used":
                    item["caption"] = "Ya produjo este turno"
                "wait":
                    item["caption"] = "Esperando turno"
                "funds":
                    item["caption"] = "Fondos insuficientes"
                "blocked":
                    item["caption"] = "Producción bloqueada"
                _:
                    item["caption"] = "Instalación propia"
        result.append(item)
    return result

static func _own_factory_status(state: Dictionary, site: Dictionary, viewer: int, modern: bool) -> String:
    var economy: Dictionary = state["economy"]
    if int(site.get("produced_turn",-1)) == int(economy.get("turn",-2)):
        return "used"
    if int(state.get("winner",-1)) != -1:
        return "wait"
    if int(state.get("faction",-1)) != viewer:
        return "wait"
    var roles: Array = Roles.ORDER.duplicate()
    if modern:
        roles.append_array(Arsenal.ORDER)
    var min_cost := 9999999
    var has_role := false
    for role_id in roles:
        var role: String = str(role_id)
        if Economy.producer_for(role,modern) != str(site.get("kind","")):
            continue
        has_role = true
        min_cost = mini(min_cost,Economy.cost(role))
        if Economy.can_purchase(state,site["pos"],role):
            return "ready"
    if not has_role:
        return "blocked"
    var funds: Array = economy.get("credits",[])
    if funds.size() > viewer and int(funds[viewer]) < min_cost:
        return "funds"
    return "blocked"
