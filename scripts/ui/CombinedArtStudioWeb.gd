extends "res://scripts/ui/UnitArtStudioWeb.gd"
class_name TarvokaCombinedArtStudioWeb

# Add the approved Headquarters to the existing actual Godot Web studio.
# This adapter deliberately does NOT alter the tank inspector or meshes.
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const TerrainStudio = preload("res://scripts/ui/TerrainStudio3D.gd")
const BattleTerrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const BattleRanges = preload("res://scripts/ui/BattleRanges3D.gd")
const BattleBoard = preload("res://scripts/ui/TouchBoard.gd")
const BattleFull = preload("res://scripts/ui/Battle3DMapView.gd")
const BattleScenarios = preload("res://scripts/core/Scenarios.gd")
const BattleOrders = preload("res://scripts/ui/Battle3DOrders.gd")
const BUILDING_STATES := ["operativo","capturado","danado","destruido"]

var category_picker: OptionButton
var building_picker: OptionButton
var level_picker: OptionButton
var building_state_picker: OptionButton
var building_controls: VBoxContainer
var terrain_controls: VBoxContainer
var battle_controls: VBoxContainer
var battle_scenario_picker: OptionButton
var battle_size_picker: OptionButton
var battle_fog_toggle: CheckButton
var battle_modern_toggle: CheckButton
var battle_sample_board: Control
var battle_full_view: Control
var battle_launch_button: Button
var battle_reset_button: Button
var battle_guidance: Label
var _battle_seed: int = 22435
var _battle_panoramic_center := Vector3.ZERO
var terrain_scene_picker: OptionButton
var terrain_light_picker: OptionButton
var terrain_shadow_toggle: CheckButton
var terrain_grid_toggle: CheckButton
var terrain_continuous_toggle: CheckButton
var terrain_scatter_toggle: CheckButton
var terrain_samples_toggle: CheckButton
var terrain_bridge_v4_toggle: CheckButton
var terrain_shore_v5_toggle: CheckButton
var terrain_water_v5_toggle: CheckButton
var terrain_rocks_v5_toggle: CheckButton
var terrain_camera_picker: OptionButton
var terrain_compare_button: Button
var terrain_faction_grid: GridContainer
var terrain_side_panel: PanelContainer
var terrain_fullscreen_button: Button
var terrain_restore_panel_button: Button
var _terrain_fullscreen := false
var terrain_faction_buttons: Array[Button] = []
var _terrain_v5_enabled := true
var _unit_only_controls: Array[Control] = []
var hq_compare_button: Button
var hq_v3_compare_button: Button
var _hq_show_v2 := true
var _hq_show_v3 := true

func _ready() -> void:
    super._ready()
    _add_building_mode()

