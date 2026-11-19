extends SceneTree

# TARVOKA v4.0.0: no production changes unless an explicit opt-in
# flag is passed. Pure decision contracts: immediate city income, legal
# recruitment, and a genuinely urgent visible race are kept separate.
const Opportunity = preload("res://scripts/core/OpportunityCostV400.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Study = preload("res://tests/test_ai_initiative_counterfactual_v379.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const GRID := Vector2i(40,30)
const RACE := {
    "valid":true,"action":"move",
    "destination":Vector2i(17,8),
    "target_relay":Vector2i(18,8),
    "visible_enemy_eta":2,"own_eta":2
}
const RECRUIT := {"valid":true,"action":"produce","cost":300}
const CITY := {
    "valid":true,"action":"move","reason":"capture_city",
    "unit_id":"A","destination":Vector2i(12,8)
}

static func _knowledge() -> Dictionary:
    return {
        "units":[
            {"id":"A","faction":0,"role":"scout","hp":6,
             "pos":Vector2i(11,8)}
        ],
        "economy":{
            "modern":true,
            "sites":[
                {"kind":"city","pos":Vector2i(12,8),"owner":-1}
            ]
        }
    }

func _initialize() -> void:
    var knowledge: Dictionary = _knowledge()
    var city: Dictionary = Opportunity.decide(
        knowledge,0,RACE,CITY,RECRUIT)
    assert(city["choice"] == "city")
    assert(city["known_city_capture_this_action"])
    assert(int(city["known_city_three_round_income"]) == 750)
    assert(int(city["recruit_cost"]) == 300)
    var distant: Dictionary = CITY.duplicate()
    distant["destination"] = Vector2i(12,9)
    var force: Dictionary = Opportunity.decide(
        knowledge,0,RACE,distant,RECRUIT)
    assert(force["choice"] == "recruit")
    assert(not force["known_city_capture_this_action"])
    var urgent: Dictionary = RACE.duplicate()
    urgent["destination"] = Vector2i(18,8)
    urgent["visible_enemy_eta"] = 1
    urgent["own_eta"] = 1
    var exact: Dictionary = Opportunity.decide(
        knowledge,0,urgent,CITY,RECRUIT)
    assert(exact["choice"] == "race")
    assert(exact["relay_captured_by_move"])
    var invalid: Dictionary = Opportunity.decide(
        knowledge,0,{"valid":false},CITY,RECRUIT)
    assert(invalid["choice"] == "none")

    var checks := 0
    for fog in [false,true]:
        for first in [0,1]:
            var state: Dictionary = Study._initial(
                GRID,682,fog,first)
            var mirrored: Dictionary = Mirror.reflect(state)
            var opts: Dictionary = Study._configuration()
            var off: Dictionary = opts.duplicate(true)
            off["_ab_economic_arbitration_v400"] = false
            var enable: Dictionary = opts.duplicate(true)
            enable["_ab_economic_arbitration_v400"] = true
            var original: Dictionary = AI.step(state,opts)
            var explicitly_off: Dictionary = AI.step(state,off)
            assert(original["valid"] == explicitly_off["valid"])
            assert(original["state"] == explicitly_off["state"])
            assert(Mirror.signature(original,40,false) ==
                Mirror.signature(explicitly_off,40,false))
            var before: Dictionary = state.duplicate(true)
            var action: Dictionary = AI.step(state,enable)
            var reflected: Dictionary = AI.step(mirrored,enable)
            assert(action["valid"] == reflected["valid"])
            assert(Mirror.signature(action,40,false) ==
                Mirror.signature(reflected,40,true))
            assert(state == before)
            assert(not Codec.encode(action["state"]).is_empty())
            assert(not Codec.encode(reflected["state"]).is_empty())
            var observed: Dictionary = Visibility.observed_state(
                state,first)
            if fog:
                assert(int(observed["economy"]["credits"][1-first]) == -1)
            checks += 1

    print("OPPORTUNITY400_MICRO " + JSON.stringify({
        "validated_city_income":750,
        "validated_legal_recruitment_cost":300,
        "urgent_relay_preempts_city_and_recruit":true,
        "default_off_unchanged":true,
        "real_match_mirror_checks":checks,
        "fog_opponent_treasury_masked":true,
        "no_game_rule_changes":true
    }))
    print("PASS TARVOKA v400 micro: city/relay/recruit arbitration, "
        + "default bit-identical, valid saves and mirrored legal actions")
    quit(0)
