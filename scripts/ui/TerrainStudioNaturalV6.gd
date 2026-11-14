extends RefCounted
class_name TarvokaTerrainStudioNaturalV6

# Preview geometry only. No changes to tactical heights, tile types,
# pathfinding, bridge rules, line of sight or serialized game states.
# Batches all mountain silhouettes into ONE mesh and the three forest
# species into THREE MultiMeshes; shore meanders share ONE mesh.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const LAND_ROCK := Color("#61727d")
const ROCK_HIGHLIGHT := Color("#a7acaa")
const WATER_LEVEL := -0.17

static func _noise(n: int) -> float:
    return float(posmod(n*7919+104729,65521))/65521.0

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
        tint_a: Color, tint_b: Color, tint_c: Color) -> void:
    tool.set_color(tint_a)
    tool.add_vertex(a)
    tool.set_color(tint_b)
    tool.add_vertex(b)
    tool.set_color(tint_c)
    tool.add_vertex(c)

static func _finish(parent: Node3D, label: String,
        tool: SurfaceTool) -> MeshInstance3D:
    tool.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.name = label
    mesh.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.93
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material
    mesh.set_meta("visual_only",true)
    parent.add_child(mesh)
    return mesh

static func _surface(cell: Dictionary, dx: float, dz: float) -> float:
    return Sampler.height(float(cell["top"]),cell["corners"],
        dx,dz,float(cell["half"]))

static func _ridge(tool: SurfaceTool, cell: Dictionary,
        has_mountains: Dictionary, scene: int) -> void:
    var x: int = int(cell["x"])
    var z: int = int(cell["z"])
    var seed: int = x*283+z*571+scene*127
    var origin: Vector3 = cell["center"]
    # Ridge direction follows neighboring mountain cells instead of
    # assigning the same recognizable cone silhouette to every tile.
    var east: bool = has_mountains.has(Vector2i(x+1,z))
    var west: bool = has_mountains.has(Vector2i(x-1,z))
    var north: bool = has_mountains.has(Vector2i(x,z-1))
    var south: bool = has_mountains.has(Vector2i(x,z+1))
    var along_x: bool = east or west
    var along_z: bool = north or south
    var angle: float = (PI*0.5 if along_z and not along_x else 0.0)
    angle += (_noise(seed+3)-0.5)*0.52
    var forward := Vector2(cos(angle),sin(angle))
    var across := Vector2(-forward.y,forward.x)
    var half: float = float(cell["half"])*0.92
    var height: float = 0.88+1.24*_noise(seed+47)
    if (east and west) or (north and south):
        height *= 1.13
    var second_h: float = height*(0.58+0.26*_noise(seed+101))
    var main_at: Vector2 = forward*(-0.27+_noise(seed+17)*0.40)
    var other_at: Vector2 = forward*(0.46+_noise(seed+19)*0.27)
    var y0: float = float(cell["top"])
    var peak := origin+Vector3(main_at.x,y0+height,main_at.y)
    var second := origin+Vector3(other_at.x,y0+second_h,other_at.y)
    var n: int = 10
    var foot: Array[Vector3] = []
    var middle: Array[Vector3] = []
    for i in range(n):
        var theta: float = TAU*float(i)/float(n)
        var radial: float = half*(0.72+0.35*_noise(seed+i*11))
        var p: Vector2 = forward*cos(theta)*radial+across*sin(theta)*radial
        var sampled_y: float = _surface(cell,p.x,p.y)
        foot.append(origin+Vector3(p.x,sampled_y+0.027,p.y))
        var shrink: float = 0.38+0.10*_noise(seed+i*13)
        middle.append(origin+Vector3(
            p.x*shrink,y0+height*(0.31+0.09*_noise(seed+i*7)),
            p.y*shrink))
    var rock_tint: Color = LAND_ROCK if scene != 1 else Color("#80777b")
    for i in range(n):
        var j: int = (i+1)%n
        var shade: float = 0.11*_noise(seed+i*31)
        var dark: Color = rock_tint.darkened(0.09+shade)
        var mid: Color = rock_tint.lightened(0.04+shade)
        _triangle(tool,foot[i],foot[j],middle[i],
            dark,dark.darkened(0.06),mid)
        _triangle(tool,middle[i],foot[j],middle[j],
            mid,dark,mid.lightened(0.08))
        var summit: Vector3 = second if i >= 3 and i <= 6 else peak
        var top: Color = ROCK_HIGHLIGHT if scene != 1 and height > 1.48 else mid.lightened(0.12)
        _triangle(tool,middle[i],middle[j],summit,
            mid,mid.lightened(0.09),top)
    # Avoid a straight line of identical summits; the two crest heights,
    # footprints and orientations depend on the real mountain neighborhood.

