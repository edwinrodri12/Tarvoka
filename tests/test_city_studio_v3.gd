extends SceneTree

# Executed within the existing V11 unified Studio export assembled by Pages.
# Verifies the REAL shared scene uses the additive civilian-city adapter,
# preserving all older buildings, tank and other unit inspection menus.
const City=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const V3=preload("res://scripts/ui/CivilianCityPublicSpaceV3.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=9) -> void:
    for i in range(n):
        await process_frame

func _run() -> void:
    root.content_scale_size=Vector2i(1180,780)
    var packed: PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    assert(packed!=null)
    var studio=packed.instantiate()
    root.add_child(studio)
    await _frames(12)
    var picker: OptionButton=studio.building_picker
    assert(picker!=null and picker.item_count>=5)
    assert(picker.get_item_text(4).contains("Ciudad Civil"))
    # Use the SAME main studio building selector, not a second city app.
    picker.select(4)
    picker.item_selected.emit(4)
    await _frames()
    assert(studio._role=="civilian_city")
    assert(studio.city_controls.visible)
    assert(studio.model_root!=null)
    assert(studio.model_root.has_node(City.STAGE_NAME))
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(studio.city_v2_toggle.button_pressed)
    assert(studio.city_v3_toggle.button_pressed)
    assert(City.count_meshes(studio.model_root)>30)
    assert(int(studio.model_root.get_meta("visual_level",-1))==1)
    assert(int(studio.model_root.get_meta("visual_faction",-2))==0)
    # All three architectural variants and all eight faction colors
    # share the same camera, official picker, and real Godot mesh model.
    for level in [0,1,2]:
        studio.city_level_picker.select(level)
        studio.city_level_picker.item_selected.emit(level)
        await _frames(4)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level+1)
        assert(studio.detail_label.text.contains("Ciudad Civil V3"))
    studio.city_faction_picker.select(0)
    studio.city_faction_picker.item_selected.emit(0)
    assert(int(studio.model_root.get_meta("visual_faction",-2))==-1)
    studio.city_faction_picker.select(8)
    studio.city_faction_picker.item_selected.emit(8)
    assert(int(studio.model_root.get_meta("visual_faction",-2))==7)
    # Compare the V2 public space with the V3 sculpt in the same viewport.
    studio.city_v3_toggle.set_pressed_no_signal(false)
    studio._toggle_city_v3(false)
    await _frames(4)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    assert(not studio.model_root.has_node(V3.STAGE_NAME))
    assert(studio.detail_label.text.contains("Ciudad Civil V2"))
    studio.city_v3_toggle.set_pressed_no_signal(true)
    studio._toggle_city_v3(true)
    await _frames(4)
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    # The same inspector must correctly remove and restore only V2 meshes.
    studio.city_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_city_v2(false)
    await _frames(4)
    assert(studio.model_root.has_node(City.STAGE_NAME))
    assert(not studio.model_root.has_node(V2.STAGE_NAME))
    assert(not studio.model_root.has_node(V3.STAGE_NAME))
    assert(studio.city_v3_toggle.disabled)
    assert(studio.detail_label.text.contains("Ciudad Civil V1"))
    studio.city_v2_toggle.set_pressed_no_signal(true)
    studio._toggle_city_v2(true)
    await _frames(4)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(not studio.city_v3_toggle.disabled)
    studio.city_damage_picker.select(3)
    studio.city_damage_picker.item_selected.emit(3)
    assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==3)
    # Old categories remain browsable and return to the SAME viewport.
    for category in [3,2,1,0]:
        picker.select(category)
        picker.item_selected.emit(category)
        await _frames(4)
        assert(studio._role!="civilian_city")
        assert(not studio.city_controls.visible)
    picker.select(4)
    picker.item_selected.emit(4)
    assert(studio._role=="civilian_city")
    assert(studio.model_root.has_node(City.STAGE_NAME))
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    if DisplayServer.get_name()!="headless":
        await _frames(16)
        var img: Image=studio.preview.get_texture().get_image()
        assert(img!=null and not img.is_empty())
        var samples: Dictionary={}
        for y in range(0,img.get_height(),maxi(1,img.get_height()/14)):
            for x in range(0,img.get_width(),maxi(1,img.get_width()/20)):
                samples[img.get_pixel(x,y).to_html()]=true
        assert(samples.size()>7)
        assert(DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))==OK)
        assert(img.save_png(
            "res://artifacts/tarvoka_city_v3_shared_studio.png")==OK)
    studio.queue_free()
    await _frames(2)
    print("PASS TARVOKA CITY V3 SHARED STUDIO: fifth building, tiers, eight factions, neutral, damage, preserved four existing building categories")
    quit(0)
