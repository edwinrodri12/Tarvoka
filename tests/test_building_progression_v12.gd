extends SceneTree

# Tier I-II-III BALANCE LAB: economy + real producer actions.
# Does not activate progression in Android, SaveCodec or production AI.
const Lab = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Save = preload("res://scripts/core/SaveCodec.gd")

func _initialize() -> void:
    var n := 0
    _catalog_coverage()
    n += 1
    for side in [0,1]:
        _tier_price_vs_early_army(side)
        _global_antiarmor_research(side)
        _field_workshop_research(side)
        _capture_resets_facility_level(side)
        _budget_and_misuse(side)
        n += 5
    assert(n == 11)
    print("PASS building progression v12: 11 suites, 32 catalog roles, I/II/III gates, real producer turn tradeoffs, credit-paid scoped technologies, mirrored factions and capture resets")
    quit(0)

static func _board() -> Array:
    var board: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        board.append(row)
    # Existing production engine requires water on shipyard tiles.
    board[0][0] = "water"
    board[0][9] = "water"
    return board

static func _start(side: int) -> Dictionary:
    var piercer: Dictionary = Roles.make_unit("P",side,Vector2i(2,3),"piercer")
    var tank_foe: Dictionary = Roles.make_unit("T",1-side,Vector2i(3,3),"tank")
    var engineer: Dictionary = Roles.make_unit("ENG",side,Vector2i(2,5),"engineer")
    var wounded: Dictionary = Roles.make_unit("W",side,Vector2i(3,5),"tank")
    wounded["hp"] = 5
    var state: Dictionary = Session.start(
        [piercer,tank_foe,engineer,wounded],
        _board(),side,false,false,true,true
    )
    assert(state.has("economy") and Economy.valid(state["economy"],state["terrain"]))
    assert(Economy.site_at(state["economy"],Vector2i(0,0))["kind"] == "shipyard")
    assert(Save.decode(Save.encode(state)) == state)
    return state

static func _plant(side: int) -> Vector2i:
    return Vector2i(0,1) if side == 0 else Vector2i(9,1)

static func _base(side: int) -> Vector2i:
    return Vector2i(0,3) if side == 0 else Vector2i(9,3)

static func _side_returns(state: Dictionary, progress: Dictionary,
        side: int) -> Dictionary:
    var next: Dictionary = Lab.end_turn(state,progress)
    assert(bool(next.get("valid",false)))
    assert(int(next["state"]["faction"]) == 1-side)
    next = Lab.end_turn(next["state"],next["progress"])
    assert(bool(next.get("valid",false)))
    assert(int(next["state"]["faction"]) == side)
    return next

static func _lookup(units: Array, identifier: String) -> Dictionary:
    for u in units:
        if str(u.get("id","")) == identifier:
            return u
    return {}

static func _catalog_coverage() -> void:
    assert(Lab.missing_catalog_roles().is_empty())
    var found: Dictionary = {}
    var roster: Array = []
    roster.append_array(Roles.ORDER)
    roster.append_array(Arsenal.ORDER)
    assert(roster.size() == 32)
    for role in roster:
        assert(not found.has(role))
        found[role] = true
        var tier: int = Lab.required_level(str(role))
        var site: String = Economy.producer_for(str(role),true)
        assert(tier in [1,2,3])
        assert(Lab.UPGRADE_COSTS.has(site))
        assert(not Roles.make_unit("X",0,Vector2i(3,3),str(role)).is_empty())
    assert(Lab.required_level("tank") == 2)
    assert(Lab.required_level("bomber") == 3)
    assert(Lab.required_level("destroyer") == 3)
    assert(Lab.required_level("piercer") == 1)
    assert(Lab.required_level("engineer") == 2)
    assert(Lab.required_level("role_not_real") == 0)
    # No imaginary "level 3 drones" until a real specialist ability exists.
    assert(not Lab.UPGRADE_COSTS["drone_center"].has(3))
    print("TIER_CATALOG validated_roles=%d factory_kinds=%d drone_level3_blocked=true" % [
        roster.size(),Lab.UPGRADE_COSTS.size()
    ])

