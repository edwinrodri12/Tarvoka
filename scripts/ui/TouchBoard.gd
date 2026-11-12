extends Control
class_name TarvokaTouchBoard

const Session = preload("res://scripts/core/BattleSession.gd")
const BasicAI = preload("res://scripts/core/BasicAI.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const TacticalHints = preload("res://scripts/core/TacticalHints.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const WIDTH := 10
const HEIGHT := 8
var state: Dictionary = {}
var current_scenario_id := 0
var symmetric_setup := false
var specialized_roster := false
var ai_enabled := true # Faction 1 is computer-controlled; disable for local two-player tests.
var autosave_enabled := false # Enabled by Main after board initializes; tests opt in explicitly.
var autosave_path := "user://tarvoka_autosave_v1.json"
var autosave_warning := ""
var selected_id := ""
var require_order_confirmation := false # Main enables safer two-stage taps; legacy test boards remain immediate.
var pending_order: Dictionary = {}
var selected_factory_pos := Vector2i(-1,-1)
var message := "Selecciona una unidad."
var last_enemy_turn_report := ""
var last_economy_report := ""
var touch_origin := Vector2.ZERO
var touch_active := false
var touch_finger_index := -1
var touch_cancelled := false
const TAP_DRAG_LIMIT := 18.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    new_game()

func new_game(scenario_id: int = 0, symmetric: bool = false, fog_mode: bool = false, relay_mode: bool = false, specialized: bool = false, economy_mode: bool = false) -> void:
    symmetric_setup = symmetric
    specialized_roster = specialized
    var enemy_hp: int = 10 if symmetric else 8
    var enemy_attack: int = 5 if symmetric else 4
    current_scenario_id = scenario_id if scenario_id >= 0 and scenario_id < Scenarios.LABELS.size() else 0
    var terrain: Array = Scenarios.terrain(current_scenario_id)
    var units: Array = [
        {"id":"A","faction":0,"hp":10,"pos":Vector2i(1,2),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,5),"move_points":3,"attack":5,"defense":0,"cover":0,"acted":false},
        {"id":"X","faction":1,"hp":enemy_hp,"pos":Vector2i(8,2),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false},
        {"id":"Y","faction":1,"hp":enemy_hp,"pos":Vector2i(8,5),"move_points":3,"attack":enemy_attack,"defense":0,"cover":0,"acted":false}
    ]
    if specialized_roster:
        units = Roles.experimental_armies(symmetric)
    if fog_mode and not specialized_roster:
        # Classic recon scouts are mirrored: mobility 4, sight 5.
        units.append({"id":"S","faction":0,"hp":6,"pos":Vector2i(1,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false})
        units.append({"id":"Z","faction":1,"hp":6,"pos":Vector2i(8,3),"move_points":4,"attack":2,"defense":0,"cover":0,"vision":5,"acted":false})
    state = Session.start(units, terrain, 0, fog_mode, relay_mode, economy_mode)
    selected_factory_pos = Vector2i(-1,-1)
    selected_id = ""
    pending_order.clear()
    message = "Selecciona una unidad."
    last_enemy_turn_report = ""
    last_economy_report = ""
    _write_autosave(false)
    queue_redraw()

func _cell_size() -> float:
    return min(size.x / float(WIDTH), size.y / float(HEIGHT))

func _board_origin() -> Vector2:
    var tile := _cell_size()
    return (size - Vector2(WIDTH * tile, HEIGHT * tile)) * 0.5

# Completely opaque unknown cells prevent even subtle color-based terrain
# leaks; previously explored cells retain a dim, recognizable map surface.
static func fog_cover_color(has_explored: bool) -> Color:
    return Color(0.025, 0.035, 0.05, 0.73) if has_explored else Color(0.015, 0.025, 0.04, 1.0)

func _draw() -> void:
    var tile := _cell_size()
    var origin := _board_origin()
    var font := ThemeDB.fallback_font
    var fog: bool = Visibility.enabled(state)
    var visible: Dictionary = Visibility.visible_cells(state, 0) if fog else {}
    var explored: Dictionary = Visibility.explored_cells(state, 0) if fog else {}
    for y in range(HEIGHT):
        for x in range(WIDTH):
            var pos := origin + Vector2(x, y) * tile
            var terrain_type := str(state.get("terrain", [])[y][x])
            var terrain_color := Color(0.18, 0.27, 0.22) if (x + y) % 2 == 0 else Color(0.22, 0.32, 0.26)
            match terrain_type:
                "forest":
                    terrain_color = Color(0.09, 0.26, 0.14)
                "road":
                    terrain_color = Color(0.32, 0.29, 0.23)
                "mountain":
                    terrain_color = Color(0.32, 0.34, 0.41)
                "water":
                    terrain_color = Color(0.07, 0.23, 0.40)
            draw_rect(Rect2(pos, Vector2.ONE * tile), terrain_color)
            draw_rect(Rect2(pos, Vector2.ONE * tile), Color(0.48, 0.55, 0.53, 0.60), false, 1.0)
            # Simple self-contained symbols, no borrowed art or sprite assets.
            if terrain_type == "forest":
                draw_circle(pos + tile * Vector2(0.29, 0.31), tile * 0.09, Color(0.25, 0.53, 0.27))
                draw_circle(pos + tile * Vector2(0.65, 0.27), tile * 0.11, Color(0.20, 0.45, 0.22))
            elif terrain_type == "road":
                draw_line(pos + tile * Vector2(0.12, 0.51), pos + tile * Vector2(0.88, 0.51), Color(0.71, 0.65, 0.47, 0.70), maxf(1.0, tile * 0.035))
            elif terrain_type == "mountain":
                var triangle := PackedVector2Array([
                    pos + tile * Vector2(0.18, 0.77),
                    pos + tile * Vector2(0.52, 0.23),
                    pos + tile * Vector2(0.85, 0.77)
                ])
                draw_colored_polygon(triangle, Color(0.53, 0.58, 0.65, 0.70))
            elif terrain_type == "water":
                draw_line(pos + tile * Vector2(0.19, 0.40), pos + tile * Vector2(0.79, 0.40), Color(0.38, 0.66, 0.86, 0.80), maxf(1.0, tile * 0.025))
                draw_line(pos + tile * Vector2(0.12, 0.62), pos + tile * Vector2(0.72, 0.62), Color(0.38, 0.66, 0.86, 0.65), maxf(1.0, tile * 0.025))
            if fog:
                var spot := Vector2i(x, y)
                if not visible.has(spot):
                    # Previously seen terrain remains dim; unknown areas are dark.
                    var shade: Color = fog_cover_color(explored.has(spot))
                    draw_rect(Rect2(pos, Vector2.ONE * tile), shade)
    # Mission markers are objectives, not selectable enemy units. Under fog,
    # unknown objectives are concealed, while already explored objectives
    # remain marked without revealing their CURRENT owner until visible.
    if state.has("control"):
        for node in state["control"]["nodes"]:
            var objective_cell: Vector2i = node["pos"]
            if fog and not explored.has(objective_cell):
                continue
            var known_owner: int = int(node["owner"]) if not fog or visible.has(objective_cell) else -1
            var signal_color := Color(0.95, 0.76, 0.30)
            if known_owner == 0:
                signal_color = Color(0.30, 0.68, 1.0)
            elif known_owner == 1:
                signal_color = Color(1.0, 0.45, 0.36)
            var signal_center: Vector2 = origin + (Vector2(objective_cell) + Vector2(0.5, 0.5)) * tile
            var marker: PackedVector2Array = PackedVector2Array([
                signal_center + Vector2(0, -tile * 0.30),
                signal_center + Vector2(tile * 0.30, 0),
                signal_center + Vector2(0, tile * 0.30),
                signal_center + Vector2(-tile * 0.30, 0)
            ])
            marker.append(marker[0])
            draw_polyline(marker, signal_color, maxf(2.0, tile * 0.055), true)
    # Urban installations use distinct shapes and letters. Sites not yet
    # explored stay hidden; the current owner stays unknown outside sight.
    if state.has("economy"):
        for site in state["economy"]["sites"]:
            var city_cell: Vector2i = site["pos"]
            if fog and not explored.has(city_cell):
                continue
            var known_owner: int = int(site["owner"]) if not fog or visible.has(city_cell) or int(site["owner"]) == 0 else -1
            var city_tint := Color(0.94, 0.79, 0.39)
            if known_owner == 0:
                city_tint = Color(0.35, 0.73, 0.99)
            elif known_owner == 1:
                city_tint = Color(1.0, 0.45, 0.39)
            var top_left := origin + Vector2(city_cell) * tile
            var center := top_left + Vector2.ONE * (tile * 0.5)
            var is_town: bool = str(site["kind"]) == "city"
            var half: float = tile * (0.30 if is_town else 0.35)
            draw_rect(Rect2(center-Vector2.ONE*half, Vector2.ONE*(half*2)), Color(0.03,0.07,0.10,0.82))
            draw_rect(Rect2(center-Vector2.ONE*half, Vector2.ONE*(half*2)), city_tint, false, maxf(2.0,tile*0.065))
            if tile >= 20.0:
                var symbol := "C" if is_town else "F"
                draw_string(font, center+Vector2(-tile*0.14,tile*0.12), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(11.0,tile*0.27)), city_tint)
            if city_cell == selected_factory_pos:
                draw_rect(Rect2(top_left,Vector2.ONE*tile),Color.YELLOW,false,3.0)
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
        if fog and int(unit.get("faction", -1)) != 0 and not visible.has(cell):
            continue
        var center := origin + (Vector2(cell) + Vector2(0.5,0.5)) * tile
        var is_player := int(unit["faction"]) == 0
        var color := Color(0.35, 0.65, 1.0) if is_player else Color(1.0, 0.4, 0.3)
        var face: Color = color.darkened(0.45) if unit.get("acted", false) else (color.darkened(0.18) if unit.get("moved", false) else color)
        # Circle vs square provides faction identity without requiring color vision.
        if is_player:
            draw_circle(center, tile * 0.34, face)
        else:
            var half := tile * 0.32
            draw_rect(Rect2(center - Vector2.ONE * half, Vector2.ONE * (half * 2.0)), face)
        if str(unit["id"]) in ["S", "Z"] and not unit.has("role") or str(unit.get("role", "")) == "scout":
            draw_arc(center, tile * 0.40, 0, TAU, 24, Color(0.60, 0.94, 0.88), 2.0)
        if str(unit["id"]) == selected_id:
            draw_arc(center, tile * 0.44, 0, TAU, 32, Color.YELLOW, 3.0)
        draw_string(font, center + Vector2(-tile * 0.11, tile * 0.10), str(unit["id"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(12.0, tile * 0.30)), Color.WHITE)
        # A second visual marker identifies the tactical role independently
        # of faction color and unit ID; no borrowed game sprites.
        if Roles.valid(str(unit.get("role", ""))) and tile >= 36.0:
            var role_pos := center + Vector2(tile * 0.19, -tile * 0.14)
            draw_string(font, role_pos, Roles.symbol(str(unit["role"])), HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(11.0, tile * 0.19)), Color(1.0, 0.94, 0.65))
        # Numeric health avoids a misleading percentage: this prototype has no
        # persistent per-unit maximum-HP field yet. Hide on very small tiles.
        if tile >= 39.0:
            var unit_pos := origin + Vector2(cell) * tile
            var badge_rect := Rect2(unit_pos + Vector2(tile * 0.04, tile * 0.76), Vector2(tile * 0.47, tile * 0.22))
            draw_rect(badge_rect, Color(0.03, 0.07, 0.09, 0.89))
            var health_tint := Color(1.0, 0.75, 0.46) if int(unit["hp"]) <= 3 else Color.WHITE
            draw_string(font, badge_rect.position + Vector2(tile * 0.04, tile * 0.17),
                "HP %d" % int(unit["hp"]), HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(max(10.0, tile * 0.16)), health_tint)
    # A question mark is deliberately NOT a unit: no HP, target preview,
    # hitbox or legal attack is created from historical sightings.
    if fog:
        var stale_contacts: Dictionary = Visibility.last_known_contacts(state, 0)
        for enemy_id in stale_contacts:
            var old_cell: Vector2i = stale_contacts[enemy_id]
            var ghost_center: Vector2 = origin + (Vector2(old_cell) + Vector2(0.5, 0.5)) * tile
            draw_arc(ghost_center, tile * 0.26, 0, TAU, 20, Color(0.95, 0.73, 0.38, 0.80), 2.0)
            draw_string(font, ghost_center + Vector2(-tile * 0.09, tile * 0.11),
                "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(max(12.0, tile * 0.31)), Color(1.0, 0.86, 0.55))
    if pending_order.has("cell"):
        var preview_cell: Vector2i = pending_order["cell"]
        var preview_pos: Vector2 = origin + Vector2(preview_cell) * tile
        draw_rect(Rect2(preview_pos, Vector2.ONE * tile), Color(1.0, 0.86, 0.20), false, 4.0)
    # Put expected damage above the enemy tile, after units are drawn so it stays readable.
    for destination in hints["attacks"]:
        if tile >= 33.0:
            var target_pos: Vector2 = origin + Vector2(destination) * tile
            var dmg: int = int(hints["attacks"][destination]["damage"])
            draw_string(font, target_pos + Vector2(tile * 0.52, tile * 0.89),
                "-%d" % dmg, HORIZONTAL_ALIGNMENT_LEFT, -1,
                int(max(11.0, tile * 0.22)), Color(1.0, 0.88, 0.60))

func cancel_selection() -> void:
    if selected_id.is_empty() and pending_order.is_empty() and selected_factory_pos == Vector2i(-1,-1):
        return
    selected_id = ""
    selected_factory_pos = Vector2i(-1,-1)
    pending_order.clear()
    message = "Seleccion cancelada."
    queue_redraw()

func confirm_pending_order() -> bool:
    if pending_order.is_empty():
        return false
    var order: Dictionary = pending_order.duplicate(true)
    var committed := _commit_order(order)
    queue_redraw()
    return committed

func _request_order(cell: Vector2i, target: Dictionary) -> void:
    var hints: Dictionary = TacticalHints.for_unit(state, selected_id)
    var enemy_id := str(target.get("id", ""))
    var kind := "attack" if not target.is_empty() else "move"
    var legal: bool = bool(hints["attacks"].has(cell)) if kind == "attack" else bool(hints["moves"].has(cell))
    if not legal:
        pending_order.clear()
        message = "Accion no permitida."
        return
    var order: Dictionary = {"unit_id": selected_id, "cell": cell, "kind": kind, "target_id": enemy_id}
    if require_order_confirmation and pending_order != order:
        pending_order = order
        if kind == "attack":
            var damage := int(hints["attacks"][cell]["damage"])
            message = "Atacar %s (-%d). Toca el objetivo otra vez o Confirmar orden." % [enemy_id, damage]
        else:
            message = "Mover a (%d,%d). Toca otra vez o Confirmar orden." % [cell.x + 1, cell.y + 1]
        return
    _commit_order(order)

func _commit_order(order: Dictionary) -> bool:
    # State can change between preview and confirmation; never trust a stale hint.
    var unit_id := str(order.get("unit_id", ""))
    var cell = order.get("cell", null)
    var kind := str(order.get("kind", ""))
    var enemy_id := str(order.get("target_id", ""))
    pending_order.clear()
    if unit_id.is_empty() or unit_id != selected_id or not (cell is Vector2i):
        message = "Orden cancelada."
        return false
    if int(state.get("winner", -1)) != -1 or (ai_enabled and int(state.get("faction", -1)) != 0):
        message = "Orden cancelada."
        return false
    var hints: Dictionary = TacticalHints.for_unit(state, unit_id)
    var result: Dictionary = {}
    if kind == "attack":
        if not hints["attacks"].has(cell) or str(hints["attacks"][cell]["id"]) != enemy_id:
            message = "Objetivo ya no disponible."
            return false
        result = Session.attack(state, unit_id, enemy_id)
    elif kind == "move":
        if not hints["moves"].has(cell):
            message = "Destino ya no disponible."
            return false
        result = Session.move(state, unit_id, cell)
    else:
        message = "Orden no valida."
        return false
    if not result.get("valid", false):
        message = "Accion no permitida."
        return false
    state = result["state"]
    selected_factory_pos = Vector2i(-1,-1)
    _write_autosave()
    var winner := int(state.get("winner", -1))
    if winner != -1:
        message = "Victoria de faccion %d." % (winner + 1)
        selected_id = ""
    elif kind == "move":
        # Keep the mover selected if an enemy is now within its attack range.
        # Fog observations were refreshed by Session.move, so the list is fair.
        var follow_up: Dictionary = TacticalHints.for_unit(state, unit_id)
        if not follow_up["attacks"].is_empty():
            selected_id = unit_id
            message = "Movimiento completado. Ahora selecciona un objetivo rojo para atacar."
        else:
            selected_id = ""
            message = "Movimiento completado. Sin objetivos visibles en alcance."
    else:
        selected_id = ""
        message = "Ataque realizado."
    return true

# Purchases come from a selected, currently owned and unoccupied workshop.
# The definitive decision is validated again by BattleSession.purchase.
func can_purchase_selected(role: String) -> bool:
    if selected_factory_pos == Vector2i(-1,-1) or not pending_order.is_empty():
        return false
    if ai_enabled and int(state.get("faction",-1)) != 0:
        return false
    return Economy.can_purchase(state, selected_factory_pos, role)

func buy_selected(role: String) -> bool:
    if not can_purchase_selected(role):
        message = "No se puede producir: revisa creditos, propietario y espacio."
        return false
    var action: Dictionary = Session.purchase(state, selected_factory_pos, role)
    if not action.get("valid", false):
        message = "No se pudo producir la unidad."
        return false
    state = action["state"]
    selected_factory_pos = Vector2i(-1,-1)
    selected_id = ""
    pending_order.clear()
    message = "Unidad %s producida (-%d creditos). Actuara el proximo turno." % [Roles.label(role), int(action["cost"])]
    _write_autosave()
    queue_redraw()
    return true

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
    var visible: Dictionary = Visibility.visible_cells(state, 0) if Visibility.enabled(state) else {}
    for unit in state["units"]:
        if int(unit.get("hp",0)) > 0 and unit["pos"] == cell:
            if Visibility.enabled(state) and int(unit.get("faction", -1)) != 0 and not visible.has(cell):
                continue
            target = unit
            break
    if not target.is_empty() and int(target["faction"]) == int(state["faction"]):
        selected_factory_pos = Vector2i(-1,-1)
        pending_order.clear()
        var tapped_id := str(target["id"])
        if tapped_id == selected_id:
            selected_id = ""
            message = "Seleccion cancelada."
        elif bool(target.get("acted", false)):
            selected_id = ""
            message = "Esta unidad ya termino sus acciones."
        else:
            selected_id = tapped_id
            message = "Unidad " + selected_id + " seleccionada."
    elif not selected_id.is_empty():
        _request_order(cell, target)
    elif target.is_empty() and state.has("economy"):
        var found := false
        var own_side: int = int(state["faction"])
        var fogged: bool = Visibility.enabled(state)
        var discovered: Dictionary = Visibility.explored_cells(state,own_side) if fogged else {}
        for site in state["economy"]["sites"]:
            if site["pos"] != cell:
                continue
            # Unknown installations never expose their existence or owner
            # through tapping a dark cell.
            if fogged and not discovered.has(cell) and int(site["owner"]) != own_side:
                continue
            var owner_known: bool = not fogged or visible.has(cell) or int(site["owner"]) == own_side
            var owner_text := "desconocido"
            if owner_known:
                match int(site["owner"]):
                    0:
                        owner_text = "Azul"
                    1:
                        owner_text = "Rojo"
                    _:
                        owner_text = "neutral"
            if site["kind"] == "factory" and int(site["owner"]) == own_side:
                selected_factory_pos = cell if selected_factory_pos != cell else Vector2i(-1,-1)
                message = "Taller seleccionado. Elige una unidad y pulsa Producir." if selected_factory_pos == cell else "Taller cancelado."
            else:
                selected_factory_pos = Vector2i(-1,-1)
                if site["kind"] == "city":
                    message = "Ciudad (%s): +100 creditos/turno. Guardia o Rastreador la captura al finalizar turno." % owner_text
                else:
                    message = "Taller (%s): produce unidades para su propietario." % owner_text
            found = true
            break
        if not found:
            selected_factory_pos = Vector2i(-1,-1)
    queue_redraw()

func finish_turn() -> void:
    # Human cannot manually skip the computer faction.
    if ai_enabled and int(state.get("faction", -1)) != 0:
        return
    var previous: Dictionary = state.duplicate(true)
    var result: Dictionary = Session.end_turn(state)
    if not result.get("valid", false):
        return
    state = result["state"]
    selected_id = ""
    selected_factory_pos = Vector2i(-1,-1)
    pending_order.clear()
    last_enemy_turn_report = ""
    last_economy_report = ""
    if previous.has("economy") and state.has("economy"):
        var captured_cities := 0
        var captured_factories := 0
        for i in range(previous["economy"]["sites"].size()):
            var before_site: Dictionary = previous["economy"]["sites"][i]
            var after_site: Dictionary = state["economy"]["sites"][i]
            if int(before_site["owner"]) != int(previous["faction"]) and int(after_site["owner"]) == int(previous["faction"]):
                if after_site["kind"] == "city":
                    captured_cities += 1
                else:
                    captured_factories += 1
        if captured_cities + captured_factories > 0:
            last_economy_report = "Capturas de faccion %d: %d ciudades, %d talleres." % [int(previous["faction"])+1,captured_cities,captured_factories]
    message = "Turno de faccion " + str(state["faction"] + 1)
    if state.has("control"):
        message = "Reles: " + _relay_turn_report(previous, state, 0)
    if int(state.get("winner", -1)) != -1:
        message = "Victoria de faccion %d." % (int(state["winner"]) + 1)
    if ai_enabled and int(state["faction"]) == 1:
        _play_ai_turn()
        if previous.has("economy") and state.has("economy") and int(state.get("faction",-1)) == 0 and int(state.get("winner",-1)) == -1:
            var received: int = int(state["economy"]["credits"][0])-int(previous["economy"]["credits"][0])
            if received > 0:
                last_economy_report += " +%d creditos al iniciar tu turno." % received
    _write_autosave()
    queue_redraw()

func _play_ai_turn() -> void:
    # Never advance the computer from a human or terminal state.
    if not ai_enabled or int(state.get("faction", -1)) != 1 or int(state.get("winner", -1)) != -1:
        return
    # A unit may move and attack; each factory may additionally produce at
    # most once this phase. Bound all possibilities even after recruitment.
    var max_actions: int = (state.get("units", []) as Array).size() * 2
    if state.has("economy"):
        max_actions += state["economy"]["sites"].size()
    var movements := 0
    var attacks := 0
    var produced := 0
    for i in range(max_actions):
        if int(state.get("winner", -1)) != -1:
            break
        var result: Dictionary = BasicAI.step(state)
        if not result.get("valid", false):
            break
        state = result["state"]
        match str(result.get("action", "")):
            "move":
                movements += 1
            "attack":
                attacks += 1
            "produce":
                produced += 1
    last_enemy_turn_report = "Turno enemigo: %d movimientos, %d ataques." % [movements, attacks]
    if state.has("economy"):
        last_enemy_turn_report += " %d refuerzos producidos." % produced
    if movements + attacks + produced == 0:
        last_enemy_turn_report = "Turno enemigo: sin acciones disponibles."
    if int(state.get("winner", -1)) != -1:
        message = "Victoria de faccion %d." % (int(state["winner"]) + 1)
        return
    var before_score: Dictionary = state.duplicate(true)
    var next: Dictionary = Session.end_turn(state)
    if next.get("valid", false):
        state = next["state"]
        if state.has("control"):
            last_enemy_turn_report += " " + _relay_turn_report(before_score, state, 1)
        message = "Victoria de faccion %d." % (int(state["winner"]) + 1) if int(state.get("winner", -1)) != -1 else "Tu turno: faccion 1."

# Derive reports from actual post-turn state, never inferred intentions.
# Scores are public mission information; no hidden positions are exposed.
static func _relay_turn_report(before: Dictionary, after: Dictionary, faction: int) -> String:
    if faction not in [0, 1] or not before.has("control") or not after.has("control"):
        return ""
    var nodes_before: Array = before["control"]["nodes"]
    var nodes_after: Array = after["control"]["nodes"]
    var captures := 0
    for i in range(mini(nodes_before.size(), nodes_after.size())):
        if int(nodes_before[i]["owner"]) != faction and int(nodes_after[i]["owner"]) == faction:
            captures += 1
    var earned: int = int(after["control"]["scores"][faction]) - int(before["control"]["scores"][faction])
    return "%d reles capturados, +%d senal." % [captures, earned]

func save_game(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var ok := SaveStore.save(state, path)
    message = "Partida guardada." if ok else "No se pudo guardar la partida."
    return ok

func load_game(path: String = SaveStore.DEFAULT_PATH) -> bool:
    var report: Dictionary = SaveStore.load_report(path)
    var restored: Dictionary = report["state"]
    if restored.is_empty():
        message = "No se pudo cargar la partida."
        return false
    state = restored
    selected_factory_pos = Vector2i(-1,-1)
    current_scenario_id = Scenarios.identify(state["terrain"])
    specialized_roster = Roles.is_specialized(state["units"])
    symmetric_setup = _infer_symmetric_setup()
    selected_id = ""
    pending_order.clear()
    last_enemy_turn_report = ""
    last_economy_report = ""
    var loaded_winner := int(state.get("winner", -1))
    message = "Victoria de faccion %d." % (loaded_winner + 1) if loaded_winner != -1 else "Partida cargada."
    if bool(report["recovered"]):
        message = "Se recupero una copia anterior de la partida."
    # A saved computer turn must resume immediately; human input is locked during it.
    if ai_enabled and int(state.get("faction", -1)) == 1 and int(state.get("winner", -1)) == -1:
        _play_ai_turn()
    _write_autosave()
    queue_redraw()
    return true

# Autosave is a separate file; manual "Guardar partida" always remains untouched.
# The main scene chooses when to restore so unit tests can create fresh boards.
func _infer_symmetric_setup() -> bool:
    # Existing v1 saved games contain per-unit attack values but no setup flag.
    # Those values do not decrease when units lose HP, so the mode is recoverable.
    for unit in state.get("units", []):
        if int(unit.get("faction", -1)) == 1:
            return int(unit.get("attack", 0)) == 5
    return false

func resume_autosave() -> bool:
    var report: Dictionary = SaveStore.load_report(autosave_path)
    var restored: Dictionary = report["state"]
    if restored.is_empty():
        return false
    state = restored
    selected_factory_pos = Vector2i(-1,-1)
    current_scenario_id = Scenarios.identify(state["terrain"])
    specialized_roster = Roles.is_specialized(state["units"])
    symmetric_setup = _infer_symmetric_setup()
    selected_id = ""
    pending_order.clear()
    last_enemy_turn_report = ""
    last_economy_report = ""
    message = "Se recupero una copia anterior de la partida." if bool(report["recovered"]) else "Partida recuperada automaticamente."
    if ai_enabled and int(state.get("faction", -1)) == 1 and int(state.get("winner", -1)) == -1:
        _play_ai_turn()
        _write_autosave()
    queue_redraw()
    return true

func _write_autosave(retain_previous: bool = true) -> bool:
    if not autosave_enabled:
        return false
    var ok: bool = SaveStore.save(state, autosave_path, retain_previous)
    # An interrupted or unwritable save must not silently imply progress is safe.
    autosave_warning = "" if ok else "Atencion: no se pudo guardar automaticamente. Guarda la partida manualmente."
    return ok
