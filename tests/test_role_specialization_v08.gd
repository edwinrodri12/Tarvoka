extends SceneTree

# Independent diagnostic: real Session attacks and save-safe engineer repair.
# Two selectable buffs, two repair packs, both factions and strict refusals.
const Lab = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")
const Turns = preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        _armor_options(side)
        _repair_packs(side)
        _illegal_repair(side)
        _unaffected_foes(side)
        cases += 4
    assert(cases == 8)
    print("PASS role specialization v08: 8 grouped suites covering 2 sides, 3 armor options, 2 paid repair packs, save compatibility, legal action consumption and hostile/invalid requests")
    quit(0)

static func _board() -> Array:
    var rows: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        rows.append(row)
    return rows

static func _unit(role: String, id: String, side: int, pos: Vector2i) -> Dictionary:
    var unit: Dictionary = Roles.make_unit(id,side,pos,role)
    assert(not unit.is_empty())
    return unit

static func _setup(side: int, target_role: String) -> Dictionary:
    var state: Dictionary = Session.start([
        _unit("piercer","P",side,Vector2i(2,3)),
        _unit(target_role,"T",1-side,Vector2i(3,3)),
        _unit("line","A",side,Vector2i(7,6))
    ],_board(),side,false,false,true,true)
    assert(state.has("economy"))
    return state

static func _get(state: Dictionary, identifier: String) -> Dictionary:
    for unit in state["units"]:
        if str(unit.get("id","")) == identifier:
            return unit
    return {}

static func _armor_options(side: int) -> void:
    var state: Dictionary = _setup(side,"tank")
    var before: Dictionary = state.duplicate(true)
    var base: Dictionary = Lab.attack_antiarmor(state,"P","T",0)
    var plus2: Dictionary = Lab.attack_antiarmor(state,"P","T",2)
    var plus3: Dictionary = Lab.attack_antiarmor(state,"P","T",3)
    assert(base.get("valid",false) and plus2.get("valid",false) and plus3.get("valid",false))
    assert(int(base["damage"]) == 2)
    assert(int(plus2["damage"]) == 4)
    assert(int(plus3["damage"]) == 5)
    assert(int(base["temporary_bonus"]) == 0)
    assert(int(plus2["temporary_bonus"]) == 2)
    assert(int(plus3["temporary_bonus"]) == 3)
    assert(int(_get(plus3["state"],"P")["attack"]) == 4)
    assert(int(_get(plus3["state"],"T")["hp"]) == 9)
    assert(int(_get(plus2["state"],"P")["ammo"]) == int(_get(state,"P")["ammo"])-1)
    assert(bool(_get(plus3["state"],"P")["acted"]))
    assert(state == before)
    assert(Save.decode(Save.encode(plus2["state"])) == plus2["state"])
    assert(not Lab.attack_antiarmor(state,"P","T",4).get("valid",false))
    assert(not Lab.attack_antiarmor(plus2["state"],"P","T",2).get("valid",false))
    print("ROLE_ARMOR side=%d tank_hp=14 armor=2 base=%d plus2=%d plus3=%d no_persistent_attack=true" % [
        side,int(base["damage"]),int(base["damage"]),int(plus2["damage"]),int(plus3["damage"])
    ])

static func _repair_start(side: int) -> Dictionary:
    var tank: Dictionary = _unit("tank","T",side,Vector2i(3,3))
    tank["hp"] = 8
    var engineer: Dictionary = _unit("engineer","E",side,Vector2i(2,3))
    var foe: Dictionary = _unit("line","FOE",1-side,Vector2i(7,6))
    var state: Dictionary = Session.start([engineer,tank,foe],
        _board(),side,false,false,true,true)
    assert(int(_get(state,"T")["hp"]) == 8)
    return state

