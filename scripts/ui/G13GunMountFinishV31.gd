extends RefCounted
class_name TarvokaG13GunMountFinishV31

# G13 V31 / ART ONLY: visibly articulated twin-gun mounting.
# Low-poly tactical LOD8 only. The stationary trunnion collars follow
# turret yaw, while closed armored receiver cheeks follow gun pitch.
# Both original cannons, their flash effects and V29 folding radar stay.
const FLAG := "tarvoka_g13_v31_articulated_gun_guards"
const PREV_FLAG := "tarvoka_g13_v30_radar_stowage_cradle"
const TURRET := "G13_TorretaAzimut"
const PITCH := "G13_ElevacionCanones"
const CHEEKS := "G13_V31_PitchArmoredCheeks"
const BEARINGS := "G13_V31_StationaryTrunnionCollars"
const COLLAR_RADIUS := 0.145
const COLLAR_DEPTH := 0.078
const TRIANGLE_COUNT := 48
# Convex side profile expressed as (vertical Y, fore/aft Z). The cheek
# extends in FRONT of the fixed axle rather than covering the hinge.
const PROFILE: Array[Vector2] = [
    Vector2(-0.11, -0.17),
    Vector2(-0.13, -0.33),
    Vector2(-0.07, -0.55),
    Vector2(0.02, -0.61),
    Vector2(0.13, -0.50),
    Vector2(0.16, -0.30),
    Vector2(0.09, -0.16)
]

static func _mat(color: Color, metallic: float, rough: float) -> StandardMaterial3D:
    var out := StandardMaterial3D.new()
    out.albedo_color = color
    out.metallic = metallic
    out.roughness = rough
    out.cull_mode = BaseMaterial3D.CULL_DISABLED
    return out

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_normal(normal)
    st.add_vertex(c)

static func _cheek_sculpt() -> ArrayMesh:
    # One closed, paired mesh. At the inner side the plate overlaps the
    # existing receiver by 23mm; the outer face projects beyond the turret.
    # Since it is parented to PITCH, the shields elevate WITH the two guns.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1, 1]:
        var sx: float = float(side)
        var inner: Array[Vector3] = []
        var outer: Array[Vector3] = []
        for p in PROFILE:
            inner.append(Vector3(sx * 0.342, p.x * 0.84, p.y * 0.86))
            outer.append(Vector3(sx * 0.518, p.x, p.y))
        for i in range(1, PROFILE.size() - 1):
            _tri(st, inner[0], inner[i], inner[i + 1])
            _tri(st, outer[0], outer[i + 1], outer[i])
        for i in range(PROFILE.size()):
            var j: int = (i + 1) % PROFILE.size()
            _tri(st, inner[i], inner[j], outer[j])
            _tri(st, inner[i], outer[j], outer[i])
    return st.commit()

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREV_FLAG, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    if bool(root.get_meta("tarvoka_g13_v1_high_detail", true)):
        return false
    var turret := root.find_child(TURRET, true, false) as Node3D
    var pitch := root.find_child(PITCH, true, false) as Node3D
    if turret == null or pitch == null or pitch.get_parent() != turret:
        return false
    var receiver := pitch.find_child(
        "G13_TwinGunReceiver", false, false) as MeshInstance3D
    var paint_strip := turret.find_child(
        "G13_TurretFaction_1", false, false) as MeshInstance3D
    if receiver == null or not receiver.mesh is ArrayMesh or (
            paint_strip == null or (
                not paint_strip.material_override is StandardMaterial3D)):
        return false
    if not pitch.position.is_equal_approx(Vector3(0, 0.28, -0.21)):
        return false
    for side in [-1, 1]:
        var gun := pitch.find_child(
            "G13_Autocannon_%d" % side, false, false) as MeshInstance3D
        if gun == null or not gun.mesh is CylinderMesh:
            return false
    # Honor whichever of the eight canonical faction materials is active.
    var faction: Color = (
        paint_strip.material_override as StandardMaterial3D).albedo_color
    var plate_coat := _mat(
        Color("#617378").lerp(faction, 0.34), 0.34, 0.66)
    var bearing_coat := _mat(Color("#323f45"), 0.53, 0.59)
    var armor: ArrayMesh = _cheek_sculpt()
    if armor == null or armor.get_surface_count() != 1 or (
            armor.get_faces().size() != TRIANGLE_COUNT * 3):
        return false

    var collars_mesh := CylinderMesh.new()
    collars_mesh.top_radius = COLLAR_RADIUS
    collars_mesh.bottom_radius = COLLAR_RADIUS
    collars_mesh.height = COLLAR_DEPTH
    collars_mesh.radial_segments = 12
    collars_mesh.material = bearing_coat
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = collars_mesh
    batch.instance_count = 2
    var collar_basis := Basis(Vector3.FORWARD, PI * 0.5)
    batch.set_instance_transform(0, Transform3D(
        collar_basis, Vector3(-0.512, 0.28, -0.21)))
    batch.set_instance_transform(1, Transform3D(
        collar_basis, Vector3(0.512, 0.28, -0.21)))
    var fixed := MultiMeshInstance3D.new()
    fixed.name = BEARINGS
    fixed.multimesh = batch
    turret.add_child(fixed)

    var rotating := MeshInstance3D.new()
    rotating.name = CHEEKS
    rotating.mesh = armor
    rotating.material_override = plate_coat
    pitch.add_child(rotating)

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v31_visual_only", true)
    root.set_meta("tarvoka_g13_v31_new_draw_nodes", 2)
    root.set_meta("tarvoka_g13_v31_added_triangles", TRIANGLE_COUNT + 48)
    root.set_meta("tarvoka_g13_v31_gun_count", 2)
    root.set_meta("tarvoka_g13_v31_missile_count", 0)
    root.set_meta("tarvoka_g13_v31_stationary_parent", TURRET)
    root.set_meta("tarvoka_g13_v31_pitch_parent", PITCH)
    return true
