extends "res://scripts/ui/CombinedArtStudioWeb.gd"
class_name TarvokaEnvironmentArtStudioWeb

# Native 3D terrain is the third tab in the EXISTING unit/HQ web viewer.
# This reuses the exact terrain meshes from the mobile experimental view.
const LabScene = preload("res://scenes/Terrain3DLab.tscn")
const LabScript = preload("res://tools/terrain3d_lab.gd")

var terrain_controls: VBoxContainer
var terrain_scenario_picker: OptionButton
var terrain_quality_picker: OptionButton
var terrain_focus_picker: OptionButton
var terrain_fog_toggle: CheckButton
var terrain_status: Label
var terrain_lab: Node3D
var terrain_grid: Array = []
var terrain_scenario := 0
var terrain_focus := 0

func _ready() -> void:
    super._ready()
    _install_environment_controls()

func _install_environment_controls() -> void:
    category_picker.add_item("ENTORNO Y MAPA 3D")
    var column: VBoxContainer = category_picker.get_parent() as VBoxContainer
    terrain_controls = VBoxContainer.new()
    terrain_controls.name = "OpcionesDelTerreno3D"
    terrain_controls.add_theme_constant_override("separation",8)
    column.add_child(terrain_controls)
    column.move_child(terrain_controls,
        column.get_children().find(building_controls)+1)
    _title(terrain_controls,"ENTORNO 3D REAL · FASES 1–15",15)
    _title(terrain_controls,
        "Relieve, bosques, río, puente, ribera y niebla del mismo motor Godot.",12)
    terrain_scenario_picker = OptionButton.new()
    terrain_scenario_picker.name = "EscenariosDelTerreno"
    for title in ["Valle del río · 15×10","Cordilleras y bosque · 20×14",
            "Mapa táctico · 24×18","Mapa grande · 40×30 (pesado)"]:
        terrain_scenario_picker.add_item(title)
    terrain_controls.add_child(terrain_scenario_picker)
    terrain_scenario_picker.item_selected.connect(_change_terrain_scenario)
    _title(terrain_controls,"CALIDAD DE RENDERIZADO",12)
    terrain_quality_picker = OptionButton.new()
    terrain_quality_picker.name = "CalidadDelTerreno"
    terrain_quality_picker.add_item("Alta: sombras y viento")
    terrain_quality_picker.add_item("Móvil: menos vegetación y sombras")
    terrain_controls.add_child(terrain_quality_picker)
    terrain_quality_picker.item_selected.connect(_change_terrain_quality)
    _title(terrain_controls,"VISTA DE REGIÓN",12)
    terrain_focus_picker = OptionButton.new()
    terrain_focus_picker.name = "EnfoqueDeBiomas"
    for title in ["Mapa completo","Cordillera","Bosque","Río y puente"]:
        terrain_focus_picker.add_item(title)
    terrain_controls.add_child(terrain_focus_picker)
    terrain_focus_picker.item_selected.connect(_change_terrain_focus)
    terrain_fog_toggle = CheckButton.new()
    terrain_fog_toggle.name = "MostrarNieblaEnEstudio"
    terrain_fog_toggle.text = "Simular niebla de guerra"
    terrain_fog_toggle.toggled.connect(_change_terrain_fog)
    terrain_controls.add_child(terrain_fog_toggle)
    _button(terrain_controls,"Restablecer vista",_reset_camera)
    terrain_status = _title(terrain_controls,"",12)
    terrain_controls.visible = false

func _set_faction_widgets_visible(enabled: bool) -> void:
    faction_picker.visible = enabled
    faction_view_grid.visible = enabled
    faction_view_label.visible = enabled
    for child in category_picker.get_parent().get_children():
        if child is Label and (child as Label).text.begins_with(
                "VISTAS POR FACCIÓN"):
            child.visible = enabled

func _switch_category(index: int) -> void:
    if index != 2:
        if terrain_controls != null:
            terrain_controls.visible = false
        _set_faction_widgets_visible(true)
        super._switch_category(index)
        return
    building_controls.visible = false
    for widget in _unit_only_controls:
        widget.visible = false
    _set_faction_widgets_visible(false)
    hq_ground.visible = false
    terrain_controls.visible = true
    _display_terrain()
    category_picker.select(2)

