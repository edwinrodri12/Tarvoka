extends PanelContainer
class_name TarvokaCity3DPerfProbeV7

# Opt-in REAL device readings while the ACTUAL playable 3D battle is open.
# Never estimates Android frame rates from a desktop CI runner.
# No game-state writes, telemetry upload, timers or external dependencies.
# The same ORIGINAL capital cities already rendered by BattleTerrain3D
# also get native HQ V24 meshes. Measure them inside the existing opt-in FPS
# panel: nothing new is spawned, captured or added to the economy.
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
        "meshes":0,"changes":0,"peak_step_ms":0.0}
    if scene_root==null or not is_instance_valid(scene_root):
        return output
    var driver: Node=scene_root.get_node_or_null(
        "CiudadesCivilesV6_LOD_Camara")
    if driver==null:
        return output
    output["changes"]=int(driver.get("transitions"))
    output["peak_step_ms"]=float(driver.get("peak_step_ms"))
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

# Workshop readings share the same opt-in FPS panel. Each value comes
# exclusively from models that the live 3D battlefield already instantiated.
func _workshop_stats() -> Dictionary:
    var stats:Dictionary={"workshops":0,"tactical":0,"distant":0,
        "batches":0,"changes":0,"peak_step_ms":0.0}
    if scene_root==null or not is_instance_valid(scene_root):
        return stats
    var driver:Node=scene_root.get_node_or_null("TallerBlindadosLOD_Camara")
    if driver==null:
        return stats
    stats["changes"]=int(driver.get("transitions"))
    stats["peak_step_ms"]=float(driver.get("peak_step_ms"))
    var entries:Array=driver.get("_sites")
    for site in entries:
        if not is_instance_valid(site):
            continue
        stats["workshops"]=int(stats["workshops"])+1
        var profile:int=int(site.get_meta("workshop_lod_profile",2))
        if profile==1:
            stats["tactical"]=int(stats["tactical"])+1
        elif profile==2:
            stats["distant"]=int(stats["distant"])+1
        stats["batches"]=int(stats["batches"])+int(
            site.get_meta("workshop_batches",0))
    return stats

# Read-only airbase scene statistics using the same local FPS button.
func _airbase_stats() -> Dictionary:
    var stats:Dictionary={"airbases":0,"close":0,"distant":0,
        "surfaces":0,"changes":0,"peak_step_ms":0.0}
    if scene_root==null or not is_instance_valid(scene_root):
        return stats
    var driver:Node=scene_root.get_node_or_null("BaseAereaLOD_Camara")
    if driver==null:
        return stats
    stats["changes"]=int(driver.get("transitions"))
    stats["peak_step_ms"]=float(driver.get("peak_step_ms"))
    var entries:Array=driver.get("_sites")
    for site in entries:
        if not is_instance_valid(site):
            continue
        stats["airbases"]=int(stats["airbases"])+1
        if int(site.get_meta("airbase_lod_profile",0))==1:
            stats["close"]=int(stats["close"])+1
        else:
            stats["distant"]=int(stats["distant"])+1
        stats["surfaces"]=int(stats["surfaces"])+int(
            site.get_meta("airbase_mesh_surfaces",0))
    return stats

# Opt-in drone center statistics from visible, existing producer sites.
func _drone_stats() -> Dictionary:
    var output:Dictionary={"centers":0,"close":0,"far":0,
        "surfaces":0,"changes":0,"peak_step_ms":0.0}
    if scene_root==null or not is_instance_valid(scene_root):
        return output
    var driver:Node=scene_root.get_node_or_null("CentroDronesLOD_Camara")
    if driver==null:
        return output
    output["changes"]=int(driver.get("transitions"))
    output["peak_step_ms"]=float(driver.get("peak_step_ms"))
    var entries:Array=driver.get("_sites")
    for item in entries:
        if not is_instance_valid(item):
            continue
        output["centers"]=int(output["centers"])+1
        if int(item.get_meta("drone_center_lod",0))==1:
            output["close"]=int(output["close"])+1
        else:
            output["far"]=int(output["far"])+1
        output["surfaces"]=int(output["surfaces"])+int(
            item.get_meta("render_surface_count",0))
    return output

