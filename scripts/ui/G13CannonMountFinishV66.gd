extends RefCounted
class_name TarvokaG13CannonMountFinishV66

# V66 real 3D articulated twin autocannon mount finish.
# Replaces existing hero V19 fixed trunnions and V18 barrel collars with
# CLOSED, HOLLOW, 8-profile machined annular meshes. Android LOD8 replaces
# only the EXISTING V31 two-instance stationary collar batch (1 draw call).
# Existing moving V19 spindle hubs and cheek shields receive restrained
# satin steel PBR while the V32 tactical faction enamel hue stays intact.
# Original turret yaw and gun pitch pivots, 2 barrels, flash, ammunition and
# V29 radar remain unchanged. 0 new nodes on either LOD, full restore.
const V65=preload("res://scripts/ui/G13TurretRingFinishV65.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
const V31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
const FLAG="tarvoka_g13_v66_machined_articulated_twin_gun_mounts"
const SAVED="tarvoka_g13_v66_original_mounted_meshes_and_coats"
const EXTRA_DRAW_NODES=0
const PROFILE_VERTICES=8
const HERO_TRUNNION_SEGMENTS=20
const HERO_BARREL_SEGMENTS=16
const ANDROID_TRUNNION_SEGMENTS=12
const HERO_TRUNNION_TRIANGLES=PROFILE_VERTICES*HERO_TRUNNION_SEGMENTS*2
const HERO_BARREL_TRIANGLES=PROFILE_VERTICES*HERO_BARREL_SEGMENTS*2
const ANDROID_TRUNNION_TRIANGLES=PROFILE_VERTICES*ANDROID_TRUNNION_SEGMENTS*2
static var _meshes:Dictionary={}

static func _point(axis:String,d:float,r:float,a:float)->Vector3:
    if axis=="x":
        return Vector3(d,cos(a)*r,sin(a)*r)
    return Vector3(cos(a)*r,d,sin(a)*r)

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        shade:float)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    var color:=Color(shade,shade,shade,1.0)
    st.set_color(color)
    st.set_normal(n)
    st.add_vertex(a)
    st.set_color(color)
    st.set_normal(n)
    st.add_vertex(b)
    st.set_color(color)
    st.set_normal(n)
    st.add_vertex(c)

