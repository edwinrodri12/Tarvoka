extends RefCounted
class_name TarvokaTerrain3DMesh

# First native 3D environment module for TARVOKA. Uses existing 2D tactical
# terrain as READ-ONLY input, then creates independent, continuous 3D geometry.
# No physics bodies, pathfinding, collision map or gameplay height changes.
const BASE_HEIGHTS := {
    "plain":0.20, "forest":0.32, "road":0.12,
    "mountain":0.96, "water":-0.48
}
const BASE_TINTS := {
    "plain":"#748C52","forest":"#305F47","road":"#858071",
    "mountain":"#62757E","water":"#486C6E"
}
const WATER_LEVEL := 0.075
const Regions = preload("res://scripts/ui/LandscapeRegions.gd")
const Topology = preload("res://scripts/ui/TerrainTopology.gd")
const RockMaterials = preload("res://scripts/ui/TerrainRockMaterials.gd")

static func inside(grid: Array, cell: Vector2i) -> bool:
    return cell.y >= 0 and cell.y < grid.size() and (
        grid[cell.y] is Array) and cell.x >= 0 and (
        cell.x < (grid[cell.y] as Array).size())

static func observed_cell(grid: Array, cell: Vector2i,
        observed: Dictionary = {}, restricted: bool = false) -> bool:
    return inside(grid,cell) and (not restricted or observed.has(cell))

# Reserved for the future camera ray hit-test. Every 3D ground position
# resolves to the SAME logical grid tile as the existing tactical engine.
# Camera, lighting and decorative elevation never change these indices.
static func tactical_cell_from_world(grid: Array, world: Vector3) -> Vector2i:
    var cell := Vector2i(floori(world.x),floori(world.z))
    return cell if inside(grid,cell) else Vector2i(-1,-1)

static func tactical_cell_center(grid: Array, cell: Vector2i,
        observed: Dictionary = {}, restricted: bool = false) -> Vector3:
    if not observed_cell(grid,cell,observed,restricted):
        return Vector3(-1,-1,-1)
    return Vector3(float(cell.x)+0.5,
        height_at(grid,cell,0.5,0.5,observed,restricted),
        float(cell.y)+0.5)

static func base_height(kind: String) -> float:
    return float(BASE_HEIGHTS.get(kind,0.20))

static func corner_height(grid: Array, corner: Vector2i,
        observed: Dictionary = {}, restricted: bool = false) -> float:
    var total := 0.0
    var samples := 0
    for dy in [-1,0]:
        for dx in [-1,0]:
            var tile := corner+Vector2i(dx,dy)
            if not observed_cell(grid,tile,observed,restricted):
                continue
            total += base_height(str(grid[tile.y][tile.x]))
            samples += 1
    return total/float(samples) if samples > 0 else 0.0

