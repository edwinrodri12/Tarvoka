extends SceneTree

const Roles = preload("res://scripts/core/UnitRoles.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Cargo = preload("res://scripts/core/CargoActions.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Logistics = preload("res://scripts/core/Logistics.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")

func _initialize() -> void:
    var state: Dictionary = Session.start([
        Roles.make_unit("AP",0,Vector2i(2,2),"apc"),
        Roles.make_unit("INF",0,Vector2i(2,3),"line"),
        Roles.make_unit("SURVIVE",1,Vector2i(8,6),"line")
    ],Scenarios.terrain(0),0,true,false,true,true)
    var before: Dictionary = state.duplicate(true)
    var embark: Dictionary = Session.embark(state,"INF","AP")
    assert(embark["valid"] and state == before)
    var loaded: Dictionary = embark["state"]
    var raw: String = Codec.encode(loaded)
    assert(not raw.is_empty())
    assert(Codec.decode(raw) == loaded)
    var baseline: Dictionary = JSON.parse_string(raw)
    assert(baseline["version"] == 1)
    assert((baseline["units"][0]["cargo"] as Array).size() == 1)
    assert(not baseline["units"][0]["cargo"][0].has("pos"))
    var attacks := 0
    for fault in ["duplicate_id","opponent_cargo","tank_cargo",
            "position_forgery","nested_cargo","negative_hp",
            "oversized_ammo","missing_stats","invalid_moved",
            "invalid_ready","bad_domain","too_many_seats",
            "dead_carrier","other_carrier","missing_cargo"]:
        var forged: Dictionary = baseline.duplicate(true)
        var unit: Dictionary = forged["units"][0]
        var soldier: Dictionary = unit["cargo"][0]
        match fault:
            "duplicate_id":
                soldier["id"] = "SURVIVE"
            "opponent_cargo":
                soldier["faction"] = 1
            "tank_cargo":
                soldier["role"] = "tank"
            "position_forgery":
                soldier["pos"] = [2,2]
            "nested_cargo":
                soldier["cargo"] = []
            "negative_hp":
                soldier["hp"] = -99
            "oversized_ammo":
                soldier["ammo"] = 300
            "missing_stats":
                soldier.erase("defense")
            "invalid_moved":
                soldier["moved"] = "false"
            "invalid_ready":
                soldier["acted"] = false
            "bad_domain":
                soldier["domain"] = "air"
            "too_many_seats":
                unit["cargo"] = [soldier.duplicate(true),soldier.duplicate(true),soldier.duplicate(true)]
            "dead_carrier":
                unit["hp"] = 0
            "other_carrier":
                unit["role"] = "ifv"
            "missing_cargo":
                unit["cargo"] = null
        var invalid: String = JSON.stringify(forged)
        assert(Codec.decode(invalid).is_empty())
        attacks += 1

    # The old JSON v1 without cargo remains bytewise roundtrip compatible.
    var legacy: Dictionary = Session.start([
        Roles.make_unit("A",0,Vector2i(2,2),"line"),
        Roles.make_unit("X",1,Vector2i(7,5),"line")
    ],Scenarios.terrain(0),0,true)
    assert(not legacy["units"][0].has("cargo"))
    assert(Codec.decode(Codec.encode(legacy)) == legacy)
    assert(not Codec.encode(legacy).contains("\"cargo\""))

    # On a large game board the loaded APC takes exactly one surface tile,
    # the passenger neither doubles vision nor grants a second ground layer.
    for dimensions in [Vector2i(24,18),Vector2i(40,30)]:
        var terrain: Array = Scenarios.terrain(0,dimensions)
        var big: Dictionary = Session.start([
            Roles.make_unit("AP",0,Vector2i(2,2),"apc"),
            Roles.make_unit("INF",0,Vector2i(2,3),"line"),
            Roles.make_unit("EN",1,Vector2i(dimensions.x-2,dimensions.y-2),"line")
        ],terrain,0,true,false,true,true)
        var original: Dictionary = big.duplicate(true)
        var before_sight: Dictionary = Visibility.visible_cells(big,0)
        var loaded_big: Dictionary = Session.embark(big,"INF","AP")
        assert(loaded_big["valid"])
        assert(Codec.decode(Codec.encode(loaded_big["state"])) == loaded_big["state"])
        var after_sight: Dictionary = Visibility.visible_cells(loaded_big["state"],0)
        assert(after_sight.size() <= before_sight.size())
        assert(original == big)

    # Refuse cargo of IFV and APC itself; these would be unreachable
    # phantom units if an action accepted them.
    var occupied: Dictionary = Session.start([
        Roles.make_unit("AP",0,Vector2i(2,2),"apc"),
        Roles.make_unit("IFV",0,Vector2i(2,3),"ifv"),
        Roles.make_unit("EN",1,Vector2i(8,6),"line")
    ],Scenarios.terrain(0),0,false,false,true,true)
    assert(not Session.embark(occupied,"IFV","AP")["valid"])
    assert(not Session.embark(occupied,"AP","IFV")["valid"])

    # Max army cap counts soldiers INSIDE the APC. An otherwise legal
    # factory purchase cannot raise the total above 256 or reuse a stowed ID.
    var saturated: Dictionary = loaded.duplicate(true)
    for n in range(253):
        var gone: Dictionary = Roles.make_unit("DEAD%d" % n,0,
            Vector2i(0,0),"line")
        gone["hp"] = 0
        saturated["units"].append(gone)
    assert(saturated["units"].size() == 255)
    assert(saturated["units"][0]["cargo"].size() == 1)
    assert(not Codec.encode(saturated).is_empty()) # 255 deployed + 1 held.
    assert(not Economy.can_purchase(saturated,Vector2i(0,1),"apc"))
    assert(not Session.purchase(saturated,Vector2i(0,1),"apc")["valid"])
    var over_cap: Dictionary = saturated.duplicate(true)
    over_cap["units"].append(Roles.make_unit("OVER",0,Vector2i(0,0),"line"))
    over_cap["units"].back()["hp"] = 0
    assert(Codec.encode(over_cap).is_empty())
    saturated["units"].pop_back()
    assert(Economy.can_purchase(saturated,Vector2i(0,1),"apc"))
    var last_slot: Dictionary = Session.purchase(saturated,Vector2i(0,1),"apc")
    assert(last_slot["valid"] and last_slot["state"]["units"].size() == 255)
    assert(not Codec.encode(last_slot["state"]).is_empty())
    attacks += 1
    print("PASS APC transport save security: %d forged cargo manifests rejected; old v1, 24x18/40x30 fog, domain and identity guard" % attacks)
    quit(0)
