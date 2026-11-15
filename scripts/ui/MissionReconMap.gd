extends Control
class_name TarvokaMissionReconMap

# A faithful non-interactive miniature of playable C01's initial state.
# No campaign checkpoint is read or written here. This is not a fake map.
const Mission = preload("res://scripts/core/CampaignMission.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Beacons := [Vector2i(4,2), Vector2i(5,5)]

var _start: Dictionary = {}

func _ready() -> void:
    custom_minimum_size = Vector2(285,180)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _start = Mission.start_c01()
    resized.connect(queue_redraw)
    queue_redraw()

func _draw() -> void:
    if size.x < 1.0 or size.y < 1.0:
        return
    draw_rect(Rect2(Vector2.ZERO,size),Color("#0A2231"))
    if _start.is_empty():
        return
    var battle: Dictionary = _start.get("battle",{})
    var terrain: Array = battle.get("terrain",[])
    if terrain.size() != 8:
        return
    var tile_w: float = (size.x - 28.0) / 10.0
    var tile_h: float = (size.y - 42.0) / 8.0
    var origin := Vector2(14,30)
    draw_string(ThemeDB.fallback_font,Vector2(14,20),
        "RECONOCIMIENTO · CORREDOR DE ARVEN",HORIZONTAL_ALIGNMENT_LEFT,
        -1,13,Color("#E3C66E"))
    for y in range(8):
        var row: Array = terrain[y]
        for x in range(10):
            var top_left: Vector2 = origin + Vector2(float(x)*tile_w,float(y)*tile_h)
            var base: Color = Style.terrain_color(str(row[x]),x,y)
            draw_rect(Rect2(top_left,Vector2(tile_w-1,tile_h-1)),base)
            if str(row[x]) == "forest":
                draw_circle(top_left+Vector2(tile_w*0.53,tile_h*0.42),
                    minf(tile_w,tile_h)*0.16,Color("#102F24"))
            elif str(row[x]) == "mountain":
                draw_line(top_left+Vector2(tile_w*0.2,tile_h*0.8),
                    top_left+Vector2(tile_w*0.5,tile_h*0.2),
                    Color("#B9C9C7"),1.5)
                draw_line(top_left+Vector2(tile_w*0.5,tile_h*0.2),
                    top_left+Vector2(tile_w*0.8,tile_h*0.8),
                    Color("#B9C9C7"),1.5)
    for index in range(Beacons.size()):
        var point: Vector2i = Beacons[index]
        var center: Vector2 = origin + Vector2((point.x+0.5)*tile_w,(point.y+0.5)*tile_h)
        draw_arc(center,minf(tile_w,tile_h)*0.38,0.0,TAU,24,Color("#FFDB60"),2.5,true)
        draw_string(ThemeDB.fallback_font,center+Vector2(-4,5),
            "A" if index == 0 else "B",HORIZONTAL_ALIGNMENT_LEFT,
            -1,13,Color.WHITE)
    for soldier in battle.get("units",[]):
        if not (soldier is Dictionary):
            continue
        var pos: Vector2i = soldier.get("pos",Vector2i(-1,-1))
        if pos.x < 0 or pos.y < 0:
            continue
        var dot: Vector2 = origin + Vector2((pos.x+0.5)*tile_w,(pos.y+0.5)*tile_h)
        var color: Color = Color("#2E9BFF") if int(soldier.get("faction",-1))==0 else Color("#F04C55")
        draw_circle(dot,maxf(4.0,minf(tile_w,tile_h)*0.23),Color("#071421"))
        draw_circle(dot,maxf(3.0,minf(tile_w,tile_h)*0.18),color)
    draw_string(ThemeDB.fallback_font,Vector2(14,size.y-5),
        "AZUL: ALIANZA NORTE   ·   ROJO: PACTO ESCARLATA   ·   DORADO: BALIZAS",
        HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#C0D5DF"))
