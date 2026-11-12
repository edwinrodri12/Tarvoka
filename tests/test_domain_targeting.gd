extends SceneTree

const Domains = preload("res://scripts/core/Domains.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    assert(Domains.valid_domain("ground"))
    assert(Domains.valid_domain("air"))
    assert(Domains.valid_domain("naval"))
    assert(not Domains.valid_domain("space"))
    assert(Domains.valid_targets(["air", "ground"]))
    assert(Domains.valid_targets([]))
    assert(not Domains.valid_targets(["air", "air"]))
    assert(not Domains.valid_targets(["space"]))
    assert(not Domains.valid_targets("all"))
    assert(not Domains.valid_targets(["ground", "air", "naval", "space"]))

    var soldier: Dictionary = Roles.make_unit("A", 0, Vector2i(1,1), "line")
    var rival: Dictionary = Roles.make_unit("X", 1, Vector2i(2,1), "line")
    var plane: Dictionary = rival.duplicate(true)
    plane["domain"] = "air"
    var ship: Dictionary = rival.duplicate(true)
    ship["domain"] = "naval"
    assert(Turns.in_attack_range(soldier,rival))
    assert(not Turns.in_attack_range(soldier,plane))
    assert(not Turns.in_attack_range(soldier,ship))
    assert(Domains.can_attack(soldier,rival))
    assert(not Domains.can_attack(soldier,plane))
    var aa: Dictionary = soldier.duplicate(true)
    aa["target_domains"] = ["air"]
    assert(not Turns.in_attack_range(aa,rival))
    assert(Turns.in_attack_range(aa,plane))
    assert(not Turns.in_attack_range(aa,ship))
    var multi: Dictionary = soldier.duplicate(true)
    multi["target_domains"] = ["ground","air"]
    assert(Turns.in_attack_range(multi,rival))
    assert(Turns.in_attack_range(multi,plane))
    assert(not Turns.in_attack_range(multi,ship))
    var antisub: Dictionary = soldier.duplicate(true)
    antisub["target_domains"] = ["naval"]
    assert(Turns.in_attack_range(antisub,ship))
    assert(not Turns.in_attack_range(antisub,plane))

    var state: Dictionary = Session.start([soldier, plane], Scenarios.terrain(0))
    var snapshot: Dictionary = state.duplicate(true)
    assert(not Session.attack(state,"A","X")["valid"])
    assert(Hints.for_unit(state,"A")["attacks"].is_empty())
    assert(not AI.step(state).get("action","") == "attack")
    assert(state == snapshot)

    var air_defense: Dictionary = Session.start([aa,plane],Scenarios.terrain(0))
    var preview: Dictionary = Hints.for_unit(air_defense,"A")
    assert(preview["attacks"].has(Vector2i(2,1)))
    assert(air_defense == Codec.decode(Codec.encode(air_defense)))
    var result: Dictionary = Session.attack(air_defense,"A","X")
    assert(result["valid"])
    assert(result["state"]["units"][1]["hp"] < plane["hp"])
    assert(Codec.decode(Codec.encode(result["state"])) == result["state"])
    assert(not Session.attack(result["state"],"A","X")["valid"])
    var ai_action: Dictionary = AI.step(air_defense)
    assert(ai_action["valid"] and ai_action["action"] == "attack")
    assert(ai_action["state"]["units"][1]["hp"] == result["state"]["units"][1]["hp"])
    assert(air_defense["units"][1]["hp"] == plane["hp"])

    # Existing version 1 saves remain EXACTLY unchanged when fields are absent.
    var legacy: Dictionary = Session.start([soldier,rival],Scenarios.terrain(0))
    var raw: String = Codec.encode(legacy)
    assert(not raw.is_empty())
    assert(not raw.contains("domain"))
    assert(Codec.decode(raw) == legacy)

    # Both JSON ingestion and export reject malformed/falsified domain claims.
    for malicious in [
        {"domain":"space"},
        {"domain":7},
        {"target_domains":["space"]},
        {"target_domains":["air","air"]},
        {"target_domains":"air"},
        {"target_domains":[42]}
    ]:
        var invalid: Dictionary = air_defense.duplicate(true)
        invalid["units"][0].merge(malicious,true)
        assert(Codec.encode(invalid).is_empty())
        var forged: Dictionary = JSON.parse_string(Codec.encode(air_defense))
        for key in malicious:
            forged["units"][0][key] = malicious[key]
        assert(Codec.decode(JSON.stringify(forged)).is_empty())
    print("PASS domain target legality: ground/air/naval, anti-air, previews, AI, strict JSON, legacy saves")
    quit(0)
