extends SceneTree

const Atlas = preload("res://scripts/ui/UnitSpriteAtlas.gd")
const Art = preload("res://scripts/ui/UnitArt.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Board = preload("res://scripts/ui/TouchBoard.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Atlas.POSES == ["idle","move","attack","damaged"])
    assert(Atlas.role_order().size()==32)
    assert(Atlas.dimension() == Vector2i(768,1536))
    assert(Atlas.CELL==96)
    assert(Art.role_count()==32)
    assert(Atlas.region("not_a_role","idle")==Rect2i())
    assert(Atlas.region("tank","invalid")==Rect2i())
    assert(Atlas.svg_source("tank","invalid").is_empty())
    assert(Atlas.svg_source("unknown","idle").is_empty())
    var image: Image = Atlas.image_copy()
    assert(image!=null and not image.is_empty())
    assert(image.get_size()==Vector2i(768,1536))
    var used: Dictionary = {}
    var drawn_frames := 0
    for role in Roles.ORDER + Arsenal.ORDER:
        for pose in Atlas.POSES:
            var key: String = "%s/%s" % [role,pose]
            var rect: Rect2i = Atlas.region(str(role),str(pose))
            assert(rect.size==Vector2i(96,96))
            assert(rect.position.x>=0 and rect.position.y>=0)
            assert(rect.end.x<=image.get_width() and rect.end.y<=image.get_height())
            assert(not used.has(rect.position))
            used[rect.position]=key
            assert(Atlas.svg_source(str(role),str(pose)).contains("<svg"))
            var visible_pixels := 0
            for yy in range(16,88,8):
                for xx in range(16,80,8):
                    if image.get_pixel(rect.position.x+xx,rect.position.y+yy).a>0.1:
                        visible_pixels+=1
            assert(visible_pixels>=5) # Each role really produced image pixels.
            assert(image.get_pixel(rect.position.x+1,rect.position.y+1).a<0.01)
            var frame: Texture2D = Atlas.frame_texture(str(role),str(pose))
            assert(frame!=null and frame.get_size()==Vector2(96,96))
            drawn_frames+=1
        assert(Atlas.svg_source(str(role),"idle")!=Atlas.svg_source(str(role),"move"))
        assert(Atlas.svg_source(str(role),"idle")!=Atlas.svg_source(str(role),"damaged"))
    assert(drawn_frames==128 and used.size()==128)
    assert(Atlas.frame_texture("unknown","idle")==null)
    assert(Atlas.frame_texture("tank","invalid")==null)

    # Sprite generation cannot modify the same game state shared with rules.
    var board = Board.new()
    board.size=Vector2(800,640)
    board.ai_enabled=false
    root.add_child(board)
    board.new_game(0,true,true,false,true,true,true)
    board.set_isometric(true)
    var snapshot: Dictionary=board.state.duplicate(true)
    board.queue_redraw()
    await process_frame
    assert(board.state==snapshot)
    assert(Atlas.frame_texture("tank","idle") != null)
    for faction in range(8):
        assert(VisualStyle.faction_color(faction).a > 0.99)
    board.queue_free()
    print("PASS sprite atlas: 32 roles, 4 nonempty poses, 128 unique regions, Android tint & tactics unchanged")
    quit(0)
