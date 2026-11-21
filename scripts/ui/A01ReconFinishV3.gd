extends RefCounted
class_name TarvokaA01ReconFinishV3

# A01 V3: physical aviation hardware for the SAME unarmed reconnaissance UAV.
# Purely visual. Keeps A01 V1/V2 skeleton, eight faction colors, and Android LOD8.
const FLAG:String="tarvoka_a01_recon_v3_airframe_hardware"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V2=preload("res://scripts/ui/A01ReconFinishV2.gd")
const BLADE_PREFIX:String="A01_V3_RealPusherBlade_"
const CAMERA_BEARING:String="A01_V3_EOIRTrunnion"
const WINGLET:String="A01_V3_ClosedWinglet"
const TAIL_TRIM:String="A01_V3_TailControlSurface"

static func _mat(color:Color,metal:float=0.22,rough:float=0.48)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _box(parent:Node3D,label:String,at:Vector3,dim:Vector3,
        material:Material,angles:Vector3=Vector3.ZERO)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=BoxMesh.new()
    mesh.size=dim
    n.mesh=mesh
    n.material_override=material
    n.position=at
    n.rotation_degrees=angles
    parent.add_child(n)
    return n

static func _bearing(parent:Node3D,label:String,at:Vector3,
        radius:float,length:float,material:Material,sides:int)->MeshInstance3D:
    var n:=MeshInstance3D.new()
    n.name=label
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=length
    mesh.radial_segments=sides
    n.mesh=mesh
    n.material_override=material
    n.position=at
    n.rotation_degrees.z=90.0
    parent.add_child(n)
    return n

static func has_model(root:Node3D)->bool:
    if not V2.has_model(root) or not bool(root.get_meta(FLAG,false)):
        return false
    var prop:=root.find_child(V1.PROPELLER,true,false) as Node3D
    var sensor:=root.find_child(V1.SENSOR,true,false) as Node3D
    if prop==null or sensor==null:
        return false
    for i in range(3):
        if prop.find_child(BLADE_PREFIX+str(i),true,false)==null:
            return false
    return sensor.find_child(CAMERA_BEARING+"_L",true,false)!=null and (
        root.find_child(WINGLET+"_L",true,false)!=null)

static func apply(root:Node3D,color:Color,hero:bool)->bool:
    if root==null or not V2.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    var prop:=root.find_child(V1.PROPELLER,true,false) as Node3D
    var sensor:=root.find_child(V1.SENSOR,true,false) as Node3D
    if body==null or prop==null or sensor==null:
        return false
    var airframe:=_mat(Color("#b8c7cc"),0.39,0.39)
    var graphite:=_mat(Color("#242f38"),0.15,0.77)
    var alloy:=_mat(Color("#61747d"),0.62,0.34)
    var blades:=_mat(Color("#20262c"),0.12,0.65)
    var paint:=_mat(color,0.22,0.38)

    # Solid wingtip fences, tail trims and cable-protected servo joints.
    # All are 3-D solids; no alpha decals or 2-sided fake wing planes.
    for side in [-1,1]:
        var s:float=float(side)
        var suffix:String="_L" if side<0 else "_R"
        _box(body,WINGLET+suffix,Vector3(s*1.685,1.205,-0.10),
            Vector3(0.053,0.28,0.35),airframe,Vector3(0,0,-s*7.0))
        _box(body,TAIL_TRIM+suffix,Vector3(s*0.76,1.079,1.475),
            Vector3(0.21,0.044,0.12),paint,Vector3(0,0,s*16.0))
        _box(body,"A01_V3_TailServoFairing"+suffix,
            Vector3(s*0.48,0.99,1.425),Vector3(0.12,0.14,0.20),alloy)
        if hero:
            _box(body,"A01_V3_WingServiceHatch"+suffix,
                Vector3(s*0.81,1.109,-0.07),Vector3(0.22,0.018,0.21),graphite)
            _box(body,"A01_V3_TailWiringCover"+suffix,
                Vector3(s*0.47,0.992,0.91),Vector3(0.053,0.026,0.42),airframe)

    # Camera mechanical bearings are children of the animated gimbal itself.
    # Their rotation and reset follow the V1 EO/IR scan without a separate rig.
    _bearing(sensor,CAMERA_BEARING+"_L",Vector3(-0.182,0,0),
        0.135,0.072,alloy,16 if hero else 8)
    _bearing(sensor,CAMERA_BEARING+"_R",Vector3(0.182,0,0),
        0.135,0.072,alloy,16 if hero else 8)
    _box(sensor,"A01_V3_GimbalLowerProtection",Vector3(0,-0.158,0.02),
        Vector3(0.29,0.045,0.25),graphite)
    if hero:
        _box(sensor,"A01_V3_EOIRSerialPlate",Vector3(0,0.198,-0.02),
            Vector3(0.155,0.025,0.13),paint)

    # V1 used three centered boxes: optically they appeared as SIX blades.
    # Keep the V1 baseline nodes for comparison, but hide them in V3.
    # Three radial blade pivots now form exactly THREE visible single-ended
    # pusher blades; all remain children of the V1 spinning motor node.
    for i in range(3):
        var old:=prop.find_child("A01_V1_PusherBlade_"+str(i),false,false) as MeshInstance3D
        if old!=null:
            old.visible=false
        var pivot:=Node3D.new()
        pivot.name="A01_V3_PusherBladePivot_"+str(i)
        pivot.rotation_degrees.z=float(i)*120.0
        prop.add_child(pivot)
        _box(pivot,BLADE_PREFIX+str(i),Vector3(0,0.285,0.01),
            Vector3(0.115,0.44,0.044),blades,Vector3(0,0,-7.0))
        if hero:
            _box(pivot,"A01_V3_BladeSteelRoot_"+str(i),
                Vector3(0,0.125,0.022),Vector3(0.142,0.10,0.050),alloy)

    _bearing(prop,"A01_V3_MotorBackplate",Vector3(0,0,-0.067),
        0.18,0.09,graphite,18 if hero else 10)
    _bearing(prop,"A01_V3_PropellerSpinner",Vector3(0,0,0.080),
        0.13,0.13,alloy,20 if hero else 10)
    if hero:
        _box(body,"A01_V3_AntennaTip",
            Vector3(0,1.405,0.175),Vector3(0.035,0.080,0.035),graphite)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v3_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v3_unarmed_visual_only",true)
    return has_model(root)
