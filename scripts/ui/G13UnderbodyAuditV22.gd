extends RefCounted
class_name TarvokaG13UnderbodyAuditV22

# G13 V22 360-degree visual audit correction.
# The V21 underside showed an almost uninterrupted flat rectangle even
# though the V6 axles and frame rails existed. Build real shallow,
# segmented armor, drivetrain and spring packs directly on the G13 hull.
# Hero LOD13 studio sculpture ONLY. No missiles, extra weapons, collisions,
# LOD8 Android cost, vehicle handling or gameplay changes.
const FLAG := "tarvoka_g13_v22_underbody_closed_service_finish"
const SKID := "G13_V22_UnderfloorSkid_%d_%d"
const SPRING := "G13_V22_LeafSpringPack_%d_%d"
const DIFF := "G13_V22_DifferentialCaseCover_%d"
const SHAFT := "G13_V22_PropellerDriveshaft"
const BOLTS := "G13_V22_SkidBoltsBatched"
const MESH_COUNT := 12
const FASTENERS := 16

static func _mat(hex:String,metal:float,rough:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(hex)
    material.metallic=metal
    material.roughness=rough
    material.cull_mode=BaseMaterial3D.CULL_DISABLED
    return material

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(n)
    st.add_vertex(a)
    st.set_normal(n)
    st.add_vertex(c)
    st.set_normal(n)
    st.add_vertex(b)

static func _octagon(x:float,y:float,z:float,
        hw:float,hh:float,bevel:float)->Array[Vector3]:
    var cut:float=minf(bevel,minf(hw,hh)*0.60)
    return [
        Vector3(x-hw+cut,y-hh,z),
        Vector3(x+hw-cut,y-hh,z),
        Vector3(x+hw,y-hh+cut,z),
        Vector3(x+hw,y+hh-cut,z),
        Vector3(x+hw-cut,y+hh,z),
        Vector3(x-hw+cut,y+hh,z),
        Vector3(x-hw,y+hh-cut,z),
        Vector3(x-hw,y-hh+cut,z)
    ]

static func _sealed_profile(rings:Array)->ArrayMesh:
    # Closed convex station loft with closed polygonal end caps; these
    # are genuine beveled 3D solids, not paper-thin simulated textures.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for k in range(rings.size()-1):
        var a:Array=rings[k]
        var b:Array=rings[k+1]
        for i in range(8):
            var j:int=(i+1)%8
            _tri(st,a[i],b[j],a[j])
            _tri(st,a[i],b[i],b[j])
    var start:Array=rings[0]
    var finish:Array=rings[rings.size()-1]
    for i in range(1,7):
        _tri(st,start[0],start[i+1],start[i])
        _tri(st,finish[0],finish[i],finish[i+1])
    return st.commit()

static func _skid_section(x:float,z:float)->ArrayMesh:
    # Four non-overlapping protected patches stop well short of both
    # differential housings at +/-0.85 and leave the driveshaft exposed.
    return _sealed_profile([
        _octagon(x,0.375,z-0.295,0.142,0.023,0.010),
        _octagon(x,0.369,z-0.259,0.178,0.031,0.019),
        _octagon(x,0.369,z+0.259,0.178,0.031,0.019),
        _octagon(x,0.375,z+0.295,0.142,0.023,0.010)
    ])

static func _leaf_spring(x:float,z:float)->ArrayMesh:
    # One fully closed layered-spring envelope per wheel, under the
    # pre-existing V6 mounts, with the original wheel clearances intact.
    return _sealed_profile([
        _octagon(x,0.313,z-0.236,0.038,0.014,0.007),
        _octagon(x,0.313,z-0.175,0.065,0.023,0.011),
        _octagon(x,0.313,z+0.175,0.065,0.023,0.011),
        _octagon(x,0.313,z+0.236,0.038,0.014,0.007)
    ])

static func _mesh(parent:Node3D,name:String,geo:Mesh,coat:Material,
        position:Vector3=Vector3.ZERO,
        rotate:Vector3=Vector3.ZERO)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=name
    part.mesh=geo
    part.material_override=coat
    part.position=position
    part.rotation_degrees=rotate
    parent.add_child(part)
    return part

static func _cylinder(radius:float,height:float)->CylinderMesh:
    var mesh:=CylinderMesh.new()
    mesh.bottom_radius=radius
    mesh.top_radius=radius
    mesh.height=height
    mesh.radial_segments=16
    return mesh

static func _bolt_batch(hull:Node3D,coat:Material)->void:
    var bolt:=SphereMesh.new()
    bolt.radius=0.013
    bolt.height=0.011
    bolt.radial_segments=8
    bolt.rings=3
    bolt.material=coat
    var batches:=MultiMesh.new()
    batches.transform_format=MultiMesh.TRANSFORM_3D
    batches.mesh=bolt
    batches.instance_count=FASTENERS
    var n:int=0
    for side in [-1,1]:
        for half in [-1,1]:
            for xc in [-1,1]:
                for zc in [-1,1]:
                    # All bolts are on the visible face of the plate,
                    # far inside the original inner wheel faces.
                    var px:float=float(side)*0.225+float(xc)*0.132
                    var pz:float=float(half)*0.34+float(zc)*0.238
                    batches.set_instance_transform(n,Transform3D(
                        Basis.IDENTITY,Vector3(px,0.334,pz)))
                    n+=1
    var draw:=MultiMeshInstance3D.new()
    draw.name=BOLTS
    draw.multimesh=batches
    hull.add_child(draw)

static func apply(root:Node3D)->bool:
    if root==null or bool(root.get_meta(FLAG,false)) or not bool(
            root.get_meta("tarvoka_g13_v21_swept_turret_side_armor",false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",
        true,false) as Node3D
    var floor:=root.find_child("G13_LowerMonocoque",
        true,false) as MeshInstance3D
    if hull==null or floor==null or floor.get_parent()!=hull or (
            not floor.mesh is BoxMesh):
        return false
    # All checks happen before mutating the model; existing rear/front
    # skid plates, axle centers, frame rails and wheels remain unchanged.
    for axle in [-1,1]:
        var shaft:=hull.find_child(
            "G13_V6_Axle_%d" % axle,false,false) as MeshInstance3D
        var housing:=hull.find_child(
            "G13_V6_Differential_%d" % axle,false,false) as MeshInstance3D
        if shaft==null or housing==null or (
                not shaft.mesh is CylinderMesh or (
                not housing.mesh is BoxMesh)):
            return false
        for side in [-1,1]:
            if hull.find_child("G13_V6_SuspensionMount_%d_%d" %
                    [side,axle],false,false)==null:
                return false
    var skid_mat:=_mat("#748184",0.44,0.73)
    var spring_mat:=_mat("#37444a",0.38,0.81)
    var diff_mat:=_mat("#56646b",0.45,0.70)
    var bolt_mat:=_mat("#939e9f",0.55,0.56)
    for side in [-1,1]:
        for half in [-1,1]:
            _mesh(hull,SKID % [side,half],
                _skid_section(float(side)*0.225,float(half)*0.34),skid_mat)
        for axle in [-1,1]:
            _mesh(hull,SPRING % [side,axle],
                _leaf_spring(float(side)*0.545,float(axle)*0.85),
                spring_mat)
    for axle in [-1,1]:
        _mesh(hull,DIFF % axle,_cylinder(0.119,0.041),diff_mat,
            Vector3(0,0.224,float(axle)*0.85))
    _mesh(hull,SHAFT,_cylinder(0.041,1.56),diff_mat,
        Vector3(0,0.295,0),Vector3(90,0,0))
    _bolt_batch(hull,bolt_mat)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v22_visual_only",true)
    root.set_meta("tarvoka_g13_v22_sculpt_parts",MESH_COUNT)
    root.set_meta("tarvoka_g13_v22_batched_fasteners",FASTENERS)
    root.set_meta("tarvoka_g13_v22_weapon_identity",
        "twin_autocannon_no_missiles")
    return true

static func show_baseline(root:Node3D,old:bool)->bool:
    # Same-pose native comparison for the V21 underside ONLY; hides
    # all new objects, preserving all V6 originals in both captures.
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var names:Array[String]=[SHAFT,BOLTS]
    for axle in [-1,1]:
        names.append(DIFF % axle)
        for side in [-1,1]:
            names.append(SPRING % [side,axle])
            names.append(SKID % [side,axle])
    for name in names:
        if root.find_child(name,true,false)==null:
            return false
    for name in names:
        root.find_child(name,true,false).visible=not old
    return true
