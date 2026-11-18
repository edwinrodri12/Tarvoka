extends RefCounted
class_name TarvokaG13CabServiceFinishV45

# Native G13 V45: closed sculpted lower maintenance doors, physically fixed
# cab glazing pillars, armoured roof brow and cooling ribs on TWO autocannons.
# This is built INSIDE the existing Godot G13 rig, not a picture or proxy.
# No gameplay, rockets, radar/weapon motion or faction palette edits.
const FLAG := "tarvoka_g13_v45_cab_service_hardsurface"
const PREVIOUS := "tarvoka_g13_v44_hard_surface_faction_finish"
const DOORS := "G13_V45_LowerFacetedServiceHatches"
const FITTINGS := "G13_V45_RecessedDoorFittings"
const PILLARS := "G13_V45_CabWindowProtectors"
const BROW := "G13_V45_ClosedArmoredWindshieldBrow"
const PAINT := "G13_V45_FactionRoofRecognitionBars"
const RIBS := "G13_V45_TwinReceiverCoolingFins"
const DOOR_TRIANGLES := 64
const BROW_TRIANGLES := 32
const DOOR_HARDWARE_COUNT := 16
const PILLAR_COUNT := 4
const PAINT_COUNT := 2
const COOLING_COUNT := 10
const DRAW_NODES := 6

static func _mat(c: Color, metal: float, rough: float) -> StandardMaterial3D:
    var out := StandardMaterial3D.new()
    out.albedo_color = c
    out.metallic = metal
    out.roughness = rough
    out.cull_mode = BaseMaterial3D.CULL_DISABLED
    return out

static func _tri(st: SurfaceTool, a: Vector3,
        b: Vector3, c: Vector3) -> void:
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

static func _prism(st: SurfaceTool, a: Array[Vector3],
        b: Array[Vector3]) -> void:
    var size: int = a.size()
    for i in range(1, size - 1):
        _tri(st, a[0], a[i], a[i + 1])
        _tri(st, b[0], b[i + 1], b[i])
    for i in range(size):
        var next: int = (i + 1) % size
        _quad(st, a[i], b[i], b[next], a[next])

static func _service_hatches() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Four fully closed five-sided hatches on the real lower hull.
    # Inner X=.664 intersects original body side X=.675; the outer
    # edge X=.722 gives a layered metallic shadow instead of a flat box.
    # Front ends at Z=-.070; rear begins Z=+.055; both stay between
    # wheel centres (-.85,+.85), out of the circular tyre envelopes.
    for side in [-1, 1]:
        for start in [-0.380, 0.055]:
            var outline: Array[Vector2] = [
                Vector2(start, 0.750),
                Vector2(start + 0.039, 0.855),
                Vector2(start + 0.262, 0.855),
                Vector2(start + 0.310, 0.775),
                Vector2(start + 0.270, 0.720)
            ]
            var inner: Array[Vector3] = []
            var outer: Array[Vector3] = []
            for p in outline:
                inner.append(Vector3(float(side) * 0.664, p.y, p.x))
                outer.append(Vector3(float(side) * 0.722, p.y, p.x))
            _prism(st, inner, outer)
    return st.commit()

static func _roof_front_brow() -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Two tapered, capped roof-front armor mounts between V37 outer rails
    # (|X|=.563) and original V2 access hatch (-.52..-.20, Z>=-.845).
    # Front Z=-1.18..-1.065 stays ahead of the roof hatch.
    var profile: Array[Vector2] = [
        Vector2(0.250, 1.407),
        Vector2(0.304, 1.462),
        Vector2(0.470, 1.462),
        Vector2(0.522, 1.418),
        Vector2(0.472, 1.399)
    ]
    for side in [-1, 1]:
        var a: Array[Vector3] = []
        var b: Array[Vector3] = []
        for p in profile:
            a.append(Vector3(float(side) * p.x, p.y, -1.186))
            b.append(Vector3(float(side) * p.x, p.y, -1.068))
        _prism(st, a, b)
    return st.commit()

static func _fitting_poses() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    for side in [-1, 1]:
        var x: float = float(side) * 0.724
        for start in [-0.380, 0.055]:
            # Two armored hinge barrels, one handle and a low lock plate.
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.020, 0.057, 0.024)),
                Vector3(x, 0.799, start + 0.040)))
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.018, 0.036, 0.025)),
                Vector3(x, 0.787, start + 0.267)))
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.025, 0.021, 0.082)),
                Vector3(x, 0.766, start + 0.197)))
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.023, 0.023, 0.026)),
                Vector3(x, 0.812, start + 0.232)))
    return poses

static func _glass_protectors() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    # V11 closed side glass is at |X|=.566 and Y=1.14..1.28.
    # These slim steel posts overlap its Z ends and do not cover the panes.
    for side in [-1, 1]:
        for z in [-1.033, -0.552]:
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.027, 0.137, 0.027)),
                Vector3(float(side) * 0.573, 1.206, float(z))))
    return poses

