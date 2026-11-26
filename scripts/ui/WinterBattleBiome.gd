extends RefCounted
class_name TarvokaWinterBattleBiome

# V19 winter artwork in the REAL Android battle renderer. The same snow/rock
# identity as the 3D studio is painted as lightweight tactical isometric art.
# This is a persistent VISUAL biome, independent from rain/snow weather rules.
# No new tactical terrain kinds, paths, water passability or hidden enemy data.
const FIELD := "visual_biome"
const TEMPERATE := "temperate"
const WINTER := "winter"
const CANYON := "canyon"
const COASTAL := "coastal"
const DESERT := "desert"
# Preserve historic index 1 = winter. New schemes are appended.
const CHOICES := [TEMPERATE, WINTER, CANYON, COASTAL, DESERT]
const LABELS := ["Valle boscoso", "Nevado V19", "Canon rocoso", "Delta costero", "Desierto de dunas"]

static func from_index(index: int) -> String:
    return str(CHOICES[clampi(index,0,CHOICES.size()-1)])

static func index_for(state: Dictionary) -> int:
    return CHOICES.find(from_state(state))

static func label_for(value: String) -> String:
    var index: int = CHOICES.find(value)
    return str(LABELS[index]) if index >= 0 else str(LABELS[0])
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
    return value is String and value in CHOICES

static func from_state(state: Dictionary) -> String:
    var value: Variant = state.get(FIELD,TEMPERATE)
    return str(value) if valid(value) else TEMPERATE

static func tile_color(kind: String,x: int,y: int,
        biome: String = WINTER) -> Color:
    # V19 permanent palette. The checker+grain is deterministic; no time or
    # faction/team information is used. Existing grass/rocks stay unchanged
    # in temperate games, including every historical save.
    var grain: float = float(posmod(x*37+y*59,11))/10.0
    if biome == DESERT:
        match kind:
            "plain": return Color("#d9b679").lerp(Color("#efd39a"),0.28*grain)
            "forest": return Color("#b4aa69").lerp(Color("#bfc287"),0.22*grain)
            "mountain": return Color("#a66c45").lerp(Color("#cb9261"),0.34*grain)
            "road": return Color("#8a735b")
            "water": return Color("#347d82").lerp(Color("#60b3a5"),0.21*grain)
    elif biome == CANYON:
        match kind:
            "plain": return Color("#bfa27b").lerp(Color("#d2ba94"),0.16*grain)
            "forest": return Color("#98896c").lerp(Color("#acaa7f"),0.24*grain)
            "mountain": return Color("#8f7565").lerp(Color("#b69b80"),0.26*grain)
            "road": return Color("#736c63")
            "water": return Color("#316f8d").lerp(Color("#3f91a8"),0.12*grain)
    elif biome == COASTAL:
        match kind:
            "plain": return Color("#82a583").lerp(Color("#9ebe91"),0.17*grain)
            "forest": return Color("#4a836c").lerp(Color("#669c81"),0.20*grain)
            "mountain": return Color("#718985").lerp(Color("#88a39c"),0.22*grain)
            "road": return Color("#58676b")
            "water": return Color("#24748d").lerp(Color("#4398a9"),0.17*grain)
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

# Distinct canyon and coastal terrain drawings. Temperate retains WorldArt.
# Desert is sparse scrub, sandstone and wind-carved sand; a forest tile
# still represents the same tactical cover as in every other biome.
static func _draw_desert(canvas: CanvasItem,kind: String,
        center: Vector2,s: float) -> void:
    match kind:
        "plain":
            for i in range(3):
                var y: float = -0.32+float(i)*0.29
                _poly(canvas,center,s,[[-0.85,y+0.16],[-0.30,y-0.11],
                    [0.30,y-0.18],[0.85,y+0.05],[0.30,y+0.02],[-0.32,y+0.10]],
                    Color("#edcf96") if i%2==0 else Color("#c69a60"))
        "forest":
            for offset in [Vector2(-0.50,0.12),Vector2(0.40,-0.06)]:
                var at: Vector2 = center+offset*s
                _line(canvas,at,s,Vector2(0,0.27),Vector2(0,-0.38),Color("#776343"),0.10)
                _poly(canvas,at,s,[[-0.38,0.04],[-0.23,-0.33],[0.0,-0.48],
                    [0.32,-0.29],[0.38,0.10],[0.0,0.21]],Color("#7e8b52"))
                _line(canvas,at,s,Vector2(-0.18,-0.27),Vector2(0.23,-0.16),
                    Color("#aeb476"),0.09)
        "mountain":
            _poly(canvas,center,s,[[-0.99,0.48],[-0.65,-0.53],[-0.22,-0.79],
                [0.34,-0.75],[0.92,0.48]],Color("#a66c45"))
            _poly(canvas,center,s,[[-0.22,-0.79],[0.34,-0.75],[0.92,0.48],
                [0.31,0.30]],Color("#cf9a68"))
            _line(canvas,center,s,Vector2(-0.68,-0.18),Vector2(0.53,-0.12),
                Color("#e1ab79"),0.07)
        "road":
            _line(canvas,center,s,Vector2(-0.96,-0.19),Vector2(0.96,0.19),
                Color("#c4a379"),0.42)
            _line(canvas,center,s,Vector2(-0.96,-0.19),Vector2(0.96,0.19),
                Color("#8a735b"),0.27)
        "water":
            for i in range(3):
                var y: float = -0.30+float(i)*0.26
                _line(canvas,center,s,Vector2(-0.75,y),Vector2(0.45,y+0.06),
                    Color("#8cc7b1"),0.07)

