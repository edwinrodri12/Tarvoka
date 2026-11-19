extends RefCounted
class_name TarvokaG13MuzzleMountFinishV69

# TARVOKA G13 V69 — true native muzzle brake, stepped barrel sleeve and
# outer gun support. NO prop mockups, decals, additional MeshInstances, ammo
# logic, battle effects or missiles. The original paired gun nodes on the
# G13_ElevacionCanones pivot get genuinely machined replacement meshes.
# HERO13 keeps a richer two-band pierced muzzle and the two original V19
# spindle hubs get chamfered recessed bolt-seat geometry. LOD8 uses a
# reduced one-band muzzle and 12-sided stepped barrel: same four draw nodes.
# All original resources are retained for same-scene historical comparison.
const V68=preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
const FLAG="tarvoka_g13_v69_open_muzzle_brake_and_mount_seats"
const SAVED="tarvoka_g13_v69_original_and_machined_gun_end_resources"
const DRAW_NODES_ADDED=0
const GUN_COUNT=2
const MUZZLE_BORE=0.048
const BARREL_BORE=0.035
const MUZZLE_RINGS=8
const BARREL_RINGS=12
const HUB_RINGS=4
const HERO_SECTORS=16
const ANDROID_SECTORS=12
const HUB_SECTORS=12
const HUB_TRIANGLES=HUB_SECTORS*12
static var _barrels:Dictionary={}
static var _muzzles:Dictionary={}
static var _hub:ArrayMesh

static func _point(y:float,r:float,a:float)->Vector3:
    return Vector3(cosf(a)*r,y,sinf(a)*r)

static func _tri(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        shade:float)->void:
    var n:Vector3=(b-a).cross(c-a).normalized()
    var color:=Color(shade,shade,shade,1.0)
    st.set_normal(n)
    st.set_color(color)
    st.add_vertex(a)
    st.set_normal(n)
    st.set_color(color)
    st.add_vertex(b)
    st.set_normal(n)
    st.set_color(color)
    st.add_vertex(c)

static func _quad(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,
        d:Vector3,shade:float)->void:
    _tri(st,a,b,c,shade)
    _tri(st,a,c,d,shade)

static func _vented(layer:int,index:int,high:bool,n:int)->bool:
    if high:
        if layer!=2 and layer!=4:
            return false
    elif layer!=3:
        return false
    var half:int=n/2
    return index==0 or index==1 or index==half or index==half+1

