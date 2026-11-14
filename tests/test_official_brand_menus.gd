extends SceneTree

const Scenarios = preload("res://scripts/core/Scenarios.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const SavedUI = preload("res://scripts/ui/SavedMatchesMenu.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    await process_frame
    var home = screen.home_menu
    assert(home != null and home.primary_buttons.size() == 7)
    assert(home.primary_buttons.has("Partidas guardadas"))
    assert(home.primary_buttons["Multijugador"].disabled)
    assert(home.hero != null and home.action_card != null)
    assert(home._brand_image.texture != null)
    var reference := Image.new()
    assert(reference.load(home.OFFICIAL_ICON) == OK)
    assert(reference.get_width() == 64 and reference.get_height() == 64)

    screen._show_home_menu()
    assert(home.visible)
    var baseline: Dictionary = screen.board.state.duplicate(true)

    # Landscape navigation uses the same real save and battle controls.
    home._reflow()
    home.primary_buttons["Partidas guardadas"].pressed.emit()
    var slots = screen.saved_matches_menu
    assert(not home.visible and slots.visible)
    assert(slots.slot_buttons.size() == 2)
    assert(screen.board.state == baseline)
    slots.back_requested.emit()
    assert(home.visible and not slots.visible)

    screen._prepare_skirmish()
    var setup = screen.skirmish_setup
    assert(setup.visible and not home.visible)
    assert(setup.map_preview != null)
    setup.apply_preset(2)
    assert(setup.map_preview.preview_map == Scenarios.seeded_terrain(
        int(setup.seed_picker.value),Vector2i(24,18)))
    setup.scenario_picker.select(1)
    setup.size_picker.select(0)
    setup._changed()
    assert(setup.map_preview.preview_map == Scenarios.terrain(1))
    var old_tiles: Array = setup.map_preview.preview_map.duplicate(true)
    setup.scenario_picker.select(Scenarios.RANDOM_SCENARIO_ID)
    setup.seed_picker.value = 77137
    setup._changed()
    assert(setup.map_preview.preview_map == Scenarios.seeded_terrain(77137))
    assert(setup.map_preview.preview_map != old_tiles)
    assert(screen.board.state == baseline)

    # User-readable save slots only enable after a real, validated file
    # is written. Requesting the list cannot load or erase the battle.
    assert(SaveStore.save(baseline,SavedUI.AUTO_PATH))
    assert(SaveStore.save(baseline,SavedUI.MANUAL_PATH))
    screen._show_home_menu()
    home.primary_buttons["Partidas guardadas"].pressed.emit()
    assert(slots.slot_buttons["auto"].disabled == false)
    assert(slots.slot_buttons["manual"].disabled == false)
    assert(str(slots.slot_summaries["auto"].text).contains("Batalla"))
    assert(screen.board.state == baseline)
    slots.slot_buttons["manual"].pressed.emit()
    assert(slots.visible and slots.confirmation_panel.visible)
    assert(screen.board.state == baseline) # Preview alone never loads.
    slots.cancel_load_button.pressed.emit()
    assert(slots.visible and not slots.confirmation_panel.visible)
    assert(screen.board.state == baseline)
    slots.slot_buttons["manual"].pressed.emit()
    slots.confirm_load_button.pressed.emit()
    assert(not slots.visible and screen.board.state == baseline)

    # A rejected arbitrary save path cannot reach disk through this UI.
    screen._show_home_menu()
    home.primary_buttons["Partidas guardadas"].pressed.emit()
    screen._load_saved_match("res://fake_save.json")
    assert(slots.visible and screen.board.state == baseline)
    slots.back_requested.emit()
    assert(home.visible)

    # Settings/Arsenal opened from the title screen must return to Inicio,
    # not silently expose the battle behind the menu.
    home.primary_buttons["Ajustes"].pressed.emit()
    assert(screen.command_menu.visible and not home.visible)
    screen.command_menu.close_requested.emit()
    assert(home.visible and not screen.command_menu.visible)
    home.primary_buttons["Arsenal"].pressed.emit()
    assert(screen._gallery_from_home and not home.visible)
    # The new official full-screen landscape Arsenal is a themed
    # PanelContainer, not the retired AcceptDialog with a confirmed signal.
    assert(screen.unit_art_gallery.visible)
    screen.unit_art_gallery.close_requested.emit()
    assert(not screen.unit_art_gallery.visible)
    assert(home.visible and not screen._gallery_from_home)
    screen._continue_from_home()
    assert(not home.visible)
    screen._open_command_menu()
    assert(not screen._command_from_home)
    screen.command_menu.close_requested.emit()
    assert(not screen.command_menu.visible and not home.visible)
    screen._show_home_menu()

    # The campaign button stays wired, but tests do not switch the scene.
    assert(home.primary_buttons["Modo historia"].disabled == false)
    assert(home.primary_buttons["Escaramuza"].disabled == false)
    assert(home.primary_buttons["Continuar"].disabled == false)
    screen.queue_free()
    for path in [SavedUI.AUTO_PATH,SavedUI.MANUAL_PATH]:
        for suffix in ["",".bak",".tmp"]:
            if FileAccess.file_exists(path+suffix):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    print("PASS official brand home and save selection: fictional planet icon, functional routes, live scenario preview and safe slots")
    quit(0)
