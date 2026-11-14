extends RefCounted
class_name TarvokaTerrainStudioDetailV5

# Visual-only detail pass for the native WebGL studio. The tactical grid,
# LOS, roads, bridges, pathfinding and saves are completely unaffected.
# All river-bank transitions use the SAME triangle-fan surface sampler as V2.
# Three batched draw nodes at most: shoreline, water currents, mountain gravel.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const WATER_LEVEL := -0.17
const SHORE_TONES := [
    Color("#b2ad88"),Color("#ad9479"),Color("#c0b59a")]
const ROCK := Color("#82959a")

static func _hash(seed: int) -> float:
    return float(posmod(seed*7927+9973,65521))/65521.0

static func _point(cell: Dictionary, offset: Vector2, extra_y: float) -> Vector3:
    var center: Vector3 = cell["center"]
    var height: float = Sampler.height(float(cell["top"]),
        cell["corners"],offset.x,offset.y,float(cell["half"]))
    return center+Vector3(offset.x,height+extra_y,offset.y)

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
    for item in [[a,ca],[b,cb],[c,cc]]:
        var pos: Vector3 = item[0]
        tool.set_color(item[1])
        tool.set_uv(Vector2(pos.x*0.13,pos.z*0.13))
        tool.add_vertex(pos)

static func _finish(parent: Node3D, name: String,
        surface: SurfaceTool, translucent: bool) -> MeshInstance3D:
    surface.generate_normals()
    var node := MeshInstance3D.new()
    node.name = name
    node.mesh = surface.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.roughness = 0.84 if translucent else 0.97
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    if translucent:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    node.material_override = mat
    node.set_meta("visual_only",true)
    parent.add_child(node)
    return node

static func _bank_point(cell: Dictionary, dir: Vector2i,
        lateral: float, outward: float, at_water: bool) -> Vector3:
    var tangent := Vector2(-float(dir.y),float(dir.x))
    var direction := Vector2(float(dir.x),float(dir.y))
    var offset: Vector2 = tangent*lateral+direction*outward
    if at_water:
        var center: Vector3 = cell["center"]
        return center+Vector3(offset.x,WATER_LEVEL+0.026,offset.y)
    return _point(cell,offset,0.018)

static func _bank(tool: SurfaceTool, cell: Dictionary,
        side: Vector2i, preset: int) -> void:
    # Model the exposed shore as a gently sloped transition, rather than
    # the sheer cliff and unnaturally rectangular water edge of V4.
    var half: float = float(cell["half"])
    var shore_color: Color = SHORE_TONES[clampi(preset,0,2)]
    var upper: Color = shore_color.darkened(0.15)
    var middle: Color = shore_color
    var toe: Color = shore_color.lightened(0.16)
    for section in range(4):
        var left: float = lerpf(-half+0.10,half-0.10,float(section)/4.0)
        var right: float = lerpf(-half+0.10,half-0.10,float(section+1)/4.0)
        var a: Vector3 = _bank_point(cell,side,left,half-0.32,false)
        var b: Vector3 = _bank_point(cell,side,right,half-0.32,false)
        var c: Vector3 = _bank_point(cell,side,left,half-0.015,false)
        var d: Vector3 = _bank_point(cell,side,right,half-0.015,false)
        var e: Vector3 = _bank_point(cell,side,left,half+0.20,true)
        var f: Vector3 = _bank_point(cell,side,right,half+0.20,true)
        _triangle(tool,a,c,b,upper,middle,upper)
        _triangle(tool,b,c,d,upper,middle,middle)
        _triangle(tool,c,e,d,middle,toe,middle)
        _triangle(tool,d,e,f,middle,toe,toe)

