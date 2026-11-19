extends SceneTree

# Screen-space strategy only: no changes to game systems.
const Policy=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const Mobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    assert(Policy.nominal_width(0)==0.0)
    assert(Policy.nominal_width(4)==0.0)
    assert(Policy.nominal_width(1)==9.5)
    assert(Policy.nominal_width(2)==15.0)
    assert(Policy.nominal_width(3)==20.5)
    assert(Policy.projected_width(null,Vector3.ZERO,9.5)==0.0)
    assert(Policy.choose_mobile(-7)==Mobile.PROFILE_DISTANT)
    assert(Policy.choose_mobile(0)==Mobile.PROFILE_DISTANT)
    assert(Policy.choose_mobile(100)==Mobile.PROFILE_DISTANT)
    assert(Policy.choose_mobile(150)==Mobile.PROFILE_DISTANT)
    assert(Policy.choose_mobile(152)==Mobile.PROFILE_TACTICAL)
    assert(Policy.choose_mobile(300)==Mobile.PROFILE_TACTICAL)
    assert(Policy.choose_mobile(100,Mobile.PROFILE_TACTICAL)==Mobile.PROFILE_DISTANT)
    assert(Policy.choose_mobile(112,Mobile.PROFILE_TACTICAL)==Mobile.PROFILE_DISTANT)
    assert(Policy.choose_mobile(113,Mobile.PROFILE_TACTICAL)==Mobile.PROFILE_TACTICAL)
    assert(Policy.choose_mobile(150,Mobile.PROFILE_TACTICAL)==Mobile.PROFILE_TACTICAL)
    var counts:Dictionary={
        Mobile.PROFILE_TACTICAL:0,
        Mobile.PROFILE_DISTANT:0
    }
    var loops:int=0
    for level in [1,2,3]:
        for camera_size in range(0,420,3):
            for previous in [Mobile.PROFILE_TACTICAL,Mobile.PROFILE_DISTANT]:
                var profile:int=Policy.choose_mobile(
                    float(camera_size),previous)
                assert(profile==Mobile.PROFILE_TACTICAL or
                    profile==Mobile.PROFILE_DISTANT)
                counts[profile]=int(counts[profile])+1
                assert(Mobile.valid(level,-1,0,profile))
                loops+=1
    assert(loops==840)
    assert(int(counts[Mobile.PROFILE_TACTICAL])>0)
    assert(int(counts[Mobile.PROFILE_DISTANT])>0)
    # Zoom jitter inside hysteresis band cannot trigger flipping.
    for px in [130.0,151.0,115.0,145.0,113.0,148.0]:
        assert(Policy.choose_mobile(px,Mobile.PROFILE_DISTANT)==
            Mobile.PROFILE_DISTANT)
        assert(Policy.choose_mobile(px,Mobile.PROFILE_TACTICAL)==
            Mobile.PROFILE_TACTICAL)
    print("PASS WORKSHOP LOD POLICY: ",loops,
        " stable mobile size/zoom selections; 112-152px hysteresis; ",
        "no automatic HERO on Android")
    quit(0)
