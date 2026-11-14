extends "res://scripts/ui/UnitArtStudioWeb.gd"
class_name TarvokaCombinedArtStudioWeb

# Add the approved Headquarters to the existing actual Godot Web studio.
# This adapter deliberately does NOT alter the tank inspector or meshes.
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const HQMapLOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const HQCityBatch = preload("res://scripts/ui/HeadquartersCityBatch3D.gd")
const OfficialEmblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const BUILDING_STATES := ["operativo","capturado","danado","destruido"]

var category_picker: OptionButton
var building_picker: OptionButton
var level_picker: OptionButton
var building_state_picker: OptionButton
var building_controls: VBoxContainer
var _unit_only_controls: Array[Control] = []
var hq_compare_button: Button
var hq_v3_compare_button: Button
var hq_version_picker: OptionButton
var hq_v7_toggle: CheckButton
var hq_v8_toggle: CheckButton
var hq_v9_toggle: CheckButton
var hq_v10_toggle: CheckButton
var hq_v11_toggle: CheckButton
var hq_lighting_picker: OptionButton
var hq_lighting_label: Label
var hq_fill_light: DirectionalLight3D
var hq_environment: WorldEnvironment
var hq_night_lamps: Array[OmniLight3D] = []
var _hq_light_preset := 0
var faction_view_grid: GridContainer
var faction_view_label: Label
var faction_view_buttons: Array[Button] = []
var hq_map_lod_toggle: CheckButton
var hq_batch_toggle: CheckButton
var hq_fps_label: Label
var _fps_refresh := 0.0
var hq_ground: MeshInstance3D
var hq_key_light: DirectionalLight3D
var _hq_show_v2 := true
var _hq_show_v3 := true
var _hq_show_v4 := true

func _ready() -> void:
    super._ready()
    _add_building_mode()
    _setup_architecture_stage()

func _setup_architecture_stage() -> void:
    # Only the laboratory gets a ground plane and true shadows. The actual
    # building geometry and tactical terrain remain separate.
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(120.0,120.0)
    var ground_material := StandardMaterial3D.new()
    ground_material.albedo_color = Color("#182d32")
    ground_material.metallic = 0.04
    ground_material.roughness = 0.98
    hq_ground = MeshInstance3D.new()
    hq_ground.name = "SueloNeutroDeEstudio3D"
    hq_ground.mesh = ground_mesh
    hq_ground.material_override = ground_material
    hq_ground.position = Vector3(0,-0.28,0)
    hq_ground.visible = false
    preview.add_child(hq_ground)
    for child in preview.get_children():
        if child is DirectionalLight3D:
            if hq_key_light == null:
                hq_key_light = child as DirectionalLight3D
                hq_key_light.shadow_enabled = false
            else:
                hq_fill_light = child as DirectionalLight3D
        elif child is WorldEnvironment:
            hq_environment = child as WorldEnvironment
    for lamp_data in [
            [Vector3(0,2.65,-5.4),Color("#ffd39d"),5.0],
            [Vector3(4.8,2.5,-4.1),Color("#a4dfff"),6.3],
            [Vector3(0,7.0,-3.3),Color("#cbdfff"),7.4]]:
        var lamp := OmniLight3D.new()
        lamp.name = "BalizaNocturnaEscenarioV11"
        lamp.position = lamp_data[0] as Vector3
        lamp.light_color = lamp_data[1] as Color
        lamp.omni_range = float(lamp_data[2])
        lamp.light_energy = 0.58
        lamp.shadow_enabled = false
        lamp.visible = false
        preview.add_child(lamp)
        hq_night_lamps.append(lamp)
    _apply_hq_lighting(0)

