extends RefCounted
class_name TarvokaG13BodyJoineryV38

# G13 V38 — finish actual 3D silhouette around cab roof ends and flank joints.
# Visual-only, additive to V37. No new weapons, recoloring, animations,
# radar movement, stats, collisions or changes to approved meshes.
const FLAG := "tarvoka_g13_v38_silhouette_joinery"
const PREVIOUS := "tarvoka_g13_v37_roof_hood_radar_finish"
const ROOF := "G13_V38_RoofRearEndCaps"
const SIDE := "G13_V38_RearCabArmoredSaddles"
const FASTENERS := "G13_V38_JointAndBumperFasteners"
const ROOF_TRIANGLES := 40
const SIDE_TRIANGLES := 32
const FIXINGS := 12
const DRAW_NODES := 3

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metal
    material.roughness = rough
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

static func _tri(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    surface.set_normal(normal)
    surface.add_vertex(a)
    surface.set_normal(normal)
    surface.add_vertex(b)
    surface.set_normal(normal)
    surface.add_vertex(c)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    _tri(surface, a, b, c)
    _tri(surface, a, c, d)

static func _closed_loft(surface: SurfaceTool,
        front: Array[Vector3], rear: Array[Vector3]) -> void:
    # Closed polygonal prism: two capped ends and contiguous sidewalls.
    var size: int = front.size()
    for i in range(1, size - 1):
        _tri(surface, front[0], front[i], front[i + 1])
        _tri(surface, rear[0], rear[i + 1], rear[i])
    for i in range(size):
        var next_i: int = (i + 1) % size
        _quad(surface, front[i], rear[i], rear[next_i], front[next_i])

static func _roof_cap() -> ArrayMesh:
    # LOD13 and LOD8: close V37's roof rails at the back of the cab,
    # outside the original roof hatch, and blend into existing armored roof.
    # Front starts 15mm inside V37 sculpt's rear edge (z=-0.275).
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var near_profile: Array[Vector2] = [
        Vector2(0.565, 1.429), Vector2(0.572, 1.447),
        Vector2(0.590, 1.452), Vector2(0.623, 1.449),
        Vector2(0.642, 1.435), Vector2(0.636, 1.416)
    ]
    var far_profile: Array[Vector2] = [
        Vector2(0.554, 1.396), Vector2(0.566, 1.413),
        Vector2(0.581, 1.419), Vector2(0.613, 1.416),
        Vector2(0.630, 1.397), Vector2(0.625, 1.381)
    ]
    for side in [-1, 1]:
        var s: float = float(side)
        var near: Array[Vector3] = []
        var far: Array[Vector3] = []
        for p in near_profile:
            near.append(Vector3(s * p.x, p.y, -0.290))
        for p in far_profile:
            far.append(Vector3(s * p.x, p.y, -0.152))
        _closed_loft(st, near, far)
    return st.commit()

static func _side_saddles() -> ArrayMesh:
    # Bridges V33's cab/chassis shoulder end at z=-0.325 to the
    # rear of the cab around z=-0.117. Deliberately stays inside x=.70,
    # clear of V32 flank paint at x=.726 and turret rotation.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var front_section: Array[Vector2] = [
        Vector2(0.575, 1.202), Vector2(0.630, 1.160),
        Vector2(0.685, 1.024), Vector2(0.688, 0.895),
        Vector2(0.621, 0.876)
    ]
    var rear_section: Array[Vector2] = [
        Vector2(0.565, 1.140), Vector2(0.627, 1.120),
        Vector2(0.678, 1.004), Vector2(0.678, 0.890),
        Vector2(0.616, 0.870)
    ]
    for side in [-1, 1]:
        var s: float = float(side)
        var a: Array[Vector3] = []
        var b: Array[Vector3] = []
        for p in front_section:
            a.append(Vector3(s * p.x, p.y, -0.338))
        for p in rear_section:
            b.append(Vector3(s * p.x, p.y, -0.117))
        _closed_loft(st, a, b)
    return st.commit()

