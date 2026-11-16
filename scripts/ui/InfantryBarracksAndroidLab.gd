extends Node3D
class_name TarvokaInfantryBarracksAndroidLab

# Standalone Android benchmark using the ACTUAL native V1-V5 Godot meshes.
# This is NOT the normal TARVOKA game scene, and does not edit saves or rules.
# Only device-side measurements can establish real Android performance.
const BarracksV1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const BarracksV2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const BarracksV3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const BarracksV4=preload("res://scripts/ui/InfantryBarracksRearFacadeV4.gd")
const BarracksV5=preload("res://scripts/ui/InfantryBarracksEntranceYardV5.gd")
const WARMUP_FRAMES=45
const SAMPLE_FRAMES=180
const OUTPUT="user://infantry_barracks_android_benchmark.json"

var _root: Node3D
var _camera: Camera3D
var _models: Array[Node3D]=[]
var _title: Label
var _status: Label
var _level: int=3
var _count: int=1
var _faction: int=0
var _damage: int=0
var _far_lod: bool=false
var _frame: int=0
var _sample_count: int=0
var _sample_seconds: float=0.0
var _draw_call_sum: float=0.0
var _frame_ms: Array[float]=[]
var _reports: Array[Dictionary]=[]
var _last_result: Dictionary={}

func _ready() -> void:
    _setup_world()
    _setup_buttons()
    set_scenario(3,1,0,0,false)

func _setup_world() -> void:
    _root=Node3D.new()
    _root.name="CuartelesInfanteriaParaPruebaAndroid"
    add_child(_root)
    _camera=Camera3D.new()
    _camera.name="CamaraIsometricaAndroid"
    _camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    _camera.current=true
    add_child(_camera)
    var sun:=DirectionalLight3D.new()
    sun.name="LuzPrincipalPrueba"
    sun.rotation_degrees=Vector3(-48,-34,0)
    sun.light_energy=1.30
    sun.shadow_enabled=false
    add_child(sun)
    var base:=MeshInstance3D.new()
    base.name="TerrenoNeutralPrueba"
    var plane:=PlaneMesh.new()
    plane.size=Vector2(130.0,130.0)
    base.mesh=plane
    base.position.y=-0.28
    var ground:=StandardMaterial3D.new()
    ground.albedo_color=Color("#435753")
    ground.roughness=0.95
    base.material_override=ground
    add_child(base)

func _button(parent: Control,title: String,callback: Callable) -> void:
    var b:=Button.new()
    b.text=title
    b.custom_minimum_size=Vector2(102,43)
    b.pressed.connect(callback)
    parent.add_child(b)

func _setup_buttons() -> void:
    var layer:=CanvasLayer.new()
    layer.name="UIPruebasInfanteriaAndroid"
    add_child(layer)
    var controls:=Control.new()
    controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(controls)
    var panel:=PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    controls.add_child(panel)
    var column:=VBoxContainer.new()
    column.add_theme_constant_override("separation",5)
    panel.add_child(column)
    _title=Label.new()
    _title.add_theme_font_size_override("font_size",19)
    column.add_child(_title)
    var row1:=HBoxContainer.new()
    row1.add_theme_constant_override("separation",5)
    column.add_child(row1)
    _button(row1,"Nivel 1",func(): set_scenario(1,_count,_faction,_damage,_far_lod))
    _button(row1,"Nivel 2",func(): set_scenario(2,_count,_faction,_damage,_far_lod))
    _button(row1,"Nivel 3",func(): set_scenario(3,_count,_faction,_damage,_far_lod))
    _button(row1,"1 edificio",func(): set_scenario(_level,1,_faction,_damage,_far_lod))
    _button(row1,"4 edificios",func(): set_scenario(_level,4,_faction,_damage,_far_lod))
    _button(row1,"9 edificios",func(): set_scenario(_level,9,_faction,_damage,_far_lod))
    var row2:=HBoxContainer.new()
    row2.add_theme_constant_override("separation",5)
    column.add_child(row2)
    _button(row2,"LOD cercano",func(): set_scenario(_level,_count,_faction,_damage,false))
    _button(row2,"LOD lejano",func(): set_scenario(_level,_count,_faction,_damage,true))
    _button(row2,"Facción +",func(): set_scenario(_level,_count,(_faction+1)%8,_damage,_far_lod))
    _button(row2,"Daño +",func(): set_scenario(_level,_count,_faction,(_damage+1)%5,_far_lod))
    _button(row2,"Copiar datos",copy_report)
    _button(row2,"Guardar",save_report)
    _status=Label.new()
    _status.add_theme_font_size_override("font_size",14)
    column.add_child(_status)

