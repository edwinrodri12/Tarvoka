extends RefCounted
class_name TarvokaUnitModels3D

# First actual editable 3D geometry for TARVOKA. These eight models are native
# Godot MeshInstance3D trees, NOT SVG sprites or AI-rendered concept images.
# Tuned to existing approved category silhouettes; no tactical stats live here.
const ROLES := ["line","scout","apc","tank","mlrs","attack_heli","fighter","destroyer","aa_mobile"]
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const TankSurface = preload("res://scripts/ui/TankSurface3D.gd")
const TankRig = preload("res://scripts/ui/TankVisualRig3D.gd")
const TankDamage = preload("res://scripts/ui/TankDamage3D.gd")
const BastionDamage = preload("res://scripts/ui/BastionDamage3D.gd")
const BastionRig = preload("res://scripts/ui/BastionVisualRig3D.gd")
const G11Art = preload("res://scripts/ui/G11Art3D.gd")
const G11Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const G11Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const G13AA = preload("res://scripts/ui/G13MobileAirDefenseV1.gd")
const G13DetailV2 = preload("res://scripts/ui/G13DetailV2.gd")
const G13UndercarriageV6 = preload("res://scripts/ui/G13UndercarriageV6.gd")
const G13SurfaceV8 = preload("res://scripts/ui/G13SurfaceFinishV8.gd")
const AttackHelicopterV1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const AttackHelicopterCabinV2 = preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const AttackHelicopterRotorV3 = preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const AttackHelicopterEnginesV4 = preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const AttackHelicopterLandingV5 = preload("res://scripts/ui/AttackHelicopterLandingV5.gd")
const AttackHelicopterLandingFinishV6 = preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
const AttackHelicopterReadabilityV7 = preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
const AttackHelicopterSilhouetteV8 = preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const AttackHelicopterFinishV10 = preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
# Original production P06 sculpt: V1 sealed troop bay, V2 sculpted armored
# running gear, V3 wear/damage and V5 integrated roof/optical finish.
const APCArtV1 = preload("res://scripts/ui/APCArtV1.gd")
const APCArmorV2 = preload("res://scripts/ui/APCArmorV2.gd")
const APCFinishV3 = preload("res://scripts/ui/APCFinishV3.gd")
const APCDetailV5 = preload("res://scripts/ui/APCDetailV5.gd")
const APCFinishV6 = preload("res://scripts/ui/APCFinishV6.gd")
const APCMachineGunV7 = preload("res://scripts/ui/APCMachineGunV7.gd")
const APCDamageV7 = preload("res://scripts/ui/APCDamageV7.gd")
const APCRearDesignV10 = preload("res://scripts/ui/APCRearDesignV10.gd")
const APCExteriorV11 = preload("res://scripts/ui/APCExteriorV11.gd")
const APCTurretV12 = preload("res://scripts/ui/APCTurretV12.gd")
const APCSurfaceV13 = preload("res://scripts/ui/APCSurfaceV13.gd")
const APCWheelV14 = preload("res://scripts/ui/APCWheelV14.gd")
const APCUndercarriageV15 = preload("res://scripts/ui/APCUndercarriageV15.gd")
const APCJointFinishV16 = preload("res://scripts/ui/APCJointFinishV16.gd")
const APCContourV17 = preload("res://scripts/ui/APCContourV17.gd")
const APCWheelwellV18 = preload("res://scripts/ui/APCWheelwellV18.gd")
const APCUnifiedFlankV19 = preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const APCMicrodetailV20 = preload("res://scripts/ui/APCMicrodetailV20.gd")
const APCMaterialFinishV21 = preload("res://scripts/ui/APCMaterialFinishV21.gd")
const APCWeatherFinishV22 = preload("res://scripts/ui/APCWeatherFinishV22.gd")
const APCTireFinishV23 = preload("res://scripts/ui/APCTireFinishV23.gd")
const APCRubberArchV24 = preload("res://scripts/ui/APCRubberArchV24.gd")
const APCClosedTiresV25 = preload("res://scripts/ui/APCClosedTiresV25.gd")
const APCTacticalV8 = preload("res://scripts/ui/APCTacticalLOD8.gd")
const APCWeaponAudioV8 = preload("res://scripts/ui/APCWeaponAudioV8.gd")
const APCFullRigV1 = preload("res://scripts/ui/APCVisualRigV1.gd")
const TankFinish = preload("res://scripts/ui/TankFinish3D.gd")
const TankProduction = preload("res://scripts/ui/TankProduction3D.gd")
const TankSilhouette = preload("res://scripts/ui/TankSilhouetteV5.gd")
const TankArt = preload("res://scripts/ui/TankArtV6.gd")
const TankHero = preload("res://scripts/ui/TankHeroV7.gd")
const TankProductionV9 = preload("res://scripts/ui/TankProductionV9.gd")
const TankArmorV10 = preload("res://scripts/ui/TankArmorV10.gd")
const TANK_PAINT_META := "tarvoka_paint_zone"
const TANK_TURRET := "TorretaGiratoria"
const TANK_BARREL_PIVOT := "ElevacionCanon"
# Orthographic visual footprint, shared by in-game sprite captures and
# the inspection viewer. Each value leaves enough room for hull/rotors.
const PREVIEW_FRAME := {
    "line":3.05,"scout":3.05,"apc":3.55,"tank":3.75,
    "mlrs":4.05,"attack_heli":4.60,"fighter":4.65,"destroyer":5.10,
    "aa_mobile":3.85
}

