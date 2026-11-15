extends SceneTree

# Godot 4.3 native visual QA: 8 factions, 5 damage levels, correct
# per-panel roof supports, rear facade, and no floating rooftop equipment.
# This is a 3D model review, NOT an Android FPS benchmark.
const Airbase=preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar=preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6=preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7=preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const V8=preload("res://scripts/ui/AirbaseFinishV8.gd")
const V9=preload("res://scripts/ui/AirbaseDetailV9.gd")
const V10=preload("res://scripts/ui/AirbaseStructureV10.gd")
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _shot(studio: Control,name: String) -> void:
    var capture: Image=studio.preview.get_texture().get_image()
    assert(capture!=null and capture.get_width()>=640)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(capture.save_png(
        "res://artifacts/tarvoka_airbase_v10_"+name+".png")==OK)

func _make(tier: int,faction: int,damage: int,add_v10: bool=true) -> Node3D:
    var model: Node3D=Airbase.build(tier,faction,damage)
    assert(model!=null)
    assert(Hangar.apply(model,tier,faction,damage))
    assert(V6.apply(model,tier,faction,damage))
    assert(V7.apply(model,tier,faction,damage))
    assert(V8.apply(model,tier,faction,damage))
    assert(V9.apply(model,tier,faction,damage))
    if add_v10:
        assert(V10.apply(model,tier,faction,damage))
    return model

func _count_node(root_node: Node,label: String) -> int:
    var total: int=1 if str(root_node.name)==label else 0
    for child in root_node.get_children():
        total+=_count_node(child,label)
    return total

func _assert_equipment_seated(model: Node3D,damage: int) -> void:
    var hangar: Node3D=model.find_child("HangarPrincipalV1",true,false) as Node3D
    if hangar==null:
        return
    for child in hangar.get_children():
        var name: String=str(child.name)
        if not name.begins_with("ExtractorCubierta_") and not name.begins_with(
                "RejillaExtractor_") and not name.begins_with(
                "PanelFotovoltaico_"):
            continue
        var mesh: MeshInstance3D=child as MeshInstance3D
        assert(mesh!=null)
        var index: int=V10._segment_for_x(mesh.position.x)
        if V10._has_roof(index,damage):
            assert(mesh.visible)
            var expected_y: float=V10._roof_y(mesh.position.x)
            var offset: float=0.11 if name.begins_with(
                "ExtractorCubierta_") else 0.245 if name.begins_with(
                "RejillaExtractor_") else 0.044
            assert(absf(mesh.position.y-(expected_y+offset))<0.002)
        else:
            assert(not mesh.visible)

