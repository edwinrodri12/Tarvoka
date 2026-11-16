extends SceneTree

# Two genuine tactical decisions through BattleSession, opt-in abilities only.
# Neither unit prices nor global combat roles are modified by this test.
const Lab = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var cases := 0
    for side in [0,1]:
        for pack in ["small","field"]:
            _rescue_wounded_tank(side,pack)
            cases += 1
        _finish_wounded_armor_without_one_shot_full_tank(side)
        cases += 1
    assert(cases == 6)
    print("PASS specialization tactical v10: 6 cases with real attack, end-turn, both sides, 2 recovery packs, saved armor and specialized weakened-target elimination")
    quit(0)

static func _terrain() -> Array:
    var board: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        board.append(row)
    return board

static func _find(units: Array, target_id: String) -> Dictionary:
    for u in units:
        if str(u.get("id","")) == target_id:
            return u
    return {}

static func _build(side: int, friendly_hp: int = 5) -> Dictionary:
    var engineer: Dictionary = Roles.make_unit("ENG",side,Vector2i(2,3),"engineer")
    var armor: Dictionary = Roles.make_unit("ALL",side,Vector2i(3,3),"tank")
    var hostile: Dictionary = Roles.make_unit("FOE",1-side,Vector2i(4,3),"tank")
    armor["hp"] = friendly_hp
    var state: Dictionary = Session.start([engineer,armor,hostile],_terrain(),
        side,false,false,true,true)
    assert(state.has("economy"))
    return state

static func _rescue_wounded_tank(side: int, pack: String) -> void:
    var initial: Dictionary = _build(side)
    var original: Dictionary = initial.duplicate(true)
    var no_repair_turn: Dictionary = Session.end_turn(initial)
    assert(no_repair_turn.get("valid",false))
    var lethal: Dictionary = Session.attack(no_repair_turn["state"],"FOE","ALL")
    assert(lethal.get("valid",false))
    assert(int(_find(lethal["state"]["units"],"ALL")["hp"]) == 0)
    var repair: Dictionary = Lab.field_repair(initial,"ENG","ALL",pack)
    assert(repair.get("valid",false))
    assert(initial == original)
    assert(Save.decode(Save.encode(repair["state"])) == repair["state"])
    var restored: int = int(repair["hp_restored"])
    var repaired_turn: Dictionary = Session.end_turn(repair["state"])
    assert(repaired_turn.get("valid",false))
    var after_attack: Dictionary = Session.attack(repaired_turn["state"],"FOE","ALL")
    assert(after_attack.get("valid",false))
    var hp_left: int = int(_find(after_attack["state"]["units"],"ALL")["hp"])
    assert(hp_left == 5+restored-6)
    assert(hp_left > 0)
    print("ROLE_RESCUE side=%d pack=%s base_target_killed=true repaired_survives_hp=%d cost=%d" % [
        side,pack,hp_left,int(repair["cost"])
    ])

static func _finish_wounded_armor_without_one_shot_full_tank(side: int) -> void:
    var piercer: Dictionary = Roles.make_unit("PIER",side,Vector2i(2,3),"piercer")
    var tank: Dictionary = Roles.make_unit("TANK",1-side,Vector2i(3,3),"tank")
    var initial: Dictionary = Session.start([piercer,tank],_terrain(),
        side,false,false,true,true)
    var original: Dictionary = initial.duplicate(true)
    var full: Dictionary = Lab.attack_antiarmor(initial,"PIER","TANK",3)
    assert(full.get("valid",false))
    assert(int(_find(full["state"]["units"],"TANK")["hp"]) == 9)
    var wounded: Dictionary = Session.start([
        Roles.make_unit("PIER",side,Vector2i(2,3),"piercer"),
        Roles.make_unit("TANK",1-side,Vector2i(3,3),"tank")
    ],_terrain(),side,false,false,true,true)
    _find(wounded["units"],"TANK")["hp"] = 5
    var no_bonus: Dictionary = Lab.attack_antiarmor(wounded,"PIER","TANK",0)
    var plus2: Dictionary = Lab.attack_antiarmor(wounded,"PIER","TANK",2)
    var plus3: Dictionary = Lab.attack_antiarmor(wounded,"PIER","TANK",3)
    assert(int(_find(no_bonus["state"]["units"],"TANK")["hp"]) == 3)
    assert(int(_find(plus2["state"]["units"],"TANK")["hp"]) == 1)
    assert(int(_find(plus3["state"]["units"],"TANK")["hp"]) == 0)
    assert(int(_find(plus3["state"]["units"],"PIER")["attack"]) == 4)
    assert(initial == original)
