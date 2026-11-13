extends SceneTree

const Preferences = preload("res://scripts/ui/DisplayPreferences.gd")

func _initialize() -> void:
    call_deferred("_run")

func _remove(path: String) -> void:
    if FileAccess.file_exists(path):
        assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)

func _run() -> void:
    var local_path := "user://tarvoka_display_preferences_test.cfg"
    _remove(local_path)
    _remove(Preferences.FILE_PATH)
    assert(Preferences.load_config(false,local_path) == {
        "isometric":false,"battery_saver":false,"minimap_enabled":false
    })
    assert(Preferences.load_config(true,local_path) == {
        "isometric":true,"battery_saver":false,"minimap_enabled":true
    })
    var stored := {"isometric":true,"battery_saver":true,"minimap_enabled":false}
    assert(Preferences.save_config(stored,local_path))
    assert(Preferences.load_config(false,local_path) == stored)
    assert(not Preferences.save_config({"isometric":1,"battery_saver":true,"minimap_enabled":false},local_path))
    assert(Preferences.load_config(false,local_path) == stored)
    # Old and tampered configs fall back safely; no unsafe arbitrary types.
    var invalid := ConfigFile.new()
    invalid.set_value("display","version",3)
    invalid.set_value("display","isometric",false)
    assert(invalid.save(local_path) == OK)
    assert(Preferences.load_config(true,local_path)["isometric"] == true)
    invalid.set_value("display","version",Preferences.VERSION)
    invalid.set_value("display","isometric","yes")
    assert(invalid.save(local_path) == OK)
    assert(Preferences.load_config(false,local_path)["isometric"] == false)
    _remove(local_path)

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board = main.board
    board.autosave_enabled = false
    var before: Dictionary = board.state.duplicate(true)
    assert(not board.iso_enabled)
    assert(not board.battery_saver)
    assert(not main._minimap_preference)
    assert(not main.battle_minimap.visible)
    main._toggle_isometric_view()
    assert(board.iso_enabled)
    assert(not main.battle_minimap.visible) # User preference still off.
    main._toggle_minimap()
    assert(main.battle_minimap.visible)
    assert(main.minimap_caption.visible)
    assert(main._minimap_preference)
    main._toggle_isometric_view()
    assert(not board.iso_enabled)
    assert(not main.battle_minimap.visible)
    assert(main._minimap_preference) # Remember until next iso switch.
    main._toggle_isometric_view()
    assert(main.battle_minimap.visible)
    main._toggle_battery_saver()
    assert(board.battery_saver)
    assert(board.state == before) # No movement, credit changes or saved turn.
    var saved: Dictionary = Preferences.load_config(false)
    assert(saved == {"isometric":true,"battery_saver":true,"minimap_enabled":true})
    main.command_menu.open_for(board,"Ajustes")
    main.command_menu.refresh()
    assert(main.command_menu.minimap_enabled)
    assert(main.command_menu.settings_body.get_child_count() > 5)
    main.command_menu.hide()
    main.queue_free()
    await process_frame

    var restored: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(restored)
    await process_frame
    restored.board.autosave_enabled = false
    assert(restored.board.iso_enabled)
    assert(restored.board.battery_saver)
    assert(restored.battle_minimap.visible)
    assert(restored._minimap_preference)
    restored._toggle_minimap()
    assert(not restored.battle_minimap.visible)
    assert(not Preferences.load_config(false)["minimap_enabled"])
    restored.queue_free()
    await process_frame
    _remove(Preferences.FILE_PATH)
    for suffix in ["",".bak"]:
        _remove("user://tarvoka_autosave_v1.json" + suffix)
    print("PASS persistent display preferences: validation, UI toggles, minimized map, restart and save isolation")
    quit(0)
