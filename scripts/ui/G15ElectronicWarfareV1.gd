extends RefCounted
class_name TarvokaG15ElectronicWarfareV1

# G15: native Godot 3D ART ONLY. No attack, detection, jamming, money,
# turn logic or new playable BattleSession class is installed by this file.
# The silhouette is deliberately unlike the gun-equipped G13: a six-wheel
# communications carrier with a sealed electronic shelter and deployable mast.
const FLAG := "tarvoka_g15_ew_native_3d_v1"
const CHASSIS := "G15_Chassis6x6"
const MAST := "G15_ArticulatedSensorMast"
const ROTOR := "G15_DirectionalArray"
const PULSE := "G15_SignalPreview"
const WHEEL_GROUP := "G15_WheelPivots"
const TIRES := "G15_RubberTire"
const PAINT := "G15_FactionPanel"
static var _material_cache: Dictionary = {}

static func _mat(color: Color, metal: float, rough: float,
        coat: bool = false) -> StandardMaterial3D:
    var key := "%s/%s/%s/%s" % [color.to_html(), metal, rough, coat]
    if _material_cache.has(key):
        return _material_cache[key] as StandardMaterial3D
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    m.clearcoat_enabled = coat
    if coat:
        m.clearcoat = 0.32
        m.clearcoat_roughness = 0.24
    _material_cache[key] = m
    return m

