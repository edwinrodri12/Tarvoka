extends SceneTree

# Geometry-only G13 V6: prevent large intersecting underbody plates,
# preserve preexisting model roles, V5 ground-clearance and two LODs.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const G13=preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const Under=preload("res://scripts/ui/G13UndercarriageV6.gd")
var failures:=0

func check(ok: bool,why: String)->void:
    if not ok:
        failures+=1
        push_error("G13 V6: "+why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    check(Under.AXLE_LENGTH*0.5<Under.WHEEL_INNER_X,
        "axles finish inside each wheel inner face")
    check(Under.FRAME_BOTTOM>Under.HULL_BOTTOM,
        "frame rails clear chassis bottom")
    check(Under.AXLE_Y-Under.AXLE_RADIUS>0.0,
        "axles are not buried in terrain")
    for faction in range(8):
        var hero:=Models.build("aa_mobile",faction,true,13)
        check(hero!=null,"hero exists")
        if hero==null:
            continue
        check(bool(hero.get_meta(Under.FLAG,false)),
            "V6 assembled with standard 3D hero")
        for axle in [-1,1]:
            check(hero.find_child("G13_V6_Axle_%d" % axle,true,false)
                is MeshInstance3D,"visible axle on each wheel pair")
            check(hero.find_child("G13_V6_Differential_%d" % axle,
                true,false) is MeshInstance3D,"axle differential")
            for side in [-1,1]:
                check(hero.find_child("G13_V6_SuspensionMount_%d_%d" %
                    [side,axle],true,false) is MeshInstance3D,
                    "four suspension mounts")
        var count: int=Models.inspect_meshes(hero)
        check(not Under.install(hero),"installation idempotent")
        check(Models.inspect_meshes(hero)==count,
            "no duplicated undercarriage solids")
        check(Models.pose_model("aa_mobile",hero,"move",0.45),
            "G13 wheels still animate")
        check(Models.pose_model("aa_mobile",hero,"attack_ground",0.5),
            "G13 ground attack remains selectable")
        Models.restore_model_pose("aa_mobile",hero)
        check(Models.inspect_meshes(hero)==count,
            "animation adds no new geometry")
        hero.free()
        var low:=Models.build("aa_mobile",faction,true,8)
        check(low!=null,"mobile LOD exists")
        if low!=null:
            check(not bool(low.get_meta(Under.FLAG,false)),
                "LOD8 avoids extra V6 chassis geometry")
            low.free()
    if failures>0:
        quit(1)
        return
    print("PASS G13 V6: underbody separated, 8 faction heroes, LOD8 unchanged, animations reversible")
    quit(0)
