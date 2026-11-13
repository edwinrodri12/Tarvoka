extends SceneTree

# Capture the ACTUAL TouchBoard with native 3D rendering enabled, then the
# exact same battle with its existing 2.5D fallback. No mocked UI or models.
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const OUTPUT := "res://build/battle3d-previews"
const WIDTH := 1600
const HEIGHT := 960

func _initialize() -> void:
    call_deferred("_capture")

func _save_frame(filename: String) -> bool:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var screenshot: Image = root.get_texture().get_image()
    if screenshot.is_empty() or screenshot.get_width() != WIDTH or (
            screenshot.get_height() != HEIGHT):
        push_error("Invalid battle screenshot: "+filename)
        return false
    var result: Error = screenshot.save_png(
        ProjectSettings.globalize_path(OUTPUT).path_join(filename))
    if result != OK:
        push_error("Failed to save "+filename+" : "+str(result))
        return false
    print("PASS battle view preview: "+filename)
    return true

func _capture() -> void:
    if DirAccess.make_dir_recursive_absolute(
            ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("Unable to create battle screenshot directory")
        quit(1)
        return
    root.size = Vector2i(WIDTH,HEIGHT)
    var board := Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(WIDTH,HEIGHT)
    root.add_child(board)
    board.new_game(Scenarios.RANDOM_SCENARIO_ID,true,false,true,true,
        true,true,0,661233,Vector2i(24,18))
    board.set_isometric(true)
    var snapshot: Dictionary = board.state.duplicate(true)
    for unit in board.state.get("units",[]):
        if int(unit.get("faction",-1)) == 0 and (
                int(unit.get("hp",0)) > 0):
            board.selected_id = str(unit.get("id",""))
            break
    board.set_3d_view(true)
    board.reset_view_camera()
    if not await _save_frame("battle-native-3d.png"):
        board.queue_free()
        quit(1)
        return
    assert(board.state == snapshot)
    board.set_3d_view(false)
    assert(board.iso_enabled)
    board.reset_view_camera()
    board.queue_redraw()
    if not await _save_frame("battle-2d-fallback.png"):
        board.queue_free()
        quit(1)
        return
    assert(board.state == snapshot)
    board.queue_free()
    quit(0)
