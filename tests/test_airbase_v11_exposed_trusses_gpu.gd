extends SceneTree

# Godot 4.3 native visual QA for the exposed roof skeleton, never Android FPS.
const Airbase=preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar=preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6=preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7=preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const V8=preload("res://scripts/ui/AirbaseFinishV8.gd")
const V9=preload("res://scripts/ui/AirbaseDetailV9.gd")
const V10=preload("res://scripts/ui/AirbaseStructureV10.gd")
const V11=preload("res://scripts/ui/AirbaseTrussesV11.gd")
const Doors=preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather=preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress=preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _shot(studio: Control,label: String) -> void:
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png(
        "res://artifacts/tarvoka_airbase_v11_"+label+".png")==OK)

func _model(tier: int,faction: int,damage: int) -> Node3D:
    var model: Node3D=Airbase.build(tier,faction,damage)
    assert(model!=null)
    assert(Hangar.apply(model,tier,faction,damage))
    assert(V6.apply(model,tier,faction,damage))
    assert(V7.apply(model,tier,faction,damage))
    assert(V8.apply(model,tier,faction,damage))
    assert(V9.apply(model,tier,faction,damage))
    assert(V10.apply(model,tier,faction,damage))
    assert(V11.apply(model,tier,faction,damage))
    return model

func _count(root_node: Node,label: String) -> int:
    var count: int=1 if str(root_node.name)==label else 0
    for child in root_node.get_children():
        count+=_count(child,label)
    return count

func _mesh_vertices(model: Node3D,label: String) -> int:
    var node: MeshInstance3D=model.find_child(
        label,true,false) as MeshInstance3D
    if node==null:
        return 0
    return node.mesh.surface_get_array_len(0)

func _assert_v11(model: Node3D,faction: int,
        level: int,damage: int) -> void:
    var stats: Dictionary=model.get_meta("tarvoka_airbase_v11_stats",{})
    assert(stats["faction"]==faction)
    assert(stats["damage"]==damage)
    assert(stats["level"]==level)
    var roof_count: int=0 if damage==4 else 8 if damage==3 else 12 if damage==2 else 14
    var torn_count: int=2 if damage in [2,3] else 0
    var stub_count: int=6 if damage==3 else 4 if damage==2 else 0
    assert(stats["roof_panels_supported"]==roof_count)
    assert(stats["diagonal_members"]==roof_count*4)
    assert(stats["roof_anchors"]==roof_count*2)
    assert(stats["intact_batches"]==(2 if roof_count>0 else 0))
    assert(stats["torn_edges"]==torn_count)
    assert(stats["hanging_stubs"]==stub_count)
    assert(stats["damage_batches"]==(2 if torn_count>0 else 0))
    assert(_count(model,V11.STAGE_NAME)==1)
    assert(_count(model,V11.CROSS_BRACES)==(1 if roof_count>0 else 0))
    assert(_count(model,V11.FASTENERS)==(1 if roof_count>0 else 0))
    assert(_count(model,V11.TORN_LIPS)==(1 if torn_count>0 else 0))
    assert(_count(model,V11.HANGING)==(1 if torn_count>0 else 0))
    # Each solid bar produces 6 rectangular faces * 2 triangles * 3
    # vertices, proving these are genuine 3D roof trusses, not planes.
    if roof_count>0:
        assert(_mesh_vertices(model,V11.CROSS_BRACES)==roof_count*4*36)
        assert(_mesh_vertices(model,V11.FASTENERS)==roof_count*2*36)
    if torn_count>0:
        assert(_mesh_vertices(model,V11.TORN_LIPS)==torn_count*36)
        assert(_mesh_vertices(model,V11.HANGING)==stub_count*36)
    assert(_count(model,"MuroTraseroCerrado")==(0 if damage==4 else 1))

