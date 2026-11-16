extends Node3D
class_name TarvokaG11AndroidPerfLab

# Isolated G11 Android benchmark scene, NOT loaded by the normal campaign.
# The actual device measures FPS and draw calls; it does not claim any score
# until it runs on hardware. No game rules, player data or saves touched.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const AuditV33 = preload("res://scripts/ui/G11FinalAuditV33.gd")
const SAMPLE_FRAMES := 180
const WARMUP_FRAMES := 45
const OUTPUT := "user://g11_android_performance.json"
var _models: Array[Node3D] = []
var _group: Node3D
var _camera: Camera3D
var _label: Label
var _message: Label
var _units: int = 8
var _quality: int = 10
var _total_frames: int = 0
var _sample_frames: int = 0
var _sample_time: float = 0.0
var _draw_calls: float = 0.0
var _last_report: Dictionary = {}
var _history: Array[Dictionary] = []
var _frame_ms: Array[float] = []
var _units_validated: int = 0
var _lod_validated: bool = false

func _ready() -> void:
    _create_environment()
    _create_controls()
    set_scenario(8,10)

func _create_environment() -> void:
    _group = Node3D.new()
    _group.name = "G11AndroidUnits"
    add_child(_group)
    _camera = Camera3D.new()
    _camera.current = true
    _camera.fov = 61.0
    add_child(_camera)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-50,-35,0)
    light.light_energy = 1.25
    light.shadow_enabled = false
    add_child(light)
    var ground := MeshInstance3D.new()
    ground.name = "G11AndroidGround"
    var plane := PlaneMesh.new()
    plane.size = Vector2(48,48)
    ground.mesh = plane
    ground.position = Vector3(9,-0.31,9)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#455451")
    material.roughness = 0.90
    ground.material_override = material
    add_child(ground)

