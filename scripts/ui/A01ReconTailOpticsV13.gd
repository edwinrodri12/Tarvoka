extends RefCounted
class_name TarvokaA01ReconTailOpticsV13

# A01 V13: aircraft-quality tail enamel and moving EO/IR underguard.
# Purely native visual polish on the V12.1 UNARMED reconnaissance UAV.
# Every replacement remains a solid opaque mesh; no battle-stat changes.
const FLAG:String="tarvoka_a01_v13_tail_optics_surface_finish"
const PAINT_L:String="A01_V13_ConformalVtailFactionSkin_L"
const PAINT_R:String="A01_V13_ConformalVtailFactionSkin_R"
const HINGE_L:String="A01_V13_SculptedTailRootJoint_L"
const HINGE_R:String="A01_V13_SculptedTailRootJoint_R"
const POD_GUARD:String="A01_V13_SealedMovingEOIRUnderGuard"

const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const V4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const V5=preload("res://scripts/ui/A01ReconTailV5.gd")
const V12=preload("res://scripts/ui/A01ReconWingRootV12.gd")

static func _mat(color:Color,metallic:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_BACK
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    return m

static func _tail_station(x:float,hero:bool)->Array:
    # Match the exact V5 fixed tail airfoil shape, including its middle
    # station in LOD13. There is NO separate/hovering artist's decal.
    var stages:Array=[
        [0.300,1.045,1.327,1.674,0.084]
    ]
    if hero:
        stages.append([0.660,1.110,1.365,1.650,0.064])
    stages.append([1.000,1.185,1.422,1.570,0.033])
    for j in range(stages.size()-1):
        var a:Array=stages[j]
        var b:Array=stages[j+1]
        if x<=float(b[0]):
            var t:float=clampf((x-float(a[0]))/
                (float(b[0])-float(a[0])),0.0,1.0)
            return [x,lerpf(float(a[1]),float(b[1]),t),
                lerpf(float(a[2]),float(b[2]),t),
                lerpf(float(a[3]),float(b[3]),t),
                lerpf(float(a[4]),float(b[4]),t)]
    return stages[stages.size()-1]

static func _tail_top(side:float,x:float,u:float,hero:bool)->Vector3:
    var st:Array=_tail_station(x,hero)
    var profile:Array[Vector3]=V4._profile(side*float(st[0]),
        float(st[1]),float(st[2]),float(st[3]),float(st[4]))
    # The top sloping facet lies precisely between profile[1] and [2].
    return profile[1].lerp(profile[2],u)

static func _triangle(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    t.add_vertex(a)
    t.add_vertex(b)
    t.add_vertex(c)

static func _tail_skin(body:Node3D,tag:String,side:float,hero:bool,
        enamel:Material)->MeshInstance3D:
    # Closed twelve-triangle enamel skin above the TRUE V5 wing section,
    # approximately 3-7 mm thick; no intersecting or floating boxes.
    var positions:Array=[
        _tail_top(side,0.705,0.23,hero),
        _tail_top(side,0.908,0.23,hero),
        _tail_top(side,0.908,0.79,hero),
        _tail_top(side,0.705,0.79,hero)
    ]
    var surface:Vector3=Vector3(0,0.91,0.41).normalized()
    var winding:Array=[0,1,2,3]
    if (positions[1]-positions[0]).cross(
            positions[2]-positions[0]).dot(surface)<0.0:
        winding=[0,3,2,1]
    var outer:Array=[]
    var inner:Array=[]
    for i in winding:
        var point:Vector3=positions[int(i)]
        outer.append(point+surface*0.008)
        inner.append(point+surface*0.003)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    _triangle(t,outer[0],outer[1],outer[2])
    _triangle(t,outer[0],outer[2],outer[3])
    _triangle(t,inner[0],inner[2],inner[1])
    _triangle(t,inner[0],inner[3],inner[2])
    for i in range(4):
        var j:int=(i+1)%4
        _triangle(t,outer[i],inner[i],inner[j])
        _triangle(t,outer[i],inner[j],outer[j])
    t.generate_normals()
    var out:=MeshInstance3D.new()
    out.name=tag
    out.mesh=t.commit()
    out.material_override=enamel
    body.add_child(out)
    return out

static func _rounded(parent:Node3D,tag:String,at:Vector3,extents:Vector3,
        surface:Material,hero:bool)->MeshInstance3D:
    # Actual closed tessellated capsule/ellipsoid, not a double-sided plane.
    # Kept to ONE mesh and strictly lower complexity in Android LOD8.
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=16 if hero else 8
    mesh.rings=8 if hero else 4
    var node:=MeshInstance3D.new()
    node.name=tag
    node.position=at
    node.scale=extents
    node.mesh=mesh
    node.material_override=surface
    parent.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    return root!=null and V12.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(PAINT_L,true,false) is MeshInstance3D) and (
        root.find_child(PAINT_R,true,false) is MeshInstance3D) and (
        root.find_child(HINGE_L,true,false) is MeshInstance3D) and (
        root.find_child(HINGE_R,true,false) is MeshInstance3D) and (
        root.find_child(POD_GUARD,true,false) is MeshInstance3D)

static func apply(root:Node3D,color:Color,hero:bool)->bool:
    if root==null or not V12.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    var pivot:=root.find_child(V1.SENSOR,true,false) as Node3D
    if body==null or pivot==null:
        return false
    # Check the old geometry before editing so a corrupted model never
    # silently loses a component or changes a different aircraft.
    var retired:Array[MeshInstance3D]=[]
    for side in [-1,1]:
        var suffix:String="_L" if side<0 else "_R"
        for name in ["A01_V5_VtailFactionPanel"+suffix,
                "A01_V5_ClosedTailHinge"+suffix]:
            var old:=body.find_child(name,false,false) as MeshInstance3D
            if old==null:
                return false
            retired.append(old)
        # The V3 box fared servo and exposed long wiring cover duplicate
        # the V5 closed boom and V13 rounded hinge in HERO.
        for name in ["A01_V3_TailServoFairing"+suffix,
                "A01_V3_TailWiringCover"+suffix]:
            var extra:=body.find_child(name,false,false) as MeshInstance3D
            if extra!=null:
                retired.append(extra)
    var old_pod:=pivot.find_child("A01_V3_GimbalLowerProtection",
        false,false) as MeshInstance3D
    if old_pod==null:
        return false
    retired.append(old_pod)
    var paint:=_mat(color,0.24,0.42)
    var composite:=_mat(Color("#c3cfd2"),0.29,0.46)
    var graphite:=_mat(Color("#303e47"),0.28,0.60)
    for side in [-1,1]:
        var s:float=float(side)
        var skin:=_tail_skin(body,PAINT_L if side<0 else PAINT_R,
            s,hero,paint)
        var hinge:=_rounded(body,HINGE_L if side<0 else HINGE_R,
            Vector3(s*0.465,1.052,1.455),
            Vector3(0.138,0.073,0.151),composite,hero)
        if skin.mesh==null or hinge.mesh==null:
            return false
    # The new protective lower skirt is parented to the existing animated
    # EO/IR pivot, preserving scan, rotation, Stop and damage/repair behavior.
    var guard:=_rounded(pivot,POD_GUARD,Vector3(0,-0.158,0.018),
        Vector3(0.287,0.071,0.245),graphite,hero)
    if guard.mesh==null:
        return false
    for obsolete in retired:
        obsolete.visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v13_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v13_visual_only",true)
    return has_model(root)
