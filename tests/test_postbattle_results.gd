extends SceneTree

const ResultsData = preload("res://scripts/ui/ResultsData.gd")
const ResultsPanel = preload("res://scripts/ui/ResultsPanel.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var units: Array = [
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("B",0,Vector2i(2,2),"scout"),
        Roles.make_unit("X",1,Vector2i(8,2),"tank"),
        Roles.make_unit("Y",1,Vector2i(8,4),"scout")
    ]
    units[1]["hp"] = 3
    units[2]["hp"] = 0
    units[3]["hp"] = 0
    var game: Dictionary = Session.start(units,terrain,0,false,false,true)
    var copy: Dictionary = game.duplicate(true)
    assert(int(game["winner"]) == 0)
    var report: Dictionary = ResultsData.report(game)
    assert(report["valid"] and report["winner"] == 0)
    assert(report["survivors"] == [2,0])
    assert(report["recorded_losses"] == [0,2])
    assert(report["hp"][0] == 13)
    assert(report["hp"][1] == 0)
    assert(report["cause"] == "Victoria por eliminación")
    assert(report["cities"] == [1,1])
    assert(report["income"] == [100,100])
    assert(report["has_economy"])
    assert(not report["has_relay"])
    assert(game == copy)
    assert(not ResultsData.report({"winner":-1,"units":units})["valid"])
    assert(not ResultsData.report({"winner":0,"units":"oops"})["valid"])

    var relay: Dictionary = Session.start(units,terrain,0,false,true,false)
    relay["control"]["scores"][0] = int(relay["control"]["target"])
    relay["winner"] = 0
    var by_relay: Dictionary = ResultsData.report(relay)
    assert(by_relay["relay_victory"])
    assert(by_relay["cause"] == "Victoria por control de relés")
    assert(by_relay["signal"][0] == by_relay["signal_target"])
    assert(not by_relay["has_economy"])

    var viewer_two: Dictionary = game.duplicate(true)
    viewer_two["winner"] = 1
    viewer_two["units"][0]["hp"] = 0
    viewer_two["units"][1]["hp"] = 0
    viewer_two["units"][2]["hp"] = 7
    var red_result: Dictionary = ResultsData.report(viewer_two)
    assert(red_result["valid"] and red_result["winner"] == 1)

    var panel: Control = ResultsPanel.new()
    root.add_child(panel)
    panel.open_for(game,0)
    assert(panel.visible)
    assert(panel.title_label.text.contains("VICTORIA"))
    assert(panel.stats_column.get_child_count() >= 6)
    panel.open_for(viewer_two,1)
    assert(panel.title_label.text.contains("VICTORIA"))
    assert(panel.title_label.text.contains("ROJO"))
    panel.open_for(viewer_two,0)
    assert(panel.title_label.text.contains("DERROTA"))
    panel.open_for({},0)
    assert(not panel.visible)
    panel.queue_free()

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    main.board.new_game(0,false,false,false,true,true)
    var before: Dictionary = main.board.state.duplicate(true)
    assert(not main.results_panel.visible)
    assert(not main.results_scrim.visible)
    main.board.state = game.duplicate(true)
    var terminal: Dictionary = main.board.state.duplicate(true)
    main._process(0.0)
    assert(main.results_panel.visible)
    assert(main.results_scrim.visible)
    assert(main.result_banner.visible)
    assert(main.result_title.text == "VICTORIA")
    assert(main.compact_confirm.text == "Resultados")
    assert(not main.compact_confirm.disabled)
    assert(not main.confirm_button.disabled)
    assert(main.board.state == terminal)

    main.results_panel.map_requested.emit()
    assert(not main.results_panel.visible)
    assert(not main.results_scrim.visible)
    main._process(0.0)
    assert(not main.results_panel.visible) # Do not reopen every frame.
    main.compact_confirm.pressed.emit()
    assert(main.results_panel.visible)
    assert(main.board.state == terminal)
    main.results_panel.home_requested.emit()
    assert(main.home_menu.visible)
    assert(not main.results_panel.visible)
    assert(main.board.state == terminal)
    main.home_menu.hide()
    main._open_results_screen()
    main.results_panel.new_battle_requested.emit()
    assert(main.skirmish_setup.visible)
    assert(not main.results_panel.visible)
    assert(main.board.state == terminal) # Before confirmation nothing resets.
    main.skirmish_setup.hide()

    main._confirm_new_game()
    main._process(0.0)
    assert(int(main.board.state["winner"]) == -1)
    assert(not main.results_panel.visible)
    assert(not main.results_scrim.visible)
    assert(main._results_seen_signature == -1)
    assert(not main.compact_confirm.text == "Resultados")
    assert(before["winner"] == -1)

    main.queue_free()
    print("PASS postbattle results: truthful end metrics, both factions, radar-safe modal, preserve finished match, confirm new battle")
    quit(0)
