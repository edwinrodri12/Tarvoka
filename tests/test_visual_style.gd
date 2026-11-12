extends SceneTree

const Style = preload("res://scripts/ui/VisualStyle.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Style.FACTIONS.size() == 8)
    var keys := {}
    var colors := {}
    for i in range(8):
        var info: Dictionary = Style.faction_info(i)
        assert(not info.is_empty())
        assert(not keys.has(info["key"]))
        assert(not colors.has(info["color"]))
        keys[info["key"]] = true
        colors[info["color"]] = true
        assert(Style.emblem_path(i).ends_with("%s.png" % info["key"]))
        assert(Style.faction_color(i).a == 1.0)
    assert(Style.faction_info(-1).is_empty())
    assert(Style.faction_info(8).is_empty())
    assert(Style.emblem_path(8).is_empty())
    assert(Style.emblem_texture(8) == null)
    assert(Style.FACTIONS[0]["name"] == "Alianza Norte")
    assert(Style.FACTIONS[1]["name"] == "Pacto Escarlata")
    assert(Style.FACTIONS[7]["name"] == "Orden Ónix")
    assert(Style.movement_fill().b > Style.movement_fill().r)
    assert(Style.attack_fill().r > Style.attack_fill().b)
    assert(Style.terrain_color("forest", 0, 0) != Style.terrain_color("forest", 1, 0))
    assert(Style.terrain_color("plain", 0, 0) != Style.terrain_color("water", 0, 0))
    var board = Board.new()
    board.ai_enabled = false
    board.size = Vector2(800, 640)
    root.add_child(board)
    var before: Dictionary = board.state.duplicate(true)
    board.queue_redraw()
    await process_frame
    assert(board.state == before)
    board.queue_free()
    var scene: PackedScene = load("res://scenes/Main.tscn")
    assert(scene != null)
    var screen: Control = scene.instantiate()
    root.add_child(screen)
    var gallery: AcceptDialog = screen.get("faction_gallery")
    var button: Button = screen.get("faction_gallery_button")
    assert(gallery != null and button != null)
    var cards: VBoxContainer = gallery.get("cards")
    assert(cards != null and cards.get_child_count() == 8)
    assert(button.text.contains("ocho facciones"))
    screen.queue_free()
    print("PASS visual style: eight locked faction identities, safe palette and Android gallery")
    quit(0)
