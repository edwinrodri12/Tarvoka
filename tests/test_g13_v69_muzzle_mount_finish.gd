extends SceneTree

# TARVOKA G13 V69 native Godot 4.3 verification: eight factions x
# Android LOD8 and HERO LOD13, actual hollow twin muzzle brake openings,
# turned-steel barrel chambers, and two captive moving trunnion hubs.
# No extra gun, missile, network logic, draw objects or new weapon rigs.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V69=preload("res://scripts/ui/G13MuzzleMountFinishV69.gd")
const V68=preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const V67=preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const V66=preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
var failures:int=0
var faction_enamel:Dictionary={}

func check(ok:bool,msg:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V69 native barrel and muzzle mesh: "+msg)

func _initialize()->void:
    call_deferred("_run")

func _has_real_colors(mesh:Mesh)->bool:
    if not mesh is ArrayMesh:
        return false
    var arrays:Array=(mesh as ArrayMesh).surface_get_arrays(0)
    var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var colors:PackedColorArray=arrays[Mesh.ARRAY_COLOR]
    if verts.size()<15 or colors.size()!=verts.size():
        return false
    var darkest:float=2.0
    var brightest:float=-1.0
    for c in colors:
        darkest=minf(darkest,c.r)
        brightest=maxf(brightest,c.r)
    return darkest<0.40 and brightest>0.70

func _max_axis(mesh:Mesh,axis:int)->float:
    var maxval:float=-999.0
    for p in mesh.get_faces():
        if axis==1:
            maxval=maxf(maxval,p.y)
        else:
            maxval=maxf(maxval,absf(p.x))
    return maxval

func _min_y(mesh:Mesh)->float:
    var low:float=999.0
    for p in mesh.get_faces():
        low=minf(low,p.y)
    return low

func _run()->void:
    check(V69.GUN_COUNT==2 and V69.DRAW_NODES_ADDED==0,
        "exact two original cannons and no new 3D GPU objects")
    for faction in range(8):
        for lod in [8,13]:
            var high:bool=lod==13
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"original G13 model built for faction/LOD")
            if model==null:
                continue
            check(bool(model.get_meta(V66.FLAG,false)) and
                bool(model.get_meta(V67.FLAG,false)) and
                bool(model.get_meta(V68.FLAG,false)) and
                bool(model.get_meta(V69.FLAG,false)),
                "new V69 real mouth and mounts layered after proven V66-68")
            check(int(model.get_meta(
                "tarvoka_g13_v69_draw_nodes_added",-1))==0 and
                int(model.get_meta(
                "tarvoka_g13_v69_gun_count",-1))==2 and
                int(model.get_meta(
                "tarvoka_g13_v69_missiles",-1))==0,
                "no new launcher, no missiles, no new render batches")
            check(int(model.get_meta(
                "tarvoka_g13_v69_muzzle_ports_per_gun",-1))==(
                4 if high else 2),"two lateral openings per vent band")
            check(int(model.get_meta(
                "tarvoka_g13_v69_hub_anchor_plates",-1))==(
                2 if high else 0),"hero outer hub plates, low-cost LOD8")
            var pitch:=model.find_child(
                "G13_ElevacionCanones",true,false) as Node3D
            var turret:=model.find_child(
                "G13_TorretaAzimut",true,false) as Node3D
            check(pitch!=null and turret!=null and
                pitch.get_parent()==turret,
                "unchanged original azimuth and gun elevation pivots")
            var resources:Dictionary=model.get_meta(V69.SAVED,{})
            var before:Dictionary=resources.get("before_meshes",{})
            var after:Dictionary=resources.get("after_meshes",{})
            var before_pbr:Dictionary=resources.get("before_coats",{})
            var after_pbr:Dictionary=resources.get("after_coats",{})
            var poses:Dictionary=resources.get("unchanged_transforms",{})
            check(before.size()==(6 if high else 4) and
                after.size()==before.size() and
                before_pbr.size()==before.size() and
                after_pbr.size()==before.size() and
                poses.size()==before.size(),
                "all existing cannon meshes and PBR originals preserved")
            var sides:Array=[-1,1]
            for side in sides:
                var gun_name:String="G13_Autocannon_%d" % side
                var mouth_name:String="G13_RealMuzzle_%d" % side
                var barrel:=model.find_child(
                    gun_name,true,false) as MeshInstance3D
                var muzzle:=model.find_child(
                    mouth_name,true,false) as MeshInstance3D
                check(barrel!=null and muzzle!=null,
                    "two existing barrel and muzzle nodes still present")
                if barrel==null or muzzle==null:
                    continue
                check(barrel.get_parent()==pitch and
                    muzzle.get_parent()==pitch and
                    barrel.mesh==after.get(gun_name) and
                    muzzle.mesh==after.get(mouth_name),
                    "same native moving gun nodes draw new 3D geometry")
                check(before.get(gun_name) is CylinderMesh and
                    before.get(mouth_name) is ArrayMesh,
                    "the previous real V68 barrel and muzzle meshes saved")
                check(barrel.transform.is_equal_approx(poses[gun_name]) and
                    muzzle.transform.is_equal_approx(poses[mouth_name]),
                    "actual barrel/muzzle rotation and muzzle-flash alignment")
                var sectors:int=(
                    V69.HERO_SECTORS if high else V69.ANDROID_SECTORS)
                var bands:int=2 if high else 1
                check(barrel.mesh.get_faces().size()==28*sectors*3,
                    "12-step true 3D turned-steel barrel with recessed bore")
                check(muzzle.mesh.get_faces().size()==(
                    32*sectors+8*bands)*3,
                    "open two-sided ported muzzle brake, not dark fake slots")
                check(absf(_min_y(barrel.mesh)+0.55)<0.0001 and
                    absf(_max_axis(barrel.mesh,1)-0.55)<0.0001,
                    "original full 1.10m barrel length stays unchanged")
                check(absf(_min_y(muzzle.mesh)+0.0425)<0.0001 and
                    absf(_max_axis(muzzle.mesh,1)-0.0425)<0.0001,
                    "original 0.085m muzzle length and barrel overlap")
                check(_has_real_colors(barrel.mesh) and
                    _has_real_colors(muzzle.mesh),
                    "physical bore / exterior directional PBR face shading")
                var barrel_coat:=after_pbr.get(gun_name) as StandardMaterial3D
                var muzzle_coat:=after_pbr.get(mouth_name) as StandardMaterial3D
                check(barrel_coat!=null and muzzle_coat!=null and
                    barrel_coat.vertex_color_use_as_albedo and
                    muzzle_coat.vertex_color_use_as_albedo and
                    barrel_coat.metallic>0.7 and muzzle_coat.metallic>0.7,
                    "satin gun steel and dark internal brake")
                var muzzle_flash:=model.find_child(
                    "G13_MuzzleFlash_%d" % side,true,false) as Node3D
                check(muzzle_flash!=null and
                    muzzle_flash.get_parent()==pitch,
                    "all original 3D firing flash anchors remain intact")
                if high:
                    var hub_name:String=V19.MOBILE_HUB%side
                    var hub:=model.find_child(
                        hub_name,true,false) as MeshInstance3D
                    check(hub!=null and hub.get_parent()==pitch and
                        hub.mesh==after.get(hub_name),
                        "hero mobile mount follows existing pitch pivot")
                    if hub!=null:
                        check(before.get(hub_name) is CylinderMesh and
                            hub.mesh.get_faces().size()==(
                            V69.HUB_TRIANGLES*3),
                            "12-sided captive bolt seat replaces same two hubs")
                        check(_has_real_colors(hub.mesh) and
                            hub.transform.is_equal_approx(poses[hub_name]),
                            "machined hub recess and original rig positions")
            var paint:=model.find_child(
                "G13_TurretFaction_1",true,false) as MeshInstance3D
            if paint!=null:
                var material:=paint.material_override as StandardMaterial3D
                if material!=null:
                    faction_enamel[material.albedo_color.to_html()]=true
            check(Models.pose_model("aa_mobile",model,"aim_air",0.70,
                Vector2i(1,1)),"original twin barrel pitch and azimuth pose")
            Models.restore_model_pose("aa_mobile",model)
            check(V69.show_finish(model,false),
                "reversible genuine V68 barrel and muzzle comparison")
            for name in before:
                var part:=model.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(part.mesh==before[name] and
                    part.material_override==before_pbr[name] and
                    part.transform.is_equal_approx(poses[name]),
                    "same instance restores exact original geometry, PBR and pose")
            check(V69.show_finish(model,true),
                "restore the latest V69 physically vented muzzle brake")
            for name in after:
                var part:=model.find_child(str(name),true,false
                    ) as MeshInstance3D
                check(part.mesh==after[name] and
                    part.material_override==after_pbr[name],
                    "latest complete hard-surface finish reactivates")
            model.free()
    check(faction_enamel.size()==8,
        "all eight original faction identities remain distinct")
    if failures==0:
        print("PASS G13 V69 REAL PORTED MUZZLES: 8 factions x LOD8/13, two open steel muzzle brakes, 12-step twin barrels, two captive hero hubs, zero new draw nodes, original animations and exact restore")
    quit(1 if failures>0 else 0)
