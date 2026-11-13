extends SceneTree

# Actual GL Compatibility 3D screenshot for review WITHOUT an Android APK.
# This does not replace the 2D tactical board or fake a game screenshot.
const WIDTH := 1600
const HEIGHT := 960
const OUTPUT := "res://build/map3d-previews"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var path := ProjectSettings.globalize_path(OUTPUT)
    if DirAccess.make_dir_recursive_absolute(path) != OK:
        push_error("Cannot create the native 3D preview directory")
        quit(1)
        return
    root.size = Vector2i(WIDTH,HEIGHT)
    var viewport := SubViewport.new()
    viewport.name = "Terrain3DFrame"
    viewport.size = Vector2i(WIDTH,HEIGHT)
    viewport.world_3d = World3D.new()
    viewport.transparent_bg = false
    viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var lab: Node3D = load("res://scenes/Terrain3DLab.tscn").instantiate()
    viewport.add_child(lab)
    for quality in [6,3]:
        lab.call("set_quality",quality)
        # Let camera, materials, lights and render thread settle.
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var image: Image = viewport.get_texture().get_image()
        if image.is_empty() or image.get_width() != WIDTH or (
                image.get_height() != HEIGHT):
            push_error("Invalid native 3D Godot framebuffer")
            viewport.queue_free()
            quit(1)
            return
        var filename := "terrain3d-full.png" if quality == 6 else (
            "terrain3d-medium.png")
        var save_error: Error = image.save_png(path.path_join(filename))
        if save_error != OK:
            push_error("Could not save native 3D view: "+str(save_error))
            viewport.queue_free()
            quit(1)
            return
        print("PASS exported native 3D terrain: "+filename)
    viewport.queue_free()
    quit(0)
