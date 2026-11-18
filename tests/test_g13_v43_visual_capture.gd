extends SceneTree

# G13 V43: capture REAL Godot 4.3 frames from the shared 3D Studio.
# DESIGN INSPECTION ONLY, not gameplay/Android stress or a render mockup.
# Produces eight hero angles, an exact V41 comparison, and two tactical
# views. The screenshots are GitHub Actions artifacts, not an approval.
const V42_FLAG := "tarvoka_g13_v42_fender_tip_continuity"
const FENDER := "G13_V40_CurvedOuterFenders"
const OUTPUT := "res://build/qa/g13-v43"
var failures: int = 0
var frames: Array[Dictionary] = []

func _check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("G13 V43 visual capture: " + reason)

func _initialize() -> void:
    call_deferred("_run")

func _inspect_model(studio: Control, lod: int) -> bool:
    var model := studio.get("model_root") as Node3D
    if model == null:
        _check(false, "no G13 model root in LOD%d" % lod)
        return false
    var flag: bool = bool(model.get_meta(V42_FLAG, false))
    _check(flag, "real V42 native silhouette missing in LOD%d" % lod)
    _check(int(model.get_meta("tarvoka_g13_v42_added_draw_nodes", -1)) == 0,
        "V42 must not introduce extra draw nodes in LOD%d" % lod)
    _check(bool(model.get_meta("tarvoka_g13_v1_high_detail", lod == 13)) ==
        (lod == 13), "incorrect G13 detail tier")
    var mesh := model.find_child(FENDER, true, false) as MultiMeshInstance3D
    _check(mesh != null, "four-wheel sculpt missing")
    if mesh != null:
        _check(mesh.multimesh != null and
            mesh.multimesh.instance_count == 2,
            "two axle instances required for four curved guards")
        _check(mesh.visible, "sculpted wheel guards are not visible")
    return flag and mesh != null

func _capture(studio: Control, filename: String, lod: int,
        yaw: float, tilt: float) -> void:
    # Same real 3D camera, lighting, materials and scene as the public
    # viewer; no duplicated geometry or artificial silhouette drawings.
    studio.call("_g13_v41_view", yaw, tilt)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = root.get_texture().get_image()
    var ok: bool = img != null and img.get_width() >= 960 and (
        img.get_height() >= 540)
    _check(ok, "native frame unavailable for " + filename)
    if not ok:
        return
    var png_path: String = ProjectSettings.globalize_path(
        OUTPUT.path_join(filename + ".png"))
    var status: Error = img.save_png(png_path)
    _check(status == OK, "PNG save failed for " + filename)
    if status == OK:
        frames.append({
            "file": filename + ".png", "lod": lod,
            "yaw": yaw, "tilt": tilt,
            "width": img.get_width(), "height": img.get_height()
        })
        print("G13 V43 REAL FRAME: " + png_path)

func _run() -> void:
    var packed := load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(packed != null, "native studio scene was not found")
    if packed == null:
        quit(1)
        return
    var studio := packed.instantiate() as Control
    _check(studio != null, "native studio failed to instantiate")
    if studio == null:
        quit(1)
        return
    root.size = Vector2i(1280, 720)
    root.add_child(studio)
    await process_frame
    studio.call("_display_role", "aa_mobile")
    studio.call("_studio_select_tab", 0)
    await process_frame
    if not _inspect_model(studio, 13):
        studio.queue_free()
        quit(1)
        return
    var directory: String = ProjectSettings.globalize_path(OUTPUT)
    _check(DirAccess.make_dir_recursive_absolute(directory) == OK,
        "cannot create output for actual Godot renders")
    var views: Array[Dictionary] = [
        {"name": "hero-front", "yaw": 0.0, "tilt": 0.0},
        {"name": "hero-front-three-quarter", "yaw": 38.0, "tilt": 0.0},
        {"name": "hero-left", "yaw": 90.0, "tilt": 0.0},
        {"name": "hero-rear-three-quarter", "yaw": 145.0, "tilt": 0.0},
        {"name": "hero-rear", "yaw": 180.0, "tilt": 0.0},
        {"name": "hero-right", "yaw": 270.0, "tilt": 0.0},
        {"name": "hero-roof", "yaw": 42.0, "tilt": -55.0},
        {"name": "hero-underside", "yaw": 132.0, "tilt": 58.0}
    ]
    for view in views:
        await _capture(studio, "g13-v43-" + str(view["name"]), 13,
            float(view["yaw"]), float(view["tilt"]))

    # Real same-camera comparison: V41 has the prior termination geometry.
    studio.call("_g13_v42_compare", false)
    await _capture(studio, "g13-v43-comparison-v41-left", 13, 90.0, 0.0)
    studio.call("_g13_v42_compare", true)

    # The tactical version uses a distinct native LOD8 tree. Keep two
    # important 3/4 and side evidence frames alongside the hero set.
    studio.call("_g13_show_tactical_lod", 8)
    await process_frame
    if _inspect_model(studio, 8):
        await _capture(studio, "g13-v43-tactical-left", 8, 90.0, 0.0)
        await _capture(studio, "g13-v43-tactical-three-quarter", 8, 38.0, 0.0)

    var report := {
        "subject": "G13 V43 native 360 visual design inspection",
        "rendered_by": "Godot 4.3 X11 GL compatibility",
        "not_approved": true,
        "no_gameplay_changes": true,
        "frames": frames,
        "failures": failures
    }
    var json_path: String = directory.path_join("g13-v43-manifest.json")
    var manifest := FileAccess.open(json_path, FileAccess.WRITE)
    _check(manifest != null, "manifest output unavailable")
    if manifest != null:
        manifest.store_string(JSON.stringify(report, "  "))
        manifest.close()
    studio.queue_free()
    await process_frame
    _check(frames.size() == 11, "expected 11 actual captured frames")
    if failures > 0:
        push_error("G13 V43 capture failed (%d issues)" % failures)
        quit(1)
        return
    print("PASS G13 V43 NATIVE VISUAL CAPTURE: 8 hero, 1 V41 and 2 tactical frames")
    quit(0)
