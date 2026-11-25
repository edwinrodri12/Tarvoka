extends RefCounted
class_name TarvokaA01ReconTailV5

# V5: genuine sculpted twin booms and ascending V-tail airfoils.
# Visual-only 3D refinements on the SAME unarmed A01 reconnaissance UAV.
# No combat weapons, gameplay movement, fog, costs or tactical stats.
const FLAG:String="tarvoka_a01_v5_tapered_v_tail_and_booms"
const V1=preload("res://scripts/ui/A01ReconDroneV1.gd")
const V3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const V4=preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const TAIL_L:String="A01_V5_SealedVtail_Left"
const TAIL_R:String="A01_V5_SealedVtail_Right"
const BOOM_L:String="A01_V5_SmoothTailBoom_Left"
const BOOM_R:String="A01_V5_SmoothTailBoom_Right"

static func _finish(color:Color,metal:float,rough:float)->StandardMaterial3D:
    var material:=StandardMaterial3D.new()
    material.albedo_color=color
    material.metallic=metal
    material.roughness=rough
    material.cull_mode=BaseMaterial3D.CULL_BACK
    return material

# The previous ellipsoid ended below the tail hinge, leaving a gap.
# These closed composite booms rise from inside the wing spar to inside
# the tailplane and follow the physical axis of the two support arms.
static func _boom(body:Node3D,tag:String,side:float,hero:bool,
        mat:Material)->MeshInstance3D:
    var stations:Array=[
        [-0.22,1.043,0.055,0.034],
        [0.04,1.037,0.078,0.064],
        [0.37,1.002,0.077,0.070],
        [0.91,0.997,0.065,0.064],
        [1.33,1.026,0.052,0.052],
        [1.47,1.055,0.039,0.033]
    ]
    var sides:int=12 if hero else 8
    var rings:Array=[]
    for station in stations:
        var ring:Array[Vector3]=[]
        for i in range(sides):
            var angle:float=TAU*float(i)/float(sides)
            ring.append(Vector3(side*0.46+cos(angle)*float(station[2]),
                float(station[1])+sin(angle)*float(station[3]),float(station[0])))
        rings.append(ring)
    var t:=SurfaceTool.new()
    t.begin(Mesh.PRIMITIVE_TRIANGLES)
    for j in range(rings.size()-1):
        var front:Array=rings[j]
        var back:Array=rings[j+1]
        for i in range(sides):
            var k:int=(i+1)%sides
            var angle:float=TAU*(float(i)+0.5)/float(sides)
            var radial:=Vector3(cos(angle),sin(angle),0.0)
            V4._triangle(t,front[i],front[k],back[k],radial)
            V4._triangle(t,front[i],back[k],back[i],radial)
    var start:Array=rings[0]
    var finish:Array=rings[rings.size()-1]
    for i in range(1,sides-1):
        V4._triangle(t,start[0],start[i],start[i+1],Vector3.FORWARD)
        V4._triangle(t,finish[0],finish[i],finish[i+1],Vector3.BACK)
    t.index()
    t.generate_normals()
    var boom:=MeshInstance3D.new()
    boom.name=tag
    boom.mesh=t.commit()
    boom.material_override=mat
    body.add_child(boom)
    return boom

static func _exists(root:Node3D,name:String)->bool:
    return root.find_child(name,true,false) is MeshInstance3D

static func has_model(root:Node3D)->bool:
    return root!=null and V4.has_model(root) and bool(root.get_meta(FLAG,false)) and (
        _exists(root,TAIL_L) and _exists(root,TAIL_R) and
        _exists(root,BOOM_L) and _exists(root,BOOM_R))

static func apply(root:Node3D,paint:Color,hero:bool)->bool:
    if root==null or not V4.has_model(root) or bool(root.get_meta(FLAG,false)):
        return false
    var body:=root.find_child(V1.BODY,true,false) as Node3D
    if body==null:
        return false
    var shell:=_finish(Color("#8899a5"),0.12,0.72)
    var alloy:=_finish(Color("#8799a1"),0.49,0.45)
    var faction:=_finish(paint,0.24,0.41)
    var hinges:=_finish(Color("#3c4b54"),0.37,0.66)
    # The old flat rectangular tailplanes and straight box booms remain
    # as hidden legacy comparison sources, never as doubles in the render.
    for side in [-1,1]:
        var s:float=float(side)
        var tag:String="_L" if side<0 else "_R"
        var boom_name:String=BOOM_L if side<0 else BOOM_R
        var tail_name:String=TAIL_L if side<0 else TAIL_R
        var old_boom:=body.find_child(
            "A01_V1_ClosedTailBoom_"+str(side),false,false) as MeshInstance3D
        if old_boom!=null:
            old_boom.visible=false
        var old_tail:=body.find_child(
            "A01_V1_DihedralTail_"+str(side),false,false) as MeshInstance3D
        if old_tail!=null:
            old_tail.visible=false
        var old_trim:=body.find_child(
            V3.TAIL_TRIM+tag,false,false) as MeshInstance3D
        if old_trim!=null:
            old_trim.visible=false
        # Elliptical enclosed composite boom, with a long sealed fuselage
        # connection and an aerodynamic fairing to the twin stabilizer.
        var smooth:=_boom(body,boom_name,s,hero,alloy)
        # Preserve old nodes for historical tests, but remove floating
        # cable channels and square servo blocks from the rendered shell.
        var side_tag:String="Port" if side<0 else "Starboard"
        for old_name in ["A01_V2_TailServoBridge_"+side_tag,
                "A01_V2_CableChannel_"+side_tag]:
            var obsolete:=body.find_child(old_name,false,false) as MeshInstance3D
            if obsolete!=null:
                obsolete.visible=false
        if smooth==null:
            return false
        var stations:Array=[
            [0.30,1.045,1.327,1.674,0.084]
        ]
        if hero:
            stations.append([0.66,1.110,1.365,1.650,0.064])
        stations.append([1.000,1.185,1.422,1.570,0.033])
        # Ascending V-shaped, six-sided watertight airfoil with closed
        # root/tip caps, unlike an invisible plane or thin box.
        var vtail:=V4._airfoil(body,tail_name,stations,s,shell)
        if vtail==null or not (vtail.mesh is ArrayMesh):
            return false
        # Distinct physical faction color stays readable from above.
        V4._flap(body,"A01_V5_VtailFactionPanel"+tag,
            Vector3(s*0.765,1.166,1.515),
            Vector3(0.225,0.023,0.105),faction)
        # Sturdy hinge bridge between stabilizer and composite boom.
        V4._flap(body,"A01_V5_ClosedTailHinge"+tag,
            Vector3(s*0.465,1.055,1.462),
            Vector3(0.14,0.075,0.160),hinges)
        if hero:
            V4._flap(body,"A01_V5_TrailingServoTab"+tag,
                Vector3(s*0.805,1.158,1.583),
                Vector3(0.180,0.024,0.044),alloy)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_a01_v5_lod",13 if hero else 8)
    root.set_meta("tarvoka_a01_v5_3d_visual_only",true)
    return has_model(root)
