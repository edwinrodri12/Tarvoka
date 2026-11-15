extends SceneTree

# Native Godot visual audit: all 8 real camera orientations and V8/V9
# geometry at every faction and damage stage. Does not simulate Android FPS.
const Airbase=preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar=preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6=preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7=preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const V8=preload("res://scripts/ui/AirbaseFinishV8.gd")
const V9=preload("res://scripts/ui/AirbaseDetailV9.gd")
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const CAPTURES := [
    "front_iso","left","rear","right",
    "roof","control_tower","hangar_inside","low_front"]

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=5) -> void:
    for _i in range(n):
        await process_frame

func _shot(studio: Control, name: String) -> void:
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png("res://artifacts/tarvoka_airbase_v9_"+name+".png")==OK)

func _make(tier: int, faction: int, stage: int) -> Node3D:
    var root_model: Node3D=Airbase.build(tier,faction,stage)
    assert(root_model!=null)
    assert(Hangar.apply(root_model,tier,faction,stage))
    assert(V6.apply(root_model,tier,faction,stage))
    assert(V7.apply(root_model,tier,faction,stage))
    assert(V8.apply(root_model,tier,faction,stage))
    assert(V9.apply(root_model,tier,faction,stage))
    return root_model

func _count(node: Node,label: String) -> int:
    var total: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        total+=_count(child,label)
    return total

func _lights(node: Node) -> int:
    var total: int=1 if node is OmniLight3D else 0
    for child in node.get_children():
        total+=_lights(child)
    return total

func _run() -> void:
    var total:=0
    for faction in range(8):
        for stage in range(5):
            var model: Node3D=_make(2,faction,stage)
            var stats: Dictionary=model.get_meta("tarvoka_airbase_v9_stats",{})
            assert(stats["stage"]==stage)
            assert(stats["faction"]==faction)
            assert(model.find_child(V9.STAGE_NAME,true,false)!=null)
            assert(not V9.apply(model,2,faction,stage))
            assert(_lights(model)==0)
            if stage<3:
                assert(stats["hidden_solid_glass"]==1)
                assert(stats["hidden_old_sides"]==2)
                assert(stats["thin_glass_panes"]==4)
                assert(_count(model,"CabinaHuecaPanoramicaV9")==1)
                assert(_count(model,"EscritorioControlV9")==1)
                assert(_count(model,"CristalFrontalFinoV9")==1)
                assert(_count(model,"CristalPosteriorFinoV9")==1)
                var old: MeshInstance3D=model.find_child(
                    "CristalPerimetral",true,false) as MeshInstance3D
                assert(old!=null and not old.visible)
                var pane: MeshInstance3D=model.find_child(
                    "CristalFrontalFinoV9",true,false) as MeshInstance3D
                assert(pane.mesh is BoxMesh)
                assert((pane.mesh as BoxMesh).size.z<=0.032)
                assert(pane.material_override is StandardMaterial3D)
                var glass: StandardMaterial3D=pane.material_override as StandardMaterial3D
                assert(glass.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA)
                assert(glass.albedo_color.a<0.50)
            else:
                assert(stats["thin_glass_panes"]==0)
                assert(_count(model,"CabinaHuecaPanoramicaV9")==0)
            var expected: int=0 if stage==4 else 8 if stage==3 else 12 if stage==2 else 14
            assert(stats["roof_segments_preserved"]==expected)
            assert(stats["roof_batches"]==0 if stage==4 else stats["roof_batches"]==1)
            if stage==0:
                var seam: MeshInstance3D=model.find_child(
                    "JuntaCurvaV6_01",true,false) as MeshInstance3D
                assert(seam!=null)
                var x: float=-3.65+7.30/14.0
                var roof_y: float=2.80+0.73*sin(PI*(x+3.65)/7.30)
                assert(absf(seam.position.y-roof_y)<0.035)
                var storm: Dictionary=Weather.apply(model,"snow",true)
                assert(storm.get("valid",false))
                Weather.clear(model)
                var wet: Dictionary=Weather.apply(model,"rain",true)
                assert(wet.get("valid",false))
                Weather.clear(model)
            model.free()
            total+=1
    assert(total==40)

    for tier in range(1,4):
        var model: Node3D=_make(tier,2,0)
        assert(model.get_meta("tarvoka_airbase_v9_stats")["level"]==tier)
        model.free()

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

    var grid: Node3D=Stress.build_grid(8,4,true,true,true,true)
    assert(grid!=null)
    assert(grid.get_meta("tarvoka_stress_proxy_count")==4)
    assert(grid.get_meta("tarvoka_stress_detail_v9"))
    assert(grid.find_child("CabinaHuecaPanoramicaV9",true,false)!=null)
    grid.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(10)
    assert(studio._role=="airbase")
    assert(studio.airbase_detail_v9_toggle.button_pressed)
    assert(studio.model_root.find_child("CabinaHuecaPanoramicaV9",true,false)!=null)
    assert(studio.airbase_v9_view_picker.item_count==8)

    # V8 baseline remains exactly available in the same viewer.
    studio.airbase_detail_v9_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_detail_v9(false)
    await _frames(8)
    assert(studio.model_root.find_child("CabinaHuecaPanoramicaV9",true,false)==null)
    _shot(studio,"compare_v8")
    studio.airbase_detail_v9_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_detail_v9(true)
    await _frames(8)

    for i in range(8):
        studio.airbase_v9_view_picker.select(i)
        studio._change_airbase_v9_view(i)
        await _frames(6)
        assert(studio._airbase_v9_view==i)
        assert(studio._airbase_camera_interior==(i==6))
        if i==5:
            # 3D panorama uses an orthographic projection: actual closeup
            # requires a reduced frustum, not merely moving the camera.
            assert(studio.camera.projection==Camera3D.PROJECTION_ORTHOGONAL)
            assert(studio.camera.size<=6.0)
        _shot(studio,str(CAPTURES[i]))
    var gate: TarvokaAirbaseDoorRigV2=studio._airbase_gate_rig()
    assert(gate!=null and gate.open_fraction()>0.99)
    studio.airbase_v9_view_picker.select(0)
    studio._change_airbase_v9_view(0)
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(8)
    var damaged: Dictionary=studio.model_root.get_meta("tarvoka_airbase_v9_stats")
    assert(damaged["roof_segments_preserved"]==12)
    assert(damaged["medium_glass_cracks"]==3)
    _shot(studio,"medium_damage")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    assert(studio.model_root.find_child("CabinaHuecaPanoramicaV9",true,false)==null)
    _shot(studio,"critical_damage")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(8)
    assert(studio.model_root.find_child("HangarPrincipalV1",true,false)==null)
    _shot(studio,"ruins")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(6)
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(8)
    _shot(studio,"winter")
    studio.airbase_weather_picker.select(0)
    studio._change_airbase_weather(0)
    await _frames(4)
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(4)
    print("PASS AIRBASE V9: 40 damage/faction combinations, 3 levels, 4 thin glass panels, 20 original animated door parts, roof-seam contact, 8 real camera views and 13 Godot screenshots")
    quit(0)
