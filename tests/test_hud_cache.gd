extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var main: Control = scene.instantiate()
    root.add_child(main)
    var board = main.get("board")
    var detail: Label = main.get("unit_label")
    var status: Label = main.get("status_label")

    var previous: int = main.unit_summary_refresh_count
    assert(previous >= 1)
    for i in range(120):
        main._process(0.0) # Simulate 2 seconds at 60 fps, unchanged.
    assert(main.unit_summary_refresh_count == previous)

    # Selection requires fresh tactical hints once, not every frame.
    board.selected_id = "A"
    main._process(0.0)
    assert(main.unit_summary_refresh_count == previous + 1)
    assert(detail.text.contains("Vida 10"))
    previous = main.unit_summary_refresh_count
    for i in range(60):
        main._process(0.0)
    assert(main.unit_summary_refresh_count == previous)

    # Mutating a unit through a direct state API must invalidate the cache.
    board.state["units"][0]["hp"] = 7
    main._process(0.0)
    assert(main.unit_summary_refresh_count == previous + 1)
    assert(detail.text.contains("Vida 7"))
    previous = main.unit_summary_refresh_count

    # Text feedback alone should update the status, not re-run pathfinding.
    board.message = "Orden preparada; espera confirmacion."
    main._process(0.0)
    assert(status.text.contains("Orden preparada"))
    assert(main.unit_summary_refresh_count == previous)

    # Terminal state and new scenario always cause an actual refresh.
    board.state["winner"] = 1
    main._process(0.0)
    assert(main.unit_summary_refresh_count == previous + 1)
    assert(main.get("result_banner").visible)
    previous = main.unit_summary_refresh_count
    board.new_game(2)
    main._process(0.0)
    assert(main.unit_summary_refresh_count == previous + 1)
    assert(not main.get("result_banner").visible)

    for suffix in ["", ".bak", ".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(board.autosave_path + suffix))
    main.queue_free()
    print("PASS HUD performance: 180 idle frames without duplicate tactical pathfinding")
    quit(0)
