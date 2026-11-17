extends RefCounted
class_name TarvokaG13ProportionFinishV36

# G13 V36 / ART ONLY. Connect the four V33 wheel arches to the actual hull,
# taper the rear-quarter armor into the existing V34 bumper, and anchor the
# V35 exhausts. No new weapons, rig changes, paint, radar or gameplay rules.
const FLAG := "tarvoka_g13_v36_proportion_and_joinery"
const PREVIOUS := "tarvoka_g13_v35_rear_service_exhaust"
const FENDERS := "G13_V36_FenderBridgeSculpt"
const REAR := "G13_V36_RearQuarterTapers"
const HANGERS := "G13_V36_ExhaustSupportBrackets"
const ARC_SEGMENTS := 8
const TIRE_CENTER_Y := 0.33
const AXLE_Z := 0.85
const ARCH_INNER_RADIUS := 0.405
const ARCH_OUTER_RADIUS := 0.436
const ARCH_START := 1.06
const ARCH_END := 2.08
const REAR_STATIONS := 4
const DRAW_NODES := 3
const EXPECTED_RIM_FACES := 272
const EXPECTED_REAR_FACES := 56

static func _coat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3) -> void:
    _tri(st, a, b, c)
    _tri(st, a, c, d)

static func _arch_section(side: int, axle: int, theta: float) -> Array[Vector3]:
    var sx: float = float(side)
    var z0: float = float(axle) * AXLE_Z
    var points: Array[Vector3] = []
    # The inner X=0.661 section overlaps the original hull wall at X=0.675.
    # The outer X=0.719 section overlaps V33's existing 0.699..0.811 fender.
    # Radial 0.405..0.436 intersects V33's 0.354..0.419 metal by 14 mm.
    for sample in [
        Vector2(0.661, ARCH_INNER_RADIUS),
        Vector2(0.719, ARCH_INNER_RADIUS),
        Vector2(0.719, ARCH_OUTER_RADIUS),
        Vector2(0.661, ARCH_OUTER_RADIUS)
    ]:
        points.append(Vector3(
            sx * sample.x,
            TIRE_CENTER_Y + sample.y * sin(theta),
            z0 + sample.y * cos(theta)))
    return points

static func _wheel_bridge_mesh() -> ArrayMesh:
    # Four shallow closed curved saddle sections, one on every wheel arch.
    # One mesh/material/draw node, not eight independent scene nodes.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        for axle in [-1, 1]:
            for i in range(ARC_SEGMENTS):
                var a0: float = lerpf(ARCH_START, ARCH_END,
                    float(i) / float(ARC_SEGMENTS))
                var a1: float = lerpf(ARCH_START, ARCH_END,
                    float(i + 1) / float(ARC_SEGMENTS))
                var first := _arch_section(side, axle, a0)
                var last := _arch_section(side, axle, a1)
                for k in range(4):
                    var j: int = (k + 1) % 4
                    _quad(st, first[k], first[j], last[j], last[k])
                if i == 0:
                    _quad(st, first[0], first[3], first[2], first[1])
                if i == ARC_SEGMENTS - 1:
                    _quad(st, last[0], last[1], last[2], last[3])
    return st.commit()

static func _rear_section(side: int, station: int) -> Array[Vector3]:
    var s: float = float(side)
    # The joint narrows as the rear wheel arch blends into the existing
    # V34 bumper corner. The bumper ends around X=0.609, and the terminal
    # cross-section X=0.583..0.604 genuinely intersects that face.
    var z_coords := [1.065, 1.135, 1.206, 1.286]
    var upper := [0.681, 0.646, 0.603, 0.560]
    var lower := [0.622, 0.585, 0.548, 0.506]
    var outer := [0.721, 0.697, 0.654, 0.604]
    var z: float = float(z_coords[station])
    var y0: float = float(lower[station])
    var y1: float = float(upper[station])
    var x0: float = 0.583
    var x1: float = float(outer[station])
    return [
        Vector3(s * x0, y0, z), Vector3(s * x1, y0, z),
        Vector3(s * x1, y1, z), Vector3(s * x0, y1, z)
    ]

