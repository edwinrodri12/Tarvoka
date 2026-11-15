extends RefCounted
class_name TarvokaWinterBattleBiome

# V19 winter artwork in the REAL Android battle renderer. The same snow/rock
# identity as the 3D studio is painted as lightweight tactical isometric art.
# This is a persistent VISUAL biome, independent from rain/snow weather rules.
# No new tactical terrain kinds, paths, water passability or hidden enemy data.
const FIELD := "visual_biome"
const TEMPERATE := "temperate"
const WINTER := "winter"
const SNOW := Color("#dce5e7")
const HARDPACK := Color("#b9c9d3")
const ICE := Color("#91b7c4")
const SLATE := Color("#71818a")
const FROSTED_STONE := Color("#a9b9bd")
const SNOW_FOREST := Color("#b2c9c2")
const COLD_WATER := Color("#263f52")
const FROZEN_SHORE := Color("#c6dce0")
const ROAD_DARK := Color("#525b64")
const ROAD_SLUSH := Color("#abbac0")

static func valid(value: Variant) -> bool:
    return value is String and value in [TEMPERATE, WINTER]

static func from_state(state: Dictionary) -> String:
    var value: Variant = state.get(FIELD,TEMPERATE)
    return str(value) if valid(value) else TEMPERATE

static func tile_color(kind: String,x: int,y: int) -> Color:
    # V19 permanent palette. The checker+grain is deterministic; no time or
    # faction/team information is used. Existing grass/rocks stay unchanged
    # in temperate games, including every historical save.
    var grain: float = float(posmod(x*37+y*59,11))/10.0
    match kind:
        "plain":
            return SNOW.lerp(HARDPACK,0.17+grain*0.20)
        "forest":
            return SNOW_FOREST.lerp(HARDPACK,0.30+grain*0.18)
        "mountain":
            return SLATE.lerp(FROSTED_STONE,0.27+grain*0.18)
        "road":
            return ROAD_DARK.lerp(ROAD_SLUSH,0.05+grain*0.09)
        "water":
            return COLD_WATER.lerp(ICE,0.06+grain*0.12)
    return SNOW

static func _poly(canvas: CanvasItem,center: Vector2,
        scale: float,coords: Array,tint: Color) -> void:
    var shape := PackedVector2Array()
    for pair in coords:
        shape.append(center+Vector2(float(pair[0]),float(pair[1]))*scale)
    canvas.draw_colored_polygon(shape,tint)

static func _line(canvas: CanvasItem,center: Vector2,
        scale: float,a: Vector2,b: Vector2,tint: Color,
        width: float = 0.045) -> void:
    canvas.draw_line(center+a*scale,center+b*scale,
        tint,maxf(0.85,scale*width),true)

