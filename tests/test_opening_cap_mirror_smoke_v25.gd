extends SceneTree

# Opt-in modes must not change V21 defaults, official Session or saves.
const Lab = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    for size in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for first in [0,1]:
            var original: Dictionary = Lab.start(0,size,first)
            var restricted: Dictionary = Lab.start(0,size,first,
                {"opening_cap":true})
            assert(original.get("valid",false))
            assert(restricted.get("valid",false))
            assert(not original["session"]["world"]["state"].has("opening"))
            var before: Dictionary = restricted["session"]["world"]["state"]
            assert(Opening.valid(before["opening"]))
            assert(int(before["opening"]["starter"]) == first)
            assert(Opening.remaining(before) == 3)
            assert(int(before["economy"]["credits"][0]) == Economy.MODERN_START_CREDITS)
            assert(int(before["economy"]["credits"][1]) == Economy.MODERN_START_CREDITS)
            var step: Dictionary = Lab.play_half_turn(restricted,"expansion")
            assert(step.get("valid",false))
            var after: Dictionary = step["battle"]["session"]["world"]["state"]
            assert(not after.has("opening"))
            assert(int(after["faction"]) == 1-first)
            assert(int(step["battle"]["stats"]["orders"][first]) <= 3)
            var income: int = int(restricted["session"]["world"]["layout"]["starting_income_each"])
            assert(int(after["economy"]["credits"][1-first]) == \
                Economy.MODERN_START_CREDITS+income)
            assert(int(after["economy"]["credits"][first]) == \
                Economy.MODERN_START_CREDITS-int(step["battle"]["stats"]["recruits_cost"][first]))
            print("CAP_SMOKE_V25 size=%s starter=%d cap_orders=%d second_cash=%d" % [
                str(size),first,int(step["battle"]["stats"]["orders"][first]),
                int(after["economy"]["credits"][1-first])])
    assert(Lab._candidate_key("line",0,10,Vector2i(2,2),Vector2i(4,3)) == \
        Lab._candidate_key("line",1,10,Vector2i(7,2),Vector2i(5,3)))
    assert(Lab._candidate_key("piercer",0,24,Vector2i(4,12),Vector2i(9,10)) == \
        Lab._candidate_key("piercer",1,24,Vector2i(19,12),Vector2i(14,10)))
    var sample: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],18)
    var control: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],18,{})
    assert(sample.get("valid",false) and control.get("valid",false))
    assert(sample == control)
    var tied: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],18,{"canonical_ties":true})
    var capped: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],18,{"opening_cap":true})
    var combined: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],18,
        {"canonical_ties":true,"opening_cap":true})
    for run in [tied,capped,combined]:
        assert(run.get("valid",false))
        assert(int(run["halfturns"]) <= 18)
        assert(run["winner"] in [-1,0,1])
        for side in ["0","1"]:
            var cell: Dictionary = run["sides"][side]
            assert(int(cell["cash"]) == Economy.MODERN_START_CREDITS+ \
                int(cell["income"])-int(cell["spent"]))
    print("PASS v25 opening smoke: three map sizes, both initiative sides, exact first income, first 3 orders, canonical mirror keys, byte-for-byte legacy result")
    quit(0)
