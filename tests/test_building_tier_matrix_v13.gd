extends SceneTree

# All six producer types, mirrored factions, genuine purchases and upgrades.
# Funded probes are explicitly isolated: they test unlocks, not earnings.
const Lab = preload("res://scripts/experiments/BuildingProgressionV12.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

const CASES := [
    {"kind":"factory","row":3,"l1":"line","l2":"engineer",
        "l3":"","tech":"field_workshop"},
    {"kind":"armor_plant","row":1,"l1":"apc","l2":"tank",
        "l3":"","tech":"antiarmor_v1"},
    {"kind":"artillery_depot","row":5,"l1":"mobile_aa","l2":"spg",
        "l3":"mlrs","tech":""},
    {"kind":"drone_center","row":2,"l1":"uav_recon","l2":"loitering",
        "l3":"","tech":""},
    {"kind":"airbase","row":6,"l1":"attack_heli","l2":"fighter",
        "l3":"bomber","tech":""},
    {"kind":"shipyard","row":0,"l1":"patrol","l2":"corvette",
        "l3":"destroyer","tech":""}
]

func _initialize() -> void:
    var tested := 0
    var tier3_tested := 0
    for side in [0,1]:
        for spec in CASES:
            var caps: Dictionary = _verify(side,spec)
            tested += 1
            tier3_tested += int(caps["third"])
    assert(tested == 12 and tier3_tested == 10)
    print("PASS building tier matrix v13: 12 mirrored producer cases, 10 real level III paths, one intentionally blocked drone III, funded role unlocks, tech vs recruitment competition")
    quit(0)

static func _world(side: int) -> Dictionary:
    var board: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        board.append(row)
    board[0][0] = "water"
    board[0][9] = "water"
    var a: Dictionary = Roles.make_unit("A",side,Vector2i(2,3),"line")
    var b: Dictionary = Roles.make_unit("B",1-side,Vector2i(7,3),"line")
    var state: Dictionary = Session.start([a,b],board,side,false,false,true,true)
    assert(Economy.valid(state["economy"],state["terrain"]))
    return state

static func _site(spec: Dictionary, side: int) -> Vector2i:
    return Vector2i(0,int(spec["row"])) if side == 0 else Vector2i(9,int(spec["row"]))

static func _next_own_turn(state: Dictionary, progress: Dictionary,
        side: int) -> Dictionary:
    var first: Dictionary = Lab.end_turn(state,progress)
    assert(first.get("valid",false) and int(first["state"]["faction"]) == 1-side)
    var next: Dictionary = Lab.end_turn(first["state"],first["progress"])
    assert(next.get("valid",false) and int(next["state"]["faction"]) == side)
    return next

static func _funded(state: Dictionary, side: int) -> Dictionary:
    var new_state: Dictionary = state.duplicate(true)
    new_state["economy"]["credits"][side] = 2500
    return new_state

static func _verify(side: int, spec: Dictionary) -> Dictionary:
    var kind: String = str(spec["kind"])
    var place: Vector2i = _site(spec,side)
    var original: Dictionary = _world(side)
    var untouched: Dictionary = original.duplicate(true)
    var progress: Dictionary = {}
    assert(str(Economy.site_at(original["economy"],place)["kind"]) == kind)
    assert(Lab.level_for(original,progress,place) == 1)
    assert(Lab.can_recruit(original,progress,place,str(spec["l1"])))
    assert(not Lab.can_recruit(original,progress,place,str(spec["l2"])))
    var native_can_build_level2: bool = Economy.can_purchase(original,place,str(spec["l2"]))
    assert(native_can_build_level2)
    var raised: Dictionary = Lab.upgrade(original,progress,place)
    assert(raised.get("valid",false))
    assert(int(raised["level"]) == 2)
    assert(int(raised["cost"]) == int(Lab.UPGRADE_COSTS[kind][2]))
    assert(not Lab.can_recruit(raised["state"],raised["progress"],place,str(spec["l2"])))
    var next: Dictionary = _next_own_turn(raised["state"],raised["progress"],side)
    assert(Lab.level_for(next["state"],next["progress"],place) == 2)
    var full: Dictionary = _funded(next["state"],side)
    assert(Lab.can_recruit(full,next["progress"],place,str(spec["l2"])))
    var acquired: Dictionary = Lab.recruit(full,next["progress"],place,str(spec["l2"]))
    assert(acquired.get("valid",false))
    assert(str(acquired["role"]) == str(spec["l2"]))
    assert(int(acquired["state"]["units"].size()) == int(full["units"].size())+1)
    var third := false
    if Lab.UPGRADE_COSTS[kind].has(3):
        third = true
        var unupgraded: Dictionary = _funded(next["state"],side)
        if not str(spec["l3"]).is_empty():
            assert(not Lab.can_recruit(unupgraded,next["progress"],place,str(spec["l3"])))
        if not str(spec["tech"]).is_empty():
            assert(not Lab.can_research(unupgraded,next["progress"],place,str(spec["tech"])))
        var lvl3: Dictionary = Lab.upgrade(next["state"],next["progress"],place)
        assert(lvl3.get("valid",false))
        assert(int(lvl3["level"]) == 3)
        var phase: Dictionary = _next_own_turn(lvl3["state"],lvl3["progress"],side)
        var budgeted: Dictionary = _funded(phase["state"],side)
        assert(Lab.level_for(budgeted,phase["progress"],place) == 3)
        if not str(spec["l3"]).is_empty():
            assert(Lab.can_recruit(budgeted,phase["progress"],place,str(spec["l3"])))
            var end_unit: Dictionary = Lab.recruit(budgeted,phase["progress"],place,str(spec["l3"]))
            assert(end_unit.get("valid",false))
        else:
            assert(Lab.can_research(budgeted,phase["progress"],place,str(spec["tech"])))
            var researched: Dictionary = Lab.research(budgeted,phase["progress"],place,str(spec["tech"]))
            assert(researched.get("valid",false))
            assert(not Lab.can_research(researched["state"],researched["progress"],place,str(spec["tech"])))
    else:
        assert(kind == "drone_center")
        assert(not Lab.can_upgrade(next["state"],next["progress"],place))
    assert(original == untouched)
    print("BUILDING_TIER_CASE side=%d kind=%s level2_cost=%d tier2_role=%s tier3_supported=%s tier3_role=%s tier3_tech=%s production_slot_shared=true" % [
        side,kind,int(Lab.UPGRADE_COSTS[kind][2]),str(spec["l2"]),
        str(third),str(spec["l3"]),str(spec["tech"])
    ])
    return {"third":third}
