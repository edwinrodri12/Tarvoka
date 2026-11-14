extends SceneTree

const Planner = preload("res://scripts/core/GroundArmorProcurement.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

const CASES := [
    {"threat":"tank","fog":false,"owned":[],"credits":2500,"role":"piercer"},
    {"threat":"bulwark","fog":false,"owned":[],"credits":2500,"role":"piercer"},
    {"threat":"tank","fog":false,"owned":["piercer"],"credits":2500,"role":"tank"},
    {"threat":"ifv","fog":false,"owned":[],"credits":2500,"role":"tank"},
    {"threat":"apc","fog":false,"owned":["tank"],"credits":2500,"role":"ifv"},
    {"threat":"line","fog":false,"owned":[],"credits":2500,"role":"ifv"},
    {"threat":"line","fog":false,"owned":["ifv"],"credits":2500,"role":"apc"},
    {"threat":"spg","fog":false,"owned":[],"credits":2500,"role":"apc"},
    {"threat":"artillery","fog":false,"owned":["apc"],"credits":2500,"role":"ifv"},
    {"threat":"line","fog":true,"owned":[],"credits":2500,"role":"apc"},
    {"threat":"line","fog":true,"owned":["apc"],"credits":2500,"role":"ifv"},
    {"threat":"line","fog":false,"owned":[],"credits":330,"role":"apc"},
    {"threat":"tank","fog":false,"owned":[],"credits":350,"role":"piercer"},
    {"threat":"tank","fog":false,"owned":[],"credits":299,"role":""}
]

static func _scenario(side: int, threat: String, fog: bool,
        owned: Array, credits: int) -> Dictionary:
    var ours := Vector2i(1,2) if side == 0 else Vector2i(8,2)
    var theirs := Vector2i(8,5) if side == 0 else Vector2i(1,5)
    var units: Array = [
        Roles.make_unit("A",side,ours,"line"),
        Roles.make_unit("E",1-side,theirs,threat)
    ]
    for i in range(owned.size()):
        var pos := Vector2i(2,5+i) if side == 0 else Vector2i(7,5+i)
        units.append(Roles.make_unit("OWN%d" % i,side,pos,str(owned[i])))
    var state: Dictionary = Session.start(
        units,Scenarios.terrain(0),side,fog,false,true,true)
    assert(state.get("winner",-2) == -1)
    state["economy"]["credits"][side] = credits
    for unit in state["units"]:
        if int(unit.get("faction",-1)) == side:
            unit["acted"] = true # Make recruiting the only legal AI order.
    for site in state["economy"]["sites"]:
        if int(site["owner"]) != side:
            continue
        if str(site["kind"]) not in ["armor_plant","city"]:
            # Neutralize unrelated factories without consuming the shared
            # 1/2/3-purchases-per-phase limit or leaking opponent funds.
            site["owner"] = -1
    assert(Economy.valid(state["economy"],state["terrain"]))
    return state

func _initialize() -> void:
    assert(Planner.GROUND_ROLES.size() == 5)
    assert(Planner.ranking({},0,{}) == [
        "apc","ifv","piercer","tank","bulwark"])
    var checks := 0
    for entry in CASES:
        for side in [0,1]:
            var state: Dictionary = _scenario(side,str(entry["threat"]),
                bool(entry["fog"]),entry["owned"],int(entry["credits"]))
            var before: Dictionary = state.duplicate(true)
            var observed: Dictionary = Visibility.observed_state(state,side)
            var counts: Dictionary = {}
            for unit in observed["units"]:
                if int(unit["faction"]) == side and int(unit["hp"]) > 0:
                    counts[str(unit["role"])] = int(counts.get(str(unit["role"]),0))+1
            var rank: Array = Planner.ranking(observed,side,counts)
            assert(rank.size() == 5)
            for role in Planner.GROUND_ROLES:
                assert(rank.count(role) == 1)
            # Missing enemy contacts are hidden under fog. The public
            # observed snapshot never passes their role to the planner.
            if bool(entry["fog"]):
                assert(not Visibility.is_unit_visible(state,side,"E"))
                assert(not rank[0] == "piercer")
            var chosen: Dictionary = AI.step(state)
            if str(entry["role"]).is_empty():
                assert(not chosen.get("valid",false))
            else:
                assert(chosen["valid"] and chosen["action"] == "produce")
                assert(str(chosen["role"]) == str(entry["role"]))
                assert(int(chosen["cost"]) == Economy.cost(str(entry["role"])))
                var spent: int = int(before["economy"]["credits"][side]) - int(chosen["state"]["economy"]["credits"][side])
                assert(spent == int(chosen["cost"]))
                assert(chosen["state"]["economy"]["credits"][1-side] ==
                    before["economy"]["credits"][1-side])
                assert(chosen["state"]["units"].back()["role"] == chosen["role"])
                assert(chosen["state"]["units"].back()["acted"])
                assert(Codec.decode(Codec.encode(chosen["state"])) ==
                    chosen["state"])
                assert(Economy.valid(chosen["state"]["economy"],
                    chosen["state"]["terrain"]))
            assert(before == state) # Planner never mutates combat or treasury.
            checks += 1
    assert(checks == CASES.size()*2)

    # Known enemy budgets, ammo and fuel do NOT affect our ranking, even
    # when a scout has observed the enemy role (public visible role only).
    var visible: Dictionary = _scenario(0,"tank",false,[],2500)
    var hidden_finance: Dictionary = visible.duplicate(true)
    hidden_finance["economy"]["credits"][1] = 31415
    hidden_finance["units"][1]["ammo"] = 0
    hidden_finance["units"][1]["fuel"] = 0
    assert(AI.step(visible)["role"] == AI.step(hidden_finance)["role"])

    var fogged: Dictionary = _scenario(0,"tank",true,[],2500)
    var unseen: Dictionary = fogged.duplicate(true)
    unseen["units"][1]["role"] = "line" # Alien role changes outside sight.
    unseen["units"][1]["attack"] = 5
    unseen["units"][1]["hp"] = 10
    assert(not Visibility.is_unit_visible(fogged,0,"E"))
    assert(not Visibility.is_unit_visible(unseen,0,"E"))
    assert(AI.step(fogged)["role"] == "apc")
    assert(AI.step(unseen)["role"] == "apc")
    assert(AI.step(fogged)["cost"] == AI.step(unseen)["cost"])

    print("PASS ground armor procurement: %d mirrored real factory orders; four real roles, budget fallback, cargo honesty, visible threats and fog privacy" % checks)
    quit(0)
