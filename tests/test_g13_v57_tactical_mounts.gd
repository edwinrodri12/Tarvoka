extends SceneTree

# G13 V57 acceptance: actual, GPU-batched external mechanical anchoring.
# One GPU draw on Android LOD8, two on hero, wheel/faction/rig unchanged.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const V57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
var errors:int=0
var faction_paints:Dictionary={}

func check(ok:bool,message:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V57 tactical mount 3D: "+message)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"G13 faction %d LOD%d did not build" % [faction,lod])
            if model==null:
                continue
            var hero:bool=lod==13
            check(bool(model.get_meta(V57.FLAG,false)),
                "V57 installed in 3D LOD%d faction %d" % [lod,faction])
            check(int(model.get_meta("tarvoka_g13_v57_added_draw_nodes",-1))
                ==(2 if hero else 1),"mobile cost must be exactly one draw")
            var bracket:=model.find_child(V57.BRACKETS,
                true,false) as MultiMeshInstance3D
            var pins:=model.find_child(V57.PINS,
                true,false) as MultiMeshInstance3D
            var chassis:=model.find_child("G13_Casco4x4",true,false) as Node3D
            check(bracket!=null and chassis!=null,
                "V57 physical fender bracket batch parented to original hull")
            check((pins!=null)==hero,
                "bolts only for hero 13; not Android 8")
            check(bool(model.get_meta(V56.FLAG,false))==hero,
                "hero V56 shock hardware remains protected")
            if bracket!=null and bracket.multimesh!=null:
                var mm:MultiMesh=bracket.multimesh
                check(bracket.get_parent()==chassis and
                    mm.instance_count==8 and mm.mesh is ArrayMesh,
                    "eight sculpted closed steel brackets in one draw object")
                check(mm.mesh.get_faces().size()==20*3,
                    "closed 20-triangle chamfered mechanical plate shape")
                var steel:=bracket.material_override as StandardMaterial3D
                check(steel!=null and steel.metallic>=0.50,
                    "neutral alloy not fake faction color stickers")
                for side in [-1,1]:
                    for axle in [-1,1]:
                        for arm in range(2):
                            var idx:int=((0 if side==-1 else 2)+(
                                0 if axle==-1 else 1))*2+arm
                            var pose:Transform3D=mm.get_instance_transform(idx)
                            var relative:Vector3=pose.origin-Vector3(
                                0,V57.ARC_CENTER_Y,float(axle)*V57.AXLE_Z)
                            var radius:float=Vector2(relative.y,relative.z).length()
                            check(absf(radius-V57.ARC_RADIUS)<0.002,
                                "plate must physically follow V42 curved arch")
                            check(absf(absf(pose.origin.x)-V57.OUTER_X)<0.002,
                                "fender bracket seated on outer side, not floating")
                            check(pose.origin.y>0.53 and pose.origin.y<0.65,
                                "readable arched support limited to wheel shoulder")
                            check(absf(pose.basis.y.length()-1.0)<0.001,
                                "bracket has original tangent scale and contour")
                            check(radius-0.024-0.310>0.08,
                                "V54/V53 wheel radial motion clearance preserved")
                var first_pose:=mm.get_instance_transform(0)
                check(V57.show_finish(model,false) and not bracket.visible,
                    "same-camera V56 reference hides new visible mounts")
                check(V57.show_finish(model,true) and bracket.visible,
                    "restore readable external mounts without reassembly")
                if hero and pins!=null:
                    check(pins.multimesh.instance_count==8 and pins.visible,
                        "8 machined captive bolt caps restored in hero")
                check(Models.pose_model("aa_mobile",model,"move",0.51),
                    "V57 changes must not break original four-wheel roll")
                check(mm.get_instance_transform(0).is_equal_approx(first_pose),
                    "external body anchors cannot roll with wheels")
                check(Models.pose_model("aa_mobile",model,"aim_air",0.74,
                    Vector2i(1,0)),"original turret still rotates freely")
                check(mm.get_instance_transform(0).is_equal_approx(first_pose),
                    "external brackets do not rotate with turret")
                Models.restore_model_pose("aa_mobile",model)
            var paint:=model.find_child("G13_V44_SculptedFactionFlanks",
                true,false) as GeometryInstance3D
            if paint!=null:
                var mat:=paint.material_override as StandardMaterial3D
                if mat!=null:
                    faction_paints[mat.albedo_color.to_html()]=true
            for side in [-1,1]:
                check(model.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,
                    "approved twin autocannons and no missile additions")
            if hero:
                check(model.find_child(V54.TIRE,true,false)!=null,
                    "rounded V54 rubber wheels untouched in hero")
            else:
                check(model.find_child(V56.BEARING,true,false)==null,
                    "tactical Android still excludes heavy V56 details")
            model.free()
    check(faction_paints.size()==8,
        "eight official faction colors retained without re-painting")
    if errors==0:
        print("PASS G13 V57 TACTICAL MOUNTS: 8 factions, 8 physical brackets, one Android draw and 2 hero draws, tyre clearance, poses and original weaponry intact")
    quit(1 if errors>0 else 0)
