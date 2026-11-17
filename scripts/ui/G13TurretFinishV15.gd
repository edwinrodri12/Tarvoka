extends RefCounted
class_name TarvokaG13TurretFinishV15

# V15 closes the visible turret-to-chassis gap and improves tactical
# identification in day/night inspection. Real meshes, no Light3D nodes,
# no combat changes, and NEVER applied to the lightweight Android LOD8.
const FLAG := "tarvoka_g13_turret_tactical_finish_v15"
const PEDESTAL := "G13_V15_FixedTurretPedestal"
const SEAL := "G13_V15_RotatingTurretSeal"
const LOWER_SEAL := "G13_V15_FixedRubberNeck"
const RIVETS := "G13_V15_TurretSealFasteners"
const CUFF := "G13_V15_TurretSideCuff_%d"
const RECOGNITION := "G13_V15_FactionTopRail_%d"
const SEGMENTS := 24

static func _mat(color: Color,metallic: float,roughness: float)->StandardMaterial3D:
    var out := StandardMaterial3D.new()
    out.albedo_color = color
    out.metallic = metallic
    out.roughness = roughness
    out.cull_mode = BaseMaterial3D.CULL_DISABLED
    return out

static func _draw(parent: Node3D,label: String,mesh: Mesh,
        at: Vector3,material: Material)->MeshInstance3D:
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.position = at
    part.material_override = material
    parent.add_child(part)
    return part

static func _box(parent: Node3D,label: String,at: Vector3,
        size: Vector3,material: Material)->MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    return _draw(parent,label,mesh,at,material)

static func _frustum(parent: Node3D,label: String,at: Vector3,
        top_radius: float,bottom_radius: float,height: float,
        material: Material)->MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = top_radius
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    mesh.radial_segments = SEGMENTS
    return _draw(parent,label,mesh,at,material)

static func _tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3)->void:
    var normal: Vector3 = (b - a).cross(c - a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _point(radius: float,y: float,index: int)->Vector3:
    var angle: float = TAU*float(index)/float(SEGMENTS)
    return Vector3(cos(angle)*radius,y,sin(angle)*radius)

static func _annular_seal()->ArrayMesh:
    # A real four-sided hollow annular bearing skirt, closed at upper/lower
    # faces. No solid plug over the rotating ring or over the receiver.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var outer: float = 0.500
    var inner: float = 0.388
    var lower: float = 0.047
    var upper: float = 0.145
    for i in range(SEGMENTS):
        var j: int = (i+1)%SEGMENTS
        var ol0 := _point(outer,lower,i)
        var ol1 := _point(outer,lower,j)
        var ou0 := _point(outer,upper,i)
        var ou1 := _point(outer,upper,j)
        var il0 := _point(inner,lower,i)
        var il1 := _point(inner,lower,j)
        var iu0 := _point(inner,upper,i)
        var iu1 := _point(inner,upper,j)
        _tri(st,ol0,ol1,ou1)
        _tri(st,ol0,ou1,ou0)
        _tri(st,ou0,ou1,iu1)
        _tri(st,ou0,iu1,iu0)
        _tri(st,iu0,iu1,il1)
        _tri(st,iu0,il1,il0)
        _tri(st,il0,il1,ol1)
        _tri(st,il0,ol1,ol0)
    return st.commit()

static func _fasteners(turret: Node3D,material: Material)->MultiMeshInstance3D:
    # Eight rivets in one draw batch. Coordinates are turret-local,
    # so they follow azimuth but not gun elevation.
    var head := SphereMesh.new()
    head.radius = 0.013
    head.height = 0.009
    head.radial_segments = 8
    head.rings = 4
    head.material = material
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    batch.mesh = head
    batch.instance_count = 8
    for i in range(8):
        var angle: float = TAU*float(i)/8.0
        var center := Vector3(cos(angle)*0.478,0.148,sin(angle)*0.478)
        batch.set_instance_transform(i,Transform3D(Basis.IDENTITY,center))
    var result := MultiMeshInstance3D.new()
    result.name = RIVETS
    result.multimesh = batch
    turret.add_child(result)
    return result

static func _emissive(original: MeshInstance3D,color: Color)->bool:
    var old := original.material_override as StandardMaterial3D
    if old == null:
        return false
    var coat := old.duplicate() as StandardMaterial3D
    coat.emission_enabled = true
    coat.emission = color
    coat.emission_energy_multiplier = 0.56
    coat.roughness = 0.42
    original.material_override = coat
    return true

static func apply(root: Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta("tarvoka_g13_sensor_sculpt_v14",false))):
        return false
    var hull := root.find_child("G13_Casco4x4",true,false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut",true,false) as Node3D
    var ring := root.find_child("G13_RotationRing",true,false) as MeshInstance3D
    var paint := root.find_child("G13_V2_TurretInsignia_1",true,false) as MeshInstance3D
    if hull==null or turret==null or ring==null or paint==null or (
            ring.get_parent()!=turret):
        return false
    var original_paint := paint.material_override as StandardMaterial3D
    if original_paint==null:
        return false
    var lamps: Array[MeshInstance3D] = []
    for side in [-1,1]:
        var front := root.find_child("G13_Lamp_%d" % side,
            true,false) as MeshInstance3D
        var rear := root.find_child("G13_V2_RearLamp_%d" % side,
            true,false) as MeshInstance3D
        if front==null or rear==null or (
                front.material_override == null or rear.material_override == null):
            return false
        lamps.append(front)
        lamps.append(rear)
    var armor := _mat(Color("#657477"),0.33,0.70)
    var gasket := _mat(Color("#303b40"),0.19,0.88)
    var edge := _mat(Color("#919e9e"),0.50,0.54)
    var faction := original_paint.duplicate() as StandardMaterial3D
    faction.metallic = 0.30
    faction.roughness = 0.56
    # V15 visual audit: previous 0.592 m tower looked like an exposed
    # pedestal instead of a hull-integrated armored mount. The revised
    # 0.340 m tapered skirt embeds its bottom into the existing deck
    # (top ~1.12 m) and ends under the original V1 rotating ring at 1.42 m.
    # It occupies the SAME hull pivot without changing azimuth behaviour.
    _frustum(hull,PEDESTAL,Vector3(0,1.250,0.35),
        0.408,0.535,0.340,armor)
    _frustum(hull,LOWER_SEAL,Vector3(0,1.409,0.35),
        0.454,0.454,0.056,gasket)
    # Rotating annulus follows approved turret azimuth, not gun pitch.
    _draw(turret,SEAL,_annular_seal(),Vector3.ZERO,gasket)
    _fasteners(turret,edge)
    for side in [-1,1]:
        var s: float=float(side)
        _box(turret,CUFF % side,
            Vector3(s*0.464,0.171,0.222),
            Vector3(0.056,0.106,0.270),armor)
        # Colored rails are clear of the original roof emblem at x +/-0.19.
        # The original eight faction colors are cloned rather than hardcoded.
        _box(turret,RECOGNITION % side,
            Vector3(s*0.355,0.452,0.132),
            Vector3(0.082,0.018,0.284),faction)
    for i in range(4):
        var lamp: MeshInstance3D=lamps[i]
        if not _emissive(lamp,
                Color("#f5d4a0") if i%2==0 else Color("#d45846")):
            return false
    # Emission is painted surface only; no OmniLight3D/SpotLight3D and
    # no physical lighting load per unit in a large Android battle.
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v15_art_only",true)
    root.set_meta("tarvoka_g13_v15_emissive_markers",4)
    return true
