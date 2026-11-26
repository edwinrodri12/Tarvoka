extends Control
class_name TarvokaBattleWeatherOverlay3D

# Screen-space precipitation, independent of terrain, units and fog.
# Dust is decorative in clear desert battles, not a new weather rule.
const Weather = preload("res://scripts/core/Weather.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const MAX_PARTICLES := 64
const TICK := 1.0/15.0
var mode: String = "clear"
var phase: float = 0.0
var elapsed: float = 0.0
var active_count: int = 0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hide()

static func mode_for(state: Dictionary) -> String:
    var weather: String = Weather.from_state(state)
    if weather==Weather.CLEAR and Biomes.from_state(state)==Biomes.DESERT:
        return "dust"
    return weather

func configure(state: Dictionary, conserving: bool) -> void:
    var next: String = "clear" if conserving else mode_for(state)
    if next!=mode:
        mode = next
        phase = 0.0
        elapsed = 0.0
        active_count = 0
        visible = mode!="clear"
        queue_redraw()

func advance(delta: float) -> void:
    if not visible or mode=="clear":
        return
    elapsed += maxf(delta,0.0)
    if elapsed<TICK:
        return
    phase = fposmod(phase+elapsed,120.0)
    elapsed = 0.0
    queue_redraw()

func reset() -> void:
    mode = "clear"
    phase = 0.0
    elapsed = 0.0
    active_count = 0
    hide()
    queue_redraw()

func _draw() -> void:
    active_count = 0
    if mode=="clear" or size.x<1.0 or size.y<1.0:
        return
    # Bounded work on all screen and map sizes. Use deterministic trajectories
    # without sampling hidden world geometry or using simulation RNG.
    var density: int = clampi(roundi(size.x*size.y/14000.0),12,MAX_PARTICLES)
    var tint := Color(0.52,0.69,0.85,0.035)
    if mode=="snow":
        tint = Color(0.83,0.91,1.0,0.045)
    elif mode=="dust":
        tint = Color(0.84,0.67,0.41,0.045)
        density = mini(density,32)
    draw_rect(Rect2(Vector2.ZERO,size),tint)
    for i in range(density):
        var sx: float = float(posmod(i*137+43,997))/997.0
        var sy: float = float(posmod(i*271+19,991))/991.0
        var speed: float = 0.75+float(i%5)*0.11
        var p := Vector2(sx,sy)
        if mode=="rain":
            p.x = fposmod(sx-phase*0.15*speed,1.0)
            p.y = fposmod(sy+phase*0.65*speed,1.0)
            var at: Vector2 = p*size
            draw_line(at,at+Vector2(-3.5,11.0),Color(0.71,0.84,0.96,0.31),1.0,true)
        elif mode=="snow":
            p.x = fposmod(sx+sin(phase*0.8+float(i))*0.025,1.0)
            p.y = fposmod(sy+phase*0.075*speed,1.0)
            draw_circle(p*size,0.8+float(i%3)*0.42,Color(0.94,0.97,1.0,0.66))
        elif mode=="dust":
            p.x = fposmod(sx+phase*0.16*speed,1.0)
            p.y = fposmod(sy+phase*0.018,1.0)
            var at: Vector2 = p*size
            draw_line(at,at+Vector2(8.0+float(i%4)*2.0,1.2),
                Color(0.92,0.78,0.54,0.22),1.0,true)
        active_count += 1
