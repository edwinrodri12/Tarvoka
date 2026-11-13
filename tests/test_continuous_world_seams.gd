extends SceneTree

const Flow = preload("res://scripts/ui/LandscapeContinuity.gd")
const Coast = preload("res://scripts/ui/LandscapeTransitions.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")

func _initialize() -> void:
    call_deferred("_run")

func _assert_shared_bank(c: Vector2, hw: float, cell: Vector2i,
        side: int, other_center: Vector2, other_cell: Vector2i) -> void:
    var other_side: int = Flow.opposite_side(side)
    assert(Coast.shared_edge_seed(cell,side) == (
        Coast.shared_edge_seed(other_cell,other_side)))
    var land: PackedVector2Array = Coast.shore_curve(
        c,hw,side,13,11,cell)
    var sea: PackedVector2Array = Coast.shore_curve(
        other_center,hw,other_side,91,11,other_cell)
    assert(land.size() == 11)
    assert(sea.size() == 11)
    var e0 := Vector2.ZERO
    var e1 := Vector2.ZERO
    match side:
        0:
            e0 = c+Vector2(hw,0)
            e1 = c+Vector2(0,hw*0.5)
        2:
            e0 = c+Vector2(0,hw*0.5)
            e1 = c+Vector2(-hw,0)
    for j in range(11):
        var t: float = float(j)/10.0
        var shared_edge: Vector2 = e0.lerp(e1,t)
        var first: float = land[j].distance_to(shared_edge)/(
            c.distance_to(shared_edge))
        var second: float = sea[10-j].distance_to(shared_edge)/(
            other_center.distance_to(shared_edge))
        assert(absf(first-second) < 0.00003)
        # No beach/foam surface crosses the tactical grid edge.
        assert(absf(land[j].x-c.x)/hw+
            absf(land[j].y-c.y)/(hw*0.5) <= 1.0001)
        assert(absf(sea[10-j].x-other_center.x)/hw+
            absf(sea[10-j].y-other_center.y)/(hw*0.5) <= 1.0001)

func _run() -> void:
    var c := Vector2(250,250)
    var hw: float = 64.0
    var cell := Vector2i(4,6)
    _assert_shared_bank(c,hw,cell,0,
        c+Vector2(hw,hw*0.5),cell+Vector2i(1,0))
    _assert_shared_bank(c,hw,cell,2,
        c+Vector2(-hw,hw*0.5),cell+Vector2i(0,1))
    assert(Flow.opposite_side(0) == 1)
    assert(Flow.opposite_side(2) == 3)
    assert(Flow.opposite_side(9) == -1)
    for side in range(4):
        var neighbor: Vector2i = Topology.DIRECTIONS[side]
        var neighbor_center: Vector2 = c+(
            Flow.DIRECTIONS[side]*hw*2.0)
        var one: PackedVector2Array = Flow.river_curve(c,hw,side,cell,9)
        var two: PackedVector2Array = Flow.river_curve(neighbor_center,hw,
            Flow.opposite_side(side),cell+neighbor,9)
        assert(one.size() == 10)
        assert(one[one.size()-1].distance_to(two[two.size()-1]) < 0.0001)
        for point in one:
            assert(absf(point.x-c.x)/hw+
                absf(point.y-c.y)/(hw*0.5) <= 1.0001)
    assert(Flow.river_curve(c,hw,8).is_empty())
    assert(Flow.river_curve(c,0.0,0).is_empty())
    var world: Array = [
        ["mountain","mountain","plain"],
        ["water","water","water"],
        ["forest","forest","plain"]
    ]
    var revealed: Dictionary = {Vector2i(1,1):true}
    assert(Topology.neighbor_mask(world,Vector2i(0,1),
        "water",true,revealed,true) == Topology.EAST)
    assert(Topology.neighbor_mask(world,Vector2i(0,0),
        "mountain",true,{},true) == 0)
    assert(Topology.neighbor_mask(world,Vector2i(0,0),
        "mountain",true,{},false) == Topology.EAST)
    print("PASS continuous world seams: river and mountain shared endpoints, mirrored coast profiles, fog-safe masks")
    quit(0)
