extends RefCounted
class_name TarvokaG13GunTrunnionV19

# G13 V19: real closed gun-carriage fairings and annular trunnion bearings.
# Original 4x4 vehicle, twin autocannons and radar ONLY — no missiles.
# The stationary bearing collars use turret AZIMUTH; mobile spindle caps
# and machined cheek gussets use gun PITCH (ground/air firing).
const FLAG := "tarvoka_g13_gun_trunnion_integrated_v19"
const FIXED_RING := "G13_V19_StationaryTrunnionCollar_%d"
const MOBILE_HUB := "G13_V19_MovingTrunnionHub_%d"
const CHEEK := "G13_V19_CannonReceiverCheek_%d"
const PART_COUNT := 6
const SEGMENTS := 20

static func _mat(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metallic
    material.roughness=roughness
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    return material

static func _tri(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    tool.set_normal(normal)
    tool.add_vertex(a)
    tool.set_normal(normal)
    tool.add_vertex(c)
    tool.set_normal(normal)
    tool.add_vertex(b)

static func _ring_point(x:float,r:float,index:int)->Vector3:
    var a:float=TAU*float(index)/float(SEGMENTS)
    return Vector3(x,cos(a)*r,sin(a)*r)

static func _annular_bearing()->ArrayMesh:
    # Actual open center along X: no solid plug, no fake circular decal.
    # A thin outer ring surrounds the pre-existing V12 trunnion and the
    # rotating V19 hub fits *inside* the 0.100 m clear bore.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var outer:float=0.137
    var inner:float=0.100
    var x0:float=-0.0435
    var x1:float=0.0435
    for i in range(SEGMENTS):
        var j:int=(i+1)%SEGMENTS
        var a:=_ring_point(x0,outer,i)
        var b:=_ring_point(x0,outer,j)
        var c:=_ring_point(x1,outer,i)
        var d:=_ring_point(x1,outer,j)
        var e:=_ring_point(x0,inner,i)
        var f:=_ring_point(x0,inner,j)
        var g:=_ring_point(x1,inner,i)
        var h:=_ring_point(x1,inner,j)
        # External wall, left annular face, hollow bore and right face.
        _tri(st,a,b,d)
        _tri(st,a,d,c)
        _tri(st,e,f,b)
        _tri(st,e,b,a)
        _tri(st,g,h,f)
        _tri(st,g,f,e)
        _tri(st,c,d,h)
        _tri(st,c,h,g)
    return st.commit()

static func _octagon(x:float,hy:float,half_z:float,
        center_z:float,chamfer:float)->Array[Vector3]:
    return [
        Vector3(x,-hy,center_z-half_z+chamfer),
        Vector3(x,-hy,center_z+half_z-chamfer),
        Vector3(x,-hy+chamfer,center_z+half_z),
        Vector3(x,hy-chamfer,center_z+half_z),
        Vector3(x,hy,center_z+half_z-chamfer),
        Vector3(x,hy,center_z-half_z+chamfer),
        Vector3(x,hy-chamfer,center_z-half_z),
        Vector3(x,-hy+chamfer,center_z-half_z)
    ]

static func _joint_cheek(side:int)->ArrayMesh:
    # Two closed beveled metal cheeks join the V18 receiver rear to
    # the original V12 rotating hub. They are small solid gussets,
    # NOT independent side pods or launcher containers.
    var sx:float=float(side)
    var a:Array[Vector3]=_octagon(sx*0.301,0.088,0.109,0.076,0.028)
    var b:Array[Vector3]=_octagon(sx*0.485,0.060,0.080,0.050,0.020)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(8):
        var j:int=(i+1)%8
        _tri(st,a[i],b[j],a[j])
        _tri(st,a[i],b[i],b[j])
    for i in range(1,7):
        _tri(st,a[0],a[i+1],a[i])
        _tri(st,b[0],b[i],b[i+1])
    return st.commit()

static func _mesh(parent:Node3D,name:String,geometry:Mesh,
        pos:Vector3,coat:Material)->MeshInstance3D:
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=geometry
    mesh.position=pos
    mesh.material_override=coat
    parent.add_child(mesh)
    return mesh

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta(
                "tarvoka_g13_twin_autocannon_sculpt_v18",false))):
        return false
    var turret:=root.find_child("G13_TorretaAzimut",
        true,false) as Node3D
    var pitch:=root.find_child("G13_ElevacionCanones",
        true,false) as Node3D
    var receiver:=root.find_child("G13_TwinGunReceiver",
        true,false) as MeshInstance3D
    if turret==null or pitch==null or receiver==null or (
            pitch.get_parent()!=turret) or (
            receiver.get_parent()!=pitch) or (
            not receiver.mesh is ArrayMesh):
        return false
    # Validate old V12/Twin-Gun anchors before allocating any geometry.
    for side in [-1,1]:
        var fixed:=turret.find_child(
            "G13_V12_TrunnionFixed_%d" % side,false,false) as MeshInstance3D
        var follower:=pitch.find_child(
            "G13_V12_TrunnionFollower_%d" % side,false,false) as MeshInstance3D
        var gun:=pitch.find_child("G13_Autocannon_%d" % side,
            false,false) as MeshInstance3D
        var mouth:=pitch.find_child("G13_RealMuzzle_%d" % side,
            false,false) as MeshInstance3D
        if fixed==null or follower==null or gun==null or mouth==null:
            return false
        if not fixed.mesh is CylinderMesh or (
            not follower.mesh is CylinderMesh) or (
            not gun.mesh is CylinderMesh) or (
            not mouth.mesh is ArrayMesh):
            return false
        if not fixed.position.is_equal_approx(
                Vector3(float(side)*0.415,0.280,-0.215)) or (
            not follower.position.is_equal_approx(
                Vector3(float(side)*0.420,0.0,0.0))):
            return false
    var gasket:=_mat(Color("#28383c"),0.27,0.81)
    var alloy:=_mat(Color("#87989b"),0.57,0.50)
    var armor:=_mat(Color("#65767c"),0.41,0.68)
    for side in [-1,1]:
        var sx:float=float(side)
        # Keep the fixed ring on the original azimuth turret.
        # The 0.087m deep open bearing overlaps the old 0.045m V12
        # trunnion by ~0.0m without exposing a floating axle, and
        # projects outside the armored cheek where it is legible.
        _mesh(turret,FIXED_RING % side,_annular_bearing(),
            Vector3(sx*0.482,0.280,-0.215),gasket)
        # Moving cap stays inside this longer bearing sleeve, following gun elevation.
        var hub:=CylinderMesh.new()
        hub.top_radius=0.080
        hub.bottom_radius=0.080
        hub.height=0.018
        hub.radial_segments=20
        var cap:=_mesh(pitch,MOBILE_HUB % side,hub,
            Vector3(sx*0.529,0.0,0.0),alloy)
        cap.rotation_degrees=Vector3(0,0,90)
        # Receiver-side reinforcement, contoured to the existing rear body.
        _mesh(pitch,CHEEK % side,_joint_cheek(side),
            Vector3.ZERO,armor)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v19_visual_only",true)
    root.set_meta("tarvoka_g13_v19_cannon_count",2)
    root.set_meta("tarvoka_g13_v19_launcher_count",0)
    root.set_meta("tarvoka_g13_v19_integrated_parts",PART_COUNT)
    return true
