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
const InfantryBarracks = preload("res://scripts/ui/InfantryBarracksBattle3D.gd")
const ArmoredWorkshop = preload("res://scripts/ui/ArmoredWorkshopBattle3D.gd")
const ArmoredWorkshopLOD = preload("res://scripts/ui/ArmoredWorkshopBattleLOD.gd")
const Airbase3D = preload("res://scripts/ui/AirbaseBattle3D.gd")
const AirbaseLOD = preload("res://scripts/ui/AirbaseBattleLOD.gd")
const NavalBase3D = preload("res://scripts/ui/NavalBaseBattle3D.gd")
const NavalBaseLOD = preload("res://scripts/ui/NavalBaseBattleLOD.gd")
const DroneCenter3D = preload("res://scripts/ui/DroneCenterBattle3D.gd")
const DroneCenterLOD = preload("res://scripts/ui/DroneCenterBattleLOD.gd")
const CivilianCity = preload("res://scripts/ui/CivilianCityBattle3D.gd")
const Headquarters3D = preload("res://scripts/ui/HeadquartersBattle3D.gd")
const CityDistance = preload("res://scripts/ui/CivilianCityDistanceLODV6.gd")
const APCTactical = preload("res://scripts/ui/APCTacticalLOD8.gd")
const APCCameraLOD = preload("res://scripts/ui/APCDistanceLODControllerV9.gd")
const G11BattleLOD = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const G11Tactical = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const G11ActionsV29 = preload("res://scripts/ui/G11BattleActionsV29.gd")
const G13ActionsV70 = preload("res://scripts/ui/G13BattleActionsV70.gd")
const FactionIdentity = preload("res://scripts/ui/FactionIdentity.gd")
const Domains = preload("res://scripts/core/Domains.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
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

static func _biome_color(kind: String,cell: Vector2i,
        biome: String) -> Color:
    if kind == "unknown":
        return COLORS["unknown"]
    if biome == Biomes.TEMPERATE:
        return COLORS.get(kind,COLORS["plain"])
    return Biomes.tile_color(kind,cell.x,cell.y,biome)

static func _tint(record: Dictionary,biome: String = Biomes.TEMPERATE) -> Color:
    var tint: Color = _biome_color(str(record.get("kind","unknown")),
        record.get("cell",Vector2i.ZERO),biome)
    if not bool(record.get("visible",false)) and bool(record.get("seen",false)):
        tint = tint.darkened(0.60)
    return tint

# V17: every visible LAND corner gets one deterministic, world-space
# palette sample. Neighbouring 8x8 chunks cannot assign different colours
# to a shared corner, and unexplored tiles never enter the sample.
# Water reads as alluvial shoreline and roads as a dusty verge, instead of
# spilling water-blue or dark asphalt across the surrounding ground.
static func _shared_corner_tint(cells: Dictionary, corner: Vector2i,
        biome: String = Biomes.TEMPERATE) -> Color:
    var total := Color(0.0,0.0,0.0,0.0)
    var weight_sum := 0.0
    for dy in [-1,0]:
        for dx in [-1,0]:
            var tile: Dictionary = cells.get(corner+Vector2i(dx,dy),{})
            if not bool(tile.get("details",false)):
                continue
            var kind: String = str(tile.get("kind","unknown"))
            var tint: Color = _biome_color(
                kind,corner+Vector2i(dx,dy),biome)
            var weight := 1.0
            if kind == "water":
                tint = Color("#c6dce0") if biome == Biomes.WINTER else (
                    Color("#bbaa89") if biome != Biomes.COASTAL else Color("#7aa99b"))
                weight = 0.74
            elif kind == "road":
                tint = Color("#abbac0") if biome == Biomes.WINTER else (
                    Color("#999481") if biome != Biomes.CANYON else Color("#b79b76"))
                weight = 0.88
            total += tint*weight
            weight_sum += weight
    if weight_sum <= 0.0:
        return _biome_color("plain",corner,biome)
    return total*(1.0/weight_sum)

static func _cached_corner_tint(cells: Dictionary,corner: Vector2i,
        cache: Dictionary,biome: String = Biomes.TEMPERATE) -> Color:
    if not cache.has(corner):
        cache[corner] = _shared_corner_tint(cells,corner,biome)
    return cache[corner]

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

static func _road_color(biome: String) -> Color:
    if biome == Biomes.WINTER:
        return Biomes.ROAD_DARK
    if biome == Biomes.CANYON:
        return Color("#777068")
    if biome == Biomes.COASTAL:
        return Color("#56676b")
    return Color("#5f6566")

static func _shore_color(biome: String) -> Color:
    if biome == Biomes.WINTER:
        return Biomes.FROZEN_SHORE
    if biome == Biomes.CANYON:
        return Color("#c5a980")
    if biome == Biomes.COASTAL:
        return Color("#7fa896")
    return Color("#c4b18d")

static func _build_chunk(parent: Node3D, data: Dictionary,
        cells: Dictionary,corner_cache: Dictionary,
        biome: String = Biomes.TEMPERATE) -> Dictionary:
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
        var tinted: Color = _tint(tile,biome)
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
            var nw_tint: Color = _cached_corner_tint(cells,cell,corner_cache,biome)
            var ne_tint: Color = _cached_corner_tint(cells,cell+Vector2i(1,0),corner_cache,biome)
            var se_tint: Color = _cached_corner_tint(cells,cell+Vector2i(1,1),corner_cache,biome)
            var sw_tint: Color = _cached_corner_tint(cells,cell+Vector2i(0,1),corner_cache,biome)
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
                _road_color(biome),ROAD_LIFT)
            var roads: Dictionary = tile["roads"]
            if bool(roads["north"]):
                RoadShore._rect(road,at,surface_cell,-width,width,-half,-width,
                    _road_color(biome),ROAD_LIFT)
            if bool(roads["south"]):
                RoadShore._rect(road,at,surface_cell,-width,width,width,half,
                    _road_color(biome),ROAD_LIFT)
            if bool(roads["west"]):
                RoadShore._rect(road,at,surface_cell,-half,-width,-width,width,
                    _road_color(biome),ROAD_LIFT)
            if bool(roads["east"]):
                RoadShore._rect(road,at,surface_cell,width,half,-width,width,
                    _road_color(biome),ROAD_LIFT)
            roads_count += 1
        else:
            var shore_edges: Dictionary = tile["shore"]
            for key in ["north","south","west","east"]:
                if not bool(shore_edges.get(key,false)):
                    continue
                var off: float = half-0.22
                if key=="north":
                    RoadShore._rect(shore,at,surface_cell,-half+0.12,half-0.12,
                        -half+0.04,-off,_shore_color(biome),0.033)
                elif key=="south":
                    RoadShore._rect(shore,at,surface_cell,-half+0.12,half-0.12,
                        off,half-0.04,_shore_color(biome),0.033)
                elif key=="west":
                    RoadShore._rect(shore,at,surface_cell,-half+0.04,-off,
                        -half+0.12,half-0.12,_shore_color(biome),0.033)
                else:
                    RoadShore._rect(shore,at,surface_cell,off,half-0.04,
                        -half+0.12,half-0.12,_shore_color(biome),0.033)
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

