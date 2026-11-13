extends SceneTree

# Visual QA driver. It runs the REAL Godot scene under Xvfb/OpenGL (never
# --headless) and exports image captures that can be reviewed without APKs.
# No screenshots are committed into git and no developer save is overwritten.
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

var _out_dir := ""
var _manifest: Array[Dictionary] = []
var _failed := false

func _initialize() -> void:
    call_deferred("_run_gallery")

func _run_gallery() -> void:
    _out_dir = OS.get_environment("TARVOKA_UI_CAPTURE_DIR")
    if _out_dir.is_empty():
        push_error("Set TARVOKA_UI_CAPTURE_DIR to an output directory first.")
        quit(1)
        return
    if DisplayServer.get_name() == "headless":
        push_error("Visual QA requires a real renderer. Use Xvfb, not --headless.")
        quit(1)
        return
    var dir_error: Error = DirAccess.make_dir_recursive_absolute(_out_dir)
    if dir_error != OK:
        push_error("Cannot create UI artifact directory: %s (%d)" % [_out_dir,dir_error])
        quit(1)
        return

    var scene: PackedScene = load("res://scenes/Main.tscn")
    if scene == null:
        push_error("Main.tscn was not found.")
        quit(1)
        return
    var main: Control = scene.instantiate()
    root.add_child(main)
    await process_frame
    # CI uses fresh user:// state. Never create a new game or write a save.
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    var initial_state: Dictionary = main.board.state.duplicate(true)

    main._show_home_menu()
    if not await _capture("01-home-portrait",Vector2i(412,915),"Inicio · teléfono vertical"):
        _failed = true
    # Keep Continue, Story, Skirmish and Saved Matches accessible before
    # the first screenful on a normal Android phone (no mandatory scrolling).
    for key in ["Continuar","Modo historia","Escaramuza","Partidas guardadas"]:
        if not _inside_viewport(main.home_menu.primary_buttons[key],Vector2i(412,915)):
            _failed = true
    if not await _capture("02-home-landscape",Vector2i(1280,720),"Inicio · horizontal"):
        _failed = true

    main._prepare_skirmish()
    if not await _capture("03-skirmish-portrait",Vector2i(412,915),"Escaramuza · preparación"):
        _failed = true
    for required in [main.skirmish_setup.heading,
            main.skirmish_setup.footer_faction_button,
            main.skirmish_setup.start_button]:
        if not _inside_viewport(required,Vector2i(412,915)):
            _failed = true
    if main.skirmish_setup.map_preview.custom_minimum_size.y > 152.0:
        push_error("Terrain reconnaissance card is too tall for Android portrait.")
        _failed = true
    for portrait in main.skirmish_setup.faction_portraits:
        if portrait.texture == null:
            push_error("Skirmish preparation still lacks approved commander art.")
            _failed = true
    main._open_faction_selection()
    main.faction_selector._choose_side(0)
    main.faction_selector._choose_faction(6)
    main.faction_selector._choose_side(1)
    main.faction_selector._choose_faction(7)
    main.faction_selector._choose_side(0)
    if not await _capture("04-factions-portrait",Vector2i(412,915),"Ocho facciones · teléfono vertical"):
        _failed = true
    # Catch the clipping that visual QA revealed in the original selector.
    for control in [main.faction_selector.header_row.get_child(1),
            main.faction_selector.side_buttons[0],
            main.faction_selector.side_buttons[1],
            main.faction_selector.commander_portrait,
            main.faction_selector.confirm_button]:
        if not _inside_viewport(control,Vector2i(412,915)):
            _failed = true
    if not await _capture("05-factions-landscape",Vector2i(1280,720),"Ocho facciones · horizontal"):
        _failed = true
    # Cancel the tentative faction changes. This screenshot tool does not
    # start a match or change the player's active formation.
    main._cancel_faction_selection()
    main._back_from_skirmish()
    assert(main.board.state == initial_state)

    # To preview the actual in-battle identity renderer, use an isolated
    # memory-only cosmetic choice. No campaign progress or orders are changed.
    main.home_menu.hide()
    main.board.state[Identity.STATE_FIELD] = {
        "0":"union_verde", "1":"orden_onix"
    }
    main._process(0.0)
    main._set_compact_hud(true)
    if not await _capture("06-battle-portrait",Vector2i(412,915),"Batalla · HUD compacto Android"):
        _failed = true
    # Check every essential action stays entirely within the touch screen.
    for action in [main.compact_cancel,main.compact_confirm,
            main.compact_end_turn,main.compact_menu_button,
            main.compact_objectives_button,main.compact_options_button]:
        if not _inside_viewport(action,Vector2i(412,915)):
            _failed = true
    var tile: float = main.board._cell_size()
    var start: Vector2 = main.board._board_origin()
    var extent: Vector2 = Vector2(main.board.map_dimensions())*tile
    if start.x < -2.0 or start.x+extent.x > main.board.size.x+2.0:
        push_error("Small battlefield is clipped after Android rotation.")
        _failed = true
    main._set_compact_hud(false)
    if not await _capture("07-battle-landscape",Vector2i(1280,720),"Batalla · HUD ampliado"):
        _failed = true
    main._open_command_menu()
    if not await _capture("08-command-portrait",Vector2i(412,915),"Centro de mando · teléfono vertical"):
        _failed = true
    main.command_menu.hide()
    # For a read-only terminal preview, set the result in the isolated
    # temporary state. This does NOT claim a real in-game battle took place.
    main.board.state["winner"] = 0
    main._process(0.0)
    if not await _capture("09-results-portrait",Vector2i(412,915),"Resultados · teléfono vertical"):
        _failed = true
    if main.results_panel.get_global_rect().size.y > 635.0:
        push_error("Result sheet wastes excessive height in portrait.")
        _failed = true
    var result_scroller: ScrollContainer = main.results_panel.stats_column.get_parent()
    var last_metric: Control = main.results_panel.stats_column.get_child(2)
    if not result_scroller.get_global_rect().encloses(last_metric.get_global_rect()):
        push_error("Essential results metric still clipped inside its scroll region.")
        _failed = true
    if not await _capture("10-results-landscape",Vector2i(1280,720),"Resultados · horizontal"):
        _failed = true

    var manifest_path: String = _out_dir.path_join("manifest.json")
    var manifest_file := FileAccess.open(manifest_path,FileAccess.WRITE)
    if manifest_file == null:
        push_error("Unable to write visual QA manifest.")
        _failed = true
    else:
        manifest_file.store_string(JSON.stringify({
            "generator":"Godot 4 · TARVOKA visual gallery",
            "review_only":true,
            "no_real_player_save_modified":true,
            "screens":_manifest
        },"  "))
        manifest_file.close()
    main.queue_free()
    if _failed or _manifest.size() != 10:
        push_error("Visual QA incomplete: %d/10 captures" % _manifest.size())
        quit(1)
        return
    print("PASS visual gallery: 10 rendered PNG screens with nonblank frame checks and manifest")
    quit(0)

