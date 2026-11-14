extends Control
class_name TarvokaBattleMinimap

# Camera navigation only. Never issues tactical commands, marks explored
# cells, changes fog visibility or touches the battle/save state.
const Visibility = preload("res://scripts/core/Visibility.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const IsoTransform = preload("res://scripts/ui/IsoProjection.gd")
const TacticalAlerts = preload("res://scripts/ui/TacticalAlertsData.gd")
const AlertPainter = preload("res://scripts/ui/TacticalAlertPainter.gd")

var board: Control = null
var last_state_hash := -1
var cached_snapshot: Dictionary = {}
var terrain_texture: Texture2D = null
var cache_rebuild_count := 0
var cache_reuse_count := 0

func _ready() -> void:
    custom_minimum_size = Vector2(220, 138)
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    tooltip_text = "Toca para centrar. Rojo: crítico; ámbar: atención/base; cian: disponible. No mueve unidades."

func set_board(target: Control) -> void:
    board = target
    last_state_hash = -1
    terrain_texture = null
    cached_snapshot = {}
    queue_redraw()

static func dimensions(state: Dictionary) -> Vector2i:
    var terrain: Array = state.get("terrain", [])
    if terrain.is_empty() or not terrain[0] is Array:
        return Vector2i.ZERO
    return Vector2i((terrain[0] as Array).size(), terrain.size())

static func local_bounds(canvas_size: Vector2, map_size: Vector2i) -> Rect2:
    if map_size.x <= 0 or map_size.y <= 0:
        return Rect2()
    var cell: float = minf((canvas_size.x - 12.0)/float(map_size.x),
        (canvas_size.y - 12.0)/float(map_size.y))
    if cell <= 0:
        return Rect2()
    var extent := Vector2(float(map_size.x)*cell,float(map_size.y)*cell)
    return Rect2((canvas_size-extent)*0.5,extent)

static func point_to_cell(point: Vector2, canvas_size: Vector2,
        map_size: Vector2i) -> Vector2i:
    var bounds: Rect2 = local_bounds(canvas_size,map_size)
    if not bounds.has_point(point) or bounds.size.x <= 0.0:
        return Vector2i(-1,-1)
    var col: int = int(floor((point.x-bounds.position.x)*float(map_size.x)/bounds.size.x))
    var row: int = int(floor((point.y-bounds.position.y)*float(map_size.y)/bounds.size.y))
    if col < 0 or row < 0 or col >= map_size.x or row >= map_size.y:
        return Vector2i(-1,-1)
    return Vector2i(col,row)

# The snapshot is safe to hand to the UI, even when all enemy locations and
# installation ownership are present in the underlying authoritative state.
static func safe_snapshot(state: Dictionary, viewer: int = 0,
        vs_ai: bool = false) -> Dictionary:
    var dims: Vector2i = dimensions(state)
    var result: Dictionary = {"size":dims,"tiles":[],"units":[],"sites":[],"nodes":[],"alerts":[]}
    if dims.x <= 0 or dims.y <= 0:
        return result
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if fog else {}
    var explored: Dictionary = Visibility.explored_cells(state,viewer) if fog else {}
    for y in range(dims.y):
        for x in range(dims.x):
            var cell := Vector2i(x,y)
            var is_known: bool = not fog or explored.has(cell)
            var is_visible: bool = not fog or visible.has(cell)
            result["tiles"].append({
                "pos":cell,
                "kind":str(state["terrain"][y][x]) if is_known else "unknown",
                "visible":is_visible,"explored":is_known
            })
    for unit in state.get("units",[]):
        if int(unit.get("hp",0)) <= 0:
            continue
        var cell: Vector2i = unit["pos"]
        var faction: int = int(unit.get("faction",-1))
        if faction != viewer and fog and not visible.has(cell):
            continue
        result["units"].append({"pos":cell,"faction":faction})
    if state.has("economy"):
        for site in state["economy"]["sites"]:
            var cell: Vector2i = site["pos"]
            if fog and not explored.has(cell):
                continue
            var owner: int = int(site["owner"]) if not fog or visible.has(cell) or int(site["owner"]) == viewer else -1
            result["sites"].append({"pos":cell,"owner":owner})
    if state.has("control"):
        for node in state["control"]["nodes"]:
            var cell: Vector2i = node["pos"]
            if fog and not explored.has(cell):
                continue
            var owner: int = int(node["owner"]) if not fog or visible.has(cell) else -1
            result["nodes"].append({"pos":cell,"owner":owner})
    # The alert feed uses only friendly units and sight-approved site markers.
    # This snapshot is cached alongside terrain, never on camera panning.
    result["alerts"] = TacticalAlerts.build(state,viewer,vs_ai).get("markers",[])
    return result

static func viewport_corners(canvas_size: Vector2, state: Dictionary,
        board_size: Vector2, zoom: float, pan: Vector2) -> PackedVector2Array:
    var dims: Vector2i = dimensions(state)
    var bounds: Rect2 = local_bounds(canvas_size,dims)
    var hw: float = IsoTransform.half_width(board_size,zoom,dims)
    var result := PackedVector2Array()
    if hw <= 0.0 or bounds.size.x <= 0.0:
        return result
    var base: Vector2 = IsoTransform.origin(board_size,zoom,pan,dims)
    var cell_size: Vector2 = bounds.size / Vector2(dims)
    for corner in [Vector2.ZERO,Vector2(board_size.x,0),
            board_size,Vector2(0,board_size.y)]:
        var d: Vector2 = corner - base
        var u: float = d.x / hw
        var v: float = d.y / (hw * 0.5)
        var grid: Vector2 = Vector2((u+v)*0.5,(v-u)*0.5) + Vector2(0.5,0.5)
        result.append(bounds.position+grid*cell_size)
    result.append(result[0])
    return result

static func _rasterize_terrain(data: Dictionary) -> Texture2D:
    var dims: Vector2i = data.get("size",Vector2i.ZERO)
    if dims.x <= 0 or dims.y <= 0:
        return null
    var image: Image = Image.create(dims.x,dims.y,false,Image.FORMAT_RGBA8)
    image.fill(Color("#09101C"))
    for item in data.get("tiles",[]):
        var cell: Vector2i = item["pos"]
        var color := Color("#09101C")
        if bool(item["explored"]):
            color = VisualStyle.terrain_color(str(item["kind"]),cell.x,cell.y)
            if not bool(item["visible"]):
                color = color.darkened(0.70)
        image.set_pixel(cell.x,cell.y,color)
    return ImageTexture.create_from_image(image)

func _snapshot_for_state(state: Dictionary) -> Dictionary:
    # Hashing a map is cheaper than recreating 1,200 tile dictionaries and
    # all its draw commands every time the camera moves. Rebuild on any change
    # to authoritative content, including externally loaded/save-restored data.
    var vs_ai: bool = bool(board.get("ai_enabled")) if board != null else false
    var viewer: int = 0 if vs_ai else int(state.get("faction",0))
    var key: int = hash([state,viewer,vs_ai])
    if terrain_texture != null and key == last_state_hash:
        cache_reuse_count += 1
        return cached_snapshot
    cached_snapshot = safe_snapshot(state,viewer,vs_ai)
    terrain_texture = _rasterize_terrain(cached_snapshot)
    last_state_hash = key
    cache_rebuild_count += 1
    return cached_snapshot

func _draw() -> void:
    if board == null:
        return
    var state: Dictionary = board.get("state")
    var data: Dictionary = _snapshot_for_state(state)
    var dims: Vector2i = data["size"]
    if dims.x <= 0 or dims.y <= 0:
        return
    var bounds: Rect2 = local_bounds(size,dims)
    if bounds.size.x <= 0:
        return
    var tile := bounds.size / Vector2(dims)
    draw_rect(Rect2(Vector2.ZERO,size),Color("#0B1821"))
    if terrain_texture != null:
        # One draw command instead of up to 1,200 tiled rectangles; camera
        # movement only changes the viewport outline and existing markers.
        draw_texture_rect(terrain_texture,bounds,false)
    for site in data["sites"]:
        var pos: Vector2 = bounds.position+(Vector2(site["pos"])+Vector2(0.5,0.5))*tile
        var owner: int = int(site["owner"])
        var tint := Color("#D5BE79")
        if owner in [0,1]:
            tint = VisualStyle.faction_color(owner)
        var half: float = maxf(1.4,minf(tile.x,tile.y)*0.25)
        draw_rect(Rect2(pos-Vector2.ONE*half,Vector2.ONE*half*2.0),tint)
    for node in data["nodes"]:
        var pos: Vector2 = bounds.position+(Vector2(node["pos"])+Vector2(0.5,0.5))*tile
        var owner: int = int(node["owner"])
        var tint := Color("#D8B766")
        if owner in [0,1]:
            tint = VisualStyle.faction_color(owner)
        draw_circle(pos,maxf(1.4,minf(tile.x,tile.y)*0.25),tint)
    for unit in data["units"]:
        var pos: Vector2 = bounds.position+(Vector2(unit["pos"])+Vector2(0.5,0.5))*tile
        var faction: int = int(unit["faction"])
        var color: Color = VisualStyle.faction_color(faction)
        draw_circle(pos,maxf(2.0,minf(tile.x,tile.y)*0.24),color)
    AlertPainter.draw_minimap(self,data.get("alerts",[]),bounds,dims,
        bool(board.get("battery_saver")))
    var view: PackedVector2Array = viewport_corners(size,state,board.size,
        float(board.get("iso_zoom")),board.get("iso_pan"))
    if view.size() == 5:
        draw_polyline(view,Color("#F9EBB9"),1.8,true)
    draw_rect(bounds,Color("#C4D5DC"),false,1.0)

func _focus(point: Vector2) -> void:
    if board == null or not bool(board.get("iso_enabled")):
        return
    var state: Dictionary = board.get("state")
    var target: Vector2i = point_to_cell(point,size,dimensions(state))
    if target.x < 0:
        return
    board.call("focus_iso_cell",target)
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not event.pressed:
        _focus(event.position)
        accept_event()
    elif event is InputEventScreenDrag:
        _focus(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if event.device != InputEvent.DEVICE_ID_EMULATION:
            _focus(event.position)
        accept_event()
