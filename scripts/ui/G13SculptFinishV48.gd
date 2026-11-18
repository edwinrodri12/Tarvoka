extends RefCounted
class_name TarvokaG13SculptFinishV48

# G13 V48: a REAL redesign of three MAJOR existing closed Godot 3D shells,
# informed by eight actual exported 1280x720 Studio screenshots.
# No decorative clutter or additional draw nodes: each old Mesh resource is
# replaced in place. The original V47 shells and turret paint placement are
# preserved for an exact live camera/faction comparison.
# Preserve four-wheel suspension, twin autocannons, radar, eight faction
# palettes, attack/fold/roll animation, collision and all combat rules.
const FLAG := "tarvoka_g13_v48_major_armored_hull_sculpt"
const PREVIOUS := "tarvoka_g13_v47_individual_pbr_materials"
const SAVED := "tarvoka_g13_v48_original_and_sculpted_profiles"
const HERO := [
    "G13_V10_ChamferedCabShell",
    "G13_V10_ChamferedTurretShell",
    "G13_V11_ArmoredRoof"
]
const TACTICAL := [
    "G13_SealedCab",
    "G13_RemoteWeaponHousing",
    "G13_CabRoof"
]
const FACTION_GUARD := "G13_V44_FactionTurretGuards"
const CAB_TRIANGLES := 96
const TURRET_TRIANGLES := 96
const ROOF_TRIANGLES := 64
const NEW_DRAW_NODES := 0

static func _tri(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    # Match the proven V10/V11 Godot 4 clockwise winding.
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _ring(hx: float, hz: float, bevel: float,
        y: float, front_shift: float, rear_shift: float) -> Array[Vector3]:
    var cut: float = minf(bevel, minf(hx, hz) * 0.45)
    var front: float = -hz + front_shift
    var rear: float = hz + rear_shift
    return [
        Vector3(-hx + cut, y, front),
        Vector3(hx - cut, y, front),
        Vector3(hx, y, front + cut),
        Vector3(hx, y, rear - cut),
        Vector3(hx - cut, y, rear),
        Vector3(-hx + cut, y, rear),
        Vector3(-hx, y, rear - cut),
        Vector3(-hx, y, front + cut)
    ]

static func _closed_loft(rings: Array) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size() - 1):
        var first: Array[Vector3] = rings[layer]
        var second: Array[Vector3] = rings[layer + 1]
        for edge in range(8):
            var next_edge: int = (edge + 1) % 8
            _tri(st, first[edge], second[next_edge], first[next_edge])
            _tri(st, first[edge], second[edge], second[next_edge])
    var bottom: Array[Vector3] = rings[0]
    var top: Array[Vector3] = rings[rings.size() - 1]
    var low_y: float = bottom[0].y
    var high_y: float = top[0].y
    for edge in range(8):
        var next_edge: int = (edge + 1) % 8
        _tri(st, Vector3(0, low_y, 0),
            bottom[edge], bottom[next_edge])
        _tri(st, Vector3(0, high_y, 0),
            top[next_edge], top[edge])
    return st.commit()

static func _cab_mesh() -> ArrayMesh:
    # Major correction seen in real 3/4 renders: the front of the cab
    # fell behind the front windshields, creating a flat empty glacis.
    # These six rings give the cab a continuous armored raked windshield
    # silhouette matching the actual pane Z=-1.101 near Y=1.22.
    # Local origin is G13_SealedCab at (0,1.08,-.66).
    return _closed_loft([
        _ring(0.475, 0.415, 0.077, -0.295, -0.060, 0.014),
        _ring(0.548, 0.448, 0.094, -0.220, -0.060, 0.022),
        _ring(0.595, 0.460, 0.115, -0.085, -0.040, 0.018),
        _ring(0.574, 0.448, 0.123, 0.075, -0.018, 0.028),
        _ring(0.535, 0.425, 0.120, 0.200, 0.015, 0.025),
        _ring(0.470, 0.398, 0.105, 0.295, 0.031, 0.006)
    ])

