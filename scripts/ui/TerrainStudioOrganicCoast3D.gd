extends RefCounted
class_name TarvokaTerrainOrganicCoast3D

# Standalone visual detail pass: water/shore geometry in the WebGL studio.
# Does not alter the tactical WATER tile type, movement or pathfinding.
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")
const Textures = preload("res://scripts/ui/TerrainTextures3D.gd")
const BANK := Color("#aa9f81")
const WET_SAND := Color("#868f80")
const SHALLOWS := Color("#478da1")
const DEEP := Color("#337b96")
const SURF := Color("#6caeb3")

static func _noise(a: int, b: int, salt: int) -> float:
    return float(posmod(a*191+b*293+salt*419,1009)) / 1009.0

static func _vertex(tool: SurfaceTool, p: Vector3, tint: Color) -> void:
    tool.set_color(tint)
    tool.set_uv(Vector2(p.x*0.31+p.y*0.018,p.z*0.31))
    tool.add_vertex(p)

static func _quad(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, d: Vector3, ca: Color, cb: Color,
        cc: Color, cd: Color) -> void:
    _vertex(tool,a,ca)
    _vertex(tool,c,cc)
    _vertex(tool,b,cb)
    _vertex(tool,b,cb)
    _vertex(tool,c,cc)
    _vertex(tool,d,cd)

static func _local_offset(direction: Vector2i,
        across: float, along: float) -> Vector2:
    if direction.x != 0:
        return Vector2(float(direction.x)*across,along)
    return Vector2(along,float(direction.y)*across)

static func _shore_point(x: int, z: int, scene: int,
        local: Vector2, land: bool) -> Vector3:
    var center: Vector3 = Terrain._cell_center(x,z)
    var elevation: float = Terrain.surface_height_at(
        x,z,scene,local.x,local.y) + 0.025 if land else (
            Terrain.WATER_LEVEL + 0.028)
    return center+Vector3(local.x,elevation,local.y)