static func _ring(axis:String,inner:float,outer:float,length:float,
        segments:int)->ArrayMesh:
    var key:String="%s_%.4f_%.4f_%.4f_%d" % [
        axis,inner,outer,length,segments]
    if _meshes.has(key):
        return _meshes[key] as ArrayMesh
    # Loop around the closed cross-section of an actual annular collar:
    # inner recessed bore, flush caps, 10-mm outer steel bevels and two
    # broad load-bearing walls. No fake solid cylinder over the spindle.
    var half:float=length*0.5
    var profile:Array[Vector2]=[
        Vector2(-half,inner+0.004),
        Vector2(-half,outer-0.012),
        Vector2(-half+0.010,outer),
        Vector2(half-0.010,outer),
        Vector2(half,outer-0.012),
        Vector2(half,inner+0.004),
        Vector2(half-0.009,inner),
        Vector2(-half+0.009,inner)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for segment in range(segments):
        var a0:float=TAU*float(segment)/float(segments)
        var a1:float=TAU*float(segment+1)/float(segments)
        for edge in range(PROFILE_VERTICES):
            var j:int=(edge+1)%PROFILE_VERTICES
            var p0:Vector2=profile[edge]
            var p1:Vector2=profile[j]
            var v00:Vector3=_point(axis,p0.x,p0.y,a0)
            var v01:Vector3=_point(axis,p0.x,p0.y,a1)
            var v10:Vector3=_point(axis,p1.x,p1.y,a0)
            var v11:Vector3=_point(axis,p1.x,p1.y,a1)
            var shade:float=(
                0.49 if edge>=6 else (
                0.93 if edge==2 else (
                0.68 if edge==1 or edge==3 else 0.77)))
            _tri(st,v00,v01,v11,shade)
            _tri(st,v00,v11,v10,shade)
    var output:=st.commit() as ArrayMesh
    _meshes[key]=output
    return output

static func _source(node:GeometryInstance3D)->StandardMaterial3D:
    if node.material_override is StandardMaterial3D:
        return node.material_override as StandardMaterial3D
    if node is MultiMeshInstance3D:
        var batch:=node as MultiMeshInstance3D
        if batch.multimesh!=null and (
                batch.multimesh.mesh is PrimitiveMesh):
            return (batch.multimesh.mesh as PrimitiveMesh
                ).material as StandardMaterial3D
    return null

static func _coat(original:StandardMaterial3D,kind:String
        )->StandardMaterial3D:
    var coat:=original.duplicate(true) as StandardMaterial3D
    if kind=="fixed" or kind=="barrel":
        coat.albedo_color=Color(
            "#899a9d" if kind=="barrel" else "#617479")
        coat.vertex_color_use_as_albedo=true
        coat.metallic=0.68 if kind=="fixed" else 0.76
        coat.roughness=0.43 if kind=="fixed" else 0.36
        coat.clearcoat_enabled=true
        coat.clearcoat=0.16
        coat.clearcoat_roughness=0.32
        coat.cull_mode=BaseMaterial3D.CULL_DISABLED
    elif kind=="hub":
        coat.albedo_color=Color("#9caaab")
        coat.metallic=0.73
        coat.roughness=0.38
        coat.clearcoat_enabled=false
    elif kind=="cheek":
        # Preserve EXACT tactical faction color from V32.
        coat.metallic=clampf(original.metallic+0.09,0.20,0.55)
        coat.roughness=clampf(original.roughness-0.085,0.44,0.68)
        coat.clearcoat_enabled=true
        coat.clearcoat=0.20
        coat.clearcoat_roughness=0.46
    return coat

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V65.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hero:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var turret:=model.find_child("G13_TorretaAzimut",
        true,false) as Node3D
    var pitch:=model.find_child("G13_ElevacionCanones",
        true,false) as Node3D
    if turret==null or pitch==null or pitch.get_parent()!=turret:
        return false
    var nodes:Dictionary={}
    var newmeshes:Dictionary={}
    if hero:
        if not bool(model.get_meta(V19.FLAG,false)) or (
                not bool(model.get_meta(V18.FLAG,false))):
            return false
        var fixed:=_ring("x",0.096,0.149,0.108,HERO_TRUNNION_SEGMENTS)
        var barrel:=_ring("y",0.064,0.084,0.102,HERO_BARREL_SEGMENTS)
        if fixed.get_faces().size()!=HERO_TRUNNION_TRIANGLES*3 or (
                barrel.get_faces().size()!=HERO_BARREL_TRIANGLES*3):
            return false
        for side in [-1,1]:
            var f:String=V19.FIXED_RING%side
            var b:String=V18.COLLAR%side
            var hub:String=V19.MOBILE_HUB%side
            var cheek:String=V19.CHEEK%side
            for name in [f,b,hub,cheek]:
                var item:=model.find_child(
                    name,true,false) as MeshInstance3D
                if item==null:
                    return false
                if name==f and item.get_parent()!=turret:
                    return false
                if name!=f and item.get_parent()!=pitch:
                    return false
                nodes[name]=item
            if not (nodes[f] as MeshInstance3D).mesh is ArrayMesh or (
                    not (nodes[b] as MeshInstance3D
                    ).mesh is CylinderMesh):
                return false
            newmeshes[f]=fixed
            newmeshes[b]=barrel
    else:
        if not bool(model.get_meta(V31.FLAG,false)):
            return false
        var fixed:=model.find_child(
            V31.BEARINGS,true,false) as MultiMeshInstance3D
        var cheek:=model.find_child(
            V31.CHEEKS,true,false) as MeshInstance3D
        if fixed==null or cheek==null or fixed.multimesh==null or (
                fixed.get_parent()!=turret or cheek.get_parent()!=pitch) or (
                fixed.multimesh.instance_count!=2) or (
                not fixed.multimesh.mesh is CylinderMesh):
            return false
        nodes[V31.BEARINGS]=fixed
        nodes[V31.CHEEKS]=cheek
        var tactical:=_ring(
            "y",0.100,0.153,0.085,ANDROID_TRUNNION_SEGMENTS)
        if tactical.get_faces().size()!=ANDROID_TRUNNION_TRIANGLES*3:
            return false
        newmeshes[V31.BEARINGS]=tactical
    var before:Dictionary={}
    var after:Dictionary={}
    for name in nodes:
        var node:=nodes[name] as GeometryInstance3D
        var original:=_source(node)
        if original==null:
            return false
        before[name]=node.material_override
        var kind:String=(
            "fixed" if name in newmeshes and (
                name==V31.BEARINGS or str(name).begins_with(
                "G13_V19_StationaryTrunnionCollar")) else (
            "barrel" if name in newmeshes else (
            "hub" if str(name).begins_with(
                "G13_V19_MovingTrunnionHub") else "cheek")))
        after[name]=_coat(original,kind)
    var before_mesh:Dictionary={}
    for name in newmeshes:
        var node:GeometryInstance3D=nodes[name] as GeometryInstance3D
        if node is MultiMeshInstance3D:
            before_mesh[name]=(node as MultiMeshInstance3D).multimesh.mesh
        else:
            before_mesh[name]=(node as MeshInstance3D).mesh
    for name in nodes:
        (nodes[name] as GeometryInstance3D).material_override=after[name]
    for name in newmeshes:
        var node:GeometryInstance3D=nodes[name] as GeometryInstance3D
        if node is MultiMeshInstance3D:
            (node as MultiMeshInstance3D).multimesh.mesh=newmeshes[name]
        else:
            (node as MeshInstance3D).mesh=newmeshes[name]
    model.set_meta(SAVED,{
        "before_coats":before,"after_coats":after,
        "before_meshes":before_mesh,"after_meshes":newmeshes})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v66_real_hollow_collars",
        4 if hero else 2)
    model.set_meta("tarvoka_g13_v66_new_draw_nodes",EXTRA_DRAW_NODES)
    model.set_meta("tarvoka_g13_v66_pitch_parent",pitch.name)
    model.set_meta("tarvoka_g13_v66_turret_parent",turret.name)
    model.set_meta("tarvoka_g13_v66_guns",2)
    model.set_meta("tarvoka_g13_v66_missiles",0)
    model.set_meta("tarvoka_g13_v66_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var state:Dictionary=model.get_meta(SAVED,{})
    var coats:Dictionary=state.get(
        "after_coats",{}) if enabled else state.get("before_coats",{})
    var meshes:Dictionary=state.get(
        "after_meshes",{}) if enabled else state.get("before_meshes",{})
    if coats.size()!=(8 if bool(model.get_meta(
            "tarvoka_g13_v1_high_detail",false)) else 2):
        return false
    for name in coats:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in meshes:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in coats:
        var part:=model.find_child(str(name),true,false
            ) as GeometryInstance3D
        part.material_override=coats[name]
    for name in meshes:
        var part:=model.find_child(str(name),true,false)
        if part is MultiMeshInstance3D:
            (part as MultiMeshInstance3D).multimesh.mesh=meshes[name]
        else:
            (part as MeshInstance3D).mesh=meshes[name]
    model.set_meta("tarvoka_g13_v66_preview_enabled",enabled)
    return true
