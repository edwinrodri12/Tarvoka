extends SceneTree

const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Policy=preload("res://scripts/ui/G13LODPolicyV17.gd")
var failed:int=0

func verify(ok:bool,why:String)->void:
    if not ok:
        failed+=1
        push_error("G13 V17 LOD policy: "+why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    # Never build the hero detail on Android, even in an inspection request.
    for count in [1,2,3,8,16,32]:
        for distance in [0.0,2.0,6.5,7.0,8.0,100.0]:
            for previous in [8,13]:
                verify(Models.recommend_g13_art_level(distance,count,true,
                    true,previous)==8,"Android always lightweight for any density")
    verify(Policy.choose(1.0,1,false,true)==13,
        "native inspection viewer intentionally keeps the approved hero")
    verify(Policy.choose(1.0,1,false,false,8)==13,
        "desktop close-up, one unit may use hero 13")
    verify(Policy.choose(6.6,1,false,false,8)==8,
        "cannot enter hero until near the 6.5 boundary")
    verify(Policy.choose(7.7,1,false,false,13)==13,
        "hysteresis prevents rapid flickering around camera threshold")
    verify(Policy.choose(8.1,1,false,false,13)==8,
        "far camera exits hero at 8.0")
    verify(Policy.choose(0.1,2,false,false,8)==13,
        "desktop maximum two close-up hero units")
    verify(Policy.choose(0.1,3,false,false,13)==8,
        "dense formations force lightweight detail")
    verify(Policy.choose(0.1,0,false,false,13)==8,
        "invalid zero-visible-unit case is cheap")
    verify(Policy.choose(INF,1,false,false,13)==8,
        "invalid infinite camera distance is cheap")
    verify(Policy.recommended_for_formation(32,false)==8,
        "overview with 32 vehicles always uses mobile LOD8")
    for level in [8,13]:
        var result:=Models.build("aa_mobile",0,true,level)
        verify(result!=null,"approved G13 LOD%d builds" % level)
        if result!=null:
            verify(bool(result.get_meta(
                "tarvoka_g13_gpu_static_batches_v16",false))==(level==13),
                "only hero model carries V16 instanced microgeometry")
            result.free()
    if failed>0:
        quit(1)
        return
    print("PASS G13 V17 LOD POLICY: Android 8, 2-hero desktop limit, 6.5/8m hysteresis, 32-vehicle formation, original V16 model preservation")
    quit(0)