func _add_building_mode() -> void:
    # Use the same SubViewport and camera that already serve the tank.
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    assert(column != null)
    terrain_side_panel = column.get_parent().get_parent() as PanelContainer
    assert(terrain_side_panel != null)
    for node in column.get_children():
        if node is Label and (node as Label).text.begins_with("El mismo modelo de Godot"):
            (node as Label).text = "Visor 3D del motor Godot: las unidades se usan en Android; los edificios son prototipos visuales independientes. Arrastra para girar y pellizca para acercar."
    category_picker = OptionButton.new()
    category_picker.name = "CategoriaEstudio3D"
    category_picker.custom_minimum_size.y = 52.0
    category_picker.add_item("UNIDADES 3D")
    category_picker.add_item("EDIFICIOS 3D")
    category_picker.add_item("ENTORNO Y MAPA 3D")
    category_picker.add_item("BATALLA 3D · INTERACTIVA")
    category_picker.select(0)
    category_picker.item_selected.connect(_switch_category)
    column.add_child(category_picker)
    column.move_child(category_picker,3)

    # Remember exactly which existing controls are tank/unit-specific.
    # Common faction, rotation, zoom and reset widgets remain shared.
    var unit_section := false
    for node in column.get_children():
        if node is Label:
            var label: String = (node as Label).text
            if label == "MODELO" or label == "ANIMACION REAL" or label == "CONDICION DEL TANQUE":
                unit_section = true
            elif label == "FACCION" or label == "ROTAR Y ACERCAR":
                unit_section = false
        if node == detail_label:
            unit_section = false
        if unit_section and node is Control:
            _unit_only_controls.append(node as Control)

    building_controls = VBoxContainer.new()
    building_controls.name = "OpcionesDeEdificios"
    building_controls.add_theme_constant_override("separation",8)
    column.add_child(building_controls)
    var building_heading := _title(building_controls,"EDIFICIO",14)
    building_heading.add_theme_color_override("font_color",Color("#f1c978"))
    building_picker = OptionButton.new()
    building_picker.name = "TipoDeEdificio"
    building_picker.custom_minimum_size.y = 49
    building_picker.add_item("Cuartel General")
    building_controls.add_child(building_picker)
    hq_compare_button = _button(building_controls,
        "Comparar con diseño anterior (V1)",_toggle_hq_finish)
    hq_compare_button.name = "CompararAcabadoDeEdificio"
    hq_compare_button.custom_minimum_size.y = 49
    hq_v3_compare_button = _button(building_controls,
        "Comparar arquitectura V2 / V3",_toggle_hq_detail)
    hq_v3_compare_button.name = "ComparadorArquitecturaV3"
    hq_v3_compare_button.custom_minimum_size.y = 49

    _title(building_controls,"NIVEL ARQUITECTONICO",13)
    level_picker = OptionButton.new()
    level_picker.name = "NivelDeEdificio"
    level_picker.custom_minimum_size.y = 49
    level_picker.add_item("Nivel 1 — Puesto de mando")
    level_picker.add_item("Nivel 2 — Centro de comunicaciones")
    level_picker.add_item("Nivel 3 — Complejo avanzado")
    level_picker.select(0)
    level_picker.item_selected.connect(_change_building_variant)
    building_controls.add_child(level_picker)

    _title(building_controls,"ESTADO DE LA INSTALACION",13)
    building_state_picker = OptionButton.new()
    building_state_picker.name = "EstadoDeEdificio"
    building_state_picker.custom_minimum_size.y = 49
    for condition in ["Operativo","Capturado","Dañado","Destruido"]:
        building_state_picker.add_item(condition)
    building_state_picker.item_selected.connect(_change_building_variant)
    building_controls.add_child(building_state_picker)
    _title(building_controls,
        "Modelo editable de prueba. La arquitectura, daños y niveles "
        + "son visuales: no cambian estadísticas, recursos ni partidas.",12)
    building_controls.visible = false

    # A separate preview category shares the true Godot viewport and camera.
    # Geometry is reviewed here without changing the 2D tactical grid.
    terrain_controls = VBoxContainer.new()
    terrain_controls.name = "OpcionesDeEntornoYMapa"
    terrain_controls.add_theme_constant_override("separation",8)
    column.add_child(terrain_controls)
    _title(terrain_controls,"ESCENARIO 3D",14)
    terrain_scene_picker = OptionButton.new()
    terrain_scene_picker.name = "SelectorDeBioma"
    terrain_scene_picker.custom_minimum_size.y = 49
    for caption in TerrainStudio.SCENES:
        terrain_scene_picker.add_item(caption)
    terrain_scene_picker.item_selected.connect(_change_terrain_scene)
    terrain_controls.add_child(terrain_scene_picker)

    terrain_grid_toggle = CheckButton.new()
    terrain_grid_toggle.name = "MostrarCuadricula"
    terrain_grid_toggle.text = "Mostrar cuadrícula de casillas"
    terrain_grid_toggle.button_pressed = false
    terrain_grid_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_grid_toggle)

    terrain_samples_toggle = CheckButton.new()
    terrain_samples_toggle.name = "MostrarModelosReferencia"
    terrain_samples_toggle.text = "Ver tanque y edificio en el terreno"
    terrain_samples_toggle.button_pressed = true
    terrain_samples_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_samples_toggle)

    terrain_continuous_toggle = CheckButton.new()
    terrain_continuous_toggle.name = "CompararSueloV1V2"
    terrain_continuous_toggle.text = "Suelo continuo V2 (desactivar para V1)"
    terrain_continuous_toggle.button_pressed = true
    terrain_continuous_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_continuous_toggle)

    terrain_scatter_toggle = CheckButton.new()
    terrain_scatter_toggle.name = "VegetacionYOrillasV3"
    terrain_scatter_toggle.text = "Vegetación y orillas detalladas V3"
    terrain_scatter_toggle.button_pressed = true
    terrain_scatter_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_scatter_toggle)

    _title(terrain_controls,"PUENTES Y ACABADOS DEL TERRENO",13)
    terrain_bridge_v4_toggle = CheckButton.new()
    terrain_bridge_v4_toggle.name = "PuentesRampasV4"
    terrain_bridge_v4_toggle.text = "Puentes y rampas continuas V4"
    terrain_bridge_v4_toggle.button_pressed = true
    terrain_bridge_v4_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_bridge_v4_toggle)

    terrain_shore_v5_toggle = CheckButton.new()
    terrain_shore_v5_toggle.name = "TaludesDeRiberaV5"
    terrain_shore_v5_toggle.text = "Riberas con pendiente natural V5"
    terrain_shore_v5_toggle.button_pressed = true
    terrain_shore_v5_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_shore_v5_toggle)

    terrain_water_v5_toggle = CheckButton.new()
    terrain_water_v5_toggle.name = "CorrientesDeAguaV5"
    terrain_water_v5_toggle.text = "Corrientes y reflejos sutiles V5"
    terrain_water_v5_toggle.button_pressed = true
    terrain_water_v5_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_water_v5_toggle)

    terrain_rocks_v5_toggle = CheckButton.new()
    terrain_rocks_v5_toggle.name = "DetalleGeologicoV5"
    terrain_rocks_v5_toggle.text = "Rocas y estratos de montaña V5"
    terrain_rocks_v5_toggle.button_pressed = true
    terrain_rocks_v5_toggle.toggled.connect(_rebuild_terrain)
    terrain_controls.add_child(terrain_rocks_v5_toggle)

    terrain_compare_button = _button(terrain_controls,
        "COMPARAR: volver a acabado V4",_toggle_v5_finish)
    terrain_compare_button.name = "ComparacionTerrenoV4V5"
    terrain_compare_button.custom_minimum_size.y = 50

    _title(terrain_controls,"CAMARAS Y ENCUADRES",13)
    terrain_camera_picker = OptionButton.new()
    terrain_camera_picker.name = "CamarasDeTerreno"
    terrain_camera_picker.custom_minimum_size.y = 48
    for caption in ["Isométrica general","Cenital táctica","A ras del terreno","Vista contraria"]:
        terrain_camera_picker.add_item(caption)
    terrain_camera_picker.select(0)
    terrain_camera_picker.item_selected.connect(_change_terrain_camera)
    terrain_controls.add_child(terrain_camera_picker)
    terrain_fullscreen_button = _button(terrain_controls,
        "AMPLIAR VISUALIZACIÓN · SIN PANEL",_toggle_terrain_fullscreen)
    terrain_fullscreen_button.name = "PantallaCompletaTerreno3D"
    terrain_fullscreen_button.custom_minimum_size.y = 50

    _title(terrain_controls,"OCHO FACCIONES OFICIALES",13)
    terrain_faction_grid = GridContainer.new()
    terrain_faction_grid.name = "GaleriaFaccionesTerreno"
    terrain_faction_grid.columns = 2
    terrain_faction_grid.add_theme_constant_override("h_separation",5)
    terrain_faction_grid.add_theme_constant_override("v_separation",5)
    var short_names := ["NORTE","ESCARLATA","VERDE","SOLAR",
        "VIOLETA","ÁMBAR","TURQUESA","ÓNIX"]
    for i in range(Factions.FACTIONS.size()):
        var item := Button.new()
        item.name = "TerrenoFaccion_%d" % i
        item.text = str(short_names[i])
        item.tooltip_text = str(Factions.FACTIONS[i]["name"])
        # Use original shield textures when bundled. This standalone V8/V9
        # studio does not bundle the HQ branch's two emblem atlases, so
        # its selector always retains the eight approved colors and labels.
        item.icon = Factions.emblem_texture(i)
        item.add_theme_color_override("font_color",
            Factions.faction_color(i).lightened(0.16))
        item.expand_icon = true
        item.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        item.alignment = HORIZONTAL_ALIGNMENT_LEFT
        item.custom_minimum_size = Vector2(134,45)
        item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        item.toggle_mode = true
        item.pressed.connect(_select_terrain_faction.bind(i))
        terrain_faction_grid.add_child(item)
        terrain_faction_buttons.append(item)
    terrain_controls.add_child(terrain_faction_grid)
    _sync_terrain_factions()

    _title(terrain_controls,"ILUMINACION",13)
    terrain_light_picker = OptionButton.new()
    terrain_light_picker.name = "LuzDeEntorno"
    for option in ["Mediodía","Atardecer","Nublado"]:
        terrain_light_picker.add_item(option)
    terrain_light_picker.item_selected.connect(_change_terrain_light)
    terrain_controls.add_child(terrain_light_picker)
    terrain_shadow_toggle = CheckButton.new()
    terrain_shadow_toggle.name = "SombrasDeRelieve"
    terrain_shadow_toggle.text = "Sombras del relieve (comparar)"
    terrain_shadow_toggle.button_pressed = true
    terrain_shadow_toggle.toggled.connect(_change_terrain_shadow)
    terrain_controls.add_child(terrain_shadow_toggle)
    _title(terrain_controls,
        "Escenarios artísticos 3D de prueba. Las casillas, alturas y modelos "
        + "de referencia NO cambian el combate, la movilidad ni los guardados. "
        + "Usa girar, acercar y restablecer cámara.",12)
    terrain_controls.visible = false

    # Fourth Studio category: a sandbox copy of the REAL Android battle
    # state, with no autosave or AI. The preview shares the established
    # WebGL Godot camera, while the fullscreen view reuses V5–V7 picking,
    # drag/zoom and safe confirmed combat orders.
    battle_controls = VBoxContainer.new()
    battle_controls.name = "OpcionesDeBatalla3D"
    battle_controls.add_theme_constant_override("separation",8)
    column.add_child(battle_controls)
    _title(battle_controls,"CAMPO DE BATALLA 3D",14)
    battle_scenario_picker = OptionButton.new()
    battle_scenario_picker.name = "EscenarioBatalla3D"
    battle_scenario_picker.custom_minimum_size.y = 50
    for caption in BattleScenarios.LABELS:
        battle_scenario_picker.add_item(caption)
    battle_scenario_picker.add_item("Mapa aleatorio · semilla 22435")
    battle_scenario_picker.selected = 1
    battle_controls.add_child(battle_scenario_picker)
    battle_size_picker = OptionButton.new()
    battle_size_picker.name = "TamanoBatalla3D"
    battle_size_picker.custom_minimum_size.y = 50
    for caption in ["10 × 8 · rápido","24 × 18 · mediano","40 × 30 · grande"]:
        battle_size_picker.add_item(caption)
    battle_size_picker.select(0)
    battle_controls.add_child(battle_size_picker)
    battle_fog_toggle = CheckButton.new()
    battle_fog_toggle.name = "NieblaDeGuerra3D"
    battle_fog_toggle.text = "Niebla de guerra real"
    # Studio default is a complete art showcase; users can enable real fog.
    battle_fog_toggle.button_pressed = false
    battle_controls.add_child(battle_fog_toggle)
    battle_modern_toggle = CheckButton.new()
    battle_modern_toggle.name = "UnidadesModernas3D"
    battle_modern_toggle.text = "Tanques, infantería y aeronaves"
    battle_modern_toggle.button_pressed = true
    battle_controls.add_child(battle_modern_toggle)
    battle_reset_button = _button(battle_controls,
        "CREAR / REINICIAR MAPA 3D",_reset_battle_demo)
    battle_reset_button.name = "ReiniciarPartida3DEstudio"
    battle_reset_button.custom_minimum_size.y = 50
    battle_launch_button = _button(battle_controls,
        "ABRIR BATALLA 3D INTERACTIVA",_open_battle_fullscreen)
    battle_launch_button.name = "AbrirBatalla3DDesdeEstudio"
    battle_launch_button.custom_minimum_size.y = 58
    battle_guidance = _title(battle_controls,
        "Vista de laboratorio basada en la partida real de Godot. "
        + "Abre el visor interactivo para tocar unidades y destinos, "
        + "girar, acercar y confirmar movimientos o ataques. "
        + "La demostración no modifica guardados de Android.",12)
    battle_controls.hide()

    # The only return control when the sidebar is hidden is an overlay
    # OUTSIDE the sidebar, so exiting expanded view always remains possible.
    terrain_restore_panel_button = Button.new()
    terrain_restore_panel_button.name = "RestaurarPanelTerreno3D"
    terrain_restore_panel_button.text = "MOSTRAR CONTROLES 3D"
    terrain_restore_panel_button.anchor_left = 1.0
    terrain_restore_panel_button.anchor_right = 1.0
    terrain_restore_panel_button.offset_left = -225.0
    terrain_restore_panel_button.offset_right = -12.0
    terrain_restore_panel_button.offset_top = 12.0
    terrain_restore_panel_button.offset_bottom = 60.0
    terrain_restore_panel_button.pressed.connect(_toggle_terrain_fullscreen)
    terrain_restore_panel_button.hide()
    add_child(terrain_restore_panel_button)

    # The battle simulation and interactive viewer are WebGL-compatible
    # Godot nodes. Hidden parent 2D UI and autosave are disabled.
    battle_sample_board = BattleBoard.new()
    battle_sample_board.name = "PartidaDePruebaAislada"
    battle_sample_board.ai_enabled = false
    battle_sample_board.autosave_enabled = false
    battle_sample_board.require_order_confirmation = true
    battle_sample_board.visible = false
    add_child(battle_sample_board)
    battle_full_view = BattleFull.new()
    battle_full_view.name = "PantallaBatalla3DDelEstudio"
    add_child(battle_full_view)
    battle_full_view.connect("focus_requested",_return_from_battle_fullscreen)

    # Place above the shared faction selector.
    var index: int = column.get_children().find(faction_picker)
    column.move_child(building_controls,maxi(0,index-1))
    column.move_child(terrain_controls,maxi(0,index-1))
    column.move_child(battle_controls,maxi(0,index-1))
    faction_picker.item_selected.connect(_refresh_building_faction)

