extends SceneTree

# Actual native-Godot weather/terrain QA inside TARVOKA's 3D web showroom.
# Confirms 3 public climates x 4 locations, existing V12/V13/V15 controls,
# rain/snow geometry budgets, no gameplay state or original 3D mesh changes.
const Climate = preload("res://scripts/ui/HeadquartersClimateV17.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Production = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const Sprites = preload("res://scripts/ui/HeadquartersSpriteStudioV16.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int = 7) -> void:
    for i in range(count):
        await process_frame

func _save(name: String) -> Image:
    var image: Image = root.get_texture().get_image()
    assert(image != null and not image.is_empty())
    assert(image.get_width()>=900 and image.get_height()>=540)
    assert(image.save_png("res://artifacts/"+name)==OK)
    return image

func _different(a: Image,b: Image) -> int:
    var first: Image = a.duplicate()
    var second: Image = b.duplicate()
    first.resize(420,260,Image.INTERPOLATE_LANCZOS)
    second.resize(420,260,Image.INTERPOLATE_LANCZOS)
    var diff: int = 0
    for y in range(0,260,4):
        for x in range(0,420,4):
            var p: Color = first.get_pixel(x,y)
            var q: Color = second.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.17:
                diff+=1
    return diff

func _run() -> void:
    assert(Climate.WEATHERS == ["clear","rain","snow"])
    assert(Climate.TERRAINS == ["asphalt","grass","desert","rock"])
    assert(Climate.GROUND_COLORS.size()==4)
    assert(not Climate.valid("blizzard","asphalt"))
    assert(not Climate.valid("clear","ocean"))
    var standalone: Node3D = Climate.build()
    assert(standalone != null)
    assert(standalone.get_meta("tarvoka_hq_visual_only",false))
    assert(Climate.active_mesh_count(standalone)<=Climate.MATERIAL_BUDGET)
    assert(Climate.apply(standalone,"rain","grass",3))
    assert(standalone.get_meta("tarvoka_weather_visual")=="rain")
    assert(standalone.get_meta("tarvoka_terrain_visual")=="grass")
    assert(standalone.get_node("LluviaUnLoteV17").visible)
    assert(not standalone.get_node("CoposNieveUnLoteV17").visible)
    for i in range(4):
        assert(standalone.get_node("CharcoFisicoV17_%d" % i).visible)
    assert(Climate.apply(standalone,"snow","desert",1))
    assert(standalone.get_node("CoposNieveUnLoteV17").visible)
    for i in range(3):
        assert(standalone.get_node("NieveAcumuladaCubiertaV17_%d" % i).visible)
    assert(Climate.apply(standalone,"snow","desert",2,"destruido"))
    for i in range(3):
        assert(not standalone.get_node("NieveAcumuladaCubiertaV17_%d" % i).visible)
    assert(Climate.apply(standalone,"snow","desert",2,"operativo",true))
    for i in range(3):
        assert(not standalone.get_node("NieveAcumuladaCubiertaV17_%d" % i).visible)
    assert(not Climate.apply(standalone,"storm","desert"))
    assert(not Climate.apply(standalone,"clear","grass",5))
    assert(Climate.apply(standalone,"clear","rock"))
    assert(Climate.active_mesh_count(standalone)==2)
    assert(standalone.get_meta("tarvoka_precipitation_draws",-1)==0)
    standalone.free()

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    root.add_child(studio)
    await _frames()
    studio._switch_category(1)
    await _frames()
    assert(studio.hq_weather_picker.item_count==3)
    assert(studio.hq_terrain_picker.item_count==4)
    assert(studio.hq_weather_picker.selected==0)
    assert(studio.hq_terrain_picker.selected==0)
    assert(studio.hq_climate_stage!=null and studio.hq_climate_stage.visible)
    assert(studio.hq_climate_stage.get_meta("tarvoka_hq_climate_stage_v17",false))
    assert(studio.hq_v15_thumbnail.texture==Sprites.texture_for(0))
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    var original_meshes: int = Production._meshes(studio.model_root)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var clear: Image = _save("tarvoka_hq_v17_3d_clear_asphalt.png")

    # Preview actual 12 combinations with a fixed 3D camera; retain primary
    # V12 model without building a 3D mesh for each weather transition.
    var contact := Image.create(1440,960,false,Image.FORMAT_RGBA8)
    for terrain_index in range(4):
        studio._change_hq_terrain_v17(terrain_index)
        for weather_index in range(3):
            var same_model: Node3D = studio.model_root
            studio._change_hq_weather_v17(weather_index)
            assert(studio.model_root==same_model)
            assert(Production._meshes(studio.model_root)==original_meshes)
            assert(studio.hq_climate_stage.get_meta("tarvoka_weather_visual")==Climate.WEATHERS[weather_index])
            assert(studio.hq_climate_stage.get_meta("tarvoka_terrain_visual")==Climate.TERRAINS[terrain_index])
            assert(Climate.active_mesh_count(studio.hq_climate_stage)<=Climate.MATERIAL_BUDGET)
            assert(studio.hq_climate_status.text.contains(str(Climate.WEATHER_NAMES[weather_index])))
            assert(studio.hq_climate_status.text.contains(str(Climate.TERRAIN_NAMES[terrain_index])))
            await _frames(7)
            var raw: Image = studio.preview.get_texture().get_image()
            assert(raw!=null and not raw.is_empty())
            raw.resize(360,240,Image.INTERPOLATE_LANCZOS)
            contact.blit_rect(raw,Rect2i(0,0,360,240),
                Vector2i(terrain_index*360,weather_index*240))
            if terrain_index==0 and weather_index==1:
                _save("tarvoka_hq_v17_real_rain_puddles_3d_studio.png")
            if terrain_index==1 and weather_index==2:
                _save("tarvoka_hq_v17_snow_on_grass_and_roof_3d_studio.png")
            if terrain_index==2 and weather_index==2:
                _save("tarvoka_hq_v17_snow_desert_studio.png")
    assert(contact.save_png(
        "res://artifacts/tarvoka_hq_v17_four_terrains_three_weathers_godot.png")==OK)
    studio._change_hq_terrain_v17(0)
    studio._change_hq_weather_v17(1)
    await _frames()
    var rainy: Image = _save("tarvoka_hq_v17_rain_screen_with_controls.png")
    assert(_different(clear,rainy)>150)
    studio._change_hq_weather_v17(2)
    await _frames()
    var snowy: Image = _save("tarvoka_hq_v17_snow_screen_with_controls.png")
    assert(_different(clear,snowy)>150)
    assert(_different(rainy,snowy)>140)

    # The current sprite V15 remains the original dry PNG. Climate appears
    # around it as independent, lightweight Godot stage geometry.
    studio._change_hq_v15_mode(2)
    assert(studio.model_root.get_meta("tarvoka_hq_v15_sprite_card",false))
    assert(not studio.hq_climate_stage.get_node("NieveAcumuladaCubiertaV17_0").visible)
    assert(studio.hq_climate_stage.get_node("CoposNieveUnLoteV17").visible)
    assert(studio.hq_climate_status.text.contains("Sprite V15"))
    await _frames()
    _save("tarvoka_hq_v17_weather_around_actual_android_sprite.png")
    studio._change_hq_v15_mode(0)
    studio.hq_production_toggle.set_pressed_no_signal(true)
    studio._change_hq_production_v13(true)
    assert(studio.model_root.get_meta("tarvoka_hq_production_v13",false))
    studio._change_hq_weather_v17(1)
    assert(Production.render_budget(studio.model_root)["within_tactical_budget"])
    await _frames()
    _save("tarvoka_hq_v17_optimized_v13_rain.png")

    studio._switch_category(0)
    assert(studio._role=="tank")
    assert(not studio.hq_climate_stage.visible)
    assert(studio.faction_view_grid.visible)
    studio._switch_category(1)
    assert(studio.hq_climate_stage.visible)
    assert(studio.hq_terrain_picker.selected==0)
    assert(studio.hq_weather_picker.selected==1)
    studio.queue_free()
    print("PASS HQ V17: 3 public climates, 4 material terrains, one-batch precipitation, rain puddles, snow roofs, 12 GPU renders, Android sprite/v12/v13 preservation, no gameplay mutation")
    quit(0)
