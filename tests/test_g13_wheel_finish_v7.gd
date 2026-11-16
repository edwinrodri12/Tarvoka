extends SceneTree

# G13 V7 art regression: ensure wheel geometry remains sealed,
# four corners roll consistently and mobile LOD avoids hero detailing.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Finish=preload("res://scripts/ui/G13WheelFinishV7.gd")
var failures:=0

func check(ok: bool,reason: String)->void:
    if not ok:
        failures+=1
        push_error("G13 wheels V7: "+reason)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(G13.INNER_CLEARANCE>=0.04,"inner side of tire clears sealed hull")
    check(Finish.TREAD_RADIUS+Finish.TREAD_HALF_THICK<
        0.72-0.085/2.0,"tread clears fender roof")
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero model builds faction "+str(faction))
        if hero==null:
            continue
        check(bool(hero.get_meta(Finish.FLAG,false)),
            "all faction hero models have finished wheels")
        var tires:=hero.find_child(G13.WHEELS,true,false) as MultiMeshInstance3D
        var hubs:=hero.find_child(G13.HUBS,true,false) as MultiMeshInstance3D
        var rims:=hero.find_child(Finish.OUTER_RIM,true,false) as MultiMeshInstance3D
        var sidewalls:=hero.find_child(Finish.SIDEWALL,true,false) as MultiMeshInstance3D
        var pads:=hero.find_child(Finish.TREAD,true,false) as MultiMeshInstance3D
        check(tires!=null and hubs!=null and rims!=null and
            sidewalls!=null and pads!=null,"all five GPU batches exist")
        if tires!=null and hubs!=null and rims!=null and sidewalls!=null and pads!=null:
            check(tires.multimesh.instance_count==4 and
                hubs.multimesh.instance_count==4 and
                rims.multimesh.instance_count==4 and
                sidewalls.multimesh.instance_count==4 and
                pads.multimesh.instance_count==32,
                "four tires, four hubs, four rims, four faces and 32 tread blocks")
            var before:=tires.multimesh.get_instance_transform(0)
            var oldpad:=pads.multimesh.get_instance_transform(0)
            check(Models.pose_model("aa_mobile",hero,"move",0.42),
                "rolling animation remains available")
            var after:=tires.multimesh.get_instance_transform(0)
            var newpad:=pads.multimesh.get_instance_transform(0)
            check(not before.basis.is_equal_approx(after.basis),
                "tire rotation changes along correct axle")
            check(not oldpad.origin.is_equal_approx(newpad.origin),
                "tread pad rotates with its tire")
            check(absf(hubs.multimesh.get_instance_transform(0).origin.x)>
                absf(tires.multimesh.get_instance_transform(0).origin.x),
                "center hub sits outside rim instead of buried")
        var meshes:=Models.inspect_meshes(hero)
        check(not Finish.install(hero),"cannot add duplicate wheel finish")
        check(Models.inspect_meshes(hero)==meshes,
            "duplicate install cannot duplicate geometry")
        Models.restore_model_pose("aa_mobile",hero)
        check(Models.inspect_meshes(hero)==meshes,
            "pose/restore does not instantiate meshes")
        hero.free()
        var low:=Models.build("aa_mobile",faction,true,8)
        check(low!=null,"mobile LOD still builds")
        if low!=null:
            check(not bool(low.get_meta(Finish.FLAG,false)),
                "LOD8 remains low cost")
            low.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V7: eight faction hero finishes, four closed tire faces, rotating rims/tread, low LOD unchanged")
    quit(0)
