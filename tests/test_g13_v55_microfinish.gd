extends SceneTree

# Native Godot 4.3 G13 V55 acceptance, not a material mockup.
# Tests real hero model, original eight faction colors, PBR microtextures,
# one instanced 20-gasket draw, reversible V54 compare, mobile untouched.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const V53=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const V54=preload("res://scripts/ui/G13RubberSculptV54.gd")
const V55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const V59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const V60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
var errors:int=0
var faction_paints:Dictionary={}

func assert_ok(ok:bool,reason:String)->void:
    if not ok:
        errors+=1
        push_error("G13 V55 native material QA: "+reason)

func _mat(node:Node3D,name:String)->StandardMaterial3D:
    var part:=node.find_child(name,true,false) as GeometryInstance3D
    return part.material_override as StandardMaterial3D if part!=null else null

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        assert_ok(hero!=null,"hero build failed for faction %d" % faction)
        if hero==null:
            continue
        # V59 purposefully boosts enamel and sculpted rubber, so remove
        # its live layer before checking that V55 was color-preserving.
        if bool(hero.get_meta(V60.FLAG,false)):
            assert_ok(V60.show_finish(hero,false),
                "V60 hidden during historical V55 QA")
        if bool(hero.get_meta(V59.FLAG,false)):
            assert_ok(V59.show_finish(hero,false),
                "must expose historic V55 under current V59 PBR finish")
        assert_ok(bool(hero.get_meta(V54.FLAG,false)) and
            bool(hero.get_meta(V55.FLAG,false)),
            "V55 on V54 sculpt absent for faction %d" % faction)
        var saved:Dictionary=hero.get_meta(V55.SAVED,{})
        assert_ok(saved.has("original") and saved.has("finished"),
            "material comparison must be saved atomically")
        var original:Dictionary=saved.get("original",{})
        var finished:Dictionary=saved.get("finished",{})
        assert_ok(finished.size()>=V55.REQUIRED.size(),
            "all mandatory painted and machined panels must be surfaced")
        for key in finished.keys():
            var mat:=finished[key] as StandardMaterial3D
            var before:=original.get(key,null) as StandardMaterial3D
            assert_ok(mat!=null and before!=null,
                "both material revisions available "+str(key))
            if mat==null or before==null:
                continue
            assert_ok(mat.albedo_color==before.albedo_color,
                "do not retint any faction albedo: "+str(key))
            assert_ok(mat.roughness_texture!=null and
                mat.normal_texture!=null and mat.normal_enabled and
                mat.uv1_triplanar,
                "actual UV-independent metal microfinish: "+str(key))
            assert_ok(mat.normal_scale<=0.11 and
                mat.roughness>=0.25 and mat.roughness<=0.60,
                "avoid aggressive fake scratches and oily metal: "+str(key))
        var original_paint:=_mat(hero,"G13_V44_SculptedFactionFlanks")
        if original_paint!=null:
            faction_paints[original_paint.albedo_color.to_html()]=true
        var cab:=_mat(hero,"G13_V10_ChamferedCabShell")
        var hubs:=_mat(hero,"G13_V46_MachinedArmoredHubCaps")
        var enamel:=_mat(hero,"G13_V44_SculptedFactionFlanks")
        var tire:=_mat(hero,V54.TIRE)
        assert_ok(cab!=null and hubs!=null and enamel!=null and tire!=null,
            "machined alloys, armor, paint and rubber physically present")
        if cab!=null and hubs!=null and enamel!=null and tire!=null:
            assert_ok(cab.metallic>0.56 and hubs.metallic>0.82 and
                enamel.clearcoat_enabled,
                "metal and protected painted panels have distinct light response")
            assert_ok(tire.metallic<0.01 and tire.roughness>0.85,
                "do not polish tires into black chrome")
        var seams:=hero.find_child(V55.SEAMS,true,false) as MultiMeshInstance3D
        assert_ok(seams!=null,"actual gasket geometry must be attached")
        if seams!=null and seams.multimesh!=null:
            assert_ok(seams.multimesh.instance_count==20,
                "all four service hatches need 20 real seam segments")
            assert_ok(seams.get_parent().name=="G13_Casco4x4",
                "seams stay attached to original hull, not turret or world")
            var line_index:int=0
            for side in [-1,1]:
                for start in [-0.380,0.055]:
                    var points:Array[Vector2]=[
                        Vector2(start,0.750),
                        Vector2(start+0.039,0.855),
                        Vector2(start+0.262,0.855),
                        Vector2(start+0.310,0.775),
                        Vector2(start+0.270,0.720)]
                    for edge in range(5):
                        if line_index>=seams.multimesh.instance_count:
                            break
                        var pose:Transform3D=seams.multimesh.get_instance_transform(
                            line_index)
                        var start_world:=Vector3(
                            float(side)*0.727,points[edge].y,points[edge].x)
                        var next:Vector2=points[(edge+1)%5]
                        var end_world:=Vector3(
                            float(side)*0.727,next.y,next.x)
                        # Test the physical line endpoints, not just its
                        # midpoint. Earlier global-axis scaling produced
                        # long dangling spikes visible in real 3D images.
                        var drawn_a:Vector3=pose.origin-pose.basis.y*0.5
                        var drawn_b:Vector3=pose.origin+pose.basis.y*0.5
                        assert_ok((drawn_a.distance_to(start_world)<0.002 and
                            drawn_b.distance_to(end_world)<0.002) or (
                            drawn_a.distance_to(end_world)<0.002 and
                            drawn_b.distance_to(start_world)<0.002),
                            "gasket endpoints must attach to real 3D edge %d" % line_index)
                        assert_ok(absf(pose.basis.x.length()-0.003)<0.0005 and
                            absf(pose.basis.z.length()-0.005)<0.0005,
                            "gasket thickness cannot stretch into dangling spikes")
                        line_index+=1
            assert_ok(line_index==20,"all twenty real V45 panel edges checked")
        assert_ok(int(hero.get_meta("tarvoka_g13_v55_added_draw_nodes",-1))==1,
            "one GPU draw per entire 20-element gasket set, not 20 nodes")
        var tiremesh:Mesh=(hero.find_child(V54.TIRE,true,false
            ) as MultiMeshInstance3D).multimesh.mesh
        assert_ok(V55.show_finish(hero,false),"V54 same-camera comparison failed")
        if seams!=null:
            assert_ok(not seams.visible,"reference shows no new gasket segments")
        var v53cab:=_mat(hero,"G13_V10_ChamferedCabShell")
        if v53cab!=null:
            assert_ok(absf(v53cab.metallic-0.54)<0.001,
                "V55 comparison restores the exact approved V53 metal layer")
        assert_ok(V55.show_finish(hero,true),"V55 final PBR reapply failed")
        if seams!=null:
            assert_ok(seams.visible,"V55 physical gasket restored")
        assert_ok(_mat(hero,"G13_V10_ChamferedCabShell")==cab,
            "reapply exact native material resource, no global duplication")
        var wheels_after:=hero.find_child(V54.TIRE,true,false) as MultiMeshInstance3D
        assert_ok(wheels_after!=null and
            wheels_after.multimesh.mesh==tiremesh,
            "V54 rolling tire mesh must not be replaced by surface pass")
        if bool(hero.get_meta(V59.FLAG,false)):
            assert_ok(V59.show_finish(hero,true),
                "V59 premium rubber and glass must be restored after V55 QA")
        if bool(hero.get_meta(V60.FLAG,false)):
            assert_ok(V60.show_finish(hero,true),
                "restore V60 after V55 history")
        hero.free()
        var tactical:=Models.build("aa_mobile",faction,true,8)
        assert_ok(tactical!=null,"LOD8 must still build")
        if tactical!=null:
            assert_ok(not bool(tactical.get_meta(V55.FLAG,false)) and
                tactical.find_child(V55.SEAMS,true,false)==null,
                "Android LOD8 retains zero V55 microtexture passes")
            tactical.free()
    assert_ok(faction_paints.size()==8,
        "all eight official paint families survive without retinting")
    if errors==0:
        print("PASS G13 V55 MICROFINISH: 8 factions, real PBR triplanar grain, 20 gasket seams, 1 GPU batch, V54 reference, rubber and LOD8 preserved")
    quit(1 if errors>0 else 0)
