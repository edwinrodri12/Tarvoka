extends RefCounted
class_name TarvokaA01ReconWingRootV12

# A01 V12 — sealed load-bearing aerofoil shoulder, not a floating ellipsoid.
# Additive physical visual geometry ONLY on the unarmed V11 recon aircraft.
# Both sides share the same real coordinates as the V4 swept wing roots.
const FLAG:String="tarvoka_a01_v12_watertight_wing_shoulder"
const ROOT_L:String="A01_V12_ClosedWingShoulder_L"
const ROOT_R:String="A01_V12_ClosedWingShoulder_R"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const V11=preload("res://scripts/ui/A01ReconAirframeV11.gd")

# X distance to centre, vertical centre, front/rear chord bounds,
# upper and lower thickness. Same physical outer silhouette for LOD8/13.
const STATIONS=[
    [0.205,1.055,-0.355,0.265,0.125,0.088],
    [0.310,1.049,-0.355,0.273,0.133,0.080],
    [0.460,1.046,-0.346,0.249,0.106,0.071],
    [0.680,1.047,-0.327,0.222,0.074,0.058]
]

static func _material()->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color("#bbc9cf")
    m.metallic=0.29
    m.roughness=0.47
    m.transparency=BaseMaterial3D.TRANSPARENCY_DISABLED
    m.cull_mode=BaseMaterial3D.CULL_BACK
    return m

static func _ring(side:float,station:Array)->Array:
    # The six vertices describe a genuinely 3D, sealed aerodynamic section.
    # Upper shoulder encloses the V4 foil root; underside bridges into body.
    var x:float=side*float(station[0])
    var y:float=float(station[1])
    var z0:float=float(station[2])
    var z1:float=float(station[3])
    var top:float=float(station[4])
    var bottom:float=float(station[5])
    var chord:float=z1-z0
    return [
        Vector3(x,y,z0),
        Vector3(x,y+top*0.82,z0+chord*0.18),
        Vector3(x,y+top*0.60,z1-chord*0.15),
        Vector3(x,y,z1),
        Vector3(x,y-bottom*0.64,z1-chord*0.18),
        Vector3(x,y-bottom*0.82,z0+chord*0.18)
    ]

static func _loft(body:Node3D,tag:String,side:float,hero:bool,
        paint:Material)->MeshInstance3D:
    var ring_stations:Array=[STATIONS[0],STATIONS[1]]
    if hero:
        ring_stations.append(STATIONS[2])
    ring_stations.append(STATIONS[3])
    var cross_sections:Array=[]
    for station in ring_stations:
        cross_sections.append(_ring(side,station))
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(cross_sections.size()-1):
        var inner:Array=cross_sections[j]
        var outer:Array=cross_sections[j+1]
        for i in range(6):
            var next:int=(i+1)%6
            var z_middle:float=0.5*(float(ring_stations[j][2])+
                float(ring_stations[j][3]))
            var centre:Vector3=Vector3(side*float(ring_stations[j][0]),
                float(ring_stations[j][1]),z_middle)
            var normal:Vector3=(inner[i]+inner[next])*0.5-centre
            normal.x=0.0
            V4._triangle(t,inner[i],outer[i],outer[next],normal)
            V4._triangle(t,inner[i],outer[next],inner[next],normal)
    # True solid end caps; no double-sided planes or alpha tricks.
    var root_cap:Array=cross_sections[0]
    var tip_cap:Array=cross_sections[cross_sections.size()-1]
    for i in range(1,5):
        V4._triangle(t,root_cap[0],root_cap[i],root_cap[i+1],
            Vector3(-side,0,0))
        V4._triangle(t,tip_cap[0],tip_cap[i],tip_cap[i+1],
            Vector3(side,0,0))
    t.generate_normals()
    var node:=MeshInstance3D.new()
    node.name=tag
    node.mesh=t.commit()
    node.material_override=paint
    body.add_child(node)
    return node

static func has_model(root:Node3D)->bool:
    return root!=null and V11.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        root.find_child(ROOT_L,true,false) is MeshInstance3D) and (
        root.find_child(ROOT_R,true,false) is MeshInstance3D)

static func apply(root:Node3D,hero:bool)->bool:
    if root==null or not V11.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    var legacy:Array=[]
    for side in [-1,1]:
        var tag:String="_L" if side<0 else "_R"
        var old_root:=body.find_child("A01_V4_SmoothCompositeWingRoot"+tag,
            false,false) as MeshInstance3D
        if old_root==null:
            return false
        legacy.append(old_root)
        # Hero inherited protruding black rectangular spar/fasteners.
        # Hide after the new physical fillet is successfully built.
        if hero:
            for name in ["A01_V1_WingSparJoint_"+str(side),
                    "A01_V2_WingRootFastener_"+(
                    "Port" if side<0 else "Starboard")]:
                var original:=body.find_child(name,false,false) as MeshInstance3D
                if original!=null:
                    legacy.append(original)
    var material:=_material()
    for side in [-1,1]:
        var wing:=_loft(body,ROOT_L if side<0 else ROOT_R,
            float(side),hero,material)
        if wing.mesh==null or not (wing.mesh is ArrayMesh):
            return false
    for old in legacy:
        (old as MeshInstance3D).visible=false
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v12_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v12_visual_only",true)
    return has_model(root)
