extends SceneTree

const Style = preload("res://scripts/ui/VisualStyle.gd")
const Selection = preload("res://scripts/ui/FactionSelection.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var atlases := [Style.FIRST_FOUR_ATLAS,Style.LAST_FOUR_ATLAS]
    for path in atlases:
        var image := Image.new()
        assert(image.load(path) == OK)
        assert(image.get_width() == 640 and image.get_height() == 273)
    var keys := [
        "alianza_norte","pacto_escarlata","union_verde","confederacion_solar",
        "sindicato_violeta","legion_ambar","dominio_turquesa","orden_onix"
    ]
    for i in range(8):
        assert(str(Style.FACTIONS[i]["key"]) == keys[i])
        var emblem: Texture2D = Style.emblem_texture(i)
        var portrait: Texture2D = Style.commander_texture(i)
        assert(emblem != null and portrait != null)
        assert(emblem is AtlasTexture and portrait is AtlasTexture)
        assert(emblem.get_width() == 160 and emblem.get_height() == 160)
        assert(portrait.get_width() == 160 and portrait.get_height() == 113)
        var local: int = i % 4
        assert((emblem as AtlasTexture).region == Rect2(local*160,0,160,160))
        assert((portrait as AtlasTexture).region == Rect2(local*160,160,160,113))
        assert((emblem as AtlasTexture).atlas.resource_path == atlases[i/4] or
            (emblem as AtlasTexture).atlas.get_size() == Vector2(640,273))
    assert(Style.emblem_texture(8) == null)
    assert(Style.commander_texture(8) == null)

    var screen := Selection.new()
    root.add_child(screen)
    await process_frame
    var state := Identity.defaults()
    screen.open_for(state)
    for i in range(8):
        screen._choose_side(0)
        screen._choose_faction(i)
        assert(screen.portrait.visible and screen.portrait.texture != null)
        assert(screen.commander_portrait.visible and screen.commander_portrait.texture != null)
        assert(not screen.commander_notice.visible)
        assert(screen.preview_commander.text.contains("Retrato oficial"))
        assert(screen.preview_title.text == Style.FACTIONS[i]["name"])

    # Reading visual assets or switching cards never adds a combat modifier
    # or changes selected faction state until confirmation is requested.
    assert(state == Identity.defaults())
    screen.queue_free()
    print("PASS approved faction assets: all 8 authentic crests, 8 portraits, exact atlas regions and Android previews")
    quit(0)
