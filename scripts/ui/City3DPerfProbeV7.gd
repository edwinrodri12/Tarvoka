extends PanelContainer
class_name TarvokaCity3DPerfProbeV7

# Opt-in REAL device readings while the ACTUAL playable 3D battle is open.
# Never estimates Android frame rates from a desktop CI runner.
# No game-state writes, telemetry upload, timers or external dependencies.
const INTERVAL: float=0.50
const MAX_SAMPLES: int=180
var readout: Label
var scene_root: Node3D=null
var _elapsed: float=0.0
var _samples: Array[float]=[]
var _peak_meshes: int=0

func _ready() -> void:
    name="DiagnosticoCiudades3DAndroidV7"
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    var surface:=StyleBoxFlat.new()
    surface.bg_color=Color(0.025,0.06,0.085,0.90)
    surface.border_color=Color("#D9BA71")
    surface.set_border_width_all(1)
    surface.set_corner_radius_all(6)
    surface.content_margin_left=9.0
    surface.content_margin_right=9.0
    surface.content_margin_top=5.0
    surface.content_margin_bottom=5.0
    add_theme_stylebox_override("panel",surface)
    readout=Label.new()
    readout.name="LecturasRealesDelDispositivo"
    readout.mouse_filter=Control.MOUSE_FILTER_IGNORE
    readout.add_theme_font_size_override("font_size",12)
    readout.add_theme_color_override("font_color",Color("#DFEDF2"))
    readout.text="FPS: recopilando muestras..."
    add_child(readout)
    set_process(false)
    hide()

func attach_battle(terrain: Node3D) -> void:
    scene_root=terrain
    reset_samples()
    if visible:
        refresh_once()

func reset_samples() -> void:
    _samples.clear()
    _elapsed=0.0
    _peak_meshes=0
    if readout!=null:
        readout.text="FPS: recopilando muestras..."

func set_recording(active: bool) -> void:
    visible=active and scene_root!=null and is_instance_valid(scene_root)
    set_process(visible)
    if visible:
        refresh_once()

func toggle_recording() -> void:
    set_recording(not visible)

func _city_stats() -> Dictionary:
    var output: Dictionary={"cities":0,"lod0":0,"lod1":0,"lod2":0,
        "meshes":0,"changes":0}
    if scene_root==null or not is_instance_valid(scene_root):
        return output
    var driver: Node=scene_root.get_node_or_null(
        "CiudadesCivilesV6_LOD_Camara")
    if driver==null:
        return output
    output["changes"]=int(driver.get("transitions"))
    var entries: Array=driver.get("cities")
    for city in entries:
        if not is_instance_valid(city):
            continue
        output["cities"]=int(output["cities"])+1
        var lod: int=clampi(int(city.get_meta("city_lod",2)),0,2)
        var key: String="lod%d" % lod
        output[key]=int(output[key])+1
        output["meshes"]=int(output["meshes"])+int(
            city.get_meta("actual_3d_meshes",0))
    return output

func snapshot() -> Dictionary:
    var city: Dictionary=_city_stats()
    var current_fps: float=_samples[-1] if not _samples.is_empty() else 0.0
    var samples: Array[float]=_samples.duplicate()
    samples.sort()
    var average: float=0.0
    for value in samples:
        average+=value
    if not samples.is_empty():
        average/=float(samples.size())
    var low: float=0.0
    if not samples.is_empty():
        # 5th-percentile (low-tail) FPS, not a falsely claimed Android FPS
        # from off-device rendering. Each sample is Engine FPS at runtime.
        var idx: int=clampi(
            int(floor(float(samples.size()-1)*0.05)),0,samples.size()-1)
        low=samples[idx]
    return {
        "source":"Godot Engine FPS on the device running this scene",
        "sample_count":samples.size(),
        "fps_current":current_fps,
        "fps_average":snappedf(average,0.1),
        "fps_low_5pct":snappedf(low,0.1),
        "cities":city["cities"],
        "city_lod0":city["lod0"],"city_lod1":city["lod1"],
        "city_lod2":city["lod2"],"city_meshes":city["meshes"],
        "city_peak_meshes":_peak_meshes,
        "city_lod_changes":city["changes"],
        "device":OS.get_name(),
    }

func refresh_once() -> void:
    if scene_root==null or not is_instance_valid(scene_root):
        return
    var fps: float=Engine.get_frames_per_second()
    if fps>0.0:
        _samples.append(fps)
        if _samples.size()>MAX_SAMPLES:
            _samples.pop_front()
    var stats: Dictionary=_city_stats()
    _peak_meshes=maxi(_peak_meshes,int(stats["meshes"]))
    var count: int=_samples.size()
    var total: float=0.0
    var low: float=fps
    for value in _samples:
        total+=value
        low=minf(low,value)
    var mean: float=total/float(count) if count>0 else 0.0
    if readout!=null:
        readout.text=(
            "FPS %d · media %.1f · mínimo %.0f\n" % [
                roundi(fps),mean,low]
            +"Ciudades %d · LOD cercano/medio/lejos %d/%d/%d\n" % [
                stats["cities"],stats["lod0"],stats["lod1"],stats["lod2"]]
            +"Mallas %d · cambios LOD %d · muestras %d" % [
                stats["meshes"],stats["changes"],count])

func _process(delta: float) -> void:
    if not visible:
        return
    _elapsed+=maxf(0.0,delta)
    if _elapsed<INTERVAL:
        return
    _elapsed=fmod(_elapsed,INTERVAL)
    refresh_once()
