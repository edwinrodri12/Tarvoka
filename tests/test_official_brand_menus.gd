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
    # Approved commercial home adds Online, Créditos and Salir beyond the old 7-key registry.
    assert(home != null and home.primary_buttons.size() >= 8)
    assert(home.primary_buttons.has("Online"))
    assert(home.primary_buttons["Online"].disabled)
    assert(home.primary_buttons.has("Créditos"))
    assert(home.primary_buttons.has("Salir"))
    assert(home.showcase_emblems.size() == 8)
    for shield in home.showcase_emblems:
        assert(shield.texture != null)
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
    assert(setup.active_preset == 2)
    assert(setup.faction_crests.size() == 2)
    assert(setup.faction_crests[0].texture is AtlasTexture)
    assert(setup.faction_crests[1].texture is AtlasTexture)
    assert(setup.map_preview.preview_map == Scenarios.seeded_terrain(
        int(setup.seed_picker.value),Vector2i(24,18)))
    setup.scenario_picker.select(1)
    setup.size_picker.select(0)
    setup._changed(true)
    assert(setup.active_preset == -1)
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

    # The exit flow cannot quit from a single tap on the Home menu.
    home.primary_buttons["Salir"].pressed.emit()
    var exit_prompt: Control = home._exit_confirmation
    assert(exit_prompt.visible)
    assert(exit_prompt.cancel_button.custom_minimum_size.y >= 44)
    assert(exit_prompt.exit_button.custom_minimum_size.y >= 44)
    assert(exit_prompt.warning_label.text.contains("guardado"))
    assert(exit_prompt.cancel_button.text.contains("CANCELAR"))
    exit_prompt.reflow_for_size(Vector2(780,360))
    assert(exit_prompt.compact_landscape)
    assert(exit_prompt.cancel_button.custom_minimum_size.y == 44)
    exit_prompt.reflow_for_size(Vector2(1280,720))
    assert(not exit_prompt.compact_landscape)
    exit_prompt.cancel_button.pressed.emit()
    assert(not exit_prompt.visible)
    assert(home.visible)
    assert(screen.board.state == baseline)

    # Credits V9 is a real, read-only screen with all eight official crests.
    home.primary_buttons["Créditos"].pressed.emit()
    var credits: Control = screen.home_credits_menu
    assert(credits.visible and not home.visible)
    assert(credits.category_buttons.size() == 4)
    assert(credits.crest_buttons.size() == 8)
    assert(credits.hero_mark.texture is AtlasTexture)
    credits._choose_faction(7)
    assert(credits.selected_tab == 1 and credits.selected_faction == 7)
    assert(credits.portrait_title.text == "ORDEN ÓNIX")
    credits._change_tab(3)
    assert(credits.fact_values[0].text == "POR CONFIRMAR")
    credits.reflow_for_size(Vector2(915,412))
    assert(credits.compact_landscape)
    assert(credits.category_buttons[0].custom_minimum_size.y >= 44)
    credits.reflow_for_size(Vector2(780,360))
    assert(credits.done_button.custom_minimum_size.y >= 44)
    credits.reflow_for_size(Vector2(1280,720))
    assert(not credits.compact_landscape)
    credits.close_requested.emit()
    assert(home.visible and not credits.visible)
    assert(screen.board.state == baseline)

    # Settings/Arsenal opened from the title screen must return to Inicio,
    # not silently expose the battle behind the menu.
    home.primary_buttons["Ajustes"].pressed.emit()
    var preferences: Control = screen.home_settings_menu
    assert(preferences.visible and not home.visible)
    assert(not screen.command_menu.visible)
    assert(preferences.setting_buttons.size() == 3)
    assert(preferences.category_buttons.size() == 4)
    assert(preferences.setting_buttons["isometric"].visible)
    assert(preferences.setting_buttons["minimap_enabled"].visible)
    assert(not preferences.setting_buttons["battery_saver"].visible)
    preferences._change_category(1)
    assert(preferences.setting_buttons["battery_saver"].visible)
    preferences._change_category(2)
    assert(not preferences.setting_buttons["battery_saver"].visible)
    preferences._change_category(0)
    preferences.reflow_for_size(Vector2(915,412))
    assert(preferences.compact_landscape)
    assert(not preferences.content_rail.vertical)
    assert(preferences.category_buttons[0].custom_minimum_size.y >= 44)
    assert(screen.board.state == baseline)
    preferences.reflow_for_size(Vector2(1280,720))
    assert(not preferences.compact_landscape)
    preferences.close_requested.emit()
    assert(home.visible and not preferences.visible)
    assert(not screen.command_menu.visible)
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

    # Story navigation shows approved chapters without replacing battle state.
    home.primary_buttons["Modo historia"].pressed.emit()
    assert(screen.story_chapter_menu.visible and not home.visible)
    assert(screen.story_chapter_menu._play.disabled == false)
    # A real pre-battle briefing is now required before a C01 scene change.
    screen.story_chapter_menu._launch_selected()
    var briefing: Control = screen.story_chapter_menu._mission_briefing
    assert(briefing != null and briefing.visible)
    assert(briefing._map._start["id"] == "C01")
    assert(briefing._voice.text.contains("ALIANZA NORTE"))
    assert(briefing._voice.text.contains("PACTO ESCARLATA"))
    assert(briefing._launch.custom_minimum_size.y >= 48)
    assert(not briefing.open_for(2))
    assert(screen.board.state == baseline)
    briefing._toggle_radio()
    assert(briefing._voice_panel.visible)
    briefing.back_requested.emit()
    assert(not briefing.visible and screen.story_chapter_menu.visible)
    screen.story_chapter_menu._select_chapter(24)
    assert(screen.story_chapter_menu._play.disabled)
    screen.story_chapter_menu._select_chapter(1)
    assert(not screen.story_chapter_menu._play.disabled)
    screen.story_chapter_menu.back_requested.emit()
    assert(home.visible and not screen.story_chapter_menu.visible)
    assert(screen.board.state == baseline)

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
