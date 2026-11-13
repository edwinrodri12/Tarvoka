extends SceneTree

const Rules = preload("res://scripts/core/Rules.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Inspector = preload("res://scripts/ui/InspectionData.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var hills: Array = Scenarios.terrain(1)
    assert(hills[0][4] == "mountain")
    assert(Rules.movement_cost_for("mountain",Domains.GROUND) == 3)
    var origin := Vector2i(3,0)
    var summit := Vector2i(4,0)
    var slow: Dictionary = Rules.reachable(origin,2,hills,[],Domains.GROUND)
    assert(slow.has(summit) and int(slow[summit]) == 2)
    assert(not slow.has(Vector2i(5,0)))
    var crawling: Dictionary = Rules.reachable(origin,1,hills,[],Domains.GROUND)
    assert(crawling.has(summit) and int(crawling[summit]) == 1)
    assert(not Rules.reachable(origin,0,hills,[],Domains.GROUND).has(summit))
    assert(Rules.reachable(origin,3,hills,[],Domains.GROUND)[summit] == 3)
    assert(Rules.reachable(origin,2,hills,[],Domains.AIR)[summit] == 1)
    assert(not Rules.reachable(origin,2,hills,[],Domains.NAVAL).has(summit))

    var bulwark: Dictionary = Roles.make_unit("A",0,origin,"bulwark")
    var opponent: Dictionary = Roles.make_unit("X",1,Vector2i(8,2),"bulwark")
    var state: Dictionary = Session.start([bulwark,opponent],hills)
    var original: Dictionary = state.duplicate(true)
    var climbed: Dictionary = Session.move(state,"A",summit)
    assert(climbed["valid"])
    # Session.move returns authoritative state, while Rules.reachable carries the path cost.
    assert(int(slow[summit]) == 2)
    assert(climbed["state"]["units"][0]["pos"] == summit)
    assert(state == original)
    assert(Codec.decode(Codec.encode(climbed["state"])) == climbed["state"])
    var landed: Dictionary = climbed["state"]["units"][0]
    var attacker: Dictionary = Roles.make_unit("Q",1,Vector2i(3,0),"line")
    var stats: Dictionary = Terrain.modifiers(attacker,landed,hills,{})
    assert(int(stats["defense_cover"]) == 2 and int(stats["height_delta"]) == -1)

    # One read-only presenter drives both HUD modes and never mutates saves.
    var own_card: Dictionary = Inspector.inspect(climbed["state"],"A","",Vector2i(-1,-1),summit)
    assert(own_card["kind"] == "friendly")
    assert(str(own_card["body"]).contains("cobertura +2"))
    var tile_card: Dictionary = Inspector.inspect(climbed["state"],"","",Vector2i(-1,-1),summit)
    assert(tile_card["kind"] == "terrain" and str(tile_card["body"]).contains("todo su movimiento"))
    var neutral: Dictionary = Session.start([bulwark,opponent],Scenarios.terrain(0),0,false,false,true)
    var before_card: Dictionary = neutral.duplicate(true)
    var city: Dictionary = Inspector.inspect(neutral,"","",Vector2i(-1,-1),Vector2i(3,4))
    assert(city["kind"] == "building" and str(city["title"]).contains("Ciudad"))
    assert(str(city["body"]).contains("Ingreso: +100"))
    var factory: Dictionary = Inspector.inspect(neutral,"","",Vector2i(0,3),Vector2i(0,3))
    assert(factory["kind"] == "building" and str(factory["title"]).contains("Taller"))
    assert(neutral == before_card)

    # A hidden hostile unit or installation must not disclose state in fog.
    var fogged: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,2),"line")
    ],Scenarios.terrain(0),0,true,false,true)
    var untouched: Dictionary = fogged.duplicate(true)
    var hidden: Dictionary = Inspector.inspect(fogged,"","X",Vector2i(-1,-1),Vector2i(-1,-1))
    assert(hidden["kind"] == "none")
    var uncharted: Dictionary = Inspector.inspect(fogged,"","",Vector2i(-1,-1),Vector2i(6,4))
    assert(uncharted["kind"] == "unknown" and not str(uncharted["body"]).contains("Ciudad"))
    assert(fogged == untouched)

    var view: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(view)
    await process_frame
    var board = view.board
    board.new_game(1)
    board.selected_id = "A"
    view._process(0.0)
    assert(view.inspection_title.visible)
    assert(view.inspection_title.text.contains("A"))
    view._set_compact_hud(true)
    view._process(0.0)
    assert(view.compact_info_panel.visible)
    assert(view.compact_info_title.text == view.inspection_title.text)
    assert(view.compact_info_body.text == view.inspection_detail.text)

    board.selected_id = ""
    board.inspected_cell = summit
    view._process(0.0)
    assert(view.compact_info_title.text == "Montana")
    board.cancel_selection()
    view._process(0.0)
    assert(not view.compact_info_panel.visible)
    board.new_game(0,false,false,false,false,true)
    board.selected_factory_pos = Vector2i(0,3)
    view._process(0.0)
    assert(view.compact_info_title.text.contains("Taller"))
    assert(view.compact_info_body.text.contains("producir"))
    var saved: Dictionary = board.state.duplicate(true)
    assert(board.state == saved)
    view.queue_free()
    print("PASS mountain mobility and contextual inspection: slow ascent, heights, UI cards, fog safety, saved state")
    quit(0)