func _inside_viewport(control: Control, resolution: Vector2i) -> bool:
    if control == null or not control.is_visible_in_tree():
        push_error("Important Android control is hidden or missing.")
        return false
    var rect: Rect2 = control.get_global_rect()
    var safe: Rect2 = Rect2(Vector2.ZERO,Vector2(resolution))
    if rect.size.x < 24.0 or rect.size.y < 24.0:
        push_error("Touch control is too small: "+str(control.name))
        return false
    if not safe.encloses(rect):
        push_error("Android control clipped: %s (%s)" % [str(control.name),str(rect)])
        return false
    return true

func _capture(stem: String, resolution: Vector2i, caption: String) -> bool:
    root.size = resolution
    await process_frame
    await process_frame
    await process_frame
    RenderingServer.force_draw(false)
    await process_frame
    var viewport_texture: ViewportTexture = root.get_texture()
    if viewport_texture == null:
        push_error("No viewport texture for "+stem)
        return false
    var image: Image = viewport_texture.get_image()
    if image == null or image.is_empty():
        push_error("Empty render for "+stem)
        return false
    if image.get_width() != resolution.x or image.get_height() != resolution.y:
        push_error("%s captured at %dx%d, expected %dx%d" % [
            stem,image.get_width(),image.get_height(),resolution.x,resolution.y])
        return false
    # Detect black/solid screenshots (common when accidentally using a
    # headless renderer). Inspect the actual captured pixels, not UI state.
    var tones := {}
    for row in range(11):
        for column in range(13):
            var x: int = clampi(int((float(column)+0.5)*image.get_width()/13.0),0,image.get_width()-1)
            var y: int = clampi(int((float(row)+0.5)*image.get_height()/11.0),0,image.get_height()-1)
            var c: Color = image.get_pixel(x,y)
            tones[c.to_html(false)] = true
    if tones.size() < 6:
        push_error("Rendered screenshot looks blank: "+stem)
        return false
    var filename: String = stem+".png"
    var target: String = _out_dir.path_join(filename)
    var result: Error = image.save_png(target)
    if result != OK:
        push_error("Could not save "+target)
        return false
    _manifest.append({
        "file":filename,"title":caption,
        "width":image.get_width(),"height":image.get_height(),
        "distinct_sampled_colors":tones.size()
    })
    print("CAPTURE %s %dx%d colors=%d" % [
        stem,resolution.x,resolution.y,tones.size()])
    return true