func _apply_hq_lighting(index: int) -> void:
    if hq_key_light == null or hq_environment == null:
        return
    var active: bool = _role == "headquarters"
    _hq_light_preset = clampi(index,0,2)
    var preset: int = _hq_light_preset if active else 0
    # Three reproducible lighting rigs, same camera and exact 3D material.
    # Material response is measured instead of painted with false colors.
    var sun_color := [Color("#fff3e4"),Color("#ffc289"),Color("#7597c0")]
    var sky_color := [Color("#14232d"),Color("#493b38"),Color("#0a1427")]
    var ambient_color := [Color("#c1d5de"),Color("#e1a789"),Color("#7297bd")]
    var key_energy := [1.65,1.23,0.18]
    var fill_energy := [0.80,0.37,0.12]
    var ambient_energy := [0.84,0.61,0.39]
    var pitch := [-46.0,-18.0,-9.0]
    if hq_key_light != null:
        hq_key_light.rotation_degrees = Vector3(float(pitch[preset]),-32.0,0)
        hq_key_light.light_color = sun_color[preset]
        hq_key_light.light_energy = float(key_energy[preset])
        hq_key_light.shadow_enabled = active
    if hq_fill_light != null:
        hq_fill_light.light_color = ambient_color[preset]
        hq_fill_light.light_energy = float(fill_energy[preset])
    var scene: Environment = hq_environment.environment
    if scene != null:
        scene.background_color = sky_color[preset]
        scene.ambient_light_color = ambient_color[preset]
        scene.ambient_light_energy = float(ambient_energy[preset])
    for lamp in hq_night_lamps:
        lamp.visible = active and preset == 2

func _change_hq_lighting(index: int) -> void:
    _apply_hq_lighting(index)

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
    hq_compare_button.visible = false
    hq_v3_compare_button.visible = false
    _title(building_controls,"ACABADO VISUAL",14)
    hq_version_picker = OptionButton.new()
    hq_version_picker.name = "SelectorAcabadoCuartelGeneral"
    hq_version_picker.custom_minimum_size.y = 50
    for name_version in ["V11 · Curvas y acabados bajo distintas luces",
            "V3 · Arquitectura anterior",
            "V2 · Primera revisión",
            "V1 · Prototipo original"]:
        hq_version_picker.add_item(name_version)
    hq_version_picker.select(0)
    hq_version_picker.item_selected.connect(_change_hq_version)
    building_controls.add_child(hq_version_picker)
    hq_v7_toggle = CheckButton.new()
    hq_v7_toggle.name = "AcabadoArquitectonicoV7"
    hq_v7_toggle.text = "Acabado escultórico V7 (comparar con V4)"
    hq_v7_toggle.button_pressed = true
    hq_v7_toggle.toggled.connect(_change_hq_sculpt)
    building_controls.add_child(hq_v7_toggle)
    hq_v8_toggle = CheckButton.new()
    hq_v8_toggle.name = "AcabadoMaterialesYDesgasteV8"
    hq_v8_toggle.text = "Materiales PBR y daños V8 (comparar con V7)"
    hq_v8_toggle.button_pressed = true
    hq_v8_toggle.toggled.connect(_change_hq_materials_v8)
    building_controls.add_child(hq_v8_toggle)
    hq_v9_toggle = CheckButton.new()
    hq_v9_toggle.name = "SiluetaTacticaHQV9"
    hq_v9_toggle.text = "Silueta V9 visible a distancia (comparar V8)"
    hq_v9_toggle.button_pressed = true
    hq_v9_toggle.toggled.connect(_change_hq_readability_v9)
    building_controls.add_child(hq_v9_toggle)
    hq_v10_toggle = CheckButton.new()
    hq_v10_toggle.name = "TransicionesFisicasMaterialesV10"
    hq_v10_toggle.text = "Uniones y superficies V10 (comparar con V9)"
    hq_v10_toggle.button_pressed = true
    hq_v10_toggle.toggled.connect(_change_hq_surfaces_v10)
    building_controls.add_child(hq_v10_toggle)
    hq_v11_toggle = CheckButton.new()
    hq_v11_toggle.name = "EsculturaAristasRedondeadasV11"
    hq_v11_toggle.text = "Remates curvos V11 (comparar con V10)"
    hq_v11_toggle.button_pressed = true
    hq_v11_toggle.toggled.connect(_change_hq_refinement_v11)
    building_controls.add_child(hq_v11_toggle)

    hq_lighting_label = _title(building_controls,"ILUMINACIÓN DE ESTUDIO",13)
    hq_lighting_picker = OptionButton.new()
    hq_lighting_picker.name = "IluminacionCuartelGeneral"
    hq_lighting_picker.custom_minimum_size.y = 49
    for name_preset in ["Día neutro","Atardecer cálido","Noche operativa"]:
        hq_lighting_picker.add_item(name_preset)
    hq_lighting_picker.select(0)
    hq_lighting_picker.item_selected.connect(_change_hq_lighting)
    building_controls.add_child(hq_lighting_picker)

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
    hq_map_lod_toggle = CheckButton.new()
    hq_map_lod_toggle.name = "VistaTacticaOptimizadaHQ"
    hq_map_lod_toggle.text = "Vista lejana optimizada (mapa)"
    hq_map_lod_toggle.button_pressed = false
    hq_map_lod_toggle.toggled.connect(_set_hq_map_lod)
    building_controls.add_child(hq_map_lod_toggle)
    hq_batch_toggle = CheckButton.new()
    hq_batch_toggle.name = "Escenario49Cuarteles"
    hq_batch_toggle.text = "Probar distrito de 49 edificios 3D"
    hq_batch_toggle.toggled.connect(_change_building_batch)
    building_controls.add_child(hq_batch_toggle)
    hq_fps_label = _title(building_controls,"FPS: — | 49 edificios | carga agrupada",12)
    hq_fps_label.visible = false
    _title(building_controls,
        "Modelo editable de prueba. La arquitectura, daños y niveles "
        + "son visuales: no cambian estadísticas, recursos ni partidas.",12)
    building_controls.visible = false

    # Place above the shared faction selector.
    var index: int = column.get_children().find(faction_picker)
    column.move_child(building_controls,maxi(0,index-1))
    faction_picker.item_selected.connect(_refresh_building_faction)
    _install_faction_gallery(column)
    _sync_faction_gallery(_faction)

