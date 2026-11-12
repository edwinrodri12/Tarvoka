extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Arsenal = preload("res://scripts/core/ModernArsenal.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")

func _initialize() -> void:
    assert(Scenarios.LABELS.size() == 4)
    var classic: Dictionary = Session.start(Roles.experimental_armies(true),Scenarios.terrain(0),0,false,false,true)
    assert(classic["economy"]["credits"] == [300,300])
    assert(classic["economy"]["sites"].size() == 6)
    assert(Economy.income_for(classic["economy"],0) == 100)
    assert(not classic["economy"].has("modern"))
    assert(Codec.decode(Codec.encode(classic)) == classic)

    var sea: Array = Scenarios.terrain(3)
    for x in range(10):
        assert(sea[0][x] == "water" and sea[7][x] == "water")
        assert(sea[1][x] != "water" and sea[6][x] != "water")
    assert(Scenarios.identify(sea) == 3)
    var modern: Dictionary = Session.start(Roles.modern_armies(true),sea,0,false,false,true,true)
    assert(modern["economy"]["modern"] == true)
    assert(modern["economy"]["sites"].size() == 16)
    assert(modern["economy"]["credits"] == [2500,2500])
    assert(Economy.income_for(modern["economy"],0) == 250)
    assert(Economy.valid(modern["economy"],sea))
    assert(modern["units"].size() == 12)
    assert(Codec.decode(Codec.encode(modern)) == modern)

    # All 32 categories are obtainable in a modern coastal scenario.
    var roster: Array = Roles.ORDER.duplicate()
    roster.append_array(Arsenal.ORDER)
    assert(roster.size() == 32)
    var count := 0
    for role in roster:
        var producer: String = Economy.producer_for(role,true)
        var factory: Dictionary = {}
        for site in modern["economy"]["sites"]:
            if site["kind"] == producer and int(site["owner"]) == 0:
                factory = site
                break
        assert(not factory.is_empty())
        assert(Economy.can_purchase(modern,factory["pos"],role))
        var before: Dictionary = modern.duplicate(true)
        var action: Dictionary = Session.purchase(modern,factory["pos"],role)
        assert(action["valid"])
        var recruit: Dictionary = action["state"]["units"].back()
        assert(recruit["role"] == role)
        assert(recruit["faction"] == 0 and recruit["pos"] == factory["pos"])
        assert(recruit["acted"] and recruit["moved"])
        assert(action["cost"] == Economy.cost(role))
        assert(action["state"]["economy"]["credits"][0] == 2500 - action["cost"])
        assert(action["state"]["units"].size() == modern["units"].size()+1)
        assert(not Economy.can_purchase(action["state"],factory["pos"],role))
        assert(not Session.purchase(action["state"],factory["pos"],role)["valid"])
        assert(Codec.decode(Codec.encode(action["state"])) == action["state"])
        assert(before == modern)
        count += 1
    assert(count == 32)

    # An airbase never makes a ship; a dock cannot produce an aircraft or
    # land transport. Wrong-faction and blocked-layer purchases are rejected.
    var blue_shipyard: Vector2i = Vector2i(0,0)
    var blue_airbase: Vector2i = Vector2i(0,6)
    var blue_factory: Vector2i = Vector2i(0,3)
    assert(not Economy.can_purchase(modern,blue_shipyard,"fighter"))
    assert(not Economy.can_purchase(modern,blue_airbase,"frigate"))
    assert(not Economy.can_purchase(modern,blue_factory,"tank"))
    assert(not Economy.can_purchase(modern,Vector2i(9,0),"submarine"))
    assert(not Economy.can_purchase(modern,Vector2i(1,0),"submarine"))
    assert(not Economy.can_purchase(classic,blue_factory,"tank"))

    var air_blocker: Dictionary = Roles.make_unit("Q",0,blue_airbase,"uav_recon")
    var blocked: Dictionary = modern.duplicate(true)
    blocked["units"].append(air_blocker)
    assert(not Economy.can_purchase(blocked,blue_airbase,"fighter"))
    var surface_blocker: Dictionary = Roles.make_unit("R",0,blue_airbase,"line")
    blocked = modern.duplicate(true)
    blocked["units"].append(surface_blocker)
    assert(Economy.can_purchase(blocked,blue_airbase,"fighter")) # Another layer.
    assert(Codec.decode(Codec.encode(blocked)) == blocked)

    # A workshop is valid only on dry land; a dock only on navigable water.
    var corrupt: Dictionary = modern.duplicate(true)
    corrupt["economy"]["sites"][-1]["pos"] = Vector2i(2,2)
    assert(Codec.encode(corrupt).is_empty())
    corrupt = modern.duplicate(true)
    corrupt["economy"]["sites"][4]["kind"] = "shipyard"
    assert(Codec.encode(corrupt).is_empty())
    corrupt = modern.duplicate(true)
    corrupt["economy"]["modern"] = "yes"
    assert(Codec.encode(corrupt).is_empty())

    for id in range(3):
        var battleground: Array = Scenarios.terrain(id)
        var modern_land: Dictionary = Session.start(Roles.modern_armies(true),battleground,0,false,false,true,true)
        var expected_sites: int = 16 if id == 2 else 14 # The bridge map has navigable water for dock production.
        assert(modern_land["economy"]["modern"] and modern_land["economy"]["sites"].size() == expected_sites)
        assert(Economy.valid(modern_land["economy"],battleground))
        assert(Codec.decode(Codec.encode(modern_land)) == modern_land)

    print("PASS modern production: 32 roles, 6 facilities, 4 maps, legal costs/collisions, coastal docks and saved state")
    quit(0)
