extends Control
class_name TarvokaHQAndroidPhysicalBench

# Production-like GL compatibility renderer running *on an Android device*.
# All output is local/ephemeral; no gameplay, network, purchases or save data.
# Results include real sampled frame times, not guessed device FPS.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const City = preload("res://scripts/ui/HeadquartersCityBatch3D.gd")
const Climate = preload("res://scripts/ui/HeadquartersClimateV17.gd")
const Universal = preload("res://scripts/ui/WeatherCoating3D.gd")
const MODE_NAMES := ["HQ V20 detallado (1)","Distrito 49","Distrito 100","Distrito 144"]
const COUNTS := [1,49,100,144]
const WEATHER := ["clear","rain","snow"]
const CSV_PATH := "user://tarvoka_hq_physical_benchmark.csv"
const WARMUP_SECONDS := 5.0
const SAMPLE_SECONDS := 20.0
const ROUNDS := 3

var scene_view: SubViewport
var stage: Node3D
var active_model: Node3D
var stage_weather: Node3D
var camera: Camera3D
var status: Label
var metrics: Label
var mode_picker: OptionButton
var weather_picker: OptionButton
var start_button: Button
var _mode := 0
var _weather := 0
var _running := false
var _iteration := 0
var _phase_time := 0.0
var _samples: Array[float] = []
var _frame_ui_counter := 0.0
var _last_csv := ""
var _records: Array[Dictionary] = []

func _ready() -> void:
    name = "TARVOKA HQ · Prueba física Android"
    _make_ui()
    _make_3d()
    _change_mode(0)
    status.text = "Preparado. El FPS se medirá en ESTE dispositivo, no en CI."

func _label(parent: Node, value: String, min_height: int = 0) -> Label:
    var label := Label.new()
    label.text = value
    label.custom_minimum_size.y = min_height
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label

func _button(parent: Node,value: String,callback: Callable) -> Button:
    var b := Button.new()
    b.text = value
    b.custom_minimum_size.y = 48
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _make_ui() -> void:
    var body := HBoxContainer.new()
    body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    body.add_theme_constant_override("separation",4)
    add_child(body)
    var visual := SubViewportContainer.new()
    visual.stretch = true
    visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(visual)
    scene_view = SubViewport.new()
    scene_view.size = Vector2i(1040,720)
    scene_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    visual.add_child(scene_view)
    var sidebar := PanelContainer.new()
    sidebar.custom_minimum_size.x = 315.0
    sidebar.size_flags_horizontal = Control.SIZE_SHRINK_END
    sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(sidebar)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    sidebar.add_child(scroll)
    var column := VBoxContainer.new()
    column.custom_minimum_size.x = 305.0
    column.add_theme_constant_override("separation",7)
    scroll.add_child(column)
    _label(column,"TARVOKA · HQ V20\nBENCHMARK EN TELÉFONO",52)
    _label(column,"Godot 4.3 · OpenGL 3 · sin alterar el juego",38)
    mode_picker = OptionButton.new()
    mode_picker.custom_minimum_size.y = 46
    for item in MODE_NAMES:
        mode_picker.add_item(item)
    mode_picker.item_selected.connect(_change_mode)
    column.add_child(mode_picker)
    weather_picker = OptionButton.new()
    weather_picker.custom_minimum_size.y = 46
    for weather in ["Despejado","Lluvia","Nieve"]:
        weather_picker.add_item(weather)
    weather_picker.item_selected.connect(_change_weather)
    column.add_child(weather_picker)
    start_button = _button(column,"INICIAR · 3 rondas de medición",
        _toggle_benchmark)
    _button(column,"COPIAR RESULTADOS CSV",_copy_csv)
    status = _label(column,"",95)
    metrics = _label(column,"",140)
    _label(column,
        "Medición por escenario: 5 s estabilización + 20 s de FPS. "
        + "Tres rondas, cuatro escenarios. No es un benchmark de la IA "
        + "ni una partida multijugador de ocho participantes.",115)
    _label(column,
        "Tras ejecutarlo, comparte el CSV copiado. Anota también "
        + "temperatura aproximada, brillo, batería y si aparecen "
        + "tirones. El test no puede leer temperatura física "
        + "del dispositivo.",122)

