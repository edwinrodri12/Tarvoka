extends Control
class_name TarvokaChapter01Screen

# Campaign owns only narrative goals and checkpoint; the real TouchBoard
# continues resolving moves, attacks, AI turns, fog and camera gestures.
const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
const Mission = preload("res://scripts/core/CampaignMission.gd")
const Store = preload("res://scripts/core/CampaignStore.gd")
const MinimapScript = preload("res://scripts/ui/BattleMinimap.gd")

var checkpoint_path: String = Store.DEFAULT_PATH
var mission: Dictionary = {}
var board: Control
var grid: GridContainer
var board_holder: MarginContainer
var objective_label: Label
var progress_label: Label
var dialogue_label: Label
var battlefield_label: Label
var notice_label: Label
var end_button: Button
var confirm_button: Button
var cancel_button: Button
var restart_dialog: ConfirmationDialog
var minimap: Control
var _draw_hash: int = -1

func _ready() -> void:
    var background := ColorRect.new()
    background.color = Color("#0D1720")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    grid = GridContainer.new()
    grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    grid.add_theme_constant_override("h_separation",6)
    grid.add_theme_constant_override("v_separation",6)
    add_child(grid)
    board_holder = MarginContainer.new()
    board_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board_holder.custom_minimum_size = Vector2(260,250)
    grid.add_child(board_holder)

    board = BoardScript.new()
    board.autosave_enabled = false # Never overwrite skirmish autosave.
    board.require_order_confirmation = true
    board.ai_enabled = true
    board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board.tactical_action_committed.connect(_on_tactical_action)
    board.tactical_phase_completed.connect(_on_tactical_phase)
    board_holder.add_child(board)
    board.set_isometric(true)

    var sidebar := PanelContainer.new()
    sidebar.custom_minimum_size.x = 305
    sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var dark := StyleBoxFlat.new()
    dark.bg_color = Color("#172733")
    dark.content_margin_left = 12
    dark.content_margin_right = 12
    dark.content_margin_top = 9
    dark.content_margin_bottom = 9
    sidebar.add_theme_stylebox_override("panel", dark)
    grid.add_child(sidebar)
    var scrolling := ScrollContainer.new()
    scrolling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scrolling.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scrolling.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sidebar.add_child(scrolling)
    var panel := VBoxContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_constant_override("separation",8)
    scrolling.add_child(panel)

    var title := Label.new()
    title.text = "TARVOKA · MODO HISTORIA"
    title.add_theme_color_override("font_color",Color("#FFD875"))
    title.add_theme_font_size_override("font_size",19)
    panel.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "01 / 50 — ESCUDO COMPARTIDO"
    subtitle.add_theme_font_size_override("font_size",17)
    panel.add_child(subtitle)
    objective_label = Label.new()
    objective_label.text = "Captura las 2 balizas con Guardia y mantenlas durante la respuesta rival. Eliminar enemigos NO sustituye el objetivo."
    objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    objective_label.add_theme_font_size_override("font_size",16)
    panel.add_child(objective_label)
    progress_label = Label.new()
    progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    progress_label.add_theme_color_override("font_color",Color("#9BE4BD"))
    progress_label.add_theme_font_size_override("font_size",16)
    panel.add_child(progress_label)

    minimap = MinimapScript.new()
    minimap.custom_minimum_size = Vector2(230,130)
    minimap.call("set_board",board)
    panel.add_child(minimap)

    var dialogue_heading := Label.new()
    dialogue_heading.text = "COMUNICACIONES · MERIDIAN"
    dialogue_heading.add_theme_color_override("font_color",Color("#FFD875"))
    panel.add_child(dialogue_heading)
    dialogue_label = Label.new()
    dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_label.add_theme_font_size_override("font_size",16)
    panel.add_child(dialogue_label)
    battlefield_label = Label.new()
    battlefield_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(battlefield_label)

    var commands := HBoxContainer.new()
    panel.add_child(commands)
    confirm_button = _button(commands,"Confirmar",_confirm_order)
    cancel_button = _button(commands,"Cancelar",_cancel_order)
    end_button = _button(panel,"Terminar turno",_finish_turn)
    var zoom_row := HBoxContainer.new()
    panel.add_child(zoom_row)
    _button(zoom_row,"Zoom −",func(): board.change_view_zoom(-1))
    _button(zoom_row,"Zoom +",func(): board.change_view_zoom(1))
    _button(zoom_row,"Centrar",func(): board.frame_player_force())
    var lower := HBoxContainer.new()
    panel.add_child(lower)
    _button(lower,"Guardar",_save_checkpoint)
    _button(lower,"Reiniciar",_ask_restart)
    _button(panel,"Volver a batallas libres",_back_to_main)
    notice_label = Label.new()
    notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notice_label.add_theme_color_override("font_color",Color("#FFD27A"))
    panel.add_child(notice_label)
    restart_dialog = ConfirmationDialog.new()
    restart_dialog.title = "Reiniciar capítulo 01"
    restart_dialog.dialog_text = "Se reemplazará únicamente el guardado del capítulo 01. Las partidas libres no se tocarán."
    restart_dialog.confirmed.connect(_start_fresh)
    add_child(restart_dialog)
    get_viewport().size_changed.connect(_layout)
    _layout()
    var report: Dictionary = Store.load_report(checkpoint_path)
    if report["state"].is_empty():
        _start_fresh()
    else:
        _apply_loaded(report["state"],bool(report["recovered"]))
    set_process(true)

