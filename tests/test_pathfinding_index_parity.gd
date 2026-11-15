extends SceneTree

# Differential correctness test: optimized Dictionary blocker membership
# must be byte-for-byte identical to the old Array membership algorithm.
const Rules=preload("res://scripts/core/Rules.gd")
const Scenarios=preload("res://scripts/core/Scenarios.gd")

static func _reference_reachable(origin: Vector2i,points: int,
        terrain: Array,blocked: Array[Vector2i],domain: String) -> Dictionary:
    var distances: Dictionary={}
    if not Rules.valid_terrain(terrain) or not Rules.inside(origin,terrain) or (
            points<0 or origin in blocked):
        return distances
    if Rules.movement_cost_for(terrain[origin.y][origin.x],domain)<0:
        return distances
    distances[origin]=0
    var frontier: Array[Vector2i]=[origin]
    var cursor: int=0
    while cursor<frontier.size():
        var current: Vector2i=frontier[cursor]
        cursor+=1
        for direction in Rules.DIRECTIONS:
            var next: Vector2i=current+direction
            if not Rules.inside(next,terrain) or next in blocked:
                continue
            var cost: int=Rules.movement_cost_for(
                str(terrain[next.y][next.x]),domain)
            if cost<0:
                continue
            var total: int=int(distances[current])+cost
            if total>points or (
                    distances.has(next) and int(distances[next])<=total):
                continue
            distances[next]=total
            frontier.append(next)
    return distances

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var cases: int=0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        for scenario in [0,1,2,3]:
            var terrain: Array=Scenarios.terrain(scenario,dims)
            assert(Rules.valid_terrain(terrain))
            var blocked: Array[Vector2i]=[]
            for i in range(48):
                var cell:=Vector2i(
                    (i*17+3)%dims.x,(i*11+2)%dims.y)
                if cell not in blocked:
                    blocked.append(cell)
            for domain in ["ground","air","naval"]:
                var found: bool=false
                var start:=Vector2i.ZERO
                for y in range(dims.y):
                    if found:
                        break
                    for x in range(dims.x):
                        var probe:=Vector2i(x,y)
                        if Rules.movement_cost_for(
                                str(terrain[y][x]),domain)>=0 and (
                                probe not in blocked):
                            start=probe
                            found=true
                            break
                if not found:
                    continue
                for movement in [0,1,3,6,8]:
                    var expected: Dictionary=_reference_reachable(
                        start,movement,terrain,blocked,domain)
                    var optimized: Dictionary=Rules.reachable(
                        start,movement,terrain,blocked,domain)
                    assert(optimized==expected)
                    cases+=1
                # An occupied starting tile cannot be used as an exploit.
                var blocked_origin: Array[Vector2i]=blocked.duplicate()
                blocked_origin.append(start)
                assert(Rules.reachable(start,4,terrain,blocked_origin,
                    domain).is_empty())
    assert(cases>=100)
    print("PASS TARVOKA INDEXED PATHFINDING PARITY: %d movement comparisons, three domains, 10x8/24x18/40x30, blocked origins" % cases)
    quit(0)
