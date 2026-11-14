extends RefCounted
class_name TarvokaTerrainStudioErosionV7

# Studio-only V7 finish. Replaces rhythmic triangular peaks, perfectly
# straight exposed river cliffs and identical per-tile white foam marks.
# All tile types, navigation, elevation rules, combat and saves are untouched.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const MaterialsV9 = preload("res://scripts/ui/TerrainStudioMaterialsV9.gd")
const RidgeV10 = preload("res://scripts/ui/TerrainStudioRidgeV10.gd")
const WATER_LEVEL := -0.17
const WORLD_CELL := 2.4
static var _fracture_noise: FastNoiseLite

static func _geology(at: Vector2, scene: int) -> float:
    if _fracture_noise == null:
        _fracture_noise = FastNoiseLite.new()
        _fracture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
        _fracture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
        _fracture_noise.fractal_octaves = 4
        _fracture_noise.frequency = 0.28
        _fracture_noise.seed = 24701
    return _fracture_noise.get_noise_2d(
        at.x*4.3+float(scene)*67.0,at.y*4.3)

static func _hash(n: int) -> float:
    return float(posmod(n*1327+17471,65521))/65521.0

static func _point(cell: Dictionary, dx: float, dz: float) -> Vector3:
    var p: Vector3 = cell["center"]
    return p+Vector3(dx,Sampler.height(float(cell["top"]),
        cell["corners"],dx,dz,float(cell["half"])),dz)

static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, col_a: Color, col_b: Color, col_c: Color) -> void:
    for pair in [[a,col_a],[b,col_b],[c,col_c]]:
        tool.set_color(pair[1])
        tool.set_uv(Vector2(pair[0].x, pair[0].z)*0.13)
        tool.add_vertex(pair[0])

static func _surface_node(parent: Node3D, name: String,
        tool: SurfaceTool, translucent: bool = false) -> MeshInstance3D:
    tool.generate_normals()
    var node := MeshInstance3D.new()
    node.name = name
    node.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.98 if not translucent else 0.75
    material.specular = 0.11 if not translucent else 0.18
    material.metallic = 0.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if translucent:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    node.material_override = material
    node.set_meta("visual_only",true)
    parent.add_child(node)
    return node

static func _uplift(cell: Dictionary, offset: Vector2,
        mountains: Dictionary, scene: int) -> float:
    var x: int = int(cell["x"])
    var z: int = int(cell["z"])
    var here: Vector3 = cell["center"]
    var world := Vector2(here.x+offset.x,here.z+offset.y)
    var elevation := 0.0
    # Neighbor peaks share a continuous Gaussian field at every vertex.
    # This avoids seams along mountain-to-mountain cell boundaries.
    for dz in range(-2,3):
        for dx in range(-2,3):
            var neighbor: Variant = mountains.get(Vector2i(x+dx,z+dz),null)
            if not neighbor is Dictionary:
                continue
            var at: Vector3 = neighbor["center"]
            var dist: Vector2 = (world-Vector2(at.x,at.z))/WORLD_CELL
            var distance_squared: float = dist.length_squared()
            var seed: int = (x+dx)*239+(z+dz)*467+scene*271
            var amplitude: float = 1.18+0.67*_hash(seed)
            elevation += amplitude*exp(-1.65*distance_squared)
    elevation = minf(elevation*0.68,2.13)
    # Each outer mountain border fades to the exact V2 terrain surface,
    # rather than creating an exposed vertical wedge at the forest.
    var half: float = float(cell["half"])
    var fade: float = 1.0
    if not mountains.has(Vector2i(x-1,z)):
        fade *= smoothstep(0.0,0.72,offset.x+half)
    if not mountains.has(Vector2i(x+1,z)):
        fade *= smoothstep(0.0,0.72,half-offset.x)
    if not mountains.has(Vector2i(x,z-1)):
        fade *= smoothstep(0.0,0.72,offset.y+half)
    if not mountains.has(Vector2i(x,z+1)):
        fade *= smoothstep(0.0,0.72,half-offset.y)
    # Multi-scale simplex fractures prevent the unrealistically smooth
    # monochrome glacier/dune silhouettes seen in the first V11 capture.
    var large_fracture: float = _geology(world,scene)*0.40
    var fine_fracture: float = _geology(world*2.2,scene)*0.17
    var uplift: float = maxf(0.0,elevation+large_fracture+fine_fracture)
    return uplift*fade

