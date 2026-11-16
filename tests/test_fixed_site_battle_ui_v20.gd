extends SceneTree

const Orders = preload("res://scripts/experiments/FixedSiteOrdersV19.gd")
const LabUI = preload("res://scripts/ui/FixedSiteBattleV20.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _unit(units: Array, uid: String) -> Dictionary:
    for entry in units:
        if str(entry.get("id","")) == uid:
            return entry
    return {}

static func _free(terrain: Array, banned: Array) -> Vector2i:
    var dims: Vector2i = Rules.map_size(terrain)
    for x in range(dims.x-2,0,-1):
        for y in range(1,dims.y-1):
            var point := Vector2i(x,y)
            if point not in banned and Rules.movement_cost(str(terrain[y][x])) >= 0:
                return point
    return Vector2i(-1,-1)

func _run() -> void:
    print("V20_CHECKPOINT START main")\n    var main: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    print("V20_CHECKPOINT MAIN ready")\n    var prior: Dictionary = main.board.state.duplicate(true)
    main._show_home_menu()
    assert(main.home_menu.visible)
    assert(main.home_menu.primary_buttons.has("Conquistas · prueba"))
    main.home_menu.territorial_lab_requested.emit()
    print("V20_CHECKPOINT LAB opened")\n    assert(main.territory_lab != null)
    assert(not main.home_menu.visible)
    var ui: Control = main.territory_lab
    assert(ui.session.get("valid",false))
    assert(main.board.state == prior)
    assert(ui.board_view.pixel_to_cell(Vector2(-4,0)).x < 0)
    assert(ui.board_view.pixel_to_cell(Vector2(25,25)).x >= 0)
    assert(ui.buy_button.disabled)
    assert(ui.move_button.disabled)
    assert(ui.attack_button.disabled)
    assert(ui.session["world"]["layout"]["core_site_cap_exceeded"])
    var initial_sites: int = ui.session["world"]["layout"]["sites"].size()
    print("V20_CHECKPOINT STARTERS")\n    var first: Dictionary = {}
    for unit in ui.session["world"]["state"]["units"]:
        if int(unit["faction"]) == 0 and str(unit["role"]) == "scout":
            first = unit
            break
    assert(not first.is_empty())
    var before_cash: int = int(ui.session["world"]["state"]["economy"]["credits"][0])
    ui.select_cell(first["pos"])
    assert(ui.selected_unit_id == str(first["id"]))
    assert(not ui.camp_button.disabled)
    assert(str(ui.camp_picker.get_selected_metadata()) == "recon")
    ui.camp_button.pressed.emit()
    assert(ui.session["camps"].size() == 1)
    assert(int(ui.session["world"]["state"]["economy"]["credits"][0]) == before_cash-100)
    assert(bool(_unit(ui.session["world"]["state"]["units"],str(first["id"]))["acted"]))
    assert(ui.session["world"]["layout"]["sites"].size() == initial_sites)
    assert(ui.camp_button.disabled)
    print("V20_CHECKPOINT CAMP built")\n    ui.save_lab()
    assert(FileAccess.file_exists(LabUI.SAVE_PATH))
    var snapshot: String = Orders.encode(ui.session)
    ui.load_lab()
    assert(Orders.encode(ui.session) == snapshot)
    var file: FileAccess = FileAccess.open(LabUI.SAVE_PATH,FileAccess.WRITE)
    assert(file != null)
    file.store_string("{}")
    file.close()
    ui.load_lab()
    assert(Orders.encode(ui.session) == snapshot) # Corrupted save cannot destroy session.
    ui._end_turn()
    assert(int(ui.session["world"]["state"]["faction"]) == 1)
    ui._change_zoom(2)
    assert(ui.board_view.cell_pixels == 48)
    ui._change_zoom(-3)
    assert(ui.board_view.cell_pixels == 22)

    print("V20_CHECKPOINT NEW CAPTURE MAP")\n    var size := Vector2i(24,18)
    var terrain: Array = Scenarios.terrain(0,size)
    var layout: Dictionary = Sites.layout(terrain)
    var base: Dictionary = {}
    for site in layout["sites"]:
        if str(site["kind"]) == "armor_plant" and int(site["owner"]) == -1:
            base = site
            break
    assert(not base.is_empty())
    var enemy_pos: Vector2i = _free(terrain,[base["pos"]])
    var army := [
        Roles.make_unit("CAP",0,base["pos"],"scout"),
        Roles.make_unit("FOE",1,enemy_pos,"line")
    ]
    ui.session = Orders.start(0,size,0,army)
    assert(ui.session.get("valid",false))
    ui.selected_unit_id = ""
    ui.select_cell(base["pos"])
    assert(ui.buy_button.disabled)
    assert(str(ui.info.text).contains("Captura: 0/2"))
    print("V20_CHECKPOINT CAPTURE turn 1")\n    ui._end_turn() # First own phase, 1/2.
    assert(str(ui.info.text).contains("Captura: 1/2"))
    assert(int(Orders.site_card(ui.session,base["pos"])["owner"]) == -1)
    ui._end_turn() # Enemy phase, do not erase original hold.
    assert(int(Orders.site_card(ui.session,base["pos"])["progress"]) == 1)
    print("V20_CHECKPOINT CAPTURE turn 2")\n    ui._end_turn() # Second own phase -> factory switches owner.
    assert(int(Orders.site_card(ui.session,base["pos"])["owner"]) == 0)
    assert(ui.session["world"]["layout"]["sites"].size() == layout["sites"].size())
    ui._end_turn() # Back to the new owner's phase.
    assert(int(ui.session["world"]["state"]["faction"]) == 0)
    ui.select_cell(base["pos"]) # Soldier is currently blocking surface production.
    assert(ui.buy_button.disabled)
    assert(ui.selected_unit_id == "CAP")
    print("V20_CHECKPOINT MOVE AFTER CAPTURE")\n    var legal: Dictionary = Hints.for_unit(ui.session["world"]["state"],"CAP")
    var destination := Vector2i(-1,-1)
    for cell in legal.get("moves",{}):
        destination = cell
        break
    assert(destination.x >= 0)
    ui.select_cell(destination)
    assert(not ui.move_button.disabled)
    ui.move_button.pressed.emit()
    assert(_unit(ui.session["world"]["state"]["units"],"CAP")["pos"] == destination)
    ui.select_cell(base["pos"])
    assert(not ui.buy_button.disabled)
    assert(ui.buy_picker.item_count >= 1)
    var funds_before: int = int(ui.session["world"]["state"]["economy"]["credits"][0])
    var units_before: int = ui.session["world"]["state"]["units"].size()
    var role: String = str(ui.buy_picker.get_selected_metadata())
    print("V20_CHECKPOINT PURCHASE")\n    ui.buy_button.pressed.emit()
    assert(ui.session["world"]["state"]["units"].size() == units_before+1)
    assert(int(ui.session["world"]["state"]["economy"]["credits"][0]) == funds_before-Economy.cost(role))
    assert(ui.buy_button.disabled) # One production per facility per phase.
    assert(main.board.state == prior) # Experiment did not touch normal game.

    # Sea docks remain on water; infantry captures using a different shore cell.
    var coast: Dictionary = {}
    for site in layout["sites"]:
        if str(site["kind"]) == "shipyard":
            coast = site
            break
    if not coast.is_empty():
        var card: Dictionary = Orders.site_card(ui.session,coast["capture_pos"])
        assert(card["kind"] == "shipyard")
        assert(card["position"] == coast["pos"])
        assert(card["capture_position"] == coast["capture_pos"])
    print("V20_CHECKPOINT CLOSE")\n    main._close_territory_lab()
    assert(main.territory_lab == null)
    assert(main.home_menu.visible)
    assert(main.board.state == prior)
    main.queue_free()
    if FileAccess.file_exists(LabUI.SAVE_PATH):
        assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(LabUI.SAVE_PATH)) == OK)
    print("PASS fixed site battle UI v20: home entry, touch inspection, 2/2 capture HUD, construction, movement, production, landscape zoom, separate save and unchanged normal battle")
    quit(0)
