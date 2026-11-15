extends SceneTree

# Native Godot 4.3 3D visual QA. Validates the physical model and compares
# the EXACT V4 studio view with optional V6 architecture. Not Android FPS.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar = preload("res://scripts/ui/AirbaseHangarV2.gd")
const Exterior = preload("res://scripts/ui/AirbaseExteriorV6.gd")
const Doors = preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Stress = preload("res://scripts/ui/AirbaseStressV4.gd")
const Scene = preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=6) -> void:
    for _i in range(count):
        await process_frame

func _capture(studio: Control,filename: String) -> void:
    var shot: Image = studio.preview.get_texture().get_image()
    assert(shot!=null and shot.get_width()>400 and shot.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(shot.save_png("res://artifacts/"+filename)==OK)

func _run() -> void:
    # The external shell has no duplicated full hangar, no modified
    # original dimensions and no fake aircraft production mechanics.
    var configurations := 0
    for faction in range(8):
        for damage in range(5):
            var v1: Node3D = Airbase.build(2,faction,damage)
            assert(v1!=null and Hangar.apply(v1,2,faction,damage))
            var base_meshes: int = Airbase.mesh_count(v1)
            assert(Exterior.apply(v1,2,faction,damage))
            assert(v1.get_meta("tarvoka_airbase_v6",false))
            assert(v1.get_meta("tarvoka_airbase_v6_faction",-1)==faction)
            assert(v1.get_meta("tarvoka_airbase_v6_damage",-1)==damage)
            assert(not Exterior.apply(v1,2,faction,damage))
            assert(Airbase.mesh_count(v1)>base_meshes)
            assert(v1.find_child("MarcasAeronauticasYDrainajeV6",true,false)!=null)
            assert(v1.find_child("FlechaRodajeTalloV6",true,false)!=null)
            if damage==4:
                assert(v1.find_child("RestosEstructuralesBaseAereaV6",true,false)!=null)
                assert(v1.find_child("HangarPrincipalV1",true,false)==null)
                assert(v1.find_child("TorreControlAereoV1",true,false)==null)
            else:
                assert(v1.find_child("FachadasPanelizadasHangarV6",true,false)!=null)
                assert(v1.find_child("CostillasCubiertaCurvaV6",true,false)!=null)
                assert(v1.find_child("TorreAeroNavegacionV6",true,false)!=null)
                assert(v1.find_child("LineaUmbralHangarV3",true,false)!=null)
                if damage<3:
                    assert(v1.find_child("PatioMantenimientoAeronauticoV6",true,false)!=null)
            v1.free()
            configurations+=1
    for tier in range(1,4):
        var sample: Node3D = Airbase.build(tier,0,0)
        assert(Hangar.apply(sample,tier,0,0))
        assert(Exterior.apply(sample,tier,0,0))
        assert(sample.get_meta("tarvoka_airbase_v6_level")==tier)
        sample.free()
    assert(configurations==40)
    assert(Exterior.apply(null,1,0,0)==false)

    var low: Node3D = Stress.build_grid(8,4,false)
    assert(low.get_meta("tarvoka_stress_exterior_v6")==false)
    assert(low.find_child(Exterior.STAGE_NAME,true,false)==null)
    low.free()
    var high: Node3D = Stress.build_grid(8,4,true)
    assert(high.get_meta("tarvoka_stress_exterior_v6")==true)
    assert(high.find_child(Exterior.STAGE_NAME,true,false)!=null)
    assert(high.get_meta("tarvoka_stress_proxy_count")==4)
    high.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control = Scene.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(1)
    await _frames(12)
    assert(studio._role=="airbase")
    assert(studio.airbase_exterior_v6_toggle!=null)
    assert(studio.airbase_exterior_v6_toggle.button_pressed)
    assert(studio.model_root.find_child(Exterior.STAGE_NAME,true,false)!=null)
    assert(studio.model_root.find_child("LineaUmbralHangarV3",true,false)!=null)
    _capture(studio,"tarvoka_airbase_v6_after_clean.png")

    studio.airbase_exterior_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_exterior_v6(false)
    await _frames(10)
    assert(studio.model_root.find_child(Exterior.STAGE_NAME,true,false)==null)
    _capture(studio,"tarvoka_airbase_v6_before_v4.png")
    studio.airbase_exterior_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_exterior_v6(true)
    await _frames(10)
    assert(studio.model_root.find_child(Exterior.STAGE_NAME,true,false)!=null)
    assert(studio.airbase_open_button.disabled==false)
    studio._play_airbase_doors(true)
    await _frames(6)
    var rig: TarvokaAirbaseDoorRigV2 = studio._airbase_gate_rig()
    assert(rig!=null and rig.is_operational())
    assert(rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    _capture(studio,"tarvoka_airbase_v6_hangar_open.png")

    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(10)
    assert(studio.model_root.find_child(Exterior.STAGE_NAME,true,false)!=null)
    assert(studio.airbase_open_button.disabled)
    _capture(studio,"tarvoka_airbase_v6_moderate_damage.png")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(10)
    _capture(studio,"tarvoka_airbase_v6_critical.png")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(10)
    assert(studio.model_root.find_child("RestosEstructuralesBaseAereaV6",true,false)!=null)
    assert(studio.airbase_open_button.disabled)
    _capture(studio,"tarvoka_airbase_v6_ruins.png")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(8)
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(12)
    assert(studio.model_root.find_child(Exterior.STAGE_NAME,true,false)!=null)
    _capture(studio,"tarvoka_airbase_v6_snow.png")
    studio.airbase_weather_picker.select(0)
    studio._change_airbase_weather(0)
    await _frames(6)
    studio._change_selected_building(0)
    await _frames(8)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(6)
    print("PASS AIRBASE V6 VISUAL: 40 faction/damage combinations, 3 architectural levels, 20 operating gate pieces, V4/V6 comparison, 5 damage stages, winter, 8x LOD and HQ regression")
    quit(0)
