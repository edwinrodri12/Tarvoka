extends RefCounted
class_name TarvokaA01ReconAirframeV11

# A01 V11: genuine closed tapered composite fuselage and physically seated
# faction enamel. Works on the existing unarmed V10 UAV, not the HAT-29.
# Geometry/materials only: no sensor range, fog, weapons or flight changes.
const FLAG:String="tarvoka_a01_v11_sculpted_body_conformal_paint"
const HULL:String="A01_V11_ClosedTaperedCompositeFuselage"
const CREST:String="A01_V11_ConformalDorsalFactionCrest"
const WING_L:String="A01_V11_ConformalWingEnamel_L"
const WING_R:String="A01_V11_ConformalWingEnamel_R"
const ANTENNA:String="A01_V11_SealedLowProfileAntenna"

const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V2=preload("res://scripts/ui/A01ReconFinishV2.gd")
const V4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const V10=preload("res://scripts/ui/A01ReconNoseOpticsV10.gd")

# [longitudinal z, semi-width x, semi-height y]. Fixed endpoints on both LODs.
const SECTIONS=[
    [-1.160,0.145,0.111],
    [-0.960,0.237,0.184],
    [-0.660,0.299,0.223],
    [-0.280,0.333,0.242],
    [0.140,0.344,0.245],
    [0.570,0.296,0.217],
    [0.970,0.193,0.158],
    [1.170,0.091,0.077]
]
const CENTER_Y:float=0.950

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metal
    material.roughness=rough
    material.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode=BaseMaterial3D.CULL_BACK
    return material

static func _body_cross_section(station:Array,count:int)->Array:
    var ring:Array=[]
    for index in range(count):
        var angle:float=TAU*float(index)/float(count)
        ring.append(Vector3(cos(angle)*float(station[1]),
            CENTER_Y+sin(angle)*float(station[2]),float(station[0])))
    return ring

static func _fuselage(body:Node3D,hero:bool,shell:Material)->MeshInstance3D:
    var count:int=14 if hero else 10
    var sections:Array=[]
    for station in SECTIONS:
        sections.append(_body_cross_section(station,count))
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(sections.size()-1):
        var anterior:Array=sections[j]
        var posterior:Array=sections[j+1]
        for i in range(count):
            var next:int=(i+1)%count
            var outward:Vector3=(anterior[i]+anterior[next])*0.5-Vector3(
                0,CENTER_Y,float(SECTIONS[j][0]))
            outward.z=0.0
            V10._face(t,anterior[i],anterior[next],posterior[next],outward)
            V10._face(t,anterior[i],posterior[next],posterior[i],outward)
    var nose:Array=sections[0]
    var tail:Array=sections[sections.size()-1]
    for i in range(1,count-1):
        V10._face(t,nose[0],nose[i],nose[i+1],Vector3.FORWARD)
        V10._face(t,tail[0],tail[i],tail[i+1],Vector3.BACK)
    t.generate_normals()
    var result:=MeshInstance3D.new()
    result.name=HULL
    result.mesh=t.commit()
    result.material_override=shell
    body.add_child(result)
    return result

static func _body_dimensions(z:float)->Vector2:
    for i in range(SECTIONS.size()-1):
        var a:Array=SECTIONS[i]
        var b:Array=SECTIONS[i+1]
        if z<=float(b[0]):
            var f:float=clampf((z-float(a[0]))/(float(b[0])-float(a[0])),0,1)
            return Vector2(
                lerpf(float(a[1]),float(b[1]),f),
                lerpf(float(a[2]),float(b[2]),f))
    return Vector2(float(SECTIONS[SECTIONS.size()-1][1]),
        float(SECTIONS[SECTIONS.size()-1][2]))

static func _body_surface(z:float,angle_deg:float)->Vector3:
    var d:Vector2=_body_dimensions(z)
    var a:float=deg_to_rad(angle_deg)
    return Vector3(d.x*cos(a),CENTER_Y+d.y*sin(a),z)

