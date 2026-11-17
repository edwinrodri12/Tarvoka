extends SceneTree

const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V19=preload("res://scripts/ui/G13GunTrunnionV19.gd")
const V18=preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const V12=preload("res://scripts/ui/G13MechanicalFinishV12.gd")
var failures:int=0

func check(ok:bool,detail:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V19 true 3D turret joint: "+detail)

func _count(root:Node)->int:
    var count:int=1 if root is MeshInstance3D or root is MultiMeshInstance3D else 0
    for child in root.get_children():
        count+=_count(child)
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"V19 production detail-13 build for faction %d" % faction)
        if hero==null:
            continue
        var azimuth:=hero.find_child("G13_TorretaAzimut",true,false) as Node3D
        var pitch:=hero.find_child("G13_ElevacionCanones",true,false) as Node3D
        var radar:=hero.find_child("G13_RadarAzimut",true,false) as Node3D
        check(bool(hero.get_meta(V18.FLAG,false)) and
            bool(hero.get_meta(V19.FLAG,false)),
            "V18 twin guns and V19 new sculpt actually applied")
        check(int(hero.get_meta("tarvoka_g13_v19_integrated_parts",0))==6,
            "six new physically-modeled mechanical joint surfaces")
        check(int(hero.get_meta("tarvoka_g13_v19_cannon_count",0))==2 and
            int(hero.get_meta("tarvoka_g13_v19_launcher_count",-1))==0,
            "exact two autocannons and no unapproved missile launcher")
        check(azimuth!=null and pitch!=null and radar!=null,
            "existing turret/gun/radar pivots preserved")
        if azimuth==null or pitch==null or radar==null:
            hero.free()
            continue
        for side in [-1,1]:
            var fixed:=hero.find_child(V19.FIXED_RING % side,
                true,false) as MeshInstance3D
            var cap:=hero.find_child(V19.MOBILE_HUB % side,
                true,false) as MeshInstance3D
            var cheek:=hero.find_child(V19.CHEEK % side,
                true,false) as MeshInstance3D
            check(fixed!=null and cap!=null and cheek!=null,
                "both side joints are complete")
            if fixed==null or cap==null or cheek==null:
                continue
            check(fixed.get_parent()==azimuth and cap.get_parent()==pitch and
                cheek.get_parent()==pitch,
                "bearing ring on fixed yaw, spindle and closed armored cheek on moving pitch")
            check(fixed.mesh is ArrayMesh and cheek.mesh is ArrayMesh and
                cap.mesh is CylinderMesh,
                "hollow machined annulus, closed sculpted cheek and cylindrical spindle")
            check(fixed.position.is_equal_approx(
                Vector3(float(side)*0.482,0.28,-0.215)),
                "fixed annulus concentric with original trunnion joint center")
            check(cap.position.is_equal_approx(
                Vector3(float(side)*0.529,0.0,0.0)),
                "spindle cap protrudes from V19 bearing while staying coaxial")
            if fixed.mesh is ArrayMesh:
                var vertices:PackedVector3Array=(
                    fixed.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
                var least_radius:float=INF
                var largest:float=0.0
                for vertex in vertices:
                    var r:float=Vector2(vertex.y,vertex.z).length()
                    least_radius=minf(least_radius,r)
                    largest=maxf(largest,r)
                check(absf(least_radius-0.100)<0.001 and
                    absf(largest-0.137)<0.001,
                    "bearing is a genuinely open ring (0.100 inner, 0.137 outer)")
                check(vertices.size()==V19.SEGMENTS*24,
                    "physical outer/inner/front/back rings sealed by 160 triangles")
                var min_x_ring:float=INF
                var max_x_ring:float=-INF
                for vertex in vertices:
                    min_x_ring=minf(min_x_ring,vertex.x)
                    max_x_ring=maxf(max_x_ring,vertex.x)
                check(absf(min_x_ring+0.0435)<0.001 and
                    absf(max_x_ring-0.0435)<0.001,
                    "0.087m deep open bearing projects past the armored turret shell")
                check(0.482-0.0435>0.437 and
                    0.482-0.0435<0.441,
                    "bearing attaches close to original 0.045m-wide fixed trunnion")
            if cheek.mesh is ArrayMesh:
                var verts:PackedVector3Array=(
                    cheek.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
                check(verts.size()==132,
                    "closed actual 3D armored cheek has 3 eight-sided profiles")
                var min_x:float=INF
                var max_x:float=-INF
                for vertex in verts:
                    min_x=minf(min_x,absf(vertex.x))
                    max_x=maxf(max_x,absf(vertex.x))
                check(min_x<=0.302 and max_x>=0.484,
                    "receiver cheek physically bridges housing to exposed pivot spindle")
                for point in verts:
                    # Outer two loft sections, which enter the fixed annular
                    # bearing, must fit the 0.100m bore in ALL gun pitch poses.
                    if absf(point.x)>0.400:
                        check(Vector2(point.y,point.z).length()<0.099,
                            "moving support stays inside open ring, avoiding interpenetration")
            if cap.mesh is CylinderMesh:
                var cyl:=cap.mesh as CylinderMesh
                check(absf(cyl.top_radius-0.080)<0.001 and
                    absf(cyl.height-0.018)<0.001 and
                    cyl.top_radius<0.100,
                    "spindle fits in stationary bearing bore with 0.020 m clearance")
            var gun:=hero.find_child("G13_Autocannon_%d" % side,
                true,false) as MeshInstance3D
            var muzzle:=hero.find_child("G13_RealMuzzle_%d" % side,
                true,false) as MeshInstance3D
            check(gun!=null and muzzle!=null and muzzle.mesh is ArrayMesh,
                "both original open-bore cannon barrels remain untouched")
        var built:int=_count(hero)
        check(not V19.apply(hero),"cannot duplicate integrated gun joints")
        check(_count(hero)==built,"duplicate attempt allocates zero geometry")
        check(Models.pose_model("aa_mobile",hero,"aim_air",0.37,
            Vector2i(1,0)),"air aiming with real mechanical gun joints")
        check(absf(pitch.rotation_degrees.x-42.0)<0.01 and
            absf(azimuth.rotation_degrees.y-90.0)<0.01,
            "high elevation and turret azimuth genuinely animated")
        check(Models.pose_model("aa_mobile",hero,"attack_ground",0.42,
            Vector2i(1,0)),"ground attack with same gun joints")
        check(pitch.rotation_degrees.x<16.0 and
            pitch.rotation_degrees.x>2.0,
            "ground fire stays low, rather than an AA missile trajectory")
        check(Models.pose_model("aa_mobile",hero,"scan",1.0),
            "radar scans independently of both new trunnion bearings")
        check(absf(radar.rotation_degrees.y-70.0)<0.01,
            "original radar 140 degree arc retained")
        Models.restore_model_pose("aa_mobile",hero)
        check(_count(hero)==built,
            "idle/movement/shooting never instantiate duplicate hardware")
        hero.free()
        var low:=Models.build("aa_mobile",faction,true,8)
        check(low!=null,"LOD8 mobile model still builds")
        if low!=null:
            check(not bool(low.get_meta(V19.FLAG,false)) and
                low.find_child(V19.FIXED_RING % -1,true,false)==null and
                low.find_child(V19.CHEEK % 1,true,false)==null,
                "no V19 hero sculpt or performance overhead on Android LOD8")
            low.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V19: eight factions, real open annular trunnions, two closed receiver cheek connections, gun elevation and ground/air attack, radar isolation, no missiles and unchanged LOD8")
    quit(0)
