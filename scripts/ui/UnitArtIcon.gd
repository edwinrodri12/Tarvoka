extends Control
class_name TarvokaUnitArtIcon

const UnitArt = preload("res://scripts/ui/UnitArt.gd")
const UnitSprites = preload("res://scripts/ui/UnitSpriteAtlas.gd")
var role: String = "line"
var faction_tint := Color("#2375F3")
var phase := 0.0
var pose := "idle"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(70,70)

func configure(next_role: String, next_tint: Color) -> void:
    role = next_role
    faction_tint = next_tint
    queue_redraw()

func set_pose(next_pose: String) -> void:
    if next_pose in UnitSprites.POSES:
        pose = next_pose
        queue_redraw()

func _draw() -> void:
    var edge: float = minf(size.x,size.y)
    if edge <= 0:
        return
    var center := size*0.5+Vector2(0,edge*0.05)
    draw_circle(center+Vector2(0,edge*0.18),edge*0.35,Color("#102330"))
    var sprite: Texture2D = UnitSprites.frame_texture(role,pose)
    if sprite != null:
        var sprite_side: float = edge*0.82
        draw_texture_rect(sprite,Rect2(center-Vector2(sprite_side*0.5,sprite_side*0.55),
            Vector2.ONE*sprite_side),false,faction_tint)
    else:
        UnitArt.draw_unit(self,role,center,edge*0.28,faction_tint,phase)
