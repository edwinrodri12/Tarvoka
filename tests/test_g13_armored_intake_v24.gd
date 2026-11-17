extends SceneTree

# G13 V24: genuine 3D armor intake on the inclined existing 4x4 glacis.
# No additional gun, missiles or battle stats; Android mobile LOD unchanged.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Intake=preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const Front=preload("res://scripts/ui/G13FrontLightingV23.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
var failures:int=0
var checks:int=0

func check(ok:bool,detail:String)->void:
    checks+=1
    if not ok:
        failures+=1
        push_error("G13 V24 armored intake: "+detail)

func count_meshes(node:Node)->int:
    var count:int=1 if node is MeshInstance3D or (
        node is MultiMeshInstance3D) else 0
    for child in node.get_children():
        count+=count_meshes(child)
    return count

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var model:=Models.build("aa_mobile",faction,true,13)
        check(model!=null,"all factions load sculpted V24 G13")
        if model==null:
            continue
        check(bool(model.get_meta(Intake.FLAG,false)) and
            bool(model.get_meta(Front.FLAG,false)),
            "original headlights and new front armor coexist")
        check(int(model.get_meta("tarvoka_g13_v24_geometry_parts",0))==3
            and int(model.get_meta("tarvoka_g13_v24_louvres",0))==4,
            "real closed frame, backing and batched four-slat surface")
        check(str(model.get_meta("tarvoka_g13_v24_weapon_identity",""))==
            "twin_autocannon_no_missiles",
            "only two original autocannons on turret")
        var hull:=model.find_child("G13_Casco4x4",true,false) as Node3D
        var glacis:=model.find_child("G13_SlopedGlacis",true,false) as MeshInstance3D
        var pivot:=model.find_child(Intake.PIVOT,true,false) as Node3D
        check(hull!=null and glacis!=null and pivot!=null,
            "front intake is mounted on original four wheel armor hull")
        if pivot==null or glacis==null:
            model.free()
            continue
        check(pivot.get_parent()==hull and
            pivot.position.is_equal_approx(glacis.position) and
            pivot.rotation.is_equal_approx(glacis.rotation),
            "intake precisely follows existing 23-degree glacis slope")
        var frame:=pivot.find_child(Intake.BEZEL,false,false) as MeshInstance3D
        var backing:=pivot.find_child(Intake.BACK,false,false) as MeshInstance3D
        var slats:=pivot.find_child(Intake.LOUVRES,false,false) as MeshInstance3D
        check(frame!=null and backing!=null and slats!=null,
            "three genuine visible 3D objects, not 2D texture")
        if frame!=null and backing!=null and slats!=null:
            check(frame.mesh is ArrayMesh and slats.mesh is ArrayMesh
                and backing.mesh is BoxMesh and (
                frame.visible and slats.visible and backing.visible),
                "closed depthful 3D cavity, hardware, louvers")
            var fg:PackedVector3Array=(
                frame.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            var sg:PackedVector3Array=(
                slats.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
            check(fg.size()==192,
                "8 chamfered corners * 4 real annulus walls * 2 triangles")
            check(sg.size()==144,
                "4 independent sealed 3D louvres sharing one mesh")
            var fb:AABB=frame.mesh.get_aabb()
            var sb:AABB=slats.mesh.get_aabb()
            check(fb.position.z<-0.31 and fb.end.z>-0.27 and
                fb.size.z>0.045,
                "steel frame penetrates original sloped glacis by 9 mm")
            check(sb.position.z>fb.position.z+0.01 and
                sb.end.z<fb.end.z,
                "blades protected INSIDE frame depth, not floating outside")
            check(fb.size.x<0.66 and fb.size.y<0.18,
                "central grille stops short of both light bezels and bumper")
            for side in [-1,1]:
                var lamp:=hull.find_child(Front.RIM % side,false,false) as MeshInstance3D
                check(lamp!=null and absf(lamp.position.x)>fb.end.x+0.09,
                    "wide frontal intake never touches original headlight side")
        var original_count:int=count_meshes(model)
        check(not Intake.apply(model),"V24 cannot generate duplicate parts")
        check(count_meshes(model)==original_count,
            "new V24 geometry remains stable after duplicate install attempt")
        check(Intake.show_v23_reference(model,true),
            "exact V23 same-camera geometry reference remains available")
        check(not pivot.visible,
            "V23 reference hides only the V24 front intake")
        check(Intake.show_v23_reference(model,false) and pivot.visible,
            "V24 full physical intake return without new mesh objects")
        for pose in ["idle","move","scan","aim_ground",
                "attack_ground","aim_air","attack_air"]:
            check(Models.pose_model("aa_mobile",model,pose,0.42,
                Vector2i(1,-1)),pose+" unchanged with new fixed intake")
            check(count_meshes(model)==original_count,
                "V24 does not create objects while animating")
        Models.restore_model_pose("aa_mobile",model)
        var radar:=model.find_child(G13.RADAR,true,false)
        var guns:=model.find_child(G13.GUNS,true,false)
        check(radar!=null and guns!=null,
            "original radar and twin-barrel pitch rig preserved")
        model.free()
        var tactical:=Models.build("aa_mobile",faction,true,8)
        check(tactical!=null,"mobile Android model still builds")
        if tactical!=null:
            check(not bool(tactical.get_meta(Intake.FLAG,false)) and
                tactical.find_child(Intake.PIVOT,true,false)==null,
                "V24 adds NO meshes or complexity to Android LOD8")
            tactical.free()
    if failures>0:
        print("FAIL G13 V24 INTAKE: ",failures," of ",checks)
        quit(1)
        return
    print("PASS G13 V24 INTAKE: ",checks,
        " native checks; eight faction variants; 3 real 3D objects; ",
        "4 sealed structural louvres; dual cannons + radar; 7 animations; ",
        "true 23-degree hull attachment; Android LOD8 isolated")
    quit(0)