func _button(parent: Node, title: String, handler: Callable) -> Button:
    var button := Button.new()
    button.text = title
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.custom_minimum_size.y = 44
    button.pressed.connect(handler)
    parent.add_child(button)
    return button

func _layout() -> void:
    if grid == null:
        return
    var bounds: Vector2 = get_viewport_rect().size
    var tall: bool = bounds.y > bounds.x
    grid.columns = 1 if tall else 2
    board_holder.custom_minimum_size = Vector2(260,maxf(260.0,bounds.y*0.50)) if tall else Vector2(260,250)

func _start_fresh() -> void:
    mission = Mission.start_c01()
    if mission.is_empty():
        notice_label.text = "No se pudo iniciar el capítulo."
        return
    _set_board(mission)
    dialogue_label.text = "La Alianza Norte y el Pacto Escarlata realizan un ejercicio conjunto. Munición de simulación; sin bajas reales."
    _emit_narrative("C01_START")
    _save_checkpoint()
    notice_label.text = "Ejercicio iniciado. Las balizas 1 y 2 están marcadas en amarillo."

func _apply_loaded(restored: Dictionary, recovered: bool) -> void:
    mission = restored.duplicate(true)
    _set_board(mission)
    var history: Array = mission["events_seen"]
    if not history.is_empty():
        _show_dialogue(str(history.back()))
    else:
        dialogue_label.text = "El ejercicio conjunto está en marcha."
    notice_label.text = "Se recuperó un guardado anterior del capítulo." if recovered else "Capítulo reanudado."

func _set_board(data: Dictionary) -> void:
    board.state = data["battle"].duplicate(true)
    board.ai_enabled = true
    board.autosave_enabled = false
    board.campaign_locked = str(data["status"]) in ["completed","failed"]
    board.campaign_markers = [Vector2i(4,2),Vector2i(5,5)]
    board.selected_id = ""
    board.inspected_enemy_id = ""
    board.pending_order.clear()
    board.message = "Ejercicio conjunto: selecciona una Guardia."
    board.queue_redraw()
    if minimap != null:
        minimap.queue_redraw()
    _draw_hash = -1
    _refresh()

func _on_tactical_action(facts: Dictionary) -> void:
    if mission.is_empty() or str(mission["status"]) in ["completed","failed"]:
        return
    mission["battle"] = board.state.duplicate(true)
    if str(facts.get("kind","")) == "attack":
        var result: Dictionary = facts.get("result",{})
        _emit_narrative("C01_FIRST_ATTACK",{"valid":true,"attacker_id":str(facts.get("unit_id",""))})
    _emit_narrative("C01_FIRST_CAPTURE")
    if int(board.state.get("winner",-1)) != -1:
        mission = Mission.resolve_terminal(mission,board.state)
    _finish_if_terminal()
    _save_checkpoint()
    board.queue_redraw()

