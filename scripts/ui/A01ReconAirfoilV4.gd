extends RefCounted
class_name TarvokaA01ReconAirfoilV4

# V4: closed sculpted aerofoils replace the V1/V2 rectangular presentation.
# The original airframe remains the same UAV. No battle, fog or weapon changes.
const FLAG:String="tarvoka_a01_v4_sculpted_closed_aerofoil"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const WING_L:String="A01_V4_ClosedAirfoil_Left"
const WING_R:String="A01_V4_ClosedAirfoil_Right"

static func _material(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

# V24: composite wing finish uses the existing closed triangle surface.
# No raised decal, additional geometry, or transparent materials.
static func _wing_pigment(p:Vector3,hero:bool)->Color:
    var x:float=clampf(absf(p.x),0.28,1.72)
    var stations:Array=[[0.28,1.030,-0.364,0.264,0.100]]
    if hero:
        stations.append([0.99,1.047,-0.322,0.220,0.086])
    stations.append([1.72,1.080,-0.255,0.142,0.054])
    var a:Array=stations[0]
    var b:Array=stations[1]
    if hero and x>0.99:
        a=stations[1]
        b=stations[2]
    var t:float=clampf((x-float(a[0]))/(float(b[0])-float(a[0])),0.0,1.0)
    var center_y:float=lerpf(float(a[1]),float(b[1]),t)
    var leading:float=lerpf(float(a[2]),float(b[2]),t)
    var trailing:float=lerpf(float(a[3]),float(b[3]),t)
    var thickness:float=lerpf(float(a[4]),float(b[4]),t)
    var chord:float=clampf((p.z-leading)/(trailing-leading),0.0,1.0)
    var elevation:float=(p.y-center_y)/thickness
    var base:Color=Color("#60737e").lerp(Color("#8899a5"),
        smoothstep(-0.45,0.52,elevation))
    var lip:float=1.0-smoothstep(0.0,0.19,chord)
    var trailing_lip:float=smoothstep(0.82,1.0,chord)
    return base.lerp(Color("#647581"),0.35*maxf(lip,trailing_lip))

static func apply_composite_finish(wing:MeshInstance3D,hero:bool)->bool:
    if wing==null or not (wing.mesh is ArrayMesh):
        return false
    var source:=wing.mesh as ArrayMesh
    if source.get_surface_count()!=1:
        return false
    var arrays:Array=source.surface_get_arrays(0)
    var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var pigment:=PackedColorArray()
    for vertex in vertices:
        pigment.append(_wing_pigment(vertex,hero))
    arrays[Mesh.ARRAY_COLOR]=pigment
    var finished:=ArrayMesh.new()
    finished.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    var surface:=_material(Color.WHITE,0.12,0.72)
    surface.vertex_color_use_as_albedo=true
    surface.vertex_color_is_srgb=true
    wing.mesh=finished
    wing.material_override=surface
    return true

static func _profile(x:float,y:float,leading:float,trailing:float,
        thickness:float)->Array[Vector3]:
    # Six vertices around a convex aerodynamic closed cross-section.
    # Both top and underside exist, so backface culling reveals no gaps.
    var chord:float=trailing-leading
    return [
        Vector3(x,y,leading),
        Vector3(x,y+thickness*0.82,leading+chord*0.18),
        Vector3(x,y+thickness*0.30,trailing-chord*0.15),
        Vector3(x,y,trailing),
        Vector3(x,y-thickness*0.34,trailing-chord*0.15),
        Vector3(x,y-thickness*0.52,leading+chord*0.18)
    ]

static func _triangle(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        normal_out:Vector3)->void:
    # A visible manifold, never a two-sided plane or transparent material.
    tool.add_vertex(a)
    if (b-a).cross(c-a).dot(normal_out)>0.0:
        tool.add_vertex(c)
        tool.add_vertex(b)
    else:
        tool.add_vertex(b)
        tool.add_vertex(c)

static func _airfoil(parent:Node3D,label:String,stations:Array,
        s:float,paint:Material)->MeshInstance3D:
    var profiles:Array=[]
    for station in stations:
        var v:Array=station
        profiles.append(_profile(s*float(v[0]),float(v[1]),
            float(v[2]),float(v[3]),float(v[4])))
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var face_normals:Array[Vector3]=[
        Vector3(0,0.7,-0.7),Vector3.UP,Vector3(0,0.7,0.7),
        Vector3(0,-0.7,0.7),Vector3.DOWN,Vector3(0,-0.7,-0.7)
    ]
    # Six watertight sides between every adjacent span station.
    for span in range(profiles.size()-1):
        var left:Array=profiles[span]
        var right:Array=profiles[span+1]
        for edge in range(6):
            var next:int=(edge+1)%6
            var desired:Vector3=face_normals[edge]
            _triangle(tool,left[edge],right[edge],right[next],desired)
            _triangle(tool,left[edge],right[next],left[next],desired)
    # End caps are triangulated solid faces, not open wingtip holes.
    var root_section:Array=profiles[0]
    var tip_section:Array=profiles[profiles.size()-1]
    for edge in range(1,5):
        _triangle(tool,root_section[0],root_section[edge],
            root_section[edge+1],Vector3(-s,0,0))
        _triangle(tool,tip_section[0],tip_section[edge],
            tip_section[edge+1],Vector3(s,0,0))
    tool.generate_normals()
    var out:=MeshInstance3D.new()
    out.name=label
    out.mesh=tool.commit()
    out.material_override=paint
    parent.add_child(out)
    return out

# V18: follow the actual trailing edge, rather than floating a straight box
# above the swept wing. The leading overlap is buried inside the host foil.
static func _flaperon_stations(wing:Array,hero:bool)->Array:
    var span:Array=[0.60,0.73,1.43,1.55]
    if hero:
        span.insert(2,0.99)
        span.insert(3,1.20)
    var result:Array=[]
    for position in span:
        var x:float=float(position)
        for j in range(wing.size()-1):
            var a:Array=wing[j]
            var b:Array=wing[j+1]
            if x>float(b[0]):
                continue
            var t:float=(x-float(a[0]))/(float(b[0])-float(a[0]))
            var y:float=lerpf(float(a[1]),float(b[1]),t)
            var trailing:float=lerpf(float(a[3]),float(b[3]),t)
            var tip:bool=is_equal_approx(x,0.60) or is_equal_approx(x,1.55)
            var overlap:float=0.046 if tip else 0.075
            var extension:float=0.007 if tip else 0.025
            var depth:float=0.012 if tip else 0.024
            result.append([x,y+0.002,trailing-overlap,trailing+extension,depth])
            break
    return result

static func _fairing(parent:Node3D,label:String,at:Vector3,
        dimension:Vector3,material:Material,hero:bool)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=14 if hero else 8
    mesh.rings=8 if hero else 4
    node.mesh=mesh
    node.position=at
    node.scale=dimension
    node.material_override=material
    parent.add_child(node)
    return node

static func _flap(parent:Node3D,label:String,at:Vector3,dim:Vector3,
        material:Material)->MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    var mesh:=BoxMesh.new()
    mesh.size=dim
    node.mesh=mesh
    node.material_override=material
    node.position=at
    parent.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    return V3.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(WING_L,true,false) is MeshInstance3D) and (
        root.find_child(WING_R,true,false) is MeshInstance3D)

