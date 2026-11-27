extends Control
class_name TarvokaBattlefieldPreview

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Winter = preload("res://scripts/ui/WinterBattleBiome.gd")
const MixedRegions = preload("res://scripts/core/MixedBiomeRegionsV49.gd")
const Crossings = preload("res://scripts/core/LayeredCrossingsV48.gd")

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
var visual_biome := Winter.TEMPERATE
var mixed_config: Dictionary = {}
var mixed_regions: Dictionary = {}
var geographic_bridge_candidates: Array = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(250,196)
    resized.connect(queue_redraw)

func configure(scenario_id: int, size_id: int, seed: int,
        biome: String = Winter.TEMPERATE,mixed: Dictionary = {}) -> void:
    var next_size: Vector2i = SIZES[clampi(size_id,0,SIZES.size()-1)]
    var next_seed: int = clampi(seed,Scenarios.MIN_SEED,Scenarios.MAX_SEED)
    var next_biome: String = biome if Winter.valid(biome) else Winter.TEMPERATE
    var next_mixed: Dictionary = mixed.duplicate(true) if scenario_id==Scenarios.GEOGRAPHIC_SCENARIO_ID and MixedRegions.valid_config(mixed) else {}
    if grid_size == next_size and selected_seed == next_seed and scenario_name == str(scenario_id) and visual_biome == next_biome and mixed_config==next_mixed:
        return
    visual_biome = next_biome
    grid_size = next_size
    selected_seed = next_seed
    scenario_name = str(scenario_id)
    mixed_config = next_mixed
    mixed_regions = MixedRegions.generate(selected_seed,grid_size,mixed_config) if not mixed_config.is_empty() else {}
    preview_map = Scenarios.selected_terrain(scenario_id,grid_size,selected_seed,visual_biome) if mixed_config.is_empty() else MixedRegions.geographic_candidate(selected_seed,grid_size,mixed_config)
    geographic_bridge_candidates = Crossings.geographic_records(preview_map) if scenario_id==Scenarios.GEOGRAPHIC_SCENARIO_ID else []
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
            var tile: Color = (
                Winter.tile_color(kind,x,y,visual_biome) if visual_biome != Winter.TEMPERATE
                else TILES.get(kind,TILES["plain"]))
            if mixed_regions.has(Vector2i(x,y)):
                var region: Dictionary = mixed_regions[Vector2i(x,y)]
                tile = Winter.tile_color(kind,x,y,region["primary"]).lerp(Winter.tile_color(kind,x,y,region["secondary"]),float(region["secondary_weight"])/1000.0)
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