func _install_faction_gallery(column: VBoxContainer) -> void:
    # Restore the eight *visible*, officially approved faction views.
    # Keep the original full-name dropdown intact for accessibility.
    var gallery_heading := _title(column,"VISTAS POR FACCIÓN · 8 ESCUDOS OFICIALES",12)
    faction_view_label = _title(column,"",12)
    faction_view_label.name = "NombreFaccionEnEstudio"
    faction_view_grid = GridContainer.new()
    faction_view_grid.name = "GaleriaOchoFacciones"
    faction_view_grid.columns = 2
    faction_view_grid.add_theme_constant_override("h_separation",6)
    faction_view_grid.add_theme_constant_override("v_separation",6)
    column.add_child(faction_view_grid)
    for faction in range(VisualStyle.FACTIONS.size()):
        var record: Dictionary = VisualStyle.FACTIONS[faction]
        var button := Button.new()
        button.name = "FaccionOficial_%d" % faction
        # Compact labels fit the 306px scroll panel; tooltip and selected
        # label always show the full, approved faction name.
        var short_names := ["NORTE","ESCARLATA","VERDE","SOLAR",
            "VIOLETA","ÁMBAR","TURQUESA","ÓNIX"]
        button.text = str(short_names[faction])
        button.tooltip_text = str(record["name"])
        button.icon = OfficialEmblems.emblem_texture(faction)
        button.expand_icon = true
        button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size = Vector2(143,52)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.toggle_mode = true
        button.pressed.connect(_select_faction_view.bind(faction))
        faction_view_grid.add_child(button)
        faction_view_buttons.append(button)
    # The entire gallery must remain visible for Units and Buildings;
    # it is deliberately NOT in _unit_only_controls / building_controls.
    var at: int = column.get_children().find(faction_picker)
    column.move_child(gallery_heading,at+1)
    column.move_child(faction_view_label,at+2)
    column.move_child(faction_view_grid,at+3)

func _select_faction_view(faction: int) -> void:
    if faction < 0 or faction >= VisualStyle.FACTIONS.size():
        return
    faction_picker.select(faction)
    # OptionButton.select() does not emit item_selected in Godot.
    _on_faction(faction)
    _refresh_building_faction(faction)

func _sync_faction_gallery(index: int) -> void:
    if faction_view_label == null:
        return
    if index < 0 or index >= VisualStyle.FACTIONS.size():
        return
    faction_view_label.text = "Mostrando: %s" % str(VisualStyle.FACTIONS[index]["name"])
    for i in range(faction_view_buttons.size()):
        var button: Button = faction_view_buttons[i]
        button.set_pressed_no_signal(i == index)
        button.modulate = Color.WHITE if i == index else Color(0.79,0.81,0.85,0.88)

func _change_hq_version(index: int) -> void:
    if index < 0 or index > 3:
        return
    _hq_show_v2 = index <= 2
    _hq_show_v3 = index <= 1
    _hq_show_v4 = index == 0
    if index != 0 and hq_batch_toggle != null:
        hq_batch_toggle.set_pressed_no_signal(false)
    hq_version_picker.select(index)
    if _role == "headquarters":
        _display_headquarters()

