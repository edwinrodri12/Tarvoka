extends SceneTree

const Regions = preload("res://scripts/ui/LandscapeRegions.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")

class RegionCanvas:
    extends Control
    const Painter = preload("res://scripts/ui/LandscapeRegions.gd")
    const Landscape = preload("res://scripts/ui/LandscapeDetailPainter.gd")
    const WorldArt = preload("res://scripts/ui/WorldArt.gd")

    func _draw() -> void:
        for mask in range(16):
            var c: Vector2 = Vector2(110+float(mask%8)*142,
                135+float(mask/8)*158)
            var cell := Vector2i(mask%8,mask/8)
            var neighbors: Dictionary = {}
            for side in range(4):
                if (mask & (1 << side)) != 0:
                    neighbors[side] = Color("#758C55")
            Painter.draw_biome_fringe(self,c,46.0,cell,
                "forest",neighbors,2)
            Landscape.draw_forest(self,c,46.0,mask*19,
                mask,2,cell)
            Landscape.draw_mountain(self,c+Vector2(0,450),46.0,
                mask*29,mask,2,mask,cell)
            WorldArt.draw_terrain(self,"plain",
                c+Vector2(0,690),46.0,0.0,mask*37,0,0,0,0,2,
                {"cell":cell,"biome_colors":neighbors})

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Regions.connection_count(0) == 0)
    assert(Regions.connection_count(15) == 4)
    assert(Regions.connection_count(5) == 2)
    # A genuine massif needs a few standout summits and many shoulders,
    # not a mountain peak of equal prominence in every connected cell.
    var prominent := 0
    var shoulders := 0
    var forest_counts: Dictionary = {}
    for x in range(15):
        var region_cell := Vector2i(x,3)
        var score: float = Regions.summit_strength(region_cell,15)
        if score > 0.81:
            prominent += 1
        if score < 0.60:
            shoulders += 1
        forest_counts[Regions.forest_density(region_cell,15,2)] = true
    assert(prominent >= 1 and prominent <= 5)
    assert(shoulders >= 5)
    assert(forest_counts.size() >= 2)
    for cell in [
        Vector2i.ZERO,Vector2i(1,2),
        Vector2i(12,7),Vector2i(31,29)
    ]:
        var v: float = Regions.region_variation(cell,13)
        assert(v >= 0.0 and v <= 1.0)
        assert(Regions.region_variation(cell,13) == v)
        assert(Regions.summit_strength(cell,0) >= 0.88)
        for mask in range(16):
            var s: float = Regions.summit_strength(cell,mask)
            assert(s >= 0.4 and s <= 1.1)
            for detail in [1,2]:
                var count: int = Regions.forest_density(cell,mask,detail)
                assert(count >= 2 and count <= 8)
            assert(Regions.forest_density(cell,mask,0) == 0)
        for side in range(4):
            var edge: PackedVector2Array = Regions.fringe_curve(
                Vector2.ZERO,64.0,side,cell,10)
            assert(edge.size() == 10)
            assert(edge == Regions.fringe_curve(
                Vector2.ZERO,64.0,side,cell,10))
            for pt in edge:
                assert(absf(pt.x)/64.0+absf(pt.y)/32.0 <= 1.0001)
    assert(Regions.fringe_curve(Vector2.ZERO,64.0,5,
        Vector2i.ZERO).is_empty())
    assert(Regions.fringe_curve(Vector2.ZERO,0.0,0,
        Vector2i.ZERO).is_empty())
    # The draw layer receives only explicit neighbors. An unknown fog tile
    # must never be consulted or inferred by the decorative painter.
    var grid: Array = [
        ["forest","plain","mountain"],
        ["forest","forest","plain"]
    ]
    var visible := {
        Vector2i(0,0):true,Vector2i(1,0):true
    }
    assert(Topology.neighbor_mask(grid,Vector2i(0,0),
        "forest",true,visible,true) == 0)
    assert(Topology.neighbor_mask(grid,Vector2i(0,0),
        "forest",true,visible,false) == Topology.SOUTH)
    var preview := RegionCanvas.new()
    preview.size = Vector2(1300,1100)
    root.add_child(preview)
    preview.queue_redraw()
    await process_frame
    preview.queue_free()
    print("PASS landscape regions: mixed canopy, massif dominance, biome fringes inside tiles, fog-safe tests")
    quit(0)
