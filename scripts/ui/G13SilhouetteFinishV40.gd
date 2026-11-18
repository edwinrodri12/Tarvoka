extends RefCounted
class_name TarvokaG13SilhouetteFinishV40

# G13 V40: replace the HERO's legacy square wheel covers with true curved
# outboard fenders, seal the V39 sill-to-arch crest, and connect front cheek
# armour to the V34 bumper corner. VISUAL ONLY; no rig/paint/combat change.
# LOD8 has no V16 old fenders: add the same low-poly outboard sculpt there.
const FLAG := "tarvoka_g13_v40_curved_silhouette_finish"
const PREVIOUS := "tarvoka_g13_v39_underseal_hardware_finish"
const CURVES := "G13_V40_CurvedOuterFenders"
const WELDS := "G13_V40_SillFenderWelds"
const NOSE := "G13_V40_FrontCornerTransitions"
const LEGACY_NAMES := ["G13_V16_Fenders", "G13_V16_FenderTrims"]
const VIS_STATE := "tarvoka_g13_v40_legacy_fender_visibility"
const SEGMENTS := 12
const INNER_RADIUS := 0.348
const OUTER_RADIUS := 0.427
const TREAD_RADIUS_LIMIT := 0.324
const ARC_START := 0.25
const ARC_END := PI - 0.25
const FENDER_FACES := 200 # both sides in one mesh, instanced on two axles
const NOSE_FACES := 32 # two closed pentagonal joiners
const WELD_COUNT := 4
const DRAW_NODES := 3

static func _material(color: Color, metallic: float,
        roughness: float) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = metallic
    result.roughness = roughness
    result.cull_mode = BaseMaterial3D.CULL_DISABLED
    return result

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

static func _arc_profile(side: int, theta: float) -> Array[Vector3]:
    var s: float = float(side)
    var sn: float = sin(theta)
    var cs: float = cos(theta)
    # V33 inner wheel arch reaches x~.811, this new outer shell overlaps
    # x=.786..811, and its outermost edge reaches only x=1.015 (less than
    # the old V2 fender trim x=1.038). No tyre or wheel position is changed.
    return [
        Vector3(s * 0.786, 0.33 + INNER_RADIUS * sn, INNER_RADIUS * cs),
        Vector3(s * 1.015, 0.33 + INNER_RADIUS * sn, INNER_RADIUS * cs),
        Vector3(s * 1.015, 0.33 + OUTER_RADIUS * sn, OUTER_RADIUS * cs),
        Vector3(s * 0.786, 0.33 + OUTER_RADIUS * sn, OUTER_RADIUS * cs)
    ]

static func _curved_fenders() -> ArrayMesh:
    # Two true sealed quarter-circle bands (left/right), then instanced
    # for the front and rear wheel centres at Z=-.85 and +.85.
    # Geometry follows tyre radius throughout, unlike V2's flat cuboids.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        for segment in range(SEGMENTS):
            var a0: float = lerpf(ARC_START, ARC_END,
                float(segment) / float(SEGMENTS))
            var a1: float = lerpf(ARC_START, ARC_END,
                float(segment + 1) / float(SEGMENTS))
            var first := _arc_profile(side, a0)
            var second := _arc_profile(side, a1)
            for edge in range(4):
                var next_edge: int = (edge + 1) % 4
                _quad(st, first[edge], first[next_edge],
                    second[next_edge], second[edge])
            if segment == 0:
                _quad(st, first[0], first[3], first[2], first[1])
            if segment == SEGMENTS - 1:
                _quad(st, second[0], second[1], second[2], second[3])
    return st.commit()

static func _nose_joiner_mesh() -> ArrayMesh:
    # V39 upper bumper plate at x=.421..553 and V34 corner bumper at
    # x=.529..645: the pentagonal joining plate intersects BOTH solids.
    # It is located below headlights (y=.85) and outboard of the intake.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var profile: Array[Vector2] = [
        Vector2(0.516, 0.579), Vector2(0.590, 0.563),
        Vector2(0.615, 0.585), Vector2(0.585, 0.641),
        Vector2(0.536, 0.638)
    ]
    for side in [-1, 1]:
        var first: Array[Vector3] = []
        var last: Array[Vector3] = []
        for point in profile:
            first.append(Vector3(float(side) * point.x, point.y, -1.329))
            last.append(Vector3(float(side) * point.x, point.y, -1.261))
        for i in range(1, profile.size() - 1):
            _tri(st, first[0], first[i], first[i + 1])
            _tri(st, last[0], last[i + 1], last[i])
        for i in range(profile.size()):
            var j: int = (i + 1) % profile.size()
            _quad(st, first[i], last[i], last[j], first[j])
    return st.commit()

static func _crest_welds() -> Array[Transform3D]:
    var parts: Array[Transform3D] = []
    for side in [-1, 1]:
        for axle in [-1, 1]:
            # x=.690..822 overlaps V36 inward arch and the new curved outer
            # fender. Y=.7495..7765 touches the V39 lower cab sill at Y=.775.
            parts.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.132, 0.027, 0.125)),
                Vector3(float(side) * 0.756, 0.763, float(axle) * 0.85)))
    return parts

static func _create_mesh(parent: Node3D, name: String, mesh: Mesh,
        material: Material) -> void:
    var part := MeshInstance3D.new()
    part.name = name
    part.mesh = mesh
    part.material_override = material
    parent.add_child(part)