func _toggle_hq_detail() -> void:
    _hq_show_v2 = true
    _hq_show_v3 = not _hq_show_v3
    hq_v3_compare_button.text = (
        "Volver al diseño V3 mejorado" if not _hq_show_v3
        else "Comparar arquitectura V2 / V3")
    hq_compare_button.text = "Comparar con diseño anterior (V1)"
    if _role == "headquarters":
        _display_headquarters()

func _toggle_hq_finish() -> void:
    _hq_show_v2 = not _hq_show_v2
    hq_compare_button.text = (
        "Volver al diseño arquitectónico V2" if not _hq_show_v2
        else "Comparar con diseño anterior (V1)")
    if _role == "headquarters":
        _display_headquarters()

func _switch_category(index: int) -> void:
    if index < 0 or index > 3:
        return
    if _terrain_fullscreen:
        _leave_terrain_fullscreen()
    var building: bool = index == 1
    var terrain: bool = index == 2
    var battle: bool = index == 3
    building_controls.visible = building
    terrain_controls.visible = terrain
    battle_controls.visible = battle
    for widget in _unit_only_controls:
        widget.visible = not building and not terrain and not battle
    faction_picker.visible = building or terrain
    if building:
        _restore_default_lighting()
        _display_headquarters()
    elif terrain:
        _display_terrain()
    elif battle:
        _display_battle()
    else:
        _restore_default_lighting()
        camera.position = Vector3(5.3,4.2,6.3)
        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
        super._display_role("tank")
    category_picker.select(index)

