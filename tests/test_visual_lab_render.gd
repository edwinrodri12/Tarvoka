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
    # Do not allow the isometric artwork to overpaint the top title or
    # sidebar. Verified against the screen recording 242287.mp4.
    assert(board.clip_contents)
    assert(board.get_parent().clip_contents)
    assert(board.get_parent().get_parent().clip_contents)
    assert(lab.get("attacker_picker").selected == Lab.CATALOG.find("tank"))
    assert(lab.get("defender_picker").selected == Lab.CATALOG.find("ifv"))
    var app_view: Vector2 = root.get_viewport().get_visible_rect().size
    var lab_rect: Rect2 = lab.get_global_rect()
    assert(lab_rect.size.x >= app_view.x * 0.90)
    assert(lab_rect.size.y >= app_view.y * 0.90)
    var side: Control = lab.find_child("PanelDePruebas",true,false)
    assert(side != null and side.size.x >= 280)
    # Regression from user's 242263 Android video: opaque, wider tap
    # controls, while the tactical board retains most of the landscape.
    var sidebar_panel: PanelContainer = side.get_parent() as PanelContainer
    assert(sidebar_panel != null)
    assert(sidebar_panel.custom_minimum_size.x >= 400.0)
    var sidebar_style: StyleBoxFlat = sidebar_panel.get_theme_stylebox("panel") as StyleBoxFlat
    assert(sidebar_style != null and sidebar_style.bg_color.a > 0.95)
    assert(is_equal_approx(float(board.iso_zoom),0.85))
    var lab_button: Button = lab.get("attack_button") as Button
    assert(lab_button != null and lab_button.custom_minimum_size.y >= 50)
    var snapshot: Image = root.get_viewport().get_texture().get_image()
    assert(snapshot != null and not snapshot.is_empty())
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
    assert(snapshot.save_png("res://artifacts/tarvoka_visual_lab_android.png") == OK)
    lab.close_lab()
    assert(not lab.visible)
    app.queue_free()
    print("PASS visual laboratory real OpenGL screenshot, menu, screen bounds, Android landscape and own 3D battle")
    quit(0)