static func preview_frame_height(role: String) -> float:
    return float(PREVIEW_FRAME.get(role,4.50))
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
                var point: Vector3 = points[index]
                surface.set_uv(Vector2(point.x*0.34+0.5,point.z*0.30+0.5))
                surface.add_vertex(point)
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
    # P06 Bastion v4: native Godot geometry, a distinct 6x6 APC rather than
    # a scaled tank or passenger vehicle. Forward is negative Z.
    # The large hull pieces are complete closed solids; no visible hollow rear.
    var chassis := Node3D.new()
    chassis.name = "Bastion_P06_Casco"
    root.add_child(chassis)
    _body(chassis,"Monocasco6x6",0.78,1.37,1.35,0.55,1.34,STEEL)
    _body(chassis,"SobrecascoInclinado",0.70,1.20,1.22,1.21,1.47,ARMOR)
    _box(chassis,"FrenteGlacis",Vector3(0,0.99,-1.30),
        Vector3(1.20,0.38,0.085),STEEL.darkened(0.09),Vector3(-25,0,0))
    _box(chassis,"Parachoques",Vector3(0,0.48,-1.41),
        Vector3(1.36,0.16,0.15),DARK)
    _box(chassis,"TechoBlindadoSellado",Vector3(0,1.48,0.13),
        Vector3(1.28,0.095,1.99),STEEL.darkened(0.06))
    _box(chassis,"UnionTechoFrontal",Vector3(0,1.48,-0.98),
        Vector3(1.06,0.085,0.22),DARK)
    _box(chassis,"PortonTraseroBlindado",Vector3(0,0.98,1.385),
        Vector3(1.18,0.91,0.11),STEEL.darkened(0.14))
    _box(chassis,"PanelCentralRampa",Vector3(0,0.94,1.454),
        Vector3(0.94,0.66,0.028),ARMOR)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(chassis,"BisagraRampa%s" % side,
            Vector3(sign*0.55,1.37,1.46),
            Vector3(0.12,0.10,0.11),BLACK)
        _box(chassis,"CierreRampa%s" % side,
            Vector3(sign*0.43,0.69,1.48),
            Vector3(0.095,0.16,0.06),DARK)
        _box(chassis,"PeldañoPosterior%s" % side,
            Vector3(sign*0.40,0.42,1.48),
            Vector3(0.33,0.09,0.23),DARK)
        # Each tyre is a real cylinder with a recessed dark sidewall,
        # separate metal hub and visible fixing bolts.
        _box(chassis,"CajaGuardabarros%s" % side,
            Vector3(sign*0.77,0.90,0),
            Vector3(0.19,0.14,2.65),DARK)
        for axle in range(3):
            var z: float = -0.91+float(axle)*0.91
            # Steering pivot holds the entire wheel assembly at the axle,
            # and a nested spin pivot keeps tyre, rim, hub and bolts coherent.
            var steering := Node3D.new()
            steering.name = "DireccionP06_%s_%d" % [side,axle]
            steering.position = Vector3(sign*0.79,0.355,z)
            chassis.add_child(steering)
            var wheel := Node3D.new()
            wheel.name = "GiroRuedaP06_%s_%d" % [side,axle]
            steering.add_child(wheel)
            _cylinder(wheel,"NeumaticoBastion%s_%d" % [side,axle],
                Vector3.ZERO,0.35,0.30,RUBBER,Vector3(0,0,90),20)
            _cylinder(wheel,"PerfilNeumatico%s_%d" % [side,axle],
                Vector3(sign*0.15,0,0),0.274,0.025,BLACK,
                Vector3(0,0,90),20)
            _cylinder(wheel,"RinBlindado%s_%d" % [side,axle],
                Vector3(sign*0.175,0,0),0.165,0.034,
                STEEL.darkened(0.16),Vector3(0,0,90),14)
            _cylinder(wheel,"BujeCentral%s_%d" % [side,axle],
                Vector3(sign*0.198,0,0),0.065,0.045,
                DARK,Vector3(0,0,90),12)
            for bolt in range(6):
                var angle: float = TAU*float(bolt)/6.0
                _sphere(wheel,"Tuerca%s_%d_%d" % [side,axle,bolt],
                    Vector3(sign*0.211,cos(angle)*0.118,
                        sin(angle)*0.118),
                    Vector3(0.034,0.034,0.034),METAL)
            # Segmented wheel arches with black relief, rather than
            # squared passenger-car wheel housings.
            _box(chassis,"ArcoAlto%s_%d" % [side,axle],
                Vector3(sign*0.82,0.75,z),
                Vector3(0.23,0.075,0.54),DARK)
            for edge in [-1,1]:
                _box(chassis,"ArcoExtremo%s_%d_%d" % [side,axle,edge],
                    Vector3(sign*0.82,0.65,z+float(edge)*0.31),
                    Vector3(0.23,0.19,0.075),DARK,
                    Vector3(float(edge)*19,0,0))
        # Armor modules and discrete paint panels can take any of the eight
        # official factions without tinting the whole APC.
        for panel in range(3):
            var pz: float = -0.66+float(panel)*0.77
            _box(chassis,"BlindajeLateral%s_%d" % [side,panel],
                Vector3(sign*0.75,1.15,pz),
                Vector3(0.16,0.35,0.56),ARMOR,
                Vector3(0,0,sign*9))
            _paint_box(chassis,"FaccionAPCPanel%s_%d" % [side,panel],
                Vector3(sign*0.846,1.29,pz),
                Vector3(0.018,0.070,0.34),"dark")
            _box(chassis,"JuntaLateral%s_%d" % [side,panel],
                Vector3(sign*0.845,1.13,pz+0.30),
                Vector3(0.023,0.31,0.023),BLACK)
        _box(chassis,"EspejoBlindado%s" % side,
            Vector3(sign*0.69,1.28,-1.20),
            Vector3(0.16,0.20,0.11),BLACK)
        _box(chassis,"PilotoTrasero%s" % side,
            Vector3(sign*0.57,0.76,1.46),
            Vector3(0.115,0.18,0.04),Color("#a34237"))
        _antenna(chassis,"RadioBastion%s" % side,
            Vector3(sign*0.54,1.54,0.96),0.63 if side<0 else 0.48)
    _box(chassis,"CristalConductorProtegido",Vector3(-0.34,1.23,-1.22),
        Vector3(0.31,0.16,0.065),GLASS,Vector3(-18,0,0))
    _box(chassis,"CristalCopilotoProtegido",Vector3(0.34,1.23,-1.22),
        Vector3(0.31,0.16,0.065),GLASS,Vector3(-18,0,0))
    _box(chassis,"MarcoCentralVisores",Vector3(0,1.27,-1.25),
        Vector3(0.09,0.23,0.086),DARK,Vector3(-18,0,0))
    for side in [-1,1]:
        _box(chassis,"FaroDelantero%s" % side,
            Vector3(float(side)*0.53,0.67,-1.37),
            Vector3(0.18,0.13,0.055),METAL)
        _box(chassis,"ProtectorFaro%s" % side,
            Vector3(float(side)*0.53,0.75,-1.41),
            Vector3(0.23,0.045,0.05),DARK)
    for slit in range(5):
        _box(chassis,"RejillaRefrigeracion_%d" % slit,
            Vector3(-0.38+float(slit)*0.19,1.54,0.78),
            Vector3(0.09,0.025,0.27),BLACK)
    _box(chassis,"EscotillaTripulacion",Vector3(-0.35,1.565,-0.42),
        Vector3(0.38,0.064,0.43),DARK)
    _box(chassis,"AsaEscotilla",Vector3(-0.35,1.625,-0.39),
        Vector3(0.24,0.045,0.055),METAL)

    var remote := Node3D.new()
    remote.name = "TorretaRemotaP06"
    remote.position = Vector3(0.17,1.55,0.08)
    root.add_child(remote)
    _cylinder(remote,"AnilloTorreta",Vector3.ZERO,0.27,0.11,
        BLACK,Vector3.ZERO,14)
    _box(remote,"BaseEstabilizada",Vector3(0,0.21,0),
        Vector3(0.49,0.30,0.50),DARK)
    _body(remote,"CarcasaSensores",0.29,0.32,0.33,0.30,0.56,ARMOR)
    _box(remote,"FrontalElectrooptico",Vector3(-0.12,0.40,-0.34),
        Vector3(0.20,0.19,0.085),GLASS)
    _sphere(remote,"OpticaTermica",Vector3(-0.12,0.40,-0.40),
        Vector3(0.11,0.11,0.045),BLACK)
    # Elevation and recoil are limited to the weapon, never the whole turret.
    var gun := Node3D.new()
    gun.name = "ElevacionArmaP06"
    gun.position = Vector3(0.13,0.42,-0.06)
    remote.add_child(gun)
    _cylinder(gun,"AmetralladoraRemota",Vector3(0,0,-0.49),
        0.040,0.86,BLACK,Vector3(90,0,0),12)
    _cylinder(gun,"BocachaRemota",Vector3(0,0,-0.93),
        0.064,0.11,DARK,Vector3(90,0,0),12)
    var flash := Node3D.new()
    flash.name = "EfectoFogonazoP06"
    flash.position = Vector3(0,0,-1.02)
    gun.add_child(flash)
    _tank_effect_mesh(flash,"LuzDisparoP06",Vector3(0,0,-0.10),
        Vector3(0.21,0.22,0.43),Color(1,0.74,0.28,0.88),true)
    flash.visible = false
    var discharge := Node3D.new()
    discharge.name = "EfectoHumoDisparoP06"
    discharge.position = Vector3(0,0,-1.08)
    gun.add_child(discharge)
    _tank_effect_mesh(discharge,"HumoBocaP06",Vector3(0,0,-0.11),
        Vector3(0.36,0.26,0.35),Color(0.52,0.57,0.60,0.35))
    discharge.visible = false
    var dust := Node3D.new()
    dust.name = "EfectoPolvoRuedasP06"
    root.add_child(dust)
    for side in [-1,1]:
        _tank_effect_mesh(dust,"PolvoP06%s" % side,
            Vector3(float(side)*0.92,0.15,1.20),
            Vector3(0.43,0.24,0.57),Color(0.60,0.57,0.49,0.30))
    dust.visible = false
    _box(remote,"CajaAlimentacion",Vector3(0.30,0.36,0.08),
        Vector3(0.24,0.24,0.30),STEEL)
    _paint_box(remote,"FaccionAPC_Torre",Vector3(0,0.58,0.10),
        Vector3(0.34,0.026,0.26))