static func ridge_height(cell: Dictionary, offset: Vector2,
        mountains: Dictionary, scene: int, sculpted: bool = false) -> float:
    var rise: float = RidgeV10.uplift(
        cell,offset,mountains,scene) if sculpted else _uplift(
        cell,offset,mountains,scene)
    return Sampler.height(float(cell["top"]),cell["corners"],
        offset.x,offset.y,float(cell["half"]))+rise

static func lithology_color(pos: Vector3, elevation: float,
        scene: int, layered: bool = true) -> Color:
    # World-space strata are vertex colors, no heavy textures/shaders.
    var rock: Color = Color("#53666b") if scene != 1 else Color("#776861")
    var top: float = clampf(elevation/2.0,0.0,1.0)
    if not layered:
        rock = rock.lerp(Color("#829193") if scene != 1
            else Color("#9f8b7b"),pow(top,1.34)*0.28)
        var legacy: float = 0.064*_geology(
            Vector2(pos.x,pos.z)*1.9,scene)
        return rock.lightened(legacy) if legacy >= 0.0 else rock.darkened(-legacy)
    # Bent sedimentary layers, deterministically anchored to the world.
    var fold: float = _geology(Vector2(pos.x,pos.z)*0.85,scene)
    var phase: float = pos.y*3.8+pos.x*0.19+pos.z*0.12+fold*0.82
    var band: float = fposmod(phase,1.0)
    var mineral: Color = (
        Color("#526269") if scene == 0 else
        Color("#847266") if scene == 1 else Color("#677a76"))
    var palette: Color = (
        Color("#8b9590") if scene == 0 else
        Color("#ad967f") if scene == 1 else Color("#8a9689"))
    if band < 0.14:
        rock = mineral.darkened(0.16)
    elif band < 0.42:
        rock = mineral
    elif band < 0.70:
        rock = mineral.lerp(palette,0.39)
    else:
        rock = mineral.darkened(0.075)
    var fractures: float = _geology(Vector2(pos.x,pos.z)*3.0,scene)*0.11
    rock = rock.lightened(fractures) if fractures > 0.0 else rock.darkened(-fractures)
    if top < 0.38 and scene != 1:
        var lichen: Color = Color("#647865") if scene == 0 else Color("#687f70")
        var cover: float = (0.38-top)*0.47*clampf(
            _geology(Vector2(pos.x,pos.z)*1.25,scene)+0.65,0.0,1.0)
        rock = rock.lerp(lichen,cover)
    return rock

static func _ridge(parent: Node3D, cells: Array[Dictionary],
        mountains: Dictionary, scene: int,
        layered: bool = false, facets: bool = false,
        sculpted: bool = false) -> Dictionary:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count := 0
    var subdivisions := 12 if sculpted else 8
    for cell in cells:
        if str(cell["kind"]) != "mountain":
            continue
        count += 1
        var half: float = float(cell["half"])
        var center: Vector3 = cell["center"]
        var points: Array[Vector3] = []
        var tones: Array[Color] = []
        for row in range(subdivisions+1):
            for col in range(subdivisions+1):
                var dx: float = lerpf(-half,half,float(col)/subdivisions)
                var dz: float = lerpf(-half,half,float(row)/subdivisions)
                var elevation: float = RidgeV10.uplift(
                    cell,Vector2(dx,dz),mountains,scene) if sculpted else _uplift(
                    cell,Vector2(dx,dz),mountains,scene)
                var pos: Vector3 = _point(cell,dx,dz)+Vector3(0,elevation+0.016,0)
                points.append(pos)
                tones.append(lithology_color(pos,elevation,scene,layered))
        if facets:
            # Height-based central differences reveal broad cracks and
            # ridges at normal gameplay scale, with no extra polygons.
            for row in range(subdivisions+1):
                for col in range(subdivisions+1):
                    var idx: int = row*(subdivisions+1)+col
                    var li: int = row*(subdivisions+1)+maxi(0,col-1)
                    var ri: int = row*(subdivisions+1)+mini(subdivisions,col+1)
                    var ui: int = maxi(0,row-1)*(subdivisions+1)+col
                    var di: int = mini(subdivisions,row+1)*(subdivisions+1)+col
                    var rise_x: float = (
                        (points[ri].y-points[li].y) /
                        maxf(0.01,points[ri].x-points[li].x))
                    var rise_z: float = (
                        (points[di].y-points[ui].y) /
                        maxf(0.01,points[di].z-points[ui].z))
                    tones[idx] = MaterialsV9.rock_color(
                        tones[idx],points[idx],Vector2(rise_x,rise_z),scene)
        for row in range(subdivisions):
            for col in range(subdivisions):
                var a: int = row*(subdivisions+1)+col
                var b: int = a+1
                var c: int = a+subdivisions+1
                var d: int = c+1
                _tri(tool,points[a],points[c],points[b],
                    tones[a],tones[c],tones[b])
                _tri(tool,points[b],points[c],points[d],
                    tones[b],tones[c],tones[d])
    if count > 0:
        _surface_node(parent,"MacizosErosionadosContinuosV7",tool)
    return {"mountain_cells":count,"ridge_triangles":
        count*subdivisions*subdivisions*2,"ridge_batches":1 if count>0 else 0,
        "crest_subdivisions":subdivisions,"silhouette_cells":count if sculpted else 0}

