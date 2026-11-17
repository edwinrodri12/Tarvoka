extends SceneTree

const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V20=preload("res://scripts/ui/G13TurretArmorV20.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
var failed:int=0

func check(ok:bool,description:String)->void:
    if not ok:
        failed+=1
        push_error("G13 V20 sculpt audit: "+description)

func _vertices(node:MeshInstance3D)->PackedVector3Array:
    if node==null or not node.mesh is ArrayMesh:
        return PackedVector3Array()
    return (node.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func _mesh_count(root:Node)->int:
    var n:int=1 if root is MeshInstance3D or root is MultiMeshInstance3D else 0
    for child in root.get_children():
        n+=_mesh_count(child)
    return n

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero for faction %d builds" % faction)
        if hero==null:
            continue
        var hull:=hero.find_child("G13_Casco4x4",true,false) as Node3D
        var turret:=hero.find_child("G13_TorretaAzimut",true,false) as Node3D
        var gun:=hero.find_child("G13_ElevacionCanones",true,false) as Node3D
        var radar:=hero.find_child("G13_RadarAzimut",true,false) as Node3D
        check(hull!=null and turret!=null and gun!=null and radar!=null,
            "original 4x4 chassis / turret / cannon / independent radar")
        check(bool(hero.get_meta(V20.FLAG,false)) and
            bool(hero.get_meta(V19.FLAG,false)) and
            int(hero.get_meta("tarvoka_g13_v20_new_parts",0))==5,
            "five real V20 armored meshes installed after V19 bearings")
        check(int(hero.get_meta("tarvoka_g13_v20_missile_count",-1))==0
            and int(hero.get_meta("tarvoka_g13_v20_autocannon_count",0))==2,
            "no missile launchers and exactly two autocannons")
        if hull==null or turret==null or gun==null or radar==null:
            hero.free()
            continue
        var underside:=gun.find_child(V20.GUN_UNDERSHIELD,
            false,false) as MeshInstance3D
        check(underside!=null and underside.get_parent()==gun,
            "full belly shell follows actual weapon pitch, not static turret")
        if underside!=null:
            var points:=_vertices(underside)
            check(points.size()==60,"real closed six-side machined moving breech skirt")
            for pt in points:
                check(absf(pt.x)<=0.290 and pt.y<=-0.126 and (
                    pt.y>=-0.191),
                    "gun shield fits under receiver without covering muzzles")
            check(not underside.mesh is BoxMesh,
                "undershield is real sculpt, not a floating cube")
        for side in [-1,1]:
            var rear:=turret.find_child(V20.TURRET_AFT % side,
                false,false) as MeshInstance3D
            var saddle:=hull.find_child(V20.DECK_SADDLE % side,
                false,false) as MeshInstance3D
            check(rear!=null and saddle!=null,
                "both rotating aft turret shields and fixed pedestal saddles")
            if rear!=null:
                check(rear.get_parent()==turret,
                    "rear quarter shield follows azimuth but not pitch")
                var pts:=_vertices(rear)
                check(pts.size()==132,
                    "closed 3-profile armored turret quarter shell")
                for point in pts:
                    check(point.z>=0.184 and point.z<=0.426 and (
                        point.y<=0.230),
                        "aft quarter is behind V2 painted side emblem and top faction rail")
                    check(float(side)*point.x>0.44 and (
                        float(side)*point.x<0.63),
                        "aft armor narrow enough not to create side weapon pods")
            if saddle!=null:
                check(saddle.get_parent()==hull,
                    "deck saddle is fixed to the chassis, never spins with turret")
                var pts:=_vertices(saddle)
                check(pts.size()==132,
                    "closed 3-profile blended hull-to-pedestal gusset")
                for point in pts:
                    check(point.z>=0.419 and point.z<=0.816 and (
                        point.y>=1.08 and point.y<=1.24),
                        "pedestal gusset intersects deck and stays below turret ring")
        var original:int=_mesh_count(hero)
        check(not V20.apply(hero),
            "V20 art module cannot add duplicate armor on repeated calls")
        check(_mesh_count(hero)==original,
            "failed second application created zero unexpected geometry")
        for state in ["idle","move","aim_ground","attack_ground",
                "aim_air","attack_air","scan"]:
            check(Models.pose_model("aa_mobile",hero,state,0.42,
                Vector2i(1,0)),"original native animation "+state)
            check(_mesh_count(hero)==original,
                "no new meshes spawned while animating "+state)
            if state in ["aim_air","attack_air"]:
                check(gun.rotation_degrees.x>=35.0,
                    "moving underside rises with both cannons in air pose")
            if state in ["aim_ground","attack_ground"]:
                check(gun.rotation_degrees.x<=12.0,
                    "underplate stays with low ground weapon elevation")
            if state=="scan":
                check(absf(radar.rotation_degrees.y)>0.01,
                    "independent radar scan not obstructed")
        Models.restore_model_pose("aa_mobile",hero)
        hero.free()
        var mobile:=Models.build("aa_mobile",faction,true,8)
        check(mobile!=null,"LOD8 mobile faction still builds")
        if mobile!=null:
            check(not bool(mobile.get_meta(V20.FLAG,false)) and (
                mobile.find_child(V20.GUN_UNDERSHIELD,true,false)==null),
                "V20 adds no Android LOD8 geometry or runtime work")
            mobile.free()
    if failed>0:
        quit(1)
        return
    print("PASS G13 V20: 8 factions, 5 closed armor sculpts on correct hull/turret/pitch nodes, paint and gun clearance, ground+air+radar animations, 0 missiles, no Android LOD8 change")
    quit(0)