func _toggle_hq_detail() -> void:
    _hq_show_v2 = true
    _hq_show_v4 = false
    _hq_show_v3 = not _hq_show_v3
    if hq_version_picker != null:
        hq_version_picker.select(1 if _hq_show_v3 else 2)
    hq_v3_compare_button.text = (
        "Volver al diseño V3 mejorado" if not _hq_show_v3
        else "Comparar arquitectura V2 / V3")
    hq_compare_button.text = "Comparar con diseño anterior (V1)"
    if _role == "headquarters":
        _display_headquarters()

func _toggle_hq_finish() -> void:
    _hq_show_v2 = not _hq_show_v2
    _hq_show_v3 = false
    _hq_show_v4 = false
    if hq_version_picker != null:
        hq_version_picker.select(2 if _hq_show_v2 else 3)
    hq_compare_button.text = (
        "Volver al diseño arquitectónico V2" if not _hq_show_v2
        else "Comparar con diseño anterior (V1)")
    if _role == "headquarters":
        _display_headquarters()

func _switch_category(index: int) -> void:
    if index < 0 or index > 1:
        return
    var building: bool = index == 1
    building_controls.visible = building
    if hq_ground != null:
        hq_ground.visible = building
    if hq_key_light != null:
        hq_key_light.shadow_enabled = building
    _apply_hq_lighting(_hq_light_preset)
    for widget in _unit_only_controls:
        widget.visible = not building
    if building:
        faction_picker.visible = true
        _display_headquarters()
    else:
        camera.position = Vector3(5.3,4.2,6.3)
        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
        super._display_role("tank")
    category_picker.select(index)
    _apply_hq_lighting(_hq_light_preset)

