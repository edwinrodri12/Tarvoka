extends RefCounted
class_name TarvokaG13RoofRadarFinishV37

# G13 V37 — native roof edge, service hood and stowed-radar bracing.
# ART ONLY. Additive to V36 on the real G13 4x4 model. Works with the
# existing 8 faction colors without recoloring old paint, blocking glass,
# enlarging the hull, or touching the twin cannons / radar folding rig.
const FLAG := "tarvoka_g13_v37_roof_hood_radar_finish"
const PREVIOUS := "tarvoka_g13_v36_proportion_and_joinery"
const ROOF := "G13_V37_SculptedRoofShoulders"
const HOOD := "G13_V37_EngineHoodStiffeners"
const RADAR_BRACE := "G13_V37_FixedRadarCradleGussets"
const RADAR_V30 := "tarvoka_g13_v30_radar_stowage_cradle"
const ROOF_PROFILE_SIZE := 6
const ROOF_TRIANGLES := 40
const RADAR_TRIANGLES := 16

static func _coat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3) -> void:
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

static func _roof_profile(side: int) -> Array[Vector2]:
    var s: float = float(side)
    return [
        Vector2(s * 0.563, 1.430),
        Vector2(s * 0.572, 1.448),
        Vector2(s * 0.589, 1.455),
        Vector2(s * 0.623, 1.452),
        Vector2(s * 0.644, 1.437),
        Vector2(s * 0.638, 1.417)
    ]

static func _roof_sculpt() -> ArrayMesh:
    # Two closed hexagonal rails. Side edges overlap the V11 roof gasket;
    # x >= 0.563 keeps clear of the V2 access hatch (ends at |x|=0.520).
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        var front: Array[Vector3] = []
        var back: Array[Vector3] = []
        for cross in _roof_profile(side):
            front.append(Vector3(cross.x, cross.y, -1.080))
            back.append(Vector3(cross.x, cross.y, -0.275))
        for i in range(1, ROOF_PROFILE_SIZE - 1):
            _tri(st, front[0], front[i], front[i + 1])
            _tri(st, back[0], back[i + 1], back[i])
        for i in range(ROOF_PROFILE_SIZE):
            var j: int = (i + 1) % ROOF_PROFILE_SIZE
            _quad(st, front[i], back[i], back[j], front[j])
    return st.commit()

static func _hood_ribs() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    # Top of original G13 engine lid: Y = 1.120. The low-profile rods
    # penetrate that lid by ~8 mm, and sit inside the V34 LOD8 perimeter.
    for side in [-1, 1]:
        var s: float = float(side)
        poses.append(Transform3D(
            Basis.IDENTITY.scaled(Vector3(0.040, 0.028, 0.260)),
            Vector3(s * 0.485, 1.126, 0.575)))
    # Short forward crossbar seals front of the common rear service cover.
    poses.append(Transform3D(
        Basis.IDENTITY.scaled(Vector3(0.795, 0.022, 0.027)),
        Vector3(0, 1.126, 0.404)))
    return poses

static func _radar_points(side: int, x: float) -> Array[Vector3]:
    var s: float = float(side)
    return [
        Vector3(s * x, 1.108, 1.088),
        Vector3(s * x, 1.108, 1.270),
        Vector3(s * x, 1.199, 1.213)
    ]

static func _radar_cradle_sculpt() -> ArrayMesh:
    # Two closed triangular steel gussets, fixed on the deck. Their inner
    # faces overlap V30's static bracket at |x|=0.155..0.225. None are
    # children of G13_RadarAzimut: the V29 folded mast can still move.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        var inner := _radar_points(side, 0.196)
        var outer := _radar_points(side, 0.259)
        _tri(st, inner[0], inner[1], inner[2])
        _tri(st, outer[0], outer[2], outer[1])
        for i in range(3):
            var j: int = (i + 1) % 3
            _quad(st, inner[i], outer[i], outer[j], inner[j])
    return st.commit()

static func _add_sculpt(parent: Node3D, label: String,
        geometry: Mesh, material: Material) -> void:
    var mesh := MeshInstance3D.new()
    mesh.name = label
    mesh.mesh = geometry
    mesh.material_override = material
    parent.add_child(mesh)

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hi: bool = bool(root.get_meta("tarvoka_g13_v1_high_detail", true))
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var roof := root.find_child("G13_CabRoof", true, false) as MeshInstance3D
    var cover := root.find_child("G13_EngineCover", true, false) as MeshInstance3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    if hull == null or roof == null or cover == null or turret == null or (
            roof.get_parent() != hull) or (
            cover.get_parent() != hull) or (
            turret.get_parent() != hull):
        return false
    if not roof.mesh is BoxMesh or not cover.mesh is BoxMesh:
        return false
    if not roof.position.is_equal_approx(Vector3(0, 1.40, -0.68)) or (
            not cover.position.is_equal_approx(Vector3(0, 1.03, 0.70))):
        return false

    var radar_geometry: ArrayMesh = null
    if not hi:
        if not bool(root.get_meta(RADAR_V30, false)):
            return false
        var cradle := root.find_child(
            "G13_RadarStowageV30", true, false) as MultiMeshInstance3D
        var radar := root.find_child(
            "G13_RadarAzimut", true, false) as Node3D
        if cradle == null or radar == null or (
                cradle.get_parent() != hull or radar.get_parent() != hull):
            return false
        radar_geometry = _radar_cradle_sculpt()
        if radar_geometry == null or (
                radar_geometry.get_faces().size() != RADAR_TRIANGLES * 3):
            return false

    var roof_geometry := _roof_sculpt()
    if roof_geometry == null or roof_geometry.get_surface_count() != 1 or (
            roof_geometry.get_faces().size() != ROOF_TRIANGLES * 3):
        return false

    var hood_positions := _hood_ribs()
    if hood_positions.size() != 3:
        return false

    # Only now mutate the scene tree, so missing prereqs cannot leave
    # unfinished paint, radar or geometry behind.
    _add_sculpt(hull, ROOF, roof_geometry,
        _coat(Color("#77888c"), 0.37, 0.66))
    var hood_mesh := BoxMesh.new()
    hood_mesh.size = Vector3.ONE
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = hood_mesh
    mm.instance_count = hood_positions.size()
    for i in range(hood_positions.size()):
        mm.set_instance_transform(i, hood_positions[i])
    var hood := MultiMeshInstance3D.new()
    hood.name = HOOD
    hood.multimesh = mm
    hood.material_override = _coat(Color("#364449"), 0.35, 0.72)
    hull.add_child(hood)

    if not hi:
        _add_sculpt(hull, RADAR_BRACE, radar_geometry,
            _coat(Color("#526369"), 0.43, 0.64))

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v37_visual_only", true)
    root.set_meta("tarvoka_g13_v37_roof_shoulders", 2)
    root.set_meta("tarvoka_g13_v37_hood_reinforcements", 3)
    root.set_meta("tarvoka_g13_v37_fixed_radar_gussets", 0 if hi else 2)
    root.set_meta("tarvoka_g13_v37_added_draw_nodes", 2 if hi else 3)
    root.set_meta("tarvoka_g13_v37_weapons", "two_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var names := [ROOF, HOOD]
    if not bool(root.get_meta("tarvoka_g13_v1_high_detail", true)):
        names.append(RADAR_BRACE)
    var nodes: Array[VisualInstance3D] = []
    for label in names:
        var node := root.find_child(label, true, false) as VisualInstance3D
        if node == null:
            return false
        nodes.append(node)
    for node in nodes:
        node.visible = enabled
    root.set_meta("tarvoka_g13_v37_preview_enabled", enabled)
    return true
