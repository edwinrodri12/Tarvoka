extends SceneTree

# V18 GPU/geometry contract for real terrain and its three existing
# environmental scenes. Not a mock image; inspect Godot generated mesh
# triangles, terrain ownership, draw budgets and same-camera screenshots.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _inspect_mesh(studio: Control, label: String, scene: int,
        may_include_mountain: bool) -> Dictionary:
    var mesh: MeshInstance3D = studio.model_root.find_child(
        label,true,false) as MeshInstance3D
    assert(mesh != null and mesh.mesh != null)
    assert(mesh.get_meta("visual_only",false))
    var faces: PackedVector3Array = mesh.mesh.get_faces()
    assert(faces.size()>0 and faces.size()%3==0)
    var array: Array = mesh.mesh.surface_get_arrays(0)
    var colors: PackedColorArray = array[Mesh.ARRAY_COLOR]
    var vertices: PackedVector3Array = array[Mesh.ARRAY_VERTEX]
    assert(vertices.size()==colors.size())
    assert(vertices.size()==faces.size())
    var seen: Dictionary = {}
    var touched_mountain := false
    var touched_land := false
    for i in range(vertices.size()):
        var position: Vector3 = vertices[i]
        var x: int = roundi(position.x/Terrain.CELL+float(Terrain.WIDTH-1)*0.5)
        var z: int = roundi(position.z/Terrain.CELL+float(Terrain.HEIGHT-1)*0.5)
        assert(x>=0 and x<Terrain.WIDTH and z>=0 and z<Terrain.HEIGHT)
        var kind: String = Terrain.kind(x,z,scene)
        assert(kind in ["mountain","plain","forest"])
        if not may_include_mountain:
            assert(kind in ["plain","forest"])
        touched_mountain = touched_mountain or kind=="mountain"
        touched_land = touched_land or kind in ["plain","forest"]
        var gx: float = (float(x)-float(Terrain.WIDTH-1)*0.5)*Terrain.CELL
        var gz: float = (float(z)-float(Terrain.HEIGHT-1)*0.5)*Terrain.CELL
        assert(absf(position.x-gx)<Terrain.CELL*0.5-0.10)
        assert(absf(position.z-gz)<Terrain.CELL*0.5-0.10)
        assert(position.y>=Terrain.surface_height_at(
            x,z,scene,position.x-gx,position.z-gz)+0.009)
        var tint: Color = colors[i]
        assert(tint.r>=0.0 and tint.r<=1.0)
        assert(tint.g>=0.0 and tint.g<=1.0)
        assert(tint.b>=0.0 and tint.b<=1.0)
        seen[tint.to_html()] = true
    assert(seen.size()>=3)
    return {"faces":faces.size()/3,
        "colors":seen.size(),"mountain":touched_mountain,
        "land":touched_land}

func _image(studio: Control,path: String) -> Image:
    for i in range(7):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image!=null and not image.is_empty())
    assert(image.save_png(path)==OK)
    return image