# Small alpha-blended 3D effects belong to the rig. They are only shown
# during real tactical actions, not as permanently glowing weapons.
static func _tank_effect_mesh(parent: Node3D, label: String,
        pos: Vector3, volume: Vector3, tint: Color,
        emissive: bool = false) -> MeshInstance3D:
    var mesh: MeshInstance3D = _sphere(parent,label,pos,volume,tint)
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    if emissive:
        material.emission_enabled = true
        material.emission = Color("#FDC675")
    mesh.material_override = material
    return mesh

# MBT v2: recognizable modern low-profile armor, compound sloped glacis, turret,
# side skirt ERA, optic/cupola detail and an articulated long smoothbore cannon.
# This is in-game editable 3D geometry; no insignias, decals or faction crests.
static func _paint_box(parent: Node3D, label: String, pos: Vector3,
        dimensions: Vector3, zone: String = "accent",
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var item: MeshInstance3D = _box(parent,label,pos,dimensions,ARMOR,rotation)
    item.set_meta(TANK_PAINT_META,zone)
    return item

static func _paint_panels(node: Node, color: Color) -> int:
    var count := 0
    if node is MeshInstance3D and (node.has_meta(TANK_PAINT_META) or node.name.begins_with("Faccion")):
        var shape: MeshInstance3D = node as MeshInstance3D
        # The "Faccion*" naming convention survives glTF import; meshes may
        # also mark a more explicit zone using metadata in native Godot models.
        var zone: String = str(node.get_meta(TANK_PAINT_META,"dark" if node.name.contains("Franja") else "accent"))
        var original: StandardMaterial3D = shape.material_override as StandardMaterial3D
        var material: StandardMaterial3D = original.duplicate(true) as StandardMaterial3D if original != null else StandardMaterial3D.new()
        material.albedo_color = color.darkened(0.31) if zone == "dark" else color
        material.metallic = 0.16
        material.roughness = 0.68
        shape.material_override = material
        count += 1
    for child in node.get_children():
        count += _paint_panels(child,color)
    return count

static func faction_paint_color(faction: int) -> Color:
    # Muted military enamel: official faction hue, reserved for a handful
    # of replaceable panels, never an all-over body tint.
    var source: Color = VisualStyle.faction_color(faction)
    return Color("#364955").lerp(source,0.86) if faction >= 0 and faction < VisualStyle.FACTIONS.size() else ARMOR

static func apply_faction_palette(model: Node3D, faction: int) -> int:
    # Independently generated models receive independent StandardMaterial3D
    # instances; recoloring a tank cannot modify any other unit.
    if model == null or faction < 0 or faction >= VisualStyle.FACTIONS.size():
        return 0
    return _paint_panels(model,faction_paint_color(faction))

static func paintable_count(model: Node) -> int:
    if model == null:
        return 0
    var total := 1 if model is MeshInstance3D and (model.has_meta(TANK_PAINT_META) or model.name.begins_with("Faccion")) else 0
    for child in model.get_children():
        total += paintable_count(child)
    return total

static func _tank(root: Node3D) -> void:
    # Hull footprint stays within old model bounds so 24x18/40x30 maps and
    # the existing orthographic camera still display the complete silhouette.
    var hull := Node3D.new()
    hull.name = "ChasisBlindado"
    root.add_child(hull)
    _body(hull,"MonocascoBlindajeCompuesto",0.86,1.47,1.45,0.36,0.96,STEEL)
    _body(hull,"PlacaGlacisInclinada",0.75,1.47,-0.12,0.84,1.06,STEEL.darkened(0.06))
    _box(hull,"NervioProa",Vector3(0.0,0.68,-1.35),
        Vector3(1.30,0.18,0.12),DARK)
    _box(hull,"PlacaBasalFrontal",Vector3(0,0.46,-1.33),
        Vector3(1.36,0.17,0.12),ARMOR,Vector3(26,0,0))
    _box(hull,"CubiertaMotor",Vector3(0,0.99,0.89),
        Vector3(1.36,0.10,0.80),DARK)
    for n in range(8):
        _box(hull,"RejillaMotor_%02d" % n,Vector3(-0.49+float(n%4)*0.33,1.055,
            0.61+float(int(n/4))*0.32),Vector3(0.21,0.024,0.23),BLACK)
    for n in range(3):
        _box(hull,"LamasRefrigeracion_%02d" % n,
            Vector3(-0.38+float(n)*0.38,1.055,1.26),
            Vector3(0.24,0.02,0.08),METAL)
    _box(hull,"TapaConductor",Vector3(-0.40,1.04,-0.78),
        Vector3(0.31,0.07,0.38),DARK)
    _box(hull,"PeriscopioConductor",Vector3(-0.40,1.11,-1.02),
        Vector3(0.24,0.13,0.10),GLASS)
    for side in [-1,1]:
        var sign: float = float(side)
        var x: float = sign*0.94
        _box(hull,"BandaOruga%s" % side,Vector3(x,0.32,0),
            Vector3(0.37,0.47,2.84),RUBBER)
        _box(hull,"GuiaOruga%s" % side,Vector3(sign*0.91,0.51,0),
            Vector3(0.42,0.14,2.70),DARK)
        # Continuous visible tread edges, not seven isolated wheels. Their
        # closed dark profile is independent of the faction-colored skirts.
        _box(hull,"CintaSuperiorOruga%s" % side,Vector3(sign*1.213,0.52,0),
            Vector3(0.12,0.135,2.50),RUBBER)
        _box(hull,"CintaInferiorOruga%s" % side,Vector3(sign*1.213,0.09,0),
            Vector3(0.12,0.13,2.50),RUBBER)
        for end in [-1,1]:
            _cylinder(hull,"ExtremoCinta%s_%s" % [side,end],
                Vector3(sign*1.225,0.305,float(end)*1.23),
                0.28,0.075,RUBBER,Vector3(0,0,90),18)
        for t in range(15):
            var offset: float = -1.21 + float(t)*0.173
            _box(hull,"EslabonTreadSuperior%s_%02d" % [side,t],
                Vector3(sign*1.281,0.58,offset),
                Vector3(0.075,0.045,0.105),DARK)
            _box(hull,"EslabonTreadInferior%s_%02d" % [side,t],
                Vector3(sign*1.281,0.05,offset),
                Vector3(0.075,0.045,0.105),DARK)
        for n in range(7):
            var z: float = -1.13+float(n)*0.38
            _cylinder(hull,"Rodillo%s_%02d" % [side,n],
                Vector3(sign*1.14,0.29,z),0.16,0.065,STEEL.darkened(0.19),
                Vector3(0,0,90),12)
            _cylinder(hull,"BujeOscuro%s_%02d" % [side,n],
                Vector3(sign*1.18,0.29,z),0.07,0.035,BLACK,
                Vector3(0,0,90),10)
        for n in range(10):
            var z: float = -1.24+float(n)*0.277
            _box(hull,"ZapataOruga%s_%02d" % [side,n],
                Vector3(sign*1.158,0.11,z),Vector3(0.038,0.08,0.24),DARK)
        # Painted replaceable upper skirt modules, not full hull camouflage.
        for n in range(5):
            var z: float = -1.07+float(n)*0.54
            # On the physical 242323 capture the broad enamel rectangles
            # looked like bright passenger-bus side panels. Keep all fourteen
            # original paint zones, but make color an armored identification
            # stripe over a dark removable steel skirt, not the whole skirt.
            _box(hull,"FaldonBase%s_%02d" % [side,n],
                Vector3(sign*1.180,0.69,z),
                Vector3(0.087,0.34,0.49),DARK)
            _paint_box(hull,"FaccionFaldon%s_%02d" % [side,n],
                Vector3(sign*1.235,0.72,z),
                Vector3(0.024,0.135,0.433))
            _box(hull,"SeparadorFaldon%s_%02d" % [side,n],
                Vector3(sign*1.223,0.69,z+0.255),
                Vector3(0.071,0.38,0.022),BLACK)
        for n in range(4):
            var z: float = -1.00+float(n)*0.58
            _box(hull,"ModuloERAChasis%s_%02d" % [side,n],
                Vector3(sign*0.755,1.013,z),
                Vector3(0.26,0.12,0.43),ARMOR)
        _box(hull,"GuardabarrosFrontal%s" % side,
            Vector3(sign*1.13,0.69,-1.39),
            Vector3(0.42,0.16,0.29),DARK)
        _box(hull,"EscapePosterior%s" % side,
            Vector3(sign*0.79,0.81,1.38),
            Vector3(0.22,0.17,0.13),BLACK)

    var turret := Node3D.new()
    turret.name = TANK_TURRET
    turret.position = Vector3(0,1.11,-0.15)
    root.add_child(turret)
    _cylinder(root,"AnilloDeGiro",Vector3(0,1.045,-0.15),
        0.64,0.18,BLACK,Vector3.ZERO,16)
    # Low, sloped turret and composite front cheeks; center is turret-local.
    _body(turret,"TorreBlindada",0.69,0.92,0.71,0.0,0.43,STEEL)
    _body(turret,"SobreblindajeTorre",0.57,0.67,0.45,0.39,0.53,STEEL.darkened(0.10))
    for side in [-1,1]:
        var sign: float = float(side)
        _box(turret,"MejillaBlindada%s" % side,
            Vector3(sign*0.45,0.23,-0.70),
            Vector3(0.37,0.37,0.42),STEEL,
            Vector3(-13,sign*19,0))
        for n in range(3):
            _box(turret,"ProteccionERA%s_%d" % [side,n],
                Vector3(sign*0.675,0.245,-0.45+float(n)*0.39),
                Vector3(0.10,0.25,0.31),DARK)
        # Short accent strips and the roof identification panels can be
        # colored without requiring eight separate tank meshes.
        _paint_box(turret,"FaccionFranjaTorre%s" % side,
            Vector3(sign*0.72,0.407,0.12),
            Vector3(0.063,0.075,0.63),"dark")
        _paint_box(turret,"FaccionPlacaSuperior%s" % side,
            Vector3(sign*0.37,0.547,0.04),
            Vector3(0.29,0.027,0.31))
        _box(turret,"CestaEquipamiento%s" % side,
            Vector3(sign*0.57,0.23,0.67),
            Vector3(0.27,0.24,0.32),DARK)
        for smoke in range(3):
            _cylinder(turret,"LanzaFumigenas%s_%d" % [side,smoke],
                Vector3(sign*(0.71+float(smoke)*0.055),0.38,-0.38+float(smoke)*0.13),
                0.051,0.22,BLACK,Vector3(0,0,69),8)
        _antenna(turret,"AntenaTorre%s" % side,
            Vector3(sign*0.52,0.52,0.54),0.52 if side<0 else 0.67)

    var gun := Node3D.new()
    gun.name = TANK_BARREL_PIVOT
    gun.position = Vector3(0.0,0.235,-0.56)
    turret.add_child(gun)
    _cylinder(gun,"Canon120mm",Vector3(0.0,0,-1.18),
        0.103,2.54,DARK,Vector3(90,0,0),16)
    _cylinder(gun,"ManguitoTermico",Vector3(0.0,0,-0.82),
        0.146,0.76,STEEL,Vector3(90,0,0),14)
    _cylinder(gun,"ExtractorGases",Vector3(0.0,0,-1.12),
        0.17,0.30,ARMOR,Vector3(90,0,0),14)
    _cylinder(gun,"BocaCanon",Vector3(0.0,0,-2.46),
        0.139,0.08,BLACK,Vector3(90,0,0),14)
    _box(gun,"EscudoMantlete",Vector3(0,0.025,-0.28),
        Vector3(0.48,0.37,0.22),ARMOR)
    _box(turret,"PantallaTermica",Vector3(0.47,0.62,-0.41),
        Vector3(0.27,0.25,0.34),DARK)
    _box(turret,"CristalTermico",Vector3(0.47,0.63,-0.602),
        Vector3(0.21,0.12,0.025),GLASS)
    _cylinder(turret,"BaseEscotillaComandante",Vector3(-0.37,0.55,0.12),
        0.26,0.12,BLACK,Vector3.ZERO,14)
    _cylinder(turret,"EscotillaComandante",Vector3(-0.37,0.628,0.12),
        0.24,0.07,STEEL,Vector3.ZERO,14)
    for n in range(6):
        var a: float = float(n)*TAU/6.0
        _box(turret,"VisorComandante_%d" % n,
            Vector3(-0.37+cos(a)*0.23,0.61,0.12+sin(a)*0.23),
            Vector3(0.075,0.11,0.08),GLASS)
    var rws := Node3D.new()
    rws.name = "ArmaSecundariaEstabilizada"
    rws.position = Vector3(-0.37,0.72,0.12)
    turret.add_child(rws)
    _box(rws,"ReceptorAmetralladora",Vector3(0,0.15,-0.09),
        Vector3(0.23,0.20,0.33),BLACK)
    _cylinder(rws,"CanonAmetralladora",Vector3(0,0.145,-0.39),
        0.029,0.68,BLACK,Vector3(90,0,0),10)
    _box(rws,"MunicionAmetralladora",Vector3(0.18,0.15,0.04),
        Vector3(0.16,0.22,0.23),DARK)
    _box(rws,"CamaraArma",Vector3(-0.12,0.27,-0.15),
        Vector3(0.12,0.12,0.15),GLASS)
    var muzzle_flash := Node3D.new()
    muzzle_flash.name = "EfectoFogonazoCanon"
    gun.add_child(muzzle_flash)
    muzzle_flash.position = Vector3(0.0,0.0,-2.53)
    _tank_effect_mesh(muzzle_flash,"NucleoLuminoso",Vector3(0,0,-0.12),
        Vector3(0.42,0.37,0.74),Color(1,0.72,0.21,0.9),true)
    _tank_effect_mesh(muzzle_flash,"LuzFogonazo",Vector3(0,0,-0.34),
        Vector3(0.19,0.25,0.88),Color(1,0.91,0.58,0.95),true)
    muzzle_flash.visible = false

    var smoke := Node3D.new()
    smoke.name = "EfectoHumoCanon"
    gun.add_child(smoke)
    smoke.position = Vector3(0.0,0.11,-2.67)
    _tank_effect_mesh(smoke,"NubeHumo",Vector3(0,0,-0.12),
        Vector3(0.52,0.37,0.54),Color(0.55,0.60,0.64,0.43))
    _tank_effect_mesh(smoke,"VahoHumo",Vector3(0.15,0.24,-0.21),
        Vector3(0.36,0.42,0.40),Color(0.70,0.75,0.78,0.26))
    smoke.visible = false

    var dust := Node3D.new()
    dust.name = "EfectoPolvoOrugas"
    root.add_child(dust)
    for side in [-1,1]:
        _tank_effect_mesh(dust,"NubePolvo%s" % side,
            Vector3(float(side)*1.15,0.17,1.42),
            Vector3(0.59,0.39,0.63),Color(0.55,0.52,0.44,0.34))
    dust.visible = false

    var battle_damage := Node3D.new()
    battle_damage.name = "EfectoImpactoBlindaje"
    turret.add_child(battle_damage)
    _tank_effect_mesh(battle_damage,"EscarchaHumo",
        Vector3(0.46,0.68,-0.35),
        Vector3(0.68,0.45,0.51),Color(0.12,0.14,0.16,0.48))
    battle_damage.visible = false
    # No shields or faction logos anywhere in the model.

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

static func build(role: String, faction: int = -1, finish_enabled: bool = true, art_level: int = 10) -> Node3D:
    if not supports(role):
        return null
    var imported: Node3D = _imported_model(role)
    if imported != null:
        if role == "tank":
            apply_faction_palette(imported,faction)
            TankDamage.prepare(imported)
        elif role == "apc":
            apply_faction_palette(imported,faction)
            BastionDamage.prepare(imported)
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
            # Art level 8 is a separate native lightweight *same silhouette*
            # profile for eight-player Android boards. Older art-level 6
            # remains accessible for backwards-compatible P06 visual tests.
            if not finish_enabled and art_level==8:
                if not APCTacticalV8.build(model,faction_paint_color(faction)):
                    _apc(model)
            elif not (finish_enabled and art_level >= 13):
                _apc(model)
        "tank":
            _tank(model)
        "mlrs":
            # G11: preserve the hero sculpt in Studio; batch wheels and tubes
            # into a lighter native 3D model for the Android battle camera.
            if not (finish_enabled and art_level >= 13):
                if not G11Mobile.build(model,faction_paint_color(faction),art_level):
                    _mlrs(model)
        "attack_heli":
            if not (finish_enabled and art_level >= 13):
                _helicopter(model)
        "fighter":
            _fighter(model)
        "destroyer":
            _destroyer(model)
        "aa_mobile":
            # G13 V1 is an ART preview role only. It is deliberately NOT
            # registered as a playable BattleSession unit yet.
            if not G13AA.build(model,faction_paint_color(faction),
                    finish_enabled and art_level>=13):
                return null
            if finish_enabled and art_level>=13:
                if not G13DetailV2.apply(model,faction_paint_color(faction)):
                    push_warning("G13 V2 detail failed to apply")
                if not G13UndercarriageV6.install(model):
                    push_warning("G13 V6 undercarriage failed to apply")
                if not G13SurfaceV8.apply(model,faction_paint_color(faction)):
                    push_warning("G13 V8 surface finish failed to apply")
    if role in ["line","scout"]:
        model.scale = Vector3.ONE * 0.82
        model.position.y = -0.58
    elif role in ["attack_heli","fighter","destroyer"]:
        model.scale = Vector3.ONE * 0.77
        model.position.y = -0.11
    elif role=="aa_mobile":
        # Grounded four-wheel AA chassis: its 0.33m wheel centers must NOT
        # inherit the -0.27m offset used by old tracked 3D proxies.
        # The 0.31m radii now sit above the terrain with 0.017m margin.
        model.scale=Vector3.ONE*0.83
        model.position.y=0.0
    else:
        model.scale = Vector3.ONE * 0.83
        model.position.y = -0.27
    # G11 shares the launcher role with the tactical atlas without altering stats.
    if role == "mlrs" and finish_enabled and art_level >= 13:
        G11Art.build(model,faction_paint_color(faction))
    if role == "attack_heli" and finish_enabled and art_level >= 13:
        if AttackHelicopterV1.build(model,faction_paint_color(faction)):
            if AttackHelicopterCabinV2.apply(model,faction_paint_color(faction)):
                if AttackHelicopterRotorV3.apply(model,faction_paint_color(faction)):
                    if AttackHelicopterEnginesV4.apply(model,faction_paint_color(faction)):
                        if AttackHelicopterLandingV5.apply(model,faction_paint_color(faction)):
                            if AttackHelicopterLandingFinishV6.apply(model,faction_paint_color(faction)):
                                if AttackHelicopterReadabilityV7.apply(model,faction_paint_color(faction)):
                                    if AttackHelicopterSilhouetteV8.apply(model,faction_paint_color(faction)):
                                        AttackHelicopterFinishV10.apply(model,faction_paint_color(faction))
    # Studio-quality P06 is the actual sculpted V5 source, never the
    # simplified P06 procedural prototype shown in the previous web release.
    # Battle map LOD (art_level <= 10) stays lightweight by default.
    if role == "apc" and finish_enabled and art_level >= 13:
        var enamel: Color = faction_paint_color(faction)
        if APCArtV1.apply(model,enamel):
            if APCArmorV2.apply(model,enamel):
                if APCFinishV3.apply(model,enamel):
                    if APCDetailV5.apply(model,enamel):
                        if art_level >= 14:
                            if APCFinishV6.apply(model,enamel):
                                if APCMachineGunV7.prepare(model):
                                    APCWeaponAudioV8.prepare(model)
                                if APCDamageV7.prepare(model):
                                    if APCRearDesignV10.apply(model,enamel):
                                        if APCExteriorV11.apply(model,enamel):
                                            if APCTurretV12.apply(model,enamel):
                                                if APCSurfaceV13.apply(model,enamel):
                                                    if APCWheelV14.apply(model,enamel):
                                                        if APCUndercarriageV15.apply(model,enamel):
                                                            if APCJointFinishV16.apply(model,enamel):
                                                                if APCContourV17.apply(model,enamel):
                                                                    if APCWheelwellV18.apply(model,enamel):
                                                                        if APCUnifiedFlankV19.apply(model,enamel):
                                                                            if APCMicrodetailV20.apply(model,enamel):
                                                                                if APCMaterialFinishV21.apply(model,enamel):
                                                                                    if APCWeatherFinishV22.apply(model):
                                                                                        if APCTireFinishV23.apply(model):
                                                                                            if APCRubberArchV24.apply(model):
                                                                                                APCClosedTiresV25.apply(model)
    if role == "tank":
        # Physical finish is authored on the neutral geometry BEFORE PBR and
        # strictly independent of the fourteen faction-color mesh panels.
        if finish_enabled:
            TankFinish.apply(model)
            TankProduction.apply(model)
            # Shape overhaul: truly sealed armored hull and turret from all
            # angles, not accessory detail layered over the first blockout.
            TankSilhouette.apply(model)
            TankArt.apply(model)
            if art_level >= 7:
                TankHero.apply(model)
                if art_level >= 9:
                    TankProductionV9.apply(model)
                    if art_level >= 10:
                        TankArmorV10.apply(model)
        apply_faction_palette(model,faction)
        TankSurface.apply_finish(model)
        if finish_enabled and art_level >= 7:
            # Reapply the authored high-resolution military UV armor coat after
            # the generic five-family PBR pass; battle/Android/Web share it.
            TankHero.apply_final_materials(model)
            if art_level >= 9:
                TankProductionV9.restore_materials(model)
                if art_level >= 10:
                    TankArmorV10.finish_materials(model)
        TankDamage.prepare(model)
    elif role == "apc":
        apply_faction_palette(model,faction)
        # Sculpted V5 owns its physical damage rig. Only the fallback P06
        # prototype uses the original procedural 5-stage damage subsystem.
        if not model.get_meta("tarvoka_apc_finish_v3",false) and not APCTacticalV8.has_model(model):
            BastionDamage.prepare(model)
    # Studio-quality P06 is the actual sculpted V5 source, never the
    # simplified P06 procedural prototype shown in the previous web release.
    # Battle map LOD (art_level <= 10) stays lightweight by default.
    if role == "apc" and finish_enabled and art_level >= 13:
        var enamel: Color = faction_paint_color(faction)
        if APCArtV1.apply(model,enamel):
            if APCArmorV2.apply(model,enamel):
                if APCFinishV3.apply(model,enamel):
                    if APCDetailV5.apply(model,enamel):
                        if art_level >= 14:
                            if APCFinishV6.apply(model,enamel):
                                if APCMachineGunV7.prepare(model):
                                    APCWeaponAudioV8.prepare(model)
                                if APCDamageV7.prepare(model):
                                    if APCRearDesignV10.apply(model,enamel):
                                        if APCExteriorV11.apply(model,enamel):
                                            if APCTurretV12.apply(model,enamel):
                                                if APCSurfaceV13.apply(model,enamel):
                                                    if APCWheelV14.apply(model,enamel):
                                                        if APCUndercarriageV15.apply(model,enamel):
                                                            if APCJointFinishV16.apply(model,enamel):
                                                                if APCContourV17.apply(model,enamel):
                                                                    if APCWheelwellV18.apply(model,enamel):
                                                                        if APCUnifiedFlankV19.apply(model,enamel):
                                                                            if APCMicrodetailV20.apply(model,enamel):
                                                                                if APCMaterialFinishV21.apply(model,enamel):
                                                                                    if APCWeatherFinishV22.apply(model):
                                                                                        if APCTireFinishV23.apply(model):
                                                                                            if APCRubberArchV24.apply(model):
                                                                                                APCClosedTiresV25.apply(model)
    if role == "tank":
        # Physical finish is authored on the neutral geometry BEFORE PBR and
        # strictly independent of the fourteen faction-color mesh panels.
        if finish_enabled:
            TankFinish.apply(model)
            TankProduction.apply(model)
            # Shape overhaul: truly sealed armored hull and turret from all
            # angles, not accessory detail layered over the first blockout.
            TankSilhouette.apply(model)
            TankArt.apply(model)
            if art_level >= 7:
                TankHero.apply(model)
                if art_level >= 9:
                    TankProductionV9.apply(model)
                    if art_level >= 10:
                        TankArmorV10.apply(model)
        apply_faction_palette(model,faction)
        TankSurface.apply_finish(model)
        if finish_enabled and art_level >= 7:
            # Reapply the authored high-resolution military UV armor coat after
            # the generic five-family PBR pass; battle/Android/Web share it.
            TankHero.apply_final_materials(model)
            if art_level >= 9:
                TankProductionV9.restore_materials(model)
                if art_level >= 10:
                    TankArmorV10.finish_materials(model)
        TankDamage.prepare(model)
    elif role == "apc":
        apply_faction_palette(model,faction)
        # Sculpted V5 owns its physical damage rig. Only the fallback P06
        # prototype uses the original procedural 5-stage damage subsystem.
        if not model.get_meta("tarvoka_apc_finish_v3",false) and not APCTacticalV8.has_model(model):
            BastionDamage.prepare(model)
    return model

# Single entrypoint for battle/studio visual poses. No gameplay state is changed.
# Old unit roles keep their existing renderer and pose behavior.
static func pose_model(role: String, model: Node3D, kind: String,
        progress: float, target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    match role:
        "tank":
            return TankRig.pose(model,kind,progress,target_heading)
        "apc":
            if APCTacticalV8.has_model(model):
                return APCTacticalV8.pose(model,kind,progress,target_heading)
            if model.get_meta("tarvoka_apc_sculpt_v1",false):
                return APCFullRigV1.pose(
                    model,kind,progress,rad_to_deg(
                        atan2(float(target_heading.x),-float(target_heading.y))))
            return BastionRig.pose(model,kind,progress,target_heading)
        "mlrs":
            if G11Mobile.has_model(model):
                return G11Mobile.pose(model,kind,progress,target_heading)
            return G11Rig.pose(model,kind,progress,target_heading)
        "attack_heli":
            return AttackHelicopterV1.pose(model,kind,progress,target_heading)
        "aa_mobile":
            return G13AA.pose(model,kind,progress,target_heading)
    return false

static func restore_model_pose(role: String, model: Node3D) -> void:
    match role:
        "tank":
            TankRig.restore(model)
        "apc":
            if APCTacticalV8.has_model(model):
                APCTacticalV8.restore(model)
            elif model.get_meta("tarvoka_apc_sculpt_v1",false):
                APCFullRigV1.restore(model)
            else:
                BastionRig.restore(model)
        "mlrs":
            if G11Mobile.has_model(model):
                G11Mobile.restore(model)
            else:
                G11Rig.restore(model)
        "attack_heli":
            AttackHelicopterV1.restore(model)
        "aa_mobile":
            G13AA.restore(model)

static func inspect_meshes(model: Node) -> int:
    if model == null:
        return 0
    var count := 1 if model is MeshInstance3D else 0
    for child in model.get_children():
        count += inspect_meshes(child)
    return count
