extends SceneTree

# QA of real Godot 4.3 material-specific impact animations; no Android FPS.
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
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const TARGET_LABELS:=["gate","concrete","roof"]
const ATTACK_LABELS:=["bullet","missile","bombardment"]

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=6) -> void:
    for _i in range(n):
        await process_frame

func _capture(studio: Control,label: String) -> void:
    var shot: Image=studio.preview.get_texture().get_image()
    assert(shot!=null and shot.get_width()>400 and shot.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(shot.save_png("res://artifacts/tarvoka_airbase_v13_"+label+".png")==OK)

func _count(model: Node,label: String) -> int:
    var n: int=1 if str(model.name)==label else 0
    for child in model.get_children():
        n+=_count(child,label)
    return n

func _build(tier: int,faction: int,stage: int) -> Node3D:
    var root_model: Node3D=V1.build(tier,faction,stage)
    assert(root_model!=null)
    assert(V2.apply(root_model,tier,faction,stage))
    assert(V6.apply(root_model,tier,faction,stage))
    assert(V7.apply(root_model,tier,faction,stage))
    assert(V8.apply(root_model,tier,faction,stage))
    assert(V9.apply(root_model,tier,faction,stage))
    assert(V10.apply(root_model,tier,faction,stage))
    assert(V11.apply(root_model,tier,faction,stage))
    assert(V12.apply(root_model,tier,faction,stage))
    return root_model

func _rig(model: Node3D,stage: int) -> TarvokaAirbaseImpactsV13:
    var rig:=TarvokaAirbaseImpactsV13.new()
    rig.damage_stage=stage
    rig.name=V13.STAGE_NAME
    model.add_child(rig)
    return rig

func _check_pool(rig: TarvokaAirbaseImpactsV13) -> void:
    assert(_count(rig,"ChispasPorMaterialUnLoteV13")==1)
    assert(_count(rig,"DesconchonesSuperficieUnLoteV13")==1)
    assert(_count(rig,"EstelaMisilV13_0")==1)
    assert(_count(rig,"DestelloVolumetricoV13_2")==1)
    assert(_count(rig,"OndaPresionV13_2")==1)
    assert(_count(rig,"PolvoYHumoV13_2")==1)
    assert(_count(rig,"MarcaTemporalSuperficieV13_2")==1)
    assert(rig.get_child_count()==17)
    assert(rig.active_visual_batches()==0)

func _run() -> void:
    assert(V13.KINDS.size()==3)
    assert(V13.TARGETS.size()==3)
    assert(not V13.valid_attack("laser","hangar_roof",0))
    assert(not V13.valid_attack("missile","hangar_roof",4))
    assert(not V13.valid_attack("bombardment","water",1))
    assert(V13.valid_attack("bullet","gate_metal",3))
    # The chosen roof section 12 is never one of the removed sections.
    assert(V10._has_roof(V10._segment_for_x(2.8),2))
    assert(V10._has_roof(V10._segment_for_x(2.8),3))
    var target_position: Vector3=V13.surface_position("hangar_roof")
    assert(absf(target_position.y-(V10._roof_y(2.8)+0.052))<0.002)
    assert(absf(V13.surface_position("tower_concrete").x-4.17)<0.001)

    var variants:=0
    for faction in range(8):
        for stage in range(5):
            var model: Node3D=_build(2,faction,stage)
            if stage<4:
                # Pool is installed once per live building, never per attack.
                var rig: TarvokaAirbaseImpactsV13=_rig(model,stage)
                assert(rig.damage_stage==stage)
                assert(_count(model,V13.STAGE_NAME)==1)
                for surface in V13.TARGETS:
                    for attack in V13.KINDS:
                        assert(V13.valid_attack(attack,surface,stage))
                if stage==0:
                    var wet: Dictionary=Weather.apply(model,"rain",true)
                    assert(wet.get("valid",false))
                    Weather.clear(model)
                    var snow: Dictionary=Weather.apply(model,"snow",true)
                    assert(snow.get("valid",false))
                    Weather.clear(model)
            else:
                assert(model.find_child("HangarPrincipalV1",true,false)==null)
                assert(not V13.valid_attack("missile","hangar_roof",stage))
            model.free()
            variants+=1
    assert(variants==40)
    for tier in range(1,4):
        var model: Node3D=_build(tier,5,0)
        var fx: TarvokaAirbaseImpactsV13=_rig(model,0)
        assert(fx.damage_stage==0)
        model.free()

    # 3 attacks × 3 targets: distinct timings, positions and pools.
    var sample: Node3D=_build(2,0,0)
    sample.add_child(Doors.build(0))
    var fx: TarvokaAirbaseImpactsV13=_rig(sample,0)
    root.add_child(sample)
    await _frames(4)
    _check_pool(fx)
    var rig: TarvokaAirbaseDoorRigV2=sample.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(rig!=null and rig.is_operational())
    assert(rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    var expected_count:=0
    for kind in V13.KINDS:
        for surface in V13.TARGETS:
            assert(fx.trigger(kind,surface))
            expected_count+=1
            assert(fx.event_count()==expected_count)
            assert(fx.last_kind()==kind)
            assert(fx.last_surface()==surface)
            var frame: float=0.20 if kind=="bullet" else (
                0.49 if kind=="missile" else 1.05)
            fx._render(frame)
            assert(fx.active_visual_batches()>0)
            assert(fx.active_visual_batches()<=17)
            _check_pool_visible(fx)
            fx.stop()
            _check_pool(fx)
    assert(fx.event_count()==9)
    # Restarting during an impact uses the same nodes and resets duration.
    assert(fx.trigger("missile","gate_metal"))
    assert(fx.trigger("bombardment","tower_concrete"))
    assert(fx.event_count()==11)
    assert(fx.last_kind()=="bombardment")
    fx.stop()
    _check_pool(fx)
    sample.queue_free()
    await _frames(3)

    var board: Node3D=Stress.build_grid(8,4,true,true,true,true,true,true,true)
    assert(board!=null)
    assert(board.get_meta("tarvoka_stress_proxy_count")==4)
    # No 3D attack pools are spawned across 8,32,64 stress-only boards.
    assert(_count(board,V13.STAGE_NAME)==0)
    board.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(10)
    assert(studio._role=="airbase")
    assert(studio.airbase_impacts_v13_toggle.button_pressed)
    assert(studio.airbase_surface_v13_picker.item_count==3)
    assert(studio.airbase_missile_v13_button!=null)
    assert(studio.airbase_bombard_v13_button!=null)
    assert(studio.model_root.find_child(V13.STAGE_NAME,true,false)!=null)
    _capture(studio,"overview")

    # Compare original V12 bullet on the same current intact model.
    studio.airbase_impacts_v13_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_impacts_v13(false)
    await _frames(7)
    assert(studio.model_root.find_child(V13.STAGE_NAME,true,false)==null)
    _capture(studio,"baseline_v12")
    studio.airbase_impacts_v13_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_impacts_v13(true)
    await _frames(7)

    for surface_index in range(3):
        studio.airbase_surface_v13_picker.select(surface_index)
        for kind in V13.KINDS:
            studio._play_airbase_impact(kind)
            var local_fx: TarvokaAirbaseImpactsV13=studio.model_root.get_node(
                V13.STAGE_NAME) as TarvokaAirbaseImpactsV13
            assert(local_fx.event_count()>0)
            assert(local_fx.last_kind()==kind)
            assert(local_fx.last_surface()==V13.TARGETS[surface_index])
            local_fx._elapsed=0.20 if kind=="bullet" else (
                0.50 if kind=="missile" else 0.98)
            local_fx._render(local_fx._elapsed)
            await _frames(2)
            _capture(studio,"%s_%s" % [
                str(ATTACK_LABELS[V13.KINDS.find(kind)]),
                str(TARGET_LABELS[surface_index])])
            local_fx.stop()

    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    studio.airbase_surface_v13_picker.select(2)
    studio._play_airbase_impact("bombardment")
    await _frames(3)
    var damaged_fx: TarvokaAirbaseImpactsV13=studio.model_root.get_node(
        V13.STAGE_NAME) as TarvokaAirbaseImpactsV13
    assert(damaged_fx.event_count()==1 and damaged_fx.damage_stage==3)
    damaged_fx._elapsed=0.97
    damaged_fx._render(0.97)
    await _frames(2)
    _capture(studio,"critical_bombardment")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(6)
    assert(studio.model_root.find_child(V13.STAGE_NAME,true,false)==null)
    assert(studio.airbase_missile_v13_button.disabled)
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(6)
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS AIRBASE V13: 40 faction/damage variants, 3 architectural levels, 3 attack classes, 3 true material targets, 2 pooled MultiMeshes, 3 staggered blast waves, 20 gate parts, existing climate/LOD, 12 native Godot screenshots")
    quit(0)

func _check_pool_visible(rig: TarvokaAirbaseImpactsV13) -> void:
    assert(_count(rig,"ChispasPorMaterialUnLoteV13")==1)
    assert(_count(rig,"DesconchonesSuperficieUnLoteV13")==1)
    assert(_count(rig,"DestelloVolumetricoV13_0")==1)
    assert(_count(rig,"DestelloVolumetricoV13_1")==1)
    assert(_count(rig,"DestelloVolumetricoV13_2")==1)
    assert(rig.get_child_count()==17)