static func draw_iso(canvas: CanvasItem,kind: String,
        center: Vector2,half_width: float,seed: int) -> void:
    # Visual art stays within the same tile footprint as WorldArt, and the
    # existing fog pass always covers concealed tiles. No extra scene nodes,
    # shaders, texture uploads or draw calls outside the visible viewport.
    var s: float = half_width*0.56
    var shift: float = float(posmod(seed,7))*0.021
    match kind:
        "forest":
            for offset in [Vector2(-0.53,0.09),Vector2(0.04,-0.18),Vector2(0.53,0.16)]:
                var at: Vector2 = center+offset*s
                _line(canvas,at,s,Vector2(0,0.14),Vector2(0,0.54),
                    Color("#536260"),0.12)
                _poly(canvas,at,s,[[-0.23,0.11],[0.0,-0.82],[0.24,0.11]],
                    Color("#45665e"))
                _poly(canvas,at,s,[[-0.21,-0.17],[0.0,-0.84],[0.21,-0.17]],
                    HARDPACK)
                _poly(canvas,at,s,[[-0.15,-0.36],[0.0,-0.86],[0.14,-0.36]],
                    SNOW)
        "mountain":
            _poly(canvas,center,s,[[-0.98,0.52],[-0.33,-0.74],[0.02,0.52]],
                SLATE)
            _poly(canvas,center,s,[[-0.33,-0.74],[0.25,0.53],[0.02,0.52]],
                FROSTED_STONE.darkened(0.15))
            _poly(canvas,center,s,[[-0.61,-0.23],[-0.33,-0.74],[-0.18,-0.18]],
                SNOW)
            _poly(canvas,center,s,[[-0.20,0.52],[0.48,-1.09],[1.02,0.52]],
                SLATE.lightened(0.17))
            _poly(canvas,center,s,[[0.48,-1.09],[1.02,0.52],[0.50,0.52]],
                SLATE.darkened(0.16))
            _poly(canvas,center,s,[[0.25,-0.39],[0.48,-1.09],[0.72,-0.40]],
                SNOW)
            _line(canvas,center,s,Vector2(-0.71,0.35),Vector2(-0.29,-0.42),
                FROZEN_SHORE,0.038)
        "road":
            _line(canvas,center,s,Vector2(-1.03,-0.31),
                Vector2(1.03,0.31),ROAD_SLUSH,0.42)
            _line(canvas,center,s,Vector2(-1.02,-0.31),
                Vector2(1.03,0.31),ROAD_DARK,0.31)
            for t in [-0.68,0.03,0.73]:
                _line(canvas,center,s,Vector2(t,-0.31+t*0.31),
                    Vector2(t+0.19,-0.31+(t+0.19)*0.31),SNOW,0.055)
        "water":
            for j in range(3):
                var row: float = float(j)*0.27-0.34
                _line(canvas,center,s,Vector2(-0.80+shift,row),
                    Vector2(-0.24+shift,row),ICE,0.073)
                _line(canvas,center,s,Vector2(0.09-shift,row+0.11),
                    Vector2(0.55-shift,row+0.11),FROZEN_SHORE,0.045)
        _:
            # Short snowdrifts/hardpack grain give empty fields depth.
            _poly(canvas,center,s,[[-0.73,0.23],[-0.32,-0.06],[0.00,0.25]],
                HARDPACK.lightened(0.12))
            _line(canvas,center,s,Vector2(0.16,-0.13),
                Vector2(0.72,-0.03),FROZEN_SHORE,0.04)
            _line(canvas,center,s,Vector2(-0.49,0.39),
                Vector2(-0.09,0.36),HARDPACK.darkened(0.04),0.035)

static func draw_classic(canvas: CanvasItem,kind: String,
        corner: Vector2,tile: float) -> void:
    var c: Vector2 = corner+Vector2.ONE*tile*0.5
    var s: float = tile*0.30
    match kind:
        "forest":
            for off in [-0.37,0.31]:
                var x: float = off*tile
                _poly(canvas,c+Vector2(x,0),s,
                    [[-0.36,0.34],[0.0,-0.91],[0.38,0.34]],
                    Color("#45665e"))
                _poly(canvas,c+Vector2(x,0),s,
                    [[-0.23,-0.25],[0.0,-0.91],[0.23,-0.25]],SNOW)
        "mountain":
            _poly(canvas,c,s,[[-1.32,0.93],[-0.20,-1.05],[0.76,0.93]],SLATE)
            _poly(canvas,c,s,[[-0.58,-0.37],[-0.20,-1.05],[0.16,-0.37]],SNOW)
            _poly(canvas,c+Vector2(0.42*s,0),s,
                [[-0.2,0.93],[0.49,-0.77],[1.12,0.93]],FROSTED_STONE)
        "road":
            _line(canvas,c,s,Vector2(-1.30,0),Vector2(1.30,0),
                ROAD_SLUSH,0.37)
            _line(canvas,c,s,Vector2(-1.24,0),Vector2(1.24,0),
                ROAD_DARK,0.27)
        "water":
            for y in [-0.40,0.28]:
                _line(canvas,c,s,Vector2(-1.04,y),Vector2(0.86,y),
                    FROZEN_SHORE,0.075)
        _:
            _line(canvas,c,s,Vector2(-0.95,-0.06),Vector2(0.38,-0.13),
                HARDPACK,0.05)
