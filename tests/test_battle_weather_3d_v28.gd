extends SceneTree

# Production battle-3D integration QA. Uses the *same* Godot renderer,
# G09 V25 art and 3D viewer used for actual Android tactics.
const Renderer = preload("res://scripts/ui/BattleTerrain3D.gd")
const Viewer = preload("res://scripts/ui/Battle3DMapView.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Coating = preload("res://scripts/ui/WeatherCoating3D.gd")
const LOD = preload("res://scripts/ui/TankBattleLOD27.gd")

func _initialize() -> void:
    call_deferred("_run")

func _unit(id: String,pos: Vector2i,side: int = 0) -> Dictionary:
    return {"id":id,"role":"tank","faction":side,"hp":10,"pos":pos,
        "vision":5,"move_points":4,"attack":5,"acted":false}

func _model(scene: Node3D,id: String) -> Node3D:
    var unit: Node3D = scene.find_child("Unidad3D_"+id,true,false) as Node3D
    assert(unit != null)
    return unit

func _run() -> void:
    var state: Dictionary = Session.start([
        _unit("T0",Vector2i(1,1)),
        _unit("T1",Vector2i(2,1)),
        _unit("SECRET",Vector2i(8,6),1)
    ],Scenarios.terrain(0),0,true,false,false,false,false)
    state["weather"] = "snow"
    state["economy"] = {"sites":[
        {"kind":"city","pos":Vector2i(1,2),"owner":0},
        {"kind":"city","pos":Vector2i(8,6),"owner":1}
    ]}
    var preserved: Dictionary = state.duplicate(true)
    var scene: Node3D = Renderer.build(state,"T0",12.0,true)
    assert(scene != null)
    root.add_child(scene)
    assert(scene.get_meta("battle_weather") == "snow")
    var units: Dictionary = scene.get_meta("render_stats")["units"]
    assert(units["g09_v25"] == 1)
    assert(units["weather_models"] >= 2)
    assert(units["snow_meshes"] > 0)
    assert(units["snow_triangles"] <= Coating.MAX_SNOW_TRIANGLES +
        7*Coating.MAX_ECO_SNOW_TRIANGLES)
    assert(_model(scene,"T0").get_meta("weather_coating")["mode"] == "snow")
    assert(int(_model(scene,"T0").get_meta("weather_coating")["snow_nodes"]) <=
        Coating.MAX_SNOW_NODES)
    assert(int(_model(scene,"T1").get_meta("weather_coating")["snow_nodes"]) <=
        Coating.MAX_ECO_SNOW_NODES)
    assert(scene.find_child("Unidad3D_SECRET",true,false) == null)
    var visible_hq: Dictionary = scene.get_meta("battle_hq_weather_stats",{})
    assert(visible_hq["visible"] == 1)
    assert(int(visible_hq["snow_meshes"]) <= Coating.MAX_ECO_SNOW_NODES)
    assert(scene.find_child("CuartelGeneralVisible_1_2",true,false) != null)
    assert(scene.find_child("CuartelGeneralVisible_8_6",true,false) == null)
    assert(state == preserved)

    # LOD changes MUST release previous weather meshes and never reveal
    # hidden enemies, add HQs outside allowed zoom, or mutate board state.
    var far: Dictionary = Renderer.refresh_unit_lod(scene,state,"T0",55.0,true)
    assert(far["weather_models"] == 0 and far["snow_meshes"] == 0)
    assert(scene.get_meta("battle_hq_weather_stats")["visible"] == 0)
    assert(scene.find_child(Coating.SNOW_NODE,true,false) == null)
    assert(scene.find_child("Unidad3D_SECRET",true,false) == null)
    var medium: Dictionary = Renderer.refresh_unit_lod(scene,state,"T0",29.0,true)
    assert(medium["g09_v25"] == 0)
    assert(medium["weather_models"] >= 2)
    assert(int(medium["snow_meshes"]) <=
        int(medium["weather_models"])*Coating.MAX_ECO_SNOW_NODES)
    assert(scene.get_meta("battle_hq_weather_stats")["visible"] == 0)
    var hero: Dictionary = Renderer.refresh_unit_lod(scene,state,"T0",12.0,true)
    assert(hero["g09_v25"] == 1)
    assert(scene.get_meta("battle_hq_weather_stats")["visible"] == 1)
    assert(scene.find_child("Unidad3D_SECRET",true,false) == null)
    assert(state == preserved)
    scene.free()

    var rain: Dictionary = state.duplicate(true)
    rain["weather"] = "rain"
    var wet: Node3D = Renderer.build(rain,"T0",12.0,true)
    assert(wet != null)
    root.add_child(wet)
    var rstats: Dictionary = wet.get_meta("render_stats")["units"]
    assert(rstats["weather"] == "rain")
    assert(rstats["weather_models"] >= 2)
    assert(rstats["snow_meshes"] == 0)
    assert(_model(wet,"T0").get_meta("weather_coating")["wet"] > 0)
    assert(wet.get_meta("battle_hq_weather_stats")["wet_models"] > 0)
    assert(wet.find_child("Unidad3D_SECRET",true,false) == null)
    wet.free()

    # Standalone defaults to clear; invalid climate cannot cause a new
    # visual state. Explicitly exported weather is shared by both sides.
    var clear: Dictionary = state.duplicate(true)
    clear.erase("weather")
    var original: Node3D = Renderer.build(clear,"T0",29.0,false)
    assert(original != null)
    assert(original.get_meta("render_stats")["units"]["weather_models"] == 0)
    assert(original.get_meta("battle_weather") == "clear")
    original.free()
    clear["weather"] = "blizzard"
    assert(Renderer._weather(clear) == "clear")

    # Real UI view stays synchronized when opening a new battle and
    # supports snow/clear/rain transitions without changing game state.
    var viewer := Viewer.new()
    root.add_child(viewer)
    assert(viewer.open_from_state(state,"T0"))
    assert(viewer._scene.get_meta("battle_weather") == "snow")
    assert(viewer.stats_label.text.contains("NIEVE"))
    for _i in range(5):
        await process_frame
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var winter_image: Image = viewer.preview.get_texture().get_image()
    assert(not winter_image.is_empty())
    assert(winter_image.save_png("res://artifacts/tarvoka_battle_weather_snow_3d.png") == OK)
    assert(viewer.open_from_state(rain,"T0"))
    assert(viewer.stats_label.text.contains("LLUVIA"))
    assert(viewer._scene.get_meta("battle_weather") == "rain")
    for _i in range(5):
        await process_frame
    assert(viewer.preview.get_texture().get_image().save_png(
        "res://artifacts/tarvoka_battle_weather_rain_3d.png") == OK)
    assert(viewer.open_from_state(clear,"T0"))
    assert(viewer.stats_label.text.contains("DESPEJADO"))
    assert(viewer._scene.get_meta("battle_weather") == "clear")
    assert(viewer.weather_preview_picker.item_count == 4)
    assert(viewer.weather_preview_picker.selected == 0)
    var real_state: Dictionary = viewer._state_snapshot.duplicate(true)
    var old_camera: float = viewer._camera_size
    var old_yaw: float = viewer._yaw
    # Public PC/Android Web demo can PREVIEW rain/snow even on legacy
    # sessions which did not yet have the climatic game modes. Never saves
    # this visual-only setting in gameplay state.
    viewer._choose_visual_weather(3)
    assert(viewer._scene.get_meta("battle_weather") == "snow")
    assert(viewer.stats_label.text.contains("VISTA ARTÍSTICA"))
    assert(viewer._camera_size == old_camera and viewer._yaw == old_yaw)
    assert(viewer._state_snapshot == real_state)
    viewer._refresh_g09_lod()
    assert(viewer._scene.get_meta("render_stats")["units"]["weather"] == "snow")
    viewer._choose_visual_weather(2)
    assert(viewer._scene.get_meta("battle_weather") == "rain")
    assert(viewer._state_snapshot == real_state)
    viewer._choose_visual_weather(0)
    assert(viewer._scene.get_meta("battle_weather") == "clear")
    assert(not viewer.stats_label.text.contains("VISTA ARTÍSTICA"))
    assert(viewer._state_snapshot == real_state)
    viewer.close_view()
    viewer.queue_free()
    assert(state == preserved)

    # Large map preserves fog: no precipitation over unexplored sectors,
    # and zoomed-out modes never instantiate hundreds of snowy meshes.
    var big: Dictionary = Session.start([
        _unit("T0",Vector2i(2,2)),
        _unit("SECRET",Vector2i(37,27),1)
    ],Scenarios.terrain(0,Vector2i(40,30)),0,true,false,false,false,false)
    big["weather"] = "snow"
    var large: Node3D = Renderer.build(big,"T0",60.0,false)
    assert(large != null)
    assert(large.get_meta("board_size") == Vector2i(40,30))
    assert(large.get_meta("render_stats")["units"]["snow_meshes"] == 0)
    assert(large.find_child("Unidad3D_SECRET",true,false) == null)
    assert(large.get_meta("render_stats")["unknown"] > 0)
    large.free()
    print("PASS BATTLE_WEATHER_3D: G09 V25 rain/snow, real command HQ, fog 40x30, limits, LOD, viewer and zero state mutation")
    quit(0)
