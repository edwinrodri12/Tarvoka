extends Node3D
class_name TarvokaAirbaseAndroidBenchV5

# Independent Android instrumentation scene. No economy, battle HP or saves
# are modified: the mixed visual workload is representative, not gameplay.
const AirbaseStress = preload("res://scripts/ui/AirbaseStressV4.gd")
const Units = preload("res://scripts/ui/UnitModels3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Smoke = preload("res://scripts/ui/AirbaseDamageFXV4.gd")

const COUNTS := [8, 32, 64]
const WEATHER := ["clear", "rain", "snow"]
const UNIT_ROLES := ["tank", "apc", "fighter", "attack_heli", "line", "mlrs"]
const DURATION_SECONDS := 15.0
const DETAIL_UNITS := 12

var _count := 8
var _weather := "clear"
var _fx_enabled := true
var _wide := true
var _content: Node3D
var _weather_node: GPUParticles3D
var _camera: Camera3D
var _readout: Label
var _result: Label
var _running := false
var _seconds := 0.0
var _refresh := 0.0
var _frames: Array[float] = []
var _last_csv := ""
var _unit_count := 0
var _detailed_units := 0

func _ready() -> void:
    name = "TARVOKA_BaseAerea_V5_Android"
    _setup_world()
    _setup_ui()
    _rebuild()

func _setup_world() -> void:
    var env := WorldEnvironment.new()
    env.name = "AmbienteDePruebaV5"
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color("#172735")
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color("#92adc0")
    settings.ambient_light_energy = 0.60
    env.environment = settings
    add_child(env)

    var sunlight := DirectionalLight3D.new()
    sunlight.name = "SolPresupuestoUnicaLuz"
    sunlight.rotation_degrees = Vector3(-54, -30, 0)
    sunlight.light_energy = 0.85
    sunlight.shadow_enabled = false
    add_child(sunlight)

    _camera = Camera3D.new()
    _camera.name = "CamaraComparacion"
    _camera.fov = 48
    _camera.current = true
    add_child(_camera)

func _setup_ui() -> void:
    var ui := CanvasLayer.new()
    ui.name = "LecturasAndroidV5"
    add_child(ui)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    panel.offset_left = 14
    panel.offset_top = 14
    panel.offset_right = 370
    panel.offset_bottom = 580
    var skin := StyleBoxFlat.new()
    skin.bg_color = Color(0.035,0.075,0.11,0.93)
    skin.border_color = Color("#426579")
    skin.set_border_width_all(1)
    skin.set_corner_radius_all(10)
    skin.set_content_margin_all(12)
    panel.add_theme_stylebox_override("panel",skin)
    ui.add_child(panel)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",9)
    panel.add_child(column)
    var header := Label.new()
    header.text = "TARVOKA | BASE AEREA V5"
    header.add_theme_color_override("font_color",Color("#f3d37b"))
    header.add_theme_font_size_override("font_size",20)
    column.add_child(header)
    var subtitle := Label.new()
    subtitle.text = "Prueba visual Android - NO es una partida"
    subtitle.add_theme_font_size_override("font_size",12)
    column.add_child(subtitle)

    var count_label := Label.new()
    count_label.text = "Carga de bases"
    column.add_child(count_label)
    var options := OptionButton.new()
    for count in COUNTS:
        options.add_item("%d bases + %d unidades" % [count,count*2])
    options.item_selected.connect(_select_count)
    column.add_child(options)

    var climate_label := Label.new()
    climate_label.text = "Clima y carga adicional"
    column.add_child(climate_label)
    var climate := OptionButton.new()
    for label in ["Despejado","Lluvia","Nieve"]:
        climate.add_item(label)
    climate.item_selected.connect(_select_weather)
    column.add_child(climate)

    var effects := CheckBox.new()
    effects.text = "Humo/fuego V4 cercanos"
    effects.button_pressed = true
    effects.toggled.connect(_toggle_fx)
    column.add_child(effects)

    var camera_button := Button.new()
    camera_button.text = "Alternar camara general / cercana"
    camera_button.pressed.connect(_toggle_camera)
    column.add_child(camera_button)

    var measure := Button.new()
    measure.text = "MEDIR 15 SEGUNDOS"
    measure.pressed.connect(_start_measure)
    column.add_child(measure)

    var copy := Button.new()
    copy.text = "Copiar ultima medicion"
    copy.pressed.connect(_copy_result)
    column.add_child(copy)

    _readout = Label.new()
    _readout.text = "Preparando escenario..."
    _readout.add_theme_font_size_override("font_size",13)
    column.add_child(_readout)

    _result = Label.new()
    _result.text = "Sin medicion de dispositivo."
    _result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _result.add_theme_font_size_override("font_size",12)
    column.add_child(_result)

func _select_count(index: int) -> void:
    if index >= 0 and index < COUNTS.size():
        _count = COUNTS[index]
        _rebuild()

func _select_weather(index: int) -> void:
    if index >= 0 and index < WEATHER.size():
        _weather = WEATHER[index]
        _set_weather()

func _toggle_fx(enabled: bool) -> void:
    _fx_enabled = enabled
    _apply_fx()

func _toggle_camera() -> void:
    _wide = not _wide
    _place_camera()

func _rebuild() -> void:
    _running = false
    _frames.clear()
    if _content != null:
        _content.queue_free()
    _content = Node3D.new()
    _content.name = "EscenaMixtaV5"
    add_child(_content)
    var grid: Node3D = AirbaseStress.build_grid(_count)
    if grid == null:
        push_error("Airbase V5: invalid V4 building grid")
        return
    _content.add_child(grid)
    _content.set_meta("building_count",_count)
    _content.set_meta("proxy_count",grid.get_meta("tarvoka_stress_proxy_count",0))
    _content.set_meta("near_count",grid.get_meta("tarvoka_stress_near_count",0))
    _build_ground(grid)
    _build_units(grid)
    _apply_fx()
    _set_weather()
    _place_camera()
    _result.text = "Nueva carga lista. Inicia la medicion."

func _build_ground(grid: Node3D) -> void:
    var cols: int = int(grid.get_meta("tarvoka_stress_grid_cols",3))
    var rows: int = int(grid.get_meta("tarvoka_stress_grid_rows",3))
    var floor_mesh := PlaneMesh.new()
    floor_mesh.size = Vector2(float(cols)*16.2,float(rows)*16.2)
    var floor_mat := StandardMaterial3D.new()
    floor_mat.albedo_color = Color("#354f51")
    floor_mat.roughness = 1.0
    floor_mesh.material = floor_mat
    var ground := MeshInstance3D.new()
    ground.name = "SueloUnSoloLoteV5"
    ground.mesh = floor_mesh
    ground.position.y = -0.26
    _content.add_child(ground)

func _build_units(grid: Node3D) -> void:
    var cols: int = int(grid.get_meta("tarvoka_stress_grid_cols",3))
    var rows: int = int(grid.get_meta("tarvoka_stress_grid_rows",3))
    var army := Node3D.new()
    army.name = "OchoFaccionesUnidadesMixtas"
    _content.add_child(army)
    _unit_count = _count*2
    _detailed_units = mini(DETAIL_UNITS,_unit_count)
    var markers: Array = []
    for faction in range(8):
        var material := StandardMaterial3D.new()
        material.albedo_color = Style.faction_color(faction)
        material.roughness = 0.78
        markers.append(material)
    var cheap_mesh := BoxMesh.new()
    cheap_mesh.size = Vector3(1.35,0.65,1.8)
    for i in range(_unit_count):
        var faction: int = i%8
        var role: String = UNIT_ROLES[i%UNIT_ROLES.size()]
        var building: int = i%_count
        var x: int = building%cols
        var z: int = building/cols
        var center := Vector3(
            (float(x)-0.5*float(cols-1))*AirbaseStress.GRID_SPACING,
            0.15,
            (float(z)-0.5*float(rows-1))*AirbaseStress.GRID_SPACING)
        var unit: Node3D
        if i < _detailed_units:
            unit = Units.build(role,faction,false,0)
        else:
            var proxy := MeshInstance3D.new()
            proxy.mesh = cheap_mesh
            proxy.material_override = markers[faction]
            proxy.set_meta("distant_unit_lod",true)
            unit = proxy
        if unit == null:
            push_error("Airbase V5: failed to create "+role)
            return
        unit.name = "Unidad_%03d_%s_F%d" % [i,role,faction]
        unit.position = center+Vector3(4.3 if i%2==0 else -4.1,0.0,4.55 if i%3==0 else -4.6)
        army.add_child(unit)
    _content.set_meta("unit_count",_unit_count)
    _content.set_meta("detailed_units",_detailed_units)
    _content.set_meta("distant_unit_proxies",_unit_count-_detailed_units)

func _apply_fx() -> void:
    if _content == null:
        return
    _update_fx_nodes(_content)

func _update_fx_nodes(node: Node) -> void:
    if node is TarvokaAirbaseDamageFXV4:
        var fx: TarvokaAirbaseDamageFXV4 = node
        fx.visible = _fx_enabled
        fx.set_mobile_quality(true)
        fx.set_distant(not _fx_enabled)
    for child in node.get_children():
        _update_fx_nodes(child)

func _set_weather() -> void:
    if _content == null:
        return
    if _weather_node != null:
        _weather_node.queue_free()
        _weather_node = null
    if _weather == "clear":
        return
    var particle := GPUParticles3D.new()
    particle.name = "ClimaV5_"+_weather
    particle.amount = 280 if _weather == "rain" else 190
    particle.lifetime = 2.5 if _weather == "rain" else 4.0
    particle.visibility_aabb = AABB(Vector3(-90,-10,-90),Vector3(180,55,180))
    var motion := ParticleProcessMaterial.new()
    motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    motion.emission_box_extents = Vector3(70,6,70)
    motion.direction = Vector3.DOWN
    motion.spread = 7.0 if _weather == "rain" else 25.0
    motion.gravity = Vector3(0,-12,0) if _weather == "rain" else Vector3(0,-2.5,0)
    motion.initial_velocity_min = 6.0 if _weather == "rain" else 0.8
    motion.initial_velocity_max = 11.0 if _weather == "rain" else 2.0
    particle.process_material = motion
    var billboard := QuadMesh.new()
    billboard.size = Vector2(0.07,0.90) if _weather == "rain" else Vector2(0.20,0.20)
    var material := StandardMaterial3D.new()
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.albedo_color = Color(0.68,0.85,0.98,0.52) if _weather == "rain" else Color(0.92,0.96,1.0,0.83)
    billboard.material = material
    particle.draw_pass_1 = billboard
    particle.position.y = 11
    _content.add_child(particle)
    particle.emitting = true
    _weather_node = particle

func _place_camera() -> void:
    if _camera == null:
        return
    var columns: int = int(ceil(sqrt(float(_count))))
    var rows: int = int(ceil(float(_count)/float(columns)))
    if _wide:
        _camera.position = Vector3(0,maxf(34.0,float(rows)*19.0),maxf(38.0,float(columns)*17.0))
        _camera.look_at(Vector3.ZERO,Vector3.UP)
    else:
        _camera.position = Vector3(8,17,24)
        _camera.look_at(Vector3(-4,1,-1),Vector3.UP)

func _start_measure() -> void:
    _frames.clear()
    _seconds = 0.0
    _running = true
    _last_csv = ""
    _result.text = "Midiendo fotogramas del dispositivo durante 15 s..."

func _process(delta: float) -> void:
    if _running:
        _seconds += delta
        if delta > 0.0 and delta < 2.0:
            _frames.append(delta*1000.0)
        if _seconds >= DURATION_SECONDS:
            _finish_measure()
    _refresh += delta
    if _refresh >= 0.4:
        _refresh = 0.0
        if _readout != null:
            _readout.text = "FPS actual: %.0f | %d bases | %d unidades\nClima: %s | LOD bases: %d | detalle unidades: %d\nMotor: %s | Plataforma: %s" % [
                Engine.get_frames_per_second(),_count,_unit_count,_weather,
                _count-mini(_count,4),_detailed_units,
                RenderingServer.get_video_adapter_name(),OS.get_name()]

func _finish_measure() -> void:
    _running = false
    if _frames.is_empty():
        _result.text = "Sin fotogramas registrados; repite la prueba."
        return
    var durations: Array[float] = _frames.duplicate()
    durations.sort()
    var total_ms := 0.0
    for duration in durations:
        total_ms += duration
    var mean_ms: float = total_ms/float(durations.size())
    var p95: float = durations[mini(durations.size()-1,int(ceil(float(durations.size())*0.95))-1)]
    var average_fps := 1000.0/maxf(mean_ms,0.001)
    var timestamp := Time.get_datetime_string_from_system()
    _last_csv = "%s,%s,%s,%d,%d,%d,%s,%s,%s,%.2f,%.2f,%.2f,%d" % [
        timestamp,OS.get_name(),RenderingServer.get_video_adapter_name(),_count,
        _unit_count,_detailed_units,_weather,str(_fx_enabled),str(_wide),
        average_fps,mean_ms,p95,durations.size()]
    var filename := "user://airbase_v5_results.csv"
    var file := FileAccess.open(filename,FileAccess.READ_WRITE)
    if file == null:
        file = FileAccess.open(filename,FileAccess.WRITE)
    if file != null:
        if file.get_length() == 0:
            file.store_line("date,platform,gpu,bases,units,detailed_units,weather,fx,wide,avg_fps,mean_ms,p95_ms,frames")
        else:
            file.seek_end()
        file.store_line(_last_csv)
        file.close()
    _result.text = "Promedio: %.1f FPS | fotograma medio: %.1f ms\np95: %.1f ms | muestras: %d\nRegistro: %s" % [
        average_fps,mean_ms,p95,durations.size(),filename]
    print("TARVOKA_AIRBASE_V5_DEVICE_SAMPLE,"+_last_csv)

func _copy_result() -> void:
    if _last_csv.is_empty():
        _result.text = "Primero completa una medicion."
    else:
        DisplayServer.clipboard_set(_last_csv)
        _result.text += "\nResultado copiado al portapapeles."
