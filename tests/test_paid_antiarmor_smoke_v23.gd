extends SceneTree

# Check real authoritative ammunition/counters and +2 on only vehicles,
# and exact paid tier II->III->research progression. NOT fake fixed damage.
const Lab = preload("res://scripts/experiments/PaidAntiarmorBalanceV23.gd")
const Tank = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const V08 = preload("res://scripts/experiments/RoleSpecializationV08.gd")
const Battle = preload("res://scripts/core/BattleActions.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Tier = preload("res://scripts/experiments/BuildingProgressionV12.gd")

static func _board(tile: String) -> Array:
    var terrain: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        terrain.append(row)
    terrain[3][4] = tile
    return terrain

static func _fire(tile: String) -> void:
    var terrain: Array = _board(tile)
    var units: Array = [
        Roles.make_unit("P",0,Vector2i(3,3),"piercer"),
        Roles.make_unit("T",1,Vector2i(4,3),"tank")
    ]
    var state: Dictionary = Session.start(units,terrain,0,false,false,true,true)
    assert(Economy.valid(state["economy"],terrain))
    assert(state["units"][0]["ammo"] == 4)
    assert(state["units"][1]["ammo"] == 5)
    var base: Dictionary = Battle.preview_exchange(state["units"][0],
        state["units"][1],true,terrain,state["economy"],state["units"])
    var boosted: Dictionary = V08.preview_antiarmor(state["units"][0],
        state["units"][1],2,terrain,state["economy"],state["units"])
    assert(base.get("valid",false) and boosted.get("valid",false))
    assert(int(boosted["damage"]) >= int(base["damage"]))
    assert(V08.armor_bonus(state["units"][0],state["units"][1],2) == 2)
    var hit: Dictionary = V08.attack_antiarmor(state,"P","T",2)
    assert(hit.get("valid",false))
    assert(int(hit["temporary_bonus"]) == 2)
    assert(int(hit["damage"]) == int(boosted["damage"]))
    assert(int(hit["counter_damage"]) == int(boosted["counter_damage"]))
    assert(int(hit["state"]["units"][0]["attack"]) == 4)
    assert(int(hit["state"]["units"][0]["ammo"]) == 3)
    assert(int(hit["state"]["units"][1]["ammo"]) == \
        5-(1 if bool(boosted["counter_spent"]) else 0))
    assert(int(hit["state"]["units"][0]["hp"]) == int(boosted["attacker_hp"]))
    assert(int(hit["state"]["units"][1]["hp"]) == int(boosted["defender_hp"]))
    assert(not bool(V08.attack_antiarmor(hit["state"],"P","T",2).get("valid",false)))
    print("REAL_ANTIARMOR_V23 terrain=%s base_damage=%d bonus_damage=%d counter=%d piercer_hp=%d tank_hp=%d ammo_piercer=%d ammo_tank=%d" % [
        tile,int(base["damage"]),int(boosted["damage"]),
        int(boosted["counter_damage"]),int(boosted["attacker_hp"]),
        int(boosted["defender_hp"]),int(hit["state"]["units"][0]["ammo"]),
        int(hit["state"]["units"][1]["ammo"])
    ])

static func _exclusions() -> void:
    var terrain: Array = _board("plain")
    var shooter: Dictionary = Roles.make_unit("P",0,Vector2i(3,3),"piercer")
    var targets := ["line","scout","tank","apc","ifv","attack_heli","patrol","fpv"]
    for role in targets:
        var foe: Dictionary = Roles.make_unit("X",1,Vector2i(4,3),role)
        var plus: int = V08.armor_bonus(shooter,foe,2)
        if role in ["tank","apc","ifv"]:
            assert(plus == 2)
        else:
            assert(plus == 0)
        var outcome: Dictionary = V08.preview_antiarmor(shooter,foe,2,
            terrain,{},[shooter,foe])
        var base: Dictionary = Battle.preview_exchange(shooter,foe,true,
            terrain,{},[shooter,foe])
        if base.get("valid",false) and plus == 0:
            assert(outcome["damage"] == base["damage"])
    print("PASS v23 target whitelist: no free +2 to soldiers, air or naval")

static func _research() -> void:
    var b: Dictionary = Lab.start(0,Vector2i(24,18),0)
    assert(b.get("valid",false))
    assert(int(Tier.UPGRADE_COSTS["armor_plant"][2]) == 650)
    assert(int(Tier.UPGRADE_COSTS["armor_plant"][3]) == 1050)
    assert(int(Tier.TECH_COSTS["antiarmor_v1"]) == 450)
    var policies := ["pressure","armor"]
    var seen: Array = []
    for half in range(8):
        var side: int = int(b["session"]["world"]["state"]["faction"])
        var played: Dictionary = Lab.half_turn(b,policies,"researched")
        assert(played.get("valid",false))
        b = played["battle"]
        if side == 0:
            seen.append({"upgrades":int(b["unlock_lab"]["upgrades"][0]),
                "cost":int(b["unlock_lab"]["upgrade_spent"][0]),
                "tech":bool(b["antiarmor_lab"]["researched"][0]),
                "research_cost":int(b["antiarmor_lab"]["spent"][0])})
    assert(seen.size() == 4)
    assert(seen[0]["upgrades"] == 1 and seen[0]["cost"] == 650)
    assert(seen[1]["upgrades"] == 2 and seen[1]["cost"] == 1700)
    assert(not seen[1]["tech"])
    assert(seen[2]["tech"] and seen[2]["research_cost"] == 450)
    assert(int(b["antiarmor_lab"]["research_count"][0]) == 1)
    assert(int(b["antiarmor_lab"]["research_count"][1]) == 0)
    assert(int(b["antiarmor_lab"]["spent"][0])+ \
        int(b["unlock_lab"]["upgrade_spent"][0]) == 2150)
    assert(Lab._price_for_level(2) == Tank._cost())
    assert(Lab._price_for_level(3) == 1050)
    print("RESEARCH_V23 phase_progress=%s" % [str(seen)])

func _initialize() -> void:
    for tile in ["plain","forest","mountain"]:
        _fire(tile)
    _exclusions()
    _research()
    var control: Dictionary = Tank.duel(0,Vector2i(24,18),0,
        ["pressure","armor"],"level2",8)
    var v23: Dictionary = Lab.duel(0,Vector2i(24,18),0,
        ["pressure","armor"],"control",8)
    assert(control.get("valid",false) and v23.get("valid",false))
    assert(control["winner"] == v23["winner"])
    assert(control["halfturns"] == v23["halfturns"])
    for side in ["0","1"]:
        for field in ["attacks","moves","damage","kills","purchases","spent",
                "cash","income","city_captures","base_captures"]:
            assert(control["sides"][side][field] == v23["sides"][side][field])
        assert(not v23["sides"][side]["tech_active"])
    print("PASS paid antiarmor smoke v23: true Session damage and ammo on 3 terrains, whitelist, 2150 paid investment, and strict v22 control parity")
    quit(0)