func set_scenario(level: int,count: int,faction: int,damage: int,far_lod: bool) -> void:
    _level=clampi(level,1,3)
    _count=1 if count<=1 else 4 if count<=4 else 9
    _faction=clampi(faction,0,7)
    _damage=clampi(damage,0,4)
    _far_lod=far_lod
    _frame=0
    _sample_count=0
    _sample_seconds=0.0
    _draw_call_sum=0.0
    _frame_ms.clear()
    for old in _root.get_children():
        _root.remove_child(old)
        old.queue_free()
    _models.clear()
    var columns: int=ceili(sqrt(float(_count)))
    var rows: int=ceili(float(_count)/float(columns))
    var span_x: float=float(columns-1)*18.5
    var span_z: float=float(rows-1)*15.5
    var focus:=Vector3(span_x*0.5,2.15,span_z*0.5)
    _camera.position=focus+Vector3(26.0+float(columns)*7.0,
        26.0+float(columns)*6.0,29.0+float(rows)*7.0)
    _camera.look_at(focus,Vector3.UP)
    _camera.size=22.0+maxf(span_x,span_z)*1.35
    for i in range(_count):
        var model: Node3D=BarracksV1.build(_level,_faction,_damage)
        if model==null or not BarracksV2.apply(model,_level,_faction,_damage) or \
                not BarracksV3.apply(model,_level,_faction,_damage) or \
                not BarracksV4.apply(model,_level,_faction,_damage) or \
                not BarracksV5.apply(model,_level,_faction,_damage):
            push_error("Cuartel Android: fallo al construir V1-V5")
            if model!=null:
                model.free()
            continue
        model.position=Vector3(float(i%columns)*18.5,
            0,float(i/columns)*15.5)
        _root.add_child(model)
        BarracksV5.set_detail_lod(model,not _far_lod)
        _models.append(model)
    _title.text="TARVOKA · INFANTERÍA 3D · N%d · %d edificios · LOD %s" % [
        _level,_models.size(),"LEJANO" if _far_lod else "CERCANO"]
    _status.text="Preparando medición real. Rotar entre LOD cercano y lejano para comparar."

func model_mesh_stats() -> Dictionary:
    var visible_meshes: int=0
    var total_meshes: int=0
    var queue: Array[Node]=[_root]
    while not queue.is_empty():
        var current: Node=queue.pop_back()
        for child in current.get_children():
            queue.append(child)
            if child is MeshInstance3D:
                total_meshes+=1
                if (child as MeshInstance3D).visible:
                    visible_meshes+=1
    return {"total_meshes":total_meshes,
        "visible_meshes":visible_meshes,
        "hidden_meshes":total_meshes-visible_meshes}

func _process(delta: float) -> void:
    _frame+=1
    if _frame<=WARMUP_FRAMES or _sample_count>=SAMPLE_FRAMES:
        return
    _sample_count+=1
    var seconds: float=maxf(0.000001,delta)
    _sample_seconds+=seconds
    _frame_ms.append(seconds*1000.0)
    _draw_call_sum+=Performance.get_monitor(
        Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
    if _sample_count%45==0:
        _status.text="Muestra %d/%d · %.1f FPS" % [
            _sample_count,SAMPLE_FRAMES,Engine.get_frames_per_second()]
    if _sample_count==SAMPLE_FRAMES:
        _finish_measurement()

func _finish_measurement() -> void:
    var sorted: Array[float]=_frame_ms.duplicate()
    sorted.sort()
    var p95_index: int=clampi(ceili(float(sorted.size())*0.95)-1,
        0,sorted.size()-1)
    var result: Dictionary={
        "platform":OS.get_name(),
        "android_hardware_tested":OS.get_name()=="Android",
        "level":_level,"count":_models.size(),
        "faction":_faction,"damage":_damage,
        "lod":"far" if _far_lod else "near",
        "warmup_frames":WARMUP_FRAMES,
        "sample_frames":_sample_count,
        "fps_mean":snappedf(float(_sample_count)/_sample_seconds,0.1),
        "frame_p95_ms":snappedf(sorted[p95_index],0.01),
        "draw_calls_mean":snappedf(_draw_call_sum/float(_sample_count),0.1),
        "memory_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
        "mesh_stats":model_mesh_stats(),
        "timestamp_utc":Time.get_datetime_string_from_system(true)
    }
    _last_result=result
    _reports.append(result.duplicate(true))
    _status.text="%.1f FPS · %.0f draws · %.2f ms p95 · Copiar datos" % [
        float(result["fps_mean"]),float(result["draw_calls_mean"]),
        float(result["frame_p95_ms"])]
    save_report()

func _report_json() -> String:
    return JSON.stringify({
        "kind":"TARVOKA Infantry Barracks V5 Android benchmark",
        "notice":"Only reports with android_hardware_tested=true verify mobile device performance.",
        "reports":_reports
    },"\t")

func copy_report() -> void:
    DisplayServer.clipboard_set(_report_json())
    if _status!=null:
        _status.text="Datos copiados: pégalos en el chat para compararlos."

func save_report() -> void:
    var file: FileAccess=FileAccess.open(OUTPUT,FileAccess.WRITE)
    if file==null:
        push_error("Cuartel Android: no se pudo escribir el informe.")
        return
    file.store_string(_report_json())
    file.close()
