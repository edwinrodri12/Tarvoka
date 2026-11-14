extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Support = preload("res://scripts/core/EngineerSupport.gd")
const Repair = preload("res://scripts/core/EngineerRepair.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var all_checks := 0
    for fog in [false,true]:
        for climate in ["clear","rain","snow"]:
            # Engineer sees and can approach a damaged tank without privileged
            # intel; tank is worth preserving, and no opponent is nearby.
            var state: Dictionary = _starting(fog,climate)
            var before: Dictionary = state.duplicate(true)
            var scout: Dictionary = Visibility.observed_state(state,0)
            var plan: Dictionary = Support.plan(state,scout,scout["units"][0])
            assert(plan["valid"])
            assert(plan["destination"] == Vector2i(3,2))
            assert(plan["target_id"] == "T" and plan["engineer_id"] == "ENG")
            assert(plan["estimated_repair_hp"] == 3)
            assert(plan["estimated_repair_cost"] == 105)
            assert(int(plan["net_value"]) >= 25)
            assert(state == before)
            var advanced: Dictionary = AI.step(state)
            assert(advanced["valid"] and advanced["action"] == "move")
            assert(advanced["reason"] == "engineer_support")
            assert(advanced["unit_id"] == "ENG" and advanced["recipient_id"] == "T")
            assert(advanced["destination"] == Vector2i(3,2))
            assert(advanced["state"]["units"][0]["moved"])
            assert(not bool(advanced["state"]["units"][0]["acted"]))
            assert(int(advanced["state"]["economy"]["credits"][0]) ==
                Economy.MODERN_START_CREDITS)
            assert(state == before)
            # Same turn: moving is NOT the repair; only the next, real,
            # separately validated action spends 105 credits and 1 action.
            var repaired: Dictionary = AI.step(advanced["state"])
            assert(repaired["valid"] and repaired["action"] == "repair")
            assert(repaired["target_id"] == "T" and repaired["cost"] == 105)
            assert(int(repaired["state"]["units"][1]["hp"]) == 8)
            assert(int(repaired["state"]["economy"]["credits"][0]) ==
                Economy.MODERN_START_CREDITS-105)
            assert(bool(repaired["state"]["units"][0]["acted"]))
            assert(not Session.repair(repaired["state"],"ENG","T")["valid"])
            assert(Codec.decode(Codec.encode(repaired["state"])) == repaired["state"])
            assert(advanced["state"]["units"][1]["hp"] == 5)
            all_checks += 1

    # The first phase sometimes only gets closer on a longer route, then
    # next turn reaches the service square. No teleport and no credit spend.
    var long: Dictionary = _starting(false,"clear")
    long["units"][1]["pos"] = Vector2i(6,2)
    var long_plan: Dictionary = Support.plan(long,Visibility.observed_state(long,0),long["units"][0])
    assert(long_plan["valid"] and int(long_plan["remaining_cost"]) > 0)
    var first: Dictionary = AI.step(long)
    assert(first["valid"] and first["reason"] == "engineer_support")
    assert(int(first["state"]["economy"]["credits"][0]) == Economy.MODERN_START_CREDITS)
    # Prevent hostile actuation in the interim; original state remains intact.
    var next_phase: Dictionary = first["state"].duplicate(true)
    next_phase["units"][0]["moved"] = false
    var later: Dictionary = AI.step(next_phase)
    assert(later["valid"] and later["reason"] == "engineer_support")
    assert(int(later["remaining_cost"]) == 0)
    assert(later["state"]["units"][0]["pos"] != first["state"]["units"][0]["pos"])
    var finally_repaired: Dictionary = AI.step(later["state"])
    assert(finally_repaired["valid"] and finally_repaired["action"] == "repair")
    all_checks += 1

    # Never abandon a neutral city on which a capturing engineer stands.
    var capturing: Dictionary = _starting(false,"clear")
    capturing["units"][0]["pos"] = Vector2i(3,4)
    capturing["units"][1]["pos"] = Vector2i(6,4)
    assert(not Support.plan(capturing,Visibility.observed_state(capturing,0),
        capturing["units"][0])["valid"])

    # A cheap Baluarte costs LESS per replaced HP than 35 credits/HP.
    var cheap: Dictionary = _starting(false,"clear")
    cheap["units"][1] = Roles.make_unit("T",0,Vector2i(4,2),"bulwark")
    cheap["units"][1]["hp"] = 5
    assert(not Support.plan(cheap,Visibility.observed_state(cheap,0),
        cheap["units"][0])["valid"])

    # No subsidized order and no credit debt for wounded expensive tanks.
    var broke: Dictionary = _starting(false,"clear")
    broke["economy"]["credits"][0] = 69
    assert(not Support.plan(broke,Visibility.observed_state(broke,0),
        broke["units"][0])["valid"])

    # No support order into lethal observable fire; use public enemy stats,
    # not the enemy's hidden ammo, fuel, acted or reacted fields.
    var threatened: Dictionary = _starting(false,"clear")
    threatened["units"][2] = Roles.make_unit("E",1,Vector2i(4,4),"tank")
    assert(not Support.plan(threatened,Visibility.observed_state(threatened,0),
        threatened["units"][0])["valid"])
    var threat_modified: Dictionary = threatened.duplicate(true)
    threat_modified["units"][2]["ammo"] = 0
    threat_modified["units"][2]["fuel"] = 0
    threat_modified["units"][2]["acted"] = true
    assert(Support.plan(threat_modified,Visibility.observed_state(threat_modified,0),
        threat_modified["units"][0]) ==
        Support.plan(threatened,Visibility.observed_state(threatened,0),
        threatened["units"][0]))

    # Allies can be crossed but NOT used as a destination, exactly as in
    # Rules.reachable and the player's MoveActions.
    var convoy: Dictionary = _starting(false,"clear")
    convoy["units"].insert(1,Roles.make_unit("BLOCK",0,Vector2i(2,2),"line"))
    var expected: Dictionary = Support.plan(convoy,Visibility.observed_state(convoy,0),
        convoy["units"][0])
    assert(expected["valid"] and expected["destination"] == Vector2i(3,2))
    assert(not (expected["destination"] == convoy["units"][1]["pos"]))

    # Completely impassable divider: absolutely no false positive route.
    var partition: Dictionary = _starting(false,"clear")
    partition["units"][0]["pos"] = Vector2i(3,3)
    partition["units"][1]["pos"] = Vector2i(6,3)
    for y in range(8):
        partition["terrain"][y][4] = "water"
    assert(not Support.plan(partition,Visibility.observed_state(partition,0),
        partition["units"][0])["valid"])

    # Fog secrecy: moving an unseen rival and changing its ammunition and
    # bank balance cannot alter our choice, target, road or expected expense.
    var hidden: Dictionary = _starting(true,"clear")
    var altered: Dictionary = hidden.duplicate(true)
    altered["units"][2]["pos"] = Vector2i(8,7)
    altered["units"][2]["hp"] = 1
    altered["units"][2]["ammo"] = 0
    altered["economy"]["credits"][1] = 99999
    assert(not Visibility.is_unit_visible(hidden,0,"E"))
    assert(not Visibility.is_unit_visible(altered,0,"E"))
    var hidden_plan: Dictionary = Support.plan(hidden,Visibility.observed_state(hidden,0),
        Visibility.observed_state(hidden,0)["units"][0])
    var altered_plan: Dictionary = Support.plan(altered,Visibility.observed_state(altered,0),
        Visibility.observed_state(altered,0)["units"][0])
    assert(hidden_plan == altered_plan and hidden_plan["valid"])
    assert(AI.step(hidden)["destination"] == AI.step(altered)["destination"])

    # Real two-side symmetry: same side-relative choice, same repair cost.
    var right: Dictionary = Session.start([
        Roles.make_unit("E_R",1,Vector2i(8,2),"engineer"),
        Roles.make_unit("T_R",1,Vector2i(5,2),"tank"),
        Roles.make_unit("E_L",0,Vector2i(0,7),"line")
    ],Scenarios.terrain(0),1,false,false,true,true)
    right["units"][1]["hp"] = 5
    var reverse: Dictionary = Visibility.observed_state(right,1)
    var mirrored: Dictionary = Support.plan(right,reverse,reverse["units"][0])
    assert(mirrored["valid"] and mirrored["destination"] == Vector2i(6,2))
    var match: Dictionary = AI.step(right)
    assert(match["valid"] and match["reason"] == "engineer_support")
    var fix: Dictionary = AI.step(match["state"])
    assert(fix["valid"] and fix["action"] == "repair" and fix["cost"] == 105)
    assert(Codec.decode(Codec.encode(fix["state"])) == fix["state"])

    # A genuinely purchased engineer cannot act on its recruitment turn.
    # Upon receiving the next faction turn it can use normal move/repair
    # actions; army upkeep and income stay on their normal timeline.
    var recruited: Dictionary = Session.start([
        Roles.make_unit("T0",0,Vector2i(3,3),"tank"),
        Roles.make_unit("R0",1,Vector2i(9,7),"line")
    ],Scenarios.terrain(0),0,false,false,true,true)
    recruited["units"][0]["hp"] = 5
    var bought: Dictionary = Session.purchase(recruited,Vector2i(0,3),"engineer")
    assert(bought["valid"] and bought["role"] == "engineer")
    var new_id := str(bought["state"]["units"].back()["id"])
    assert(bool(bought["state"]["units"].back()["acted"]))
    assert(int(bought["state"]["economy"]["credits"][0]) ==
        Economy.MODERN_START_CREDITS-Economy.cost("engineer"))
    assert(not Repair.quote(bought["state"],new_id,"T0")["valid"])
    var enemy_phase: Dictionary = Session.end_turn(bought["state"])
    assert(enemy_phase["valid"] and enemy_phase["state"]["faction"] == 1)
    var friendly_phase: Dictionary = Session.end_turn(enemy_phase["state"])
    assert(friendly_phase["valid"] and friendly_phase["state"]["faction"] == 0)
    var escort_order: Dictionary = AI.step(friendly_phase["state"])
    assert(escort_order["valid"] and escort_order["reason"] == "engineer_support")
    assert(escort_order["unit_id"] == new_id)
    var workshop_repair: Dictionary = AI.step(escort_order["state"])
    assert(workshop_repair["valid"] and workshop_repair["action"] == "repair")
    assert(workshop_repair["cost"] == 105 and workshop_repair["restored"] == 3)
    assert(Codec.decode(Codec.encode(workshop_repair["state"])) ==
        workshop_repair["state"])
    all_checks += 1

    # Exercise exactly the existing 40x30 gameplay map limit with a real
    # chassis: this tests 1200 walkable tiles, NOT 8-player multiplayer.
    var arena: Array = []
    for y in range(30):
        var row: Array = []
        for x in range(40):
            row.append("plain")
        arena.append(row)
    var massive: Dictionary = Session.start([
        Roles.make_unit("EL",0,Vector2i(4,6),"engineer"),
        Roles.make_unit("TL",0,Vector2i(7,6),"tank"),
        Roles.make_unit("RL",1,Vector2i(38,26),"line")
    ],arena,0,false,false,true,true)
    massive["units"][1]["hp"] = 5
    var big_plan: Dictionary = Support.plan(massive,
        Visibility.observed_state(massive,0),massive["units"][0])
    assert(big_plan["valid"] and big_plan["destination"] == Vector2i(6,6))
    var big_move: Dictionary = AI.step(massive)
    assert(big_move["valid"] and big_move["reason"] == "engineer_support")
    assert(big_move["destination"] == Vector2i(6,6))
    assert(AI.step(big_move["state"])["action"] == "repair")
    all_checks += 1

    print("PASS engineer support navigation: %d move+repair scenarios, multistep, value, threatened, terrain, allied transit, city, fog and mirrored sides" % all_checks)
    quit(0)

static func _starting(fog: bool,climate: String) -> Dictionary:
    var state: Dictionary = Session.start([
        Roles.make_unit("ENG",0,Vector2i(1,2),"engineer"),
        Roles.make_unit("T",0,Vector2i(4,2),"tank"),
        Roles.make_unit("E",1,Vector2i(9,7),"line")
    ],Scenarios.terrain(0),0,fog,false,true,true,false,climate)
    assert(bool(state.get("economy",{}).get("modern",false)))
    state["units"][1]["hp"] = 5
    return state
