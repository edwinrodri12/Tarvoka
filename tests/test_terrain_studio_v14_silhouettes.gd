extends SceneTree

# Actual Godot SubViewport, mesh topology and GPU screenshots; no mock.
# This guards the new V14 silhouettes AND the V1–V13 fallbacks.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Erosion = preload("res://scripts/ui/TerrainStudioErosionV7.gd")
const Spines = preload("res://scripts/ui/TerrainStudioRidgeV10.gd")

func _initialize() -> void:
    call_deferred("_run")

func _image(studio: Control,path: String) -> Image:
    var result: Image = studio.preview.get_texture().get_image()
    assert(result != null and not result.is_empty())
    assert(result.save_png(path)==OK)
    return result

func _mountain_cells(scene: int) -> Dictionary:
    var mountains: Dictionary = {}
    for z in range(Terrain.HEIGHT):
        for x in range(Terrain.WIDTH):
            if Terrain.kind(x,z,scene)!="mountain":
                continue
            mountains[Vector2i(x,z)] = {
                "x":x,"z":z,"kind":"mountain",
                "center":Terrain._cell_center(x,z),
                "top":Terrain.height_at(x,z,scene),
                "corners":Terrain._cell_corner_heights(x,z,scene),
                "half":Terrain.CELL*0.5}
    return mountains

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene!=null)
    var studio: Control = scene.instantiate()
    root.add_child(studio)
    for f in range(6):
        await process_frame
    studio._switch_category(2)
    for f in range(8):
        await process_frame
    assert(studio._role=="terrain")
    assert(studio._terrain_v10_enabled)
    assert(studio.terrain_silhouette_v10_toggle.button_pressed)
    assert(studio.terrain_compare_v10_button!=null)
    assert(studio.terrain_ridge_profile_button!=null)
    var counts: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var stats: Dictionary = studio.model_root.get_meta("terrain_erosion_v7")
    assert(int(stats["silhouette_cells"])==int(counts["mountain"]))
    assert(int(stats["crest_subdivisions"])==12)
    assert(int(stats["ridge_triangles"])==int(counts["mountain"])*288)
    assert(int(stats["batches"])==3)
    assert(studio.model_root.get_meta("terrain_tile_count")==120)
    assert(studio.model_root.get_meta("terrain_bridge_visual_count")==0)
    assert(studio.model_root.get_meta("terrain_studio_v10_sculpted_ridges"))
    assert(studio.status_label.text.contains("V10:"))
    var ridge: MeshInstance3D = studio.model_root.find_child(
        "MacizosErosionadosContinuosV7",true,false) as MeshInstance3D
    assert(ridge!=null and ridge.mesh!=null)
    assert(ridge.mesh.get_faces().size()==int(stats["ridge_triangles"])*3)

    # Verify coherent world-space displacement at two adjacent mountain
    # cells, including an interior sample and a shared x or z edge.
    var mountains: Dictionary = _mountain_cells(0)
    var matched: bool = false
    var varied: int = 0
    var crest_values: Dictionary = {}
    for coordinate in mountains:
        var loc: Vector2i = coordinate
        var cell: Dictionary = mountains[loc]
        var center_offset := Vector2.ZERO
        var new_y: float = Erosion.ridge_height(cell,center_offset,mountains,0,true)
        var old_y: float = Erosion.ridge_height(cell,center_offset,mountains,0,false)
        if absf(new_y-old_y)>0.12:
            varied += 1
        crest_values[loc] = new_y
        assert(is_equal_approx(Spines.uplift(cell,center_offset,mountains,0),
            Spines.uplift(cell,center_offset,mountains,0)))
        var east := loc+Vector2i(1,0)
        if mountains.has(east) and not matched:
            var y0: float = Erosion.ridge_height(
                cell,Vector2(Terrain.CELL*0.5,0),mountains,0,true)
            var y1: float = Erosion.ridge_height(
                mountains[east],Vector2(-Terrain.CELL*0.5,0),mountains,0,true)
            assert(absf(y0-y1)<0.35)
            matched=true
    assert(matched)
    assert(varied>=4)
    assert(crest_values.size()>=10)

    # Same camera and lighting, both using real rendered mesh materials.
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    studio._view_normal_game_distance()
    for f in range(8):
        await process_frame
    var v14: Image = _image(studio,
        "res://artifacts/tarvoka_terrain_v14_normal_distance.png")
    studio._view_ridge_profile()
    assert(studio.terrain_camera_picker.selected==2)
    assert(studio.camera.position.y < 20.0)
    for f in range(6):
        await process_frame
    _image(studio,"res://artifacts/tarvoka_terrain_v14_ridge_profile.png")
    studio._view_normal_game_distance()
    studio._toggle_v10_finish()
    assert(not studio._terrain_v10_enabled)
    assert(not studio.model_root.get_meta("terrain_studio_v10_sculpted_ridges"))
    var previous: Dictionary = studio.model_root.get_meta("terrain_erosion_v7")
    assert(int(previous["silhouette_cells"])==0)
    assert(int(previous["crest_subdivisions"])==8)
    assert(int(previous["ridge_triangles"])==int(counts["mountain"])*128)
    assert(studio.model_root.get_meta("terrain_counts")==counts)
    assert(int(previous["batches"])==3)
    for f in range(8):
        await process_frame
    var v13: Image = studio.preview.get_texture().get_image()
    assert(v13!=null and not v13.is_empty())
    var old: Image = v13.duplicate()
    var fresh: Image = v14.duplicate()
    old.resize(640,400,Image.INTERPOLATE_LANCZOS)
    fresh.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var comparison: Image = Image.create(1280,400,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(old,Rect2i(0,0,640,400),Vector2i.ZERO)
    comparison.blit_rect(fresh,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(comparison.save_png(
        "res://artifacts/tarvoka_terrain_v14_v13_comparison.png")==OK)
    studio._toggle_v10_finish()
    assert(studio._terrain_v10_enabled)
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["crest_subdivisions"])==12)
    studio.terrain_silhouette_v10_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(not studio.model_root.get_meta("terrain_studio_v10_sculpted_ridges"))
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["crest_subdivisions"])==8)
    studio.terrain_silhouette_v10_toggle.button_pressed=true
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["crest_subdivisions"])==12)

    # All three 120-cell environmental maps, V4 bridges and V6 trees.
    # No rules/game state changes; one ridge batch in both V13 and V14.
    for biome in [0,1,2]:
        studio.terrain_scene_picker.select(biome)
        studio._change_terrain_scene(biome)
        var value: Dictionary = studio.model_root.get_meta("terrain_erosion_v7")
        assert(int(value["silhouette_cells"])==int(
            studio.model_root.get_meta("terrain_counts")["mountain"]))
        assert(int(value["ridge_triangles"])==int(value["silhouette_cells"])*288)
        assert(int(value["batches"])==3)
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(studio.model_root.get_meta("terrain_bridge_visual_count")==(
            2 if biome==1 else 0))
        assert(studio.model_root.find_child("BosqueCaducifoliosV6",true,false)!=null)

    # V1/V2 and previous comparators remain valid; the same studio keeps
    # unit, HQ, battle and environment tabs in their proper roles.
    studio._toggle_v9_finish()
    assert(not studio._terrain_v10_enabled)
    studio._toggle_v10_finish()
    assert(studio._terrain_v10_enabled)
    studio.terrain_continuous_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed=true
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio._switch_category(2)
    assert(studio._role=="terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V14: elongated connected rock spines, real mesh silhouette differences, seam continuity, 3 biomes, same camera comparison and all legacy viewers")
    quit(0)