static func _bank(parent: Node3D, cells: Array[Dictionary],
        scene: int) -> Dictionary:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var banks := 0
    var segments := 9
    for cell in cells:
        if str(cell["kind"]) == "water":
            continue
        var center: Vector3 = cell["center"]
        var half: float = float(cell["half"])
        var seed: int = int(cell["x"])*113+int(cell["z"])*719
        var col: Color = (
            Color("#a4a392") if scene == 0 else
            Color("#ac9480") if scene == 1 else Color("#c5ae8b"))
        for side in cell.get("water_edges",[]):
            banks += 1
            var dir := Vector2(float(side.x),float(side.y))
            var tang := Vector2(-dir.y,dir.x)
            for i in range(segments):
                var values: Array = []
                for j in [i,i+1]:
                    var t: float = float(j)/float(segments)
                    var along: float = lerpf(-half+0.01,half-0.01,t)
                    var bend: float = sin(PI*t)*(
                        0.12*sin(t*TAU+TAU*_hash(seed+int(side.x)*17+int(side.y)*29)))
                    var inner: Vector2 = tang*along+dir*(half-0.59+bend)
                    var mid: Vector2 = tang*along+dir*(half-0.22+bend)
                    var outer: Vector2 = tang*along+dir*(half+0.18+bend)
                    var a: Vector3 = _point(cell,inner.x,inner.y)
                    a.y += 0.053
                    var b: Vector3 = center+Vector3(mid.x,
                        lerpf(a.y,WATER_LEVEL+0.068,0.77),mid.y)
                    var c: Vector3 = center+Vector3(outer.x,
                        WATER_LEVEL+0.025,outer.y)
                    values.append([a,b,c])
                var left: Array = values[0]
                var right: Array = values[1]
                _tri(tool,left[0],left[1],right[0],
                    col.darkened(0.16),col,col.darkened(0.16))
                _tri(tool,right[0],left[1],right[1],
                    col.darkened(0.16),col,col)
                _tri(tool,left[1],left[2],right[1],
                    col,col.lightened(0.09),col)
                _tri(tool,right[1],left[2],right[2],
                    col,col.lightened(0.09),col.lightened(0.09))
    if banks > 0:
        _surface_node(parent,"SedimentosYOrillasSinParedV7",tool)
    return {"shore_edges":banks,"shore_triangles":banks*segments*4,
        "shore_batches":1 if banks>0 else 0}