static func _batch(parent: Node3D, name: String, shape: Mesh,
        material: Material, transforms: Array[Transform3D]) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = shape
    mm.instance_count = transforms.size()
    for i in range(transforms.size()):
        mm.set_instance_transform(i, transforms[i])
    var part := MultiMeshInstance3D.new()
    part.name = name
    part.multimesh = mm
    part.material_override = material
    parent.add_child(part)

static func _legacy_nodes(root: Node3D, hi: bool) -> Array[VisualInstance3D]:
    # V16 has ALREADY replaced 8 old individual hero fenders/trims with TWO
    # static GPU batches. Preserve those batches' visibility, plus their
    # retained hidden source meshes, for a clean V39 Studio comparison.
    var nodes: Array[VisualInstance3D] = []
    if not hi:
        return nodes
    for label in LEGACY_NAMES:
        var batch := root.find_child(label, true, false) as MultiMeshInstance3D
        if batch == null:
            return []
        nodes.append(batch)
    for label in ["G13_V2_Fender_%d_%d", "G13_V2_FenderTrim_%d_%d"]:
        for side in [-1, 1]:
            for axle in [-1, 1]:
                var instance := root.find_child(
                    label % [side, axle], true, false) as MeshInstance3D
                if instance == null:
                    return []
                nodes.append(instance)
    return nodes

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var wheel := root.find_child(
        "G13_Ruedas4x4MultiMesh", true, false) as MultiMeshInstance3D
    var old_arch := root.find_child(
        "G13_V33_CurvedFenderArch", true, false) as MultiMeshInstance3D
    var cab_sills := root.find_child(
        "G13_V39_SealedLowerCabSills", true, false) as MeshInstance3D
    var front_cheeks := root.find_child(
        "G13_V39_FrontBumperCheekJoints", true, false) as MeshInstance3D
    var front_bumper := root.find_child(
        "G13_FrontBumper", true, false) as MeshInstance3D
    if hull == null or wheel == null or old_arch == null or (
            cab_sills == null or front_cheeks == null or front_bumper == null):
        return false
    for part in [wheel, old_arch, cab_sills, front_cheeks, front_bumper]:
        if part.get_parent() != hull:
            return false
    if INNER_RADIUS - TREAD_RADIUS_LIMIT < 0.020:
        return false
    var hi: bool = bool(root.get_meta("tarvoka_g13_v1_high_detail", true))
    var legacy: Array[VisualInstance3D] = _legacy_nodes(root, hi)
    if hi and (legacy.size() != 10 or (
            not bool(root.get_meta("tarvoka_g13_gpu_static_batches_v16", false)))):
        return false
    var faces := _curved_fenders()
    var nose := _nose_joiner_mesh()
    var welds := _crest_welds()
    if faces == null or nose == null or welds.size() != WELD_COUNT:
        return false
    if faces.get_surface_count() != 1 or (
            faces.get_faces().size() != FENDER_FACES * 3) or (
            nose.get_surface_count() != 1) or (
            nose.get_faces().size() != NOSE_FACES * 3):
        return false

    var saved: Dictionary = {}
    for old_piece in legacy:
        saved[old_piece.name] = old_piece.visible

    var positions: Array[Transform3D] = []
    for axle in [-1, 1]:
        positions.append(Transform3D(
            Basis.IDENTITY, Vector3(0.0, 0.0, float(axle) * 0.85)))
    _batch(hull, CURVES, faces, _material(Color("#303c41"), 0.28, 0.79),
        positions)
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    _batch(hull, WELDS, box, _material(Color("#6e7c80"), 0.43, 0.67),
        welds)
    _create_mesh(hull, NOSE, nose,
        _material(Color("#67777c"), 0.39, 0.68))

    for old_piece in legacy:
        old_piece.visible = false
    root.set_meta(VIS_STATE, saved)
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v40_visual_only", true)
    root.set_meta("tarvoka_g13_v40_outboard_curved_fenders", 4)
    root.set_meta("tarvoka_g13_v40_sill_fender_welds", WELD_COUNT)
    root.set_meta("tarvoka_g13_v40_front_corner_joins", 2)
    root.set_meta("tarvoka_g13_v40_hidden_legacy_fender_batches",
        LEGACY_NAMES.size() if hi else 0)
    root.set_meta("tarvoka_g13_v40_draw_nodes_added", DRAW_NODES)
    root.set_meta("tarvoka_g13_v40_armament", "two_original_autocannons")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var names := [CURVES, WELDS, NOSE]
    var items: Array[VisualInstance3D] = []
    for label in names:
        var part := root.find_child(label, true, false) as VisualInstance3D
        if part == null:
            return false
        items.append(part)
    var hi: bool = bool(root.get_meta("tarvoka_g13_v1_high_detail", true))
    var legacy: Array[VisualInstance3D] = _legacy_nodes(root, hi)
    if hi and legacy.size() != 10:
        return false
    var saved: Dictionary = root.get_meta(VIS_STATE, {})
    for part in items:
        part.visible = enabled
    for old_piece in legacy:
        old_piece.visible = false if enabled else bool(
            saved.get(old_piece.name, false))
    root.set_meta("tarvoka_g13_v40_preview_enabled", enabled)
    return true
