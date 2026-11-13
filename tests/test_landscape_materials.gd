extends SceneTree

const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Transitions = preload("res://scripts/ui/LandscapeTransitions.gd")

# Force real CanvasItem drawing in headless Godot. A malformed polygon is
# reported as ERROR by Godot; the GitHub workflow rejects it.
class TerrainMaterialCanvas:
    extends Control
    const WorldArt = preload("res://scripts/ui/WorldArt.gd")
    const Materials = preload("res://scripts/ui/TerrainSurfaceMaterials.gd")
    const Textures = preload("res://scripts/ui/TerrainTextureAtlas.gd")
    var detail: int = 2

    func _draw() -> void:
        for mask in range(16):
            var column: int = mask%8
            var line: int = int(mask/8)
            var c := Vector2(82.0+float(column)*124.0,
                95.0+float(line)*145.0)
            var hw: float = 42.0
            # Exercise every coast, scree, and exposed-cliff topology in
            # medium and full detail, including all four-bit intersections.
            # Exercise the same material painter used by real battles.
            for kind_index in range(5):
                var kind: String = ["mountain","forest","road","water","plain"][kind_index]
                var material_c: Vector2 = c+Vector2(0,340*kind_index)
                Textures.draw_ground(self,kind,material_c,hw,
                    Vector2i(mask,kind_index),detail)
                Materials.draw_surface(self,kind,material_c,hw,
                    Vector2i(mask,kind_index),detail)
            Materials.draw_road_wear(self,c+Vector2(0,680),hw,
                Vector2i(mask,3),detail,false)
            WorldArt.draw_terrain(self,"mountain",c,hw,0.2,mask,
                0,0,mask,0,detail,
                {"water_edges":mask,"exposed_edges":mask})
            WorldArt.draw_terrain(self,"forest",c+Vector2(0,340),hw,
                0.3,mask+7,0,0,mask,0,detail,
                {"water_edges":mask,"mountain_edges":mask})
            WorldArt.draw_terrain(self,"road",c+Vector2(0,680),hw,
                0.5,mask+13,mask,0,0,1 if mask%2 == 0 else 2,
                detail,{"water_edges":mask,"mountain_edges":mask})
            WorldArt.draw_terrain(self,"water",c+Vector2(0,1020),hw,
                0.7,mask+17,0,mask,0,0,detail,
                {"water_connections":mask})
            WorldArt.draw_terrain(self,"plain",c+Vector2(0,1360),hw,
                0.9,mask+23,0,0,0,0,detail,
                {"water_edges":mask,"mountain_edges":mask})

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var landscape := [
        ["plain","mountain","water"],
        ["forest","mountain","water"],
        ["forest","plain","plain"]
    ]
    assert(Topology.neighbor_mask(landscape,Vector2i(1,0),
        "mountain",false) == (Topology.WEST | Topology.EAST))
    assert(Topology.neighbor_mask(landscape,Vector2i(0,1),
        "mountain",true) == Topology.EAST)
    assert(Topology.neighbor_mask(landscape,Vector2i(1,2),
        "mountain",true) == Topology.NORTH)
    assert(Topology.neighbor_mask(landscape,Vector2i(2,2),
        "water",true) == Topology.NORTH)
    assert(Topology.neighbor_mask(landscape,Vector2i(1,0),
        "mountain",false,{Vector2i(0,0):true},true
        ) == Topology.WEST)
    assert(Topology.neighbor_mask(landscape,Vector2i(1,0),
        "mountain",false,{},true) == 0)
    # Broad organic color zones must be deterministic across redraws,
    # but not a checkerboard of alternating light/dark cells.
    for terrain_kind in ["plain","forest","mountain","water","road"]:
        var a: Color = Style.terrain_color(terrain_kind,2,3)
        var b: Color = Style.terrain_color(terrain_kind,2,3)
        assert(a == b)
        assert(a.a == 1.0)
        assert(a != Style.terrain_color(terrain_kind,3,3))
        assert(Style.terrain_color(terrain_kind,0,0) != (
            Style.terrain_color(terrain_kind,1,0)))
    const Materials = preload("res://scripts/ui/TerrainSurfaceMaterials.gd")
    assert(Materials.sample_count("plain",0) == 0)
    assert(Materials.sample_count("forest",1) <= Materials.sample_count("forest",2))
    assert(Materials.material_seed(Vector2i(10,5),4) == (
        Materials.material_seed(Vector2i(10,5),4)))
    for terrain_cell in [Vector2i(0,0),Vector2i(4,7),Vector2i(16,17)]:
        for mark in range(24):
            var local: Vector2 = Materials.material_position(terrain_cell,mark)
            assert(absf(local.x)+2.0*absf(local.y) <= 0.745)
    const Textures = preload("res://scripts/ui/TerrainTextureAtlas.gd")
    assert(Textures.get_material("unknown",2) == null)
    assert(Textures.get_material("plain",0) == null)
    var same_texture: Texture2D = Textures.get_material("plain",2)
    assert(same_texture != null)
    assert(same_texture == Textures.get_material("plain",2))
    assert(same_texture.get_width() == 160)
    assert(Textures.get_material("water",1).get_width() == 96)
    var material_count: int = Textures.texture_count()
    assert(material_count >= 2)
    # Organic bank vertices never leave the legal diamond or disclose
    # neighboring tiles: only visible-edge masks call these brushes.
    for side in range(4):
        for variant in [0,7,31,73]:
            var curve: PackedVector2Array = Transitions.shore_curve(
                Vector2.ZERO,64.0,side,variant,10)
            var repeated: PackedVector2Array = Transitions.shore_curve(
                Vector2.ZERO,64.0,side,variant,10)
            assert(curve.size() == 10)
            assert(curve == repeated)
            for point in curve:
                var radius: float = absf(point.x)/64.0+(
                    absf(point.y)/32.0)
                assert(radius < 1.001)
            assert(curve[0] != curve[9])
    assert(Transitions.shore_curve(Vector2.ZERO,0.0,0,0).is_empty())
    assert(Transitions.shore_curve(Vector2.ZERO,64.0,7,0).is_empty())
    for detail in [1,2]:
        var probe := TerrainMaterialCanvas.new()
        probe.size = Vector2(1300,1700)
        probe.detail = detail
        root.add_child(probe)
        probe.queue_redraw()
        await process_frame
        probe.queue_free()
    print("PASS landscape materials: organic shores ridges trees, cached atlas, safe topology and Godot draw")
    quit(0)
