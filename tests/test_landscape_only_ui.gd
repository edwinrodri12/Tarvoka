extends SceneTree

const Identity = preload("res://scripts/ui/FactionIdentity.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(int(ProjectSettings.get_setting("display/window/handheld/orientation",-1)) == 0)
    assert(int(ProjectSettings.get_setting("display/window/size/viewport_width",0)) == 1280)
    assert(int(ProjectSettings.get_setting("display/window/size/viewport_height",0)) == 720)
    assert(str(ProjectSettings.get_setting("display/window/stretch/mode","")) == "canvas_items")
    assert(str(ProjectSettings.get_setting("display/window/stretch/aspect","")) == "expand")

    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    await process_frame
    var snapshot: Dictionary = screen.board.state.duplicate(true)

    for resolution in [Vector2i(1280,720),Vector2i(960,540)]:
        root.size = resolution
        await process_frame
        screen.home_menu._reflow()
        screen.skirmish_setup._reflow()
        screen.saved_matches_menu._reflow()
        screen.faction_selector.reflow_for_size(Vector2(resolution))
        screen.layout_for_size(Vector2(resolution))

        assert(resolution.x > resolution.y)
        assert(not screen.main_layout.vertical)
        assert(not screen.home_menu.content_rail.vertical)
        assert(screen.home_menu.faction_showcase.visible)
        assert(not screen.skirmish_setup.preflight_columns.vertical)
        assert(screen.skirmish_setup.preflight_columns.get_child_count() == 2)
        assert(screen.skirmish_setup.map_scroll != screen.skirmish_setup.rules_scroll)
        assert(screen.skirmish_setup.map_scroll.get_parent() == screen.skirmish_setup.preflight_columns)
        assert(screen.skirmish_setup.rules_scroll.get_parent() == screen.skirmish_setup.preflight_columns)
        assert(not screen.saved_matches_menu.slot_cards.vertical)
        assert(screen.saved_matches_menu.slot_cards.get_child_count() == 2)
        assert(not screen.faction_selector.is_portrait_layout)
        assert(not screen.faction_selector.content_rail.vertical)
        assert(screen.faction_selector.chooser_card.get_index() == 0)
        assert(not screen.faction_selector.header_row.vertical)
        assert(not screen.faction_selector.sides_row.vertical)
        assert(screen.skirmish_setup.faction_portraits.size() == 2)
        assert(screen.skirmish_setup.start_button.custom_minimum_size.y >= 48)
        assert(screen.faction_selector.confirm_button.custom_minimum_size.y >= 48)

    # Do not load or overwrite a real match when browsing configurations.
    screen._prepare_skirmish()
    screen._open_faction_selection()
    screen.faction_selector._choose_faction(4)
    assert(screen.board.state == snapshot)
    screen._cancel_faction_selection()
    assert(screen.skirmish_setup.visible)
    screen._back_from_skirmish()
    screen._open_saved_matches_from_home()
    assert(screen.saved_matches_menu.slot_buttons.size() == 2)
    assert(screen.board.state == snapshot)
    screen._back_from_saved_matches()
    assert(screen.home_menu.visible)

    screen.queue_free()
    print("PASS landscape-only UI: Godot Android orientation, 16:9 and compact horizontal screens, two-column menus, save-safe navigation")
    quit(0)
