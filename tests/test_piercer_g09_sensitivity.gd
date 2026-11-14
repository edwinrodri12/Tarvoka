extends SceneTree

# Evidence-first A/B test: the real Godot combat preview and the real
# authoritative attack run on temporary copies. Candidate bonuses are
# NEVER entered in save files nor a live balance table by this test.
# A tank-only counter must not raise all attacks against every ground target.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")

const CANDIDATES := [0,1,2,4]
const TARGETS := ["tank","bulwark","ifv","apc","line","spg"]
const ENVIRONMENTS := ["plain","road","forest","mountain","city"]

static func _setup(target_role: String, environment: String, first: int = 0) -> Dictionary:
    var terrain: Array = Scenarios.terrain(0)
    var at := Vector2i(2,2)
    var defend := Vector2i(3,2)
    if environment == "city":
        at = Vector2i(2,4)
        defend = Vector2i(3,4) # Actual neutral city from UrbanEconomy.
    elif environment != "plain":
        terrain[defend.y][defend.x] = environment
    var state: Dictionary = Session.start([
        Roles.make_unit("P",0,at,"piercer"),
        Roles.make_unit("T",1,defend,target_role)
    ],terrain,first,false,false,true,true)
    assert(not state.is_empty() and bool(state["economy"]["modern"]))
    assert(Economy.valid(state["economy"],terrain))
    return state

# Normalize the hypothetical attack to the requested bonus, whatever the
# officially published role_bonus currently is (0 initially, 2 if approved).
static func _probe(state: Dictionary, bonus: int) -> Dictionary:
    var target: Dictionary = state["units"][1]
    var effective: Dictionary = state.duplicate(true)
    var attack: Dictionary = effective["units"][0]
    var base_bonus: int = Roles.role_bonus(attack,target)
    if str(target["role"]) == "tank":
        attack["attack"] = int(attack["attack"])+bonus-base_bonus
    return effective

