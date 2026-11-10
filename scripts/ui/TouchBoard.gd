extends Control
class_name TarvokaTouchBoard

const Session = preload("res://scripts/core/BattleSession.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const WIDTH := 10
const HEIGHT := 8
var state: Dictionary = {}
var ai_enabled := true # Faction 1 is computer-controlled; disable for local two-player tests.
var autosave_enabled := false # Enabled by Main after board initializes; tests opt in explicitly.
var autosave_path := "user://tarvoka_autosave_v1.json"
var selected_id := ""
var message := "Selecciona una unidad."
var touch_origin := Vector2.ZERO
var touch_active := false
var touch_finger_index := -1
var touch_cancelled := false
const TAP_DRAG_LIMIT := 18.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    new_game()

func new_game() -> void:
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
    selected_id = ""
    message = "Selecciona una unidad."
    _write_autosave()
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
    # Legal destinations in green, adjacent attack targets in red.
    # Reuse the exact movement/combat rules instead of drawing guessed ranges.
    var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
    for destination in hints["moves"]:
        var movement_cell: Vector2i = destination
        var movement_pos: Vector2 = origin + Vector2(movement_cell) * tile
        draw_rect(Rect2(movement_pos, Vector2.ONE * tile), Color(0.18, 0.76, 0.40, 0.34))
        if tile >= 25.0:
            draw_string(font, movement_pos + Vector2(3.0, max(12.0, tile * 0.25)),
                str(hints["moves"][destination]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(max(10.0, tile * 0.20)), Color.WHITE)
    for destination in hints["attacks"]:
        var attack_cell: Vector2i = destination
        var attack_pos: Vector2 = origin + Vector2(attack_cell) * tile
        draw_rect(Rect2(attack_pos, Vector2.ONE * tile), Color(0.94, 0.20, 0.16, 0.40))
        draw_rect(Rect2(attack_pos, Vector2.ONE * tile), Color(1.0, 0.32, 0.24), false, 2.0)
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

func selected_unit_summary() -> String:
    return TacticalHints.unit_summary(state, selected_id)

func legal_action_hints() -> Dictionary:
    return TacticalHints.for_unit(state, selected_id)

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and not touch_active:
            touch_origin = event.position
            touch_cancelled = false
            touch_finger_index = event.index
            touch_active = true
        elif not event.pressed and touch_active and event.index == touch_finger_index:
            touch_active = false
            touch_finger_index = -1
            if not touch_cancelled and touch_origin.distance_to(event.position) <= TAP_DRAG_LIMIT:
                _tap(event.position)
        accept_event()
    elif event is InputEventScreenDrag:
        # Cancel the gesture permanently if its primary finger ever leaves the tap radius.
        if touch_active and event.index == touch_finger_index and touch_origin.distance_to(event.position) > TAP_DRAG_LIMIT:
            touch_cancelled = true
        accept_event()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # Native Buttons need touch-to-mouse emulation on Android, but the board
        # already handles ScreenTouch release. Ignore only duplicated mouse events.
        if event.device != InputEvent.DEVICE_ID_EMULATION:
            _tap(event.position)
        accept_event()

func _tap(point: Vector2) -> void:
    if ai_enabled and int(state.get("faction", -1)) != 0:
        return
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
            _write_autosave()
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
    _write_autosave()
    queue_redraw()

func _play_ai_turn() -> void:
    # Never advance the computer from a human or terminal state.
    if not ai_enabled or int(state.get("faction", -1)) != 1 or int(state.get("winner", -1)) != -1:
        return
    # Hard bound: each valid AI action consumes one unit's action.
    var max_actions: int = (state.get("units", []) as Array).size()
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

func save_game(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var ok := SaveStore.save(state, path)
    message = "Partida guardada." if ok else "No se pudo guardar la partida."
    return ok

func load_game(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var restored: Dictionary = SaveStore.load(path)
    if restored.is_empty():
        message = "No se pudo cargar la partida."
        return false
    state = restored
    selected_id = ""
    var loaded_winner := int(state.get("winner", -1))
    message = "Victoria de faccion %d." % (loaded_winner + 1) if loaded_winner != -1 else "Partida cargada."
    # A saved computer turn must resume immediately; human input is locked during it.
    if ai_enabled and int(state.get("faction", -1)) == 1 and int(state.get("winner", -1)) == -1:
        _play_ai_turn()
    _write_autosave()
    queue_redraw()
    return true

# Autosave is a separate file; manual "Guardar partida" always remains untouched.
# The main scene chooses when to restore so unit tests can create fresh boards.
func resume_autosave() -> bool:
    var restored: Dictionary = SaveStore.load(autosave_path)
    if restored.is_empty():
        return false
    state = restored
    selected_id = ""
    message = "Partida recuperada automaticamente."
    if ai_enabled and int(state.get("faction", -1)) == 1 and int(state.get("winner", -1)) == -1:
        _play_ai_turn()
        _write_autosave()
    queue_redraw()
    return true

func _write_autosave() -> bool:
    if not autosave_enabled:
        return false
    return SaveStore.save(state, autosave_path)
