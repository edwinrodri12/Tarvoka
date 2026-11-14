extends SceneTree

# Real OpenGL images of each 3D tank condition, not concept sketches.
const Inspector = preload("res://scripts/ui/Unit3DInspector.gd")
const Damage = preload("res://scripts/ui/TankDamage3D.gd")
const WIDTH := 320
const HEIGHT := 245

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var inspector = Inspector.new()
    root.add_child(inspector)
    inspector.show_role("tank")
    inspector.open_viewer()
    for i in range(5):
        await process_frame
    var sheet := Image.create(WIDTH*5,HEIGHT,false,Image.FORMAT_RGBA8)
    sheet.fill(Color("#122430"))
    var signatures: Dictionary = {}
    for stage in range(5):
        inspector.set_damage_stage(stage)
        for tick in range(4):
            await process_frame
        assert(inspector.tank_damage_picker.selected == stage)
        assert(Damage.current_stage(inspector.model_root) == stage)
        var image: Image = inspector.preview.get_texture().get_image()
        assert(image != null and not image.is_empty())
        assert(image.get_width() >= 250 and image.get_height() >= 170)
        image.resize(WIDTH,HEIGHT,Image.INTERPOLATE_LANCZOS)
        var key: int = hash(image.get_data())
        assert(not signatures.has(key))
        signatures[key] = stage
        sheet.blit_rect(image,Rect2i(Vector2i.ZERO,Vector2i(WIDTH,HEIGHT)),
            Vector2i(stage*WIDTH,0))
    assert(signatures.size() == 5)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(sheet.save_png("res://artifacts/tarvoka_tank_5_destruction_stages.png") == OK)
    inspector.set_damage_stage(4)
    for frame in range(3):
        await process_frame
    var screen: Image = root.get_viewport().get_texture().get_image()
    assert(screen != null and not screen.is_empty())
    assert(screen.save_png("res://artifacts/tarvoka_damage_inspector_android.png") == OK)
    inspector.hide()
    inspector.queue_free()
    print("PASS 5 actual Godot 3D tank damage stages, distinct frames and Android destruction viewer screenshot")
    quit(0)
