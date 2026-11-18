extends RefCounted
class_name TarvokaG13RoofShoulderFitV52

# TARVOKA G13 V52: REPLACE the existing V37 roof shoulder rail mesh.
# Actual ArrayMesh hard-surface geometry in the original Godot vehicle,
# matched to the V51 cab roof / V38 rear termination. This does not add
# draw objects, change PBR/faction color, radar, twin guns or battle rules.
const V51 = preload("res://scripts/ui/G13CabRoofIntegrationV51.gd")
const FLAG := "tarvoka_g13_v52_integrated_roof_shoulder_rails"
const PREVIOUS := "tarvoka_g13_v51_roof_to_glazing_integration"
const NAME := "G13_V37_SculptedRoofShoulders"
const END_CAP := "G13_V38_RoofRearEndCaps"
const SAVED := "tarvoka_g13_v52_original_and_fitted_shoulder_meshes"
const RAIL_SIDES := 2
const STATIONS := 4
const PROFILE_POINTS := 6
const TRIANGLES := 88
const ADDED_DRAW_NODES := 0

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3) -> void:
    var n: Vector3 = (b-a).cross(c-a).normalized()
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

static func _section(side: int, station: int) -> Array[Vector3]:
    # Ordered perimeter: inner landing, rising bevel, roof crest,
    # upper outer cheek, outer bevel, inner underside. All stations
    # penetrate the V51 roof in their lower section. The rear station
    # is numerically close to the V38 cap at z=-0.290, eliminating
    # the old shallow floating rail-to-end-cap seam.
    var p: Array[Vector2] = []
    var z: float = 0.0
    match station:
        0:
            z = -1.110
            p = [
                Vector2(0.563, 1.424),
                Vector2(0.571, 1.442),
                Vector2(0.586, 1.450),
                Vector2(0.611, 1.446),
                Vector2(0.635, 1.431),
                Vector2(0.629, 1.410)
            ]
        1:
            z = -0.875
            p = [
                Vector2(0.563, 1.429),
                Vector2(0.573, 1.449),
                Vector2(0.590, 1.456),
                Vector2(0.624, 1.452),
                Vector2(0.645, 1.437),
                Vector2(0.637, 1.413)
            ]
        2:
            z = -0.535
            p = [
                Vector2(0.563, 1.429),
                Vector2(0.574, 1.449),
                Vector2(0.590, 1.455),
                Vector2(0.622, 1.451),
                Vector2(0.643, 1.435),
                Vector2(0.636, 1.412)
            ]
        3:
            z = -0.285
            p = [
                Vector2(0.565, 1.428),
                Vector2(0.572, 1.446),
                Vector2(0.590, 1.452),
                Vector2(0.623, 1.449),
                Vector2(0.642, 1.435),
                Vector2(0.635, 1.414)
            ]
        _:
            return []
    var s: float = float(side)
    var vertices: Array[Vector3] = []
    for v in p:
        vertices.append(Vector3(s * v.x, v.y, z))
    return vertices

static func _mesh() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        var first: Array[Vector3] = _section(side, 0)
        var last: Array[Vector3] = _section(side, STATIONS-1)
        for station in range(STATIONS-1):
            var a: Array[Vector3] = _section(side, station)
            var b: Array[Vector3] = _section(side, station+1)
            for edge in range(PROFILE_POINTS):
                var k: int = (edge+1)%PROFILE_POINTS
                _quad(st, a[edge], b[edge], b[k], a[k])
        for i in range(1, PROFILE_POINTS-1):
            _tri(st, first[0], first[i+1], first[i])
            _tri(st, last[0], last[i], last[i+1])
    return st.commit()

static func _rails(root: Node3D) -> MeshInstance3D:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return null
    var hull := root.find_child(
        "G13_Casco4x4", true, false) as Node3D
    var rail := root.find_child(NAME, true, false) as MeshInstance3D
    var end := root.find_child(END_CAP, true, false) as MeshInstance3D
    if hull == null or rail == null or end == null:
        return null
    if rail.get_parent()!=hull or end.get_parent()!=hull:
        return null
    if not rail.mesh is ArrayMesh or not end.mesh is ArrayMesh:
        return null
    return rail

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var rail := _rails(root)
    if rail == null:
        return false
    var geometry := _mesh()
    if geometry == null or geometry.get_surface_count()!=1 or (
            geometry.get_faces().size()!=TRIANGLES*3):
        return false
    var prior: Mesh = rail.mesh
    # Preserve the exact material and node; only replace the real mesh.
    root.set_meta(SAVED, {"v51": prior, "v52": geometry})
    rail.mesh = geometry
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v52_roof_rail_triangles", TRIANGLES)
    root.set_meta("tarvoka_g13_v52_new_draw_nodes", ADDED_DRAW_NODES)
    root.set_meta("tarvoka_g13_v52_station_count", STATIONS)
    root.set_meta("tarvoka_g13_v52_faction_colors_unchanged", true)
    root.set_meta("tarvoka_g13_v52_weapons", "dual_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    if not V51.show_finish(root, true):
        return false
    var rail := _rails(root)
    if rail == null:
        return false
    var saved: Dictionary = root.get_meta(SAVED, {})
    if not saved.has("v51") or not saved.has("v52"):
        return false
    if not saved["v51"] is ArrayMesh or not saved["v52"] is ArrayMesh:
        return false
    rail.mesh = saved["v52"] if enabled else saved["v51"]
    root.set_meta("tarvoka_g13_v52_preview_enabled", enabled)
    return true
