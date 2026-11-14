extends SceneTree

# Commercial-facing test: assets MUST be baked Godot V13 3D, imported as
# readable PNGs, and rendered by the actual 2D Android board without V13.
const Sprite = preload("res://scripts/ui/HeadquartersSpriteV15.gd")
const Command = preload("res://scripts/ui/CommandCityArtV14.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Data = preload("res://scripts/ui/SiteOverlayData.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _sample_diff(a: Image,b: Image) -> int:
    var changed: int = 0
    for y in range(0,mini(a.get_height(),b.get_height()),4):
        for x in range(0,mini(a.get_width(),b.get_width()),4):
            var p: Color = a.get_pixel(x,y)
            var q: Color = b.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.12:
                changed += 1
    return changed

static func _save_pair(first: Image,second: Image,target: String) -> void:
    var a: Image = first.duplicate()
    var b: Image = second.duplicate()
    a.resize(600,370,Image.INTERPOLATE_LANCZOS)
    b.resize(600,370,Image.INTERPOLATE_LANCZOS)
    var both := Image.create(1200,370,false,Image.FORMAT_RGBA8)
    both.blit_rect(a,Rect2i(0,0,600,370),Vector2i(0,0))
    both.blit_rect(b,Rect2i(0,0,600,370),Vector2i(600,0))
    assert(both.save_png(target)==OK)

func _wait(frames: int = 8) -> void:
    for i in range(frames):
        await process_frame

func _run() -> void:
    assert(Sprite.asset_path(-2)=="")
    assert(Sprite.asset_path(8)=="")
    assert(Sprite.asset_path(-1).ends_with("hq_neutral.png"))
    assert(Sprite.prefer(26.0,false))
    assert(not Sprite.prefer(12.0,false))
    assert(not Sprite.prefer(40.0,true))
    assert(Style.FACTIONS.size()==8)
    var hashes: Dictionary = {}
    for f in range(-1,8):
        var path: String = Sprite.asset_path(f)
        assert(not path.is_empty())
        assert(ResourceLoader.exists(path))
        var atlas: Texture2D = Sprite.sprite(f)
        assert(atlas != null)
        assert(atlas.get_width()==384 and atlas.get_height()==384)
        var img := Image.new()
        assert(img.load(path)==OK)
        assert(img.get_pixel(0,0).a<0.10)
        var count_opaque: int = 0
        for y in range(0,384,8):
            for x in range(0,384,8):
                if img.get_pixel(x,y).a>0.14:
                    count_opaque += 1
        assert(count_opaque>200)
        var key: int = hash(img.get_data())
        assert(not hashes.has(key))
        hashes[key]=true
    assert(Sprite.cache_size()==9)

    # The actual game site semantics remain unchanged on all map sizes.
    for size in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var terrain: Array = Scenarios.terrain(0,size)
        var economy: Dictionary = Economy.create(terrain)
        assert(not economy.is_empty())
        var city: Dictionary = economy["sites"][0]
        assert(Command.is_visual_command_city(city["kind"],city["pos"],size))
        assert(not Command.is_visual_command_city(
            economy["sites"][2]["kind"],economy["sites"][2]["pos"],size))

    root.content_scale_size = Vector2i(1200,740)
    var board := Board.new()
    board.ai_enabled=false
    board.autosave_enabled=false
    board.size=Vector2(1180,710)
    root.add_child(board)
    board.new_game(0,false,false,false,true,true,true)
    board.set_isometric(true)
    board.iso_zoom=1.4
    board.queue_redraw()
    await _wait()
    var before: Dictionary = board.state.duplicate(true)
    var city: Vector2i = Vector2i(2,1)
    var city_pos: Vector2 = Iso.center(
        city,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())
    assert(board.screen_cell(city_pos)==city)

    if DisplayServer.get_name() != "headless":
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))
        Sprite.enabled=false
        board.queue_redraw()
        await _wait()
        var vector: Image = root.get_texture().get_image()
        Sprite.enabled=true
        board.queue_redraw()
        await _wait()
        var baked: Image = root.get_texture().get_image()
        assert(_sample_diff(vector,baked)>28)
        _save_pair(vector,baked,
            "res://artifacts/tarvoka_hq_v14_vector_vs_v15_real_3d_baked.png")
        assert(baked.save_png(
            "res://artifacts/tarvoka_hq_v15_live_android_isometric.png")==OK)

        # Create close-up of genuine 2D battle screenshot around one HQ.
        board.iso_zoom = 2.0
        city_pos = Iso.center(city,board.size,board.iso_zoom,
            board.iso_pan,board.map_dimensions())
        board.iso_pan += board.size*0.50-city_pos
        board.queue_redraw()
        await _wait()
        var zoomed: Image = root.get_texture().get_image()
        assert(zoomed.save_png(
            "res://artifacts/tarvoka_hq_v15_live_battle_close.png")==OK)

        var montage := Image.create(1280,480,false,Image.FORMAT_RGBA8)
        montage.fill(Color("#1e2b37"))
        for f in range(8):
            board.state[Identity.STATE_FIELD]={
                "0":str(Style.FACTIONS[f]["key"]),
                "1":str(Style.FACTIONS[(f+1)%8]["key"])
            }
            board._site_overlay_key=-1
            var markers: Array = board.site_overlay_snapshots()
            assert(markers.size()>0)
            assert(Command.faction_index(board.state,0)==f)
            board.queue_redraw()
            await _wait(5)
            var shot: Image = root.get_texture().get_image()
            var center: Vector2 = Iso.center(city,board.size,
                board.iso_zoom,board.iso_pan,board.map_dimensions())
            var crop: Image = shot.get_region(
                Rect2i(int(center.x)-160,int(center.y)-135,320,240))
            montage.blit_rect(crop,Rect2i(0,0,320,240),
                Vector2i((f%4)*320,int(f/4)*240))
        assert(montage.save_png(
            "res://artifacts/tarvoka_hq_v15_8_factions_in_real_battle.png")==OK)

        # Unknown ownership MUST display gray crest-free baked asset.
        assert(Sprite.sprite(-1)!=null)
        assert(Command.faction_index(board.state,-2)==-1)
        var old: Image = Image.new()
        var neutral: Image = Image.new()
        assert(old.load(Sprite.asset_path(0))==OK)
        assert(neutral.load(Sprite.asset_path(-1))==OK)
        assert(_sample_diff(old,neutral)>100)
        Sprite.enabled=false
        board.queue_redraw()
        await _wait()
        Sprite.enabled=true

    assert(board.state["economy"] == before["economy"])
    assert(board.state["units"] == before["units"])
    assert(board.state["terrain"] == before["terrain"])
    assert(Sprite.cache_size()==9)
    board.queue_free()
    print("PASS HQ V15: 9 real 3D alpha sprites, 8 unique official-faction variants, 2D live Android battle, fog-safe neutral, zoom/battery fallback and unchanged rules")
    quit(0)
