extends SceneTree

# V7 original PBR maps and staged physical wear in REAL native Godot 4.3.
# CI can verify graphics & render samples; this is not an Android FPS test.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar = preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6 = preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7 = preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const Weather = preload("res://scripts/ui/WeatherCoating3D.gd")
const Doors = preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Stress = preload("res://scripts/ui/AirbaseStressV4.gd")
const Studio = preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=6) -> void:
    for _i in range(count):
        await process_frame

func _shot(studio: Control,name: String) -> void:
    var image: Image = studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png("res://artifacts/"+name)==OK)

func _run() -> void:
    var tested := 0
    for faction in range(8):
        for damage in range(5):
            var base: Node3D = Airbase.build(2,faction,damage)
            assert(base!=null)
            assert(Hangar.apply(base,2,faction,damage))
            assert(V6.apply(base,2,faction,damage))
            assert(V7.apply(base,2,faction,damage))
            assert(not V7.apply(base,2,faction,damage))
            var stats: Dictionary = base.get_meta("tarvoka_airbase_v7_stats",{})
            assert(stats["coated"]>=12)
            assert(stats["protected"]>0)
            assert(stats["wear_batches"]==1 if damage==0 else
                stats["wear_batches"]==2)
            assert(stats["steel"]>0)
            assert(stats["concrete"]>0)
            assert(stats["asphalt"]>0)
            assert(stats["stage"]==damage)
            assert(stats["faction"]==faction)
            assert(base.find_child("DesgastePistaYCombustibleV7",true,false)!=null)
            assert(base.find_child("OxidoYHollinDeImpactosV7",true,false)==null
                if damage==0 else base.find_child(
                "OxidoYHollinDeImpactosV7",true,false)!=null)
            assert(base.find_child("LineaUmbralHangarV3",true,false)!=null)
            assert(base.find_child("EmblemaOficialAtlasBaseAerea",true,false)!=null
                if damage!=4 else base.find_child(
                "EmblemaOficialAtlasBaseAerea",true,false)==null)
            if damage<4:
                assert(stats["roof"]>0)
                assert(stats["glass"]>0 if damage<3 else true)
            else:
                assert(base.find_child("HangarPrincipalV1",true,false)==null)
            base.free()
            tested+=1
    assert(tested==40)
    for tier in range(1,4):
        var model: Node3D=Airbase.build(tier,3,0)
        assert(Hangar.apply(model,tier,3,0))
        assert(V6.apply(model,tier,3,0))
        assert(V7.apply(model,tier,3,0))
        assert(model.get_meta("tarvoka_airbase_v7_stats")["level"]==tier)
        model.free()

    # The original safety paint, official crests and future weather changes
    # must never be overwritten by the V7 texture maps.
    var model: Node3D=Airbase.build(2,0,0)
    assert(Hangar.apply(model,2,0,0))
    assert(V6.apply(model,2,0,0))
    var emblem: MeshInstance3D=model.find_child(
        "EmblemaOficialAtlasBaseAerea",true,false) as MeshInstance3D
    assert(emblem!=null)
    var emblem_material: Material=emblem.material_override
    assert(V7.apply(model,2,0,0))
    assert(emblem.material_override==emblem_material)
    var concrete: MeshInstance3D=model.find_child(
        "FusteHormigonTorre",true,false) as MeshInstance3D
    assert(concrete!=null and concrete.material_override is StandardMaterial3D)
    var original: Material=concrete.material_override
    var pbr: StandardMaterial3D=original as StandardMaterial3D
    assert(pbr.albedo_texture!=null)
    assert(pbr.roughness_texture!=null)
    assert(pbr.normal_enabled and pbr.normal_texture!=null)
    var rain: Dictionary=Weather.apply(model,"rain")
    assert(rain.get("valid",false))
    assert(concrete.material_override!=original)
    Weather.clear(model)
    assert(concrete.material_override==original)
    assert(emblem.material_override==emblem_material)
    var snow: Dictionary=Weather.apply(model,"snow",true)
    assert(snow.get("valid",false))
    assert(snow.get("snow_nodes",999)<=Weather.MAX_ECO_SNOW_NODES)
    Weather.clear(model)
    assert(concrete.material_override==original)
    model.add_child(Doors.build(0))
    root.add_child(model)
    await _frames(2)
    var doors: TarvokaAirbaseDoorRigV2=model.get_node(
        Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(doors!=null and doors.is_operational())
    assert(doors.gate_mesh_count()==20)
    doors.set_open_fraction(1.0)
    assert(doors.open_fraction()>0.995)
    model.queue_free()
    await _frames(3)

    var near: Node3D=Stress.build_grid(8,4,true,true)
    assert(near!=null)
    assert(near.get_meta("tarvoka_stress_proxy_count")==4)
    assert(near.get_meta("tarvoka_stress_materials_v7",false))
    assert(near.find_child(V7.STAGE_NAME,true,false)!=null)
    near.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(4)
    studio._change_selected_building(1)
    await _frames(10)
    assert(studio._role=="airbase")
    assert(studio.airbase_material_v7_toggle!=null)
    assert(studio.airbase_material_v7_toggle.button_pressed)
    assert(studio.model_root.find_child(V7.STAGE_NAME,true,false)!=null)
    _shot(studio,"tarvoka_airbase_v7_materials_clean.png")
    studio.airbase_material_v7_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_material_v7(false)
    await _frames(8)
    assert(studio.model_root.find_child(V7.STAGE_NAME,true,false)==null)
    _shot(studio,"tarvoka_airbase_v7_compare_v6.png")
    studio.airbase_material_v7_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_material_v7(true)
    await _frames(8)
    studio._toggle_airbase_camera()
    await _frames(6)
    _shot(studio,"tarvoka_airbase_v7_hangar_interior.png")
    studio._toggle_airbase_camera()
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(8)
    assert(studio.airbase_open_button.disabled)
    _shot(studio,"tarvoka_airbase_v7_damage_medium.png")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    _shot(studio,"tarvoka_airbase_v7_damage_critical.png")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(8)
    _shot(studio,"tarvoka_airbase_v7_ruins.png")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(8)
    studio.airbase_weather_picker.select(1)
    studio._change_airbase_weather(1)
    await _frames(8)
    _shot(studio,"tarvoka_airbase_v7_rain_pbr.png")
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(8)
    _shot(studio,"tarvoka_airbase_v7_snow_pbr.png")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(4)
    print("PASS AIRBASE V7 PBR: 40 faction/damage variants, 3 architectural levels, 5 reusable original texture sets, progressive physical weathering, 20 gate meshes, rain/snow reversibility and Godot Studio captures")
    quit(0)
