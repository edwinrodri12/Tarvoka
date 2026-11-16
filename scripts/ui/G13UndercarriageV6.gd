extends RefCounted
class_name TarvokaG13UndercarriageV6

# Art-only modular undercarriage; no gameplay physics or attack changes.
# The axles are entirely below the sealed hull, attached by compact brackets.
const FLAG := "tarvoka_g13_undercarriage_v6"
const AXLE_Y := 0.33
const AXLE_Z := 0.85
const AXLE_RADIUS := 0.058
const AXLE_LENGTH := 1.38
const HULL_BOTTOM := 0.395
const FRAME_BOTTOM := 0.409
const WHEEL_INNER_X := 0.73
const FRAME_HALF_WIDTH := 0.45

static func _mat(color: Color,metal: float=0.18)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=0.79
    return m

static func _box(parent: Node3D,label: String,p: Vector3,dim: Vector3,
        material: Material)->MeshInstance3D:
    var instance:=MeshInstance3D.new()
    instance.name=label
    var mesh:=BoxMesh.new()
    mesh.size=dim
    instance.mesh=mesh
    instance.position=p
    instance.material_override=material
    parent.add_child(instance)
    return instance

static func _cylinder(parent: Node3D,label: String,p: Vector3,radius: float,
        length: float,material: Material)->MeshInstance3D:
    var instance:=MeshInstance3D.new()
    instance.name=label
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=12
    instance.mesh=mesh
    instance.position=p
    instance.rotation_degrees=Vector3(0,0,90)
    instance.material_override=material
    parent.add_child(instance)
    return instance

static func install(root: Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    if hull==null:
        return false
    var metal:=_mat(Color("#313c40"),0.40)
    var shadow:=_mat(Color("#222a30"))
    var steel:=_mat(Color("#59676b"),0.34)
    # Dual longitudinal frame rails are inside the inner tire faces,
    # and above the centerline of the axle. No large square underbody plate.
    for side in [-1,1]:
        var x: float=float(side)*FRAME_HALF_WIDTH
        _box(hull,"G13_V6_FrameRail_%d" % side,
            Vector3(x,0.446,0.0),Vector3(0.115,0.073,2.20),metal)
        for axle in [-1,1]:
            var z: float=float(axle)*AXLE_Z
            _box(hull,"G13_V6_SuspensionMount_%d_%d" % [side,axle],
                Vector3(x,0.387,z),Vector3(0.19,0.10,0.27),steel)
            _box(hull,"G13_V6_BumpStop_%d_%d" % [side,axle],
                Vector3(float(side)*0.56,0.405,z),
                Vector3(0.10,0.065,0.15),shadow)
    # Axle cylinders run across X; ends stop 0.04m inside wheel inner faces.
    for axle in [-1,1]:
        var z: float=float(axle)*AXLE_Z
        _cylinder(hull,"G13_V6_Axle_%d" % axle,
            Vector3(0,AXLE_Y,z),AXLE_RADIUS,AXLE_LENGTH,metal)
        _box(hull,"G13_V6_Differential_%d" % axle,
            Vector3(0,0.337,z),Vector3(0.30,0.20,0.30),steel)
    # Two underbody guards are separated, keeping inspection of axles possible.
    _box(hull,"G13_V6_FrontSkid",
        Vector3(0,0.390,-1.08),Vector3(0.90,0.035,0.25),steel)
    _box(hull,"G13_V6_RearSkid",
        Vector3(0,0.390,1.08),Vector3(0.86,0.035,0.24),steel)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_underbody_visual_only",true)
    return true
