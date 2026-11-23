extends RefCounted
class_name TarvokaA01ReconPusherV14

# Native 3D A01 V14: three genuinely tapered, pitched, closed propeller blades.
# Purely cosmetic, unarmed; the EXISTING V1/V3 spinning pivots animate them.
const FLAG:String="tarvoka_a01_v14_sealed_three_blade_pusher"
const BLADE_PREFIX:String="A01_V14_TaperedPusherBlade_"
const COWL:String="A01_V14_SealedStationaryMotorCowling"
const SPINNER:String="A01_V14_SolidRotatingMotorSpinner"

const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const V13=preload("res://scripts/ui/A01ReconTailOpticsV13.gd")
const V4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")

# distance from shaft, half chord, half thickness, twisting pitch degrees.
# The tip is physically rounded by reduced chord, NOT left open.
# V14.1: flight-propeller proportions refined from actual rear/side
# Godot screenshots; old V14 blade silhouettes read as wide paddles.
# Maintain 0.515 m span / 3 blades / 44 or 92 sealed faces per blade.
const STATIONS=[
    [0.060,0.038,0.025,-14.0],
    [0.130,0.060,0.020,-10.0],
    [0.245,0.078,0.015,-3.0],
    [0.365,0.071,0.012,6.0],
    [0.470,0.036,0.009,14.0],
    [0.515,0.009,0.005,18.0]
]

