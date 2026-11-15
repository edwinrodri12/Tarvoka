extends SceneTree

const ResultsData = preload("res://scripts/ui/ResultsData.gd")
const Prefs = preload("res://scripts/ui/DisplayPreferences.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var pref_path: String = Prefs.FILE_PATH
    var had_settings: bool = FileAccess.file_exists(pref_path)
    var saved_settings: PackedByteArray = FileAccess.get_file_as_bytes(pref_path) if had_settings else PackedByteArray()
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    var state_before: Dictionary = main.board.state.duplicate(true)

    main._show_home_menu()
    main._open_settings_from_home()
    var settings: Control = main.home_settings_menu
    var menu: Control = main.command_menu
    assert(settings.visible and not main.home_menu.visible)
    assert(not menu.visible) # In-battle command menu stays isolated.
    assert(settings.category_buttons.size() == 4)
    assert(settings.setting_buttons.size() == 3)
    assert(not settings.content_rail.vertical)
    var view: Button = settings.setting_buttons["isometric"]
    var saver: Button = settings.setting_buttons["battery_saver"]
    var map: Button = settings.setting_buttons["minimap_enabled"]
    assert(view.custom_minimum_size.y >= 44)
    assert(saver.custom_minimum_size.y >= 44)
    assert(map.custom_minimum_size.y >= 44)

    # The original saved display handlers still own each real preference.
    var iso_at_start: bool = main.board.iso_enabled
    var battery_at_start: bool = main.board.battery_saver
    var mini_at_start: bool = main._minimap_preference
    view.pressed.emit()
    assert(main.board.iso_enabled != iso_at_start)
    assert(view.text.contains("ISOMÉTRICA" if main.board.iso_enabled else "CLÁSICA"))
    saver.pressed.emit()
    assert(main.board.battery_saver != battery_at_start)
    map.pressed.emit()
    assert(main._minimap_preference != mini_at_start)
    assert(main.board.state == state_before)
    # Restore actual values; opening/closing the menu never changes a battle.
    view.pressed.emit()
    saver.pressed.emit()
    map.pressed.emit()
    assert(main.board.iso_enabled == iso_at_start)
    assert(main.board.battery_saver == battery_at_start)
    assert(main._minimap_preference == mini_at_start)
    settings.close_requested.emit()
    assert(main.home_menu.visible and not settings.visible)

    main.home_menu.hide()
    main._open_command_menu()
    assert(menu.tabs.current_tab == 0)
    assert(menu.battle_columns != null)
    assert(not menu.battle_columns.vertical)
    assert(menu.battle_columns.get_child_count() == 2)
    assert(menu.battle_body.get_child_count() == 1)
    var portraits: Control = menu.battle_columns.find_child("ComandantesDelCentroDeMando",true,false)
    assert(portraits != null and portraits.portraits.size() == 2)
    assert(portraits.portraits[0].texture != null)
    assert(portraits.portraits[1].texture != null)
    assert(main.board.state == state_before)

    var terminal: Dictionary = state_before.duplicate(true)
    terminal["winner"] = 0
    assert(bool(ResultsData.report(terminal).get("valid",false)))
    var panel: Control = main.results_panel
    panel.open_for(terminal,0)
    assert(panel.visible)
    assert(panel.result_columns != null)
    assert(panel.result_columns.get_child_count() == 2)
    assert(not panel.result_columns.vertical)
    assert(panel.stats_column.get_parent() == panel.stats_scroll)
    assert(panel.title_label.text.contains("VICTORIA"))
    assert(panel.commander_matchup.portraits.size() == 2)
    assert(panel.stats_column.get_child_count() >= 3)
    assert(main.board.state == state_before)
    panel.hide()

    # Verify a horizontal phone viewport never stacks battle or result cards.
    root.size = Vector2i(960,540)
    await process_frame
    panel._reflow()
    assert(not panel.result_columns.vertical)
    assert(not menu.battle_columns.vertical)

    if had_settings:
        var old_file := FileAccess.open(pref_path,FileAccess.WRITE)
        assert(old_file != null)
        old_file.store_buffer(saved_settings)
        old_file.close()
    elif FileAccess.file_exists(pref_path):
        assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(pref_path)) == OK)

    main.queue_free()
    print("PASS landscape dashboards: battle commands, live settings toggles, horizontal truth-only results and unchanged battle")
    quit(0)
