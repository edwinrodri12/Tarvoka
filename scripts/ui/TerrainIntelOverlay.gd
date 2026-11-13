extends RefCounted
class_name TarvokaTerrainIntelOverlay

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")

# Read-only screen layer, never part of the battle state or save file.
# 0 = off, 1 = ground defensive cover, 2 = entry movement cost.
const OFF := 0
const DEFENSE := 1
const MOBILITY := 2

static func context_for(state: Dictionary, selected_id: String) -> Dictionary:
    var result := {"domain":Domains.GROUND,"motorized":false,"move_points":3,"cities":{}}
    for site in state.get("economy",{}).get("sites",[]):
        if site is Dictionary and str(site.get("kind","")) == "city" and site.get("pos") is Vector2i:
            result["cities"][site["pos"]] = true
    var active_faction: int = int(state.get("faction",0))
    for candidate in state.get("units",[]):
        if not candidate is Dictionary:
            continue
        if str(candidate.get("id","")) != selected_id or int(candidate.get("faction",-1)) != active_faction or int(candidate.get("hp",0)) <= 0:
            continue
        result["domain"] = Domains.domain(candidate)
        result["motorized"] = Logistics.road_fast(candidate)
        result["move_points"] = int(candidate.get("move_points",3))
        break
    return result

static func can_show_cell(fog: bool, explored: Dictionary, cell: Vector2i) -> bool:
    return not fog or explored.has(cell)

static func badge(kind: String, cell: Vector2i, mode: int, context: Dictionary,
        outside_current_vision: bool = false) -> Dictionary:
    if mode not in [DEFENSE,MOBILITY] or not Rules.TERRAIN_COST.has(kind):
        return {}
    var domain: String = str(context.get("domain",Domains.GROUND))
    var opacity: float = 0.48 if outside_current_vision else 1.0
    if mode == DEFENSE:
        # Air units and ships receive NO fictitious ground-defense bonus.
        if domain != Domains.GROUND:
            return {}
        var cover: int = int(Terrain.COVER.get(kind,0))
        if context.get("cities",{}).has(cell):
            cover += Terrain.CITY_COVER
        if cover <= 0:
            return {}
        var tint := Color("#3DCB94") if cover == 1 else Color("#47C6F5")
        return {"label":"+%d" % cover, "tint":tint, "opacity":opacity,
            "cost":0,"cover":cover}
    var cost: int = Rules.movement_cost_for(kind,domain)
    if cost < 0:
        return {"label":"×","tint":Color("#D76F68"),"opacity":opacity,
            "cost":-1,"cover":0}
    var fast_road: bool = domain == Domains.GROUND and bool(context.get("motorized",false)) and kind == "road"
    var special_climb: bool = domain == Domains.GROUND and kind == "mountain" and int(context.get("move_points",3)) < 3
    var label: String = "½" if fast_road else ("%d*" % cost if special_climb else str(cost))
    var tint := Color("#58D8A2") if fast_road else (Color("#F1A564") if cost >= 3 else
        (Color("#F2CF79") if cost == 2 else Color("#80A9CC")))
    return {"label":label,"tint":tint,"opacity":opacity,
        "cost":0.5 if fast_road else float(cost),"cover":0}

static func draw_classic(canvas: CanvasItem, tile_rect: Rect2, info: Dictionary) -> void:
    if info.is_empty() or tile_rect.size.x < 11.0:
        return
    var tint: Color = info["tint"]
    tint.a = 0.18 * float(info["opacity"])
    canvas.draw_rect(tile_rect,tint)
    if tile_rect.size.x < 39.0:
        return
    var label: String = str(info["label"])
    var font_size: int = clampi(roundi(tile_rect.size.x * 0.22),11,19)
    var label_width: float = maxf(tile_rect.size.x*0.29,float(label.length())*font_size*0.57)
    var panel: Rect2 = Rect2(tile_rect.position+Vector2(2,2),Vector2(label_width+5,font_size+5))
    canvas.draw_rect(panel,Color(0.025,0.060,0.080,0.87*float(info["opacity"])))
    var ink: Color = info["tint"]
    ink.a = float(info["opacity"])
    canvas.draw_string(ThemeDB.fallback_font,panel.position+Vector2(3,font_size+1),label,
        HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)

static func draw_iso(canvas: CanvasItem, polygon: PackedVector2Array, center: Vector2,
        half_width: float, info: Dictionary) -> void:
    if info.is_empty():
        return
    var tint: Color = info["tint"]
    tint.a = 0.18 * float(info["opacity"])
    canvas.draw_colored_polygon(polygon,tint)
    if half_width < 36.0:
        return
    var label: String = str(info["label"])
    var font_size: int = clampi(roundi(half_width*0.21),10,18)
    var top: Vector2 = center + Vector2(half_width*0.16,-half_width*0.25)
    var rect: Rect2 = Rect2(top,Vector2(maxf(half_width*0.29,float(label.length())*font_size*0.55)+5,font_size+5))
    canvas.draw_rect(rect,Color(0.025,0.060,0.080,0.86*float(info["opacity"])))
    var ink: Color = info["tint"]
    ink.a = float(info["opacity"])
    canvas.draw_string(ThemeDB.fallback_font,top+Vector2(3,font_size+1),label,
        HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,ink)
