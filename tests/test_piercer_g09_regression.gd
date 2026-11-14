extends SceneTree

# Contract for the approved candidate BEFORE any release. The AI, user HUD
# and authoritative combat all consume UnitRoles.role_bonus; never add a
# second buff in BattleActions or an invisible +/- to a faction's unit stats.
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")

func _initialize() -> void:
    assert(Roles.BONUSES["piercer"] == {"bulwark":4,"tank":2})
    assert(Roles.PROFILES["piercer"] == {
        "label":"Rompedor","hp":8,"move_points":3,"attack":4,"defense":0,
        "vision":3,"attack_min_range":1,"attack_range":1,"symbol":"P"
    })
    assert(Economy.cost("piercer") == 300)
    assert(Economy.cost("tank") == 750)
    assert(Arsenal.PROFILES["tank"]["attack"] == 8)
    assert(Arsenal.PROFILES["tank"]["defense"] == 2)
    assert(Arsenal.PROFILES["tank"]["hp"] == 14)
    assert(Economy.producer_for("piercer",true) == "armor_plant")

    var rom: Dictionary = Roles.make_unit("P",0,Vector2i(2,2),"piercer")
    var all_roles: Array = Roles.ORDER.duplicate()
    all_roles.append_array(Arsenal.ORDER)
    assert(all_roles.size() == 32)
    # EXACT, named-role bonus, not generic armor buffs or air/naval attack.
    for role in all_roles:
        var defender: Dictionary = Roles.make_unit("D",1,Vector2i(3,2),role)
        var expected := 0
        if role == "tank":
            expected = 2
        elif role == "bulwark":
            expected = 4
        assert(Roles.role_bonus(rom,defender) == expected)
        assert(Roles.role_bonus(defender,rom) == 0) # No bonus vs Rompedor itself.
    assert(Roles.role_bonus(
        Roles.make_unit("S",0,Vector2i(2,2),"scout"),
        Roles.make_unit("L",1,Vector2i(3,2),"artillery")) == 3)
    assert(str(Roles.counter_description("piercer")).contains("+2"))
    assert(str(Roles.counter_description("piercer")).contains("+4"))
    assert(str(Arsenal.PROFILES["tank"]["note"]).contains("+2"))

    var observed: Dictionary = {}
    var scenarios := 0
    for climate in ["clear","rain","snow"]:
        for environment in ["plain","road","forest","mountain","city"]:
            var terrain: Array = Scenarios.terrain(0)
            var from := Vector2i(2,2)
            var to := Vector2i(3,2)
            if environment == "city":
                from = Vector2i(2,4)
                to = Vector2i(3,4) # Actual neutral economic city.
            elif environment != "plain":
                terrain[to.y][to.x] = environment
            var state: Dictionary = Session.start([
                Roles.make_unit("P",0,from,"piercer"),
                Roles.make_unit("G",1,to,"tank")
            ],terrain,0,false,false,true,true,false,climate)
            var unchanged: Dictionary = state.duplicate(true)
            var forecast: Dictionary = Actions.preview_exchange(
                state["units"][0],state["units"][1],true,
                state["terrain"],state["economy"],state["units"])
            var expected_damage: Dictionary = {
                "plain":4,"road":4,"forest":3,"mountain":1,"city":3
            }
            var expected_counter: Dictionary = {
                "plain":4,"road":4,"forest":4,"mountain":5,"city":4
            }
            assert(forecast["valid"])
            assert(int(forecast["damage"]) == int(expected_damage[environment]))
            assert(int(forecast["counter_damage"]) == int(expected_counter[environment]))
            assert(int(forecast["defender_hp"]) == 14-int(forecast["damage"]))
            assert(int(forecast["attacker_hp"]) == 8-int(forecast["counter_damage"]))
            var played: Dictionary = Session.attack(state,"P","G")
            assert(played["valid"] and played["damage"] == forecast["damage"])
            assert(played["counter_damage"] == forecast["counter_damage"])
            assert(played["state"]["units"][1]["hp"] == forecast["defender_hp"])
            assert(played["state"]["units"][0]["hp"] == forecast["attacker_hp"])
            assert(played["state"]["units"][0]["ammo"] ==
                Logistics.ammo_capacity("piercer")-1)
            assert(played["state"]["units"][1]["ammo"] ==
                Logistics.ammo_capacity("tank")-1)
            assert(bool(played["state"]["units"][1]["reacted"]))
            assert(not Session.attack(played["state"],"P","G")["valid"])
            assert(Codec.decode(Codec.encode(played["state"])) == played["state"])
            assert(state == unchanged)
            observed[climate+"_"+environment] = {
                "damage":played["damage"],"counter":played["counter_damage"]
            }
            scenarios += 1
    assert(scenarios == 15)
    # Two sub-750-credit piercers cannot blow up a full G09 in one attack
    # phase. Tank may react once, and the second piercer stays uninjured.
    var pair: Dictionary = Session.start([
        Roles.make_unit("P1",0,Vector2i(2,2),"piercer"),
        Roles.make_unit("P2",0,Vector2i(3,3),"piercer"),
        Roles.make_unit("G09",1,Vector2i(3,2),"tank")
    ],Scenarios.terrain(0),0,false,false,true,true)
    var pristine: Dictionary = pair.duplicate(true)
    var first: Dictionary = Session.attack(pair,"P1","G09")
    assert(first["valid"] and first["damage"] == 4)
    assert(first["counter_damage"] == 4)
    assert(first["state"]["units"][0]["hp"] == 4)
    var second: Dictionary = Session.attack(first["state"],"P2","G09")
    assert(second["valid"] and second["damage"] == 4)
    assert(second["counter_damage"] == 0)
    assert(second["state"]["units"][2]["hp"] == 6)
    assert(second["state"]["units"][1]["hp"] == 8)
    assert(pair == pristine)
    assert(Codec.decode(Codec.encode(second["state"])) == second["state"])

    # If G09 initiates, its 8-HP hit defeats a full Rompedor immediately:
    # the affordable antitank is a specialist, NOT an unbeatable tank.
    var reverse: Dictionary = Session.start([
        Roles.make_unit("P",0,Vector2i(2,2),"piercer"),
        Roles.make_unit("G",1,Vector2i(3,2),"tank")
    ],Scenarios.terrain(0),1,false,false,true,true)
    var tank_starts: Dictionary = Session.attack(reverse,"G","P")
    assert(tank_starts["valid"] and tank_starts["damage"] == 8)
    assert(tank_starts["counter_damage"] == 0)
    assert(tank_starts["state"]["units"][0]["hp"] == 0)
    assert(tank_starts["state"]["units"][1]["hp"] == 14)

    # Faction/color independence: mirror G09 and Rompedor positions and side.
    var flipped: Dictionary = Session.start([
        Roles.make_unit("P",1,Vector2i(7,2),"piercer"),
        Roles.make_unit("G",0,Vector2i(6,2),"tank")
    ],Scenarios.terrain(0),1,false,false,true,true)
    var mirror_shot: Dictionary = Session.attack(flipped,"P","G")
    assert(mirror_shot["valid"] and mirror_shot["damage"] == 4)
    assert(mirror_shot["counter_damage"] == 4)
    assert(mirror_shot["state"]["units"][0]["hp"] == 4)
    assert(mirror_shot["state"]["units"][1]["hp"] == 10)

    # The promised "move + attack in one turn" must use +2 after movement,
    # not only when the attacker began already adjacent.
    var approach: Dictionary = Session.start([
        Roles.make_unit("P",0,Vector2i(1,2),"piercer"),
        Roles.make_unit("G",1,Vector2i(3,2),"tank")
    ],Scenarios.terrain(0),0,true,false,true,true)
    var walked: Dictionary = Session.move(approach,"P",Vector2i(2,2))
    assert(walked["valid"] and bool(walked["state"]["units"][0]["moved"]))
    assert(not bool(walked["state"]["units"][0]["acted"]))
    var strike_after_move: Dictionary = Session.attack(walked["state"],"P","G")
    assert(strike_after_move["valid"] and strike_after_move["damage"] == 4)
    assert(Codec.decode(Codec.encode(strike_after_move["state"])) ==
        strike_after_move["state"])

    # Never allow G09-specialized infantry to shoot targets it cannot reach.
    var air: Dictionary = Session.start([
        Roles.make_unit("P",0,Vector2i(2,2),"piercer"),
        Roles.make_unit("A",1,Vector2i(3,2),"attack_heli")
    ],Scenarios.terrain(0),0,false,false,true,true)
    assert(not Session.attack(air,"P","A")["valid"])
    assert(Roles.role_bonus(air["units"][0],air["units"][1]) == 0)

    # Baluarte remains the stronger +4 specialist target, and price is
    # unchanged. The G09 counter is only +2, not universal heavy-armor magic.
    var shield: Dictionary = Session.start([
        Roles.make_unit("P",0,Vector2i(2,2),"piercer"),
        Roles.make_unit("B",1,Vector2i(3,2),"bulwark")
    ],Scenarios.terrain(0),0,false,false,true,true)
    var breakthrough: Dictionary = Session.attack(shield,"P","B")
    assert(breakthrough["valid"] and breakthrough["damage"] == 6)
    assert(Roles.role_bonus(shield["units"][0],shield["units"][1]) == 4)
    assert(Economy.cost("piercer") == 300 and Economy.cost("tank") == 750)

    print("PIERCER_G09_REGRESSION_JSON "+JSON.stringify({
        "terrain_weather_matrix":observed,
        "pair_one_phase":{"tank_left":second["state"]["units"][2]["hp"],
            "piercer1_left":second["state"]["units"][0]["hp"]},
        "tank_first_damage":tank_starts["damage"],
        "mirrored_damage":mirror_shot["damage"]
    }))
    print("PASS piercer G09 regression: %d battle+weather checks; cover, costs, ammo, save, mirror, 2v1, initiative, move-and-shoot and anti-air exclusions" % scenarios)
    quit(0)
