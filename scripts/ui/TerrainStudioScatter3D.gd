extends RefCounted
class_name TarvokaTerrainScatter3D

# A deterministic, render-only detail pass for the browser art studio.
# Repeated grass, reeds and stones use three MultiMesh batches instead of
# hundreds of separate nodes. No collision or tactical terrain is created.

static func _variation(seed: int, salt: int) -> float:
    return float(posmod(seed * 7919 + salt * 104729 + 193, 65521)) / 65521.0

static func _mat(tint: Color, use_vertex_colors: bool = false) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.vertex_color_use_as_albedo = use_vertex_colors
    mat.roughness = 0.96
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _blade_mesh(width: float, height: float, tint: Color) -> ArrayMesh:
    # Three crossed tapered blades remain visible from every orbit angle.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for blade in range(3):
        var angle: float = float(blade) * PI / 3.0
        var axis := Vector3(cos(angle), 0.0, sin(angle))
        var span: Vector3 = axis * width
        var tip := Vector3(axis.x * width * 0.13, height, axis.z * width * 0.13)
        surface.set_color(tint.darkened(0.18))
        surface.add_vertex(-span)
        surface.set_color(tint.lightened(0.13))
        surface.add_vertex(tip)
        surface.set_color(tint)
        surface.add_vertex(span)
    surface.generate_normals()
    var mesh: ArrayMesh = surface.commit()
    mesh.surface_set_material(0, _mat(Color.WHITE, true))
    return mesh

static func _batch(parent: Node3D, label: String, mesh: Mesh,
        placements: Array[Transform3D]) -> int:
    if placements.is_empty():
        return 0
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = mesh
    multi.instance_count = placements.size()
    for i in range(placements.size()):
        multi.set_instance_transform(i, placements[i])
    var node := MultiMeshInstance3D.new()
    node.name = label
    node.multimesh = multi
    parent.add_child(node)
    return 1

static func _placement(at: Vector3, yaw: float, dimensions: Vector3) -> Transform3D:
    var basis := Basis(Vector3.UP, yaw).scaled(dimensions)
    return Transform3D(basis, at)

static func populate(parent: Node3D, cells: Array[Dictionary],
        preset: int) -> Dictionary:
    var grass: Array[Transform3D] = []
    var reeds: Array[Transform3D] = []
    var gravel: Array[Transform3D] = []
    for cell in cells:
        var x: int = int(cell["x"])
        var z: int = int(cell["z"])
        var kind: String = str(cell["kind"])
        var center: Vector3 = cell["center"]
        var top: float = float(cell["top"])
        var seed: int = x * 7349 + z * 9283 + preset * 5671
        if kind == "plain" or kind == "forest":
            # Leave enough empty ground for roads, vehicles and buildings.
            var quantity: int = 3 if kind == "forest" else 2
            if preset == 1:
                quantity = 1 if kind == "plain" else 2
            for i in range(quantity):
                var rx: float = _variation(seed,i*7+2)
                var rz: float = _variation(seed,i*11+19)
                var at: Vector3 = center + Vector3(
                    (rx-0.5)*1.50,top+0.025,(rz-0.5)*1.50)
                var size: float = 0.70+_variation(seed,i+43)*0.57
                grass.append(_placement(at,_variation(seed,i+67)*TAU,
                    Vector3(size,size,size)))
            # Reeds mark the water-facing edge, never the road or lake bed.
            var edges: Array = cell.get("water_edges",[])
            for side in edges:
                var direction: Vector2i = side
                for i in range(3):
                    var tangent: float = (float(i)-1.0)*0.53+(
                        _variation(seed,i+111)-0.5)*0.16
                    var near_edge: float = 0.89+0.11*_variation(seed,i+109)
                    var dx: float = float(direction.x)*near_edge
                    var dz: float = float(direction.y)*near_edge
                    if direction.x != 0:
                        dz += tangent
                    else:
                        dx += tangent
                    var at := center+Vector3(dx,top+0.01,dz)
                    var size: float = 0.82+_variation(seed,i+131)*0.48
                    reeds.append(_placement(at,_variation(seed,i+151)*TAU,
                        Vector3(size,size,size)))
        if kind == "mountain" or (preset == 1 and kind == "plain"):
            # Broken stone fragments echo the mountains' faceted silhouette.
            for i in range(2):
                var px: float = (_variation(seed,i+179)-0.5)*1.38
                var pz: float = (_variation(seed,i+211)-0.5)*1.38
                var size: float = 0.54+_variation(seed,i+223)*0.60
                gravel.append(_placement(
                    center+Vector3(px,top+0.065,pz),
                    _variation(seed,i+251)*TAU,
                    Vector3(size,0.42*size,0.76*size)))
    var grass_tint: Color = Color("#879c69") if preset == 0 else (
        Color("#ae9c71") if preset == 1 else Color("#589479"))
    var reed_tint := Color("#afad72") if preset != 1 else Color("#a59c78")
    var rock_tint: Color = Color("#858f8e") if preset != 1 else Color("#927d72")
    var pebbles := SphereMesh.new()
    pebbles.radius = 0.23
    pebbles.height = 0.36
    pebbles.radial_segments = 6
    pebbles.rings = 3
    pebbles.material = _mat(rock_tint)
    var batches: int = 0
    batches += _batch(parent,"HierbaInstanciadaV3",
        _blade_mesh(0.16,0.38,grass_tint),grass)
    batches += _batch(parent,"JuncosDeRiberaInstanciadosV3",
        _blade_mesh(0.105,0.82,reed_tint),reeds)
    batches += _batch(parent,"GravaInstanciadaV3",pebbles,gravel)
    var stats: Dictionary = {
        "grass":grass.size(),"reeds":reeds.size(),
        "gravel":gravel.size(),"batches":batches}
    parent.set_meta("terrain_scatter_v3",stats)
    return stats
