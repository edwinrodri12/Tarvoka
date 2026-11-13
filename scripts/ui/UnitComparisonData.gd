extends RefCounted
class_name TarvokaUnitComparisonData

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")

# Price and numbers come from the actual production catalog. Previewing a
# candidate is read-only; Purchase still requires Economy.can_purchase.
static func candidate(state: Dictionary, site_pos: Vector2i, role: String, viewer: int = 0) -> Dictionary:
    if viewer not in [0,1] or not Roles.valid(role):
        return {}
    var economy: Dictionary = state.get("economy",{})
    var site: Dictionary = Economy.site_at(economy,site_pos)
    if site.is_empty() or int(site.get("owner",-1)) != viewer:
        return {}
    var modern: bool = bool(economy.get("modern",false))
    if Economy.producer_for(role,modern) != str(site.get("kind","")):
        return {}
    var unit: Dictionary = Roles.make_unit("PREVIEW",viewer,site_pos,role)
    if unit.is_empty():
        return {}
    var price: int = Economy.cost(role)
    var funds: Array = economy.get("credits",[])
    var credits: int = int(funds[viewer]) if funds.size() == 2 else 0
    var allowed: bool = Economy.can_purchase(state,site_pos,role) and int(state.get("faction",-1)) == viewer
    var explanation := "Disponible para producir" if allowed else "Producción no disponible"
    if not allowed:
        if int(state.get("winner",-1)) != -1:
            explanation = "La batalla terminó"
        elif int(state.get("faction",-1)) != viewer:
            explanation = "No es tu turno"
        elif int(site.get("produced_turn",-1)) == int(economy.get("turn",-2)):
            explanation = "La instalación ya produjo este turno"
        elif credits < price:
            explanation = "Faltan %d créditos" % (price - credits)
        else:
            explanation = "Instalación ocupada o destino bloqueado"
    var target_domains: Array = Domains.targets(unit)
    var targets: String = "Sin ataque" if int(unit.get("attack",0)) <= 0 or target_domains.is_empty() else "/".join(target_domains)
    var fuel_capacity: int = Logistics.fuel_capacity(role) if modern else 0
    var ammo_capacity: int = Logistics.ammo_capacity(role) if modern else 0
    return {
        "role":role,"name":Roles.label(role),"price":price,
        "available":allowed,"reason":explanation,"funds":credits,
        "hp":int(unit.get("hp",0)),"attack":int(unit.get("attack",0)),
        "defense":int(unit.get("defense",0)),"move":int(unit.get("move_points",0)),
        "vision":int(unit.get("vision",3)),
        "range_min":int(unit.get("attack_min_range",1)),
        "range_max":int(unit.get("attack_range",1)),
        "domain":Domains.domain(unit),"targets":targets,
        "can_capture":Economy.can_capture(unit),
        "ammo_capacity":ammo_capacity,"fuel_capacity":fuel_capacity,
        "note":Roles.counter_description(role),
        "road_fast":modern and Logistics.road_fast(unit)
    }

static func compare(state: Dictionary, site_pos: Vector2i, left_role: String, right_role: String, viewer: int = 0) -> Dictionary:
    var left: Dictionary = candidate(state,site_pos,left_role,viewer)
    var right: Dictionary = candidate(state,site_pos,right_role,viewer) if not right_role.is_empty() else {}
    if left.is_empty():
        return {}
    var rows: Array = []
    for entry in [
        ["hp","VIDA"],["attack","ATAQUE"],["defense","DEFENSA"],
        ["move","MOVIMIENTO"],["vision","VISIÓN"],
        ["range_min","ALCANCE MÍN."],["range_max","ALCANCE MÁX."],
        ["price","PRECIO"]
    ]:
        var key: String = str(entry[0])
        rows.append({
            "metric":str(entry[1]),"left":int(left[key]),
            "right":int(right.get(key,0)) if not right.is_empty() else -1,
            "difference":int(left[key]) - int(right.get(key,0)) if not right.is_empty() else 0
        })
    return {"left":left,"right":right,"rows":rows}
