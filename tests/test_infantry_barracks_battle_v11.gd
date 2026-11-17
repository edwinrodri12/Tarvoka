extends SceneTree

# Acceptance: the approved V11 model is now rendered inside TARVOKA's real
# battle terrain, 2D board, and 3D inspection modal. No fake preview scenes.
const Barracks=preload("res://scripts/ui/InfantryBarracksBattle3D.gd")
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const Terrain=preload("res://scripts/ui/BattleTerrain3D.gd")
const Economy=preload("res://scripts/core/UrbanEconomy.gd")
const Session=preload("res://scripts/core/BattleSession.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Identity=preload("res://scripts/ui/FactionIdentity.gd")
const VisualStyle=preload("res://scripts/ui/VisualStyle.gd")
const Markers=preload("res://scripts/ui/SiteOverlayData.gd")
const Painter=preload("res://scripts/ui/SiteOverlayPainter.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

static func _find_marked(model: Node3D,cell: Vector2i) -> Node3D:
    return model.find_child("Instalacion3D_factory_%d_%d" % [
        cell.x,cell.y],true,false) as Node3D

func _real_3d_battles() -> void:
    var terrain: Array=Scenarios.terrain(0)
    var state: Dictionary=Session.start(
        Roles.experimental_armies(),terrain,0,false,false,true)
    assert(not state.is_empty())
    var baseline: Dictionary=state.duplicate(true)
    var allied:=Vector2i(0,3)
    var rival:=Vector2i(9,3)
    var original_economy: Dictionary=state["economy"].duplicate(true)
    assert(Economy.site_at(state["economy"],allied)["kind"]=="factory")
    assert(Economy.site_at(state["economy"],rival)["kind"]=="factory")
    var battle: Node3D=Terrain.build(state,"")
    assert(battle!=null)
    for cell in [allied,rival]:
        var model: Node3D=_find_marked(battle,cell)
        assert(model!=null)
        assert(model.get_meta("kind")=="factory")
        assert(model.get_meta("approved_art_version")==Barracks.ART_VERSION)
        assert(model.get_meta("visual_tier")==1)
        assert(model.get_meta("game_visual_only"))
        assert(model.has_node("InfanteriaV11ViserasProtectorasVentanas"))
        assert(int(model.get_meta("actual_3d_meshes",0))>70)
        assert(model.scale.is_equal_approx(Vector3.ONE*Barracks.CELL_MODEL_SCALE))
    assert(_find_marked(battle,allied).get_meta("owner_public")==0)
    assert(_find_marked(battle,rival).get_meta("owner_public")==1)
    assert(int(battle.get_meta("render_stats")["sites"])>=6)
    battle.free()
    assert(state==baseline)
    assert(state["economy"]==original_economy)

    # Explicit visual tiers are supported on pre-placed sites; they NEVER
    # change factory production slots, capture, credits, or turn timing.
    for tier in [2,3]:
        var modified: Dictionary=baseline.duplicate(true)
        Economy.site_at(modified["economy"],allied)["visual_level"]=tier
        var stable: Dictionary=modified.duplicate(true)
        var scene: Node3D=Terrain.build(modified,"")
        var inspected: Node3D=_find_marked(scene,allied)
        assert(inspected!=null)
        assert(inspected.get_meta("visual_tier")==tier)
        assert(int(inspected.get_meta("actual_3d_meshes",0))>70)
        assert(inspected.get_meta("approved_art_version")==11)
        assert(modified==stable)
        scene.free()

    # Palette reads eight official visual identities, even though game
    # mechanics still have exactly two sides.
    for faction in range(8):
        var colored: Dictionary=baseline.duplicate(true)
        var keys: Dictionary=colored.get(Identity.STATE_FIELD,{})
        keys=Identity.resolved(keys)
        keys["0"]=str(VisualStyle.FACTIONS[faction]["key"])
        keys["1"]=str(VisualStyle.FACTIONS[(faction+1)%8]["key"])
        colored[Identity.STATE_FIELD]=keys
        var model: Node3D=Barracks.build_site(colored,Economy.site_at(
            colored["economy"],allied),0)
        assert(model!=null)
        assert(int(model.get_meta("visual_faction",-1))==faction)
        assert(model.get_meta("approved_art_version")==11)
        model.free()
    assert(state==baseline)

    # Fog: an UNDISCOVERED enemy building is not created. An explored,
    # unobserved enemy facility is neutral-colored and has unknown owner.
    var fog: Dictionary=Session.start([
        Roles.make_unit("AL",0,Vector2i(1,2),"line"),
        Roles.make_unit("EN",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true)
    var unseen: Node3D=Terrain.build(fog,"",0)
    assert(unseen!=null)
    assert(_find_marked(unseen,rival)==null)
    unseen.free()
    fog["explored"]["0"].append(rival)
    var remembered: Node3D=Terrain.build(fog,"",0)
    assert(remembered!=null)
    var unknown: Node3D=_find_marked(remembered,rival)
    assert(unknown!=null)
    assert(unknown.get_meta("owner_public")==-1)
    assert(unknown.get_meta("visual_faction")==Barracks.NEUTRAL_FACTION_ART)
    remembered.free()

    # Both 2D projections carry the approved barracks flag; ownership
    # signaling and fog/public marker structure remain unchanged.
    var snapshots: Array=Markers.snapshots(baseline)
    var count: int=0
    for marker in snapshots:
        if marker.get("kind")=="factory":
            assert(bool(marker.get("visual_infantry_barracks",false)))
            assert(marker.get("visual_level")==1)
            count+=1
    assert(count==2)
    assert(Painter.status_symbol({"status":"ready"})=="+")
    assert(Economy.site_at(baseline["economy"],allied)["kind"]=="factory")

func _run() -> void:
    root.content_scale_size=Vector2i(1280,720)
    _real_3d_battles()

    # MAIN SCENE TEST: real HUD and the established 3D battle toggle.
    var main: Control=load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await _frames(12)
    var board: Control=main.board
    board.ai_enabled=false
    board.autosave_enabled=false
    board.new_game(0,false,false,false,true,true)
    var before: Dictionary=board.state.duplicate(true)
    # Hide the intro overlay before opening the battle: otherwise a
    # successful GUI test can still produce a flat, never-drawn viewport.
    main._continue_from_home()
    await _frames(8)
    main._open_battle_3d()
    var view=main.battle_3d_view
    await _frames(13)
    assert(view!=null and view.visible)
    assert(view._live_board==board)
    assert(_find_marked(view._scene,Vector2i(0,3))!=null)
    assert(_find_marked(view._scene,Vector2i(9,3))!=null)
    assert(view.tap_battle_cell(Vector2i(0,3)))
    assert(view.building_info_panel.visible)
    assert(view.building_info_panel.production_button.visible)
    assert(board.state==before)
    if DisplayServer.get_name()!="headless":
        var image: Image=view.preview.get_texture().get_image()
        assert(image!=null and not image.is_empty())
        var palette: Dictionary={}
        for py in range(0,image.get_height(),maxi(1,int(image.get_height()/18))):
            for px in range(0,image.get_width(),maxi(1,int(image.get_width()/24))):
                palette[image.get_pixel(px,py).to_html()]=true
        # A uniform clear-color image is NOT evidence of a rendered battle.
        assert(palette.size()>6)
        assert(DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path("res://artifacts"))==OK)
        assert(image.save_png(
            "res://artifacts/tarvoka_infantry_v11_in_game_battle.png")==OK)
    view.close_view()
    main.queue_free()
    await _frames(2)
    print("PASS INFANTRY V11 IN REAL GAME: actual 3D battle, 2D site markers, 3 levels, 8 faction palettes, captured production menu, fog safety, no gameplay mutation")
    quit(0)
