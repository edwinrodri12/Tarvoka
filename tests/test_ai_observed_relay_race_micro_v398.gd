extends SceneTree

# v3.9.8 micro-contract: strategic forecast is OFF by default and
# cannot manufacture a race using an enemy absent from observed_state.
const AI = preload("res://scripts/core/BasicAI.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _friends(view: Dictionary, side: int) -> Array:
    var out: Array = []
    for unit in view["units"]:
        if int(unit["faction"]) == side and \
                int(unit["hp"]) > 0 and \
                not bool(unit.get("acted",true)):
            out.append(unit)
    return out

static func _enemies(view: Dictionary, side: int) -> Array:
    var out: Array = []
    for unit in view["units"]:
        if int(unit["faction"]) == 1-side and \
                int(unit["hp"]) > 0:
            out.append(unit)
    return out

func _initialize() -> void:
    var inspected := 0
    var legal := 0
    for fog in [false,true]:
        for first in [0,1]:
            var start: Dictionary = Study._initial(
                Vector2i(40,30),666,fog,first)
            var mirror: Dictionary = Mirror.reflect(start)
            var options: Dictionary = Study._configuration()
            var opted: Dictionary = options.duplicate(true)
            opted["_ab_relay_race_forecast_v398"] = true
            var explicitly_off: Dictionary = options.duplicate(true)
            explicitly_off["_ab_relay_race_forecast_v398"] = false
            var original: Dictionary = AI.step(start,options)
            var off: Dictionary = AI.step(start,explicitly_off)
            assert(original["valid"] == off["valid"])
            assert(original["state"] == off["state"])
            assert(Mirror.signature(original,40,false) ==
                Mirror.signature(off,40,false))
            var actual: Dictionary = AI.step(start,opted)
            var flipped: Dictionary = AI.step(mirror,opted)
            assert(actual["valid"] == flipped["valid"])
            assert(Mirror.signature(actual,40,false) ==
                Mirror.signature(flipped,40,true))
            assert(Codec.encode(actual["state"]).length() > 0)
            if bool(actual["valid"]):
                legal += 1
            # Removing all observed opponents is a TEST ONLY view: a
            # hidden enemy cannot be conjured to justify an urgent race.
            var observed: Dictionary = Visibility.observed_state(start,first)
            var friends: Array = _friends(observed,first)
            var none: Dictionary = AI._forecast_relay_race_v398(
                start,observed,friends,[])
            assert(not bool(none.get("valid",false)))
            var no_relay: Dictionary = observed.duplicate(true)
            no_relay.erase("control")
            none = AI._forecast_relay_race_v398(
                start,no_relay,friends,_enemies(observed,first))
            assert(not bool(none.get("valid",false)))
            inspected += 1
    assert(inspected == 4)
    print("RACE398_MICRO " + JSON.stringify({
        "cases":inspected,"legal_or_nonempty_actions":legal,
        "default_flag_exactly_unchanged":true,
        "no_enemy_no_relay_no_prediction":true,
        "first_actions_mirror_equivalent":true,
        "valid_saves":true
    }))
    print("PASS TARVOKA v398 micro: opt-in planner respects default, "
        + "hidden-enemy limits, exact mirrored decisions and save schema")
    quit(0)
