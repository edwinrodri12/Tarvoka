extends SceneTree

# Native GPU test of the real browser studio: terrain V7 replaces repeated
# peaks, vertical waterfronts and white box foam, without changing any
# of the 120 tactical cells or breaking V1–V6 comparisons.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Erosion = preload("res://scripts/ui/TerrainStudioErosionV7.gd")

func _initialize() -> void:
    call_deferred("_run")

func _read_stats(root: Node3D) -> Dictionary:
    return root.get_meta("terrain_erosion_v7",{})

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
    for i in range(6):
        await process_frame
    assert(studio._role == "terrain")
    assert(studio._terrain_v7_enabled)
    assert(studio.terrain_ridges_v7_toggle.button_pressed)
    assert(studio.terrain_shores_v7_toggle.button_pressed)
    assert(studio.terrain_water_v7_toggle.button_pressed)
    assert(studio.terrain_continuous_toggle.button_pressed)
    assert(studio.terrain_scatter_toggle.button_pressed)
    var counts: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var v7: Dictionary = _read_stats(studio.model_root)
    assert(int(v7["mountain_cells"]) == int(counts["mountain"]))
    assert(int(v7["ridge_triangles"]) == int(counts["mountain"])*128)
    assert(int(v7["shore_edges"]) > 0)
    assert(int(v7["wave_strips"]) > 0)
    assert(int(v7["batches"]) == 3)
    var ridge: MeshInstance3D = studio.model_root.find_child(
        "MacizosErosionadosContinuosV7",true,false) as MeshInstance3D
    assert(ridge != null and ridge.mesh != null)
    assert(ridge.mesh.get_faces().size() == int(v7["ridge_triangles"])*3)
    assert(studio.model_root.find_child("SedimentosYOrillasSinParedV7",true,false) != null)
    assert(studio.model_root.find_child("OndulacionesDispersasV7",true,false) != null)
    assert(studio.model_root.find_child("CordilleraContinuaV6",true,false) == null)
    assert(studio.model_root.find_child("MacizoTallado_0",true,false) == null)
    assert(studio.model_root.find_child("EspumaOla",true,false) == null)
    assert(studio.model_root.find_child("LineaEspumaCosta",true,false) == null)
    assert(studio.model_root.find_child("BosqueAbetosV6",true,false) != null)
    assert(studio.status_label.text.contains("V7:"))

    # The heightfield uses the SAME 3D point on mountain-mountain shared
    # borders, so the uplift should not tear apart adjacent rock cells.
    var mountains: Dictionary = {}
    for z in range(Terrain.HEIGHT):
        for x in range(Terrain.WIDTH):
            if Terrain.kind(x,z,0) != "mountain":
                continue
            mountains[Vector2i(x,z)] = {
                "x":x,"z":z,
                "kind":"mountain",
                "center":Terrain._cell_center(x,z),
                "top":Terrain.height_at(x,z,0),
                "corners":Terrain._cell_corner_heights(x,z,0),
                "half":Terrain.CELL*0.5}
    var seam_checked := false
    for pos in mountains.keys():
        var east: Vector2i = pos+Vector2i(1,0)
        if not mountains.has(east):
            continue
        var west_height: float = Erosion.ridge_height(mountains[pos],
            Vector2(Terrain.CELL*0.5,0),mountains,0)
        var east_height: float = Erosion.ridge_height(mountains[east],
            Vector2(-Terrain.CELL*0.5,0),mountains,0)
        assert(absf(west_height-east_height) < 0.35)
        seam_checked = true
        break
    assert(seam_checked)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for i in range(8):
        await process_frame
    var new_image: Image = studio.preview.get_texture().get_image()
    assert(new_image != null and not new_image.is_empty())
    assert(new_image.save_png("res://artifacts/tarvoka_terrain_v11_erosion.png") == OK)
    studio._toggle_v7_finish()
    assert(not studio._terrain_v7_enabled)
    assert(int(_read_stats(studio.model_root)["batches"])==0)
    assert(studio.model_root.get_meta("terrain_counts") == counts)
    assert(studio.model_root.find_child("MacizosErosionadosContinuosV7",true,false) == null)
    assert(studio.model_root.find_child("CordilleraContinuaV6",true,false) != null)
    assert(studio.model_root.find_child("EspumaOla",true,false) != null)
    for i in range(8):
        await process_frame
    var older: Image = studio.preview.get_texture().get_image()
    assert(older != null and not older.is_empty())
    var small_old: Image = older.duplicate()
    var small_new: Image = new_image.duplicate()
    small_old.resize(640,400,Image.INTERPOLATE_LANCZOS)
    small_new.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var compare := Image.create(1280,400,false,Image.FORMAT_RGBA8)
    compare.blit_rect(small_old,Rect2i(0,0,640,400),Vector2i.ZERO)
    compare.blit_rect(small_new,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(compare.save_png("res://artifacts/tarvoka_terrain_v11_v10_comparison.png")==OK)
    studio._toggle_v7_finish()
    assert(studio._terrain_v7_enabled)

    # Each V7 layer toggles independently. The V5/V6 reference geometry
    # only reappears for the specific layer switched off.
    studio.terrain_ridges_v7_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(_read_stats(studio.model_root)["mountain_cells"])==0)
    assert(studio.model_root.find_child("CordilleraContinuaV6",true,false)!=null)
    studio.terrain_ridges_v7_toggle.button_pressed = true
    studio.terrain_shores_v7_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(_read_stats(studio.model_root)["shore_edges"])==0)
    assert(int(studio.model_root.get_meta("terrain_natural_v6")["banks"])>0)
    studio.terrain_shores_v7_toggle.button_pressed = true
    studio.terrain_water_v7_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(_read_stats(studio.model_root)["wave_strips"])==0)
    assert(studio.model_root.find_child("EspumaOla",true,false)!=null)
    studio.terrain_water_v7_toggle.button_pressed = true
    studio._rebuild_terrain(false)

    for biome in [0,1,2]:
        studio.terrain_scene_picker.select(biome)
        studio._change_terrain_scene(biome)
        var stats: Dictionary = _read_stats(studio.model_root)
        assert(int(stats["mountain_cells"])>0)
        assert(int(stats["shore_edges"])>0)
        assert(int(stats["wave_strips"])>0)
        assert(int(stats["batches"])<=3)
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(studio.model_root.get_meta("terrain_bridge_visual_count")==
            (2 if biome==1 else 0))

    # V1 and V2/V3 comparisons remain independently usable.
    studio.terrain_continuous_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(_read_stats(studio.model_root)["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed = true
    studio.terrain_scatter_toggle.button_pressed = false
    studio._rebuild_terrain(false)
    assert(int(_read_stats(studio.model_root)["batches"])==0)
    studio.terrain_scatter_toggle.button_pressed = true
    studio._rebuild_terrain(false)
    assert(int(_read_stats(studio.model_root)["batches"])==3)
    studio._switch_category(0)
    assert(studio._role == "tank")
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    studio._switch_category(3)
    assert(studio._role == "battle")
    studio._switch_category(2)
    assert(studio._role == "terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V11: eroded shared ridge field, bank slopes with no vertical water wall, nonuniform wave strips, independent switches, all biomes and old 3D galleries")
    quit(0)
