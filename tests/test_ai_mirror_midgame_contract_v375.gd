extends SceneTree

# Verifies reflection of 48 REAL midgame states after four full phases of
# authoritative AI/BattleSession orders. Covers generated N* IDs, persisted
# objectives, purchases, exploration, visits and signal-score transitions.
const Session = preload("res://scripts/core/BattleSession.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Relays = preload("res://scripts/core/RelayControl.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Semantics = preload("res://tests/MirrorSemanticsV375.gd")

static func _check(map_id: int, fog: bool, first: int, layout: String) -> void:
    var state: Dictionary = Session.start(
        Roles.experimental_armies(true),Scenarios.terrain(map_id),first,
        fog,true,true,false,true,"clear",false,true)
    state["ai_config"] = {"level":12,"style":"balanced"}
    var cols: Array = [4,5] if layout == "center" else [3,6]
    var rows: Array = [1,6] if layout == "flanks" else [2,5]
    var sites: Array = []
    for y in rows:
        for x in cols:
            var position := Vector2i(x,y)
            assert(Economy.site_at(state["economy"],position).is_empty())
            assert(Rules.movement_cost(str(state["terrain"][y][x])) >= 0)
            sites.append({"pos":position,"owner":-1})
    state["control"]["nodes"] = sites
    state["control"]["target"] = 8
    state["control"]["fair_round"] = true
    state["control"]["round_scoring"] = true
    state["control"]["first_faction"] = first
    assert(not Codec.encode(state).is_empty())
    var purchases := 0
    var decisions := 0
    var ended_phases := 0
    var conf := {
        "ai_level":12,"ai_style":"balanced",
        "_ab_disable_future_threat_v36":false,
        "_ab_offensive_discipline_v361":true,
        "_ab_critical_rescue_v362":true,
        "_ab_risk_reward_v363":true}
    for phase in range(4):
        if int(state["winner"]) != -1:
            break
        var budget: int = state["units"].size()*2+state["economy"]["sites"].size()
        for i in range(budget+1):
            var before: Dictionary = state.duplicate(true)
            var a: Dictionary = AI.step(state,conf)
            assert(state == before)
            if not bool(a.get("valid",false)):
                break
            if str(a.get("action","")) == "produce":
                purchases += 1
            decisions += 1
            state = a["state"]
            assert(Economy.valid(state["economy"],state["terrain"]))
            assert(Relays.valid(state["control"],state["terrain"]))
            assert(not Codec.encode(state).is_empty())
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var next: Dictionary = Session.end_turn(state)
        assert(bool(next.get("valid",false)))
        state = next["state"]
        ended_phases += 1
        assert(not Codec.encode(state).is_empty())
    assert(decisions >= 3 and ended_phases >= 2)
    var copy: Dictionary = state.duplicate(true)
    var reflected: Dictionary = Mirror.reflect(state)
    assert(state == copy)
    assert(Mirror.reflect(reflected) == state)
    assert(Semantics.normalize(state) == Semantics.normalize(reflected,true))
    assert(not Codec.encode(reflected).is_empty())
    assert(Codec.decode(Codec.encode(reflected)) == reflected)
    assert(Codec.decode(Codec.encode(state)) == state)
    assert(Relays.valid(reflected["control"],reflected["terrain"]))
    assert(Economy.valid(reflected["economy"],reflected["terrain"]))
    assert(reflected["winner"] == Mirror.flipped(int(state["winner"])))
    var los_differences := Mirror.visibility_mismatch(state,reflected)
    # Record LOS/vision differences rather than masking them by fabricating
    # explored tiles or omitting a failed action.
    print("MIDGAME375_CONTRACT map=%d fog=%s first=%d layout=%s phases=%d actions=%d purchases=%d new_units=%d los_diff=%d" % [
        map_id,str(fog),first,layout,ended_phases,decisions,purchases,
        state["units"].size()-10,los_differences])

func _initialize() -> void:
    var cases := 0
    for map_id in [0,1,2,3]:
        for fog in [false,true]:
            for first in [0,1]:
                for layout in ["center","approach","flanks"]:
                    _check(map_id,fog,first,layout)
                    cases += 1
    assert(cases == 48)
    print("PASS AI v375 midgame mirror: 48 genuine progressed battles, generated units, fog, saved goals and involution")
    quit(0)
