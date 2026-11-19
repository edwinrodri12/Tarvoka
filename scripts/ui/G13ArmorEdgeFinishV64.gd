extends RefCounted
class_name TarvokaG13ArmorEdgeFinishV64

# G13 V64 HARD-SURFACE ART — real native metal edging, not an image.
# Existing V44 side shield and V45 lower maintenance hatches receive
# deeper physical lips and faceted edge-shadow vertex color IN THE ORIGINAL
# TWO MESHES. The original V45 sixteen fittings move out to the new hatch
# surface; turret rotation ring and roof brow gain distinct painted-steel
# PBR. No new nodes, mesh batches, gameplay, weapon or faction-color edits.
# Keep V63's faction panels, V62 optical glass and V61 wheels untouched.
const V63=preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const V44=preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const V45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const FLAG="tarvoka_g13_v64_real_faceted_seam_and_armor_edges"
const SAVED="tarvoka_g13_v64_original_mesh_coatings_and_fitting_poses"
const BODY=V44.BODY_ARMOR
const HATCH=V45.DOORS
const BROW=V45.BROW
const FITTINGS=V45.FITTINGS
const JOINT=V44.TURRET_JOINT
const PARTS=[BODY,HATCH,BROW,FITTINGS,JOINT]
const EXTRA_DRAW_NODES=0
const BODY_FRONT_OLD=0.732
const BODY_FRONT_NEW=0.737
const HATCH_FRONT_OLD=0.722
const HATCH_FRONT_NEW=0.733
const FITTING_FRONT_NEW=0.737
const ORIGINAL_FITTINGS=16

static func _faceted_mesh(original:ArrayMesh,old_front:float,
        new_front:float,inner:float)->ArrayMesh:
    if original==null or original.get_surface_count()!=1:
        return null
    var arrays:Array=original.surface_get_arrays(0)
    var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var normals:PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
    if points.size()<30 or (points.size()%3)!=0 or (
            normals.size()!=points.size()):
        return null
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(points.size()):
        var point:Vector3=points[i]
        var t:float=clampf(
            (absf(point.x)-inner)/maxf(old_front-inner,0.0001),0.0,1.0)
        # The original outer cap really advances in X while its inner
        # base stays seated in the old steel; faces become deeper bevels.
        if absf(absf(point.x)-old_front)<0.0003:
            point.x=signf(point.x)*new_front
        # Exterior face reflects the sky; underside and machined
        # perimeter are darker by their actual 3D vertex positions.
        var shade:float=lerpf(0.60,1.0,t)
        st.set_color(Color(shade,shade,shade,1.0))
        st.set_normal(normals[i])
        st.add_vertex(point)
    return st.commit() as ArrayMesh

static func _coat(before:StandardMaterial3D,
        part:String)->StandardMaterial3D:
    var after:=before.duplicate(true) as StandardMaterial3D
    if part==BODY or part==HATCH:
        after.vertex_color_use_as_albedo=true
        after.metallic=0.60 if part==BODY else 0.55
        after.roughness=0.47 if part==BODY else 0.49
        after.clearcoat_enabled=true
        after.clearcoat=0.14
        after.clearcoat_roughness=0.39
    elif part==BROW:
        after.metallic=0.54
        after.roughness=0.47
        after.clearcoat_enabled=true
        after.clearcoat=0.16
        after.clearcoat_roughness=0.42
    elif part==FITTINGS:
        # Satin galvanized steel: still legible over dark seam.
        after.albedo_color=Color("#849398")
        after.metallic=0.66
        after.roughness=0.40
        after.clearcoat_enabled=false
    elif part==JOINT:
        # The rotating bearing stays darker than the flank badges.
        after.albedo_color=Color("#38494f")
        after.metallic=0.55
        after.roughness=0.56
        after.clearcoat_enabled=false
    return after

static func _fitting_poses(original:MultiMesh)->Array[Transform3D]:
    var poses:Array[Transform3D]=[]
    for i in range(original.instance_count):
        var p:Transform3D=original.get_instance_transform(i)
        p.origin.x=signf(p.origin.x)*FITTING_FRONT_NEW
        poses.append(p)
    return poses