func _terrain_for_scenario(index: int) -> Array:
    if index == 0:
        return LabScript.sample_terrain()
    var dims := Vector2i(20,14) if index == 1 else (
        Vector2i(24,18) if index == 2 else Vector2i(40,30))
    var map: Array = []
    for y in range(dims.y):
        var row: Array = []
        for x in range(dims.x):
            var kind: String = "plain"
            if x < dims.x/3 and (
                    y < dims.y/2 or (x+y)%5 == 0):
                kind = "mountain"
            elif (x < dims.x/2 and y >= dims.y/2) or (
                    x > dims.x*2/3 and y < dims.y/2):
                kind = "forest"
            var stream_x: int = int(dims.x*0.57)+(
                1 if y%6 >= 3 else 0)
            if x == stream_x or x == stream_x+1:
                kind = "water"
            if y == int(dims.y/2):
                kind = "road"
            row.append(kind)
        map.append(row)
    return map

func _terrain_visible() -> Dictionary:
    var visible: Dictionary = {}
    if not terrain_fog_toggle.button_pressed:
        return visible
    var height: int = terrain_grid.size()
    var width: int = (terrain_grid[0] as Array).size()
    for y in range(height):
        for x in range(width):
            if x < int(width*0.70) and y < int(height*0.76):
                visible[Vector2i(x,y)] = true
    return visible

func _display_terrain() -> void:
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "terrain"
    terrain_lab = LabScene.instantiate()
    terrain_lab.embedded_in_studio = true
    model_root = terrain_lab
    preview.add_child(terrain_lab)
    camera.make_current()
    terrain_grid = _terrain_for_scenario(terrain_scenario)
    terrain_focus = 0
    terrain_focus_picker.select(0)
    _yaw = -32.0
    _zoom = 1.0
    _apply_terrain()
    _update_camera()

func _apply_terrain() -> void:
    if terrain_lab == null:
        return
    terrain_lab.set_battle_terrain(
        terrain_grid,_terrain_visible(),
        terrain_fog_toggle.button_pressed,
        6 if terrain_quality_picker.selected == 0 else 3)
    _update_details()

func _change_terrain_scenario(index: int) -> void:
    terrain_scenario = clampi(index,0,3)
    if _role != "terrain":
        return
    terrain_grid = _terrain_for_scenario(terrain_scenario)
    terrain_focus = 0
    terrain_focus_picker.select(0)
    _apply_terrain()
    _update_camera()

func _change_terrain_quality(_index: int) -> void:
    if _role == "terrain":
        _apply_terrain()

func _change_terrain_fog(_enabled: bool) -> void:
    if _role == "terrain":
        _apply_terrain()

func _change_terrain_focus(index: int) -> void:
    terrain_focus = index
    if _role == "terrain":
        _update_camera()

func _terrain_target() -> Vector3:
    var w: int = (terrain_grid[0] as Array).size()
    var h: int = terrain_grid.size()
    match terrain_focus:
        1:
            return Vector3(float(w)*0.19,0.9,float(h)*0.23)
        2:
            return Vector3(float(w)*0.33,0.35,float(h)*0.68)
        3:
            return Vector3(float(w)*0.65,0.18,float(h)*0.48)
    return Vector3(float(w)*0.5,0.45,float(h)*0.5)

func _rotate(degrees: float) -> void:
    if _role == "terrain":
        _yaw += degrees
        _update_camera()
        return
    super._rotate(degrees)

func _reset_camera() -> void:
    if _role == "terrain":
        _yaw = -32.0
        _zoom = 1.0
        terrain_focus = 0
        terrain_focus_picker.select(0)
        _update_camera()
        return
    super._reset_camera()

func _update_camera() -> void:
    if _role == "terrain":
        if camera == null or terrain_grid.is_empty():
            return
        var span: float = float(maxi(
            (terrain_grid[0] as Array).size(),terrain_grid.size()))
        var focus_scale: float = 0.39 if terrain_focus > 0 else 1.0
        var target := _terrain_target()
        var delta := Vector3(span*0.83,span*0.89,
            span*0.93)*focus_scale
        camera.position = target+delta.rotated(
            Vector3.UP,deg_to_rad(_yaw))
        camera.look_at(target,Vector3.UP)
        camera.size = maxf(4.3,span*1.51*focus_scale/_zoom)
        camera.make_current()
        return
    super._update_camera()

func _update_details() -> void:
    if _role == "terrain":
        if terrain_lab == null:
            return
        var stats: Dictionary = terrain_lab.environment_metrics()
        detail_label.text = (
            "ENTORNO 3D · %d árboles · %d arbustos · %d triángulos") % [
                int(stats.get("trees",0)),
                int(stats.get("shrubs",0)),
                int(stats.get("approx_total_triangles",0))]
        status_label.text = (
            "Terreno Godot · ríos, puentes, roca, nieve y niebla regional")
        terrain_status.text = (
            "Sectores renovados: %d/%d · Construcción: %.1f ms") % [
                int(stats.get("fog_chunks_updated",0)),
                int(stats.get("fog_chunks_total",0)),
                float(stats.get("build_ms",0.0))]
        return
    super._update_details()
