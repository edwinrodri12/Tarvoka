extends SceneTree

# G13 V58 regression: native Godot hero and lightweight Android materials.
# 8 factions, reversible native resources and rig invariants. No fake mesh.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
const V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const V56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const V57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const V58=preload("res://scripts/ui/G13IsometricMechanicalFinishV58.gd")
var failures:int=0
var enamel_colors:Dictionary={}

func check(ok:bool,message:String)->void:
    if not ok:
        failures+=1
        push_error("G13 V58 isometric native QA: "+message)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        for lod in [8,13]:
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"faction %d LOD%d model exists" % [faction,lod])
            if model==null:
                continue
            var high:bool=lod==13
            check(bool(model.get_meta(V58.FLAG,false)) and
                bool(model.get_meta(V57.FLAG,false)),
                "finish V58 on original V57 fender brackets")
            check(int(model.get_meta("tarvoka_g13_v58_extra_draw_nodes",-1))==0,
                "isometric improvement CANNOT add GPU draw nodes")
            check(int(model.get_meta("tarvoka_g13_v57_added_draw_nodes",-1))==
                (2 if high else 1),
                "preserve Android single-batch V57 brackets")
            var saved:Dictionary=model.get_meta(V58.SAVED,{})
            var old:Dictionary=saved.get("original",{})
            var latest:Dictionary=saved.get("finished",{})
            check(latest.size()==(6 if high else 1),
                "must finish exact number of real mechanical surfaces")
            check(old.size()==latest.size(),"each new PBR coat has original")
            # Later G13 versions (V59+) deliberately apply their own live
            # coatings to shared geometry, including the turret bearing.
            # Re-enable the historical V58 finish on this disposable test
            # model before asserting exact material identity. Do not change
            # the production G13 V68 render or weaken the V58 comparison.
            check(V58.show_finish(model,true),
                "historical V58 coat can be restored after newer finishes")
            var parts:Dictionary=V58._parts(model,high)
            check(parts.size()==latest.size(),
                "same mechanically-linked Godot nodes remain")
            for key in latest:
                var mat:=latest[key] as StandardMaterial3D
                var old_mat:=old.get(key,null) as StandardMaterial3D
                var part:=parts.get(key,null) as GeometryInstance3D
                check(mat!=null and old_mat!=null and part!=null,
                    "physically valid coat "+str(key))
                if mat==null or old_mat==null or part==null:
                    continue
                check(part.material_override==mat,
                    "V58 is actually live on real node "+str(key))
                check(mat.roughness>=0.35 and mat.roughness<=0.70 and
                    mat.metallic>=0.50 and mat.metallic<=0.80,
                    "controlled reflection, no plastic or mirror chrome "+str(key))
                check(mat.clearcoat_enabled==false,
                    "no exaggerated second specular coat on mechanisms")
            var bracket:=model.find_child(V57.BRACKETS,
                true,false) as MultiMeshInstance3D
            check(bracket!=null and bracket.multimesh.instance_count==8,
                "8 original V57 brackets still in one GPU batch")
            if bracket!=null:
                check(bracket.multimesh.mesh is ArrayMesh,
                    "no painted-over substitute for original physical mesh")
                check(bracket.material_override==latest.get(
                    "fender_lod13" if high else "fender_lod8"),
                    "coherent dark steel connects to existing fenders")
            var original_paint:=model.find_child(
                "G13_V44_SculptedFactionFlanks",true,false) as GeometryInstance3D
            if original_paint!=null:
                var coat:=original_paint.material_override as StandardMaterial3D
                if coat!=null:
                    enamel_colors[coat.albedo_color.to_html()]=true
            if high:
                check(bool(model.get_meta(V56.FLAG,false)) and
                    bool(model.get_meta(V55.FLAG,false)),
                    "existing heavy mechanical and PBR preserved")
                var bolts:=model.find_child(V57.PINS,
                    true,false) as MultiMeshInstance3D
                check(bolts!=null and bolts.multimesh.instance_count==8,
                    "eight original screws, not 8 extra mesh nodes")
                if bolts!=null:
                    var poses:Dictionary=model.get_meta(V58.SAVED,{})
                    var before: Array=poses.get("pins_before",[])
                    var after: Array=poses.get("pins_after",[])
                    check(before.size()==8 and after.size()==8,
                        "exact reversible 8 screw transforms preserved")
                    if after.size()==8 and before.size()==8:
                        for i in range(8):
                            var p0:Transform3D=before[i]
                            var p1:Transform3D=after[i]
                            check(absf(absf(p0.origin.x)-absf(p1.origin.x)-
                                V58.PIN_RECESS_M)<0.0001,
                                "actual rivet recessed by exactly 9 mm")
                            check(bolts.multimesh.get_instance_transform(i).
                                origin.distance_to(p1.origin)<0.0001,
                                "actual geometry must use V58 recessed pose")
                var tyres:=model.find_child(V54.TIRE,
                    true,false) as MultiMeshInstance3D
                check(tyres!=null and tyres.multimesh.mesh is ArrayMesh,
                    "rounded V54 tyre physical sculpture unchanged")
            else:
                check(not bool(model.get_meta(V56.FLAG,false)) and
                    model.find_child(V57.PINS,true,false)==null,
                    "LOD8 no V56 internal geometry nor 8 new screws")
            check(V58.show_finish(model,false),"V57 exact historical finish")
            for key in old:
                var part:=parts.get(key,null) as GeometryInstance3D
                if part!=null:
                    check(part.material_override==old[key],
                        "restore exact original resource "+str(key))
            check(V58.show_finish(model,true),"restore V58 physical PBR")
            for key in latest:
                var part:=parts.get(key,null) as GeometryInstance3D
                if part!=null:
                    check(part.material_override==latest[key],
                        "after comparison restore new material "+str(key))
            var turret:=model.find_child("G13_TorretaAzimut",
                true,false) as Node3D
            check(Models.pose_model("aa_mobile",model,"aim_air",0.61,
                Vector2i(1,0)),"original twin-gun azimuth works")
            check(turret!=null and absf(turret.rotation_degrees.y)>10,
                "rotating turret stays unchanged")
            check(Models.pose_model("aa_mobile",model,"move",0.53),
                "original 4x4 animation preserved")
            Models.restore_model_pose("aa_mobile",model)
            for side in [-1,1]:
                check(model.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,"both original twin autocannons intact")
            model.free()
    check(enamel_colors.size()==8,
        "all 8 official faction paint albedos unchanged")
    if failures==0:
        print("PASS G13 V58 ISOMETRIC: 8 factions x 2 native LODs, coherent PBR steel, recessed 8 rivets, no new GPU draws, old/new compare, original twin weapons and tactical performance")
    quit(1 if failures>0 else 0)
