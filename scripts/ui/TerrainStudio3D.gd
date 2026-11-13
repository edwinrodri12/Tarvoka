extends RefCounted
class_name TarvokaTerrainStudio3D

# Geometry-only terrain samples for the native Godot Web studio.
# Logical cells remain 2D Vector2i. This class does not alter travel costs,
# tactical height, fog-of-war, map saves or Android battle rendering.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const WIDTH := 12
const HEIGHT := 10
const CELL := 2.40
const SCENES := ["Valle boscoso", "Canon rocoso", "Delta costero"]
const WATER := Color("#337b96")
const FOAM := Color("#98d5dc")
const ROAD := Color("#5a6264")
const ROAD_EDGE := Color("#ada18d")
const MARKER := Color("#e6d9aa")
const GRASS := Color("#668868")
const GRASS_LIGHT := Color("#829a70")
const SAND := Color("#bb9e74")
const MOSS := Color("#648677")
const ROCK := Color("#647681")
const ROCK_LIGHT := Color("#9ca8a6")
const SNOW := Color("#d7dfdc")
const COAST := Color("#c5b792")
const DEEP_WATER := Color("#22465e")
const WATER_LEVEL := -0.17
const BASE_LEVEL := -0.73
static var _materials: Dictionary = {}

static func _material(color: Color, rough: float = 0.89) -> StandardMaterial3D:
    var key: String = color.to_html(true) + "/" + str(rough)
    if _materials.has(key):
        return _materials[key]
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mat.metallic = 0.0
    _materials[key] = mat
    return mat

static func _box(parent: Node3D, label: String, center: Vector3,
        size: Vector3, tint: Color) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = mesh
    item.position = center
    item.material_override = _material(tint)
    parent.add_child(item)
    return item

static func _cone(parent: Node3D, label: String, center: Vector3,
        bottom_radius: float, height: float, tint: Color, sides: int = 7) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = bottom_radius
    mesh.height = height
    mesh.radial_segments = sides
    mesh.rings = 1
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = mesh
    item.position = center
    item.material_override = _material(tint)
    parent.add_child(item)
    return item

static func _cylinder(parent: Node3D, label: String, center: Vector3,
        radius: float, height: float, tint: Color) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 6
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = mesh
    item.position = center
    item.material_override = _material(tint)
    parent.add_child(item)
    return item

static func kind(x: int, z: int, scene: int) -> String:
    if x < 0 or z < 0 or x >= WIDTH or z >= HEIGHT:
        return "outside"
    match scene:
        0:
            if (x >= 9 and z >= 4 and z <= 8) or (x == 8 and z == 6):
                return "water"
            if (x <= 2 and z <= 3) or (x >= 9 and z <= 2):
                return "mountain"
            if x == 5 or z == 5:
                return "road"
            if (x <= 3 and z >= 6) or (x >= 6 and x <= 8 and z <= 3):
                return "forest"
        1:
            # Narrow causeway links the actual bridge deck in this visual sample.
            if z == 5 and x in [3,6,7]:
                return "road"
            var river_left: int = 3 + int(z / 3)
            if z >= 1 and z <= 8 and (x == river_left or x == river_left + 1):
                return "water"
            if x <= 2 or (x >= 9 and z <= 4):
                return "mountain"
            if x == 8 or z == 8:
                return "road"
            if x == 7 and z <= 3:
                return "forest"
        2:
            if x >= 9 or (x <= 2 and z <= 3) or (x == 8 and z >= 4 and z <= 6):
                return "water"
            if x == 5 or z == 7:
                return "road"
            if (x <= 4 and z >= 4) or (x >= 6 and z <= 3):
                return "forest"
            if x == 7 and z == 8:
                return "mountain"
    return "plain"

static func height_at(x: int, z: int, scene: int) -> float:
    var type: String = kind(x,z,scene)
    if type == "water":
        return -0.17
    if type == "mountain":
        return 0.62 + float(posmod(x*3 + z*7,5)) * 0.10
    if type == "road":
        return 0.14
    return 0.17 + float(posmod(x*11 + z*5,4)) * 0.025

