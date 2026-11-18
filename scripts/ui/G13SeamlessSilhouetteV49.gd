extends RefCounted
class_name TarvokaG13SeamlessSilhouetteV49

# G13 V49 — remodel the actual closed 3D meshes from V48, IN PLACE.
# Fix the window-side cab shoulder transition, turret waist/upper join and
# roof transition using denser structural lofts, not decorative add-ons.
# Independent native ArrayMeshes, no new render nodes and no new weapons.
# The original V48 resources are retained for exact same-scene comparison.
const V48 = preload("res://scripts/ui/G13SculptFinishV48.gd")
const FLAG := "tarvoka_g13_v49_window_turret_seamless_lofts"
const PREVIOUS := "tarvoka_g13_v48_major_armored_hull_sculpt"
const SAVED := "tarvoka_g13_v49_v48_and_finished_shell_meshes"
const CAB_TRIANGLES := 128
const TURRET_TRIANGLES := 128
const ROOF_TRIANGLES := 80
const DRAW_NODES := 0

static func _tri(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
    var n: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _ring(x: float, z: float, bevel: float,
        y: float, front_offset: float, rear_offset: float) -> Array[Vector3]:
    var cut: float = minf(bevel, minf(x, z) * 0.45)
    var front: float = -z + front_offset
    var rear: float = z + rear_offset
    return [
        Vector3(-x + cut, y, front),
        Vector3(x - cut, y, front),
        Vector3(x, y, front + cut),
        Vector3(x, y, rear - cut),
        Vector3(x - cut, y, rear),
        Vector3(-x + cut, y, rear),
        Vector3(-x, y, rear - cut),
        Vector3(-x, y, front + cut)
    ]

static func _loft(rings: Array) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size() - 1):
        var low: Array[Vector3] = rings[layer]
        var high: Array[Vector3] = rings[layer + 1]
        for i in range(8):
            var j: int = (i + 1) % 8
            # Godot 4 clockwise exterior winding, identical to V10/V48.
            _tri(st, low[i], high[j], low[j])
            _tri(st, low[i], high[i], high[j])
    var bottom: Array[Vector3] = rings[0]
    var top: Array[Vector3] = rings[rings.size() - 1]
    for i in range(8):
        var j: int = (i + 1) % 8
        _tri(st, Vector3(0, bottom[0].y, 0),
            bottom[i], bottom[j])
        _tri(st, Vector3(0, top[0].y, 0),
            top[j], top[i])
    return st.commit()

static func _cab_mesh() -> ArrayMesh:
    # V11 original side windows: lower outer X=+/-0.566 at Y=1.140,
    # upper X=+/-0.516 at Y=1.280. The V48 hull could overlap their
    # upper edges. Taper the EXTERIOR shoulder to X=.556/.508 at the
    # corresponding heights, giving the original windows a visible lip.
    # Original cab origin remains (0,1.08,-.66); no pane is moved.
    return _loft([
        _ring(0.475,0.415,0.077,-0.295,-0.060,0.014),
        _ring(0.548,0.448,0.094,-0.220,-0.060,0.022),
        _ring(0.595,0.460,0.115,-0.085,-0.040,0.018),
        _ring(0.578,0.451,0.120, 0.015, 0.009,0.022),
        _ring(0.556,0.439,0.123, 0.075, 0.015,0.028),
        _ring(0.508,0.422,0.117, 0.200, 0.019,0.025),
        _ring(0.486,0.410,0.109, 0.252, 0.022,0.019),
        _ring(0.470,0.398,0.105, 0.295, 0.031,0.006)
    ])

static func _turret_mesh() -> ArrayMesh:
    # V48 was a large shallow shoulder with a sudden upper crown.
    # The extra structural stations give a progressive faceted armour
    # waist and a stronger rear taper, keeping the original rotating rig.
    # Outer belt X stays <=.518; the V48 faction guards start at .5175.
    return _loft([
        _ring(0.390,0.318,0.079,-0.190,-0.008,0.000),
        _ring(0.453,0.351,0.102,-0.139,-0.012,0.008),
        _ring(0.486,0.372,0.113,-0.086,-0.016,0.014),
        _ring(0.509,0.382,0.123,-0.046,-0.020,0.021),
        _ring(0.518,0.368,0.128, 0.028,-0.015,0.020),
        _ring(0.495,0.352,0.121, 0.082, 0.006,0.010),
        _ring(0.454,0.322,0.102, 0.144, 0.023,0.003),
        _ring(0.403,0.285,0.084, 0.190, 0.031,-0.006)
    ])

