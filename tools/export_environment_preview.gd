extends SceneTree

# Exports two real Godot screenshots of the SAME terrain renderer used in
# battles. This is a gallery of environment materials, not a screenshot of an
# actual player's battle or a claim of final concept-art fidelity.
const OUTPUT := "res://build/map-previews"
const WIDTH := 1600
const HEIGHT := 960

class PreviewCanvas:
    extends Control
    const WorldArt = preload("res://scripts/ui/WorldArt.gd")
    const Materials = preload("res://scripts/ui/TerrainSurfaceMaterials.gd")
    const Topology = preload("res://scripts/ui/TerrainTopology.gd")
    const Style = preload("res://scripts/ui/VisualStyle.gd")
    const GRID_SIZE := Vector2i(13,9)
    var detail: int = 2
    var grid: Array = []

    func _init() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        # Scenario drafted solely as an artwork QA fixture:
        # mountains, wooded valley, connected river and a road bridge.
        for y in range(GRID_SIZE.y):
            var line: Array = []
            for x in range(GRID_SIZE.x):
                var kind := "plain"
                if x <= 2 and y <= 3 or x <= 1 and y <= 5:
                    kind = "mountain"
                elif (x >= 2 and x <= 5 and y <= 2) or (
                        x >= 2 and x <= 5 and y >= 6) or (
                        x >= 9 and x <= 12 and y <= 2):
                    kind = "forest"
                if x in [6,7] and y != 4 or (
                        y >= 7 and x >= 8):
                    kind = "water"
                if y == 4 and x >= 1:
                    kind = "road"
                line.append(kind)
            grid.append(line)

    func _diamond(c: Vector2, hw: float) -> PackedVector2Array:
        return PackedVector2Array([
            c+Vector2(0,-hw*0.5),c+Vector2(hw,0),
            c+Vector2(0,hw*0.5),c+Vector2(-hw,0)
        ])

    func _draw() -> void:
        var width: float = size.x
        var height: float = size.y
        draw_rect(Rect2(Vector2.ZERO,size),Color("#0B1924"),true)
        draw_rect(Rect2(20,18,width-40,90),Color("#162E3C"),true)
        draw_string(ThemeDB.fallback_font,Vector2(55,55),
            "TARVOKA    |    ENVIRONMENT MATERIAL LAB",
            HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("#F1F2DC"))
        draw_string(ThemeDB.fallback_font,Vector2(55,89),
            "PLAYABLE WORLD ART  /  ROCK  -  FOREST  -  RIVER  -  ROAD",
            HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#9DC3C5"))
        draw_string(ThemeDB.fallback_font,Vector2(width-250,55),
            "DETAIL: %s" % ("FULL" if detail == 2 else "MEDIUM"),
            HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#E7BC63"))

        var hw: float = 49.0
        var start := Vector2(710,220)
        for depth in range(GRID_SIZE.x+GRID_SIZE.y-1):
            for y in range(GRID_SIZE.y):
                var x: int = depth-y
                if x < 0 or x >= GRID_SIZE.x:
                    continue
                var cell := Vector2i(x,y)
                var kind: String = str(grid[y][x])
                var c: Vector2 = start+Vector2(float(x-y)*hw,
                    float(x+y)*hw*0.5)
                var tint: Color = Style.terrain_color(kind,x,y)
                draw_colored_polygon(_diamond(c,hw),tint)
                var road_links: int = Topology.road_mask(grid,cell)
                var shore: int = Topology.shore_mask(grid,cell)
                var neigh: int = Topology.neighbor_mask(grid,cell,kind)
                var crossing: int = Topology.bridge_axis(grid,cell)
                var environment: Dictionary = {}
                if kind == "water":
                    environment["water_connections"] = neigh
                else:
                    environment["water_edges"] = Topology.neighbor_mask(
                        grid,cell,"water")
                    if kind == "mountain":
                        environment["exposed_edges"] = Topology.neighbor_mask(
                            grid,cell,"mountain",false)
                    else:
                        environment["mountain_edges"] = Topology.neighbor_mask(
                            grid,cell,"mountain")
                Materials.draw_surface(self,kind,c,hw,cell,detail)
                WorldArt.draw_terrain(self,kind,c,hw,1.1,depth*17+x,
                    road_links,shore,neigh,crossing,detail,environment)
                if kind == "road":
                    Materials.draw_road_wear(self,c,hw,cell,detail,
                        crossing != 0)

        draw_rect(Rect2(28,height-111,width-56,84),
            Color("#162E3C"),true)
        var labels: Array = [
            "1  ALPINE RIDGES", "2  TEMPERATE FORESTS",
            "3  RIVER + SHORES", "4  BRIDGE + ROAD"
        ]
        for i in range(labels.size()):
            var x: float = 58+float(i)*378
            draw_string(ThemeDB.fallback_font,Vector2(x,height-69),
                str(labels[i]),HORIZONTAL_ALIGNMENT_LEFT,-1,19,
                Color("#D9E5DB"))
        draw_string(ThemeDB.fallback_font,Vector2(58,height-42),
            "Original procedural 2.5D game assets. Visual-only; tactical rules unchanged.",
            HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#92ABB3"))

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = Vector2i(WIDTH,HEIGHT)
    var output_path: String = ProjectSettings.globalize_path(OUTPUT)
    var directory_error: Error = DirAccess.make_dir_recursive_absolute(output_path)
    if directory_error != OK:
        push_error("Cannot create screenshot folder: %s" % directory_error)
        quit(1)
        return
    var canvas := PreviewCanvas.new()
    canvas.size = Vector2(WIDTH,HEIGHT)
    root.add_child(canvas)
    for quality in [2,1]:
        canvas.detail = quality
        canvas.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        var shot: Image = root.get_texture().get_image()
        if shot.is_empty() or shot.get_width() != WIDTH or (
                shot.get_height() != HEIGHT):
            push_error("Preview window did not render at the expected resolution")
            canvas.queue_free()
            quit(1)
            return
        var filename := "terrain-full.png" if quality == 2 else (
            "terrain-medium.png")
        var saved: Error = shot.save_png(output_path.path_join(filename))
        if saved != OK:
            push_error("Could not save "+filename+" : "+str(saved))
            canvas.queue_free()
            quit(1)
            return
        print("PASS exported game-material preview: "+filename)
    canvas.queue_free()
    quit(0)