static func _cell_center(x: int, z: int) -> Vector3:
    return Vector3((float(x) - float(WIDTH-1)*0.5)*CELL,0,
        (float(z) - float(HEIGHT-1)*0.5)*CELL)

static func _ground_tint(type: String, scene: int, seed: int) -> Color:
    var tint: Color = ROCK if type == "mountain" else (
        ROAD_EDGE if type == "road" else (
        MOSS if scene == 2 else SAND if scene == 1 else GRASS))
    if type in ["plain","forest"]:
        tint = tint.lightened(float(posmod(seed,6))*0.018)
    if type == "forest":
        tint = tint.darkened(0.065)
    return tint

static func _vertex_height(grid_x: int, grid_z: int, scene: int) -> float:
    # A shared corner function is essential: every neighboring land cell
    # uses precisely the same vertex and cannot open a crack in the ground.
    var sum: float = 0.0
    var neighbors: int = 0
    var near_road: bool = false
    for dz in [-1,0]:
        for dx in [-1,0]:
            var x: int = grid_x+dx
            var z: int = grid_z+dz
            var biome: String = kind(x,z,scene)
            if biome == "outside" or biome == "water":
                continue
            sum += height_at(x,z,scene)
            neighbors += 1
            near_road = near_road or biome == "road"
    if neighbors == 0:
        return WATER_LEVEL
    var average: float = sum / float(neighbors)
    # The road is a flattened cut through the ridge, not a floating slab.
    return minf(average,0.235) if near_road else average

static func _vertex_tint(grid_x: int, grid_z: int, scene: int) -> Color:
    var result := Color(0,0,0,0)
    var neighbors: int = 0
    for dz in [-1,0]:
        for dx in [-1,0]:
            var x: int = grid_x+dx
            var z: int = grid_z+dz
            var biome: String = kind(x,z,scene)
            if biome == "outside" or biome == "water":
                continue
            result += _ground_tint(biome,scene,x*29+z*43)
            neighbors += 1
    if neighbors == 0:
        return SAND
    return result * (1.0 / float(neighbors))

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
    # Deliberately unindexed: faceted normals describe readable low-poly relief.
    surface.set_color(ca)
    surface.set_uv(Vector2(a.x*0.05,a.z*0.05))
    surface.add_vertex(a)
    surface.set_color(cb)
    surface.set_uv(Vector2(b.x*0.05,b.z*0.05))
    surface.add_vertex(b)
    surface.set_color(cc)
    surface.set_uv(Vector2(c.x*0.05,c.z*0.05))
    surface.add_vertex(c)

