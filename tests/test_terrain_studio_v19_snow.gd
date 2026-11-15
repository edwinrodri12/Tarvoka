extends SceneTree

# Godot 4.3/GPU V19 contract: a TRUE 4th winter scene, not a filter on the
# forest, with ice-water/roads/snow-tipped conifers and snow painted directly
# on the actual V7/V11 meshes. First 3 scenes and game rules remain intact.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Winter = preload("res://scripts/ui/TerrainStudioSnowPaletteV15.gd")

func _initialize() -> void:
    call_deferred("_run")

func _mesh_colors(node: MeshInstance3D) -> Dictionary:
    assert(node!=null and node.mesh!=null)
    var data: Array = node.mesh.surface_get_arrays(0)
    var verts: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
    var hues: PackedColorArray = data[Mesh.ARRAY_COLOR]
    assert(verts.size()>0 and verts.size()==hues.size())
    assert(node.material_override is StandardMaterial3D)
    assert((node.material_override as StandardMaterial3D).vertex_color_use_as_albedo)
    var accumulated := Color(0.0,0.0,0.0,0.0)
    for hue in hues:
        accumulated += hue
    return {"vertices":verts,"colors":hues,
        "mean":accumulated/float(hues.size())}

func _different_real_vertices(a: Dictionary,b: Dictionary,
        min_rgb: float) -> int:
    var v1: PackedVector3Array = a["vertices"]
    var v2: PackedVector3Array = b["vertices"]
    var c1: PackedColorArray = a["colors"]
    var c2: PackedColorArray = b["colors"]
    assert(v1.size()==v2.size() and c1.size()==c2.size())
    var changed := 0
    for i in range(v1.size()):
        assert(v1[i].distance_to(v2[i])<0.0001)
        var d: Color = c1[i]
        var e: Color = c2[i]
        if absf(d.r-e.r)+absf(d.g-e.g)+absf(d.b-e.b)>min_rgb:
            changed += 1
    return changed

