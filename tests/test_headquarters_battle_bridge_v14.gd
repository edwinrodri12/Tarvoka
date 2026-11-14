extends SceneTree

# Actual 2D battlefield integration: from the V13 3D silhouette vocabulary
# to the two canonical city landmark silhouettes, with NO changed mechanics.
const Command = preload("res://scripts/ui/CommandCityArtV14.gd")
const Data = preload("res://scripts/ui/SiteOverlayData.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Identity = preload("res://scripts/ui/FactionIdentity.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _at(markers: Array,position: Vector2i) -> Dictionary:
    for marker in markers:
        if marker is Dictionary and marker.get("pos")==position:
            return marker
    return {}

static func _pixels_changed(first: Image,second: Image) -> int:
    var a: Image = first.duplicate()
    var b: Image = second.duplicate()
    a.resize(560,350,Image.INTERPOLATE_LANCZOS)
    b.resize(560,350,Image.INTERPOLATE_LANCZOS)
    var diff: int = 0
    for y in range(0,350,3):
        for x in range(0,560,3):
            var c: Color = a.get_pixel(x,y)
            var d: Color = b.get_pixel(x,y)
            if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b) > 0.12:
                diff += 1
    return diff

static func _pair(left: Image,right: Image) -> void:
    var a: Image = left.duplicate()
    var b: Image = right.duplicate()
    a.resize(600,370,Image.INTERPOLATE_LANCZOS)
    b.resize(600,370,Image.INTERPOLATE_LANCZOS)
    var sheet := Image.create(1200,370,false,Image.FORMAT_RGBA8)
    sheet.blit_rect(a,Rect2i(0,0,600,370),Vector2i.ZERO)
    sheet.blit_rect(b,Rect2i(0,0,600,370),Vector2i(600,0))
    assert(sheet.save_png(
        "res://artifacts/tarvoka_hq_v14_battle_original_city_vs_command_city.png")==OK)

func _frames(n: int = 6) -> void:
    for i in range(n):
        await process_frame

