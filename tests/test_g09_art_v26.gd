extends SceneTree

# G09 V26 battle-like visual QA. Render the original V25 tank under
# twelve actual Godot lighting/terrain combinations, with A/B V24 control.
# Scenarios are an art-preview feature, not tactical game map overrides.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Studio = preload("res://scripts/ui/UnitArtStudioWeb.gd")
const Scenario = preload("res://scripts/ui/TankBattleScenarioV26.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const Wear = preload("res://scripts/ui/TankWearV25.gd")

func _initialize() -> void:
    call_deferred("_run")

func _capture(studio) -> Image:
    for i in range(8):
        await process_frame
    var output: Image = studio.preview.get_texture().get_image()
    assert(output!=null and not output.is_empty())
    output.resize(480,330,Image.INTERPOLATE_LANCZOS)
    return output

func _pixel_delta(a: Image,b: Image) -> int:
    var changed: int = 0
    for y in range(0,330,5):
        for x in range(0,480,5):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.14:
                changed += 1
    return changed

func _average(image: Image) -> float:
    var value := 0.0
    var count := 0
    for y in range(0,330,8):
        for x in range(0,480,8):
            var p: Color = image.get_pixel(x,y)
            value += 0.2126*p.r+0.7152*p.g+0.0722*p.b
            count += 1
    return value/float(count)

func _two(a: Image,b: Image,path: String) -> void:
    var compare := Image.create(960,330,false,Image.FORMAT_RGBA8)
    compare.blit_rect(a,Rect2i(0,0,480,330),Vector2i.ZERO)
    compare.blit_rect(b,Rect2i(0,0,480,330),Vector2i(480,0))
    assert(compare.save_png("res://artifacts/"+path)==OK)

func _run() -> void:
    assert(Scenario.TERRAIN_NAMES.size()==4)
    assert(Scenario.LIGHT_NAMES.size()==3)
    var model: Node3D = Models.build("tank",4,true,25)
    var android: Node3D = Models.build("tank",4,true)
    assert(model!=null and android!=null)
    assert(Models.paintable_count(model)==14)
    assert(Models.paintable_count(android)==14)
    assert(model.get_meta("tarvoka_mbt_wear_v25",false))
    assert(not android.get_meta("tarvoka_mbt_wear_v25",false))
    assert(Wear._targets().size()==17)
    model.free()
    android.free()

    DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))
    var studio := Studio.new()
    root.add_child(studio)
    studio._toggle_v25()
    studio._on_faction(4)
    studio._toggle_tactical_camera()
    assert(studio._tactical_view)
    var initial_meshes: int = Models.inspect_meshes(studio.model_root)
    assert(studio.terrain_picker.item_count==4)
    assert(studio.light_picker.item_count==3)
    var tank_id: int = studio.model_root.get_instance_id()
    var yaw: float = studio._yaw
    var zoom: float = studio._zoom
    studio._set_damage(1)
    studio._toggle_scenario()
    assert(studio._scenario_enabled)
    assert(studio.battle_scenario.active)
    assert(studio.battle_scenario.ground.visible)
    assert(studio.battle_scenario.ground.mesh.get_surface_count()==1)
    assert(Models.inspect_meshes(studio.model_root)==initial_meshes)
    # Four terrestrial materials by three lighting periods, same tank,
    # camera, angle, four-color structure and lightly damaged condition.
    var grid := Image.create(1920,990,false,Image.FORMAT_RGBA8)
    var day_asphalt: Image
    var night_asphalt: Image
    var day_snow: Image
    var night_snow: Image
    var day_forest: Image
    var night_forest: Image
    var rendered := 0
    for period in range(3):
        for terrain in range(4):
            studio._on_scenario_terrain(terrain)
            studio._on_scenario_light(period)
            assert(studio._scenario_terrain==terrain)
            assert(studio._scenario_light==period)
            assert(studio.battle_scenario.terrain_index==terrain)
            assert(studio.battle_scenario.light_index==period)
            assert(studio.model_root.get_instance_id()==tank_id)
            assert(Models.inspect_meshes(studio.model_root)==initial_meshes)
            assert(Models.paintable_count(studio.model_root)==14)
            assert(Damage.current_stage(studio.model_root)==1)
            assert(is_equal_approx(studio._yaw,yaw))
            assert(is_equal_approx(studio._zoom,zoom))
            var view: Image = await _capture(studio)
            assert(_average(view)>0.035)
            grid.blit_rect(view,Rect2i(0,0,480,330),
                Vector2i(terrain*480,period*330))
            if period==0 and terrain==0:
                day_asphalt = view
            if period==2 and terrain==0:
                night_asphalt = view
            if period==0 and terrain==1:
                day_forest = view
            if period==2 and terrain==1:
                night_forest = view
            if period==0 and terrain==3:
                day_snow = view
            if period==2 and terrain==3:
                night_snow = view
            rendered += 1
    assert(rendered==12)
    assert(day_asphalt!=null and night_asphalt!=null)
    assert(day_snow!=null and night_snow!=null)
    assert(_pixel_delta(day_asphalt,day_forest)>90)
    assert(_pixel_delta(day_asphalt,day_snow)>90)
    assert(_pixel_delta(day_asphalt,night_asphalt)>90)
    assert(_pixel_delta(day_snow,night_snow)>90)
    assert(_average(day_asphalt)>_average(night_asphalt)+0.04)
    assert(_average(day_snow)>_average(night_snow)+0.04)
    assert(grid.save_png(
        "res://artifacts/tarvoka_g09_v26_12_lighting_terrain.png")==OK)
    _two(day_asphalt,night_asphalt,
        "tarvoka_g09_v25_day_vs_night.png")

    # True material A/B is judged under exactly the same terrain, time,
    # light, faction, camera and HP damage stage.
    studio._on_scenario_terrain(1)
    studio._on_scenario_light(2)
    var paint_v25: Image = await _capture(studio)
    studio._toggle_v25()
    assert(studio._v24_preview and not studio._v25_preview)
    assert(studio._scenario_enabled and studio._scenario_terrain==1)
    assert(studio._scenario_light==2 and studio._tactical_view)
    assert(Damage.current_stage(studio.model_root)==1)
    assert(Models.inspect_meshes(studio.model_root)==initial_meshes)
    var paint_v24: Image = await _capture(studio)
    _two(paint_v24,paint_v25,
        "tarvoka_g09_v24_v25_night_forest.png")
    studio._toggle_v25()
    assert(studio._v25_preview)
    assert(studio.model_root.get_meta("tarvoka_mbt_wear_v25",false))
    studio._set_damage(0)
    # All eight factions are rendered with EXACT matching nighttime
    # lighting and one terrain, checking color selection remains responsive.
    var night_grid := Image.create(1920,660,false,Image.FORMAT_RGBA8)
    for faction in range(8):
        studio._on_faction(faction)
        assert(Models.paintable_count(studio.model_root)==14)
        assert(studio.model_root.get_meta("tarvoka_mbt_wear_v25",false))
        var night_frame: Image = await _capture(studio)
        night_grid.blit_rect(night_frame,Rect2i(0,0,480,330),
            Vector2i((faction%4)*480,int(faction/4)*330))
    assert(night_grid.save_png(
        "res://artifacts/tarvoka_g09_v26_eight_factions_night.png")==OK)

    for stage in range(5):
        studio._set_damage(stage)
        assert(Damage.current_stage(studio.model_root)==stage)
    studio._set_damage(0)
    studio._toggle_scenario()
    assert(not studio._scenario_enabled and not studio.battle_scenario.active)
    assert(not studio.battle_scenario.ground.visible)
    assert(studio.battle_scenario.world.environment.background_color==
        Color("#14232D"))
    assert(is_equal_approx(studio.battle_scenario.key_light.light_energy,1.65))
    assert(Models.inspect_meshes(studio.model_root)==initial_meshes)
    studio.queue_free()
    print("PASS G09 V26: 12 real terrain/light combinations, day-night brightness, 8 faction night renders, 5 damage stages, V24/V25 AB, independent Android models; cases=%d" % rendered)
    quit(0)