static func _turret_mesh() -> ArrayMesh:
    # Six working structural levels instead of a rectangular gun housing:
    # bevelled lower skirt, sharp reinforced belt and narrow upper crown.
    # Turret-local origin is G13_RemoteWeaponHousing (0,.22,0).
    # It does not alter original gun receiver or azimuth rotation pivots.
    return _closed_loft([
        _ring(0.390, 0.318, 0.079, -0.190, -0.008, 0.000),
        _ring(0.471, 0.360, 0.107, -0.115, -0.012, 0.016),
        _ring(0.509, 0.382, 0.112, -0.046, -0.022, 0.021),
        _ring(0.518, 0.368, 0.128, 0.036, -0.016, 0.024),
        _ring(0.482, 0.341, 0.107, 0.113, 0.015, 0.005),
        _ring(0.403, 0.285, 0.084, 0.190, 0.031, -0.006)
    ])

static func _roof_mesh() -> ArrayMesh:
    # Replace the huge flat roof silhouette by a low crowned and angled
    # three-stage armored canopy; stays BELOW the established V37 roof
    # shoulder rails and V45 recognition marks.
    # Local origin is G13_V11_ArmoredRoof (0,1.4,-.68), or G13_CabRoof
    # in tactical mode. Roof range still protects original glazing.
    return _closed_loft([
        _ring(0.580, 0.500, 0.120, -0.038, -0.016, 0.018),
        _ring(0.647, 0.555, 0.138, -0.008, -0.004, 0.000),
        _ring(0.579, 0.505, 0.128, 0.023, 0.012, -0.010),
        _ring(0.508, 0.442, 0.112, 0.034, 0.019, -0.014)
    ])

static func _nodes(root: Node3D, high: bool) -> Dictionary:
    var labels: Array = HERO if high else TACTICAL
    var out: Dictionary = {}
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    if hull == null or turret == null:
        return {}
    for i in range(labels.size()):
        var label: String = labels[i]
        var part := root.find_child(label, true, false) as MeshInstance3D
        if part == null or part.mesh == null:
            return {}
        var parent: Node3D = turret if i == 1 else hull
        if part.get_parent() != parent:
            return {}
        if high and not part.mesh is ArrayMesh:
            return {}
        if not high:
            # Tactical V26 already replaces the cab and turret BoxMesh with
            # real closed ArrayMesh shells. Requiring BoxMesh here rejected
            # the entire V48/V49 tactical pipeline and blocked publication.
            if i < 2 and not part.mesh is ArrayMesh:
                return {}
            if i == 2 and not (
                    part.mesh is BoxMesh or part.mesh is ArrayMesh):
                return {}
        out[label] = part
    return out