static func _continuous_ground(parent: Node3D, scene: int) -> void:
    var land := SurfaceTool.new()
    land.begin(Mesh.PRIMITIVE_TRIANGLES)
    var water := SurfaceTool.new()
    water.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in range(HEIGHT):
        for x in range(WIDTH):
            var biome: String = kind(x,z,scene)
            var center: Vector3 = _cell_center(x,z)
            var half: float = CELL*0.5
            if biome == "water":
                var a := center+Vector3(-half,WATER_LEVEL,-half)
                var b := center+Vector3(half,WATER_LEVEL,-half)
                var d := center+Vector3(half,WATER_LEVEL,half)
                var e := center+Vector3(-half,WATER_LEVEL,half)
                for triangle in [[a,e,b],[b,e,d]]:
                    _triangle(water,triangle[0],triangle[1],triangle[2],
                        WATER,WATER,WATER)
                continue
            var corners: Array[Vector3] = [
                center+Vector3(-half,0,-half),
                center+Vector3(half,0,-half),
                center+Vector3(half,0,half),
                center+Vector3(-half,0,half)]
            var shades: Array[Color] = []
            for i in range(4):
                var dx: int = 1 if i == 1 or i == 2 else 0
                var dz: int = 1 if i >= 2 else 0
                var corner: Vector3 = corners[i]
                corner.y = _vertex_height(x+dx,z+dz,scene)
                corners[i] = corner
                shades.append(_vertex_tint(x+dx,z+dz,scene))
            center.y = height_at(x,z,scene)
            var face_color: Color = _ground_tint(biome,scene,x*29+z*43)
            for i in range(4):
                var nxt: int = (i+1)%4
                _triangle(land,corners[i],center,corners[nxt],
                    shades[i],face_color,shades[nxt])
                var neighbor: Vector2i = [
                    Vector2i(0,-1),Vector2i(1,0),
                    Vector2i(0,1),Vector2i(-1,0)][i]
                if kind(x+neighbor.x,z+neighbor.y,scene) in ["water","outside"]:
                    # Exposed outer boundary or cliff down to the water.
                    var below_a: Vector3 = corners[i]
                    var below_b: Vector3 = corners[nxt]
                    below_a.y = BASE_LEVEL
                    below_b.y = BASE_LEVEL
                    var cliff_tint: Color = face_color.darkened(0.31)
                    _triangle(land,corners[i],below_a,corners[nxt],
                        shades[i].darkened(0.17),cliff_tint,shades[nxt].darkened(0.17))
                    _triangle(land,corners[nxt],below_a,below_b,
                        shades[nxt].darkened(0.17),cliff_tint,cliff_tint)
    land.generate_normals()
    water.generate_normals()
    var ground := MeshInstance3D.new()
    ground.name = "SueloContinuoConRelieve"
    ground.mesh = land.commit()
    var land_mat := StandardMaterial3D.new()
    land_mat.vertex_color_use_as_albedo = true
    land_mat.roughness = 0.92
    land_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    ground.material_override = land_mat
    parent.add_child(ground)
    var water_surface := MeshInstance3D.new()
    water_surface.name = "LaminaDeAguaContinua"
    water_surface.mesh = water.commit()
    water_surface.material_override = _material(WATER,0.28)
    parent.add_child(water_surface)
    _box(parent,"LechoSubmarino",Vector3(0,BASE_LEVEL-0.09,0),
        Vector3(float(WIDTH)*CELL,0.20,float(HEIGHT)*CELL),DEEP_WATER)

static func _bush(parent: Node3D, center: Vector3, seed: int,
        coastal: bool) -> void:
    var leaf: Color = Color("#56836b") if coastal else Color("#52794b")
    var size: float = 0.28 + float(posmod(seed,5))*0.035
    _cone(parent,"Matorral_%d" % seed,
        center+Vector3(0,size*0.45,0),size,size*0.9,leaf,6)
    _cone(parent,"MatorralCopa_%d" % seed,
        center+Vector3(0,size*0.75,0),size*0.70,size*0.72,
        leaf.lightened(0.16),6)

static func _bridge(parent: Node3D, origin: Vector3, col: int) -> void:
    # Visually traversable span above water. No tactical bridge type is added.
    var deck_y: float = 0.28
    _box(parent,"PuenteElevado_%d" % col,
        origin+Vector3(0,deck_y,0),Vector3(CELL*1.008,0.18,1.38),ROAD)
    for side in [-1.0,1.0]:
        _box(parent,"BarandalPuente",
            origin+Vector3(0,deck_y+0.43,side*0.79),
            Vector3(CELL*1.008,0.085,0.10),ROAD_EDGE)
        for post in [-0.88,0.88]:
            _box(parent,"PostePuente",
                origin+Vector3(post,deck_y+0.22,side*0.79),
                Vector3(0.11,0.48,0.11),ROCK_LIGHT)
    for mark in [-0.66,0.66]:
        _box(parent,"MarcaPuente",
            origin+Vector3(mark,deck_y+0.104,0),
            Vector3(0.49,0.024,0.065),MARKER)
    _box(parent,"PilarPuente",
        origin+Vector3(0,-0.16,0),Vector3(0.34,0.70,1.04),
        ROCK_LIGHT.darkened(0.12))

static func _ellipsoid(parent: Node3D, label: String, center: Vector3,
        extent: Vector3, tint: Color) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.50
    mesh.height = 1.0
    mesh.radial_segments = 10
    mesh.rings = 6
    var leaf := MeshInstance3D.new()
    leaf.name = label
    leaf.mesh = mesh
    leaf.position = center
    leaf.scale = extent
    leaf.material_override = _material(tint)
    parent.add_child(leaf)
    return leaf

