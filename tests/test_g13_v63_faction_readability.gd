extends SceneTree

# Godot 4.3 real G13 V63 hard-surface and faction-PBR validation.
# Tests all eight official factions in 3D HERO13 and Android LOD8.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const V61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const V62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const V63=preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const V32=preload("res://scripts/ui/G13FactionMountFinishV32.gd")
const V44=preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const V45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
var errors:int=0
var official:Dictionary={}

func check(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V63 faction visual regression: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(V63.DRAW_NODES_ADDED==0,
        "use existing colored surfaces, zero new GPU draws")
    for faction in range(8):
        for lod in [8,13]:
            var hero:bool=lod==13
            var model:=Models.build("aa_mobile",faction,true,lod)
            check(model!=null,"real G13 for faction %d LOD%d" % [faction,lod])
            if model==null:
                continue
            check(bool(model.get_meta(V63.FLAG,false)) and
                bool(model.get_meta(V62.FLAG,false)) and
                bool(model.get_meta(V61.FLAG,false)) and
                bool(model.get_meta(V60.FLAG,false)),
                "V63 applied after validated reflective glass and real wheels")
            var state:Dictionary=model.get_meta(V63.SAVED,{})
            var before:Dictionary=state.get("before_materials",{})
            var after:Dictionary=state.get("after_materials",{})
            var poses_before:Dictionary=state.get("before_poses",{})
            var poses_after:Dictionary=state.get("after_poses",{})
            check(before.size()==V63.PARTS.size() and
                after.size()==before.size() and
                poses_before.size()==3 and poses_after.size()==3,
                "all six existing faction groups and three mesh batches")
            check(int(model.get_meta(
                "tarvoka_g13_v63_zero_extra_draw_nodes",-1))==0 and
                int(model.get_meta(
                "tarvoka_g13_v63_repositioned_flank_badges",-1))==4,
                "visible armor badges without extra GPU objects")
            for name in after:
                var node:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                var a:=after[name] as StandardMaterial3D
                var b:=before[name] as StandardMaterial3D
                check(node!=null and node.material_override==a,
                    "new live PBR finish on original "+str(name))
                check(a!=null and b!=null and
                    absf(a.albedo_color.h-b.albedo_color.h)<0.0001 and
                    a.albedo_color.s+0.0001>=b.albedo_color.s and
                    a.albedo_color.v+0.0001>=b.albedo_color.v,
                    "preserve faction hue, modestly enrich original enamel")
                check(a.clearcoat_enabled and
                    a.roughness>=0.34 and a.roughness<=0.54,
                    "real satin painted steel, no mirror chrome")
            var badge:=model.find_child(V32.DRAW_BODY,true,false
                ) as MultiMeshInstance3D
            var turret:=model.find_child(V44.TURRET_PAINT,true,false
                ) as MultiMeshInstance3D
            var roof:=model.find_child(V45.PAINT,true,false
                ) as MultiMeshInstance3D
            check(badge!=null and turret!=null and roof!=null,
                "same original physical flank/turret/roof mesh groups")
            if badge==null or turret==null or roof==null:
                model.free()
                continue
            var body_orig:Array[Transform3D]=poses_before[V32.DRAW_BODY]
            var body_new:Array[Transform3D]=poses_after[V32.DRAW_BODY]
            var moved:int=0
            for i in range(body_orig.size()):
                if absf(body_orig[i].origin.x)>0.62:
                    moved+=1
                    check(absf(body_new[i].origin.x-
                        signf(body_orig[i].origin.x)*V63.OUTER_BADGE_X)
                        <0.0001,
                        "badge physically seated above later V44 armor")
                else:
                    check(body_new[i].is_equal_approx(body_orig[i]),
                        "rear badges preserved with their old positioning")
            check(moved==V63.LATERAL_BADGES,
                "all four side badges physically unhidden")
            var guards_orig:Array[Transform3D]=(
                poses_before[V44.TURRET_PAINT])
            var guards_new:Array[Transform3D]=(
                poses_after[V44.TURRET_PAINT])
            check(guards_new.size()==4 and
                guards_new[0].basis.z.length()>
                    guards_orig[0].basis.z.length()*1.19,
                "real turret guards enlarged, not only saturation")
            var roof_orig:Array[Transform3D]=poses_before[V45.PAINT]
            var roof_new:Array[Transform3D]=poses_after[V45.PAINT]
            check(roof_new.size()==2 and
                roof_new[0].basis.x.length()>
                    roof_orig[0].basis.x.length()*1.17,
                "two visible original roof recognition bars widened")
            check(V63.show_finish(model,false),
                "restore legacy faction finish exactly")
            for name in before:
                var node:=model.find_child(str(name),true,false
                    ) as GeometryInstance3D
                check(node.material_override==before[name],
                    "original surface material restored")
            for name in poses_before:
                var item:=model.find_child(str(name),true,false
                    ) as MultiMeshInstance3D
                var poses:Array[Transform3D]=poses_before[name]
                for i in range(poses.size()):
                    check(item.multimesh.get_instance_transform(i).
                        is_equal_approx(poses[i]),
                        "all badge poses restored exactly")
            check(V63.show_finish(model,true),
                "new colored plates reappear on the same model")
            check(badge.multimesh.get_instance_transform(0).
                is_equal_approx(body_new[0]),
                "latest faction badge positions restored")
            var fixed:=model.find_child(
                "G13_TurretFaction_1",true,false) as GeometryInstance3D
            if fixed!=null:
                var mat:=fixed.material_override as StandardMaterial3D
                if mat!=null:
                    official[mat.albedo_color.to_html()]=true
            for side in [-1,1]:
                check(model.find_child("G13_Autocannon_%d" % side,
                    true,false)!=null,
                    "two original autocannons unchanged")
            check(Models.pose_model("aa_mobile",model,
                "aim_air",0.6,Vector2i(1,1)),
                "original turret/radar weapons animation intact")
            Models.restore_model_pose("aa_mobile",model)
            model.free()
    check(official.size()==8,"all eight original faction identities distinct")
    if errors==0:
        print("PASS G13 V63 FACTION READABILITY: 8 factions x LOD8/13, four visible flank badges, wider turret and roof, exact colors and reversible materials, 0 GPU nodes, V61/V62 preserved")
    quit(1 if errors>0 else 0)
