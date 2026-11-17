extends SceneTree
# Regression guard: the offline Android game must not instantiate network clients.
# Static scope is intentionally limited to runtime scripts and scenes.
const ROOTS: Array[String] = ["res://scripts", "res://scenes"]
const FORBIDDEN: Array[String] = [
    "HTTPRequest.new(", "HTTPClient.new(", "WebSocketPeer.new(",
    "WebSocketMultiplayerPeer.new(", "ENetMultiplayerPeer.new(",
    "TCPServer.new(", "StreamPeerTCP.new("
]

func _initialize() -> void:
    var failures: Array[String] = []
    var checked: int = 0
    for root in ROOTS:
        if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root)):
            failures.append("Missing runtime directory: " + root)
            continue
        checked += _scan(root, failures)
    if checked == 0:
        failures.append("No runtime files scanned")
    if failures.is_empty():
        print("PASS: offline runtime network-constructor guard (%d files)" % checked)
        quit(0)
    else:
        for failure in failures:
            push_error(failure)
        quit(1)

func _scan(folder: String, failures: Array[String]) -> int:
    var directory := DirAccess.open(folder)
    if directory == null:
        failures.append("Cannot open: " + folder)
        return 0
    var count := 0
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        if not entry.begins_with("."):
            var path := folder.path_join(entry)
            if directory.current_is_dir():
                count += _scan(path, failures)
            elif entry.ends_with(".gd") or entry.ends_with(".tscn"):
                count += 1
                var file := FileAccess.open(path, FileAccess.READ)
                if file == null:
                    failures.append("Cannot read: " + path)
                else:
                    var source := file.get_as_text()
                    for token in FORBIDDEN:
                        if source.contains(token):
                            failures.append("Network constructor '%s' in %s" % [token, path])
        entry = directory.get_next()
    directory.list_dir_end()
    return count
