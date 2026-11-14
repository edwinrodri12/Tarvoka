extends RefCounted
class_name TarvokaBattleTerrain3D

# Read-only 3D representation of an ACTUAL battle state.
# The 2D tactical board, movement rules, saved games and touch orders remain
# authoritative. This renderer can never alter battle state.
const Rules = preload("res://scripts/core/Rules.gd")
const Visibility = preload("res://scripts/core/Visibility.gd")
const Adapter = preload("res://scripts/ui/TerrainVisualMapBridge3D.gd")
const SurfaceFinish = preload("res://scripts/ui/TerrainSurfaceFinish3D.gd")
const SurfaceSampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const RoadShore = preload("res://scripts/ui/TerrainStudioRoadShore3D.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const CELL := 2.40
const MAX_DETAILED_UNITS := 8
const WATER_LEVEL := -0.17
const FOG_LEVEL := -0.23
const ROAD_LIFT := 0.065
const COLORS := {
    "unknown":Color("#101822"),
    "plain":Color("#6e8c63"),
    "forest":Color("#446e55"),
    "mountain":Color("#82929c"),
    "road":Color("#8d8675"),
    "water":Color("#468aa6")}

static func world_at(cell: Vector2i) -> Vector3:
    return Vector3(float(cell.x)*CELL,0.0,float(cell.y)*CELL)

static func _cell_height(tile: Dictionary) -> float:
    var kind: String = str(tile.get("kind","unknown"))
    match kind:
        "mountain":
            return 0.80
        "road":
            return 0.14
        "forest":
            return 0.23
        "plain":
            return 0.19
        "water":
            return WATER_LEVEL
    return FOG_LEVEL

static func _vertex_height(cells: Dictionary, at: Vector2i) -> float:
    var total := 0.0
    var count := 0
    var near_road := false
    for dy in [-1,0]:
        for dx in [-1,0]:
            var record: Dictionary = cells.get(at+Vector2i(dx,dy),{})
            var kind: String = str(record.get("kind","unknown"))
            if kind in ["unknown","water"]:
                continue
            total += _cell_height(record)
            count += 1
            near_road = near_road or kind == "road"
    if count == 0:
        return WATER_LEVEL
    var mean: float = total/float(count)
    return minf(mean,0.25) if near_road else mean

static func _corners(cells: Dictionary, cell: Vector2i) -> PackedFloat32Array:
    return PackedFloat32Array([
        _vertex_height(cells,cell),
        _vertex_height(cells,cell+Vector2i(1,0)),
        _vertex_height(cells,cell+Vector2i(1,1)),
        _vertex_height(cells,cell+Vector2i(0,1))])

static func height_at(cells: Dictionary, cell: Vector2i,
        x: float = 0.0, z: float = 0.0) -> float:
    var record: Dictionary = cells.get(cell,{})
    if str(record.get("kind","unknown")) in ["water","unknown"]:
        return _cell_height(record)
    return SurfaceSampler.height(_cell_height(record),_corners(cells,cell),
        x,z,CELL*0.5)

static func _tint(record: Dictionary) -> Color:
    var tint: Color = COLORS.get(str(record.get("kind","unknown")),
        COLORS["unknown"])
    if not bool(record.get("visible",false)) and bool(record.get("seen",false)):
        tint = tint.darkened(0.60)
    return tint

# V17: every visible LAND corner gets one deterministic, world-space
# palette sample. Neighbouring 8x8 chunks cannot assign different colours
# to a shared corner, and unexplored tiles never enter the sample.
# Water reads as alluvial shoreline and roads as a dusty verge, instead of
# spilling water-blue or dark asphalt across the surrounding ground.
static func _shared_corner_tint(cells: Dictionary, corner: Vector2i) -> Color:
    var total := Color(0.0,0.0,0.0,0.0)
    var weight_sum := 0.0
    for dy in [-1,0]:
        for dx in [-1,0]:
            var tile: Dictionary = cells.get(corner+Vector2i(dx,dy),{})
            if not bool(tile.get("details",false)):
                continue
            var kind: String = str(tile.get("kind","unknown"))
            var tint: Color = COLORS.get(kind,COLORS["plain"])
            var weight := 1.0
            if kind == "water":
                tint = Color("#bbaa89")
                weight = 0.74
            elif kind == "road":
                tint = Color("#999481")
                weight = 0.88
            total += tint*weight
            weight_sum += weight
    if weight_sum <= 0.0:
        return COLORS["plain"]
    return total*(1.0/weight_sum)

static func _vertex(tool: SurfaceTool, at: Vector3,
        color: Color) -> void:
    tool.set_color(color)
    tool.set_uv(Vector2(at.x*0.06,at.z*0.06))
    tool.add_vertex(at)

static func _tri(tool: SurfaceTool, a: Vector3,b: Vector3,c: Vector3,
        color: Color) -> void:
    _vertex(tool,a,color)
    _vertex(tool,b,color)
    _vertex(tool,c,color)

static func _tri_tinted(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,
        ca: Color,cb: Color,cc: Color) -> void:
    _vertex(tool,a,ca)
    _vertex(tool,b,cb)
    _vertex(tool,c,cc)

static func _panel(tool: SurfaceTool, nw: Vector3,ne: Vector3,
        se: Vector3,sw: Vector3,color: Color) -> void:
    _tri(tool,nw,sw,ne,color)
    _tri(tool,ne,sw,se,color)

static func _finish(parent: Node3D, label: String,
        tool: SurfaceTool, count: int, kind: String) -> void:
    if count == 0:
        return
    tool.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.name = label
    mesh.mesh = tool.commit()
    var mat := StandardMaterial3D.new()
    SurfaceFinish.apply(mat,kind)
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = mat
    parent.add_child(mesh)

static func _build_chunk(parent: Node3D, data: Dictionary,
        cells: Dictionary) -> Dictionary:
    var ground := SurfaceTool.new()
    var water := SurfaceTool.new()
    var unknown := SurfaceTool.new()
    var road := SurfaceTool.new()
    var shore := SurfaceTool.new()
    for tool in [ground,water,unknown,road,shore]:
        tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var land_count := 0
    var water_count := 0
    var hidden_count := 0
    var roads_count := 0
    var shores_count := 0
    var blended_count := 0
    for tile in data["cells"]:
        var cell: Vector2i = tile["cell"]
        var kind: String = str(tile["kind"])
        var at: Vector3 = world_at(cell)
        var half: float = CELL*0.5
        var tinted: Color = _tint(tile)
        if kind == "unknown":
            var flat: Vector3 = at+Vector3(0,FOG_LEVEL,0)
            _panel(unknown,flat+Vector3(-half,0,-half),
                flat+Vector3(half,0,-half),flat+Vector3(half,0,half),
                flat+Vector3(-half,0,half),tinted)
            hidden_count += 1
            continue
        if kind == "water":
            var sea: Vector3 = at+Vector3(0,WATER_LEVEL,0)
            _panel(water,sea+Vector3(-half,0,-half),sea+Vector3(half,0,-half),
                sea+Vector3(half,0,half),sea+Vector3(-half,0,half),tinted)
            water_count += 1
            continue
        var corners: PackedFloat32Array = _corners(cells,cell)
        var nw: Vector3 = at+Vector3(-half,corners[0],-half)
        var ne: Vector3 = at+Vector3(half,corners[1],-half)
        var se: Vector3 = at+Vector3(half,corners[2],half)
        var sw: Vector3 = at+Vector3(-half,corners[3],half)
        var middle: Vector3 = at+Vector3(0,_cell_height(tile),0)
        # No new geometry or draw calls: only vertex pigments change.
        # Explored but not presently visible tiles stay uniformly dim.
        if bool(tile.get("details",false)):
            var nw_tint: Color = _shared_corner_tint(cells,cell)
            var ne_tint: Color = _shared_corner_tint(cells,cell+Vector2i(1,0))
            var se_tint: Color = _shared_corner_tint(cells,cell+Vector2i(1,1))
            var sw_tint: Color = _shared_corner_tint(cells,cell+Vector2i(0,1))
            _tri_tinted(ground,nw,middle,ne,nw_tint,tinted,ne_tint)
            _tri_tinted(ground,ne,middle,se,ne_tint,tinted,se_tint)
            _tri_tinted(ground,se,middle,sw,se_tint,tinted,sw_tint)
            _tri_tinted(ground,sw,middle,nw,sw_tint,tinted,nw_tint)
            blended_count += 1
        else:
            _tri(ground,nw,middle,ne,tinted)
            _tri(ground,ne,middle,se,tinted)
            _tri(ground,se,middle,sw,tinted)
            _tri(ground,sw,middle,nw,tinted)
        land_count += 1
        # No landscape detail on explored-but-currently-hidden positions.
        if not bool(tile.get("details",false)):
            continue
        var surface_cell: Dictionary = {
            "x":cell.x,"z":cell.y,"top":_cell_height(tile),
            "half":half,"corners":corners}
        if kind == "road":
            var width := 0.70
            RoadShore._rect(road,at,surface_cell,-width,width,-width,width,
                Color("#5f6566"),ROAD_LIFT)
            var roads: Dictionary = tile["roads"]
            if bool(roads["north"]):
                RoadShore._rect(road,at,surface_cell,-width,width,-half,-width,
                    Color("#5f6566"),ROAD_LIFT)
            if bool(roads["south"]):
                RoadShore._rect(road,at,surface_cell,-width,width,width,half,
                    Color("#5f6566"),ROAD_LIFT)
            if bool(roads["west"]):
                RoadShore._rect(road,at,surface_cell,-half,-width,-width,width,
                    Color("#5f6566"),ROAD_LIFT)
            if bool(roads["east"]):
                RoadShore._rect(road,at,surface_cell,width,half,-width,width,
                    Color("#5f6566"),ROAD_LIFT)
            roads_count += 1
        else:
            var shore_edges: Dictionary = tile["shore"]
            for key in ["north","south","west","east"]:
                if not bool(shore_edges.get(key,false)):
                    continue
                var off: float = half-0.22
                if key=="north":
                    RoadShore._rect(shore,at,surface_cell,-half+0.12,half-0.12,
                        -half+0.04,-off,Color("#c4b18d"),0.033)
                elif key=="south":
                    RoadShore._rect(shore,at,surface_cell,-half+0.12,half-0.12,
                        off,half-0.04,Color("#c4b18d"),0.033)
                elif key=="west":
                    RoadShore._rect(shore,at,surface_cell,-half+0.04,-off,
                        -half+0.12,half-0.12,Color("#c4b18d"),0.033)
                else:
                    RoadShore._rect(shore,at,surface_cell,off,half-0.04,
                        -half+0.12,half-0.12,Color("#c4b18d"),0.033)
                shores_count += 1
    var chunk := Node3D.new()
    chunk.name = "Sector3D_%d_%d" % [data["origin"].x,data["origin"].y]
    parent.add_child(chunk)
    _finish(chunk,"SueloVisible",ground,land_count,"soil")
    _finish(chunk,"AguaVisible",water,water_count,"water")
    # Unknown terrain stays an opaque, untextured solid dark surface.
    if hidden_count > 0:
        unknown.generate_normals()
        var mesh := MeshInstance3D.new()
        mesh.name = "NieblaNoExplorada"
        mesh.mesh = unknown.commit()
        var mat := StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        mesh.material_override = mat
        chunk.add_child(mesh)
    _finish(chunk,"CaminosVisibles",road,roads_count,"soil")
    _finish(chunk,"OrillasVisibles",shore,shores_count,"soil")
    chunk.set_meta("origin",data["origin"])
    chunk.set_meta("tiles",data["tile_count"])
    return {"land":land_count,"water":water_count,"unknown":hidden_count,
        "roads":roads_count,"shore_edges":shores_count,
        "blended_tiles":blended_count}

static func _make_cone_trees(parent: Node3D,cells: Dictionary) -> int:
    var positions: Array[Transform3D] = []
    for cell in cells:
        var tile: Dictionary = cells[cell]
        if str(tile["kind"]) != "forest" or not bool(tile.get("details",false)):
            continue
        var tree_pos: Vector3 = world_at(cell)
        tree_pos.y = height_at(cells,cell,0.38,-0.16)+0.48
        positions.append(Transform3D(Basis.IDENTITY,tree_pos))
    if positions.is_empty():
        return 0
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = 0.43
    mesh.height = 1.02
    mesh.radial_segments = 7
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color("#37684d")
    mat.roughness = 0.94
    mesh.material = mat
    var group := MultiMesh.new()
    group.transform_format = MultiMesh.TRANSFORM_3D
    group.mesh = mesh
    group.instance_count = positions.size()
    for i in range(positions.size()):
        group.set_instance_transform(i,positions[i])
    var draw := MultiMeshInstance3D.new()
    draw.name = "BosqueInstanciado3D"
    draw.multimesh = group
    parent.add_child(draw)
    return positions.size()

static func _make_sites(parent: Node3D,state: Dictionary,
        cells: Dictionary) -> int:
    var sites: Array = []
    var economy: Dictionary = state.get("economy",{})
    for site in economy.get("sites",[]):
        sites.append({"kind":str(site["kind"]),"pos":site["pos"],
            "owner":int(site.get("owner",-1))})
    var control: Dictionary = state.get("control",{})
    for objective in control.get("nodes",[]):
        sites.append({"kind":"relay","pos":objective["pos"],
            "owner":int(objective.get("owner",-1))})
    var drawn: int = 0
    for site in sites:
        var cell: Vector2i = site["pos"]
        if not cells.has(cell):
            continue
        var known: Dictionary = cells[cell]
        if not bool(known.get("seen",false)):
            continue
        var visible: bool = bool(known.get("visible",false))
        # Ownership cannot leak through fog; unknown allegiance is neutral.
        var owner: int = int(site["owner"]) if visible else -1
        var color: Color = Color("#a9ada5")
        if owner == 0:
            color = Color("#6099db")
        elif owner == 1:
            color = Color("#dc6c65")
        var mesh: PrimitiveMesh
        if site["kind"] == "relay":
            var tower := CylinderMesh.new()
            tower.top_radius = 0.15
            tower.bottom_radius = 0.28
            tower.height = 1.45
            tower.radial_segments = 6
            mesh = tower
        else:
            var factory := BoxMesh.new()
            factory.size = Vector3(1.15,0.72,0.90)
            mesh = factory
        var material := StandardMaterial3D.new()
        material.albedo_color = color
        mesh.material = material
        var marker := MeshInstance3D.new()
        marker.name = "Instalacion3D_%s_%d_%d" % [
            str(site["kind"]),cell.x,cell.y]
        marker.mesh = mesh
        var lift: float = 0.73 if site["kind"]=="relay" else 0.37
        marker.position = world_at(cell)+Vector3(0,height_at(cells,cell)+lift,0)
        marker.set_meta("owner_public",owner)
        marker.set_meta("kind",site["kind"])
        parent.add_child(marker)
        drawn += 1
    return drawn

static func _make_units(parent: Node3D,state: Dictionary,
        cells: Dictionary, selected_id: String) -> Dictionary:
    var visible_count := 0
    var detailed := 0
    var hidden_enemies := 0
    var player: int = 0
    for unit in state.get("units",[]):
        if not unit is Dictionary or int(unit.get("hp",0))<=0:
            continue
        var cell: Vector2i = unit["pos"]
        var faction: int = int(unit.get("faction",-1))
        if faction != player and (not cells.has(cell) or
                not bool(cells[cell].get("visible",false))):
            hidden_enemies += 1
            continue
        if not cells.has(cell) or not bool(cells[cell].get("seen",false)):
            continue
        var role: String = str(unit.get("role","line"))
        var model: Node3D = null
        if detailed < MAX_DETAILED_UNITS and Models.supports(role):
            model = Models.build(role,faction,false,6)
            if model != null:
                detailed += 1
        if model == null:
            model = Node3D.new()
            var disc := MeshInstance3D.new()
            var disk := CylinderMesh.new()
            disk.top_radius = 0.42
            disk.bottom_radius = 0.48
            disk.height = 0.42
            disk.radial_segments = 8
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color("#5d94d8") if faction == 0 else Color("#d76d61")
            disk.material = mat
            disc.mesh = disk
            model.add_child(disc)
        model.name = "Unidad3D_%s" % str(unit["id"])
        # Distinct layers may share exactly one logical grid coordinate.
        # Air models must be visibly ABOVE ground/naval models rather than
        # clipping through another unit when both occupy the same cell.
        var altitude: float = 2.45 if Domains.layer(unit) == "air" else 0.43
        model.position = world_at(cell)+Vector3(0,height_at(cells,cell)+altitude,0)
        model.set_meta("visual_layer",Domains.layer(unit))
        model.set_meta("cell",cell)
        model.set_meta("faction",faction)
        model.set_meta("selected",str(unit["id"])==selected_id)
        parent.add_child(model)
        visible_count += 1
    return {"visible":visible_count,"detailed":detailed,
        "hidden_enemies":hidden_enemies}

static func build(state: Dictionary, selected_id: String = "") -> Node3D:
    var terrain: Array = state.get("terrain",[])
    if not Rules.valid_terrain(terrain):
        return null
    var scene := Node3D.new()
    scene.name = "MapaTactico3DReal"
    var dims: Vector2i = Rules.map_size(terrain)
    var use_fog: bool = Visibility.enabled(state)
    var explored: Dictionary = Visibility.explored_cells(state,0) if use_fog else {}
    var visible: Dictionary = Visibility.visible_cells(state,0) if use_fog else {}
    var cells: Dictionary = {}
    var chunks: Array[Dictionary] = []
    for y in range(0,dims.y,Adapter.CHUNK_SIDE):
        for x in range(0,dims.x,Adapter.CHUNK_SIDE):
            var chunk: Dictionary = Adapter.collect(terrain,Vector2i(x,y),
                Vector2i(Adapter.CHUNK_SIDE,Adapter.CHUNK_SIDE),
                explored,visible,use_fog)
            if chunk.is_empty():
                scene.free()
                return null
            for tile in chunk["cells"]:
                cells[tile["cell"]] = tile
            chunks.append(chunk)
    var counters: Dictionary = {"land":0,"water":0,"unknown":0,
        "roads":0,"shore_edges":0,"blended_tiles":0}
    for chunk in chunks:
        var stats: Dictionary = _build_chunk(scene,chunk,cells)
        for key in counters:
            counters[key] = int(counters[key])+int(stats[key])
    counters["trees"] = _make_cone_trees(scene,cells)
    counters["sites"] = _make_sites(scene,state,cells)
    counters["units"] = _make_units(scene,state,cells,selected_id)
    counters["chunks"] = chunks.size()
    # A shared vertex palette reuses the existing ground mesh/material;
    # no extra render batches for 24x18 or 40x30 mobile boards.
    counters["terrain_blend_extra_batches"] = 0
    scene.set_meta("board_size",dims)
    scene.set_meta("visual_only",true)
    scene.set_meta("public_cells",cells)
    scene.set_meta("render_stats",counters)
    scene.set_meta("selected_unit_id",selected_id)
    return scene