func _make_3d() -> void:
    stage = Node3D.new()
    scene_view.add_child(stage)
    var environment := WorldEnvironment.new()
    var sky := Environment.new()
    sky.background_mode = Environment.BG_COLOR
    sky.background_color = Color("#172734")
    sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    sky.ambient_light_color = Color("#c8dae4")
    sky.ambient_light_energy = 0.75
    environment.environment = sky
    stage.add_child(environment)
    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-46,-32,0)
    key.light_energy = 1.6
    stage.add_child(key)
    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.current = true
    stage.add_child(camera)
    stage_weather = Climate.build()
    stage.add_child(stage_weather)

func _change_mode(index: int) -> void:
    if index < 0 or index >= MODE_NAMES.size():
        return
    if _running:
        return
    _mode = index
    mode_picker.select(_mode)
    _show_model()
    if status != null:
        status.text = "Escenario activo: %s · listo" % MODE_NAMES[_mode]

func _change_weather(index: int) -> void:
    if index < 0 or index >= WEATHER.size():
        return
    if _running:
        return
    _weather = index
    weather_picker.select(index)
    _apply_weather()

func _show_model() -> void:
    if active_model != null:
        stage.remove_child(active_model)
        active_model.queue_free()
        active_model = null
    if _mode == 0:
        active_model = HQ.build(2,0,"operativo")
        if active_model == null:
            status.text = "ERROR: HQ V20 no se pudo generar"
            return
        camera.position = Vector3(-19.0,17.5,-21.0)
        camera.size = 20.0
    else:
        var dimension: int = [0,7,10,12][_mode]
        active_model = City.build_grid(dimension,dimension,15.5)
        camera.position = Vector3(-2.5*dimension,2.0*dimension,
            -2.5*dimension)
        camera.size = 16.5*float(dimension)
    stage.add_child(active_model)
    camera.look_at(Vector3(0.0,2.0,0.0),Vector3.UP)
    _apply_weather()

func _apply_weather() -> void:
    if stage_weather == null or active_model == null:
        return
    # This build explicitly compares WEATHER on a single genuine 3D HQ.
    # The district modes are intentionally grouped low-poly geometry.
    var hero: bool = _mode == 0
    stage_weather.visible = hero
    if hero:
        var applied: bool = Climate.apply(stage_weather,WEATHER[_weather],
            "asphalt",2,"operativo",false)
        if not applied:
            push_error("HQ climate benchmark apply failed")
        var result: Dictionary = Universal.apply(active_model,WEATHER[_weather])
        if _weather == 2 and int(result.get("snow_nodes",0)) > 0:
            for i in range(3):
                stage_weather.get_node(
                    "NieveAcumuladaCubiertaV17_%d" % i).visible = false
    if weather_picker != null:
        weather_picker.disabled = not hero

func _toggle_benchmark() -> void:
    if _running:
        _running = false
        start_button.text = "INICIAR · 3 rondas de medición"
        status.text = "Prueba detenida. Resultados parciales disponibles."
        return
    _running = true
    _iteration = 0
    _records.clear()
    _last_csv = ""
    start_button.text = "DETENER MEDICIÓN"
    mode_picker.disabled = true
    weather_picker.disabled = true
    _next_scenario()

func _next_scenario() -> void:
    if _iteration >= MODE_NAMES.size()*ROUNDS:
        _running = false
        start_button.text = "INICIAR · 3 rondas de medición"
        mode_picker.disabled = false
        weather_picker.disabled = _mode != 0
        status.text = "FINALIZADO · %d mediciones reales. Copia el CSV." % _records.size()
        _save_csv()
        return
    _mode = _iteration % MODE_NAMES.size()
    mode_picker.select(_mode)
    _show_model()
    _samples.clear()
    _phase_time = 0.0
    _frame_ui_counter = 0.0
    status.text = "Ronda %d/%d · %s · estabilizando" % [
        1+int(_iteration/MODE_NAMES.size()),ROUNDS,MODE_NAMES[_mode]]