func _headquarters_stats() -> Dictionary:
    var output:Dictionary={
        "headquarters":0,"meshes":0,"surfaces":0,
        "neutral":0,"ruins":0,"tier1":0,"tier2":0,"tier3":0
    }
    if scene_root==null or not is_instance_valid(scene_root):
        return output
    # Search only the actual live city site nodes, not synthetic stress
    # models or hidden enemy HQs. This honors the renderer's fog-of-war.
    for landmark in scene_root.find_children(
            "Instalacion3D_city_*","Node3D",true,false):
        if str(landmark.get_meta("site_kind",""))!="visual_headquarters":
            continue
        # HQ.build_site supplies the ROOT itself; BattleTerrain3D only
        # renames that root to the original city-site identifier.
        var visual:Node3D=landmark as Node3D
        if visual==null or not bool(
                visual.get_meta("hq_native_geometry",false)):
            continue
        output["headquarters"]=int(output["headquarters"])+1
        output["meshes"]=int(output["meshes"])+visual.find_children(
            "*","MeshInstance3D",true,false).size()
        output["surfaces"]=int(output["surfaces"])+int(
            visual.get_meta("hq_material_surfaces",0))
        if int(visual.get_meta("visual_faction",-1))<0:
            output["neutral"]=int(output["neutral"])+1
        if int(visual.get_meta("visual_damage_stage",0))==4:
            output["ruins"]=int(output["ruins"])+1
        var tier:int=clampi(
            int(visual.get_meta("visual_tier",1)),1,3)
        var field:String="tier%d" % tier
        output[field]=int(output[field])+1
    return output

func snapshot() -> Dictionary:
    var city: Dictionary=_city_stats()
    var workshop:Dictionary=_workshop_stats()
    var airbases:Dictionary=_airbase_stats()
    var drones:Dictionary=_drone_stats()
    var headquarters:Dictionary=_headquarters_stats()
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
    var terrain_stats: Dictionary = scene_root.get_meta("render_stats",{}) if is_instance_valid(scene_root) else {}
    return {
        "terrain_build_ms":float(terrain_stats.get("chunk_build_ms_v42",0.0)),
        "terrain_height_samples":int(terrain_stats.get("height_samples_v42",0)),
        "terrain_shared_materials":int(terrain_stats.get("shared_chunk_materials_v27",0)),
        "terrain_regional_tree_groups":int(terrain_stats.get("regional_tree_groups_v49",0)),
        "terrain_regional_ridge_groups":int(terrain_stats.get("regional_ridge_groups_v49",0)),
        "terrain_extra_biome_batches":int(terrain_stats.get("biome_extra_batches",0)),
        "mixed_pigments":bool(scene_root.get_meta("mixed_pigments_v49",false)) if is_instance_valid(scene_root) else false,
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
        "lod_peak_step_ms":city["peak_step_ms"],
        "workshops":workshop["workshops"],
        "workshop_lod_tactical":workshop["tactical"],
        "workshop_lod_distant":workshop["distant"],
        "workshop_batches":workshop["batches"],
        "workshop_lod_changes":workshop["changes"],
        "workshop_peak_step_ms":workshop["peak_step_ms"],
        "airbases":airbases["airbases"],
        "airbase_lod_close":airbases["close"],
        "airbase_lod_distant":airbases["distant"],
        "airbase_surfaces":airbases["surfaces"],
        "airbase_lod_changes":airbases["changes"],
        "airbase_peak_step_ms":airbases["peak_step_ms"],
        "drone_centers":drones["centers"],
        "drone_lod_close":drones["close"],
        "drone_lod_far":drones["far"],
        "drone_surfaces":drones["surfaces"],
        "drone_lod_changes":drones["changes"],
        "drone_peak_step_ms":drones["peak_step_ms"],
        "headquarters":headquarters["headquarters"],
        "headquarters_meshes":headquarters["meshes"],
        "headquarters_surfaces":headquarters["surfaces"],
        "headquarters_neutral":headquarters["neutral"],
        "headquarters_ruins":headquarters["ruins"],
        "headquarters_tier1":headquarters["tier1"],
        "headquarters_tier2":headquarters["tier2"],
        "headquarters_tier3":headquarters["tier3"],
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
    var workshop:Dictionary=_workshop_stats()
    var airbases:Dictionary=_airbase_stats()
    var drones:Dictionary=_drone_stats()
    var headquarters:Dictionary=_headquarters_stats()
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
            +"Mallas ciudad %d · cambios %d · pico %.1f ms\n" % [
                stats["meshes"],stats["changes"],stats["peak_step_ms"]]
            +"Talleres %d · detalle cercano/lejos %d/%d · pico %.1f ms" % [
                workshop["workshops"],workshop["tactical"],
                workshop["distant"],workshop["peak_step_ms"]]
            +"\nBases aéreas %d · cerca/lejos %d/%d · pico %.1f ms" % [
                airbases["airbases"],airbases["close"],airbases["distant"],
                airbases["peak_step_ms"]]
            +"\nCentros drones %d · cerca/lejos %d/%d · pico %.1f ms" % [
                drones["centers"],drones["close"],drones["far"],
                drones["peak_step_ms"]]
            +("\nCuarteles HQ V24 %d · mallas %d · superficies %d"
              +" · neutros %d · ruinas %d") % [
                headquarters["headquarters"],headquarters["meshes"],
                headquarters["surfaces"],headquarters["neutral"],
                headquarters["ruins"]])

func _process(delta: float) -> void:
    if not visible:
        return
    _elapsed+=maxf(0.0,delta)
    if _elapsed<INTERVAL:
        return
    _elapsed=fmod(_elapsed,INTERVAL)
    refresh_once()
