extends RefCounted
class_name TarvokaTerrainStudioMountainBiomesV13

# V18 visual biome integration atop the EXISTING V10/V11 geometry.
# Three real scenes: wooded valley, dry canyon, humid coastal delta.
# Two grouped colour-geometry surfaces maximum. Never alter tactical cells,
# heights, water, bridges, roads, fog, collisions, movement or save data.
const Sampler = preload("res://scripts/ui/TerrainSurfaceSampler3D.gd")
const Spines = preload("res://scripts/ui/TerrainStudioRidgeV10.gd")
const Foothills = preload("res://scripts/ui/TerrainStudioFoothillsV11.gd")
const DIRECTIONS := [
    Vector2i(1,0),Vector2i(-1,0),
    Vector2i(0,1),Vector2i(0,-1)]

static func _hash(value: int) -> float:
    return float(posmod(value*4517+31013,65521))/65521.0

static func _stone(scene: int) -> Color:
    if scene == 1:
        return Color("#a18a74")
    return Color("#728783") if scene == 2 else Color("#788b80")

static func _ground(scene: int, kind: String) -> Color:
    if scene == 1:
        return Color("#b39c78") if kind == "forest" else Color("#c2a77f")
    if scene == 2:
        return Color("#577969") if kind == "forest" else Color("#779b86")
    return Color("#567a5b") if kind == "forest" else Color("#849a73")

static func _facet_tint(scene: int, point: Vector3, phase: float) -> Color:
    var mineral: Color = _stone(scene)
    var bands: float = sin(
        point.y*4.6+point.x*1.4+point.z*0.9+phase)
    var band_strength: float = 0.08+0.09*absf(bands)
    if scene == 1:
        return mineral.lerp(Color("#bda181"),band_strength*1.8).darkened(
            0.04 if bands < 0.0 else 0.0)
    if scene == 2:
        return mineral.lerp(Color("#506f6b"),band_strength*1.35).darkened(
            0.08 if point.y < 1.0 else 0.0)
    return mineral.lerp(Color("#64806c"),band_strength*1.3)

static func _transition_color(scene: int, kind: String,
        inward: float, position: Vector3, seed: int) -> Color:
    var rock: Color = _stone(scene)
    var soil: Color = _ground(scene,kind)
    # Same multi-scale world-space mineral grain across neighbouring cells.
    var noise: float = 0.5+0.5*sin(
        position.x*2.13+position.z*1.79+position.y*3.21)
    var blend: float = smoothstep(0.06,0.99,inward)
    var cover: Color = rock.lerp(soil,blend)
    if scene == 0 and kind == "forest":
        cover = cover.lerp(Color("#486a50"),0.10+0.11*noise*blend)
    elif scene == 1:
        cover = cover.lerp(Color("#d0b38c"),0.06+0.09*blend*noise)
    elif scene == 2:
        cover = cover.lerp(Color("#50746a"),0.06+0.12*(1.0-blend))
    var grain: float = (_hash(seed+41)-0.5)*0.040
    return cover.lightened(grain) if grain >= 0.0 else cover.darkened(-grain)

static func _tri(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,
        ca: Color,cb: Color,cc: Color) -> void:
    tool.set_color(ca)
    tool.add_vertex(a)
    tool.set_color(cb)
    tool.add_vertex(b)
    tool.set_color(cc)
    tool.add_vertex(c)

static func _finish(parent: Node3D,label: String,tool: SurfaceTool) -> void:
    tool.generate_normals()
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.99
    material.specular = 0.08
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    node.material_override = material
    node.set_meta("visual_only",true)
    parent.add_child(node)

