extends RefCounted
class_name TarvokaG13ArcTerminationV42

# G13 V42: resolve the truncated arc tips of V40/V41 in native 3D.
# The original curved wheel band stopped at 0.25..PI-0.25, leaving a
# visibly abrupt edge near the axle line. Extend the band to the full
# upper semicircle and taper each end INTO the existing V33 steel arch.
# This replaces only a mesh resource on the already approved V41 nodes:
# no new draw nodes, weapons, colors, wheel/aim/radar transforms or FX.
const FLAG := "tarvoka_g13_v42_fender_tip_continuity"
const REQUIRES := "tarvoka_g13_v41_curved_contour_polish"
const FENDERS := "G13_V40_CurvedOuterFenders"
const META := "tarvoka_g13_v42_fender_mesh_pair"
const SEGMENTS := 16
const INNER_RADIUS := 0.348
const END_INNER_RADIUS := 0.358
const OUTER_RADIUS := 0.427
const AXLE_CENTER_Y := 0.33
const RADIAL_TREAD_BOUND := 0.324
const INNER_X := 0.786
const END_OUTER_X := 0.804
const CREST_OUTER_X := 1.005
const END_OUTER_RADIUS := 0.419
const FACES := 2 * (SEGMENTS * 8 + 4)
const NEW_NODES := 0

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

static func _section(side: int, angle: float) -> Array[Vector3]:
    var s: float = float(side)
    var rise: float = sin(angle)
    var forward: float = cos(angle)
    # At each end: x=.786..804, radii .358..419. This cross-section
    # is physically INSIDE V33's x=.699..811, radial .354..419 arch,
    # so no new protruding end cap remains at the wheel axle level.
    # At the crown: x=.786..1.005, radii .348..427, preserving V41's
    # prominent top arc and the welds already touching its upper face.
    var taper: float = smoothstep(0.0, 0.38, rise)
    var out_x: float = lerpf(END_OUTER_X, CREST_OUTER_X, taper)
    var out_radius: float = lerpf(END_OUTER_RADIUS, OUTER_RADIUS,
        smoothstep(0.0, 0.45, rise))
    var in_radius: float = lerpf(END_INNER_RADIUS, INNER_RADIUS,
        smoothstep(0.0, 0.25, rise))
    return [
        Vector3(s * INNER_X, AXLE_CENTER_Y + in_radius * rise,
            in_radius * forward),
        Vector3(s * out_x, AXLE_CENTER_Y + in_radius * rise,
            in_radius * forward),
        Vector3(s * out_x, AXLE_CENTER_Y + out_radius * rise,
            out_radius * forward),
        Vector3(s * INNER_X, AXLE_CENTER_Y + out_radius * rise,
            out_radius * forward)
    ]

static func _full_arch_mesh() -> ArrayMesh:
    # Same two-sided sealed four-edge band topology as V41. More
    # interpolation stations smooth the two tapered tips; no extra node.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        for i in range(SEGMENTS):
            var a0: float = PI * float(i) / float(SEGMENTS)
            var a1: float = PI * float(i + 1) / float(SEGMENTS)
            var first := _section(side, a0)
            var second := _section(side, a1)
            for edge in range(4):
                var k: int = (edge + 1) % 4
                _quad(st, first[edge], first[k],
                    second[k], second[edge])
            if i == 0:
                _quad(st, first[0], first[3], first[2], first[1])
            if i == SEGMENTS - 1:
                _quad(st, second[0], second[1], second[2], second[3])
    return st.commit()

static func _find_fender(root: Node3D) -> MultiMeshInstance3D:
    if root == null or not bool(root.get_meta(REQUIRES, false)):
        return null
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var fender := root.find_child(
        FENDERS, true, false) as MultiMeshInstance3D
    var v33 := root.find_child(
        "G13_V33_CurvedFenderArch", true, false) as MultiMeshInstance3D
    if hull == null or fender == null or v33 == null:
        return null
    if fender.get_parent() != hull or v33.get_parent() != hull:
        return null
    if fender.multimesh == null or (
            fender.multimesh.instance_count != 2) or (
            not fender.multimesh.mesh is ArrayMesh):
        return null
    if not is_equal_approx(
            fender.multimesh.get_instance_transform(0).origin.z, -0.85) or (
            not is_equal_approx(
            fender.multimesh.get_instance_transform(1).origin.z, 0.85)):
        return null
    return fender

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(REQUIRES, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var fender := _find_fender(root)
    if fender == null:
        return false
    if INNER_RADIUS - RADIAL_TREAD_BOUND < 0.020 or (
            END_INNER_RADIUS < 0.354) or (
            END_OUTER_RADIUS > 0.419) or (END_OUTER_X > 0.811):
        return false
    var finished := _full_arch_mesh()
    if finished == null or finished.get_surface_count() != 1 or (
            finished.get_faces().size() != FACES * 3):
        return false
    # Save the exact V41 resource, not an approximation of the earlier
    # profile. The Studio comparison swaps only the native ArrayMesh.
    var source: Mesh = fender.multimesh.mesh
    root.set_meta(META, {"v41": source, "v42": finished})
    fender.multimesh.mesh = finished
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v42_visual_only", true)
    root.set_meta("tarvoka_g13_v42_completed_wheel_arches", 4)
    root.set_meta("tarvoka_g13_v42_tip_integrated_in_v33", 8)
    root.set_meta("tarvoka_g13_v42_added_draw_nodes", NEW_NODES)
    root.set_meta("tarvoka_g13_v42_radial_gap_m",
        INNER_RADIUS - RADIAL_TREAD_BOUND)
    root.set_meta("tarvoka_g13_v42_weapons", "twin_autocannons_only")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var saved: Dictionary = root.get_meta(META, {})
    if not saved.has("v41") or not saved.has("v42") or (
            not saved["v41"] is ArrayMesh) or (
            not saved["v42"] is ArrayMesh):
        return false
    # V41 turns V40's normal curved guards back on if an older inspector
    # toggle hid them. Then replace only the wheel guard mesh.
    var v41 := preload("res://scripts/ui/G13ContourPolishV41.gd")
    if not v41.show_finish(root, true):
        return false
    var fender := _find_fender(root)
    if fender == null:
        return false
    fender.multimesh.mesh = saved["v42"] if enabled else saved["v41"]
    root.set_meta("tarvoka_g13_v42_preview_enabled", enabled)
    return true