func _initialize() -> void:
    assert(Economy.cost("piercer") == 300)
    assert(Economy.cost("tank") == 750)
    assert(int(Roles.PROFILES["piercer"]["hp"]) == 8)
    assert(int(Arsenal.PROFILES["tank"]["hp"]) == 14)
    assert(Doctrine.profile("tank")["armor"] == "pesada")
    assert(Doctrine.reaction_percent("tank") == 60)

    var rows: Array = []
    var baseline: Dictionary = {}
    var comparison: Dictionary = {}
    var verified := 0
    for role in TARGETS:
        for environment in ENVIRONMENTS:
            var source: Dictionary = _setup(role,environment)
            var original: Dictionary = source.duplicate(true)
            var previous_damage := -1
            var untouched_damage := -1
            for candidate in CANDIDATES:
                var hypothetical: Dictionary = _probe(source,candidate)
                var att: Dictionary = hypothetical["units"][0]
                var def: Dictionary = hypothetical["units"][1]
                assert(Logistics.valid_unit(att) and Logistics.valid_unit(def))
                var forecast: Dictionary = Actions.preview_exchange(
                    att,def,true,hypothetical["terrain"],
                    hypothetical["economy"],hypothetical["units"])
                assert(bool(forecast.get("valid",false)))
                # Compare the literal, authoritative Session.attack with the
                # very same preview; no handwritten combat approximation.
                var result: Dictionary = Session.attack(hypothetical,"P","T")
                assert(bool(result.get("valid",false)))
                assert(int(result["damage"]) == int(forecast["damage"]))
                assert(int(result["counter_damage"]) == int(forecast["counter_damage"]))
                assert(int(result["state"]["units"][0]["hp"]) == int(forecast["attacker_hp"]))
                assert(int(result["state"]["units"][1]["hp"]) == int(forecast["defender_hp"]))
                assert(int(result["state"]["units"][0]["ammo"]) ==
                    Logistics.ammo_capacity("piercer")-1)
                assert(hypothetical["units"][0]["hp"] == 8 and source == original)
                assert(Codec.decode(Codec.encode(result["state"])) == result["state"])
                var damage: int = int(forecast["damage"])
                if previous_damage != -1:
                    assert(damage >= previous_damage)
                previous_damage = damage
                if role != "tank":
                    if untouched_damage == -1:
                        untouched_damage = damage
                    assert(untouched_damage == damage)
                if role == "tank" and environment == "plain":
                    var expected: Dictionary = {0:2,1:3,2:4,4:6}
                    assert(damage == int(expected[candidate]))
                if role == "tank" and environment == "forest":
                    var expected_forest: Dictionary = {0:1,1:2,2:3,4:5}
                    assert(damage == int(expected_forest[candidate]))
                if role == "tank" and environment == "mountain":
                    var expected_mountain: Dictionary = {0:1,1:1,2:1,4:3}
                    assert(damage == int(expected_mountain[candidate]))
                if role == "tank" and environment == "city":
                    var expected_city: Dictionary = {0:1,1:2,2:3,4:5}
                    assert(damage == int(expected_city[candidate]))
                if role == "tank" and candidate == 2:
                    assert(damage <= 4) # Tank still needs several hits.
                if role == "bulwark" and environment == "plain":
                    assert(damage == 6) # Preserve specialized +4.
                rows.append({
                    "target":role,"terrain":environment,
                    "candidate_bonus":candidate,"damage":damage,
                    "counter_damage":int(forecast["counter_damage"]),
                    "piercer_hp_after":int(forecast["attacker_hp"]),
                    "target_hp_after":int(forecast["defender_hp"]),
                    "shots_without_reply":ceili(float(def["hp"])/float(maxi(1,damage)))
                })
                verified += 1

    assert(verified == TARGETS.size()*ENVIRONMENTS.size()*CANDIDATES.size())
    # Four comparisons for each role/environment: only G09 may change.
    for row in rows:
        if row["target"] == "tank" and row["terrain"] == "plain":
            comparison[row["candidate_bonus"]] = {
                "damage":row["damage"],
                "counter":row["counter_damage"],
                "piercer_hp_after":row["piercer_hp_after"],
                "shots_to_kill":row["shots_without_reply"]
            }
    assert(int(comparison[0]["shots_to_kill"]) == 7)
    assert(int(comparison[2]["shots_to_kill"]) == 4)
    assert(int(comparison[2]["piercer_hp_after"]) > 0)
    assert(int(comparison[2]["piercer_hp_after"]) < 8)
    assert(int(comparison[2]["shots_to_kill"]) > 2)

    # Two real 300-credit piercers against a 750-credit tank. A G09 may
    # counter only once per attacking phase, even after both shots.
    for side in [0,1]:
        var two: Dictionary = Session.start([
            Roles.make_unit("P1",0,Vector2i(2,2),"piercer"),
            Roles.make_unit("P2",0,Vector2i(3,3),"piercer"),
            Roles.make_unit("G09",1,Vector2i(3,2),"tank")
        ],Scenarios.terrain(0),side,false,false,true,true)
        var original_two: Dictionary = two.duplicate(true)
        if side == 0:
            var adjusted: Dictionary = two.duplicate(true)
            for i in [0,1]:
                adjusted["units"][i]["attack"] += 2 - Roles.role_bonus(
                    adjusted["units"][i],adjusted["units"][2])
            var first: Dictionary = Session.attack(adjusted,"P1","G09")
            assert(first["valid"] and first["damage"] == 4)
            assert(first["counter_damage"] == 4)
            assert(first["state"]["units"][0]["hp"] == 4)
            assert(first["state"]["units"][2]["hp"] == 10)
            var second: Dictionary = Session.attack(first["state"],"P2","G09")
            assert(second["valid"] and second["damage"] == 4)
            assert(second["counter_damage"] == 0)
            assert(second["state"]["units"][2]["hp"] == 6)
            assert(second["state"]["units"][1]["hp"] == 8)
            assert(Codec.decode(Codec.encode(second["state"])) == second["state"])
        else:
            var first_tank: Dictionary = Session.attack(two,"G09","P1")
            assert(first_tank["valid"] and first_tank["damage"] == 8)
            assert(first_tank["state"]["units"][0]["hp"] == 0)
            assert(first_tank["state"]["units"][2]["hp"] == 14)
            var passed: Dictionary = Session.end_turn(first_tank["state"])
            assert(passed["valid"] and passed["state"]["faction"] == 0)
        assert(two == original_two)

    # Direct price comparison is an INPUT to tuning, not a win-rate claim:
    # two piercers cost 600 (< 750 for a G09), but can still be destroyed.
    assert(Economy.cost("piercer")*2 < Economy.cost("tank"))
    var report: Dictionary = {
        "schema":"tarvoka.piercer_g09_sensitivity.v1",
        "status":"counterfactual_real_engine_not_pvp_balance_certificate",
        "current_official_bonus":Roles.role_bonus(
            Roles.make_unit("P",0,Vector2i(2,2),"piercer"),
            Roles.make_unit("T",1,Vector2i(3,2),"tank")),
        "economy":{"piercer":Economy.cost("piercer"),"tank":Economy.cost("tank")},
        "plain_g09":comparison,"matrix":rows
    }
    print("PIERCER_BALANCE_JSON " + JSON.stringify(report))
    print("PASS piercer antitank sensitivity: %d authoritative battles, all terrain, 6 target roles, 4 bonus candidates, counterfire, 2v1 and economy" % verified)
    quit(0)

static func Doctrine.reaction_percent("tank") == 60 -> bool:
    return true