func _change_terrain_scene(_index: int) -> void:
    _rebuild_terrain(false)

func _toggle_terrain_fullscreen() -> void:
    if _role != "terrain":
        return
    _terrain_fullscreen = not _terrain_fullscreen
    if terrain_side_panel != null:
        terrain_side_panel.visible = not _terrain_fullscreen
    terrain_restore_panel_button.visible = _terrain_fullscreen

func _leave_terrain_fullscreen() -> void:
    _terrain_fullscreen = false
    if terrain_side_panel != null:
        terrain_side_panel.show()
    if terrain_restore_panel_button != null:
        terrain_restore_panel_button.hide()

func _select_terrain_faction(index: int) -> void:
    if index < 0 or index >= Factions.FACTIONS.size():
        return
    _faction = index
    faction_picker.select(index)
    _sync_terrain_factions()
    _rebuild_terrain(false)

func _sync_terrain_factions() -> void:
    for i in range(terrain_faction_buttons.size()):
        var item: Button = terrain_faction_buttons[i]
        item.set_pressed_no_signal(i == _faction)
        item.modulate = Color.WHITE if i == _faction else Color(0.76,0.81,0.86,0.80)

func _change_terrain_camera(_index: int) -> void:
    if _role == "terrain":
        _update_camera()

func _toggle_v5_finish() -> void:
    _terrain_v5_enabled = not _terrain_v5_enabled
    terrain_compare_button.text = (
        "COMPARAR: volver a acabado V4" if _terrain_v5_enabled
        else "VOLVER AL ACABADO V5")
    _rebuild_terrain(false)

