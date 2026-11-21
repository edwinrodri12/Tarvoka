extends RefCounted
class_name TarvokaA01ReconWingletV8

# V8: actual tapered, swept, watertight vertical wingtip fins.
# Art ONLY. Preserve all eight official faction colors, V1-V7 geometry,
# recon UAV movement, no-weapons rule, and original shared Studio.
const FLAG:String="tarvoka_a01_v8_sealed_swept_winglets"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const V6=preload("res://scripts/ui/A01ReconDamageV6.gd")
const FIN_L:String="A01_V8_SealedSweptWinglet_L"
const FIN_R:String="A01_V8_SealedSweptWinglet_R"
const PAINT_L:String="A01_V8_WingletFactionEnamel_L"
const PAINT_R:String="A01_V8_WingletFactionEnamel_R"

static func _mat(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _profile(side:float,s:Array)->Array[Vector3]:
    # Ring of six real vertices in a horizontal cross section. Z is the
    # aerodynamic chord, X the fin thickness, Y the vertical ascent.
    var cx:float=side*float(s[0])
    var y:float=float(s[1])
    var leading:float=float(s[2])
    var trailing:float=float(s[3])
    var half_thickness:float=float(s[4])
    var chord:float=trailing-leading
    return [
        Vector3(cx,y,leading),
        Vector3(cx+half_thickness,y,leading+chord*0.24),
        Vector3(cx+half_thickness*0.83,y,trailing-chord*0.19),
        Vector3(cx,y,trailing),
        Vector3(cx-half_thickness*0.83,y,trailing-chord*0.19),
        Vector3(cx-half_thickness,y,leading+chord*0.24)
    ]

static func _face(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        outward:Vector3)->void:
    tool.add_vertex(a)
    if (b-a).cross(c-a).dot(outward)<0.0:
        tool.add_vertex(c)
        tool.add_vertex(b)
    else:
        tool.add_vertex(b)
        tool.add_vertex(c)

static func _fin(parent:Node3D,label:String,side:float,hero:bool,
        surface:Material)->MeshInstance3D:
    # Same exterior height/span in both LODs. Hero adds an intermediate
    # sculpted station; Android LOD8 saves triangles and materials.
    var stations:Array=[
        [1.678,1.080,-0.265,0.179,0.044],
        [1.703,1.183,-0.237,0.149,0.038]
    ]
    if hero:
        stations.append([1.735,1.289,-0.173,0.093,0.026])
    stations.append([1.757,1.395,-0.092,0.019,0.014])
    var profiles:Array=[]
    for st in stations:
        profiles.append(_profile(side,st))
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for segment in range(profiles.size()-1):
        var low:Array=profiles[segment]
        var high:Array=profiles[segment+1]
        for edge in range(6):
            var nxt:int=(edge+1)%6
            var side_center:Vector3=Vector3(side*float(stations[segment][0]),
                float(stations[segment][1]),0.5*(float(stations[segment][2])+
                float(stations[segment][3])))
            var outward:Vector3=(low[edge]+low[nxt])*0.5-side_center
            outward.y=0.0
            _face(t,low[edge],high[edge],high[nxt],outward)
            _face(t,low[edge],high[nxt],low[nxt],outward)
    # Cap both ends: there are no open backfaces when inspected at 360°.
    for e in range(1,5):
        _face(t,profiles[0][0],profiles[0][e],profiles[0][e+1],Vector3.DOWN)
        var top:int=profiles.size()-1
        _face(t,profiles[top][0],profiles[top][e],
            profiles[top][e+1],Vector3.UP)
    t.generate_normals()
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=t.commit()
    node.material_override=surface
    parent.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    return root!=null and V6.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(FIN_L,true,false) is MeshInstance3D) and (
        root.find_child(FIN_R,true,false) is MeshInstance3D) and (
        root.find_child(PAINT_L,true,false) is MeshInstance3D) and (
        root.find_child(PAINT_R,true,false) is MeshInstance3D)

static func apply(root:Node3D,team_color:Color,hero:bool)->bool:
    if root==null or not V6.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    var shell:=_mat(Color("#c6d1d4"),0.32,0.43)
    var enamel:=_mat(team_color,0.25,0.42)
    for side in [-1,1]:
        var s:float=float(side)
        var suffix:String="_L" if side<0 else "_R"
        var old:=body.find_child(V3.WINGLET+suffix,false,false) as MeshInstance3D
        if old==null:
            return false
        var wingtip:=_fin(body,FIN_L if side<0 else FIN_R,s,hero,shell)
        if wingtip==null or not (wingtip.mesh is ArrayMesh):
            return false
        # Small opaque enamel stripe, seated on the OUTER surface of the
        # tapered lower fin, where it can be read from a tactical angle.
        var paint:=MeshInstance3D.new()
        paint.name=PAINT_L if side<0 else PAINT_R
        var patch:=BoxMesh.new()
        patch.size=Vector3(0.018,0.084,0.180)
        paint.mesh=patch
        paint.position=Vector3(s*1.752,1.207,-0.022)
        paint.rotation_degrees=Vector3(0,-s*11.0,-s*9.0)
        paint.material_override=enamel
        body.add_child(paint)
        # Retire the old tall rectangular plates, not a duplicate fin.
        old.visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v8_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v8_visual_only",true)
    return has_model(root)
