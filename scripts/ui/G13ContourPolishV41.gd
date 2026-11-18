extends RefCounted
class_name TarvokaG13ContourPolishV41

# G13 V41 — polish the existing V40 fenders and crest welds IN PLACE.
# V40 already closes the real 4-wheel fender silhouette. This pass refines
# its two reusable mesh resources without adding any draw nodes, changing
# a rig, animating a wheel, modifying faction tint or adding weapons.
# All V40 geometry stays stored for exact same-scene comparison.
const V40 = preload("res://scripts/ui/G13SilhouetteFinishV40.gd")
const FLAG := "tarvoka_g13_v41_curved_contour_polish"
const REQUIRES := "tarvoka_g13_v40_curved_silhouette_finish"
const FENDERS := "G13_V40_CurvedOuterFenders"
const WELDS := "G13_V40_SillFenderWelds"
const RESOURCES := "tarvoka_g13_v41_original_and_refined_resources"
const ARC_SEGMENTS := 12
const ARC_BEGIN := 0.25
const ARC_END := PI - 0.25
const ARCH_INNER := 0.348
const ARCH_OUTER := 0.427
const TREAD_BOUND := 0.324
const WHEEL_CENTER_Y := 0.33
const FENDER_TRIANGLES := 200
const WELD_TRIANGLES := 20
const ADDED_DRAW_NODES := 0

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3) -> void:
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

static func _contour(side: int, angle: float) -> Array[Vector3]:
    var s: float = float(side)
    var rise: float = sin(angle)
    var longitudinal: float = cos(angle)
    # V40 had an identical outboard reach along the entire arch. Taper
    # just 15 mm at each end so both lower quarters merge more naturally
    # with the V39 sill and V36 quarter plates in front/rear 3/4 views.
    # Outer edge never intrudes on the wheel sidewall (x~0.97) or exceeds
    # the old V40 1.015-m width. The 24-mm tyre radial gap is unchanged.
    var reach: float = lerpf(0.990, 1.005, rise)
    var lip_radius: float = ARCH_OUTER - 0.006 * (1.0 - rise)
    return [
        Vector3(s * 0.786,
            WHEEL_CENTER_Y + ARCH_INNER * rise, ARCH_INNER * longitudinal),
        Vector3(s * reach,
            WHEEL_CENTER_Y + ARCH_INNER * rise, ARCH_INNER * longitudinal),
        Vector3(s * reach,
            WHEEL_CENTER_Y + lip_radius * rise, lip_radius * longitudinal),
        Vector3(s * 0.786,
            WHEEL_CENTER_Y + lip_radius * rise, lip_radius * longitudinal)
    ]

static func _fender_mesh() -> ArrayMesh:
    # Same topology and exact wheel center/radii as V40. One geometry
    # holding left/right sides, used by V40's two existing axle instances.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        for i in range(ARC_SEGMENTS):
            var a0: float = lerpf(ARC_BEGIN, ARC_END,
                float(i) / float(ARC_SEGMENTS))
            var a1: float = lerpf(ARC_BEGIN, ARC_END,
                float(i + 1) / float(ARC_SEGMENTS))
            var a := _contour(side, a0)
            var b := _contour(side, a1)
            for edge in range(4):
                var k: int = (edge + 1) % 4
                _quad(st, a[edge], a[k], b[k], b[edge])
            if i == 0:
                _quad(st, a[0], a[3], a[2], a[1])
            if i == ARC_SEGMENTS - 1:
                _quad(st, b[0], b[1], b[2], b[3])
    return st.commit()

