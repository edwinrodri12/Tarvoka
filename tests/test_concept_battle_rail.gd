extends SceneTree

const Chrome = preload("res://scripts/ui/GameUiTheme.gd")
const Dossier = preload("res://scripts/ui/UnitDossierView.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var look: Theme = Chrome.create_theme()
    var button: StyleBoxFlat = look.get_stylebox("normal","Button") as StyleBoxFlat
    var selected_tab: StyleBoxFlat = look.get_stylebox("tab_selected","TabContainer") as StyleBoxFlat
    assert(button != null and button.border_color == Chrome.EDGE)
    assert(button.shadow_size > 0)
    assert(selected_tab != null and selected_tab.border_color == Chrome.GOLD)
    assert(Chrome.EDGE_BRIGHT.b > Chrome.EDGE_BRIGHT.r)
    var accent := Button.new()
    Chrome.emphasize(accent,"primary")
    assert((accent.get_theme_stylebox("normal") as StyleBoxFlat).border_color == Chrome.GOLD)
    accent.free()

    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    main.board.autosave_enabled = false
    var before: Dictionary = main.board.state.duplicate(true)
    assert(main.theme != null)
    assert(main.polished_status_card != null)
    assert(main.polished_unit_card != null)
    assert(main.polished_actions_card != null)
    assert(main.expanded_header != null)
    assert(main.expanded_actions != null)
    assert(main.expanded_summary != null)
    assert(main.expanded_header.visible)
    assert(main.expanded_actions.visible)
    assert(not main.battle_hud_commands.visible)
    assert(main.expanded_summary.text.contains("TARVOKA"))
    assert(main.expanded_summary.text.contains("CR") == main.board.state.has("economy"))
    assert(main.expanded_confirm.disabled)
    assert(not main.expanded_end_turn.disabled)
    assert(main.board.state == before)
    main.layout_for_size(Vector2(1400,800))
    assert(not main.main_layout.vertical)
    main.layout_for_size(Vector2(520,940))
    assert(main.main_layout.vertical)
    assert(main.board.state == before)
    main._set_compact_hud(true)
    assert(main.battle_hud_commands.visible)
    assert(not main.expanded_actions.visible and not main.expanded_header.visible)
    main._set_compact_hud(false)
    assert(main.expanded_actions.visible and main.expanded_header.visible)
    assert(main.board.state == before)

    main.command_menu.open_for(main.board,"Batalla")
    assert(main.command_menu.tabs.get_tab_count() == 4)
    main.command_menu.hide()
    assert(main.home_menu.primary_buttons["Multijugador"].disabled)
    assert(main.polished_status_card.is_ancestor_of(main.status_label))
    assert(main.polished_actions_card.is_ancestor_of(main.confirm_button))

    var d: Control = Dossier.new()
    root.add_child(d)
    await process_frame
    d.bind_dossier({"kind":"friendly","name":"Tanque principal",
        "role":"tank","hp":3,"max_hp":10,"stats":[],"status":"Activo"})
    assert(d._health.visible)
    var low: StyleBoxFlat = d._health.get_theme_stylebox("fill") as StyleBoxFlat
    assert(low != null and low.bg_color == Color("#F4C33C"))
    d.bind_dossier({"kind":"friendly","name":"Tanque principal",
        "role":"tank","hp":1,"max_hp":10,"stats":[],"status":"Dañado"})
    var critical: StyleBoxFlat = d._health.get_theme_stylebox("fill") as StyleBoxFlat
    assert(critical.bg_color == Color("#ED5963"))
    d.bind_dossier({"kind":"friendly","name":"Tanque principal",
        "role":"tank","hp":10,"max_hp":10,"stats":[],"status":"Activo"})
    var healthy: StyleBoxFlat = d._health.get_theme_stylebox("fill") as StyleBoxFlat
    assert(healthy.bg_color == Color("#2DD793"))
    d.queue_free()

    main._open_objectives_radar()
    assert(main.objectives_panel.visible)
    var modal: StyleBoxFlat = main.objectives_panel.get_theme_stylebox("panel") as StyleBoxFlat
    assert(modal != null and modal.border_color == Chrome.EDGE_BRIGHT)
    main._close_objectives_radar()
    assert(main.board.state == before)

    main.queue_free()
    await process_frame
    for suffix in ["",".bak"]:
        var path: String = "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS concept rail: merged card chrome, cyan-gold tactical HUD, responsive controls, HP gauges and safe battle state")
    quit(0)
