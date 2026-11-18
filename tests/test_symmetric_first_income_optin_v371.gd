extends SceneTree

# The optional gameplay rule keeps classic sessions byte-for-byte compatible.
# It suppresses ONLY the responder's first city payout; both factions still
# earn full normal incomes at every subsequent eligible turn.
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

static func _case(map_id: int, fog: bool, first: int, modern: bool) -> void:
    var army: Array = Roles.experimental_armies(true)
    var land: Array = Scenarios.terrain(map_id)
    # Last argument is new and opt-in. The 10 pre-existing argument slots
    # are untouched, retaining all old call sites and saved game behavior.
    var classic: Dictionary = Session.start(
        army,land,first,fog,true,true,modern,true)
    var explicit_default: Dictionary = Session.start(
        army,land,first,fog,true,true,modern,true,"clear",false,false)
    var equal: Dictionary = Session.start(
        army,land,first,fog,true,true,modern,true,"clear",false,true)
    var start_credit: int = Economy.MODERN_START_CREDITS if modern else Economy.START_CREDITS
    var city_income: int = Economy.MODERN_CITY_INCOME if modern else Economy.CITY_INCOME
    assert(classic == explicit_default)
    assert(classic["economy"]["credits"] == [start_credit,start_credit])
    assert(equal["economy"]["credits"] == [start_credit,start_credit])
    assert(classic["units"] == equal["units"])
    assert(classic["control"] == equal["control"])
    assert(not classic["economy"].has("symmetric_first_income"))
    assert(equal["economy"]["symmetric_first_income"] == true)
    assert(Economy.valid(equal["economy"],equal["terrain"]))
    assert(Codec.decode(Codec.encode(equal)) == equal)
    assert(Codec.decode(Codec.encode(classic)) == classic)
    var bad: Dictionary = equal.duplicate(true)
    bad["economy"]["symmetric_first_income"] = "true"
    assert(not Economy.valid(bad["economy"],bad["terrain"]))
    assert(Codec.encode(bad).is_empty())
    var classic_turn: Dictionary = Session.end_turn(classic)
    var equal_turn: Dictionary = Session.end_turn(equal)
    assert(classic_turn["valid"] and equal_turn["valid"])
    var c: Dictionary = classic_turn["state"]
    var e: Dictionary = equal_turn["state"]
    var responder: int = 1-first
    assert(int(c["faction"]) == responder and int(e["faction"]) == responder)
    assert(int(c["economy"]["turn"]) == 1)
    assert(int(e["economy"]["turn"]) == 1)
    assert(int(c["economy"]["credits"][responder]) == start_credit+city_income)
    assert(int(e["economy"]["credits"][responder]) == start_credit)
    assert(int(c["economy"]["credits"][first]) == start_credit)
    assert(int(e["economy"]["credits"][first]) == start_credit)
    assert(c["units"] == e["units"])
    assert(c["economy"]["sites"] == e["economy"]["sites"])
    assert(Codec.decode(Codec.encode(e)) == e)

    # Resume the opt-in session from a saved file before the responder ends.
    e = Codec.decode(Codec.encode(e))
    var next_a: Dictionary = Session.end_turn(c)
    var next_b: Dictionary = Session.end_turn(e)
    assert(next_a["valid"] and next_b["valid"])
    c = next_a["state"]
    e = next_b["state"]
    assert(int(c["faction"]) == first and int(e["faction"]) == first)
    assert(int(c["economy"]["credits"][first]) == start_credit+city_income)
    assert(int(e["economy"]["credits"][first]) == start_credit+city_income)
    assert(int(c["economy"]["credits"][responder]) == start_credit+city_income)
    assert(int(e["economy"]["credits"][responder]) == start_credit)

    # Next handoff back to responder is economy.turn=3: normal payout
    # resumes, including across SaveCodec roundtrips and fog.
    next_a = Session.end_turn(c)
    next_b = Session.end_turn(e)
    assert(next_a["valid"] and next_b["valid"])
    c = next_a["state"]
    e = next_b["state"]
    assert(int(c["faction"]) == responder and int(e["faction"]) == responder)
    assert(int(c["economy"]["credits"][responder]) == start_credit+2*city_income)
    assert(int(e["economy"]["credits"][responder]) == start_credit+city_income)
    assert(int(c["economy"]["credits"][first]) == start_credit+city_income)
    assert(int(e["economy"]["credits"][first]) == start_credit+city_income)
    assert(Codec.decode(Codec.encode(e)) == e)
    assert(Codec.decode(Codec.encode(c)) == c)
    print("EQUAL371_CONTRACT map=%d fog=%s first=%d modern=%s payout=%d next_reply_income=%d" % [
        map_id,str(fog),first,str(modern),city_income,city_income])

func _initialize() -> void:
    for map_id in [0,1,2,3]:
        for fog in [false,true]:
            for first in [0,1]:
                for modern in [false,true]:
                    _case(map_id,fog,first,modern)
    print("PASS symmetric income opt-in v371: 32 map/fog/side/modern cases, save parity, unchanged legacy, later incomes retained")
    quit(0)