func _rebuild_terrain(_checked: bool = false) -> void:
    if _role == "terrain":
        _display_terrain()

func _change_terrain_light(_index: int) -> void:
    if _role == "terrain":
        _apply_terrain_lighting()

func _change_terrain_shadow(_checked: bool) -> void:
    if _role == "terrain":
        _apply_terrain_lighting()

func _restore_default_lighting() -> void:
    for item in preview.get_children():
        if item is WorldEnvironment:
            var env: Environment = (item as WorldEnvironment).environment
            env.background_color = Color("#14232D")
            env.ambient_light_color = Color("#C1D5DE")
            env.ambient_light_energy = 0.84
        elif item is DirectionalLight3D:
            var light: DirectionalLight3D = item as DirectionalLight3D
            light.light_color = Color.WHITE
            light.light_energy = 1.65 if light == preview.get_child(2) else 0.8
            light.shadow_enabled = false
            light.rotation_degrees = Vector3(-46,-32,0) if light == preview.get_child(2) else Vector3(-25,132,0)

func _apply_terrain_lighting() -> void:
    var setting: int = terrain_light_picker.selected
    for item in preview.get_children():
        if item is WorldEnvironment:
            var env: Environment = (item as WorldEnvironment).environment
            env.background_color = Color("#374c58") if setting == 1 else Color("#4b606c") if setting == 2 else Color("#526c75")
            env.ambient_light_color = Color("#f1c8a7") if setting == 1 else Color("#becdd6")
            env.ambient_light_energy = 0.37 if setting == 1 else 0.53 if setting == 2 else 0.46
        elif item is DirectionalLight3D:
            var sun: DirectionalLight3D = item as DirectionalLight3D
            var is_key: bool = sun == preview.get_child(2)
            if is_key:
                sun.light_color = Color("#f5b98b") if setting == 1 else Color("#e3edf4") if setting == 2 else Color("#fff6dd")
                sun.light_energy = 0.89 if setting == 0 else 0.76 if setting == 1 else 0.62
                sun.rotation_degrees = Vector3(-27,-52,0) if setting == 1 else Vector3(-46,-32,0)
                sun.shadow_enabled = terrain_shadow_toggle.button_pressed
                sun.shadow_blur = 1.18
            else:
                # The old prototype used the FULL key-light energy on BOTH
                # directionals, bleaching vertex-coloured ground to white.
                sun.light_color = Color("#9cb7d5") if setting == 1 else Color("#bbcbd6")
                sun.light_energy = 0.20 if setting == 1 else 0.30 if setting == 2 else 0.26
                sun.shadow_enabled = false

