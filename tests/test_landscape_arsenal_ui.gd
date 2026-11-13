extends SceneTree

const Style = preload("res://scripts/ui/VisualStyle.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Poses = preload("res://scripts/ui/UnitSpriteAtlas.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene: PackedScene = load("res://scenes/Main.tscn")
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    await process_frame
    var starting: Dictionary = screen.board.state.duplicate(true)
    screen._show_home_menu()

    screen._open_arsenal_from_home()
    var gallery: Control = screen.unit_art_gallery
    assert(gallery.visible and not screen.home_menu.visible)
    assert(gallery.get_class() != "AcceptDialog")
    assert(gallery.role_buttons.size() == Roles.ORDER.size() + Arsenal.ORDER.size())
    assert(gallery.entries.get_child_count() == gallery.role_buttons.size())
    assert(not gallery.content_rail.vertical)
    assert(gallery.unit_preview != null)
    assert(gallery.faction_picker.item_count == 8)
    assert(gallery.pose_picker.item_count == 4)
    assert(gallery.heading_picker.item_count == 9)

    var role: String = str(Arsenal.ORDER[0])
    gallery._select_role(role)
    assert(gallery.selected_role == role)
    assert(gallery.unit_name.text == Roles.label(role))
    assert(gallery.unit_preview.role == role)
    gallery.faction_picker.select(7)
    gallery._select_faction(7)
    assert(gallery.selected_faction == 7)
    assert(gallery.unit_preview.faction_tint == Style.faction_color(7))
    gallery.pose_picker.select(2)
    gallery._select_pose(2)
    assert(gallery.unit_preview.pose == str(Poses.POSES[2]))
    gallery.heading_picker.select(3)
    gallery._select_heading(3)
    assert(gallery.unit_preview.heading == Vector2.RIGHT)
    assert(screen.board.state == starting)

    # Arsenal from Home returns there; from battle returns to the map.
    gallery.close_requested.emit()
    assert(not gallery.visible and screen.home_menu.visible)
    screen.home_menu.hide()
    screen._open_unit_art_gallery()
    assert(gallery.visible)
    gallery.close_requested.emit()
    assert(not gallery.visible and not screen.home_menu.visible)
    assert(screen.board.state == starting)

    screen.queue_free()
    print("PASS landscape arsenal: fullscreen themed unit catalog, 8 faction colors, four poses, nine headings and save-safe navigation")
    quit(0)