static func _roof_mesh() -> ArrayMesh:
    # Roof crown retains vertical range 1.362..1.438m, BELOW the V37
    # roof reinforcement crest at Y=1.455; the forward break adds a
    # readable beveled face without hiding original V45 roof markings.
    return _loft([
        _ring(0.580,0.500,0.120,-0.038,-0.016,0.018),
        _ring(0.624,0.544,0.133,-0.021,-0.007,0.006),
        _ring(0.647,0.555,0.138,-0.008,-0.004,0.000),
        _ring(0.577,0.499,0.124, 0.026, 0.014,-0.011),
        _ring(0.508,0.442,0.112, 0.038, 0.019,-0.014)
    ])

static func _parts(root: Node3D) -> Dictionary:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return {}
    var high: bool = bool(root.get_meta(
        "tarvoka_g13_v1_high_detail", true))
    var labels: Array = V48.HERO if high else V48.TACTICAL
    var hull := root.find_child(
        "G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child(
        "G13_TorretaAzimut", true, false) as Node3D
    if hull == null or turret == null:
        return {}
    var parts: Dictionary = {}
    for i in range(labels.size()):
        var name: String = str(labels[i])
        var part := root.find_child(
            name, true, false) as MeshInstance3D
        var parent: Node3D = turret if i == 1 else hull
        if part == null or part.get_parent() != parent or (
                not part.mesh is ArrayMesh):
            return {}
        parts[name] = part
    return parts

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var parts := _parts(root)
    if parts.size() != 3:
        return false

    # Prepare and validate all replacement resources before touching the
    # existing render geometry; a rejected pass cannot partially apply.
    var updated: Array[ArrayMesh] = [
        _cab_mesh(), _turret_mesh(), _roof_mesh()]
    var expected: Array[int] = [
        CAB_TRIANGLES, TURRET_TRIANGLES, ROOF_TRIANGLES]
    var high: bool = bool(root.get_meta(
        "tarvoka_g13_v1_high_detail", true))
    var labels: Array = V48.HERO if high else V48.TACTICAL
    var original: Dictionary = {}
    var finished: Dictionary = {}
    for i in range(labels.size()):
        if updated[i] == null or (
                updated[i].get_surface_count() != 1) or (
                updated[i].get_faces().size() != expected[i] * 3):
            return false
        var name: String = str(labels[i])
        var previous_mesh := (parts[name] as MeshInstance3D).mesh
        if not previous_mesh is ArrayMesh:
            return false
        original[name] = previous_mesh
        finished[name] = updated[i]

    root.set_meta(SAVED, {
        "v48": original, "v49": finished,
        "hero": high
    })
    for name in finished.keys():
        (parts[name] as MeshInstance3D).mesh = finished[name]
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v49_real_closed_major_meshes", 3)
    root.set_meta("tarvoka_g13_v49_new_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v49_windows_repositioned", false)
    root.set_meta("tarvoka_g13_v49_faction_palette_changed", false)
    root.set_meta("tarvoka_g13_v49_animated_rig_unchanged", true)
    root.set_meta("tarvoka_g13_v49_weapons", "two_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var old: Dictionary = root.get_meta(SAVED, {})
    if old.is_empty():
        return false
    # Historical V48 inspector can swap the old V47 meshes. Ensure the
    # actual V48 faction badge positions and body nodes are restored
    # before this same-model V48/V49 comparison.
    if not V48.show_finish(root, true):
        return false
    var parts := _parts(root)
    if parts.size() != 3:
        return false
    var sources: Dictionary = old["v48"]
    var dest: Dictionary = old["v49"]
    for name in parts.keys():
        if not sources.has(name) or not dest.has(name):
            return false
    for name in parts.keys():
        (parts[name] as MeshInstance3D).mesh = (
            dest[name] if enabled else sources[name])
    root.set_meta("tarvoka_g13_v49_preview_enabled", enabled)
    return true
