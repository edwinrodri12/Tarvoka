extends SceneTree

# End-to-end regression for the real BattleSession attack API, independent
# of experimental mountain/flanking PRs. Run with Godot 4.3 --headless.
const Session = preload("res://scripts/core/BattleSession.gd")
const Actions = preload("res://scripts/core/BattleActions.gd")
const Codec = preload("res://scripts/core/SaveCodec.gd")
const Store = preload("res://scripts/core/SaveStore.gd")

func _terrain() -> Array:
    var board: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(10):
            row.append("plain")
        board.append(row)
    return board

func _unit(uid: String, side: int, pos: Vector2i, hp: int, power: int) -> Dictionary:
    return {"id":uid, "faction":side, "pos":pos, "hp":hp,
        "attack":power, "defense":0, "cover":0, "move_points":3,
        "acted":false}

func _initialize() -> void:
    var board: Array = _terrain()
    var initial: Array = [
        _unit("attacker",0,Vector2i(2,2),10,4),
        _unit("defender",1,Vector2i(3,2),10,3)
    ]
    var state: Dictionary = Session.start(initial,board)
    var snapshot: Dictionary = state.duplicate(true)
    var expected: Dictionary = Actions.preview_exchange(
        state["units"][0],state["units"][1],true,board,{},state["units"])
    assert(expected.get("valid",false))
    assert(int(expected["defender_hp"]) > 0)
    var outcome: Dictionary = Session.attack(state,"attacker","defender")
    assert(outcome.get("valid",false))
    assert(int(outcome["damage"]) == int(expected["damage"]))
    assert(int(outcome["counter_damage"]) == int(expected["counter_damage"]))
    assert(bool(outcome["counter_spent"]) == bool(expected["counter_spent"]))
    assert(int(outcome["state"]["units"][0]["hp"]) == int(expected["attacker_hp"]))
    assert(int(outcome["state"]["units"][1]["hp"]) == int(expected["defender_hp"]))
    assert(bool(outcome["state"]["units"][0]["acted"]))
    assert(state == snapshot) # Neither HP nor action flags mutate caller state.
    assert(not Session.attack(outcome["state"],"attacker","defender")["valid"])
    assert(int(outcome["state"]["winner"]) == -1)
    # Save roundtrip must preserve combat HP and consumed action.
    var raw: String = Codec.encode(outcome["state"])
    assert(not raw.is_empty())
    var restored: Dictionary = Codec.decode(raw)
    assert(not restored.is_empty())
    assert(restored == outcome["state"])
    assert(not Session.attack(restored,"attacker","defender")["valid"])
    var turn: Dictionary = Session.end_turn(restored)
    assert(turn.get("valid",false))
    assert(int(turn["state"]["faction"]) == 1)
    assert(int(turn["state"]["units"][0]["hp"]) == int(expected["attacker_hp"]))
    assert(int(turn["state"]["units"][1]["hp"]) == int(expected["defender_hp"]))

    # A decisive hit must suppress retaliation and freeze the terminal session.
    var lethal: Array = [
        _unit("winner",0,Vector2i(4,4),10,10),
        _unit("loser",1,Vector2i(5,4),2,10)
    ]
    var final_state: Dictionary = Session.start(lethal,board)
    var decisive: Dictionary = Session.attack(final_state,"winner","loser")
    assert(decisive.get("valid",false))
    assert(int(decisive["counter_damage"]) == 0)
    assert(int(decisive["state"]["units"][0]["hp"]) == 10)
    assert(int(decisive["state"]["units"][1]["hp"]) == 0)
    assert(int(decisive["state"]["winner"]) == 0)
    assert(not Session.end_turn(decisive["state"])["valid"])
    assert(not Session.attack(decisive["state"],"winner","loser")["valid"])
    assert(final_state["units"][1]["hp"] == 2)
    # Terminal saves must remain terminal after decode.
    var terminal_raw: String = Codec.encode(decisive["state"])
    assert(not terminal_raw.is_empty())
    var terminal: Dictionary = Codec.decode(terminal_raw)
    assert(not terminal.is_empty())
    assert(int(terminal["winner"]) == 0)
    assert(int(terminal["units"][1]["hp"]) == 0)
    assert(not Session.end_turn(terminal)["valid"])
    assert(not Session.attack(terminal,"winner","loser")["valid"])
    # Exercise actual user:// disk writes and backup recovery, not just JSON.
    # Use a dedicated filename so no player's real save is ever touched.
    var disk_path := "user://tarvoka_session_exchange_contract_test.json"
    for suffix in ["", ".bak", ".tmp"]:
        var candidate: String = disk_path + suffix
        if FileAccess.file_exists(candidate):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK)
    assert(Store.save(outcome["state"], disk_path))
    var first_report: Dictionary = Store.load_report(disk_path)
    assert(not first_report["recovered"])
    assert(first_report["state"] == outcome["state"])
    assert(Store.save(decisive["state"], disk_path))
    assert(FileAccess.file_exists(disk_path + ".bak"))
    assert(Store.load(disk_path) == decisive["state"])
    # A structurally invalid but parseable primary must fall back to the verified backup.
    # Avoid deliberately malformed JSON: Godot logs ERROR on parse failure,
    # which correctly trips the strict CI log gate even when recovery succeeds.
    var corrupted := FileAccess.open(disk_path, FileAccess.WRITE)
    assert(corrupted != null)
    corrupted.store_string('{"version":999,"units":[],"terrain":[]}')
    corrupted.close()
    var recovered: Dictionary = Store.load_report(disk_path)
    assert(recovered["recovered"])
    assert(recovered["state"] == outcome["state"])
    assert(not Session.attack(recovered["state"], "attacker", "defender")["valid"])
    # Both copies invalid: never manufacture a battle state or silently resume.
    # This protects the caller from loading an unrelated/partial match.
    var invalid_backup := FileAccess.open(disk_path + ".bak", FileAccess.WRITE)
    assert(invalid_backup != null)
    invalid_backup.store_string('{"version":999,"units":[],"terrain":[]}')
    invalid_backup.close()
    var unrecoverable: Dictionary = Store.load_report(disk_path)
    assert(unrecoverable.get("state", {}).is_empty())
    assert(Store.load(disk_path).is_empty())
    # The previously recovered snapshot remains a valid in-memory session.
    assert(recovered["state"] == outcome["state"])
    assert(not Session.attack(recovered["state"], "attacker", "defender")["valid"])
    for suffix in ["", ".bak", ".tmp"]:
        var candidate: String = disk_path + suffix
        if FileAccess.file_exists(candidate):
            assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK)
    # Recover from a missing primary, not only an invalid primary.
    assert(Store.save(outcome["state"], disk_path))
    assert(Store.save(decisive["state"], disk_path))
    assert(FileAccess.file_exists(disk_path + ".bak"))
    assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(disk_path)) == OK)
    var missing_primary: Dictionary = Store.load_report(disk_path)
    assert(missing_primary.get("recovered", false))
    assert(missing_primary.get("state", {}) == outcome["state"])
    assert(not Session.attack(missing_primary["state"], "attacker", "defender")["valid"])
    assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(disk_path + ".bak")) == OK)
    assert(not FileAccess.file_exists(disk_path))
    assert(not FileAccess.file_exists(disk_path + ".bak"))
    print("PASS battle session exchange: preview parity, HP, reaction, save roundtrip, disk backup recovery, victory")
    quit(0)
