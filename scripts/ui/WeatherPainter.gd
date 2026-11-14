extends RefCounted
class_name TarvokaWeatherPainter

# Cheap deterministic precipitation, drawn on observed tiles only by the
# board renderers. No particle nodes, timers or simulation-side state.
const Weather = preload("res://scripts/core/Weather.gd")
const RAIN_TINT := Color(0.64,0.79,0.94,0.64)
const SNOW_TINT := Color(0.96,0.98,1.0,0.87)

static func draw_classic(canvas: CanvasItem, cell: Vector2i, pos: Vector2,
        tile: float, weather: String, battery_saver: bool = false) -> void:
    if weather == Weather.CLEAR or battery_saver or tile < 13.0:
        return
    var code: int = (cell.x*17 + cell.y*31) % 11
    if weather == Weather.RAIN:
        for i in range(2):
            var cx: float = 0.28+float((code+i*5)%10)*0.045
            var cy: float = 0.16+float((code+i*3)%7)*0.095
            var begin: Vector2 = pos + Vector2(cx,cy)*tile
            canvas.draw_line(begin,begin+Vector2(-tile*0.13,tile*0.22),
                RAIN_TINT,maxf(0.8,tile*0.020))
    elif weather == Weather.SNOW:
        for i in range(3):
            var px: float = 0.20+float((code+i*3)%10)*0.054
            var py: float = 0.15+float((code+i*4)%9)*0.076
            canvas.draw_circle(pos+Vector2(px,py)*tile,
                maxf(1.0,tile*0.023),SNOW_TINT)

static func draw_iso(canvas: CanvasItem, cell: Vector2i, center: Vector2,
        half_width: float, weather: String, battery_saver: bool = false) -> void:
    if weather == Weather.CLEAR or battery_saver or half_width < 12.0:
        return
    var code: int = (cell.x*17 + cell.y*31) % 11
    if weather == Weather.RAIN:
        for i in range(2):
            var x: float = (float((code+i*4)%8)-3.5)*half_width*0.14
            var y: float = (float((code+i*2)%7)-3.0)*half_width*0.055
            var start: Vector2 = center+Vector2(x,y)
            canvas.draw_line(start,start+Vector2(-half_width*0.13,half_width*0.17),
                RAIN_TINT,maxf(0.8,half_width*0.018))
    elif weather == Weather.SNOW:
        for i in range(3):
            var x: float = (float((code+i*3)%9)-4.0)*half_width*0.13
            var y: float = (float((code+i*2)%7)-3.0)*half_width*0.045
            canvas.draw_circle(center+Vector2(x,y),
                maxf(0.9,half_width*0.022),SNOW_TINT)