static func _tree(parent: Node3D, center: Vector3, seed: int, coastal: bool) -> void:
    var size: float = 0.75 + float(posmod(seed,5))*0.085
    _cylinder(parent,"Tronco_%d" % seed,center + Vector3(0,size*0.34,0),
        0.095*size,size*0.68,Color("#665746"))
    var leaf: Color = Color("#326456") if coastal else Color("#365f48")
    if coastal:
        # Coastal broadleaf canopy: avoid pine forests in the warm river delta.
        _ellipsoid(parent,"CopaFrondosa_%d" % seed,
            center+Vector3(0,size*1.15,0),Vector3(0.96,0.82,0.94)*size,
            leaf)
        _ellipsoid(parent,"CopaFrondosaLuz_%d" % seed,
            center+Vector3(-0.19*size,size*1.43,0.12*size),
            Vector3(0.70,0.60,0.65)*size,leaf.lightened(0.17))
    else:
        _cone(parent,"CopaInferior_%d" % seed,
            center+Vector3(0,size*0.91,0),0.50*size,0.92*size,leaf,7)
        _cone(parent,"CopaSuperior_%d" % seed,
            center+Vector3(0,size*1.32,0),0.38*size,0.75*size,
            leaf.lightened(0.14),7)

static func _rock_spire(parent: Node3D, name: String, origin: Vector3,
        radius: float, height: float, seed: int, tint: Color,
        snow: bool = true) -> MeshInstance3D:
    # Geometric mountain with irregular radial silhouette and two sculpted
    # elevation rings. Replaces recognizable repeated cone primitives.
    var segments: int = 7
    var rock_surface := SurfaceTool.new()
    rock_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var low: Array[Vector3] = []
    var ridge: Array[Vector3] = []
    for i in range(segments):
        var angle: float = TAU*float(i)/float(segments) + float(posmod(seed,11))*0.027
        var variation: float = 0.77+float(posmod(seed*3+i*7,9))*0.043
        var r: float = radius*variation
        var lower: Vector3 = Vector3(cos(angle)*r,0.0,sin(angle)*r)
        low.append(lower)
        ridge.append(Vector3(
            cos(angle)*r*0.47,
            height*(0.48+float(posmod(seed+i*13,7))*0.031),
            sin(angle)*r*0.47))
    var apex := Vector3(
        (float(posmod(seed,5))-2.0)*radius*0.08,height,
        (float(posmod(seed*3,5))-2.0)*radius*0.08)
    for i in range(segments):
        var nxt: int = (i+1)%segments
        var face_tint: Color = tint.lightened(0.065) if i%3 == 0 else (
            tint.darkened(0.18) if i%3 == 1 else tint)
        _triangle(rock_surface,low[i],ridge[i],low[nxt],
            face_tint.darkened(0.13),face_tint,face_tint.darkened(0.06))
        _triangle(rock_surface,low[nxt],ridge[i],ridge[nxt],
            face_tint.darkened(0.08),face_tint,face_tint.lightened(0.08))
        _triangle(rock_surface,ridge[i],apex,ridge[nxt],
            face_tint.lightened(0.02),SNOW if snow else face_tint.lightened(0.17),
            face_tint.lightened(0.08))
    rock_surface.generate_normals()
    var mountain := MeshInstance3D.new()
    mountain.name = name
    mountain.mesh = rock_surface.commit()
    mountain.position = origin
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = 0.92
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mountain.material_override = material
    parent.add_child(mountain)
    return mountain

static func _mountain(parent: Node3D, origin: Vector3, top: float,
        seed: int, scene: int) -> void:
    var peak_h: float = 1.28 + float(posmod(seed,6))*0.18
    var tint: Color = ROCK.lightened(0.06) if scene == 2 else ROCK
    _rock_spire(parent,"MacizoTallado_%d" % seed,
        origin+Vector3(-0.07,top,-0.09),1.17,peak_h,seed,tint)
    _rock_spire(parent,"CrestaSecundaria_%d" % seed,
        origin+Vector3(-0.44,top,0.47),0.64,peak_h*0.63,
        seed+37,ROCK_LIGHT.darkened(0.05),false)
    _box(parent,"RocaLateral_%d" % seed,
        origin+Vector3(0.71,top+0.18,-0.44),Vector3(0.53,0.35,0.59),
        tint.darkened(0.17))