static func _tier_price_vs_early_army(side: int) -> void:
    var origin: Dictionary = _start(side)
    var snap: Dictionary = origin.duplicate(true)
    var place: Vector2i = _plant(side)
    var progress: Dictionary = {}
    assert(Economy.can_purchase(origin,place,"tank"))
    assert(not Lab.can_recruit(origin,progress,place,"tank"))
    assert(Lab.can_recruit(origin,progress,place,"apc"))
    # Alternative 1 — buy a light APC immediately; move it off the
    # factory on the next friendly turn and build another.
    var apc_one: Dictionary = Lab.recruit(origin,progress,place,"apc")
    assert(apc_one.get("valid",false) and int(apc_one["cost"]) == 300)
    assert(not Lab.can_upgrade(apc_one["state"],apc_one["progress"],place))
    var to_next: Dictionary = _side_returns(apc_one["state"],apc_one["progress"],side)
    var cell: Vector2i = Vector2i(1,1) if side == 0 else Vector2i(8,1)
    var moved: Dictionary = Session.move(to_next["state"],str(apc_one["unit_id"]),cell)
    assert(moved.get("valid",false))
    var apc_two: Dictionary = Lab.recruit(moved["state"],to_next["progress"],place,"apc")
    assert(apc_two.get("valid",false) and int(apc_two["cost"]) == 300)
    assert(int(apc_two["state"]["economy"]["credits"][side]) == 2150)
    # Alternative 2 — spend the first production phase upgrading to II.
    var upgraded: Dictionary = Lab.upgrade(origin,progress,place)
    assert(upgraded.get("valid",false))
    assert(int(upgraded["level"]) == 2 and int(upgraded["cost"]) == 650)
    assert(int(upgraded["state"]["economy"]["credits"][side]) == 1850)
    assert(not Lab.can_recruit(upgraded["state"],upgraded["progress"],place,"tank"))
    assert(not Lab.can_upgrade(upgraded["state"],upgraded["progress"],place))
    var following: Dictionary = _side_returns(upgraded["state"],upgraded["progress"],side)
    assert(Lab.can_recruit(following["state"],following["progress"],place,"tank"))
    var tank: Dictionary = Lab.recruit(following["state"],following["progress"],place,"tank")
    assert(tank.get("valid",false) and int(tank["cost"]) == 750)
    assert(int(tank["state"]["economy"]["credits"][side]) == 1350)
    assert(int(tank["state"]["economy"]["credits"][1-side]) ==
        int(apc_two["state"]["economy"]["credits"][1-side]))
    assert(int(tank["state"]["units"].size()) == int(origin["units"].size())+1)
    assert(int(apc_two["state"]["units"].size()) == int(origin["units"].size())+2)
    assert(origin == snap)
    print("TIER_EARLY_TRADE side=%d level1_two_apc=600cr_and_two_units left=%d level2_upgrade_plus_tank=1400cr_one_unit left=%d two_owned_turns=true" % [
        side,int(apc_two["state"]["economy"]["credits"][side]),
        int(tank["state"]["economy"]["credits"][side])
    ])

static func _global_antiarmor_research(side: int) -> void:
    var state: Dictionary = _start(side)
    var progress: Dictionary = {}
    var place: Vector2i = _plant(side)
    assert(not Lab.can_research(state,progress,place,"antiarmor_v1"))
    var upgrade2: Dictionary = Lab.upgrade(state,progress,place)
    assert(upgrade2.get("valid",false))
    var ready2: Dictionary = _side_returns(upgrade2["state"],upgrade2["progress"],side)
    var upgrade3: Dictionary = Lab.upgrade(ready2["state"],ready2["progress"],place)
    assert(upgrade3.get("valid",false))
    assert(int(upgrade3["level"]) == 3 and int(upgrade3["cost"]) == 1050)
    assert(not Lab.can_research(upgrade3["state"],upgrade3["progress"],place,"antiarmor_v1"))
    var ready3: Dictionary = _side_returns(upgrade3["state"],upgrade3["progress"],side)
    var plain_hit: Dictionary = Lab.attack(ready3["state"],ready3["progress"],"P","T")
    assert(plain_hit.get("valid",false))
    assert(int(plain_hit["damage"]) == 2)
    var tech: Dictionary = Lab.research(ready3["state"],ready3["progress"],place,"antiarmor_v1")
    assert(tech.get("valid",false))
    assert(int(tech["cost"]) == 450)
    assert(Lab.has_tech(tech["progress"],side,"antiarmor_v1"))
    assert(not Lab.has_tech(tech["progress"],1-side,"antiarmor_v1"))
    assert(not Lab.can_research(tech["state"],tech["progress"],place,"antiarmor_v1"))
    assert(not Lab.can_recruit(tech["state"],tech["progress"],place,"apc"))
    var specialized: Dictionary = Lab.attack(tech["state"],tech["progress"],"P","T")
    assert(specialized.get("valid",false) and int(specialized["damage"]) == 4)
    assert(int(_lookup(specialized["state"]["units"],"P")["attack"]) == 4)
    assert(int(_lookup(specialized["state"]["units"],"T")["hp"]) == 10)
    assert(Lab.level_for(tech["state"],tech["progress"],place) == 3)
    # Costs sum to 2150, with 500 city income before researching.
    assert(int(tech["state"]["economy"]["credits"][side]) == 850)
    assert(int(upgrade2["state"]["economy"]["credits"][side]) == 1850)
    assert(int(upgrade3["state"]["economy"]["credits"][side]) == 1050)
    assert(Save.decode(Save.encode(tech["state"])) == tech["state"])
    print("TIER_ANTIARMOR_TECH side=%d tier2=650 tier3=1050 research=450 total=2150 no_buff_before=true hit=2_to_4 tech_side_only=true" % side)

