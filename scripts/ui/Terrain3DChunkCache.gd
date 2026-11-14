extends RefCounted
class_name TarvokaTerrain3DChunkCache

# A chunk only depends on its own known cells and a TWO-cell halo.
# Ground corner heights use immediate neighbors; shorelines and bridges
# can inspect a neighbor's neighbors. No hidden biome is ever hashed.
# This signature is solely for optional rendering, not game state.
const CHUNK_SIZE := 8
const VISUAL_HALO := 2

static func regions(grid: Array, chunk_size: int = CHUNK_SIZE) -> Array:
    var result: Array = []
    if grid.is_empty() or chunk_size < 1:
        return result
    var width: int = 0
    for line in grid:
        if line is Array:
            width = maxi(width,(line as Array).size())
    if width == 0:
        return result
    for y in range(0,grid.size(),chunk_size):
        for x in range(0,width,chunk_size):
            result.append(Rect2i(x,y,
                mini(chunk_size,width-x),mini(chunk_size,grid.size()-y)))
    return result

static func signature(grid: Array, region: Rect2i,
        observed: Dictionary = {}, restricted: bool = false) -> int:
    if not region.has_area():
        return 0
    var content: Array = [region.position,region.size,restricted]
    for y in range(maxi(0,region.position.y-VISUAL_HALO),
            mini(grid.size(),region.end.y+VISUAL_HALO)):
        if not (grid[y] is Array):
            continue
        for x in range(maxi(0,region.position.x-VISUAL_HALO),
                mini((grid[y] as Array).size(),
                region.end.x+VISUAL_HALO)):
            var cell := Vector2i(x,y)
            if restricted and not observed.has(cell):
                continue
            content.append([cell,str(grid[y][x])])
    return hash(content)

static func local_landscape_signature(grid: Array,
        observed: Dictionary, restricted: bool,
        biome: String, divisions: int) -> int:
    # A visual-only forest or bridge rebuild can be skipped when the
    # visible local neighborhood is identical. Including a two-cell halo
    # also covers corner-height queries and observed bridge links.
    var items: Array = [biome,divisions,restricted]
    for y in range(grid.size()):
        if not (grid[y] is Array):
            continue
        for x in range((grid[y] as Array).size()):
            var cell := Vector2i(x,y)
            if restricted and not observed.has(cell):
                continue
            if str(grid[y][x]) != biome:
                continue
            items.append(cell)
            for dy in range(-VISUAL_HALO,VISUAL_HALO+1):
                for dx in range(-VISUAL_HALO,VISUAL_HALO+1):
                    var near := cell+Vector2i(dx,dy)
                    if near.y < 0 or near.y >= grid.size():
                        continue
                    if not (grid[near.y] is Array):
                        continue
                    if near.x < 0 or near.x >= (
                            grid[near.y] as Array).size():
                        continue
                    if restricted and not observed.has(near):
                        continue
                    items.append([near,str(grid[near.y][near.x])])
    return hash(items)