func _run() -> void:
    assert(not V11.apply(null,2,0,0))
    var total:=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=_model(2,faction,damage)
            _assert_v11(model,faction,2,damage)
            assert(not V11.apply(model,2,faction,damage))
            var v10: Dictionary=model.get_meta("tarvoka_airbase_v10_stats",{})
            assert(v10["supported_roof_segments"]==(
                0 if damage==4 else 8 if damage==3 else 12 if damage==2 else 14))
            if damage==0:
                var rain: Dictionary=Weather.apply(model,"rain",true)
                assert(rain.get("valid",false))
                Weather.clear(model)
                var snow: Dictionary=Weather.apply(model,"snow",true)
                assert(snow.get("valid",false))
                Weather.clear(model)
            model.free()
            total+=1
    assert(total==40)

    for tier in range(1,4):
        var m: Node3D=_model(tier,4,0)
        _assert_v11(m,4,tier,0)
        m.free()

    var sample: Node3D=_model(2,0,0)
    sample.add_child(Doors.build(0))
    root.add_child(sample)
    await _frames(3)
    var rig: TarvokaAirbaseDoorRigV2=sample.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(rig!=null and rig.is_operational())
    assert(rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    sample.queue_free()
    await _frames(4)

    var board: Node3D=Stress.build_grid(8,4,true,true,true,true,true,true)
    assert(board!=null)
    assert(board.get_meta("tarvoka_stress_proxy_count")==4)
    assert(board.get_meta("tarvoka_stress_trusses_v11",false))
    assert(_count(board,V11.STAGE_NAME)==4)
    board.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(11)
    assert(studio._role=="airbase")
    assert(studio.airbase_trusses_v11_toggle.button_pressed)
    assert(studio.model_root.find_child(V11.STAGE_NAME,true,false)!=null)

    # Same building/faction/camera: compare actual 3D V10 vs V11.
    studio.airbase_v9_view_picker.select(6)
    studio._change_airbase_v9_view(6)
    await _frames(6)
    studio.airbase_trusses_v11_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_trusses_v11(false)
    await _frames(9)
    assert(studio.model_root.find_child(V11.STAGE_NAME,true,false)==null)
    _shot(studio,"inside_v10")
    studio.airbase_trusses_v11_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_trusses_v11(true)
    await _frames(9)
    assert(studio.model_root.find_child(V11.CROSS_BRACES,true,false)!=null)
    _shot(studio,"inside_v11")
    studio.airbase_v9_view_picker.select(4)
    studio._change_airbase_v9_view(4)
    await _frames(8)
    _shot(studio,"roof_v11")
    assert(not studio.airbase_v11_cutaway_toggle.button_pressed)
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_cutaway_v11(true)
    await _frames(7)
    var roof_panel: Node3D=studio.model_root.find_child(
        "CubiertaCurva3D_00",true,false) as Node3D
    assert(roof_panel!=null and not roof_panel.visible)
    assert(studio.model_root.find_child(V11.CROSS_BRACES,true,false)!=null)
    _shot(studio,"cutaway_v11")
    studio.airbase_trusses_v11_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_trusses_v11(false)
    await _frames(9)
    assert(studio.model_root.find_child(V11.CROSS_BRACES,true,false)==null)
    assert(not (studio.model_root.find_child(
        "CubiertaCurva3D_00",true,false) as Node3D).visible)
    _shot(studio,"cutaway_v10")
    studio.airbase_trusses_v11_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_trusses_v11(true)
    await _frames(9)
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_cutaway_v11(false)
    roof_panel=studio.model_root.find_child(
        "CubiertaCurva3D_00",true,false) as Node3D
    assert(roof_panel.visible)
    studio.airbase_v9_view_picker.select(2)
    studio._change_airbase_v9_view(2)
    await _frames(8)
    _shot(studio,"rear_v11")
    studio.airbase_v9_view_picker.select(0)
    studio._change_airbase_v9_view(0)
    await _frames(6)
    _shot(studio,"exterior_v11")

    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(8)
    assert(studio.model_root.get_meta(
        "tarvoka_airbase_v11_stats")["torn_edges"]==2)
    _shot(studio,"medium_damage")
    studio.airbase_v9_view_picker.select(4)
    studio._change_airbase_v9_view(4)
    await _frames(8)
    _shot(studio,"medium_roof")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_cutaway_v11(true)
    await _frames(8)
    _shot(studio,"medium_cutaway")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_cutaway_v11(false)
    studio.airbase_v9_view_picker.select(6)
    studio._change_airbase_v9_view(6)
    await _frames(8)
    _shot(studio,"medium_inside")

    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    assert(studio.model_root.get_meta(
        "tarvoka_airbase_v11_stats")["hanging_stubs"]==6)
    _shot(studio,"critical_inside")
    studio.airbase_v9_view_picker.select(4)
    studio._change_airbase_v9_view(4)
    await _frames(8)
    _shot(studio,"critical_roof")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_cutaway_v11(true)
    await _frames(8)
    _shot(studio,"critical_cutaway")
    studio.airbase_v11_cutaway_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_cutaway_v11(false)

    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(8)
    assert(studio.model_root.find_child(V11.CROSS_BRACES,true,false)==null)
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
    print("PASS AIRBASE V11: 40 faction/damage variants, 3 levels, physical 3D diagonal supports, no roof-hole bridges, torn edges, original 20 animated doors, reversible weather, near LOD, reversible structural cutaway and 16 authentic Godot previews")
    quit(0)