static func _ridge_anchor(cell: Dictionary,at: Vector2,
        mountains: Dictionary,scene: int) -> Vector3:
    var half: float = float(cell["half"])
    var local := Vector2(
        clampf(at.x,-half+0.19,half-0.19),
        clampf(at.y,-half+0.19,half-0.19))
    var center: Vector3 = cell["center"]
    var surface_y: float = Sampler.height(
        float(cell["top"]),cell["corners"],
        local.x,local.y,half)
    var rise: float = Spines.uplift(cell,local,mountains,scene)
    return center+Vector3(local.x,surface_y+rise+0.045,local.y)

static func _ridge_facet(tool: SurfaceTool,cell: Dictionary,
        mountains: Dictionary,scene: int,seed: int) -> int:
    var id := Vector2i(int(cell["x"]),int(cell["z"]))
    var axis: Vector2 = Spines._spine_axis(id,mountains,seed)
    var tangent := Vector2(-axis.y,axis.x)
    var near: Array[Vector3] = []
    var far: Array[Vector3] = []
    for j in range(4):
        var t: float = lerpf(-0.74,0.74,float(j)/3.0)
        var bend: float = (_hash(seed+j*17)-0.5)*0.16
        var mid: Vector2 = axis*t+tangent*bend
        near.append(_ridge_anchor(cell,mid-tangent*0.17,mountains,scene))
        far.append(_ridge_anchor(cell,mid+tangent*0.17,mountains,scene))
    for j in range(3):
        var a: Vector3 = near[j]
        var b: Vector3 = near[j+1]
        var c: Vector3 = far[j]
        var d: Vector3 = far[j+1]
        var phase: float = float(seed%13)*0.31
        _tri(tool,a,b,c,_facet_tint(scene,a,phase),
            _facet_tint(scene,b,phase),_facet_tint(scene,c,phase))
        _tri(tool,b,d,c,_facet_tint(scene,b,phase),
            _facet_tint(scene,d,phase),_facet_tint(scene,c,phase))
    return 6

static func _apron_point(cell: Dictionary,mountain: Dictionary,
        face: Vector2,tangent: Vector2,along: float,
        inward: float,scene: int,mountains: Dictionary,seed: int) -> Vector3:
    # Match V11 mountain-contact geometry exactly, then sit above it:
    # this is a colour mantle over the existing foothill, not a new cliff.
    return Foothills._apron_vertex(
        cell,mountain,face,tangent,along,inward,scene,mountains,seed
    )+Vector3(0,0.028,0)

static func _mantle(tool: SurfaceTool,cell: Dictionary,
        mountain: Dictionary,direction: Vector2i,
        mountains: Dictionary,scene: int,seed: int) -> int:
    var face := Vector2(float(direction.x),float(direction.y))
    var tangent := Vector2(-face.y,face.x)
    var half: float = float(cell["half"])
    var rows: Array = []
    for inward in [0.16,0.40,0.67,0.90]:
        var row: Array = []
        for i in range(9):
            var along: float = lerpf(-half+0.23,half-0.23,float(i)/8.0)
            var position: Vector3 = _apron_point(cell,mountain,
                face,tangent,along,inward,scene,mountains,seed)
            row.append({"point":position,"color":_transition_color(
                scene,str(cell["kind"]),inward,position,seed+i*31)})
        rows.append(row)
    for j in range(3):
        for i in range(8):
            var a: Dictionary = rows[j][i]
            var b: Dictionary = rows[j][i+1]
            var c: Dictionary = rows[j+1][i]
            var d: Dictionary = rows[j+1][i+1]
            _tri(tool,a["point"],c["point"],b["point"],
                a["color"],c["color"],b["color"])
            _tri(tool,b["point"],c["point"],d["point"],
                b["color"],c["color"],d["color"])
    return 48

