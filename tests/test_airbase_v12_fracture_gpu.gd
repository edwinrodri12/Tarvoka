extends SceneTree

# Real Godot 4.3 visual regression. Checks 3D topology, reused impact
# fragments and V11 compatibility. Not an Android FPS measurement.
const Airbase=preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar=preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6=preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7=preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const V8=preload("res://scripts/ui/AirbaseFinishV8.gd")
const V9=preload("res://scripts/ui/AirbaseDetailV9.gd")
const V10=preload("res://scripts/ui/AirbaseStructureV10.gd")
const V11=preload("res://scripts/ui/AirbaseTrussesV11.gd")
const V12=preload("res://scripts/ui/AirbaseFractureV12.gd")
const Impact=preload("res://scripts/ui/AirbaseImpactV3.gd")
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=6) -> void:
    for _i in range(n):
        await process_frame

func _capture(studio: Control,name: String) -> void:
    var snap: Image=studio.preview.get_texture().get_image()
    assert(snap!=null and snap.get_width()>400 and snap.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(snap.save_png(
        "res://artifacts/tarvoka_airbase_v12_"+name+".png")==OK)

func _count(root_node: Node,name: String) -> int:
    var n: int=1 if str(root_node.name)==name else 0
    for child in root_node.get_children():
        n+=_count(child,name)
    return n

func _build(tier: int,faction: int,damage: int,
        with_v12: bool=true) -> Node3D:
    var model: Node3D=Airbase.build(tier,faction,damage)
    assert(model!=null and Hangar.apply(model,tier,faction,damage))
    assert(V6.apply(model,tier,faction,damage))
    assert(V7.apply(model,tier,faction,damage))
    assert(V8.apply(model,tier,faction,damage))
    assert(V9.apply(model,tier,faction,damage))
    assert(V10.apply(model,tier,faction,damage))
    assert(V11.apply(model,tier,faction,damage))
    if with_v12:
        assert(V12.apply(model,tier,faction,damage))
    return model

func _expect(model: Node3D,tier: int,
        faction: int,damage: int) -> void:
    var stats: Dictionary=model.get_meta("tarvoka_airbase_v12_stats",{})
    assert(stats["level"]==tier and stats["faction"]==faction)
    assert(stats["damage"]==damage)
    assert(_count(model,V12.STAGE_NAME)==1)
    var edges: int=2 if damage in [2,3] else 0
    var scorch: int=3 if damage==1 else 10 if edges==2 else 0
    var twisted: int=12 if damage==2 else 16 if damage==3 else 0
    assert(stats["damaged_edges"]==edges)
    assert(stats["burn_strips"]==scorch)
    assert(stats["twisted_segments"]==twisted)
    assert(stats["burn_batches"]==(1 if scorch>0 else 0))
    assert(stats["bent_batches"]==(1 if twisted>0 else 0))
    assert(stats["reusable_shards"]==(0 if damage==4 else 6))
    assert(stats["collapsed_beams"]==(6 if damage==4 else 0))
    assert(stats["ruins_batches"]==(1 if damage==4 else 0))
    assert(_count(model,V12.SCORCHED_NAME)==(1 if scorch>0 else 0))
    assert(_count(model,V12.BENT_NAME)==(1 if twisted>0 else 0))
    assert(_count(model,V12.RUINS_NAME)==(1 if damage==4 else 0))
    assert(_count(model,V12.SHARDS_NAME)==(0 if damage==4 else 1))
    assert(_count(model,"EsquirlaMetalRealV12_00")==(0 if damage==4 else 1))
    var original_roof: Dictionary=model.get_meta("tarvoka_airbase_v11_stats",{})
    assert(original_roof["roof_panels_supported"]==(
        0 if damage==4 else 8 if damage==3 else 12 if damage==2 else 14))

func _run() -> void:
    assert(not V12.apply(null,1,0,0))
    var variants:=0
    for faction in range(8):
        for stage in range(5):
            var model: Node3D=_build(2,faction,stage)
            _expect(model,2,faction,stage)
            assert(not V12.apply(model,2,faction,stage))
            if stage==0:
                var rain: Dictionary=Weather.apply(model,"rain",true)
                assert(rain.get("valid",false))
                Weather.clear(model)
                var snow: Dictionary=Weather.apply(model,"snow",true)
                assert(snow.get("valid",false))
                Weather.clear(model)
            if stage==4:
                assert(not V12.trigger_explosion(model))
                assert(model.find_child("HangarPrincipalV1",true,false)==null)
            model.free()
            variants+=1
    assert(variants==40)
    for tier in range(1,4):
        var model: Node3D=_build(tier,3,3)
        _expect(model,tier,3,3)
        model.free()

    # A pooled real mesh must animate in the current scene without
    # creating new particle nodes or permanent additional buildings.
    var sample: Node3D=_build(2,0,0)
    sample.add_child(Doors.build(0))
    root.add_child(sample)
    await _frames(3)
    var door: TarvokaAirbaseDoorRigV2=sample.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(door!=null and door.is_operational())
    assert(door.gate_mesh_count()==20)
    door.set_open_fraction(1.0)
    assert(door.open_fraction()>0.99)
    var shard: MeshInstance3D=sample.find_child(
        "EsquirlaMetalRealV12_00",true,false) as MeshInstance3D
    assert(shard!=null and not shard.visible)
    assert(V12.trigger_explosion(sample))
    assert(shard.visible)
    assert(sample.get_meta("tarvoka_airbase_v12_explosions",0)==1)
    var initial: Vector3=shard.position
    await _frames(7)
    assert(shard.position.distance_to(initial)>0.0001)
    assert(V12.trigger_explosion(sample))
    assert(_count(sample,"EsquirlaMetalRealV12_00")==1)
    assert(sample.get_meta("tarvoka_airbase_v12_explosions",0)==2)
    sample.queue_free()
    await _frames(3)

    # Keep all distant buildings as V4 proxies, V12 belongs to near four.
    var board: Node3D=Stress.build_grid(8,4,true,true,true,true,true,true,true)
    assert(board!=null)
    assert(board.get_meta("tarvoka_stress_fracture_v12",false))
    assert(board.get_meta("tarvoka_stress_proxy_count")==4)
    assert(_count(board,V12.STAGE_NAME)==4)
    board.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(9)
    assert(studio._role=="airbase")
    assert(studio.airbase_fracture_v12_toggle.button_pressed)
    assert(studio.model_root.find_child(V12.STAGE_NAME,true,false)!=null)

    studio.airbase_v9_view_picker.select(0)
    studio._change_airbase_v9_view(0)
    await _frames(6)
    _capture(studio,"clean")
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(9)
    assert(studio.model_root.find_child(V12.BENT_NAME,true,false)!=null)
    studio.airbase_fracture_v12_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_fracture_v12(false)
    await _frames(9)
    assert(studio.model_root.find_child(V12.STAGE_NAME,true,false)==null)
    _capture(studio,"medium_v11")
    studio.airbase_fracture_v12_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_fracture_v12(true)
    await _frames(9)
    _capture(studio,"medium_v12")
    studio.airbase_v9_view_picker.select(4)
    studio._change_airbase_v9_view(4)
    await _frames(8)
    _capture(studio,"medium_roof")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_cutaway_v11(true)
    await _frames(7)
    _capture(studio,"medium_exposed")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_cutaway_v11(false)

    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    _capture(studio,"critical_roof")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_cutaway_v11(true)
    await _frames(7)
    _capture(studio,"critical_exposed")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_cutaway_v11(false)
    studio.airbase_v9_view_picker.select(6)
    studio._change_airbase_v9_view(6)
    await _frames(7)
    _capture(studio,"critical_inside")

    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(9)
    studio.airbase_v9_view_picker.select(0)
    studio._change_airbase_v9_view(0)
    studio._play_airbase_impact("explosive")
    assert(studio.model_root.get_meta("tarvoka_airbase_v12_explosions",0)==1)
    await _frames(7)
    _capture(studio,"explosive_debris")

    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(7)
    assert(studio.model_root.find_child(V12.RUINS_NAME,true,false)!=null)
    _capture(studio,"destroyed")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(7)
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(8)
    _capture(studio,"winter")
    studio.airbase_weather_picker.select(0)
    studio._change_airbase_weather(0)
    await _frames(5)
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS AIRBASE V12: 40 faction/damage variants, 3 levels, charred torn edges, twisted joined real steel, 6 reused animated fragments, explosion UI, 20 gate pieces, climate, near LOD and 11 native Godot screenshots")
    quit(0)
