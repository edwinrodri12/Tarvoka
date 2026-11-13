extends RefCounted
class_name TarvokaInspectionData

const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

# A read-only view model for both the full sidebar and the Android battle HUD.
# It must never change the game state or reveal hidden enemies/sites.
const SITE_NAMES := {
    "city":"Ciudad", "factory":"Taller", "armor_plant":"Fabrica de blindados",
    "artillery_depot":"Centro de artilleria", "drone_center":"Centro de drones",
    "airbase":"Aerodromo", "shipyard":"Astillero"
}

static func _card(kind: String, title: String, body: String) -> Dictionary:
    return {"kind":kind, "title":title, "body":body}

static func _own_unit(state: Dictionary, unit: Dictionary) -> Dictionary:
    var role: String = str(unit.get("role",""))
    var title: String = "%s · %s" % [Roles.label(role),str(unit.get("id",""))]
    var location: Vector2i = unit.get("pos",Vector2i(-1,-1))
    var kind: String = Terrain.tile_at(state["terrain"],location)
    var economy: Dictionary = state.get("economy",{})
    var cover: int = int(Terrain.COVER.get(kind,0))
    if Terrain.city_at(economy,location) and Domains.domain(unit) == Domains.GROUND:
        cover += Terrain.CITY_COVER
    if Domains.domain(unit) != Domains.GROUND:
        cover = 0
    var body: String = "Vida %d  ·  ATQ %d  ·  DEF %d  ·  MOV %d  ·  Arma %d–%d" % [
        int(unit.get("hp",0)),int(unit.get("attack",0)),int(unit.get("defense",0)),
        int(unit.get("move_points",0)),int(unit.get("attack_min_range",1)),int(unit.get("attack_range",1))
    ]
    body += "\n%s · cobertura +%d" % [Hints.terrain_name(kind),cover]
    if kind == "mountain" and Domains.domain(unit) == Domains.GROUND:
        body += " · altura: +1 ATQ contra tierra baja"
    if unit.has("ammo"):
        body += "\nMunicion %d/%d" % [int(unit["ammo"]),Logistics.ammo_capacity(role)]
        if Logistics.fuel_capacity(role) > 0:
            body += "  ·  Combustible %d/%d" % [int(unit["fuel"]),Logistics.fuel_capacity(role)]
    if bool(unit.get("acted",false)):
        body += "\nTurno completado"
    elif bool(unit.get("moved",false)):
        body += "\nMovimiento usado; ataque disponible si el arma lo permite"
    return _card("friendly",title,body)

static func _enemy_unit(state: Dictionary, enemy_id: String, viewer: int) -> Dictionary:
    var intel: Dictionary = Hints.inspect_enemy(state,enemy_id,viewer)
    if not bool(intel.get("valid",false)):
        return _card("none","","")
    # The observed copy is filtered by fog. Never use private enemy ammo,
    # fuel, reactions or remaining movement to fill an intelligence panel.
    var observed: Dictionary = Visibility.observed_state(state,viewer)
    for unit in observed.get("units",[]):
        if not unit is Dictionary or str(unit.get("id","")) != enemy_id:
            continue
        var role: String = str(unit.get("role",""))
        var title: String = "ENEMIGO · %s · %s" % [Roles.label(role),enemy_id]
        var body: String = "Vida %d  ·  ATQ %d  ·  DEF %d  ·  MOV base %d" % [
            int(unit.get("hp",0)),int(unit.get("attack",0)),int(unit.get("defense",0)),int(unit.get("move_points",0))
        ]
        body += "\nAlcance %d–%d  ·  Amenaza teorica %d casillas" % [
            int(unit.get("attack_min_range",1)),int(unit.get("attack_range",1)),(intel.get("attacks",{}) as Dictionary).size()
        ]
        body += "\n" + Terrain.defensive_description(unit,observed["terrain"],observed.get("economy",{}))
        return _card("enemy",title,body)
    return _card("none","","")

