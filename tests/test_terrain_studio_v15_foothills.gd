extends SceneTree

# Native GPU regression for the real TARVOKA Godot Web Studio.
# The V15 footslope rock and transition meshes must remain inside land
# tiles, never water/road, and preserve all old V1-V14 visual modes.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _checked_mesh(studio: Control,name: String,biome: int) -> MeshInstance3D:
    var node: MeshInstance3D = studio.model_root.find_child(
        name,true,false) as MeshInstance3D
    assert(node!=null and node.mesh!=null)
    assert(node.get_meta("visual_only",false))
    var faces: PackedVector3Array = node.mesh.get_faces()
    for position in faces:
        var x: int = roundi(position.x/Terrain.CELL+float(Terrain.WIDTH-1)*0.5)
        var z: int = roundi(position.z/Terrain.CELL+float(Terrain.HEIGHT-1)*0.5)
        assert(x>=0 and x<Terrain.WIDTH)
        assert(z>=0 and z<Terrain.HEIGHT)
        # A slope or stone cannot ever overlap a river or a road tile,
        # including the V4 bridges crossing the canyon.
        assert(Terrain.kind(x,z,biome) in ["forest","plain"])
    return node

func _image(studio: Control,filepath: String) -> Image:
    var result: Image = studio.preview.get_texture().get_image()
    assert(result!=null and not result.is_empty())
    assert(result.save_png(filepath)==OK)
    return result

func _run() -> void:
    root.content_scale_size=Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed!=null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for i in range(6):
        await process_frame
    studio._switch_category(2)
    for i in range(6):
        await process_frame
    assert(studio._role=="terrain")
    assert(studio._terrain_v11_enabled)
    assert(studio._terrain_v10_enabled)
    assert(studio.terrain_aprons_v11_toggle.button_pressed)
    assert(studio.terrain_outcrops_v11_toggle.button_pressed)
    assert(studio.terrain_compare_v11_button!=null)
    assert(studio.terrain_compare_v11_button.name=="ComparadorTerrenoV10V11")
    var original_counts: Dictionary = studio.model_root.get_meta("terrain_counts").duplicate(true)
    var stat: Dictionary = studio.model_root.get_meta("terrain_foothills_v11")
    assert(int(stat["mountain_edges"])>0)
    assert(int(stat["apron_triangles"])==int(stat["mountain_edges"])*48)
    assert(int(stat["boulders"])==int(stat["mountain_edges"])*4)
    assert(int(stat["batches"])==2)
    assert(int(stat["road_cells_skipped"])>0)
    assert(int(stat["water_cells_skipped"])>0)
    assert(studio.model_root.get_meta("terrain_tile_count")==120)
    assert(studio.model_root.get_meta("terrain_bridge_visual_count")==0)
    assert(studio.status_label.text.contains("V11:"))
    var apron := _checked_mesh(studio,"TaludesTransicionV11",0)
    var rocks := _checked_mesh(studio,"AfloramientosDeValleV11",0)
    assert(apron.mesh.get_faces().size()==int(stat["apron_triangles"])*3)
    assert(rocks.mesh.get_faces().size()==int(stat["boulders"])*5*3)
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["crest_subdivisions"])==12)

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    studio._view_normal_game_distance()
    for i in range(7):
        await process_frame
    var enhanced: Image = _image(studio,
        "res://artifacts/tarvoka_terrain_v15_foothills.png")
    studio._view_ridge_profile()
    for i in range(7):
        await process_frame
    _image(studio,"res://artifacts/tarvoka_terrain_v15_profile.png")
    studio._view_normal_game_distance()
    studio._toggle_v11_finish()
    assert(not studio._terrain_v11_enabled)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["batches"])==0)
    assert(studio.model_root.find_child("TaludesTransicionV11",true,false)==null)
    assert(studio.model_root.find_child("AfloramientosDeValleV11",true,false)==null)
    assert(studio.model_root.get_meta("terrain_counts")==original_counts)
    assert(int(studio.model_root.get_meta("terrain_erosion_v7")["crest_subdivisions"])==12)
    for i in range(7):
        await process_frame
    var prior: Image = studio.preview.get_texture().get_image()
    assert(prior!=null and not prior.is_empty())
    var old_small: Image = prior.duplicate()
    var new_small: Image = enhanced.duplicate()
    old_small.resize(640,400,Image.INTERPOLATE_LANCZOS)
    new_small.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var comparison: Image = Image.create(1280,400,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(old_small,Rect2i(0,0,640,400),Vector2i.ZERO)
    comparison.blit_rect(new_small,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(comparison.save_png(
        "res://artifacts/tarvoka_terrain_v15_v14_comparison.png")==OK)
    studio._toggle_v11_finish()
    assert(studio._terrain_v11_enabled)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["batches"])==2)

    studio.terrain_aprons_v11_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["apron_triangles"])==0)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["boulders"])>0)
    studio.terrain_aprons_v11_toggle.button_pressed=true
    studio.terrain_outcrops_v11_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["boulders"])==0)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["apron_triangles"])>0)
    studio.terrain_outcrops_v11_toggle.button_pressed=true
    studio._rebuild_terrain(false)

    # Every scenario is checked with the actual rendered geometry, tile
    # occupancy, the canyon's two V4 bridges and zero extra draw instances.
    for biome in [0,1,2]:
        studio.terrain_scene_picker.select(biome)
        studio._change_terrain_scene(biome)
        var summary: Dictionary = studio.model_root.get_meta("terrain_foothills_v11")
        assert(int(summary["mountain_edges"])>0)
        assert(int(summary["batches"])<=2)
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(studio.model_root.get_meta("terrain_bridge_visual_count")==(
            2 if biome==1 else 0))
        _checked_mesh(studio,"TaludesTransicionV11",biome)
        _checked_mesh(studio,"AfloramientosDeValleV11",biome)

    # Existing V14 compare must disable V15 and restoring V15 re-enables
    # the selected rock finish. Unit/building/battle tabs remain stable.
    studio._toggle_v10_finish()
    assert(not studio._terrain_v11_enabled)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["batches"])==0)
    studio._toggle_v11_finish()
    assert(studio._terrain_v11_enabled)
    assert(studio._terrain_v10_enabled)
    studio.terrain_continuous_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed=true
    studio.terrain_scatter_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["batches"])==0)
    studio.terrain_scatter_toggle.button_pressed=true
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_foothills_v11")["batches"])==2)
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio._switch_category(2)
    assert(studio._role=="terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V15: blended aprons, valley outcrops, strict road/water bounds, 2 render batches, 3 biomes, preserved V1-V14 comparisons")
    quit(0)
