extends SceneTree

# Turns are ordered, not realtime. The starter can act with initial cash
# only; the responder gets owned-city income ON opening of its FIRST turn.
# When the starter gets its second turn it earns its own regular income.
# This is an audit of CURRENT rules, not an additional handicap bonus.
const Match = preload("res://scripts/experiments/StrategicMatchBalanceV21.gd")
const Orders = preload("res://scripts/experiments/FixedSiteOrdersV19.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

const MAP_SIZES := [
    Vector2i(10,8),
    Vector2i(24,18),
    Vector2i(40,30)
]
const EXPECTED_LAB_INCOME := {
    "10x8":250,
    "24x18":166,
    "40x30":186
}

static func _key(size: Vector2i) -> String:
    return "%dx%d" % [size.x,size.y]

static func _audit_distributed_cities(size: Vector2i, starter: int) -> void:
    var b: Dictionary = Match.start(0,size,starter)
    assert(b.get("valid",false))
    var session: Dictionary = b["session"]
    var state: Dictionary = session["world"]["state"]
    var income: int = int(session["world"]["layout"]["starting_income_each"])
    assert(income == int(EXPECTED_LAB_INCOME[_key(size)]))
    assert(int(state["faction"]) == starter)
    assert(int(state["economy"]["credits"][0]) == Economy.MODERN_START_CREDITS)
    assert(int(state["economy"]["credits"][1]) == Economy.MODERN_START_CREDITS)
    assert(int(session["world"]["layout"]["neutral_cities"]) >= 0)
    var expected := [Economy.MODERN_START_CREDITS,Economy.MODERN_START_CREDITS]
    for phase in range(4):
        var current: int = int(state["faction"])
        assert(current == (starter if phase%2 == 0 else 1-starter))
        var next: Dictionary = Orders.end_turn(session)
        assert(bool(next.get("valid",false)))
        session = next["session"]
        state = session["world"]["state"]
        var recipient: int = 1-current
        assert(int(state["faction"]) == recipient)
        expected[recipient] = int(expected[recipient])+income
        assert(int(state["economy"]["credits"][recipient]) == int(expected[recipient]))
        assert(int(state["economy"]["credits"][current]) == int(expected[current]))
        assert(int(state["winner"]) == -1)
        assert(int(session["world"]["layout"]["starting_income_each"]) == income)
        print("OPENING_INCOME_V24 mode=territorial size=%s starter=%d phase=%d begins=%d credits=(%d,%d) newly_paid=%d" % [
            _key(size),starter,phase+1,recipient,
            int(expected[0]),int(expected[1]),income])
    assert(int(expected[starter]) == Economy.MODERN_START_CREDITS+2*income)
    assert(int(expected[1-starter]) == Economy.MODERN_START_CREDITS+2*income)

static func _audit_current_core(size: Vector2i, starter: int) -> void:
    var terrain: Array = Scenarios.terrain(0,size)
    var units: Array = [
        Roles.make_unit("BASE0",0,Vector2i(1,1),"line"),
        Roles.make_unit("BASE1",1,Vector2i(size.x-2,size.y-2),"line")
    ]
    var state: Dictionary = Session.start(units,terrain,starter,
        false,false,true,true)
    assert(state.has("economy"))
    assert(Economy.valid(state["economy"],terrain))
    assert(int(state["economy"]["credits"][0]) == Economy.MODERN_START_CREDITS)
    assert(int(state["economy"]["credits"][1]) == Economy.MODERN_START_CREDITS)
    var initial_income: int = Economy.income_for(state["economy"],starter)
    var second_income: int = Economy.income_for(state["economy"],1-starter)
    assert(initial_income == Economy.MODERN_CITY_INCOME)
    assert(second_income == Economy.MODERN_CITY_INCOME)
    for phase in range(2):
        var from: int = int(state["faction"])
        var next: Dictionary = Session.end_turn(state)
        assert(next.get("valid",false))
        state = next["state"]
        var to: int = 1-from
        assert(int(state["faction"]) == to)
        assert(int(state["economy"]["credits"][to]) == \
            Economy.MODERN_START_CREDITS+Economy.MODERN_CITY_INCOME)
        assert(int(state["economy"]["credits"][from]) == \
            (Economy.MODERN_START_CREDITS if phase == 0 else \
            Economy.MODERN_START_CREDITS+Economy.MODERN_CITY_INCOME))
    print("OPENING_INCOME_V24 mode=current_core size=%s starter=%d starter_first=%d responder_first=%d both_second=%d" % [
        _key(size),starter,Economy.MODERN_START_CREDITS,
        Economy.MODERN_START_CREDITS+Economy.MODERN_CITY_INCOME,
        Economy.MODERN_START_CREDITS+Economy.MODERN_CITY_INCOME])

func _initialize() -> void:
    for size in MAP_SIZES:
        for starter in [0,1]:
            _audit_distributed_cities(size,starter)
            _audit_current_core(size,starter)
    print("PASS opening income fairness v24: 3 map sizes x 2 initiative orders x 2 economies; only responder gets first-turn income, then starter gets normal income once")
    quit(0)
