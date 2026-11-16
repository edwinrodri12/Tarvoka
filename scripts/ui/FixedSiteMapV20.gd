extends Control
class_name TarvokaFixedSiteMapV20

# Genuine v19 BattleSession units + canonical enlarged sites, rendered in
# an independent interactive map. No modifications to shipping TouchBoard.
signal cell_pressed(cell: Vector2i)

const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const LABELS := {
    "city":"CI","factory":"INF","armor_plant":"BL","artillery_depot":"ART",
    "drone_center":"DR","airbase":"AIR","shipyard":"NAV"
}
const TILE_COLORS := {
    "plain":"#3C6044","forest":"#254638","mountain":"#686964",
    "road":"#776B56","water":"#204C69","snow":"#BECBD3",
    "desert":"#A88D57","city":"#525D66"
}
var world: Dictionary = {}
var camps: Array = []
var focus := Vector2i(-1,-1)
var zoom := 1
var cell_pixels := 28

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_zoom(1)

func set_zoom(level: int) -> void:
    zoom = clampi(level,0,3)
    cell_pixels = [22,28,38,48][zoom]
    _resize_map()
    queue_redraw()

func set_snapshot(next_world: Dictionary, next_camps: Array,
        focus_cell: Vector2i = Vector2i(-1,-1)) -> void:
    world = next_world.duplicate(true)
    camps = next_camps.duplicate(true)
    focus = focus_cell
    _resize_map()
    queue_redraw()

func _resize_map() -> void:
    if world.is_empty() or not world.has("state"):
        custom_minimum_size = Vector2(500,340)
        return
    var dims: Vector2i = Rules.map_size(world["state"]["terrain"])
    custom_minimum_size = Vector2(dims.x*cell_pixels,dims.y*cell_pixels)
    update_minimum_size()

func pixel_to_cell(pixel: Vector2) -> Vector2i:
    if cell_pixels <= 0 or world.is_empty():
        return Vector2i(-1,-1)
    var cell := Vector2i(int(floor(pixel.x/cell_pixels)),int(floor(pixel.y/cell_pixels)))
    return cell if Rules.inside(cell,world["state"]["terrain"]) else Vector2i(-1,-1)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var cell: Vector2i = pixel_to_cell(event.position)
        if cell.x >= 0:
            cell_pressed.emit(cell)
            accept_event()
    elif event is InputEventScreenTouch and event.pressed:
        var touch_cell: Vector2i = pixel_to_cell(event.position)
        if touch_cell.x >= 0:
            cell_pressed.emit(touch_cell)
            accept_event()

func _draw() -> void:
    if world.is_empty() or not world.has("state"):
        return
    var state: Dictionary = world["state"]
    var terrain: Array = state["terrain"]
    var dims: Vector2i = Rules.map_size(terrain)
    var font: Font = ThemeDB.fallback_font
    var fs: int = maxi(10,mini(17,int(cell_pixels/2)))
    for y in range(dims.y):
        for x in range(dims.x):
            var kind: String = str(terrain[y][x])
            var rgb: Color = Color(str(TILE_COLORS.get(kind,"#47564D")))
            var bounds := Rect2(Vector2(x,y)*cell_pixels,Vector2.ONE*cell_pixels)
            draw_rect(bounds,rgb,true)
            draw_rect(bounds,Color("#132C39"),false,1.0)
    # Permanent buildings: no fake factories. Docks are placed in water,
    # with their separate shore tile outlined for infantry conquest.
    for site in world["layout"]["sites"]:
        var pos: Vector2i = site["pos"]
        var kind: String = str(site["kind"])
        var owner: int = int(site["owner"])
        var color := Color("#D6BE78") if owner == -1 else (
            Color("#5AC3FA") if owner == 0 else Color("#F17A72"))
        var center: Vector2 = (Vector2(pos)+Vector2(0.5,0.5))*cell_pixels
        var rect := Rect2(center-Vector2.ONE*(cell_pixels*0.37),
            Vector2.ONE*(cell_pixels*0.74))
        draw_rect(rect,Color("#142A36"),true)
        draw_rect(rect,color,false,2.0)
        if cell_pixels >= 27:
            draw_string(font,rect.position+Vector2(2,cell_pixels*0.45),
                str(LABELS.get(kind,"B")),HORIZONTAL_ALIGNMENT_LEFT,-1,mini(11,fs),color)
        if site.has("capture_pos"):
            var access: Vector2i = site["capture_pos"]
            var shore: Rect2 = Rect2(Vector2(access)*cell_pixels+Vector2.ONE*3,
                Vector2.ONE*(cell_pixels-6))
            draw_rect(shore,Color("#F0D08D"),false,2.0)
    for camp in camps:
        var cp: Vector2i = camp["pos"]
        var tint: Color = Color("#5AC3FA") if int(camp["owner"]) == 0 else Color("#F17A72")
        var c: Vector2 = (Vector2(cp)+Vector2(0.5,0.5))*cell_pixels
        draw_circle(c,cell_pixels*0.27,tint)
        draw_string(font,c+Vector2(-cell_pixels*0.23,4),
            "C",HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("#102331"))
    for unit in state["units"]:
        if int(unit.get("hp",0)) <= 0:
            continue
        var pos: Vector2i = unit["pos"]
        var center: Vector2 = (Vector2(pos)+Vector2(0.5,0.5))*cell_pixels
        var color: Color = Color("#39A9EC") if int(unit["faction"]) == 0 else Color("#D65D60")
        draw_circle(center,cell_pixels*0.32,Color("#081823"))
        draw_circle(center,cell_pixels*0.26,color)
        draw_string(font,center+Vector2(-cell_pixels*0.20,fs*0.35),
            str(Roles.symbol(str(unit.get("role","")))),HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color.WHITE)
    if Rules.inside(focus,terrain):
        var rect := Rect2(Vector2(focus)*cell_pixels+Vector2.ONE*1,
            Vector2.ONE*(cell_pixels-2))
        draw_rect(rect,Color("#FFE7A0"),false,3.0)
