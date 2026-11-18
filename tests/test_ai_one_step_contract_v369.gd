extends SceneTree

# The FULL AI-like fourth move and its reduced one-cell movement are both
# executed through authoritative Session.move; the original 3-action opening
# still rejects any 4th request. No production scripts are changed.
const Session = preload("res://scripts/core/BattleSession.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Opening = preload("res://scripts/core/OpeningBalance.gd")
const Limited = preload("res://tests/LimitedFourthStepV369.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")

static func _trial(first: int, map_id: int, fog: bool) -> void:
    var army: Array = Roles.experimental_armies(true)
    var terrain: Array = Scenarios.terrain(map_id)
    var official: Dictionary = Session.start(army,terrain,first,fog,true,true,false,true)
    var legacy: Dictionary = Session.start(army,terrain,first,fog,true,true,false,false)
    assert(Opening.remaining(official) == 3)
    assert(not legacy.has("opening"))
    var ids: Array = ["A","B","C","E"] if first == 0 else ["X","Y","Z","V"]
    var side_x: int = 2 if first == 0 else 7
    for i in range(3):
        var goal := Vector2i(side_x,i+1)
        var o: Dictionary = Session.move(official,str(ids[i]),goal)
        var l: Dictionary = Session.move(legacy,str(ids[i]),goal)
        assert(o["valid"] and l["valid"])
        official = o["state"]
        legacy = l["state"]
        assert(official["units"] == legacy["units"])
    var full_destination := Vector2i(3,5) if first == 0 else Vector2i(6,5)
    var short_destination := Vector2i(2,5) if first == 0 else Vector2i(7,5)
    var full: Dictionary = Session.move(legacy,str(ids[3]),full_destination)
    assert(full["valid"])
    var proposed: Dictionary = {
        "valid":true,"action":"move","unit_id":str(ids[3]),
        "destination":full_destination,"reason":"relay","state":full["state"]
    }
    var source: Dictionary = legacy.duplicate(true)
    var shorter: Dictionary = Limited.reduce(legacy,proposed)
    assert(shorter["valid"] and shorter["reason"] == "shortened")
    assert(shorter["origin"] == (Vector2i(1,5) if first==0 else Vector2i(8,5)))
    assert(shorter["destination"] == short_destination)
    assert(shorter["reduced_manhattan"] == 1)
    assert(shorter["full_manhattan"] == 2)
    assert(legacy == source)
    var actual: Dictionary = Session.move(legacy,str(ids[3]),short_destination)
    assert(actual["valid"])
    assert(shorter["applied"]["state"] == actual["state"])
    assert(shorter["applied"]["destination"] == short_destination)
    assert(shorter["applied"]["experimental_original_destination"] == full_destination)
    assert(shorter["applied"]["state"]["units"] != full["state"]["units"])
    assert(Codec.decode(Codec.encode(shorter["applied"]["state"])) == shorter["applied"]["state"])
    var denied: Dictionary = Session.move(official,str(ids[3]),short_destination)
    assert(not denied["valid"] and denied["state"] == official)
    var end: Dictionary = Session.end_turn(shorter["applied"]["state"])
    assert(end["valid"] and end["state"]["faction"] == 1-first)
    assert(Codec.decode(Codec.encode(end["state"])) == end["state"])
    var not_shorter := {
        "valid":true,"action":"move","unit_id":str(ids[3]),
        "destination":short_destination,"state":actual["state"]
    }
    assert(not Limited.reduce(legacy,not_shorter)["valid"])
    print("STEP369_CONTRACT map=%d fog=%s first=%d legal_one_step=true original_cap_unchanged=true" % [
        map_id,str(fog),first])

func _initialize() -> void:
    for map_id in [0,2]:
        for fog in [false,true]:
            for first in [0,1]:
                _trial(first,map_id,fog)
    print("PASS AI one-step v369 contract: 8 real terrain/fog/starter cases, authoritative one-cell legality and save parity")
    quit(0)