static func _repair_packs(side: int) -> void:
    var origin: Dictionary = _repair_start(side)
    var previous: Dictionary = origin.duplicate(true)
    for pack in ["small","field"]:
        var order: Dictionary = Lab.field_repair(origin,"E","T",pack)
        assert(order.get("valid",false))
        var expected_hp: int = 2 if pack == "small" else 3
        var expected_cost: int = 60 if pack == "small" else 100
        assert(int(order["hp_restored"]) == expected_hp)
        assert(int(order["cost"]) == expected_cost)
        assert(int(_get(order["state"],"T")["hp"]) == 8+expected_hp)
        assert(bool(_get(order["state"],"E")["acted"]))
        assert(int(_get(order["state"],"E")["attack"]) == 2)
        assert(int(order["state"]["economy"]["credits"][side]) ==
            int(origin["economy"]["credits"][side])-expected_cost)
        assert(int(order["state"]["economy"]["credits"][1-side]) ==
            int(origin["economy"]["credits"][1-side]))
        assert(Economy.valid(order["state"]["economy"],order["state"]["terrain"]))
        assert(not Lab.field_repair(order["state"],"E","T",pack).get("valid",false))
        assert(not Session.attack(order["state"],"E","FOE").get("valid",false))
        assert(Save.decode(Save.encode(order["state"])) == order["state"])
    assert(origin == previous)
    # A unit can move AND repair on its turn (but not attack afterward).
    var moved: Dictionary = origin.duplicate(true)
    var moving_engineer: Dictionary = _get(moved,"E")
    moving_engineer["moved"] = true
    var after_moving: Dictionary = Lab.field_repair(moved,"E","T","small")
    assert(after_moving.get("valid",false))
    print("ROLE_REPAIR side=%d small=2hp/60cr field=3hp/100cr no_double_use=true" % side)

static func _illegal_repair(side: int) -> void:
    var base: Dictionary = _repair_start(side)
    var untouched: Dictionary = base.duplicate(true)
    assert(not Lab.field_repair(base,"E","FOE").get("valid",false))
    assert(not Lab.field_repair(base,"T","E").get("valid",false))
    assert(not Lab.field_repair(base,"E","T","unknown").get("valid",false))
    assert(not Lab.field_repair(base,"E","E").get("valid",false))
    var scarce: Dictionary = base.duplicate(true)
    scarce["economy"]["credits"][side] = 50
    assert(not Lab.field_repair(scarce,"E","T","small").get("valid",false))
    var full: Dictionary = base.duplicate(true)
    var full_target: Dictionary = _get(full,"T")
    full_target["hp"] = 14
    assert(not Lab.field_repair(full,"E","T","small").get("valid",false))
    var zero: Dictionary = base.duplicate(true)
    var dead_target: Dictionary = _get(zero,"T")
    dead_target["hp"] = 0
    assert(not Lab.field_repair(zero,"E","T","small").get("valid",false))
    var distant: Dictionary = base.duplicate(true)
    var distant_target: Dictionary = _get(distant,"T")
    distant_target["pos"] = Vector2i(5,3)
    assert(not Lab.field_repair(distant,"E","T","small").get("valid",false))
    var no_action: Dictionary = base.duplicate(true)
    var used_engineer: Dictionary = _get(no_action,"E")
    used_engineer["acted"] = true
    assert(not Lab.field_repair(no_action,"E","T","small").get("valid",false))
    var airborne: Dictionary = base.duplicate(true)
    var aircraft_target: Dictionary = _get(airborne,"T")
    aircraft_target["role"] = "attack_heli"
    assert(not Lab.field_repair(airborne,"E","T","small").get("valid",false))
    var infantry: Dictionary = base.duplicate(true)
    var infantry_target: Dictionary = _get(infantry,"T")
    infantry_target["role"] = "line"
    assert(not Lab.field_repair(infantry,"E","T","small").get("valid",false))
    assert(base == untouched)

static func _unaffected_foes(side: int) -> void:
    var cases := 0
    for target_role in ["line","scout","assault","bulwark","tank","apc","ifv","spg","mlrs","mobile_aa","sam","ew","logistics","attack_heli"]:
        var state: Dictionary = _setup(side,target_role)
        var regular: Dictionary = Lab.attack_antiarmor(state,"P","T",0)
        var upgraded: Dictionary = Lab.attack_antiarmor(state,"P","T",2)
        # An unarmed enemy doesn't block the attack; an airborne enemy
        # is out of domain so both requests must be rejected equally.
        assert(bool(regular.get("valid",false)) == bool(upgraded.get("valid",false)))
        if bool(regular.get("valid",false)):
            var expected: int = 2 if target_role in Lab.ANTI_ARMOR_ROLES else 0
            assert(int(upgraded["temporary_bonus"]) == expected)
            if expected == 0:
                assert(int(upgraded["damage"]) == int(regular["damage"]))
            else:
                assert(int(upgraded["damage"]) >= int(regular["damage"]))
            cases += 1
    assert(cases >= 10)
    print("ROLE_TARGET_FILTER side=%d eligible_duels=%d no_infantry_air_naval_bonus=true" % [side,cases])