# V20b: use one reusable 21-facet layered fir mesh, NOT hundreds of
# separate trees. Snow is painted directly into the upper branches.
static func _make_cone_trees(parent: Node3D,cells: Dictionary,
        biome: String = Biomes.TEMPERATE) -> int:
    var positions: Array[Transform3D] = []
    for cell in cells:
        var tile: Dictionary = cells[cell]
        if str(tile["kind"]) != "forest" or not bool(tile.get("details",false)):
            continue
        for j in range(2 if biome!=Biomes.CANYON else 1):
            var shift: Vector2 = Vector2(-0.38,0.26) if j==0 else Vector2(0.38,-0.28)
            var at: Vector3 = world_at(cell)+Vector3(shift.x,0,shift.y)
            at.y = height_at(cells,cell,shift.x,shift.y)+0.41
            var angle: float = float(posmod(
                cell.x*37+cell.y*83+j*19,16))/16.0*TAU
            var scale: float = 0.82+float(posmod(cell.x*7+cell.y*13+j,5))*0.075
            var rotated := Basis(Vector3.UP,angle).scaled(
                Vector3(scale,scale,scale))
            positions.append(Transform3D(rotated,at))
    if positions.is_empty():
        return 0
    var foliage: Color = (
        Color("#40625b") if biome==Biomes.WINTER else
        Color("#91845c") if biome==Biomes.CANYON else
        Color("#2e7665") if biome==Biomes.COASTAL else Color("#396b4c"))
    var tree_mesh := SurfaceTool.new()
    tree_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(3):
        var radius: float = 0.45-float(layer)*0.10
        var low: float = -0.32+float(layer)*0.29
        var tip: Vector3 = Vector3(0,0.63+float(layer)*0.25,0)
        for seg in range(7):
            var angle_a: float = TAU*float(seg)/7.0
            var angle_b: float = TAU*float(seg+1)/7.0
            var a := Vector3(cos(angle_a)*radius,low,sin(angle_a)*radius)
            var b := Vector3(cos(angle_b)*radius,low,sin(angle_b)*radius)
            var top_tint: Color = (
                Biomes.HARDPACK if biome==Biomes.WINTER and layer>=1 else
                foliage.lightened(0.08+0.045*float(layer)))
            var side: Color = foliage.darkened(0.065*float(seg%3))
            _tri_tinted(tree_mesh,a,b,tip,side,foliage.lightened(0.055),
                top_tint)
    tree_mesh.generate_normals()
    var mesh: ArrayMesh = tree_mesh.commit()
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color.WHITE
    mat.vertex_color_use_as_albedo = true
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.roughness = 0.96
    mesh.surface_set_material(0,mat)
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
    if biome == Biomes.WINTER:
        var cap := CylinderMesh.new()
        cap.top_radius = 0.0
        cap.bottom_radius = 0.14
        cap.height = 0.22
        cap.radial_segments = 7
        var snow_mat := StandardMaterial3D.new()
        snow_mat.albedo_color = Biomes.SNOW
        snow_mat.roughness = 0.99
        cap.material = snow_mat
        var snow := MultiMesh.new()
        snow.transform_format = MultiMesh.TRANSFORM_3D
        snow.mesh = cap
        snow.instance_count = positions.size()
        for i in range(positions.size()):
            snow.set_instance_transform(i,positions[i].translated_local(
                Vector3(0,0.99,0)))
        var snow_draw := MultiMeshInstance3D.new()
        snow_draw.name = "NieveEnConiferasInstanciadaV20"
        snow_draw.multimesh = snow
        parent.add_child(snow_draw)
    return positions.size()