static func _road(parent: Node3D, x: int, z: int, scene: int,
        origin: Vector3, top: float) -> void:
    # Tile-to-tile topology, not arbitrary road labels, drives junctions.
    var along_z: bool = kind(x,z-1,scene) == "road" or kind(x,z+1,scene) == "road"
    var along_x: bool = kind(x-1,z,scene) == "road" or kind(x+1,z,scene) == "road"
    if scene == 1 and z == 5 and x in [3,6,7]:
        along_x = true
    if not along_z and not along_x:
        along_z = true
    var orientations: Array[bool] = []
    if along_z:
        orientations.append(true)
    if along_x:
        orientations.append(false)
    for vertical in orientations:
        var size: Vector3 = Vector3(1.30,0.065,CELL*1.01) if vertical else Vector3(CELL*1.01,0.065,1.30)
        _box(parent,"Calzada_%d_%d_%s" % [x,z,str(vertical)],
            origin+Vector3(0,top+0.055,0),size,ROAD)
        for side in [-1.0,1.0]:
            var offset: Vector3 = Vector3(0.70*side,top+0.093,0) if vertical else Vector3(0,top+0.093,0.70*side)
            var edge_size: Vector3 = Vector3(0.055,0.035,CELL*1.02) if vertical else Vector3(CELL*1.02,0.035,0.055)
            _box(parent,"ArcénLateral",origin+offset,edge_size,ROAD_EDGE)
        # Never draw crossing lane lines through the center of a junction.
        if orientations.size() == 1:
            for n in [-1,0,1]:
                var marking: Vector3 = Vector3(0,top+0.098,float(n)*0.70) if vertical else Vector3(float(n)*0.70,top+0.098,0)
                var mark_size: Vector3 = Vector3(0.065,0.022,0.37) if vertical else Vector3(0.37,0.022,0.065)
                _box(parent,"LineaDiscontinua",origin+marking,mark_size,MARKER)

static func _shore(parent: Node3D, x: int, z: int, scene: int,
        origin: Vector3, top: float) -> void:
    for direction in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
        if kind(x+direction.x,z+direction.y,scene) != "water":
            continue
        var stripe: Vector3 = Vector3(0.18,0.026,CELL-0.10) if direction.x != 0 else Vector3(CELL-0.10,0.026,0.18)
        var offset: Vector3 = Vector3(float(direction.x)*1.03,top+0.018,
            float(direction.y)*1.03)
        _box(parent,"OrillaNatural",origin+offset,stripe,
            SAND.lightened(0.12) if scene != 1 else SAND)

static func _water_details(parent: Node3D, origin: Vector3, x: int,
        z: int, scene: int) -> void:
    for wave in range(2):
        var at: Vector3 = origin + Vector3(-0.45+wave*0.64,-0.135,
            -0.28+float(posmod(x+z+wave,3))*0.19)
        _box(parent,"EspumaOla",at,Vector3(0.67,0.014,0.044),FOAM)
    # Shore foam follows the actual shoreline, including meandering rivers.
    for direction in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
        var neighbor: String = kind(x+direction.x,z+direction.y,scene)
        if neighbor == "water" or neighbor == "outside":
            continue
        var size: Vector3 = Vector3(0.10,0.012,CELL-0.14) if direction.x != 0 else Vector3(CELL-0.14,0.012,0.10)
        _box(parent,"LineaEspumaCosta",
            origin+Vector3(float(direction.x)*1.04,-0.127,float(direction.y)*1.04),
            size,FOAM.lightened(0.10))

