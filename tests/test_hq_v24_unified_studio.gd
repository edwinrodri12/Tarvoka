extends SceneTree

# Inspect EXACT V24 native runtime mesh INSIDE the existing combined Godot Web
# Studio scene, without replacing the approved HQ V23 HERO art.
const Combined=preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const HQBattle=preload("res://scripts/ui/HeadquartersBattle3D.gd")
const Curves=preload("res://scripts/ui/HeadquartersCurvedRoof3D.gd")
const OUT:String="res://artifacts/hq_v24_studio"

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio:Control,name:String) -> void:
    for i in range(5):
        await RenderingServer.frame_post_draw
    var image:Image=studio.preview.get_texture().get_image()
    assert(image!=null and not image.is_empty())
    assert(image.save_png(OUT+"/"+name+".png")==OK)

func _run() -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path(OUT))==OK)
    root.content_scale_size=Vector2i(1280,800)
    var scene:PackedScene=load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene!=null)
    var studio:Control=scene.instantiate()
    assert(studio.get_script()==Combined)
    root.add_child(studio)
    for i in range(6):
        await process_frame
    assert(studio._role=="tank")
    studio._switch_category(1)
    for i in range(6):
        await process_frame
    assert(studio._role=="headquarters")
    assert(not studio.hq_v24_toggle.button_pressed)
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    await _capture(studio,"01_hq_hero_original_v23")

    studio.hq_v24_toggle.set_pressed_no_signal(true)
    studio._change_hq_live_v24(true)
    for i in range(6):
        await process_frame
    assert(studio.model_root.get_meta("hq_native_geometry",false))
    assert(studio.hq_damage_stage_picker.disabled==false)
    assert(studio.camera.size<5.0)
    assert(studio.model_root.get_node_or_null(Curves.NAME)!=null)
    assert(studio.model_root.has_node("EscudoOficialDeFaccion"))
    assert(studio.hq_v24_neutral_toggle.visible)
    await _capture(studio,"02_hq_real_battle_v24_close")

    studio.level_picker.select(2)
    studio._change_building_variant(2)
    assert(studio.model_root.get_meta("visual_tier")==3)
    assert(studio.model_root.get_meta("hq_material_surfaces")==9)
    studio.hq_damage_stage_picker.select(3)
    studio._change_hq_damage_stage(3)
    assert(studio.model_root.get_meta("visual_damage_stage")==3)
    await _capture(studio,"03_hq_v24_D3_critical")

    studio.hq_damage_stage_picker.select(4)
    studio._change_hq_damage_stage(4)
    assert(studio.model_root.get_meta("visual_damage_stage")==4)
    assert(not studio.model_root.has_node("EscudoOficialDeFaccion"))
    await _capture(studio,"04_hq_v24_D4_ruins")

    studio.hq_damage_stage_picker.select(0)
    studio._change_hq_damage_stage(0)
    studio.hq_v24_neutral_toggle.set_pressed_no_signal(true)
    studio._change_hq_live_v24_neutral(true)
    assert(studio.model_root.get_meta("visual_faction")==-1)
    assert(not studio.model_root.has_node("EscudoOficialDeFaccion"))
    await _capture(studio,"05_hq_v24_neutral_no_emblem")

    studio.hq_v24_neutral_toggle.set_pressed_no_signal(false)
    studio._change_hq_live_v24_neutral(false)
    for f in range(8):
        studio._on_faction(f)
        studio._refresh_building_faction(f)
        assert(int(studio.model_root.get_meta("visual_faction",-1))==f)
        assert(studio.model_root.has_node("EscudoOficialDeFaccion"))
    studio.hq_v24_toggle.set_pressed_no_signal(false)
    studio._change_hq_live_v24(false)
    assert(not studio.model_root.get_meta("hq_native_geometry",false))
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio.queue_free()
    await process_frame
    print("PASS HQ V24 UNIFIED STUDIO: original HERO, native runtime mesh, D3/D4, neutral, eight factions and return to units")
    quit(0)
