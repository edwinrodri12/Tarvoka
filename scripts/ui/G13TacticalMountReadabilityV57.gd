extends RefCounted
class_name TarvokaG13TacticalMountReadabilityV57

# V57 — fender-to-chassis MECHANICAL MOUNT READABILITY at normal game zoom.
# Eight compact solid sculpted brackets follow the existing V42 curved
# wheel arches (two per wheel), not decals or separated floating details.
# Tactical LOD8 uses ONE GPU-instanced draw; hero LOD13 uses TWO, adding
# eight tiny flush rivet heads. All original V56 shocks, wheel clearance,
# eight faction paints, wheel motion, guns, azimuth and physics untouched.
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const V53=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const FLAG: String="tarvoka_g13_v57_visible_fender_mechanical_mounts"
const V42_FLAG: String="tarvoka_g13_v42_fender_tip_continuity"
const BRACKETS: String="G13_V57_EightExternalFenderMountBrackets"
const PINS: String="G13_V57_EightExternalMachinedBoltHeads"
const ARC_CENTER_Y: float=0.33
const ARC_RADIUS: float=0.428
const AXLE_Z: float=0.85
const OUTER_X: float=1.015
const BRACKET_COUNT: int=8
const HERO_DRAW_NODES: int=2
const TACTICAL_DRAW_NODES: int=1

static func _coat(color: String,metal: float,rough: float)->StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(color)
    m.metallic=metal
    m.roughness=rough
    # Mirrored two-sided brackets on the existing physical fender surfaces.
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    return m

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_normal(normal)
    st.add_vertex(c)
    st.set_normal(normal)
    st.add_vertex(b)

static func _bracket_mesh()->ArrayMesh:
    # Beveled six-sided solid, local Y = tangent of fender arc,
    # local Z = radial relief, local X = outward side thickness.
    # Inset underside at radius .402m fully intersects the existing
    # R=.427m fender while leaving the V54 tyre R=.310m unobstructed.
    var outline:Array[Vector2]=[
        Vector2(-0.094,-0.014),
        Vector2(-0.083,-0.024),
        Vector2(0.065,-0.024),
        Vector2(0.092,-0.009),
        Vector2(0.086,0.022),
        Vector2(-0.075,0.026)
    ]
    var inner:Array[Vector3]=[]
    var outer:Array[Vector3]=[]
    for p in outline:
        inner.append(Vector3(-0.015,p.x,p.y))
        outer.append(Vector3(0.015,p.x,p.y))
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(1,outline.size()-1):
        _tri(st,inner[0],inner[i+1],inner[i])
        _tri(st,outer[0],outer[i],outer[i+1])
    for i in range(outline.size()):
        var j:int=(i+1)%outline.size()
        _tri(st,inner[i],outer[i],outer[j])
        _tri(st,inner[i],outer[j],inner[j])
    return st.commit() as ArrayMesh

static func _poses()->Dictionary:
    var brackets:Array[Transform3D]=[]
    var bolts:Array[Transform3D]=[]
    for side in [-1,1]:
        for axle in [-1,1]:
            for theta in [0.62,PI-0.62]:
                var y:float=ARC_CENTER_Y+ARC_RADIUS*sin(theta)
                var z:float=float(axle)*AXLE_Z+ARC_RADIUS*cos(theta)
                # Rotation around X makes plate follow the ORIGINAL V42
                # curved arch without a visible flat floating gap.
                var orientation:=Basis(Vector3.RIGHT,-theta)
                brackets.append(Transform3D(
                    orientation,Vector3(float(side)*OUTER_X,y,z)))
                bolts.append(Transform3D(
                    Basis.IDENTITY,
                    Vector3(float(side)*1.036,y,z)))
    return {"brackets":brackets,"pins":bolts}

static func _batch(parent:Node3D,label:String,mesh:Mesh,
        material:Material,poses:Array[Transform3D])->MultiMeshInstance3D:
    var mm:=MultiMesh.new()
    mm.transform_format=MultiMesh.TRANSFORM_3D
    mm.mesh=mesh
    mm.instance_count=poses.size()
    for i in range(poses.size()):
        mm.set_instance_transform(i,poses[i])
    var result:=MultiMeshInstance3D.new()
    result.name=label
    result.multimesh=mm
    result.material_override=material
    parent.add_child(result)
    return result

static func apply(root:Node3D)->bool:
    if root==null or not bool(root.get_meta(V42_FLAG,false)):
        return false
    if bool(root.get_meta(FLAG,false)):
        return true
    var high:bool=bool(root.get_meta("tarvoka_g13_v1_high_detail",false))
    if high and not bool(root.get_meta(V56.FLAG,false)):
        return false
    if not high and not bool(root.get_meta(V53.FLAG,false)):
        return false
    var hull:=root.find_child("G13_Casco4x4",true,false) as Node3D
    var fender:=root.find_child("G13_V40_CurvedOuterFenders",
        true,false) as MultiMeshInstance3D
    if hull==null or fender==null or (
            fender.get_parent()!=hull or fender.multimesh==null or
            fender.multimesh.instance_count!=2):
        return false
    if root.find_child(BRACKETS,true,false)!=null or (
            root.find_child(PINS,true,false)!=null):
        return false
    var meshes:ArrayMesh=_bracket_mesh()
    var poses:Dictionary=_poses()
    var metal:Array[Transform3D]=poses["brackets"]
    var bolts:Array[Transform3D]=poses["pins"]
    if meshes==null or meshes.get_faces().size()!=20*3 or (
            metal.size()!=BRACKET_COUNT or bolts.size()!=BRACKET_COUNT):
        return false
    var outer:=_coat("#8a989c",0.57,0.56)
    _batch(hull,BRACKETS,meshes,outer,metal)
    if high:
        var head:=SphereMesh.new()
        head.radius=0.013
        head.height=0.016
        head.radial_segments=8
        head.rings=4
        _batch(hull,PINS,head,_coat("#bac2c1",0.74,0.40),bolts)
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g13_v57_outer_bracket_count",BRACKET_COUNT)
    root.set_meta("tarvoka_g13_v57_added_draw_nodes",
        HERO_DRAW_NODES if high else TACTICAL_DRAW_NODES)
    root.set_meta("tarvoka_g13_v57_tactical_batched",true)
    root.set_meta("tarvoka_g13_v57_faction_paint_untouched",true)
    root.set_meta("tarvoka_g13_v57_weapon_identity",
        "dual_autocannons_without_missiles")
    root.set_meta("tarvoka_g13_v57_min_tire_gap_m",
        ARC_RADIUS-0.024-0.31)
    return true

static func show_finish(root:Node3D,enabled:bool)->bool:
    if root==null or not bool(root.get_meta(FLAG,false)):
        return false
    var brackets:=root.find_child(BRACKETS,
        true,false) as MultiMeshInstance3D
    if brackets==null or brackets.multimesh==null:
        return false
    var high:bool=bool(root.get_meta("tarvoka_g13_v1_high_detail",false))
    var bolt:=root.find_child(PINS,true,false) as MultiMeshInstance3D
    if high and bolt==null:
        return false
    brackets.visible=enabled
    if bolt!=null:
        bolt.visible=enabled
    root.set_meta("tarvoka_g13_v57_show_finish",enabled)
    return true