static func _fixings() -> Array[Transform3D]:
    var result: Array[Transform3D] = []
    var side_basis := Basis(Vector3.FORWARD, PI * 0.5)
    var rear_basis := Basis(Vector3.RIGHT, PI * 0.5)
    for side in [-1, 1]:
        var s: float = float(side)
        # Four side rivets each, on the cab's new angled protector.
        for y in [0.937, 1.066]:
            for z in [-0.260, -0.172]:
                result.append(Transform3D(
                    side_basis, Vector3(s * 0.698, float(y), float(z))))
    # Four small rear bumper fasteners, lower than the service insignia.
    for x in [-0.420, -0.250, 0.250, 0.420]:
        result.append(Transform3D(rear_basis,
            Vector3(float(x), 0.511, 1.399)))
    return result

static func _sculpt(parent: Node3D, name: String,
        mesh: Mesh, coat: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = mesh
    part.material_override = coat
    parent.add_child(part)

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var body := root.find_child("G13_Casco4x4", true, false) as Node3D
    var roof := root.find_child(
        "G13_V37_SculptedRoofShoulders", true, false) as MeshInstance3D
    var shoulders := root.find_child(
        "G13_V33_CabChassisTransitions", true, false) as MeshInstance3D
    var bumpers := root.find_child(
        "G13_V34_ReinforcedBumpers", true, false) as MultiMeshInstance3D
    var tint := root.find_child(
        "G13_TurretFaction_1", true, false) as MeshInstance3D
    if body == null or roof == null or shoulders == null or (
            bumpers == null or tint == null):
        return false
    for part in [roof, shoulders, bumpers]:
        if part.get_parent() != body:
            return false
    var mesh_roof := _roof_cap()
    var mesh_sides := _side_saddles()
    var fixings := _fixings()
    if mesh_roof == null or mesh_sides == null or fixings.size() != FIXINGS:
        return false
    if mesh_roof.get_surface_count() != 1 or (
            mesh_roof.get_faces().size() != ROOF_TRIANGLES * 3) or (
            mesh_sides.get_surface_count() != 1) or (
            mesh_sides.get_faces().size() != SIDE_TRIANGLES * 3):
        return false

    _sculpt(body, ROOF, mesh_roof,
        _mat(Color("#708185"), 0.37, 0.67))
    _sculpt(body, SIDE, mesh_sides,
        _mat(Color("#607075"), 0.33, 0.73))
    var bolt := CylinderMesh.new()
    bolt.top_radius = 0.010
    bolt.bottom_radius = 0.012
    bolt.height = 0.016
    bolt.radial_segments = 8
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = bolt
    mm.instance_count = fixings.size()
    for i in range(fixings.size()):
        mm.set_instance_transform(i, fixings[i])
    var fasteners := MultiMeshInstance3D.new()
    fasteners.name = FASTENERS
    fasteners.multimesh = mm
    fasteners.material_override = _mat(Color("#9ba8aa"), 0.58, 0.50)
    body.add_child(fasteners)

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v38_visual_only", true)
    root.set_meta("tarvoka_g13_v38_roof_caps", 2)
    root.set_meta("tarvoka_g13_v38_cab_saddles", 2)
    root.set_meta("tarvoka_g13_v38_metal_fasteners", FIXINGS)
    root.set_meta("tarvoka_g13_v38_extra_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v38_weapons", "twin_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    # Real same-scene comparison against V37: do not clone the rig.
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var nodes: Array[VisualInstance3D] = []
    for label in [ROOF, SIDE, FASTENERS]:
        var node := root.find_child(label, true, false) as VisualInstance3D
        if node == null:
            return false
        nodes.append(node)
    for node in nodes:
        node.visible = enabled
    root.set_meta("tarvoka_g13_v38_preview_enabled", enabled)
    return true
