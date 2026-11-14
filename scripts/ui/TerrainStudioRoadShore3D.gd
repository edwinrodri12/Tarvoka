extends RefCounted
class_name TarvokaTerrainRoadShore3D

# A preview-only, slope-following surface treatment. The existing tactical
# movement/bridge/river system remains independent of this decoration mesh.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const ASPHALT := Color("#5b6063")
const SHOULDER := Color("#938c78")
const MARKINGS := Color("#f0e5bd")
const SHORE := Color("#c0b28b")

static func _point(at: Vector3, cell: Dictionary, dx: float,
        dz: float, lift: float) -> Vector3:
    var corners: PackedFloat32Array = cell["corners"]
    return at+Vector3(dx,Sampler.height(float(cell["top"]),corners,
        dx,dz,float(cell["half"]))+lift,dz)

static func _tri(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, shade: Color) -> void:
    for point in [a,b,c]:
        surface.set_color(shade)
        surface.set_uv(Vector2(point.x*0.14,point.z*0.14))
        surface.add_vertex(point)

static func _rect(surface: SurfaceTool, at: Vector3, cell: Dictionary,
        x0: float, x1: float, z0: float, z1: float,
        color: Color, height_offset: float = 0.05) -> void:
    # Two subdivisions per axis make road surface follow the four-face fan
    # instead of floating above ramps or cutting through mountains.
    for row in range(2):
        var za: float = lerpf(z0,z1,float(row)*0.5)
        var zb: float = lerpf(z0,z1,float(row+1)*0.5)
        for col in range(2):
            var xa: float = lerpf(x0,x1,float(col)*0.5)
            var xb: float = lerpf(x0,x1,float(col+1)*0.5)
            var nw: Vector3 = _point(at,cell,xa,za,height_offset)
            var ne: Vector3 = _point(at,cell,xb,za,height_offset)
            var se: Vector3 = _point(at,cell,xb,zb,height_offset)
            var sw: Vector3 = _point(at,cell,xa,zb,height_offset)
            _tri(surface,nw,sw,ne,color)
            _tri(surface,ne,sw,se,color)

static func _finish(parent: Node3D, label: String,
        triangles: SurfaceTool) -> MeshInstance3D:
    triangles.generate_normals()
    triangles.generate_tangents()
    var mesh := MeshInstance3D.new()
    mesh.name = label
    mesh.mesh = triangles.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.95
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material
    parent.add_child(mesh)
    return mesh

static func road(parent: Node3D, at: Vector3, cell: Dictionary,
        connected: Dictionary) -> MeshInstance3D:
    var asphalt := SurfaceTool.new()
    asphalt.begin(Mesh.PRIMITIVE_TRIANGLES)
    var center_width: float = 0.68
    var border_width: float = 0.76
    var half: float = float(cell["half"])
    # Draw the shoulder beneath the asphalt, with visible narrow edges.
    for layer in range(2):
        var width: float = border_width if layer == 0 else center_width
        var material: Color = SHOULDER if layer == 0 else ASPHALT
        var lift: float = 0.033 if layer == 0 else 0.060
        _rect(asphalt,at,cell,-width,width,-width,width,material,lift)
        if bool(connected.get("north",false)):
            _rect(asphalt,at,cell,-width,width,-half,-width,material,lift)
        if bool(connected.get("south",false)):
            _rect(asphalt,at,cell,-width,width,width,half,material,lift)
        if bool(connected.get("west",false)):
            _rect(asphalt,at,cell,-half,-width,-width,width,material,lift)
        if bool(connected.get("east",false)):
            _rect(asphalt,at,cell,width,half,-width,width,material,lift)
    # Dashed road markings on straights only. No lines over crossroads.
    var n: bool = bool(connected.get("north",false))
    var s: bool = bool(connected.get("south",false))
    var w: bool = bool(connected.get("west",false))
    var e: bool = bool(connected.get("east",false))
    if n and s and not e and not w:
        for z_center in [-0.83,0.0,0.83]:
            _rect(asphalt,at,cell,-0.038,0.038,
                z_center-0.19,z_center+0.19,MARKINGS,0.078)
    elif e and w and not n and not s:
        for x_center in [-0.83,0.0,0.83]:
            _rect(asphalt,at,cell,x_center-0.19,x_center+0.19,
                -0.038,0.038,MARKINGS,0.078)
    return _finish(parent,"CalzadaContinuaV3_%d_%d" % [
        int(cell["x"]),int(cell["z"])],asphalt)

static func shore(parent: Node3D, at: Vector3, cell: Dictionary,
        edges: Array[Vector2i], scene: int) -> int:
    if edges.is_empty():
        return 0
    var beach := SurfaceTool.new()
    beach.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half: float = float(cell["half"])
    var color: Color = SHORE if scene != 1 else Color("#b29a7b")
    # Each beach lip follows the actual land slope at its water boundary.
    for direction in edges:
        if direction.x > 0:
            _rect(beach,at,cell,half-0.25,half-0.05,
                -half+0.12,half-0.12,color,0.036)
        elif direction.x < 0:
            _rect(beach,at,cell,-half+0.05,-half+0.25,
                -half+0.12,half-0.12,color,0.036)
        elif direction.y > 0:
            _rect(beach,at,cell,-half+0.12,half-0.12,
                half-0.25,half-0.05,color,0.036)
        else:
            _rect(beach,at,cell,-half+0.12,half-0.12,
                -half+0.05,-half+0.25,color,0.036)
    _finish(parent,"OrillaConPendienteV3_%d_%d" % [
        int(cell["x"]),int(cell["z"])],beach)
    return edges.size()
