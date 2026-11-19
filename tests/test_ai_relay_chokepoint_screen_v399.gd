extends SceneTree

# v3.9.9 micro gate:
# A genuine bridge choke blocks the shortest visible enemy route to
# a guarded owned relay. Without an OBSERVED enemy (fog), no ambush.
const Screens = preload("res://scripts/core/RelayScreensV399.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const SIZE := Vector2i(40,30)

static func _start(fog: bool = false) -> Dictionary:
    var terrain: Array = Scenarios.terrain(2,SIZE)
    var relay := Vector2i(Scenarios.scale_x(4,SIZE),
        Scenarios.scale_y(2,SIZE))
    assert(relay == Vector2i(18,8))
    assert(str(terrain[8][19]) == "road")
    assert(str(terrain[7][19]) == "water")
    assert(str(terrain[9][19]) == "water")
    var guard: Dictionary = Roles.make_unit("A",0,relay,"line")
    var scout: Dictionary = Roles.make_unit(
        "B",0,relay+Vector2i.LEFT,"scout")
    var opponent: Dictionary = Roles.make_unit(
        "X",1,relay+Vector2i(6,0),"scout")
    assert(not guard.is_empty() and not scout.is_empty()
        and not opponent.is_empty())
    var state: Dictionary = Session.start(
        [guard,scout,opponent],terrain,0,fog,
        true,true,true,false,"clear",false,true)
    assert(state.has("control") and state.has("economy"))
    var owner_assigned := false
    for node in state["control"]["nodes"]:
        if node["pos"] == relay:
            node["owner"] = 0
            owner_assigned = true
    assert(owner_assigned)
    assert(not Codec.encode(state).is_empty())
    return state

static func _propose(state: Dictionary) -> Dictionary:
    var side: int = int(state["faction"])
    var observed: Dictionary = Visibility.observed_state(state,side)
    return Screens.propose(observed,side)

func _initialize() -> void:
    var original: Dictionary = _start()
    var copy: Dictionary = original.duplicate(true)
    var proposed: Dictionary = _propose(original)
    assert(not proposed.is_empty())
    assert(str(proposed["unit_id"]) == "B")
    assert(str(proposed["reason"]) == "relay_narrow_screen_v399")
    assert(proposed["protected_relay"] == Vector2i(18,8))
    assert(Screens._is_narrow(original["terrain"],
        proposed["destination"]))
    assert(int(proposed["public_path_delay"]) >= Screens.MIN_ROUTE_DELAY)
    assert(int(proposed["visible_enemy_eta"]) <= Screens.MAX_FORECAST_TURNS)
    assert(original == copy) # Forecast is side-effect-free.

    var action: Dictionary = AI.step(original,
        {"_ab_relay_screen_v399":true})
    assert(bool(action.get("valid",false)))
    assert(str(action.get("action","")) == "move")
    assert(str(action.get("reason","")) == "relay_narrow_screen_v399")
    assert(str(action.get("unit_id","")) == "B")
    assert(action.get("destination") == proposed["destination"])
    assert(action["state"]["control"] == original["control"])
    assert(action["state"]["economy"]["credits"] ==
        original["economy"]["credits"])
    assert(not Codec.encode(action["state"]).is_empty())
    var baseline: Dictionary = AI.step(original,{})
    var explicit_off: Dictionary = AI.step(original,
        {"_ab_relay_screen_v399":false})
    assert(baseline["valid"] == explicit_off["valid"])
    assert(baseline["state"] == explicit_off["state"])
    assert(Mirror.signature(baseline,40,false) ==
        Mirror.signature(explicit_off,40,false))

    var mirror: Dictionary = Mirror.reflect(original)
    var reflected: Dictionary = AI.step(mirror,
        {"_ab_relay_screen_v399":true})
    assert(bool(reflected.get("valid",false)))
    assert(Mirror.signature(action,40,false) ==
        Mirror.signature(reflected,40,true))
    assert(Mirror.reflect(reflected["state"]) == action["state"])

    # The enemy x24 is outside all allied vision on this map.
    # No knowledge of its location may leak from the true state.
    var hidden: Dictionary = _start(true)
    var view: Dictionary = Visibility.observed_state(hidden,0)
    var seen_opponents := 0
    for member in view["units"]:
        if int(member["faction"]) == 1:
            seen_opponents += 1
    assert(seen_opponents == 0)
    assert(_propose(hidden).is_empty())
    assert(not Codec.encode(hidden).is_empty())
    # An open map without opposite impassable flanks has no bottleneck.
    var plains: Array = Scenarios.terrain(0,SIZE)
    assert(not Screens._is_narrow(plains,Vector2i(19,8)))

    print("SCREEN399_MICRO " + JSON.stringify({
        "guarded_owned_relay":"(18, 8)",
        "screen_destination":str(proposed["destination"]),
        "route_delay":proposed["public_path_delay"],
        "visible_enemy_eta":proposed["visible_enemy_eta"],
        "legal_move":true,
        "default_off_identical":true,
        "full_mirror_parity":true,
        "hidden_enemy_rejected":true,
        "nonchokepoint_rejected":true
    }))
    print("PASS TARVOKA v399 micro: legal choke screen, exact mirror, "
        + "unmodified default, true fog isolation and no free resources")
    quit(0)
