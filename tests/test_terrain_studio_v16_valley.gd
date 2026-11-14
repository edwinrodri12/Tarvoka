extends SceneTree

# V16 Godot GPU contract: terrain-following sediments and road verge patches
# must keep ALL vertices inside open/forest land, preserve V15b topology,
# restore old V1-V15 modes and use at most two new mesh batches.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _check_mesh(studio: Control,label: String,scene: int) -> int:
    var node: MeshInstance3D = studio.model_root.find_child(
        label,true,false) as MeshInstance3D
    assert(node!=null and node.mesh!=null)
    assert(node.get_meta("visual_only",false))
    var faces: PackedVector3Array = node.mesh.get_faces()
    assert(faces.size()>0)
    for vertex in faces:
        var x: int = roundi(vertex.x/Terrain.CELL+float(Terrain.WIDTH-1)*0.5)
        var z: int = roundi(vertex.z/Terrain.CELL+float(Terrain.HEIGHT-1)*0.5)
        assert(x>=0 and x<Terrain.WIDTH)
        assert(z>=0 and z<Terrain.HEIGHT)
        assert(Terrain.kind(x,z,scene) in ["plain","forest"])
        var origin_x: float = (float(x)-float(Terrain.WIDTH-1)*0.5)*Terrain.CELL
        var origin_z: float = (float(z)-float(Terrain.HEIGHT-1)*0.5)*Terrain.CELL
        assert(absf(vertex.x-origin_x)<Terrain.CELL*0.5-0.11)
        assert(absf(vertex.z-origin_z)<Terrain.CELL*0.5-0.11)
        # Geometry is a decorative surface slightly above the SAME shared
        # four-fan terrain mesh. It must not float or change tactical height.
        var height: float = Terrain.surface_height_at(
            x,z,scene,vertex.x-origin_x,vertex.z-origin_z)
        assert(vertex.y>=height+0.006 and vertex.y<height+0.028)
    return int(faces.size()/3)

func _capture(studio: Control,path: String) -> Image:
    for i in range(7):
        await process_frame
    var result: Image = studio.preview.get_texture().get_image()
    assert(result!=null and not result.is_empty())
    assert(result.save_png(path)==OK)
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
    assert(studio._terrain_v12_enabled)
    assert(studio._terrain_v11_enabled)
    assert(studio.terrain_deposits_v12_toggle.button_pressed)
    assert(studio.terrain_verges_v12_toggle.button_pressed)
    assert(studio.terrain_compare_v12_button.name=="ComparadorTerrenoV11V12")
    var original_counts: Dictionary = studio.model_root.get_meta(
        "terrain_counts").duplicate(true)
    var old_foothills: Dictionary = studio.model_root.get_meta(
        "terrain_foothills_v11").duplicate(true)
    assert(studio.model_root.get_meta("terrain_tile_count")==120)
    var initial: Dictionary = studio.model_root.get_meta("terrain_sediments_v12")
    assert(int(initial["batches"])==2)
    assert(int(initial["sediment_patches"])>0)
    assert(int(initial["road_verges"])>0)
    assert(int(initial["river_patches"])>0)
    assert(int(initial["mountain_patches"])>0)
    assert(int(initial["triangles"])==8*(
        int(initial["sediment_patches"])+int(initial["road_verges"])))
    assert(int(initial["water_cells_skipped"])>0)
    assert(int(initial["road_cells_skipped"])>0)
    assert(studio.status_label.text.contains("V12:"))
    assert(_check_mesh(studio,"DepositosAluvialesV12",0)==
        8*int(initial["sediment_patches"]))
    assert(_check_mesh(studio,"ArcenesNaturalesV12",0)==
        8*int(initial["road_verges"]))

    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    studio._view_normal_game_distance()
    var new_image: Image = await _capture(studio,
        "res://artifacts/tarvoka_terrain_v16_valley_sediments.png")
    studio._toggle_v12_finish()
    assert(not studio._terrain_v12_enabled)
    var older: Dictionary = studio.model_root.get_meta("terrain_sediments_v12")
    assert(int(older["batches"])==0)
    assert(studio.model_root.find_child("DepositosAluvialesV12",true,false)==null)
    assert(studio.model_root.find_child("ArcenesNaturalesV12",true,false)==null)
    assert(studio.model_root.get_meta("terrain_counts")==original_counts)
    assert(studio.model_root.get_meta("terrain_foothills_v11")==old_foothills)
    var old_image: Image = await _capture(studio,
        "res://artifacts/tarvoka_terrain_v16_before_v15b.png")
    old_image.resize(640,400,Image.INTERPOLATE_LANCZOS)
    new_image.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var comparison := Image.create(1280,400,false,Image.FORMAT_RGBA8)
    comparison.blit_rect(old_image,Rect2i(0,0,640,400),Vector2i.ZERO)
    comparison.blit_rect(new_image,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(comparison.save_png(
        "res://artifacts/tarvoka_terrain_v16_vs_v15b.png")==OK)
    studio._toggle_v12_finish()
    assert(studio._terrain_v12_enabled)

    # Independent controls enable only their own material batch.
    studio.terrain_deposits_v12_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    var no_deposits: Dictionary = studio.model_root.get_meta("terrain_sediments_v12")
    assert(int(no_deposits["sediment_patches"])==0)
    assert(int(no_deposits["road_verges"])>0)
    assert(int(no_deposits["batches"])==1)
    studio.terrain_deposits_v12_toggle.button_pressed=true
    studio.terrain_verges_v12_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    var no_roads: Dictionary = studio.model_root.get_meta("terrain_sediments_v12")
    assert(int(no_roads["sediment_patches"])>0)
    assert(int(no_roads["road_verges"])==0)
    assert(int(no_roads["batches"])==1)
    studio.terrain_verges_v12_toggle.button_pressed=true

    for scene in [0,1,2]:
        studio.terrain_scene_picker.select(scene)
        studio._change_terrain_scene(scene)
        var data: Dictionary = studio.model_root.get_meta("terrain_sediments_v12")
        assert(int(data["batches"])==2)
        assert(int(data["sediment_patches"])>0)
        assert(int(data["road_verges"])>0)
        assert(studio.model_root.get_meta("terrain_counts").values().reduce(
            func(acc,amount): return acc+int(amount),0)==120)
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(int(studio.model_root.get_meta("terrain_bridge_visual_count"))==(
            2 if scene==1 else 0))
        _check_mesh(studio,"DepositosAluvialesV12",scene)
        _check_mesh(studio,"ArcenesNaturalesV12",scene)

    # The older comparison disables V16, without erasing its controls.
    studio._toggle_v11_finish()
    assert(not studio._terrain_v12_enabled)
    assert(int(studio.model_root.get_meta("terrain_sediments_v12")["batches"])==0)
    studio._toggle_v12_finish()
    assert(studio._terrain_v12_enabled)
    assert(studio._terrain_v11_enabled)
    studio.terrain_continuous_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta("terrain_sediments_v12")["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed=true
    studio._rebuild_terrain(false)
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio._switch_category(2)
    assert(studio._role=="terrain")
    studio.free()
    print("PASS TERRAIN_STUDIO_V16: valley sediments, road verges, V15b comparison, two batches, full land-safe mesh, three biomes")
    quit(0)
