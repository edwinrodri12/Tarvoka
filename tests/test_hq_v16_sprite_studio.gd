extends SceneTree

# Native Godot GPU QA for the PUBLIC browser studio's new 3D / V15 Android
# sprite comparison. Capture the full UI: reviewer can see real controls,
# approved eight factions, neutral fog and zoom, not an imagined mockup.
const Studio = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Sprites = preload("res://scripts/ui/HeadquartersSpriteStudioV16.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const HQ = preload("res://scripts/ui/HeadquartersProductionV13.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int = 9) -> void:
    for i in range(count):
        await process_frame

func _shot(file: String) -> Image:
    var image: Image = root.get_texture().get_image()
    assert(image != null and not image.is_empty())
    assert(image.get_width() >= 900 and image.get_height() >= 540)
    assert(image.save_png("res://artifacts/"+file)==OK)
    return image

func _diff(a: Image,b: Image) -> int:
    var x: Image = a.duplicate()
    var y: Image = b.duplicate()
    x.resize(440,280,Image.INTERPOLATE_LANCZOS)
    y.resize(440,280,Image.INTERPOLATE_LANCZOS)
    var count: int = 0
    for py in range(0,280,4):
        for px in range(0,440,4):
            var c: Color = x.get_pixel(px,py)
            var d: Color = y.get_pixel(px,py)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.16:
                count+=1
    return count

func _run() -> void:
    assert(Sprites.NAMES.size()==8)
    assert(Sprites.path_for(-2).is_empty())
    assert(Sprites.path_for(8).is_empty())
    assert(Sprites.path_for(-1).ends_with("hq_neutral.png"))
    assert(Sprites.available())
    assert(Sprites.cache_size()==9)
    assert(Sprites.ZOOM_PIXELS.size()==3)
    assert(HQ.QUALITY_TACTICAL=="tactical")
    for faction in range(8):
        var texture: Texture2D = Sprites.texture_for(faction)
        assert(texture != null and texture.get_size()==Vector2(384,384))
    var neutral: Texture2D = Sprites.texture_for(-1)
    assert(neutral != null and neutral.get_size()==Vector2(384,384))
    assert(neutral != Sprites.texture_for(0))

    root.content_scale_size = Vector2i(1200,740)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    assert(studio != null and studio.has_method("_switch_category"))
    root.add_child(studio)
    await _frames()
    studio._switch_category(1)
    await _frames()
    assert(studio.category_picker.selected==1)
    assert(studio.hq_v15_mode_picker != null)
    assert(studio.hq_v15_mode_picker.item_count==3)
    assert(studio.hq_v15_neutral_toggle != null)
    assert(studio.hq_v15_zoom_picker.item_count==3)
    assert(studio.hq_v15_frame != null)
    assert(studio.hq_v15_caption != null)
    assert(studio.hq_v15_frame.visible)
    assert(studio.hq_v15_thumbnail.texture==Sprites.texture_for(0))
    assert(studio.hq_v15_thumbnail.custom_minimum_size==Vector2(220,220))
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    var initial: Image = _shot("tarvoka_hq_v16_3d_and_android_v15_same_screen.png")

    var thumbs: Array[Texture2D] = []
    assert(studio.faction_view_buttons.size()==8)
    for f in range(8):
        studio._select_faction_view(f)
        assert(studio._faction==f)
        assert(studio.faction_picker.selected==f)
        assert(studio.faction_view_buttons[f].button_pressed)
        assert(studio.hq_v15_thumbnail.texture==Sprites.texture_for(f))
        assert(studio.hq_v15_caption.text.contains(str(Style.FACTIONS[f]["name"])))
        assert(studio.model_root.get_meta("visual_faction",-1)==f)
        thumbs.append(studio.hq_v15_thumbnail.texture)
    for a in range(8):
        for b in range(a+1,8):
            assert(thumbs[a]!=thumbs[b])
    studio._select_faction_view(0)

    studio.hq_v15_neutral_toggle.set_pressed_no_signal(true)
    studio._change_hq_v15_neutral(true)
    assert(studio.hq_v15_thumbnail.texture==Sprites.texture_for(-1))
    assert(studio.hq_v15_caption.text.contains("sin insignia"))
    studio._change_hq_v15_mode(2)
    await _frames()
    assert(studio.model_root.get_meta("tarvoka_hq_v15_sprite_card",false))
    assert(studio.model_root.get_meta("tarvoka_hq_sprite_faction",0)==false)
    assert(int(studio.model_root.get_meta("tarvoka_hq_sprite_faction",-2))==-1)
    var card: Sprite3D = studio.model_root.find_child(
        "Sprite3DOriginalAndroid384",true,false) as Sprite3D
    assert(card != null and card.texture==Sprites.texture_for(-1))
    assert(card.billboard==BaseMaterial3D.BILLBOARD_ENABLED)
    assert(studio.detail_label.text.contains("384"))
    _shot("tarvoka_hq_v16_neutral_sprite_in_3d_scene.png")

    studio.hq_v15_neutral_toggle.set_pressed_no_signal(false)
    studio._change_hq_v15_neutral(false)
    assert(studio.model_root.get_meta("tarvoka_hq_v15_sprite_card",false))
    card = studio.model_root.find_child(
        "Sprite3DOriginalAndroid384",true,false) as Sprite3D
    assert(card != null and card.texture==Sprites.texture_for(0))
    await _frames()
    var billboard: Image = _shot("tarvoka_hq_v16_android_sprite_inside_3d_studio.png")
    assert(_diff(initial,billboard)>120)

    studio._change_hq_v15_mode(0)
    await _frames()
    assert(studio.model_root.get_meta("tarvoka_hq_visual_v12",false))
    assert(studio.hq_v15_frame.visible)
    studio._change_hq_v15_zoom(1)
    assert(studio.hq_v15_thumbnail.custom_minimum_size==Vector2(148,148))
    studio._change_hq_v15_zoom(2)
    assert(studio.hq_v15_thumbnail.custom_minimum_size==Vector2(85,85))
    assert(studio.hq_v15_caption.text.contains("V14"))
    _shot("tarvoka_hq_v16_zoom_distant_fallback_comparison.png")
    studio._change_hq_v15_zoom(0)

    studio.hq_production_toggle.set_pressed_no_signal(true)
    studio._change_hq_production_v13(true)
    await _frames()
    assert(studio.model_root.get_meta("tarvoka_hq_production_v13",false))
    assert(studio.hq_v15_thumbnail.texture==Sprites.texture_for(0))
    assert(studio.hq_production_metric_label.visible)
    _shot("tarvoka_hq_v16_v13_optimized_and_v15_android.png")

    studio._change_hq_v15_mode(1)
    assert(not studio.hq_v15_frame.visible)
    assert(studio.model_root.get_meta("tarvoka_hq_production_v13",false))
    studio._change_hq_v15_mode(0)
    assert(studio.hq_v15_frame.visible)
    studio._switch_category(0)
    assert(studio._role=="tank")
    assert(studio.faction_view_grid.visible)
    studio._switch_category(1)
    assert(studio.hq_v15_thumbnail.texture==Sprites.texture_for(0))
    studio.queue_free()
    print("PASS HQ V16 studio: full approved V15 PNG family in native 3D viewer, eight faction sync, neutral fog, true V13 and V12 comparison, 3 tactical zooms, billboard transparency and tank preservation")
    quit(0)
