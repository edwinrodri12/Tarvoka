extends SceneTree

# Only specialist infantry may build a NON-PRODUCING camp.
# Supply/medical infantry are explicitly not yet in UnitRoles and
# cannot be faked through arbitrary role-string dictionaries.
const Camp = preload("res://scripts/experiments/SpecialistCampsV17.gd")
const Sites = preload("res://scripts/experiments/StrategicMapSitesV17.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    var tested := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var terrain: Array = Scenarios.terrain(0,dims)
        var map: Dictionary = Sites.layout(terrain)
        assert(map.get("valid",false))
        _case(dims,terrain,map)
        tested += 1
    assert(tested == 3)
    assert(Camp.proposed_new_infantry_roles() == ["field_medic","quartermaster"])
    print("PASS specialist camps v17: 3 map sizes, camp-only construction, strict scout/engineer exclusivity, planned medic/quartermaster locked, no overlapping sites, no automatic unit production")
    quit(0)

static func _free(terrain: Array, sites: Array, excluded: Array) -> Vector2i:
    var dims: Vector2i = Rules.map_size(terrain)
    for y in range(1,dims.y-1):
        for x in range(1,dims.x-1):
            var loc := Vector2i(x,y)
            if loc in excluded or str(terrain[y][x]) not in ["plain","road","forest"]:
                continue
            var used := false
            for site in sites:
                if site["pos"] == loc:
                    used = true
            if not used:
                return loc
    return Vector2i(-1,-1)

static func _case(dims: Vector2i, terrain: Array, map: Dictionary) -> void:
    var position: Vector2i = _free(terrain,map["sites"],[])
    assert(position.x >= 0)
    var scout: Dictionary = Roles.make_unit("SC",0,position,"scout")
    var guard: Dictionary = Roles.make_unit("GU",0,Vector2i(1,0),"line")
    var units: Array = [scout,guard]
    var camps: Array = []
    assert(Camp.max_per_side(terrain) == (2 if dims.x == 10 else (4 if dims.x == 24 else 6)))
    assert(Camp.can_build(terrain,map["sites"],camps,units,"SC","recon",0,100))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"SC","defense",0,999))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"GU","defense",0,999))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"SC","medical",0,999))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"SC","supply",0,999))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"SC","armor_plant",0,999))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"SC","recon",1,999))
    assert(not Camp.can_build(terrain,map["sites"],camps,units,"SC","recon",0,99))
    var result: Dictionary = Camp.build(terrain,map["sites"],camps,units,"SC","recon",0,300)
    assert(result.get("valid",false))
    assert(int(result["credits_after"]) == 200)
    assert(int(result["cost"]) == 100)
    assert(not bool(result["produces_units"]))
    assert(bool(result["consumes_action"]))
    assert(int(result["camps"].size()) == 1)
    assert(bool(result["units"][0]["acted"]))
    assert(not bool(units[0]["acted"]))
    assert(not Camp.build(terrain,map["sites"],result["camps"],result["units"],"SC","recon",0,999).get("valid",false))
    # Engineer can build DEFENSIVE, but not scout's recon or medic's tents.
    var next: Vector2i = _free(terrain,map["sites"],[position])
    assert(next.x >= 0)
    var engineer: Dictionary = Roles.make_unit("EN",0,next,"engineer")
    var builders: Array = [engineer]
    assert(Camp.can_build(terrain,map["sites"],result["camps"],builders,"EN","defense",0,130))
    assert(not Camp.can_build(terrain,map["sites"],result["camps"],builders,"EN","medical",0,1000))
    assert(not Camp.can_build(terrain,map["sites"],result["camps"],builders,"EN","supply",0,1000))
    var defenses: Dictionary = Camp.build(terrain,map["sites"],result["camps"],builders,"EN","defense",0,500)
    assert(defenses.get("valid",false))
    assert(int(defenses["credits_after"]) == 370)
    assert(defenses["camps"].size() == 2)
    assert(not Camp.can_build(terrain,map["sites"],defenses["camps"],builders,"EN","defense",0,999))
    assert(not Camp.can_build(terrain,map["sites"],defenses["camps"],builders,"EN","recon",0,999))
    # A new "field_medic" or "quartermaster" string is NOT a valid core
    # unit. Even a synthetic fixture cannot get those camps yet.
    var pretend_medic: Dictionary = {
        "id":"F-M","role":"field_medic","faction":0,"hp":8,
        "acted":false,"domain":"ground","pos":_free(terrain,map["sites"],[position,next])
    }
    var pretend_supply: Dictionary = pretend_medic.duplicate(true)
    pretend_supply["id"] = "F-Q"
    pretend_supply["role"] = "quartermaster"
    assert(not Camp.can_build(terrain,map["sites"],[],[pretend_medic],"F-M","medical",0,999))
    assert(not Camp.can_build(terrain,map["sites"],[],[pretend_supply],"F-Q","supply",0,999))
    for kind in Camp.CAMPS:
        assert(not bool(Camp.CAMPS[kind].has("produces_units")))
        assert(str(Camp.CAMPS[kind]["effect"]).length() > 0)
    assert(map["sites"].size() == int(map["cities"])+int(map["producers"]))
    print("SPECIAL_CAMPS size=%s per_faction_cap=%d recon_100cr=legal defense_130cr=legal supply_medic=locked_until_infantry_roles no_player_built_producers=true" % [
        str(dims),Camp.max_per_side(terrain)
    ])
