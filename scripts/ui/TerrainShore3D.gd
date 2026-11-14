extends RefCounted
class_name TarvokaTerrainShore3D

# Purely decorative shoreline geometry. The tactical grid and existing
# water/land meshes remain authoritative and untouched. The beach strip
# stays INSIDE each known land cell; never reads a fogged neighbor.
const Terrain = preload("res://scripts/ui/Terrain3DMesh.gd")
const SIDES := [
    Vector2i(0,-1),Vector2i(1,0),
    Vector2i(0,1),Vector2i(-1,0)
]

static func bank_strip(grid: Array, land_cell: Vector2i,
        side: int, observed: Dictionary = {},
        restricted: bool = false, segments: int = 8) -> PackedVector3Array:
    var points := PackedVector3Array()
    if segments < 2 or side < 0 or side >= 4 or not (
            Terrain.observed_cell(grid,land_cell,observed,restricted)):
        return points
    var kind: String = str(grid[land_cell.y][land_cell.x])
    if kind not in ["plain","forest","mountain"]:
        return points
    var neighbor: Vector2i = land_cell+SIDES[side]
    if not Terrain.observed_cell(grid,neighbor,observed,restricted):
        return points
    # Recognized decorative bridges count as continuous water only when
    # all crossing neighbors are observed. A fogged tile never reveals it.
    if not Terrain._neighbor_water(
            grid,land_cell,side,observed,restricted):
        return points
    for i in range(segments+1):
        var t: float = float(i)/float(segments)
        var u: float = 0.0
        var v: float = 0.0
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
        var amplitude: float = sin(t*PI)
        var world_x: float = float(land_cell.x)+u
        var world_z: float = float(land_cell.y)+v
        var variation: float = sin(world_x*7.8+world_z*3.1)
        var width: float = amplitude*(0.14+0.041*variation)
        var inland_u: float = u
        var inland_v: float = v
        match side:
            0:
                inland_v += width
            1:
                inland_u -= width
            2:
                inland_v -= width
            _:
                inland_u += width
        # The top coat hugs the actual heightfield, rather than lying
        # at river level and cutting through sloped forest terrain.
        var edge_y: float = Terrain.height_at(grid,land_cell,
            u,v,observed,restricted)
        var inner_y: float = Terrain.height_at(grid,land_cell,
            inland_u,inland_v,observed,restricted)
        points.append(Vector3(world_x,edge_y+0.024,world_z))
        points.append(Vector3(float(land_cell.x)+inland_u,
            inner_y+0.026,float(land_cell.y)+inland_v))
    return points

static func build_banks(grid: Array, observed: Dictionary = {},
        restricted: bool = false, segments: int = 8) -> ArrayMesh:
    var result := ArrayMesh.new()
    if segments < 2:
        return result
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var triangles := 0
    for y in range(grid.size()):
        if not (grid[y] is Array):
            continue
        for x in range((grid[y] as Array).size()):
            var cell := Vector2i(x,y)
            if not Terrain.observed_cell(grid,cell,observed,restricted):
                continue
            var kind: String = str(grid[y][x])
            for side in range(4):
                var band: PackedVector3Array = bank_strip(
                    grid,cell,side,observed,restricted,segments)
                if band.is_empty():
                    continue
                for index in range(segments):
                    var a: Vector3 = band[index*2]
                    var b: Vector3 = band[index*2+1]
                    var c: Vector3 = band[(index+1)*2]
                    var d: Vector3 = band[(index+1)*2+1]
                    var grain: float = sin(
                        a.x*8.1+a.z*5.9+a.y*2.1)
                    var waterline: Color = Color("#718482") if (
                        kind == "mountain") else Color("#788676")
                    var upper: Color = Color("#939B8E") if (
                        kind == "mountain") else Color("#8E8C71")
                    waterline = waterline.lightened(0.034*grain)
                    upper = upper.darkened(0.035*grain)
                    for vertex in [a,b,c,c,b,d]:
                        st.set_color(waterline if (
                            vertex == a or vertex == c) else upper)
                        st.add_vertex(vertex)
                    triangles += 2
    if triangles == 0:
        return result
    st.index()
    st.generate_normals(true)
    st.commit(result)
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 1.0
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    result.surface_set_material(0,material)
    return result