func _make_button(parent: Control, title: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = title
    button.custom_minimum_size = Vector2(112,43)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _create_controls() -> void:
    var overlay := CanvasLayer.new()
    overlay.name = "G11RendimientoAndroidUI"
    add_child(overlay)
    var shell := Control.new()
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay.add_child(shell)
    var panel := PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    panel.custom_minimum_size = Vector2(0,132)
    shell.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    _label = Label.new()
    _label.text = "TARVOKA · G11 · diagnóstico de rendimiento"
    _label.add_theme_font_size_override("font_size",19)
    column.add_child(_label)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation",6)
    column.add_child(row)
    _make_button(row,"8 unidades",func(): set_scenario(8,_quality))
    _make_button(row,"32 unidades",func(): set_scenario(32,_quality))
    _make_button(row,"64 unidades",func(): set_scenario(64,_quality))
    _make_button(row,"LOD cercano",func(): set_scenario(_units,10))
    _make_button(row,"LOD lejano",func(): set_scenario(_units,8))
    _make_button(row,"Guardar",save_report)
    _make_button(row,"Copiar",copy_report)
    _message = Label.new()
    _message.text = "Iniciando captura…"
    _message.add_theme_font_size_override("font_size",14)
    column.add_child(_message)

func set_scenario(unit_count: int, detail: int) -> void:
    _units = clampi(unit_count,1,96)
    _quality = 8 if detail <= 8 else 10
    _total_frames = 0
    _sample_frames = 0
    _sample_time = 0
    _draw_calls = 0
    _frame_ms.clear()
    _units_validated = 0
    _lod_validated = false
    for old in _group.get_children():
        _group.remove_child(old)
        old.queue_free()
    _models.clear()
    var columns: int = 8
    var rows: int = ceili(float(_units)/float(columns))
    var width: float = float(columns-1)*2.70
    var depth: float = float(rows-1)*2.95
    _camera.position = Vector3(width*0.5+18,17.0+float(rows)*2.0,
        depth*0.5+22)
    _camera.look_at(Vector3(width*0.5,0.65,depth*0.5))
    for i in range(_units):
        var unit: Node3D = Models.build("mlrs",i%8,false,_quality)
        if unit == null:
            push_error("G11 Android Lab: model not built for index %d" % i)
            continue
        unit.position += Vector3(float(i%columns)*2.70,0,
            float(i/columns)*2.95)
        unit.rotation_degrees.y = float(i%4)*90.0
        _group.add_child(unit)
        _models.append(unit)
        if AuditV33.verify_tactical_model(unit,_quality):
            _units_validated+=1
    _lod_validated=_units_validated==_units
    if not _lod_validated:
        push_error("G11 Android Lab: model detail does not match requested true tactical LOD")
    _label.text = "G11 en Android · %d unidades · LOD %d" % [_units,_quality]
    _message.text = ("Preparando medición nativa… (LOD de batalla verificado)"
        if _lod_validated else "Error: alguno de los modelos no coincide con el LOD elegido")

func _process(delta: float) -> void:
    _total_frames += 1
    for i in range(mini(8,_models.size())):
        Models.pose_model("mlrs",_models[i],"attack",
            fmod(float(_total_frames)*0.02+float(i)*0.13,1.0),Vector2i(1,0))
    if _total_frames <= WARMUP_FRAMES or _sample_frames >= SAMPLE_FRAMES:
        return
    _sample_frames += 1
    var frame_time: float=maxf(0.000001,delta)
    _sample_time += frame_time
    _frame_ms.append(frame_time*1000.0)
    _draw_calls += Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    if _sample_frames % 30 == 0:
        _message.text = "Muestra %d/%d · %.1f FPS actuales" % [
            _sample_frames,SAMPLE_FRAMES,Engine.get_frames_per_second()]
    if _sample_frames == SAMPLE_FRAMES:
        var fps: float = float(_sample_frames)/_sample_time
        var draw_avg: float = _draw_calls/float(SAMPLE_FRAMES)
        var sorted: Array[float]=_frame_ms.duplicate()
        sorted.sort()
        var p95_frame_ms: float=sorted[mini(sorted.size()-1,
            ceili(float(sorted.size())*0.95)-1)]
        _last_report = {
            "device_platform":OS.get_name(),
            "renderer":"Godot 4.3 scene measured on local device",
            "units":_units,
            "lod":_quality,
            "sample_type":"real mobile/tactical models, NOT hero sculpture",
            "verified_tactical_models":_units_validated,
            "lod_validated":_lod_validated,
            "samples":SAMPLE_FRAMES,
            "fps_mean":snappedf(fps,0.1),
            "frame_mean_ms":snappedf(_sample_time*1000.0/float(SAMPLE_FRAMES),0.01),
            "draw_calls_mean":snappedf(draw_avg,0.1),
            "frame_p95_ms":snappedf(p95_frame_ms,0.01),
            "memory_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
            "date_utc":Time.get_datetime_string_from_system(true),
            "hardware_tested":OS.get_name()=="Android"
        }
        _history.append(_last_report.duplicate(true))
        _message.text = "%.1f FPS · %.2f ms/fotograma · %.0f draw calls · toca Guardar" % [
            fps,_sample_time*1000.0/float(SAMPLE_FRAMES),draw_avg]
        save_report()

func _report_json() -> String:
    var payload: Dictionary = {
        "platform":OS.get_name(),
        "kind":"G11 native tactical LOD visual benchmark",
        "note":"Hardware Android performance is confirmed only when platform is Android; desktop/software GL results are not mobile FPS",
        "tests":_history
    }
    return JSON.stringify(payload,"\t")

func copy_report() -> void:
    DisplayServer.clipboard_set(_report_json())
    if _message != null:
        _message.text = "Resultados copiados. Pégalos en el chat para analizarlos."

func save_report() -> void:
    var file: FileAccess = FileAccess.open(OUTPUT,FileAccess.WRITE)
    if file == null:
        push_error("G11 Android Lab: failed to open user JSON")
        if _message != null:
            _message.text = "Error: no pude guardar el informe"
        return
    file.store_string(_report_json())
    file.close()
    if _sample_frames >= SAMPLE_FRAMES and _message != null:
        _message.text += " · informe guardado"
