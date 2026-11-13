extends RefCounted
class_name TarvokaUnitDossierData

const Inspect = preload("res://scripts/ui/InspectionData.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Rules = preload("res://scripts/core/Rules.gd")

# Extra, structured fields for visual battle fichas. A prior Inspector.inspect
# must approve visibility before any enemy or building fields are considered.
# Never expose hostile ammunition, fuel, reaction flags or private turns.
static func inspect(state: Dictionary, friendly_id: String, enemy_id: String,
        selected_site: Vector2i, selected_cell: Vector2i, viewer: int = 0) -> Dictionary:
    var base: Dictionary = Inspect.inspect(state,friendly_id,enemy_id,selected_site,selected_cell,viewer)
    var kind: String = str(base.get("kind","none"))
    if kind == "friendly":
        for unit in state.get("units",[]):
            if unit is Dictionary and str(unit.get("id","")) == friendly_id and int(unit.get("faction",-1)) == viewer and int(unit.get("hp",0)) > 0:
                return _unit_data(unit,state,true)
    if kind == "enemy":
        var observed: Dictionary = Visibility.observed_state(state,viewer)
        for unit in observed.get("units",[]):
            if unit is Dictionary and str(unit.get("id","")) == enemy_id and int(unit.get("faction",-1)) != viewer and int(unit.get("hp",0)) > 0:
                return _unit_data(unit,observed,false)
    if kind == "building":
        var cell: Vector2i = selected_site if Rules.inside(selected_site,state["terrain"]) else selected_cell
        var site: Dictionary = Economy.site_at(state.get("economy",{}),cell)
        if site.is_empty():
            return {}
        var sight: Dictionary = Visibility.visible_cells(state,viewer) if Visibility.enabled(state) else {}
        var known_owner: bool = not Visibility.enabled(state) or sight.has(cell) or int(site.get("owner",-1)) == viewer
        var owner: int = int(site.get("owner",-1))
        var owner_label: String = "Sin confirmar"
        if known_owner:
            owner_label = "Neutral" if owner == -1 else ("Aliado" if owner == viewer else "Rival")
        var kind_name: String = str(site.get("kind",""))
        var economy: Dictionary = state.get("economy",{})
        var data := {
            "kind":"building","name":str(base.get("title","")),
            "owner":owner_label,"position":cell,"site_kind":kind_name,
            "stats":[],"note":str(base.get("body",""))
        }
        if kind_name == "city":
            var revenue: int = Economy.MODERN_CITY_INCOME if bool(economy.get("modern",false)) else Economy.CITY_INCOME
            data["stats"] = [{"name":"INGRESO","value":"+%d/turno" % revenue},{"name":"CAPTURA","value":"Infantería"}]
        elif known_owner and owner == viewer:
            var ready: bool = int(site.get("produced_turn",-1)) != int(economy.get("turn",-2))
            data["stats"] = [{"name":"PRODUCCIÓN","value":"Lista" if ready else "Usada"}]
            data["note"] = "Base propia · elige una unidad en Centro de mando > Producción."
        else:
            data["stats"] = [{"name":"PRODUCCIÓN","value":"Propietario"}]
        return data
    return {} # Unknown terrain is shown by the existing safe text presenter.

static func _unit_data(unit: Dictionary, observed: Dictionary, friendly: bool) -> Dictionary:
    var role: String = str(unit.get("role",""))
    var profile: Dictionary = Roles.PROFILES.get(role,Arsenal.profile(role))
    var position: Vector2i = unit.get("pos",Vector2i(-1,-1))
    var domain: String = Domains.domain(unit)
    var terrain_name: String = Terrain.tile_at(observed.get("terrain",[]),position)
    var cover: int = 0
    if domain == Domains.GROUND:
        cover = int(Terrain.COVER.get(terrain_name,0))
        if Terrain.city_at(observed.get("economy",{}),position):
            cover += Terrain.CITY_COVER
    var current_hp: int = int(unit.get("hp",0))
    var max_hp: int = maxi(current_hp,int(profile.get("hp",current_hp)))
    var result := {
        "kind":"friendly" if friendly else "enemy",
        "name":Roles.label(role),"role":role,"unit_id":str(unit.get("id","")),
        "faction":int(unit.get("faction",-1)),
        "hp":current_hp,"max_hp":max_hp,
        "stats":[
            {"name":"ATQ","value":str(unit.get("attack",0))},
            {"name":"DEF","value":str(unit.get("defense",0))},
            {"name":"MOV","value":str(unit.get("move_points",0))},
            {"name":"VIS","value":str(unit.get("vision",3))},
            {"name":"ARMA","value":"%d-%d" % [int(unit.get("attack_min_range",1)),int(unit.get("attack_range",1))]},
            {"name":"COB","value":"+%d" % cover}
        ],
        "note":Roles.counter_description(role),
        "domain":domain
    }
    if friendly:
        result["status"] = "Turno completado" if bool(unit.get("acted",false)) else ("Movimiento agotado" if bool(unit.get("moved",false)) else "Lista")
        if unit.has("ammo"):
            result["ammo"] = int(unit.get("ammo",0))
            result["ammo_max"] = Logistics.ammo_capacity(role)
            if Logistics.fuel_capacity(role) > 0:
                result["fuel"] = int(unit.get("fuel",0))
                result["fuel_max"] = Logistics.fuel_capacity(role)
    else:
        result["status"] = "Alcance y cobertura conocidos · suministros desconocidos"
    return result
