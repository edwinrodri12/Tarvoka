extends SceneTree

# v3.9.8 focused deterministic behavioral test for an actual contested
# relay, road motor speed, and a genuinely unseen enemy in fog. Does
# not mutate official rules or grant an order to the AI.
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Mirror = preload("res://tests/MirrorBattleV374.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Rules = preload("res://scripts/core/Rules.gd")

const SIZE := Vector2i(40,30)

static func _units(view: Dictionary, side: int) -> Array:
    var out: Array = []
    for unit in view["units"]:
        if int(unit["faction"]) == side and int(unit["hp"]) > 0 and \
                not bool(unit.get("acted",true)):
            out.append(unit)
    return out

static func _enemies(view: Dictionary, side: int) -> Array:
    var out: Array = []
    for unit in view["units"]:
        if int(unit["faction"]) == 1-side and int(unit["hp"]) > 0:
            out.append(unit)
    return out

static func _race(state: Dictionary) -> Dictionary:
    var side: int = int(state["faction"])
    var observed: Dictionary = Visibility.observed_state(state,side)
    return AI._forecast_relay_race_v398(
        state,observed,_units(observed,side),_enemies(observed,side))

func _initialize() -> void:
    var plain: Array = Scenarios.terrain(0,SIZE)
    var top_relay := Vector2i(Scenarios.scale_x(4,SIZE),
        Scenarios.scale_y(2,SIZE))
    assert(top_relay == Vector2i(17,8))
    var ally: Dictionary = Roles.make_unit(
        "A",0,top_relay+Vector2i(-3,0),"scout")
    var enemy: Dictionary = Roles.make_unit(
        "X",1,top_relay+Vector2i(3,0),"scout")
    assert(not ally.is_empty() and not enemy.is_empty())
    var state: Dictionary = Session.start(
        [ally,enemy],plain,0,false,true,true,true,false,
        "clear",false,true)
    assert(state.has("control"))
    assert(Codec.encode(state).length() > 0)
    var original: Dictionary = state.duplicate(true)
    var race: Dictionary = _race(state)
    assert(bool(race.get("valid",false)))
    assert(str(race.get("action","")) == "move")
    assert(str(race.get("reason","")) ==
        "observed_relay_race_forecast_v398")
    assert(str(race.get("unit_id","")) == "A")
    assert(int(race.get("visible_enemy_eta",-1)) == 1)
    assert(int(race.get("own_eta",-1)) >= 1)
    assert(Codec.encode(race["state"]).length() > 0)
    assert(state == original) # No mutation while planning.
    var mirrored: Dictionary = Mirror.reflect(state)
    var reflected_race: Dictionary = _race(mirrored)
    assert(bool(reflected_race.get("valid",false)))
    assert(Mirror.signature(race,40,false) ==
        Mirror.signature(reflected_race,40,true))
    assert(Mirror.reflect(reflected_race["state"]) ==
        race["state"])

    # Identical real units, now with fog enabled: the enemy six cells
    # away is outside scout sight (vision=5). The plan must not invent it.
    var hidden: Dictionary = state.duplicate(true)
    hidden["fog_enabled"] = true
    hidden = Visibility.update_exploration(hidden)
    assert(Codec.encode(hidden).length() > 0)
    var view: Dictionary = Visibility.observed_state(hidden,0)
    assert(_enemies(view,0).is_empty())
    var no_cheat: Dictionary = _race(hidden)
    assert(not bool(no_cheat.get("valid",false)))
    assert(Codec.encode(hidden).length() > 0)

    # A 4-cell road profile costs 4 movement points to infantry and
    # only 2 to tracked vehicles, using the same weighted route code.
    var bridge: Array = Scenarios.terrain(2,SIZE)
    var road_start: Vector2i = top_relay+Vector2i(-4,0)
    assert(str(bridge[road_start.y][road_start.x]) == "road")
    var foot: Dictionary = AI._route_to_relay(
        bridge,top_relay,[],"clear","foot",false)
    var motor: Dictionary = AI._route_to_relay(
        bridge,top_relay,[],"clear","tracked",true)
    assert(foot.has(road_start) and motor.has(road_start))
    assert(int(foot[road_start]) == 4)
    assert(int(motor[road_start]) == 2)
    print("RACE398_CONTEST " + JSON.stringify({
        "direct_contested_relay":"passed",
        "mirror":"exact",
        "hidden_enemy":"never_inferred",
        "enemy_ETA":race["visible_enemy_eta"],
        "road_foot_cost":foot[road_start],
        "road_motor_cost":motor[road_start],
        "planning_mutation":false
    }))
    print("PASS TARVOKA v398 contested relay: motorized roads, honest "
        + "ETA, fog visibility, real legal movement, mirror parity")
    quit(0)
