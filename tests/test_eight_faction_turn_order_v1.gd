extends SceneTree

const Future=preload("res://scripts/core/FactionTurnOrderV1.gd")
const LegacyTurns=preload("res://scripts/core/Turns.gd")

func _initialize() -> void:
    call_deferred("_run")

static func _make_armies(roster: Array) -> Array:
    var units: Array=[]
    for faction in roster:
        units.append({"id":"F%d" % int(faction),
            "faction":int(faction),"hp":10})
    return units

func _run() -> void:
    assert(not Future.valid([]))
    assert(not Future.valid([0]))
    assert(Future.valid([0,1]))
    assert(Future.valid([0,1,2,3,4,5,6,7]))
    assert(not Future.valid([0,0]))
    assert(not Future.valid([0,8]))
    assert(not Future.valid([0,1,2,3,4,5,6,7,8]))
    assert(not Future.valid([0,"1"]))
    var two: Array=_make_armies([0,1])
    assert(Future.next_faction([0,1],0,two)==1)
    assert(Future.next_faction([0,1],1,two)==0)
    assert(Future.winner([0,1],two)==LegacyTurns.winner(two))
    two[1]["hp"]=0
    assert(Future.winner([0,1],two)==0)
    assert(Future.next_faction([0,1],0,two)==-1)
    assert(Future.next_faction([0,1],1,two)==-1)
    assert(Future.winner([0,1],two)==LegacyTurns.winner(two))
    var roster: Array=[0,1,2,3,4,5,6,7]
    var eight: Array=_make_armies(roster)
    var current: int=0
    var observed: Array[int]=[current]
    for round_index in range(7):
        current=Future.next_faction(roster,current,eight)
        observed.append(current)
    assert(observed==[0,1,2,3,4,5,6,7])
    assert(Future.next_faction(roster,7,eight)==0)
    assert(Future.winner(roster,eight)==-1)
    # Remove three teams. Scheduling must skip them without changing IDs.
    eight[2]["hp"]=0
    eight[4]["hp"]=0
    eight[7]["hp"]=0
    assert(Future.alive_factions(roster,eight)==[0,1,3,5,6])
    assert(Future.next_faction(roster,1,eight)==3)
    assert(Future.next_faction(roster,3,eight)==5)
    assert(Future.next_faction(roster,6,eight)==0)
    assert(Future.next_faction(roster,7,eight)==0)
    for faction in [0,1,3,5]:
        eight[faction]["hp"]=0
    assert(Future.winner(roster,eight)==6)
    assert(Future.next_faction(roster,6,eight)==-1)
    assert(Future.next_faction(roster,99,eight)==-1)
    eight[6]["hp"]=0
    assert(Future.winner(roster,eight)==-1)
    assert(Future.alive_factions(roster,eight).is_empty())
    print("PASS TARVOKA FUTURE EIGHT-TURN ROTATION: 2-player compatibility, 8-player order, elimination, victory and no-rule-mutation")
    quit(0)
