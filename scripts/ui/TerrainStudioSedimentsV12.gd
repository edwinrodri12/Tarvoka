extends RefCounted
class_name TarvokaTerrainStudioSedimentsV12

# V16: valley sediment deposits and natural road-edge integration.
# Visual-only, deterministic, terrain-following mesh batches. The tactical
# grid, water, roads, collision, heights, movement, fog and saves do not change.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const DIRECTIONS := [
    Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]

static func _hash(seed: int) -> float:
    return float(posmod(seed*3571+19171,65521))/65521.0

static func _base_color(cell: Dictionary, scene: int) -> Color:
    var soil: Color = (
        Color("#bb9e74") if scene == 1 else
        Color("#648677") if scene == 2 else Color("#668868"))
    if str(cell["kind"]) == "forest":
        soil = soil.darkened(0.065)
    return soil

static func _deposit_color(scene: int, source: String) -> Color:
    if source == "mountain":
        return Color("#8d9185") if scene == 0 else (
            Color("#a28f7c") if scene == 1 else Color("#89988a"))
    if source == "water":
        return Color("#b8ad86") if scene != 1 else Color("#c0a381")
    return Color("#a0a38b") if scene == 0 else (
        Color("#a9977b") if scene == 1 else Color("#a4ab92"))

static func _point(cell: Dictionary, offset: Vector2, lift: float) -> Vector3:
    var center: Vector3 = cell["center"]
    var ground: float = Sampler.height(
        float(cell["top"]),cell["corners"],
        offset.x,offset.y,float(cell["half"]))
    return center+Vector3(offset.x,ground+lift,offset.y)

static func _triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,
        ca: Color,cb: Color,cc: Color) -> void:
    tool.set_color(ca)
    tool.add_vertex(a)
    tool.set_color(cb)
    tool.add_vertex(b)
    tool.set_color(cc)
    tool.add_vertex(c)

static func _finish(parent: Node3D,label: String,tool: SurfaceTool) -> void:
    tool.generate_normals()
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.98
    material.specular = 0.09
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = material
    node.set_meta("visual_only",true)
    parent.add_child(node)

static func _fan(tool: SurfaceTool,cell: Dictionary,center: Vector2,
        radius: float,tint: Color,scene: int,seed: int) -> int:
    # Sample all vertices from the same ground as the valley, with a strict
    # inset. No material ever crosses into a road, river or mountain tile.
    var half: float = float(cell["half"])
    var inset: float = 0.15
    center.x = clampf(center.x,-half+inset+radius,half-inset-radius)
    center.y = clampf(center.y,-half+inset+radius,half-inset-radius)
    var mid: Vector3 = _point(cell,center,0.018)
    var ring: Array[Vector3] = []
    var base: Color = _base_color(cell,scene)
    var spin: float = _hash(seed+17)*TAU
    for k in range(8):
        var angle: float = spin+float(k)*TAU/8.0
        var scale: float = 0.74+0.24*_hash(seed+k*37)
        var offset: Vector2 = center+Vector2(cos(angle),sin(angle))*radius*scale
        ring.append(_point(cell,offset,0.010))
    for k in range(8):
        var corner: Color = base.lerp(tint,0.12+0.07*_hash(seed+k*19))
        var middle: Color = tint.lerp(base,0.06+0.16*_hash(seed+k*11))
        _triangle(tool,mid,ring[(k+1)%8],ring[k],
            middle,corner,corner)
    return 8

static func populate(parent: Node3D,cells: Array[Dictionary],scene: int,
        deposits: bool = true,shoulders: bool = true) -> Dictionary:
    var index: Dictionary = {}
    for cell in cells:
        index[Vector2i(int(cell["x"]),int(cell["z"]))] = cell
    var sediment_tool := SurfaceTool.new()
    sediment_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var verge_tool := SurfaceTool.new()
    verge_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sediment_patches := 0
    var road_verges := 0
    var river_patches := 0
    var mountain_patches := 0
    var skipped_roads := 0
    var skipped_water := 0
    var triangles := 0
    for cell in cells:
        var biome: String = str(cell["kind"])
        if biome == "road":
            skipped_roads += 1
            continue
        if biome == "water":
            skipped_water += 1
            continue
        if biome not in ["plain","forest"]:
            continue
        var id := Vector2i(int(cell["x"]),int(cell["z"]))
        var seed: int = id.x*229+id.y*607+scene*367
        var natural_passes := 0
        var verge_passes := 0
        for direction in DIRECTIONS:
            var neighbor: Vector2i = id+direction
            if not index.has(neighbor):
                continue
            var adjacent: String = str(index[neighbor]["kind"])
            var face := Vector2(float(direction.x),float(direction.y))
            var tangent := Vector2(-face.y,face.x)
            if deposits and adjacent in ["mountain","water"] and natural_passes<2:
                # Alluvial patches break up the footslope. Their elliptical
                # footprint is irregular, but no new terrain tessellation
                # or tactical relief is introduced.
                var seed_part: int = seed+natural_passes*59+direction.x*71+direction.y*109
                var lateral: float = (_hash(seed_part+37)-0.5)*0.45
                var center: Vector2 = face*0.28+tangent*lateral
                var radius: float = 0.31+0.07*_hash(seed_part+91)
                triangles += _fan(sediment_tool,cell,center,radius,
                    _deposit_color(scene,adjacent),scene,seed_part)
                sediment_patches += 1
                if adjacent == "water":
                    river_patches += 1
                else:
                    mountain_patches += 1
                natural_passes += 1
            elif shoulders and adjacent == "road" and verge_passes<2:
                # Soften the VISUAL verge on open ground; the road asphalt
                # and its legal traversable tile are never re-meshed.
                var seed_part: int = seed+verge_passes*73+direction.x*43+direction.y*89
                var lateral: float = (_hash(seed_part+21)-0.5)*0.53
                var center: Vector2 = face*0.54+tangent*lateral
                triangles += _fan(verge_tool,cell,center,0.26,
                    _deposit_color(scene,"road"),scene,seed_part)
                road_verges += 1
                verge_passes += 1
        # A few isolated deposits give uninterrupted plains subtle color
        # variation, avoiding obvious per-tile repetition at game distance.
        if deposits and natural_passes==0 and biome=="plain" and (
                _hash(seed+29)>0.72):
            var center := Vector2(
                (_hash(seed+13)-0.5)*0.45,
                (_hash(seed+53)-0.5)*0.45)
            triangles += _fan(sediment_tool,cell,center,0.32,
                _deposit_color(scene,"plain"),scene,seed+137)
            sediment_patches += 1
    var batches := 0
    if deposits and sediment_patches>0:
        _finish(parent,"DepositosAluvialesV12",sediment_tool)
        batches += 1
    if shoulders and road_verges>0:
        _finish(parent,"ArcenesNaturalesV12",verge_tool)
        batches += 1
    var summary := {
        "sediment_patches":sediment_patches,
        "road_verges":road_verges,
        "river_patches":river_patches,
        "mountain_patches":mountain_patches,
        "triangles":triangles,
        "road_cells_skipped":skipped_roads,
        "water_cells_skipped":skipped_water,
        "batches":batches}
    parent.set_meta("terrain_sediments_v12",summary)
    return summary
