extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Dossier = preload("res://scripts/ui/UnitDossierData.gd")
const Compare = preload("res://scripts/ui/UnitComparisonData.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = Scenarios.terrain(3)
    var modern: Dictionary = Session.start(Roles.modern_armies(),terrain,0,false,false,true,true)
    var saved: Dictionary = modern.duplicate(true)
    var armor := Vector2i(0,1)
    var my_factory := Vector2i(0,3)
    var tank: Dictionary = Compare.candidate(modern,armor,"tank")
    assert(not tank.is_empty())
    assert(tank["name"] == Roles.label("tank"))
    assert(int(tank["price"]) == Economy.cost("tank"))
    assert(int(tank["attack"]) == 8 and int(tank["defense"]) == 2)
    assert(bool(tank["available"]))
    assert(Compare.candidate(modern,armor,"fighter").is_empty())
    assert(Compare.candidate(modern,Vector2i(9,1),"tank").is_empty())
    var against_ifv: Dictionary = Compare.compare(modern,armor,"tank","ifv")
    assert(int(against_ifv["left"]["hp"]) > int(against_ifv["right"]["hp"]))
    assert(int(against_ifv["left"]["price"]) > int(against_ifv["right"]["price"]))
    assert(against_ifv["rows"].size() == 7)
    assert(Compare.candidate(modern,my_factory,"scout")["available"])
    assert(modern == saved) # Comparing doesn't buy.

    var spent: Dictionary = modern.duplicate(true)
    var used_site: Dictionary = Economy.site_at(spent["economy"],armor)
    used_site["produced_turn"] = int(spent["economy"]["turn"])
    assert(not Compare.candidate(spent,armor,"tank")["available"])
    assert(str(Compare.candidate(spent,armor,"tank")["reason"]).contains("ya produjo"))
    var broke: Dictionary = modern.duplicate(true)
    broke["economy"]["credits"][0] = 10
    assert(str(Compare.candidate(broke,armor,"tank")["reason"]).contains("Faltan"))
    var blocked: Dictionary = modern.duplicate(true)
    blocked["units"][0]["pos"] = armor
    assert(not bool(Compare.candidate(blocked,armor,"tank")["available"]))
    var enemy_turn: Dictionary = modern.duplicate(true)
    enemy_turn["faction"] = 1
    assert(not bool(Compare.candidate(enemy_turn,armor,"tank")["available"]))
    assert(str(Compare.candidate(enemy_turn,armor,"tank")["reason"]) == "No es tu turno")

    var ally := Roles.make_unit("A",0,Vector2i(1,2),"line")
    var opponent := Roles.make_unit("X",1,Vector2i(2,2),"tank")
    Logistics.equip(opponent)
    var visible: Dictionary = Session.start([ally,opponent],Scenarios.terrain(0),0,true,false,true,true)
    var visible_before: Dictionary = visible.duplicate(true)
    var own: Dictionary = Dossier.inspect(visible,"A","",Vector2i(-1,-1),Vector2i(-1,-1))
    assert(own["kind"] == "friendly")
    assert(own["stats"].size() == 6)
    assert(own["hp"] == 10)
    assert(str(own["name"]).contains("Guardia"))
    var opponent_card: Dictionary = Dossier.inspect(visible,"","X",Vector2i(-1,-1),Vector2i(-1,-1))
    assert(opponent_card["kind"] == "enemy")
    assert(opponent_card["role"] == "tank")
    assert(not opponent_card.has("ammo") and not opponent_card.has("fuel"))
    assert(not opponent_card.has("reacted") and not opponent_card.has("acted"))
    assert(not str(opponent_card).contains("combustible"))
    assert(visible == visible_before)

    var distant: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"line"),
        Roles.make_unit("X",1,Vector2i(8,5),"line")
    ],Scenarios.terrain(0),0,true,false,true)
    var distant_before: Dictionary = distant.duplicate(true)
    assert(Dossier.inspect(distant,"","X",Vector2i(-1,-1),Vector2i(-1,-1)).is_empty())
    assert(Dossier.inspect(distant,"","",Vector2i(-1,-1),Vector2i(7,1)).is_empty())
    # An explored but unobserved hostile city reveals its function, not current owner.
    distant["explored"]["0"].append(Vector2i(7,1))
    var remembered: Dictionary = Dossier.inspect(distant,"","",Vector2i(-1,-1),Vector2i(7,1))
    assert(remembered["kind"] == "building")
    assert(remembered["owner"] == "Sin confirmar")
    assert(not str(remembered).contains("Rival"))
    var city: Dictionary = Dossier.inspect(distant,"","",Vector2i(-1,-1),Vector2i(2,1))
    assert(city["kind"] == "building")
    assert(city["owner"] == "Aliado")
    assert(str(city["stats"][0]["value"]).contains("+100"))
    assert(distant["units"] == distant_before["units"])

    var view: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(view)
    await process_frame
    var board = view.board
    board.new_game(0)
    var ui_snapshot: Dictionary = board.state.duplicate(true)
    board.selected_id = "A"
    view._process(0.0)
    assert(view.sidebar_dossier.visible and view.compact_dossier.visible)
    assert(view.sidebar_dossier._name.text.contains("HP"))
    assert(view.compact_dossier._stats.text.contains("MOV"))
    assert(not view.compact_info_body.visible) # Visual compact stats replace duplicate prose.
    assert(board.state == ui_snapshot)
    board.cancel_selection()
    board.inspected_cell = Vector2i(4,0)
    view._process(0.0)
    assert(not view.compact_dossier.visible)
    assert(view.compact_info_body.visible)

    board.new_game(3,false,false,false,true,true,true)
    board.selected_factory_pos = armor
    var before_menu: Dictionary = board.state.duplicate(true)
    view._open_command_menu()
    var menu = view.command_menu
    assert(menu.tabs.current_tab == 2)
    assert(menu.comparison_preview != null and menu.comparison_preview.visible)
    assert(menu.selected_catalog_role == "bulwark" or menu.selected_catalog_role == "piercer" or menu.selected_catalog_role == "apc")
    menu._select_production_role("tank")
    assert(menu.selected_catalog_role == "tank")
    menu._compare_production_role("ifv")
    assert(menu.comparison_catalog_role == "ifv")
    assert(menu.comparison_preview._content.get_child_count() >= 5)
    assert(board.state == before_menu)
    menu.close_requested.emit()
    view.queue_free()
    for suffix in ["",".bak"]:
        var path: String = "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS unit dossiers and production comparison: visual stats, city fog privacy, real cost/availability and zero state changes")
    quit(0)