# Two high points and six lateral faces, all painted in this actual rock
# mesh. This explicitly replaces the small generic cones that made the
# battlefield mountains appear separate from the V18b/V19 environments.
static func _make_mountain_ridges(parent: Node3D,cells: Dictionary,
        biome: String) -> int:
    var transforms: Array[Transform3D] = []
    for cell in cells:
        var tile: Dictionary = cells[cell]
        if str(tile.get("kind",""))!="mountain" or not bool(tile.get("details",false)):
            continue
        var base: Vector3 = world_at(cell)
        base.y = height_at(cells,cell)+0.33
        var angle: float = float(posmod(
            cell.x*31+cell.y*17,13))/13.0*TAU
        var shape := Basis(Vector3.UP,angle).scaled(
            Vector3(0.95,0.9+float(posmod(cell.x*11+cell.y,4))*0.07,0.95))
        transforms.append(Transform3D(shape,base))
    if transforms.is_empty():
        return 0
    var rock: Color = _biome_color("mountain",Vector2i(2,2),biome)
    var shadow: Color = rock.darkened(0.25)
    var light: Color = rock.lightened(0.12)
    var crest: Color = (
        Biomes.SNOW if biome==Biomes.WINTER else
        Color("#c2ac89") if biome==Biomes.CANYON else
        Color("#80a69b") if biome==Biomes.COASTAL else Color("#96a9a0"))
    var nw := Vector3(-0.84,-0.37,-0.80)
    var ne := Vector3(0.76,-0.40,-0.86)
    var se := Vector3(0.85,-0.42,0.74)
    var sw := Vector3(-0.81,-0.35,0.81)
    var peak_a := Vector3(-0.33,1.08,-0.18)
    var peak_b := Vector3(0.35,0.83,0.19)
    var mesh_tool := SurfaceTool.new()
    mesh_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    _tri_tinted(mesh_tool,nw,ne,peak_a,shadow,rock,crest)
    _tri_tinted(mesh_tool,ne,peak_b,peak_a,rock,light,crest)
    _tri_tinted(mesh_tool,ne,se,peak_b,light,rock,light)
    _tri_tinted(mesh_tool,se,sw,peak_b,shadow,rock,crest)
    _tri_tinted(mesh_tool,sw,peak_a,peak_b,shadow,crest,light)
    _tri_tinted(mesh_tool,sw,nw,peak_a,rock,shadow,crest)
    mesh_tool.generate_normals()
    var peaks: ArrayMesh = mesh_tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.albedo_color = Color.WHITE
    material.roughness = 0.97
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    peaks.surface_set_material(0,material)
    var multi := MultiMesh.new()
    multi.mesh = peaks
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.instance_count = transforms.size()
    for i in range(transforms.size()):
        multi.set_instance_transform(i,transforms[i])
    var rock_instance := MultiMeshInstance3D.new()
    rock_instance.name = "Macizos3DPorBiomaV20"
    rock_instance.multimesh = multi
    parent.add_child(rock_instance)
    return transforms.size()

