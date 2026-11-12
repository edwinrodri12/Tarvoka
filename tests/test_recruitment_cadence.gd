extends SceneTree

const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Strategy = preload("res://scripts/core/SupplyStrategy.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var force: Array = [Roles.make_unit("X",1,Vector2i(8,7),"line")]
    for i in range(6):
        force.append(Roles.make_unit("F%d" % i,0,Vector2i(2+i,6),"line"))
    var calm: Dictionary = Session.start(force,terrain,0,false,false,true,true)
    var profile: Dictionary = Strategy.assess(Visibility.observed_state(calm,0),0)
    assert(profile["ready_combat"] == 6)
    assert(Strategy.recruitment_limit(profile) == 1)
    assert(Strategy.produced_this_phase(calm,0) == 0)
    var first: Dictionary = Session.purchase(calm,Vector2i(0,3),"scout")
    assert(first["valid"])
    var after: Dictionary = first["state"]
    assert(Strategy.produced_this_phase(after,0) == 1)
    assert(not Strategy.can_spend_on_recruitment(after,0,"piercer",Economy.cost("piercer"),profile))
    # This is AI discipline, NOT a new limit on the player's factories:
    # the second licensed producer still accepts a player's legal purchase.
    var human_order: Dictionary = Session.purchase(after,Vector2i(0,1),"piercer")
    assert(human_order["valid"])
    assert(Strategy.produced_this_phase(human_order["state"],0) == 2)
    assert(Codec.decode(Codec.encode(human_order["state"])) == human_order["state"])

    var urgency: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(2,6),"line"),
        Roles.make_unit("E",1,Vector2i(8,6),"line")
    ],terrain,0,false,false,true,true)
    var needs: Dictionary = Strategy.assess(Visibility.observed_state(urgency,0),0)
    assert(needs["ready_combat"] == 1 and Strategy.recruitment_limit(needs) == 3)
    var built: Dictionary = urgency
    for order in [
        {"pos":Vector2i(0,3),"role":"scout"},
        {"pos":Vector2i(0,1),"role":"piercer"},
        {"pos":Vector2i(0,5),"role":"artillery"}
    ]:
        assert(Strategy.can_spend_on_recruitment(built,0,str(order["role"]),Economy.cost(str(order["role"])),needs))
        var produced: Dictionary = Session.purchase(built,order["pos"],str(order["role"]))
        assert(produced["valid"])
        built = produced["state"]
    assert(Strategy.produced_this_phase(built,0) == 3)
    assert(not Strategy.can_spend_on_recruitment(built,0,"uav_recon",Economy.cost("uav_recon"),needs))
    assert(Codec.decode(Codec.encode(built)) == built)

    # Per-side counters do not steal the other faction's legal quota.
    var switched: Dictionary = Session.end_turn(built)
    assert(switched["valid"] and switched["state"]["faction"] == 1)
    assert(Strategy.produced_this_phase(switched["state"],1) == 0)
    var enemy_profile: Dictionary = Strategy.assess(Visibility.observed_state(switched["state"],1),1)
    assert(Strategy.can_spend_on_recruitment(switched["state"],1,"scout",Economy.cost("scout"),enemy_profile))
    var enemy_built: Dictionary = Session.purchase(switched["state"],Vector2i(9,3),"scout")
    assert(enemy_built["valid"])
    assert(Strategy.produced_this_phase(enemy_built["state"],1) == 1)

    # Scarcity wins over a tight cap when a first field truck is necessary.
    var stranded: Dictionary = Session.start([
        Roles.make_unit("T",0,Vector2i(1,1),"tank"),
        Roles.make_unit("X",1,Vector2i(8,7),"line")
    ],terrain,0,false,false,true,true)
    stranded["units"][0]["fuel"] = 0
    stranded["units"][0]["ammo"] = 0
    var rescue: Dictionary = Strategy.assess(Visibility.observed_state(stranded,0),0)
    assert(rescue["need_truck"])
    var used: Dictionary = stranded.duplicate(true)
    for row in [
        {"pos":Vector2i(0,1),"role":"piercer"},
        {"pos":Vector2i(0,5),"role":"artillery"},
        {"pos":Vector2i(0,2),"role":"fpv"}
    ]:
        var result: Dictionary = Session.purchase(used,row["pos"],str(row["role"]))
        assert(result["valid"])
        used = result["state"]
    assert(Strategy.produced_this_phase(used,0) == 3)
    assert(Strategy.can_spend_on_recruitment(used,0,"logistics",Economy.cost("logistics"),rescue))
    var convoy: Dictionary = Session.purchase(used,Vector2i(0,3),"logistics")
    assert(convoy["valid"] and convoy["state"]["units"].back()["role"] == "logistics")

    # AI pressure decisions never inspect an enemy outside line of sight.
    var fog_force: Array = force.duplicate(true)
    fog_force[0]["pos"] = Vector2i(9,0)
    var fog: Dictionary = Session.start(fog_force,terrain,0,true,false,true,true)
    var alternate: Dictionary = fog.duplicate(true)
    alternate["units"][0]["pos"] = Vector2i(8,0)
    alternate["units"][0]["hp"] = 1
    assert(not Visibility.is_unit_visible(fog,0,"X"))
    assert(Strategy.assess(Visibility.observed_state(fog,0),0) == Strategy.assess(Visibility.observed_state(alternate,0),0))

    print("PASS recruitment discipline: 1/2/3-unit cadences, player factory rights, side isolation, emergency truck, fog")
    quit(0)
