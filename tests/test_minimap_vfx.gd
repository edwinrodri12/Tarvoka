extends SceneTree

const Board = preload("res://scripts/ui/TouchBoard.gd")
const Minimap = preload("res://scripts/ui/BattleMinimap.gd")
const VFX = preload("res://scripts/ui/BattleVFX.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Eight screen headings, independently quantized from the actual grid.
    var headings := {}
    for delta in [Vector2.RIGHT,Vector2(1,1),Vector2.DOWN,Vector2(-1,1),
            Vector2.LEFT,Vector2(-1,-1),Vector2.UP,Vector2(1,-1)]:
        headings[VFX.direction_sector(delta)] = true
    assert(headings.size() == 8)
    assert(VFX.direction_sector(Vector2.ZERO) == -1)
    assert(VFX.projected_heading(Vector2i(2,2),Vector2i(3,2)) !=
        VFX.projected_heading(Vector2i(2,2),Vector2i(2,3)))
    assert(VFX.sprite_rotation("tank",Vector2.RIGHT) !=
        VFX.sprite_rotation("tank",Vector2.LEFT))
    assert(VFX.sprite_rotation("fighter",Vector2.DOWN) !=
        VFX.sprite_rotation("fighter",Vector2.UP))
    assert(VFX.sprite_rotation("invalid",Vector2.RIGHT) == 0.0)
    assert(VFX.family_for_role("fighter") == "air")
    assert(VFX.family_for_role("destroyer") == "naval")
    assert(VFX.impact_color("fighter") != VFX.impact_color("tank"))
    assert(VFX.impact_color("frigate") != VFX.impact_color("tank"))

    # Larger maps already have a reversible projection and camera footprint,
    # before their separate movement/AI/serialization migration.
    for dimensions in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for zoom in [0.7,1.0,2.0]:
            for cell in [Vector2i(0,0),
                    Vector2i(dimensions.x-1,dimensions.y-1),
                    Vector2i(int(dimensions.x/2),int(dimensions.y/2))]:
                var view := Vector2(1200,740)
                var pan := Vector2(-63,27)
                var screen: Vector2 = Iso.center(cell,view,zoom,pan,dimensions)
                assert(Iso.screen_to_cell(screen,view,zoom,pan,dimensions)==cell)
                assert(Iso.diamond(cell,view,zoom,pan,dimensions).size()==4)
    assert(Iso.half_width(Vector2(800,640),1.0,Vector2i.ZERO)==0.0)

    var board = Board.new()
    board.ai_enabled = false
    board.size = Vector2(800,640)
    root.add_child(board)
    board.new_game(0,true,true,true,true,true,true)
    board.set_isometric(true)
    var original: Dictionary = board.state.duplicate(true)
    var map = Minimap.new()
    map.size = Vector2(280,190)
    root.add_child(map)
    map.set_board(board)
    assert(Minimap.dimensions(board.state) == Vector2i(10,8))
    assert(Minimap.dimensions({}) == Vector2i.ZERO)
    var bounds: Rect2 = Minimap.local_bounds(map.size,Vector2i(10,8))
    assert(bounds.size.x > 0 and bounds.size.y > 0)
    assert(Minimap.point_to_cell(Vector2(-100,-100),map.size,Vector2i(10,8)) == Vector2i(-1,-1))
    var target := Vector2i(4,5)
    var touch: Vector2 = bounds.position+(Vector2(target)+Vector2(0.5,0.5)) * (bounds.size/Vector2(10,8))
    assert(Minimap.point_to_cell(touch,map.size,Vector2i(10,8)) == target)
    assert(Minimap.viewport_corners(map.size,board.state,board.size,1.0,Vector2.ZERO).size() == 5)
    var expanded_state := {"terrain":[]}
    for y in range(18):
        var row: Array = []
        for x in range(24):
            row.append("plain")
        expanded_state["terrain"].append(row)
    assert(Minimap.dimensions(expanded_state)==Vector2i(24,18))
    var expanded_corners: PackedVector2Array = Minimap.viewport_corners(map.size,
        expanded_state,board.size,1.6,Vector2(-100,70))
    assert(expanded_corners.size()==5)
    var expanded_bounds: Rect2 = Minimap.local_bounds(map.size,Vector2i(24,18))
    var expanded_point: Vector2 = expanded_bounds.position+Vector2(21.5,15.5)*(
        expanded_bounds.size/Vector2(24,18))
    assert(Minimap.point_to_cell(expanded_point,map.size,Vector2i(24,18))==Vector2i(21,15))
    var hidden_data: Dictionary = Minimap.safe_snapshot(board.state)
    assert(hidden_data["tiles"].size() == 80)
    assert(hidden_data["size"] == Vector2i(10,8))
    var fog_enabled: bool = Visibility.enabled(board.state)
    assert(fog_enabled)
    var visible: Dictionary = Visibility.visible_cells(board.state,0)
    var explored: Dictionary = Visibility.explored_cells(board.state,0)
    for unit in hidden_data["units"]:
        if int(unit["faction"]) != 0:
            assert(visible.has(unit["pos"]))
    for unit in board.state["units"]:
        if int(unit["faction"]) != 0 and not visible.has(unit["pos"]):
            var revealed := false
            for marker in hidden_data["units"]:
                if marker["pos"] == unit["pos"] and int(marker["faction"]) != 0:
                    revealed = true
            assert(not revealed)
    for tile in hidden_data["tiles"]:
        if not explored.has(tile["pos"]):
            assert(tile["kind"] == "unknown")
            assert(not bool(tile["visible"]))
    for site in hidden_data["sites"]:
        if not visible.has(site["pos"]) and int(site["owner"]) != 0:
            assert(int(site["owner"]) == -1)

    map._focus(touch)
    assert(board.state == original)
    assert(board.selected_id == "")
    assert(board.pending_order.is_empty())
    assert(board.screen_cell(board.size*0.5) == target)
    var centered_pan: Vector2 = board.iso_pan
    var down := InputEventScreenTouch.new()
    down.pressed = false
    down.position = bounds.position + (Vector2(2.5,2.5)*(bounds.size/Vector2(10,8)))
    map._gui_input(down)
    assert(board.iso_pan != centered_pan)
    assert(board.state == original)
    var previous_pan: Vector2 = board.iso_pan
    map._focus(Vector2(-999,-999))
    assert(board.iso_pan == previous_pan)
    assert(board.state == original)
    assert(not board.focus_iso_cell(Vector2i(-2,2)))
    assert(not board.focus_iso_cell(Vector2i(12,2)))

    # Verify transient VFX never overwrite a real battle result and recognize
    # eliminations where the dead defender is removed from the units array.
    board.new_game()
    board.set_isometric(true)
    var before: Dictionary = board.state.duplicate(true)
    var attacker: Dictionary = {}
    var defender: Dictionary = {}
    for unit in before["units"]:
        if int(unit["faction"]) == 0 and attacker.is_empty():
            attacker = unit
        elif int(unit["faction"]) == 1 and defender.is_empty():
            defender = unit
    assert(not attacker.is_empty() and not defender.is_empty())
    var after: Dictionary = before.duplicate(true)
    for i in range(after["units"].size()-1,-1,-1):
        if str(after["units"][i]["id"]) == str(defender["id"]):
            after["units"].remove_at(i)
    board._record_attack_effect(before,{"state":after},str(attacker["id"]),str(defender["id"]))
    assert(board.combat_effects.size() == 1)
    assert(board.combat_effects[0]["destroyed"])
    assert(board.combat_effects[0].has("attacker_role"))
    assert(board.combat_effects[0].has("defender_role"))
    assert(board.state == before)
    board.combat_effects[0]["elapsed"] = 0.12
    board.queue_redraw()
    await process_frame
    board.combat_effects[0]["elapsed"] = 0.39
    board.queue_redraw()
    await process_frame
    assert(board.state == before)
    board._process(0.24)
    assert(board.state == before)
    map.queue_redraw()
    await process_frame

    # The actual Android HUD toggles the minimap alongside isometric mode.
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var mini: Control = screen.get("battle_minimap")
    var label: Label = screen.get("minimap_caption")
    var camera: Control = screen.get("board")
    assert(mini != null and label != null and camera != null)
    assert(not mini.visible)
    var screen_before: Dictionary = camera.state.duplicate(true)
    screen._toggle_isometric_view()
    assert(mini.visible and label.visible)
    assert(camera.state == screen_before)
    screen._toggle_isometric_view()
    assert(not mini.visible and not label.visible)
    assert(camera.state == screen_before)
    screen.queue_free()
    map.queue_free()
    board.queue_free()
    print("PASS 8-way facing, three weapon impact families, destroyed enemy, fog-safe minimap and no tactical mutations")
    quit(0)