static func _make_sites(parent: Node3D,state: Dictionary,
        cells: Dictionary) -> int:
    var sites: Array = []
    var economy: Dictionary = state.get("economy",{})
    for site in economy.get("sites",[]):
        var visual_site: Dictionary={
            "kind":str(site["kind"]),"pos":site["pos"],
            "owner":int(site.get("owner",-1)),
            "visual_damage_stage":int(site.get("visual_damage_stage",0))}
        # Only preserve a VISUALLY EXPLICIT tier. A synthetic default
        # must not disable deterministic map-size city silhouettes.
        if site.has("visual_level"):
            visual_site["visual_level"]=int(site["visual_level"])
        sites.append(visual_site)
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
        # A hidden workshop is explored geometry only, never a live feed
        # of enemy upgrades or fresh damage inflicted behind the fog.
        if not visible and str(site["kind"]) in ["armor_plant","airbase","shipyard","drone_center"]:
            site["visual_damage_stage"]=0
            site.erase("visual_level")
        # Real civil V4 district, identical to the shared Art Studio.
        # CELL_MODEL_SCALE confines all geometry to one 2.4 m board tile.
        # An explored-but-not-visible city must not reveal its new owner.
        if str(site["kind"])=="city":
            # The same TWO command-city landmarks as the approved 2D HQ:
            # native tactical 3D architecture, still a capturable income city.
            # Never use the hidden real owner or upgrades through fog.
            var command_hq:Node3D=Headquarters3D.build_site(
                state,site,owner,visible)
            if command_hq!=null:
                command_hq.name="Instalacion3D_city_%d_%d" % [cell.x,cell.y]
                command_hq.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                command_hq.set_meta("owner_public",owner)
                command_hq.set_meta("kind","city")
                command_hq.set_meta("battle_cell",cell)
                parent.add_child(command_hq)
                drawn+=1
                continue
            var city: Node3D=CivilianCity.build_site(state,site,owner,2)
            if city!=null:
                city.name="Instalacion3D_city_%d_%d" % [cell.x,cell.y]
                city.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                city.set_meta("owner_public",owner)
                city.set_meta("kind","city")
                city.set_meta("battle_cell",cell)
                parent.add_child(city)
                drawn+=1
                continue
        # The approved Infantry Barracks V11 replaces the generic cube
        # for the pre-existing factory site in actual playable 3D battles.
        # FOW still hides unexplored cells and unknown ownership.
        if str(site["kind"])=="factory":
            var barracks: Node3D=InfantryBarracks.build_site(state,site,owner)
            if barracks!=null:
                barracks.name="Instalacion3D_factory_%d_%d" % [cell.x,cell.y]
                barracks.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                barracks.set_meta("owner_public",owner)
                barracks.set_meta("kind","factory")
                barracks.set_meta("battle_cell",cell)
                parent.add_child(barracks)
                drawn+=1
                continue
        # Existing modern armor_plant sites already manufacture armored
        # units. Replace ONLY their generic render cube with approved
        # workshop art; keep all game production, capture, saving and supply.
        if str(site["kind"])=="armor_plant":
            var workshop:Node3D=ArmoredWorkshop.build_site(
                state,site,owner)
            if workshop!=null:
                workshop.name="Instalacion3D_armor_plant_%d_%d" % [
                    cell.x,cell.y]
                workshop.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                workshop.set_meta("owner_public",owner)
                workshop.set_meta("kind","armor_plant")
                workshop.set_meta("battle_cell",cell)
                parent.add_child(workshop)
                drawn+=1
                continue
        # The existing airbase already produces aircraft. Render its
        # approved V4 single-mesh tactical building in that SAME tile.
        # Do not insert new sites or touch prices / production / capture.
        if str(site["kind"])=="airbase":
            var airfield:Node3D=Airbase3D.build_site(state,site,owner)
            if airfield!=null:
                airfield.name="Instalacion3D_airbase_%d_%d" % [
                    cell.x,cell.y]
                airfield.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                airfield.set_meta("owner_public",owner)
                airfield.set_meta("kind","airbase")
                airfield.set_meta("battle_cell",cell)
                parent.add_child(airfield)
                drawn+=1
                continue
        # Existing modern shipyard site is the NAVAL BASE on navigable water.
        # One sculpted native 3D visual replaces its generic gameplay cube.
        # No extra shipyard building or production rules are introduced.
        if str(site["kind"])=="shipyard":
            var port:Node3D=NavalBase3D.build_site(state,site,owner)
            if port!=null:
                port.name="Instalacion3D_shipyard_%d_%d" % [
                    cell.x,cell.y]
                port.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                port.set_meta("owner_public",owner)
                port.set_meta("kind","shipyard")
                port.set_meta("battle_cell",cell)
                parent.add_child(port)
                drawn+=1
                continue
        # Existing drone producer uses its real tactical 3D building.
        # No new site or drone production change; only public geometry.
        if str(site["kind"])=="drone_center":
            var drone_site:Node3D=DroneCenter3D.build_site(state,site,owner)
            if drone_site!=null:
                drone_site.name="Instalacion3D_drone_center_%d_%d" % [
                    cell.x,cell.y]
                drone_site.position=world_at(cell)+Vector3(
                    0,height_at(cells,cell)+0.07,0)
                drone_site.set_meta("owner_public",owner)
                drone_site.set_meta("kind","drone_center")
                drone_site.set_meta("battle_cell",cell)
                parent.add_child(drone_site)
                drawn+=1
                continue
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
        cells: Dictionary, selected_id: String, viewer: int = 0) -> Dictionary:
    var visible_count := 0
    var detailed := 0
    var apc_lod := 0
    var g11_lod := 0
    var g13_visible := 0
    var g13_lod8 := 0
    var hidden_enemies := 0
    var player: int = viewer
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
        if role=="apc":
            # Every visible P06 keeps its authentic 6x6 silhouette even
            # beyond the eight high-detail slots. Six tires are two GPU
            # batches and do not expand into hundreds of individual meshes.
            model = Models.build("apc",faction,false,8)
            if model!=null:
                apc_lod+=1
        elif role=="mobile_aa":
            # The playable G13 shares the approved V69 studio sculpt.
            # Convert the logical team to one of eight selected art factions.
            var art_faction: int = FactionIdentity.index_for(
                FactionIdentity.key_for(state,faction))
            if art_faction < 0:
                art_faction = faction
            # Eight premium Android LOD8 models per battle; further G13s
            # retain their authentic four-wheel LOD6 chassis.
            var g13_level: int = 8 if g13_lod8 < MAX_DETAILED_UNITS else 6
            model = Models.build(role,art_faction,true,g13_level)
            if model != null:
                model.set_meta("tarvoka_g13_game_role","mobile_aa")
                model.set_meta("tarvoka_g13_visual_faction",art_faction)
                g13_visible += 1
                if g13_level == 8:
                    g13_lod8 += 1
        elif role=="mlrs":
            # V25: the actual 3D battle camera must use the corrected V24
            # rounded tracks rather than a legacy G11 LOD6 box silhouette.
            # One logical unit, no hero art and never a gameplay mutation.
            model = Models.build("mlrs",faction,false,8)
            if model!=null and bool(model.get_meta(G11Tactical.FLAG,false)):
                g11_lod+=1
        elif role=="engineer" and detailed < MAX_DETAILED_UNITS:
            # The playable G05 role is `engineer`; its approved 3D identity
            # in the shared art roster is `infantry_engineer`. The map
            # previously drew an anonymous fallback disc because Models
            # does not expose a logical "engineer" art role.
            # Keep the same Android 8-detailed-unit budget and LOD8 meshes.
            # Neither state nor combat profile nor capture rules change.
            var engineer_faction: int = FactionIdentity.index_for(
                FactionIdentity.key_for(state,faction))
            if engineer_faction<0:
                engineer_faction=faction
            model=Models.build("infantry_engineer",engineer_faction,true,8)
            if model!=null:
                model.set_meta("tarvoka_engineer_game_role","engineer")
                model.set_meta("tarvoka_engineer_visual_faction",engineer_faction)
                detailed+=1
        elif detailed < MAX_DETAILED_UNITS and Models.supports(role):
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
        if role=="apc" and APCTactical.has_model(model):
            APCTactical.rebase(model)
        model.set_meta("visual_layer",Domains.layer(unit))
        model.set_meta("cell",cell)
        model.set_meta("faction",faction)
        model.set_meta("selected",str(unit["id"])==selected_id)
        parent.add_child(model)
        visible_count += 1
    return {"visible":visible_count,"detailed":detailed,
        "apc_lod":apc_lod,"g11_lod":g11_lod,
        "g13_visible":g13_visible,"g13_lod8":g13_lod8,
        "hidden_enemies":hidden_enemies}

