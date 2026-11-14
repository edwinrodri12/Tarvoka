extends "res://scripts/ui/UnitArtStudioWeb.gd"
class_name TarvokaCombinedArtStudioWeb

# Add the approved Headquarters to the existing actual Godot Web studio.
# This adapter deliberately does NOT alter the tank inspector or meshes.
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const HQMapLOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const HQCityBatch = preload("res://scripts/ui/HeadquartersCityBatch3D.gd")
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
            hq_key_light = child as DirectionalLight3D
            hq_key_light.shadow_enabled = false
            break

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
    for name_version in ["V8 · Cuartel General: material final",
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

func _change_building_variant(_index: int) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _change_hq_sculpt(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4:
        _display_headquarters()

func _change_hq_materials_v8(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v7_toggle.button_pressed:
        _display_headquarters()

func _change_building_batch(_enabled: bool) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _set_hq_map_lod(distant: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and model_root != null:
        HQMapLOD.set_distant(model_root,distant)
        _update_details()

func _refresh_building_faction(_index: int) -> void:
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
        hq_v7_toggle.button_pressed,hq_v8_toggle.button_pressed)
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