func _display_terrain() -> void:
    if preview == null:
        return
    var initial: bool = _role != "terrain"
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "terrain"
    model_root = TerrainStudio.build_demo(terrain_scene_picker.selected,
        terrain_grid_toggle.button_pressed,terrain_samples_toggle.button_pressed,
        _faction,terrain_continuous_toggle.button_pressed,
        terrain_scatter_toggle.button_pressed,
        _terrain_v5_enabled and terrain_shore_v5_toggle.button_pressed,
        _terrain_v5_enabled and terrain_water_v5_toggle.button_pressed,
        _terrain_v5_enabled and terrain_rocks_v5_toggle.button_pressed,
        terrain_bridge_v4_toggle.button_pressed)
    preview.add_child(model_root)
    if initial:
        _yaw = -32.0
        _zoom = 1.0
    model_root.rotation_degrees.y = _yaw
    _apply_terrain_lighting()
    _update_camera()
    _update_details()

func _battle_dimensions() -> Vector2i:
    match battle_size_picker.selected:
        1:
            return Vector2i(24,18)
        2:
            return Vector2i(40,30)
    return Vector2i(10,8)

func _reset_battle_demo() -> void:
    # Keep each browser demo independent from the user's Android save,
    # offline, and always requiring a separate confirmation.
    var scenario: int = battle_scenario_picker.selected
    var modern: bool = battle_modern_toggle.button_pressed
    battle_sample_board.ai_enabled = false
    battle_sample_board.autosave_enabled = false
    battle_sample_board.require_order_confirmation = true
    battle_sample_board.new_game(scenario,true,battle_fog_toggle.button_pressed,
        modern,modern,modern,modern,0,_battle_seed,_battle_dimensions())
    if _role == "battle":
        _display_battle()