static func draw_biome_iso(canvas: CanvasItem,kind: String,
        center: Vector2,half_width: float,seed: int,biome: String) -> void:
    if biome == WINTER:
        draw_iso(canvas,kind,center,half_width,seed)
        return
    var s: float = half_width*0.56
    if biome == DESERT:
        _draw_desert(canvas,kind,center,s)
        return
    var rock: Color = Color("#957864") if biome==CANYON else Color("#778d86")
    var foliage: Color = Color("#8e8a59") if biome==CANYON else Color("#346f63")
    match kind:
        "mountain":
            _poly(canvas,center,s,[[-1.00,0.62],[-0.31,-0.96],[0.13,0.56]],
                rock.darkened(0.14))
            _poly(canvas,center,s,[[-0.31,-0.96],[0.75,0.51],[0.13,0.56]],
                rock.lightened(0.14))
            _poly(canvas,center,s,[[0.10,0.45],[0.51,-1.15],[1.02,0.45]],
                rock.darkened(0.03))
        "forest":
            for offset in [Vector2(-0.48,0.18),Vector2(0.42,-0.08)]:
                var at: Vector2 = center+offset*s
                _line(canvas,at,s,Vector2.ZERO,Vector2(0.0,0.44),
                    rock.darkened(0.37),0.13)
                _poly(canvas,at,s,[[-0.32,0.08],[0.0,-0.79],[0.36,0.08]],
                    foliage)
                _poly(canvas,at,s,[[-0.18,-0.19],[0.0,-0.74],[0.17,-0.19]],
                    foliage.lightened(0.15))
        "road":
            _line(canvas,center,s,Vector2(-1.02,-0.18),Vector2(1.02,0.18),
                rock.lightened(0.13),0.42)
            _line(canvas,center,s,Vector2(-0.98,-0.18),Vector2(0.98,0.18),
                Color("#636a6a") if biome==COASTAL else Color("#80776a"),0.29)
        "water":
            for j in range(3):
                var y: float = float(j)*0.31-0.37
                _line(canvas,center,s,Vector2(-0.85,y),
                    Vector2(0.22,y+0.05),Color("#8bb9c2"),0.045)
        _:
            _line(canvas,center,s,Vector2(-0.49,0.17),Vector2(0.53,0.10),
                rock.lightened(0.29),0.041)

static func draw_biome_classic(canvas: CanvasItem,kind: String,
        corner: Vector2,tile: float,biome: String) -> void:
    if biome == WINTER:
        draw_classic(canvas,kind,corner,tile)
        return
    var c: Vector2 = corner+Vector2.ONE*tile*0.5
    var s: float = tile*0.30
    if biome == DESERT:
        _draw_desert(canvas,kind,c,s)
        return
    var rock: Color = Color("#a1876b") if biome==CANYON else Color("#708b80")
    var foliage: Color = Color("#95925d") if biome==CANYON else Color("#36735f")
    match kind:
        "mountain":
            _poly(canvas,c,s,[[-1.32,0.93],[-0.20,-1.05],[0.76,0.93]],rock)
            _poly(canvas,c+Vector2(0.34*s,0),s,
                [[-0.2,0.93],[0.44,-0.79],[1.10,0.93]],rock.darkened(0.17))
        "forest":
            for offset in [-0.36,0.32]:
                _poly(canvas,c+Vector2(offset*tile,0),s,
                    [[-0.34,0.35],[0,-0.90],[0.35,0.35]],foliage)
        "road":
            _line(canvas,c,s,Vector2(-1.25,0),Vector2(1.25,0),
                rock.lightened(0.12),0.36)
            _line(canvas,c,s,Vector2(-1.23,0),Vector2(1.23,0),
                Color("#626566"),0.26)
        "water":
            _line(canvas,c,s,Vector2(-1.05,-0.34),Vector2(0.91,-0.34),
                Color("#8cb8c4"),0.07)
        _:
            _line(canvas,c,s,Vector2(-0.91,-0.08),Vector2(0.54,0.0),
                rock.lightened(0.28),0.038)

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
