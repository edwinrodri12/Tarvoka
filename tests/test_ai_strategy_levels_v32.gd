extends SceneTree

const Director = preload("res://scripts/core/StrategicDirectorV32.gd")
const AI = preload("res://scripts/core/BasicAI.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Vision = preload("res://scripts/core/Visibility.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

static func _squad() -> Array:
    return [
        {"id":"ALLY","faction":0,"hp":8,
         "pos":Vector2i(2,2),"move_points":3,
         "attack":4,"defense":0,"cover":0,"acted":false,"role":"line"},
        {"id":"ENEMY","faction":1,"hp":10,
         "pos":Vector2i(7,5),"move_points":3,
         "attack":4,"defense":0,"cover":0,"acted":false,"role":"line"}
    ]

static func _session(fog: bool = false) -> Dictionary:
    return Session.start(_squad(),Scenarios.terrain(0),
        0,fog,false,true,true)

static func _level_contract() -> void:
    var state: Dictionary = _session()
    var knowledge: Dictionary = Vision.observed_state(state,0)
    var old: Dictionary = state.duplicate(true)
    assert(Director.LEVEL_NAMES.size() == 12)
    assert(Director.STYLES.size() >= 10)
    var last_weight := 0
    for level in range(1,13):
        var plan: Dictionary = Director.choose(knowledge,0,
            {"ai_level":level})
        assert(plan.get("valid",false))
        assert(int(plan["level"]) == level)
        assert(not str(plan["difficulty"]).is_empty())
        assert(int(plan["city_weight"]) > last_weight)
        last_weight = int(plan["city_weight"])
        assert(plan["available_actions"] == [
            "move","attack","purchase","resupply","end_turn"])
        assert(not plan["available_actions"].has("upgrade"))
        assert(not plan.has("enemy_credits"))
        var priorities: Dictionary = Director.production_priorities(
            plan,{},plan["counts"])
        assert(priorities.size() == Economy.MODERN_PRODUCERS.size())
        for site in priorities:
            assert(not priorities[site].is_empty())
            for role in priorities[site]:
                assert(Economy.producer_for(str(role),true) == str(site))
        print("AI_LEVEL_V32 level=%d name=%s style=%s city_weight=%d capture_threshold=%d counter=%s" % [
            level,str(plan["difficulty"]),str(plan["style"]),
            int(plan["city_weight"]),int(plan["profile"]["capture_threshold"]),
            str(plan["profile"]["observed_counterplay"])])
    assert(not Director.choose(knowledge,0,
        {"ai_level":6,"ai_style":"invalid"}).get("valid",false))
    assert(state == old)

static func _strategic_styles() -> void:
    var state: Dictionary = _session()
    var known: Dictionary = Vision.observed_state(state,0)
    for style in Director.STYLES:
        var plan: Dictionary = Director.choose(known,0,
            {"ai_level":12,"ai_style":style})
        assert(plan.get("valid",false))
        assert(str(plan["style"]) == str(style) or style == "adaptive")
        var production: Dictionary = Director.production_priorities(
            plan,{},plan["counts"])
        for facility in Economy.MODERN_PRODUCERS:
            assert(production.has(facility))
            assert(production[facility].size() >= 3)
        assert(not plan["available_actions"].has("research"))
        print("AI_STYLE_V32 name=%s chosen=%s intent=%s" % [
            style,str(plan["style"]),str(plan["development_intent"])])

    # A visible armored threat changes policy at higher levels; a novice
    # keeps a simpler policy. Both are confined to the same observed map.
    var pressured: Dictionary = state.duplicate(true)
    pressured["units"].append({
        "id":"TANK2","faction":1,"hp":14,
        "pos":Vector2i(6,6),"move_points":4,
        "attack":8,"defense":2,"cover":0,"acted":false,"role":"tank"
    })
    pressured["units"][1]["role"] = "tank"
    var p: Dictionary = Director.choose(
        Vision.observed_state(pressured,0),0,{"ai_level":9})
    assert(p.get("valid",false))
    assert(str(p["style"]) == "combined_arms")
    assert(int(p["visible_armor"]) >= 2)
    var novice: Dictionary = Director.choose(
        Vision.observed_state(pressured,0),0,{"ai_level":1})
    assert(novice["style"] == "balanced")

static func _real_recruitment() -> void:
    var original: Dictionary = _session()
    var state: Dictionary = original.duplicate(true)
    state["units"][0]["acted"] = true
    state["units"][0]["moved"] = true
    var before: Dictionary = state.duplicate(true)
    var expansion: Dictionary = AI.step(state,{
        "ai_level":9,"ai_style":"expansion"})
    assert(expansion.get("valid",false))
    assert(expansion["action"] == "produce")
    assert(Economy.valid(expansion["state"]["economy"],
        expansion["state"]["terrain"]))
    assert(int(expansion["state"]["economy"]["credits"][0]) ==
        int(before["economy"]["credits"][0]) -
        Economy.cost(str(expansion["role"])))
    assert(state == before)
    var legacy: Dictionary = AI.step(state)
    assert(legacy.get("valid",false))
    var default_options: Dictionary = AI.step(state,{})
    assert(legacy == default_options)
    print("AI_RECRUIT_V32 strategy=expansion role=%s price=%d old_role=%s" % [
        str(expansion["role"]),Economy.cost(str(expansion["role"])),
        str(legacy.get("role","none"))])

static func _fog_and_level_tactics() -> void:
    var terrain: Array = Scenarios.terrain(0)
    var ally := {"id":"A","faction":0,"hp":6,"pos":Vector2i(3,3),
        "move_points":3,"attack":2,"defense":0,"cover":0,"acted":false}
    var support := {"id":"B","faction":0,"hp":10,"pos":Vector2i(1,3),
        "move_points":3,"attack":3,"defense":0,"cover":0,"acted":false}
    var enemy := {"id":"X","faction":1,"hp":10,"pos":Vector2i(4,3),
        "move_points":3,"attack":8,"defense":0,"cover":0,"acted":false}
    var threatened: Dictionary = Session.start([ally,enemy,support],terrain)
    var easy: Dictionary = AI.step(threatened,{"ai_level":2})
    var hard: Dictionary = AI.step(threatened,{"ai_level":10})
    assert(easy.get("valid",false) and hard.get("valid",false))
    assert(easy["action"] == "attack")
    assert(hard["action"] == "move" and hard["reason"] == "retreat")
    assert(hard["state"]["units"][0]["hp"] == 6)
    var fog: Dictionary = _session(true)
    var unknown: Dictionary = fog.duplicate(true)
    assert(not Vision.is_unit_visible(fog,0,"ENEMY"))
    unknown["units"][1]["pos"] = Vector2i(8,6)
    unknown["units"][1]["hp"] = 2
    assert(not Vision.is_unit_visible(unknown,0,"ENEMY"))
    var view1: Dictionary = Vision.observed_state(fog,0)
    var view2: Dictionary = Vision.observed_state(unknown,0)
    assert(Director.choose(view1,0,{"ai_level":12}) ==
        Director.choose(view2,0,{"ai_level":12}))
    var a: Dictionary = AI.step(fog,{"ai_level":12})
    var b: Dictionary = AI.step(unknown,{"ai_level":12})
    assert(bool(a.get("valid",false)) == bool(b.get("valid",false)))
    assert(str(a.get("action","none")) == str(b.get("action","none")))
    assert(a.get("unit_id","") == b.get("unit_id",""))
    assert(a.get("destination",Vector2i(-1,-1)) ==
        b.get("destination",Vector2i(-1,-1)))
    print("AI_FAIRNESS_V32 difficulty=12 no_unseen_knowledge=true lethality=visible_only=true")

func _initialize() -> void:
    _level_contract()
    _strategic_styles()
    _real_recruitment()
    _fog_and_level_tactics()
    print("PASS strategic AI v32: 12 difficulty levels, 11 styles, all 6 factories, legal purchases, observed-only adaptive tactics, default parity")
    quit(0)
