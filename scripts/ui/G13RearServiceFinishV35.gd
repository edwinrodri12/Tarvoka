extends RefCounted
class_name TarvokaG13RearServiceFinishV35

# G13 V35 — native rear service hatch, open exhaust and rear axle protection.
# VISUAL ONLY, additive to V34 in the existing LOD8 / LOD13 model.
# No rockets, missiles, gameplay stats, wheel rig or radar modifications.
const FLAG := "tarvoka_g13_v35_rear_service_exhaust"
const REQUIRES := "tarvoka_g13_v34_body_closure_and_bumper_finish"
const SERVICE := "G13_V35_RearServiceInset"
const LATCHES := "G13_V35_ServicePanelBolts"
const EXHAUST := "G13_V35_ExhaustOutlets"
const SHROUDS := "G13_V35_ExhaustShrouds"
const AXLE := "G13_V35_RearAxleBraces"
const SEGMENTS := 12
const PART_NODES := 5

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
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

static func _panel_profile(half_x: float, half_y: float,
        corner: float, z: float) -> Array[Vector3]:
    return [
        Vector3(-half_x + corner, -half_y, z),
        Vector3(half_x - corner, -half_y, z),
        Vector3(half_x, -half_y + corner, z),
        Vector3(half_x, half_y - corner, z),
        Vector3(half_x - corner, half_y, z),
        Vector3(-half_x + corner, half_y, z),
        Vector3(-half_x, half_y - corner, z),
        Vector3(-half_x, -half_y + corner, z)
    ]

static func _panel_mesh() -> ArrayMesh:
    # A true closed, beveled 8-corner inset access panel: not an image.
    # Back face overlaps existing rear hatch / chassis by 11 mm.
    var back := _panel_profile(0.155, 0.100, 0.024, -0.012)
    var front := _panel_profile(0.143, 0.088, 0.021, 0.016)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1, 7):
        _tri(st, front[0], front[i], front[i + 1])
        _tri(st, back[0], back[i + 1], back[i])
    for i in range(8):
        var j: int = (i + 1) % 8
        _tri(st, back[i], back[j], front[j])
        _tri(st, back[i], front[j], front[i])
    return st.commit()

static func _ring_point(z: float, radius: float, index: int) -> Vector3:
    var a: float = float(index) * TAU / float(SEGMENTS)
    return Vector3(cos(a) * radius, sin(a) * radius, z)

static func _exhaust_tube() -> ArrayMesh:
    # Genuine OPEN BORE exhaust. The back annular lip closes the wall, not
    # the hole; avoids cylinders mistaken for small missile launchers.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var z0: float = -0.125
    var z1: float = 0.155
    var ro: float = 0.050
    var ri: float = 0.034
    for i in range(SEGMENTS):
        var j: int = (i + 1) % SEGMENTS
        var a := _ring_point(z0, ro, i)
        var b := _ring_point(z0, ro, j)
        var c := _ring_point(z1, ro, i)
        var d := _ring_point(z1, ro, j)
        var e := _ring_point(z0, ri, i)
        var f := _ring_point(z0, ri, j)
        var g := _ring_point(z1, ri, i)
        var h := _ring_point(z1, ri, j)
        # Outer wall, inner bore and annular end caps.
        _tri(st, a, b, d)
        _tri(st, a, d, c)
        _tri(st, e, h, f)
        _tri(st, e, g, h)
        _tri(st, c, d, h)
        _tri(st, c, h, g)
        _tri(st, a, f, b)
        _tri(st, a, e, f)
    return st.commit()

static func _batch(parent: Node3D, label: String, mesh: Mesh,
        material: Material, transforms: Array[Transform3D]) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = mesh
    mm.instance_count = transforms.size()
    for i in range(transforms.size()):
        mm.set_instance_transform(i, transforms[i])
    var view := MultiMeshInstance3D.new()
    view.name = label
    view.multimesh = mm
    view.material_override = material
    parent.add_child(view)

static func _cube(at: Vector3, size: Vector3,
        rotation: Vector3 = Vector3.ZERO) -> Transform3D:
    var basis := Basis.from_euler(rotation)
    return Transform3D(basis.scaled(size), at)

static func _bolt_positions(y: float, z: float) -> Array[Transform3D]:
    var out: Array[Transform3D] = []
    for side in [-1, 1]:
        for dy in [-0.064, 0.064]:
            out.append(_cube(
                Vector3(float(side) * 0.109, y + float(dy), z),
                Vector3(0.015, 0.015, 0.009)))
    return out