static func _installation(state: Dictionary, site: Dictionary, position: Vector2i, owner_known: bool, viewer: int) -> Dictionary:
    var type: String = str(site.get("kind",""))
    var owner: int = int(site.get("owner",-1))
    var owned_by_viewer: bool = owner == viewer
    var owner_text := "sin confirmar"
    if owner_known:
        owner_text = "Neutral" if owner == -1 else ("Aliada" if owned_by_viewer else "Enemiga")
    var title: String = "%s · %s" % [str(SITE_NAMES.get(type,"Instalacion")),owner_text]
    var body: String = "Casilla %d,%d  ·  Cobertura urbana +1 para tropas terrestres" % [position.x+1,position.y+1]
    if type == "city":
        var income: int = Economy.MODERN_CITY_INCOME if bool(state.get("economy",{}).get("modern",false)) else Economy.CITY_INCOME
        body += "\nIngreso: +%d creditos por turno de su propietario" % income
        body += "\nCaptura: infanteria al finalizar el turno"
    elif owned_by_viewer:
        var site_turn: int = int(site.get("produced_turn",-1))
        var active_turn: int = int(state.get("economy",{}).get("turn",-2))
        body += "\n%s · elige unidad en Opciones" % ("Ya produjo este turno" if site_turn == active_turn else "Lista para producir")
    else:
        body += "\nProduce unidades para su propietario"
    return _card("building",title,body)

static func _land(kind: String, cell: Vector2i) -> Dictionary:
    var movement: int = Rules.movement_cost_for(kind,Domains.GROUND)
    var body: String = "Casilla %d,%d  ·  Movimiento terrestre: %s" % [
        cell.x+1,cell.y+1,"intransitable" if movement < 0 else str(movement)
    ]
    body += "\nCobertura terrestre +%d" % int(Terrain.COVER.get(kind,0))
    if kind == "mountain":
        body += "  ·  Atacar desde arriba: +1 ATQ / desde abajo: -1"
        body += "\nAscenso directo: las unidades lentas gastan todo su movimiento"
    elif kind == "forest":
        body += "\nEl bosque reduce el dano recibido; entrar cuesta 2"
    elif kind == "road":
        body += "\nTransito rapido; sin proteccion adicional"
    elif kind == "water":
        body += "\nSolo unidades navales y aereas"
    return _card("terrain",Hints.terrain_name(kind),body)

static func inspect(state: Dictionary, friendly_id: String, enemy_id: String,
        selected_site: Vector2i, inspected_cell: Vector2i, viewer: int = 0) -> Dictionary:
    var empty: Dictionary = _card("none","","")
    if viewer not in [0,1] or not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]):
        return empty
    for unit in state.get("units",[]):
        if unit is Dictionary and str(unit.get("id","")) == friendly_id and int(unit.get("faction",-1)) == viewer and int(unit.get("hp",0)) > 0 and not friendly_id.is_empty():
            return _own_unit(state,unit)
    if not enemy_id.is_empty():
        var result: Dictionary = _enemy_unit(state,enemy_id,viewer)
        if result["kind"] != "none":
            return result
    var cell: Vector2i = selected_site if Rules.inside(selected_site,state["terrain"]) else inspected_cell
    if not Rules.inside(cell,state["terrain"]):
        return empty
    var fogged: bool = Visibility.enabled(state)
    var revealed: Dictionary = Visibility.explored_cells(state,viewer) if fogged else {}
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if fogged else {}
    if fogged and not revealed.has(cell):
        return _card("unknown","Area sin explorar","Envia un explorador para descubrir esta casilla.")
    var economy: Dictionary = state.get("economy",{})
    var site: Dictionary = Economy.site_at(economy,cell)
    if not site.is_empty():
        var owner_known: bool = not fogged or visible.has(cell) or int(site.get("owner",-1)) == viewer
        return _installation(state,site,cell,owner_known,viewer)
    return _land(Terrain.tile_at(state["terrain"],cell),cell)