func _preview_selected_unit() -> String:
    var selected: String = str(battle_sample_board.selected_id)
    if not selected.is_empty():
        return selected
    for unit in battle_sample_board.state.get("units",[]):
        if unit is Dictionary and int(unit.get("faction",-1)) == 0 and \
                int(unit.get("hp",0)) > 0:
            selected = str(unit.get("id",""))
            if BattleOrders.select(battle_sample_board,selected):
                return selected
    return ""

func _display_battle() -> void:
    if preview == null:
        return
    var initial: bool = _role != "battle"
    _stop_animation()
    if initial:
        _reset_battle_demo()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "battle"
    var selected: String = _preview_selected_unit()
    model_root = BattleTerrain.build(battle_sample_board.state,selected)
    if model_root == null:
        status_label.text = "No se pudo construir el mapa de batalla 3D."
        return
    var dims: Vector2i = model_root.get_meta("board_size")
    _battle_panoramic_center = Vector3(
        float(dims.x-1)*BattleTerrain.CELL*0.5,0,
        float(dims.y-1)*BattleTerrain.CELL*0.5)
    # The tactical engine's original coordinates remain unchanged. Only
    # the exhibited model is centered for the shared rotating studio camera.
    model_root.position = -_battle_panoramic_center
    preview.add_child(model_root)
    var cells: Dictionary = model_root.get_meta("public_cells")
    BattleRanges.build(model_root,battle_sample_board.state,selected,cells)
    if initial:
        _yaw = -32.0
        _zoom = 1.0
    _apply_terrain_lighting()
    _update_camera()
    _update_details()

func _open_battle_fullscreen() -> void:
    if battle_full_view == null or battle_sample_board == null:
        return
    # The Studio preview and fullscreen battle share a sandbox state, but
    # only the latter can issue orders. No real player save is read/written.
    preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
    if not bool(battle_full_view.call("open_from_board",battle_sample_board)):
        preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS

func _return_from_battle_fullscreen(_cell: Vector2i) -> void:
    preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    if _role == "battle":
        _display_battle()

func _change_building_variant(_index: int) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _refresh_building_faction(_index: int) -> void:
    # UnitArtStudioWeb's handler owns _faction; we rebuild using that
    # selected paint colour rather than tinting an entire concrete building.
    if _role == "headquarters":
        _display_headquarters()
    elif _role == "terrain":
        _sync_terrain_factions()
        _display_terrain()

func _display_headquarters() -> void:
    if preview == null:
        return
    var initial: bool = _role != "headquarters"
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "headquarters"
    var level: int = level_picker.selected + 1
    var condition: String = str(BUILDING_STATES[building_state_picker.selected])
    model_root = Headquarters.build(level,_faction,condition,_hq_show_v2,_hq_show_v3)
    assert(model_root != null)
    preview.add_child(model_root)
    if initial:
        _yaw = -32.0
        _zoom = 1.0
    model_root.rotation_degrees.y = _yaw
    # Front-right camera reveals the command entrance, insignia, and helipad.
    camera.position = Vector3(18.0,16.5,-19.0)
    camera.look_at(Vector3(0,2.3,0),Vector3.UP)
    _update_camera()
    _update_details()

