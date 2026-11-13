extends SceneTree

const Style = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    await process_frame
    var board: Control = screen.board
    var original: Dictionary = board.state.duplicate(true)
    var desktop = screen.commander_sidebar_strip
    var mobile = screen.commander_compact_strip
    assert(desktop != null and mobile != null)
    assert(desktop.names.size() == 2 and mobile.names.size() == 2)
    assert(desktop.portraits.size() == 2 and mobile.portraits.size() == 2)
    assert(not desktop.compact and mobile.compact)
    assert(mobile.mouse_filter == Control.MOUSE_FILTER_IGNORE)
    assert(mobile.portraits[0].custom_minimum_size.x <= 32)
    assert(desktop.portraits[0].custom_minimum_size.x >= 45)
    assert(desktop.names[0].text == "Alianza Norte")
    assert(mobile.names[1].text == "Pacto Escarlata")
    assert(desktop.portraits[0].texture != null)
    assert(mobile.portraits[1].texture != null)
    assert(board.state == original)

    # Both presentation surfaces must share exactly the same game state,
    # never silently choose names from an unrelated selected unit.
    var picks: Dictionary = {"0":"sindicato_violeta","1":"orden_onix"}
    board.state[Identity.STATE_FIELD] = picks.duplicate(true)
    screen._process(0.0)
    for strip in [desktop,mobile]:
        assert(strip.names[0].text == "Sindicato Violeta")
        assert(strip.names[1].text == "Orden Ónix")
        assert(strip.portraits[0].texture != null)
        assert(strip.portraits[1].texture != null)
        assert(strip.portraits[0].texture is AtlasTexture)
        assert((strip.portraits[0].texture as AtlasTexture).region == Rect2(0,160,160,113))
        assert((strip.portraits[1].texture as AtlasTexture).region == Rect2(480,160,160,113))
        assert(strip.bars[0].color == Style.faction_color(4))
    assert(board.state.get(Identity.STATE_FIELD,{}) == picks)
    screen.command_menu.open_for(board,"Ejercito")
    assert(screen.command_menu.info_label.text.contains("Sindicato Violeta"))
    var test_group := VBoxContainer.new()
    screen.command_menu._unit_action(test_group,"line","Prueba",func(): pass,true,0)
    var test_icon = test_group.get_child(0).get_child(0)
    assert(test_icon.faction_tint == Style.faction_color(4))
    test_group.free()
    screen.command_menu.hide()

    # Hotseat and AI turns use distinct labels without leaking fogged
    # enemy unit data, and the identities survive turn switches.
    board.ai_enabled = false
    board.state["faction"] = 1
    screen._process(0.0)
    assert(mobile.turns[1].text == "EN TURNO")
    assert(desktop.turns[1].text == "EN TURNO")
    board.ai_enabled = true
    screen._process(0.0)
    assert(mobile.turns[1].text == "TURNO IA")
    board.state["winner"] = 0
    screen._process(0.0)
    assert(mobile.turns[0].text == "VICTORIA")
    assert(mobile.turns[1].text == "DERROTA")
    assert(screen.results_panel.visible)
    assert(screen.results_panel.title_label.text.contains("SINDICATO VIOLETA"))
    assert(screen.results_panel.commander_matchup.names[1].text == "Orden Ónix")
    assert(screen.results_panel.commander_matchup.portraits[0].texture != null)
    assert(screen.results_panel._side_labels == ["BANDO 1","BANDO 2"])

    # Legacy saved games must keep their old AZUL / ROJO labels and still
    # display the default, real commander imagery.
    var legacy_result: Dictionary = board.state.duplicate(true)
    legacy_result.erase(Identity.STATE_FIELD)
    screen.results_panel.open_for(legacy_result,0)
    assert(screen.results_panel.title_label.text.contains("AZUL"))
    assert(screen.results_panel._side_labels == ["AZUL","ROJO"])
    assert(screen.results_panel.commander_matchup.portraits[1].texture != null)
    board.state["winner"] = -1
    board.state["faction"] = 0
    board.ai_enabled = false
    screen._process(0.0)

    screen._set_compact_hud(true)
    assert(screen.battle_hud_compact)
    assert(not screen.sidebar.visible and screen.battle_hud_commands.visible)
    assert(mobile.is_ancestor_of(screen.compact_status) == false)
    assert(screen.battle_hud_commands.is_ancestor_of(mobile))
    screen._set_compact_hud(false)
    assert(screen.sidebar.visible and not screen.battle_hud_commands.visible)
    assert(screen.sidebar.is_ancestor_of(desktop))

    # The archived eight commander portraits also appear in the existing
    # reference gallery, not only on the skirmish picker.
    var gallery: AcceptDialog = screen.faction_gallery
    assert(gallery.cards.get_child_count() == 8)
    for i in range(8):
        var row: HBoxContainer = gallery.cards.get_child(i)
        var portrait: TextureRect = row.get_node_or_null("Portrait%d" % i)
        assert(portrait != null and portrait.texture != null)
        assert(portrait.texture.get_width() == 160)

    # Reproducible layout checks, including phones wider than 880 logical
    # pixels where pure-width breakpoints would incorrectly use desktop mode.
    var chooser = screen.faction_selector
    chooser.open_for(Identity.defaults())
    chooser.reflow_for_size(Vector2(1080,2400))
    assert(chooser.is_portrait_layout and chooser.content_rail.vertical)
    assert(chooser.dossier_card.get_index() == 0)
    chooser.reflow_for_size(Vector2(390,844))
    assert(chooser.emblem_display_box.custom_minimum_size.x <= 96)
    assert(chooser.commander_display_box.custom_minimum_size.x <= 96)
    chooser._choose_faction(6)
    assert(chooser.commander_portrait.texture != null)
    assert(chooser.preview_title.text == "Dominio Turquesa")
    chooser.reflow_for_size(Vector2(1280,720))
    assert(not chooser.is_portrait_layout)
    assert(not chooser.content_rail.vertical)
    assert(chooser.chooser_card.get_index() == 0)
    assert(chooser.emblem_display_box.custom_minimum_size.x >= 122)
    assert(chooser.selected["0"] == "dominio_turquesa")

    # The commander dossier and layout controls never place orders or
    # mutate the active battle; all selections are still tentative.
    assert(board.state.get(Identity.STATE_FIELD,{}) == picks)
    assert(board.state["winner"] == -1)
    assert(board.state["faction"] == 0)
    chooser.hide()
    screen.queue_free()
    for suffix in ["",".bak",".tmp"]:
        var path: String = "user://tarvoka_autosave_v1.json"+suffix
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS commander presentation: eight approved portraits, battle HUD states and portrait/landscape Android layout")
    quit(0)
