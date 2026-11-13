extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const SiteData = preload("res://scripts/ui/SiteOverlayData.gd")
const SitePaint = preload("res://scripts/ui/SiteOverlayPainter.gd")
const Dossier = preload("res://scripts/ui/UnitDossierData.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _at(markers: Array, position: Vector2i) -> Dictionary:
    for marker in markers:
        if marker is Dictionary and marker.get("pos") == position:
            return marker
    return {}

func _run() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var state: Dictionary = Session.start(Roles.experimental_armies(),terrain,0,false,false,true)
    var original: Dictionary = state.duplicate(true)
    var factory := Vector2i(0,3)
    var city := Vector2i(3,4)
    var rival_city := Vector2i(7,1)
    var sites: Array = SiteData.snapshots(state)
    assert(sites.size() == state["economy"]["sites"].size())
    assert(_at(sites,factory)["status"] == "ready")
    assert(_at(sites,factory)["owner"] == 0)
    assert(SitePaint.status_symbol(_at(sites,factory)) == "+")
    assert(_at(sites,city)["kind"] == "city")
    assert(int(_at(sites,city)["income"]) == Economy.CITY_INCOME)
    assert(SitePaint.selected_caption(_at(sites,city)).contains("+100"))
    assert(SitePaint.owner_tint(-1) != SitePaint.owner_tint(-2))
    assert(state == original)
    var taken: Dictionary = state.duplicate(true)
    Economy.site_at(taken["economy"],factory)["produced_turn"] = int(taken["economy"]["turn"])
    assert(_at(SiteData.snapshots(taken),factory)["status"] == "used")
    assert(SitePaint.status_symbol(_at(SiteData.snapshots(taken),factory)) == "-")
    var poor: Dictionary = state.duplicate(true)
    poor["economy"]["credits"][0] = 0
    assert(_at(SiteData.snapshots(poor),factory)["status"] == "funds")
    var occupied: Dictionary = state.duplicate(true)
    occupied["units"].append(Roles.make_unit("K",0,factory,"line"))
    assert(_at(SiteData.snapshots(occupied),factory)["status"] == "blocked")
    var alternate: Dictionary = state.duplicate(true)
    alternate["faction"] = 1
    assert(_at(SiteData.snapshots(alternate),factory)["status"] == "wait")

    var capture_state: Dictionary = Session.start([
        Roles.make_unit("A",0,city,"line"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],terrain,0,false,false,true)
    var before: Dictionary = capture_state.duplicate(true)
    var marker: Dictionary = _at(SiteData.snapshots(capture_state),city)
    assert(marker["status"] == "capture" and marker["capture_pending"])
    assert(SitePaint.status_symbol(marker) == "!")
    assert(SitePaint.selected_caption(marker).contains("Captura"))
    var city_data: Dictionary = Dossier.inspect(capture_state,"","",Vector2i(-1,-1),city)
    assert(str(city_data["stats"][1]["value"]) == "Al fin de turno")
    assert(capture_state == before)
    var captured: Dictionary = Session.end_turn(capture_state)
    assert(captured["valid"])
    assert(Economy.site_at(captured["state"]["economy"],city)["owner"] == 0)
    assert(not bool(_at(SiteData.snapshots(captured["state"]),city)["capture_pending"]))

    # Enemy production state and ownership must not be leaked from a
    # previously explored (but now unobserved) city or enemy factory.
    var fogged: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],terrain,0,true,false,true)
    var dark: Dictionary = fogged.duplicate(true)
    assert(_at(SiteData.snapshots(fogged),rival_city).is_empty())
    fogged["explored"]["0"].append(rival_city)
    var remembered: Dictionary = _at(SiteData.snapshots(fogged),rival_city)
    assert(remembered["kind"] == "city")
    assert(remembered["owner"] == -2)
    assert(not remembered["owner_known"])
    assert(remembered["status"] == "city")
    assert(not str(remembered).contains("Rival"))
    # The current owner does not matter unless a scouting unit observes it.
    var remote: Dictionary = fogged.duplicate(true)
    Economy.site_at(remote["economy"],rival_city)["owner"] = -1
    assert(_at(SiteData.snapshots(remote),rival_city) == remembered)
    assert(fogged["units"] == dark["units"])

    var board = Board.new()
    board.ai_enabled = false
    board.size = Vector2(880,640)
    root.add_child(board)
    board.new_game(0,false,false,false,true,true)
    var match_snapshot: Dictionary = board.state.duplicate(true)
    var baseline: Array = board.site_overlay_snapshots()
    assert(not baseline.is_empty())
    var site_change: Dictionary = board.state.duplicate(true)
    Economy.site_at(site_change["economy"],factory)["produced_turn"] = int(site_change["economy"]["turn"])
    board.state = site_change
    assert(_at(board.site_overlay_snapshots(),factory)["status"] == "used")
    assert(board.state == site_change)
    board.state = match_snapshot
    board.inspected_cell = city
    board.queue_redraw()
    await process_frame
    assert(board.site_overlay_snapshots().size() == baseline.size())
    board.set_isometric(true)
    board.queue_redraw()
    await process_frame
    assert(board.state == match_snapshot)
    assert(board.screen_cell(Iso.center(city,board.size,board.iso_zoom,board.iso_pan,board.map_dimensions())) == city)
    # Markers always follow tile hitboxes, never become clickable fake units.
    board.queue_free()
    print("PASS map site overlays: owner visibility, city income, end-turn capture, true factory status, classic and iso render")
    quit(0)
