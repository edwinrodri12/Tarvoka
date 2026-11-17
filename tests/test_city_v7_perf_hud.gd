extends SceneTree

# Test the REAL gameplay 3D view, including its on-device diagnostic button.
# This is a Godot engine acceptance test, not an Android phone FPS claim.
const Session=preload("res://scripts/core/BattleSession.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Roles=preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size=Vector2i(960,540)
    var main: Control=load("res://scenes/Main.tscn").instantiate()
    root.add_child(main)
    await process_frame
    var board: Control=main.board
    board.autosave_enabled=false
    board.ai_enabled=false
    board.new_game(0,false,false,false,true,true)
    main._continue_from_home()
    var untouched: Dictionary=board.state.duplicate(true)
    main._open_battle_3d()
    var viewer=main.battle_3d_view
    assert(viewer!=null and viewer.visible)
    assert(viewer._scene!=null)
    var probe=viewer.city_perf_probe
    assert(probe!=null and not probe.visible)
    var fps_button: Button=null
    for child in viewer._three_d_shortcuts.get_children():
        if child is Button and child.text=="FPS":
            fps_button=child
            break
    assert(fps_button!=null and fps_button.visible)
    fps_button.pressed.emit()
    assert(probe.visible and probe.is_processing())
    assert(probe.scene_root==viewer._scene)
    var first: Dictionary=probe.snapshot()
    assert(int(first["cities"])==4)
    assert(int(first["city_lod2"])==4)
    assert(first["sample_count"]>=0)
    for _frame in range(12):
        await process_frame
    probe.refresh_once()
    var before: Dictionary=probe.snapshot()
    assert(str(before["source"]).contains("Godot Engine FPS"))
    assert(int(before["sample_count"])>0)
    assert(int(before["city_meshes"])>0)
    assert(probe.readout.text.contains("FPS"))
    assert(probe.readout.text.contains("LOD"))
    assert(board.state==untouched)

    # Touch-free zoom uses the real viewport camera and V6 LOD driver.
    var driver=viewer._scene.get_node_or_null(
        "CiudadesCivilesV6_LOD_Camara")
    assert(driver!=null)
    viewer._camera_size=4.0
    viewer._refresh_camera()
    # Offscreen CI containers may give this Control a tiny viewport during
    # the first frame. Exercise the actual engine driver using a known
    # 640x360 mobile render target instead of assuming layout settled.
    var mobile_height: float=maxf(360.0,float(viewer.preview.size.y))
    print("CITY V7 HUD viewport=",viewer.preview.size,
        " presentation=",viewer.holder.size,
        " test_pixels=",mobile_height)
    assert(driver.update_now(viewer.camera,mobile_height)>0)
    probe.refresh_once()
    var near: Dictionary=probe.snapshot()
    assert(int(near["city_lod0"])>0)
    assert(int(near["city_meshes"])>int(before["city_meshes"]))
    viewer._camera_size=100.0
    viewer._refresh_camera()
    assert(driver.update_now(viewer.camera,mobile_height)>0)
    probe.refresh_once()
    var far: Dictionary=probe.snapshot()
    assert(int(far["city_lod2"])==4)
    assert(int(far["city_meshes"])==int(before["city_meshes"]))
    assert(int(far["city_lod_changes"])>0)
    assert(board.state==untouched)

    # A second press disables sampling and restores an unobstructed HUD.
    fps_button.pressed.emit()
    assert(not probe.visible and not probe.is_processing())
    fps_button.pressed.emit()
    assert(probe.visible)
    viewer.close_view()
    assert(not viewer.visible)
    assert(not probe.visible and not probe.is_processing())
    assert(probe.scene_root==null)
    assert(board.state==untouched)
    main.queue_free()
    await process_frame
    print("PASS TARVOKA CITY V7 REAL 3D HUD: FPS toggle, meshes, distance LOD, mobile viewport and immutable gameplay")
    quit(0)