static func apply(root:Node3D,hero:bool)->bool:
    if not V3.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    var metal:=_material(Color("#8899a5"),0.12,0.72)
    var seam:=_material(Color("#6f808c"),0.16,0.70)
    # Fixed shared silhouette across both LODs; hero adds an extra section
    # for more convincing taper and surface curvature without giant meshes.
    var right_stations:Array=[
        [0.28,1.030,-0.364,0.264,0.100]
    ]
    if hero:
        right_stations.append([0.99,1.047,-0.322,0.220,0.086])
    right_stations.append([1.72,1.080,-0.255,0.142,0.054])
    for side in [-1,1]:
        var s:float=float(side)
        var suffix:String="_L" if side<0 else "_R"
        var name:String=WING_L if side<0 else WING_R
        var wing:=_airfoil(body,name,right_stations,s,metal)
        if wing.mesh==null or not apply_composite_finish(wing,hero):
            return false
        _fairing(body,"A01_V4_SmoothCompositeWingRoot"+suffix,
            Vector3(s*0.36,1.037,-0.075),
            Vector3(0.32,0.16,0.61),metal,hero)
        # Retain the historical node name for D4 visibility and repair.
        var control:=_airfoil(body,"A01_V4_SolidTrailingFlap"+suffix,
            _flaperon_stations(right_stations,hero),s,seam)
        if control.mesh==null:
            return false
        # Keep the existing V2/V3 physical faction band and winglets.
        # Retire only the redundant rectangular wing and straight V2 edges.
        var old_wing:=body.find_child(
            V1.WING_L if side<0 else V1.WING_R,false,false) as MeshInstance3D
        if old_wing!=null:
            old_wing.visible=false
        var edge:=body.find_child(
            "A01_V2_WingLeadingEdge_Port" if side<0 else
            "A01_V2_WingLeadingEdge_Starboard",false,false) as MeshInstance3D
        if edge!=null:
            edge.visible=false
        var old_flap:=body.find_child(
            "A01_V2_ClosedFlaperon_Port" if side<0 else
            "A01_V2_ClosedFlaperon_Starboard",false,false) as MeshInstance3D
        if old_flap!=null:
            old_flap.visible=false
    root.set_meta("tarvoka_a01_v24_wing_composite",true)
    root.set_meta("tarvoka_a01_v18_conformal_flaperons",true)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v4_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v4_closed_meshes_only",true)
    return has_model(root)
