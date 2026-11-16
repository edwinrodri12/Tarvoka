extends RefCounted
class_name TarvokaG13WheelFinishV7

# Geometric wheel finish with GPU-instanced rims and tread pads.
# Art only: no physics, movement rules or tactical vehicle changes.
const FLAG := "tarvoka_g13_wheel_finish_v7"
const OUTER_RIM := "G13_V7_OuterRims"
const SIDEWALL := "G13_V7_Sidewalls"
const TREAD := "G13_V7_TreadBlocks"
const RADIUS := 0.31
const TRACK_X := 0.85
const CENTER_Y := 0.33
const AXLE_Z := 0.85
const PADS_PER_WHEEL := 8
const TREAD_RADIUS := 0.310
const TREAD_HALF_THICK := 0.012

static func _material(color: Color,metal: float=0.0)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metal
    material.roughness=0.84 if metal<0.1 else 0.49
    return material

static func _batch(parent: Node3D,label: String,mesh: Mesh,count: int)->MultiMeshInstance3D:
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=mesh
    mm.instance_count=count
    var out:=MultiMeshInstance3D.new()
    out.name=label
    out.multimesh=mm
    parent.add_child(out)
    return out

static func install(root: Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    if hull==null:
        return false
    # Four shallow sealed sidewall disks. Face disks sit outside tire faces
    # but inside the projecting alloy rim and centered hub.
    var disks:=CylinderMesh.new()
    disks.top_radius=0.245
    disks.bottom_radius=0.245
    disks.height=0.016
    disks.radial_segments=20
    disks.material=_material(Color("#292f32"))
    _batch(hull,SIDEWALL,disks,4)

    # Torus rims preserve the metal hub visible in their open center.
    var torus:=TorusMesh.new()
    torus.inner_radius=0.135
    torus.outer_radius=0.197
    torus.rings=20
    torus.ring_segments=8
    torus.material=_material(Color("#98a7aa"),0.63)
    _batch(hull,OUTER_RIM,torus,4)

    # A single GPU batch holds all 32 shallow tread pads. They follow the
    # rolling basis and preserve >0.01m fender clearance.
    var tread:=BoxMesh.new()
    tread.size=Vector3(0.095,0.024,0.165)
    tread.material=_material(Color("#34383a"))
    _batch(hull,TREAD,tread,4*PADS_PER_WHEEL)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_wheel_finish_art_only",true)
    return pose(root,0.0)

static func pose(root: Node3D,spin: float)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var rim:=root.find_child(OUTER_RIM,true,false) as MultiMeshInstance3D
    var disk:=root.find_child(SIDEWALL,true,false) as MultiMeshInstance3D
    var tread:=root.find_child(TREAD,true,false) as MultiMeshInstance3D
    if rim==null or disk==null or tread==null:
        return false
    if rim.multimesh==null or disk.multimesh==null or tread.multimesh==null:
        return false
    var i:=0
    for side in [-1,1]:
        for axle in [-1,1]:
            var sign: float=float(side)
            var center:=Vector3(sign*TRACK_X,CENTER_Y,float(axle)*AXLE_Z)
            # All cylindrical meshes start along Y and must face out along X.
            # Rolling rotation is around WORLD X, not the wheel cylinder's
            # original local vertical axis.
            var basis:=Basis(Vector3.RIGHT,spin)*Basis(Vector3.FORWARD,PI*0.5)
            disk.multimesh.set_instance_transform(i,
                Transform3D(basis,center+Vector3(sign*0.134,0,0)))
            rim.multimesh.set_instance_transform(i,
                Transform3D(basis,center+Vector3(sign*0.152,0,0)))
            for pad in range(PADS_PER_WHEEL):
                var angle:=spin+TAU*float(pad)/float(PADS_PER_WHEEL)
                var offset:=Vector3(0,cos(angle)*TREAD_RADIUS,
                    sin(angle)*TREAD_RADIUS)
                var pad_basis:=Basis(Vector3.RIGHT,angle)
                # Rectangular tread block is tangential around the wheel.
                tread.multimesh.set_instance_transform(
                    i*PADS_PER_WHEEL+pad,
                    Transform3D(pad_basis,center+offset))
            i+=1
    return true
