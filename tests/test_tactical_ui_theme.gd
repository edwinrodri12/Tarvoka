extends SceneTree

const Skin = preload("res://scripts/ui/TacticalUITheme.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var skin: Theme = Skin.make_theme()
    assert(skin != null)
    var gold: StyleBoxFlat = skin.get_stylebox("tab_selected","TabContainer") as StyleBoxFlat
    var blue: StyleBoxFlat = skin.get_stylebox("normal","Button") as StyleBoxFlat
    assert(gold != null and blue != null)
    assert(gold.border_color == Skin.GOLD)
    assert(blue.border_color == Skin.CYAN)
    assert(skin.get_font_size("font_size","Button") >= 16)
    var big_panel: StyleBoxFlat = Skin.frame("hero")
    assert(big_panel.border_color == Skin.CYAN)
    assert(big_panel.shadow_size > 0)

    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    await process_frame
    var board = screen.board
    assert(screen.theme != null)
    assert(screen.sidebar.get_theme_stylebox("panel") is StyleBoxFlat)
    var side_style: StyleBoxFlat = screen.sidebar.get_theme_stylebox("panel") as StyleBoxFlat
    assert(side_style.border_color == Skin.CYAN)
    assert(screen.expanded_header != null and screen.expanded_actions != null)
    assert(screen.expanded_summary != null)
    assert(screen.expanded_actions.visible)
    assert(not screen.battle_hud_commands.visible)
    assert(screen.expanded_confirm.disabled)
    assert(not screen.expanded_end_turn.disabled)
    assert(screen.expanded_confirm.text == "CONFIRMAR")
    assert(screen.expanded_summary.text.contains("TARVOKA"))
    assert(screen.expanded_summary.text.contains("CR") == board.state.has("economy"))
    var before: Dictionary = board.state.duplicate(true)
    screen.layout_for_size(Vector2(1280,720))
    assert(not screen.main_layout.vertical)
    screen.layout_for_size(Vector2(530,940))
    assert(screen.main_layout.vertical)
    assert(board.state == before)
    screen._set_compact_hud(true)
    assert(not screen.expanded_actions.visible and not screen.expanded_header.visible)
    assert(screen.battle_hud_commands.visible)
    screen._set_compact_hud(false)
    assert(screen.expanded_header.visible and screen.expanded_actions.visible)
    assert(board.state == before)

    var menu: Control = screen.command_menu
    menu.open_for(board,"Ajustes")
    assert(menu.visible)
    assert(menu.get_theme_stylebox("panel") is StyleBoxFlat)
    assert(menu.tabs.get_tab_count() == 4)
    var tabs: StyleBoxFlat = menu.tabs.get_theme_stylebox("tab_selected") as StyleBoxFlat
    assert(tabs != null and tabs.border_color == Skin.GOLD)
    menu.hide()
    screen.home_menu.show()
    assert(screen.home_menu.primary_buttons["Continuar"] != null)
    assert(screen.home_menu.primary_buttons["Multijugador"].disabled)
    var home_gold: StyleBoxFlat = screen.home_menu.primary_buttons["Continuar"].get_theme_stylebox("normal") as StyleBoxFlat
    assert(home_gold.border_color == Skin.GOLD)
    screen.home_menu.hide()
    screen._open_objectives_radar()
    assert(screen.objectives_panel.visible)
    assert(screen.objectives_panel.get_theme_stylebox("panel") is StyleBoxFlat)
    assert(board.state == before)
    screen._close_objectives_radar()
    assert(not screen.objectives_panel.visible)
    screen.queue_free()
    await process_frame
    for suffix in ["",".bak"]:
        var path := "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS concept UI: gold and cyan theme, responsive battle rail, live status, menu chrome, no tactical state mutations")
    quit(0)
