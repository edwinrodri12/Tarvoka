extends RefCounted
class_name TarvokaG13ChassisFinishV33

# G13 V33: wheel-arch, service-hinge and cab-to-chassis native sculpture.
# Art-only on the existing 4x4 G13, for BOTH the LOD8 tactical and LOD13 hero
# models. Zero changes to wheels, animations, combat, paint identities or rigs.
const FLAG := "tarvoka_g13_v33_arch_hinge_transition"
const REQUIRE_V32 := "tarvoka_g13_v32_faction_mount_finish"
const ARCH := "G13_V33_CurvedFenderArch"
const LIP := "G13_V33_FenderLip"
const CAB_JOINT := "G13_V33_CabChassisTransitions"
const HINGE := "G13_V33_ServiceHinges"
const RADIUS_TIRE := 0.31
const RADIUS_TREAD_BOUND := 0.324
const ARCH_INSIDE := 0.354
const ARCH_OUTSIDE := 0.419
const ARCH_SEGMENTS := 12
const AXLE_Z := 0.85
const AXLE_Y := 0.33
const ARCH_X := 0.755
const MIN_RADIAL_GAP := 0.026

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metal
    material.roughness = rough
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    return material

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var n: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(b)
    st.set_normal(n)
    st.add_vertex(c)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    _tri(st, a, b, c)
    _tri(st, a, c, d)

static func _arc(angle: float, radius: float, x: float) -> Vector3:
    # The circle is in the wheel's YZ plane; its upper semicircle remains
    # above the center so the fender never fills the tire or hub space.
    return Vector3(x, sin(angle) * radius, cos(angle) * radius)

