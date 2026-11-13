extends RefCounted
class_name TarvokaUnitModels3D

# First actual editable 3D geometry for TARVOKA. These eight models are native
# Godot MeshInstance3D trees, NOT SVG sprites or AI-rendered concept images.
# Tuned to existing approved category silhouettes; no tactical stats live here.
const ROLES := ["line","scout","apc","tank","mlrs","attack_heli","fighter","destroyer"]
const STEEL := Color("#788795")
const ARMOR := Color("#a4adb4")
const DARK := Color("#293a47")
const BLACK := Color("#162630")
const GLASS := Color("#6795ae")
const METAL := Color("#d5dce0")
const ACCENT := Color("#e1a94f")
const RUBBER := Color("#222930")
const CLOTH := Color("#8e9588")
const WATER := Color("#568596")

static func supports(role: String) -> bool:
    return role in ROLES

static func production_asset_path(role: String) -> String:
    # Production-ready GLB files replace native blockouts without touching
    # battles, UI, faction rules or the shared rendering cache.
    return "res://assets/units3d/" + role + ".glb" if supports(role) else ""

static func _imported_model(role: String) -> Node3D:
    var path: String = production_asset_path(role)
    if path.is_empty() or not ResourceLoader.exists(path):
        return null
    var packed: PackedScene = load(path) as PackedScene
    if packed == null:
        push_warning("TARVOKA: invalid 3D scene " + path)
        return null
    var imported: Node = packed.instantiate()
    if imported is Node3D:
        imported.name = "Modelo3D_" + role
        return imported as Node3D
    imported.free()
    push_warning("TARVOKA: 3D model root must be Node3D: " + path)
    return null

static func _material(color: Color, metal: float = 0.15) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = 0.64
    return mat

