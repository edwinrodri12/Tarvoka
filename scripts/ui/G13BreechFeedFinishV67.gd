extends RefCounted
class_name TarvokaG13BreechFeedFinishV67

# G13 V67 — native hard-surface breech/feed maintenance access.
# HERO: replace the EXISTING two V18 upper ejection hatches and two
# lateral ammunition-feed covers with closed faceted / recessed steel.
# ANDROID: weld 2 readable recessed-feed plates into the EXISTING V31
# armored moving cheek mesh. Nothing new is drawn or parented; no
# additional projectiles, barrels, magazine geometry or battle stats.
# Same gun pitch, radar, V66 trunnions, eight approved faction paints.
const V66=preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
const FLAG="tarvoka_g13_v67_closed_machined_breech_and_feed_panels"
const SAVED="tarvoka_g13_v67_original_and_formed_receiver_covers"
const PROFILE_POINTS=8
const PROFILE_LEVELS=4
const HERO_COVER_TRIANGLES=60
const ANDROID_CHEEK_OLD_TRIANGLES=48
const ANDROID_ADDED_TRIANGLES=56
const ANDROID_CHEEK_TRIANGLES=104
const NEW_DRAW_NODES=0
const HERO_COVERS=4
const ANDROID_FEED_PANELS=2
static var _top_cache: ArrayMesh
static var _side_cache:Dictionary={}

static func _profile(axis:String,location:float,
        half_a:float,half_b:float,cut:float)->Array[Vector3]:
    var pts:Array[Vector2]=[
        Vector2(-half_a+cut,-half_b),Vector2(half_a-cut,-half_b),
        Vector2(half_a,-half_b+cut),Vector2(half_a,half_b-cut),
        Vector2(half_a-cut,half_b),Vector2(-half_a+cut,half_b),
        Vector2(-half_a,half_b-cut),Vector2(-half_a,-half_b+cut)]
    var result:Array[Vector3]=[]
    for p in pts:
        result.append(
            Vector3(location,p.x,p.y) if axis=="x" else
            Vector3(p.x,location,p.y))
    return result

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        shade:float)->void:
    var normal:Vector3=(b-a).cross(c-a).normalized()
    var c0:=Color(shade,shade,shade,1.0)
    st.set_color(c0)
    st.set_normal(normal)
    st.add_vertex(a)
    st.set_color(c0)
    st.set_normal(normal)
    st.add_vertex(b)
    st.set_color(c0)
    st.set_normal(normal)
    st.add_vertex(c)

static func _shell(st:SurfaceTool,levels:Array,
        brightness:Array[float])->void:
    for layer in range(levels.size()-1):
        var lower:Array[Vector3]=levels[layer]
        var upper:Array[Vector3]=levels[layer+1]
        for i in range(PROFILE_POINTS):
            var j:int=(i+1)%PROFILE_POINTS
            _tri(st,lower[i],lower[j],upper[j],
                brightness[layer])
            _tri(st,lower[i],upper[j],upper[i],
                brightness[layer])
    var bottom:Array[Vector3]=levels[0]
    var top:Array[Vector3]=levels[levels.size()-1]
    for i in range(1,PROFILE_POINTS-1):
        _tri(st,bottom[0],bottom[i+1],bottom[i],0.50)
        _tri(st,top[0],top[i],top[i+1],0.64)

static func _hero_cover(axis:String,side:int)->ArrayMesh:
    if axis=="y" and _top_cache!=null:
        return _top_cache
    var key:String=str(side)
    if axis=="x" and _side_cache.has(key):
        return _side_cache[key] as ArrayMesh
    var d:float=float(side)
    var depth:Array[float]=(
        [-0.012,0.008,0.021,0.017] if axis=="y" else
        [-0.011,0.010,0.023,0.017])
    var half_a:float=0.058 if axis=="y" else 0.038
    var half_b:float=0.083 if axis=="y" else 0.074
    var levels:Array=[]
    var scales:Array[float]=[0.86,1.04,0.88,0.64]
    for i in range(PROFILE_LEVELS):
        levels.append(_profile(axis,
            depth[i]*d if axis=="x" else depth[i],
            half_a*scales[i],half_b*scales[i],
            0.013*scales[i]))
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _shell(st,levels,[0.61,0.91,0.53])
    var mesh:=st.commit() as ArrayMesh
    if axis=="y":
        _top_cache=mesh
    else:
        _side_cache[key]=mesh
    return mesh

static func _android_cheek(original:Mesh)->ArrayMesh:
    if original==null or original.get_faces().size()!=(
            ANDROID_CHEEK_OLD_TRIANGLES*3):
        return null
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var vertices:PackedVector3Array=original.get_faces()
    for i in range(0,vertices.size(),3):
        _tri(st,vertices[i],vertices[i+1],vertices[i+2],1.0)
    # Two flush geometric feed-access surrounds share the existing
    # moving receiver cheek: no detached plates or fresh GPU draw.
    for side in [-1,1]:
        var d:float=float(side)
        var base:Array[Vector3]=[]
        var front:Array[Vector3]=[]
        var shape_a:Array[Vector3]=_profile(
            "x",d*0.520,0.035,0.072,0.013)
        var shape_b:Array[Vector3]=_profile(
            "x",d*0.531,0.030,0.061,0.012)
        for i in range(PROFILE_POINTS):
            base.append(shape_a[i]+Vector3(0,0.012,-0.356))
            front.append(shape_b[i]+Vector3(0,0.012,-0.356))
        for i in range(PROFILE_POINTS):
            var j:int=(i+1)%PROFILE_POINTS
            _tri(st,base[i],base[j],front[j],0.68)
            _tri(st,base[i],front[j],front[i],0.68)
        for i in range(1,PROFILE_POINTS-1):
            _tri(st,base[0],base[i+1],base[i],0.83)
            _tri(st,front[0],front[i],front[i+1],0.49)
    return st.commit() as ArrayMesh

