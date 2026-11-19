extends RefCounted
class_name TarvokaG13TurretRingFinishV65

# G13 V65 native hard-surface turret/hull union.
# Replace only the primitive cube mesh INSIDE the existing 12-instance
# rotating V44 bearing batch. Twelve real chamfered steel segments bridge
# the upper armored hull and the azimuth pedestal, with a recessed dark
# bearing and satin upper pedestal on HERO13. Android LOD8 keeps precisely
# the same 12 GPU instances; no additional draw nodes, weapons or pivots.
# Reversible native geometry and PBR; no faction-color or gameplay edits.
const V64=preload("res://scripts/ui/G13ArmorEdgeFinishV64.gd")
const V44=preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const FLAG="tarvoka_g13_v65_chamfered_rotating_turret_ring"
const SAVED="tarvoka_g13_v65_before_after_ring_geometry_and_pbr"
const SEGMENTS=V44.TURRET_JOINT
const BEARING=V56.BEARING
const PEDESTAL="G13_V15_FixedTurretPedestal"
const SEGMENT_COUNT=12
const OCTAGON_CORNERS=8
const SECTION_LAYERS=4
const SEGMENT_TRIANGLES=60
const NEW_DRAW_NODES=0
static var _machined: ArrayMesh

static func _octagon(y:float,scale:float)->Array[Vector3]:
    var e:float=0.5*scale
    var inset:float=0.11*scale
    return [
        Vector3(-e+inset,y,-e),Vector3(e-inset,y,-e),
        Vector3(e,y,-e+inset),Vector3(e,y,e-inset),
        Vector3(e-inset,y,e),Vector3(-e+inset,y,e),
        Vector3(-e,y,e-inset),Vector3(-e,y,-e+inset)
    ]

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        shade:float)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    var tint:=Color(shade,shade,shade,1.0)
    st.set_color(tint)
    st.set_normal(n)
    st.add_vertex(a)
    st.set_color(tint)
    st.set_normal(n)
    st.add_vertex(b)
    st.set_color(tint)
    st.set_normal(n)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        d:Vector3,shade:float)->void:
    _tri(st,a,b,c,shade)
    _tri(st,a,c,d,shade)

static func _segment_mesh()->ArrayMesh:
    if _machined!=null:
        return _machined
    var levels:Array[Vector2]=[
        Vector2(-0.50,0.79),
        Vector2(-0.35,1.00),
        Vector2(0.35,1.00),
        Vector2(0.50,0.79)
    ]
    var rings:Array=[]
    for p in levels:
        rings.append(_octagon(p.x,p.y))
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(SECTION_LAYERS-1):
        var bottom:Array[Vector3]=rings[layer]
        var top:Array[Vector3]=rings[layer+1]
        var brightness:float=(
            0.58 if layer==0 else (
            0.90 if layer==1 else 0.76))
        for i in range(OCTAGON_CORNERS):
            var j:int=(i+1)%OCTAGON_CORNERS
            _quad(st,bottom[i],bottom[j],top[j],top[i],
                brightness)
    var first:Array[Vector3]=rings[0]
    var last:Array[Vector3]=rings[SECTION_LAYERS-1]
    for i in range(1,OCTAGON_CORNERS-1):
        _tri(st,first[0],first[i+1],first[i],0.53)
        _tri(st,last[0],last[i],last[i+1],0.81)
    _machined=st.commit() as ArrayMesh
    return _machined