static func _field_workshop_research(side: int) -> void:
    var state: Dictionary = _start(side)
    var progress: Dictionary = {}
    var factory: Vector2i = _base(side)
    var early_field: Dictionary = Lab.repair(state,progress,"ENG","W","field")
    assert(not early_field.get("valid",false))
    var early_light: Dictionary = Lab.repair(state,progress,"ENG","W","small")
    assert(early_light.get("valid",false) and int(early_light["hp_restored"]) == 2)
    var second: Dictionary = Lab.upgrade(state,progress,factory)
    assert(second.get("valid",false) and int(second["cost"]) == 400)
    var after: Dictionary = _side_returns(second["state"],second["progress"],side)
    assert(Lab.can_recruit(after["state"],after["progress"],factory,"engineer"))
    var third: Dictionary = Lab.upgrade(after["state"],after["progress"],factory)
    assert(third.get("valid",false) and int(third["cost"]) == 750)
    var open: Dictionary = _side_returns(third["state"],third["progress"],side)
    var researched: Dictionary = Lab.research(open["state"],open["progress"],factory,"field_workshop")
    assert(researched.get("valid",false) and int(researched["cost"]) == 250)
    assert(Lab.has_tech(researched["progress"],side,"field_workshop"))
    var healed: Dictionary = Lab.repair(researched["state"],researched["progress"],"ENG","W","field")
    assert(healed.get("valid",false))
    assert(int(healed["hp_restored"]) == 3 and int(healed["cost"]) == 100)
    assert(int(_lookup(healed["state"]["units"],"W")["hp"]) == 8)
    assert(bool(_lookup(healed["state"]["units"],"ENG")["acted"]))
    print("TIER_FIELD_REPAIR side=%d workshop_l2=400 l3=750 research=250 light_baseline=true upgraded_3hp=true" % side)

static func _capture_resets_facility_level(side: int) -> void:
    var original: Dictionary = _start(side)
    var place: Vector2i = _plant(side)
    var upgraded: Dictionary = Lab.upgrade(original,{},place)
    assert(upgraded.get("valid",false))
    var stolen: Dictionary = upgraded["state"].duplicate(true)
    var site: Dictionary = Economy.site_at(stolen["economy"],place)
    site["owner"] = 1-side
    assert(Economy.valid(stolen["economy"],stolen["terrain"]))
    var cleared: Dictionary = Lab.reconcile(stolen,upgraded["progress"])
    assert(Lab.level_for(stolen,cleared,place) == 1)
    assert(Lab.level_for(stolen,upgraded["progress"],place) == 1)
    var recaptured: Dictionary = stolen.duplicate(true)
    var ours: Dictionary = Economy.site_at(recaptured["economy"],place)
    ours["owner"] = side
    assert(Lab.level_for(recaptured,cleared,place) == 1)
    print("TIER_OWNER_RESET side=%d lvl2_not_transferred=true no_upgrade_reappears_after_recapture=true" % side)

static func _budget_and_misuse(side: int) -> void:
    var base: Dictionary = _start(side)
    var place: Vector2i = _plant(side)
    var factory: Vector2i = _base(side)
    var shortage: Dictionary = base.duplicate(true)
    shortage["economy"]["credits"][side] = 649
    assert(not Lab.upgrade(shortage,{},place).get("valid",false))
    var upgraded: Dictionary = Lab.upgrade(base,{},place)
    assert(upgraded.get("valid",false))
    assert(not Lab.upgrade(upgraded["state"],upgraded["progress"],place).get("valid",false))
    assert(not Lab.can_research(upgraded["state"],upgraded["progress"],place,"field_workshop"))
    assert(not Lab.recruit(base,{},factory,"engineer").get("valid",false))
    assert(not Lab.can_upgrade(base,{},Vector2i(3,4)))
    assert(not Lab.can_upgrade(base,{},Vector2i(1,1)))
    assert(not Lab.can_recruit(base,{},place,"bomber"))
    assert(not Lab.can_recruit(base,{},place,"role_not_real"))
    assert(not Lab.can_research(base,{},factory,"antiarmor_v1"))
    assert(not Lab.research(base,{},factory,"alien_technology").get("valid",false))
    assert(int(Lab.level_for(base,{},factory)) == 1)
    var naval: Vector2i = Vector2i(0,0) if side == 0 else Vector2i(9,0)
    assert(Lab.can_recruit(base,{},naval,"patrol"))
    assert(not Lab.can_recruit(base,{},naval,"destroyer"))
    var drone: Vector2i = Vector2i(0,2) if side == 0 else Vector2i(9,2)
    var drone_ii: Dictionary = Lab.upgrade(base,{},drone)
    assert(drone_ii.get("valid",false))
    var ready: Dictionary = _side_returns(drone_ii["state"],drone_ii["progress"],side)
    assert(not Lab.can_upgrade(ready["state"],ready["progress"],drone))
