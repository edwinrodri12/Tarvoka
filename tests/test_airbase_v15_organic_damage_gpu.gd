extends SceneTree

# Native Godot 4.3 art regression; geometry and viewer only, no Android FPS.
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
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _count(root_node: Node,label: String) -> int:
    var n: int=1 if str(root_node.name)==label else 0
    for child in root_node.get_children():
        n+=_count(child,label)
    return n

func _shot(studio: Control,label: String) -> void:
    await _frames(4)
    var snap: Image=studio.preview.get_texture().get_image()
    assert(snap!=null and snap.get_width()>400 and snap.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(snap.save_png(
        "res://artifacts/tarvoka_airbase_v15_"+label+".png")==OK)

func _model(level: int,faction: int,stage: int) -> Node3D:
    var model: Node3D=V1.build(level,faction,stage)
    assert(model!=null)
    assert(V2.apply(model,level,faction,stage))
    assert(V6.apply(model,level,faction,stage))
    assert(V7.apply(model,level,faction,stage))
    assert(V8.apply(model,level,faction,stage))
    assert(V9.apply(model,level,faction,stage))
    assert(V10.apply(model,level,faction,stage))
    assert(V11.apply(model,level,faction,stage))
    assert(V12.apply(model,level,faction,stage))
    return model

func _finish(model: Node3D,stage: int) -> Dictionary:
    var scars:=TarvokaAirbaseScarsV14.new()
    scars.name=V14.STAGE_NAME
    scars.damage_stage=stage
    model.add_child(scars)
    var finish:=TarvokaAirbaseScarFinishV15.new()
    finish.name=V15.STAGE_NAME
    model.add_child(finish)
    assert(finish.bind_to_scars(scars))
    return {"scars":scars,"finish":finish}

func _check_shape(finish: TarvokaAirbaseScarFinishV15) -> void:
    for surface in V14.SURFACES:
        for attack in V14.ATTACKS:
            for slot in range(V14.MAX_PER_SURFACE):
                var stats: Dictionary=finish.finish_stats(surface,attack,slot)
                assert(not stats.is_empty())
                var mesh: ArrayMesh=V15._build_mesh(surface,attack,slot)
                assert(mesh.surface_get_array_len(0)>30)
                assert(mesh.get_surface_count()==1)
                if surface=="tower_concrete":
                    assert(stats["crack_segments"]>=20)
                    assert(stats["chips"]>=5)
                    assert(stats["folds"]==0)
                else:
                    assert(stats["folds"]>=3)
                    assert(stats["scratches"]>=3)
                    assert(stats["crack_segments"]==0)
                if attack=="bullet":
                    assert(stats["soot_islands"]==0)
                else:
                    assert(stats["soot_islands"]>=7)

func _run() -> void:
    assert(V15.STAGE_NAME!="")
    assert(V15.ACCENT_NAME!="")
    assert(V14.MAX_PER_SURFACE==3)
    var combinations:=0
    for faction in range(8):
        for stage in range(5):
            var model: Node3D=_model(2,faction,stage)
            if stage<4:
                var pair: Dictionary=_finish(model,stage)
                assert(_count(model,V15.STAGE_NAME)==1)
                assert(_count(model,V14.STAGE_NAME)==1)
            else:
                assert(model.find_child("HangarPrincipalV1",true,false)==null)
            if stage==0:
                assert(Weather.apply(model,"rain",true).get("valid",false))
                Weather.clear(model)
                assert(Weather.apply(model,"snow",true).get("valid",false))
                Weather.clear(model)
            model.free()
            combinations+=1
    assert(combinations==40)
    for tier in range(1,4):
        var level_model: Node3D=_model(tier,4,0)
        _finish(level_model,0)
        assert(_count(level_model,V15.STAGE_NAME)==1)
        level_model.free()

    var sample: Node3D=_model(2,0,0)
    sample.add_child(Doors.build(0))
    var pair: Dictionary=_finish(sample,0)
    var scars: TarvokaAirbaseScarsV14=pair["scars"]
    var finish: TarvokaAirbaseScarFinishV15=pair["finish"]
    root.add_child(sample)
    await _frames(5)
    _check_shape(finish)
    assert(finish.total_detail_slots()==0)
    assert(finish.active_detail_slots()==0)
    assert(scars.add_mark("bullet","gate_metal"))
    assert(finish.active_detail_slots()==1)
    assert(scars.add_mark("missile","tower_concrete"))
    assert(finish.active_detail_slots()==2)
    assert(scars.add_mark("bombardment","hangar_roof"))
    assert(finish.active_detail_slots()==5)
    assert(_count(sample,V15.ACCENT_NAME)==5)
    var old: Array[Dictionary]=scars.snapshot()
    assert(old.size()==3)
    for i in range(8):
        assert(scars.add_mark("missile","gate_metal"))
    assert(scars.visible_marks("gate_metal")==3)
    assert(finish.total_detail_slots()<=9)
    assert(finish.active_detail_slots()<=9)
    var rig: TarvokaAirbaseDoorRigV2=sample.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(rig!=null and rig.is_operational())
    assert(rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    scars.clear_marks()
    assert(finish.active_detail_slots()==0)
    assert(scars.active_mesh_instances()==0)
    scars.restore(old)
    assert(finish.active_detail_slots()==5)
    assert(scars.event_count()==3)
    sample.queue_free()
    await _frames(4)

    # No V15 details on the 8/32/64 distant-building LOD board.
    var stress: Node3D=Stress.build_grid(8,4,true,true,true,true,true,true,true)
    assert(stress!=null)
    assert(stress.get_meta("tarvoka_stress_proxy_count")==4)
    assert(_count(stress,V15.STAGE_NAME)==0)
    stress.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(11)
    assert(studio._role=="airbase")
    assert(studio.airbase_finish_v15_toggle.button_pressed)
    assert(studio.model_root.find_child(V15.STAGE_NAME,true,false)!=null)
    await _shot(studio,"clean")

    studio.airbase_v13_focus_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_v13_focus(true)
    for surface_index in range(3):
        studio.airbase_surface_v13_picker.select(surface_index)
        studio._change_airbase_v13_target(surface_index)
        await _frames(6)
        for kind in V13.KINDS:
            studio._play_airbase_impact(kind)
            var fx: TarvokaAirbaseImpactsV13=studio.model_root.get_node(
                V13.STAGE_NAME) as TarvokaAirbaseImpactsV13
            assert(fx!=null and fx.last_kind()==kind)
            fx.stop()
            await _frames(3)
            var finished: TarvokaAirbaseScarFinishV15=studio.model_root.get_node(
                V15.STAGE_NAME) as TarvokaAirbaseScarFinishV15
            assert(finished.active_detail_slots()>=1)
            var labels: Array[String]=["gate","concrete","roof"]
            await _shot(studio,"%s_%s" % [kind,labels[surface_index]])
    assert(studio._airbase_v14_history.size()==9)

    # Same actual damaged model / camera: compare V14 and V15.
    studio.airbase_surface_v13_picker.select(1)
    studio._change_airbase_v13_target(1)
    studio.airbase_finish_v15_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_finish_v15(false)
    await _frames(8)
    assert(studio.model_root.find_child(V15.STAGE_NAME,true,false)==null)
    assert(studio.model_root.find_child(V14.STAGE_NAME,true,false)!=null)
    await _shot(studio,"concrete_baseline_v14")
    studio.airbase_finish_v15_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_finish_v15(true)
    await _frames(8)
    assert(studio.model_root.find_child(V15.STAGE_NAME,true,false)!=null)
    assert((studio.model_root.get_node(V15.STAGE_NAME) as
        TarvokaAirbaseScarFinishV15).active_detail_slots()==9)
    await _shot(studio,"concrete_rebuilt_v15")
    studio.airbase_surface_v13_picker.select(2)
    studio._change_airbase_v13_target(2)
    await _shot(studio,"roof_rebuilt_v15")

    var before: Array[Dictionary]=studio._airbase_v14_history.duplicate(true)
    studio.airbase_weather_picker.select(1)
    studio._change_airbase_weather(1)
    await _frames(8)
    var restored: TarvokaAirbaseScarFinishV15=studio.model_root.get_node(
        V15.STAGE_NAME) as TarvokaAirbaseScarFinishV15
    assert(restored.active_detail_slots()==9)
    assert(studio._airbase_v14_history==before)
    await _shot(studio,"rain_retained")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    restored=studio.model_root.get_node(V15.STAGE_NAME) as TarvokaAirbaseScarFinishV15
    assert(restored.active_detail_slots()==9)
    await _shot(studio,"critical_retained")

    studio._clear_airbase_v14_marks()
    assert(studio._airbase_v14_history.is_empty())
    assert(restored.active_detail_slots()==0)
    await _shot(studio,"repaired_v15")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(8)
    assert(studio.model_root.find_child(V15.STAGE_NAME,true,false)==null)
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(4)
    print("PASS AIRBASE V15: 40 faction/damage variants, 3 levels, 27 cached unique scar meshes, concrete branching cracks, steel lifted folds, irregular ash, capped V14 slots, persistence/clear, 20 sliding gate parts, near-LOD and 16 actual Godot screenshots")
    quit(0)
