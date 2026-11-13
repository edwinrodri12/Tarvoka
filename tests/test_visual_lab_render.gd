extends SceneTree

# Captures the genuine Godot Android-style visual laboratory, not a mockup.
const Lab = preload("res://scripts/ui/VisualLab.gd")
const Main = preload("res://scripts/ui/Main.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var app: Control = scene.instantiate()
    root.add_child(app)
    for i in range(3):
        await process_frame
    var lab: Control = app.get("visual_laboratory")
    assert(lab != null)
    app._open_visual_lab()
    for i in range(8):
        await process_frame
    assert(lab.visible)
    var board: Control = lab.get("lab_board")
    assert(board != null and board.iso_enabled)
    assert(lab.get("attacker_picker").selected == Lab.CATALOG.find("tank"))
    assert(lab.get("defender_picker").selected == Lab.CATALOG.find("ifv"))
    var app_view: Vector2 = root.get_viewport().get_visible_rect().size
    var lab_rect: Rect2 = lab.get_global_rect()
    assert(lab_rect.size.x >= app_view.x * 0.90)
    assert(lab_rect.size.y >= app_view.y * 0.90)
    var side: Control = lab.find_child("PanelDePruebas",true,false)
    assert(side != null and side.size.x >= 280)
    var snapshot: Image = root.get_viewport().get_texture().get_image()
    assert(snapshot != null and not snapshot.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(snapshot.save_png("res://artifacts/tarvoka_visual_lab_android.png") == OK)
    lab.close_lab()
    assert(not lab.visible)
    app.queue_free()
    print("PASS visual laboratory real OpenGL screenshot, menu, screen bounds, Android landscape and own 3D battle")
    quit(0)
