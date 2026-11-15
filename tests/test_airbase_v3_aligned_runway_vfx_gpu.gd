extends SceneTree

# Godot 4.3 native GPU regression test, not an inferred screenshot.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Hangar = preload("res://scripts/ui/AirbaseHangarV2.gd")
const Smoke = preload("res://scripts/ui/AirbaseDamageFXV3.gd")
const Hits = preload("res://scripts/ui/AirbaseImpactV3.gd")
const Doors = preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const Scene = preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_test")

func _frames(n: int = 6) -> void:
    for _i in range(n):
        await process_frame

func _image(studio: Control,file_name: String) -> Image:
    var shot: Image = studio.preview.get_texture().get_image()
    assert(shot!=null and shot.get_width()>400)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(shot.save_png("res://artifacts/"+file_name)==OK)
    return shot

func _diff(a: Image,b: Image) -> int:
    var first: Image = a.duplicate()
    var second: Image = b.duplicate()
    first.resize(210,160)
    second.resize(210,160)
    var change := 0
    for yy in range(0,160,2):
        for xx in range(0,210,2):
            var c: Color = first.get_pixel(xx,yy)
            var d: Color = second.get_pixel(xx,yy)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.13:
                change+=1
    return change

func _runway(model: Node3D) -> void:
    var pad: Node3D = model.find_child("PlataformaYRodaduras",true,false) as Node3D
    assert(pad!=null and pad.get_meta("tarvoka_airbase_v3_taxiway_aligned",false))
    var hangar: Node3D = model.get_node_or_null("HangarPrincipalV1") as Node3D
    var road: MeshInstance3D = pad.get_node_or_null("CarrilRodaje") as MeshInstance3D
    var line: MeshInstance3D = pad.get_node_or_null("LineaUmbralHangarV3") as MeshInstance3D
    assert(road!=null and line!=null)
    assert(is_equal_approx(road.position.x,Airbase.HANGAR_CENTER_X))
    assert(is_equal_approx(line.position.x,Airbase.HANGAR_CENTER_X))
    assert(road.mesh is BoxMesh)
    assert(absf((road.mesh as BoxMesh).size.x-6.40)<0.01)
    assert(absf(road.position.z-Airbase.TAXIWAY_CENTER_Z)<0.001)
    assert(absf(line.position.z-(Airbase.HANGAR_FRONT_Z-0.13))<0.001)
    assert(is_equal_approx((pad.get_node("RayaDiscontinuaRodaje_2") as MeshInstance3D).position.x,
        Airbase.HANGAR_CENTER_X))
    for side in [-1,1]:
        var marking: MeshInstance3D = pad.get_node(
            "LineaSeguridadLateral_%s" % side) as MeshInstance3D
        assert(absf(marking.position.x-(Airbase.HANGAR_CENTER_X+float(side)*3.04))<0.003)
    if hangar!=null:
        assert(absf(hangar.position.x-road.position.x)<0.0001)
        assert(absf((hangar.position.z-3.345)-Airbase.HANGAR_FRONT_Z)<0.005)
        var gate: MeshInstance3D = hangar.get_node_or_null("CompuertaPrincipal_1") as MeshInstance3D
        if gate!=null:
            assert(absf((gate.global_position.x-road.position.x))<3.3)

