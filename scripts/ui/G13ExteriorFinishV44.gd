extends RefCounted
class_name TarvokaG13ExteriorFinishV44

# G13 V44 — REAL NATIVE 3D hard-surface facelift, not an illustration.
# The previous V42 wheel contours are retained. Broad shielded side plates,
# shaped faction enamel, curved fender ribbons, rotating turret joint armour
# and recessed deck ventilation make the art model more coherent and readable.
# No missiles, rig, radar, animations, stats or foreign-unit meshes changed.
# Uses only the LIVE faction paint already assigned to the selected G13.
const FLAG := "tarvoka_g13_v44_hard_surface_faction_finish"
const REQUIRES := "tarvoka_g13_v32_faction_mount_finish"
const BODY_ARMOR := "G13_V44_FacetedSideArmor"
const BODY_PAINT := "G13_V44_SculptedFactionFlanks"
const FENDER_PAINT := "G13_V44_CurvedFactionFenderBands"
const TURRET_JOINT := "G13_V44_RotatingTurretJointArmor"
const TURRET_PAINT := "G13_V44_FactionTurretGuards"
const REAR_VENTS := "G13_V44_SculptedEngineDeckVents"
const DRAW_NODES := 6
const FENDER_SEGMENTS := 12
const FENDER_TRIANGLES := 200
const ARMOR_TRIANGLES := 40 # Two 6-sided closed prisms.
const PAINT_TRIANGLES := 32 # Two 5-sided closed prisms.

static func _mat(c: Color, metallic: float, rough: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = c
    result.metallic = metallic
    result.roughness = rough
    result.cull_mode = BaseMaterial3D.CULL_DISABLED
    return result

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3) -> void:
    var n := (b - a).cross(c - a).normalized()
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

static func _sided_closed_plate(shape: Array[Vector2],
        x_in: float, x_out: float) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        var a: Array[Vector3] = []
        var b: Array[Vector3] = []
        for p in shape:
            # Polygon is (Z,Y): front, roof shoulder, rear, lower bevel.
            a.append(Vector3(float(side) * x_in, p.y, p.x))
            b.append(Vector3(float(side) * x_out, p.y, p.x))
        for i in range(1, shape.size() - 1):
            _tri(st, a[0], a[i], a[i + 1])
            _tri(st, b[0], b[i + 1], b[i])
        for i in range(shape.size()):
            var k: int = (i + 1) % shape.size()
            _quad(st, a[i], b[i], b[k], a[k])
    return st.commit()

static func _side_armor() -> ArrayMesh:
    # Flank plating is ABOVE the wheel tops and BELOW the V2 upper stripe.
    # The 24-mm outside step makes a visible edge, not a flat texture decal.
    var contour: Array[Vector2] = [
        Vector2(-0.310, 0.999),
        Vector2(-0.233, 1.091),
        Vector2(0.417, 1.091),
        Vector2(0.540, 1.001),
        Vector2(0.478, 0.920),
        Vector2(-0.242, 0.920)
    ]
    return _sided_closed_plate(contour, 0.696, 0.732)

static func _side_faction() -> ArrayMesh:
    # Raised five-facet paint insert follows the shield contour and keeps a
    # visible steel border around its edges, even at tactical camera size.
    var contour: Array[Vector2] = [
        Vector2(-0.204, 0.987),
        Vector2(-0.165, 1.065),
        Vector2(0.370, 1.065),
        Vector2(0.458, 1.003),
        Vector2(0.374, 0.958)
    ]
    return _sided_closed_plate(contour, 0.732, 0.746)

static func _fender_section(side: int, angle: float) -> Array[Vector3]:
    var s: float = float(side)
    var sn: float = sin(angle)
    var cs: float = cos(angle)
    # G13 V42 outer arch follows R=0.427 around axle Y=.33 and X~1.005.
    # This 8-mm-high enamel ribbon overlaps that armor, NOT the wheel.
    var inner: float = 0.427
    var outer: float = 0.437
    return [
        Vector3(s * 0.979, 0.33 + inner * sn, inner * cs),
        Vector3(s * 1.011, 0.33 + inner * sn, inner * cs),
        Vector3(s * 1.011, 0.33 + outer * sn, outer * cs),
        Vector3(s * 0.979, 0.33 + outer * sn, outer * cs)
    ]

static func _fender_bands() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        for i in range(FENDER_SEGMENTS):
            var a0: float = lerpf(0.54, PI - 0.54,
                float(i) / float(FENDER_SEGMENTS))
            var a1: float = lerpf(0.54, PI - 0.54,
                float(i + 1) / float(FENDER_SEGMENTS))
            var a := _fender_section(side, a0)
            var b := _fender_section(side, a1)
            for edge in range(4):
                var k: int = (edge + 1) % 4
                _quad(st, a[edge], a[k], b[k], b[edge])
            if i == 0:
                _quad(st, a[0], a[3], a[2], a[1])
            if i == FENDER_SEGMENTS - 1:
                _quad(st, b[0], b[1], b[2], b[3])
    return st.commit()

