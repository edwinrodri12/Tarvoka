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
# Unified longitudinal shell: the V10 nose profile is now part of the
# SAME closed mesh as the central fuselage, without overlapping end caps.
const SECTIONS=[
    [-1.355,0.078,0.064],
    [-1.230,0.169,0.136],
    [-1.075,0.236,0.187],
    [-0.940,0.254,0.2026],
    [-0.850,0.266,0.213],
    [-0.700,0.27993,0.21246],
    [-0.570,0.303,0.226],
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

static func _center_y(z:float)->float:
    return lerpf(0.922,CENTER_Y,clampf((z+0.700)/0.130,0.0,1.0))

static func _body_cross_section(station:Array,count:int)->Array:
    var ring:Array=[]
    for index in range(count):
        var angle:float=TAU*float(index)/float(count)
        ring.append(Vector3(cos(angle)*float(station[1]),
            _center_y(float(station[0]))+sin(angle)*float(station[2]),float(station[0])))
    return ring

# V19: a two-tone composite finish and faction shoulder pigment are
# encoded on the existing sealed shell, not added as floating decals.
static func _hull_pigment(p:Vector3,faction:Color)->Color:
    var d:Vector2=_body_dimensions(p.z)
    var lateral:float=absf(p.x)/maxf(d.x,0.001)
    var elevation:float=(p.y-_center_y(p.z))/maxf(d.y,0.001)
    var base:Color=Color("#53636e").lerp(Color("#91a0aa"),
        smoothstep(-0.85,0.55,elevation))
    var axial:float=smoothstep(-1.30,-0.57,p.z)*(1.0-smoothstep(0.57,1.16,p.z))
    var shoulder:float=smoothstep(0.42,0.90,lateral)*smoothstep(-0.62,0.35,elevation)
    var result:Color=base.lerp(faction,0.66*axial*shoulder)
    result.a=1.0
    return result

static func _hull_face(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        outward:Vector3,faction:Color)->void:
    # Same clockwise winding as V16. Color is a deterministic function of
    # position, so shared indexed vertices keep their smooth normals.
    var vertices:Array[Vector3]=[a,b,c]
    if (b-a).cross(c-a).dot(outward)>0.0:
        vertices=[a,c,b]
    for vertex in vertices:
        t.set_color(_hull_pigment(vertex,faction))
        t.add_vertex(vertex)

static func _fuselage(body:Node3D,hero:bool,shell:Material,faction:Color)->MeshInstance3D:
    var count:int=16 if hero else 12
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
                0,_center_y(float(SECTIONS[j][0])),float(SECTIONS[j][0]))
            outward.z=0.0
            _hull_face(t,anterior[i],anterior[next],posterior[next],outward,faction)
            _hull_face(t,anterior[i],posterior[next],posterior[i],outward,faction)
    var nose:Array=sections[0]
    var tail:Array=sections[sections.size()-1]
    for i in range(1,count-1):
        _hull_face(t,nose[0],nose[i],nose[i+1],Vector3.FORWARD,faction)
        _hull_face(t,tail[0],tail[i],tail[i+1],Vector3.BACK,faction)
    t.index()
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
    return Vector3(d.x*cos(a),_center_y(z)+d.y*sin(a),z)

static func _dorsal_skin(body:Node3D,paint:Material,hero:bool)->MeshInstance3D:
    # A four-corner flat decal would sink INSIDE the curved fuselage near
    # its highest centerline. Sample the REAL ellipse at angular and axial
    # stations and close every boundary with opposite winding.
    var stations_z:Array=[-0.570,-0.280,0.140,0.570,0.760]
    # Exact angular vertices of the unified 12/16-sided shell.
    var angles:Array=[45.0,67.5,90.0,112.5,135.0] if hero else [60.0,90.0,120.0]
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
            outer_row.append(base+normal*0.004)
            inner_row.append(base-normal*0.002)
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

