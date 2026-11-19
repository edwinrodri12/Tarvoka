extends RefCounted
class_name TarvokaG15ChassisAndMastFinishV2

# G15 V2 — physical original 6x6 fender contours and braced mast base.
# Replaces the visible six V1 rectangular fender caps with a single native
# ArrayMesh (both sides) instanced on three axles, protecting the original
# rolling pivot and its twelve physical tread bars.
# Two CLOSED triangular steel gussets physically bridge the shielded roof
# with the existing mast pedestal; no reparenting or new animation pivots.
# The exact V1 nodes and materials remain available for Studio comparison.
# Three? New draws: one arch MultiMesh + one gusset MeshInstance = TWO.
# ART ONLY: no fictional jamming combat, no balance/range/weapon changes.
const V1=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const FLAG="tarvoka_g15_v2_sculpted_6x6_arches_and_mast_gussets"
const FENDERS="G15_V2_SixClosedCurvedFenderArches"
const BRACES="G15_V2_ShieldedMastMountGussets"
const VISIBILITY="tarvoka_g15_v2_v1_fender_visibility"
const AXLES=[-1.27,-0.01,1.25]
const WHEEL_Y=0.355
const ARCH_INSIDE_R=0.401
const ARCH_OUTSIDE_R=0.450
const TIRE_CLEARANCE=0.016
const ADDED_DRAW_NODES=2
const REPLACED_FENDERS=6
const GUSSET_SOLIDS=2

static func _coat(color:String,metal:float,rough:float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color)
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _triangle(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _quad(st:SurfaceTool,
        a:Vector3,b:Vector3,c:Vector3,d:Vector3)->void:
    _triangle(st,a,b,c)
    _triangle(st,a,c,d)

static func _profile(side:int,angle:float)->Array[Vector3]:
    var s:float=float(side)
    var sn:float=sin(angle)
    var cs:float=cos(angle)
    var yin:float=WHEEL_Y+ARCH_INSIDE_R*sn
    var zin:float=ARCH_INSIDE_R*cs
    var yout:float=WHEEL_Y+ARCH_OUTSIDE_R*sn
    var zout:float=ARCH_OUTSIDE_R*cs
    # Inner lip seats against old armored body at x=.790, while outboard
    # steel shade covers top tire tread but never cuts into radial tire.
    # Full 3D closed four-edge cross-section, not a flat ribbon or decal.
    return [
        Vector3(s*0.787,yin,zin),
        Vector3(s*1.076,yin,zin),
        Vector3(s*1.076,yout,zout),
        Vector3(s*0.787,yout,zout)
    ]

static func _arch_mesh(segments:int)->ArrayMesh:
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1,1]:
        for n in range(segments):
            var a:float=lerpf(0.10,PI-0.10,float(n)/float(segments))
            var b:float=lerpf(0.10,PI-0.10,float(n+1)/float(segments))
            var first:Array[Vector3]=_profile(side,a)
            var last:Array[Vector3]=_profile(side,b)
            for edge in range(4):
                var next:int=(edge+1)%4
                _quad(st,first[edge],first[next],
                    last[next],last[edge])
            if n==0:
                _quad(st,first[0],first[3],first[2],first[1])
            if n==segments-1:
                _quad(st,last[0],last[1],last[2],last[3])
    return st.commit() as ArrayMesh

static func _mast_brace()->ArrayMesh:
    # Two physical triangular gussets, welded between roof at Y~2.18
    # and mast pedestal at X~.16, Y~2.32 (V1 original rig).
    # Each is solid with 10 outward-facing triangle sides and a beveled
    # leading shoulder, not a free-floating faux receiver.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for side in [-1,1]:
        var s:float=float(side)
        var front:Array[Vector3]=[
            Vector3(s*0.143,2.22,0.354),
            Vector3(s*0.355,2.185,0.354),
            Vector3(s*0.355,2.225,0.354),
            Vector3(s*0.178,2.404,0.354)
        ]
        var back:Array[Vector3]=[]
        for p in front:
            back.append(Vector3(p.x,p.y,0.490))
        for i in range(1,3):
            _triangle(st,front[0],front[i],front[i+1])
            _triangle(st,back[0],back[i+1],back[i])
        for i in range(4):
            var j:int=(i+1)%4
            _quad(st,front[i],back[i],back[j],front[j])
    return st.commit() as ArrayMesh