static func _batch(parent: Node3D, label: String, shape: Mesh,
        material: Material, poses: Array[Transform3D]) -> void:
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = shape
    multi.instance_count = poses.size()
    for i in range(poses.size()):
        multi.set_instance_transform(i, poses[i])
    var node := MultiMeshInstance3D.new()
    node.name = label
    node.multimesh = multi
    node.material_override = material
    parent.add_child(node)

static func _sculpt(parent: Node3D, label: String, mesh: Mesh,
        material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.material_override = material
    parent.add_child(part)

static func _axles() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    for axle in [-1, 1]:
        poses.append(Transform3D(
            Basis.IDENTITY, Vector3(0, 0, float(axle) * 0.85)))
    return poses

static func _turret_joint_segments() -> Array[Transform3D]:
    # Only rotating weapon station parts go under G13_TorretaAzimut.
    # 12 articulated-looking steel blocks bridge the base ring visually.
    var poses: Array[Transform3D] = []
    for i in range(12):
        var a: float = TAU * float(i) / 12.0
        var basis := Basis(Vector3.UP, -a).scaled(
            Vector3(0.052, 0.061, 0.211))
        poses.append(Transform3D(
            basis, Vector3(cos(a) * 0.495, 0.090, sin(a) * 0.495)))
    return poses

static func _turret_faction_guards() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    for side in [-1, 1]:
        for z in [-0.105, 0.252]:
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.017, 0.103, 0.151)),
                Vector3(float(side) * 0.637, 0.305, float(z))))
    return poses

static func _engine_vents() -> Array[Transform3D]:
    # 8 raised physically shaped heat-exchanger louvers on the aft deck.
    # Clear of V37 ribs near X=+/-0.485, and of the moving turret.
    var poses: Array[Transform3D] = []
    for side in [-1, 1]:
        for z in [0.530, 0.652, 0.774, 0.896]:
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.157, 0.021, 0.043)),
                Vector3(float(side) * 0.285, 1.136, float(z))))
    return poses

static func apply(root: Node3D) -> bool:
    # Independent of V38–V42 so a failed old cosmetic pass never suppresses
    # the requested new finish. V32 and original rig/body ARE mandatory.
    if root == null or not bool(root.get_meta(REQUIRES, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    var original := root.find_child(
        "G13_TurretFaction_1", true, false) as MeshInstance3D
    if hull == null or turret == null or original == null:
        return false
    if turret.get_parent() != hull or (
            not original.material_override is StandardMaterial3D):
        return false
    var enamel: Color = (
        original.material_override as StandardMaterial3D).albedo_color
    if enamel.a <= 0.0:
        return false
    var armor := _side_armor()
    var paint := _side_faction()
    var fenders := _fender_bands()
    var axle_poses := _axles()
    var turret_poses := _turret_joint_segments()
    var turret_paint_poses := _turret_faction_guards()
    var vent_poses := _engine_vents()
    if armor == null or paint == null or fenders == null or (
            armor.get_faces().size() != ARMOR_TRIANGLES * 3) or (
            paint.get_faces().size() != PAINT_TRIANGLES * 3) or (
            fenders.get_faces().size() != FENDER_TRIANGLES * 3) or (
            axle_poses.size() != 2) or (turret_poses.size() != 12) or (
            turret_paint_poses.size() != 4) or (vent_poses.size() != 8):
        return false

    var steel := _mat(Color("#4a5a61"), 0.46, 0.65)
    var dark := _mat(Color("#27343b"), 0.33, 0.78)
    var accent := _mat(enamel.lightened(0.065), 0.29, 0.59)
    _sculpt(hull, BODY_ARMOR, armor, steel)
    _sculpt(hull, BODY_PAINT, paint, accent)
    _batch(hull, FENDER_PAINT, fenders, accent, axle_poses)
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE
    _batch(turret, TURRET_JOINT, cube, steel, turret_poses)
    _batch(turret, TURRET_PAINT, cube, accent, turret_paint_poses)
    _batch(hull, REAR_VENTS, cube, dark, vent_poses)

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v44_3d_native", true)
    root.set_meta("tarvoka_g13_v44_faction", enamel.to_html())
    root.set_meta("tarvoka_g13_v44_faction_flank_shields", 2)
    root.set_meta("tarvoka_g13_v44_curved_painted_wheel_guards", 4)
    root.set_meta("tarvoka_g13_v44_turret_faction_strips", 4)
    root.set_meta("tarvoka_g13_v44_turret_joint_segments", 12)
    root.set_meta("tarvoka_g13_v44_deck_vents", 8)
    root.set_meta("tarvoka_g13_v44_added_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v44_armament", "dual_autocannon_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var pieces: Array[VisualInstance3D] = []
    for label in [BODY_ARMOR, BODY_PAINT, FENDER_PAINT,
            TURRET_JOINT, TURRET_PAINT, REAR_VENTS]:
        var mesh := root.find_child(label, true, false) as VisualInstance3D
        if mesh == null:
            return false
        pieces.append(mesh)
    for mesh in pieces:
        mesh.visible = enabled
    root.set_meta("tarvoka_g13_v44_preview_enabled", enabled)
    return true
