extends SceneTree

const Art = preload("res://scripts/ui/UnitArt.gd")
const World = preload("res://scripts/ui/WorldArt.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")
const Gallery = preload("res://scripts/ui/UnitArtGallery.gd")
const Iso = preload("res://scripts/ui/IsoProjection.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var all_roles: Array = Roles.ORDER.duplicate()
    all_roles.append_array(Arsenal.ORDER)
    assert(all_roles.size() == 32)
    assert(Art.role_count() == 32)
    var fingerprints := {}
    for role in all_roles:
        var key: String = str(role)
        assert(Roles.valid(key))
        assert(Art.has_role(key))
        var spec: Array = Art.design(key)
        assert(spec.size() == 2)
        var token := "%s/%s" % [spec[0],spec[1]]
        assert(not fingerprints.has(token))
        fingerprints[token] = true
    assert(fingerprints.size() == 32)
    assert(not Art.has_role("unknown_design"))
    assert(Art.design("unknown_design").is_empty())
    assert(World.SITE_KINDS.size() == 7)
    for kind in ["city","factory","armor_plant","artillery_depot","drone_center","airbase","shipyard"]:
        assert(World.supports_site(kind))
    assert(not World.supports_site("future_building"))

    var gallery = Gallery.new()
    root.add_child(gallery)
    var entries: VBoxContainer = gallery.get("entries")
    assert(entries != null and entries.get_child_count() == 32)
    for i in range(32):
        var row: HBoxContainer = entries.get_child(i)
        var icon: Control = row.get_child(0)
        assert(str(icon.get("role")) == str(all_roles[i]))
        assert(icon.has_method("configure"))
        icon.size = Vector2(78,72)
        icon.queue_redraw()
    await process_frame # Actually executes the 32 vector silhouettes in Godot.
    gallery.queue_free()

    var board = Board.new()
    board.size = Vector2(800,640)
    board.ai_enabled = false
    root.add_child(board)
    board.new_game(0,true,true,true,true,true,true)
    board.set_isometric(true)
    var original: Dictionary = board.state.duplicate(true)
    board.queue_redraw()
    await process_frame # Actually renders environment, overlays and 6 modern units.
    assert(board.state == original)
    # Changing presentation does not mutate the save/turn state.
    board.change_iso_zoom(1)
    board._process(0.12)
    assert(board.state == original)

    # Interpolation follows actual units but never changes a position in rules.
    var blue_id: String = str(board.state["units"][0]["id"])
    var before: Dictionary = board.state.duplicate(true)
    var after: Dictionary = before.duplicate(true)
    after["units"][0]["pos"] = Vector2i(2,2)
    board._record_move_effect(before,after,blue_id)
    assert(board.motion_effects.size() == 1)
    assert(board.state == original)
    board._process(0.33)
    assert(board.motion_effects.is_empty())
    assert(board.state == original)
    # Under fog, a hidden enemy move must not create a visual trail.
    var red: Dictionary = {}
    for unit in before["units"]:
        if int(unit["faction"]) == 1:
            red = unit
            break
    assert(not red.is_empty())
    var enemy_id: String = str(red["id"])
    var obscured_after: Dictionary = before.duplicate(true)
    for unit in obscured_after["units"]:
        if str(unit["id"]) == enemy_id:
            unit["pos"] = Vector2i(7,0)
    board._record_move_effect(before,obscured_after,enemy_id)
    assert(board.motion_effects.is_empty())

    # Verify the gallery is available in the real Android main scene.
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var ui: Button = screen.get("unit_art_gallery_button")
    var popup: AcceptDialog = screen.get("unit_art_gallery")
    assert(ui != null and popup != null)
    assert(ui.text.contains("32 unidades"))
    var rows: VBoxContainer = popup.get("entries")
    assert(rows.get_child_count() == 32)
    screen.queue_free()
    board.queue_free()
    print("PASS 32 unique art silhouettes, seven structures, realtime rendering, fog-safe motion and Android gallery")
    quit(0)