static func build(state: Dictionary, selected_id: String = "", viewer: int = 0) -> Node3D:
    var biome: String = Biomes.from_state(state)
    var terrain: Array = state.get("terrain",[])
    if not Rules.valid_terrain(terrain):
        return null
    var scene := Node3D.new()
    scene.name = "MapaTactico3DReal"
    var dims: Vector2i = Rules.map_size(terrain)
    var use_fog: bool = Visibility.enabled(state)
    var explored: Dictionary = Visibility.explored_cells(state,viewer) if use_fog else {}
    var visible: Dictionary = Visibility.visible_cells(state,viewer) if use_fog else {}
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
    # One palette sample per global grid corner, reused by up to four
    # tiles and across 8x8 sectors. Cache only for this render build.
    var corner_cache: Dictionary = {}
    for chunk in chunks:
        var stats: Dictionary = _build_chunk(scene,chunk,cells,corner_cache,biome)
        for key in counters:
            counters[key] = int(counters[key])+int(stats[key])
    counters["trees"] = _make_cone_trees(scene,cells,biome)
    counters["mountain_ridges"] = _make_mountain_ridges(scene,cells,biome)
    counters["sites"] = _make_sites(scene,state,cells)
    # Automatic workshop LOD runs only on already instantiated public sites,
    # at 4 Hz, and never changes a tile/root or any gameplay object.
    var workshop_lod:Node=ArmoredWorkshopLOD.new()
    workshop_lod.name="TallerBlindadosLOD_Camara"
    var workshop_count:int=0
    for placed in scene.get_children():
        if placed is Node3D and str(placed.get_meta(
                "site_kind",""))=="armor_plant":
            if workshop_lod.register(placed as Node3D):
                workshop_count+=1
    if workshop_count>0:
        scene.add_child(workshop_lod)
    else:
        workshop_lod.free()
    counters["workshop_lod_models"]=workshop_count
    # Only already-visible, pre-existing airbase producer sites are managed.
    # Camera detail changes are strictly visual, never persisted to a save.
    var airbase_lod:Node=AirbaseLOD.new()
    airbase_lod.name="BaseAereaLOD_Camara"
    var airbase_count:int=0
    for placed in scene.get_children():
        if placed is Node3D and str(placed.get_meta(
                "site_kind",""))=="airbase":
            if airbase_lod.register(placed as Node3D):
                airbase_count+=1
    if airbase_count>0:
        scene.add_child(airbase_lod)
    else:
        airbase_lod.free()
    counters["airbase_lod_models"]=airbase_count
    var naval_lod:Node=NavalBaseLOD.new()
    naval_lod.name="BaseNavalLOD_Camara"
    var naval_count:int=0
    for placed in scene.get_children():
        if placed is Node3D and str(placed.get_meta(
                "site_kind",""))=="shipyard":
            if naval_lod.register(placed as Node3D):
                naval_count+=1
    if naval_count>0:
        scene.add_child(naval_lod)
    else:
        naval_lod.free()
    counters["naval_lod_models"]=naval_count
    var drone_lod:Node=DroneCenterLOD.new()
    drone_lod.name="CentroDronesLOD_Camara"
    var drone_count:int=0
    for placed in scene.get_children():
        if placed is Node3D and str(placed.get_meta(
                "site_kind",""))=="drone_center":
            if drone_lod.register(placed as Node3D):
                drone_count+=1
    if drone_count>0:
        scene.add_child(drone_lod)
    else:
        drone_lod.free()
    counters["drone_center_lod_models"]=drone_count
    counters["units"] = _make_units(scene,state,cells,selected_id,viewer)
    # Android-safe, 4 Hz dynamic LOD: only cities already visible to the
    # public viewer are registered. Model roots and selection cells persist.
    var city_lod: Node=CityDistance.new()
    city_lod.name="CiudadesCivilesV6_LOD_Camara"
    var city_count: int=0
    for placed in scene.get_children():
        if placed is Node3D and str(placed.get_meta("site_kind",""))=="city":
            city_lod.register(placed as Node3D)
            city_count+=1
    if city_count>0:
        scene.add_child(city_lod)
    else:
        city_lod.free()
    counters["city_lod_models"]=city_count
    counters["city_dynamic_lod"]=city_count>0
    # Camera-based LOD runs at 4 Hz AFTER the scene enters the viewport.
    # Headless battle/test scenes without a camera keep their stable V8 mesh.
    if int(counters["units"].get("apc_lod",0))>0:
        var lod_driver: Node=APCCameraLOD.new()
        lod_driver.name="P06V9_LOD_Camara"
        scene.add_child(lod_driver)
        for child in scene.get_children():
            if child is Node3D and bool(child.get_meta(
                    "tarvoka_apc_tactical_lod_v8",false)):
                lod_driver.register(child as Node3D)
        counters["apc_distance_lod"]=true
    else:
        counters["apc_distance_lod"]=false
    if int(counters["units"].get("g11_lod",0))>0:
        var g11_driver: Node=G11BattleLOD.new()
        g11_driver.name="G11V25_LOD_Camara"
        scene.add_child(g11_driver)
        for child in scene.get_children():
            if child is Node3D and bool(child.get_meta(
                    G11Tactical.FLAG,false)):
                g11_driver.register(child as Node3D)
        # Visual post-confirmation animation runs on the SAME visible model.
        # No extra units, BattleSession calls or changes to fog filtering.
        var g11_actions: Node=G11ActionsV29.new()
        g11_actions.name="G11V29_AccionesBatalla"
        scene.add_child(g11_actions)
        counters["g11_v29_visual_actions"]=true
        counters["g11_camera_lod"]=true
    else:
        counters["g11_camera_lod"]=false
        counters["g11_v29_visual_actions"]=false
    if int(counters["units"].get("g13_visible",0))>0:
        # Visual-only playback on visible models; never touches combat rules.
        var g13_actions: Node = G13ActionsV70.new()
        g13_actions.name = "G13V70_AccionesBatalla"
        scene.add_child(g13_actions)
        counters["g13_v70_visual_actions"] = true
    else:
        counters["g13_v70_visual_actions"] = false
    counters["chunks"] = chunks.size()
    # A shared vertex palette reuses the existing ground mesh/material;
    # no extra render batches for 24x18 or 40x30 mobile boards.
    counters["terrain_blend_extra_batches"] = 0
    counters["biome_extra_batches"] = (
        1 if counters["mountain_ridges"]>0 else 0) + (
        1 if biome==Biomes.WINTER and counters["trees"]>0 else 0)
    counters["terrain_blend_palette_samples"] = corner_cache.size()
    scene.set_meta("board_size",dims)
    scene.set_meta("viewer",viewer)
    scene.set_meta("visual_only",true)
    scene.set_meta("visual_biome",biome)
    scene.set_meta("public_cells",cells)
    scene.set_meta("render_stats",counters)
    scene.set_meta("selected_unit_id",selected_id)
    return scene