func _snapshot(studio: Control,path: String) -> Image:
    for i in range(7):
        await process_frame
    var image: Image = studio.preview.get_texture().get_image()
    assert(image!=null and not image.is_empty())
    assert(image.save_png(path)==OK)
    return image

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    assert(Terrain.SCENES.size()==4)
    assert(Terrain.SCENES[3]=="Bioma nevado")
    assert(Terrain.kind(0,0,0)=="mountain")
    assert(Terrain.kind(0,0,1)=="mountain")
    assert(Terrain.kind(9,5,2)=="water")
    assert(Terrain.kind(0,0,3)=="mountain")
    assert(Terrain.kind(10,6,3)=="water")
    assert(Terrain.kind(5,6,3)=="road")
    assert(Terrain.kind(2,6,3)=="forest")
    assert(Terrain.kind(4,6,3)=="plain")
    assert(Winter.ground("plain",100)!=
        Terrain._ground_tint("plain",0,100))
    assert(Winter.mountain(Color("#586c73"),
        Vector3(1.5,2.0,-3.2),1.3,0.4)!=Color("#586c73"))

    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed!=null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for i in range(7):
        await process_frame
    studio._switch_category(2)
    for i in range(6):
        await process_frame
    assert(studio._role=="terrain")
    assert(studio.terrain_scene_picker.item_count==4)
    assert(studio.terrain_scene_picker.get_item_text(3)=="Bioma nevado")
    assert(studio._terrain_v13_enabled)
    assert(studio.terrain_baked_biome_v14_toggle.button_pressed)
    assert(studio.terrain_continuous_toggle.button_pressed)
    assert(studio.terrain_scatter_toggle.button_pressed)

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    studio.terrain_scene_picker.select(3)
    studio._change_terrain_scene(3)
    studio._view_normal_game_distance()
    assert(studio.model_root.get_meta("terrain_snow_v19"))
    assert(studio.model_root.get_meta("terrain_studio_scene")==3)
    var original: Dictionary = studio.model_root.get_meta(
        "terrain_counts").duplicate(true)
    var tiles := 0
    for count in original.values():
        tiles += int(count)
        assert(int(count)>0)
    assert(tiles==120)
    assert(studio.model_root.get_meta("terrain_tile_count")==120)
    assert(studio.model_root.get_meta("terrain_bridge_visual_count")==0)
    assert(studio.model_root.get_meta("terrain_biome_v14")["enabled"])
    var mountain: Dictionary = _mesh_colors(
        studio.model_root.find_child("MacizosErosionadosContinuosV7",true,false))
    var slope: Dictionary = _mesh_colors(
        studio.model_root.find_child("TaludesTransicionV11",true,false))
    var road: Dictionary = _mesh_colors(
        studio.model_root.find_child("CalzadaContinuaV3_*",true,false))
    var water: Dictionary = _mesh_colors(
        studio.model_root.find_child("LaminaDeAguaContinua",true,false))
    var ground: Dictionary = _mesh_colors(
        studio.model_root.find_child("SueloContinuoConRelieve",true,false))
    var trees: Dictionary = studio.model_root.get_meta("terrain_natural_v6")
    assert(int(trees["trees"])>=10)
    assert(int(trees["batches"])>0)
    assert(studio.model_root.find_child("BosqueAbetosV6",true,false)!=null)
    assert(studio.model_root.find_child("BosquePinosV6",true,false)!=null)
    assert(studio.model_root.find_child("BosqueCaducifoliosV6",true,false)==null)
    assert(studio.model_root.find_child("TanqueDeReferencia",true,false)!=null)
    assert(studio.model_root.find_child("CuartelDeReferencia",true,false)!=null)
    # Winter asphalt still reads distinctly darker than bright snowfield.
    assert((road["mean"] as Color).r<(ground["mean"] as Color).r)
    assert((water["mean"] as Color).r<0.40)
    assert((water["mean"] as Color).b>(water["mean"] as Color).r)
    assert((ground["mean"] as Color).r>0.54)
    assert((mountain["mean"] as Color).r>0.43)
    var new_image: Image = await _snapshot(studio,
        "res://artifacts/tarvoka_v19_bioma_nevado.png")

    # The snow must change the visible ridge & footslope, never slide a
    # decal underneath. Compare identical vertex positions after toggle.
    studio.terrain_baked_biome_v14_toggle.button_pressed=false
    studio._rebuild_terrain(false)
    var old_mountain: Dictionary = _mesh_colors(
        studio.model_root.find_child("MacizosErosionadosContinuosV7",true,false))
    var old_slope: Dictionary = _mesh_colors(
        studio.model_root.find_child("TaludesTransicionV11",true,false))
    assert(_different_real_vertices(old_mountain,mountain,0.035)>100)
    assert(_different_real_vertices(old_slope,slope,0.025)>30)
    assert(studio.model_root.get_meta("terrain_counts")==original)
    var old_image: Image = await _snapshot(studio,
        "res://artifacts/tarvoka_v19_before_direct_snow.png")
    new_image.resize(640,400,Image.INTERPOLATE_LANCZOS)
    old_image.resize(640,400,Image.INTERPOLATE_LANCZOS)
    var image_pair := Image.create(1280,400,false,Image.FORMAT_RGBA8)
    image_pair.blit_rect(
        old_image,Rect2i(0,0,640,400),Vector2i.ZERO)
    image_pair.blit_rect(
        new_image,Rect2i(0,0,640,400),Vector2i(640,0))
    assert(image_pair.save_png(
        "res://artifacts/tarvoka_v19_snow_surface_comparison.png")==OK)
    studio.terrain_baked_biome_v14_toggle.button_pressed=true
    studio._rebuild_terrain(false)
    studio._view_ridge_profile()
    await _snapshot(studio,
        "res://artifacts/tarvoka_v19_snow_mountain_profile.png")

    # Prior environments remain selectable with their expected types.
    for scene in [0,1,2]:
        studio.terrain_scene_picker.select(scene)
        studio._change_terrain_scene(scene)
        assert(not studio.model_root.get_meta("terrain_snow_v19"))
        assert(studio.model_root.get_meta("terrain_tile_count")==120)
        assert(studio.model_root.get_meta(
            "terrain_bridge_visual_count")==(2 if scene==1 else 0))
    studio._switch_category(0)
    assert(studio._role=="tank")
    studio._switch_category(1)
    assert(studio._role=="headquarters")
    studio._switch_category(3)
    assert(studio._role=="battle")
    studio.free()
    print("PASS TERRAIN_STUDIO_V19_SNOW: fourth selectable snow scene, real ridge and talus pigments, iced water, roads, conifers, 120 tiles, preserved prior biomes")
    quit(0)