static func _muzzle_mesh(high:bool)->ArrayMesh:
    var key:String="hero" if high else "tactical"
    if _muzzles.has(key):
        return _muzzles[key] as ArrayMesh
    var n:int=HERO_SECTORS if high else ANDROID_SECTORS
    # Axial positions deliberately retain the 0.085 m original muzzle
    # length and its existing Y-to-Z rotation; the muzzle-flash anchor at
    # z=-1.29 stays completely untouched.
    var profile:Array[Vector2]=[
        Vector2(-0.0425,0.068),
        Vector2(-0.0360,0.073),
        Vector2(-0.0250,0.072),
        Vector2(-0.0090,0.066),
        Vector2(0.0090,0.066),
        Vector2(0.0240,0.072),
        Vector2(0.0360,0.072),
        Vector2(0.0425,0.065)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(MUZZLE_RINGS-1):
        var p0:Vector2=profile[layer]
        var p1:Vector2=profile[layer+1]
        for i in range(n):
            if _vented(layer,i,high,n):
                # The side window is a real opening in both outer and
                # inner walls, NOT a dark painted square over solid steel.
                continue
            var a0:float=TAU*float(i)/float(n)
            var a1:float=TAU*float(i+1)/float(n)
            _quad(st,_point(p0.x,p0.y,a0),
                _point(p0.x,p0.y,a1),
                _point(p1.x,p1.y,a1),
                _point(p1.x,p1.y,a0),
                0.92 if layer==1 or layer==5 else (
                0.72 if layer==2 or layer==4 else 0.80))
            _quad(st,_point(p0.x,MUZZLE_BORE,a1),
                _point(p0.x,MUZZLE_BORE,a0),
                _point(p1.x,MUZZLE_BORE,a0),
                _point(p1.x,MUZZLE_BORE,a1),0.28)
    # Closed annular steel faces at both ends, while the center is hollow.
    for i in range(n):
        var a0:float=TAU*float(i)/float(n)
        var a1:float=TAU*float(i+1)/float(n)
        var first:Vector2=profile[0]
        var last:Vector2=profile[MUZZLE_RINGS-1]
        _quad(st,_point(first.x,first.y,a0),
            _point(first.x,first.y,a1),
            _point(first.x,MUZZLE_BORE,a1),
            _point(first.x,MUZZLE_BORE,a0),0.86)
        _quad(st,_point(last.x,MUZZLE_BORE,a0),
            _point(last.x,MUZZLE_BORE,a1),
            _point(last.x,last.y,a1),
            _point(last.x,last.y,a0),0.60)
    var bands:Array=[2,4] if high else [3]
    for layer in bands:
        var p0:Vector2=profile[layer]
        var p1:Vector2=profile[layer+1]
        for base in [0,n/2]:
            # Perforations in the two opposing lateral sides. Both 2-sector
            # cutouts have four real radial material walls at each band.
            for part in range(2):
                var i:int=base+part
                var a0:float=TAU*float(i)/float(n)
                var a1:float=TAU*float(i+1)/float(n)
                for p in [p0,p1]:
                    _quad(st,_point(p.x,p.y,a0),
                        _point(p.x,p.y,a1),
                        _point(p.x,MUZZLE_BORE,a1),
                        _point(p.x,MUZZLE_BORE,a0),0.45)
            for edge in [base,base+2]:
                var angle:float=TAU*float(edge)/float(n)
                _quad(st,_point(p0.x,p0.y,angle),
                    _point(p1.x,p1.y,angle),
                    _point(p1.x,MUZZLE_BORE,angle),
                    _point(p0.x,MUZZLE_BORE,angle),0.43)
    var mesh:=st.commit() as ArrayMesh
    _muzzles[key]=mesh
    return mesh

static func _barrel_mesh(high:bool)->ArrayMesh:
    var key:String="hero" if high else "tactical"
    if _barrels.has(key):
        return _barrels[key] as ArrayMesh
    var n:int=HERO_SECTORS if high else ANDROID_SECTORS
    # Twelve concentric turned-steel stations along the original 1.10 m
    # barrel. Machined relief bands stay above the existing muzzle brake
    # overlap and below the original receiver, with an open inset bore.
    var p:Array[Vector2]=[
        Vector2(-0.550,0.051),
        Vector2(-0.538,0.056),
        Vector2(-0.490,0.056),
        Vector2(-0.472,0.051),
        Vector2(-0.420,0.051),
        Vector2(-0.406,0.055),
        Vector2(-0.344,0.055),
        Vector2(-0.326,0.051),
        Vector2(0.330,0.051),
        Vector2(0.365,0.056),
        Vector2(0.510,0.056),
        Vector2(0.550,0.054)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(BARREL_RINGS-1):
        var a:Vector2=p[i]
        var b:Vector2=p[i+1]
        for seg in range(n):
            var t0:float=TAU*float(seg)/float(n)
            var t1:float=TAU*float(seg+1)/float(n)
            _quad(st,_point(a.x,a.y,t0),_point(a.x,a.y,t1),
                _point(b.x,b.y,t1),_point(b.x,b.y,t0),
                0.63 if i==2 or i==6 else (
                0.93 if i==4 or i==9 else 0.84))
    for seg in range(n):
        var t0:float=TAU*float(seg)/float(n)
        var t1:float=TAU*float(seg+1)/float(n)
        # Facing the hollow muzzle, a small 0.11m deep recessed chamber.
        _quad(st,_point(-0.55,0.051,t0),
            _point(-0.55,0.051,t1),
            _point(-0.55,BARREL_BORE,t1),
            _point(-0.55,BARREL_BORE,t0),0.78)
        _quad(st,_point(-0.55,BARREL_BORE,t1),
            _point(-0.55,BARREL_BORE,t0),
            _point(-0.44,BARREL_BORE,t0),
            _point(-0.44,BARREL_BORE,t1),0.34)
        var center_front:=Vector3(0.0,-0.44,0.0)
        _tri(st,center_front,_point(-0.44,BARREL_BORE,t0),
            _point(-0.44,BARREL_BORE,t1),0.23)
        var center_rear:=Vector3(0.0,0.55,0.0)
        _tri(st,center_rear,_point(0.55,0.054,t1),
            _point(0.55,0.054,t0),0.74)
    var mesh:=st.commit() as ArrayMesh
    _barrels[key]=mesh
    return mesh

static func _moving_hub()->ArrayMesh:
    if _hub!=null:
        return _hub
    var p:Array[Vector2]=[
        Vector2(-0.009,0.074),
        Vector2(-0.006,0.082),
        Vector2(0.006,0.082),
        Vector2(0.009,0.075)
    ]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(HUB_RINGS-1):
        var a:Vector2=p[i]
        var b:Vector2=p[i+1]
        for seg in range(HUB_SECTORS):
            var t0:float=TAU*float(seg)/float(HUB_SECTORS)
            var t1:float=TAU*float(seg+1)/float(HUB_SECTORS)
            _quad(st,_point(a.x,a.y,t0),_point(a.x,a.y,t1),
                _point(b.x,b.y,t1),_point(b.x,b.y,t0),
                0.91 if i==1 else 0.66)
    for seg in range(HUB_SECTORS):
        var t0:float=TAU*float(seg)/float(HUB_SECTORS)
        var t1:float=TAU*float(seg+1)/float(HUB_SECTORS)
        _tri(st,Vector3(0.0,-0.009,0.0),
            _point(-0.009,0.074,t1),
            _point(-0.009,0.074,t0),0.70)
        # Outer twelve-sided captive bolt seat with dark inset center.
        _quad(st,_point(0.009,0.075,t0),
            _point(0.009,0.075,t1),
            _point(0.009,0.026,t1),
            _point(0.009,0.026,t0),0.77)
        _quad(st,_point(0.009,0.026,t0),
            _point(0.009,0.026,t1),
            _point(0.002,0.026,t1),
            _point(0.002,0.026,t0),0.37)
        _tri(st,Vector3(0.0,0.002,0.0),
            _point(0.002,0.026,t0),
            _point(0.002,0.026,t1),0.22)
    _hub=st.commit() as ArrayMesh
    return _hub

static func _coat(old:StandardMaterial3D,kind:String
        )->StandardMaterial3D:
    var result:=old.duplicate(true) as StandardMaterial3D
    result.vertex_color_use_as_albedo=true
    result.cull_mode=BaseMaterial3D.CULL_DISABLED
    match kind:
        "muzzle":
            result.albedo_color=Color("#63747a")
            result.metallic=0.72
            result.roughness=0.40
            result.clearcoat_enabled=true
            result.clearcoat=0.11
            result.clearcoat_roughness=0.38
        "barrel":
            result.albedo_color=Color("#819399")
            result.metallic=0.76
            result.roughness=0.37
            result.clearcoat_enabled=true
            result.clearcoat=0.14
            result.clearcoat_roughness=0.37
        "hub":
            result.albedo_color=Color("#8e9fa1")
            result.metallic=0.75
            result.roughness=0.38
            result.clearcoat_enabled=true
            result.clearcoat=0.12
            result.clearcoat_roughness=0.41
    return result

static func apply(model:Node3D)->bool:
    if model==null or not bool(model.get_meta(V68.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var high:bool=bool(model.get_meta("tarvoka_g13_v1_high_detail",false))
    var pitch:=model.find_child(
        "G13_ElevacionCanones",true,false) as Node3D
    var turret:=model.find_child(
        "G13_TorretaAzimut",true,false) as Node3D
    if pitch==null or turret==null or pitch.get_parent()!=turret:
        return false
    var target:Dictionary={}
    var new_geo:Dictionary={}
    var kinds:Dictionary={}
    var barrel:=_barrel_mesh(high)
    var muzzle:=_muzzle_mesh(high)
    var n:int=HERO_SECTORS if high else ANDROID_SECTORS
    var vent_bands:int=2 if high else 1
    var expected_muzzle:int=32*n+8*vent_bands
    var expected_barrel:int=28*n
    if barrel==null or muzzle==null or (
            barrel.get_faces().size()!=expected_barrel*3) or (
            muzzle.get_faces().size()!=expected_muzzle*3):
        return false
    for side in [-1,1]:
        var gun_name:String="G13_Autocannon_%d" % side
        var muzzle_name:String="G13_RealMuzzle_%d" % side
        var gun:=model.find_child(
            gun_name,true,false) as MeshInstance3D
        var mouth:=model.find_child(
            muzzle_name,true,false) as MeshInstance3D
        if gun==null or mouth==null or (
                gun.get_parent()!=pitch or mouth.get_parent()!=pitch) or (
                not gun.mesh is CylinderMesh or
                not mouth.mesh is ArrayMesh) or (
                gun.rotation_degrees.distance_to(Vector3(90,0,0))>0.1 or
                mouth.rotation_degrees.distance_to(Vector3(90,0,0))>0.1):
            return false
        target[gun_name]=gun
        target[muzzle_name]=mouth
        kinds[gun_name]="barrel"
        kinds[muzzle_name]="muzzle"
        new_geo[gun_name]=barrel
        new_geo[muzzle_name]=muzzle
        if high:
            var hub_name:String=V19.MOBILE_HUB%side
            var hub:=model.find_child(
                hub_name,true,false) as MeshInstance3D
            if hub==null or hub.get_parent()!=pitch or (
                    not hub.mesh is CylinderMesh):
                return false
            target[hub_name]=hub
            kinds[hub_name]="hub"
            new_geo[hub_name]=_moving_hub()
    if high and _hub.get_faces().size()!=HUB_TRIANGLES*3:
        return false
    var before_mats:Dictionary={}
    var after_mats:Dictionary={}
    var before_mesh:Dictionary={}
    var poses:Dictionary={}
    for name in target:
        var part:=target[name] as MeshInstance3D
        var original:=part.material_override as StandardMaterial3D
        if original==null:
            return false
        before_mats[name]=original
        after_mats[name]=_coat(original,str(kinds[name]))
        before_mesh[name]=part.mesh
        poses[name]=part.transform
    for name in target:
        var part:=target[name] as MeshInstance3D
        part.mesh=new_geo[name]
        part.material_override=after_mats[name]
    model.set_meta(SAVED,{
        "before_coats":before_mats,"after_coats":after_mats,
        "before_meshes":before_mesh,"after_meshes":new_geo,
        "unchanged_transforms":poses})
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_g13_v69_muzzle_ports_per_gun",
        4 if high else 2)
    model.set_meta("tarvoka_g13_v69_hub_anchor_plates",
        GUN_COUNT if high else 0)
    model.set_meta("tarvoka_g13_v69_stepped_barrels",GUN_COUNT)
    model.set_meta("tarvoka_g13_v69_draw_nodes_added",DRAW_NODES_ADDED)
    model.set_meta("tarvoka_g13_v69_gun_count",GUN_COUNT)
    model.set_meta("tarvoka_g13_v69_missiles",0)
    model.set_meta("tarvoka_g13_v69_no_gameplay_changes",true)
    return true

static func show_finish(model:Node3D,enabled:bool)->bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var state:Dictionary=model.get_meta(SAVED,{})
    var coats:Dictionary=state.get(
        "after_coats",{}) if enabled else state.get("before_coats",{})
    var meshes:Dictionary=state.get(
        "after_meshes",{}) if enabled else state.get("before_meshes",{})
    var high:bool=bool(model.get_meta("tarvoka_g13_v1_high_detail",false))
    if coats.size()!=(6 if high else 4) or meshes.size()!=coats.size():
        return false
    for name in coats:
        var node:=model.find_child(str(name),true,false) as MeshInstance3D
        if node==null or node.get_parent()==null:
            return false
    for name in coats:
        var node:=model.find_child(str(name),true,false) as MeshInstance3D
        node.mesh=meshes[name]
        node.material_override=coats[name]
    model.set_meta("tarvoka_g13_v69_preview_enabled",enabled)
    return true
