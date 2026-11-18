extends RefCounted
class_name TarvokaG13WheelMachiningV46

# G13 V46: actual machined wheel-center geometry for all four 4x4 wheels.
# The wheel center rotates with G13MobileAirDefenseV1._wheels_pose().
# No changes to wheel locations, clearance/collision, radar, weapons,
# animations, faction identity or approved vehicle models.
const FLAG := "tarvoka_g13_v46_machined_wheels"
const PREVIOUS := "tarvoka_g13_v45_cab_service_hardsurface"
const HUBS := "G13_V46_MachinedArmoredHubCaps"
const RINGS := "G13_V46_FactionHubRings"
const BOLTS := "G13_V46_RotatingHubBolts"
const GROOVES := "G13_V46_RadialSidewallRelief"
const DRAW_NODES := 4
const WHEEL_COUNT := 4
const BOLTS_PER_WHEEL := 8
const GROOVES_PER_WHEEL := 12
const BASE_RADIUS := 0.310
const WHEEL_X := 0.850
const WHEEL_Y := 0.330
const WHEEL_Z := 0.850

static func _mat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    return m

static func _batch(parent: Node3D, name: String, mesh: Mesh,
        material: Material, count: int) -> void:
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = mesh
    batch.instance_count = count
    var node := MultiMeshInstance3D.new()
    node.name = name
    node.multimesh = batch
    node.material_override = material
    parent.add_child(node)

static func _parts(root: Node3D) -> Dictionary:
    var parts: Dictionary = {}
    for name in [HUBS, RINGS, BOLTS, GROOVES]:
        var item := root.find_child(name, true, false) as MultiMeshInstance3D
        if item == null or item.multimesh == null:
            return {}
        parts[name] = item
    if (parts[HUBS] as MultiMeshInstance3D).multimesh.instance_count != WHEEL_COUNT or (
            (parts[RINGS] as MultiMeshInstance3D).multimesh.instance_count != WHEEL_COUNT) or (
            (parts[BOLTS] as MultiMeshInstance3D).multimesh.instance_count !=
                WHEEL_COUNT * BOLTS_PER_WHEEL) or (
            (parts[GROOVES] as MultiMeshInstance3D).multimesh.instance_count !=
                WHEEL_COUNT * GROOVES_PER_WHEEL):
        return {}
    return parts

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var wheels := root.find_child(
        "G13_Ruedas4x4MultiMesh", true, false) as MultiMeshInstance3D
    var tint := root.find_child(
        "G13_TurretFaction_1", true, false) as MeshInstance3D
    if hull == null or wheels == null or tint == null:
        return false
    if wheels.get_parent() != hull or wheels.multimesh == null or (
            wheels.multimesh.instance_count != WHEEL_COUNT) or (
            not tint.material_override is StandardMaterial3D):
        return false
    var enamel: Color = (
        tint.material_override as StandardMaterial3D).albedo_color
    # Four closed metal wheel discs replace the unarticulated flat center
    # appearance. They are slightly wider than the V1/V7 caps, but they
    # never touch the radial tire tread (0.31 m) or the upper wheel arches.
    var hub := CylinderMesh.new()
    hub.top_radius = 0.145
    hub.bottom_radius = 0.145
    hub.height = 0.026
    hub.radial_segments = 20
    var ring := TorusMesh.new()
    ring.inner_radius = 0.152
    ring.outer_radius = 0.180
    ring.rings = 24
    ring.ring_segments = 8
    var bolt := CylinderMesh.new()
    bolt.top_radius = 0.0105
    bolt.bottom_radius = 0.0105
    bolt.height = 0.012
    bolt.radial_segments = 8
    var sidewall := BoxMesh.new()
    sidewall.size = Vector3(0.013, 0.061, 0.021)
    _batch(hull, HUBS, hub,
        _mat(Color("#869599"), 0.64, 0.48), WHEEL_COUNT)
    _batch(hull, RINGS, ring,
        _mat(enamel.lightened(0.040), 0.34, 0.53), WHEEL_COUNT)
    _batch(hull, BOLTS, bolt,
        _mat(Color("#c1c7c4"), 0.60, 0.45),
        WHEEL_COUNT * BOLTS_PER_WHEEL)
    _batch(hull, GROOVES, sidewall,
        _mat(Color("#353d40"), 0.10, 0.88),
        WHEEL_COUNT * GROOVES_PER_WHEEL)
    root.set_meta(FLAG, true)
    if not pose(root, 0.0):
        return false
    root.set_meta("tarvoka_g13_v46_native_3d", true)
    root.set_meta("tarvoka_g13_v46_machined_wheel_centres", WHEEL_COUNT)
    root.set_meta("tarvoka_g13_v46_rotating_bolts", WHEEL_COUNT * BOLTS_PER_WHEEL)
    root.set_meta("tarvoka_g13_v46_sidewall_relief", WHEEL_COUNT * GROOVES_PER_WHEEL)
    root.set_meta("tarvoka_g13_v46_faction_rim_bands", WHEEL_COUNT)
    root.set_meta("tarvoka_g13_v46_draw_nodes", DRAW_NODES)
    return true

static func pose(root: Node3D, wheel_angle: float) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var parts := _parts(root)
    if parts.is_empty():
        return false
    var hub := parts[HUBS] as MultiMeshInstance3D
    var ring := parts[RINGS] as MultiMeshInstance3D
    var bolts := parts[BOLTS] as MultiMeshInstance3D
    var grooves := parts[GROOVES] as MultiMeshInstance3D
    # Uses exactly the V1 pose convention (roll around world X). One
    # original unit rig is retained; every decorative part rolls with it.
    var spin_basis := Basis(Vector3.RIGHT, wheel_angle)
    var disk_basis := spin_basis * Basis(Vector3.FORWARD, PI * 0.5)
    var index: int = 0
    for side in [-1, 1]:
        for axle in [-1, 1]:
            var sign: float = float(side)
            var c := Vector3(
                sign * WHEEL_X, WHEEL_Y, float(axle) * WHEEL_Z)
            hub.multimesh.set_instance_transform(index,
                Transform3D(disk_basis,
                    c + Vector3(sign * 0.210, 0, 0)))
            ring.multimesh.set_instance_transform(index,
                Transform3D(disk_basis,
                    c + Vector3(sign * 0.224, 0, 0)))
            for i in range(BOLTS_PER_WHEEL):
                var a: float = (
                    wheel_angle + TAU * float(i) / float(BOLTS_PER_WHEEL))
                var position := c + Vector3(sign * 0.232,
                    cos(a) * 0.113, sin(a) * 0.113)
                bolts.multimesh.set_instance_transform(
                    index * BOLTS_PER_WHEEL + i,
                    Transform3D(disk_basis, position))
            for i in range(GROOVES_PER_WHEEL):
                var a: float = (
                    wheel_angle + TAU * float(i) / float(GROOVES_PER_WHEEL))
                var position := c + Vector3(sign * 0.122,
                    cos(a) * 0.266, sin(a) * 0.266)
                var orientation := Basis(Vector3.RIGHT, a)
                grooves.multimesh.set_instance_transform(
                    index * GROOVES_PER_WHEEL + i,
                    Transform3D(orientation, position))
            index += 1
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var parts := _parts(root)
    if parts.is_empty():
        return false
    for name in [HUBS, RINGS, BOLTS, GROOVES]:
        (parts[name] as MultiMeshInstance3D).visible = enabled
    root.set_meta("tarvoka_g13_v46_preview_enabled", enabled)
    return true
