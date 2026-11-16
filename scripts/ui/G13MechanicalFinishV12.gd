extends RefCounted
class_name TarvokaG13MechanicalFinishV12

# G13 V12: physical body joints, weapon bearings and open gun muzzles.
# Hero detail 13 only. Every part is real Godot geometry: no textures
# pretending to be a mesh, and no gameplay or targeting changes.
const FLAG := "tarvoka_g13_mechanical_finish_v12"
const MOUTH := "G13_RealMuzzle_%d"
const SLEEVE := "G13_V12_RecoilSleeve_%d"
const BEARING := "G13_V12_TrunnionFixed_%d"
const FOLLOWER := "G13_V12_TrunnionFollower_%d"
const ARM := "G13_V12_GunBrace_%d"
const FASTENERS := "G13_V12_RoofBolts"

static func _metal(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m

static func _cylinder(parent: Node3D, label: String, pos: Vector3,
        radius: float, depth: float, material: Material,
        orientation: Vector3 = Vector3.ZERO, segments: int = 16) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = depth
    mesh.radial_segments = segments
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.material_override = material
    node.position = pos
    node.rotation_degrees = orientation
    parent.add_child(node)
    return node

static func _rod(parent: Node3D, label: String, start: Vector3, end: Vector3,
        radius: float, material: Material) -> MeshInstance3D:
    var vector: Vector3 = end - start
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = vector.length()
    mesh.radial_segments = 8
    var rod := MeshInstance3D.new()
    rod.name = label
    rod.mesh = mesh
    rod.material_override = material
    rod.position = (start + end) * 0.5
    rod.basis = Basis(Quaternion(Vector3.UP, vector.normalized()))
    parent.add_child(rod)
    return rod

static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _circle(radius: float, angle: float, z: float) -> Vector3:
    return Vector3(cos(angle) * radius, sin(angle) * radius, z)

static func _open_muzzle() -> ArrayMesh:
    # A proper open annular muzzle, with an actual 0.048 m inner bore
    # and 0.090 m depth. No solid disk obstructs its frontal silhouette.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var segments: int = 20
    var outer: float = 0.082
    var inner: float = 0.048
    var front: float = -0.050
    var back: float = 0.046
    for i in range(segments):
        var a: float = TAU * float(i) / float(segments)
        var b: float = TAU * float(i + 1) / float(segments)
        var of0 := _circle(outer, a, front)
        var of1 := _circle(outer, b, front)
        var ob0 := _circle(outer, a, back)
        var ob1 := _circle(outer, b, back)
        var inf0 := _circle(inner, a, front)
        var inf1 := _circle(inner, b, front)
        var inb0 := _circle(inner, a, back)
        var inb1 := _circle(inner, b, back)
        # Four independent closed annular surfaces: front lip, rear lip,
        # outer barrel casing and concave inner tube wall.
        _tri(st, of0, of1, inf1)
        _tri(st, of0, inf1, inf0)
        _tri(st, ob1, ob0, inb0)
        _tri(st, ob1, inb0, inb1)
        _tri(st, of0, ob0, ob1)
        _tri(st, of0, ob1, of1)
        _tri(st, inf1, inb1, inb0)
        _tri(st, inf1, inb0, inf0)
    return st.commit()

static func _bolt_batch(hull: Node3D, material: Material) -> MultiMeshInstance3D:
    # Eight flush roof fasteners use one GPU batch, not eight draw calls.
    var head := SphereMesh.new()
    head.radius = 0.016
    head.height = 0.011
    head.radial_segments = 8
    head.rings = 4
    head.material = material
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = head
    batch.instance_count = 8
    var n: int = 0
    for side in [-1, 1]:
        for z in [-1.055, -0.835, -0.615, -0.395]:
            batch.set_instance_transform(n, Transform3D(Basis.IDENTITY,
                Vector3(float(side) * 0.57, 1.421, float(z))))
            n += 1
    var out := MultiMeshInstance3D.new()
    out.name = FASTENERS
    out.multimesh = batch
    hull.add_child(out)
    return out

static func install(root: Node3D) -> bool:
    if root == null or bool(root.get_meta(FLAG, false)) or (
            not bool(root.get_meta("tarvoka_g13_body_finish_v11", false))):
        return false
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    var pitch := root.find_child("G13_ElevacionCanones", true, false) as Node3D
    var roof := root.find_child("G13_V11_ArmoredRoof", true, false) as MeshInstance3D
    if hull == null or turret == null or pitch == null or roof == null:
        return false
    var barrels: Array[MeshInstance3D] = []
    var mouths: Array[MeshInstance3D] = []
    for side in [-1, 1]:
        var barrel := pitch.find_child("G13_Autocannon_%d" % side,
            false, false) as MeshInstance3D
        var mouth := pitch.find_child(MOUTH % side,
            false, false) as MeshInstance3D
        if barrel == null or mouth == null or not mouth.mesh is CylinderMesh:
            return false
        barrels.append(barrel)
        mouths.append(mouth)
    var gasket := _metal(Color("#303a3d"), 0.27, 0.79)
    var reinforced := _metal(Color("#879396"), 0.54, 0.54)
    var titanium := _metal(Color("#a3aaa7"), 0.62, 0.43)
    var dark := _metal(Color("#232c30"), 0.24, 0.77)

    # Raised weld seams are physically thin round profiles following the
    # V11 tapered doors. They do not enter the four wheel arches.
    for side in [-1, 1]:
        var s: float = float(side)
        _rod(hull, "G13_V12_SillWeld_%d" % side,
            Vector3(s * 0.597, 0.955, -0.97),
            Vector3(s * 0.598, 0.955, -0.415), 0.011, gasket)
        _rod(hull, "G13_V12_RearDoorJoint_%d" % side,
            Vector3(s * 0.598, 0.955, -0.415),
            Vector3(s * 0.550, 1.157, -0.415), 0.012, gasket)
        _rod(hull, "G13_V12_WindshieldPost_%d" % side,
            Vector3(s * 0.525, 1.326, -1.017),
            Vector3(s * 0.579, 1.112, -1.113), 0.015, reinforced)
    _rod(hull, "G13_V12_FrontGlassCenterSeal",
        Vector3(0, 1.087, -1.144), Vector3(0, 1.355, -1.016),
        0.013, gasket)
    _bolt_batch(hull, titanium)

    # Fixed trunnion housings are attached to the AZIMUTH ring. Interior
    # followers and support links attach to the PITCH pivot, so elevation
    # is physically visible without introducing a second animation rig.
    for side in [-1, 1]:
        var s: float = float(side)
        _cylinder(turret, BEARING % side, Vector3(s * 0.415, 0.280, -0.215),
            0.112, 0.045, dark, Vector3(0, 0, 90))
        _cylinder(pitch, FOLLOWER % side, Vector3(s * 0.420, 0.0, 0.0),
            0.073, 0.026, titanium, Vector3(0, 0, 90))
        _rod(pitch, ARM % side,
            Vector3(s * 0.397, -0.015, -0.065),
            Vector3(s * 0.385, -0.078, -0.350), 0.025, reinforced)
        # The old barrel nodes move by 2.5 cm during V4 recoil. Attaching
        # sleeves to those same barrel nodes makes them recoil correctly.
        _cylinder(barrels[0 if side == -1 else 1], SLEEVE % side,
            Vector3(0, 0, 0.325), 0.084, 0.270, reinforced,
            Vector3(90, 0, 0))
        # Replace the V1 sealed muzzle CAPS rather than overlaying extra
        # cylinders. V4 still animates the original G13_RealMuzzle pivots.
        mouths[0 if side == -1 else 1].mesh = _open_muzzle()
        mouths[0 if side == -1 else 1].material_override = dark
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v12_visual_only", true)
    return true