func _on_tactical_phase(completed_side: int) -> void:
    if mission.is_empty() or str(mission["status"]) in ["completed","failed"]:
        return
    mission = Mission.after_phase(mission,board.state,completed_side)
    _emit_narrative("C01_FIRST_CAPTURE")
    _finish_if_terminal()
    _save_checkpoint()
    board.queue_redraw()

func _finish_if_terminal() -> void:
    var outcome: String = str(mission.get("status",""))
    if outcome == "completed":
        _emit_narrative("C01_SUCCESS")
        board.campaign_locked = true
        notice_label.text = "CAPÍTULO COMPLETADO · Guardia (G01) desbloqueada para la campaña. Siguiente: Dos minutos de silencio (en desarrollo)."
    elif outcome == "failed":
        board.campaign_locked = true
        notice_label.text = "EJERCICIO FALLIDO · Tienes que conservar ambas balizas; puedes reiniciar sin penalización."

func _emit_narrative(event_id: String, context: Dictionary = {}) -> void:
    var result: Dictionary = Mission.acknowledge_event(mission,event_id,context)
    if not bool(result["valid"]):
        return
    mission = result["state"]
    _show_dialogue(event_id)

func _show_dialogue(event_id: String) -> void:
    var captions: Dictionary = {
        "alianza_norte":"ALIANZA NORTE",
        "pacto_escarlata":"PACTO ESCARLATA",
        "control":"CENTRAL DE CONTROL"
    }
    var lines: Array[String] = []
    for line in Mission.EVENTS.get(event_id,[]):
        lines.append("%s: %s" % [str(captions.get(str(line.get("speaker","")),"CONTROL")),str(line.get("text",""))])
    dialogue_label.text = "\n".join(lines)

func _save_checkpoint() -> void:
    if mission.is_empty():
        return
    # The board is authoritative; never snapshot the old pre-action army.
    mission["battle"] = board.state.duplicate(true)
    if not Store.save(mission,checkpoint_path):
        notice_label.text = "Atención: no se pudo guardar el capítulo."
    _refresh()

func _confirm_order() -> void:
    board.confirm_pending_order()

func _cancel_order() -> void:
    board.cancel_selection()

func _finish_turn() -> void:
    if not board.pending_order.is_empty():
        notice_label.text = "Confirma o cancela la orden antes de finalizar el turno."
        return
    board.finish_turn()
    _refresh()

func _ask_restart() -> void:
    if DisplayServer.get_name() != "headless":
        restart_dialog.popup_centered()

func _back_to_main() -> void:
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _process(_delta: float) -> void:
    if board == null or mission.is_empty():
        return
    var state_key: int = hash([board.state,mission["status"],board.selected_id,board.pending_order,board.message])
    if state_key != _draw_hash:
        _draw_hash = state_key
        _refresh()
        if minimap != null:
            minimap.queue_redraw()

func _refresh() -> void:
    if mission.is_empty() or board == null or progress_label == null:
        return
    var held: int = 0
    for coords in Mission.BEACONS:
        var cell := Vector2i(int(coords[0]),int(coords[1]))
        for u in board.state.get("units",[]):
            if u is Dictionary and int(u.get("hp",0)) > 0 and int(u.get("faction",-1)) == 0 and u.get("pos") == cell:
                held += 1
                break
    var stage: String = str(mission["status"])
    progress_label.text = ("Balizas aseguradas: %d/2 · %s" % [held,"resiste el turno rojo" if stage == "holding" else "ocupa ambas"]) if stage in ["active","holding"] else ("VICTORIA NARRATIVA · 01/50" if stage == "completed" else "OBJETIVO FALLIDO · REINTENTAR")
    battlefield_label.text = "Turno %s · %s" % ["Alianza Norte" if int(board.state.get("faction",0)) == 0 else "Pacto Escarlata",str(board.message)]
    var locked: bool = board.campaign_locked or int(board.state.get("winner",-1)) != -1 or int(board.state.get("faction",0)) != 0
    end_button.disabled = locked or not board.pending_order.is_empty()
    confirm_button.disabled = locked or board.pending_order.is_empty()
    cancel_button.disabled = board.pending_order.is_empty() and board.selected_id.is_empty()
