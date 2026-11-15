extends SceneTree

# 8-team visibility is a future, isolated module. Existing two-team fog
# must remain byte-identical; only public observations may leave the server.
const Fog=preload("res://scripts/core/FactionVisibilityV1.gd")
const Legacy=preload("res://scripts/core/Visibility.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")
const Rules=preload("res://scripts/core/Rules.gd")
const ROLES: Array=[0,1,2,3,4,5,6,7]
const LOCATIONS: Array=[
    Vector2i(1,1),Vector2i(4,1),Vector2i(10,1),Vector2i(20,1),
    Vector2i(1,15),Vector2i(8,15),Vector2i(15,15),Vector2i(22,15)
]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var terrain: Array=Scenarios.terrain(0,Vector2i(24,18))
    assert(Rules.valid_terrain(terrain))
    var army: Array=[]
    for faction in ROLES:
        army.append({"id":"U%d" % faction,"faction":faction,
            "hp":10,"vision":3,"pos":LOCATIONS[faction]})
    var state: Dictionary={
        "terrain":terrain,"units":army,"fog_enabled":true,
        "winner":-1,"faction":0,"secret_admin_token":"NEVER_LEAK",
        "contacts":{"0":{"U7":LOCATIONS[7]}},
        "economy":{"credits":[100,110,120,130,140,150,160,170],
            "sites":[{"kind":"city","owner":7,"pos":Vector2i(21,14)},
                     {"kind":"factory","owner":0,
                      "pos":Vector2i(2,1),"produced_turn":2}]},
        "control":{"scores":[1,2,3,4,5,6,7,8],
            "nodes":[{"owner":7,"pos":Vector2i(21,14)}]}
    }
    var original: Dictionary=state.duplicate(true)
    assert(Fog.visible_cells(state,0,ROLES).has(LOCATIONS[0]))
    assert(not Fog.visible_cells(state,0,ROLES).has(LOCATIONS[7]))
    for faction in ROLES:
        var visible: Dictionary=Fog.visible_cells(state,faction,ROLES)
        assert(visible.has(LOCATIONS[faction]))
        assert(visible.size()>0)
    var updated: Dictionary=Fog.update_exploration(state,ROLES)
    assert(updated!=state)
    assert((updated["explored"] as Dictionary).size()==8)
    assert(state==original)
    var f0: Dictionary=Fog.observed_state(updated,0,ROLES)
    assert(not f0.is_empty())
    assert(not f0.has("secret_admin_token"))
    assert(not f0.has("contacts"))
    assert(not f0.has("explored"))
    assert(not f0["units"].has(army[7]))
    assert(f0["units"].size()>=1)
    assert(int(f0["economy"]["credits"][0])==100)
    for faction in range(1,8):
        assert(int(f0["economy"]["credits"][faction])==-1)
        assert(int(f0["control"]["scores"][faction])==-1)
    assert(int(f0["control"]["scores"][0])==1)
    assert(int(f0["economy"]["sites"][0]["owner"])==-2)
    assert(int(f0["control"]["nodes"][0]["owner"])==-2)
    assert(str(f0["terrain"][LOCATIONS[7].y][LOCATIONS[7].x])=="water")
    assert(updated["units"]==army)
    assert(state==original)

    # Exploration can be remembered even after this unit leaves the tile.
    var after_move: Dictionary=updated.duplicate(true)
    after_move["units"][0]["pos"]=Vector2i(2,2)
    var seen: Dictionary=Fog.explored_cells(after_move,0,ROLES)
    assert(seen.has(LOCATIONS[0]))
    assert(not Fog.explored_cells(after_move,7,ROLES).has(LOCATIONS[0]))

    # The new LOS helper MUST agree exactly with today's live two-team fog
    # on regular, fog-disabled and mountain-occluded terrain.
    var old: Dictionary={
        "terrain":Scenarios.terrain(1,Vector2i(24,18)),
        "units":[army[0].duplicate(true),army[1].duplicate(true)],
        "fog_enabled":true
    }
    for fog_enabled in [true,false]:
        old["fog_enabled"]=fog_enabled
        for side in [0,1]:
            assert(Fog.visible_cells(old,side,[0,1])==Legacy.visible_cells(old,side))
    assert(Fog.visible_cells(state,8,ROLES).is_empty())
    assert(Fog.observed_state(state,8,ROLES).is_empty())
    assert(Fog.observed_state(state,0,[]).is_empty())

    # Roster IDs need not be contiguous. Wrong-size bank arrays must
    # fail closed rather than reveal the other participant's credits.
    var gap: Dictionary={
        "terrain":terrain,"units":[army[2],army[7]],"fog_enabled":true,
        "economy":{"credits":[999,123],"sites":[]},
        "control":{"scores":[5,9],"nodes":[]}
    }
    var private: Dictionary=Fog.observed_state(gap,2,[2,7])
    assert(not private.has("economy"))
    assert(not private.has("control"))
    assert(not private.has("contacts"))
    print("PASS TARVOKA EIGHT-FACTION FOG PRIVACY: 8 independent views, own-only budgets, no secrets, old 2-team LOS parity, sparse roster fail-closed")
    quit(0)
