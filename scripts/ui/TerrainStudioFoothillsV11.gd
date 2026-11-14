extends RefCounted
class_name TarvokaTerrainStudioFoothillsV11

# Entirely artistic V15b footslope treatment (safer rock margins). The land/water/road tiles,
# tactical heights, occupancy, movement, cover, fog and save state remain
# unchanged. Two batched surfaces maximum for the whole 12x10 study.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const Spines = preload("res://scripts/ui/TerrainStudioRidgeV10.gd")
const DIRECTIONS := [
    Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]

static func _hash(seed: int) -> float:
    return float(posmod(seed*2333+19661,65521))/65521.0

static func _point(cell: Dictionary, at: Vector2, raise: float = 0.0) -> Vector3:
    var center: Vector3 = cell["center"]
    var base: float = Sampler.height(float(cell["top"]),cell["corners"],
        at.x,at.y,float(cell["half"]))
    return center+Vector3(at.x,base+raise,at.y)

static func _tri(mesh: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
    mesh.set_color(ca)
    mesh.add_vertex(a)
    mesh.set_color(cb)
    mesh.add_vertex(b)
    mesh.set_color(cc)
    mesh.add_vertex(c)

static func _finish(parent: Node3D, label: String,
        tool: SurfaceTool) -> MeshInstance3D:
    tool.generate_normals()
    var piece := MeshInstance3D.new()
    piece.name = label
    piece.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.98
    material.specular = 0.11
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    piece.material_override = material
    piece.set_meta("visual_only",true)
    parent.add_child(piece)
    return piece

static func _ground_color(cell: Dictionary, scene: int) -> Color:
    if scene == 1:
        return Color("#a79479")
    return Color("#6d9076") if str(cell["kind"])=="forest" else Color("#7b967e")

static func _stone_color(scene: int) -> Color:
    return (
        Color("#768581") if scene == 0 else
        Color("#938273") if scene == 1 else
        Color("#7c8984"))

static func _apron_vertex(cell: Dictionary, mountain: Dictionary,
        facing: Vector2, tangent: Vector2, along: float, inward: float,
        scene: int, mountains: Dictionary, seed: int) -> Vector3:
    var half: float = float(cell["half"])
    # The inner contour undulates; the outer contour follows the same
    # mountain border as the V14 ridge, avoiding a straight tile outline.
    var wobble: float = (
        sin(along*2.6+float(seed%13))*0.067+
        sin(along*5.1+float(seed%17))*0.027)*sin(PI*inward)
    var reach: float = 0.84+0.21*_hash(seed+19)
    var span: float = 0.070+inward*reach+wobble
    var offset: Vector2 = facing*(half-span)+tangent*along
    # Use the neighboring mountain's real continuous uplift at the
    # shared world border; this is a visible material transition only.
    var source_offset: Vector2 = -facing*half+tangent*along
    var mountain_rise: float = Spines.uplift(
        mountain,source_offset,mountains,scene)
    var height: float = (
        clampf(mountain_rise*0.64+0.05,0.045,0.34)*
        pow(1.0-inward,2.2)+0.009)
    return _point(cell,offset,height)

static func _apron(mesh: SurfaceTool, cell: Dictionary,
        mountain: Dictionary, direction: Vector2i, scene: int,
        mountains: Dictionary, seed: int) -> int:
    var facing := Vector2(float(direction.x),float(direction.y))
    var tangent := Vector2(-facing.y,facing.x)
    var half: float = float(cell["half"])
    var rock: Color = _stone_color(scene)
    var ground: Color = _ground_color(cell,scene)
    var rows: Array = []
    var cross_sections := 8
    for j in range(4):
        var inward: float = float(j)/3.0
        var contour: Array = []
        for i in range(cross_sections+1):
            var fraction: float = float(i)/float(cross_sections)
            var along: float = lerpf(-half+0.13,half-0.13,fraction)
            var at: Vector3 = _apron_vertex(cell,mountain,
                facing,tangent,along,inward,scene,mountains,seed)
            var mineral: float = 0.10*Spines._noise(
                Vector2(at.x,at.z)*1.5,scene)
            var tint: Color = rock.lerp(ground,
                smoothstep(0.03,0.98,inward))
            # Subtle mineral banding follows the slope, not a tile grid.
            var strata: float = sin(along*12.0+float(seed%19)*0.7)*0.027
            tint = tint.darkened(maxf(0.0,strata))
            if mineral>0.0:
                tint = tint.lightened(mineral)
            else:
                tint = tint.darkened(-mineral)
            contour.append({"at":at,"color":tint})
        rows.append(contour)
    for j in range(3):
        for i in range(cross_sections):
            var a: Dictionary = rows[j][i]
            var b: Dictionary = rows[j][i+1]
            var c: Dictionary = rows[j+1][i]
            var d: Dictionary = rows[j+1][i+1]
            _tri(mesh,a["at"],c["at"],b["at"],
                a["color"],c["color"],b["color"])
            _tri(mesh,b["at"],c["at"],d["at"],
                b["color"],c["color"],d["color"])
    return 3*cross_sections*2

static func _outcrop(mesh: SurfaceTool, cell: Dictionary,
        direction: Vector2i, scene: int, seed: int) -> int:
    var facing := Vector2(float(direction.x),float(direction.y))
    var tangent := Vector2(-facing.y,facing.x)
    var pieces := 4
    var mineral: Color = _stone_color(scene)
    var half: float = float(cell["half"])
    # V15b: stratified, low-profile fragments instead of four identical
    # upright cones. Each rock is kept back from all FOUR tile boundaries,
    # including edges next to a road, river or bridge.
    for i in range(pieces):
        var along: float = lerpf(-0.66,0.66,float(i)/3.0)
        along += (_hash(seed+i*31+12)-0.5)*0.13
        var distance: float = 0.33+0.36*_hash(seed+i*53+7)
        var offset: Vector2 = facing*(half-distance)+tangent*along
        var phi: float = TAU*_hash(seed+i*37+11)
        var axis := Vector2(cos(phi),sin(phi))
        var sideways := Vector2(-axis.y,axis.x)
        var radius: float = 0.103+0.059*_hash(seed+i*43+5)
        var tall: float = 0.105+0.21*_hash(seed+i*29+3)
        var rim_margin: float = radius*1.30+0.11
        offset.x = clampf(offset.x,-half+rim_margin,half-rim_margin)
        offset.y = clampf(offset.y,-half+rim_margin,half-rim_margin)
        var apex := _point(cell,offset,0.015+tall)
        apex.x += (_hash(seed+i*7)-0.5)*radius*0.58
        apex.z += (_hash(seed+i*13)-0.5)*radius*0.58
        var ring: Array[Vector3] = []
        for k in range(5):
            var angle: float = TAU*float(k)/5.0
            var edge: Vector2 = (
                axis*cos(angle)+sideways*sin(angle)) * (
                radius*(0.75+0.40*_hash(seed+i*41+k*7)))
            var at: Vector2 = offset+edge
            # Anchor every fragment on the exact same continuous four-fan
            # ground as the valley. No hovering pebbles or terrain punches.
            ring.append(_point(cell,at,0.013+0.019*_hash(seed+i*23+k*17)))
        for k in range(5):
            var fleck: float = _hash(seed+i*59+k*37)
            var c: Color = mineral.darkened(0.025+fleck*0.15)
            _tri(mesh,ring[k],ring[(k+1)%5],apex,
                c.darkened(0.10),c,c.lightened(0.08+fleck*0.06))
    return pieces

static func populate(parent: Node3D, cells: Array[Dictionary],
        scene: int, aprons: bool = true,
        rocks: bool = true) -> Dictionary:
    var index: Dictionary = {}
    var mountain_index: Dictionary = {}
    for cell in cells:
        var id := Vector2i(int(cell["x"]),int(cell["z"]))
        index[id] = cell
        if str(cell["kind"])=="mountain":
            mountain_index[id] = cell
    var apron_tool := SurfaceTool.new()
    apron_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var outcrop_tool := SurfaceTool.new()
    outcrop_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var edges := 0
    var triangles := 0
    var pieces := 0
    var skipped_roads := 0
    var skipped_water := 0
    for cell in cells:
        var biome: String = str(cell["kind"])
        if biome == "road":
            skipped_roads += 1
            continue
        if biome == "water":
            skipped_water += 1
            continue
        if biome not in ["forest","plain"]:
            continue
        var id := Vector2i(int(cell["x"]),int(cell["z"]))
        for direction in DIRECTIONS:
            var next: Vector2i = id+direction
            if not mountain_index.has(next):
                continue
            edges += 1
            var seed: int = int(cell["x"])*227+int(cell["z"])*619+(
                direction.x*109+direction.y*61)+scene*179
            if aprons:
                triangles += _apron(apron_tool,cell,
                    mountain_index[next],direction,scene,mountain_index,seed)
            if rocks:
                pieces += _outcrop(outcrop_tool,cell,direction,scene,seed)
    var batches := 0
    if aprons and triangles>0:
        _finish(parent,"TaludesTransicionV11",apron_tool)
        batches += 1
    if rocks and pieces>0:
        _finish(parent,"AfloramientosDeValleV11",outcrop_tool)
        batches += 1
    var stats := {
        "mountain_edges":edges,"apron_triangles":triangles,
        "boulders":pieces,"road_cells_skipped":skipped_roads,
        "water_cells_skipped":skipped_water,"batches":batches}
    parent.set_meta("terrain_foothills_v11",stats)
    return stats