func _test() -> void:
    var maximum := 0
    for faction in range(8):
        for tier in range(1,4):
            for stage in range(5):
                var building: Node3D = Airbase.build(tier,faction,stage)
                assert(building!=null)
                _runway(building)
                assert(Hangar.apply(building,tier,faction,stage))
                if stage<4:
                    assert(building.find_child("MuroTraseroCerrado",true,false)!=null)
                    assert(building.find_child("EmblemaOficialAtlasBaseAerea",true,false)!=null)
                if stage in [2,3]:
                    var effects: TarvokaAirbaseDamageFXV3 = Smoke.build(stage)
                    building.add_child(effects)
                    root.add_child(building)
                    await _frames(1)
                    assert(effects.is_active())
                    assert(effects.smoke_instance_count()==(6 if stage==2 else 12))
                    assert(effects.flame_batch_count()==(0 if stage==2 else 1))
                    effects.advance(0.23)
                    effects.set_mobile_quality(true)
                    assert(effects.smoke_instance_count()==(4 if stage==2 else 8))
                    effects.set_distant(true)
                    assert(not effects.is_active() and not effects.is_processing())
                    effects.set_distant(false)
                    assert(effects.is_active() and effects.is_processing())
                    root.remove_child(building)
                else:
                    assert(building.find_child(Smoke.STAGE_NAME,true,false)==null)
                maximum=maxi(maximum,Airbase.mesh_count(building))
                building.free()

    # Reuse the tested detailed 3D bullet and explosive effects at exact
    # AIRBASE hit positions. No fake game HP or battle session changes.
    var hit_model: Node3D = Airbase.build(1,0,0)
    var impact := TarvokaAirbaseImpactV3.new()
    hit_model.add_child(impact)
    root.add_child(hit_model)
    await _frames(3)
    assert(impact.name==Hits.AIRBASE_NAME)
    assert(impact.trigger_airbase("bullet"))
    assert(impact.is_running() and impact.current_kind()=="bullet")
    assert(impact.active_mesh_batches()==1)
    assert(not impact.trigger_airbase("inexistent"))
    impact.stop()
    assert(impact.trigger_airbase("explosive"))
    assert(impact.current_kind()=="explosive")
    assert(impact.active_mesh_batches()==6)
    impact.stop()
    hit_model.queue_free()
    await _frames(4)

    root.content_scale_size = Vector2i(1280,800)
    var studio: Control = Scene.instantiate()
    root.add_child(studio)
    await _frames(9)
    studio._switch_category(1)
    await _frames(4)
    studio._change_selected_building(1)
    await _frames(8)
    assert(studio._role=="airbase")
    assert(studio.building_picker.item_count==2)
    assert(studio.airbase_open_button!=null and not studio.airbase_open_button.disabled)
    assert(studio.airbase_impact_bullet_button!=null)
    assert(not studio.airbase_impact_bullet_button.disabled)
    assert(studio.airbase_impact_explosive_button!=null)
    _runway(studio.model_root)
    var clear_img: Image = _image(studio,"tarvoka_airbase_v3_aligned_runway.png")
    studio._play_airbase_doors(true)
    var door: TarvokaAirbaseDoorRigV2 = studio._airbase_gate_rig()
    door.advance(Doors.MOTION_SECONDS+0.2)
    await _frames(5)
    assert(door.open_fraction()>0.99)
    _image(studio,"tarvoka_airbase_v3_runway_open_hangar.png")
    studio._play_airbase_impact("bullet")
    await _frames(3)
    assert(studio._airbase_impact_rig().current_kind()=="bullet")
    var bullet: Image = _image(studio,"tarvoka_airbase_v3_bullet_hit.png")
    assert(_diff(clear_img,bullet)>12)
    studio._play_airbase_impact("explosive")
    await _frames(3)
    assert(studio._airbase_impact_rig().current_kind()=="explosive")
    var explosive: Image = _image(studio,"tarvoka_airbase_v3_explosion_hit.png")
    assert(_diff(bullet,explosive)>12)
    var hit: TarvokaAirbaseImpactV3 = studio._airbase_impact_rig()
    hit.stop()
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(8)
    assert(studio._airbase_gate_rig()==null)
    assert(studio.airbase_open_button.disabled)
    var medium: TarvokaAirbaseDamageFXV3 = studio.model_root.get_node(
        Smoke.STAGE_NAME) as TarvokaAirbaseDamageFXV3
    assert(medium!=null and medium.is_active())
    assert(medium.flame_batch_count()==0)
    var medium_img: Image = _image(studio,"tarvoka_airbase_v3_medium_smoke.png")
    studio.airbase_mobile_fx_toggle.button_pressed = true
    studio._set_airbase_mobile_vfx(true)
    assert(medium.smoke_instance_count()==4)
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    var fire: TarvokaAirbaseDamageFXV3 = studio.model_root.get_node(
        Smoke.STAGE_NAME) as TarvokaAirbaseDamageFXV3
    assert(fire!=null and fire.flame_batch_count()==1)
    assert(fire.smoke_instance_count()==8)
    fire.advance(0.33)
    var critical_img: Image = _image(studio,"tarvoka_airbase_v3_critical_fire.png")
    assert(_diff(medium_img,critical_img)>15)
    studio.airbase_damage_picker.select(4)
    studio._change_airbase_damage(4)
    await _frames(6)
    assert(studio._airbase_impact_rig()==null)
    assert(studio.airbase_impact_bullet_button.disabled)
    assert(studio.model_root.find_child("HangarPrincipalV1",true,false)==null)
    _runway(studio.model_root)
    _image(studio,"tarvoka_airbase_v3_ruins.png")
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    studio._on_faction(6)
    studio._refresh_building_faction(6)
    await _frames(7)
    assert(studio.model_root.get_meta("visual_faction",-1)==6)
    _runway(studio.model_root)
    _image(studio,"tarvoka_airbase_v3_aligned_turquoise.png")
    studio.airbase_weather_picker.select(2)
    studio._change_airbase_weather(2)
    await _frames(8)
    assert(studio.model_root.get_meta("weather_coating",{}).get("mode","")=="snow")
    _image(studio,"tarvoka_airbase_v3_runway_snow.png")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    studio.queue_free()
    await _frames(5)
    print("PASS AIRBASE V3: runway/hangar same X with 2.75 m old alignment fixed, 8 factions x 3 tiers x 5 stages, bullet+explosive GPU reactions, medium smoke, critical smoke/fire, mobile LOD, door/HQ/Android weather regressions; %d meshes" % maximum)
    quit(0)