static func _set_fitting_poses(mm:MultiMesh,poses:Array[Transform3D])->void:
    for i in range(poses.size()):
        mm.set_instance_transform(i,poses[i])

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V63.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var nodes:Dictionary={}
    var before:Dictionary={}
    var after:Dictionary={}
    for name in PARTS:
        var node:=model.find_child(str(name),true,false) as GeometryInstance3D
        if node==null or not node.material_override is StandardMaterial3D:
            return false
        nodes[name]=node
        var original:=node.material_override as StandardMaterial3D
        before[name]=original
        after[name]=_coat(original,str(name))
    var body:=nodes[BODY] as MeshInstance3D
    var hatch:=nodes[HATCH] as MeshInstance3D
    var hardware:=nodes[FITTINGS] as MultiMeshInstance3D
    if body==null or hatch==null or hardware==null or (
            not body.mesh is ArrayMesh) or (
            not hatch.mesh is ArrayMesh) or (
            hardware.multimesh==null) or (
            hardware.multimesh.instance_count!=ORIGINAL_FITTINGS):
        return false
    var original_body:=body.mesh as ArrayMesh
    var original_hatch:=hatch.mesh as ArrayMesh
    var new_body:=_faceted_mesh(
        original_body,BODY_FRONT_OLD,BODY_FRONT_NEW,0.660)
    var new_hatch:=_faceted_mesh(
        original_hatch,HATCH_FRONT_OLD,HATCH_FRONT_NEW,0.664)
    if new_body==null or new_hatch==null or (
            new_body.get_faces().size()!=original_body.get_faces().size()) or (
            new_hatch.get_faces().size()!=original_hatch.get_faces().size()):
        return false
    var old_fittings:Array[Transform3D]=[]
    for i in range(hardware.multimesh.instance_count):
        old_fittings.append(hardware.multimesh.get_instance_transform(i))
    var new_fittings:Array[Transform3D]=_fitting_poses(hardware.multimesh)
    for i in range(new_fittings.size()):
        if absf(new_fittings[i].origin.x)-absf(
                old_fittings[i].origin.x)<0.008:
            return false
    for name in PARTS:
        var node:=nodes[name] as GeometryInstance3D
        node.material_override=after[name]
    body.mesh=new_body
    hatch.mesh=new_hatch
    _set_fitting_poses(hardware.multimesh,new_fittings)
    model.set_meta(SAVED,{
        "before_materials":before,"after_materials":after,
        "before_body_mesh":original_body,"after_body_mesh":new_body,
        "before_hatch_mesh":original_hatch,"after_hatch_mesh":new_hatch,
        "before_fittings":old_fittings,"after_fittings":new_fittings})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v64_faceted_body_triangles",
        new_body.get_faces().size()/3)
    model.set_meta("tarvoka_g13_v64_faceted_hatch_triangles",
        new_hatch.get_faces().size()/3)
    model.set_meta("tarvoka_g13_v64_reseated_hardware",ORIGINAL_FITTINGS)
    model.set_meta("tarvoka_g13_v64_extra_gpu_nodes",EXTRA_DRAW_NODES)
    model.set_meta("tarvoka_g13_v64_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var s:Dictionary=model.get_meta(SAVED,{})
    var mats:Dictionary=s.get(
        "after_materials",{}) if enabled else s.get("before_materials",{})
    if mats.size()!=PARTS.size():
        return false
    var body:=model.find_child(BODY,true,false) as MeshInstance3D
    var hatch:=model.find_child(HATCH,true,false) as MeshInstance3D
    var hw:=model.find_child(FITTINGS,true,false) as MultiMeshInstance3D
    var poses:Array[Transform3D]=s.get(
        "after_fittings",[]) if enabled else s.get("before_fittings",[])
    if body==null or hatch==null or hw==null or (
            hw.multimesh==null) or (
            hw.multimesh.instance_count!=poses.size()):
        return false
    for name in PARTS:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in PARTS:
        var part:=model.find_child(str(name),true,false
            ) as GeometryInstance3D
        part.material_override=mats[name]
    body.mesh=s["after_body_mesh"] if enabled else s["before_body_mesh"]
    hatch.mesh=s["after_hatch_mesh"] if enabled else s["before_hatch_mesh"]
    _set_fitting_poses(hw.multimesh,poses)
    model.set_meta("tarvoka_g13_v64_preview_enabled",enabled)
    return true