func _change_building_variant(_index: int) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _change_hq_sculpt(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4:
        _display_headquarters()

func _change_hq_materials_v8(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v7_toggle.button_pressed:
        _display_headquarters()

func _change_hq_readability_v9(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v7_toggle.button_pressed and hq_v8_toggle.button_pressed:
        _display_headquarters()

func _change_hq_surfaces_v10(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v9_toggle.button_pressed:
        _display_headquarters()

func _change_hq_refinement_v11(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v10_toggle.button_pressed:
        _display_headquarters()

func _change_building_batch(_enabled: bool) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _set_hq_map_lod(distant: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and model_root != null:
        HQMapLOD.set_distant(model_root,distant)
        _update_details()

func _refresh_building_faction(_index: int) -> void:
    _sync_faction_gallery(_faction)
    # UnitArtStudioWeb's handler owns _faction; we rebuild using that
    # selected paint colour rather than tinting an entire concrete building.
    if _role == "headquarters":
        _display_headquarters()

func _display_headquarters() -> void:
    if preview == null:
        return
    var initial: bool = _role != "headquarters"
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "headquarters"
    var showing_batch: bool = hq_batch_toggle.button_pressed and _hq_show_v4
    hq_batch_toggle.visible = _hq_show_v4
    hq_v7_toggle.visible = _hq_show_v4 and not showing_batch
    hq_v8_toggle.visible = _hq_show_v4 and hq_v7_toggle.button_pressed and not showing_batch
    hq_v9_toggle.visible = _hq_show_v4 and hq_v7_toggle.button_pressed and hq_v8_toggle.button_pressed and not showing_batch
    hq_v10_toggle.visible = _hq_show_v4 and hq_v7_toggle.button_pressed and hq_v8_toggle.button_pressed and hq_v9_toggle.button_pressed and not showing_batch
    hq_v11_toggle.visible = hq_v10_toggle.visible and hq_v10_toggle.button_pressed
    hq_fps_label.visible = showing_batch
    if showing_batch:
        model_root = HQCityBatch.build_grid(7,7,15.5)
        assert(model_root != null)
        hq_map_lod_toggle.visible = false
        preview.add_child(model_root)
        if initial:
            _yaw = 32.0
            _zoom = 1.0
        model_root.rotation_degrees.y = _yaw
        camera.position = Vector3(-125.0,100.0,-125.0)
        camera.look_at(Vector3(0,2.3,0),Vector3.UP)
        _update_camera()
        _update_details()
        return
    var level: int = level_picker.selected + 1
    var condition: String = str(BUILDING_STATES[building_state_picker.selected])
    model_root = Headquarters.build(level,_faction,condition,_hq_show_v2,_hq_show_v3,_hq_show_v4,
        hq_v7_toggle.button_pressed,hq_v8_toggle.button_pressed,hq_v9_toggle.button_pressed,
        hq_v10_toggle.button_pressed,hq_v11_toggle.button_pressed)
    assert(model_root != null)
    hq_map_lod_toggle.visible = _hq_show_v4
    if _hq_show_v4:
        HQMapLOD.install(model_root,level,_faction,condition)
        HQMapLOD.set_distant(model_root,hq_map_lod_toggle.button_pressed)
    preview.add_child(model_root)
    if initial:
        _yaw = 32.0
        _zoom = 1.0
    model_root.rotation_degrees.y = _yaw
    # Front-right camera reveals the command entrance, insignia, and helipad.
    camera.position = Vector3(-18.0,16.5,-19.0)
    camera.look_at(Vector3(0,2.3,0),Vector3.UP)
    _update_camera()
    _update_details()

func _reset_camera() -> void:
    if _role == "headquarters":
        _yaw = 32.0
        _zoom = 1.0
        if model_root != null:
            model_root.rotation_degrees.y = _yaw
        _update_camera()
        return
    super._reset_camera()

func _update_camera() -> void:
    if _role == "headquarters":
        if camera != null:
            camera.size = (153.0 if hq_batch_toggle.button_pressed and _hq_show_v4 else 18.6) / _zoom
            if model_root != null and not hq_batch_toggle.button_pressed:
                Headquarters.set_render_detail(model_root,_zoom >= 1.24)
        return
    super._update_camera()

func _update_details() -> void:
    if _role != "headquarters":
        super._update_details()
        return
    if model_root == null:
        return
    if model_root.get_meta("tarvoka_building_kind","") == "headquarters_city":
        var buildings: int = int(model_root.get_meta("tarvoka_studio_building_count",0))
        var batches: int = int(model_root.get_meta("tarvoka_studio_batch_count",0))
        detail_label.text = "Distrito 3D · %d cuarteles · %d lotes MultiMesh" % [buildings,batches]
        status_label.text = "Geometrías compartidas · %d variantes en caché" % HQMapLOD.cached_variant_count()
        return
    var level: int = int(model_root.get_meta("visual_level",1))
    var faction: int = int(model_root.get_meta("visual_faction",0))
    var condition: String = str(model_root.get_meta("visual_condition","operativo"))
    var meshes: int = Models.inspect_meshes(model_root)
    detail_label.text = "Cuartel General · %s · Nivel %d · %d mallas 3D" % [
        ("ARQUITECTURA V4" if _hq_show_v4 else ("ARQUITECTURA V3" if _hq_show_v3 else "ARQUITECTURA V2")) if _hq_show_v2 else "PROTOTIPO V1",level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v7",false):
        detail_label.text = "Cuartel General · ACABADO ESCULPIDO V7 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v8",false):
        detail_label.text = "Cuartel General · ACABADO PBR Y DAÑOS V8 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v9",false):
        detail_label.text = "Cuartel General · SILUETA V9 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v10",false):
        detail_label.text = "Cuartel General · SUPERFICIES V10 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v11",false):
        detail_label.text = "Cuartel General · REMATES CURVOS V11 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_map_distant",false):
        detail_label.text = "Cuartel General · VISTA DE MAPA V5 · Nivel %d · 1 malla 3D / 6 superficies" % level
    status_label.text = "%s · %s · Piezas de color: %d" % [
        str(Factions.FACTIONS[faction]["name"]),
        condition.capitalize(),
        Headquarters.paintable_count(model_root)]

func _process(delta: float) -> void:
    super._process(delta)
    if _role != "headquarters" or hq_batch_toggle == null or not hq_batch_toggle.button_pressed:
        return
    _fps_refresh += delta
    if _fps_refresh < 0.75:
        return
    _fps_refresh = 0.0
    if hq_fps_label != null and model_root != null:
        hq_fps_label.text = "FPS visor: %d | %d edificios | %d lotes de dibujo" % [
            Engine.get_frames_per_second(),
            int(model_root.get_meta("tarvoka_studio_building_count",0)),
            int(model_root.get_meta("tarvoka_studio_batch_count",0))]
