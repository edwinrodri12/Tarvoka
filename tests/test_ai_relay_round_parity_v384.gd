extends SceneTree

# TARVOKA v3.8.4: diagnostic-only contract for relay point settlement.
# This test does NOT approve or install a different scoring rule.
# A preset legal relay ownership snapshot is evaluated twice in a round.
# No moves, combats, upgrades or units are fabricated as actual actions.
const Relays = preload("res://scripts/core/RelayControl.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SIZE := Vector2i(40,30)
const SEEDS := [630,631,632,633]
const PATTERNS := {
    "neutral": [-1,-1,-1,-1],
    "equal": [0,0,1,1],
    "color0_majority": [0,0,0,1],
    "color1_majority": [0,1,1,1]
}

static func _owners(control: Dictionary) -> Array:
    var counts := [0,0]
    for relay in control["nodes"]:
        var owner: int = int(relay["owner"])
        if owner in [0,1]:
            counts[owner] += 1
    return counts

static func _run(seed: int, starter: int, pattern: String) -> Dictionary:
    var terrain: Array = Scenarios.seeded_terrain(seed,SIZE)
    assert(Rules.valid_terrain(terrain))
    var c: Dictionary = Relays.create(terrain,5,true,starter)
    assert(not c.is_empty())
    assert(bool(c["round_scoring"]))
    assert(int(c["first_faction"]) == starter)
    var owners: Array = PATTERNS[pattern]
    assert(owners.size() == c["nodes"].size())
    for i in range(owners.size()):
        c["nodes"][i]["owner"] = int(owners[i])
    c["scores"] = [4,4]
    assert(Relays.valid(c,terrain))
    var holdings: Array = _owners(c)
    var state := {"terrain":terrain,"units":[],
        "faction":starter,"winner":-1,"control":c}
    var original: Dictionary = state.duplicate(true)
    var first_end: Dictionary = Relays.finish_turn(state)
    assert(state == original) # immutable
    assert(int(first_end["winner"]) == -1)
    assert(int(first_end["control"]["turns"]) == 1)
    assert(first_end["control"]["scores"] == [4,4])
    assert(first_end["control"]["nodes"] == original["control"]["nodes"])
    assert(Relays.score_winner(first_end["control"]) == -1)
    first_end["faction"] = 1-starter
    var after_reply: Dictionary = Relays.finish_turn(first_end)
    assert(int(after_reply["control"]["turns"]) == 2)
    assert(Relays.valid(after_reply["control"],terrain))
    var scores: Array = after_reply["control"]["scores"]
    assert(scores == [4+holdings[0],4+holdings[1]])
    var winner: int = -1
    if scores[0] != scores[1] and maxi(scores[0],scores[1]) >= 5:
        winner = 0 if int(scores[0]) > int(scores[1]) else 1
    assert(int(after_reply["winner"]) == winner)
    assert(Relays.score_winner(after_reply["control"]) == winner)
    assert(after_reply["control"]["nodes"] == original["control"]["nodes"])
    return {"seed":seed,"template":Scenarios.seeded_template(seed),
        "starter":starter,"pattern":pattern,
        "holdings":holdings,"score_at_start":[4,4],
        "score_after_first":[4,4],"score_after_full_round":scores,
        "winner_after_first":-1,"winner_after_full_round":winner,
        "ownership_changed":false,"round_scoring":true}

func _initialize() -> void:
    var rows: Array = []
    for seed in SEEDS:
        for pattern in ["neutral","equal","color0_majority","color1_majority"]:
            var first0: Dictionary = _run(seed,0,pattern)
            var first1: Dictionary = _run(seed,1,pattern)
            # With the same physical relay ownership, the rule does not
            # award extra score to the first or second player.
            assert(first0["score_after_full_round"] ==
                first1["score_after_full_round"])
            assert(first0["winner_after_full_round"] ==
                first1["winner_after_full_round"])
            assert(first0["holdings"] == first1["holdings"])
            rows.append(first0)
            rows.append(first1)
    assert(rows.size() == 32)
    var report := {
        "size":"40x30",
        "templates":4,"ownership_patterns":4,
        "first_turn_orders_tested":2,"cases":rows.size(),
        "same_winner_across_starter_swap":true,
        "same_scores_across_starter_swap":true,
        "payout_only_after_two_half_turns":true,
        "automatic_second_income_or_signal_bonus":false,
        "no_ai_playout_in_this_contract":true,
        "no_production_changes":true,
        "cases_detail":rows
    }
    print("RELAY384_RESULT " + JSON.stringify(report))
    print("PASS TARVOKA v384: round-boundary relay accounting is starter-neutral on fixed ownership")
    quit(0)
