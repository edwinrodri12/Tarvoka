extends SceneTree
# Regression guard: the offline Android game must not instantiate network clients.
# Static scope is intentionally limited to runtime scripts and scenes.
const ROOTS: Array[String] = ["res://scripts", "res://scenes"]
const NETWORK_TYPES: Array[String] = [
    "HTTPRequest", "HTTPClient", "WebSocketPeer",
    "WebSocketMultiplayerPeer", "ENetMultiplayerPeer",
    "TCPServer", "StreamPeerTCP", "PacketPeerUDP"
]

func _initialize() -> void:
    var failures: Array[String] = []
    _self_test(failures)
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
                    for hit in _find_network_usage(source, entry.ends_with(".tscn")):
                        failures.append("Network usage '%s' in %s" % [hit, path])
        entry = directory.get_next()
    directory.list_dir_end()
    return count

# Detect whitespace variants and direct scene nodes as well as literal constructors.
func _find_network_usage(source: String, is_scene: bool) -> Array[String]:
    var hits: Array[String] = []
    for kind in NETWORK_TYPES:
        var constructor := RegEx.new()
        var expression := "\\b" + kind + "\\s*\\.\\s*new\\s*\\("
        if constructor.compile(expression) != OK:
            hits.append("Invalid detector expression: " + kind)
            continue
        if constructor.search(source) != null:
            hits.append(kind + ".new")
        if is_scene:
            var node_detector := RegEx.new()
            var node_expression := "\\[node\\b[^\\]\\n]*\\btype\\s*=\\s*\\\"" + kind + "\\\""
            if node_detector.compile(node_expression) != OK:
                hits.append("Invalid scene detector: " + kind)
            elif node_detector.search(source) != null:
                hits.append(kind + " scene node")
    return hits

func _self_test(failures: Array[String]) -> void:
    if not _find_network_usage("var x = HTTPClient  .  new ( )", false).has("HTTPClient.new"):
        failures.append("Detector misses whitespace-separated HTTPClient constructor")
    if not _find_network_usage("[node name=\"Request\" type=\"HTTPRequest\"]", true).has("HTTPRequest scene node"):
        failures.append("Detector misses HTTPRequest scene node")
    if not _find_network_usage("var x = Vector2.new(1, 2)", false).is_empty():
        failures.append("Detector incorrectly rejects unrelated constructors")
