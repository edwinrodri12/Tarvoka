extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Radar = preload("res://scripts/ui/ObjectivesRadarData.gd")
const RadarPanel = preload("res://scripts/ui/ObjectivesRadarPanel.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var tank: Dictionary = Roles.make_unit("T",0,Vector2i(1,2),"tank")
    Logistics.equip(tank)
    tank["ammo"] = 0
    tank["fuel"] = 0
    tank["hp"] = 2
    var own: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"line")
    var enemy: Dictionary = Roles.make_unit("X",1,Vector2i(8,5),"tank")
    Logistics.equip(enemy)
    enemy["ammo"] = 0
    enemy["fuel"] = 0
    enemy["hp"] = 2
    var battle: Dictionary = Session.start([own,tank,enemy],terrain,0,false,false,true,true)
    # Modern-mode setup equips units on spawn; simulate shortages AFTER spawn.
    for unit in battle["units"]:
        if str(unit.get("id","")) in ["T","X"]:
            unit["ammo"] = 0
            unit["fuel"] = 0
            unit["hp"] = 2
    var initial: Dictionary = battle.duplicate(true)
    var radar: Dictionary = Radar.build(battle)
    assert(radar["valid"])
    assert(radar["objective"] == "Neutralizar el ejército rival")
    assert(radar["relays"].is_empty())
    assert(radar["sites"].size() == battle["economy"]["sites"].size())
    assert(int(radar["income"]) == Economy.MODERN_CITY_INCOME)
    assert(int(radar["owned_cities"]) == 1)
    assert(int(radar["alert_count"]) == 1)
    assert(radar["alerts"][0]["id"] == "T")
    assert(str(radar["alerts"][0]["status"]).contains("MUNICION AGOTADA"))
    assert(str(radar["alerts"][0]["status"]).contains("SIN COMBUSTIBLE"))
    assert(not str(radar).contains("X · "))
    assert(battle == initial)

    var relay_battle: Dictionary = Session.start([own,enemy],terrain,0,true,true,true,false)
    var relays: Dictionary = Radar.build(relay_battle)
    assert(relays["valid"])
    assert(str(relays["objective"]).contains("Señal táctica"))
    assert(relays["relays"].size() == relay_battle["control"]["nodes"].size())
    var fogged_unknown := 0
    for point in relays["relays"]:
        if point["owner"] == -2:
            fogged_unknown += 1
    assert(fogged_unknown > 0) # Relay positions are known; remote ownership is NOT.
    var hidden: Dictionary = Radar.build(relay_battle)
    assert(hidden["sites"].size() < relay_battle["economy"]["sites"].size())
    for item in hidden["sites"]:
        if item["owner"] == -2:
            assert(item["status"] == "Control sin confirmar")
    var far_city := Vector2i(7,1)
    relay_battle["explored"]["0"].append(far_city)
    var known: Dictionary = Radar.build(relay_battle)
    var found_unconfirmed := false
    for item in known["sites"]:
        if item["pos"] == far_city:
            found_unconfirmed = true
            assert(item["owner"] == -2)
            assert(item["status"] == "Control sin confirmar")
    assert(found_unconfirmed)
    var altered: Dictionary = relay_battle.duplicate(true)
    var site: Dictionary = Economy.site_at(altered["economy"],far_city)
    site["owner"] = -1
    assert(Radar.build(altered)["sites"] == known["sites"]) # No silent enemy ownership leak.

    var panel = RadarPanel.new()
    root.add_child(panel)
    panel.open_with_state(battle)
    assert(panel.visible)
    assert(panel.tabs.get_tab_count() == 3)
    assert(panel.overview_body.get_child_count() > 3)
    assert(panel.sites_body.get_child_count() > 3)
    assert(panel.alerts_body.get_child_count() > 1)
    panel.tabs.current_tab = 2
    panel.refresh_from_state(battle)
    assert(panel.tabs.current_tab == 2)
    var tapped_units: Array = []
    var tapped_sites: Array = []
    panel.locate_unit_requested.connect(func(uid: String): tapped_units.append(uid))
    panel.locate_site_requested.connect(func(cell: Vector2i,cat: String): tapped_sites.append([cell,cat]))
    panel.locate_unit_requested.emit("T")
    panel.locate_site_requested.emit(Vector2i(3,4),"site")
    assert(tapped_units == ["T"])
    assert(tapped_sites.size() == 1 and tapped_sites[0][1] == "site")
    panel.hide()
    panel.queue_free()

    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    await process_frame
    var board = screen.board
    board.new_game(0,false,false,false,true,true)
    var save: Dictionary = board.state.duplicate(true)
    assert(screen.objectives_button != null and screen.compact_objectives_button != null)
    screen.compact_objectives_button.pressed.emit()
    assert(screen.objectives_panel.visible)
    assert(screen.objectives_scrim.visible)
    assert(screen.objectives_panel.tabs.get_tab_count() == 3)
    assert(board.state == save)
    screen.objectives_panel.tabs.current_tab = 2
    board.state["units"][0]["hp"] = 2
    var modified: Dictionary = board.state.duplicate(true)
    screen._process(0.0)
    assert(screen.objectives_panel.tabs.current_tab == 2)
    assert(screen.objectives_panel._data["alert_count"] >= 1)
    assert(board.state == modified)
    screen._locate_objective_unit("A")
    assert(board.selected_id == "A")
    assert(not screen.objectives_panel.visible and not screen.objectives_scrim.visible)
    assert(board.pending_order.is_empty())
    assert(board.state == modified)

    screen.objectives_button.pressed.emit()
    assert(screen.objectives_panel.visible)
    screen._locate_objective_site(Vector2i(3,4),"site")
    assert(board.inspected_cell == Vector2i(3,4))
    assert(board.selected_id == "")
    assert(not screen.objectives_panel.visible)
    assert(board.state == modified)

    screen._open_objectives_radar()
    board.pending_order = {"kind":"move","unit_id":"A"}
    screen._locate_objective_site(Vector2i(3,4),"site")
    assert(screen.objectives_panel.visible) # Refuse to discard existing order.
    assert(board.pending_order.has("kind"))
    screen._close_objectives_radar()
    board.pending_order.clear()
    screen._open_objectives_radar()
    screen._locate_objective_site(Vector2i(8,2),"site") # Unknown target is rejected.
    assert(screen.objectives_panel.visible)
    screen._close_objectives_radar()
    assert(board.state == modified)
    screen.queue_free()
    for suffix in ["",".bak"]:
        var path: String = "user://tarvoka_autosave_v1.json" + suffix
        if FileAccess.file_exists(path):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
    print("PASS objectives radar: real win modes, no fog leaks, allied warnings, tabs, safe map navigation and no battle mutation")
    quit(0)
