extends Control

const BoardScript = preload("res://scripts/ui/TouchBoard.gd")
var board: Control
var status_label: Label
var end_button: Button

func _ready() -> void:
    var layout := VBoxContainer.new()
    layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(layout)
    var heading := Label.new()
    heading.text = "TARVOKA | Prototipo tactico local"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(heading)
    board = BoardScript.new()
    board.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board.custom_minimum_size = Vector2(280, 240)
    layout.add_child(board)
    status_label = Label.new()
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(status_label)
    end_button = Button.new()
    end_button.text = "Terminar turno"
    end_button.custom_minimum_size.y = 54
    end_button.pressed.connect(_end_turn)
    layout.add_child(end_button)
    var save_button := Button.new()
    save_button.text = "Guardar partida"
    save_button.custom_minimum_size.y = 48
    save_button.pressed.connect(_save_game)
    layout.add_child(save_button)
    var load_button := Button.new()
    load_button.text = "Cargar partida"
    load_button.custom_minimum_size.y = 48
    load_button.pressed.connect(_load_game)
    layout.add_child(load_button)
    set_process(true)

func _process(_delta: float) -> void:
    if board == null or status_label == null:
        return
    var winner := int(board.state.get("winner",-1))
    end_button.disabled = winner != -1
    if winner != -1:
        status_label.text = "Victoria de faccion %d" % (winner + 1)
    else:
        status_label.text = "Faccion %d | %s" % [int(board.state.get("faction",0)) + 1, board.message]

func _end_turn() -> void:
    board.finish_turn()

func _save_game() -> void:
    board.save_game()

func _load_game() -> void:
    board.load_game()