static func _dorsal_skin(body:Node3D,paint:Material)->MeshInstance3D:
    # A four-corner flat decal would sink INSIDE the curved fuselage near
    # its highest centerline. Sample the REAL ellipse at angular and axial
    # stations and close every boundary with opposite winding.
    var stations_z:Array=[-0.360,-0.040,0.550]
    var angles:Array=[68.0,80.0,100.0,112.0]
    var outer:Array=[]
    var inner:Array=[]
    for z in stations_z:
        var outer_row:Array=[]
        var inner_row:Array=[]
        var dims:Vector2=_body_dimensions(float(z))
        for angle in angles:
            var a:float=deg_to_rad(float(angle))
            var normal:=Vector3(cos(a)/dims.x,sin(a)/dims.y,0.0).normalized()
            var base:Vector3=_body_surface(float(z),float(angle))
            outer_row.append(base+normal*0.008)
            inner_row.append(base+normal*0.003)
        outer.append(outer_row)
        inner.append(inner_row)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z_index in range(stations_z.size()-1):
        for i in range(angles.size()-1):
            var angle_mid:float=deg_to_rad((
                float(angles[i])+float(angles[i+1]))*0.5)
            var normal:=Vector3(cos(angle_mid),sin(angle_mid),0)
            V10._face(t,outer[z_index][i],outer[z_index+1][i],
                outer[z_index+1][i+1],normal)
            V10._face(t,outer[z_index][i],outer[z_index+1][i+1],
                outer[z_index][i+1],normal)
            V10._face(t,inner[z_index][i],inner[z_index][i+1],
                inner[z_index+1][i+1],-normal)
            V10._face(t,inner[z_index][i],inner[z_index+1][i+1],
                inner[z_index+1][i],-normal)
    for i in range(angles.size()-1):
        for j in [0,stations_z.size()-1]:
            var facing:Vector3=Vector3.FORWARD if j==0 else Vector3.BACK
            V10._face(t,outer[j][i],inner[j][i],inner[j][i+1],facing)
            V10._face(t,outer[j][i],inner[j][i+1],outer[j][i+1],facing)
    for j in range(stations_z.size()-1):
        for i in [0,angles.size()-1]:
            var angle:float=deg_to_rad(float(angles[i]))
            var tangent:=Vector3(-sin(angle),cos(angle),0)
            var facing:Vector3=-tangent if i==0 else tangent
            V10._face(t,outer[j][i],inner[j][i],inner[j+1][i],facing)
            V10._face(t,outer[j][i],inner[j+1][i],outer[j+1][i],facing)
    t.generate_normals()
    var mesh:=MeshInstance3D.new()
    mesh.name=CREST
    mesh.mesh=t.commit()
    mesh.material_override=paint
    body.add_child(mesh)
    return mesh

static func _wing_surface(side:float,x:float,t:float,hero:bool)->Vector3:
    # Follows the ACTUAL top chord between V4 profile vertices 1 and 2,
    # rather than placing an axis-aligned box above a swept wing.
    var sections:Array=[[0.280,1.030,-0.364,0.264,0.100]]
    if hero:
        sections.append([0.990,1.047,-0.322,0.220,0.086])
    sections.append([1.720,1.080,-0.255,0.142,0.054])
    for index in range(sections.size()-1):
        var a:Array=sections[index]
        var b:Array=sections[index+1]
        if x<=float(b[0]):
            var f:float=clampf((x-float(a[0]))/(float(b[0])-float(a[0])),0,1)
            var y:float=lerpf(float(a[1]),float(b[1]),f)
            var leading:float=lerpf(float(a[2]),float(b[2]),f)
            var trailing:float=lerpf(float(a[3]),float(b[3]),f)
            var thickness:float=lerpf(float(a[4]),float(b[4]),f)
            return Vector3(side*x,y+thickness*(0.82-0.52*t),
                leading+(trailing-leading)*(0.18+0.67*t))
    return Vector3.ZERO