static func build_demo(scene: int = 0, show_grid: bool = false,
        show_samples: bool = true, faction: int = 0,
        continuous: bool = true) -> Node3D:
    var preset: int = clampi(scene,0,SCENES.size()-1)
    var root := Node3D.new()
    root.name = "EntornoTARVOKA_Mapa3D"
    root.set_meta("terrain_studio_scene",preset)
    root.set_meta("terrain_studio_grid",show_grid)
    root.set_meta("terrain_studio_samples",show_samples)
    root.set_meta("terrain_studio_continuous",continuous)
    var counts: Dictionary = {"water":0,"mountain":0,"forest":0,"road":0,"plain":0}
    var tiles := Node3D.new()
    tiles.name = "TerrenoDeCasillas"
    root.add_child(tiles)
    var props := Node3D.new()
    props.name = "RelieveVegetacionYDetalles"
    root.add_child(props)
    if continuous:
        _continuous_ground(tiles,preset)
    for z in range(HEIGHT):
        for x in range(WIDTH):
            var type: String = kind(x,z,preset)
            var top: float = height_at(x,z,preset)
            var p: Vector3 = _cell_center(x,z)
            var seed: int = x*29+z*43
            counts[type] = int(counts[type])+1
            var tint: Color = WATER if type == "water" else _ground_tint(type,preset,seed)
            if not continuous:
                # Opt-in baseline for same-camera comparison against the
                # original separate 3D blocks (V1).
                var thickness: float = top+0.62
                _box(tiles,"Casilla_%02d_%02d_%s" % [x,z,type],
                    p+Vector3(0,(top-0.62)*0.5,0),
                    Vector3(CELL*0.992,thickness,CELL*0.992),tint)
            match type:
                "mountain":
                    _mountain(props,p,top,seed,preset)
                "forest":
                    for index in range(2):
                        var displacement := Vector3(
                            -0.43+float(index)*0.72,top,
                            -0.28+float(posmod(seed+index*2,5))*0.13)
                        _tree(props,p+displacement,seed+index,preset==2)
                    _shore(props,x,z,preset,p,top)
                    if continuous and posmod(seed,3) != 0:
                        _bush(props,p+Vector3(0.51,top,-0.49),seed+103,preset==2)
                "plain":
                    if posmod(seed,3) == 0:
                        _box(props,"PiedraSuelo",p+Vector3(0.45,top+0.08,-0.32),
                            Vector3(0.28,0.16,0.33),ROCK_LIGHT.darkened(0.13))
                    _shore(props,x,z,preset,p,top)
                    if continuous and posmod(seed,5) == 2:
                        _bush(props,p+Vector3(-0.31,top,0.43),seed+211,preset==2)
                "road":
                    _road(props,x,z,preset,p,top)
                    _shore(props,x,z,preset,p,top)
                "water":
                    _water_details(props,p,x,z,preset)
                    if preset == 1 and z == 5 and x in [4,5]:
                        _bridge(props,p,x)
            if show_grid:
                var grid_tint: Color = Color("#223842") if type != "water" else Color("#19566d")
                _box(props,"GuiaCasillaN",
                    p+Vector3(0,top+0.025,-CELL*0.49),
                    Vector3(CELL*0.985,0.026,0.026),grid_tint)
                _box(props,"GuiaCasillaO",
                    p+Vector3(-CELL*0.49,top+0.025,0),
                    Vector3(0.026,0.026,CELL*0.985),grid_tint)
    if show_samples:
        var samples := Node3D.new()
        samples.name = "MuestrasDeEscalaUnidadYEdificio"
        root.add_child(samples)
        var tank := Models.build("tank",clampi(faction,0,7),true,10)
        tank.name = "TanqueDeReferencia"
        tank.scale = Vector3.ONE*0.64
        var tank_cell: Vector2i = Vector2i(8,8) if preset == 1 else Vector2i(5,7) if preset == 2 else Vector2i(5,5)
        tank.position = _cell_center(tank_cell.x,tank_cell.y) + Vector3(0,height_at(tank_cell.x,tank_cell.y,preset)+0.06,0)
        samples.add_child(tank)
        var hq := Headquarters.build(1,clampi(faction,0,7),"operativo",true,true)
        hq.name = "CuartelDeReferencia"
        hq.scale = Vector3.ONE*0.27
        var hq_cell: Vector2i = Vector2i(10,8) if preset == 1 else Vector2i(6,8)
        hq.position = _cell_center(hq_cell.x,hq_cell.y) + Vector3(0,height_at(hq_cell.x,hq_cell.y,preset),0)
        samples.add_child(hq)
    root.set_meta("terrain_counts",counts)
    root.set_meta("terrain_tile_count",WIDTH*HEIGHT)
    return root
