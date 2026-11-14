extends SceneTree

# Read-only visual adapter regression: large boards, chunk coverage, fog,
# and topology must agree with the tactical array without changing it.
const Adapter = preload("res://scripts/ui/TerrainVisualMapBridge3D.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

func _initialize() -> void:
    call_deferred("_run")

func _tile(data: Dictionary, pos: Vector2i) -> Dictionary:
    for tile in data.get("cells",[]):
        if tile["cell"] == pos:
            return tile
    return {}

func _run() -> void:
    var checked_tiles: int = 0
    for size in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var battlefield: Array = Scenarios.seeded_terrain(127,size)
        assert(Rules.valid_terrain(battlefield))
        var copy: Array = battlefield.duplicate(true)
        var covered: Dictionary = {}
        for y in range(0,size.y,Adapter.CHUNK_SIDE):
            for x in range(0,size.x,Adapter.CHUNK_SIDE):
                var data: Dictionary = Adapter.collect(battlefield,Vector2i(x,y))
                assert(data.get("visual_only",false))
                assert(data["board_size"] == size)
                assert(int(data["tile_count"]) <= 64)
                assert(int(data["tile_count"]) == (
                    data["size"].x*data["size"].y))
                assert(data["hidden"] == 0)
                for tile in data["cells"]:
                    var pos: Vector2i = tile["cell"]
                    assert(not covered.has(pos))
                    covered[pos] = true
                    assert(tile["kind"] == battlefield[pos.y][pos.x])
                    assert(tile["details"])
                    checked_tiles += 1
        assert(covered.size() == size.x*size.y)
        assert(battlefield == copy)
        assert(Adapter.collect(battlefield,Vector2i(-1,0)).is_empty())
        assert(Adapter.collect(battlefield,Vector2i(0,0),Vector2i(17,1)).is_empty())
    var river: Array = Scenarios.terrain(2)
    var road := Vector2i(3,2)
    var bridge := Vector2i(4,2)
    var near_shore := Vector2i(3,1)
    var water := Vector2i(4,1)
    assert(river[road.y][road.x] == "road")
    assert(river[bridge.y][bridge.x] == "road")
    assert(river[water.y][water.x] == "water")
    var initially_seen := {road:true,near_shore:true}
    var initially_visible := {road:true,near_shore:true}
    var masked: Dictionary = Adapter.collect(river,Vector2i.ZERO,
        Vector2i(8,8),initially_seen,initially_visible,true)
    assert(masked["known"] == 2 and masked["hidden"] == 62)
    assert(_tile(masked,bridge)["kind"] == "unknown")
    assert(not _tile(masked,bridge)["details"])
    assert(not _tile(masked,road)["roads"]["east"])
    assert(not _tile(masked,near_shore)["shore"]["east"])
    var seen_more := {road:true,bridge:true,near_shore:true,water:true}
    var shown_more := {road:true,near_shore:true}
    var known: Dictionary = Adapter.collect(river,Vector2i.ZERO,
        Vector2i(8,8),seen_more,shown_more,true)
    assert(_tile(known,road)["roads"]["east"])
    assert(_tile(known,near_shore)["shore"]["east"])
    assert(_tile(known,bridge)["kind"] == "road")
    assert(not _tile(known,bridge)["details"])
    assert(not _tile(known,bridge)["roads"]["west"]) # Explored but currently obscured.
    assert(river == Scenarios.terrain(2))
    print("PASS TERRAIN_MAP_ADAPTER_V4: %d tactical tiles, 3 sizes, fog-safe neighbor topology and zero mutation" % checked_tiles)
    quit(0)
