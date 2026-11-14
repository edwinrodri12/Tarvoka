extends SceneTree

# Real Godot geometry and GPU studio: no mock textures or source model edits.
const Weather = preload("res://scripts/ui/WeatherCoating3D.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _shapes(parent: Node, found: Array[MeshInstance3D]) -> void:
    for child in parent.get_children():
        if child is MeshInstance3D and not child.has_meta(Weather.COAT_TAG):
            found.append(child as MeshInstance3D)
        _shapes(child,found)

func _painted(model: Node3D) -> Array[MeshInstance3D]:
    var shapes: Array[MeshInstance3D] = []
    _shapes(model,shapes)
    var colors: Array[MeshInstance3D] = []
    for mesh in shapes:
        if mesh.has_meta("tarvoka_faction_panel") or \
                mesh.has_meta("tarvoka_paint_zone") or \
                mesh.name.begins_with("Faccion"):
            colors.append(mesh)
    return colors

func _assert_snow_protection(model: Node3D) -> void:
    for shape in _painted(model):
        assert(shape.find_child(Weather.SNOW_NODE,false,false) == null)
        assert(shape.material_override is StandardMaterial3D)

func _run() -> void:
    assert(Weather.MODES == ["clear","rain","snow"])
    assert(Weather.MAX_SNOW_NODES <= 18)
    var tank: Node3D = Models.build("tank",0,true,10)
    assert(tank != null)
    root.add_child(tank)
    var faction_panels: Array[MeshInstance3D] = _painted(tank)
    assert(faction_panels.size() >= 10)
    var original_color: Color = (faction_panels[0].material_override as StandardMaterial3D).albedo_color
    var original_material: Material = faction_panels[0].material_override
    var mesh_count: int = Models.inspect_meshes(tank)
    var wet: Dictionary = Weather.apply(tank,"rain")
    assert(wet["valid"] and wet["wet"] > 10)
    assert(int(wet["snow_nodes"]) == 0)
    assert(Models.inspect_meshes(tank) == mesh_count)
    var wet_color: Color = (faction_panels[0].material_override as StandardMaterial3D).albedo_color
    assert(wet_color.is_equal_approx(original_color))
    assert(faction_panels[0].material_override != original_material)
    assert((faction_panels[0].material_override as StandardMaterial3D).roughness <=
        (original_material as StandardMaterial3D).roughness)
    assert((original_material as StandardMaterial3D).albedo_color == original_color)
    # Switching mode is fully reversible and never rewrites authored textures.
    var dry: Dictionary = Weather.apply(tank,"clear")
    assert(dry["valid"])
    assert(faction_panels[0].material_override == original_material)
    assert(Models.inspect_meshes(tank) == mesh_count)
    var snowy: Dictionary = Weather.apply(tank,"snow")
    assert(snowy["valid"] and int(snowy["snow_nodes"]) > 0)
    assert(int(snowy["snow_nodes"]) <= Weather.MAX_SNOW_NODES)
    assert(int(snowy["snow_triangles"]) > 0 and
        int(snowy["snow_triangles"]) <= Weather.MAX_SNOW_TRIANGLES)
    _assert_snow_protection(tank)
    var repeated: Dictionary = Weather.apply(tank,"snow")
    assert(repeated["snow_nodes"] == snowy["snow_nodes"])
    assert(repeated["snow_triangles"] == snowy["snow_triangles"])
    # Local-space snow geometry follows its own articulated parent. The
    # overlay must never be a disconnected world-space scene root.
    for child in tank.find_children(Weather.SNOW_NODE,"MeshInstance3D",true,false):
        assert(child.get_parent() is MeshInstance3D)
        assert(child.transform == Transform3D.IDENTITY)
        assert(child.get_meta("visual_only",false))
    var eco: Dictionary = Weather.apply(tank,"snow",true)
    assert(int(eco["snow_nodes"]) <= Weather.MAX_ECO_SNOW_NODES)
    assert(int(eco["snow_triangles"]) <= Weather.MAX_ECO_SNOW_TRIANGLES)
    Weather.clear(tank)
    assert(Models.inspect_meshes(tank) == mesh_count)
    assert(tank.find_child(Weather.SNOW_NODE,true,false) == null)
    # Repaint into a second faction and verify no snow over painted elements.
    Models.apply_faction_palette(tank,5)
    assert(_painted(tank).size() == faction_panels.size())
    var repaint: Color = (faction_panels[0].material_override as StandardMaterial3D).albedo_color
    assert(not repaint.is_equal_approx(original_color))
    Weather.apply(tank,"rain")
    assert((faction_panels[0].material_override as StandardMaterial3D).albedo_color == repaint)
    Weather.clear(tank)
    assert((faction_panels[0].material_override as StandardMaterial3D).albedo_color == repaint)
    Weather.apply(tank,"snow")
    _assert_snow_protection(tank)
    tank.free()

    # ONE service across all eight unit roles; ground, air and naval are
    # visual modes only and never change movement or fuel.
    for role in Models.ROLES:
        var model: Node3D = Models.build(str(role),0,true,10)
        assert(model != null)
        root.add_child(model)
        var rain: Dictionary = Weather.apply(model,"rain",true)
        assert(rain["valid"] and int(rain["wet"]) > 0)
        var winter: Dictionary = Weather.apply(model,"snow",true)
        assert(winter["valid"] and int(winter["snow_nodes"]) <=
            Weather.MAX_ECO_SNOW_NODES)
        Weather.clear(model)
        model.free()

    # Headquarters levels/conditions and ALL 8 factions. Transparent glass
    # and faction panels must remain legible under snowfall.
    for level in [1,2,3]:
        for faction in range(8):
            var hq: Node3D = HQ.build(level,faction,"operativo",true,true)
            assert(hq != null)
            root.add_child(hq)
            var paint: Array[MeshInstance3D] = _painted(hq)
            assert(paint.size() > 0)
            var before: Color = (paint[0].material_override as StandardMaterial3D).albedo_color
            var frosted: Dictionary = Weather.apply(hq,"snow",false)
            assert(frosted["valid"] and int(frosted["snow_nodes"]) > 0)
            assert(int(frosted["snow_nodes"]) <= Weather.MAX_SNOW_NODES)
            _assert_snow_protection(hq)
            assert((paint[0].material_override as StandardMaterial3D).albedo_color == before)
            var wet_hq: Dictionary = Weather.apply(hq,"rain")
            assert(int(wet_hq["wet"]) > 0)
            assert((paint[0].material_override as StandardMaterial3D).albedo_color == before)
            Weather.clear(hq)
            assert((paint[0].material_override as StandardMaterial3D).albedo_color == before)
            assert(hq.find_child(Weather.SNOW_NODE,true,false) == null)
            hq.free()

    # Actual unified web studio including controller and same-camera A/B.
    root.content_scale_size = Vector2i(1366,860)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(scene != null)
    var studio: Control = scene.instantiate()
    root.add_child(studio)
    for _i in range(8):
        await process_frame
    assert(studio.model_weather_picker != null)
    assert(studio.model_weather_compare_button != null)
    assert(studio.model_weather_picker.item_count == 3)
    assert(studio._role == "tank")
    var initial_position: Vector3 = studio.camera.position
    studio.model_weather_picker.select(1)
    studio._change_model_weather(1)
    assert(studio.model_root.get_meta("weather_coating")["wet"] > 0)
    assert(studio.camera.position.is_equal_approx(initial_position))
    studio._compare_model_weather()
    assert(studio.model_weather_picker.selected == 0)
    assert(studio.model_root.get_meta("weather_coating")["mode"] == "clear")
    studio._compare_model_weather()
    assert(studio.model_weather_picker.selected == 1)
    studio.model_weather_picker.select(2)
    studio._change_model_weather(2)
    assert(studio.model_root.get_meta("weather_coating")["snow_nodes"] > 0)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    for _i in range(6):
        await process_frame
    assert(studio.preview.get_texture().get_image().save_png(
        "res://artifacts/tarvoka_universal_snow_g09.png") == OK)
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    assert(studio.model_root.get_meta("weather_coating")["mode"] == "snow")
    assert(studio.model_root.get_meta("weather_coating")["snow_nodes"] > 0)
    for _i in range(6):
        await process_frame
    assert(studio.preview.get_texture().get_image().save_png(
        "res://artifacts/tarvoka_universal_snow_hq.png") == OK)
    studio.model_weather_picker.select(1)
    studio._change_model_weather(1)
    assert(studio.model_root.get_meta("weather_coating")["wet"] > 0)
    for _i in range(6):
        await process_frame
    assert(studio.preview.get_texture().get_image().save_png(
        "res://artifacts/tarvoka_universal_wet_hq.png") == OK)
    studio._switch_category(0)
    assert(studio._role == "tank")
    assert(studio.model_root.get_meta("weather_coating")["mode"] == "rain")
    studio._on_faction(3)
    assert(studio._faction == 3)
    var current_tank: Node3D = studio.model_root
    assert(current_tank.get_meta("weather_coating")["mode"] == "rain")
    studio._switch_category(2)
    assert(studio._role == "terrain")
    assert(not studio.model_weather_picker.visible)
    assert(studio.terrain_weather_picker.item_count == 3)
    studio._switch_category(3)
    assert(studio._role == "battle")
    studio._switch_category(0)
    assert(studio._role == "tank")
    studio.queue_free()
    print("PASS UNIVERSAL_WEATHER_3D: native tank/HQ + 8 roles + 8 factions, reversible wet PBR, local animated snow, economy, real web studio GPU")
    quit(0)
