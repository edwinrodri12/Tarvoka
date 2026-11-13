extends Control
class_name TarvokaBattlefieldPreview

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")

const SIZES := [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]
const TILES := {
    "plain":Color("#566B46"),
    "forest":Color("#254D3C"),
    "road":Color("#B49E69"),
    "mountain":Color("#88919D"),
    "water":Color("#215B82")
}
var preview_map: Array = []
var scenario_name := ""
var grid_size := Vector2i.ZERO
var selected_seed := 0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(250,196)
    resized.connect(queue_redraw)

func configure(scenario_id: int, size_id: int, seed: int) -> void:
    var next_size: Vector2i = SIZES[clampi(size_id,0,SIZES.size()-1)]
    var next_seed: int = clampi(seed,Scenarios.MIN_SEED,Scenarios.MAX_SEED)
    if grid_size == next_size and selected_seed == next_seed and scenario_name == str(scenario_id):
        return
    grid_size = next_size
    selected_seed = next_seed
    scenario_name = str(scenario_id)
    preview_map = Scenarios.seeded_terrain(selected_seed,grid_size) if scenario_id == Scenarios.RANDOM_SCENARIO_ID else Scenarios.terrain(scenario_id,grid_size)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO,size),Color("#0D2131"),true)
    draw_rect(Rect2(Vector2.ONE*0.5,size-Vector2.ONE),Chrome.EDGE, false,2)
    if preview_map.is_empty() or grid_size.x <= 0 or grid_size.y <= 0:
        return
    var inset := Vector2(12,12)
    var canvas := size-2*inset
    var tile_w: float = canvas.x/float(grid_size.x)
    var tile_h: float = canvas.y/float(grid_size.y)
    for y in range(grid_size.y):
        var row: Array = preview_map[y]
        for x in range(grid_size.x):
            var kind: String = str(row[x])
            var tile: Color = TILES.get(kind,TILES["plain"])
            var top_left := inset + Vector2(float(x)*tile_w,float(y)*tile_h)
            var rect := Rect2(top_left,Vector2(tile_w+0.13,tile_h+0.13))
            draw_rect(rect,tile,true)
            if tile_w > 8.0 and tile_h > 8.0:
                draw_rect(rect,Color(0.04,0.10,0.15,0.13),false,0.7)
    var left_x: float = inset.x+tile_w*0.6
    var right_x: float = size.x-inset.x-tile_w*0.6
    var cy: float = size.y*0.5
    var radius: float = clampf(minf(tile_w,tile_h)*0.64,2.5,6)
    draw_circle(Vector2(left_x,cy),radius,Chrome.EDGE_BRIGHT)
    draw_circle(Vector2(right_x,cy),radius,Chrome.RED)
    draw_arc(Vector2(left_x,cy),radius*1.9,0,TAU,20,Chrome.EDGE_BRIGHT,1)
    draw_arc(Vector2(right_x,cy),radius*1.9,0,TAU,20,Chrome.RED,1)
    draw_line(Vector2(size.x*0.5,inset.y),
        Vector2(size.x*0.5,size.y-inset.y),Color(1,1,1,0.12),1)