static func _curve_mesh(inner: float, outer: float,
        x_half: float, start_angle: float, end_angle: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(ARCH_SEGMENTS):
        var a0: float = lerpf(start_angle, end_angle,
            float(i) / float(ARCH_SEGMENTS))
        var a1: float = lerpf(start_angle, end_angle,
            float(i + 1) / float(ARCH_SEGMENTS))
        var p0 := _arc(a0, inner, -x_half)
        var p1 := _arc(a1, inner, -x_half)
        var q0 := _arc(a0, outer, -x_half)
        var q1 := _arc(a1, outer, -x_half)
        var r0 := _arc(a0, inner, x_half)
        var r1 := _arc(a1, inner, x_half)
        var s0 := _arc(a0, outer, x_half)
        var s1 := _arc(a1, outer, x_half)
        _quad(st, p0, p1, q1, q0)
        _quad(st, r0, s0, s1, r1)
        _quad(st, q0, q1, s1, s0)
        _quad(st, r0, r1, p1, p0)
        if i == 0:
            _quad(st, p0, q0, s0, r0)
        if i == ARCH_SEGMENTS - 1:
            _quad(st, p1, r1, s1, q1)
    return st.commit()

static func _joint_mesh() -> ArrayMesh:
    # A continuous bevelled triangular cab shoulder: the thin top is
    # physically IN the cab side while the wider foot lands on the hull.
    # Near cab rear (-Z); does not cover V32 side enamel or the windows.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        var s: float = float(side)
        var outline: Array[Vector2] = [
            Vector2(0.557, 1.155),
            Vector2(0.622, 1.137),
            Vector2(0.714, 0.842),
            Vector2(0.695, 0.795),
            Vector2(0.561, 0.790)
        ]
        var front: Array[Vector3] = []
        var back: Array[Vector3] = []
        for p in outline:
            front.append(Vector3(s * p.x, p.y, -0.455))
            back.append(Vector3(s * p.x, p.y, -0.325))
        for i in range(1, outline.size() - 1):
            _tri(st, front[0], front[i], front[i + 1])
            _tri(st, back[0], back[i + 1], back[i])
        for i in range(outline.size()):
            var j: int = (i + 1) % outline.size()
            _quad(st, front[i], back[i], back[j], front[j])
    return st.commit()

static func _batch(parent: Node3D, label: String, shape: Mesh,
        coat: Material, poses: Array[Transform3D]) -> MultiMeshInstance3D:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = shape
    mm.instance_count = poses.size()
    for i in range(poses.size()):
        mm.set_instance_transform(i, poses[i])
    var node := MultiMeshInstance3D.new()
    node.name = label
    node.multimesh = mm
    node.material_override = coat
    parent.add_child(node)
    return node

static func _wheel_positions() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    for side in [-1, 1]:
        for axle in [-1, 1]:
            poses.append(Transform3D(Basis.IDENTITY,
                Vector3(float(side) * ARCH_X, AXLE_Y, float(axle) * AXLE_Z)))
    return poses

static func _service_hinges(high_detail: bool) -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    # A rear service door exists on LOD13. On LOD8, the small hinge pair
    # sits on the existing rear engine-cover lid (there is no service door).
    var y: float = 0.98 if high_detail else 1.128
    var z: float = 1.311 if high_detail else 0.985
    var orient: Basis = Basis(Vector3.RIGHT, PI * 0.5) if (
        high_detail) else Basis.IDENTITY
    for side in [-1, 1]:
        var s: float = float(side)
        for offset in [-0.068, 0.068]:
            poses.append(Transform3D(orient,
                Vector3(s * 0.411, y + (offset if high_detail else 0.0),
                    z + (0.0 if high_detail else offset))))
    return poses

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(REQUIRE_V32, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    if ARCH_INSIDE - RADIUS_TREAD_BOUND < MIN_RADIAL_GAP:
        return false
    var body := root.find_child("G13_Casco4x4", true, false) as Node3D
    var cab := root.find_child("G13_SealedCab", true, false) as MeshInstance3D
    var cover := root.find_child("G13_EngineCover", true, false) as MeshInstance3D
    var wheels := root.find_child(
        "G13_Ruedas4x4MultiMesh", true, false) as MultiMeshInstance3D
    var high_detail: bool = bool(
        root.get_meta("tarvoka_g13_v1_high_detail", true))
    if body == null or cab == null or cover == null or wheels == null or (
            cab.get_parent() != body or cover.get_parent() != body) or (
            wheels.get_parent() != body):
        return false
    var door := root.find_child("G13_RearServiceDoor", true, false)
    if high_detail and door == null:
        return false
    var arch_mesh := _curve_mesh(
        ARCH_INSIDE, ARCH_OUTSIDE, 0.056, 0.0, PI)
    var lip_mesh := _curve_mesh(
        0.418, 0.432, 0.058, 0.42, PI - 0.42)
    var joint_mesh := _joint_mesh()
    if arch_mesh == null or lip_mesh == null or joint_mesh == null:
        return false
    if arch_mesh.get_surface_count() != 1 or (
            lip_mesh.get_surface_count() != 1 or (
            joint_mesh.get_surface_count() != 1)):
        return false
    var hinge_mesh := CylinderMesh.new()
    hinge_mesh.top_radius = 0.020
    hinge_mesh.bottom_radius = 0.020
    hinge_mesh.height = 0.082
    hinge_mesh.radial_segments = 10

    var dark_coat := _mat(Color("#39454a"), 0.32, 0.77)
    var edge_coat := _mat(Color("#7b888a"), 0.48, 0.63)
    var hinge_coat := _mat(Color("#98a5a5"), 0.52, 0.57)
    var wheel_poses := _wheel_positions()
    _batch(body, ARCH, arch_mesh, dark_coat, wheel_poses)
    _batch(body, LIP, lip_mesh, edge_coat, wheel_poses)
    var joint := MeshInstance3D.new()
    joint.name = CAB_JOINT
    joint.mesh = joint_mesh
    joint.material_override = dark_coat
    body.add_child(joint)
    _batch(body, HINGE, hinge_mesh, hinge_coat,
        _service_hinges(high_detail))
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v33_visual_only", true)
    root.set_meta("tarvoka_g13_v33_archs", 4)
    root.set_meta("tarvoka_g13_v33_radial_gap_m",
        ARCH_INSIDE - RADIUS_TREAD_BOUND)
    root.set_meta("tarvoka_g13_v33_service_hinges", 4)
    root.set_meta("tarvoka_g13_v33_draw_nodes_added", 4)
    root.set_meta("tarvoka_g13_v33_weapons", "two_original_autocannons")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var labels := [ARCH, LIP, CAB_JOINT, HINGE]
    var nodes: Array[VisualInstance3D] = []
    for label in labels:
        var node := root.find_child(label, true, false) as VisualInstance3D
        if node == null:
            return false
        nodes.append(node)
    for node in nodes:
        node.visible = enabled
    root.set_meta("tarvoka_g13_v33_preview_enabled", enabled)
    return true
