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
    if DirAccess.make_dir_recursive_absolute(_out_dir) != OK:
        push_error("Cannot create visual QA output directory.")
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
    main.board.autosave_enabled = false
    main.board.ai_enabled = false
    var original: Dictionary = main.board.state.duplicate(true)

    main._show_home_menu()
    if not await _capture_landscape("01-inicio-1280x720",Vector2i(1280,720),"Inicio · Android horizontal 16:9"):
        _failed = true
    if not await _capture_landscape("02-inicio-960x540",Vector2i(960,540),"Inicio · horizontal compacto"):
        _failed = true
    if main.home_menu.content_rail.vertical:
        push_error("Inicio is incorrectly using a portrait layout on a landscape device.")
        _failed = true

    main._prepare_skirmish()
    if not await _capture_landscape("03-escaramuza-1280x720",Vector2i(1280,720),"Escaramuza · terreno y reglas en columnas"):
        _failed = true
    if not await _capture_landscape("04-escaramuza-960x540",Vector2i(960,540),"Escaramuza · horizontal compacto"):
        _failed = true
    if main.skirmish_setup.preflight_columns.vertical or
            main.skirmish_setup.preflight_columns.get_child_count() != 2:
        push_error("Escaramuza is not split into two landscape columns.")
        _failed = true
    for action in [main.skirmish_setup.footer_faction_button,
            main.skirmish_setup.start_button]:
        if not _inside_viewport(action,Vector2i(960,540)):
            _failed = true

    main._open_faction_selection()
    main.faction_selector._choose_side(0)
    main.faction_selector._choose_faction(6)
    main.faction_selector._choose_side(1)
    main.faction_selector._choose_faction(7)
    main.faction_selector._choose_side(0)
    if not await _capture_landscape("05-facciones-1280x720",Vector2i(1280,720),"Facciones · ocho escudos y comandante"):
        _failed = true
    if not await _capture_landscape("06-facciones-960x540",Vector2i(960,540),"Facciones · horizontal compacto"):
        _failed = true
    if main.faction_selector.is_portrait_layout or main.faction_selector.content_rail.vertical:
        push_error("Faction selection stacked despite a landscape screen.")
        _failed = true
    if not _inside_viewport(main.faction_selector.confirm_button,Vector2i(960,540)):
        _failed = true
    main._cancel_faction_selection()
    main._back_from_skirmish()
    assert(main.board.state == original)

    main.home_menu.hide()
    main.board.state[Identity.STATE_FIELD] = {"0":"union_verde","1":"orden_onix"}
    main._process(0.0)
    main._set_compact_hud(false)
    if not await _capture_landscape("07-batalla-1280x720",Vector2i(1280,720),"Batalla · tablero táctico horizontal"):
        _failed = true
    main._open_command_menu()
    if not await _capture_landscape("08-mando-1280x720",Vector2i(1280,720),"Centro de mando · operaciones"):
        _failed = true
    main.command_menu.open_for(main.board,"Ajustes")
    if not await _capture_landscape("09-ajustes-1280x720",Vector2i(1280,720),"Ajustes · configuraciones tácticas"):
        _failed = true
    main.command_menu.hide()

    # Demonstration victory in memory only. No real user save is touched and
    # no victory is claimed for a match the game did not play.
    main.board.state["winner"] = 0
    main._process(0.0)
    if not await _capture_landscape("10-resultados-1280x720",Vector2i(1280,720),"Resultados · simulación visual"):
        _failed = true
    main._show_home_menu()
    main._open_saved_matches_from_home()
    if not await _capture_landscape("11-guardados-1280x720",Vector2i(1280,720),"Partidas guardadas · dos ranuras reales"):
        _failed = true
    if main.saved_matches_menu.slot_cards.vertical:
        push_error("Save slots are stacked on landscape.")
        _failed = true
    main._back_from_saved_matches()
    main._open_arsenal_from_home()
    if not await _capture_landscape("12-arsenal-1280x720",Vector2i(1280,720),"Arsenal · catálogo de unidades"):
        _failed = true
    main.unit_art_gallery.hide()

    var file: FileAccess = FileAccess.open(_out_dir.path_join("manifest.json"),FileAccess.WRITE)
    if file == null:
        push_error("Could not write landscape manifest.")
        _failed = true
    else:
        file.store_string(JSON.stringify({
            "generator":"Godot 4.3 · TARVOKA landscape-only UI review",
            "review_only":true,
            "orientation":"landscape",
            "no_real_player_save_modified":true,
            "screens":_manifest
        },"  "))
        file.close()
    main.queue_free()
    if _failed or _manifest.size() != 12:
        push_error("Landscape UI QA incomplete: %d/12 captures" % _manifest.size())
        quit(1)
        return
    print("PASS visual gallery: 12 rendered landscape PNG screens with nonblank checks and manifest")
    quit(0)

func _capture_landscape(stem: String, resolution: Vector2i, caption: String) -> bool:
    if resolution.x <= resolution.y:
        push_error("Portrait screenshot prohibited: "+stem)
        return false
    return await _capture(stem,resolution,caption)

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