static func _wave(parent: Node3D, cells: Array[Dictionary],
        indexed: Dictionary, scene: int) -> Dictionary:
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var strips := 0
    for cell in cells:
        if str(cell["kind"]) != "water":
            continue
        var x: int = int(cell["x"])
        var z: int = int(cell["z"])
        var center: Vector3 = cell["center"]
        var north: bool = indexed.get(Vector2i(x,z-1),"") == "water"
        var south: bool = indexed.get(Vector2i(x,z+1),"") == "water"
        var east: bool = indexed.get(Vector2i(x+1,z),"") == "water"
        var west: bool = indexed.get(Vector2i(x-1,z),"") == "water"
        var flow := Vector2(0,1) if (north or south) and not (east and west) else Vector2(1,0)
        var cross := Vector2(-flow.y,flow.x)
        var seed: int = x*439+z*743+scene*251
        var count: int = 0 if _hash(seed+10)<0.18 else 1 if _hash(seed+10)<0.72 else 2
        for k in range(count):
            var r: float = _hash(seed+31+k*43)
            var width: float = 0.010+0.021*r
            var length: float = 0.27+0.61*_hash(seed+13+k*11)
            var start: Vector2 = Vector2(
                (_hash(seed+17+k*31)-0.5)*1.05,
                (_hash(seed+7+k*59)-0.5)*1.05)-flow*length*0.5
            var color := Color(0.57,0.77,0.81,0.13+0.15*r)
            strips += 1
            for i in range(3):
                var t0: float = float(i)/3.0
                var t1: float = float(i+1)/3.0
                var sway0: float = sin(t0*PI+TAU*_hash(seed+19))*0.075
                var sway1: float = sin(t1*PI+TAU*_hash(seed+19))*0.075
                var c0: Vector2 = start+flow*length*t0+cross*sway0
                var c1: Vector2 = start+flow*length*t1+cross*sway1
                var y: float = WATER_LEVEL+0.025
                var a := center+Vector3((c0+cross*width).x,y,(c0+cross*width).y)
                var b := center+Vector3((c0-cross*width).x,y,(c0-cross*width).y)
                var c := center+Vector3((c1+cross*width).x,y,(c1+cross*width).y)
                var d := center+Vector3((c1-cross*width).x,y,(c1-cross*width).y)
                _tri(tool,a,b,c,color,color,color)
                _tri(tool,c,b,d,color,color,color)
    if strips > 0:
        _surface_node(parent,"OndulacionesDispersasV7",tool,true)
    return {"wave_strips":strips,"wave_triangles":strips*6,
        "water_batches":1 if strips>0 else 0}

static func populate(parent: Node3D,cells: Array[Dictionary],scene: int,
        rock: bool = true, shores: bool = true, water: bool = true,
        lithology: bool = false, facets: bool = false,
        sculpted: bool = false) -> Dictionary:
    var kinds: Dictionary = {}
    var mountains: Dictionary = {}
    for cell in cells:
        var key := Vector2i(int(cell["x"]),int(cell["z"]))
        kinds[key] = str(cell["kind"])
        if str(cell["kind"]) == "mountain":
            mountains[key] = cell
    var result := {
        "mountain_cells":0,"ridge_triangles":0,"shore_edges":0,
        "shore_triangles":0,"wave_strips":0,"wave_triangles":0,
        "lithology_cells":0,"facet_cells":0,
        "crest_subdivisions":8,"silhouette_cells":0,"batches":0}
    if rock and not mountains.is_empty():
        var stats: Dictionary = _ridge(parent,cells,mountains,scene,
            lithology,facets,sculpted)
        result["crest_subdivisions"] = stats["crest_subdivisions"]
        result["silhouette_cells"] = stats["silhouette_cells"]
        result["facet_cells"] = int(stats["mountain_cells"]) if facets else 0
        result["lithology_cells"] = int(stats["mountain_cells"]) if lithology else 0
        result["mountain_cells"] = stats["mountain_cells"]
        result["ridge_triangles"] = stats["ridge_triangles"]
        result["batches"] += int(stats["ridge_batches"])
    if shores:
        var stats: Dictionary = _bank(parent,cells,scene)
        result["shore_edges"] = stats["shore_edges"]
        result["shore_triangles"] = stats["shore_triangles"]
        result["batches"] += int(stats["shore_batches"])
    if water:
        var stats: Dictionary = _wave(parent,cells,kinds,scene)
        result["wave_strips"] = stats["wave_strips"]
        result["wave_triangles"] = stats["wave_triangles"]
        result["batches"] += int(stats["water_batches"])
    parent.set_meta("terrain_erosion_v7",result)
    return result
