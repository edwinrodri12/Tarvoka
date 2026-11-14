extends SceneTree

# V17: verify REAL 3D mesh colour continuity across 8x8 chunks, three board
# sizes, fog secrecy and identical tactical state with zero extra batches.
const Renderer = preload("res://scripts/ui/BattleTerrain3D.gd")
const Session = preload("res://scripts/core/BattleSession.gd")
const Scenarios = preload("res://scripts/core/Scenarios.gd")
const Rules = preload("res://scripts/core/Rules.gd")
const CELL := 2.40

func _initialize() -> void:
    call_deferred("_run")

func _color_equal(a: Color,b: Color) -> bool:
    return absf(a.r-b.r)<0.002 and absf(a.g-b.g)<0.002 and (
        absf(a.b-b.b)<0.002 and absf(a.a-b.a)<0.002)

func _scan_seams(root: Node3D) -> Dictionary:
    var palette: Dictionary = {}
    var seam_matches := 0
    var color_variations := 0
    var ground_chunks := 0
    for chunk in root.get_children():
        if not (chunk is Node3D and chunk.name.begins_with("Sector3D_")):
            continue
        var ground: MeshInstance3D = chunk.find_child(
            "SueloVisible",false,false) as MeshInstance3D
        if ground == null:
            continue
        ground_chunks += 1
        var data: Array = ground.mesh.surface_get_arrays(0)
        var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
        var colors: PackedColorArray = data[Mesh.ARRAY_COLOR]
        assert(vertices.size()>0 and vertices.size()==colors.size())
        assert(ground.material_override is StandardMaterial3D)
        assert((ground.material_override as StandardMaterial3D).vertex_color_use_as_albedo)
        for i in range(vertices.size()):
            var p: Vector3 = vertices[i]
            var gx: float = p.x/CELL+0.5
            var gz: float = p.z/CELL+0.5
            # Only shared lattice CORNERS, not the unique fan centres.
            if absf(gx-roundf(gx))>0.001 or absf(gz-roundf(gz))>0.001:
                continue
            var key := Vector2i(roundi(gx),roundi(gz))
            if palette.has(key):
                assert(_color_equal(palette[key],colors[i]))
                if key.x%8==0 or key.y%8==0:
                    seam_matches += 1
            else:
                palette[key] = colors[i]
        # There are still only FIVE possible base terrain surfaces:
        # land, water, unknown, asphalt and shore; never one per cell.
        var base_meshes := 0
        for child in chunk.get_children():
            if child is MeshInstance3D:
                base_meshes += 1
        assert(base_meshes<=5)
    # Mixing forest/road/water at corners must be visible as more than
    # one solid flat terrain colour, while remaining a tiny mesh budget.
    for color in palette.values():
        if not _color_equal(color,Renderer.COLORS["plain"]):
            color_variations += 1
    return {"chunks":ground_chunks,"corners":palette.size(),
        "shared":seam_matches,"variations":color_variations}

func _run() -> void:
    var total_seams := 0
    var total_blended := 0
    for dims in [Vector2i(10,8),Vector2i(24,18),Vector2i(40,30)]:
        var map: Array = Scenarios.seeded_terrain(22435,dims)
        assert(Rules.valid_terrain(map))
        var units: Array = [
            {"id":"A","role":"line","faction":0,"hp":10,"pos":Vector2i(1,1),
             "acted":false},
            {"id":"X","role":"tank","faction":1,"hp":10,
             "pos":Vector2i(dims.x-2,dims.y-2),"acted":false}]
        var state: Dictionary = Session.start(units,map,0,false)
        var snapshot: Dictionary = state.duplicate(true)
        var scene: Node3D = Renderer.build(state,"A")
        assert(scene!=null and scene.get_meta("visual_only"))
        assert(scene.get_meta("board_size")==dims)
        var stats: Dictionary = scene.get_meta("render_stats")
        assert(int(stats["chunks"])==(
            int(ceili(float(dims.x)/8.0))*int(ceili(float(dims.y)/8.0))))
        assert(int(stats["unknown"])==0)
        assert(int(stats["blended_tiles"])==int(stats["land"]))
        assert(int(stats["terrain_blend_extra_batches"])==0)
        assert(int(stats["land"])+int(stats["water"])==dims.x*dims.y)
        var mesh: Dictionary = _scan_seams(scene)
        assert(int(mesh["chunks"])>0)
        assert(int(mesh["shared"])>0)
        assert(int(mesh["variations"])>0)
        total_seams += int(mesh["shared"])
        total_blended += int(stats["blended_tiles"])
        assert(state==snapshot)
        scene.free()

        var fog_state: Dictionary = Session.start(units,map,0,true)
        var old_fog: Dictionary = fog_state.duplicate(true)
        var fog_view: Node3D = Renderer.build(fog_state,"A")
        assert(fog_view!=null)
        var hidden: Dictionary = fog_view.get_meta("render_stats")
        var safe: Dictionary = fog_view.get_meta("public_cells")
        assert(int(hidden["unknown"])>0)
        var visible_land := 0
        var masked := 0
        for key in safe:
            var t: Dictionary = safe[key]
            if str(t["kind"]) == "unknown":
                assert(not bool(t.get("details",false)))
                masked += 1
            elif bool(t.get("details",false)) and str(t["kind"]) not in ["water"]:
                visible_land += 1
        assert(masked==int(hidden["unknown"]))
        assert(visible_land==int(hidden["blended_tiles"]))
        assert(int(hidden["terrain_blend_extra_batches"])==0)
        assert(fog_state==old_fog)
        fog_view.free()
    assert(total_seams>0 and total_blended>0)

    # A formerly hidden tile cannot bias the colour of visible terrain
    # even when its private kind is changed behind the fog mask.
    var corner := Vector2i(8,8)
    var visible := {"kind":"plain","details":true}
    var secret := {"kind":"unknown","details":false}
    var masked_cells: Dictionary = {
        Vector2i(7,7):visible,
        Vector2i(8,7):secret,
        Vector2i(7,8):secret,
        Vector2i(8,8):secret}
    var before: Color = Renderer._shared_corner_tint(masked_cells,corner)
    masked_cells[Vector2i(8,7)] = {"kind":"mountain","details":false}
    var after: Color = Renderer._shared_corner_tint(masked_cells,corner)
    assert(_color_equal(before,after))
    print("PASS TERRAIN_BATTLE_V17: %d shared chunk-corner matches, %d blended land tiles, 3 board sizes, fog-safe, no extra draw batches" % [total_seams,total_blended])
    quit(0)
