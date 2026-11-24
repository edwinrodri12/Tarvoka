extends RefCounted
class_name TarvokaA01ReconWingletV9

# V9: a conformal, truly solid enamel skin and blended wingtip joint.
# Adds finish to V8 without altering UAV mechanics or older visual stages.
const FLAG:String="tarvoka_a01_v9_conformal_enamel_fillet"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V8=preload("res://scripts/ui/A01ReconWingletV8.gd")
const PANEL_L:String="A01_V9_ConformalFactionWinglet_L"
const PANEL_R:String="A01_V9_ConformalFactionWinglet_R"
const ROOT_L:String="A01_V9_WingtipRootFairing_L"
const ROOT_R:String="A01_V9_WingtipRootFairing_R"

static func _material(color:Color, metallic_value:float, rough:float)->StandardMaterial3D:
    var result:=StandardMaterial3D.new()
    result.albedo_color=color
    result.metallic=metallic_value
    result.roughness=rough
    result.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    result.cull_mode=BaseMaterial3D.CULL_BACK
    return result

static func _triangle(tool:SurfaceTool, a:Vector3, b:Vector3, c:Vector3,
        outward:Vector3)->void:
    tool.add_vertex(a)
    if (b-a).cross(c-a).dot(outward)>0.0:
        tool.add_vertex(c)
        tool.add_vertex(b)
    else:
        tool.add_vertex(b)
        tool.add_vertex(c)

static func _ring(side:float, station:Array)->Array[Vector3]:
    # Use the SAME actual V8 outer aerodynamic profile vertices. The paint
    # is never a rotated box hovering beside the tapered fin.
    var section:Array[Vector3]=V8._profile(side,station)
    # V8's vertices 1/2 belong to the +X skin regardless of side.
    # On the LEFT (-X) wingtip the visible outer face is vertices 5/4.
    # A symmetric choice of 1/2 hid the left team color inside the fin.
    var front:int=1 if side>0.0 else 5
    var back:int=2 if side>0.0 else 4
    var inside:=Vector3(side*0.003,0,0)
    var outside:=Vector3(side*0.008,0,0)
    return [
        section[front]+outside,
        section[back]+outside,
        section[back]+inside,
        section[front]+inside
    ]

static func _skin(body:Node3D, name:String, side:float, hero:bool,
        enamel:Material)->MeshInstance3D:
    # One sealed, slender quadrilateral skin on each OUTER face.
    # Hero follows the extra V8 profile station; LOD8 remains inexpensive.
    var stations:Array=[
        [1.703,1.183,-0.237,0.149,0.038]
    ]
    if hero:
        stations.append([1.735,1.289,-0.173,0.093,0.026])
    stations.append([1.757,1.395,-0.092,0.019,0.014])
    var profiles:Array=[]
    for station in stations:
        profiles.append(_ring(side,station))
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(profiles.size()-1):
        var lo:Array=profiles[i]
        var hi:Array=profiles[i+1]
        var center:Vector3=Vector3.ZERO
        for p in lo:
            center+=p
        center/=float(lo.size())
        for edge in range(4):
            var nxt:int=(edge+1)%4
            var outward:Vector3=0.5*(lo[edge]+lo[nxt])-center
            outward.y=0.0
            _triangle(tool,lo[edge],hi[edge],hi[nxt],outward)
            _triangle(tool,lo[edge],hi[nxt],lo[nxt],outward)
    var start:Array=profiles[0]
    var top:Array=profiles[profiles.size()-1]
    _triangle(tool,start[0],start[1],start[2],Vector3.DOWN)
    _triangle(tool,start[0],start[2],start[3],Vector3.DOWN)
    _triangle(tool,top[0],top[1],top[2],Vector3.UP)
    _triangle(tool,top[0],top[2],top[3],Vector3.UP)
    tool.generate_normals()
    var panel:=MeshInstance3D.new()
    panel.name=name
    panel.mesh=tool.commit()
    panel.material_override=enamel
    body.add_child(panel)
    return panel

static func _fairing(body:Node3D, name:String, side:float,
        hero:bool, composite:Material)->MeshInstance3D:
    # Rounded aerodynamic attachment visibly overlaps the closed wing tip
    # and the base of the vertical fin, instead of appearing suspended.
    var fairing:=MeshInstance3D.new()
    fairing.name=name
    var surface:=SphereMesh.new()
    surface.radius=0.5
    surface.height=1.0
    surface.radial_segments=12 if hero else 8
    surface.rings=6 if hero else 4
    fairing.mesh=surface
    fairing.material_override=composite
    # V9.1 QA: the earlier 0.20-wide ball protruded like a round plug
    # beyond the wingtips in real top-view Godot captures. Tuck a slim
    # elliptical solid entirely against the wing/fin joint.
    fairing.position=Vector3(side*1.676,1.077,-0.037)
    fairing.scale=Vector3(0.110,0.072,0.226)
    body.add_child(fairing)
    return fairing

static func has_model(root:Node3D)->bool:
    return root!=null and V8.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(PANEL_L,true,false) is MeshInstance3D) and (
        root.find_child(PANEL_R,true,false) is MeshInstance3D) and (
        root.find_child(ROOT_L,true,false) is MeshInstance3D) and (
        root.find_child(ROOT_R,true,false) is MeshInstance3D)

static func apply(root:Node3D, faction:Color, hero:bool)->bool:
    if root==null or not V8.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    # Keep the approved V8 geometry and its old mesh in the tree. Only
    # replace the VISUAL box-like enamel with a close-fitting 3D skin.
    for side in [-1,1]:
        var s:float=float(side)
        var old_name:String=V8.PAINT_L if side<0 else V8.PAINT_R
        var old:=body.find_child(old_name,false,false) as MeshInstance3D
        if old==null:
            return false
        var skin:=_skin(body,PANEL_L if side<0 else PANEL_R,
            s,hero,_material(faction,0.25,0.42))
        var fairing:=_fairing(body,ROOT_L if side<0 else ROOT_R,
            s,hero,_material(Color("#b7c6cd"),0.32,0.46))
        if skin.mesh==null or fairing.mesh==null:
            return false
        old.visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v9_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v9_visual_only",true)
    return has_model(root)
