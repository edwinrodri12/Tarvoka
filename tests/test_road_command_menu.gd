extends SceneTree

const Rules = preload("res://scripts/core/Rules.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Inspector = preload("res://scripts/ui/InspectionData.gd")
const Command = preload("res://scripts/ui/CommandMenu.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var field: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        field.append(row)
    for x in range(1,9):
        field[3][x] = "road"
    var origin := Vector2i(1,3)
    var end := Vector2i(5,3)
    var too_far := Vector2i(6,3)
    var vehicle_path: Dictionary = Rules.reachable(origin,2,field,[],"ground",true)
    var infantry_path: Dictionary = Rules.reachable(origin,2,field,[],"ground",false)
    assert(vehicle_path.has(end) and int(vehicle_path[end]) == 2)
    assert(not vehicle_path.has(too_far))
    assert(infantry_path.has(Vector2i(3,3)) and not infantry_path.has(end))
    assert(not Rules.reachable(origin,2,field,[],"air",true).has(end))
    assert(Rules.reachable(origin,2,field,[],"naval",true).is_empty())
    assert(Rules.movement_cost_for("road") == 1)

    var apc: Dictionary = Roles.make_unit("APC",0,origin,"apc")
    var defender: Dictionary = Roles.make_unit("X",1,Vector2i(8,6),"line")
    apc["move_points"] = 2
    Logistics.equip(apc)
    assert(Logistics.road_fast(apc))
    assert(not Logistics.road_fast(defender))
    var battle: Dictionary = Session.start([apc,defender],field)
    var before: Dictionary = battle.duplicate(true)
    var hints: Dictionary = Hints.for_unit(battle,"APC")
    assert(hints["moves"].has(end))
    assert(not hints["moves"].has(too_far))
    var moved: Dictionary = Session.move(battle,"APC",end)
    assert(moved["valid"])
    assert(moved["state"]["units"][0]["pos"] == end)
    assert(int(moved["state"]["units"][0]["fuel"]) == int(apc["fuel"]) - 2)
    assert(battle == before)
    var card: Dictionary = Inspector.inspect(before,"APC","",Vector2i(-1,-1),origin)
    assert(str(card["body"]).contains("2 casillas por punto"))
    var terrain_card: Dictionary = Inspector.inspect(before,"","",Vector2i(-1,-1),origin)
    assert(str(terrain_card["body"]).contains("0.5 cada una"))

    # A player opening a read-only command screen must not change a match.
    var scene: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(scene)
    await process_frame
    var board = scene.board
    var snapshot: Dictionary = board.state.duplicate(true)
    assert(scene.command_menu != null)
    assert(scene.command_menu_button != null)
    assert(scene.compact_menu_button != null)
    assert(scene.home_menu != null)
    scene._show_home_menu()
    var home: Control = scene.home_menu
    assert(home.visible)
    assert(home.primary_buttons["Multijugador"].disabled)
    assert(board.state == snapshot)
    home.primary_buttons["Continuar"].pressed.emit()
    assert(not home.visible and board.state == snapshot)
    scene._show_home_menu()
    home.primary_buttons["Ajustes"].pressed.emit()
    assert(not home.visible and scene.command_menu.visible)
    assert(scene.command_menu.tabs.current_tab == 3)
    scene.command_menu.close_requested.emit()
    scene._open_command_menu()
    var menu: Control = scene.command_menu
    assert(menu.visible)
    assert(menu.tabs.get_tab_count() == 4)
    assert(menu.tabs.get_tab_title(0) == "Batalla")
    assert(board.state == snapshot)
    menu.close_requested.emit()
    assert(not menu.visible)
    assert(board.state == snapshot)
    board.selected_id = "A"
    scene._open_command_menu()
    assert(menu.tabs.current_tab == 1)
    menu.inspect_unit_requested.emit("A")
    assert(not menu.visible and board.selected_id == "A")
    assert(board.state == snapshot)
    board.cancel_selection()

    board.new_game(0,false,false,false,true,true,true)
    board.selected_factory_pos = Vector2i(0,3)
    var state_before: Dictionary = board.state.duplicate(true)
    scene._open_command_menu()
    assert(menu.tabs.current_tab == 2)
    assert(menu.production_body.get_child_count() > 2)
    assert(board.state == state_before)
    menu.close_requested.emit()
    scene.queue_free()
    print("PASS motorized roads and command menu: vehicle bonus, infantry separation, fuel, AI preview, battle navigation and production")
    quit(0)
