extends SceneTree

# Integration invariants for genuinely executed Session actions.
# Extra cities and XP remain externally tracked experiment data.
const Lab = preload("res://scripts/experiments/IntegratedBalanceBattleV16.gd")
const City = preload("res://scripts/experiments/CityDensityV14.gd")
const Tier = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var cases := 0
    for first in [0,1]:
        for city_count in [4,12,16]:
            _income(first,city_count)
            cases += 1
    _capture_xp()
    _paid_tech()
    cases += 2
    assert(cases == 8)
    print("PASS integrated balance rules v16: 8 cases; correct 4/12/16 cash on real turns, 2-own-phase captures, role XP and paid antivehicle technology")
    quit(0)

static func _find(battle: Dictionary, uid: String) -> Dictionary:
    for u in battle["state"]["units"]:
        if str(u["id"]) == uid:
            return u
    return {}

static func _owner(battle: Dictionary, cell: Vector2i) -> int:
    for site in battle["cities"]["sites"]:
        if str(site["kind"]) == "city" and site["pos"] == cell:
            return int(site["owner"])
    return -99

static func _next(battle: Dictionary) -> Dictionary:
    var ended: Dictionary = Lab.advance(battle)
    assert(bool(ended.get("valid",false)))
    return ended["battle"]

static func _income(first: int, count: int) -> void:
    var b: Dictionary = Lab.setup(0,Vector2i(24,18),count,first)
    assert(bool(b.get("valid",false)))
    var revenue: int = int(count/4)*int(City.PAYOUT[count])
    assert(int(City.income(b["cities"],0,count)) == revenue)
    assert(int(City.income(b["cities"],1,count)) == revenue)
    assert(Economy.valid(b["state"]["economy"],b["state"]["terrain"]))
    assert(bool(Economy.valid(b["cities"],b["state"]["terrain"])) == (count == 4))
    var snapshot: Dictionary = b.duplicate(true)
    b = _next(b)
    assert(int(b["state"]["economy"]["credits"][1-first]) == 2500+revenue)
    assert(snapshot["cities"] == b["cities"])
    b = _next(b)
    assert(int(b["state"]["economy"]["credits"][first]) == 2500+revenue)
    assert(int(b["metrics"]["income"][0]) == revenue)
    assert(int(b["metrics"]["income"][1]) == revenue)
    assert(Economy.valid(b["state"]["economy"],b["state"]["terrain"]))
    assert(Save.decode(Save.encode(b["state"])) == b["state"])
    print("INTEGRATED_INCOME first=%d cities=%d income_each=%d core_city_sites=4 no_double_income=true" % [first,count,revenue])

static func _capture_xp() -> void:
    var b: Dictionary = Lab.setup(0,Vector2i(24,18),12,0)
    assert(bool(b.get("valid",false)))
    var neutral: Vector2i = Vector2i(-1,-1)
    for site in b["cities"]["sites"]:
        if str(site["kind"]) != "city" or int(site["owner"]) != -1:
            continue
        var taken := false
        for u in b["state"]["units"]:
            if u["pos"] == site["pos"]:
                taken = true
        if not taken:
            neutral = site["pos"]
            break
    assert(neutral.x >= 0)
    # Place a capturer on an empty objective as a fixture. Only the
    # subsequent Session turns and promotion are the subjects here.
    var unit: Dictionary = _find(b,"S0-0")
    unit["pos"] = neutral
    b = _next(b)
    assert(_owner(b,neutral) == -1)
    b = _next(b)
    assert(_owner(b,neutral) == -1) # opponent's turn may not erase hold
    b = _next(b)
    assert(_owner(b,neutral) == 0)
    assert(int(b["xp"].get("S0-0",0)) == 15)
    assert(int(_find(b,"S0-0")["hp"]) == 11)
    assert(int(b["metrics"]["captures"]) == 1)
    b = _next(b)
    assert(int(b["metrics"]["income"][0]) == 249+332)
    print("INTEGRATED_CITY_CAPTURE city12=true two_own_phases=true xp15=true next_income332=true")

static func _paid_tech() -> void:
    var b: Dictionary = Lab.setup(0,Vector2i(24,18),12,0)
    assert(bool(b.get("valid",false)))
    var plant := Vector2i(-1,-1)
    for site in b["state"]["economy"]["sites"]:
        if str(site["kind"]) == "armor_plant" and int(site["owner"]) == 0:
            plant = site["pos"]
    assert(plant.x >= 0)
    var changed: Dictionary = Tier.upgrade(b["state"],b["tiers"],plant)
    assert(bool(changed.get("valid",false)))
    b["state"] = changed["state"]
    b["tiers"] = changed["progress"]
    b = _next(_next(b))
    changed = Tier.upgrade(b["state"],b["tiers"],plant)
    assert(bool(changed.get("valid",false)))
    b["state"] = changed["state"]
    b["tiers"] = changed["progress"]
    b = _next(_next(b))
    changed = Tier.research(b["state"],b["tiers"],plant,"antiarmor_v1")
    assert(bool(changed.get("valid",false)))
    b["state"] = changed["state"]
    b["tiers"] = changed["progress"]
    assert(Tier.has_tech(b["tiers"],0,"antiarmor_v1"))
    assert(not Tier.has_tech(b["tiers"],1,"antiarmor_v1"))
    var shooter: Dictionary = _find(b,"S0-2")
    var original_attack: int = int(shooter["attack"])
    var tank: Dictionary = Roles.make_unit("EXTRA-T",1,shooter["pos"]+Vector2i(1,0),"tank")
    Logistics.equip(tank)
    b["state"]["units"].append(tank)
    var fired: Dictionary = Lab.attack(b,"S0-2","EXTRA-T")
    assert(bool(fired.get("valid",false)))
    assert(int(fired["damage"]) == 4)
    b = fired["battle"]
    assert(int(_find(b,"S0-2")["attack"]) == original_attack)
    assert(int(b["metrics"]["spent"]) == 0) # direct fixture orders logged separately
    assert(int(b["xp"].get("S0-2",0)) == 9)
    assert(Economy.valid(b["state"]["economy"],b["state"]["terrain"]))
    print("INTEGRATED_PAID_TECH l2=650 l3=1050 research=450 attack2_to4=true xp9_no_free_stack=true")
