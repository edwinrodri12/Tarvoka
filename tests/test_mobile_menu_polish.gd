extends SceneTree

const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var snapshot: Dictionary = main.board.state.duplicate(true)

    # The home screen puts active game modes ahead of long explanatory copy.
    var home: Control = main.home_menu
    main._show_home_menu()
    assert(home.primary_buttons.size() == 7)
    assert(home.primary_buttons["Continuar"].custom_minimum_size.y >= 44)
    assert(home.primary_buttons["Escaramuza"].custom_minimum_size.y >= 44)
    assert(home.primary_buttons["Multijugador"].disabled)
    assert(home._hero_subtitle.text.contains("tierra, mar y aire"))
    assert(not home._menu_caption.text.contains("Partidas guardadas y modos"))

    # A setup card must show the approved commander images, not yesterday's
    # incorrect message that artwork was still awaiting import.
    home.primary_buttons["Escaramuza"].pressed.emit()
    var setup: Control = main.skirmish_setup
    assert(setup.visible and not home.visible)
    assert(setup.heading.text == "ESCARAMUZA")
    assert(setup.faction_portraits.size() == 2)
    assert(setup.faction_names.size() == 2)
    assert(setup.faction_portraits[0].texture != null)
    assert(setup.faction_portraits[1].texture != null)
    assert(setup.faction_names[0].text == "Alianza Norte")
    assert(setup.faction_names[1].text == "Pacto Escarlata")
    assert(not setup.faction_summary.text.contains("pendientes de importar"))
    var picks := {"0":"dominio_turquesa","1":"legion_ambar"}
    setup.set_factions(picks)
    assert(setup.options()["factions"] == picks)
    assert(setup.faction_portraits[0].texture is AtlasTexture)
    assert(setup.faction_portraits[1].texture is AtlasTexture)
    assert(setup.faction_names[0].text == "Dominio Turquesa")
    assert(setup.faction_names[1].text == "Legión Ámbar")
    assert(setup.faction_summary.text.contains("oficiales"))
    assert(main.board.state == snapshot)

    setup.faction_button.pressed.emit()
    var chooser: Control = main.faction_selector
    assert(chooser.visible)
    chooser.reflow_for_size(Vector2(412,915))
    assert(chooser.is_portrait_layout)
    assert(not chooser.selection_status.visible)
    assert(chooser.commander_display_box.custom_minimum_size.x <= 82)
    assert(chooser.commander_portrait.texture is AtlasTexture)
    chooser.reflow_for_size(Vector2(1280,720))
    assert(not chooser.is_portrait_layout)
    assert(chooser.selection_status.visible)
    assert(main.board.state == snapshot)
    main._cancel_faction_selection()
    assert(setup.visible)
    assert(setup.options()["factions"] == picks)

    main.queue_free()
    print("PASS mobile menu polish: compact home, authentic commander cards and adaptive faction dossier")
    quit(0)
