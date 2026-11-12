extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Doctrine = preload("res://scripts/core/CombatDoctrine.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Turns = preload("res://scripts/core/Turns.gd")
const Hints = preload("res://scripts/core/TacticalHints.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")

static func army(a_role: String, d_role: String, a_pos: Vector2i = Vector2i(1,2), d_pos: Vector2i = Vector2i(2,2)) -> Dictionary:
    var a: Dictionary = Roles.make_unit("A",0,a_pos,a_role)
    var d: Dictionary = Roles.make_unit("X",1,d_pos,d_role)
    return Session.start([a,d],Scenarios.terrain(0),0,false,false,true,true)

func _initialize() -> void:
    # 32 doctrine entries, including all five legacy role names, fixed
    # starting archetypes and four explicit campaign introduction tiers.
    var all: Array = Roles.ORDER.duplicate()
    all.append_array(Arsenal.ORDER)
    assert(all.size() == 32)
    assert(Doctrine.PROFILES.size() == 32)
    var counts := [0,0,0,0]
    for role in all:
        assert(Doctrine.valid(role))
        var meta: Dictionary = Doctrine.profile(role)
        assert(meta["style"] in Doctrine.STYLES and meta["armor"] in Doctrine.ARMOR_CLASSES)
        assert(int(meta["reaction_pct"]) >= 0 and int(meta["reaction_pct"]) <= 65)
        assert(not str(meta["weapon"]).is_empty())
        assert(not str(meta["strength"]).is_empty() and not str(meta["weakness"]).is_empty())
        assert(int(meta["tier"]) >= 1 and int(meta["tier"]) <= 4)
        counts[int(meta["tier"])-1] += 1
        var unit: Dictionary = Roles.make_unit("A",0,Vector2i(1,2),role)
        if int(unit["attack"]) <= 0:
            assert(Doctrine.reaction_percent(role) == 0)
        if meta["style"] in ["support","indirect","saturation","consumable"]:
            assert(Doctrine.reaction_percent(role) == 0)
    assert(counts == [9,9,8,6])
    assert(Doctrine.VETERANCY.size() == 4)
    for i in range(4):
        assert(Doctrine.VETERANCY[i]["level"] == i)
        assert(Doctrine.VETERANCY[i]["attack_bonus"] == 0 and Doctrine.VETERANCY[i]["defense_bonus"] == 0)

    # Equal MBTs: attacker goes first, takes 6 HP; a damaged tank
    # responds for only 3 HP. Never a full-power mirror strike.
    var state: Dictionary = army("tank","tank")
    var untouched: Dictionary = state.duplicate(true)
    var preview: Dictionary = Actions.preview_exchange(state["units"][0],state["units"][1])
    assert(preview["valid"])
    assert(preview["damage"] == 6 and preview["defender_hp"] == 8)
    assert(preview["counter_damage"] == 3 and preview["attacker_hp"] == 11)
    var shot: Dictionary = Session.attack(state,"A","X")
    assert(shot["valid"] and shot["damage"] == 6 and shot["counter_damage"] == 3)
    assert(shot["counter_spent"])
    assert(shot["state"]["units"][0]["hp"] == 11)
    assert(shot["state"]["units"][1]["hp"] == 8)
    assert(shot["state"]["units"][0]["ammo"] == Logistics.ammo_capacity("tank")-1)
    assert(shot["state"]["units"][1]["ammo"] == Logistics.ammo_capacity("tank")-1)
    assert(shot["state"]["units"][1]["reacted"] == true)
    assert(not shot["state"]["units"][1]["acted"]) # Reaction never spends own action.
    assert(state == untouched and Codec.decode(Codec.encode(shot["state"])) == shot["state"])

    # One automatic reply per opposing turn regardless of consecutive shots.
    var reinforce: Dictionary = Roles.make_unit("B",0,Vector2i(2,3),"tank")
    var multi: Dictionary = state.duplicate(true)
    multi["units"].append(reinforce)
    var first: Dictionary = Session.attack(multi,"A","X")
    assert(first["valid"] and first["counter_damage"] == 3)
    var second: Dictionary = Session.attack(first["state"],"B","X")
    assert(second["valid"])
    assert(second["counter_damage"] == 0 and not second["counter_spent"])
    assert(second["state"]["units"][2]["hp"] == 14)
    var red_turn: Dictionary = Session.end_turn(second["state"])
    assert(red_turn["valid"] and red_turn["state"]["faction"] == 1)
    assert(not bool(red_turn["state"]["units"][1].get("reacted",false)))
    assert(Codec.decode(Codec.encode(second["state"])) == second["state"])

    # Dead defender cannot shoot back. A one-way drone is expended but
    # cannot be counter-counterattacked regardless of target weapons.
    var lethal: Dictionary = army("tank","engineer")
    var eliminated: Dictionary = Session.attack(lethal,"A","X")
    assert(eliminated["valid"] and eliminated["counter_damage"] == 0)
    assert(eliminated["state"]["units"][1]["hp"] == 0)
    var disposable: Dictionary = army("fpv","tank")
    var strike: Dictionary = Session.attack(disposable,"A","X")
    assert(strike["valid"] and strike["counter_damage"] == 0)
    assert(strike["state"]["units"][0]["hp"] == 0)
    assert(strike["state"]["units"][1]["ammo"] == Logistics.ammo_capacity("tank"))

    # Range is bidirectional; artillery at minimum two cannot retaliate
    # against a nearby tank/infantry shot, even when it survives.
    var close: Dictionary = army("scout","spg")
    var ranged: Dictionary = Session.attack(close,"A","X")
    assert(ranged["valid"] and ranged["counter_damage"] == 0)
    assert(ranged["state"]["units"][1]["hp"] > 0)
    assert(not ranged["state"]["units"][1].has("reacted"))
    # No anti-air counterfire from a tank to a flying bomber.
    var air: Dictionary = army("bomber","tank",Vector2i(1,2),Vector2i(3,2))
    var bomb: Dictionary = Session.attack(air,"A","X")
    assert(bomb["valid"] and bomb["counter_damage"] == 0)

    # The defending vehicle must really possess a round of ammunition.
    var dry: Dictionary = state.duplicate(true)
    dry["units"][1]["ammo"] = 0
    var no_return: Dictionary = Session.attack(dry,"A","X")
    assert(no_return["valid"] and no_return["counter_damage"] == 0)
    assert(no_return["state"]["units"][1]["ammo"] == 0)
    var already: Dictionary = state.duplicate(true)
    already["units"][1]["reacted"] = true
    assert(Session.attack(already,"A","X")["counter_damage"] == 0)

    # Public tactical preview must not disclose enemy ammo or readiness.
    var hints_dry: Dictionary = Hints.for_unit(dry,"A")["attacks"]
    var hints_ready: Dictionary = Hints.for_unit(state,"A")["attacks"]
    var hints_used: Dictionary = Hints.for_unit(already,"A")["attacks"]
    assert(hints_ready == hints_dry and hints_ready == hints_used)
    assert(hints_ready[Vector2i(2,2)]["counter_damage"] == 3)
    assert(Hints.unit_summary(dry,"A").contains("posible respuesta hasta -3"))

    # Fog: defender must see attacker, not only vice versa. A defender with
    # long range but short vision cannot use privileged target coordinates.
    var fog_attacker: Dictionary = Roles.make_unit("A",0,Vector2i(2,2),"fighter")
    var blind_defender: Dictionary = Roles.make_unit("X",1,Vector2i(4,2),"mobile_aa")
    blind_defender["vision"] = 1
    var fog: Dictionary = Session.start([fog_attacker,blind_defender],Scenarios.terrain(0),0,true,false,true,true)
    assert(Visibility.is_unit_visible(fog,0,"X"))
    assert(not Visibility.is_unit_visible(fog,1,"A"))
    var no_magic: Dictionary = Session.attack(fog,"A","X")
    assert(no_magic["valid"] and no_magic["counter_damage"] == 0)
    assert(Codec.decode(Codec.encode(no_magic["state"])) == no_magic["state"])
    var with_eyes: Dictionary = fog.duplicate(true)
    with_eyes["units"][1]["vision"] = 5
    var with_reply: Dictionary = Session.attack(with_eyes,"A","X")
    assert(with_reply["valid"] and with_reply["counter_damage"] > 0)
    # Seralize strictly: legacy snapshots may omit reacted, malformed type rejected.
    var corrupt: Dictionary = shot["state"].duplicate(true)
    corrupt["units"][1]["reacted"] = "yes"
    assert(Codec.encode(corrupt).is_empty())

    # Artificial long-form regression battlegrounds may give defenders HP
    # above their normal role maximum; retaliation never scales >100%.
    var reinforced: Dictionary = Roles.make_unit("X",1,Vector2i(2,2),"line")
    reinforced["hp"] = 100
    var excess: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(1,2),"tank"), reinforced
    ],Scenarios.terrain(0),0,false,false,true,true)
    var safe: Dictionary = Session.attack(excess,"A","X")
    assert(safe["valid"] and safe["counter_damage"] == 2)
    assert(safe["state"]["units"][0]["hp"] == 12)
    assert(Codec.decode(Codec.encode(safe["state"])) == safe["state"])

    print("PASS counterfire: 32 doctrines 9/9/8/6 tiers, equal tanks 6/3, ammo, one reply per turn, fog, no one-way response and save")
    quit(0)