static func _weld_mesh() -> ArrayMesh:
    # The old four V40 welding ties were unit boxes. A sealed hexagonal
    # prism with tapered Z-end corners gives a smoother line to the arch.
    # All four original MultiMesh transforms/materials remain unchanged.
    var profile: Array[Vector2] = [
        Vector2(-0.50, -0.30),
        Vector2(-0.31, -0.50),
        Vector2(0.31, -0.50),
        Vector2(0.50, -0.30),
        Vector2(0.50, 0.50),
        Vector2(-0.50, 0.50)
    ]
    var lower: Array[Vector3] = []
    var upper: Array[Vector3] = []
    for p in profile:
        lower.append(Vector3(p.x, -0.50, p.y))
        upper.append(Vector3(p.x, 0.50, p.y))
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1, profile.size() - 1):
        _tri(st, lower[0], lower[i], lower[i + 1])
        _tri(st, upper[0], upper[i + 1], upper[i])
    for i in range(profile.size()):
        var j: int = (i + 1) % profile.size()
        _quad(st, lower[i], upper[i], upper[j], lower[j])
    return st.commit()

static func _nodes(root: Node3D) -> Dictionary:
    if root == null or not bool(root.get_meta(REQUIRES, false)):
        return {}
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var fender := root.find_child(
        FENDERS, true, false) as MultiMeshInstance3D
    var weld := root.find_child(
        WELDS, true, false) as MultiMeshInstance3D
    if hull == null or fender == null or weld == null or (
            fender.get_parent() != hull or weld.get_parent() != hull):
        return {}
    if fender.multimesh == null or weld.multimesh == null or (
            fender.multimesh.instance_count != 2 or (
            weld.multimesh.instance_count != 4)):
        return {}
    return {"fenders": fender, "welds": weld}

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(REQUIRES, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var parts := _nodes(root)
    if parts.is_empty():
        return false
    if ARCH_INNER - TREAD_BOUND < 0.020:
        return false
    var fender := parts["fenders"] as MultiMeshInstance3D
    var weld := parts["welds"] as MultiMeshInstance3D
    if not fender.multimesh.mesh is ArrayMesh or (
            not weld.multimesh.mesh is BoxMesh):
        return false

    var refined_fender := _fender_mesh()
    var refined_weld := _weld_mesh()
    if refined_fender == null or refined_weld == null or (
            refined_fender.get_faces().size() != FENDER_TRIANGLES * 3) or (
            refined_weld.get_faces().size() != WELD_TRIANGLES * 3):
        return false

    # Every ref remains a real native mesh resource, not a snapshot,
    # screenshot, fake duplicate or additional hidden draw node.
    var original_fender: Mesh = fender.multimesh.mesh
    var original_weld: Mesh = weld.multimesh.mesh
    root.set_meta(RESOURCES, {
        "v40_fender": original_fender, "v40_weld": original_weld,
        "v41_fender": refined_fender, "v41_weld": refined_weld
    })
    fender.multimesh.mesh = refined_fender
    weld.multimesh.mesh = refined_weld
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v41_visual_only", true)
    root.set_meta("tarvoka_g13_v41_wheel_fenders_refined", 4)
    root.set_meta("tarvoka_g13_v41_beveled_sill_joints", 4)
    root.set_meta("tarvoka_g13_v41_draw_nodes_added", ADDED_DRAW_NODES)
    root.set_meta("tarvoka_g13_v41_weapons_unchanged",
        "twin_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    # Switching mesh resources does NOT duplicate the unit or change
    # its world position, camera, faction, animation or draw call count.
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var parts := _nodes(root)
    var saved: Dictionary = root.get_meta(RESOURCES, {})
    if parts.is_empty() or saved.is_empty():
        return false
    for label in ["v40_fender", "v40_weld", "v41_fender", "v41_weld"]:
        if not saved.has(label) or not saved[label] is Mesh:
            return false
    # V40 may have been hidden with the older version comparison controls.
    # Keep the existing curved fenders visible for both V41 and V40 views.
    if not V40.show_finish(root, true):
        return false
    var fender := parts["fenders"] as MultiMeshInstance3D
    var weld := parts["welds"] as MultiMeshInstance3D
    fender.multimesh.mesh = (
        saved["v41_fender"] if enabled else saved["v40_fender"])
    weld.multimesh.mesh = (
        saved["v41_weld"] if enabled else saved["v40_weld"])
    root.set_meta("tarvoka_g13_v41_preview_enabled", enabled)
    return true