static func _pipe_positions() -> Array[Transform3D]:
    var out: Array[Transform3D] = []
    # Behind rear axle and BELOW all V32 faction badges / rear service door.
    for side in [-1, 1]:
        out.append(Transform3D(Basis.IDENTITY,
            Vector3(float(side) * 0.379, 0.662, 1.244)))
    return out

static func _shroud_positions() -> Array[Transform3D]:
    var out: Array[Transform3D] = []
    for side in [-1, 1]:
        var s: float = float(side)
        out.append(_cube(Vector3(s * 0.380, 0.729, 1.214),
            Vector3(0.135, 0.036, 0.248)))
        # Low-lying side deflector protects the exposed exhaust wall.
        out.append(_cube(Vector3(s * 0.458, 0.674, 1.234),
            Vector3(0.028, 0.080, 0.225)))
    return out

static func _axle_positions() -> Array[Transform3D]:
    var out: Array[Transform3D] = []
    for side in [-1, 1]:
        var s: float = float(side)
        # Inboard of x=0.73 tire face and beneath central bodywork.
        out.append(_cube(Vector3(s * 0.457, 0.425, 1.039),
            Vector3(0.080, 0.068, 0.300),
            Vector3(0.15 * s, 0.0, 0.0)))
        out.append(_cube(Vector3(s * 0.457, 0.454, 1.179),
            Vector3(0.100, 0.120, 0.080)))
    return out

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(REQUIRES, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var engine := root.find_child(
        "G13_EngineCover", true, false) as MeshInstance3D
    var bumper := root.find_child(
        "G13_V34_ReinforcedBumpers", true, false) as MultiMeshInstance3D
    if hull == null or engine == null or bumper == null or (
            engine.get_parent() != hull or bumper.get_parent() != hull):
        return false
    var high_detail: bool = bool(
        root.get_meta("tarvoka_g13_v1_high_detail", true))
    var rear_door := root.find_child("G13_RearServiceDoor", true, false)
    if high_detail and rear_door == null:
        return false
    var y: float = 1.044 if high_detail else 0.759
    var z: float = 1.311 if high_detail else 1.267
    var panel := _panel_mesh()
    var pipe := _exhaust_tube()
    if panel == null or pipe == null or panel.get_surface_count() != 1 or (
            pipe.get_surface_count() != 1):
        return false
    if panel.get_faces().size() != 28 * 3 or (
            pipe.get_faces().size() != (SEGMENTS * 8 * 3)):
        return false

    var metal := _mat(Color("#718187"), 0.42, 0.66)
    var screws := _mat(Color("#acb5b4"), 0.55, 0.49)
    var exhaust := _mat(Color("#414d52"), 0.70, 0.46)
    var shade := _mat(Color("#4e5f64"), 0.33, 0.75)
    var steel := _mat(Color("#596970"), 0.46, 0.65)

    var hatch := MeshInstance3D.new()
    hatch.name = SERVICE
    hatch.mesh = panel
    hatch.material_override = metal
    hatch.position = Vector3(0.0, y, z)
    hull.add_child(hatch)
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    _batch(hull, LATCHES, box, screws, _bolt_positions(y, z + 0.027))
    _batch(hull, EXHAUST, pipe, exhaust, _pipe_positions())
    _batch(hull, SHROUDS, box, shade, _shroud_positions())
    _batch(hull, AXLE, box, steel, _axle_positions())

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v35_visual_only", true)
    root.set_meta("tarvoka_g13_v35_service_panels", 1)
    root.set_meta("tarvoka_g13_v35_rear_exhausts", 2)
    root.set_meta("tarvoka_g13_v35_panel_bolts", 4)
    root.set_meta("tarvoka_g13_v35_axle_braces", 4)
    root.set_meta("tarvoka_g13_v35_draw_nodes", PART_NODES)
    root.set_meta("tarvoka_g13_v35_armament", "two_original_autocannons")
    return true

static func show_finish(root: Node3D, visible_now: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var names := [SERVICE, LATCHES, EXHAUST, SHROUDS, AXLE]
    var nodes: Array[VisualInstance3D] = []
    for name in names:
        var item := root.find_child(name, true, false) as VisualInstance3D
        if item == null:
            return false
        nodes.append(item)
    for item in nodes:
        item.visible = visible_now
    root.set_meta("tarvoka_g13_v35_comparison_with_v34", not visible_now)
    return true