static func _finish(old:StandardMaterial3D,kind:String)->StandardMaterial3D:
    var new:=old.duplicate(true) as StandardMaterial3D
    if kind==SEGMENTS:
        new.albedo_color=Color("#586a71")
        new.vertex_color_use_as_albedo=true
        new.metallic=0.62
        new.roughness=0.46
        new.clearcoat_enabled=true
        new.clearcoat=0.15
        new.clearcoat_roughness=0.36
        new.cull_mode=BaseMaterial3D.CULL_DISABLED
    elif kind==BEARING:
        # The recessed rotating grease/bearing track needs to read dark.
        new.albedo_color=Color("#2c393e")
        new.metallic=0.64
        new.roughness=0.47
        new.clearcoat_enabled=false
    elif kind==PEDESTAL:
        # Hull-side tapered armored mount, not faction-colored plastic.
        new.albedo_color=Color("#56676e")
        new.metallic=0.51
        new.roughness=0.53
        new.clearcoat_enabled=true
        new.clearcoat=0.12
        new.clearcoat_roughness=0.43
    return new

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V64.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hero:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var turret:=model.find_child(
        "G13_TorretaAzimut",true,false) as Node3D
    var hull:=model.find_child(
        "G13_Casco4x4",true,false) as Node3D
    var ring:=model.find_child(
        SEGMENTS,true,false) as MultiMeshInstance3D
    if turret==null or hull==null or ring==null or (
            ring.get_parent()!=turret) or ring.multimesh==null or (
            ring.multimesh.instance_count!=SEGMENT_COUNT) or (
            not ring.multimesh.mesh is BoxMesh):
        return false
    var nodes:Dictionary={SEGMENTS:ring}
    if hero:
        if not bool(model.get_meta(V56.FLAG,false)):
            return false
        var bearing:=model.find_child(
            BEARING,true,false) as MeshInstance3D
        var pedestal:=model.find_child(
            PEDESTAL,true,false) as MeshInstance3D
        if bearing==null or pedestal==null or (
                bearing.get_parent()!=turret or (
                pedestal.get_parent()!=hull)):
            return false
        nodes[BEARING]=bearing
        nodes[PEDESTAL]=pedestal
    var materials_before:Dictionary={}
    var materials_after:Dictionary={}
    for name in nodes:
        var node:=nodes[name] as GeometryInstance3D
        var mat:=node.material_override as StandardMaterial3D
        if mat==null:
            return false
        materials_before[name]=mat
        materials_after[name]=_finish(mat,str(name))
    var mesh:=_segment_mesh()
    if mesh==null or mesh.get_surface_count()!=1 or (
            mesh.get_faces().size()!=SEGMENT_TRIANGLES*3):
        return false
    var original:Mesh=ring.multimesh.mesh
    var poses:Array[Transform3D]=[]
    for i in range(SEGMENT_COUNT):
        poses.append(ring.multimesh.get_instance_transform(i))
    for name in nodes:
        var node:=nodes[name] as GeometryInstance3D
        node.material_override=materials_after[name]
    ring.multimesh.mesh=mesh
    model.set_meta(SAVED,{
        "original_ring_mesh":original,"machined_ring_mesh":mesh,
        "original_coats":materials_before,"machined_coats":materials_after,
        "unchanged_rotating_poses":poses})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v65_rotating_armor_segments",SEGMENT_COUNT)
    model.set_meta("tarvoka_g13_v65_triangles_per_segment",
        SEGMENT_TRIANGLES)
    model.set_meta("tarvoka_g13_v65_new_gpu_draw_nodes",NEW_DRAW_NODES)
    model.set_meta("tarvoka_g13_v65_pedestal_and_bearing_coated",hero)
    model.set_meta("tarvoka_g13_v65_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SAVED,{})
    var coats:Dictionary=saved.get(
        "machined_coats",{}) if enabled else saved.get(
        "original_coats",{})
    var ring:=model.find_child(
        SEGMENTS,true,false) as MultiMeshInstance3D
    if ring==null or ring.multimesh==null or (
            ring.multimesh.instance_count!=SEGMENT_COUNT) or (
            coats.is_empty()):
        return false
    for name in coats:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in coats:
        var part:=model.find_child(str(name),true,false
            ) as GeometryInstance3D
        part.material_override=coats[name]
    ring.multimesh.mesh=(
        saved["machined_ring_mesh"] if enabled else
        saved["original_ring_mesh"])
    model.set_meta("tarvoka_g13_v65_preview_enabled",enabled)
    return true
