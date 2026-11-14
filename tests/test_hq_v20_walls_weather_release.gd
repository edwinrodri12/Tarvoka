extends SceneTree

# HQ V20 native GPU and *release* source QA. Godot omits assert() expression
# evaluation in non-debug exports; shader/climate updates must run outside it.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Climate = preload("res://scripts/ui/HeadquartersClimateV17.gd")
const Universal = preload("res://scripts/ui/WeatherCoating3D.gd")
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int = 6) -> void:
    for _i in range(n):
        await process_frame

func _image(name: String) -> Image:
    var raw: Image = root.get_texture().get_image()
    assert(raw != null and raw.get_width() >= 900)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts")) == OK)
    assert(raw.save_png("res://artifacts/" + name) == OK)
    return raw

func _viewport_image(studio: Control) -> Image:
    var out: Image = studio.preview.get_texture().get_image()
    assert(out != null and not out.is_empty())
    out.resize(320,220,Image.INTERPOLATE_LANCZOS)
    return out

func _pixel_changes(a: Image,b: Image) -> int:
    var changes: int = 0
    for y in range(0,220,3):
        for x in range(0,320,3):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.14:
                changes += 1
    return changes

func _run() -> void:
    # Guard against the exact production regression reported by the user.
    var source: String = FileAccess.get_file_as_string(
        "res://scripts/ui/CombinedArtStudioWeb.gd")
    assert(not source.is_empty())
    assert(not source.contains("assert(HQClimateV17.apply("))
    assert(not source.contains("assert(HQWayfindingV18.apply("))
    assert(not source.contains("assert(HQFacadeV19.apply("))
    assert(source.contains("var climate_applied: bool = HQClimateV17.apply("))
    assert(source.contains("var applied: bool = HQWayfindingV18.apply("))
    assert(source.contains("var applied: bool = HQFacadeV19.apply("))

    # Actual geometry now seals BOTH formerly open wing walls, behind the
    # V12 glass at z=-3.117, with no stage-side visual fake wall.
    for level in range(1,4):
        var model: Node3D = HQ.build(level,0,"operativo")
        assert(model != null and model.get_meta("tarvoka_hq_visual_v12",false))
        for side in [-1,1]:
            var name: String = "MuroContinuoBajoVentanasAlaV20_%s" % side
            var wall: MeshInstance3D = model.find_child(name,true,false)
            var joint: MeshInstance3D = model.find_child(
                "EncuentroEstructuralAlaCentralV20_%s" % side,true,false)
            assert(wall != null and wall.mesh is BoxMesh)
            assert(joint != null and joint.mesh is BoxMesh)
            var dimensions: Vector3 = (wall.mesh as BoxMesh).size
            assert(dimensions.z >= 1.30 and dimensions.y >= 2.80)
            assert(wall.position.z - dimensions.z*0.5 > -3.117)
            assert(wall.position.z + dimensions.z*0.5 >= -1.74)
            assert(absf(wall.position.x-float(side)*4.06) < 0.01)
            assert(absf(joint.position.x) > 2.55)
            assert(absf(joint.position.x) < 2.95)
            assert(model.find_child(
                "VidrioMiradorAla_%s_-1" % side,true,false) != null)
        model.free()
    var rubble: Node3D = HQ.build(2,0,"destruido")
    assert(rubble.find_child("MuroContinuoBajoVentanasAlaV20_-1",true,false)==null)
    rubble.free()

    # Run exactly the user-visible climate selectors, not just static stage.
    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    root.add_child(studio)
    await _frames(8)
    studio._switch_category(1)
    await _frames(8)
    var same_model: Node3D = studio.model_root
    assert(studio.hq_climate_stage.visible)
    var clear: Image = _viewport_image(studio)
    _image("tarvoka_hq_v20_walls_day_clear.png")

    studio._change_hq_weather_v17(1)
    await _frames(8)
    var rain: Image = _viewport_image(studio)
    assert(studio.model_root == same_model)
    assert(studio.hq_climate_stage.get_node("LluviaUnLoteV17").visible)
    assert(not studio.hq_climate_stage.get_node("CoposNieveUnLoteV17").visible)
    assert(studio.hq_climate_stage.get_meta("tarvoka_weather_visual")=="rain")
    var wet: Dictionary = studio.model_root.get_meta("weather_coating",{})
    assert(wet.get("mode","")=="rain")
    assert(int(wet.get("wet",0)) > 0)
    assert(_pixel_changes(clear,rain) > 60)
    _image("tarvoka_hq_v20_walls_rain_release_fix.png")

    studio._change_hq_weather_v17(2)
    await _frames(8)
    var snow: Image = _viewport_image(studio)
    assert(studio.hq_climate_stage.get_node("CoposNieveUnLoteV17").visible)
    assert(not studio.hq_climate_stage.get_node("LluviaUnLoteV17").visible)
    var icy: Dictionary = studio.model_root.get_meta("weather_coating",{})
    assert(icy.get("mode","")=="snow")
    assert(int(icy.get("snow_nodes",0)) > 0)
    assert(int(icy.get("snow_nodes",0)) <= Universal.MAX_SNOW_NODES)
    assert(_pixel_changes(clear,snow)>80)
    assert(_pixel_changes(rain,snow)>80)
    _image("tarvoka_hq_v20_walls_snow_release_fix.png")
    studio._change_hq_weather_v17(0)
    await _frames(6)
    assert(studio.model_root.get_meta("weather_coating",{}).get("mode","")=="clear")
    assert(studio.hq_climate_status.text.contains("Despejado"))
    studio.hq_wayfinding_toggle.button_pressed = true
    studio.hq_facade_v19_toggle.button_pressed = true
    studio._change_hq_lighting(2)
    await _frames()
    assert(studio.model_root.get_node("SenalizacionArquitectonicaHQV18").visible)
    assert(studio.model_root.get_node("DetallesFachadaYMarcoEscudoHQV19").visible)
    studio._set_hq_map_lod(true)
    assert(not studio.model_root.get_node("SenalizacionArquitectonicaHQV18").visible)
    assert(not studio.model_root.get_node("DetallesFachadaYMarcoEscudoHQV19").visible)
    studio._set_hq_map_lod(false)
    studio._change_hq_weather_v17(1)
    studio.hq_v15_mode_picker.select(2)
    studio._display_headquarters()
    assert(studio.model_root.get_meta("tarvoka_hq_v15_sprite_card",false))
    assert(studio.hq_climate_stage.get_node("LluviaUnLoteV17").visible)
    studio.queue_free()
    await _frames(3)
    print("PASS HQ V20: real wing walls, glazing unblocked, release-safe rain/snow, V18/V19, LOD and V15 sprite")
    quit(0)