static func _triangle(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    # Godot considers clockwise triangles front-facing.
    t.add_vertex(a)
    t.add_vertex(c)
    t.add_vertex(b)

static func _closed_patch(body:Node3D,name:String,corners:Array,
        lift:Vector3,paint:Material)->MeshInstance3D:
    # True 12-triangle closed thin solid. Outer and inner faces and all
    # four boundary walls have opposite winding, without alpha materials.
    var order:Array=[0,1,2,3]
    var v0:Vector3=corners[0]
    var v1:Vector3=corners[1]
    var v2:Vector3=corners[2]
    if (v1-v0).cross(v2-v0).dot(lift)<0.0:
        order=[0,3,2,1]
    var outer:Array=[]
    var inner:Array=[]
    for index in order:
        var pos:Vector3=corners[int(index)]
        outer.append(pos+lift*0.011)
        inner.append(pos+lift*0.003)
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
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=t.commit()
    mesh.material_override=paint
    body.add_child(mesh)
    return mesh

static func _antenna(body:Node3D,hero:bool,material:Material)->MeshInstance3D:
    # Tapered closed physical antenna, rooted INSIDE the fuselage.
    # Retires the disconnected legacy rectangular mast and top stud.
    var mesh:=CylinderMesh.new()
    mesh.top_radius=0.012
    mesh.bottom_radius=0.055
    mesh.height=0.245
    mesh.radial_segments=10 if hero else 6
    var node:=MeshInstance3D.new()
    node.name=ANTENNA
    node.mesh=mesh
    node.material_override=material
    node.position=Vector3(0,1.315,0.190)
    body.add_child(node)
    return node

static func _retire(body:Node3D,name:String)->bool:
    var old:=body.find_child(name,false,false) as MeshInstance3D
    if old==null:
        return false
    old.visible=false
    return true

static func has_model(root:Node3D)->bool:
    return root!=null and V10.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(HULL,true,false) is MeshInstance3D) and (
        root.find_child(CREST,true,false) is MeshInstance3D) and (
        root.find_child(WING_L,true,false) is MeshInstance3D) and (
        root.find_child(WING_R,true,false) is MeshInstance3D) and (
        root.find_child(ANTENNA,true,false) is MeshInstance3D)

static func apply(root:Node3D,faction_color:Color,hero:bool)->bool:
    if root==null or not V10.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    # Verify all predecessors before changing visibility.
    var obsolete:Array=[
        "A01_V1_SealedCompositeFuselage",
        "A01_V1_FactionSpine",
        "A01_V1_AntennaSpine",
        V1.COLOR_MARK+"_L",V1.COLOR_MARK+"_R",
        "A01_V1_WingtipID_-1","A01_V1_WingtipID_1",
        V2.FACTION_STRIPE+"_Port",V2.FACTION_STRIPE+"_Starboard"
    ]
    if hero:
        obsolete.append("A01_V3_AntennaTip")
    for old_name in obsolete:
        if body.find_child(str(old_name),false,false)==null:
            return false
    var shell:=_mat(Color("#bfcbd2"),0.31,0.48)
    var paint:=_mat(faction_color,0.24,0.41)
    var graphite:=_mat(Color("#344853"),0.34,0.57)
    var hull:=_fuselage(body,hero,shell)
    var dorsal:=_dorsal_skin(body,paint)
    for side in [-1,1]:
        var s:float=float(side)
        _closed_patch(body,WING_L if side<0 else WING_R,[
            _wing_surface(s,1.230,0.20,hero),
            _wing_surface(s,1.550,0.20,hero),
            _wing_surface(s,1.550,0.83,hero),
            _wing_surface(s,1.230,0.83,hero)
        ],Vector3.UP,paint)
    var mast:=_antenna(body,hero,graphite)
    if hull.mesh==null or dorsal.mesh==null or mast.mesh==null:
        return false
    for name in obsolete:
        if not _retire(body,str(name)):
            return false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v11_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v11_visual_only",true)
    return has_model(root)
