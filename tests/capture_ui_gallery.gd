extends SceneTree

# Visual QA driver. It runs the REAL Godot scene under Xvfb/OpenGL (never
# --headless) and exports image captures that can be reviewed without APKs.
# No screenshots are committed into git and no developer save is overwritten.
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

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
    if main.skirmish_setup.preflight_columns.vertical or main.skirmish_setup.preflight_columns.get_child_count() != 2:
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

    # Mobile selection is a real, non-destructive unit state. The status strip
    # must remain readable at 960x540 in fullscreen HUD.
    var selected_before_gallery: String = main.board.selected_id
    main._set_compact_hud(true)
    main.board.selected_id = "A"
    main._process(0.0)
    if not await _capture_landscape("22-unidad-seleccionada-960x540",Vector2i(960,540),"Batalla · unidad activa y acciones disponibles"):
        _failed = true
    # Real next-unit button, not a drawn mockup: take one step through the
    # active human force, then restore the selection and untouched match.
    var navigation_before_gallery: Dictionary = main.board.state.duplicate(true)
    main.compact_next_unit.emit_signal("pressed")
    main._process(0.0)
    if main.board.selected_id.is_empty() or not main.compact_next_unit.visible:
        push_error("Android next-unit control failed to select an available unit.")
        _failed = true
    if not await _capture_landscape("26-navegacion-unidades-960x540",Vector2i(960,540),
            "Batalla · navegación rápida entre unidades disponibles"):
        _failed = true
    if main.board.state != navigation_before_gallery:
        push_error("Navigation visual QA accidentally mutated battle data.")
        _failed = true
    main.board.selected_id = selected_before_gallery
    main._set_compact_hud(false)
    main._process(0.0)

    # Two real renderer captures of the opt-in enemy-threat and real
    # terrain-cover overlays. All preview input is isolated and restored.
    var before_risk_gallery: Dictionary = main.board.state.duplicate(true)
    var risk_previous_selection: String = main.board.selected_id
    var risk_previous_iso: bool = main.board.iso_enabled
    var risk_previous_enabled: bool = main.board.threat_preview_enabled
    var risk_previous_minimap: bool = main._minimap_preference
    var risk_previous_confirmation: bool = main.board.require_order_confirmation
    var risk_terrain: Array = Scenarios.terrain(0).duplicate(true)
    risk_terrain[3][4] = "forest"
    risk_terrain[2][3] = "mountain"
    var risk_friend: Dictionary = Roles.make_unit("A",0,Vector2i(3,3),"line")
    var risk_enemy: Dictionary = Roles.make_unit("X",1,Vector2i(5,3),"tank")
    risk_enemy["move_points"] = 0
    main.board.state = Session.start([risk_friend,risk_enemy],risk_terrain,
        0,false,false,false,false)
    main.board.selected_id = "A"
    main.board.threat_preview_enabled = true
    main.board.set_isometric(false)
    main._set_compact_hud(true)
    main.board.queue_redraw()
    main._process(0.0)
    var risk_preview: Dictionary = main.board.threat_preview()
    if not bool(risk_preview.get("valid",false)) or int(risk_preview.get("danger",0)) <= 0:
        push_error("Real threat preview did not detect the exposed flank.")
        _failed = true
    if not await _capture_landscape("27-amenazas-cobertura-clasica-960x540",Vector2i(960,540),
            "Batalla clásica · posible amenaza roja y cobertura verde con botón Riesgo"):
        _failed = true
    main.board.set_isometric(true)
    main._minimap_preference = true
    main._apply_minimap_visibility()
    main._set_compact_hud(false)
    main.board.frame_player_force()
    main._process(0.0)
    main.board.queue_redraw()
    main.battle_minimap.queue_redraw()
    if not main.battle_minimap.visible or not main.board.threat_preview()["valid"]:
        push_error("Risk minimap preview is missing in isometric battle.")
        _failed = true
    if not await _capture_landscape("28-amenazas-cobertura-isometrica-1280x720",Vector2i(1280,720),
            "Batalla isométrica · amenazas teóricas y cobertura sobre minimapa"):
        _failed = true

    # Compare a TRUE legal move into forest, where cover increases but a
    # visible enemy can now reach the destination. Do NOT execute the move:
    # the same pending order must survive both landscape screenshots.
    main.board.require_order_confirmation = true
    main.board._request_order(Vector2i(4,3),{})
    if str(main.board.pending_order.get("kind","")) != "move":
        push_error("No legal pending move was created for the risk comparison gallery.")
        _failed = true
    main.board.set_isometric(false)
    main._set_compact_hud(true)
    main.board.queue_redraw()
    main._process(0.0)
    var before_move_gallery: Dictionary = main.board.state.duplicate(true)
    if not main.compact_move_risk_card.visible or int(main._last_move_risk_snapshot.get("threat_delta",0)) != 1:
        push_error("Compact move-risk card did not calculate the real exposed forest.")
        _failed = true
    if not await _capture_landscape("29-riesgo-antes-de-mover-960x540",Vector2i(960,540),
            "Movimiento pendiente · comparación visible de amenazas y cobertura en Android"):
        _failed = true
    main.board.set_isometric(true)
    main._set_compact_hud(false)
    main.board.queue_redraw()
    main._process(0.0)
    if not main.sidebar_move_risk_card.visible:
        push_error("Desktop move-risk card is missing from expanded battle sidebar.")
        _failed = true
    if not await _capture_landscape("30-riesgo-movimiento-pc-1280x720",Vector2i(1280,720),
            "Movimiento pendiente · cobertura y amenazas en panel táctico de PC"):
        _failed = true
    if main.board.state != before_move_gallery or str(main.board.pending_order.get("kind","")) != "move":
        push_error("Two read-only movement comparisons changed the battle or committed the move.")
        _failed = true
    main.board.pending_order.clear()

    # Real interactive 3-choice comparison; pins are numbered on the map.
    # Preserve the same source match from the earlier cover/risk screenshots.
    main.board.set_isometric(false)
    main._set_compact_hud(true)
    main.board.selected_id = "A"
    main._process(0.0)
    main.compact_compare_button.emit_signal("pressed")
    for option in [Vector2i(4,3),Vector2i(3,2),Vector2i(2,3)]:
        main.board.toggle_compared_cell(option)
    main.board.queue_redraw()
    main._process(0.0)
    if not main.board.compare_mode or not main.compact_compare_panel.visible or main.board.comparison_cells().size() != 3:
        push_error("Mobile three-choice comparison is not active.")
        _failed = true
    if not await _capture_landscape("31-comparar-tres-destinos-android-960x540",Vector2i(960,540),
            "Compara tres destinos · coste, cobertura, riesgo y ataque después de mover"):
        _failed = true
    main.board.set_isometric(true)
    main._set_compact_hud(false)
    main.board.queue_redraw()
    main.battle_minimap.queue_redraw()
    main._process(0.0)
    if not main.sidebar_compare_panel.visible or not main.battle_minimap.visible:
        push_error("Three-choice desktop comparison/minimap is missing.")
        _failed = true
    if not await _capture_landscape("32-comparar-destinos-iso-pc-1280x720",Vector2i(1280,720),
            "Vista isométrica · tres alternativas y selección antes de confirmar"):
        _failed = true
    main.sidebar_compare_panel.choose_buttons[0].emit_signal("pressed")
    if main.board.state != before_move_gallery or str(main.board.pending_order.get("kind","")) != "move":
        push_error("Preparing a compared choice committed a move or did not require confirmation.")
        _failed = true
    main.board.cancel_selection()
    main.board.require_order_confirmation = risk_previous_confirmation
    main.board.state = before_risk_gallery
    main.board.selected_id = risk_previous_selection
    main.board.threat_preview_enabled = risk_previous_enabled
    main.board.set_isometric(risk_previous_iso)
    main._minimap_preference = risk_previous_minimap
    main._apply_minimap_visibility()
    main._set_compact_hud(false)
    main._process(0.0)

    # True climate battles, not an overlay mock: the weather flag belongs
    # to the authoritative session and changes legal vehicle movement.
    var old_weather_scene: Dictionary = main.board.state.duplicate(true)
    var weather_original_iso: bool = main.board.iso_enabled
    var weather_original_minimap: bool = main._minimap_preference
    var weather_original_selection: String = main.board.selected_id
    var vehicle: Dictionary = Roles.make_unit("W",0,Vector2i(1,3),"apc")
    vehicle["move_points"] = 5
    var climate_enemy: Dictionary = Roles.make_unit("X",1,Vector2i(6,3),"tank")
    main.board.state = Session.start([vehicle,climate_enemy],risk_terrain,0,
        false,false,false,false,false,"rain")
    main.board.selected_id = "W"
    main.board.threat_preview_enabled = false
    main.board.set_isometric(false)
    main._set_compact_hud(true)
    main.board.queue_redraw()
    main._process(0.0)
    if not main.compact_weather.text.contains("Lluvia") or main.board.legal_action_hints()["moves"].is_empty():
        push_error("Rain battle is not connected to real Android HUD/mobility.")
        _failed = true
    if not await _capture_landscape("33-lluvia-movilidad-960x540",Vector2i(960,540),
            "Clima lluvia · barro y menor movilidad de vehículos sobre ruedas"):
        _failed = true
    main.board.state = Session.start([vehicle,climate_enemy],risk_terrain,0,
        false,false,false,false,false,"snow")
    main.board.set_isometric(true)
    main._minimap_preference = true
    main._apply_minimap_visibility()
    main._set_compact_hud(false)
    main.board.queue_redraw()
    main.battle_minimap.queue_redraw()
    main._process(0.0)
    if not main.weather_status.text.contains("Nieve") or not main.battle_minimap.visible:
        push_error("Snow battle is not shown on desktop/isometric minimap.")
        _failed = true
    if not await _capture_landscape("34-nieve-movilidad-isometrica-1280x720",Vector2i(1280,720),
            "Clima nieve · suelo helado, unidades y mapa isométrico con minimapa"):
        _failed = true
    main.board.state = old_weather_scene
    main.board.selected_id = weather_original_selection
    main.board.set_isometric(weather_original_iso)
    main._minimap_preference = weather_original_minimap
    main._apply_minimap_visibility()
    main._set_compact_hud(false)
    main._process(0.0)

    # Priority list on an actual modern match: friendly units, available
    # producers and visible objectives. No fake alerts or committed actions.
    var before_alert_frame: Dictionary = main.board.state.duplicate(true)
    var original_alert_inspection: Vector2i = main.board.inspected_cell
    main.board.new_game(0,false,false,true,true,true,true)
    main.board.selected_id = ""
    main.board.inspected_cell = Vector2i(-1,-1)
    main._set_compact_hud(true)
    main._process(0.0)
    main._open_tactical_alerts()
    if not main.objectives_panel.visible or main.objectives_panel.tabs.current_tab != 2:
        push_error("Tactical alert shortcuts did not open the existing radar priorities tab.")
        _failed = true
    if not await _capture_landscape("24-prioridades-tacticas-960x540",Vector2i(960,540),
            "Batalla · prioridades, producción y localización sin órdenes"):
        _failed = true
    main._close_objectives_radar()
    main.board.state = before_alert_frame
    main.board.inspected_cell = original_alert_inspection
    main.board.selected_id = selected_before_gallery
    main._set_compact_hud(false)
    main._process(0.0)

    # True map and minimap markers on a 1280x720 isometric battle. Only
    # temporary QA-local data is changed; no real save, order or economy cost.
    var before_marker_frame: Dictionary = main.board.state.duplicate(true)
    var marker_previous_iso: bool = main.board.iso_enabled
    var marker_previous_minimap: bool = main._minimap_preference
    main.board.new_game(0,false,false,false,true,true,true)
    var marked_unit := false
    for unit in main.board.state["units"]:
        if int(unit.get("faction",-1)) == 0 and unit.has("ammo") and unit.has("fuel") and not marked_unit:
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["hp"] = 2
            marked_unit = true
    main.board.set_isometric(true)
    main._minimap_preference = true
    main._apply_minimap_visibility()
    main._set_compact_hud(false)
    main.board.frame_player_force()
    main._process(0.0)
    main.board.queue_redraw()
    main.battle_minimap.queue_redraw()
    if not marked_unit or main.board.alert_marker_snapshots().is_empty() or not main.battle_minimap.visible:
        push_error("Map and minimap tactical alert evidence is missing.")
        _failed = true
    if not await _capture_landscape("25-alertas-mapa-minimapa-1280x720",Vector2i(1280,720),
            "Batalla isométrica · alertas críticas y fábricas visibles en minimapa"):
        _failed = true
    main.board.state = before_marker_frame
    main.board.set_isometric(marker_previous_iso)
    main._minimap_preference = marker_previous_minimap
    main._apply_minimap_visibility()
    main.board.selected_id = selected_before_gallery
    main._set_compact_hud(false)
    main._process(0.0)

    # Read-only verified factory preview in compact mode. Preserve the
    # authoritative match and restore selection after this gallery frame.
    var before_terrain_frame: Dictionary = main.board.state.duplicate(true)
    var inspected_before_frame: Vector2i = main.board.inspected_cell
    var factory_before_frame: Vector2i = main.board.selected_factory_pos
    main.board.new_game(0,false,false,false,true,true,true)
    main.board.inspected_cell = Vector2i(0,3)
    main.board.selected_id = ""
    main.board.selected_factory_pos = Vector2i(-1,-1)
    main._set_compact_hud(true)
    main._process(0.0)
    if not await _capture_landscape("23-edificio-terreno-960x540",Vector2i(960,540),
            "Inspección · cobertura, movilidad y estado de instalación"):
        _failed = true
    if not main.compact_tile_context.visible or not main.compact_site_actions.visible:
        push_error("The terrain/site fact card is missing in compact landscape.")
        _failed = true
    main.board.state = before_terrain_frame
    main.board.inspected_cell = inspected_before_frame
    main.board.selected_factory_pos = factory_before_frame
    main.board.selected_id = selected_before_gallery
    main._set_compact_hud(false)
    main._process(0.0)

    # Visual QA of the REAL attack controller, not a painted mockup.
    # The scenario stays in memory and its authoritative state is restored.
    var battle_before_effect: Dictionary = main.board.state.duplicate(true)
    var original_isometric: bool = main.board.iso_enabled
    var original_confirmation: bool = main.board.require_order_confirmation
    main.board.set_isometric(true)
    var demo_own: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),"tank")
    var demo_enemy: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"tank")
    main.board.state = Session.start([demo_own,demo_enemy],
        Scenarios.terrain(0),0,false,false,true,true)
    main.board.state[Identity.STATE_FIELD] = {"0":"union_verde","1":"orden_onix"}
    main.board.selected_id = "A"
    main.board.require_order_confirmation = true
    main.board._request_order(Vector2i(2,2),{"id":"X"})
    if main.board.pending_order.get("kind","") != "attack":
        push_error("No legal attack was prepared for the visual QA scenario.")
        _failed = true
    main._process(0.0)
    if not await _capture_landscape("20-ataque-pendiente-1280x720",Vector2i(1280,720),"Batalla · ataque preparado y confirmación"):
        _failed = true
    if not main.board.confirm_pending_order() or main.board.combat_effects.is_empty():
        push_error("The real battle attack did not commit for visual QA.")
        _failed = true
    else:
        main.board.combat_effects.back()["elapsed"] = 0.29
        main.board.queue_redraw()
        main._process(0.0)
        if not await _capture_landscape("21-dano-confirmado-960x540",Vector2i(960,540),"Batalla · daño y contraataque confirmados"):
            _failed = true
    main.board.combat_effects.clear()
    main.board.state = battle_before_effect
    main.board.selected_id = ""
    main.board.pending_order.clear()
    main.board.require_order_confirmation = original_confirmation
    main.board.set_isometric(original_isometric)
    main.board.queue_redraw()
    main._process(0.0)

    main._open_command_menu()
    if not await _capture_landscape("08-mando-1280x720",Vector2i(1280,720),"Centro de mando · operaciones"):
        _failed = true
    if not await _capture_landscape("13-mando-960x540",Vector2i(960,540),"Centro de mando · horizontal compacto"):
        _failed = true
    if main.command_menu.operational_values.size() != 4:
        push_error("Operational command tiles are not present in compact landscape.")
        _failed = true

    main.command_menu.open_for(main.board,"Ejercito")
    if not await _capture_landscape("15-ejercito-1280x720",Vector2i(1280,720),"Ejército · catálogo propio y ficha"):
        _failed = true
    if not await _capture_landscape("16-ejercito-960x540",Vector2i(960,540),"Ejército · visor horizontal compacto"):
        _failed = true
    if main.command_menu.army_columns.vertical or main.command_menu.army_list_body == null:
        push_error("Army roster does not use two landscape panels.")
        _failed = true

    # An isolated battle setup gives the production panel an actual
    # player-owned base. Restore its authoritative state and selection after
    # rendering; none of these previews issues a real purchase.
    var original_factory_pos: Vector2i = main.board.selected_factory_pos
    var prior_state: Dictionary = main.board.state.duplicate(true)
    main.board.new_game(0,false,false,false,true,true,true)
    main.board.selected_factory_pos = Vector2i(0,3)
    main.command_menu.open_for(main.board,"Produccion")
    if not await _capture_landscape("17-produccion-1280x720",Vector2i(1280,720),"Producción · precios y comparador reales"):
        _failed = true
    if not await _capture_landscape("18-produccion-960x540",Vector2i(960,540),"Producción · lista de compra horizontal"):
        _failed = true
    if main.command_menu.production_columns.vertical or main.command_menu.production_purchase_buttons.is_empty():
        push_error("Production preview must show authorized models in two columns.")
        _failed = true
    main.board.state = prior_state
    main.board.selected_factory_pos = original_factory_pos
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
    if not await _capture_landscape("14-resultados-960x540",Vector2i(960,540),"Resultados · horizontal compacto"):
        _failed = true
    if main.results_panel.result_columns.vertical:
        push_error("Result screen stacked cards on a horizontal phone.")
        _failed = true
    main._show_home_menu()
    main._open_saved_matches_from_home()
    if not await _capture_landscape("11-guardados-1280x720",Vector2i(1280,720),"Partidas guardadas · dos ranuras reales"):
        _failed = true
    if not await _capture_landscape("19-guardados-960x540",Vector2i(960,540),"Partidas guardadas · horizontal compacto"):
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
    if _failed or _manifest.size() != 34:
        push_error("Landscape UI QA incomplete: %d/34 captures" % _manifest.size())
        quit(1)
        return
    print("PASS visual gallery: 34 rendered landscape PNG screens with nonblank checks and manifest")
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
    # canvas_items stretch draws a 1280x720 logical scene into a 960x540
    # capture. Control.get_global_rect() stays in logical coordinates, so
    # compare both sides in the same pixel space.
    var logical_base := Vector2(
        float(ProjectSettings.get_setting("display/window/size/viewport_width",1280)),
        float(ProjectSettings.get_setting("display/window/size/viewport_height",720)))
    var scale: Vector2 = Vector2(resolution) / logical_base
    var local: Rect2 = control.get_global_rect()
    var rect := Rect2(local.position * scale,local.size * scale)
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