static func _roof_stripes() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    for side in [-1, 1]:
        poses.append(Transform3D(
            Basis.IDENTITY.scaled(Vector3(0.141, 0.011, 0.076)),
            Vector3(float(side) * 0.381, 1.462, -1.124)))
    return poses

static func _receiver_fins() -> Array[Transform3D]:
    var poses: Array[Transform3D] = []
    # These follow the real elevation pivot, not the static hull. Receiver
    # top Y=.115; each fin bottoms at .108 and is physically seated.
    for side in [-1, 1]:
        for z in [-0.198, -0.235, -0.272, -0.309, -0.346]:
            poses.append(Transform3D(
                Basis.IDENTITY.scaled(Vector3(0.125, 0.017, 0.012)),
                Vector3(float(side) * 0.230, 0.116, float(z))))
    return poses

static func _sculpt(parent: Node3D, title: String, shape: Mesh,
        color: Material) -> void:
    var node := MeshInstance3D.new()
    node.name = title
    node.mesh = shape
    node.material_override = color
    parent.add_child(node)

static func _batch(parent: Node3D, title: String, shape: Mesh,
        coat: Material, poses: Array[Transform3D]) -> void:
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = shape
    mm.instance_count = poses.size()
    for i in range(poses.size()):
        mm.set_instance_transform(i, poses[i])
    var part := MultiMeshInstance3D.new()
    part.name = title
    part.multimesh = mm
    part.material_override = coat
    parent.add_child(part)

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    var gun_pivot := root.find_child(
        "G13_ElevacionCanones", true, false) as Node3D
    var cab := root.find_child(
        "G13_SealedCab", true, false) as MeshInstance3D
    var receiver := root.find_child(
        "G13_TwinGunReceiver", true, false) as MeshInstance3D
    var faction := root.find_child(
        "G13_TurretFaction_1", true, false) as MeshInstance3D
    var v44 := root.find_child(
        "G13_V44_SculptedFactionFlanks", true, false) as MeshInstance3D
    if hull == null or turret == null or gun_pivot == null or (
            cab == null or receiver == null or faction == null or v44 == null):
        return false
    if turret.get_parent() != hull or gun_pivot.get_parent() != turret or (
            cab.get_parent() != hull or receiver.get_parent() != gun_pivot or (
            not faction.material_override is StandardMaterial3D)):
        return false
    var doors := _service_hatches()
    var brow := _roof_front_brow()
    var fittings := _fitting_poses()
    var pillars := _glass_protectors()
    var paint := _roof_stripes()
    var ribs := _receiver_fins()
    if doors == null or brow == null or (
            doors.get_faces().size() != DOOR_TRIANGLES * 3) or (
            brow.get_faces().size() != BROW_TRIANGLES * 3) or (
            fittings.size() != DOOR_HARDWARE_COUNT) or (
            pillars.size() != PILLAR_COUNT) or (
            paint.size() != PAINT_COUNT) or (
            ribs.size() != COOLING_COUNT):
        return false

    var enamel: Color = (
        faction.material_override as StandardMaterial3D).albedo_color
    var coat := _mat(Color("#56646b"), 0.45, 0.65)
    var upper := _mat(Color("#839196"), 0.46, 0.59)
    var hardware := _mat(Color("#9da9a9"), 0.62, 0.48)
    var graphite := _mat(Color("#2c383e"), 0.34, 0.75)
    var faction_coat := _mat(enamel.lightened(0.035), 0.30, 0.57)
    var cube := BoxMesh.new()
    cube.size = Vector3.ONE

    _sculpt(hull, DOORS, doors, coat)
    _batch(hull, FITTINGS, cube, hardware, fittings)
    _batch(hull, PILLARS, cube, graphite, pillars)
    _sculpt(hull, BROW, brow, upper)
    _batch(hull, PAINT, cube, faction_coat, paint)
    _batch(gun_pivot, RIBS, cube, graphite, ribs)

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v45_real_3d", true)
    root.set_meta("tarvoka_g13_v45_service_hatches", 4)
    root.set_meta("tarvoka_g13_v45_window_posts", pillars.size())
    root.set_meta("tarvoka_g13_v45_faction_roof_marks", paint.size())
    root.set_meta("tarvoka_g13_v45_gun_receiver_ribs", ribs.size())
    root.set_meta("tarvoka_g13_v45_new_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v45_weapons", "two_autocannons_no_rockets")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var draw: Array[VisualInstance3D] = []
    for label in [DOORS, FITTINGS, PILLARS, BROW, PAINT, RIBS]:
        var part := root.find_child(label, true, false) as VisualInstance3D
        if part == null:
            return false
        draw.append(part)
    for part in draw:
        part.visible = enabled
    root.set_meta("tarvoka_g13_v45_visible", enabled)
    return true