func _run() -> void:
    var dims := Vector2i(10,8)
    assert(Command.is_visual_command_city("city",Vector2i(2,1),dims))
    assert(Command.is_visual_command_city("city",Vector2i(7,1),dims))
    assert(not Command.is_visual_command_city("city",Vector2i(3,4),dims))
    assert(not Command.is_visual_command_city("factory",Vector2i(2,1),dims))
    assert(not Command.is_visual_command_city("city",Vector2i(7,2),dims))
    assert(not Command.is_visual_command_city("city",Vector2i(2,1),Vector2i.ZERO))
    for large in [Vector2i(24,18),Vector2i(40,30)]:
        var original: Array = Economy.create(Scenarios.terrain(0,large))["sites"]
        assert(original[0]["pos"]!=Vector2i(2,1))
        assert(Command.is_visual_command_city(
            "city",original[0]["pos"],large))
        assert(Command.is_visual_command_city(
            "city",original[1]["pos"],large))
        assert(not Command.is_visual_command_city(
            "city",original[2]["pos"],large))
    var terrain: Array = Scenarios.terrain(0)
    var state: Dictionary = Session.start(Roles.experimental_armies(),
        terrain,0,false,false,true)
    var saved: Dictionary = state.duplicate(true)
    var markers: Array = Data.snapshots(state)
    assert(markers.size()==state["economy"]["sites"].size())
    var left: Dictionary = _at(markers,Vector2i(2,1))
    var right: Dictionary = _at(markers,Vector2i(7,1))
    assert(left["kind"]=="city" and right["kind"]=="city")
    assert(left["visual_command_city"] and right["visual_command_city"])
    assert(left["owner"]==0 and right["owner"]==1)
    assert(not _at(markers,Vector2i(3,4))["visual_command_city"])
    assert(not _at(markers,Vector2i(0,3))["visual_command_city"])
    assert(state==saved)
    assert(Economy.income_for(state["economy"],0)==Economy.CITY_INCOME)
    assert(Economy.income_for(state["economy"],1)==Economy.CITY_INCOME)
    for f in range(8):
        var changed: Dictionary = state.duplicate(true)
        changed[Identity.STATE_FIELD] = {
            "0":str(Style.FACTIONS[f]["key"]),
            "1":str(Style.FACTIONS[(f+1)%8]["key"])
        }
        assert(Identity.is_valid(changed[Identity.STATE_FIELD]))
        assert(Command.faction_index(changed,0)==f)
        assert(Command.faction_index(changed,1)==(f+1)%8)
        assert(Style.emblem_texture(f)!=null)
    assert(Command.faction_index(state,-1)==-1)
    assert(Command.faction_index(state,-2)==-1)
    assert(Command.faction_index(state,3)==-1)

    # A captured original city retains its building silhouette but takes
    # the CURRENT owner's approved crest, not a hidden initial-owner hint.
    var captured: Dictionary = state.duplicate(true)
    var command_site: Dictionary = Economy.site_at(captured["economy"],Vector2i(2,1))
    command_site["owner"]=1
    var captured_view: Dictionary = _at(Data.snapshots(captured),Vector2i(2,1))
    assert(captured_view["visual_command_city"] and captured_view["owner"]==1)
    assert(Command.faction_index(captured,int(captured_view["owner"]))==1)
    assert(Economy.income_for(captured["economy"],1)==Economy.CITY_INCOME*2)
    assert(state==saved)

    # No military intelligence leak when exploring a rival city without
    # sight: the marker remains neutral and its crest is deliberately absent.
    var fogged: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true)
    var rival_pos := Vector2i(7,1)
    assert(_at(Data.snapshots(fogged),rival_pos).is_empty())
    fogged["explored"]["0"].append(rival_pos)
    var remembered: Dictionary = _at(Data.snapshots(fogged),rival_pos)
    assert(remembered["visual_command_city"])
    assert(remembered["owner"]==-2 and not remembered["owner_known"])
    assert(Command.faction_index(fogged,int(remembered["owner"]))==-1)
    var flipped: Dictionary = fogged.duplicate(true)
    Economy.site_at(flipped["economy"],rival_pos)["owner"]=-1
    assert(_at(Data.snapshots(flipped),rival_pos)==remembered)

    # Run the actual TouchBoard classic AND isometric canvas pipelines.
    var board := Board.new()
    board.ai_enabled=false
    board.autosave_enabled=false
    board.size=Vector2(1180,710)
    root.content_scale_size = Vector2i(1200,740)
    root.add_child(board)
    board.new_game(0,false,false,false,true,true,true)
    board.set_isometric(true)
    await _frames()
    var current: Dictionary = board.state.duplicate(true)
    var actual_markers: Array = board.site_overlay_snapshots()
    assert(_at(actual_markers,Vector2i(2,1))["visual_command_city"])
    assert(_at(actual_markers,Vector2i(7,1))["visual_command_city"])
    var north: Vector2 = Iso.center(
        Vector2i(2,1),board.size,board.iso_zoom,board.iso_pan,dims)
    assert(board.screen_cell(north)==Vector2i(2,1))
    board.queue_redraw()
    await _frames()
    assert(board.state==current)

    if DisplayServer.get_name() != "headless":
        DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))
        # The same authoritative state is rendered once with the former
        # city geometry, then with the approved HQ-inspired V14 skin.
        for marker in actual_markers:
            marker["visual_command_city"]=false
        board.queue_redraw()
        await _frames(9)
        var old: Image = root.get_texture().get_image()
        for marker in actual_markers:
            if str(marker.get("kind",""))=="city":
                marker["visual_command_city"]=Command.is_visual_command_city(
                    "city",marker["pos"],dims)
        board.queue_redraw()
        await _frames(9)
        var new: Image = root.get_texture().get_image()
        assert(old != null and new != null)
        assert(_pixels_changed(old,new)>35)
        _pair(old,new)
        assert(new.save_png(
            "res://artifacts/tarvoka_hq_v14_real_isometric_battle.png")==OK)

        var sheet := Image.create(1280,480,false,Image.FORMAT_RGBA8)
        for f in range(8):
            board.state[Identity.STATE_FIELD]={
                "0":str(Style.FACTIONS[f]["key"]),
                "1":str(Style.FACTIONS[(f+1)%8]["key"])
            }
            board._site_overlay_key=-1
            board.site_overlay_snapshots()
            board.queue_redraw()
            await _frames(5)
            var img: Image = root.get_texture().get_image()
            img.resize(320,240,Image.INTERPOLATE_LANCZOS)
            sheet.blit_rect(img,Rect2i(0,0,320,240),
                Vector2i((f%4)*320,int(f/4)*240))
        assert(sheet.save_png(
            "res://artifacts/tarvoka_hq_v14_eight_factions_live_battle.png")==OK)

    board.set_isometric(false)
    board.queue_redraw()
    await process_frame
    assert(board.screen_cell(Vector2(1,1))!=Vector2i(2,1))
    board.queue_free()
    print("PASS HQ V14: authentic 2D battle board, 2 command-city cosmetics, 8 official crests, ownership/fog guards, 10x8/24x18/40x30 anchors and unchanged economy/capture")
    quit(0)
