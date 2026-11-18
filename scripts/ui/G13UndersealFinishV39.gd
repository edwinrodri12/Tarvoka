extends RefCounted
class_name TarvokaG13UndersealFinishV39

# G13 V39: native under-cab sealing, bumper corners and rear service fittings.
# ADDITIVE ART only; preserves V38, twin autocannons, 8 faction paints,
# radar, wheel animation, collision and all tactical/production rules.
const FLAG := "tarvoka_g13_v39_underseal_hardware_finish"
const PREVIOUS := "tarvoka_g13_v38_silhouette_joinery"
const SILL := "G13_V39_SealedLowerCabSills"
const FRONT := "G13_V39_FrontBumperCheekJoints"
const REAR := "G13_V39_RearServiceMounts"
const BOLTS := "G13_V39_FrontRearFasteners"
const SILL_FACES := 40
const FRONT_FACES := 24
const REAR_MOUNTS := 2
const PIN_COUNT := 10
const DRAW_NODES := 4

static func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var coat := StandardMaterial3D.new()
    coat.albedo_color = color
    coat.metallic = metallic
    coat.roughness = roughness
    coat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return coat

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal := (b - a).cross(c - a).normalized()
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

static func _prism(st: SurfaceTool, a: Array[Vector3],
        b: Array[Vector3]) -> void:
    # Closed low-poly prism. Both end caps are triangulated, so there are
    # no exposed empty faces at the transition to existing armor.
    var count: int = a.size()
    for i in range(1, count - 1):
        _tri(st, a[0], a[i], a[i + 1])
        _tri(st, b[0], b[i + 1], b[i])
    for i in range(count):
        var j: int = (i + 1) % count
        _quad(st, a[i], b[i], b[j], a[j])

static func _cab_sills() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Two gently beveled rocker rails. The inner face (x=.651) overlaps
    # original hull x=.675, and exterior (x=.702) remains outside it.
    # y>=.775 clears the .64m tire crown and V33 wheel-arch upper edge.
    # Rear end z=-.400 stays ahead of V38's z=-.338..-.117 side joinery.
    var contour: Array[Vector2] = [
        Vector2(0.651, 0.787), Vector2(0.676, 0.775),
        Vector2(0.702, 0.792), Vector2(0.702, 0.835),
        Vector2(0.680, 0.868), Vector2(0.651, 0.855)
    ]
    for side in [-1, 1]:
        var a: Array[Vector3] = []
        var b: Array[Vector3] = []
        for point in contour:
            a.append(Vector3(float(side) * point.x, point.y, -1.070))
            b.append(Vector3(float(side) * point.x, point.y, -0.400))
        _prism(st, a, b)
    return st.commit()

static func _front_cheeks() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Small closed metal joint plates above V34's nose bar.
    # Their lower face intersects V1 bumper top y=.585; upper face
    # finishes at y=.667, clearly below the lamps at y=.850.
    var contour: Array[Vector2] = [
        Vector2(0.421, 0.577), Vector2(0.553, 0.577),
        Vector2(0.531, 0.667), Vector2(0.439, 0.650)
    ]
    for side in [-1, 1]:
        var a: Array[Vector3] = []
        var b: Array[Vector3] = []
        for point in contour:
            a.append(Vector3(float(side) * point.x, point.y, -1.315))
            b.append(Vector3(float(side) * point.x, point.y, -1.242))
        _prism(st, a, b)
    return st.commit()

static func _rear_mounts() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    for side in [-1, 1]:
        # Mounts are partly embedded in V34's rear bumper (ending z=1.3945),
        # but protrude slightly for readability. They are beneath V35 exhaust
        # nozzles and V32 paint patches; no rear tail lamps are hidden.
        poses.append(Transform3D(
            Basis.IDENTITY.scaled(Vector3(0.076, 0.190, 0.080)),
            Vector3(float(side) * 0.465, 0.590, 1.371)))
    return poses

