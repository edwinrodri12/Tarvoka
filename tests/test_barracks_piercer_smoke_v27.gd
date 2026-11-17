extends SceneTree

# Verify that v27 piercer production is genuinely legal: the REAL
# fixed-site order calls Session.purchase -> Economy.purchase, without
# changing a proxy factory into a fictitious armor plant or bypassing
# affordability, ownership, occupied tile or per-turn cooldown.
const Orders = preload("res://scripts/experiments/FixedSiteOrdersV19.gd")
const Lab = preload("res://scripts/experiments/TankUnlockEconomyV22.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Tier = preload("res://scripts/experiments/BuildingProgressionV12.gd")

static func _factory(side: int, size: Vector2i) -> Vector2i:
    var session: Dictionary = Orders.start(0,size,side)
    assert(session.get("valid",false))
    for site in session["world"]["layout"]["sites"]:
        if str(site["kind"]) == "factory" and int(site["owner"]) == side:
            return site["pos"]
    return Vector2i(-1,-1)

static func _test_real_purchase(side: int, size: Vector2i) -> void:
    var location: Vector2i = _factory(side,size)
    assert(location.x >= 0)
    var s: Dictionary = Orders.start(0,size,side)
    assert(s.get("valid",false))
    var initial: Dictionary = s.duplicate(true)
    var before: Dictionary = s["world"]["state"]
    assert(int(before["economy"]["credits"][side]) == 2500)
    assert(not bool(Orders.purchase(s,location,"piercer").get("valid",false)))
    assert(not bool(Economy.can_purchase(before,location,"piercer")))
    assert(bool(Economy.can_purchase(before,location,"piercer",true)) == \
        bool(Economy.site_at(before["economy"],location).get("owner",-1) == side))
    assert(s == initial)
    var result: Dictionary = Orders.purchase(s,location,"piercer",true)
    assert(result.get("valid",false))
    var changed: Dictionary = result["session"]
    var state: Dictionary = changed["world"]["state"]
    assert(int(result["cost"]) == 300)
    assert(str(result["role"]) == "piercer")
    assert(int(state["economy"]["credits"][side]) == 2200)
    assert(int(state["economy"]["credits"][1-side]) == 2500)
    assert(state["units"].size() == before["units"].size()+1)
    assert(int(changed["world"]["purchase_count"]) == 1)
    assert(Economy.valid(state["economy"],state["terrain"]))
    var spawned := 0
    for unit in state["units"]:
        if str(unit.get("id","")) == str(result["unit_id"]):
            spawned += 1
            assert(str(unit["role"]) == "piercer")
            assert(int(unit["hp"]) == 8 and int(unit["attack"]) == 4)
            assert(int(unit["move_points"]) == 3)
            assert(unit["pos"] == location)
            assert(bool(unit.get("acted",false)) and bool(unit.get("moved",false)))
    assert(spawned == 1)
    # No duplicate in a single factory phase and no neighbor/foe purchasing.
    assert(not bool(Orders.purchase(changed,location,"piercer",true).get("valid",false)))
    var enemy_location: Vector2i = _factory(1-side,size)
    assert(not bool(Orders.purchase(s,enemy_location,"piercer",true).get("valid",false)))
    assert(not bool(Orders.purchase(s,location,"tank",true).get("valid",false)))
    assert(s == initial)
    print("PIERCER_FACTORY_V27 side=%d size=%s factory=%s paid=300 hp=8 attack=4 duplicate_blocked=true" % [
        side,str(size),str(location)])

static func _test_armored_site() -> void:
    var s: Dictionary = Orders.start(0,Vector2i(24,18),0)
    assert(s.get("valid",false))
    var cell := Vector2i(-1,-1)
    for site in s["world"]["layout"]["sites"]:
        if site["kind"] == "armor_plant" and int(site["owner"]) == 0:
            cell = site["pos"]
            break
    assert(cell.x >= 0)
    # Old mode: piercer from an armor plant; opt-in new mode: unavailable.
    assert(Orders.purchase(s,cell,"piercer").get("valid",false))
    assert(not bool(Orders.purchase(s,cell,"piercer",true).get("valid",false)))
    assert(Orders.purchase(s,cell,"apc",true).get("valid",false))

func _initialize() -> void:
    assert(Economy.producer_for("piercer",true) == "armor_plant")
    assert(Economy.producer_for("piercer",true,true) == "factory")
    assert(Economy.producer_for("piercer",false,true) == "factory")
    assert(Economy.producer_for("tank",true,true) == "armor_plant")
    assert(Tier.required_level("piercer") == 1)
    assert(Economy.cost("piercer") == 300)
    for side in [0,1]:
        for size in [Vector2i(10,8),Vector2i(24,18)]:
            _test_real_purchase(side,size)
    _test_armored_site()
    var old: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],"level2",8)
    var parity: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],"level2",8,{})
    assert(old.get("valid",false) and old == parity)
    var new: Dictionary = Lab.duel(0,Vector2i(10,8),0,
        ["armor","pressure"],"level2",8,
        {"experimental_piercer_factory":true})
    assert(new.get("valid",false))
    var pressure: Dictionary = new["sides"]["1"]
    assert(int(pressure["purchases_by_role"].get("piercer",0)) >= 1)
    for side in ["0","1"]:
        var row: Dictionary = new["sides"][side]
        assert(int(row["cash"]) == Economy.MODERN_START_CREDITS+ \
            int(row["income"])-int(row["total_spent"]))
    print("PASS v27 real piercer recruitment: genuine Session purchase, no double-pay, no enemy or occupied factory, preserved legacy, 300 credits and 8HP/4attack")
    quit(0)