func _process(delta: float) -> void:
    if not _running:
        return
    _phase_time += maxf(delta,0.0)
    if _phase_time > WARMUP_SECONDS:
        _samples.append(maxf(delta,0.0001)*1000.0)
    _frame_ui_counter += delta
    if _frame_ui_counter > 0.8:
        _frame_ui_counter = 0.0
        var phase: String = "estabilizando" if _phase_time < WARMUP_SECONDS else "midiendo"
        metrics.text = "%s\nFPS ahora: %d\nMuestras: %d\nTiempo: %.1f/%.1f s" % [
            phase,Engine.get_frames_per_second(),_samples.size(),
            _phase_time,WARMUP_SECONDS+SAMPLE_SECONDS]
    if _phase_time >= WARMUP_SECONDS+SAMPLE_SECONDS:
        _finish_sample()
        _iteration += 1
        _next_scenario()

func _finish_sample() -> void:
    if _samples.size()==0:
        return
    var frames: Array[float] = _samples.duplicate()
    frames.sort()
    var sum_ms := 0.0
    for ms in frames:
        sum_ms += ms
    var count: int = frames.size()
    var worst: int = maxi(1,ceili(float(count)*0.01))
    var worst_sum := 0.0
    for i in range(count-worst,count):
        worst_sum += frames[i]
    var avg_fps: float = 1000.0*float(count)/maxf(sum_ms,0.01)
    var low_fps: float = 1000.0*float(worst)/maxf(worst_sum,0.01)
    var elapsed: float = sum_ms/1000.0
    var info := {
        "round":1+int(_iteration/MODE_NAMES.size()),
        "mode":MODE_NAMES[_mode],"buildings":COUNTS[_mode],
        "frames":count,"sample_sec":elapsed,
        "avg_fps":avg_fps,"one_pct_low_fps":low_fps,
        "worst_ms":frames[count-1],"max_process_ms":
            Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
        "device":OS.get_model_name(),"os":OS.get_name(),
        "screen":str(DisplayServer.screen_get_size()),
        "weather":WEATHER[_weather] if _mode==0 else "batched_dry"
    }
    _records.append(info)
    print("TARVOKA_HQ_PHYSICAL,%s" % JSON.stringify(info))
    metrics.text = "%s\nPromedio: %.1f FPS\n1%% peor: %.1f FPS\nMáximo: %.1f ms" % [
        MODE_NAMES[_mode],avg_fps,low_fps,frames[count-1]]
    _save_csv()

func _save_csv() -> void:
    var lines := [
        "round,mode,buildings,frames,sample_sec,avg_fps,one_pct_low_fps,worst_ms,process_ms,device,os,screen,weather"
    ]
    for item in _records:
        lines.append("%d,%s,%d,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%s,%s,%s,%s" % [
            int(item["round"]),str(item["mode"]),int(item["buildings"]),
            int(item["frames"]),float(item["sample_sec"]),float(item["avg_fps"]),
            float(item["one_pct_low_fps"]),float(item["worst_ms"]),
            float(item["max_process_ms"]),str(item["device"]),
            str(item["os"]),str(item["screen"]),str(item["weather"])])
    _last_csv = "\n".join(lines)+"\n"
    var output := FileAccess.open(CSV_PATH,FileAccess.WRITE)
    if output != null:
        output.store_string(_last_csv)
        output.close()

func _copy_csv() -> void:
    if _last_csv.is_empty():
        status.text = "Aún no hay resultados; inicia la medición."
        return
    DisplayServer.clipboard_set(_last_csv)
    status.text = "CSV copiado: pégalo en el chat para analizar FPS y 1 % bajo."