static func height_at(grid: Array, cell: Vector2i, u: float, v: float,
        observed: Dictionary = {}, restricted: bool = false) -> float:
    if not observed_cell(grid,cell,observed,restricted):
        return 0.0
    u = clampf(u,0.0,1.0)
    v = clampf(v,0.0,1.0)
    var h00: float = corner_height(grid,cell,observed,restricted)
    var h10: float = corner_height(grid,cell+Vector2i(1,0),observed,restricted)
    var h01: float = corner_height(grid,cell+Vector2i(0,1),observed,restricted)
    var h11: float = corner_height(grid,cell+Vector2i(1,1),observed,restricted)
    var interpolated: float = lerpf(lerpf(h00,h10,u),lerpf(h01,h11,u),v)
    var kind: String = str(grid[cell.y][cell.x])
    var center_bump: float = sin(u*PI)*sin(v*PI)
    if kind == "mountain":
        # Use only KNOWN adjacent mountain cells for summit grouping,
        # never hidden terrain. Most connected mountain cells are a low
        # plateau with a few isolated high peaks, not a grid of cones.
        var known_links: int = Topology.neighbor_mask(
            grid,cell,"mountain",true,observed,restricted)
        var summit: float = Regions.summit_strength(cell,known_links)
        var crest: float = maxf(0.08,(summit-0.38)*3.1)
        # Elongated folds flow across the world rather than separate
        # circular cones. Shared world coordinates vary the main ridge
        # direction, while the envelope still vanishes at each tile edge.
        var world_x: float = float(cell.x)+u
        var world_z: float = float(cell.y)+v
        var ridge_line: float = sin(
            world_x*0.78-world_z*0.44+0.46*sin(world_z*0.67))
        var folds: float = 0.69+0.31*absf(ridge_line)
        folds *= 0.88+0.12*cos(world_x*4.1+world_z*5.9)
        var weathering: float = sin(
            world_x*9.3+world_z*6.2)*0.025*crest
        # The exact-zero edge envelope keeps the native mesh crack-free.
        # World-space strata and colors are applied separately below.
        return interpolated+pow(center_bump,0.78)*(
            crest*folds+weathering)
    if kind == "water":
        # A river bed rises continuously towards adjacent terrain.
        return interpolated-center_bump*0.32
    var noise: float = sin((float(cell.x)+u)*7.2+(
        float(cell.y)+v)*4.4)*sin(u*PI)*sin(v*PI)
    if kind == "forest":
        return interpolated+0.09*center_bump+noise*0.030
    if kind == "road":
        return interpolated-noise*0.006
    return interpolated+noise*0.035

static func _color_for(grid: Array, cell: Vector2i, u: float, v: float,
        elevation: float) -> Color:
    var kind: String = str(grid[cell.y][cell.x])
    var tint: Color = Color.html(str(BASE_TINTS.get(
        kind,BASE_TINTS["plain"])))
    var world := Vector3(float(cell.x)+u,elevation,float(cell.y)+v)
    # Rock minerals and fine strata are sampled in WORLD coordinates,
    # not per-tile UVs. Adjacent mountain triangles share the same palette
    # and do not restart their fractures at an artificial grid boundary.
    if kind == "mountain":
        return RockMaterials.rock_color(world,0.82)
    if kind == "water":
        tint = Color("#526A6F")
    return RockMaterials.grass_edge_color(world,kind,tint)
static func _add_vertex(st: SurfaceTool, point: Vector3, tint: Color) -> void:
    st.set_color(tint)
    st.add_vertex(point)

static func _ground_point(grid: Array, cell: Vector2i, u: float, v: float,
        observed: Dictionary, restricted: bool) -> Vector3:
    return Vector3(float(cell.x)+u,
        height_at(grid,cell,u,v,observed,restricted),
        float(cell.y)+v)

static func build_ground(grid: Array, observed: Dictionary = {},
        restricted: bool = false, divisions: int = 5) -> ArrayMesh:
    var mesh := ArrayMesh.new()
    if divisions < 1:
        return mesh
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count := 0
    for y in range(grid.size()):
        if not (grid[y] is Array):
            continue
        for x in range((grid[y] as Array).size()):
            var cell := Vector2i(x,y)
            if not observed_cell(grid,cell,observed,restricted):
                continue
            for j in range(divisions):
                for i in range(divisions):
                    var u0: float = float(i)/float(divisions)
                    var u1: float = float(i+1)/float(divisions)
                    var v0: float = float(j)/float(divisions)
                    var v1: float = float(j+1)/float(divisions)
                    var p00 := _ground_point(grid,cell,u0,v0,observed,restricted)
                    var p10 := _ground_point(grid,cell,u1,v0,observed,restricted)
                    var p01 := _ground_point(grid,cell,u0,v1,observed,restricted)
                    var p11 := _ground_point(grid,cell,u1,v1,observed,restricted)
                    # Winding order produces upward-facing normals.
                    _add_vertex(st,p00,_color_for(grid,cell,u0,v0,p00.y))
                    _add_vertex(st,p01,_color_for(grid,cell,u0,v1,p01.y))
                    _add_vertex(st,p10,_color_for(grid,cell,u1,v0,p10.y))
                    _add_vertex(st,p10,_color_for(grid,cell,u1,v0,p10.y))
                    _add_vertex(st,p01,_color_for(grid,cell,u0,v1,p01.y))
                    _add_vertex(st,p11,_color_for(grid,cell,u1,v1,p11.y))
                    count += 6
    if count == 0:
        return mesh
    st.generate_normals()
    st.commit(mesh)
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.96
    # Godot treats the top-down grid face winding differently from a
    # conventional right-handed x/z heightfield. Two-sided shading avoids
    # dropping the entire flat landscape while keeping smooth +Y normals.
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.surface_set_material(0,material)
    return mesh

