extends SceneTree

# G13 V22 actual Godot model review: close the flat-looking underbody.
# Eight factions, seven directions, both firing domains and full LOD8
# isolation. Existing axle/suspension/weapon pivots must be untouched.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Under=preload("res://scripts/ui/G13UnderbodyAuditV22.gd")
const V6=preload("res://scripts/ui/G13UndercarriageV6.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var errors:int=0

func check(ok:bool,detail:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V22 model audit: "+detail)

func _count(parent:Node)->int:
    var n:int=1 if parent is MeshInstance3D or (
        parent is MultiMeshInstance3D) else 0
    for child in parent.get_children():
        n+=_count(child)
    return n

func _vertices(mesh:Mesh)->PackedVector3Array:
    if not mesh is ArrayMesh:
        return PackedVector3Array()
    return (mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero for faction %d" % faction)
        if hero==null:
            continue
        var hull:=hero.find_child("G13_Casco4x4",
            true,false) as Node3D
        var wheels:=hero.find_child(G13.WHEELS,
            true,false) as MultiMeshInstance3D
        var turret:=hero.find_child(G13.TURRET,
            true,false) as Node3D
        var gun:=hero.find_child(G13.GUNS,
            true,false) as Node3D
        var radar:=hero.find_child(G13.RADAR,
            true,false) as Node3D
        check(bool(hero.get_meta(Under.FLAG,false)) and
            bool(hero.get_meta(V6.FLAG,false)),
            "V22 uses the real original V6 axles and G13 3D hull")
        check(int(hero.get_meta("tarvoka_g13_v22_sculpt_parts",0))==12 and
            int(hero.get_meta("tarvoka_g13_v22_batched_fasteners",0))==16,
            "12 new closed/instanced 3D objects and 16 shared bolts")
        check(str(hero.get_meta("tarvoka_g13_v22_weapon_identity",""))==
            "twin_autocannon_no_missiles",
            "2 original autocannons, absolutely no missile launchers")
        check(hull!=null and wheels!=null and turret!=null and
            gun!=null and radar!=null,
            "original hull, four wheels, two gun rig pivots and radar")
        if hull==null or wheels==null or turret==null or gun==null or radar==null:
            hero.free()
            continue
        for side in [-1,1]:
            for half in [-1,1]:
                var skid:=hull.find_child(Under.SKID % [side,half],
                    false,false) as MeshInstance3D
                check(skid!=null and skid.visible and (
                    skid.mesh is ArrayMesh),
                    "genuine closed segmented belly plate on each side")
                if skid!=null and skid.mesh is ArrayMesh:
                    var vertices:=_vertices(skid.mesh)
                    check(vertices.size()==180,
                        "real 4-ring 60-triangle closed chamfered floor plate")
                    var min_y:float=INF
                    var max_x:float=0.0
                    var z_min:float=INF
                    var z_max:float=-INF
                    for p in vertices:
                        min_y=minf(min_y,p.y)
                        max_x=maxf(max_x,absf(p.x))
                        z_min=minf(z_min,p.z)
                        z_max=maxf(z_max,p.z)
                    check(min_y>=0.337 and min_y<=0.339 and
                        max_x<=0.410 and z_min> -0.66 and (
                        z_max<0.66),
                        "plate emerges BELOW original 0.395 floor while clearing axles")
                var spring:=hull.find_child(Under.SPRING % [side,half],
                    false,false) as MeshInstance3D
                check(spring!=null and spring.visible and (
                    spring.mesh is ArrayMesh),
                    "each wheel has independently modeled sealed spring pack")
                if spring!=null and spring.mesh is ArrayMesh:
                    var vertices:=_vertices(spring.mesh)
                    check(vertices.size()==180,
                        "leaf springs have 4 chamfered sections and closed caps")
                    for p in vertices:
                        check(absf(p.x)<=0.612 and p.y>=0.287 and (
                            p.y<=0.337),
                            "spring stays below V6 frame and within wheel inner face")
            var diff:=hull.find_child(Under.DIFF % side,
                false,false) as MeshInstance3D
            check(diff!=null and diff.mesh is CylinderMesh and
                diff.visible and absf(diff.position.z-float(side)*0.85)<0.001,
                "front and rear diff covers are physically attached to V6 housings")
            if diff!=null and diff.mesh is CylinderMesh:
                check(absf((diff.mesh as CylinderMesh).top_radius-0.119)<0.001
                    and diff.position.y>0.20,
                    "differential caps protrude beneath existing box and clear road")
        var center:=hull.find_child(Under.SHAFT,false,false) as MeshInstance3D
        check(center!=null and center.visible and
            center.mesh is CylinderMesh and (
            center.get_parent()==hull),
            "native longitudinal center propeller shaft joins both axles")
        if center!=null and center.mesh is CylinderMesh:
            check(absf((center.mesh as CylinderMesh).height-1.56)<0.001
                and center.position.is_equal_approx(Vector3(0,0.295,0))
                and absf(center.rotation_degrees.x-90.0)<0.01,
                "longitudinal prop-shaft aligns along Z below chassis")
        var fasteners:=hull.find_child(Under.BOLTS,
            false,false) as MultiMeshInstance3D
        check(fasteners!=null and fasteners.multimesh!=null,
            "metallic real head fasteners in one GPU draw")
        if fasteners!=null and fasteners.multimesh!=null:
            check(fasteners.multimesh.instance_count==16,
                "16 physical skid bolts across four underbody plates")
        var wheel_axis:=hull.find_child("G13_V6_Axle_1",
            false,false) as MeshInstance3D
        check(wheel_axis!=null and wheel_axis.mesh is CylinderMesh and
            wheel_axis.position.is_equal_approx(
            Vector3(0,V6.AXLE_Y,V6.AXLE_Z)),
            "unaltered original axle transforms")
        var mesh_count:int=_count(hero)
        check(not Under.apply(hero),"V22 cannot accidentally duplicate geometry")
        check(_count(hero)==mesh_count,
            "repeated V22 install changes no mesh or draw count")
        check(Under.show_baseline(hero,true),
            "same-camera comparison can show exact earlier V21 underside")
        check(center!=null and not center.visible,
            "all new drivetrain objects temporarily hidden in V21 baseline")
        check(Under.show_baseline(hero,false),
            "restore all real V22 underbody sculptures")
        check(center!=null and center.visible,
            "new native drivetrain is visible again after comparison")
        for pose in ["idle","move","scan","aim_ground",
                "attack_ground","aim_air","attack_air"]:
            check(Models.pose_model("aa_mobile",hero,pose,0.45,
                Vector2i(1,0)),"preserve original animation "+pose)
            check(_count(hero)==mesh_count,
                "no runtime objects added to any animation")
            if pose=="aim_air":
                check(absf(gun.rotation_degrees.x-42.0)<0.01,
                    "both guns still reach approved 42-degree AA elevation")
            if pose=="scan":
                check(absf(radar.rotation_degrees.y+7.0)<0.1,
                    "radar still sweeps on independent pivot")
        Models.restore_model_pose("aa_mobile",hero)
        check(wheels.multimesh.instance_count==4,
            "all four original rotating tires retained")
        hero.free()
        var mobile:=Models.build("aa_mobile",faction,true,8)
        check(mobile!=null,"mobile tactical LOD8 still builds")
        if mobile!=null:
            check(not bool(mobile.get_meta(Under.FLAG,false)) and
                mobile.find_child(Under.SHAFT,true,false)==null and
                mobile.find_child(Under.SKID % [1,1],true,false)==null,
                "V22 adds zero triangles/meshes on Android mobile LOD8")
            mobile.free()
    if errors>0:
        quit(1)
        return
    print("PASS G13 V22: 8 factions, 12 actual underbody parts, 16 batched bolts, real prop shaft/diffs/springs, 7 original animations, 0 missiles, unchanged LOD8")
    quit(0)