static func _rear_transition_mesh() -> ArrayMesh:
    # Pair of watertight, faceted tapered quarter panels, visibly bridging
    # the rear arch into the physical V34 bumper—not separate floating tabs.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        for station in range(REAR_STATIONS - 1):
            var a := _rear_section(side, station)
            var b := _rear_section(side, station + 1)
            for k in range(4):
                var j: int = (k + 1) % 4
                _quad(st, a[k], a[j], b[j], b[k])
        var nose := _rear_section(side, 0)
        var tail := _rear_section(side, REAR_STATIONS - 1)
        _quad(st, nose[0], nose[3], nose[2], nose[1])
        _quad(st, tail[0], tail[1], tail[2], tail[3])
    return st.commit()

static func _exhaust_hangers() -> Array[Transform3D]:
    var result: Array[Transform3D] = []
    for side in [-1, 1]:
        # Bottom y=0.549 intersects the old bumper top y=0.564;
        # top y=0.634 overlaps the existing hollow V35 outlet underside.
        result.append(Transform3D(
            Basis.IDENTITY.scaled(Vector3(0.058, 0.085, 0.075)),
            Vector3(float(side) * 0.379, 0.591, 1.301)))
    return result

static func _add_mesh(parent: Node3D, label: String,
        shape: Mesh, material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = shape
    part.material_override = material
    parent.add_child(part)

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    # Absolute invariants from V1/V33, never reposition moving wheel geometry.
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var wheel := root.find_child(
        "G13_Ruedas4x4MultiMesh", true, false) as MultiMeshInstance3D
    var arch := root.find_child(
        "G13_V33_CurvedFenderArch", true, false) as MultiMeshInstance3D
    var bumper := root.find_child(
        "G13_V34_ReinforcedBumpers", true, false) as MultiMeshInstance3D
    var outlet := root.find_child(
        "G13_V35_ExhaustOutlets", true, false) as MultiMeshInstance3D
    if hull == null or wheel == null or arch == null or (
            bumper == null or outlet == null):
        return false
    if wheel.get_parent() != hull or arch.get_parent() != hull or (
            bumper.get_parent() != hull or outlet.get_parent() != hull):
        return false
    if ARCH_INNER_RADIUS <= 0.324 or ARCH_OUTER_RADIUS <= 0.419:
        return false
    var rim_mesh := _wheel_bridge_mesh()
    var rear_mesh := _rear_transition_mesh()
    # 4 wheels * (8 bands * 4 quads * 2 triangles + 2 caps * 2 triangles)
    # 2 rear panels * (3 stations * 4 quads * 2 + 2 caps * 2)
    if rim_mesh == null or rear_mesh == null or (
            rim_mesh.get_faces().size() != EXPECTED_RIM_FACES * 3) or (
            rear_mesh.get_faces().size() != EXPECTED_REAR_FACES * 3):
        return false

    _add_mesh(hull, FENDERS, rim_mesh,
        _coat(Color("#647378"), 0.38, 0.73))
    _add_mesh(hull, REAR, rear_mesh,
        _coat(Color("#526369"), 0.42, 0.68))
    var beam := BoxMesh.new()
    beam.size = Vector3.ONE
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = beam
    var brackets := _exhaust_hangers()
    mm.instance_count = brackets.size()
    for i in range(brackets.size()):
        mm.set_instance_transform(i, brackets[i])
    var hangers := MultiMeshInstance3D.new()
    hangers.name = HANGERS
    hangers.multimesh = mm
    hangers.material_override = _coat(Color("#364249"), 0.47, 0.69)
    hull.add_child(hangers)

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v36_visual_only", true)
    root.set_meta("tarvoka_g13_v36_joined_fenders", 4)
    root.set_meta("tarvoka_g13_v36_rear_fairings", 2)
    root.set_meta("tarvoka_g13_v36_exhaust_hangers", brackets.size())
    root.set_meta("tarvoka_g13_v36_added_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v36_added_triangles",
        EXPECTED_RIM_FACES + EXPECTED_REAR_FACES + 12 * brackets.size())
    root.set_meta("tarvoka_g13_v36_weapons_unchanged",
        "two_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    # Same faction/camera/LOD/pose. Hide only the V36 new connection parts.
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var nodes: Array[VisualInstance3D] = []
    for name in [FENDERS, REAR, HANGERS]:
        var node := root.find_child(name, true, false) as VisualInstance3D
        if node == null:
            return false
        nodes.append(node)
    for node in nodes:
        node.visible = enabled
    root.set_meta("tarvoka_g13_v36_preview_enabled", enabled)
    return true
