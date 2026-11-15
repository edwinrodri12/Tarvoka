extends SceneTree

# V14 actual Godot 4.3 shader + geometry + viewer regression, NOT Android FPS.
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
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _count(model: Node,label: String) -> int:
    var n: int=1 if str(model.name)==label else 0
    for child in model.get_children():
        n+=_count(child,label)
    return n

func _capture(studio: Control,label: String) -> void:
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png(
        "res://artifacts/tarvoka_airbase_v14_"+label+".png")==OK)

func _build(level: int,faction: int,stage: int) -> Node3D:
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

func _scar(model: Node3D,stage: int) -> TarvokaAirbaseScarsV14:
    var scar:=TarvokaAirbaseScarsV14.new()
    scar.name=V14.STAGE_NAME
    scar.damage_stage=stage
    model.add_child(scar)
    return scar

func _run() -> void:
    assert(V14.SURFACES.size()==3)
    assert(V14.ATTACKS.size()==3)
    assert(V14.MAX_PER_SURFACE==3)
    assert(absf(V13.surface_position("gate_metal").x-(
        V1.HANGAR_CENTER_X-2.28))<0.002)
    assert(V10._has_roof(V10._segment_for_x(3.13),3))
    var configurations:=0
    for faction in range(8):
        for stage in range(5):
            var model: Node3D=_build(2,faction,stage)
            assert(model!=null)
            if stage<4:
                _scar(model,stage)
            assert(_count(model,V14.STAGE_NAME)==(1 if stage<4 else 0))
            model.free()
            configurations+=1
    assert(configurations==40)
    for level in range(1,4):
        var model: Node3D=_build(level,3,0)
        _scar(model,0)
        assert(_count(model,V14.STAGE_NAME)==1)
        model.free()

    var model: Node3D=_build(2,0,0)
    model.add_child(Doors.build(0))
    var fx:=TarvokaAirbaseImpactsV13.new()
    fx.damage_stage=0
    model.add_child(fx)
    var scar: TarvokaAirbaseScarsV14=_scar(model,0)
    root.add_child(model)
    await _frames(4)
    assert(_count(model,V14.STAGE_NAME)==1)
    assert(scar.get_child_count()==3)
    assert(scar.event_count()==0)
    assert(scar.active_mesh_instances()==0)
    assert(not scar.add_mark("laser","gate_metal"))
    assert(not scar.add_mark("bullet","water"))
    assert(scar.add_mark("bullet","gate_metal"))
    assert(scar.visible_marks("gate_metal")==1)
    assert(scar.add_mark("missile","tower_concrete"))
    assert(scar.visible_marks("tower_concrete")==1)
    assert(scar.add_mark("bombardment","hangar_roof"))
    assert(scar.visible_marks("hangar_roof")==3)
    assert(scar.event_count()==3)
    var snapshot: Array[Dictionary]=scar.snapshot()
    assert(snapshot.size()==3)
    assert(scar.active_mesh_instances()==9)
    var gate_mark: Node3D=scar.find_child(
        "HuellaDeImpactoV14_gate_metal_0",true,false) as Node3D
    assert(gate_mark!=null and gate_mark.visible)
    assert(absf(gate_mark.position.z+4.174)<0.002)
    var relief: MeshInstance3D=gate_mark.get_node(
        "AbolladuraConRelieveV14") as MeshInstance3D
    assert(relief!=null and relief.mesh is ArrayMesh)
    assert(relief.mesh.surface_get_array_len(0)>180)
    assert((gate_mark.get_node("HaloCarbonizadoV14") as
        MeshInstance3D).visible==false)
    var rig: TarvokaAirbaseDoorRigV2=model.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(rig!=null and rig.is_operational())
    assert(rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    assert(fx.trigger("missile","gate_metal"))
    fx.stop()
    assert(scar.visible_marks("gate_metal")==1)
    for i in range(7):
        assert(scar.add_mark("missile","gate_metal"))
    assert(scar.visible_marks("gate_metal")==3)
    assert(scar.active_mesh_instances()<=18)
    assert(scar.event_count()==10)
    scar.clear_marks()
    assert(scar.visible_marks("gate_metal")==0)
    assert(scar.active_mesh_instances()==0)
    assert(scar.event_count()==0)
    scar.restore(snapshot)
    assert(scar.event_count()==3)
    assert(scar.visible_marks("hangar_roof")==3)
    model.queue_free()
    await _frames(3)

    var critical: Node3D=_build(2,0,3)
    var crit_scar: TarvokaAirbaseScarsV14=_scar(critical,3)
    root.add_child(critical)
    await _frames(3)
    assert(crit_scar.add_mark("bombardment","gate_metal"))
    assert(crit_scar.add_mark("bullet","hangar_roof"))
    assert(crit_scar.visible_marks("gate_metal")==3)
    assert(crit_scar.visible_marks("hangar_roof")==1)
    critical.queue_free()
    await _frames(3)

    # No V14 scars across the 8/32/64-building LOD demonstrations.
    var board: Node3D=Stress.build_grid(8,4,true,true,true,true,true,true,true)
    assert(board!=null and board.get_meta("tarvoka_stress_proxy_count")==4)
    assert(_count(board,V14.STAGE_NAME)==0)
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
    assert(studio.airbase_scars_v14_toggle.button_pressed)
    assert(studio.airbase_v14_reset_button!=null)
    assert(studio.model_root.find_child(V14.STAGE_NAME,true,false)!=null)
    _capture(studio,"clean")

    studio.airbase_scars_v14_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_scars_v14(false)
    await _frames(8)
    assert(studio.model_root.find_child(V14.STAGE_NAME,true,false)==null)
    _capture(studio,"baseline_v13")
    studio.airbase_scars_v14_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_scars_v14(true)
    await _frames(9)
    studio.airbase_v13_focus_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_v13_focus(true)
    for target in range(3):
        studio.airbase_surface_v13_picker.select(target)
        studio._change_airbase_v13_target(target)
        await _frames(4)
        for kind in V13.KINDS:
            studio._play_airbase_impact(kind)
            var visual: TarvokaAirbaseImpactsV13=studio.model_root.get_node(
                V13.STAGE_NAME) as TarvokaAirbaseImpactsV13
            assert(visual!=null and visual.last_kind()==kind)
            visual.stop()
            var marks: TarvokaAirbaseScarsV14=studio.model_root.get_node(
                V14.STAGE_NAME) as TarvokaAirbaseScarsV14
            assert(marks!=null and marks.event_count()>0)
            await _frames(5)
            var suffix: String=["gate","concrete","roof"][target]
            _capture(studio,"%s_%s" % [kind,suffix])
    assert(studio._airbase_v14_history.size()==9)
    var persisted: Array[Dictionary]=studio._airbase_v14_history.duplicate(true)
    studio.airbase_weather_picker.select(1)
    studio._change_airbase_weather(1)
    await _frames(9)
    var restored: TarvokaAirbaseScarsV14=studio.model_root.get_node(
        V14.STAGE_NAME) as TarvokaAirbaseScarsV14
    assert(restored.event_count()==9)
    assert(restored.visible_marks("gate_metal")==3)
    assert(restored.visible_marks("hangar_roof")==3)
    assert(studio._airbase_v14_history==persisted)
    _capture(studio,"rain_retained")
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(8)
    restored=studio.model_root.get_node(
        V14.STAGE_NAME) as TarvokaAirbaseScarsV14
    assert(restored!=null and restored.event_count()==9)
    _capture(studio,"medium_retained")
    studio._clear_airbase_v14_marks()
    assert(studio._airbase_v14_history.is_empty())
    assert(restored.active_mesh_instances()==0)
    _capture(studio,"reset_clean")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(7)
    assert(studio.model_root.find_child(V14.STAGE_NAME,true,false)==null)
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS AIRBASE V14: 40 faction/damage combinations, 3 levels, 9 real contoured pooled scars, 3 materials x 3 attacks, 20 gate parts, persistence across weather/damage, bounded pool, reset UI, 13 real Godot captures")
    quit(0)
