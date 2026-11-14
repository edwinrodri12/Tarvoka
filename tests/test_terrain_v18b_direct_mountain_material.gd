extends SceneTree

# V18b regression: biome colour lives in the ACTUAL visible ridge and V11
# foothill meshes, and NEVER in an occluded additional overlay. Geometry,
# tile IDs, roads, water, bridges, battle, and existing world state stay fixed.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _read_surface(studio: Control,label: String) -> Dictionary:
    var node: MeshInstance3D = studio.model_root.find_child(
        label,true,false) as MeshInstance3D
    assert(node!=null and node.mesh!=null)
    assert(node.material_override is StandardMaterial3D)
    assert((node.material_override as StandardMaterial3D).vertex_color_use_as_albedo)
    var arrays: Array = node.mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
    assert(vertices.size()>0 and vertices.size()==colors.size())
    return {"positions":vertices,"colors":colors}

func _differs(before: Dictionary,after: Dictionary,
        channel_min: float) -> int:
    var one: PackedVector3Array = before["positions"]
    var two: PackedVector3Array = after["positions"]
    var ca: PackedColorArray = before["colors"]
    var cb: PackedColorArray = after["colors"]
    assert(one.size()==two.size())
    assert(ca.size()==cb.size())
    var changes := 0
    for i in range(one.size()):
        assert(one[i].distance_to(two[i])<0.0001)
        var difference: float = (
            absf(ca[i].r-cb[i].r)+
            absf(ca[i].g-cb[i].g)+
            absf(ca[i].b-cb[i].b))
        if difference>channel_min:
            changes += 1
    return changes

func _shot(studio: Control,path: String) -> Image:
    for i in range(7):
        await process_frame
    var picture: Image = studio.preview.get_texture().get_image()
    assert(picture!=null and not picture.is_empty())
    assert(picture.save_png(path)==OK)
    return picture

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
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
    assert(studio._terrain_v13_enabled)
    assert(studio.terrain_baked_biome_v14_toggle.button_pressed)
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var total_changed_ridge := 0
    var total_changed_foot := 0
    for scene in [0,1,2]:
        studio.terrain_scene_picker.select(scene)
        studio._change_terrain_scene(scene)
        studio._view_normal_game_distance()
        var root3d: Node3D = studio.model_root
        var tile_counts: Dictionary = root3d.get_meta(
            "terrain_counts").duplicate(true)
        var stats: Dictionary = root3d.get_meta("terrain_biome_v14")
        var old_v7: Dictionary = root3d.get_meta("terrain_erosion_v7")
        var old_v11: Dictionary = root3d.get_meta("terrain_foothills_v11")
        var v13: Dictionary = root3d.get_meta("terrain_mountain_biomes_v13")
        assert(bool(stats["enabled"]))
        assert(int(stats["mountain_vertices"]) ==
            int(tile_counts["mountain"])*169)
        assert(int(stats["foothill_vertices"]) ==
            int(old_v11["mountain_edges"])*36)
        assert(int(stats["mountain_vertices"])>0)
        assert(int(stats["foothill_vertices"])>0)
        assert(int(stats["extra_batches"])==0)
        assert(int(old_v7["biome_surface_vertices"]) ==
            int(stats["mountain_vertices"]))
        assert(int(v13["ridge_facets"])==0)
        assert(int(v13["mantle_triangles"])==0)
        assert(int(v13["batches"])==1)
        assert(root3d.find_child(
            "EstratosYTaludesBiomaV13",true,false)==null)
        assert(root3d.find_child(
            "VegetacionYPedregalBiomaV13",true,false)!=null)
        assert(studio.status_label.text.contains("V18b MATERIAL REAL"))
        assert(root3d.get_meta("terrain_tile_count")==120)
        assert(root3d.get_meta("terrain_bridge_visual_count")==(
            2 if scene==1 else 0))
        var mountain: Dictionary = _read_surface(
            studio,"MacizosErosionadosContinuosV7")
        var aprons: Dictionary = _read_surface(
            studio,"TaludesTransicionV11")
        var photo: Image = await _shot(studio,[
            "res://artifacts/tarvoka_v18b_valle_boscoso.png",
            "res://artifacts/tarvoka_v18b_canon_rocoso.png",
            "res://artifacts/tarvoka_v18b_delta_costero.png"][scene])

        # Exact same triangles before/after. Only pigment changes.
        studio.terrain_baked_biome_v14_toggle.button_pressed=false
        studio._rebuild_terrain(false)
        assert(not studio.model_root.get_meta("terrain_biome_v14")["enabled"])
        assert(studio.model_root.get_meta("terrain_counts")==tile_counts)
        assert(studio.model_root.get_meta(
            "terrain_bridge_visual_count")==(2 if scene==1 else 0))
        var old_mountain: Dictionary = _read_surface(
            studio,"MacizosErosionadosContinuosV7")
        var old_aprons: Dictionary = _read_surface(
            studio,"TaludesTransicionV11")
        var ridge_changed: int = _differs(old_mountain,mountain,0.035)
        var slope_changed: int = _differs(old_aprons,aprons,0.015)
        assert(ridge_changed > int(
            (mountain["positions"] as PackedVector3Array).size()*0.14))
        assert(slope_changed > int(
            (aprons["positions"] as PackedVector3Array).size()*0.12))
        total_changed_ridge += ridge_changed
        total_changed_foot += slope_changed
        var image_old: Image = await _shot(studio,
            "res://artifacts/tarvoka_v18b_before_%d.png" % scene)
        if scene == 0:
            image_old.resize(640,400,Image.INTERPOLATE_LANCZOS)
            photo.resize(640,400,Image.INTERPOLATE_LANCZOS)
            var image_pair := Image.create(
                1280,400,false,Image.FORMAT_RGBA8)
            image_pair.blit_rect(
                image_old,Rect2i(0,0,640,400),Vector2i.ZERO)
            image_pair.blit_rect(
                photo,Rect2i(0,0,640,400),Vector2i(640,0))
            assert(image_pair.save_png(
                "res://artifacts/tarvoka_v18b_actual_surface_comparison.png")==OK)
        studio.terrain_baked_biome_v14_toggle.button_pressed=true
        studio._rebuild_terrain(false)
        assert(studio.model_root.get_meta("terrain_biome_v14")["enabled"])
    assert(total_changed_ridge>0 and total_changed_foot>0)
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio.free()
    print("PASS TERRAIN_V18B_DIRECT_MATERIAL: %d ridge vertices, %d foothill vertices recoloured ON REAL MESHES; 3 climates, zero extra batches, road/water safety" % [
        total_changed_ridge,total_changed_foot])
    quit(0)
