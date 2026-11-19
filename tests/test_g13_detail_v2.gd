extends SceneTree

# G13 V2 shared viewer geometry smoke test.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13V2=preload("res://scripts/ui/G13DetailV2.gd")
var errors:=0

func check(ok: bool, message: String)->void:
    if not ok:
        errors+=1
        push_error("G13 V2: "+message)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    # G13 stays in position nine even as G15 becomes the tenth art-only
    # preview in the same Studio. Preserve existing eight original roles.
    check(Models.ROLES.size()>=9 and Models.ROLES[8]=="aa_mobile" and
        Models.ROLES.count("aa_mobile")==1,
        "V2 preserves G13 studio position when later units are added")
    for faction in range(8):
        var detailed:=Models.build("aa_mobile",faction,true,13)
        check(detailed!=null,"hero model builds for faction "+str(faction))
        if detailed!=null:
            check(bool(detailed.get_meta(G13V2.FLAG,false)),
                "hero detail applied to faction "+str(faction))
            check(detailed.find_child("G13_V2_RearTowEye",true,false)!=null,
                "rear is closed and finished")
            for side in [-1,1]:
                check(detailed.find_child(
                    "G13_V2_TurretInsignia_%d" % side,true,false)!=null,
                    "turret carries faction paint")
                for axle in [-1,1]:
                    check(detailed.find_child(
                        "G13_V2_Fender_%d_%d" % [side,axle],
                        true,false)!=null,"four independent fenders")
            var meshes:=Models.inspect_meshes(detailed)
            check(not G13V2.apply(detailed,Color.WHITE),
                "V2 is idempotent and cannot double up overlapping polygons")
            check(meshes==Models.inspect_meshes(detailed),
                "V2 cannot duplicate geometry")
            check(Models.pose_model("aa_mobile",detailed,"scan",0.5),
                "V1 radar still animates")
            Models.restore_model_pose("aa_mobile",detailed)
            detailed.free()
        var mobile:=Models.build("aa_mobile",faction,true,8)
        check(mobile!=null,"mobile LOD builds")
        if mobile!=null:
            check(not bool(mobile.get_meta(G13V2.FLAG,false)),
                "mobile LOD avoids hero mesh overhead")
            mobile.free()
    if errors:
        quit(1)
        return
    print("PASS G13 V2: eight faction finishes, four fenders, LOD isolation, no duplicated mesh, reversible radar")
    quit(0)
