extends RefCounted
class_name TarvokaA01ReconNoseOpticsV10

# V10: sealed nose loft and physical EO/IR optics finishing on the SAME
# unarmed A01 recon UAV. Visual-only; no combat, fog or economy changes.
const FLAG:String="tarvoka_a01_v10_sealed_nose_and_optics"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V9=preload("res://scripts/ui/A01ReconWingletV9.gd")
const NOSE:String="A01_V10_SealedCompositeNoseLoft"
const GIMBAL:String="A01_V10_AnnularEOIRGlassGuard"
const THERMAL:String="A01_V10_ThermalSecondaryGlass"
const PAINT_L:String="A01_V10_NoseFactionAccent_L"
const PAINT_R:String="A01_V10_NoseFactionAccent_R"
const HATCH:String="A01_V10_DorsalServiceHatch"
const SEAM_L:String="A01_V10_NoseServiceSeam_L"
const SEAM_R:String="A01_V10_NoseServiceSeam_R"

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _face(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,out:Vector3)->void:
    t.add_vertex(a)
    if (b-a).cross(c-a).dot(out)>0.0:
        t.add_vertex(c)
        t.add_vertex(b)
    else:
        t.add_vertex(b)
        t.add_vertex(c)

static func _mesh(root:Node3D,tag:String,where:Vector3,mesh:Mesh,
        surface:Material)->MeshInstance3D:
    var part:=MeshInstance3D.new()
    part.name=tag
    part.mesh=mesh
    part.position=where
    part.material_override=surface
    root.add_child(part)
    return part

static func _loft(body:Node3D,hero:bool,surface:Material)->MeshInstance3D:
    # Nose points in -Z. Every ring and both end caps are closed; no
    # double-sided transparency even when viewed underneath at 360 degrees.
    var stations:Array=[
        [-1.355,0.078,0.064],
        [-1.230,0.169,0.136],
        [-1.075,0.236,0.187],
        [-0.850,0.266,0.213],
        [-0.570,0.292,0.212]
    ]
    var sides:int=12 if hero else 8
    var rings:Array=[]
    for st in stations:
        var ring:Array[Vector3]=[]
        for i in range(sides):
            var a:float=TAU*float(i)/float(sides)
            ring.append(Vector3(cos(a)*float(st[1]),
                0.922+sin(a)*float(st[2]),float(st[0])))
        rings.append(ring)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for section in range(rings.size()-1):
        var front:Array=rings[section]
        var aft:Array=rings[section+1]
        for i in range(sides):
            var j:int=(i+1)%sides
            var radial:Vector3=0.5*(front[i]+front[j])-Vector3(
                0,0.922,float(stations[section][0]))
            radial.z=0.0
            _face(t,front[i],front[j],aft[j],radial)
            _face(t,front[i],aft[j],aft[i],radial)
    # Triangle-fan planar solid caps; no infinitely thin open cross section.
    var front_ring:Array=rings[0]
    var aft_ring:Array=rings[rings.size()-1]
    for i in range(1,sides-1):
        _face(t,front_ring[0],front_ring[i],front_ring[i+1],Vector3.FORWARD)
        _face(t,aft_ring[0],aft_ring[i],aft_ring[i+1],Vector3.BACK)
    t.generate_normals()
    return _mesh(body,NOSE,Vector3.ZERO,t.commit(),surface)

static func _annulus(pivot:Node3D,hero:bool,surface:Material)->MeshInstance3D:
    # Genuine hollow mechanical ring, not a circular plate covering the lens.
    # The inner aperture exposes the legacy blue EO glass at z=-0.278.
    var sides:int=20 if hero else 12
    var radii:Array=[0.153,0.111]
    var zfront:float=-0.320
    var zrear:float=-0.279
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(sides):
        var a:float=TAU*float(i)/float(sides)
        var b:float=TAU*float(i+1)/float(sides)
        var poa:=Vector3(cos(a)*radii[0],sin(a)*radii[0],zfront)
        var pob:=Vector3(cos(b)*radii[0],sin(b)*radii[0],zfront)
        var pia:=Vector3(cos(a)*radii[1],sin(a)*radii[1],zfront)
        var pib:=Vector3(cos(b)*radii[1],sin(b)*radii[1],zfront)
        var roa:=Vector3(cos(a)*radii[0],sin(a)*radii[0],zrear)
        var rob:=Vector3(cos(b)*radii[0],sin(b)*radii[0],zrear)
        var ria:=Vector3(cos(a)*radii[1],sin(a)*radii[1],zrear)
        var rib:=Vector3(cos(b)*radii[1],sin(b)*radii[1],zrear)
        var outward:=Vector3(cos(a+b*0.0),sin(a+b*0.0),0)
        _face(t,poa,pob,pib,Vector3.FORWARD)
        _face(t,poa,pib,pia,Vector3.FORWARD)
        _face(t,roa,rib,rob,Vector3.BACK)
        _face(t,roa,ria,rib,Vector3.BACK)
        _face(t,poa,roa,rob,outward)
        _face(t,poa,rob,pob,outward)
        _face(t,pia,pib,rib,-outward)
        _face(t,pia,rib,ria,-outward)
    t.generate_normals()
    return _mesh(pivot,GIMBAL,Vector3.ZERO,t.commit(),surface)

static func _orb(root:Node3D,name:String,at:Vector3,dimensions:Vector3,
        material:Material,hero:bool)->MeshInstance3D:
    var sphere:=SphereMesh.new()
    sphere.radius=0.5
    sphere.height=1.0
    sphere.radial_segments=12 if hero else 8
    sphere.rings=6 if hero else 4
    var part:=_mesh(root,name,at,sphere,material)
    part.scale=dimensions
    return part