static func _box(parent: Node3D, label: String, pos: Vector3, extent: Vector3,
        color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := BoxMesh.new()
    mesh.size = extent
    item.mesh = mesh
    item.material_override = _material(color)
    item.position = pos
    item.rotation_degrees = rotation
    parent.add_child(item)
    return item

static func _cylinder(parent: Node3D, label: String, pos: Vector3,
        radius: float, length: float, color: Color,
        rotation: Vector3 = Vector3.ZERO, sides: int = 12) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = maxi(6,sides)
    item.mesh = mesh
    item.material_override = _material(color,0.22)
    item.position = pos
    item.rotation_degrees = rotation
    parent.add_child(item)
    return item

static func _sphere(parent: Node3D, label: String, pos: Vector3,
        extent: Vector3, color: Color) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 12
    mesh.rings = 6
    item.mesh = mesh
    item.material_override = _material(color)
    item.position = pos
    item.scale = extent
    parent.add_child(item)
    return item

static func _hull(parent: Node3D, label: String, points: Array,
        faces: Array, color: Color) -> MeshInstance3D:
    # Model-specific tapered hulls: geometric 3D, not a flat photo decal.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        for k in range(1,face.size()-1):
            for index in [face[0],face[k],face[k+1]]:
                surface.add_vertex(points[index])
    surface.generate_normals()
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = surface.commit()
    item.material_override = _material(color,0.20)
    parent.add_child(item)
    return item

static func _body(parent: Node3D, label: String, half_width: float,
        front: float, rear: float, bottom: float, top: float,
        color: Color) -> void:
    # Beveled octagonal outline around a six-sided solid armored hull.
    var w := half_width
    var a: Array = [
        Vector3(-w,bottom,-front*0.65),Vector3(w,bottom,-front*0.65),
        Vector3(w,bottom,rear*0.82),Vector3(-w,bottom,rear*0.82),
        Vector3(-w*0.82,top,-front),Vector3(w*0.82,top,-front),
        Vector3(w*0.82,top,rear),Vector3(-w*0.82,top,rear)
    ]
    _hull(parent,label,a,[
        [0,1,2,3],[4,7,6,5],[0,4,5,1],[1,5,6,2],
        [2,6,7,3],[3,7,4,0]],color)

static func _antenna(parent: Node3D, label: String, pos: Vector3,
        height: float) -> void:
    _cylinder(parent,label,pos+Vector3(0,height*0.5,0),
        0.016,height,DARK,Vector3.ZERO,8)
    _sphere(parent,label+"Tip",pos+Vector3(0,height,0),
        Vector3(0.065,0.065,0.065),ACCENT)

static func _tracks(parent: Node3D, half_width: float, length: float,
        wheels: int = 5) -> void:
    for side in [-1,1]:
        var x: float = float(side)*half_width
        _box(parent,"Oruga%s" % side,Vector3(x,0.28,0),
            Vector3(0.33,0.47,length),RUBBER)
        _box(parent,"Costado%s" % side,Vector3(x,0.39,0),
            Vector3(0.39,0.22,length*0.84),DARK)
        for n in range(wheels):
            var z := -length*0.38+(length*0.76*float(n)/float(maxi(1,wheels-1)))
            _cylinder(parent,"Rueda_%s_%d" % [side,n],
                Vector3(x+float(side)*0.20,0.25,z),0.16,0.065,METAL,
                Vector3(0,0,90),10)

static func _wheels(parent: Node3D, axles: int = 3, wheel_radius: float = 0.28) -> void:
    for side in [-1,1]:
        for n in range(axles):
            var z := -0.87+1.75*float(n)/float(maxi(1,axles-1))
            _cylinder(parent,"Neumatico_%s_%d" % [side,n],
                Vector3(float(side)*0.78,wheel_radius,z),
                wheel_radius,0.26,RUBBER,Vector3(0,0,90),14)
            _cylinder(parent,"Llanta_%s_%d" % [side,n],
                Vector3(float(side)*0.93,wheel_radius,z),
                wheel_radius*0.52,0.03,METAL,Vector3(0,0,90),12)

static func _person(root: Node3D, special: bool) -> void:
    var person := Node3D.new()
    person.name = "Infanteria_3D"
    root.add_child(person)
    if special:
        person.rotation_degrees.y = -16.0
    # Each humanoid element is actual shaded 3D material with depth.
    for side in [-1,1]:
        var x: float = float(side)*0.20
        _box(person,"Bota%d" % side,Vector3(x,0.11,-0.13),
            Vector3(0.22,0.21,0.43),BLACK)
        _box(person,"Pierna%d" % side,Vector3(x,0.52,0.02),
            Vector3(0.24,0.72,0.27),CLOTH,
            Vector3(10 if special else 0,0,0))
        _box(person,"Rodillera%d" % side,Vector3(x,0.51,-0.15),
            Vector3(0.21,0.20,0.075),DARK)
        _box(person,"Brazo%d" % side,Vector3(float(side)*0.42,1.40,-0.12),
            Vector3(0.20,0.63,0.23),CLOTH,Vector3(30,0,float(side)*24))
        _box(person,"Hombrera%d" % side,Vector3(float(side)*0.40,1.66,0.0),
            Vector3(0.27,0.17,0.30),STEEL)
        _box(person,"Municion%d" % side,Vector3(float(side)*0.28,1.23,-0.22),
            Vector3(0.16,0.22,0.08),ARMOR)
    _box(person,"TorsoBlindado",Vector3(0,1.43,0),
        Vector3(0.75,0.70,0.40),STEEL)
    _box(person,"Chaleco",Vector3(0,1.42,-0.25),
        Vector3(0.66,0.42,0.15),DARK)
    _box(person,"Mochila",Vector3(0,1.45,0.32),
        Vector3(0.54,0.65,0.27),ARMOR)
    _cylinder(person,"Cuello",Vector3(0,1.89,0),
        0.13,0.17,CLOTH)
    _sphere(person,"Casco",Vector3(0,2.11,0),
        Vector3(0.53,0.48,0.50),STEEL)
    _box(person,"Visor",Vector3(0,2.12,-0.265),
        Vector3(0.44,0.17,0.08),GLASS)
    _box(person,"HombreraIdentificacion",Vector3(-0.43,1.66,-0.02),
        Vector3(0.04,0.12,0.25),ACCENT)
    if special:
        for side in [-1,1]:
            _cylinder(person,"OpticaTermica%d" % side,
                Vector3(float(side)*0.17,2.31,-0.31),
                0.085,0.23,BLACK,Vector3(90,0,0),10)
            _sphere(person,"Sensor%d" % side,
                Vector3(float(side)*0.17,2.31,-0.47),
                Vector3(0.13,0.13,0.06),GLASS)
        _antenna(person,"Radio",Vector3(0.24,1.8,0.32),0.43)
    # Weapon with distinct receiver, long barrel, stock, scope and muzzle.
    var rifle := Node3D.new()
    rifle.name = "FusilTactico"
    person.add_child(rifle)
    rifle.position = Vector3(0.1,1.42,-0.45)
    rifle.rotation_degrees = Vector3(0,12 if special else -8,7)
    _box(rifle,"Receptor",Vector3(0,0,0),
        Vector3(0.58,0.17,0.24),BLACK)
    _box(rifle,"Culata",Vector3(-0.40,-0.025,0),
        Vector3(0.38,0.17,0.18),DARK)
    _cylinder(rifle,"Canon",Vector3(0.54,0,0),
        0.055,0.68,BLACK,Vector3(0,0,90))
    _box(rifle,"Optica",Vector3(0.05,0.14,-0.015),
        Vector3(0.20,0.14,0.13),ARMOR)
    _box(rifle,"Cargador",Vector3(0.02,-0.20,0),
        Vector3(0.16,0.28,0.14),DARK)

static func _apc(root: Node3D) -> void:
    _body(root,"ChasisAPC",0.72,1.26,1.20,0.72,1.22,STEEL)
    _wheels(root,3,0.32)
    _box(root,"ParabrisasFrontal",Vector3(0,1.09,-1.17),
        Vector3(0.83,0.24,0.08),GLASS,Vector3(-20,0,0))
    _box(root,"BlindajeCabina",Vector3(0,1.26,-0.70),
        Vector3(0.99,0.10,0.60),ARMOR)
    _box(root,"PuestoSensores",Vector3(0,1.53,0.11),
        Vector3(0.28,0.28,0.32),DARK)
    _box(root,"CabezaElectroOptica",Vector3(0,1.81,0.07),
        Vector3(0.49,0.27,0.27),ARMOR)
    for x in [-0.15,0.15]:
        _sphere(root,"Optica%.1f" % x,Vector3(x,1.82,-0.08),
            Vector3(0.14,0.14,0.07),GLASS)
    for side in [-1,1]:
        var x: float = float(side)*0.50
        for n in range(3):
            _box(root,"Ventanilla_%s_%d" % [side,n],
                Vector3(x,1.10,-0.33+float(n)*0.39),
                Vector3(0.08,0.17,0.21),BLACK)
        _antenna(root,"Comunicacion%s" % side,
            Vector3(x,1.22,0.77),0.58)
    _box(root,"Parrilla",Vector3(0,0.75,-1.29),
        Vector3(0.50,0.18,0.06),BLACK)
    _box(root,"LuzIzq",Vector3(-0.51,0.71,-1.29),Vector3(0.16,0.13,0.05),METAL)
    _box(root,"LuzDer",Vector3(0.51,0.71,-1.29),Vector3(0.16,0.13,0.05),METAL)

static func _tank(root: Node3D) -> void:
    _body(root,"BlindajeCompuesto",0.92,1.45,1.38,0.32,0.92,STEEL)
    _tracks(root,0.92,2.65,6)
    for side in [-1,1]:
        _box(root,"FaldaLateral%s" % side,
            Vector3(float(side)*0.94,0.64,0),
            Vector3(0.30,0.29,2.27),ARMOR)
        for n in range(4):
            _box(root,"PlacaERA%s_%d" % [side,n],
                Vector3(float(side)*0.73,0.93,-0.86+float(n)*0.57),
                Vector3(0.30,0.09,0.46),DARK)
    _cylinder(root,"AnilloTorre",Vector3(0,1.00,0),
        0.56,0.15,BLACK,Vector3.ZERO,14)
    _body(root,"TorrePrincipal",0.69,0.91,0.59,1.04,1.46,ARMOR)
    _cylinder(root,"CanonPrincipal",Vector3(0,1.28,-1.26),
        0.125,2.45,DARK,Vector3(90,0,0),16)
    _cylinder(root,"ManguitoCanon",Vector3(0,1.28,-0.52),
        0.19,0.48,METAL,Vector3(90,0,0),12)
    _box(root,"BlindajeFrontal",Vector3(0,1.27,-0.76),
        Vector3(0.86,0.30,0.32),STEEL)
    _box(root,"SensorTorre",Vector3(0.42,1.62,0.15),
        Vector3(0.24,0.25,0.26),DARK)
    _sphere(root,"OpticaTorre",Vector3(0.42,1.63,-0.03),
        Vector3(0.18,0.14,0.09),GLASS)
    _cylinder(root,"Escotilla",Vector3(-0.28,1.54,0.12),
        0.22,0.10,DARK)
    _antenna(root,"Antena",Vector3(0.48,1.50,0.43),0.67)

static func _mlrs(root: Node3D) -> void:
    _body(root,"ChasisLanzacohetes",0.83,1.45,1.35,0.28,0.88,STEEL)
    _tracks(root,0.84,2.63,6)
    _box(root,"Cabina",Vector3(0,0.92,-0.89),
        Vector3(1.23,0.58,0.70),ARMOR)
    _box(root,"CristalCabina",Vector3(0,1.06,-1.25),
        Vector3(0.91,0.18,0.06),GLASS)
    var pod := Node3D.new()
    pod.name = "CestaLanzacohetesElevada"
    root.add_child(pod)
    pod.position = Vector3(0.0,1.35,0.32)
    pod.rotation_degrees.x = 25
    _box(pod,"BloqueLanzador",Vector3(0,0,0.15),
        Vector3(1.15,0.82,1.22),DARK)
    for x in range(4):
        for y in range(3):
            _cylinder(pod,"Tubo_%d_%d" % [x,y],
                Vector3(-0.42+float(x)*0.28,-0.26+float(y)*0.25,-0.47),
                0.102,0.21,BLACK,Vector3(90,0,0),12)
            _cylinder(pod,"Borde_%d_%d" % [x,y],
                Vector3(-0.42+float(x)*0.28,-0.26+float(y)*0.25,-0.59),
                0.115,0.035,METAL,Vector3(90,0,0),12)
    for side in [-1,1]:
        _box(pod,"Bisagra_%s" % side,
            Vector3(float(side)*0.69,-0.36,0.14),
            Vector3(0.18,0.27,0.45),STEEL)
    _antenna(root,"RadioCohetes",Vector3(0.55,1.18,0.78),0.42)

static func _rotor(parent: Node3D, y: float, width: float, rotor_count: int = 4) -> void:
    _cylinder(parent,"Mastil",Vector3(0,y-0.10,0),
        0.06,0.37,DARK)
    _cylinder(parent,"Cabezal",Vector3(0,y+0.10,0),
        0.22,0.13,ARMOR,Vector3.ZERO,10)
    for n in range(rotor_count):
        var blade := _box(parent,"Pala_%d" % n,
            Vector3(0,y+0.12,0),Vector3(0.09,0.035,width*1.9),
            BLACK,Vector3(0,float(n)*180.0/float(rotor_count),0))
        blade.position = Vector3.ZERO+Vector3(0,y+0.12,0)

static func _helicopter(root: Node3D) -> void:
    _sphere(root,"Fuselaje",Vector3(0,0.85,0),
        Vector3(1.10,0.95,2.20),STEEL)
    _sphere(root,"CabinaCristal",Vector3(0,0.88,-0.70),
        Vector3(0.83,0.63,1.00),GLASS)
    _box(root,"MotorIzq",Vector3(-0.30,1.35,0.47),
        Vector3(0.39,0.28,0.75),DARK)
    _box(root,"MotorDer",Vector3(0.30,1.35,0.47),
        Vector3(0.39,0.28,0.75),DARK)
    _box(root,"Cola",Vector3(0,0.94,1.79),
        Vector3(0.21,0.25,2.47),ARMOR)
    _box(root,"Estabilizador",Vector3(0,0.98,2.75),
        Vector3(1.40,0.07,0.30),STEEL)
    _box(root,"AletaVertical",Vector3(0,1.22,2.73),
        Vector3(0.10,0.71,0.43),DARK)
    _rotor(root,1.76,1.48,4)
    _cylinder(root,"RotorCola",Vector3(0.16,1.32,2.97),
        0.09,0.11,DARK,Vector3(0,0,90),8)
    for side in [-1,1]:
        var x: float = float(side)*0.82
        _box(root,"AlaCorta%s" % side,Vector3(x,0.76,0.13),
            Vector3(1.16,0.09,0.34),STEEL)
        for n in range(3):
            _cylinder(root,"Cohete%s_%d" % [side,n],
                Vector3(x+float(side)*0.19,0.62,-0.09+float(n)*0.13),
                0.07,0.73,DARK,Vector3(90,0,0),10)
        _box(root,"Patin%s" % side,Vector3(float(side)*0.40,0.22,0.03),
            Vector3(0.07,0.08,1.70),BLACK)
        _box(root,"SoportePatin%s" % side,Vector3(float(side)*0.40,0.40,0.12),
            Vector3(0.08,0.48,0.09),METAL)
    _sphere(root,"SensorMorro",Vector3(0,0.60,-1.18),
        Vector3(0.29,0.29,0.31),DARK)
    _sphere(root,"OpticaMorro",Vector3(0,0.59,-1.36),
        Vector3(0.16,0.13,0.07),GLASS)

static func _fighter(root: Node3D) -> void:
    _body(root,"FuselajeCaza",0.41,1.90,1.46,0.54,0.92,STEEL)
    _sphere(root,"Canopy",Vector3(0,0.98,-0.58),
        Vector3(0.58,0.31,0.88),GLASS)
    _box(root,"Nariz",Vector3(0,0.70,-1.91),
        Vector3(0.33,0.19,1.12),ARMOR)
    for side in [-1,1]:
        var sign: float = float(side)
        # Tapered wing as an actual 3D triangular prism with finite thickness.
        var a: Array = [
            Vector3(sign*0.22,0.67,-0.26),
            Vector3(sign*1.88,0.65,0.66),
            Vector3(sign*0.36,0.67,0.80),
            Vector3(sign*0.22,0.76,-0.26),
            Vector3(sign*1.88,0.74,0.66),
            Vector3(sign*0.36,0.76,0.80)
        ]
        _hull(root,"AlaDelta%s" % side,a,
            [[0,2,1],[3,4,5],[0,1,4,3],[1,2,5,4],[2,0,3,5]],ARMOR)
        _box(root,"Motor%s" % side,
            Vector3(sign*0.26,0.58,1.20),
            Vector3(0.35,0.27,0.80),DARK)
        _box(root,"ColaVertical%s" % side,
            Vector3(sign*0.35,1.07,1.43),
            Vector3(0.11,0.89,0.46),STEEL,Vector3(0,sign*18,sign*14))
        _box(root,"Timón%s" % side,
            Vector3(sign*0.78,0.62,1.45),
            Vector3(1.05,0.08,0.49),DARK)
        for n in range(2):
            _cylinder(root,"MisilAla%s_%d" % [side,n],
                Vector3(sign*(0.86+float(n)*0.30),0.48,0.56+float(n)*0.1),
                0.072,0.85,METAL,Vector3(90,0,0),10)
    _cylinder(root,"Tobera",Vector3(0,0.62,1.62),
        0.24,0.23,BLACK,Vector3(90,0,0),16)

static func _destroyer(root: Node3D) -> void:
    var outline: Array = [
        Vector3(-0.75,0.18,-1.35),Vector3(0.75,0.18,-1.35),
        Vector3(0.91,0.18,1.20),Vector3(-0.91,0.18,1.20),
        Vector3(0,0.22,-2.26),Vector3(-0.67,0.74,-1.20),
        Vector3(0.67,0.74,-1.20),Vector3(0.70,0.72,1.20),
        Vector3(-0.70,0.72,1.20)
    ]
    _hull(root,"CascoNaval",outline,[
        [0,3,2,1],[0,1,4],[0,5,8,3],[1,2,7,6],
        [3,8,7,2],[4,1,6],[4,6,5],[0,4,5],[5,6,7,8]],STEEL)
    _box(root,"Cubierta",Vector3(0,0.75,0.23),
        Vector3(1.30,0.09,2.69),ARMOR)
    _body(root,"Superestructura",0.43,0.25,0.50,0.80,1.36,METAL)
    _box(root,"Puente",Vector3(0,1.30,0),
        Vector3(0.79,0.26,0.50),GLASS)
    _box(root,"TorreMastil",Vector3(0,1.74,0.28),
        Vector3(0.17,0.81,0.18),DARK)
    _box(root,"Radar",Vector3(0,2.16,0.28),
        Vector3(0.82,0.20,0.13),ARMOR)
    _cylinder(root,"BaseTorreProa",Vector3(0,0.91,-1.14),
        0.25,0.20,DARK,Vector3.ZERO,10)
    _cylinder(root,"CanonNaval",Vector3(0,0.96,-1.48),
        0.07,0.95,METAL,Vector3(90,0,0),10)
    for x in [-0.25,-0.08,0.08,0.25]:
        for n in range(3):
            _box(root,"VLS%.2f_%d" % [x,n],
                Vector3(x,0.83,-0.27+float(n)*0.17),
                Vector3(0.13,0.06,0.12),BLACK)
    for side in [-1,1]:
        _antenna(root,"RadarRadio%s" % side,
            Vector3(float(side)*0.29,1.45,0.50),0.47)
    _box(root,"Helipuerto",Vector3(0,0.82,0.93),
        Vector3(1.06,0.08,0.58),DARK)
    _box(root,"MarcaHelipuerto",Vector3(0,0.87,0.92),
        Vector3(0.06,0.02,0.38),ACCENT)
    # Static white wake is part of the ship model, not map-water mechanics.
    _box(root,"EstelaEspuma",Vector3(0,0.07,1.71),
        Vector3(1.43,0.04,0.37),WATER)

static func build(role: String) -> Node3D:
    if not supports(role):
        return null
    var imported: Node3D = _imported_model(role)
    if imported != null:
        return imported
    # Authored native 3D mesh fallback, never a fake 2D illustration.
    var model := Node3D.new()
    model.name = "Modelo3D_" + role
    match role:
        "line":
            _person(model,false)
        "scout":
            _person(model,true)
        "apc":
            _apc(model)
        "tank":
            _tank(model)
        "mlrs":
            _mlrs(model)
        "attack_heli":
            _helicopter(model)
        "fighter":
            _fighter(model)
        "destroyer":
            _destroyer(model)
    if role in ["line","scout"]:
        model.scale = Vector3.ONE * 0.82
        model.position.y = -0.58
    elif role in ["attack_heli","fighter","destroyer"]:
        model.scale = Vector3.ONE * 0.77
        model.position.y = -0.11
    else:
        model.scale = Vector3.ONE * 0.83
        model.position.y = -0.27
    return model

static func inspect_meshes(model: Node) -> int:
    if model == null:
        return 0
    var count := 1 if model is MeshInstance3D else 0
    for child in model.get_children():
        count += inspect_meshes(child)
    return count
