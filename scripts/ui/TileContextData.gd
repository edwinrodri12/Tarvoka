extends RefCounted
class_name TarvokaTileContextData

# Read-only terrain/site facts for the battle HUD. A coordinate never grants
# permission to act. Hidden land and site owners are filtered before any
# economy or tactical detail is exposed.
const Rules = preload("res://scripts/core/Rules.gd")
const Weather = preload("res://scripts/core/Weather.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const SiteOverlays = preload("res://scripts/ui/SiteOverlayData.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Inspect = preload("res://scripts/ui/InspectionData.gd")

static func _cost(kind: String, domain: String, climate: String, chassis: String = "foot", motorized: bool = false) -> String:
    var half: int = Rules.entry_cost_half(kind,domain,motorized,climate,chassis)
    if half < 0:
        return "—"
    return str(half / 2) if half % 2 == 0 else "%.1f" % (float(half) / 2.0)

static func snapshot(state: Dictionary, cell: Vector2i, viewer: int = 0) -> Dictionary:
    var empty := {"kind":"none"}
    if viewer not in [0,1] or not state.get("terrain") is Array or not Rules.valid_terrain(state["terrain"]) or not Rules.inside(cell,state["terrain"]):
        return empty
    var fog: bool = Visibility.enabled(state)
    if fog and not Visibility.explored_cells(state,viewer).has(cell):
        return {
            "kind":"unknown","title":"ZONA SIN EXPLORAR",
            "location":"%d,%d" % [cell.x+1,cell.y+1],
            "movement":"Movimiento: sin datos","defense":"Cobertura: sin datos",
            "status":"El terreno permanece oculto. Envia una unidad exploradora.",
            "owner":"Sin confirmar","production":false,"capture_pending":false
        }
    var kind: String = Terrain.tile_at(state["terrain"],cell)
    var marker: Dictionary = {}
    # Source-of-truth redaction: unknown hostile owners cannot leak production
    # status, even when the terrain beneath the site has been explored before.
    for candidate in SiteOverlays.snapshots(state,viewer):
        if candidate is Dictionary and candidate.get("pos",null) == cell:
            marker = candidate
            break
    var climate: String = Weather.from_state(state)
    var movement: String = "INF %s  ·  VEH %s  ·  ORU %s  ·  AIR %s  ·  MAR %s" % [
        _cost(kind,Domains.GROUND,climate,Weather.FOOT),
        _cost(kind,Domains.GROUND,climate,Weather.WHEELED,true),
        _cost(kind,Domains.GROUND,climate,Weather.TRACKED,true),
        _cost(kind,Domains.AIR,climate,Weather.AIR),
        _cost(kind,Domains.NAVAL,climate,Weather.NAVAL)]
    var cover: int = int(Terrain.COVER.get(kind,0))
    if str(marker.get("kind","")) == "city":
        cover += Terrain.CITY_COVER
    var altitude: int = Terrain.height_of(kind)
    var defense: String = "Cobertura terrestre +%d  ·  Altura %d" % [cover,altitude]
    if altitude > 0:
        defense += "  ·  ATQ +/-1 por desnivel"
    var title: String = Hints.terrain_name(kind).to_upper()
    var status: String = "Clima %s · costes de entrada por casilla, carretera más rápida para motor." % Weather.label(climate)
    var owner := ""
    var production := false
    var capture_pending := false
    var category := "terrain"
    if not marker.is_empty():
        category = "building"
        title = str(Inspect.SITE_NAMES.get(str(marker.get("kind","")),"Instalacion")).to_upper()
        var known: bool = bool(marker.get("owner_known",false))
        var side: int = int(marker.get("owner",-2))
        owner = "Sin confirmar"
        if known:
            owner = "Neutral" if side == -1 else ("Aliado" if side == viewer else "Rival")
        capture_pending = bool(marker.get("capture_pending",false))
        production = known and side == viewer and str(marker.get("kind","")) != "city"
        var site_type: String = str(marker.get("kind",""))
        if site_type == "city":
            status = "Ingresos: +%d creditos por turno del propietario." % int(marker.get("income",0))
        elif production:
            var producer_text: Dictionary = {
                "ready":"Produccion disponible","used":"Ya produjo este turno",
                "wait":"Espera tu turno","funds":"Creditos insuficientes",
                "blocked":"Produccion bloqueada"
            }
            status = str(producer_text.get(str(marker.get("status","")),"Sin produccion disponible"))
        else:
            status = "Instalacion militar. Propiedad %s." % owner.to_lower()
        if capture_pending:
            status += " Captura pendiente al finalizar turno."
    return {
        "kind":category,"title":title,
        "location":"%d,%d" % [cell.x+1,cell.y+1],
        "movement":movement,"defense":defense,
        "status":status,"owner":owner,
        "production":production,"capture_pending":capture_pending
    }
