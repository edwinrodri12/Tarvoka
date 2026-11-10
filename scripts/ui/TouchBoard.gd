extends Control
class_name TarvokaTouchBoard

const Session = preload("res://scripts/core/BattleSession.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const WIDTH := 10
const HEIGHT := 8
var state: Dictionary = {}
var ai_enabled := true # Faction 1 is computer-controlled; disable for local two-player tests.
var selected_id := ""
var message := "Selecciona una unidad."
var touch_origin := Vector2.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    var terrain: Array = []
    for y in range(HEIGHT):
        var row: Array = []
        for x in range(WIDTH):
            row.append("plain")
        terrain.append(row)
    state = Session.start([
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":8,"pos":Vector2i(8,2),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":8,"pos":Vector2i(8,5),"move_points":3,"attack":4,"defense":0,"cover":0,"acted":false}
    ], terrain)
    queue_redraw()

func _cell_size() -> float:
    return min(size.x / float(WIDTH), size.y / float(HEIGHT))

func _board_origin() -> Vector2:
    var tile := _cell_size()
    return (size - Vector2(WIDTH * tile, HEIGHT * tile)) * 0.5

func _draw() -> void:
    var tile := _cell_size()
    var origin := _board_origin()
    var font := ThemeDB.fallback_font
    for y in range(HEIGHT):
        for x in range(WIDTH):
            var pos := origin + Vector2(x, y) * tile
            draw_rect(Rect2(pos, Vector2.ONE * tile), Color(0.18,0.27,0.22) if (x+y)%2 == 0 else Color(0.22,0.32,0.26))
            draw_rect(Rect2(pos, Vector2.ONE * tile), Color(0.45,0.52,0.46), false, 1.0)
    for unit in state.get("units", []):
        if int(unit.get("hp",0)) <= 0:
            continue
        var cell: Vector2i = unit["pos"]
        var center := origin + (Vector2(cell) + Vector2(0.5,0.5)) * tile
        var color := Color(0.35,0.65,1.0) if int(unit["faction"]) == 0 else Color(1.0,0.4,0.3)
        draw_circle(center, tile * 0.35, color.darkened(0.45) if unit.get("acted",false) else color)
        if str(unit["id"]) == selected_id:
            draw_arc(center, tile * 0.42, 0, TAU, 32, Color.YELLOW, 3.0)
        draw_string(font, center + Vector2(-tile*0.11,tile*0.10), str(unit["id"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(12,tile*0.30)), Color.WHITE)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        _tap(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _tap(event.position)
        accept_event()

func _tap(point: Vector2) -> void:
    if int(state.get("winner",-1)) != -1:
        return
    var tile := _cell_size()
    if tile <= 0:
        return
    var relative := point - _board_origin()
    if relative.x < 0 or relative.y < 0 or relative.x >= WIDTH * tile or relative.y >= HEIGHT * tile:
        return
    var cell := Vector2i(int(relative.x / tile), int(relative.y / tile))
    var target: Dictionary = {}
    for unit in state["units"]:
        if int(unit.get("hp",0)) > 0 and unit["pos"] == cell:
            target = unit
            break
    if not target.is_empty() and int(target["faction"]) == int(state["faction"]):
        var tapped_id := str(target["id"])
        if tapped_id == selected_id:
            selected_id = ""
            message = "Seleccion cancelada."
        elif bool(target.get("acted", false)):
            selected_id = ""
            message = "Esta unidad ya actuo durante este turno."
        else:
            selected_id = tapped_id
            message = "Unidad " + selected_id + " seleccionada."
    elif not selected_id.is_empty():
        var action: Dictionary
        if not target.is_empty():
            action = Session.attack(state, selected_id, str(target["id"]))
        else:
            action = Session.move(state, selected_id, cell)
        if action.get("valid",false):
            state = action["state"]
            var winner := int(state.get("winner", -1))
            message = "Victoria de faccion %d." % (winner + 1) if winner != -1 else "Accion realizada."
            selected_id = ""
        else:
            message = "Accion no permitida."
    queue_redraw()

func finish_turn() -> void:
    # Human cannot manually skip the computer faction.
    if ai_enabled and int(state.get("faction", -1)) != 0:
        return
    var result: Dictionary = Session.end_turn(state)
    if not result.get("valid", false):
        return
    state = result["state"]
    selected_id = ""
    message = "Turno de faccion " + str(state["faction"] + 1)
    if ai_enabled and int(state["faction"]) == 1:
        _play_ai_turn()
    queue_redraw()

func _play_ai_turn() -> void:
    # Hard bound: each valid AI action consumes one unit's action.
    var max_actions := state.get("units", []).size()
    for i in range(max_actions):
        if int(state.get("winner", -1)) != -1:
            break
        var result: Dictionary = BasicAI.step(state)
        if not result.get("valid", false):
            break
        state = result["state"]
    if int(state.get("winner", -1)) != -1:
        message = "Victoria de faccion %d." % (int(state["winner"]) + 1)
        return
    var next: Dictionary = Session.end_turn(state)
    if next.get("valid", false):
        state = next["state"]
        message = "Tu turno: faccion 1."
