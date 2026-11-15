extends SceneTree

# Native Godot 4.3 review for actual Airbase V8 glass, grouped hangar lights
# and localized surface stains. CI software rendering is NOT Android FPS.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar = preload("res://scripts/ui/AirbaseHangarV2.gd")
const V6 = preload("res://scripts/ui/AirbaseExteriorV6.gd")
const V7 = preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const V8 = preload("res://scripts/ui/AirbaseFinishV8.gd")
const Doors = preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Weather = preload("res://scripts/ui/WeatherCoating3D.gd")
const Stress = preload("res://scripts/ui/AirbaseStressV4.gd")
const Scene = preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=6) -> void:
    for _i in range(count):
        await process_frame

func _shot(studio: Control, name: String) -> void:
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png("res://artifacts/"+name)==OK)

func _base(level: int, faction: int, stage: int, finish: bool=true) -> Node3D:
    var model: Node3D=Airbase.build(level,faction,stage)
    assert(model!=null)
    assert(Hangar.apply(model,level,faction,stage))
    assert(V6.apply(model,level,faction,stage))
    assert(V7.apply(model,level,faction,stage))
    if finish:
        assert(V8.apply(model,level,faction,stage))
    return model

func _light_count(node: Node) -> int:
    var count: int=1 if node is OmniLight3D else 0
    for child in node.get_children():
        count+=_light_count(child)
    return count

func _run() -> void:
    var combinations:=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=_base(2,faction,damage)
            assert(model.get_meta("tarvoka_airbase_v8",false))
            assert(not V8.apply(model,2,faction,damage))
            assert(model.find_child(V8.STAGE_NAME,true,false)!=null)
            assert(model.find_child(V8.DIRT_NAME,true,false)!=null)
            assert(model.find_child("LineaUmbralHangarV3",true,false)!=null)
            assert(_light_count(model)==0)
            var stats: Dictionary=model.get_meta("tarvoka_airbase_v8_stats",{})
            assert(stats["dirt_batches"]==1)
            assert(stats["faction"]==faction)
            assert(stats["stage"]==damage)
            assert(stats["level"]==2)
            assert(stats["interior_light_batches"]<=V8.MAX_LIGHT_BATCHES)
            if damage<=2:
                assert(stats["glass_panels"]>=1)
                assert(stats["glass_glint_batches"]==1)
                assert(stats["interior_light_batches"]==2)
                assert(model.find_child(V8.LIGHT_NAME,true,false)!=null)
                assert(model.find_child(V8.POOL_NAME,true,false)!=null)
                assert(stats["interior_lights"]==(2 if damage==2 else 4))
            else:
                assert(stats["interior_lights"]==0)
                assert(stats["glass_glint_batches"]==0)
            if damage==4:
                assert(stats["glass_panels"]==0)
                assert(model.find_child("HangarPrincipalV1",true,false)==null)
            model.free()
            combinations+=1
    assert(combinations==40)

    for tier in range(1,4):
        var model: Node3D=_base(tier,3,0)
        assert(model.get_meta("tarvoka_airbase_v8_stats")["level"]==tier)
        model.free()

    # Compare real materials and ensure emblem/doors/weather stay unaltered.
    var model: Node3D=_base(2,0,0,false)
    var emblem: MeshInstance3D=model.find_child(
        "EmblemaOficialAtlasBaseAerea",true,false) as MeshInstance3D
    var glass: MeshInstance3D=model.find_child(
        "CristalPerimetral",true,false) as MeshInstance3D
    assert(emblem!=null and glass!=null)
    var emblem_mat: Material=emblem.material_override
    var old_mat: Material=glass.material_override
    assert(V8.apply(model,2,0,0))
    assert(emblem.material_override==emblem_mat)
    assert(glass.material_override!=old_mat)
    assert(glass.get_meta("tarvoka_airbase_v8_glass",false))
    var finish: StandardMaterial3D=glass.material_override as StandardMaterial3D
    assert(finish!=null)
    assert(finish.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA)
    assert(finish.metallic_specular>=0.80)
    assert(finish.albedo_color.a<0.9)
    var rain: Dictionary=Weather.apply(model,"rain")
    assert(rain.get("valid",false))
    assert(emblem.material_override==emblem_mat)
    Weather.clear(model)
    assert(glass.material_override==finish)
    var snow: Dictionary=Weather.apply(model,"snow",true)
    assert(snow.get("valid",false))
    assert(snow.get("snow_nodes",999)<=Weather.MAX_ECO_SNOW_NODES)
    Weather.clear(model)
    assert(glass.material_override==finish)
    model.add_child(Doors.build(0))
    root.add_child(model)
    await _frames(3)
    var rig: TarvokaAirbaseDoorRigV2=model.get_node(Doors.STAGE_NAME) as TarvokaAirbaseDoorRigV2
    assert(rig!=null and rig.is_operational() and rig.gate_mesh_count()==20)
    rig.set_open_fraction(1.0)
    assert(rig.open_fraction()>0.99)
    model.queue_free()
    await _frames(3)

    # In 64-building scenarios V8 never expands all distant proxy models.
    var stress: Node3D=Stress.build_grid(8,4,true,true,true)
    assert(stress!=null)
    assert(stress.get_meta("tarvoka_stress_finish_v8",false))
    assert(stress.get_meta("tarvoka_stress_proxy_count")==4)
    assert(stress.find_child(V8.STAGE_NAME,true,false)!=null)
    stress.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Scene.instantiate()
    root.add_child(studio)
    await _frames(12)
    studio._switch_category(1)
    await _frames(4)
    studio._change_selected_building(1)
    await _frames(11)
    assert(studio._role=="airbase")
    assert(studio.airbase_finish_v8_toggle!=null)
    assert(studio.airbase_finish_v8_toggle.button_pressed)
    assert(studio.model_root.find_child(V8.STAGE_NAME,true,false)!=null)
    _shot(studio,"tarvoka_airbase_v8_exterior.png")

    studio.airbase_finish_v8_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_finish_v8(false)
    await _frames(9)
    assert(studio.model_root.find_child(V8.STAGE_NAME,true,false)==null)
    _shot(studio,"tarvoka_airbase_v8_compare_v7.png")
    studio.airbase_finish_v8_toggle.set_pressed_no_signal(true)
    studio._toggle_airbase_finish_v8(true)
    await _frames(8)
    studio._toggle_airbase_camera()
    await _frames(8)
    assert(studio.airbase_open_button.disabled==false)
    _shot(studio,"tarvoka_airbase_v8_hangar_illumination.png")
    studio._toggle_airbase_camera()
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(9)
    assert(studio.airbase_open_button.disabled)
    _shot(studio,"tarvoka_airbase_v8_medium_damage.png")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    assert(studio.model_root.find_child(V8.LIGHT_NAME,true,false)==null)
    _shot(studio,"tarvoka_airbase_v8_critical_damage.png")
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(8)
    assert(studio.model_root.find_child("HangarPrincipalV1",true,false)==null)
    _shot(studio,"tarvoka_airbase_v8_destroyed.png")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(7)
    studio.airbase_weather_picker.select(1)
    studio._change_airbase_weather(1)
    await _frames(9)
    _shot(studio,"tarvoka_airbase_v8_rain.png")
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(9)
    _shot(studio,"tarvoka_airbase_v8_snow.png")
    studio._change_selected_building(0)
    await _frames(8)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(5)
    print("PASS AIRBASE V8 VISUAL: 40 faction/damage states, 3 tiers, protected crests, 20 gate meshes, 2 interior light batches, clearcoat glass, reversible rain/snow, and 8 authentic Godot captures")
    quit(0)
