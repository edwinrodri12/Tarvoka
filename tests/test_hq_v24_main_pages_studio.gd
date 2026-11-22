extends SceneTree

# Run AFTER the existing TARVOKA Pages publisher assembled all seven approved
# EDIFICIOS categories and current main unit assets, not in the obsolete
# HQ-only V23 preview branch. The shared scene itself is the test subject.
const HQ=preload("res://scripts/ui/HeadquartersBattle3D.gd")
const OUT:String="res://artifacts/hq_v24_shared_pages"

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio:Control,filename:String) -> void:
    for i in range(5):
        await RenderingServer.frame_post_draw
    var frame:Image=studio.preview.get_texture().get_image()
    assert(frame!=null and not frame.is_empty())
    assert(frame.save_png(OUT+"/"+filename+".png")==OK)

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    root.content_scale_size=Vector2i(1280,800)
    var scene:PackedScene=load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene!=null)
    var studio:Control=scene.instantiate()
    root.add_child(studio)
    for i in range(16):
        await process_frame
    # Other approved subclasses may start in tank, selected city, or an
    # URL-preset unit. Startup role is NOT the publication contract.
    assert(studio.building_picker.item_count>=7,
        "The full EDIFICIOS catalog was replaced")
    assert(studio._hq24_toggle!=null,
        "The native V24 toggle was not installed")
    assert(not studio._hq24_toggle.button_pressed)
    studio.building_picker.select(0)
    studio.category_picker.select(1)
    studio.category_picker.item_selected.emit(1)
    for i in range(10):
        await process_frame
    assert(studio._role=="headquarters")
    assert(not studio.model_root.get_meta("hq_native_geometry",false))
    await _capture(studio,"01_original_HERO_in_shared_studio")
    studio._hq24_toggle.set_pressed_no_signal(true)
    studio._hq24_mode_changed(true)
    assert(studio.model_root.get_meta("hq_native_geometry",false))
    assert(studio.model_root.get_meta("hq_material_surfaces")==13)
    assert(studio._hq24_options.visible)
    assert(studio.camera.size<5.0)
    await _capture(studio,"02_same_real_battle_HQ_N1_D0")
    studio.level_picker.select(2)
    studio._change_building_variant(2)
    assert(studio.model_root.get_meta("visual_tier")==3)
    studio.hq_damage_stage_picker.select(3)
    studio._change_hq_damage_stage(3)
    assert(studio.model_root.get_meta("visual_damage_stage")==3)
    await _capture(studio,"03_hq_real_D3")
    studio.hq_damage_stage_picker.select(4)
    studio._change_hq_damage_stage(4)
    assert(studio.model_root.get_meta("visual_damage_stage")==4)
    var main_mesh:MeshInstance3D=studio.model_root.find_child(
        "MallaConsolidadaMapaV5",true,false) as MeshInstance3D
    assert(main_mesh!=null)
    assert(main_mesh.get_aabb().size.y*HQ.MODEL_SCALE>0.30)
    assert(not studio.model_root.has_node("EscudoOficialDeFaccion"))
    await _capture(studio,"04_hq_real_fractured_ruin_D4")
    studio.hq_damage_stage_picker.select(0)
    studio._change_hq_damage_stage(0)
    studio._hq24_neutral.set_pressed_no_signal(true)
    studio._hq24_neutral_changed(true)
    assert(studio.model_root.get_meta("visual_faction")==-1)
    assert(not studio.model_root.has_node("EscudoOficialDeFaccion"))
    await _capture(studio,"05_hq_neutral_gray")
    studio._hq24_neutral.set_pressed_no_signal(false)
    studio._hq24_neutral_changed(false)
    for f in range(8):
        studio._on_faction(f)
        studio._refresh_building_faction(f)
        assert(studio.model_root.get_meta("visual_faction")==f)
        assert(studio.model_root.has_node("EscudoOficialDeFaccion"))
    studio._hq24_toggle.set_pressed_no_signal(false)
    studio._hq24_mode_changed(false)
    assert(not studio.model_root.get_meta("hq_native_geometry",false))
    # Neither original HQ nor any other EDIFICIOS category has been replaced.
    assert(studio.building_picker.item_count>=7)
    studio._switch_category(0)
    assert(studio._role=="tank")
    assert(studio.model_root!=null)
    studio.queue_free()
    await process_frame
    print("PASS HQ V24 MAIN PAGES SHARED STUDIO: 7+ buildings preserved, HERO comparison, real 3D battle mesh, 8 factions, N1/N3, D0/D3/D4, neutral")
    quit(0)
