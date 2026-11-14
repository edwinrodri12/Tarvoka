extends SceneTree

# GPU contract: same genuine Studio scene, deterministic V6 geology,
# three low-draw-call tree species, shoreline smoothing and old V1-V5 modes.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed != null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for i in range(6):
        await process_frame
    assert(studio.category_picker.item_count == 4)
    studio._switch_category(2)
    for i in range(7):
        await process_frame
    assert(studio._role == "terrain")
    assert(studio._terrain_v6_enabled)
    assert(studio.terrain_ridges_v6_toggle.button_pressed)
    assert(studio.terrain_forest_v6_toggle.button_pressed)
    assert(studio.terrain_banks_v6_toggle.button_pressed)
    var original: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var stats: Dictionary = studio.model_root.get_meta("terrain_natural_v6")
    assert(int(stats["ridges"]) == int(original["mountain"]))
    assert(int(stats["trees"]) > int(original["forest"])*2)
    assert(int(stats["banks"]) > 0)
    assert(int(stats["batches"]) <= 5)
    assert(studio.model_root.find_child("CordilleraContinuaV6",true,false) != null)
    assert(studio.model_root.find_child("OrillasMeandrantesV6",true,false) != null)
    assert(studio.model_root.find_child("BosqueAbetosV6",true,false) != null)
    assert(studio.model_root.find_child("BosquePinosV6",true,false) != null)
    assert(studio.model_root.find_child("BosqueCaducifoliosV6",true,false) != null)
    assert(studio.model_root.find_child("MacizoTallado_0",true,false) == null)
    assert(studio.status_label.text.contains("V6:"))

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for i in range(7):
        await process_frame
    var v6_image: Image = studio.preview.get_texture().get_image()
    assert(v6_image != null and not v6_image.is_empty())
    assert(v6_image.save_png("res://artifacts/tarvoka_terrain_v10_ridges_forest.png")==OK)
    studio._toggle_v6_finish()
    assert(not studio._terrain_v6_enabled)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["batches"])==0)
    assert(studio.model_root.get_meta("terrain_counts") == original)
    assert(studio.model_root.find_child("CordilleraContinuaV6",true,false) == null)
    for i in range(7):
        await process_frame
    var v5_image: Image = studio.preview.get_texture().get_image()
    assert(v5_image != null and not v5_image.is_empty())
    var old: Image = v5_image.duplicate()
    var newer: Image = v6_image.duplicate()
    old.resize(640,400,Image.INTERPOLATE_LANCZOS)
    newer.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var side_by_side := Image.create(1280,400,false,Image.FORMAT_RGBA8)
    side_by_side.blit_rect(old,Rect2i(0,0,640,400),Vector2i.ZERO)
    side_by_side.blit_rect(newer,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(side_by_side.save_png(
        "res://artifacts/tarvoka_terrain_v10_v5_vs_v6.png")==OK)
    studio._toggle_v6_finish()
    assert(studio._terrain_v6_enabled)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["batches"])>0)

    # Switches are independent. No V6 mesh should remain when its option
    # is disabled, without hiding the V5 bank/grass/rocks.
    studio.terrain_ridges_v6_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["ridges"])==0)
    assert(studio.model_root.find_child("CordilleraContinuaV6",true,false)==null)
    assert(studio.model_root.find_child("MacizoTallado_0",true,false)!=null)
    studio.terrain_ridges_v6_toggle.button_pressed = true
    studio.terrain_forest_v6_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["trees"])==0)
    studio.terrain_forest_v6_toggle.button_pressed = true
    studio.terrain_banks_v6_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["banks"])==0)
    studio.terrain_banks_v6_toggle.button_pressed = true
    studio._rebuild_terrain(false)

    # Three biomes preserve exactly the source terrain count and old bridge
    # placements, including both roadway ramps over the rocky canyon.
    for scenario in [0,1,2]:
        studio.terrain_scene_picker.select(scenario)
        studio._change_terrain_scene(scenario)
        var state: Dictionary = studio.model_root.get_meta("terrain_counts")
        var detail: Dictionary = studio.model_root.get_meta("terrain_natural_v6")
        assert(int(detail["ridges"]) == int(state["mountain"]))
        assert(int(detail["trees"])>0)
        assert(int(detail["banks"])>0)
        assert(int(detail["batches"])<=5)
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(studio.model_root.get_meta("terrain_bridge_visual_count")==
            (2 if scenario==1 else 0))
    # Old V1/V2/V3 visual comparisons must take precedence over V6.
    studio.terrain_continuous_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed = true
    studio.terrain_scatter_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["batches"])==0)
    studio.terrain_scatter_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["batches"])>0)
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio._switch_category(2)
    assert(studio._role=="terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V10: ridges replace repeated peaks, 3 tree species batched, curved waterbanks and V1–V6 comparisons across three biomes")
    quit(0)
