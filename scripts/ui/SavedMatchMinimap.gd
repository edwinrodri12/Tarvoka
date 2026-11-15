extends Control
class_name TarvokaSaveSlotMinimap

# Read-only thumbnail of a SaveStore-validated battle snapshot. Does not
# reveal hidden information to an opponent because this is a load screen.
const Style = preload("res://scripts/ui/VisualStyle.gd")

var snapshot: Dictionary = {}
var is_recovered := false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(160,92)
    resized.connect(queue_redraw)

func set_snapshot(state: Dictionary, recovered: bool = false) -> void:
    snapshot = state.duplicate(true)
    is_recovered = recovered
    queue_redraw()

func _draw() -> void:
    var bounds := size
    if bounds.x <= 1.0 or bounds.y <= 1.0:
        return
    draw_rect(Rect2(Vector2.ZERO,bounds),Color("#081B2A"))
    var terrain: Array = snapshot.get("terrain",[])
    if terrain.is_empty():
        draw_string(ThemeDB.fallback_font,Vector2(12,bounds.y*0.54),
            "SIN VISTA PREVIA",HORIZONTAL_ALIGNMENT_LEFT,-1,
            13,Color("#9AB7C7"))
        return
    var rows: int = terrain.size()
    var first_row: Array = terrain[0]
    var cols: int = first_row.size()
    if rows < 1 or cols < 1:
        return
    var edge: float = 7.0
    var cell: float = minf((bounds.x-2.0*edge)/float(cols),
        (bounds.y-2.0*edge)/float(rows))
    if cell <= 1.0:
        return
    var map_size := Vector2(float(cols)*cell,float(rows)*cell)
    var origin: Vector2 = (bounds-map_size)*0.5
    for y in range(rows):
        var line: Array = terrain[y]
        for x in range(mini(cols,line.size())):
            draw_rect(Rect2(origin+Vector2(x*cell,y*cell),
                Vector2(cell-0.5,cell-0.5)),
                Style.terrain_color(str(line[x]),x,y))
    for unit in snapshot.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0)) <= 0:
            continue
        var pos: Vector2i = unit.get("pos",Vector2i(-1,-1))
        if pos.x < 0 or pos.x >= cols or pos.y < 0 or pos.y >= rows:
            continue
        var dot: Vector2 = origin+Vector2(
            (float(pos.x)+0.5)*cell,(float(pos.y)+0.5)*cell)
        draw_circle(dot,maxf(1.5,cell*0.29),Color("#061520"))
        draw_circle(dot,maxf(1.2,cell*0.22),
            Color("#3A99FF") if int(unit.get("faction",-1)) == 0
            else Color("#EF5A64"))
    draw_rect(Rect2(origin,map_size),Color("#8AC5D1"),false,1.0)
    if is_recovered:
        draw_string(ThemeDB.fallback_font,Vector2(8,15),
            "COPIA RECUPERADA",HORIZONTAL_ALIGNMENT_LEFT,-1,11,
            Color("#FFD65E"))
