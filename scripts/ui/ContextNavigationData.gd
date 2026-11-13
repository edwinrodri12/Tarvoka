extends RefCounted
class_name TarvokaContextNavigationData

const Inspector = preload("res://scripts/ui/InspectionData.gd")
const Dossier = preload("res://scripts/ui/UnitDossierData.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const SiteActions = preload("res://scripts/ui/SiteInteractionData.gd")

# Exactly the same visibility-authorized data as the existing quick card.
# This is a read-only presentation model; no action, game state or save mutation.
static func build(state: Dictionary, friendly_id: String, enemy_id: String,
        selected_site: Vector2i, selected_cell: Vector2i, viewer: int = 0) -> Dictionary:
    var quick: Dictionary = Inspector.inspect(state,friendly_id,enemy_id,selected_site,selected_cell,viewer)
    var kind: String = str(quick.get("kind","none"))
    if kind == "none":
        return {}
    var dossier: Dictionary = Dossier.inspect(state,friendly_id,enemy_id,selected_site,selected_cell,viewer)
    var title: String = str(quick.get("title",""))
    var overview: String = str(quick.get("body",""))
    var combat: String = "No hay una unidad seleccionada."
    var movement: String = "Selecciona una unidad para ver movimientos y ventajas posicionales."
    var support: String = "Esta selección no dispone de reabastecimiento."
    var unit_role := ""
    var unit_faction := -1
    var position := selected_site if selected_site.x >= 0 else selected_cell
    var can_produce := false

    if kind in ["friendly","enemy"]:
        var friendly: bool = kind == "friendly"
        var observed: Dictionary = state if friendly else Visibility.observed_state(state,viewer)
        var sought: String = friendly_id if friendly else enemy_id
        for entry in observed.get("units",[]):
            if not entry is Dictionary or str(entry.get("id","")) != sought or int(entry.get("hp",0)) <= 0:
                continue
            var unit: Dictionary = entry
            unit_role = str(unit.get("role",""))
            unit_faction = int(unit.get("faction",-1))
            position = unit.get("pos",Vector2i(-1,-1))
            var domain: String = Domains.domain(unit)
            var terrain_kind: String = Terrain.tile_at(state.get("terrain",[]),position)
            var cover: int = 0
            if domain == Domains.GROUND:
                cover = int(Terrain.COVER.get(terrain_kind,0))
                if Terrain.city_at(state.get("economy",{}),position):
                    cover += Terrain.CITY_COVER
            overview += "\nCoordenadas: %d,%d · %s" % [position.x+1,position.y+1,domain]
            combat = "ATQ %d  ·  DEF %d  ·  RANGO %d–%d\n" % [
                int(unit.get("attack",0)),int(unit.get("defense",0)),
                int(unit.get("attack_min_range",1)),int(unit.get("attack_range",1))]
            combat += "Cobertura defensiva actual +%d (solo tierra).\n" % cover if domain == Domains.GROUND else "Sin cobertura terrestre para esta unidad.\n"
            if friendly:
                var hints: Dictionary = Hints.for_unit(state,sought)
                var footprint: Dictionary = Hints.friendly_weapon_coverage(state,sought)
                combat += "Objetivos legales ahora: %d. Alcance potencial tras mover: %d casillas.\n" % [
                    hints.get("attacks",{}).size(),footprint.size()]
                combat += "El área naranja es potencial; las órdenes se ejecutan únicamente en el mapa y con confirmación."
                movement = "MOV %d · VIS %d\nTerreno: %s\n" % [
                    int(unit.get("move_points",0)),int(unit.get("vision",3)),str(quick.get("body","")).split("\n")[-1]]
                movement += "Destinos legales disponibles: %d.\n" % hints.get("moves",{}).size()
                movement += "Las carreteras aceleran vehículos motorizados; montañas pueden consumir todo el movimiento."
                var has_ammo: bool = unit.has("ammo")
                support = "Sin sistema de combustible para infantería a pie." if not unit.has("fuel") else (
                    "Combustible %d/%d.\n" % [int(unit.get("fuel",0)),Logistics.fuel_capacity(unit_role)])
                if has_ammo:
                    support += "\nMunición %d/%d." % [int(unit.get("ammo",0)),Logistics.ammo_capacity(unit_role)]
                support += "\nReabastecimiento sujeto a fuente compatible, existencias y créditos."
            else:
                var intel: Dictionary = Hints.inspect_enemy(state,sought,viewer)
                combat += "Amenaza teórica en %d casillas conocidas.\n" % intel.get("attacks",{}).size()
                combat += "La vista NO revela movimientos pendientes, munición ni combustible enemigos."
                movement = "MOV base %d · VIS %d\nDominio %s.\n" % [
                    int(unit.get("move_points",0)),int(unit.get("vision",3)),domain]
                movement += "El alcance dibujado es teórico; no confirma la ruta futura que elegirá el rival."
                support = "SUMINISTROS ENEMIGOS: información no disponible.\nNo se muestra munición, combustible ni acciones internas."
            break
    elif kind == "building":
        position = dossier.get("position",position)
        var public_site: Dictionary = SiteActions.describe(state,position,viewer)
        can_produce = bool(public_site.get("production",false))
        var site_kind: String = str(public_site.get("kind",""))
        combat = "Las instalaciones no disparan por sí mismas.\nLas unidades terrestres sobre una ciudad obtienen +1 cobertura."
        movement = "Posición %d,%d.\n" % [position.x+1,position.y+1]
        movement += "La ocupación de una instalación no ejecuta una compra ni captura automáticamente."
        if site_kind == "city":
            support = "Economía: +%d créditos por turno para su propietario.\n" % int(public_site.get("income",0))
            support += "Captura con infantería al finalizar el turno."
        elif can_produce:
            support = "Base aliada: puede producir las unidades habilitadas por su dominio.\n"
            support += "Se comprueba el presupuesto, disponibilidad por turno y espacio al confirmar."
        else:
            support = "Producción no disponible para tu bando en esta ubicación."
        if bool(public_site.get("capture_pending",false)):
            support += "\nCaptura pendiente: se resuelve al terminar turno."
    elif kind == "terrain":
        var terrain_kind: String = Terrain.tile_at(state.get("terrain",[]),position)
        var ground_cost: int = int(3 if terrain_kind == "mountain" else 2 if terrain_kind == "forest" else 1 if terrain_kind in ["plain","road"] else -1)
        combat = "Cobertura terrestre: +%d.\n" % int(Terrain.COVER.get(terrain_kind,0))
        combat += "La altura modifica ataque y contraataque terrestre cuando hay diferencia de nivel."
        movement = "Entrada para infantería: %s.\n" % ("bloqueada" if ground_cost < 0 else str(ground_cost))
        movement += "Carretera: ½ punto para vehículos motorizados; 1 para infantería.\nMontaña: las unidades lentas pueden subir una casilla adyacente consumiendo todo su movimiento."
        support = "La casilla no genera créditos ni munición por sí sola."
    elif kind == "unknown":
        combat = "Sin datos de combate confirmados."
        movement = "Área todavía sin explorar."
        support = "No hay información disponible."

    return {
        "kind":kind,"title":title,"subtitle":("FICHA TÁCTICA / " + kind.to_upper()),
        "position":position,"role":unit_role,"faction":unit_faction,
        "overview":overview,"combat":combat,"movement":movement,
        "support":support,"can_produce":can_produce,
        "friendly":kind == "friendly","unit_id":friendly_id if kind == "friendly" else enemy_id
    }