func _update_camera() -> void:
    if _role == "battle":
        if camera == null or model_root == null:
            return
        var dims: Vector2i = model_root.get_meta("board_size",Vector2i(10,8))
        var span: float = float(maxi(dims.x,dims.y))*BattleTerrain.CELL
        camera.size = span*1.24/_zoom
        var angle: float = deg_to_rad(_yaw)
        camera.position = Vector3(sin(angle)*span*0.78,
            span*0.98,cos(angle)*span*0.78)
        camera.look_at(Vector3(0,0.08,0),Vector3.UP)
        return
    if _role == "terrain":
        if camera == null:
            return
        camera.size = 30.5 / _zoom
        var angle: int = terrain_camera_picker.selected if terrain_camera_picker != null else 0
        match angle:
            1:
                camera.position = Vector3(0.01,52.0,0.03)
                camera.look_at(Vector3.ZERO,Vector3.FORWARD)
            2:
                camera.position = Vector3(19.0,11.0,29.0)
                camera.look_at(Vector3(0,0.5,0),Vector3.UP)
            3:
                camera.position = Vector3(-34.0,28.0,-38.0)
                camera.look_at(Vector3(0,0.4,0),Vector3.UP)
            _:
                camera.position = Vector3(34.0,35.0,38.0)
                camera.look_at(Vector3(0,0.4,0),Vector3.UP)
        return
    if _role == "headquarters":
        if camera != null:
            camera.size = 20.0 / _zoom
        return
    super._update_camera()

func _update_details() -> void:
    if _role == "battle":
        if model_root == null:
            return
        var dims: Vector2i = model_root.get_meta("board_size")
        var stats: Dictionary = model_root.get_meta("render_stats",{})
        var units: Dictionary = stats.get("units",{})
        detail_label.text = "BATALLA 3D · %d × %d · %d sectores · %d mallas reales" % [
            dims.x,dims.y,int(stats.get("chunks",0)),
            Models.inspect_meshes(model_root)]
        status_label.text = "Unidades visibles %d · Detalladas %d · Niebla %d · Bosques %d · Caminos %d" % [
            int(units.get("visible",0)),int(units.get("detailed",0)),
            int(stats.get("unknown",0)),int(stats.get("trees",0)),
            int(stats.get("roads",0))]
        return
    if _role == "terrain":
        if model_root == null:
            return
        var counts: Dictionary = model_root.get_meta("terrain_counts",{})
        detail_label.text = "%s · %d casillas · %d mallas reales" % [
            str(TerrainStudio.SCENES[terrain_scene_picker.selected]),
            int(model_root.get_meta("terrain_tile_count",0)),
            Models.inspect_meshes(model_root)]
        var foliage: Dictionary = model_root.get_meta("terrain_scatter_counts",{})
        status_label.text = "Bosques %d · Montañas %d · Agua %d · Carreteras %d" % [
            int(counts.get("forest",0)),int(counts.get("mountain",0)),
            int(counts.get("water",0)),int(counts.get("road",0))]
        if bool(model_root.get_meta("terrain_studio_scatter",false)):
            status_label.text += " · Detalles %d (%d lotes)" % [
                int(foliage.get("grass",0))+int(foliage.get("reeds",0))
                +int(foliage.get("gravel",0)),int(foliage.get("batches",0))]
        var finish: Dictionary = model_root.get_meta("terrain_detail_v5",{})
        if int(finish.get("batches",0)) > 0:
            status_label.text += " · V5: %d riberas, %d corrientes, %d rocas (%d lotes)" % [
                int(finish.get("banks",0)),int(finish.get("ripples",0)),
                int(finish.get("rocks",0)),int(finish.get("batches",0))]
        return
    if _role != "headquarters":
        super._update_details()
        return
    if model_root == null:
        return
    var level: int = int(model_root.get_meta("visual_level",1))
    var faction: int = int(model_root.get_meta("visual_faction",0))
    var condition: String = str(model_root.get_meta("visual_condition","operativo"))
    var meshes: int = Models.inspect_meshes(model_root)
    detail_label.text = "Cuartel General · %s · Nivel %d · %d mallas 3D" % [
        ("ARQUITECTURA V3" if _hq_show_v3 else "ARQUITECTURA V2") if _hq_show_v2 else "PROTOTIPO V1",level,meshes]
    status_label.text = "%s · %s · Piezas de color: %d" % [
        str(Factions.FACTIONS[faction]["name"]),
        condition.capitalize(),
        Headquarters.paintable_count(model_root)]

# The common Web studio orbit/zoom buttons remain available in battle mode;
# unlike the model-gallery geometry, the grid MUST NOT rotate independently
# of its logical world-coordinate axes.
func _rotate(degrees: float) -> void:
    if _role == "battle":
        _yaw = fposmod(_yaw+degrees,360.0)
        _update_camera()
    else:
        super._rotate(degrees)

func _reset_camera() -> void:
    if _role == "battle":
        _yaw = -32.0
        _zoom = 1.0
        _update_camera()
    else:
        super._reset_camera()