static func _old_fenders(root:Node3D,chassis:Node3D)->Array[MeshInstance3D]:
    var found:Array[MeshInstance3D]=[]
    for side in [-1,1]:
        for axle in range(3):
            var fender:=root.find_child(
                "G15_Fender_%s_%d" % [side,axle],true,false
            ) as MeshInstance3D
            if fender==null or fender.get_parent()!=chassis or (
                    not fender.mesh is BoxMesh):
                return []
            found.append(fender)
    return found

static func _add_batched_arch(chassis:Node3D,
        mesh:ArrayMesh,finish:Material)->MultiMeshInstance3D:
    var batch:=MultiMesh.new()
    batch.transform_format=MultiMesh.TRANSFORM_3D
    batch.mesh=mesh
    batch.instance_count=3
    for i in range(3):
        batch.set_instance_transform(i,Transform3D(
            Basis.IDENTITY,Vector3(0,0,float(AXLES[i]))))
    var result:=MultiMeshInstance3D.new()
    result.name=FENDERS
    result.multimesh=batch
    result.material_override=finish
    chassis.add_child(result)
    return result

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(V1.FLAG,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    var mast:=root.find_child(V1.MAST,true,false) as Node3D
    var wheels:=root.find_child(V1.WHEEL_GROUP,true,false) as Node3D
    var roof:=root.find_child("G15_ShieldedRoof",true,false
        ) as MeshInstance3D
    if chassis==null or mast==null or wheels==null or roof==null or (
            mast.get_parent()!=chassis or wheels.get_parent()!=chassis or
            roof.get_parent()!=chassis or wheels.get_child_count()!=6):
        return false
    var old:Array[MeshInstance3D]=_old_fenders(root,chassis)
    if old.size()!=REPLACED_FENDERS or (
            root.find_child(FENDERS,true,false)!=null or
            root.find_child(BRACES,true,false)!=null):
        return false
    var hero:bool=bool(root.get_meta("tarvoka_g15_hero",false))
    var segments:int=18 if hero else 10
    var arch:ArrayMesh=_arch_mesh(segments)
    var brackets:ArrayMesh=_mast_brace()
    # 8 triangles per station, both sides, plus four cap triangles/side.
    if arch==null or brackets==null or (
            arch.get_faces().size()!=(2*(segments*8+4))*3 or
            brackets.get_faces().size()!=24*3):
        return false
    if ARCH_INSIDE_R-0.385<TIRE_CLEARANCE-0.001 or (
            not mast.position.is_equal_approx(Vector3(0,2.22,0.44))):
        return false
    var prior:Dictionary={}
    for old_fender in old:
        prior[old_fender.name]=old_fender.visible
    _add_batched_arch(chassis,arch,_coat("#4f6168",0.43,0.69))
    var braces:=MeshInstance3D.new()
    braces.name=BRACES
    braces.mesh=brackets
    braces.material_override=_coat("#66767a",0.50,0.62)
    chassis.add_child(braces)
    for old_fender in old:
        old_fender.visible=false
    root.set_meta(VISIBILITY,prior)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_v2_real_3d_curved_steel_arches",6)
    root.set_meta("tarvoka_g15_v2_steel_mast_gussets",2)
    root.set_meta("tarvoka_g15_v2_added_draw_nodes",ADDED_DRAW_NODES)
    root.set_meta("tarvoka_g15_v2_existing_wheel_pivots_preserved",6)
    root.set_meta("tarvoka_g15_v2_no_gameplay_changes",true)
    root.set_meta("tarvoka_g15_v2_wheel_tread_gap_m",
        ARCH_INSIDE_R-0.385)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var chassis:=root.find_child(V1.CHASSIS,true,false) as Node3D
    if chassis==null:
        return false
    var old:Array[MeshInstance3D]=_old_fenders(root,chassis)
    var arch:=root.find_child(FENDERS,true,false) as MultiMeshInstance3D
    var gussets:=root.find_child(BRACES,true,false) as MeshInstance3D
    if old.size()!=REPLACED_FENDERS or arch==null or gussets==null:
        return false
    var prior:Dictionary=root.get_meta(VISIBILITY,{})
    for fender in old:
        fender.visible=false if enabled else bool(
            prior.get(fender.name,false))
    arch.visible=enabled
    gussets.visible=enabled
    root.set_meta("tarvoka_g15_v2_preview_enabled",enabled)
    return true
