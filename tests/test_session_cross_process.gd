extends SceneTree
# Two independent Godot invocations verify that SaveStore persists across processes.
# Run with -- --phase=write then -- --phase=read, using the same user:// directory.
const Session = preload("res://scripts/core/BattleSession.gd")
const Store = preload("res://scripts/core/SaveStore.gd")
const PATH := "user://tarvoka_cross_process_contract.json"

func _initialize() -> void:
    var phase := ""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--phase="):
            phase = arg.trim_prefix("--phase=")
    if phase == "write":
        for suffix in ["", ".bak", ".tmp"]:
            var path: String = PATH + suffix
            if FileAccess.file_exists(path):
                assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
        var board: Array = []
        for y in range(8):
            var row: Array = []
            for x in range(10):
                row.append("plain")
            board.append(row)
        var units: Array = [
            {"id":"a","faction":0,"pos":Vector2i(2,2),"hp":10,"attack":4,"defense":0,"cover":0,"move_points":3,"acted":false},
            {"id":"b","faction":1,"pos":Vector2i(3,2),"hp":10,"attack":3,"defense":0,"cover":0,"move_points":3,"acted":false}
        ]
        var initial: Dictionary = Session.start(units,board)
        var attacked: Dictionary = Session.attack(initial,"a","b")
        assert(attacked.get("valid",false))
        assert(Store.save(attacked["state"],PATH))
        print("PASS cross-process write")
        quit(0)
    elif phase == "backup_write":
        # Two successive saves must create a previous-state backup on disk.
        var board: Array = []
        for y in range(8):
            var row: Array = []
            for x in range(10):
                row.append("plain")
            board.append(row)
        var units: Array = [
            {"id":"a","faction":0,"pos":Vector2i(2,2),"hp":10,"attack":4,"defense":0,"cover":0,"move_points":3,"acted":false},
            {"id":"b","faction":1,"pos":Vector2i(3,2),"hp":10,"attack":3,"defense":0,"cover":0,"move_points":3,"acted":false}
        ]
        var original: Dictionary = Session.start(units,board)
        var attacked: Dictionary = Session.attack(original,"a","b")
        assert(attacked.get("valid",false))
        assert(Store.save(attacked["state"],PATH))
        var advanced: Dictionary = Session.end_turn(attacked["state"])
        assert(advanced.get("valid",false))
        assert(Store.save(advanced["state"],PATH))
        assert(FileAccess.file_exists(PATH + ".bak"))
        # Simulate an interrupted/corrupted primary before a fresh process loads.
        var file := FileAccess.open(PATH,FileAccess.WRITE)
        assert(file != null)
        file.store_string('{"version":999}')
        file.close()
        print("PASS cross-process backup_write")
        quit(0)
    elif phase == "missing_primary_write":
        # A fresh process must recover a valid backup when the primary vanishes.
        var board: Array = []
        for y in range(8):
            var row: Array = []
            for x in range(10):
                row.append("plain")
            board.append(row)
        var units: Array = [
            {"id":"a","faction":0,"pos":Vector2i(2,2),"hp":10,"attack":4,"defense":0,"cover":0,"move_points":3,"acted":false},
            {"id":"b","faction":1,"pos":Vector2i(3,2),"hp":10,"attack":3,"defense":0,"cover":0,"move_points":3,"acted":false}
        ]
        var original: Dictionary = Session.start(units,board)
        var attacked: Dictionary = Session.attack(original,"a","b")
        assert(attacked.get("valid",false))
        assert(Store.save(attacked["state"],PATH))
        var advanced: Dictionary = Session.end_turn(attacked["state"])
        assert(advanced.get("valid",false))
        assert(Store.save(advanced["state"],PATH))
        assert(FileAccess.file_exists(PATH + ".bak"))
        assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH)) == OK)
        assert(not FileAccess.file_exists(PATH))
        print("PASS cross-process missing_primary_write")
        quit(0)
    elif phase == "missing_primary_read":
        assert(not FileAccess.file_exists(PATH))
        var report: Dictionary = Store.load_report(PATH)
        assert(bool(report.get("recovered",false)))
        var state: Dictionary = report.get("state",{})
        assert(not state.is_empty())
        assert(int(state["faction"]) == 0)
        assert(bool(state["units"][0]["acted"]))
        assert(int(state["units"][1]["hp"]) < 10)
        assert(not Session.attack(state,"a","b").get("valid",false))
        var next: Dictionary = Session.end_turn(state)
        assert(next.get("valid",false))
        assert(int(next["state"]["faction"]) == 1)
        for suffix in ["", ".bak", ".tmp"]:
            var path: String = PATH + suffix
            if FileAccess.file_exists(path):
                assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
        print("PASS cross-process missing_primary_read")
        quit(0)
    elif phase == "resume_write":
        # A recovered backup must be usable as a new durable primary save.
        assert(not FileAccess.file_exists(PATH))
        var report: Dictionary = Store.load_report(PATH)
        assert(bool(report.get("recovered",false)))
        var recovered: Dictionary = report.get("state",{})
        assert(not recovered.is_empty())
        var next: Dictionary = Session.end_turn(recovered)
        assert(next.get("valid",false))
        assert(int(next["state"]["faction"]) == 1)
        assert(Store.save(next["state"],PATH))
        print("PASS cross-process resume_write")
        quit(0)
    elif phase == "resume_read":
        var report: Dictionary = Store.load_report(PATH)
        assert(not bool(report.get("recovered",true)))
        var state: Dictionary = report.get("state",{})
        assert(not state.is_empty())
        assert(int(state["faction"]) == 1)
        assert(bool(state["units"][0]["acted"]))
        assert(int(state["units"][1]["hp"]) < 10)
        for suffix in ["", ".bak", ".tmp"]:
            var path: String = PATH + suffix
            if FileAccess.file_exists(path):
                assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
        print("PASS cross-process resume_read")
        quit(0)
    elif phase == "backup_read":
        var report: Dictionary = Store.load_report(PATH)
        assert(bool(report.get("recovered",false)))
        var state: Dictionary = report.get("state",{})
        assert(not state.is_empty())
        assert(int(state["faction"]) == 0)
        assert(bool(state["units"][0]["acted"]))
        assert(int(state["units"][1]["hp"]) < 10)
        assert(not Session.attack(state,"a","b").get("valid",false))
        for suffix in ["", ".bak", ".tmp"]:
            var path: String = PATH + suffix
            if FileAccess.file_exists(path):
                assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
        print("PASS cross-process backup_read")
        quit(0)
    elif phase == "read":
        assert(FileAccess.file_exists(PATH))
        var report: Dictionary = Store.load_report(PATH)
        assert(not report.get("recovered",true))
        var state: Dictionary = report.get("state",{})
        assert(not state.is_empty())
        assert(int(state["faction"]) == 0)
        assert(bool(state["units"][0]["acted"]))
        assert(int(state["units"][1]["hp"]) < 10)
        assert(not Session.attack(state,"a","b").get("valid",false))
        var next: Dictionary = Session.end_turn(state)
        assert(next.get("valid",false))
        assert(int(next["state"]["faction"]) == 1)
        for suffix in ["", ".bak", ".tmp"]:
            var path: String = PATH + suffix
            if FileAccess.file_exists(path):
                assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
        print("PASS cross-process read")
        quit(0)
    else:
        push_error("Specify --phase=write/read/backup_write/backup_read")
        quit(1)
