extends SceneTree

# Final G13 approved weapon identity: twin recoil-capable autocannons,
# native open muzzles, independent radar. No missile launcher at any angle.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Sculpt=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V12=preload("res://scripts/ui/G13MechanicalFinishV12.gd")
var failures:int=0

func check(ok:bool,detail:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V18 twin cannon: "+detail)

func _weapon_mesh_names(root:Node)->Array[String]:
    var names:Array[String]=[]
    if root is MeshInstance3D or root is MultiMeshInstance3D:
        names.append(root.name)
    for child in root.get_children():
        names.append_array(_weapon_mesh_names(child))
    return names

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"build approved 3D hero for faction %d" % faction)
        if hero==null:
            continue
        check(bool(hero.get_meta(Sculpt.FLAG,false)),
            "V18 sculpt installed on the production hero")
        check(str(hero.get_meta("tarvoka_g13_v18_weapon_configuration",""))==
            Sculpt.CONFIG and int(hero.get_meta(
            "tarvoka_g13_v18_autocannon_count",0))==2 and (
            int(hero.get_meta("tarvoka_g13_v18_launcher_count",-1))==0),
            "only two cannon barrels, zero rocket or missile launchers")
        var pivot:=hero.find_child("G13_ElevacionCanones",true,false) as Node3D
        var turret:=hero.find_child("G13_TorretaAzimut",true,false) as Node3D
        var radar:=hero.find_child("G13_RadarAzimut",true,false) as Node3D
        var receiver:=hero.find_child(Sculpt.RECEIVER,
            true,false) as MeshInstance3D
        check(pivot!=null and turret!=null and radar!=null,
            "original gun elevation, turret yaw, independent scanning radar")
        check(receiver!=null and receiver.mesh is ArrayMesh and (
            receiver.get_parent()==pivot),
            "original box missile-pack-looking receiver replaced in place by beveled sealed sculpt")
        if receiver!=null and receiver.mesh is ArrayMesh:
            var a:Array=receiver.mesh.surface_get_arrays(0)
            var corners:PackedVector3Array=a[Mesh.ARRAY_VERTEX]
            check(corners.size()>=140 and corners.size()<=185,
                "genuine four-section faceted closed breech topology")
            var smallest:float=INF
            var biggest:float=-INF
            for pt in corners:
                smallest=minf(smallest,pt.z)
                biggest=maxf(biggest,pt.z)
            check(smallest< -0.25 and biggest>0.26,
                "new receiver preserves barrel emergence and aft shoulder depth")
        for side in [-1,1]:
            var cannon:=hero.find_child("G13_Autocannon_%d" % side,
                true,false) as MeshInstance3D
            var muzzle:=hero.find_child("G13_RealMuzzle_%d" % side,
                true,false) as MeshInstance3D
            var collar:=hero.find_child(Sculpt.COLLAR % side,
                true,false) as MeshInstance3D
            var eject:=hero.find_child(Sculpt.EJECTION % side,
                true,false) as MeshInstance3D
            var feed:=hero.find_child(Sculpt.FEED % side,
                true,false) as MeshInstance3D
            check(cannon!=null and muzzle!=null and collar!=null and
                eject!=null and feed!=null,
                "two authentic cannon breeches, feed slots, clamps, and muzzle bores")
            if cannon!=null and muzzle!=null and collar!=null and (
                    eject!=null and feed!=null):
                check(cannon.get_parent()==pivot and muzzle.get_parent()==pivot
                    and collar.get_parent()==pivot and eject.get_parent()==pivot
                    and feed.get_parent()==pivot,
                    "all modeled cannon hardware follows original pitch pivot")
                check(muzzle.mesh is ArrayMesh,
                    "V12 hollow muzzle retained; never replaced by missile tip")
                check(cannon.mesh is CylinderMesh and (
                    (cannon.mesh as CylinderMesh).top_radius<=0.065),
                    "authentic thin cannon barrel, not a launcher tube")
                check(collar.mesh is CylinderMesh and (
                    absf((collar.mesh as CylinderMesh).top_radius-0.075)<0.001),
                    "short support collar wraps each cannon, not a missile cell")
        var fasteners:=hero.find_child(Sculpt.RIVETS,
            true,false) as MultiMeshInstance3D
        check(fasteners!=null and fasteners.multimesh!=null and (
            fasteners.multimesh.instance_count==4),
            "four metal fasteners grouped into one real native GPU instance")
        for name in _weapon_mesh_names(hero):
            var lower:=name.to_lower()
            check(not ("missile" in lower or "rocket" in lower or
                "launcher" in lower or "lanzamisil" in lower or
                "sam_tube" in lower),
                "no physical part ever named as a rocket or missile launcher: "+name)
        var before_count:int=Models.inspect_meshes(hero)
        check(not Sculpt.apply(hero),
            "cannot accidentally add a second receiver or weapon pod")
        check(Models.inspect_meshes(hero)==before_count,
            "no duplicate geometry on repeated call")
        for pose in ["move","scan","aim_air","attack_air",
                "aim_ground","attack_ground"]:
            check(Models.pose_model("aa_mobile",hero,pose,0.42,
                Vector2i(1,0)),"preserve original motion "+pose)
            check(Models.inspect_meshes(hero)==before_count,
                "no spawned missile meshes or geometry during "+pose)
            if pose in ["attack_air","attack_ground"]:
                check(pivot.rotation_degrees.x>0.0,
                    "both domains still pitch the real two cannons")
        Models.restore_model_pose("aa_mobile",hero)
        hero.free()
        var light:=Models.build("aa_mobile",faction,true,8)
        check(light!=null,"LOD8 lightweight mobile G13 build")
        if light!=null:
            check(not bool(light.get_meta(Sculpt.FLAG,false)) and
                light.find_child(Sculpt.RIVETS,true,false)==null,
                "no added V18 art cost on Android LOD8")
            var simple:=light.find_child(Sculpt.RECEIVER,true,false) as MeshInstance3D
            check(simple!=null and simple.mesh is BoxMesh,
                "LOD8 unchanged original tactical silhouette")
            light.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V18: 8 faction hero sculptures, twin real autocannon bores, 0 missile launchers, physically faceted gun breech, 4 batched bolts, full animations and unchanged Android LOD8")
    quit(0)