# V16.1: closed service skins fitted to the polygonal hull.
static func _flush_service_panel(body:Node3D,tag:String,zs:Array,angles:Array,
        hero:bool,material:Material)->void:
    var step:float=360.0/float(16 if hero else 12)
    var outer:Array=[]
    var inner:Array=[]
    for z_value in zs:
        var z:float=float(z_value)
        var outer_row:Array=[]
        var inner_row:Array=[]
        for angle_value in angles:
            var angle:float=float(angle_value)
            var lo:float=floorf(angle/step)*step
            var base:Vector3=_body_surface(z,lo).lerp(
                _body_surface(z,lo+step),(angle-lo)/step)
            var n:=Vector3(cos(deg_to_rad(angle)),sin(deg_to_rad(angle)),0)
            outer_row.append(base+n*0.0035)
            inner_row.append(base-n*0.004)
        outer.append(outer_row)
        inner.append(inner_row)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(zs.size()-1):
        for i in range(angles.size()-1):
            var a:float=deg_to_rad((float(angles[i])+float(angles[i+1]))*0.5)
            var n:=Vector3(cos(a),sin(a),0)
            V10._face(t,outer[j][i],outer[j+1][i],outer[j+1][i+1],n)
            V10._face(t,outer[j][i],outer[j+1][i+1],outer[j][i+1],n)
            V10._face(t,inner[j][i],inner[j+1][i+1],inner[j+1][i],-n)
            V10._face(t,inner[j][i],inner[j][i+1],inner[j+1][i+1],-n)
    for j in [0,zs.size()-1]:
        var n:Vector3=Vector3.FORWARD if j==0 else Vector3.BACK
        for i in range(angles.size()-1):
            V10._face(t,outer[j][i],inner[j][i],inner[j][i+1],n)
            V10._face(t,outer[j][i],inner[j][i+1],outer[j][i+1],n)
    for i in [0,angles.size()-1]:
        var a:float=deg_to_rad(float(angles[i]))
        var tangent:=Vector3(-sin(a),cos(a),0)
        var n:Vector3=-tangent if i==0 else tangent
        for j in range(zs.size()-1):
            V10._face(t,outer[j][i],inner[j][i],inner[j+1][i],n)
            V10._face(t,outer[j][i],inner[j+1][i],outer[j+1][i],n)
    t.index()
    t.generate_normals()
    var part:=body.find_child(tag,false,false) as MeshInstance3D
    if part!=null:
        part.mesh=t.commit()
        part.position=Vector3.ZERO
        part.material_override=material

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
        outer.append(pos+lift*0.005)
        inner.append(pos-lift*0.003)
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
    node.position=Vector3(0,1.285,0.190)
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
        "A01_V1_SealedCompositeFuselage",V10.NOSE,
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
    var shell:=_mat(Color.WHITE,0.12,0.72)
    shell.vertex_color_use_as_albedo=true
    shell.vertex_color_is_srgb=true
    var paint:=_mat(faction_color,0.12,0.64)
    var graphite:=_mat(Color("#344853"),0.34,0.57)
    var hull:=_fuselage(body,hero,shell,faction_color)
    var dorsal:=_dorsal_skin(body,paint,hero)
    for side in [-1,1]:
        var s:float=float(side)
        _closed_patch(body,WING_L if side<0 else WING_R,[
            _wing_surface(s,1.215,0.13,hero),
            _wing_surface(s,1.640,0.13,hero),
            _wing_surface(s,1.640,0.90,hero),
            _wing_surface(s,1.215,0.90,hero)
        ],Vector3.UP,paint)
    if hero:
        var service:=_mat(Color("#71838d"),0.27,0.62)
        _flush_service_panel(body,V10.HATCH,[-0.850,-0.700,-0.660],
            [72.0,90.0,108.0],hero,service)
        _flush_service_panel(body,V10.SEAM_R,[-1.075,-0.940,-0.910],
            [-9.0,0.0,9.0],hero,service)
        _flush_service_panel(body,V10.SEAM_L,[-1.075,-0.940,-0.910],
            [171.0,180.0,189.0],hero,service)
        # V23 audit: retire the remaining V2 box presentation. These are
        # the original three node IDs, seated on the real hull facets.
        # The nose access seam and aft intake remain outside the dorsal crest.
        _flush_service_panel(body,"A01_V2_NoseCompositeSeam",
            [-1.230,-1.185,-1.135],[67.5,90.0,112.5],hero,service)
        _flush_service_panel(body,"A01_V2_ProtectedAirIntake",
            [0.805,0.865,0.925],[67.5,90.0,112.5],hero,graphite)
        _flush_service_panel(body,"A01_V2_SensorIdentificationPlate",
            [-1.075,-0.940,-0.850],[247.5,270.0,292.5],hero,paint)
    var mast:=_antenna(body,hero,graphite)
    if hull.mesh==null or dorsal.mesh==null or mast.mesh==null:
        return false
    for name in obsolete:
        if not _retire(body,str(name)):
            return false
    root.set_meta("tarvoka_a01_v26_material_coherence",true)
    root.set_meta("tarvoka_a01_v23_service_finish",true)
    root.set_meta("tarvoka_a01_v19_integrated_composite_pigment",true)
    root.set_meta("tarvoka_a01_unified_nose_shell",true)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v11_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v11_visual_only",true)
    return has_model(root)
