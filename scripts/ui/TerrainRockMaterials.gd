extends RefCounted
class_name TarvokaTerrainRockMaterials

# Deterministic world-space mineral colors for the native Godot 3D mesh.
# Procedural without external art or GPU shader allocations. The input
# world position is the SAME on both sides of a terrain-cell seam, so
# dark veins / mineral bands do not reset at each tile.
# Color is strictly visual and never carries tactical elevation data.

static func strata(world: Vector3) -> float:
    var bending: float = sin(world.x*1.18-world.z*0.86)*0.42
    var folded: float = sin(
        world.y*8.8+world.x*1.49+world.z*0.82+bending)
    return 0.5+folded*0.5

static func fractures(world: Vector3) -> float:
    # Two crossing fracture families. Rare thin dark veins rather than
    # a grid of every rock vertex being separately outlined.
    var first: float = sin(world.x*8.1+world.z*2.6+
        world.y*2.4+sin(world.z*2.1)*0.54)
    var second: float = sin(world.z*10.7-world.x*3.5+
        world.y*1.6+cos(world.x*1.7)*0.34)
    return maxf(absf(first),absf(second))

static func rock_color(world: Vector3, summit: float = 0.0) -> Color:
    var band: float = strata(world)
    var mineral: float = sin(world.x*4.71+world.z*6.38+
        world.y*2.81)*0.5+0.5
    var broad: float = sin(world.x*1.16-world.z*1.67)*0.5+0.5
    var slate := Color("#4C6170")
    var granite := Color("#939C9B")
    var weathered := Color("#777B70")
    var tint: Color = slate.lerp(granite,clampf(
        0.23+band*0.37+mineral*0.19,0.0,1.0))
    tint = tint.lerp(weathered,0.12+broad*0.12)
    var crack: float = fractures(world)
    if crack > 0.958:
        tint = tint.darkened(
            (crack-0.958)/0.042*0.24)
    # Top-layer snow is patchy, not a full white plastic cone.
    if summit > 0.0 and world.y > 1.68:
        var scatter: float = sin(world.x*9.7+world.z*6.4)
        var snow_weight: float = clampf(
            (world.y-1.68)*0.16+scatter*0.09,0.0,0.36)
        tint = tint.lerp(Color("#BECFD2"),snow_weight*summit)
    return tint

static func grass_edge_color(world: Vector3, kind: String,
        base: Color) -> Color:
    # Large shared-world-scale patches with small dry/gravel inclusions.
    # No per-cell repeating UVs or noisy triangles.
    var meadow: float = sin(world.x*1.34+world.z*0.67)
    var soil: float = sin(world.z*2.17-world.x*1.08)
    var variation: float = clampf(
        0.5+meadow*0.29+soil*0.15,0.0,1.0)
    if kind == "forest":
        return base.lerp(Color("#496D45"),0.08+variation*0.25)
    if kind == "plain":
        return base.lerp(Color("#A1A078"),0.07+variation*0.23)
    if kind == "road":
        return base.lerp(Color("#646D66"),0.10+variation*0.12)
    return base
