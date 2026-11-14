extends SceneTree

# Organic 16-game distribution, NOT a win-rate or PvP skill certificate.
# Unlike the one-shot matrix, these orders arise from full AI turns,
# real production slots, city income, fog and troop movement.
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const WATCH := ["apc","ifv","piercer","tank"]

static func _match(map_id: int, fog: bool, relay: bool,
        first: int) -> Dictionary:
    var state: Dictionary = Session.start(
        Roles.modern_armies(true),Scenarios.terrain(map_id),
        first,fog,relay,true,true)
    var purchased: Dictionary = {}
    var visible_threat_buys := {"piercer_vs_heavy":0,"ifv_vs_infantry":0,
        "apc_vs_indirect":0}
    for role in WATCH:
        purchased[role] = 0
    var total_buys := 0
    var actions := 0
    var phases := 0
    var side_actions := [0,0]
    for phase in range(14):
        if int(state["winner"]) != -1:
            break
        var side: int = int(state["faction"])
        var limit: int = mini(40,
            state["units"].size()*2+state["economy"]["sites"].size())
        for order in range(limit):
            var previous: Dictionary = state.duplicate(true)
            var step: Dictionary = AI.step(state)
            assert(state == previous)
            if not bool(step.get("valid",false)):
                break
            assert(str(step.get("action","")) in
                ["move","attack","produce","resupply"])
            var next: Dictionary = step["state"]
            assert(Economy.valid(next["economy"],next["terrain"]))
            assert(int(next["faction"]) == side)
            if str(step["action"]) == "produce":
                var role: String = str(step["role"])
                var price: int = Economy.cost(role)
                assert(price == int(step["cost"]))
                assert(Economy.can_purchase(state,step["factory"],role))
                assert(int(previous["economy"]["credits"][side]) -
                    int(next["economy"]["credits"][side]) == price)
                assert(int(next["economy"]["credits"][1-side]) ==
                    int(previous["economy"]["credits"][1-side]))
                assert(next["units"].size() == previous["units"].size()+1)
                total_buys += 1
                if role in WATCH:
                    purchased[role] = int(purchased[role])+1
                    var obs: Dictionary = Visibility.observed_state(
                        previous,side)
                    var heavy := false
                    var infantry := false
                    var indirect := false
                    for enemy in obs["units"]:
                        if int(enemy.get("hp",0)) <= 0 or int(enemy.get("faction",-1)) == side:
                            continue
                        var e_role: String = str(enemy.get("role",""))
                        if e_role in ["tank","bulwark"]:
                            heavy = true
                        if e_role in ["line","scout","assault","engineer","piercer"]:
                            infantry = true
                        if e_role in ["artillery","spg","mlrs"]:
                            indirect = true
                    if role == "piercer" and heavy:
                        visible_threat_buys["piercer_vs_heavy"] += 1
                    if role == "ifv" and infantry:
                        visible_threat_buys["ifv_vs_infantry"] += 1
                    if role == "apc" and indirect:
                        visible_threat_buys["apc_vs_indirect"] += 1
            actions += 1
            side_actions[side] += 1
            state = next
            if int(state["winner"]) != -1:
                break
        if int(state["winner"]) != -1:
            break
        var end: Dictionary = Session.end_turn(state)
        assert(bool(end.get("valid",false)))
        state = end["state"]
        assert(Codec.decode(Codec.encode(state)) == state)
        phases += 1
    return {
        "winner":int(state["winner"]),"first":first,
        "actions":actions,"phases":phases,"buys":total_buys,
        "roles":purchased,"visible_threat_buys":visible_threat_buys,
        "side_actions":side_actions
    }

func _initialize() -> void:
    var totals := {"apc":0,"ifv":0,"piercer":0,"tank":0}
    var totals_when_visible := {"piercer_vs_heavy":0,
        "ifv_vs_infantry":0,"apc_vs_indirect":0}
    var first_wins := 0
    var second_wins := 0
    var undecided := 0
    var actions := 0
    var buys := 0
    var games := 0
    for map_id in [0,3]:
        for fog in [false,true]:
            for relay in [false,true]:
                var pair: Array = []
                for first in [0,1]:
                    var report: Dictionary = _match(map_id,fog,relay,first)
                    assert(int(report["actions"]) > 0)
                    pair.append(report)
                    for role in WATCH:
                        totals[role] = int(totals[role])+int(report["roles"][role])
                    for purpose in totals_when_visible:
                        totals_when_visible[purpose] = int(totals_when_visible[purpose])+int(report["visible_threat_buys"][purpose])
                    if int(report["winner"]) == -1:
                        undecided += 1
                    elif int(report["winner"]) == first:
                        first_wins += 1
                    else:
                        second_wins += 1
                    actions += int(report["actions"])
                    buys += int(report["buys"])
                    games += 1
                if int(pair[0]["winner"]) == -1:
                    assert(int(pair[1]["winner"]) == -1)
                else:
                    assert(int(pair[1]["winner"]) == 1-int(pair[0]["winner"]))
    assert(games == 16 and buys > 0 and actions > 100)
    var armored_buys: int = 0
    for role in WATCH:
        armored_buys += int(totals[role])
    assert(armored_buys > 0 and armored_buys <= buys)
    assert(first_wins+second_wins+undecided == games)
    var summary := {
        "games":games,"actions":actions,"buys":buys,
        "armored_purchases":totals,
        "observed_threat_purchases":totals_when_visible,
        "first_wins":first_wins,"second_wins":second_wins,
        "undecided":undecided,
        "scope":"two-AI same-roster mirrored starts, not commercial win-rate"
    }
    print("GROUND_ARMOR_SELFPLAY_JSON "+JSON.stringify(summary))
    print("PASS ground armor selfplay: %d paired modern matches, genuine four-role purchases, budget, saves and mirrored first-player results" % games)
    quit(0)
