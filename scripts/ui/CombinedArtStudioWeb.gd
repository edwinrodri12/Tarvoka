extends "res://scripts/ui/UnitArtStudioWeb.gd"
class_name TarvokaCombinedArtStudioWeb

# Add the approved Headquarters to the existing actual Godot Web studio.
# This adapter deliberately does NOT alter the tank inspector or meshes.
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const TerrainStudio = preload("res://scripts/ui/TerrainStudio3D.gd")
const BUILDING_STATES := ["operativo","capturado","danado","destruido"]

var category_picker: OptionButton
var building_picker: OptionButton
var level_picker: OptionButton
var building_state_picker: OptionButton
var building_controls: VBoxContainer
var terrain_controls: VBoxContainer
var terrain_scene_picker: OptionButton
var terrain_light_picker: OptionButton
var terrain_grid_toggle: CheckButton
var terrain_continuous_toggle: CheckButton
var terrain_samples_toggle: CheckButton
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
    for node in column.get_children():
        if node is Label and (node as Label).text.begins_with("El mismo modelo de Godot"):
            (node as Label).text = "Visor 3D del motor Godot: las unidades se usan en Android; los edificios son prototipos visuales independientes. Arrastra para girar y pellizca para acercar."
    category_picker = OptionButton.new()
    category_picker.name = "CategoriaEstudio3D"
    category_picker.custom_minimum_size.y = 52.0
    category_picker.add_item("UNIDADES 3D")
    category_picker.add_item("EDIFICIOS 3D")
    category_picker.add_item("ENTORNO Y MAPA 3D")
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

    _title(terrain_controls,"ILUMINACION",13)
    terrain_light_picker = OptionButton.new()
    terrain_light_picker.name = "LuzDeEntorno"
    for option in ["Mediodía","Atardecer","Nublado"]:
        terrain_light_picker.add_item(option)
    terrain_light_picker.item_selected.connect(_change_terrain_light)
    terrain_controls.add_child(terrain_light_picker)
    _title(terrain_controls,
        "Escenarios artísticos 3D de prueba. Las casillas, alturas y modelos "
        + "de referencia NO cambian el combate, la movilidad ni los guardados. "
        + "Usa girar, acercar y restablecer cámara.",12)
    terrain_controls.visible = false

    # Place above the shared faction selector.
    var index: int = column.get_children().find(faction_picker)
    column.move_child(building_controls,maxi(0,index-1))
    column.move_child(terrain_controls,maxi(0,index-1))
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
    if index < 0 or index > 2:
        return
    var building: bool = index == 1
    var terrain: bool = index == 2
    building_controls.visible = building
    terrain_controls.visible = terrain
    for widget in _unit_only_controls:
        widget.visible = not building and not terrain
    faction_picker.visible = building or terrain
    if building:
        _restore_default_lighting()
        _display_headquarters()
    elif terrain:
        _display_terrain()
    else:
        _restore_default_lighting()
        camera.position = Vector3(5.3,4.2,6.3)
        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
        super._display_role("tank")
    category_picker.select(index)

func _change_terrain_scene(_index: int) -> void:
    _rebuild_terrain(false)

func _rebuild_terrain(_checked: bool = false) -> void:
    if _role == "terrain":
        _display_terrain()

func _change_terrain_light(_index: int) -> void:
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

func _apply_terrain_lighting() -> void:
    var setting: int = terrain_light_picker.selected
    for item in preview.get_children():
        if item is WorldEnvironment:
            var env: Environment = (item as WorldEnvironment).environment
            env.background_color = Color("#304956") if setting == 1 else Color("#536877") if setting == 2 else Color("#7b9aa8")
            env.ambient_light_color = Color("#edb990") if setting == 1 else Color("#c3d5df")
            env.ambient_light_energy = 0.73 if setting == 1 else 0.94 if setting == 2 else 0.83
        elif item is DirectionalLight3D:
            var sun: DirectionalLight3D = item as DirectionalLight3D
            sun.light_color = Color("#ffbc86") if setting == 1 else Color("#e3edf4") if setting == 2 else Color.WHITE
            sun.light_energy = 0.92 if setting == 2 else 1.32 if setting == 1 else 1.65

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
        _faction,terrain_continuous_toggle.button_pressed)
    preview.add_child(model_root)
    if initial:
        _yaw = -32.0
        _zoom = 1.0
    model_root.rotation_degrees.y = _yaw
    camera.position = Vector3(34.0,35.0,38.0)
    camera.look_at(Vector3(0,0.4,0),Vector3.UP)
    _apply_terrain_lighting()
    _update_camera()
    _update_details()

func _change_building_variant(_index: int) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _refresh_building_faction(_index: int) -> void:
    # UnitArtStudioWeb's handler owns _faction; we rebuild using that
    # selected paint colour rather than tinting an entire concrete building.
    if _role == "headquarters":
        _display_headquarters()
    elif _role == "terrain":
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
    if _role == "terrain":
        if camera != null:
            camera.size = 43.0 / _zoom
        return
    if _role == "headquarters":
        if camera != null:
            camera.size = 20.0 / _zoom
        return
    super._update_camera()

func _update_details() -> void:
    if _role == "terrain":
        if model_root == null:
            return
        var counts: Dictionary = model_root.get_meta("terrain_counts",{})
        detail_label.text = "%s · %d casillas · %d mallas reales" % [
            str(TerrainStudio.SCENES[terrain_scene_picker.selected]),
            int(model_root.get_meta("terrain_tile_count",0)),
            Models.inspect_meshes(model_root)]
        status_label.text = "Bosques %d · Montañas %d · Agua %d · Carreteras %d" % [
            int(counts.get("forest",0)),int(counts.get("mountain",0)),
            int(counts.get("water",0)),int(counts.get("road",0))]
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