func _differences(first: Image,second: Image) -> int:
    var a: Image = first.duplicate()
    var b: Image = second.duplicate()
    a.resize(500,300,Image.INTERPOLATE_LANCZOS)
    b.resize(500,300,Image.INTERPOLATE_LANCZOS)
    var different := 0
    for y in range(10,290,3):
        for x in range(10,490,3):
            var c: Color = a.get_pixel(x,y)
            var d: Color = b.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.085:
                different += 1
    return different

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed!=null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for i in range(6):
        await process_frame
    studio._switch_category(2)
    for i in range(5):
        await process_frame
    assert(studio._role=="terrain")
    assert(studio._terrain_v13_enabled)
    assert(studio.terrain_mineral_v13_toggle.button_pressed)
    assert(studio.terrain_habitat_v13_toggle.button_pressed)
    assert(studio.terrain_compare_v13_button.name=="ComparadorTerrenoV12V13")
    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var checked := 0
    for scene in [0,1,2]:
        studio.terrain_scene_picker.select(scene)
        studio._change_terrain_scene(scene)
        studio._view_normal_game_distance()
        var counts: Dictionary = studio.model_root.get_meta(
            "terrain_counts").duplicate(true)
        var previous: Dictionary = studio.model_root.get_meta(
            "terrain_sediments_v12").duplicate(true)
        var stats: Dictionary = studio.model_root.get_meta(
            "terrain_mountain_biomes_v13")
        assert(int(studio.model_root.get_meta("terrain_tile_count"))==120)
        assert(int(stats["scene"])==scene)
        assert(int(stats["mountain_cells"])==int(counts["mountain"]))
        assert(int(stats["mountain_cells"])>0)
        assert(int(stats["mountain_edges"])>0)
        assert(int(stats["ridge_facets"])==int(counts["mountain"])*6)
        assert(int(stats["mantle_triangles"])==int(stats["mountain_edges"])*48)
        assert(int(stats["ecotone_pieces"])>=2*int(stats["mountain_edges"]))
        assert(int(stats["road_cells_skipped"])==int(counts["road"]))
        assert(int(stats["water_cells_skipped"])==int(counts["water"]))
        assert(int(stats["batches"])==2)
        assert(studio.status_label.text.contains("V13:"))
        assert(int(studio.model_root.get_meta(
            "terrain_bridge_visual_count"))==(2 if scene==1 else 0))
        var mineral: Dictionary = _inspect_mesh(
            studio,"EstratosYTaludesBiomaV13",scene,true)
        var habitat: Dictionary = _inspect_mesh(
            studio,"VegetacionYPedregalBiomaV13",scene,false)
        assert(bool(mineral["mountain"]) and bool(mineral["land"]))
        assert(bool(habitat["land"]) and not bool(habitat["mountain"]))
        assert(int(mineral["faces"])==int(stats["ridge_facets"])+int(
            stats["mantle_triangles"]))
        assert(int(habitat["faces"])==int(stats["ecotone_pieces"]))
        var image_path: String = [
            "res://artifacts/tarvoka_terrain_v18_woodland.png",
            "res://artifacts/tarvoka_terrain_v18_canyon.png",
            "res://artifacts/tarvoka_terrain_v18_coastal.png"][scene]
        var v18: Image = await _image(studio,image_path)
        studio._toggle_v13_finish()
        assert(not studio._terrain_v13_enabled)
        assert(int(studio.model_root.get_meta(
            "terrain_mountain_biomes_v13")["batches"])==0)
        assert(studio.model_root.find_child(
            "EstratosYTaludesBiomaV13",true,false)==null)
        assert(studio.model_root.find_child(
            "VegetacionYPedregalBiomaV13",true,false)==null)
        assert(studio.model_root.get_meta("terrain_counts")==counts)
        assert(studio.model_root.get_meta("terrain_sediments_v12")==previous)
        var prior: Image = await _image(studio,
            "res://artifacts/tarvoka_terrain_v18_previous_%d.png" % scene)
        assert(_differences(prior,v18)>6)
        if scene==0:
            var first: Image = prior.duplicate()
            var second: Image = v18.duplicate()
            first.resize(620,400,Image.INTERPOLATE_LANCZOS)
            second.resize(620,400,Image.INTERPOLATE_LANCZOS)
            var pair := Image.create(1240,400,false,Image.FORMAT_RGBA8)
            pair.blit_rect(first,Rect2i(0,0,620,400),Vector2i.ZERO)
            pair.blit_rect(second,Rect2i(0,0,620,400),Vector2i(620,0))
            assert(pair.save_png(
                "res://artifacts/tarvoka_terrain_v18_vs_v17.png")==OK)
        studio._toggle_v13_finish()
        assert(studio._terrain_v13_enabled)
        checked += 1
    studio.terrain_mineral_v13_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    var no_minerals: Dictionary = studio.model_root.get_meta(
        "terrain_mountain_biomes_v13")
    assert(int(no_minerals["ridge_facets"])==0)
    assert(int(no_minerals["mantle_triangles"])==0)
    assert(int(no_minerals["ecotone_pieces"])>0)
    assert(int(no_minerals["batches"])==1)
    studio.terrain_mineral_v13_toggle.button_pressed=true
    studio.terrain_habitat_v13_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    var no_habitats: Dictionary = studio.model_root.get_meta(
        "terrain_mountain_biomes_v13")
    assert(int(no_habitats["ridge_facets"])>0)
    assert(int(no_habitats["ecotone_pieces"])==0)
    assert(int(no_habitats["batches"])==1)
    studio.terrain_habitat_v13_toggle.button_pressed=true
    studio._toggle_v12_finish()
    assert(not studio._terrain_v13_enabled)
    assert(int(studio.model_root.get_meta(
        "terrain_mountain_biomes_v13")["batches"])==0)
    studio._toggle_v13_finish()
    assert(studio._terrain_v13_enabled)
    assert(studio._terrain_v12_enabled)
    studio._view_ridge_profile()
    await _image(studio,"res://artifacts/tarvoka_terrain_v18_ridge_profile.png")
    studio.terrain_continuous_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    assert(int(studio.model_root.get_meta(
        "terrain_mountain_biomes_v13")["batches"])==0)
    studio.terrain_continuous_toggle.button_pressed=true
    studio._rebuild_terrain(false)
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio.free()
    print("PASS TERRAIN_STUDIO_V18: %d biome scenes, mountain facet/apron/plant geometry, safe tile footprints, V17 comparison, zero tactical mutations" % checked)
    quit(0)
