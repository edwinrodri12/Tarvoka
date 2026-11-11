extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Combat = preload("res://scripts/core/Combat.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    var roster: Array = Roles.experimental_armies()
    assert(roster.size() == 10)
    assert(Roles.ORDER.size() == 5)
    var unique: Dictionary = {}
    for i in range(roster.size()):
        var unit: Dictionary = roster[i]
        assert(not unique.has(unit["id"]))
        unique[unit["id"]] = true
        assert(Roles.valid(unit["role"]))
        assert(unit["move_points"] > 0 and unit["hp"] > 0)
        assert(unit["attack_min_range"] <= unit["attack_range"])
        assert(unit["pos"].x == (1 if unit["faction"] == 0 else 8))
        assert(Roles.label(unit["role"]) != "Soldado")
        assert(Roles.symbol(unit["role"]) != "")
    assert(Roles.is_specialized(roster))
    assert(not Roles.is_specialized([{"id":"legacy"}]))
    assert(Roles.make_unit("A", 3, Vector2i(1,1), "line").is_empty())
    assert(Roles.make_unit("A", 0, Vector2i(1,1), "unsupported").is_empty())
    for scenario_id in range(Scenarios.LABELS.size()):
        var terrain: Array = Scenarios.terrain(scenario_id)
        for unit in roster:
            var cell: Vector2i = unit["pos"]
            assert(Rules.movement_cost(terrain[cell.y][cell.x]) >= 0)
        var battlefield: Dictionary = Session.start(roster, terrain, 0, true)
        assert(battlefield["winner"] == -1)
        assert(Codec.decode(Codec.encode(battlefield)) == battlefield)

    # Guarded counters: this is a measurable rock-paper-scissors interaction,
    # not a generic bonus, and neither faction gains an undisclosed advantage.
    var piercer: Dictionary = Roles.make_unit("P",0,Vector2i(1,2),"piercer")
    var bulwark: Dictionary = Roles.make_unit("B",1,Vector2i(2,2),"bulwark")
    var line: Dictionary = Roles.make_unit("L",0,Vector2i(1,2),"line")
    assert(Roles.role_bonus(piercer,bulwark) == 4)
    assert(Roles.role_bonus(line,bulwark) == 0)
    assert(Roles.role_bonus(bulwark,piercer) == 0)
    assert(Roles.resolve(piercer,bulwark)["damage"] == 6)
    assert(Roles.resolve(line,bulwark)["damage"] == 3)
    assert(Roles.resolve(bulwark,piercer)["damage"] == 3)
    var classic_attacker: Dictionary = {"hp":10,"attack":5}
    var classic_defender: Dictionary = {"hp":10,"defense":1,"cover":0}
    assert(Roles.resolve(classic_attacker,classic_defender) == Combat.resolve(10,10,5,1,0))
    assert(Roles.role_bonus(classic_attacker,bulwark) == 0)

    var state: Dictionary = Session.start([piercer,bulwark],Scenarios.terrain(0))
    var before: Dictionary = state.duplicate(true)
    var hints: Dictionary = Hints.for_unit(state,"P")
    assert(hints["attacks"][Vector2i(2,2)]["damage"] == 6)
    assert(Hints.unit_summary(state,"P").contains("Rompedor"))
    assert(Hints.unit_summary(state,"P").contains("Baluarte (+4 ATQ)"))
    var action: Dictionary = Session.attack(state,"P","B")
    assert(action["valid"] and action["state"]["units"][1]["hp"] == 6)
    assert(state == before)
    assert(not Session.attack(action["state"],"P","B")["valid"])

    var scout: Dictionary = Roles.make_unit("S",0,Vector2i(1,2),"scout")
    var platform: Dictionary = Roles.make_unit("M",1,Vector2i(2,2),"artillery")
    assert(Roles.role_bonus(scout,platform) == 3)
    assert(Roles.resolve(scout,platform)["damage"] == 5)
    assert(Roles.resolve(line,platform)["damage"] == 5)
    platform["pos"] = Vector2i(3,2)
    assert(Roles.role_bonus(scout,bulwark) == 0)
    var artillery: Dictionary = Roles.make_unit("A",0,Vector2i(1,1),"artillery")
    bulwark["pos"] = Vector2i(3,1)
    var bombard: Dictionary = Session.start([artillery,bulwark],Scenarios.terrain(0))
    assert(Hints.for_unit(bombard,"A")["attacks"].has(Vector2i(3,1)))
    assert(Session.attack(bombard,"A","B")["valid"])
    bulwark["pos"] = Vector2i(2,1)
    var too_close: Dictionary = Session.start([artillery,bulwark],Scenarios.terrain(0))
    assert(not Session.attack(too_close,"A","B")["valid"])

    var wrong: Dictionary = bombard.duplicate(true)
    wrong["units"][0]["role"] = "nonexistent"
    assert(Codec.encode(wrong).is_empty())
    wrong = bombard.duplicate(true)
    wrong["units"][0]["role"] = 17
    assert(Codec.encode(wrong).is_empty())
    var damaged: Dictionary = bombard.duplicate(true)
    damaged["units"][0]["hp"] = 3
    assert(Codec.decode(Codec.encode(damaged)) == damaged)

    # AI must evaluate the same bonus and prioritize a real lethal strike.
    var ai_piercer: Dictionary = Roles.make_unit("Q",0,Vector2i(1,2),"piercer")
    var ai_bulwark: Dictionary = Roles.make_unit("H",1,Vector2i(2,2),"bulwark")
    ai_bulwark["hp"] = 6
    var ai_state: Dictionary = Session.start([ai_piercer,ai_bulwark],Scenarios.terrain(0))
    var ai_action: Dictionary = AI.step(ai_state)
    assert(ai_action["valid"] and ai_action["action"] == "attack")
    assert(ai_action["state"]["winner"] == 0)
    assert(ai_state["winner"] == -1)
    print("PASS role catalog: mirrored rosters, pure matchup bonus, authoritative attack preview, AI and v1 saves")
    quit(0)
