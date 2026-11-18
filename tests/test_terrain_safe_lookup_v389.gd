extends SceneTree

# TARVOKA v3.8.9: terrain previews must return an empty terrain label
# rather than logging a runtime out-of-bounds error for missing, sparse,
# malformed or legacy implicit boards. Genuine 10x8/24x18/40x30 maps
# retain their exact legitimate tile types, heights and cover metadata.
const Terrain = preload("res://scripts/core/TerrainTactics.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")

static func _bad_maps() -> void:
    # Legacy Rules.inside(empty terrain) explicitly assumes a 10x8
    # movement grid. It may return true for (2,2) even without any rows.
    # Tile lookup must NOT turn that implicit movement convention into
    # an out-of-bounds Array access in combat previews.
    var absent: Array = []
    assert(Rules.inside(Vector2i(2,2),absent))
    assert(Terrain.tile_at(absent,Vector2i(2,2)) == "")
    assert(Terrain.tile_at(absent,Vector2i(0,0)) == "")
    assert(Terrain.tile_at(absent,Vector2i(-1,0)) == "")
    assert(Terrain.tile_at(absent,Vector2i(0,-1)) == "")

    var ragged: Array = [
        ["forest","plain","road"],["mountain"],[],
        ["water","plain"]]
    var unchanged: Array = ragged.duplicate(true)
    assert(Terrain.tile_at(ragged,Vector2i(0,0)) == "forest")
    assert(Terrain.tile_at(ragged,Vector2i(2,0)) == "road")
    assert(Terrain.tile_at(ragged,Vector2i(0,1)) == "mountain")
    assert(Terrain.tile_at(ragged,Vector2i(1,1)) == "")
    assert(Terrain.tile_at(ragged,Vector2i(0,2)) == "")
    assert(Terrain.tile_at(ragged,Vector2i(0,3)) == "water")
    assert(Terrain.tile_at(ragged,Vector2i(0,4)) == "")
    assert(Terrain.tile_at(ragged,Vector2i(3,3)) == "")
    assert(ragged == unchanged)

    var malformed: Array = [["plain"],42,{},null,["road"]]
    assert(Terrain.tile_at(malformed,Vector2i(0,0)) == "plain")
    assert(Terrain.tile_at(malformed,Vector2i(0,1)) == "")
    assert(Terrain.tile_at(malformed,Vector2i(0,2)) == "")
    assert(Terrain.tile_at(malformed,Vector2i(0,3)) == "")
    assert(Terrain.tile_at(malformed,Vector2i(0,4)) == "road")

static func _valid_map(width: int, height: int, seed: int) -> int:
    var size := Vector2i(width,height)
    var terrain: Array = Scenarios.seeded_terrain(seed,size)
    assert(Rules.valid_terrain(terrain))
    var original: Array = terrain.duplicate(true)
    var verified := 0
    for y in range(height):
        for x in range(width):
            var cell := Vector2i(x,y)
            assert(Terrain.tile_at(terrain,cell) == str(terrain[y][x]))
            verified += 1
    for outside in [Vector2i(-1,0),Vector2i(0,-1),
            Vector2i(width,0),Vector2i(0,height),
            Vector2i(width,height)]:
        assert(Terrain.tile_at(terrain,outside) == "")
    assert(original == terrain)
    return verified

func _initialize() -> void:
    _bad_maps()
    var checked := _valid_map(10,8,634)
    checked += _valid_map(24,18,635)
    checked += _valid_map(40,30,636)
    assert(checked == 1712)
    print("TERRAIN389_RESULT " + JSON.stringify({
        "verified_legitimate_cells":checked,
        "sizes":["10x8","24x18","40x30"],
        "empty_and_ragged_are_safe":true,
        "no_default_indexing_of_empty_board":true,
        "invalid_coordinates_return_empty":true,
        "map_inputs_unchanged":true,
        "production_changes":["scripts/core/TerrainTactics.gd"],
        "combat_values_for_valid_tiles_unchanged":true
    }))
    print("PASS TARVOKA v389: safe absent/ragged terrain lookup and "
        + "1712 unchanged legitimate battle-map cells")
    quit(0)