func _run() -> void:
    assert(V10._has_roof(6,0))
    assert(not V10._has_roof(6,2))
    assert(V10._has_roof(8,2))
    assert(not V10._has_roof(3,3))
    assert(not V10._has_roof(7,3))
    assert(V10._has_roof(8,3))

    var configurations:=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=_make(2,faction,damage)
            assert(not V10.apply(model,2,faction,damage))
            assert(model.get_meta("tarvoka_airbase_v10",false))
            assert(_count_node(model,V10.STAGE_NAME)==1)
            var stats: Dictionary=model.get_meta("tarvoka_airbase_v10_stats",{})
            assert(stats["damage"]==damage)
            assert(stats["faction"]==faction)
            assert(stats["level"]==2)
            var expected: int=0 if damage==4 else 8 if damage==3 else 12 if damage==2 else 14
            assert(stats["supported_roof_segments"]==expected)
            assert(stats["curved_ribs"]==expected*3)
            assert(stats["roof_mesh_batches"]==(0 if damage==4 else 1))
            assert(stats["bracket_mesh_batches"]<2)
            assert(stats["rear_vertical_ribs"]==(0 if damage==4 else 5))
            assert(stats["service_door"]==(1 if damage<3 else 0))
            assert(stats["ventilation_panels"]==(0 if damage>=3 else 1 if damage==2 else 2))
            assert(stats["rear_critical_debris"]==(2 if damage==3 else 0))
            if damage<4:
                assert(_count_node(model,V10.ROOF_BATCH_NAME)==1)
                assert(_count_node(model,V10.REAR_NAME)==1)
                assert(model.find_child("MuroTraseroCerrado",true,false)!=null)
                assert(model.find_child("ParedPosteriorInterior",true,false)!=null)
                _assert_equipment_seated(model,damage)
            else:
                assert(_count_node(model,V10.ROOF_BATCH_NAME)==0)
                assert(_count_node(model,V10.REAR_NAME)==0)
                assert(model.find_child("HangarPrincipalV1",true,false)==null)
            if damage==0:
                var snow: Dictionary=Weather.apply(model,"snow",true)
                assert(snow.get("valid",false))
                Weather.clear(model)
                var rain: Dictionary=Weather.apply(model,"rain",true)
                assert(rain.get("valid",false))
                Weather.clear(model)
            model.free()
            configurations+=1
    assert(configurations==40)
    for tier in range(1,4):
        var model: Node3D=_make(tier,4,0)
        var stat: Dictionary=model.get_meta("tarvoka_airbase_v10_stats",{})
        assert(stat["level"]==tier)
        assert(stat["supported_roof_segments"]==14)
        _assert_equipment_seated(model,0)
        model.free()

    # The 20 sliding gate meshes remain exactly V2's original mechanism.
    var sample: Node3D=_make(2,0,0)
    sample.add_child(Doors.build(0))
    root.add_child(sample)
    await _frames(2)
    var rig: TarvokaAirbaseDoorRigV2=sample.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(rig!=null and rig.is_operational())
    assert(rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    sample.queue_free()
    await _frames(3)

    # The distant LOD remains cheap; only four near models receive V10.
    var grid: Node3D=Stress.build_grid(8,4,true,true,true,true,true)
    assert(grid!=null)
    assert(grid.get_meta("tarvoka_stress_structure_v10",false))
    assert(grid.get_meta("tarvoka_stress_proxy_count")==4)
    assert(_count_node(grid,V10.STAGE_NAME)==4)
    grid.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(13)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(11)
    assert(studio._role=="airbase")
    assert(studio.airbase_structure_v10_toggle!=null)
    assert(studio.airbase_structure_v10_toggle.button_pressed)
    assert(studio.model_root.find_child(V10.STAGE_NAME,true,false)!=null)

    # Exact V9 baseline, keeping other building viewers undisturbed.
    studio.airbase_structure_v10_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_structure_v10(false)
    await _frames(8)
    assert(studio.model_root.find_child(V10.STAGE_NAME,true,false)==null)
    studio._change_airbase_v9_view(2)
    await _frames(7)
    _shot(studio,"rear_v9")
    studio.airbase_structure_v10_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_structure_v10(true)
    await _frames(8)
    studio._change_airbase_v9_view(2)
    await _frames(7)
    _shot(studio,"rear_v10")
    studio._zoom=1.43
    studio._update_camera()
    await _frames(6)
    _shot(studio,"rear_closeup")
    studio._zoom=1.0
    studio._update_camera()

    for index in [4,6,0,3,5]:
        studio.airbase_v9_view_picker.select(index)
        studio._change_airbase_v9_view(index)
        await _frames(8)
        _shot(studio,
            ["front","left","rear","right","roof","tower","interior","low"][index])
    studio.airbase_v9_view_picker.select(0)
    studio._change_airbase_v9_view(0)
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(9)
    assert(studio.model_root.get_meta(
        "tarvoka_airbase_v10_stats")["supported_roof_segments"]==12)
    _shot(studio,"medium_damage")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(9)
    _shot(studio,"critical_damage")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(9)
    assert(studio.model_root.find_child(V10.REAR_NAME,true,false)==null)
    _shot(studio,"ruins")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(5)
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(9)
    _shot(studio,"winter")
    studio.airbase_weather_picker.select(0)
    studio._change_airbase_weather(0)
    await _frames(4)
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS AIRBASE V10: 40 faction/damage combinations, 3 levels, 14/12/8/0 actual roof-support sections, aligned roof fixtures, rear panels, 20 animated gate meshes, reversible weather, four-near LOD, 12 real Godot previews")
    quit(0)