static func _coast(parent: Node3D, scene: int) -> Dictionary:
    var shore := SurfaceTool.new()
    shore.begin(Mesh.PRIMITIVE_TRIANGLES)
    var wet := SurfaceTool.new()
    wet.begin(Mesh.PRIMITIVE_TRIANGLES)
    var edge_count: int = 0
    var triangles: int = 0
    var half: float = Terrain.CELL*0.5
    var sides: Array[Vector2i] = [
        Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
    for z in range(Terrain.HEIGHT):
        for x in range(Terrain.WIDTH):
            var biome: String = Terrain.kind(x,z,scene)
            if biome in ["water","outside"]:
                continue
            for direction in sides:
                if Terrain.kind(x+direction.x,z+direction.y,scene) != "water":
                    continue
                edge_count += 1
                var seed: int = x*37+z*113+direction.x*17+direction.y*29
                for index in range(14):
                    var t0: float = float(index)/14.0
                    var t1: float = float(index+1)/14.0
                    var along_a: float = (t0-0.5)*Terrain.CELL*0.97
                    var along_b: float = (t1-0.5)*Terrain.CELL*0.97
                    var variation_a: float = sin(t0*TAU*2.0+float(seed)*0.11)*0.08
                    variation_a += (_noise(seed,index,4)-0.5)*0.08
                    var variation_b: float = sin(t1*TAU*2.0+float(seed)*0.11)*0.08
                    variation_b += (_noise(seed,index+1,4)-0.5)*0.08
                    # The landward edge meanders, breaking the straight
                    # shoreline silhouette without modifying gameplay tiles.
                    var bank_a: float = half-0.33+variation_a
                    var bank_b: float = half-0.33+variation_b
                    var outer_a: float = half+0.10+variation_a*0.55
                    var outer_b: float = half+0.10+variation_b*0.55
                    var fade_a: float = half+0.23+variation_a*0.55
                    var fade_b: float = half+0.23+variation_b*0.55
                    var inner0: Vector3 = _shore_point(x,z,scene,
                        _local_offset(direction,bank_a,along_a),true)
                    var inner1: Vector3 = _shore_point(x,z,scene,
                        _local_offset(direction,bank_b,along_b),true)
                    var outside0: Vector3 = _shore_point(x,z,scene,
                        _local_offset(direction,outer_a,along_a),false)
                    var outside1: Vector3 = _shore_point(x,z,scene,
                        _local_offset(direction,outer_b,along_b),false)
                    var fade0: Vector3 = _shore_point(x,z,scene,
                        _local_offset(direction,fade_a,along_a),false)
                    var fade1: Vector3 = _shore_point(x,z,scene,
                        _local_offset(direction,fade_b,along_b),false)
                    var grain: float = _noise(seed,index,12)
                    var drier: Color = BANK.lerp(Color("#c3ae88"),grain*0.12)
                    var muddy: Color = WET_SAND.lerp(BANK,0.17+grain*0.11)
                    _quad(shore,inner0,inner1,outside0,outside1,
                        drier,drier,muddy,muddy)
                    var wet_a: Color = SHALLOWS.lerp(WET_SAND,0.16)
                    _quad(wet,outside0,outside1,fade0,fade1,
                        wet_a,wet_a,DEEP,DEEP)
                    triangles += 4
    if edge_count == 0:
        return {"edges":0,"triangles":0}
    shore.generate_normals()
    shore.generate_tangents()
    wet.generate_normals()
    wet.generate_tangents()
    var bank := MeshInstance3D.new()
    bank.name = "RiberaEsculpidaV5"
    bank.mesh = shore.commit()
    bank.material_override = Textures.material("sand",Color.WHITE,true)
    parent.add_child(bank)
    var blending := MeshInstance3D.new()
    blending.name = "TransicionAguaSomeraV5"
    blending.mesh = wet.commit()
    blending.material_override = Textures.material("water",Color.WHITE,true)
    parent.add_child(blending)
    return {"edges":edge_count,"triangles":triangles}

static func _subtle_ripples(parent: Node3D, scene: int) -> int:
    # Sparse short curved highlights, in contrast to a grid of bright dashes.
    var lines := SurfaceTool.new()
    lines.begin(Mesh.PRIMITIVE_TRIANGLES)
    var pieces: int = 0
    for z in range(Terrain.HEIGHT):
        for x in range(Terrain.WIDTH):
            if Terrain.kind(x,z,scene) != "water":
                continue
            var seed: int = x*67+z*131
            if posmod(seed,3) != 0:
                continue
            var center: Vector3 = Terrain._cell_center(x,z)
            var ox: float = (_noise(seed,2,4)-0.5)*1.3
            var oz: float = (_noise(seed,3,5)-0.5)*1.3
            var theta: float = (_noise(seed,5,7)-0.5)*0.9
            var previous_left: Vector3 = Vector3.ZERO
            var previous_right: Vector3 = Vector3.ZERO
            for i in range(9):
                var t: float = float(i)/8.0
                var d: float = (t-0.5)*(0.43+_noise(seed,1,8)*0.45)
                var curve: float = 0.08*sin(t*PI)
                var xlocal: float = ox+d*cos(theta)-curve*sin(theta)
                var zlocal: float = oz+d*sin(theta)+curve*cos(theta)
                var wid: float = maxf(0.002,0.018*sin(t*PI))
                var at: Vector3 = center+Vector3(xlocal,
                    Terrain.WATER_LEVEL+0.038,zlocal)
                var side := Vector3(-sin(theta),0,cos(theta))*wid
                var left: Vector3 = at-side
                var right: Vector3 = at+side
                if i>0:
                    var blue: Color = SHALLOWS.lerp(SURF,0.13)
                    _quad(lines,previous_left,previous_right,left,right,
                        blue,blue,blue,blue)
                    pieces += 1
                previous_left = left
                previous_right = right
    if pieces > 0:
        lines.generate_normals()
        var ripples := MeshInstance3D.new()
        ripples.name = "DestellosDeMareaV5"
        ripples.mesh = lines.commit()
        var mat := StandardMaterial3D.new()
        mat.vertex_color_use_as_albedo = true
        mat.roughness = 0.31
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED
        ripples.material_override = mat
        parent.add_child(ripples)
    return pieces

static func apply(root: Node3D, scene: int) -> Dictionary:
    var props: Node3D = root.get_node_or_null(
        "RelieveVegetacionYDetalles") as Node3D
    if props == null:
        return {}
    var suppressed: int = 0
    for node in props.get_children():
        if not (node is MeshInstance3D):
            continue
        var item: MeshInstance3D = node as MeshInstance3D
        var label: String = str(item.name)
        if label == "OndasYLitoralV4" or label == "OrillaNatural" or (
                label.begins_with("OrillaConPendienteV3_")):
            item.visible = false
            suppressed += 1
    var shore_stats: Dictionary = _coast(props,scene)
    shore_stats["ripples"] = _subtle_ripples(props,scene)
    shore_stats["suppressed"] = suppressed
    root.set_meta("terrain_organic_coast_v5",true)
    root.set_meta("terrain_coast_v5_stats",shore_stats)
    return shore_stats
