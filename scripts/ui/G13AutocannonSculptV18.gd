extends RefCounted
class_name TarvokaG13AutocannonSculptV18

# V18 ART PASS — G13 is the approved twin-autocannon radar AA car.
# NO missiles, rockets, SAM launch tubes or missile pods. In particular,
# the old rectangular twin-gun receiver must no longer resemble a rocket pack.
# Every moving part remains under the original gun elevation pivot.
const FLAG := "tarvoka_g13_twin_autocannon_sculpt_v18"
const RECEIVER := "G13_TwinGunReceiver"
const COLLAR := "G13_V18_CannonBarrelCollar_%d"
const EJECTION := "G13_V18_CannonEjectionHatch_%d"
const FEED := "G13_V18_CannonSideFeedPort_%d"
const RIVETS := "G13_V18_CannonReceiverFasteners"
const CONFIG := "twin_autocannon_no_missiles"

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    mat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return mat

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _section(z:float,half_width:float,half_height:float,
        cut:float)->Array[Vector3]:
    return [
        Vector3(-half_width+cut,-half_height,z),
        Vector3(half_width-cut,-half_height,z),
        Vector3(half_width,-half_height+cut,z),
        Vector3(half_width,half_height-cut,z),
        Vector3(half_width-cut,half_height,z),
        Vector3(-half_width+cut,half_height,z),
        Vector3(-half_width,half_height-cut,z),
        Vector3(-half_width,-half_height+cut,z)
    ]

static func _machined_breech()->ArrayMesh:
    # Low chamfered receiver housing, not a rectangular missile canister.
    # The two cannon barrels emerge from the narrow forward face; this
    # replaces the existing BoxMesh in-place, on the SAME pitch pivot.
    var rings:Array=[
        _section(-0.263,0.285,0.086,0.047),
        _section(-0.188,0.328,0.120,0.050),
        _section(0.145,0.337,0.120,0.052),
        _section(0.278,0.302,0.095,0.044)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size()-1):
        var lower:Array=rings[layer]
        var upper:Array=rings[layer+1]
        for i in range(8):
            var j:int=(i+1)%8
            _tri(st,lower[i],upper[j],lower[j])
            _tri(st,lower[i],upper[i],upper[j])
    var head:Array=rings[0]
    var back:Array=rings[rings.size()-1]
    for i in range(1,7):
        _tri(st,head[0],head[i+1],head[i])
        _tri(st,back[0],back[i],back[i+1])
    return st.commit()

static func _draw(parent:Node3D,label:String,mesh:Mesh,
        at:Vector3,material:Material,
        rotate:Vector3=Vector3.ZERO)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=mesh
    node.position=at
    node.rotation_degrees=rotate
    node.material_override=material
    parent.add_child(node)
    return node

static func _box(parent:Node3D,label:String,at:Vector3,
        size:Vector3,material:Material)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    return _draw(parent,label,mesh,at,material)

static func _cylinder(parent:Node3D,label:String,at:Vector3,
        radius:float,depth:float,material:Material)->MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=depth
    mesh.radial_segments=16
    return _draw(parent,label,mesh,at,material,Vector3(90,0,0))

static func _rivet_batch(pitch:Node3D,material:Material)->void:
    var head:=SphereMesh.new()
    head.radius=0.011
    head.height=0.008
    head.radial_segments=8
    head.rings=3
    head.material=material
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=head
    mm.instance_count=4
    var n:int=0
    for side in [-1,1]:
        for z in [-0.235,0.015]:
            mm.set_instance_transform(n,Transform3D(
                Basis.IDENTITY,Vector3(float(side)*0.294,0.133,float(z))))
            n+=1
    var draw:=MultiMeshInstance3D.new()
    draw.name=RIVETS
    draw.multimesh=mm
    pitch.add_child(draw)

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or (
            not bool(root.get_meta(
                "tarvoka_g13_gpu_static_batches_v16",false))):
        return false
    var pitch:=root.find_child("G13_ElevacionCanones",
        true,false) as Node3D
    var gun_receiver:=root.find_child(RECEIVER,true,false) as MeshInstance3D
    if pitch==null or gun_receiver==null or (
            gun_receiver.get_parent()!=pitch) or (
            not gun_receiver.mesh is BoxMesh):
        return false
    if not gun_receiver.position.is_equal_approx(Vector3(0,0,-0.15)):
        return false
    # All geometry and motion contracts are verified BEFORE any mutation.
    for side in [-1,1]:
        var gun:=pitch.find_child("G13_Autocannon_%d" % side,
            false,false) as MeshInstance3D
        var muzzle:=pitch.find_child("G13_RealMuzzle_%d" % side,
            false,false) as MeshInstance3D
        if gun==null or muzzle==null or (
                not gun.mesh is CylinderMesh or not muzzle.mesh is ArrayMesh):
            return false
        if gun.get_parent()!=pitch or muzzle.get_parent()!=pitch:
            return false
        if (gun.mesh as CylinderMesh).top_radius>0.065:
            return false
    var metal:=_mat(Color("#8e9c9e"),0.56,0.51)
    var hardened:=_mat(Color("#29373c"),0.27,0.77)
    var inner:=_mat(Color("#1a252b"),0.14,0.88)
    # This truly replaces the box-shaped gun pack with a closed bevelled
    # articulation. The dark original material and pivot are retained.
    gun_receiver.mesh=_machined_breech()
    for side in [-1,1]:
        var s:float=float(side)
        # Compact machined collars hug each 57mm-scale cannon barrel.
        # They are NOT projectile tubes: they enclose existing guns only.
        _cylinder(pitch,COLLAR % side,Vector3(s*0.23,-0.015,-0.455),
            0.075,0.095,metal)
        # Small ejection covers above each independent cannon breech.
        _box(pitch,EJECTION % side,Vector3(s*0.228,0.129,-0.110),
            Vector3(0.118,0.014,0.178),hardened)
        # Lateral ammunition-feed access covers rather than launcher pods.
        _box(pitch,FEED % side,Vector3(s*0.343,0.013,-0.080),
            Vector3(0.012,0.072,0.148),inner)
    _rivet_batch(pitch,metal)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v18_visual_only",true)
    root.set_meta("tarvoka_g13_v18_weapon_configuration",CONFIG)
    root.set_meta("tarvoka_g13_v18_launcher_count",0)
    root.set_meta("tarvoka_g13_v18_autocannon_count",2)
    return true
