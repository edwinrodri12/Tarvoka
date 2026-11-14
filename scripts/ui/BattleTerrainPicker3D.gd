extends RefCounted
class_name TarvokaBattleTerrainPicker3D

# Geometry-accurate mouse/touch ray against the same 4-fan terrain triangles
# used by BattleTerrain3D. No physics bodies, collision layers or game actions.
const Terrain = preload("res://scripts/ui/BattleTerrain3D.gd")
const HALF := Terrain.CELL*0.5
const EPSILON := 0.000001

static func _triangle_hit(origin: Vector3, ray: Vector3,
        a: Vector3, b: Vector3, c: Vector3) -> float:
    # Moller-Trumbore, double-sided, returns smallest positive ray parameter.
    var e1: Vector3 = b-a
    var e2: Vector3 = c-a
    var p: Vector3 = ray.cross(e2)
    var det: float = e1.dot(p)
    if absf(det) <= EPSILON:
        return -1.0
    var inverse: float = 1.0/det
    var from_a: Vector3 = origin-a
    var u: float = from_a.dot(p)*inverse
    if u < -EPSILON or u > 1.0+EPSILON:
        return -1.0
    var q: Vector3 = from_a.cross(e1)
    var v: float = ray.dot(q)*inverse
    if v < -EPSILON or u+v > 1.0+EPSILON:
        return -1.0
    var t: float = e2.dot(q)*inverse
    return t if t >= 0.0 else -1.0

static func cast(cells: Dictionary, origin: Vector3,
        direction: Vector3, max_distance: float = 750.0) -> Dictionary:
    if cells.is_empty() or direction.length_squared() < EPSILON:
        return {}
    var ray: Vector3 = direction.normalized()
    var nearest: float = max_distance
    var found: Dictionary = {}
    for cell in cells:
        if not cell is Vector2i:
            continue
        var p: Vector3 = Terrain.world_at(cell)
        # Prune XZ first: do NOT sample four shared heights for every tile
        # on a 40x30 board when a finger ray can only intersect one of them.
        var reach: Vector3 = origin+ray*nearest
        if maxf(origin.x,reach.x) < p.x-HALF or minf(origin.x,reach.x) > p.x+HALF:
            continue
        if maxf(origin.z,reach.z) < p.z-HALF or minf(origin.z,reach.z) > p.z+HALF:
            continue
        var tile: Dictionary = cells[cell]
        var biome: String = str(tile.get("kind","unknown"))
        var base_y: float = Terrain._cell_height(tile)
        var nw: Vector3
        var ne: Vector3
        var se: Vector3
        var sw: Vector3
        if biome in ["water","unknown"]:
            nw = p+Vector3(-HALF,base_y,-HALF)
            ne = p+Vector3(HALF,base_y,-HALF)
            se = p+Vector3(HALF,base_y,HALF)
            sw = p+Vector3(-HALF,base_y,HALF)
        else:
            var corner: PackedFloat32Array = Terrain._corners(cells,cell)
            nw = p+Vector3(-HALF,corner[0],-HALF)
            ne = p+Vector3(HALF,corner[1],-HALF)
            se = p+Vector3(HALF,corner[2],HALF)
            sw = p+Vector3(-HALF,corner[3],HALF)
        var crossings: Array[float] = []
        if biome in ["water","unknown"]:
            crossings = [
                _triangle_hit(origin,ray,nw,sw,ne),
                _triangle_hit(origin,ray,ne,sw,se)]
        else:
            var middle: Vector3 = p+Vector3(0,base_y,0)
            crossings = [
                _triangle_hit(origin,ray,nw,middle,ne),
                _triangle_hit(origin,ray,ne,middle,se),
                _triangle_hit(origin,ray,se,middle,sw),
                _triangle_hit(origin,ray,sw,middle,nw)]
        for distance in crossings:
            if distance >= 0.0 and distance < nearest:
                nearest = distance
                found = {
                    "cell":cell,"position":origin+ray*distance,
                    "distance":distance,"kind":biome,
                    "seen":bool(tile.get("seen",false))}
    return found
