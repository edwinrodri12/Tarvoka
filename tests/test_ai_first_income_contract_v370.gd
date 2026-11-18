extends SceneTree

# Real BattleSession handoff with exactly one first responder payout
# debited in the experiment. Economy, SaveCodec and play code unchanged.
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const FirstIncome = preload("res://tests/FirstReplyIncomeV370.gd")

static func _case(map_id: int, fog: bool, first: int, skip: bool) -> void:
    var s: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),
        first,fog,true,true,false,true)
    s["control"]["fair_round"] = true
    s["control"]["round_scoring"] = true
    s["control"]["first_faction"] = first
    s["control"]["nodes"] = [
        {"pos":Vector2i(4,5),"owner":-1},
        {"pos":Vector2i(5,5),"owner":-1}
    ]
    assert(Economy.valid(s["economy"],s["terrain"]))
    assert(s["economy"]["credits"] == [Economy.START_CREDITS,Economy.START_CREDITS])
    assert(Economy.income_for(s["economy"],0) == Economy.CITY_INCOME)
    assert(Economy.income_for(s["economy"],1) == Economy.CITY_INCOME)
    assert(int(s["economy"]["turn"]) == 0)
    var first_end: Dictionary = Session.end_turn(s)
    assert(first_end.get("valid",false))
    assert(first_end["state"]["faction"] == 1-first)
    assert(int(first_end["state"]["economy"]["credits"][1-first]) ==
        Economy.START_CREDITS+Economy.CITY_INCOME)
    var saved_unmodified: Dictionary = first_end["state"].duplicate(true)
    var trial: Dictionary = FirstIncome.compare_first_handoff(s,first_end,first,skip)
    assert(trial["valid"])
    assert(int(trial["original_payout"]) == Economy.CITY_INCOME)
    assert(int(trial["deducted"]) == (Economy.CITY_INCOME if skip else 0))
    var t: Dictionary = trial["state"]
    assert(int(t["economy"]["credits"][1-first]) ==
        (Economy.START_CREDITS if skip else Economy.START_CREDITS+Economy.CITY_INCOME))
    assert(int(t["economy"]["credits"][first]) == Economy.START_CREDITS)
    assert(first_end["state"] == saved_unmodified)
    assert(Codec.decode(Codec.encode(t)) == t)
    var responder_end: Dictionary = Session.end_turn(t)
    assert(responder_end.get("valid",false))
    var next_first: Dictionary = responder_end["state"]
    assert(int(next_first["faction"]) == first)
    assert(int(next_first["economy"]["credits"][first]) ==
        Economy.START_CREDITS+Economy.CITY_INCOME)
    assert(int(next_first["economy"]["credits"][1-first]) ==
        int(t["economy"]["credits"][1-first]))
    var next_first_end: Dictionary = Session.end_turn(next_first)
    assert(next_first_end.get("valid",false))
    var next_reply: Dictionary = next_first_end["state"]
    assert(int(next_reply["faction"]) == 1-first)
    assert(int(next_reply["economy"]["credits"][1-first]) ==
        int(t["economy"]["credits"][1-first])+Economy.CITY_INCOME)
    assert(Economy.valid(next_reply["economy"],next_reply["terrain"]))
    assert(Codec.decode(Codec.encode(next_reply)) == next_reply)
    print("INCOME370_CONTRACT map=%d fog=%s first=%d skip=%s initial_reply_credit=%d next_reply_income=%d" % [
        map_id,str(fog),first,str(skip),
        int(t["economy"]["credits"][1-first]),Economy.CITY_INCOME])

func _initialize() -> void:
    for map_id in [0,1,2,3]:
        for fog in [false,true]:
            for first in [0,1]:
                for skip in [false,true]:
                    _case(map_id,fog,first,skip)
    print("PASS AI income v370 contract: 32 actual Godot handoffs, only first responder payout suppressed, later income unchanged")
    quit(0)