static func _fastener_poses() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    # Cylinders normally point in +Y. Orient their axes toward +/-Z.
    var towards_front := Basis(Vector3.RIGHT, PI * 0.5)
    var towards_rear := Basis(Vector3.RIGHT, -PI * 0.5)
    # Four heads seated on V34's forward reinforcing lip.
    for x in [-0.390, -0.185, 0.185, 0.390]:
        poses.append(Transform3D(towards_front,
            Vector3(float(x), 0.522, -1.349)))
    # Two outer heads installed on the deeper forward corner bump stops.
    for side in [-1, 1]:
        poses.append(Transform3D(towards_front,
            Vector3(float(side) * 0.587, 0.503, -1.409)))
    # Two bolt heads per new rear bracket, not over V38's rear fasteners.
    for side in [-1, 1]:
        for y in [0.553, 0.618]:
            poses.append(Transform3D(towards_rear,
                Vector3(float(side) * 0.465, float(y), 1.414)))
    return poses

static func _create(parent: Node3D, name: String,
        geometry: Mesh, coat: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = geometry
    part.material_override = coat
    parent.add_child(part)

static func _batch(parent: Node3D, name: String, shape: Mesh,
        coat: Material, poses: Array[Transform3D]) -> void:
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = shape
    multi.instance_count = poses.size()
    for i in range(poses.size()):
        multi.set_instance_transform(i, poses[i])
    var instance := MultiMeshInstance3D.new()
    instance.name = name
    instance.multimesh = multi
    instance.material_override = coat
    parent.add_child(instance)

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var cab := root.find_child("G13_SealedCab", true, false) as MeshInstance3D
    var front_bumper := root.find_child(
        "G13_FrontBumper", true, false) as MeshInstance3D
    var rear_bumper := root.find_child(
        "G13_V34_ReinforcedBumpers", true, false) as MultiMeshInstance3D
    var joinery := root.find_child(
        "G13_V38_RearCabArmoredSaddles", true, false) as MeshInstance3D
    if hull == null or cab == null or front_bumper == null or (
            rear_bumper == null or joinery == null):
        return false
    if cab.get_parent() != hull or front_bumper.get_parent() != hull or (
            rear_bumper.get_parent() != hull or joinery.get_parent() != hull):
        return false
    if not front_bumper.position.is_equal_approx(
            Vector3(0, 0.51, -1.21)):
        return false
    if not front_bumper.mesh is BoxMesh:
        return false
    if not (front_bumper.mesh as BoxMesh).size.is_equal_approx(
            Vector3(1.29, 0.15, 0.18)):
        return false

    var sills := _cab_sills()
    var cheeks := _front_cheeks()
    var rear := _rear_mounts()
    var bolts := _fastener_poses()
    if sills == null or cheeks == null or (
            rear.size() != REAR_MOUNTS or bolts.size() != PIN_COUNT):
        return false
    if sills.get_surface_count() != 1 or (
            sills.get_faces().size() != SILL_FACES * 3) or (
            cheeks.get_surface_count() != 1) or (
            cheeks.get_faces().size() != FRONT_FACES * 3):
        return false

    var steel := _mat(Color("#66777b"), 0.42, 0.68)
    var armor := _mat(Color("#53646b"), 0.44, 0.70)
    var graphite := _mat(Color("#354349"), 0.34, 0.76)
    var alloy := _mat(Color("#a8b0ad"), 0.59, 0.51)
    _create(hull, SILL, sills, graphite)
    _create(hull, FRONT, cheeks, steel)

    var cube := BoxMesh.new()
    cube.size = Vector3.ONE
    _batch(hull, REAR, cube, armor, rear)
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.013
    cylinder.bottom_radius = 0.013
    cylinder.height = 0.017
    cylinder.radial_segments = 8
    _batch(hull, BOLTS, cylinder, alloy, bolts)

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v39_visual_only", true)
    root.set_meta("tarvoka_g13_v39_sealed_cab_sills", 2)
    root.set_meta("tarvoka_g13_v39_front_bumper_cheeks", 2)
    root.set_meta("tarvoka_g13_v39_rear_mounts", rear.size())
    root.set_meta("tarvoka_g13_v39_fasteners", bolts.size())
    root.set_meta("tarvoka_g13_v39_draw_nodes_added", DRAW_NODES)
    root.set_meta("tarvoka_g13_v39_weapons", "two_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var nodes: Array[VisualInstance3D] = []
    for label in [SILL, FRONT, REAR, BOLTS]:
        var part := root.find_child(label, true, false) as VisualInstance3D
        if part == null:
            return false
        nodes.append(part)
    for part in nodes:
        part.visible = enabled
    root.set_meta("tarvoka_g13_v39_preview_enabled", enabled)
    return true
