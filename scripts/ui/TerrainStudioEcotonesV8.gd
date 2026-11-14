extends RefCounted
class_name TarvokaTerrainStudioEcotonesV8

# Visual-only transition vegetation and talus: never write to the battle
# grid, collision, fuel, movement, water or save dictionaries. Two batched
# surfaces maximum across the entire 12x10 artistic study.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const NEIGHBORS := [
    Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]

static func _hash(value: int) -> float:
    return float(posmod(value*3571+29311,65521))/65521.0

static func _ground(cell: Dictionary, offset: Vector2, lift: float) -> Vector3:
    var c: Vector3 = cell["center"]
    var y: float = Sampler.height(float(cell["top"]),cell["corners"],
        offset.x,offset.y,float(cell["half"]))
    return c+Vector3(offset.x,y+lift,offset.y)

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
    for pair in [[a,ca],[b,cb],[c,cc]]:
        tool.set_color(pair[1])
        tool.set_uv(Vector2(pair[0].x,pair[0].z)*0.19)
        tool.add_vertex(pair[0])

static func _finish(parent: Node3D,label: String,
        tool: SurfaceTool, palette: String) -> MeshInstance3D:
    tool.generate_normals()
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = tool.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.99
    mat.specular = 0.10 if palette == "rocks" else 0.16
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = mat
    node.set_meta("visual_only",true)
    parent.add_child(node)
    return node

static func _talus(tool: SurfaceTool, cell: Dictionary, toward: Vector2i,
        scene: int, seed: int) -> int:
    # Small angular scree banks radiate FROM a mountain neighbor onto
    # safe non-road land, without forming flat rectangular tile borders.
    var direction := Vector2(float(toward.x),float(toward.y))
    var tangent := Vector2(-direction.y,direction.x)
    var mineral: Color = (
        Color("#7b8c87") if scene == 0 else
        Color("#9d8975") if scene == 1 else Color("#889389"))
    var count := 5
    var half: float = float(cell["half"])
    for i in range(count):
        var side: float = (_hash(seed+37*i)-0.5)*1.57
        var near: float = 0.18+0.54*_hash(seed+23*i)
        var center: Vector2 = direction*(half-near)+tangent*side
        var angle: float = TAU*_hash(seed+61*i)
        var radius: float = 0.13+0.19*_hash(seed+17*i)
        var shape: Vector2 = Vector2(cos(angle),sin(angle))
        var spread: Vector2 = Vector2(-shape.y,shape.x)
        var p: Vector3 = _ground(cell,center,0.023)
        var a: Vector3 = _ground(cell,center+shape*radius,0.023)
        var b: Vector3 = _ground(cell,center-spread*radius*0.62,0.023)
        var c: Vector3 = _ground(cell,center+spread*radius*0.76,0.023)
        p.y += radius*(0.33+0.62*_hash(seed+i*11))
        var shade: float = 0.06+0.17*_hash(seed+i*7)
        _triangle(tool,a,b,p,mineral.darkened(shade),
            mineral.darkened(0.08),mineral.lightened(0.07))
        _triangle(tool,b,c,p,mineral.darkened(0.16),
            mineral.lightened(0.06),mineral)
        _triangle(tool,c,a,p,mineral, mineral.darkened(0.08),
            mineral.lightened(0.12))
    return count

static func _undergrowth(tool: SurfaceTool, cell: Dictionary,
        facing: Vector2i, scene: int, seed: int) -> int:
    # A transitional forest belt, not three identical bushes at every
    # corner. The band fades into the neighboring open biome.
    var direction := Vector2(float(facing.x),float(facing.y))
    var tangent := Vector2(-direction.y,direction.x)
    var greens: Array[Color] = [
        Color("#597e5b"),Color("#719069"),Color("#84957a")]
    if scene == 1:
        greens = [Color("#81765c"),Color("#9c896a"),Color("#6d8065")]
    var count := 7
    for i in range(count):
        var lateral: float = (_hash(seed+i*37)-0.5)*1.94
        var longitudinal: float = 0.25+0.66*_hash(seed+11*i)
        var offset: Vector2 = direction*longitudinal+tangent*lateral
        var p: Vector3 = _ground(cell,offset,0.023)
        var height: float = 0.13+0.28*_hash(seed+i*51)
        var width: float = 0.09+0.14*_hash(seed+i*19)
        var facing2: Vector2 = tangent.rotated(
            (_hash(seed+71*i)-0.5)*0.78)
        var a := p+Vector3(facing2.x*width,0,facing2.y*width)
        var b := p-Vector3(facing2.x*width,0,facing2.y*width)
        var tip := p+Vector3(
            (_hash(seed+i*47)-0.5)*0.11,height,
            (_hash(seed+i*53)-0.5)*0.11)
        var tint: Color = greens[posmod(seed+i,greens.size())]
        _triangle(tool,a,b,tip,tint.darkened(0.17),
            tint.darkened(0.06),tint.lightened(0.15))
    return count

static func populate(parent: Node3D,cells: Array[Dictionary],scene: int,
        talus: bool = true,ecotone: bool = true) -> Dictionary:
    var by_cell: Dictionary = {}
    for cell in cells:
        by_cell[Vector2i(int(cell["x"]),int(cell["z"]))] = cell
    var mineral_mesh := SurfaceTool.new()
    mineral_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    var plant_mesh := SurfaceTool.new()
    plant_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    var transition_edges := 0
    var mineral_pieces := 0
    var plants := 0
    var touches_water := 0
    var touches_road := 0
    for cell in cells:
        var type: String = str(cell["kind"])
        # Transition decoration must NEVER hide roads, bridges, water,
        # infantry, or terrain edges used by gameplay.
        if type != "plain" and type != "forest":
            continue
        var x: int = int(cell["x"])
        var z: int = int(cell["z"])
        var base_seed: int = x*193+z*467+scene*173
        for direction in NEIGHBORS:
            var neighbor: Variant = by_cell.get(Vector2i(x,z)+direction)
            if not neighbor is Dictionary:
                continue
            var next_type: String = str(neighbor["kind"])
            if next_type == "water":
                touches_water += 1
                continue
            if next_type == "road":
                touches_road += 1
                continue
            var seed: int = base_seed+direction.x*151+direction.y*71
            if next_type == "mountain" and talus:
                mineral_pieces += _talus(mineral_mesh,cell,direction,scene,seed)
                transition_edges += 1
            if ecotone and (next_type == "forest" and type == "plain" or
                    next_type == "plain" and type == "forest"):
                plants += _undergrowth(plant_mesh,cell,direction,scene,seed)
                transition_edges += 1
    var batches := 0
    if mineral_pieces > 0:
        _finish(parent,"PedregalesDeTransicionV8",mineral_mesh,"rocks")
        batches += 1
    if plants > 0:
        _finish(parent,"SotobosqueDeTransicionV8",plant_mesh,"plants")
        batches += 1
    var stats := {
        "transition_edges":transition_edges,
        "scree_stones":mineral_pieces,"undergrowth":plants,
        "water_edges_skipped":touches_water,"roads_skipped":touches_road,
        "batches":batches}
    parent.set_meta("terrain_ecotones_v8",stats)
    return stats
