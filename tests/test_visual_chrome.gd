extends SceneTree

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Session = preload("res://scripts/core/BattleSession.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var skin: Theme = Chrome.create_theme()
    assert(skin != null)
    assert(skin.default_font_size >= 16)
    var normal: StyleBoxFlat = skin.get_stylebox("normal","Button") as StyleBoxFlat
    var hovered: StyleBoxFlat = skin.get_stylebox("hover","Button") as StyleBoxFlat
    assert(normal != null and hovered != null)
    assert(normal.bg_color != hovered.bg_color)
    assert(normal.corner_radius_top_left > 0)
    assert(normal.content_margin_left >= 7)
    assert(skin.get_stylebox("panel","TabContainer") != null)
    assert(skin.get_stylebox("panel","PanelContainer") != null)
    var btn := Button.new()
    Chrome.emphasize(btn,"danger")
    assert(btn.has_theme_stylebox_override("normal"))
    assert(btn.get_theme_stylebox("normal","Button") is StyleBoxFlat)
    btn.free()

    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    await process_frame
    var board: Control = screen.board
    var state_before: Dictionary = board.state.duplicate(true)
    assert(screen.theme != null)
    var sidebar: PanelContainer = screen.sidebar
    assert(sidebar != null)
    assert(screen.polished_status_card != null)
    assert(screen.polished_unit_card != null)
    assert(screen.polished_actions_card != null)
    assert(screen.minimap_shell != null)
    assert(screen.status_label.is_ancestor_of(screen.polished_status_card) == false)
    assert(screen.polished_status_card.is_ancestor_of(screen.status_label))
    assert(screen.polished_status_card.is_ancestor_of(screen.economy_status))
    assert(screen.polished_unit_card.is_ancestor_of(screen.sidebar_dossier))
    assert(screen.polished_actions_card.is_ancestor_of(screen.confirm_button))
    assert(screen.polished_actions_card.is_ancestor_of(screen.end_button))
    assert(screen.command_menu_button.has_theme_stylebox_override("normal"))
    assert(screen.confirm_button.has_theme_stylebox_override("normal"))
    assert(screen.compact_confirm.has_theme_stylebox_override("normal"))
    assert(screen.compact_end_turn.has_theme_stylebox_override("normal"))
    assert(screen.battle_minimap.visible == screen.minimap_shell.visible)

    var contents: VBoxContainer = screen.polished_status_card.get_parent() as VBoxContainer
    assert(contents != null)
    assert(contents.get_child(0) is Label)
    assert(screen.polished_status_card.get_index() < screen.campaign_button.get_index())
    assert(screen.command_menu_button.get_index() < screen.faction_gallery_button.get_index())
    assert(screen.objectives_button.get_index() < screen.unit_art_gallery_button.get_index())

    # Full command menu inherits the same active skin and retains usable tabs.
    screen.command_menu.open_for(board,"Batalla")
    assert(screen.command_menu.tabs.get_tab_count() == 4)
    assert(screen.command_menu.get_theme_stylebox("panel","PanelContainer") != null)
    screen.command_menu.hide()
    var main_menu: Control = screen.home_menu
    assert(main_menu.primary_buttons.has("Continuar"))
    assert(main_menu.primary_buttons.has("Modo historia"))
    assert(main_menu.primary_buttons.has("Escaramuza"))
    assert(main_menu.primary_buttons.has("Multijugador"))
    assert(main_menu.primary_buttons["Multijugador"].disabled)
    assert(main_menu.primary_buttons["Continuar"].has_theme_stylebox_override("normal"))
    assert(main_menu.home_scroll.custom_minimum_size.x >= 300)
    screen._show_home_menu()
    assert(main_menu.visible)
    main_menu.primary_buttons["Continuar"].pressed.emit()
    assert(not main_menu.visible)
    screen._open_command_menu()
    assert(screen.command_menu.visible)
    assert(board.state == state_before)

    # The hero chrome must not change movement, orders, fog or battle rules.
    assert(Session._active(board.state))
    screen.queue_free()
    for suffix in ["",".bak"]:
        var path: String = "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS visual chrome: themed navigation, tactical priority, battle card grouping, menu actions and state safety")
    quit(0)
