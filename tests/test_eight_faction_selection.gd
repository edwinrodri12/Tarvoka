extends SceneTree

const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const SitePainter = preload("res://scripts/ui/SiteOverlayPainter.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Style.FACTIONS.size() == 8)
    assert(Identity.is_valid(Identity.defaults()))
    assert(not Identity.is_valid({"0":"alianza_norte","1":"alianza_norte"}))
    assert(not Identity.is_valid({"0":"inventada","1":"orden_onix"}))
    assert(not Identity.is_valid({"0":"alianza_norte","1":"pacto_escarlata","2":"union_verde"}))
    assert(Identity.name_for({},0) == "Alianza Norte")
    assert(Identity.name_for({},1) == "Pacto Escarlata")

    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    await process_frame
    var board: Control = screen.board
    var starting: Dictionary = board.state.duplicate(true)
    var chooser: Control = screen.faction_selector
    assert(chooser != null and chooser.faction_buttons.size() == 8)
    assert(not chooser.visible)
    var setup: Control = screen.skirmish_setup
    screen._prepare_skirmish()
    assert(setup.visible)
    assert(setup.faction_button.text.contains("FACCIONES"))
    setup.faction_button.pressed.emit()
    assert(chooser.visible and not setup.visible)
    assert(chooser.selected == Identity.defaults())
    # Four original crests and portraits are now in the app's atlas.
    assert(chooser.portrait.texture != null)
    assert(chooser.commander_portrait.texture != null)
    assert(not chooser.commander_notice.visible)
    assert(Style.commander_path(7) == "res://assets/commanders/orden_onix.png")
    chooser._choose_faction(3)
    assert(chooser.selected["0"] == "confederacion_solar")
    chooser._choose_side(1)
    chooser._choose_faction(7)
    assert(chooser.selected["1"] == "orden_onix")
    assert(chooser.preview_title.text == "Orden Ónix")
    assert(chooser.preview_motif.text.contains("Insignia"))
    assert(chooser.portrait.texture == null and chooser.commander_portrait.texture == null)
    assert(chooser.preview_commander.text.contains("pendiente"))
    assert(board.state == starting) # Merely choosing is never a battle order.
    chooser.back_requested.emit()
    assert(setup.visible and not chooser.visible)
    assert(setup.selected_factions == Identity.defaults()) # Cancel loses tentative changes.

    setup.faction_button.pressed.emit()
    chooser._choose_faction(3)
    chooser._choose_side(1)
    chooser._choose_faction(7)
    chooser.confirm_button.pressed.emit()
    assert(not chooser.visible and setup.visible)
    var picks: Dictionary = setup.options()
    assert(picks["factions"] == {"0":"confederacion_solar","1":"orden_onix"})
    assert(setup.summary.text.contains("Confederación Solar"))
    assert(setup.summary.text.contains("Orden Ónix"))
    assert(board.state == starting)
    assert(Identity.color_for({},0) == Style.faction_color(0))
    assert(Identity.color_for({},1) == Style.faction_color(1))

    setup.apply_preset(0)
    screen._start_skirmish_setup(setup.options())
    assert(board.state == starting) # Start only opens existing confirmation.
    assert(screen.new_game_dialog.dialog_text.contains("Confederación Solar"))
    screen._confirm_new_game()
    assert(not setup.visible)
    assert(Identity.is_valid(board.state.get("visual_factions",{})))
    assert(Identity.name_for(board.state,0) == "Confederación Solar")
    assert(Identity.name_for(board.state,1) == "Orden Ónix")
    assert(Identity.color_for(board.state,0) == Style.faction_color(3))
    assert(Identity.color_for(board.state,1) == Style.faction_color(7))
    screen._process(0.0)
    assert(screen.expanded_summary.text.contains("CONFEDERACIÓN SOLAR"))
    var actual: Dictionary = board.state.duplicate(true)

    var raw: String = Codec.encode(actual)
    assert(not raw.is_empty())
    var decoded: Dictionary = Codec.decode(raw)
    assert(decoded == actual)
    var denied: Dictionary = actual.duplicate(true)
    denied["visual_factions"]["1"] = denied["visual_factions"]["0"]
    assert(Codec.encode(denied).is_empty()) # Invalid names never enter saves.
    assert(Codec.decode(JSON.stringify({"version":1,"faction":0})).is_empty())

    var next: Dictionary = Session.end_turn(actual)
    assert(bool(next.get("valid",false)))
    assert(next["state"]["visual_factions"] == actual["visual_factions"])
    assert(Identity.color_for(next["state"],0) == Style.faction_color(3))
    # Unit and base flags use the same selectable visual faction colors.
    assert(SitePainter.owner_tint(0,actual) == Style.faction_color(3))
    assert(SitePainter.owner_tint(1,actual) == Style.faction_color(7))
    assert(SitePainter.owner_tint(-1,actual) != Style.faction_color(3))

    assert(board.save_game())
    board.new_game()
    assert(not board.state.has("visual_factions")) # Legacy defaults unchanged.
    assert(screen._load_game())
    assert(board.state == actual)
    assert(Identity.name_for(board.state,1) == "Orden Ónix")
    screen._show_home_menu()
    screen._prepare_skirmish()
    assert(setup.selected_factions == actual["visual_factions"]) # Restore in picker.

    # Direct legacy battles and their v1 saves still do not acquire cosmetic IDs.
    var legacy = board.state.duplicate(true)
    legacy.erase("visual_factions")
    assert(Codec.decode(Codec.encode(legacy)) == legacy)

    screen.queue_free()
    for path in [SaveStore.DEFAULT_PATH,"user://tarvoka_autosave_v1.json"]:
        for suffix in ["",".bak",".tmp"]:
            if FileAccess.file_exists(path+suffix):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
    print("PASS eight faction skirmish selection: official names, touch navigation, colors, state isolation, v1 saves and return")
    quit(0)
