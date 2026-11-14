extends SceneTree

# Opens the actual packed WebGL studio, runs its new fourth category in a
# native renderer, previews three real board sizes and commits one SANDBOX
# order from the same fullscreen viewer as the Android V7 game.
const Combined = preload("res://scripts/ui/CombinedArtStudioWeb.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _unit_position(state: Dictionary, id: String) -> Vector2i:
    for u in state.get("units",[]):
        if str(u.get("id","")) == id:
            return u["pos"]
    return Vector2i(-1,-1)

func _run() -> void:
    root.content_scale_size = Vector2i(1366,860)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    assert(packed != null)
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    for frame in range(6):
        await process_frame
    assert(studio.get_script() == Combined)
    assert(studio.category_picker.item_count == 4)
    assert(studio.category_picker.get_item_text(3).contains("BATALLA"))
    assert(studio._role == "tank")
    assert(not studio.battle_controls.visible)

    studio._switch_category(3)
    for frame in range(5):
        await process_frame
    assert(studio._role == "battle")
    assert(studio.battle_controls.visible)
    assert(not studio.building_controls.visible)
    assert(not studio.terrain_controls.visible)
    assert(not studio.faction_picker.visible)
    assert(studio.battle_sample_board != null)
    assert(not studio.battle_sample_board.autosave_enabled)
    assert(not studio.battle_sample_board.ai_enabled)
    assert(studio.battle_sample_board.require_order_confirmation)
    assert(studio.model_root.get_meta("visual_only"))
    assert(studio.model_root.get_meta("board_size") == Vector2i(10,8))
    assert(studio.model_root.find_child("GuiasAlcance3D",true,false) != null)

    var initial_zoom: float = studio.camera.size
    studio._change_zoom(1)
    assert(studio.camera.size < initial_zoom)
    var original_camera: Vector3 = studio.camera.position
    studio._rotate(45.0)
    assert(studio.camera.position.distance_to(original_camera) > 0.1)
    # The logical board cannot rotate to distort touch/raycast coordinates.
    assert(studio.model_root.rotation_degrees == Vector3.ZERO)
    studio._reset_camera()

    # Medium 24x18 randomized battlefield, with fog and modern forces.
    studio.battle_scenario_picker.select(4)
    studio.battle_size_picker.select(1)
    studio.battle_fog_toggle.button_pressed = true
    studio._reset_battle_demo()
    assert(studio.model_root.get_meta("board_size") == Vector2i(24,18))
    assert(Rules.map_size(studio.battle_sample_board.state["terrain"]) == Vector2i(24,18))
    assert(studio.battle_sample_board.state["map_seed"] == 22435)
    var counts: Dictionary = studio.model_root.get_meta("render_stats")
    assert(int(counts["unknown"]) > 0)
    assert(int(counts["chunks"]) == 9)
    assert(studio.model_root.find_child("GuiasAlcance3D",true,false) != null)
    assert(studio.status_label.text.contains("Niebla"))
    for frame in range(5):
        await process_frame
    var sample: Image = studio.preview.get_texture().get_image()
    assert(sample != null and not sample.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sample.save_png("res://artifacts/tarvoka_studio_battle_3d_medium.png") == OK)

    var board: Control = studio.battle_sample_board
    var viewer: Control = studio.battle_full_view
    var fresh: Dictionary = board.state.duplicate(true)
    studio._open_battle_fullscreen()
    for frame in range(5):
        await process_frame
    assert(viewer.visible)
    assert(viewer.get("_live_board") == board)
    assert(studio.preview.render_target_update_mode == SubViewport.UPDATE_DISABLED)
    var selected: String = str(board.get("selected_id"))
    assert(not selected.is_empty())
    var hints: Dictionary = Hints.for_unit(board.state,selected)
    if hints["moves"].is_empty():
        for unit in board.state["units"]:
            if int(unit.get("faction",-1)) != 0:
                continue
            var other: Dictionary = Hints.for_unit(board.state,str(unit["id"]))
            if not other["moves"].is_empty():
                selected = str(unit["id"])
                assert(viewer.call("_select_3d_unit",selected))
                hints = other
                break
    assert(not hints["moves"].is_empty())
    var target: Vector2i = hints["moves"].keys()[0]
    assert(viewer.call("tap_battle_cell",target))
    assert(viewer.get("_confirm_order_button").visible)
    assert(board.state == fresh)
    assert(not board.pending_order.is_empty())
    var previous: Vector2i = _unit_position(board.state,selected)
    assert(previous != target)
    for frame in range(5):
        await process_frame
    var interactive: Image = viewer.get("preview").get_texture().get_image()
    assert(interactive != null and not interactive.is_empty())
    assert(interactive.save_png("res://artifacts/tarvoka_studio_battle_3d_orders.png") == OK)
    viewer.call("_confirm_3d_order")
    assert(_unit_position(board.state,selected) == target)
    assert(board.pending_order.is_empty())
    assert(viewer.visible)
    viewer.call("close_view")
    for frame in range(6):
        await process_frame
    assert(not viewer.visible)
    assert(studio.preview.render_target_update_mode == SubViewport.UPDATE_ALWAYS)
    assert(studio.model_root.get_meta("board_size") == Vector2i(24,18))
    assert(studio._role == "battle")

    # Large 40x30 displays the REAL geometry while keeping fog protected.
    studio.battle_size_picker.select(2)
    studio.battle_scenario_picker.select(2)
    studio._reset_battle_demo()
    assert(studio.model_root.get_meta("board_size") == Vector2i(40,30))
    var large: Dictionary = studio.model_root.get_meta("render_stats")
    assert(int(large["chunks"]) == 20)
    assert(int(large["unknown"]) > 0)
    assert(studio.model_root.get_meta("public_cells").size() == 1200)
    # Switching off the fog reveals terrain, not a secret gameplay change.
    studio.battle_fog_toggle.button_pressed = false
    studio._reset_battle_demo()
    assert(int(studio.model_root.get_meta("render_stats")["unknown"]) == 0)

    # All four modes coexist and can be revisited without a page reload.
    studio._switch_category(2)
    assert(studio._role == "terrain")
    studio._switch_category(1)
    assert(studio._role == "headquarters")
    studio._switch_category(0)
    assert(studio._role == "tank")
    studio._switch_category(3)
    assert(studio._role == "battle")
    studio.free()
    print("PASS WEB_3D_BATTLE_STUDIO_V8: four categories, real 10x8/24x18/40x30 maps, fullscreen confirmed orders, fog, WebGL previews and no saves")
    quit(0)
