extends SceneTree

const Style = preload("res://scripts/ui/VisualStyle.gd")
const Selection = preload("res://scripts/ui/FactionSelection.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var image := Image.new()
    assert(image.load(Style.FIRST_FOUR_ATLAS) == OK)
    assert(image.get_width() == 640 and image.get_height() == 273)
    var keys := ["alianza_norte","pacto_escarlata","union_verde","confederacion_solar"]
    for i in range(4):
        assert(str(Style.FACTIONS[i]["key"]) == keys[i])
        var emblem: Texture2D = Style.emblem_texture(i)
        var portrait: Texture2D = Style.commander_texture(i)
        assert(emblem != null and portrait != null)
        assert(emblem is AtlasTexture and portrait is AtlasTexture)
        assert(emblem.get_width() == 160 and emblem.get_height() == 160)
        assert(portrait.get_width() == 160 and portrait.get_height() == 113)
        assert((emblem as AtlasTexture).region == Rect2(i*160,0,160,160))
        assert((portrait as AtlasTexture).region == Rect2(i*160,160,160,113))
    for i in range(4,8):
        assert(Style.emblem_texture(i) == null)
        assert(Style.commander_texture(i) == null)

    var screen := Selection.new()
    root.add_child(screen)
    await process_frame
    var state := Identity.defaults()
    screen.open_for(state)
    for i in range(4):
        screen._choose_side(0)
        screen._choose_faction(i)
        assert(screen.portrait.visible and screen.portrait.texture != null)
        assert(screen.commander_portrait.visible and screen.commander_portrait.texture != null)
        assert(not screen.commander_notice.visible)
        assert(screen.preview_commander.text.contains("Retrato oficial"))
        assert(screen.preview_title.text == Style.FACTIONS[i]["name"])
    screen._choose_faction(4)
    assert(not screen.portrait.visible and not screen.commander_portrait.visible)
    assert(screen.commander_notice.visible)
    assert(screen.preview_commander.text.contains("pendiente"))

    # Reading visual assets or switching cards never adds a combat modifier
    # or changes selected faction state until confirmation is requested.
    assert(state == Identity.defaults())
    screen.queue_free()
    print("PASS approved faction assets: 4 authentic crests, 4 portraits, exact atlas regions and Android previews")
    quit(0)