static func _paint_parts(root: Node3D) -> Dictionary:
    var parts: Dictionary = {}
    for side in [-1, 1]:
        var label: String = "G13_TurretFaction_%d" % side
        var stripe := root.find_child(label, true, false) as MeshInstance3D
        if stripe == null:
            return {}
        parts[label] = stripe
    var guards := root.find_child(
        FACTION_GUARD, true, false) as MultiMeshInstance3D
    if guards == null or guards.multimesh == null or (
            guards.multimesh.instance_count != 4):
        return {}
    parts[FACTION_GUARD] = guards
    return parts

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var high: bool = bool(root.get_meta(
        "tarvoka_g13_v1_high_detail", true))
    if high and not bool(root.get_meta(
            "tarvoka_g13_body_finish_v11", false)):
        return false
    var model_parts := _nodes(root, high)
    var paint_parts := _paint_parts(root)
    if model_parts.size() != 3 or paint_parts.size() != 3:
        return false

    # Prebuild and validate every real mesh before changing the scene.
    var shapes: Array[ArrayMesh] = [_cab_mesh(), _turret_mesh(), _roof_mesh()]
    var expected: Array[int] = [
        CAB_TRIANGLES, TURRET_TRIANGLES, ROOF_TRIANGLES]
    for i in range(shapes.size()):
        if shapes[i] == null or shapes[i].get_surface_count() != 1 or (
                shapes[i].get_faces().size() != expected[i] * 3):
            return false
    var originals: Dictionary = {}
    var sculpted: Dictionary = {}
    var labels: Array = HERO if high else TACTICAL
    for i in range(labels.size()):
        var label: String = labels[i]
        originals[label] = (model_parts[label] as MeshInstance3D).mesh
        sculpted[label] = shapes[i]

    # V44 bright side badges were several centimetres away from the housing in
    # the real render. Seat their interior edges onto the V48 x=.518
    # armored shoulder; also expose original turret faction plates.
    var paint_before: Dictionary = {}
    var paint_after: Dictionary = {}
    for side in [-1, 1]:
        var label: String = "G13_TurretFaction_%d" % side
        var badge := paint_parts[label] as MeshInstance3D
        paint_before[label] = badge.position
        var moved: Vector3 = badge.position
        moved.x = float(side) * 0.525
        paint_after[label] = moved
    var guard_node := paint_parts[FACTION_GUARD] as MultiMeshInstance3D
    var prior_transforms: Array[Transform3D] = []
    var new_transforms: Array[Transform3D] = []
    for i in range(guard_node.multimesh.instance_count):
        var old: Transform3D = guard_node.multimesh.get_instance_transform(i)
        prior_transforms.append(old)
        var new_transform: Transform3D = old
        new_transform.origin.x = (
            -0.526 if old.origin.x < 0.0 else 0.526)
        new_transforms.append(new_transform)

    root.set_meta(SAVED, {
        "source": originals,
        "finished": sculpted,
        "badge_source": paint_before,
        "badge_finished": paint_after,
        "guard_source": prior_transforms,
        "guard_finished": new_transforms,
        "hero": high
    })
    for label in labels:
        (model_parts[label] as MeshInstance3D).mesh = sculpted[label]
    for label in paint_after.keys():
        (paint_parts[label] as MeshInstance3D).position = paint_after[label]
    for i in range(new_transforms.size()):
        guard_node.multimesh.set_instance_transform(i, new_transforms[i])

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v48_real_closed_major_meshes", 3)
    root.set_meta("tarvoka_g13_v48_altered_draw_nodes", NEW_DRAW_NODES)
    root.set_meta("tarvoka_g13_v48_faction_badges_fitted", 6)
    root.set_meta("tarvoka_g13_v48_visual_only", true)
    root.set_meta("tarvoka_g13_v48_armament", "two_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var saved: Dictionary = root.get_meta(SAVED, {})
    if saved.is_empty():
        return false
    var high: bool = bool(saved.get("hero", true))
    var labels: Array = HERO if high else TACTICAL
    var parts: Dictionary = {}
    for label in labels:
        var part := root.find_child(label, true, false) as MeshInstance3D
        if part == null:
            return false
        parts[label] = part
    var paint_parts := _paint_parts(root)
    if paint_parts.size() != 3:
        return false
    var source: Dictionary = saved["source"]
    var sculpted: Dictionary = saved["finished"]
    var badge_source: Dictionary = saved["badge_source"]
    var badge_finished: Dictionary = saved["badge_finished"]
    var guards: Array = (
        saved["guard_finished"] if enabled else saved["guard_source"])
    if guards.size() != 4:
        return false
    for label in labels:
        if not source.has(label) or not sculpted.has(label):
            return false

    for label in labels:
        (parts[label] as MeshInstance3D).mesh = (
            sculpted[label] if enabled else source[label])
    for label in badge_source.keys():
        (paint_parts[label] as MeshInstance3D).position = (
            badge_finished[label] if enabled else badge_source[label])
    var node := paint_parts[FACTION_GUARD] as MultiMeshInstance3D
    for i in range(guards.size()):
        node.multimesh.set_instance_transform(i, guards[i])
    root.set_meta("tarvoka_g13_v48_preview_enabled", enabled)
    return true
