extends "res://scripts/ui/UnitArtStudioWeb.gd"
class_name TarvokaCombinedArtStudioWeb

# Add the approved Headquarters to the existing actual Godot Web studio.
# This adapter deliberately does NOT alter the tank inspector or meshes.
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const BUILDING_STATES := ["operativo","capturado","danado","destruido"]

var category_picker: OptionButton
var building_picker: OptionButton
var level_picker: OptionButton
var building_state_picker: OptionButton
var building_controls: VBoxContainer
var _unit_only_controls: Array[Control] = []
var hq_compare_button: Button
var _hq_show_v2 := true

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

    # Place above the shared faction selector.
    var index: int = column.get_children().find(faction_picker)
    column.move_child(building_controls,maxi(0,index-1))
    faction_picker.item_selected.connect(_refresh_building_faction)

func _toggle_hq_finish() -> void:
    _hq_show_v2 = not _hq_show_v2
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
    var level: int = level_picker.selected + 1
    var condition: String = str(BUILDING_STATES[building_state_picker.selected])
    model_root = Headquarters.build(level,_faction,condition,_hq_show_v2)
    assert(model_root != null)
    preview.add_child(model_root)
    if initial:
        _yaw = -32.0
        _zoom = 1.0
    model_root.rotation_degrees.y = _yaw
    camera.position = Vector3(18.0,16.5,19.0)
    camera.look_at(Vector3(0,2.3,0),Vector3.UP)
    _update_camera()
    _update_details()

func _update_camera() -> void:
    if _role == "headquarters":
        if camera != null:
            camera.size = 20.0 / _zoom
        return
    super._update_camera()

func _update_details() -> void:
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
        "ARQUITECTURA V2" if _hq_show_v2 else "PROTOTIPO V1",level,meshes]
    status_label.text = "%s · %s · Piezas de color: %d" % [
        str(Factions.FACTIONS[faction]["name"]),
        condition.capitalize(),
        Headquarters.paintable_count(model_root)]
