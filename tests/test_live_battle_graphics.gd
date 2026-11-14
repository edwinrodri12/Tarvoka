extends SceneTree

# Real Godot/OpenGL integration: screenshots, source geometry, draw quality and
# tactical-state identity are checked against a PLAYABLE modern battle.
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var board: Control = Board.new()
    board.ai_enabled = false
    board.autosave_enabled = false
    board.size = Vector2(1180,720)
    root.add_child(board)
    board.new_game(0,false,false,false,false,true,true,0,0,Vector2i(10,8))
    var original: Dictionary = board.state.duplicate(true)
    board.set_3d_view(true)
    for i in range(14):
        await process_frame
    var visual: TextureRect = board.get_node("Experimental3DTacticalView")
    var layer: Node3D = visual.get("_asset_layer")
    assert(layer != null and layer.name == "ModelosRealesEnPartida")
    # Battle map, not just the web studio, uses V9 authored micro-textures.
    var live_lab: Node3D = visual.get("_lab")
    var surface: MeshInstance3D = live_lab.get("_ground")
    var ground_mat: StandardMaterial3D = surface.mesh.surface_get_material(0) as StandardMaterial3D
    assert(ground_mat != null and ground_mat.albedo_texture != null)
    var counts: Dictionary = board.get_3d_performance_snapshot()
    assert(int(counts.get("3d_visible_units",0)) >= 6)
    assert(int(counts.get("3d_g09_v23",0)) >= 1)
    assert(int(counts.get("3d_headquarters_v13",0)) >= 2)
    assert(int(counts.get("3d_site_models",0)) >= 4)
    assert(int(counts.get("3d_unit_meshes",0)) > 10)
    assert(counts.has("engine_fps") and counts.has("draw_calls_this_frame"))
    assert(board.state == original)

    # Exactly the native V23 armored object, NOT a colored capsule fake.
    var has_real_g09 := false
    for holder in layer.get_children():
        var model: Node = holder.find_child("MallaUnidad_tank",false,false)
        if model != null and bool(model.get_meta("tarvoka_mbt_faction_v23",false)):
            has_real_g09 = true
            break
    assert(has_real_g09)

    board.set_3d_art_quality(0)
    var economy_view: Dictionary = board.get_3d_performance_snapshot()
    assert(int(economy_view.get("3d_g09_v23",99)) == 0)
    assert(int(economy_view.get("3d_visible_units",0)) >= 6)
    board.set_3d_art_quality(2)
    counts = board.get_3d_performance_snapshot()
    assert(int(counts.get("3d_g09_v23",0)) >= 1)
    assert(board.state == original)

    # Capture the EXACT playable battle and physical 3D assets for QA.
    var viewport: SubViewport = visual.get("_viewport")
    assert(viewport != null)
    for i in range(8):
        await process_frame
    var screenshot: Image = viewport.get_texture().get_image()
    assert(screenshot != null and not screenshot.is_empty())
    var folder: String = ProjectSettings.globalize_path(
        "res://build/battle3d-previews")
    assert(DirAccess.make_dir_recursive_absolute(folder) == OK)
    assert(screenshot.save_png(folder+"/battle-real-graphics.png") == OK)

    board.set_3d_view(false)
    assert(board.state == original)
    board.queue_free()
    print("PASS live battle graphics: real G09 V23, HQ V13, role prototypes, terrain, FPS counter and zero battle-state mutations")
    quit(0)