static func _quad_mesh(tool: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3, d: Vector3,
        col: Color) -> void:
    _triangle(tool,a,b,c,col.darkened(0.13),col,col.lightened(0.12))
    _triangle(tool,a,c,d,col.darkened(0.13),col.lightened(0.12),col)

static func _tree_geometry(kind: int, scene: int) -> ArrayMesh:
    # All vertices for a tree are submitted to one material / mesh surface.
    # Species 0: fir; 1: irregular pine; 2: broadleaf river woodland.
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var bark: Color = Color("#675c4b")
    var leaves: Color = (
        Color("#3c6854") if kind == 0 else
        Color("#4c7653") if kind == 1 else
        Color("#547957") if scene == 2 else Color("#627d4b"))
    # 6-sided trunk, rendered on the same draw surface as the foliage.
    var edges: int = 7
    var trunk_h: float = 0.72 if kind != 2 else 1.03
    for i in range(edges):
        var theta: float = TAU*float(i)/float(edges)
        var next_theta: float = TAU*float(i+1)/float(edges)
        var a := Vector3(cos(theta)*0.083,0.01,sin(theta)*0.083)
        var b := Vector3(cos(next_theta)*0.083,0.01,sin(next_theta)*0.083)
        _quad_mesh(tool,a,b,b+Vector3.UP*trunk_h,
            a+Vector3.UP*trunk_h,bark)
    if kind < 2:
        for layer in range(3):
            var base_h: float = 0.37+float(layer)*0.40
            var tip_h: float = base_h+(0.75 if kind == 0 else 0.55)
            var radius: float = (0.53 if kind == 0 else 0.68)*(1.0-float(layer)*0.21)
            var tip := Vector3(
                (-0.11 if kind == 1 else 0.0)*float(layer)/3.0,
                tip_h,0.04*float(layer))
            for i in range(8):
                var a: float = TAU*float(i)/8.0
                var b: float = TAU*float(i+1)/8.0
                var p := Vector3(cos(a)*radius,base_h,sin(a)*radius)
                var q := Vector3(cos(b)*radius,base_h,sin(b)*radius)
                _triangle(tool,p,q,tip,
                    leaves.darkened(0.07*float(i%3)),
                    leaves.lightened(0.08*float((i+1)%3)),
                    leaves.lightened(0.15))
    else:
        # A broadleaf silhouette uses two offset crowns and a rounded
        # faceted canopy, avoiding a row of conifer triangles in the delta.
        for crown in range(2):
            var offset_x: float = -0.26 if crown == 0 else 0.30
            var crown_h: float = 1.20 if crown == 0 else 1.38
            var radius: float = 0.57 if crown == 0 else 0.49
            var upper := Vector3(offset_x,crown_h+0.54,0.0)
            var lower := Vector3(offset_x,crown_h-0.34,0.0)
            for i in range(9):
                var a: float = TAU*float(i)/9.0
                var b: float = TAU*float(i+1)/9.0
                var p := Vector3(offset_x+radius*cos(a),crown_h,0.82*radius*sin(a))
                var q := Vector3(offset_x+radius*cos(b),crown_h,0.82*radius*sin(b))
                var color: Color = leaves.lightened(0.06*float(i%3))
                _triangle(tool,upper,p,q,color.lightened(0.16),color,color.darkened(0.06))
                _triangle(tool,lower,q,p,color.darkened(0.13),color,color)
    tool.generate_normals()
    var mesh: ArrayMesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.94
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.surface_set_material(0,material)
    return mesh

static func _forest(parent: Node3D, cells: Array[Dictionary],
        indexed: Dictionary, scene: int) -> Dictionary:
    var transforms: Array = [[],[],[]]
    for cell in cells:
        var x: int = int(cell["x"])
        var z: int = int(cell["z"])
        var biome: String = str(cell["kind"])
        var adjacent: int = 0
        for diff in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1),Vector2i(0,1)]:
            if indexed.get(Vector2i(x+diff.x,z+diff.y),"") == "forest":
                adjacent += 1
        var count: int = 3 if biome == "forest" else 0
        if biome == "plain" and adjacent > 0:
            count = 1
        if count == 0:
            continue
        var center: Vector3 = cell["center"]
        var seed: int = x*719+z*397+scene*37
        for i in range(count):
            var ox: float = (_noise(seed+i*49)-0.5)*1.66
            var oz: float = (_noise(seed+i*79+7)-0.5)*1.66
            var at := center+Vector3(ox,_surface(cell,ox,oz),oz)
            var species: int = posmod(seed+i*13,3)
            if scene == 2 and posmod(seed+i*5,5) != 0:
                species = 2
            var size: float = 0.79+0.42*_noise(seed+i*31+5)
            var yaw: float = TAU*_noise(seed+i*71+17)
            var transform := Transform3D(Basis(Vector3.UP,yaw).scaled(
                Vector3(size,size*(0.87+0.23*_noise(seed+i*23)),size)),at)
            transforms[species].append(transform)
    var drawn: int = 0
    var batches: int = 0
    for kind in range(3):
        var placements: Array = transforms[kind]
        if placements.is_empty():
            continue
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.mesh = _tree_geometry(kind,scene)
        multi.instance_count = placements.size()
        for i in range(placements.size()):
            multi.set_instance_transform(i,placements[i])
        var node := MultiMeshInstance3D.new()
        node.name = ["BosqueAbetosV6","BosquePinosV6","BosqueCaducifoliosV6"][kind]
        node.multimesh = multi
        node.set_meta("visual_only",true)
        parent.add_child(node)
        drawn += placements.size()
        batches += 1
    return {"trees":drawn,"forest_batches":batches}