static func _mat(color:Color,metallic:float,roughness:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metallic
    m.roughness=roughness
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _blade_section(station:Array,edges:int)->Array:
    # Six/eight-point elliptical chord in the local XZ plane; the blade
    # extends along local +Y before its original 120-degree pivot rotation.
    var r:float=float(station[0])
    var half_chord:float=float(station[1])
    var half_thick:float=float(station[2])
    var pitch:float=deg_to_rad(float(station[3]))
    var points:Array=[]
    for i in range(edges):
        var a:float=TAU*float(i)/float(edges)
        var xx:float=half_chord*cos(a)
        var zz:float=half_thick*sin(a)
        var x:float=xx*cos(pitch)+zz*sin(pitch)
        var z:float=-xx*sin(pitch)+zz*cos(pitch)
        # Curved but solid aerodynamic blade: modest swept-back tip.
        x+=0.018*sin(PI*clampf(r/0.515,0.0,1.0))
        points.append(Vector3(x,r,z+0.012))
    return points

static func _blade(pivot:Node3D,name:String,hero:bool,
        surface:Material)->MeshInstance3D:
    var spans:Array=[STATIONS[0],STATIONS[2],STATIONS[4],STATIONS[5]]
    if hero:
        spans=STATIONS
    var edges:int=8 if hero else 6
    var rings:Array=[]
    for st in spans:
        rings.append(_blade_section(st,edges))
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for span_idx in range(rings.size()-1):
        var inner:Array=rings[span_idx]
        var outer:Array=rings[span_idx+1]
        for e in range(edges):
            var k:int=(e+1)%edges
            var middle:Vector3=(inner[e]+inner[k])*0.5
            var outward:Vector3=Vector3(middle.x,0,middle.z-0.012)
            V4._triangle(tool,inner[e],outer[e],outer[k],outward)
            V4._triangle(tool,inner[e],outer[k],inner[k],outward)
    # End caps are triangulated true solids; no alpha-backed fake planes.
    var root_section:Array=rings[0]
    var tip_section:Array=rings[rings.size()-1]
    for e in range(1,edges-1):
        V4._triangle(tool,root_section[0],root_section[e],
            root_section[e+1],Vector3.DOWN)
        V4._triangle(tool,tip_section[0],tip_section[e],
            tip_section[e+1],Vector3.UP)
    tool.index()
    tool.generate_normals()
    var node:=MeshInstance3D.new()
    node.name=name
    node.mesh=tool.commit()
    node.material_override=surface
    pivot.add_child(node)
    return node

static func _cowling(body:Node3D,hero:bool,
        surface:Material)->MeshInstance3D:
    # Static engine pod meets V11 fuselage aft at z=1.17, while the blades
    # continue to spin on the independent V1 propeller node.
    var mesh:=SphereMesh.new()
    mesh.radius=0.5
    mesh.height=1.0
    mesh.radial_segments=14 if hero else 8
    mesh.rings=8 if hero else 4
    var node:=MeshInstance3D.new()
    node.name=COWL
    node.mesh=mesh
    node.position=Vector3(0,0.95,1.110)
    node.scale=Vector3(0.265,0.265,0.290)
    node.material_override=surface
    body.add_child(node)
    return node

static func _spinner(prop:Node3D,hero:bool,
        surface:Material)->MeshInstance3D:
    # Axis follows aircraft longitudinal Z, unlike old sideways cylinder.
    var mesh:=CylinderMesh.new()
    mesh.top_radius=0.013
    mesh.bottom_radius=0.112
    mesh.height=0.200
    mesh.radial_segments=16 if hero else 10
    var node:=MeshInstance3D.new()
    node.name=SPINNER
    node.mesh=mesh
    node.position=Vector3(0,0,0.126)
    node.rotation_degrees.x=90.0
    node.material_override=surface
    prop.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    if root==null or not V13.has_model(root) or not bool(root.get_meta(FLAG,false)):
        return false
    var prop:=root.find_child(V1.PROPELLER,true,false) as Node3D
    return prop!=null and (root.find_child(COWL,true,false) is MeshInstance3D) and (
        prop.find_child(SPINNER,false,false) is MeshInstance3D) and (
        prop.find_child(BLADE_PREFIX+"0",true,false) is MeshInstance3D) and (
        prop.find_child(BLADE_PREFIX+"1",true,false) is MeshInstance3D) and (
        prop.find_child(BLADE_PREFIX+"2",true,false) is MeshInstance3D)

static func apply(root:Node3D,hero:bool)->bool:
    if root==null or not V13.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    var prop:=root.find_child(V1.PROPELLER,true,false) as Node3D
    if body==null or prop==null:
        return false
    var retired:Array[MeshInstance3D]=[]
    for name in ["A01_V1_ClosedMotorHub",
            "A01_V3_MotorBackplate","A01_V3_PropellerSpinner"]:
        var old:=prop.find_child(name,false,false) as MeshInstance3D
        if old==null:
            return false
        retired.append(old)
    for index in range(3):
        var pivot:=prop.find_child("A01_V3_PusherBladePivot_"+str(index),
            false,false) as Node3D
        if pivot==null:
            return false
        var original:=pivot.find_child(V3.BLADE_PREFIX+str(index),
            false,false) as MeshInstance3D
        if original==null:
            return false
        retired.append(original)
        var old_steel:=pivot.find_child("A01_V3_BladeSteelRoot_"+str(index),
            false,false) as MeshInstance3D
        if old_steel!=null:
            retired.append(old_steel)
    var blades_mat:=_mat(Color("#2d3944"),0.25,0.57)
    var body_mat:=_mat(Color("#a5b6be"),0.42,0.44)
    var spinner_mat:=_mat(Color("#617580"),0.57,0.40)
    if _cowling(body,hero,body_mat).mesh==null:
        return false
    if _spinner(prop,hero,spinner_mat).mesh==null:
        return false
    for index in range(3):
        var pivot:=prop.find_child("A01_V3_PusherBladePivot_"+str(index),
            false,false) as Node3D
        if _blade(pivot,BLADE_PREFIX+str(index),hero,blades_mat).mesh==null:
            return false
    # Hide historical primitives ONLY after all new real geometry exists.
    for original in retired:
        original.visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v14_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v14_1_slim_pitched_prop",true)
    root.set_meta("tarvoka_a01_v14_unarmed_visual_only",true)
    return has_model(root)
