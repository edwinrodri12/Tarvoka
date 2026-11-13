extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Preview = preload("res://scripts/ui/CombatPreviewData.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var attacker := Roles.make_unit("A",0,Vector2i(1,2),"line")
    var defender := Roles.make_unit("X",1,Vector2i(2,2),"line")
    var map: Array = Scenarios.terrain(1)
    assert(map[2][2] == "forest")
    var state: Dictionary = Session.start([attacker,defender],map,0,true)
    var snapshot: Dictionary = state.duplicate(true)
    var preview_order := {
        "kind":"attack","unit_id":"A","target_id":"X","cell":Vector2i(2,2)
    }
    var hinted: Dictionary = Hints.for_unit(state,"A")["attacks"][Vector2i(2,2)]
    var forecast: Dictionary = Preview.estimate(state,preview_order)
    assert(bool(forecast["valid"]))
    assert(int(forecast["enemy_loss"]) == mini(int(defender["hp"]),int(hinted["damage"])))
    assert(int(forecast["counter_max"]) == int(hinted["counter_damage"]))
    assert(int(forecast["defender_after"]) == maxi(0,int(defender["hp"])-int(hinted["damage"])))
    assert(str(forecast["explanation"]).contains("Cobertura enemiga: +1"))
    assert(str(forecast["counter_note"]).contains("MAXIMA"))
    assert(state == snapshot)
    # A hypothetical unseen reacted flag is never used to tell the player
    # that a defender cannot respond. No hidden ammo or readiness leaks.
    var altered: Dictionary = state.duplicate(true)
    altered["units"][1]["reacted"] = true
    assert(int(Preview.estimate(altered,preview_order)["counter_max"]) == int(forecast["counter_max"]))
    var forged: Dictionary = preview_order.duplicate(true)
    forged["target_id"] = "OTRO"
    assert(not bool(Preview.estimate(state,forged).get("valid",false)))
    var hidden: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,6),"line")
    ],map,0,true)
    forged["target_id"] = "X"
    forged["cell"] = Vector2i(8,6)
    assert(not bool(Preview.estimate(hidden,forged).get("valid",false)))
    assert(not bool(Preview.estimate(state,{}).get("valid",false)))

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    assert(main.skirmish_setup != null)
    assert(not main.skirmish_setup.visible)
    var battle_snapshot: Dictionary = board.state.duplicate(true)
    main._prepare_skirmish()
    var setup: Control = main.skirmish_setup
    assert(setup.visible)
    assert(board.state == battle_snapshot)
    setup.apply_preset(0)
    var choices: Dictionary = setup.options()
    assert(choices["roster"] == 0 and choices["economy"] == 0 and choices["size"] == 0)
    setup.apply_preset(2)
    choices = setup.options()
    assert(choices["roster"] == 2 and choices["economy"] == 1 and choices["objective"] == 1)
    assert(choices["scenario"] == Scenarios.RANDOM_SCENARIO_ID)
    assert(board.state == battle_snapshot)
    setup.load_choices({"scenario":0,"size":0,"roster":0,"fog":0,"economy":1,
        "objective":0,"balance":0,"first":0,"seed":12345})
    assert(setup.options()["economy"] == 0) # Invalid classic+economy combination normalized.
    assert(setup.economy_picker.disabled)
    # The setup button only requests an existing confirmation. No automatic reset.
    setup.start_button.pressed.emit()
    assert(board.state == battle_snapshot)
    assert(main.new_game_dialog != null)
    main.new_game_dialog.confirmed.emit()
    assert(not setup.visible)
    assert(board.state["faction"] == 0)
    assert(board.state["terrain"].size() == 8)

    board.state = state
    board.selected_id = "A"
    board.inspected_cell = Vector2i(2,2)
    board.pending_order = preview_order
    main._process(0.0)
    assert(main.compact_combat_preview.visible)
    assert(main.sidebar_combat_preview.visible)
    assert(main.compact_combat_preview.exchange.text.contains("Respuesta hasta"))
    assert(main.compact_combat_preview.effects.text.contains("Cobertura enemiga"))
    assert(not main.compact_info_panel.visible) # One compact overlay, never two.
    var same_state: Dictionary = board.state.duplicate(true)
    board.cancel_selection()
    main._process(0.0)
    assert(not main.compact_combat_preview.visible)
    assert(board.state == same_state)

    main.queue_free()
    for suffix in ["",".bak"]:
        var path: String = "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS skirmish setup and combat forecast: presets, confirmation, forest cover, counter upper bound, fog privacy, HUD")
    quit(0)