static func _bank(tool: SurfaceTool, cell: Dictionary,
        side: Vector2i, scene: int) -> void:
    var half: float = float(cell["half"])
    var direction := Vector2(float(side.x),float(side.y))
    var tangent := Vector2(-direction.y,direction.x)
    var tint: Color = Color("#bcb59b") if scene != 1 else Color("#b7a188")
    var seed: int = int(cell["x"])*331+int(cell["z"])*617
    for n in range(7):
        var t0: float = float(n)/7.0
        var t1: float = float(n+1)/7.0
        var left: float = lerpf(-half+0.05,half-0.05,t0)
        var right: float = lerpf(-half+0.05,half-0.05,t1)
        var phase0: float = sin(t0*TAU+_noise(seed+7)*TAU)*0.095
        var phase1: float = sin(t1*TAU+_noise(seed+7)*TAU)*0.095
        var inner0: Vector2 = tangent*left+direction*(half-0.41+phase0)
        var inner1: Vector2 = tangent*right+direction*(half-0.41+phase1)
        var outer0: Vector2 = tangent*left+direction*(half+0.22+phase0)
        var outer1: Vector2 = tangent*right+direction*(half+0.22+phase1)
        var center: Vector3 = cell["center"]
        var a: Vector3 = center+Vector3(inner0.x,
            _surface(cell,inner0.x,inner0.y)+0.068,inner0.y)
        var b: Vector3 = center+Vector3(inner1.x,
            _surface(cell,inner1.x,inner1.y)+0.068,inner1.y)
        var c: Vector3 = center+Vector3(outer0.x,WATER_LEVEL+0.060,outer0.y)
        var d: Vector3 = center+Vector3(outer1.x,WATER_LEVEL+0.060,outer1.y)
        _triangle(tool,a,c,b,tint.darkened(0.12),tint.lightened(0.08),tint.darkened(0.12))
        _triangle(tool,b,c,d,tint.darkened(0.12),tint.lightened(0.08),tint.lightened(0.18))

static func populate(parent: Node3D, cells: Array[Dictionary], scene: int,
        with_ridges: bool = true, with_forest: bool = true,
        with_banks: bool = true) -> Dictionary:
    var index: Dictionary = {}
    var mountain_index: Dictionary = {}
    for cell in cells:
        var coord := Vector2i(int(cell["x"]),int(cell["z"]))
        index[coord] = str(cell["kind"])
        if str(cell["kind"]) == "mountain":
            mountain_index[coord] = true
    var summary := {"ridges":0,"trees":0,"banks":0,"batches":0}
    if with_ridges and not mountain_index.is_empty():
        var mesh := SurfaceTool.new()
        mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
        for cell in cells:
            if str(cell["kind"]) != "mountain":
                continue
            _ridge(mesh,cell,mountain_index,scene)
            summary["ridges"] = int(summary["ridges"])+1
        _finish(parent,"CordilleraContinuaV6",mesh)
        summary["batches"] = int(summary["batches"])+1
    if with_forest:
        var forests: Dictionary = _forest(parent,cells,index,scene)
        summary["trees"] = int(forests["trees"])
        summary["batches"] = int(summary["batches"])+int(forests["forest_batches"])
    if with_banks:
        var mesh := SurfaceTool.new()
        mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
        for cell in cells:
            var biome: String = str(cell["kind"])
            if biome not in ["plain","forest"]:
                continue
            for side in cell.get("water_edges",[]):
                _bank(mesh,cell,side,scene)
                summary["banks"] = int(summary["banks"])+1
        if int(summary["banks"]) > 0:
            _finish(parent,"OrillasMeandrantesV6",mesh)
            summary["batches"] = int(summary["batches"])+1
    parent.set_meta("terrain_natural_v6",summary)
    return summary
