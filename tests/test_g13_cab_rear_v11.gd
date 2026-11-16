extends SceneTree

# G13 V11 proof: two fully closed roof shoulder seams, gasket guards and a
# tapered tail that does not cover rear lamps/service door or affect LOD8.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const V11=preload("res://scripts/ui/G13CabRearFinishV11.gd")
var failures:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failures+=1
        push_error("G13 V11 roof/rear: "+why)

func mesh_part(root: Node,name: String)->MeshInstance3D:
    return root.find_child(name,true,false) as MeshInstance3D

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var palette: Dictionary={}
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero model for faction %d" % faction)
        if hero==null:
            continue
        check(bool(hero.get_meta(V11.FLAG,false)),
            "V11 only installed on high quality G13")
        var roof:=mesh_part(hero,"G13_CabRoof")
        var rear_door:=mesh_part(hero,"G13_RearServiceDoor")
        var rear:=mesh_part(hero,V11.REAR_DECK)
        var rear_seal:=mesh_part(hero,V11.REAR_LIP)
        check(roof!=null and rear_door!=null and rear!=null and
            rear_seal!=null,"roof/tailgate kept and tapered deck added")
        if roof!=null and rear_door!=null and rear!=null:
            var roof_lower: float=roof.position.y-(
                roof.mesh as BoxMesh).size.y*0.5
            var roof_front: float=roof.position.z-(
                roof.mesh as BoxMesh).size.z*0.5
            var roof_back: float=roof.position.z+(
                roof.mesh as BoxMesh).size.z*0.5
            check(V11.ROOF_Z_START>roof_front and
                V11.ROOF_Z_END<roof_back,
                "roof transitions never protrude past original roof ends")
            var end_z: float=rear.mesh.get_aabb().end.z
            var door_start: float=rear_door.position.z-(
                rear_door.mesh as BoxMesh).size.z*0.5
            check(end_z<door_start and end_z>1.20,
                "rear deck ends behind engine cover, before rear service door")
            check(rear.mesh is ArrayMesh and
                rear.mesh.get_aabb().size.y>0.24,
                "rear end genuinely tapers in three dimensions")
            check(rear_door.position.is_equal_approx(
                Vector3(0,0.94,1.278)),
                "original rear service door stays in approved position")
            for side in [-1,1]:
                var shoulder:=mesh_part(hero,V11.ROOF_SHOULDER % side)
                var gasket:=mesh_part(hero,V11.ROOF_GASKET % side)
                var guard:=mesh_part(hero,V11.REAR_GUARD % side)
                var lamp:=mesh_part(hero,"G13_V2_RearLamp_%d" % side)
                check(shoulder!=null and gasket!=null and guard!=null
                    and lamp!=null,"both sealed roof/rear assemblies and lamps exist")
                if shoulder!=null and gasket!=null and guard!=null and lamp!=null:
                    var aabb: AABB=shoulder.mesh.get_aabb()
                    check(shoulder.mesh is ArrayMesh and
                        aabb.position.y<roof_lower and
                        aabb.end.y>roof_lower+0.02,
                        "shoulder physically overlaps roof lower face")
                    check(aabb.position.z>=V11.ROOF_Z_START-0.0001 and
                        aabb.end.z<=V11.ROOF_Z_END+0.0001,
                        "shoulder meshes have no longitudinal overshoot")
                    check(absf(gasket.position.x)>0.64 and
                        gasket.position.y>roof_lower,
                        "gasket is visible along original roof outside edge")
                    check(guard.position.y-
                        (guard.mesh as BoxMesh).size.y*0.5>
                        lamp.position.y+0.015,
                        "rear sculpting keeps red rear lamps unobstructed")
        var painted:=mesh_part(hero,"G13_SideEnamel_1")
        check(painted!=null,"original faction identity remains visible")
        if painted!=null:
            var material:=painted.material_override as StandardMaterial3D
            if material!=null:
                palette[material.albedo_color.to_html()]=true
        var original_mesh_count: int=Models.inspect_meshes(hero)
        check(not V11.install(hero),
            "second installation must not duplicate roof or rear meshes")
        check(Models.inspect_meshes(hero)==original_mesh_count,
            "V11 installation is idempotent")
        for mode in ["move","scan","aim_air","attack_air",
                "aim_ground","attack_ground"]:
            check(Models.pose_model("aa_mobile",hero,mode,0.42),
                "unchanged G13 animation: "+mode)
        Models.restore_model_pose("aa_mobile",hero)
        check(Models.inspect_meshes(hero)==original_mesh_count,
            "animations cannot add or delete V11 geometry")
        var tires:=hero.find_child(G13.WHEELS,true,false) as MultiMeshInstance3D
        check(tires!=null and tires.multimesh.instance_count==4,
            "four GPU instanced tires remain unchanged")
        hero.free()
        var low:=Models.build("aa_mobile",faction,true,8)
        check(low!=null,"LOD8 still builds for faction %d" % faction)
        if low!=null:
            check(not bool(low.get_meta(V11.FLAG,false)) and
                low.find_child(V11.REAR_DECK,true,false)==null,
                "V11 never increases tactical LOD8 draw calls")
            low.free()
    check(palette.size()==8,"all 8 approved faction colors remain distinct")
    if failures>0:
        quit(1)
        return
    print("PASS G13 V11: 8 factions, closed roof seals, tapered rear, visible lamps, reversible poses, LOD8 untouched")
    quit(0)