static func _water_ripple(tool: SurfaceTool, cell: Dictionary,
        preset: int, index: int) -> void:
    var x: int = int(cell["x"])
    var z: int = int(cell["z"])
    var origin: Vector3 = cell["center"]
    var variation: float = _hash(x*239+z*179+preset*83+index*47)
    var direction: Vector2 = Vector2(0,1) if preset == 1 else Vector2(1,0)
    var across := Vector2(-direction.y,direction.x)
    var length: float = 0.38+variation*0.46
    var width: float = 0.030+variation*0.030
    var middle: Vector2 = Vector2(
        (variation-0.5)*0.65,
        (_hash(z*173+x*53+index*43)-0.5)*0.60)
    var start: Vector2 = middle-direction*length
    var finish: Vector2 = middle+direction*length
    var y: float = WATER_LEVEL+0.038+float(index)*0.004
    var a: Vector3 = origin+Vector3(
        start.x+across.x*width,y,start.y+across.y*width)
    var b: Vector3 = origin+Vector3(
        start.x-across.x*width,y,start.y-across.y*width)
    var c: Vector3 = origin+Vector3(
        finish.x+across.x*width,y,finish.y+across.y*width)
    var d: Vector3 = origin+Vector3(
        finish.x-across.x*width,y,finish.y-across.y*width)
    var water_color := Color(0.67,0.85,0.88,0.20+variation*0.15)
    _triangle(tool,a,b,c,water_color,water_color,water_color)
    _triangle(tool,c,b,d,water_color,water_color,water_color)

static func populate(parent: Node3D, cells: Array[Dictionary],
        preset: int, show_shores: bool = true,
        show_flow: bool = true, show_rocks: bool = true) -> Dictionary:
    var shore := SurfaceTool.new()
    shore.begin(Mesh.PRIMITIVE_TRIANGLES)
    var flow := SurfaceTool.new()
    flow.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rocks: Array[Transform3D] = []
    var banks: int = 0
    var ripples: int = 0
    for cell in cells:
        var kind: String = str(cell["kind"])
        var x: int = int(cell["x"])
        var z: int = int(cell["z"])
        if show_shores and kind != "water":
            for side in cell.get("water_edges",[]):
                _bank(shore,cell,side,preset)
                banks += 1
        if show_flow and kind == "water":
            for i in range(2):
                _water_ripple(flow,cell,preset,i)
                ripples += 1
        if show_rocks and kind == "mountain":
            var origin: Vector3 = cell["center"]
            for i in range(3):
                var a: float = TAU*_hash(x*113+z*307+i*41+preset*61)
                var radial: float = 0.69+_hash(z*79+x*53+i*33)*0.31
                var pos: Vector3 = origin+Vector3(
                    cos(a)*radial,float(cell["top"])+0.11,
                    sin(a)*radial)
                var scale: float = 0.45+_hash(x*43+z*23+i*57)*0.48
                var basis := Basis(Vector3.UP,a).scaled(
                    Vector3(scale,scale*0.66,scale*0.80))
                rocks.append(Transform3D(basis,pos))
    var batches: int = 0
    if banks > 0:
        _finish(parent,"TaludesNaturalesDeRiberaV5",shore,false)
        batches += 1
    if ripples > 0:
        _finish(parent,"CorrientesSuavesDeAguaV5",flow,true)
        batches += 1
    if not rocks.is_empty():
        var pebble := SphereMesh.new()
        pebble.radius = 0.27
        pebble.height = 0.48
        pebble.radial_segments = 7
        pebble.rings = 4
        var mat := StandardMaterial3D.new()
        mat.albedo_color = ROCK if preset != 1 else Color("#958a7e")
        mat.roughness = 0.94
        pebble.material = mat
        var multi := MultiMesh.new()
        multi.transform_format = MultiMesh.TRANSFORM_3D
        multi.mesh = pebble
        multi.instance_count = rocks.size()
        for i in range(rocks.size()):
            multi.set_instance_transform(i,rocks[i])
        var node := MultiMeshInstance3D.new()
        node.name = "PedregalEstratificadoV5"
        node.multimesh = multi
        node.set_meta("visual_only",true)
        parent.add_child(node)
        batches += 1
    var stats := {
        "banks":banks,"ripples":ripples,
        "rocks":rocks.size(),"batches":batches}
    parent.set_meta("terrain_detail_v5",stats)
    return stats
