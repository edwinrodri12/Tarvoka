extends SceneTree

const Codec = preload("res://scripts/core/SaveCodec.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Director = preload("res://scripts/core/StrategicDirectorV32.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var screen: Control = load("res://scenes/Main.tscn").instantiate()
    root.add_child(screen)
    await process_frame
    var board: Control = screen.board
    var setup: Control = screen.skirmish_setup
    var original: Dictionary = board.state.duplicate(true)
    assert(not original.has("ai_config")) # old games unchanged
    screen._prepare_skirmish()
    assert(setup.visible and setup.ai_level_picker.item_count == 12)
    assert(setup.ai_style_picker.item_count == Director.STYLES.size())
    setup.ai_level_picker.select(11)
    setup.ai_style_picker.select(5)
    setup._changed(true)
    var settings: Dictionary = setup.options()
    assert(settings["ai_level"] == 12)
    assert(settings["ai_style"] == "combined_arms")
    assert(setup.summary.text.contains("IA rival:"))
    assert(board.state == original) # UI never edits an existing battle
    screen._start_skirmish_setup(settings)
    assert(board.state == original) # Existing confirmation is respected
    screen._confirm_new_game()
    assert(not setup.visible)
    assert(board.state.has("ai_config"))
    assert(board.state["ai_config"] == {
        "level":12,"style":"combined_arms"})
    assert(board.ai_profile == {
        "ai_level":12,"ai_style":"combined_arms"})
    var saved: String = Codec.encode(board.state)
    assert(not saved.is_empty())
    var restored: Dictionary = Codec.decode(saved)
    assert(restored == board.state)
    assert(board._profile_from_saved_state(restored) == board.ai_profile)
    var next: Dictionary = Session.end_turn(restored)
    assert(next.get("valid",false))
    assert(next["state"]["ai_config"] == restored["ai_config"])
    var wrong: Dictionary = restored.duplicate(true)
    wrong["ai_config"]["level"] = 13
    assert(Codec.encode(wrong).is_empty())
    wrong = restored.duplicate(true)
    wrong["ai_config"]["style"] = "super_cheat"
    assert(Codec.encode(wrong).is_empty())
    wrong = restored.duplicate(true)
    wrong["ai_config"]["hidden_bonus"] = 99999
    assert(Codec.encode(wrong).is_empty())
    assert(Codec.decode(JSON.stringify({
        "version":1,"ai_config":{"level":9999,"style":"balanced"}})).is_empty())
    print("PASS AI preflight v32: selectable 12 difficulties x 11 styles, real board AI options, confirmed skirmish, persisted per-match save, legacy compatibility")
    screen.queue_free()
    quit(0)
