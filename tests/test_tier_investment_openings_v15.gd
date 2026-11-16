extends SceneTree

# Actual Session purchases over FIVE own phases. No combat, so this does
# not claim win rates or superiority of five APC versus a tank + piercer.
const Lab = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var trials := 0
    for side in [0,1]:
        var army: Dictionary = _simulate(side,false)
        var upgrades: Dictionary = _simulate(side,true)
        assert(int(army["purchased"]) == 5 and int(army["apc"]) == 5)
        assert(int(upgrades["purchased"]) == 2 and int(upgrades["tank"]) == 1 and int(upgrades["piercer"]) == 1)
        assert(int(army["spent"]) == 1500 and int(upgrades["spent"]) == 3200)
        assert(int(army["credits_end"]) == 2000 and int(upgrades["credits_end"]) == 300)
        assert(int(army["turns"]) == 5 and int(upgrades["turns"]) == 5)
        assert(int(upgrades["levels"]) == 3)
        assert(bool(upgrades["has_antiarmor"]))
        assert(not bool(army["has_antiarmor"]))
        assert(int(upgrades["revenue"]) == 1000)
        assert(int(army["revenue"]) == 1000)
        assert(int(army["credits_end"]) == Economy.MODERN_START_CREDITS + int(army["revenue"])-int(army["spent"]))
        assert(int(upgrades["credits_end"]) == Economy.MODERN_START_CREDITS + int(upgrades["revenue"])-int(upgrades["spent"]))
        print("INVESTMENT_OPENING side=%d mass=%s tier_advanced=%s cheap_has_3_more_units=true advanced_tech_affects_piercer_only=true" % [
            side,str(army),str(upgrades)
        ])
        trials += 1
    assert(trials == 2)
    print("PASS tier investment openings v15: five owned phases, two mirrored factions, actual factory slots, prices, credit flow, 5 APC versus tank+piercer with antiarmor research")
    quit(0)

static func _terrain() -> Array:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    return terrain

static func _start(side: int) -> Dictionary:
    return Session.start([
        Roles.make_unit("DEF0",0,Vector2i(2,2),"line"),
        Roles.make_unit("DEF1",1,Vector2i(7,2),"line")
    ],_terrain(),side,false,false,true,true)

static func _plant(side: int) -> Vector2i:
    return Vector2i(0,1) if side == 0 else Vector2i(9,1)

static func _step_next(state: Dictionary, progress: Dictionary,side: int) -> Dictionary:
    var a: Dictionary = Lab.end_turn(state,progress)
    assert(a.get("valid",false))
    assert(int(a["state"]["faction"]) == 1-side)
    var b: Dictionary = Lab.end_turn(a["state"],a["progress"])
    assert(b.get("valid",false))
    assert(int(b["state"]["faction"]) == side)
    return b

static func _simulate(side: int, advanced: bool) -> Dictionary:
    var state: Dictionary = _start(side)
    var progress: Dictionary = {}
    var plant: Vector2i = _plant(side)
    assert(Economy.valid(state["economy"],state["terrain"]))
    var output: Dictionary = {"turns":0,"purchased":0,"apc":0,"tank":0,
        "piercer":0,"spent":0,"credits_end":0,"revenue":0,
        "levels":1,"has_antiarmor":false}
    var last_produced := ""
    var production_cost := 0
    for turn in range(5):
        assert(int(state["faction"]) == side)
        if turn > 0:
            var before_cash: int = int(state["economy"]["credits"][side])
            var changed: Dictionary = _step_next(state,progress,side)
            state = changed["state"]
            progress = changed["progress"]
            output["revenue"] += int(state["economy"]["credits"][side])-before_cash
        var order: Dictionary = {}
        if advanced:
            if turn == 0:
                order = Lab.upgrade(state,progress,plant)
            elif turn == 1:
                order = Lab.recruit(state,progress,plant,"tank")
            elif turn == 2:
                var clear: Dictionary = Session.move(state,last_produced,
                    Vector2i(1,1) if side == 0 else Vector2i(8,1))
                assert(clear.get("valid",false))
                state = clear["state"]
                order = Lab.upgrade(state,progress,plant)
            elif turn == 3:
                order = Lab.research(state,progress,plant,"antiarmor_v1")
            elif turn == 4:
                order = Lab.recruit(state,progress,plant,"piercer")
        else:
            if turn > 0:
                var y: int = turn
                var clear: Dictionary = Session.move(state,last_produced,
                    Vector2i(1,y) if side == 0 else Vector2i(8,y))
                assert(clear.get("valid",false))
                state = clear["state"]
            order = Lab.recruit(state,progress,plant,"apc")
        assert(order.get("valid",false))
        assert(int(order.get("cost",0)) > 0)
        output["spent"] += int(order["cost"])
        output["turns"] += 1
        state = order["state"]
        progress = order["progress"]
        if str(order.get("action","")) in ["upgrade","research"]:
            assert(int(Economy.site_at(state["economy"],plant)["produced_turn"]) ==
                int(state["economy"]["turn"]))
        else:
            assert(str(order.get("reason","")) == "experimental_tier_recruitment")
            var role: String = str(order["role"])
            output[role] = int(output.get(role,0))+1
            output["purchased"] += 1
            last_produced = str(order["unit_id"])
        assert(Economy.valid(state["economy"],state["terrain"]))
    output["credits_end"] = int(state["economy"]["credits"][side])
    output["levels"] = Lab.level_for(state,progress,plant)
    output["has_antiarmor"] = Lab.has_tech(progress,side,"antiarmor_v1")
    return output
