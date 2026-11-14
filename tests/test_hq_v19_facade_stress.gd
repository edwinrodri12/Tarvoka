extends SceneTree

# Native GPU V19: verify actual bevelled mesh, authentic crest, aligned
# window lights, all three HQ levels and 49/100/144 batch stress presets.
const Facade = preload("res://scripts/ui/HeadquartersFacadeV19.gd")
const Wayfinding = preload("res://scripts/ui/HeadquartersWayfindingV18.gd")
const City = preload("res://scripts/ui/HeadquartersCityBatch3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int = 5) -> void:
    for _i in range(count):
        await process_frame

func _save(filename: String) -> void:
    var image: Image = root.get_texture().get_image()
    assert(image != null and not image.is_empty())
    assert(image.get_width() >= 900 and image.get_height() >= 540)
    assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts")) == OK)
    assert(image.save_png("res://artifacts/" + filename) == OK)

func _run() -> void:
    var stage: Node3D = Facade.build()
    assert(stage.get_meta("tarvoka_hq_v19_facade",false))
    assert(stage.get_meta("tarvoka_visual_only",false))
    assert(Facade.instances(stage) == Facade.INSTANCE_TOTAL)
    assert(Facade.INSTANCE_TOTAL == 20)
    assert(Facade.batches(stage) == 0)
    assert(Facade.apply(stage,0,1,"operativo","clear"))
    assert(Facade.batches(stage) == 2)
    var windows: MultiMeshInstance3D = stage.get_node("JunquillosVentanasAlaV19")
    var crest: MultiMeshInstance3D = stage.get_node("MarcoPerimetralSinCubrirEscudoV19")
    assert(windows.multimesh.mesh == crest.multimesh.mesh)
    assert(windows.multimesh.mesh.get_surface_count() == 1)
    var color_before: Color = (crest.material_override as StandardMaterial3D).albedo_color
    var y_before: float = crest.multimesh.get_instance_transform(0).origin.y
    assert(Facade.apply(stage,7,3,"capturado","rain"))
    assert(crest.multimesh.get_instance_transform(0).origin.y > y_before + 1.8)
    assert((crest.material_override as StandardMaterial3D).albedo_color != color_before)
    assert(Facade.instances(stage)==20)
    assert(Facade.apply(stage,2,2,"danado","snow"))
    assert(windows.multimesh.visible_instance_count == 8)
    assert(Facade.apply(stage,2,2,"destruido","snow"))
    assert(Facade.batches(stage)==0)
    assert(Facade.apply(stage,2,2,"operativo","clear",true,true))
    assert(Facade.batches(stage)==0)
    assert(not Facade.apply(stage,8,1,"operativo","clear"))
    assert(not Facade.apply(stage,0,4,"operativo","clear"))
    assert(not Facade.apply(stage,0,1,"operativo","storm"))
    stage.free()

    # V18 light coordinates must match the real V12 glass openings.
    var lights: Node3D = Wayfinding.build()
    var glow: MultiMeshInstance3D = lights.get_node("VentanasIluminadasUnLoteV18")
    assert(is_equal_approx(glow.multimesh.get_instance_transform(0).origin.x,-4.60))
    assert(is_equal_approx(glow.multimesh.get_instance_transform(3).origin.x,4.60))
    assert(is_equal_approx(glow.multimesh.get_instance_transform(0).origin.y,2.56))
    assert(Wayfinding.apply(lights,0,1,"operativo",2,"clear"))
    var lower: float = glow.multimesh.get_instance_transform(6).origin.y
    assert(Wayfinding.apply(lights,0,3,"operativo",2,"snow"))
    assert(is_equal_approx(glow.multimesh.get_instance_transform(6).origin.y-lower,1.82))
    assert(Wayfinding.instances(lights)==14 and Wayfinding.batches(lights)==3)
    lights.free()

    # Verify the official atlas remains the exact texture in each faction.
    for faction in range(8):
        var texture: Texture2D = Emblems.emblem_texture(faction)
        assert(texture != null and texture.get_width() == 160)
        assert(Emblems.emblem_texture(faction) == texture)

    root.content_scale_size = Vector2i(1200,740)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    await _frames(7)
    studio._switch_category(1)
    await _frames()
    assert(studio.hq_facade_v19_toggle.button_pressed)
    assert(studio.hq_stress_picker.item_count==3)
    var facade: Node3D = studio.model_root.get_node_or_null(Facade.STAGE_NAME)
    assert(facade!=null and Facade.instances(facade)==20)
    assert(studio.model_root.get_meta("tarvoka_hq_official_emblem",false))
    assert(studio.model_root.find_child("EscudoOficialFaccion3D",true,false)!=null)
    _save("tarvoka_hq_v19_day_facade_crest.png")
    studio._change_hq_lighting(2)
    await _frames()
    _save("tarvoka_hq_v19_night_glass_alignment.png")
    studio._change_hq_weather_v17(1)
    await _frames()
    assert(facade.get_meta("tarvoka_hq_v19_weather","")=="rain")
    _save("tarvoka_hq_v19_rain_facade_crest.png")
    studio._set_hq_map_lod(true)
    assert(Facade.batches(facade)==0)
    studio._set_hq_map_lod(false)
    assert(Facade.batches(facade)==2)
    studio._change_hq_v15_mode(2)
    await _frames()
    assert(studio.model_root.get_node_or_null(Facade.STAGE_NAME)==null)
    studio._change_hq_v15_mode(0)
    await _frames()
    assert(studio.model_root.get_node_or_null(Facade.STAGE_NAME)!=null)
    studio.hq_production_toggle.button_pressed = true
    await _frames()
    assert(studio.model_root.get_node_or_null(Facade.STAGE_NAME)==null)
    studio.hq_production_toggle.button_pressed = false
    await _frames()

    studio.hq_batch_toggle.button_pressed = true
    await _frames(5)
    for preset in range(3):
        studio._change_hq_stress_dimension(preset)
        await _frames()
        var n: int = [7,10,12][preset]
        var city: Node3D = studio.model_root
        assert(city.get_meta("tarvoka_studio_building_count",-1)==n*n)
        assert(city.get_meta("tarvoka_studio_grid_columns",-1)==n)
        assert(city.get_meta("tarvoka_studio_grid_rows",-1)==n)
        assert(city.get_child_count()==int(city.get_meta("tarvoka_studio_batch_count",-1)))
        assert(city.get_child_count()<=n*n)
        assert(city.find_child("CuartelGeneral3D",true,false)==null)
        assert(city.find_child(Facade.STAGE_NAME,true,false)==null)
        for child in city.get_children():
            assert(child is MultiMeshInstance3D)
        _save("tarvoka_hq_v19_stress_%d_buildings.png" % (n*n))
    studio.queue_free()
    await _frames(3)
    print("PASS HQ V19: aligned glows, 20 bevels/2 batches, official 8 shields, weather/LOD, 49/100/144 HQ stress")
    quit(0)
