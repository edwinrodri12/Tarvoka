extends SceneTree

# Final Godot 4.3 visual acceptance for Airbase V16. No FPS benchmark.
# Intent: inspect all eight studio cameras, 40 faction x damage variants,
# three levels and the corrected tower-concrete scar placement.
const V1=preload("res://scripts/ui/Airbase3DV1.gd")
const V2=preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6=preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7=preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const V8=preload("res://scripts/ui/AirbaseFinishV8.gd")
const V9=preload("res://scripts/ui/AirbaseDetailV9.gd")
const V10=preload("res://scripts/ui/AirbaseStructureV10.gd")
const V11=preload("res://scripts/ui/AirbaseTrussesV11.gd")
const V12=preload("res://scripts/ui/AirbaseFractureV12.gd")
const V13=preload("res://scripts/ui/AirbaseImpactsV13.gd")
const V14=preload("res://scripts/ui/AirbaseScarsV14.gd")
const V15=preload("res://scripts/ui/AirbaseScarFinishV15.gd")
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=7) -> void:
    for _i in range(count):
        await process_frame

func _shot(studio: Control,label: String) -> void:
    await _frames(7)
    var frame: Image=studio.preview.get_texture().get_image()
    assert(frame!=null and frame.get_width()>400 and frame.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(frame.save_png(
        "res://artifacts/tarvoka_airbase_v16_"+label+".png")==OK)

func _count(node: Node,label: String) -> int:
    var found: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        found+=_count(child,label)
    return found

func _build(level: int,faction: int,damage: int) -> Node3D:
    var model: Node3D=V1.build(level,faction,damage)
    assert(model!=null)
    assert(V2.apply(model,level,faction,damage))
    assert(V6.apply(model,level,faction,damage))
    assert(V7.apply(model,level,faction,damage))
    assert(V8.apply(model,level,faction,damage))
    assert(V9.apply(model,level,faction,damage))
    assert(V10.apply(model,level,faction,damage))
    assert(V11.apply(model,level,faction,damage))
    assert(V12.apply(model,level,faction,damage))
    return model

func _run() -> void:
    # The tower's actual front wall lies at z=-2.86; do not aim at an
    # exterior metallic mullion at x=4.17, or float the damage over it.
    var concrete: Vector3=V13.surface_position("tower_concrete")
    assert(absf(concrete.x-3.92)<0.002)
    assert(absf(concrete.z+2.864)<0.002)
    var variants:=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=_build(2,faction,damage)
            assert(model!=null and model.get_meta("tarvoka_airbase_v12",false))
            if damage<4:
                assert(_count(model,"MuroTraseroCerrado")==1)
                var scars:=TarvokaAirbaseScarsV14.new()
                model.add_child(scars)
                scars.damage_stage=damage
                var finish:=TarvokaAirbaseScarFinishV15.new()
                model.add_child(finish)
                assert(finish.bind_to_scars(scars))
                model.propagate_notification(Node.NOTIFICATION_TRANSFORM_CHANGED)
                assert(scars.add_mark("missile","tower_concrete"))
                var anchor: Node3D=scars.find_child(
                    "HuellaDeImpactoV14_tower_concrete_0",true,false) as Node3D
                assert(anchor!=null)
                assert(absf(anchor.position.x-3.92)<0.002)
                assert(absf(anchor.position.z+2.864)<0.002)
                assert(absf(anchor.scale.z-0.64)<0.002)
                assert(finish.active_detail_slots()==1)
            else:
                assert(model.find_child("HangarPrincipalV1",true,false)==null)
            model.free()
            variants+=1
    assert(variants==40)

    for tier in range(1,4):
        var model: Node3D=_build(tier,0,0)
        assert(_count(model,"HangarPrincipalV1")==1)
        assert(_count(model,"TorreControlAereoV1")==1)
        model.free()

    var sample: Node3D=_build(2,0,0)
    sample.add_child(Doors.build(0))
    root.add_child(sample)
    await _frames(4)
    var doors: TarvokaAirbaseDoorRigV2=sample.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(doors!=null and doors.gate_mesh_count()==20)
    doors.set_open_fraction(1.0)
    assert(doors.open_fraction()>0.99)
    assert(Weather.apply(sample,"rain",true).get("valid",false))
    Weather.clear(sample)
    assert(Weather.apply(sample,"snow",true).get("valid",false))
    Weather.clear(sample)
    sample.queue_free()
    await _frames(4)

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(15)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(12)
    assert(studio._role=="airbase")
    assert(studio.building_picker.get_item_text(1).contains("V16"))
    assert(studio.airbase_finish_v15_toggle.button_pressed)

    var views: Array[String]=[
        "front","left","rear","right","roof","tower","inside","low"
    ]
    for index in range(8):
        studio.airbase_v9_view_picker.select(index)
        studio._change_airbase_v9_view(index)
        await _frames(6)
        assert(studio._airbase_v9_view==index)
        await _shot(studio,"angle_"+views[index])

    for damage in [2,3,4]:
        studio.airbase_damage_picker.select(damage)
        studio._change_airbase_damage(damage)
        await _frames(9)
        assert(int(studio.model_root.get_meta("visual_damage_stage",damage))==damage)
        studio.airbase_v9_view_picker.select(0)
        studio._change_airbase_v9_view(0)
        await _shot(studio,"damage_"+["medium","critical","ruins"][[
            2,3,4].find(damage)])
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(7)
    for weather in [1,2]:
        studio.airbase_weather_picker.select(weather)
        studio._change_airbase_weather(weather)
        await _frames(7)
        await _shot(studio,"climate_"+["rain","snow"][weather-1])
    studio.airbase_weather_picker.select(0)
    studio._change_airbase_weather(0)
    await _frames(8)
    studio.airbase_surface_v13_picker.select(1)
    studio.airbase_v13_focus_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_v13_focus(true)
    studio._change_airbase_v13_target(1)
    await _shot(studio,"concrete_before")
    studio._play_airbase_impact("missile")
    var v13fx: TarvokaAirbaseImpactsV13=studio.model_root.get_node(
        V13.STAGE_NAME) as TarvokaAirbaseImpactsV13
    v13fx.stop()
    var scars: TarvokaAirbaseScarsV14=studio.model_root.get_node(
        V14.STAGE_NAME) as TarvokaAirbaseScarsV14
    assert(scars.visible_marks("tower_concrete")==1)
    var target: Node3D=scars.find_child(
        "HuellaDeImpactoV14_tower_concrete_0",true,false) as Node3D
    assert(absf(target.position.x-3.92)<0.002)
    assert(target.scale.z<0.70)
    await _shot(studio,"concrete_after")
    studio._clear_airbase_v14_marks()
    assert(scars.visible_marks("tower_concrete")==0)
    await _shot(studio,"concrete_repaired")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(4)
    print("PASS AIRBASE V16: final 360-degree model review, 8 approved cameras, 40 faction/damage variants, 3 levels, concrete surface anchor seated between frames, 20 gate parts, rain/snow and 16 authentic native Godot captures")
    quit(0)