static func _coat(old:StandardMaterial3D,kind:String)->StandardMaterial3D:
    var coat:=old.duplicate(true) as StandardMaterial3D
    coat.vertex_color_use_as_albedo=true
    if kind=="top":
        coat.albedo_color=Color("#839398")
        coat.metallic=0.62
        coat.roughness=0.46
        coat.clearcoat_enabled=true
        coat.clearcoat=0.15
        coat.clearcoat_roughness=0.38
    elif kind=="feed":
        coat.albedo_color=Color("#475b64")
        coat.metallic=0.55
        coat.roughness=0.52
        coat.clearcoat_enabled=false
    else:
        # The existing Android armored cheek carries official faction
        # paint from V32/V66. Preserve it EXACTLY.
        coat.metallic=clampf(old.metallic+0.06,0.22,0.64)
        coat.roughness=clampf(old.roughness-0.025,0.39,0.65)
        coat.clearcoat_enabled=true
        coat.clearcoat=0.21
        coat.clearcoat_roughness=0.41
    coat.cull_mode=BaseMaterial3D.CULL_DISABLED
    return coat

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V66.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var pitch:=model.find_child(
        "G13_ElevacionCanones",true,false) as Node3D
    if pitch==null:
        return false
    var hero:bool=bool(model.get_meta(
        "tarvoka_g13_v1_high_detail",false))
    var nodes:Dictionary={}
    var formed:Dictionary={}
    var kinds:Dictionary={}
    if hero:
        for side in [-1,1]:
            var top_name:String=V18.EJECTION%side
            var feed_name:String=V18.FEED%side
            var top:=model.find_child(top_name,true,false) as MeshInstance3D
            var feed:=model.find_child(feed_name,true,false) as MeshInstance3D
            if top==null or feed==null or (
                    top.get_parent()!=pitch or
                    feed.get_parent()!=pitch) or (
                    not top.mesh is BoxMesh or not feed.mesh is BoxMesh):
                return false
            nodes[top_name]=top
            nodes[feed_name]=feed
            formed[top_name]=_hero_cover("y",side)
            formed[feed_name]=_hero_cover("x",side)
            kinds[top_name]="top"
            kinds[feed_name]="feed"
    else:
        var cheek:=model.find_child(
            V31.CHEEKS,true,false) as MeshInstance3D
        if cheek==null or cheek.get_parent()!=pitch or (
                not cheek.mesh is ArrayMesh):
            return false
        nodes[V31.CHEEKS]=cheek
        formed[V31.CHEEKS]=_android_cheek(cheek.mesh)
        kinds[V31.CHEEKS]="android"
    var old_coats:Dictionary={}
    var new_coats:Dictionary={}
    var old_meshes:Dictionary={}
    for name in nodes:
        var node:=nodes[name] as MeshInstance3D
        var old:=node.material_override as StandardMaterial3D
        var new:Mesh=formed.get(name,null)
        var required:int=(
            HERO_COVER_TRIANGLES if hero else
            ANDROID_CHEEK_TRIANGLES)
        if old==null or new==null or (
                new.get_faces().size()!=required*3):
            return false
        old_coats[name]=old
        old_meshes[name]=node.mesh
        new_coats[name]=_coat(old,str(kinds[name]))
    if nodes.size()!=(HERO_COVERS if hero else 1):
        return false
    for name in nodes:
        var node:=nodes[name] as MeshInstance3D
        node.mesh=formed[name]
        node.material_override=new_coats[name]
    model.set_meta(SAVED,{
        "old_meshes":old_meshes,"new_meshes":formed,
        "old_coats":old_coats,"new_coats":new_coats})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v67_breech_panels",
        HERO_COVERS if hero else ANDROID_FEED_PANELS)
    model.set_meta("tarvoka_g13_v67_hero_closed_tris",
        HERO_COVER_TRIANGLES)
    model.set_meta("tarvoka_g13_v67_android_cheek_tris",
        ANDROID_CHEEK_TRIANGLES)
    model.set_meta("tarvoka_g13_v67_draw_nodes_added",NEW_DRAW_NODES)
    model.set_meta("tarvoka_g13_v67_missiles",0)
    model.set_meta("tarvoka_g13_v67_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var saved:Dictionary=model.get_meta(SAVED,{})
    var meshes:Dictionary=saved.get(
        "new_meshes",{}) if enabled else saved.get("old_meshes",{})
    var coats:Dictionary=saved.get(
        "new_coats",{}) if enabled else saved.get("old_coats",{})
    if meshes.is_empty() or meshes.size()!=coats.size():
        return false
    for name in meshes:
        if model.find_child(str(name),true,false)==null:
            return false
    for name in meshes:
        var node:=model.find_child(str(name),true,false
            ) as MeshInstance3D
        node.mesh=meshes[name]
        node.material_override=coats[name]
    model.set_meta("tarvoka_g13_v67_preview_enabled",enabled)
    return true