static func _ground_accent(tool: SurfaceTool,cell: Dictionary,
        mountain: Dictionary,direction: Vector2i,mountains: Dictionary,
        scene: int,seed: int) -> int:
    var face := Vector2(float(direction.x),float(direction.y))
    var tangent := Vector2(-face.y,face.x)
    # Dry canyon: a handful of angular scree fragments. Wooded valley:
    # dark green shrubs. Delta: lower blue-green coastal grasses.
    var pieces: int = 2 if scene == 1 else 3
    for i in range(pieces):
        var along: float = lerpf(-0.58,0.58,
            float(i)/float(maxi(1,pieces-1)))
        along += (_hash(seed+i*29)-0.5)*0.16
        var ground: Vector3 = _apron_point(cell,mountain,
            face,tangent,along,0.79,scene,mountains,seed)
        ground.y += 0.035
        var width: float = 0.085+0.032*_hash(seed+i*41)
        var height: float = (
            0.10+0.085*_hash(seed+i*53) if scene == 1 else
            0.17+0.12*_hash(seed+i*53))
        var a: Vector3 = ground+Vector3(
            tangent.x*width,0,tangent.y*width)
        var b: Vector3 = ground-Vector3(
            tangent.x*width,0,tangent.y*width)
        var tip: Vector3 = ground+Vector3(
            (_hash(seed+i*17)-0.5)*width,height,
            (_hash(seed+i*19)-0.5)*width)
        var tint: Color = (
            Color("#aa997d") if scene == 1 else
            Color("#638f7a") if scene == 2 else Color("#5b7855"))
        _tri(tool,a,b,tip,tint.darkened(0.20),
            tint.darkened(0.04),tint.lightened(0.09))
    return pieces

static func populate(parent: Node3D,cells: Array[Dictionary],
        scene: int,facets: bool = true,ecotones: bool = true) -> Dictionary:
    var mountains: Dictionary = {}
    for cell in cells:
        if str(cell["kind"]) == "mountain":
            mountains[Vector2i(int(cell["x"]),int(cell["z"]))] = cell
    var strata_tool := SurfaceTool.new()
    strata_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var habitat_tool := SurfaceTool.new()
    habitat_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var mountain_facets := 0
    var mantle_triangles := 0
    var accents := 0
    var edges := 0
    var road_protected := 0
    var water_protected := 0
    for cell in cells:
        var kind: String = str(cell["kind"])
        var id := Vector2i(int(cell["x"]),int(cell["z"]))
        if kind == "road":
            road_protected += 1
            continue
        if kind == "water":
            water_protected += 1
            continue
        var seed: int = id.x*227+id.y*619+scene*179
        if kind == "mountain":
            if facets:
                mountain_facets += _ridge_facet(
                    strata_tool,cell,mountains,scene,seed)
            continue
        if kind not in ["plain","forest"]:
            continue
        for direction in DIRECTIONS:
            var other: Vector2i = id+direction
            if not mountains.has(other):
                continue
            edges += 1
            # Reuse the V11 seed so the colour layer rests precisely on
            # the real V11 apron geometry instead of a flat tile.
            var edge_seed: int = seed+direction.x*109+direction.y*61
            if facets:
                mantle_triangles += _mantle(
                    strata_tool,cell,mountains[other],direction,
                    mountains,scene,edge_seed)
            if ecotones:
                accents += _ground_accent(
                    habitat_tool,cell,mountains[other],direction,
                    mountains,scene,edge_seed)
    var batches := 0
    if facets and mountain_facets+mantle_triangles>0:
        _finish(parent,"EstratosYTaludesBiomaV13",strata_tool)
        batches += 1
    if ecotones and accents>0:
        _finish(parent,"VegetacionYPedregalBiomaV13",habitat_tool)
        batches += 1
    var stats := {
        "scene":scene,
        "mountain_cells":mountains.size(),
        "mountain_edges":edges,
        "ridge_facets":mountain_facets,
        "mantle_triangles":mantle_triangles,
        "ecotone_pieces":accents,
        "water_cells_skipped":water_protected,
        "road_cells_skipped":road_protected,
        "batches":batches}
    parent.set_meta("terrain_mountain_biomes_v13",stats)
    return stats