static func _box(parent: Node3D, label: String, position: Vector3,
        size: Vector3, material: Material,
        angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var shape := BoxMesh.new()
    shape.size = size
    node.mesh = shape
    node.material_override = material
    node.position = position
    node.rotation_degrees = angle
    parent.add_child(node)
    return node

static func _cylinder(parent: Node3D, label: String, position: Vector3,
        radius: float, height: float, material: Material,
        angle: Vector3 = Vector3.ZERO, sides: int = 18) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var shape := CylinderMesh.new()
    shape.top_radius = radius
    shape.bottom_radius = radius
    shape.height = height
    shape.radial_segments = sides
    node.mesh = shape
    node.material_override = material
    node.position = position
    node.rotation_degrees = angle
    parent.add_child(node)
    return node

static func _sphere(parent: Node3D, label: String, position: Vector3,
        scale3: Vector3, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var shape := SphereMesh.new()
    shape.radius = 0.5
    shape.height = 1.0
    shape.radial_segments = 14
    shape.rings = 8
    node.mesh = shape
    node.material_override = material
    node.position = position
    node.scale = scale3
    parent.add_child(node)
    return node

static func _make_wheel(group: Node3D, side: int, axle: int, z: float,
        hero: bool, rubber: Material, steel: Material,
        dark: Material, accent: Material) -> void:
    var sign := float(side)
    var pivot := Node3D.new()
    pivot.name = "G15_Wheel_%s_%d" % [side, axle]
    pivot.position = Vector3(sign * 0.92, 0.355, z)
    group.add_child(pivot)
    _cylinder(pivot, TIRES + "_%s_%d" % [side, axle],
        Vector3.ZERO, 0.337, 0.245, rubber, Vector3(0, 0, 90), 24)
    _cylinder(pivot, "G15_Rim_%s_%d" % [side, axle],
        Vector3(sign * 0.137, 0, 0), 0.203, 0.022,
        steel, Vector3(0, 0, 90), 20)
    _cylinder(pivot, "G15_Hub_%s_%d" % [side, axle],
        Vector3(sign * 0.154, 0, 0), 0.090, 0.030,
        dark, Vector3(0, 0, 90), 14)
    if hero:
        for n in range(12):
            var a := TAU * float(n) / 12.0
            # Rubber blocks are physical tread volumes, not painted chrome.
            var wedge := _box(pivot, "G15_Tread_%s_%d_%d" % [side, axle, n],
                Vector3(0, cos(a)*0.332, sin(a)*0.332),
                Vector3(0.251, 0.035, 0.100), rubber)
            wedge.rotation_degrees.x = rad_to_deg(a)
        for n in range(6):
            var a := TAU * float(n) / 6.0
            _sphere(pivot, "G15_RimBolt_%s_%d_%d" % [side, axle, n],
                Vector3(sign*0.174, cos(a)*0.147, sin(a)*0.147),
                Vector3(0.038, 0.038, 0.038), accent)

static func build(root: Node3D, faction_color: Color,
        hero: bool = true) -> bool:
    if root == null:
        return false
    if has_model(root):
        return true
    var armor := _mat(Color("#75838b"), 0.54, 0.48)
    var light_armor := _mat(Color("#abb5b7"), 0.61, 0.42)
    var dark := _mat(Color("#29333b"), 0.42, 0.67)
    var machined := _mat(Color("#ccd4d5"), 0.83, 0.27)
    var tire := _mat(Color("#222427"), 0.0, 0.93)
    var glass := _mat(Color("#456c82"), 0.13, 0.16, true)
    var paint := _mat(faction_color, 0.30, 0.43, true)
    var signal := _mat(Color("#85d9e5"), 0.12, 0.26)
    var root3 := Node3D.new()
    root3.name = CHASSIS
    root.add_child(root3)
    # Long 6x6 wheelbase and uninterrupted electronic shelter distinguish it
    # from the four-wheel G13 turreted anti-air platform.
    _box(root3, "G15_LowerFrame", Vector3(0,0.73,0.0),
        Vector3(1.55,0.36,3.50), dark)
    _box(root3, "G15_Underfloor", Vector3(0,0.90,0.1),
        Vector3(1.58,0.16,3.19), machined)
    _box(root3, "G15_FrontCab", Vector3(0,1.29,-1.00),
        Vector3(1.42,0.89,1.20), armor)
    _box(root3, "G15_FrontSlope", Vector3(0,1.39,-1.60),
        Vector3(1.26,0.52,0.18), light_armor, Vector3(-17,0,0))
    _box(root3, "G15_ElectronicShelter", Vector3(0,1.47,0.63),
        Vector3(1.52,1.18,1.88), armor)
    _box(root3, "G15_ShieldedRoof", Vector3(0,2.10,0.63),
        Vector3(1.60,0.17,1.96), light_armor)
    _box(root3, "G15_ShelterRear", Vector3(0,1.47,1.62),
        Vector3(1.48,1.14,0.11), dark)
    # True PBR rubber and mechanical hubs: no metallic tire finish.
    var wheels := Node3D.new()
    wheels.name = WHEEL_GROUP
    root3.add_child(wheels)
    for side in [-1,1]:
        for axle in range(3):
            var z := -1.27 + float(axle)*1.26
            _make_wheel(wheels, side, axle, z, hero, tire, machined, dark, paint)
            _box(root3, "G15_Fender_%s_%d" % [side, axle],
                Vector3(float(side)*0.84,0.76,z),
                Vector3(0.21,0.10,0.77), dark)
        _box(root3, "G15_SidePaint_%s" % side,
            Vector3(float(side)*0.773,1.49,0.74),
            Vector3(0.016,0.13,1.30), paint)
        _box(root3, "G15_CabPaint_%s" % side,
            Vector3(float(side)*0.722,1.55,-1.12),
            Vector3(0.017,0.12,0.37), paint)
        _box(root3, "G15_FrontLamp_%s" % side,
            Vector3(float(side)*0.54,0.94,-1.71),
            Vector3(0.24,0.13,0.04), glass)
        _box(root3, "G15_RearLamp_%s" % side,
            Vector3(float(side)*0.55,0.85,1.82),
            Vector3(0.21,0.12,0.04),
            _mat(Color("#b43e37"),0.10,0.30))
        _box(root3, "G15_FrontWindow_%s" % side,
            Vector3(float(side)*0.355,1.52,-1.651),
            Vector3(0.55,0.31,0.025), glass, Vector3(-17,0,0))
        _box(root3, "G15_Door_%s" % side,
            Vector3(float(side)*0.718,1.14,-1.02),
            Vector3(0.025,0.47,0.62), light_armor)
        _box(root3, "G15_DoorHandle_%s" % side,
            Vector3(float(side)*0.738,1.26,-0.82),
            Vector3(0.04,0.035,0.16), machined)
        _cylinder(root3, "G15_RearAntenna_%s" % side,
            Vector3(float(side)*0.49,2.35,1.33),
            0.018,0.63,machined,Vector3.ZERO,8)
    _box(root3, "G15_WindowDivider", Vector3(0,1.54,-1.678),
        Vector3(0.08,0.37,0.055), dark)
    for vent in range(7):
        _box(root3, "G15_ProtectedVent_%d" % vent,
            Vector3(-0.51+0.17*float(vent),2.205,0.83),
            Vector3(0.085,0.020,0.38), dark)
    # Deployable EW mast, phased array and directional parabolic radome.
    var mast := Node3D.new()
    mast.name = MAST
    mast.position = Vector3(0,2.22,0.44)
    root3.add_child(mast)
    _cylinder(mast, "G15_MastBase", Vector3(0,0.16,0),
        0.16,0.32,dark,Vector3.ZERO,16)
    _cylinder(mast, "G15_MastLower", Vector3(0,0.52,0),
        0.065,0.76,machined,Vector3.ZERO,12)
    _cylinder(mast, "G15_MastUpper", Vector3(0,1.11,0),
        0.039,0.46,light_armor,Vector3.ZERO,10)
    var head := Node3D.new()
    head.name = ROTOR
    head.position = Vector3(0,1.37,0)
    mast.add_child(head)
    _box(head, "G15_Crossbar", Vector3(0,0.06,0),
        Vector3(1.12,0.060,0.06), machined)
    for side in [-1,1]:
        _box(head, "G15_AntennaPanel_%s" % side,
            Vector3(float(side)*0.55,0.10,-0.02),
            Vector3(0.31,0.51,0.12), dark)
        _box(head, "G15_AntennaFace_%s" % side,
            Vector3(float(side)*0.55,0.10,-0.089),
            Vector3(0.27,0.43,0.017), light_armor)
        if hero:
            for slot in range(3):
                _box(head, "G15_ArraySlot_%s_%d" % [side,slot],
                    Vector3(float(side)*0.55,-0.03+0.13*float(slot),-0.105),
                    Vector3(0.20,0.028,0.022), dark)
    _cylinder(head, "G15_DirectionalDish", Vector3(0,0.15,0.17),
        0.29,0.07,light_armor,Vector3(90,0,0),24)
    _sphere(head, "G15_DishFeed", Vector3(0,0.15,0.23),
        Vector3(0.105,0.105,0.095), dark)
    var pulse := _sphere(head, PULSE,Vector3(0,0.15,0.34),
        Vector3(0.28,0.28,0.045),signal)
    pulse.visible = false
    # High-level details share the same base geometry; mobile LOD retains
    # unmistakable antenna / rear shelter silhouette.
    if hero:
        for side in [-1,1]:
            _box(root3, "G15_ServiceHatch_%s" % side,
                Vector3(float(side)*0.78,1.30,1.04),
                Vector3(0.03,0.34,0.42), light_armor)
            _box(root3, "G15_CoolingGrille_%s" % side,
                Vector3(float(side)*0.80,1.68,1.09),
                Vector3(0.03,0.19,0.50), dark)
            _box(root3, "G15_RoofPaint_%s" % side,
                Vector3(float(side)*0.54,2.197,-0.05),
                Vector3(0.20,0.018,0.37), paint)
        for rung in range(4):
            _box(root3, "G15_ServiceLadder_%d" % rung,
                Vector3(0.50,1.13+0.24*float(rung),1.70),
                Vector3(0.38,0.035,0.05),machined)
        for bracket in [-1,1]:
            _box(root3, "G15_RoofAntennaBrace_%s" % bracket,
                Vector3(float(bracket)*0.27,2.29,0.42),
                Vector3(0.045,0.27,0.22),machined,
                Vector3(0,0,float(bracket)*20))
    root.set_meta(FLAG,true)
    root.set_meta("tarvoka_g15_hero",hero)
    root.set_meta("tarvoka_g15_art_only",true)
    restore(root)
    return true

static func has_model(root: Node3D) -> bool:
    return root != null and bool(root.get_meta(FLAG,false)) and (
        root.find_child(CHASSIS,true,false) != null)

static func pose(root: Node3D, kind: String, amount: float,
        direction: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_model(root):
        return false
    var vehicle := root.find_child(CHASSIS,true,false) as Node3D
    var mast := root.find_child(MAST,true,false) as Node3D
    var head := root.find_child(ROTOR,true,false) as Node3D
    var wheels := root.find_child(WHEEL_GROUP,true,false) as Node3D
    var pulse := root.find_child(PULSE,true,false) as MeshInstance3D
    if vehicle == null or mast == null or head == null or wheels == null or pulse == null:
        return false
    var t := clampf(amount,0.0,1.0)
    vehicle.rotation.y = atan2(float(direction.x),-float(direction.y))
    mast.rotation_degrees.x = 0.0
    head.rotation_degrees.y = 0.0
    pulse.visible = false
    pulse.scale = Vector3(0.28,0.28,0.045)
    for wheel in wheels.get_children():
        (wheel as Node3D).rotation.x = 0.0
    match kind:
        "idle":
            pass
        "move":
            mast.rotation_degrees.x = -58.0
            for wheel in wheels.get_children():
                (wheel as Node3D).rotation.x = t * TAU * 1.8
        "deploy":
            mast.rotation_degrees.x = -58.0 * (1.0-t)
        "scan":
            head.rotation_degrees.y = t * 260.0
        "jam":
            head.rotation_degrees.y = 12.0 * sin(t*TAU)
            pulse.visible = true
            var radius := 0.28 + 0.20 * t
            pulse.scale = Vector3(radius,radius,0.045)
        "damage":
            mast.rotation_degrees.x = -10.0 * t
            vehicle.rotation_degrees.z = 3.0 * t
        _:
            restore(root)
            return false
    root.set_meta("tarvoka_g15_visual_pose",kind)
    return true

static func restore(root: Node3D) -> void:
    if not has_model(root):
        return
    var vehicle := root.find_child(CHASSIS,true,false) as Node3D
    var mast := root.find_child(MAST,true,false) as Node3D
    var head := root.find_child(ROTOR,true,false) as Node3D
    var wheels := root.find_child(WHEEL_GROUP,true,false) as Node3D
    var pulse := root.find_child(PULSE,true,false) as MeshInstance3D
    vehicle.rotation = Vector3.ZERO
    mast.rotation = Vector3.ZERO
    head.rotation = Vector3.ZERO
    pulse.visible = false
    pulse.scale = Vector3(0.28,0.28,0.045)
    for wheel in wheels.get_children():
        (wheel as Node3D).rotation = Vector3.ZERO
    root.set_meta("tarvoka_g15_visual_pose","idle")
