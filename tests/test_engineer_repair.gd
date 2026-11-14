extends SceneTree

const Repair = preload("res://scripts/core/EngineerRepair.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Economy = preload("res://scripts/core/UrbanEconomy.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")

func _initialize() -> void:
    var engineer: Dictionary = Roles.make_unit("ENG",0,Vector2i(2,2),"engineer")
    var tank: Dictionary = Roles.make_unit("TANK",0,Vector2i(3,2),"tank")
    var rival: Dictionary = Roles.make_unit("ENEMY",1,Vector2i(8,6),"line")
    var original: Dictionary = Session.start([engineer,tank,rival],
        Scenarios.terrain(0),0,false,false,true,true)
    assert(original.has("economy") and bool(original["economy"]["modern"]))
    original["units"][1]["hp"] = 7
    var pristine: Dictionary = original.duplicate(true)
    var offer: Dictionary = Repair.quote(original,"ENG","TANK")
    assert(offer["valid"] and offer["restored"] == 3 and offer["cost"] == 105)
    assert(offer["before_hp"] == 7 and offer["after_hp"] == 10 and offer["maximum_hp"] == 14)
    var available: Array = Repair.options(original,"ENG")
    assert(available.size() == 1 and available[0]["target_id"] == "TANK")
    assert(original == pristine)
    var committed: Dictionary = Session.repair(original,"ENG","TANK")
    assert(committed["valid"] and committed["restored"] == 3 and committed["cost"] == 105)
    assert(int(committed["state"]["units"][1]["hp"]) == 10)
    assert(int(committed["state"]["economy"]["credits"][0]) == Economy.MODERN_START_CREDITS-105)
    assert(int(committed["state"]["economy"]["credits"][1]) == Economy.MODERN_START_CREDITS)
    assert(bool(committed["state"]["units"][0]["acted"]) and bool(committed["state"]["units"][0]["moved"]))
    assert(original == pristine and Economy.valid(committed["state"]["economy"],committed["state"]["terrain"]))
    assert(Codec.decode(Codec.encode(committed["state"])) == committed["state"])
    assert(not Session.repair(committed["state"],"ENG","TANK")["valid"])
    assert(not Session.move(committed["state"],"ENG",Vector2i(2,3))["valid"])

    var low: Dictionary = original.duplicate(true)
    low["economy"]["credits"][0] = 70
    offer = Repair.quote(low,"ENG","TANK")
    assert(offer["valid"] and offer["restored"] == 2 and offer["cost"] == 70)
    committed = Session.repair(low,"ENG","TANK")
    assert(committed["valid"] and committed["state"]["economy"]["credits"][0] == 0)
    assert(committed["state"]["units"][1]["hp"] == 9)
    low["economy"]["credits"][0] = 34
    assert(not Repair.quote(low,"ENG","TANK")["valid"])
    assert(not Session.repair(low,"ENG","TANK")["valid"])

    var nearly_full: Dictionary = original.duplicate(true)
    nearly_full["units"][1]["hp"] = 13
    offer = Repair.quote(nearly_full,"ENG","TANK")
    assert(offer["valid"] and offer["restored"] == 1 and offer["cost"] == 35)
    nearly_full["units"][1]["hp"] = 14
    assert(not Repair.quote(nearly_full,"ENG","TANK")["valid"])
    nearly_full["units"][1]["hp"] = 0
    assert(not Repair.quote(nearly_full,"ENG","TANK")["valid"]) # No revives.

    var wrong: Dictionary = original.duplicate(true)
    assert(not Repair.quote(wrong,"ENG","ENEMY")["valid"])
    assert(not Repair.quote(wrong,"ENG","ENG")["valid"])
    assert(not Repair.quote(wrong,"TANK","ENG")["valid"])
    wrong["units"][1]["pos"] = Vector2i(6,2)
    assert(not Repair.quote(wrong,"ENG","TANK")["valid"]) # No remote healing.
    wrong = original.duplicate(true)
    wrong["units"][1] = Roles.make_unit("TANK",0,Vector2i(3,2),"line")
    wrong["units"][1]["hp"] = 5
    assert(not Repair.quote(wrong,"ENG","TANK")["valid"]) # Infantry cannot heal.
    wrong["units"][1] = Roles.make_unit("TANK",0,Vector2i(3,2),"attack_heli")
    wrong["units"][1]["hp"] = 5
    assert(not Repair.quote(wrong,"ENG","TANK")["valid"]) # Aircraft: no.
    wrong = original.duplicate(true)
    wrong["units"][0]["acted"] = true
    assert(not Repair.quote(wrong,"ENG","TANK")["valid"])
    wrong = original.duplicate(true)
    wrong["faction"] = 1
    assert(not Repair.quote(wrong,"ENG","TANK")["valid"])
    wrong = original.duplicate(true)
    wrong["winner"] = 1
    assert(not Repair.quote(wrong,"ENG","TANK")["valid"])
    wrong = original.duplicate(true)
    wrong["units"][1]["id"] = "ENG" # Never accept duplicate ID target ambiguity.
    assert(not Repair.quote(wrong,"ENG","ENG")["valid"])

    var classic: Dictionary = Session.start([engineer,tank,rival],
        Scenarios.terrain(0),0,false,false,true,false)
    classic["units"][1]["hp"] = 7
    assert(not Repair.quote(classic,"ENG","TANK")["valid"])

    var opening: Dictionary = Session.start([engineer,tank,rival],
        Scenarios.terrain(0),0,false,false,true,true,true)
    opening["units"][1]["hp"] = 7
    assert(Opening.remaining(opening) == 2)
    committed = Session.repair(opening,"ENG","TANK")
    assert(committed["valid"] and Opening.remaining(committed["state"]) == 1)
    assert(Opening.remaining(opening) == 2)
    var blocked: Dictionary = original.duplicate(true)
    blocked["opening"] = {"starter":0,"used":2,"limit":2}
    assert(not Session.repair(blocked,"ENG","TANK")["valid"])

    print("PASS engineer repair: paid 3HP cap, partial budgets, no free heal, one action, live save, rules and opening")
    quit(0)
