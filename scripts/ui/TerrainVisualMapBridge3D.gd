extends RefCounted
class_name TarvokaTerrainVisualMapBridge3D

# Read-only handoff contract for a future 3D battle renderer. Never writes
# to the authoritative map or exposes unseen terrain under fog of war.
const Rules = preload("res://scripts/core/Rules.gd")
const CHUNK_SIDE := 8
const MAX_CHUNK_SIDE := 16
const KINDS := ["plain","forest","mountain","road","water"]

static func _is_known(cell: Vector2i, explored: Dictionary,
        use_fog: bool) -> bool:
    return not use_fog or explored.has(cell)

static func _neighbor_is(terrain: Array, cell: Vector2i,
        kind: String, explored: Dictionary, use_fog: bool) -> bool:
    if not Rules.inside(cell,terrain):
        return false
    if not _is_known(cell,explored,use_fog):
        return false
    return str(terrain[cell.y][cell.x]) == kind

static func collect(terrain: Array, from: Vector2i,
        requested_size: Vector2i = Vector2i(CHUNK_SIDE,CHUNK_SIDE),
        explored: Dictionary = {}, visible: Dictionary = {},
        use_fog: bool = false) -> Dictionary:
    if not Rules.valid_terrain(terrain):
        return {}
    if requested_size.x <= 0 or requested_size.y <= 0:
        return {}
    if requested_size.x > MAX_CHUNK_SIDE or requested_size.y > MAX_CHUNK_SIDE:
        return {}
    var board_size: Vector2i = Rules.map_size(terrain)
    if from.x < 0 or from.y < 0 or from.x >= board_size.x or from.y >= board_size.y:
        return {}
    var reach: Vector2i = Vector2i(
        mini(requested_size.x,board_size.x-from.x),
        mini(requested_size.y,board_size.y-from.y))
    var tiles: Array[Dictionary] = []
    var hidden_count: int = 0
    var explored_count: int = 0
    for dy in range(reach.y):
        for dx in range(reach.x):
            var cell := from+Vector2i(dx,dy)
            var is_seen: bool = _is_known(cell,explored,use_fog)
            var is_visible: bool = not use_fog or visible.has(cell)
            var record: Dictionary = {
                "cell":cell, "kind":"unknown",
                "seen":is_seen,"visible":is_visible,
                "details":false,
                "roads":{"north":false,"south":false,"west":false,"east":false},
                "shore":{"north":false,"south":false,"west":false,"east":false}}
            if not is_seen:
                hidden_count += 1
                tiles.append(record)
                continue
            var kind: String = str(terrain[cell.y][cell.x])
            record["kind"] = kind
            record["details"] = is_visible
            explored_count += 1
            # Edges are derived only from *known* adjacent cells: water
            # and bridges must never reveal unexplored map information.
            if is_visible and kind == "road":
                record["roads"] = {
                    "north":_neighbor_is(terrain,cell+Vector2i(0,-1),"road",explored,use_fog),
                    "south":_neighbor_is(terrain,cell+Vector2i(0,1),"road",explored,use_fog),
                    "west":_neighbor_is(terrain,cell+Vector2i(-1,0),"road",explored,use_fog),
                    "east":_neighbor_is(terrain,cell+Vector2i(1,0),"road",explored,use_fog)}
            if is_visible and kind != "water":
                record["shore"] = {
                    "north":_neighbor_is(terrain,cell+Vector2i(0,-1),"water",explored,use_fog),
                    "south":_neighbor_is(terrain,cell+Vector2i(0,1),"water",explored,use_fog),
                    "west":_neighbor_is(terrain,cell+Vector2i(-1,0),"water",explored,use_fog),
                    "east":_neighbor_is(terrain,cell+Vector2i(1,0),"water",explored,use_fog)}
            tiles.append(record)
    return {
        "board_size":board_size,
        "origin":from,
        "size":reach,
        "cells":tiles,
        "tile_count":tiles.size(),
        "hidden":hidden_count,
        "known":explored_count,
        "visual_only":true}
