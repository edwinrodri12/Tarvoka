extends SceneTree

const Chapter = preload("res://scripts/ui/CampaignChapter01.gd")
const Main = preload("res://scripts/ui/Main.gd")
const Mission = preload("res://scripts/core/CampaignMission.gd")
const Store = preload("res://scripts/core/CampaignStore.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const SaveStore = preload("res://scripts/core/SaveStore.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const CAMPAIGN_TEST := "user://tarvoka_campaign_test_ui.json"
const SKIRMISH_TEST := "user://tarvoka_battle_test_story.json"

func _initialize() -> void:
    call_deferred("_test")

func _cleanup(path: String) -> void:
    for suffix in ["",".tmp",".bak"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func _test() -> void:
    _cleanup(CAMPAIGN_TEST)
    _cleanup(SKIRMISH_TEST)
    var normal_battle: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,1),"line"),
        Roles.make_unit("X",1,Vector2i(8,6),"line")],
        Scenarios.terrain(0))
    assert(SaveStore.save(normal_battle,SKIRMISH_TEST))
    var skirmish_before: String = FileAccess.get_file_as_string(SKIRMISH_TEST)

    var screen := Chapter.new()
    screen.checkpoint_path = CAMPAIGN_TEST
    root.add_child(screen)
    await process_frame
    assert(screen.board != null)
    assert(screen.board.iso_enabled)
    assert(screen.board.autosave_enabled == false)
    assert(screen.board.campaign_markers == [Vector2i(4,2),Vector2i(5,5)])
    assert(screen.mission["id"] == "C01")
    assert(screen.mission["status"] == "active")
    assert(screen.mission["events_seen"] == ["C01_START"])
    assert(screen.objective_label.text.contains("balizas"))
    assert(screen.progress_label.text.contains("0/2"))
    assert(screen.dialogue_label.text.contains("PACTO ESCARLATA"))
    assert(Store.load(CAMPAIGN_TEST) == screen.mission)
    assert(not screen.end_button.disabled)

    # Commit a real move using the board's existing authoritative Session.
    screen.board.selected_id = "C01_N1"
    var legal: Dictionary = {"unit_id":"C01_N1","cell":Vector2i(1,3),"kind":"move","target_id":""}
    assert(screen.board._commit_order(legal))
    assert(Store.load(CAMPAIGN_TEST) == screen.mission)
    var moved := false
    for u in screen.board.state["units"]:
        if str(u["id"]) == "C01_N1":
            moved = u["pos"] == Vector2i(1,3)
    assert(moved)
    assert(FileAccess.get_file_as_string(SKIRMISH_TEST) == skirmish_before)
    assert(not screen.board.campaign_locked)
    screen.queue_free()
    await process_frame

    var resumed := Chapter.new()
    resumed.checkpoint_path = CAMPAIGN_TEST
    root.add_child(resumed)
    await process_frame
    assert(resumed.mission["status"] == "active")
    assert(resumed.mission["events_seen"] == ["C01_START"])
    assert(resumed.board.state == resumed.mission["battle"])
    assert(resumed.notice_label.text.contains("reanudado"))
    assert(FileAccess.get_file_as_string(SKIRMISH_TEST) == skirmish_before)

    # Exercise actual turn transitions through Session (without AI moving
    # the markers), and pass the confirmed phases through board signals.
    var setup: Dictionary = resumed.board.state.duplicate(true)
    setup["units"][0]["pos"] = Vector2i(4,2)
    setup["units"][1]["pos"] = Vector2i(5,5)
    var blue: Dictionary = Session.end_turn(setup)
    assert(blue["valid"])
    resumed.board.state = blue["state"]
    resumed.board.tactical_phase_completed.emit(0)
    assert(resumed.mission["status"] == "holding")
    assert(resumed.mission["hold_pending"])
    assert(Store.load(CAMPAIGN_TEST) == resumed.mission)
    var red: Dictionary = Session.end_turn(resumed.board.state)
    assert(red["valid"])
    resumed.board.state = red["state"]
    resumed.board.tactical_phase_completed.emit(1)
    assert(resumed.mission["status"] == "completed")
    assert(resumed.board.campaign_locked)
    assert(Mission.available_unlocks(resumed.mission) == ["G01"])
    assert(resumed.progress_label.text.contains("VICTORIA"))
    assert(resumed.dialogue_label.text.contains("ALIANZA NORTE"))
    assert(resumed.end_button.disabled)
    assert(Store.load(CAMPAIGN_TEST) == resumed.mission)
    assert(FileAccess.get_file_as_string(SKIRMISH_TEST) == skirmish_before)
    resumed.queue_free()
    await process_frame

    var finished := Chapter.new()
    finished.checkpoint_path = CAMPAIGN_TEST
    root.add_child(finished)
    await process_frame
    assert(finished.mission["status"] == "completed")
    assert(finished.board.campaign_locked)
    assert(finished.progress_label.text.contains("VICTORIA"))
    # Explicit replay does not delete the skirmish checkpoint.
    finished._start_fresh()
    assert(finished.mission["status"] == "active")
    assert(finished.mission["events_seen"] == ["C01_START"])
    assert(FileAccess.get_file_as_string(SKIRMISH_TEST) == skirmish_before)
    finished.queue_free()
    await process_frame

    # The main menu must present a live entry point instead of an inert label.
    var menu := Main.new()
    root.add_child(menu)
    await process_frame
    assert(menu.campaign_button != null)
    assert(menu.campaign_button.text.contains("HISTORIA"))
    assert(menu.campaign_button.visible)
    menu.queue_free()
    await process_frame
    _cleanup(CAMPAIGN_TEST)
    _cleanup(SKIRMISH_TEST)
    print("Playable Campaign C01: UI, turn bridge, dialogue, victory and isolated save PASS.")
    quit()
