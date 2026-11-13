extends Control
class_name TarvokaGameUiBackdrop

# Procedurally drawn ornamental HUD background, not a copied concept image.
# Light 2D line work rather than a GPU-heavy shader or animated texture.
# Available on every platform without external image files.
var mode := "home"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(queue_redraw)
    queue_redraw()

func _draw() -> void:
    if size.x <= 0 or size.y <= 0:
        return
    var top: Color = Color("#081421")
    var bottom: Color = Color("#132E42")
    var bands := 24
    for index in range(bands):
        var factor: float = float(index)/float(bands-1)
        var tint: Color = top.lerp(bottom,factor)
        var y: float = size.y * float(index)/float(bands)
        draw_rect(Rect2(0,y,size.x,size.y/float(bands)+2.0),tint)

    # Tactical cartography. Extremely low contrast to protect readability.
    var grid_gap := 52.0
    var grid_color := Color(0.31,0.60,0.73,0.105)
    for n in range(int(size.x/grid_gap)+1):
        var x: float = float(n)*grid_gap
        draw_line(Vector2(x,0),Vector2(x,size.y),grid_color,1.0)
    for n in range(int(size.y/grid_gap)+1):
        var y: float = float(n)*grid_gap
        draw_line(Vector2(0,y),Vector2(size.x,y),grid_color,1.0)

    # Original radar/target geometry; not gameplay intelligence.
    var center := Vector2(size.x*0.84,size.y*0.24) if mode == "home" else Vector2(size.x*0.91,size.y*0.13)
    var radius: float = minf(size.x,size.y)*0.17
    var line_color := Color(0.78,0.72,0.50,0.21)
    for scale in [0.45,0.72,1.0]:
        draw_arc(center,radius*scale,0.0,TAU,56,line_color,1.4,true)
    draw_line(center-Vector2(radius*1.4,0),center+Vector2(radius*1.4,0),line_color,1.0)
    draw_line(center-Vector2(0,radius*1.4),center+Vector2(0,radius*1.4),line_color,1.0)
    var trim := Color(0.91,0.78,0.48,0.55)
    draw_line(Vector2(0,8),Vector2(size.x*0.38,8),trim,2.0)
    draw_line(Vector2(8,0),Vector2(8,size.y*0.26),trim,2.0)
    var bottom_line := size.y-10
    draw_line(Vector2(size.x*0.55,bottom_line),Vector2(size.x-12,bottom_line),Color(0.35,0.67,0.82,0.32),2)
