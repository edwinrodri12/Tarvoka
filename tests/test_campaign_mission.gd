extends SceneTree

const Campaign = preload("res://scripts/core/CampaignMission.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")

func _initialize() -> void:
    _check()
    quit()

func _check() -> void:
    var start: Dictionary = Campaign.start_c01()
    assert(start["id"] == "C01")
    assert(start["status"] == "active")
    assert(start["beacons"] == [[4,2],[5,5]])
    assert(start["battle"]["units"].size() == 5)
    assert(start["battle"]["winner"] == -1)
    assert(Campaign.valid_meta(start))
    assert(Campaign.available_unlocks(start).is_empty())
    assert(Codec.decode(Codec.encode(start["battle"])) == start["battle"])
    var encoded: String = Campaign.encode(start)
    var decoded: Dictionary = Campaign.decode(encoded)
    if decoded != start:
        print("CAMPAIGN_ROUNDTRIP_DEBUG text_len=",encoded.length()," result_keys=",decoded.keys())
        if not decoded.is_empty():
            print("CAMPAIGN_ROUNDTRIP_DEBUG meta=",decoded.get("status")," beacons=",decoded.get("beacons")," battle_equal=",decoded.get("battle") == start.get("battle"))
        else:
            print("CAMPAIGN_ROUNDTRIP_DEBUG raw_meta=",JSON.parse_string(encoded).get("campaign"))
    assert(decoded == start)

    # Normal offline skirmish has NO campaign metadata, remains intact.
    var skirmish: Dictionary = Session.start(
        [Roles.make_unit("SK1",0,Vector2i(1,1),"line"),
         Roles.make_unit("SK2",1,Vector2i(8,6),"line")],
        start["battle"]["terrain"]
    )
    assert(not skirmish.has("chapter"))
    assert(Campaign.decode(Codec.encode(skirmish)).is_empty())

    var intro: Dictionary = Campaign.acknowledge_event(start,"C01_START")
    assert(intro["valid"] and intro["dialogue"].size() == 2)
    assert(start["events_seen"].is_empty()) # pure
    var opened: Dictionary = intro["state"]
    assert(not Campaign.acknowledge_event(opened,"C01_START")["valid"])
    assert(not Campaign.acknowledge_event(opened,"C01_SUCCESS")["valid"])
    assert(not Campaign.acknowledge_event(opened,"C01_FIRST_ATTACK")["valid"])
    assert(not Campaign.acknowledge_event(opened,"C01_FIRST_CAPTURE")["valid"])
    assert(not Campaign.acknowledge_event(opened,"bogus")["valid"])

    # The objective is not elimination: only alive infantry at both markers
    # may initiate a hold, and Red gets a full response.
    var both: Dictionary = start["battle"].duplicate(true)
    both["units"][0]["pos"] = Vector2i(4,2)
    both["units"][1]["pos"] = Vector2i(5,5)
    var capture: Dictionary = Campaign.acknowledge_event(opened,"C01_FIRST_CAPTURE",{})
    assert(not capture["valid"]) # uses the current saved battle, not a fake report
    var blue: Dictionary = Campaign.after_phase(opened,both,0)
    assert(blue["hold_pending"] and blue["status"] == "holding")
    assert(blue["last_completed_side"] == 0 and blue["phase_count"] == 1)
    assert(opened["status"] == "active")
    assert(Campaign.after_phase(blue,both,0) == blue) # duplicate finish phase
    assert(Campaign.decode(Campaign.encode(blue)) == blue)
    capture = Campaign.acknowledge_event(blue,"C01_FIRST_CAPTURE")
    assert(capture["valid"] and capture["dialogue"].size() == 2)
    var attack: Dictionary = Campaign.acknowledge_event(capture["state"],"C01_FIRST_ATTACK",{"valid":true,"attacker_id":"C01_N1"})
    assert(attack["valid"])
    assert(not Campaign.acknowledge_event(attack["state"],"C01_FIRST_ATTACK",{"valid":true,"attacker_id":"C01_N1"})["valid"])

    # If one capture is broken before Red ends, the hold resets.
    var evicted: Dictionary = both.duplicate(true)
    evicted["units"][1]["pos"] = Vector2i(5,4)
    var broken: Dictionary = Campaign.after_phase(blue,evicted,1)
    assert(broken["status"] == "active" and not broken["hold_pending"])
    assert(broken["phase_count"] == 2)
    assert(Campaign.available_unlocks(broken).is_empty())

    # Two markers held across the reply earn the chapter once.
    var victory: Dictionary = Campaign.after_phase(blue,both,1)
    assert(victory["status"] == "completed" and not victory["hold_pending"])
    assert(Campaign.available_unlocks(victory) == ["G01"])
    assert(victory["campaign_flags"].has("c01_ejercicio_aprobado"))
    assert(Campaign.after_phase(victory,both,0) == victory)
    var ending: Dictionary = Campaign.acknowledge_event(victory,"C01_SUCCESS")
    assert(ending["valid"] and ending["dialogue"].size() == 2)
    assert(not Campaign.acknowledge_event(ending["state"],"C01_SUCCESS")["valid"])
    assert(Campaign.decode(Campaign.encode(ending["state"])) == ending["state"])

    # Turn 0 cannot be faked as the opponent response.
    assert(Campaign.after_phase(start,both,1) == start)
    assert(Campaign.after_phase(start,both,3) == start)

    # Non-infantry units cannot trigger a capture, including armor on both tiles.
    var armor: Dictionary = both.duplicate(true)
    armor["units"][0]["role"] = "bulwark"
    armor["units"][1]["role"] = "bulwark"
    assert(not Campaign.after_phase(start,armor,0)["hold_pending"])
    armor["units"][0]["hp"] = 0
    armor["units"][1]["hp"] = 0
    armor["units"][2]["hp"] = 0
    assert(Campaign.resolve_terminal(start,armor)["status"] == "failed")
    assert(start["status"] == "active")

    # Elimination without fulfilling the markers is a failed DRILL objective,
    # not a story win. Victory cannot be forged by changing battle.winner.
    var elimination: Dictionary = start["battle"].duplicate(true)
    elimination["winner"] = 0
    assert(Campaign.resolve_terminal(start,elimination)["status"] == "failed")
    both["winner"] = 0
    assert(Campaign.resolve_terminal(start,both)["status"] == "completed")
    var wiped: Dictionary = start["battle"].duplicate(true)
    wiped["winner"] = 1
    assert(Campaign.resolve_terminal(start,wiped)["status"] == "failed")

    # Modified chapter metadata and truncated or foreign saves fail safely.
    assert(Campaign.decode("").is_empty())
    assert(Campaign.decode("{").is_empty())
    var payload: Dictionary = JSON.parse_string(Campaign.encode(start))
    payload["campaign"]["id"] = "C99"
    assert(Campaign.decode(JSON.stringify(payload)).is_empty())
    payload = JSON.parse_string(Campaign.encode(start))
    payload["campaign"]["beacons"] = [[1,1],[5,5]]
    assert(Campaign.decode(JSON.stringify(payload)).is_empty())
    payload = JSON.parse_string(Campaign.encode(start))
    payload["campaign"]["status"] = "completed"
    assert(Campaign.decode(JSON.stringify(payload)).is_empty())
    payload = JSON.parse_string(Campaign.encode(start))
    payload["battle"]["terrain"][0][0] = "invalid_tile"
    assert(Campaign.decode(JSON.stringify(payload)).is_empty())

    print("Campaign C01 objective lifecycle, branching dialogue and checkpoint tests passed.")