static func _conformal_nose_paint(body:Node3D,name:String,side:float,
        hero:bool,enamel:Material)->MeshInstance3D:
    # Godot screenshot QA: the prior ellipsoids looked like blue pods
    # stuck to the airframe. Use polygon-matched closed enamel skins.
    # Section rings share the SAME actual loft station coordinates.
    var sections:Array=[
        [-1.075,0.236,0.187]
    ]
    # Follow the real underlying nose station in BOTH LODs.
    # Without the -0.850 ring, the Android color chord can sink through
    # the curved fuselage between its two endpoints.
    if hero:
        sections.append([-0.940,0.254,0.2026])
    sections.append([-0.850,0.266,0.213])
    # Finish on the actual interpolated section of the V10 closed nose.
    sections.append([-0.700,0.27993,0.21246])
    # Match V16 unified hull ring vertices (16 hero, 12 mobile).
    var count:int=16 if hero else 12
    var lo:int=1
    var hi:int=2
    var first:int=lo if side>0.0 else int(count/2)-hi
    var second:int=hi if side>0.0 else int(count/2)-lo
    var rings:Array=[]
    for station in sections:
        var z:float=float(station[0])
        var width:float=float(station[1])
        var height:float=float(station[2])
        var front_angle:float=TAU*float(first)/float(count)
        var back_angle:float=TAU*float(second)/float(count)
        var outward_front:=Vector3(cos(front_angle),sin(front_angle),0.0)
        var outward_back:=Vector3(cos(back_angle),sin(back_angle),0.0)
        var front_base:=Vector3(outward_front.x*width,
            0.922+outward_front.y*height,z)
        var back_base:=Vector3(outward_back.x*width,
            0.922+outward_back.y*height,z)
        rings.append([
            front_base+outward_front*0.008,
            back_base+outward_back*0.008,
            back_base+outward_back*0.003,
            front_base+outward_front*0.003
        ])
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for segment in range(rings.size()-1):
        var low:Array=rings[segment]
        var high:Array=rings[segment+1]
        var center:=Vector3.ZERO
        for vertex in low:
            center+=vertex
        center/=float(low.size())
        for edge in range(4):
            var next:int=(edge+1)%4
            var outward:Vector3=0.5*(low[edge]+low[next])-center
            outward.z=0.0
            _face(t,low[edge],high[edge],high[next],outward)
            _face(t,low[edge],high[next],low[next],outward)
    var nose_cap:Array=rings[0]
    var rear_cap:Array=rings[rings.size()-1]
    _face(t,nose_cap[0],nose_cap[1],nose_cap[2],Vector3.FORWARD)
    _face(t,nose_cap[0],nose_cap[2],nose_cap[3],Vector3.FORWARD)
    _face(t,rear_cap[0],rear_cap[1],rear_cap[2],Vector3.BACK)
    _face(t,rear_cap[0],rear_cap[2],rear_cap[3],Vector3.BACK)
    t.generate_normals()
    return _mesh(body,name,Vector3.ZERO,t.commit(),enamel)

static func _box(root:Node3D,name:String,at:Vector3,dims:Vector3,
        material:Material)->MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=dims
    return _mesh(root,name,at,mesh,material)

static func has_model(root:Node3D)->bool:
    if root==null or not V9.has_model(root) or not bool(root.get_meta(FLAG,false)):
        return false
    return (root.find_child(NOSE,true,false) is MeshInstance3D) and (
        root.find_child(GIMBAL,true,false) is MeshInstance3D) and (
        root.find_child(THERMAL,true,false) is MeshInstance3D) and (
        root.find_child(PAINT_L,true,false) is MeshInstance3D) and (
        root.find_child(PAINT_R,true,false) is MeshInstance3D)

static func apply(root:Node3D,color:Color,hero:bool)->bool:
    if root==null or not V9.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    var pivot:=root.find_child(V1.SENSOR,true,false) as Node3D
    if body==null or pivot==null:
        return false
    var original:=body.find_child("A01_V1_ClosedNoseSensorBay",false,false) as MeshInstance3D
    if original==null:
        return false
    var shell:=_mat(Color("#bbc8cf"),0.27,0.47)
    var graphite:=_mat(Color("#303e47"),0.28,0.60)
    var thermal:=_mat(Color("#357d9e"),0.08,0.16)
    var enamel:=_mat(color,0.22,0.40)
    var nose:=_loft(body,hero,shell)
    var guard:=_annulus(pivot,hero,graphite)
    # Second lens remains inside the open guard, moves WITH gimbal sweep.
    var ir:=_orb(pivot,THERMAL,Vector3(0.053,-0.048,-0.321),
        Vector3(0.055,0.055,0.013),thermal,hero)
    for side in [-1,1]:
        _conformal_nose_paint(body,PAINT_L if side<0 else PAINT_R,
            float(side),hero,enamel)
    # Three optional hero-only service details are solid and subtle.
    if hero:
        _box(body,HATCH,Vector3(0,1.138,-0.765),
            Vector3(0.168,0.017,0.208),graphite)
        _box(body,SEAM_L,Vector3(-0.255,0.914,-1.020),
            Vector3(0.018,0.073,0.150),graphite)
        _box(body,SEAM_R,Vector3(0.255,0.914,-1.020),
            Vector3(0.018,0.073,0.150),graphite)
    if nose.mesh==null or guard.mesh==null or ir.mesh==null:
        return false
    original.visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v10_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v10_visual_only",true)
    return has_model(root)