static func _neighbor_water(grid: Array, cell: Vector2i, direction: int,
        observed: Dictionary, restricted: bool) -> bool:
    const SHIFTS := [
        Vector2i(0,-1),Vector2i(1,0),
        Vector2i(0,1),Vector2i(-1,0)
    ]
    var target: Vector2i = cell+SHIFTS[direction]
    return observed_cell(grid,target,observed,restricted) and (
        str(grid[target.y][target.x]) == "water")

static func water_outline(grid: Array, cell: Vector2i,
        observed: Dictionary = {}, restricted: bool = false,
        divisions: int = 8) -> PackedVector2Array:
    var outline := PackedVector2Array()
    if not observed_cell(grid,cell,observed,restricted) or (
            str(grid[cell.y][cell.x]) != "water") or divisions < 2:
        return outline
    for side in range(4):
        var border: Vector2i = [
            Vector2i(0,-1),Vector2i(1,0),
            Vector2i(0,1),Vector2i(-1,0)
        ][side]
        var next_cell: Vector2i = cell+border
        var has_visible_land: bool = observed_cell(
            grid,next_cell,observed,restricted) and not (
            _neighbor_water(grid,cell,side,observed,restricted))
        for index in range(divisions):
            var t: float = float(index)/float(divisions)
            var u := 0.0
            var v := 0.0
            match side:
                0:
                    u = t
                1:
                    u = 1.0
                    v = t
                2:
                    u = 1.0-t
                    v = 1.0
                _:
                    v = 1.0-t
            if has_visible_land:
                # Retract into the river locally: shallow, uneven edges
                # without holes on water-water seams or under fog.
                var ripple: float = sin((t+float(cell.x)*0.31+
                    float(cell.y)*0.17)*TAU*1.6)
                var inset: float = 0.075+0.036*ripple
                match side:
                    0:
                        v = inset
                    1:
                        u = 1.0-inset
                    2:
                        v = 1.0-inset
                    _:
                        u = inset
            outline.append(Vector2(float(cell.x)+u,
                float(cell.y)+v))
    return outline

static func build_water(grid: Array, observed: Dictionary = {},
        restricted: bool = false, divisions: int = 8) -> ArrayMesh:
    var mesh := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var triangles := 0
    for y in range(grid.size()):
        if not (grid[y] is Array):
            continue
        for x in range((grid[y] as Array).size()):
            var cell := Vector2i(x,y)
            var outline: PackedVector2Array = water_outline(
                grid,cell,observed,restricted,divisions)
            if outline.is_empty():
                continue
            var center := Vector3(float(x)+0.5,WATER_LEVEL,float(y)+0.5)
            for j in range(outline.size()):
                var a: Vector2 = outline[j]
                var b: Vector2 = outline[(j+1)%outline.size()]
                # Top view perimeter order is clockwise in x/z, so
                # center -> b -> a makes the normal face +y.
                _add_vertex(st,center,Color("#5AAEC4"))
                _add_vertex(st,Vector3(b.x,WATER_LEVEL,b.y),Color("#81CDDA"))
                _add_vertex(st,Vector3(a.x,WATER_LEVEL,a.y),Color("#81CDDA"))
                triangles += 1
    if triangles == 0:
        return mesh
    st.generate_normals()
    st.commit(mesh)
    var water := StandardMaterial3D.new()
    water.vertex_color_use_as_albedo = true
    water.albedo_color = Color(0.72,0.92,1.0,0.82)
    water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water.roughness = 0.21
    water.metallic = 0.08
    water.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.surface_set_material(0,water)
    return mesh
