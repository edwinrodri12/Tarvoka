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

# V17: clockwise closed lofts, with shared edges and smooth normals.
# Rings are in the XZ plane, ordered around +Y. Each ring has the same count.
static func _loft_rings(rings:Array)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var n:int=rings[0].size()
    for j in range(rings.size()-1):
        var a:Array=rings[j]
        var b:Array=rings[j+1]
        for i in range(n):
            var k:int=(i+1)%n
            for v in [a[i],a[k],b[k],a[i],b[k],b[i]]:
                st.add_vertex(v)
    var first:Array=rings[0]
    var last:Array=rings[rings.size()-1]
    for i in range(1,n-1):
        for v in [first[0],first[i+1],first[i],last[0],last[i],last[i+1]]:
            st.add_vertex(v)
    st.index()
    st.generate_normals()
    return st.commit()

static func _sculpt_blade(parent:Node3D,label:String,hero:bool,
        material:Material)->MeshInstance3D:
    # [radius, half chord, half thickness, sweep, pitch degrees].
    # Thick rounded root, swept tip and gradually reduced twist.
    var stations:Array=[
        [0.072,0.046,0.023,0.0,31.0],
        [0.155,0.066,0.020,-0.007,27.0],
        [0.305,0.061,0.014,-0.025,17.0],
        [0.440,0.040,0.009,-0.049,10.0],
        [0.505,0.013,0.004,-0.068,5.0]]
    if hero:
        stations.insert(3,[0.380,0.052,0.011,-0.037,13.0])
    var rings:Array=[]
    var sides:int=8 if hero else 6
    for section in stations:
        var ring:Array[Vector3]=[]
        for i in range(sides):
            var a:float=TAU*float(i)/float(sides)
            var cross_section:=Vector2(cos(a)*float(section[1]),
                sin(a)*float(section[2])).rotated(deg_to_rad(float(section[4])))
            ring.append(Vector3(float(section[3])+cross_section.x,
                float(section[0]),0.045+cross_section.y))
        rings.append(ring)
    var part:=MeshInstance3D.new()
    part.name=label
    # V27: metal root, graphite blade and muted tip pigmentation on
    # the same sealed blade mesh, not extra bands or transparent decals.
    var source:ArrayMesh=_loft_rings(rings)
    var arrays:Array=source.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigments:=PackedColorArray()
    for vertex in vertices:
        var shade:Color=Color("#5b6c76").lerp(Color("#303b43"),
            smoothstep(0.10,0.30,vertex.y))
        shade=shade.lerp(Color("#85949d"),0.60*smoothstep(0.43,0.505,vertex.y))
        pigments.append(shade)
    arrays[Mesh.ARRAY_COLOR]=pigments
    var finished:=ArrayMesh.new()
    finished.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    part.mesh=finished
    part.material_override=material
    parent.add_child(part)
    return part

static func _axial_shell(parent:Node3D,label:String,stations:Array,
        sides:int,material:Material)->MeshInstance3D:
    # Same loft rotated from +Y to +Z. The proper rotation preserves winding.
    var rings:Array=[]
    for section in stations:
        var ring:Array[Vector3]=[]
        for i in range(sides):
            var a:float=TAU*float(i)/float(sides)
            ring.append(Vector3(cos(a)*float(section[1]),
                float(section[0]),sin(a)*float(section[1])))
        rings.append(ring)
    var part:=MeshInstance3D.new()
    part.name=label
    part.mesh=_loft_rings(rings)
    part.rotation_degrees.x=90.0
    part.material_override=material
    parent.add_child(part)
    return part

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
    var blades:=_mat(Color.WHITE,0.15,0.68)
    blades.vertex_color_use_as_albedo=true
    blades.vertex_color_is_srgb=true
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
        _sculpt_blade(pivot,BLADE_PREFIX+str(i),hero,blades)

    var old_hub:=prop.find_child("A01_V1_ClosedMotorHub",false,false) as MeshInstance3D
    if old_hub!=null:
        old_hub.visible=false
    # Fixed fairing attached to body, not to the spinning propeller.
    var housing:=_axial_shell(body,"A01_V17_FixedMotorHousing",[
        [-0.110,0.115],[-0.065,0.139],[0.005,0.128],
        [0.055,0.090]],16 if hero else 10,graphite)
    housing.position=prop.position
    # Coaxial rotating hub sits over the three thick blade roots.
    _axial_shell(prop,"A01_V3_MotorBackplate",[
        [0.018,0.083],[0.036,0.116],[0.076,0.116],[0.093,0.088]],
        16 if hero else 10,alloy)
    _axial_shell(prop,"A01_V3_PropellerSpinner",[
        [0.068,0.091],[0.105,0.085],[0.151,0.047],[0.171,0.014]],
        16 if hero else 10,alloy)
    root.set_meta("tarvoka_a01_v27_propeller_pigment",true)
    root.set_meta("tarvoka_a01_v17_sculpted_propulsion",true)
    if hero:
        _box(body,"A01_V3_AntennaTip",
            Vector3(0,1.405,0.175),Vector3(0.035,0.080,0.035),graphite)

    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v3_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v3_unarmed_visual_only",true)
    return has_model(root)
