extends SceneTree

# Physical V56 3D joint QA: eight official factions x hero and battle LOD.
# Validate real non-floating shock endpoints, the rotating turret collar
# and original 4x4 / two-autocannon rig across moving/aiming poses.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
var failures:int=0

func check(ok:bool,reason:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V56 physical joint QA: "+reason)

func count_new(model:Node3D)->int:
    var count:int=0
    for name in [V56.BODIES,V56.PISTONS,V56.PINS,V56.BEARING]:
        if model.find_child(name,true,false)!=null:
            count+=1
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero model exists for faction %d" % faction)
        if hero==null:
            continue
        check(bool(hero.get_meta(V55.FLAG,false)) and
            bool(hero.get_meta(V56.FLAG,false)),
            "V55 and V56 must be installed together")
        check(count_new(hero)==4,"exactly four real 3D mechanical draw nodes")
        check(int(hero.get_meta("tarvoka_g13_v56_added_draw_nodes",-1))==4,
            "GPU draw budget capped at four for hero geometry")
        var hull:=hero.find_child("G13_Casco4x4",true,false) as Node3D
        var turret:=hero.find_child("G13_TorretaAzimut",true,false) as Node3D
        var pitch:=hero.find_child("G13_ElevacionCanones",true,false) as Node3D
        var bodies:=hero.find_child(V56.BODIES,true,false) as MultiMeshInstance3D
        var pistons:=hero.find_child(V56.PISTONS,true,false) as MultiMeshInstance3D
        var pins:=hero.find_child(V56.PINS,true,false) as MultiMeshInstance3D
        var collar:=hero.find_child(V56.BEARING,true,false) as MeshInstance3D
        check(hull!=null and turret!=null and pitch!=null and
            bodies!=null and pistons!=null and pins!=null and collar!=null,
            "two independently animated parents and actual draw meshes")
        if bodies==null or pistons==null or pins==null or collar==null:
            hero.free()
            continue
        check(bodies.get_parent()==hull and pistons.get_parent()==hull and
            pins.get_parent()==hull and collar.get_parent()==turret,
            "hydraulics must remain on chassis; bearing follows azimuth")
        check(bodies.multimesh.instance_count==4 and
            pistons.multimesh.instance_count==4 and
            pins.multimesh.instance_count==8,
            "4 dampers and piston rods, 8 true pivot pins")
        check(bodies.multimesh.mesh is CylinderMesh and
            pistons.multimesh.mesh is CylinderMesh and
            pins.multimesh.mesh is SphereMesh and
            collar.mesh is TorusMesh,
            "native Cylinder/Sphere/Torus geometric surfaces")
        check(absf(collar.position.y-V56.TURRET_RING_Y)<0.001,
            "rotating bearing does not float high above pedestal")
        for side in [-1,1]:
            for axle in [-1,1]:
                var idx:int=(0 if side==-1 else 2)+(0 if axle==-1 else 1)
                var ends:Array[Vector3]=V56._damper_anchors(side,axle)
                var upper:Vector3=ends[0]
                var lower:Vector3=ends[1]
                var body:Transform3D=bodies.multimesh.get_instance_transform(idx)
                var rod:Transform3D=pistons.multimesh.get_instance_transform(idx)
                var top:Transform3D=pins.multimesh.get_instance_transform(idx*2)
                var bottom:Transform3D=pins.multimesh.get_instance_transform(idx*2+1)
                check(top.origin.distance_to(upper)<0.0001 and
                    bottom.origin.distance_to(lower)<0.0001,
                    "real pin ends must seat against existing V6 and V22 mounts")
                check(body.origin.distance_to(upper.lerp(lower,0.34))<0.0001
                    and rod.origin.distance_to(upper.lerp(lower,0.75))<0.0001,
                    "hydraulic body and rod truly share their anchor vector")
                var direction:Vector3=(lower-upper).normalized()
                check(body.basis.y.normalized().dot(direction)>0.999 and
                    rod.basis.y.normalized().dot(direction)>0.999,
                    "all four shocks must align to physical mount axes")
                check(maxf(absf(upper.x),absf(lower.x))<0.70 and
                    minf(upper.y,lower.y)>0.26,
                    "shock ends cannot hit original tire clearance")
        var original_turret_parent:Node=turret.get_parent()
        # The test model is deliberately built OFF-TREE so it cannot
        # claim a global_transform. The inherited turret-local transform
        # is still the true animated azimuth and can be checked directly.
        var initial_turret:Transform3D=turret.transform
        check(Models.pose_model("aa_mobile",hero,"aim_air",0.73,
            Vector2i(1,1)),
            "V56 turret bearing must survive original air aiming pose")
        check(turret.get_parent()==original_turret_parent and
            collar.get_parent()==turret,
            "azimuth motor and yaw parent never rewired")
        check(not turret.transform.is_equal_approx(initial_turret) and
            collar.get_parent()==turret and
            collar.transform.origin.is_equal_approx(
                Vector3(0,V56.TURRET_RING_Y,0)),
            "metal band physically follows inherited rotating azimuth")
        for mode in ["move","scan","attack_air","attack_ground"]:
            check(Models.pose_model("aa_mobile",hero,mode,0.43),
                "mechanical details survive approved pose "+mode)
        Models.restore_model_pose("aa_mobile",hero)
        check(count_new(hero)==4,"animation must not create extra meshes")
        check(V56.show_finish(hero,false) and not collar.visible and
            not bodies.visible,"historical V55 comparison hides new hardware")
        check(V56.show_finish(hero,true) and collar.visible and
            bodies.visible and pistons.visible and pins.visible,
            "V56 mechanical joints restore without extra GPU draw objects")
        var wheels:=hero.find_child(V54.TIRE,true,false) as MultiMeshInstance3D
        check(wheels!=null and wheels.multimesh.instance_count==4 and
            wheels.multimesh.mesh is ArrayMesh,
            "V54 rounded tire sculpture untouched")
        for side in [-1,1]:
            check(hero.find_child("G13_Autocannon_%d" % side,
                true,false)!=null,"exactly original twin autocannons retained")
        hero.free()
        var tactical:=Models.build("aa_mobile",faction,true,8)
        check(tactical!=null,"mobile LOD8 builds")
        if tactical!=null:
            check(count_new(tactical)==0 and
                not bool(tactical.get_meta(V56.FLAG,false)),
                "Android/battle LOD8 inherits zero mechanical detail cost")
            tactical.free()
    if failures==0:
        print("PASS G13 V56 MECHANICAL JOINTS: eight factions, 4 real dampers, 8 pins, true rotating turret bearing, reversible V55 comparison, original poses and Android LOD8 intact")
    quit(1 if failures>0 else 0)
