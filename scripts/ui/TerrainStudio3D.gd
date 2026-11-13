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

static func _tree(parent: Node3D, center: Vector3, seed: int, coastal: bool) -> void:
    var size: float = 0.75 + float(posmod(seed,5))*0.085
    _cylinder(parent,"Tronco_%d" % seed,center + Vector3(0,size*0.34,0),
        0.095*size,size*0.68,Color("#665746"))
    var leaf: Color = Color("#326456") if coastal else Color("#365f48")
    _cone(parent,"CopaInferior_%d" % seed,
        center+Vector3(0,size*0.91,0),0.50*size,0.92*size,leaf,7)
    _cone(parent,"CopaSuperior_%d" % seed,
        center+Vector3(0,size*1.32,0),0.38*size,0.75*size,
        leaf.lightened(0.14),7)

static func _mountain(parent: Node3D, origin: Vector3, top: float,
        seed: int, scene: int) -> void:
    var peak_h: float = 1.35 + float(posmod(seed,4))*0.19
    var tint: Color = ROCK.lightened(0.09) if scene == 2 else ROCK
    _cone(parent,"Macizo_%d" % seed,origin+Vector3(0,top+peak_h*0.5,0),
        1.00,peak_h,tint,6)
    _cone(parent,"Cresta_%d" % seed,
        origin+Vector3(-0.29,top+peak_h*0.66,0.24),0.60,peak_h*0.64,
        ROCK_LIGHT,5)
    _cone(parent,"Cumbre_%d" % seed,
        origin+Vector3(0,top+peak_h*0.90,0),0.32,peak_h*0.35,SNOW,6)
    _box(parent,"RocaLateral_%d" % seed,
        origin+Vector3(0.71,top+0.18,-0.44),Vector3(0.53,0.35,0.59),
        tint.darkened(0.17))

static func _road(parent: Node3D, x: int, z: int, scene: int,
        origin: Vector3, top: float) -> void:
    var along_z: bool = x == (8 if scene == 1 else 5)
    var crossing: bool = z == (8 if scene == 1 else 7 if scene == 2 else 5)
    if scene == 2:
        along_z = x == 5
    var orientations: Array[bool] = []
    if along_z:
        orientations.append(true)
    if crossing:
        orientations.append(false)
    if orientations.is_empty():
        orientations.append(true)
    for vertical in orientations:
        var size := Vector3(1.30,0.055,CELL*1.01) if vertical else Vector3(CELL*1.01,0.055,1.30)
        _box(parent,"Calzada_%d_%d_%s" % [x,z,str(vertical)],
            origin+Vector3(0,top+0.04,0),size,ROAD)
        for side in [-1.0,1.0]:
            var offset: Vector3 = Vector3(0.68*side,top+0.082,0) if vertical else Vector3(0,top+0.082,0.68*side)
            var edge_size: Vector3 = Vector3(0.045,0.025,CELL) if vertical else Vector3(CELL,0.025,0.045)
            _box(parent,"BordeVial",origin+offset,edge_size,ROAD_EDGE)
        for n in [-1,0,1]:
            var marking: Vector3 = Vector3(0,top+0.085,float(n)*0.70) if vertical else Vector3(float(n)*0.70,top+0.085,0)
            var mark_size: Vector3 = Vector3(0.06,0.022,0.37) if vertical else Vector3(0.37,0.022,0.06)
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

static func _water_details(parent: Node3D, origin: Vector3, x: int, z: int) -> void:
    for wave in range(2):
        var at: Vector3 = origin + Vector3(-0.45+wave*0.64,-0.09,
            -0.28+float(posmod(x+z+wave,3))*0.19)
        _box(parent,"EspumaOla",at,Vector3(0.67,0.014,0.044),FOAM)

static func build_demo(scene: int = 0, show_grid: bool = false,
        show_samples: bool = true, faction: int = 0) -> Node3D:
    var preset: int = clampi(scene,0,SCENES.size()-1)
    var root := Node3D.new()
    root.name = "EntornoTARVOKA_Mapa3D"
    root.set_meta("terrain_studio_scene",preset)
    root.set_meta("terrain_studio_grid",show_grid)
    root.set_meta("terrain_studio_samples",show_samples)
    var counts: Dictionary = {"water":0,"mountain":0,"forest":0,"road":0,"plain":0}
    var tiles := Node3D.new()
    tiles.name = "TerrenoDeCasillas"
    root.add_child(tiles)
    var props := Node3D.new()
    props.name = "RelieveVegetacionYDetalles"
    root.add_child(props)
    for z in range(HEIGHT):
        for x in range(WIDTH):
            var type: String = kind(x,z,preset)
            var top: float = height_at(x,z,preset)
            var p: Vector3 = _cell_center(x,z)
            var seed: int = x*29+z*43
            counts[type] = int(counts[type])+1
            var tint: Color = WATER if type == "water" else (
                ROCK if type == "mountain" else (
                ROAD_EDGE if type == "road" else (
                MOSS if preset == 2 else SAND if preset == 1 else GRASS)))
            if type == "plain" or type == "forest":
                tint = tint.lightened(float(posmod(seed,6))*0.015)
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
                "plain":
                    if posmod(seed,3) == 0:
                        _box(props,"PiedraSuelo",p+Vector3(0.45,top+0.08,-0.32),
                            Vector3(0.28,0.16,0.33),ROCK_LIGHT.darkened(0.13))
                    _shore(props,x,z,preset,p,top)
                "road":
                    _road(props,x,z,preset,p,top)
                    _shore(props,x,z,preset,p,top)
                "water":
                    _water_details(props,p,x,z)
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
