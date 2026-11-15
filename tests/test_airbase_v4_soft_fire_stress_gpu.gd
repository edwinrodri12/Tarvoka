extends SceneTree

# Native Godot 4.3 CI: soft fire/smoke, real per-building LOD, 8/32/64
# building scene stress. CI uses llvmpipe; Android physical FPS NOT measured.
const Airbase = preload("res://scripts/ui/Airbase3DV1.gd")
const Soft = preload("res://scripts/ui/AirbaseDamageFXV4.gd")
const Proxy = preload("res://scripts/ui/AirbaseMapLODV4.gd")
const Stress = preload("res://scripts/ui/AirbaseStressV4.gd")
const Scene = preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=6) -> void:
    for _i in range(count):
        await process_frame

func _shot(studio: Control,name: String) -> void:
    var img: Image = studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png("res://artifacts/"+name)==OK)

func _run() -> void:
    var total_variants := 0
    for faction in range(8):
        for tier in range(1,4):
            for stage in range(5):
                var p: MeshInstance3D = Proxy.build_proxy(tier,faction,stage)
                assert(p!=null)
                assert(p.get_meta("tarvoka_airbase_lod_proxy_v4",false))
                assert(Proxy.surface_budget(p)==4)
                assert(p.get_meta("visual_faction",-1)==faction)
                assert(p.get_meta("visual_damage_stage",-1)==stage)
                var clone: MeshInstance3D = Proxy.build_proxy(tier,faction,stage)
                assert(clone.mesh==p.mesh)
                p.free()
                clone.free()
                total_variants+=1
    assert(total_variants==120 and Proxy.cache_entries()>=120)
    assert(Proxy.build_proxy(0,0,0)==null)
    assert(Stress.build_grid(6)==null)
    assert(Stress.build_grid(64,-1)==null)

    var max_draws := 0
    for count in [8,32,64]:
        var model: Node3D = Stress.build_grid(count)
        assert(model!=null)
        assert(model.get_child_count()==count)
        assert(model.get_meta("tarvoka_stress_near_count",-1)==4)
        assert(model.get_meta("tarvoka_stress_proxy_count",-1)==count-4)
        assert(model.get_meta("tarvoka_stress_active_fx_count",-1)==2)
        var proxy_count := 0
        var full_count := 0
        for item in model.get_children():
            if item.get_meta("tarvoka_airbase_lod_proxy_v4",false):
                proxy_count+=1
                assert(item is MeshInstance3D and item.get_child_count()==0)
                assert(Proxy.surface_budget(item as MeshInstance3D)==4)
            else:
                full_count+=1
                assert(item.get_meta("tarvoka_airbase_v1",false))
        assert(full_count==4 and proxy_count==count-4)
        max_draws=maxi(max_draws,int(
            model.get_meta("tarvoka_stress_estimated_surfaces",0)))
        model.free()

    # The V4 rig reuses V3 smoke/flame draw batches and real 3D sources
    # but swaps their actual ShaderMaterials to soft transparent contours.
    var damage_model: Node3D = Airbase.build(2,0,3)
    var rig: TarvokaAirbaseDamageFXV4 = Soft.build(3)
    damage_model.add_child(rig)
    root.add_child(damage_model)
    await _frames(4)
    assert(rig.is_soft_version() and rig.is_active())
    assert(rig.draw_batch_budget()==2)
    assert(rig.smoke_instance_count()==12)
    assert(rig.flame_batch_count()==1)
    var smoke_mesh: MultiMeshInstance3D = rig.get_node("HumoSuaveV4_UnLote")
    var fire_mesh: MultiMeshInstance3D = rig.get_node("FuegoSuaveV4_UnLote")
    assert(smoke_mesh.material_override is ShaderMaterial)
    assert(fire_mesh.material_override is ShaderMaterial)
    assert((smoke_mesh.material_override as ShaderMaterial).shader==Soft.SOFT_SMOKE)
    assert((fire_mesh.material_override as ShaderMaterial).shader==Soft.SOFT_FIRE)
    rig.advance(0.16)
    rig.set_mobile_quality(true)
    assert(rig.smoke_instance_count()==8)
    rig.set_distant(true)
    assert(not rig.is_active() and not rig.is_processing())
    rig.set_distant(false)
    assert(rig.is_processing())
    damage_model.queue_free()
    await _frames(5)

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Scene.instantiate()
    root.add_child(studio)
    await _frames(10)
    studio._switch_category(1)
    await _frames(4)
    studio._change_selected_building(1)
    await _frames(7)
    assert(studio._role=="airbase")
    assert(studio.building_picker.get_item_text(1).contains("V4"))
    assert(studio.airbase_stress_toggle!=null)
    assert(studio.airbase_stress_picker.item_count==3)
    assert(studio.airbase_stress_status!=null)
    assert(studio.airbase_open_button!=null and not studio.airbase_open_button.disabled)
    assert(studio.model_root.find_child("LineaUmbralHangarV3",true,false)!=null)
    studio.airbase_damage_picker.select(2)
    studio._change_airbase_damage(2)
    await _frames(8)
    var moderate: TarvokaAirbaseDamageFXV4 = studio.model_root.get_node(
        Soft.STAGE_NAME) as TarvokaAirbaseDamageFXV4
    assert(moderate.is_soft_version())
    assert(moderate.draw_batch_budget()==1)
    assert(moderate.smoke_instance_count()==6)
    _shot(studio,"tarvoka_airbase_v4_smoke_soft_medium.png")
    studio.airbase_mobile_fx_toggle.set_pressed_no_signal(true)
    studio._set_airbase_mobile_vfx(true)
    assert(moderate.smoke_instance_count()==4)
    _shot(studio,"tarvoka_airbase_v4_smoke_mobile.png")
    studio.airbase_damage_picker.select(3)
    studio._change_airbase_damage(3)
    await _frames(8)
    var critical: TarvokaAirbaseDamageFXV4 = studio.model_root.get_node(
        Soft.STAGE_NAME) as TarvokaAirbaseDamageFXV4
    assert(critical.is_soft_version() and critical.draw_batch_budget()==2)
    assert(critical.smoke_instance_count()==8)
    critical.advance(0.38)
    _shot(studio,"tarvoka_airbase_v4_soft_flames_critical.png")
    studio.airbase_mobile_fx_toggle.set_pressed_no_signal(false)
    studio._set_airbase_mobile_vfx(false)
    assert(critical.smoke_instance_count()==12)
    _shot(studio,"tarvoka_airbase_v4_full_quality.png")

    for option in range(3):
        studio.airbase_stress_picker.select(option)
        studio.airbase_stress_toggle.set_pressed_no_signal(true)
        studio._toggle_airbase_stress(true)
        await _frames(14)
        var count: int = [8,32,64][option]
        assert(studio._airbase_is_stress())
        assert(studio.model_root.get_meta("tarvoka_stress_count",-1)==count)
        assert(studio.model_root.get_meta("tarvoka_stress_proxy_count",-1)==count-4)
        assert(studio.airbase_impact_bullet_button.disabled)
        assert(studio.airbase_open_button.disabled)
        assert(studio.airbase_camera_button.disabled)
        var name: String = "tarvoka_airbase_v4_stress_%d.png" % count
        _shot(studio,name)
        print("AIRBASE V4 GPU PROFILE count=%d near=4 lod=%d mesh_nodes=%d estimated_surfaces=%d fps_llvmpipe=%d" % [
            count,count-4,
            int(studio.model_root.get_meta("tarvoka_stress_mesh_nodes",0)),
            int(studio.model_root.get_meta("tarvoka_stress_estimated_surfaces",0)),
            Engine.get_frames_per_second()])
    studio.airbase_stress_toggle.set_pressed_no_signal(false)
    studio._toggle_airbase_stress(false)
    await _frames(7)
    assert(not studio._airbase_is_stress())
    assert(not studio.airbase_open_button.disabled)
    studio.airbase_damage_picker.select(0)
    studio._change_airbase_damage(0)
    await _frames(6)
    assert(studio._airbase_gate_rig().is_operational())
    assert(studio.model_root.find_child("LineaUmbralHangarV3",true,false)!=null)
    _shot(studio,"tarvoka_airbase_v4_intact_restored.png")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    studio.queue_free()
    await _frames(5)
    print("PASS AIRBASE V4: 120 map variants, 8/32/64 real LOD stress, soft V4 smoke+fire shaders, mobile/distant FX budget, HQ regressions, max estimated surfaces %d (llvmpipe NOT Android benchmark)" % max_draws)
    quit(0)
