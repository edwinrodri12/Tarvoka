extends RefCounted
class_name TarvokaUnitModels3D

# First actual editable 3D geometry for TARVOKA. These eight models are native
# Godot MeshInstance3D trees, NOT SVG sprites or AI-rendered concept images.
# Tuned to existing approved category silhouettes; no tactical stats live here.
const ROLES := ["line","scout","apc","tank","mlrs","attack_heli","fighter","destroyer","aa_mobile","mobile_aa","ew_mobile","logistics_mobile","infantry_urban","infantry_defense","infantry_antitank","infantry_engineer",
    "infantry_sniper","infantry_logistic","infantry_medic","infantry_commando"]
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
const G15EW = preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const InfantryFamily = preload("res://scripts/ui/InfantryFamilyV1.gd")
const InfantryFinishV2 = preload("res://scripts/ui/InfantrySculptFinishV2.gd")
const InfantryVariantsV4 = preload("res://scripts/ui/InfantryVariantsV4.gd")
const InfantryEngineerV5 = preload("res://scripts/ui/InfantryEngineerSilhouetteV5.gd")
const InfantryEngineerV6 = preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const InfantryEngineerV7 = preload("res://scripts/ui/InfantryEngineerCompletenessV7.gd")
const InfantryEngineerV8 = preload("res://scripts/ui/InfantryEngineerPremiumV8.gd")
const InfantryEngineerV9 = preload("res://scripts/ui/InfantryEngineerFinishV9.gd")
const InfantryEngineerV10 = preload("res://scripts/ui/InfantryEngineerAnatomyV10.gd")
const InfantryEngineerV11 = preload("res://scripts/ui/InfantryEngineerMechanicsV11.gd")
const G16LogisticsV1 = preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const G16ExteriorV2 = preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const G16MechanicsV3 = preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const G16SculptV4 = preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const G16MaterialsV5 = preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const G16ServiceV6 = preload("res://scripts/ui/G16DeployableSupplyHardwareV6.gd")
const G15SculptV2 = preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const G15ShellV3 = preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const G15AntennaV4 = preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const G15FinishDamageV5 = preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const G15ExteriorV6 = preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const G15MechanicalV7 = preload("res://scripts/ui/G15MechanicalExteriorV7.gd")
const G15ContinuityV8 = preload("res://scripts/ui/G15ContinuitySuspensionV8.gd")
const G15SurfaceV9 = preload("res://scripts/ui/G15ProductionSurfaceV9.gd")
const G15OpticalV10 = preload("res://scripts/ui/G15OpticalGlazingV10.gd")
const G15DetailV11 = preload("res://scripts/ui/G15Detail360V11.gd")
const G13DetailV2 = preload("res://scripts/ui/G13DetailV2.gd")
const G13UndercarriageV6 = preload("res://scripts/ui/G13UndercarriageV6.gd")
const G13SurfaceV8 = preload("res://scripts/ui/G13SurfaceFinishV8.gd")
const G13SilhouetteV10 = preload("res://scripts/ui/G13SilhouetteV10.gd")
const G13CabRearV11 = preload("res://scripts/ui/G13CabRearFinishV11.gd")
const G13BodyFinishV11 = preload("res://scripts/ui/G13BodyFinishV11.gd")
const G13MechanicalV12 = preload("res://scripts/ui/G13MechanicalFinishV12.gd")
const G13SurfaceV13 = preload("res://scripts/ui/G13SurfaceFinishV13.gd")
const G13SensorsV14 = preload("res://scripts/ui/G13SensorSculptV14.gd")
const G13TurretV15 = preload("res://scripts/ui/G13TurretFinishV15.gd")
const G13BatchesV16 = preload("res://scripts/ui/G13StaticBatchV16.gd")
const G13CannonV18 = preload("res://scripts/ui/G13AutocannonSculptV18.gd")
const G13JointV19 = preload("res://scripts/ui/G13GunTrunnionV19.gd")
const G13ArmorV20 = preload("res://scripts/ui/G13TurretArmorV20.gd")
const G13SidesV21 = preload("res://scripts/ui/G13SideArmorV21.gd")
const G13UndersideV22 = preload("res://scripts/ui/G13UnderbodyAuditV22.gd")
const G13FrontV23 = preload("res://scripts/ui/G13FrontLightingV23.gd")
const G13IntakeV24 = preload("res://scripts/ui/G13ArmoredIntakeV24.gd")
const G13TacticalV25 = preload("res://scripts/ui/G13TacticalSilhouetteV25.gd")
const G13ArmorV26 = preload("res://scripts/ui/G13TacticalArmorV26.gd")
const G13RadarV27 = preload("res://scripts/ui/G13ElevatedRadarV27.gd")
const G13DeckV28 = preload("res://scripts/ui/G13RadarDeckMountV28.gd")
const G13FoldV29 = preload("res://scripts/ui/G13FoldingRadarV29.gd")
const G13StowageV30 = preload("res://scripts/ui/G13RadarStowageV30.gd")
const G13GunMountV31 = preload("res://scripts/ui/G13GunMountFinishV31.gd")
const G13FactionV32 = preload("res://scripts/ui/G13FactionMountFinishV32.gd")
const G13ChassisV33 = preload("res://scripts/ui/G13ChassisFinishV33.gd")
const G13ClosureV34 = preload("res://scripts/ui/G13BodyClosureV34.gd")
const G13RearV35 = preload("res://scripts/ui/G13RearServiceFinishV35.gd")
const G13ProportionsV36 = preload("res://scripts/ui/G13ProportionFinishV36.gd")
const G13RoofRadarV37 = preload("res://scripts/ui/G13RoofRadarFinishV37.gd")
const G13JoineryV38 = preload("res://scripts/ui/G13BodyJoineryV38.gd")
const G13UndersealV39 = preload("res://scripts/ui/G13UndersealFinishV39.gd")
const G13SilhouetteV40 = preload("res://scripts/ui/G13SilhouetteFinishV40.gd")
const G13ContourV41 = preload("res://scripts/ui/G13ContourPolishV41.gd")
const G13ArcEndsV42 = preload("res://scripts/ui/G13ArcTerminationV42.gd")
const G13ExteriorV44 = preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const G13CabV45 = preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const G13WheelV46 = preload("res://scripts/ui/G13WheelMachiningV46.gd")
const G13SurfaceV47 = preload("res://scripts/ui/G13MaterialFinishV47.gd")
const G13SculptV48 = preload("res://scripts/ui/G13SculptFinishV48.gd")
const G13SeamsV49 = preload("res://scripts/ui/G13SeamlessSilhouetteV49.gd")
const G13GlazingV50 = preload("res://scripts/ui/G13GlazingFitV50.gd")
const G13RoofV51 = preload("res://scripts/ui/G13CabRoofIntegrationV51.gd")
const G13RoofRailsV52 = preload("res://scripts/ui/G13RoofShoulderFitV52.gd")
const G13RealismV53 = preload("res://scripts/ui/G13MaterialRealismV53.gd")
const G13RubberV54 = preload("res://scripts/ui/G13RubberSculptV54.gd")
const G13MicroV55 = preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const G13JointV56 = preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const G13VisibleV57 = preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const G13VisibleV58 = preload("res://scripts/ui/G13IsometricMechanicalFinishV58.gd")
const G13PremiumV59 = preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const G13TreadV60 = preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const G13WheelArmorV61 = preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const G13GlassV62 = preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const G13FactionV63 = preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const G13EdgesV64 = preload("res://scripts/ui/G13ArmorEdgeFinishV64.gd")
const G13RingV65 = preload("res://scripts/ui/G13TurretRingFinishV65.gd")
const G13MountV66 = preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const G13FeedV67 = preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const G13EjectorV68 = preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const G13MuzzleV69 = preload("res://scripts/ui/G13MuzzleMountFinishV69.gd")
const G13LODPolicyV17 = preload("res://scripts/ui/G13LODPolicyV17.gd")
const AttackHelicopterV1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const AttackHelicopterCabinV2 = preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const AttackHelicopterRotorV3 = preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const AttackHelicopterEnginesV4 = preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const AttackHelicopterLandingV5 = preload("res://scripts/ui/AttackHelicopterLandingV5.gd")
const AttackHelicopterLandingFinishV6 = preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
const AttackHelicopterReadabilityV7 = preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
const AttackHelicopterSilhouetteV8 = preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const AttackHelicopterFinishV10 = preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const AttackHelicopterTailV11 = preload("res://scripts/ui/AttackHelicopterTailV11.gd")
const AttackHelicopterNoseV12 = preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
const AttackHelicopterDamageV13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const AttackHelicopterFactionV14 = preload("res://scripts/ui/AttackHelicopterFactionV14.gd")
const AttackHelicopterCombatFXV14 = preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
const AttackHelicopterRotorMountV145 = preload("res://scripts/ui/AttackHelicopterRotorMountV145.gd")
const AttackHelicopterRotorDampersV146 = preload("res://scripts/ui/AttackHelicopterRotorDampersV146.gd")
const AttackHelicopterDamperFinishV147 = preload("res://scripts/ui/AttackHelicopterDamperFinishV147.gd")
const AttackHelicopterPitchHingesV148 = preload("res://scripts/ui/AttackHelicopterPitchHingesV148.gd")
const AttackHelicopterRotorAnchorsV149 = preload("res://scripts/ui/AttackHelicopterRotorAnchorsV149.gd")
const AttackHelicopterRotorContactV1410 = preload("res://scripts/ui/AttackHelicopterRotorContactV1410.gd")
const AttackHelicopterBladeRootsV1411 = preload("res://scripts/ui/AttackHelicopterBladeRootsV1411.gd")
const AttackHelicopterBladeSeamV1412 = preload("res://scripts/ui/AttackHelicopterBladeSeamV1412.gd")
const AttackHelicopterHubCrownV1413 = preload("res://scripts/ui/AttackHelicopterHubCrownV1413.gd")
const AttackHelicopterHubWreckV1414 = preload("res://scripts/ui/AttackHelicopterHubWreckV1414.gd")
const AttackHelicopterHubCutFinishV1415 = preload("res://scripts/ui/AttackHelicopterHubCutFinishV1415.gd")
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
    "line":3.05,"scout":3.05,"infantry_urban":3.05,
    "infantry_defense":3.05,"infantry_antitank":3.15,
    "infantry_engineer":3.05,"infantry_sniper":3.25,
    "infantry_logistic":3.25,"infantry_medic":3.15,
    "infantry_commando":3.15,"apc":3.55,"tank":3.75,
    "mlrs":4.05,"attack_heli":4.60,"fighter":4.65,"destroyer":5.10,
    "aa_mobile":3.85,"mobile_aa":3.85,"ew_mobile":4.45,
    "logistics_mobile":5.0
}

# G13 art-only LOD selection. Public to studio/stress harnesses, not combat.
static func recommend_g13_art_level(camera_distance:float,visible_g13_count:int,
        is_android:bool,inspection:bool=false,previous_art_level:int=8)->int:
    return G13LODPolicyV17.choose(camera_distance,visible_g13_count,
        is_android,inspection,previous_art_level)

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
        "line","scout","infantry_urban","infantry_defense","infantry_antitank","infantry_engineer","infantry_sniper","infantry_logistic","infantry_medic","infantry_commando":
            # One genuine native infantry family; level variants do not invent
            # new tactical classes or alter established battle unit IDs.
            if not InfantryFamily.build(model,role,faction_paint_color(faction),
                    finish_enabled and art_level >= 13):
                _person(model,role == "scout")
            elif finish_enabled and art_level>=8:
                if not InfantryFinishV2.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("Infantry V2 organic solid sculpt/PBR not applied")
                elif InfantryVariantsV4.supports(role):
                    if not InfantryVariantsV4.apply(model,role,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Approved infantry specialist kit not applied: "+role)
                elif role=="infantry_engineer":
                    if not InfantryEngineerV5.apply(model,role,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V5 construction silhouette not applied")
                    elif not InfantryEngineerV6.apply(model,role,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V6 360 finish and animation rig not applied")
                    elif not InfantryEngineerV7.apply(model,role,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V7 enclosed rear helmet, neck and joint completion missing")
                    elif not InfantryEngineerV8.apply(model,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V8 beveled shield, sculpted shoulders and detailed rifle missing")
                    elif not InfantryEngineerV9.apply(model,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V9 helmet, accurate glove grips and anchored dorsal hardware missing")
                    elif not InfantryEngineerV10.apply(model,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V10 anatomical arm taper, chest contour and tool fingers missing")
                    elif not InfantryEngineerV11.apply(model,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V11 closed shaped torso, mechanical shield hinges and moving socket joints missing")
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
        "logistics_mobile":
            # G16 remains Studio visual-only. Tactical role logistics is
            # unchanged; V2 is genuine Godot mesh detail on the same V1 rig.
            if not G16LogisticsV1.build(model,
                    faction_paint_color(faction),finish_enabled and art_level>=13):
                return null
            if finish_enabled and art_level>=8:
                if not G16ExteriorV2.apply(model,faction_paint_color(faction)):
                    push_warning("G16 V2 opaque hard-surface cab, 6 wheels and articulated crane missing")
                elif not G16MechanicsV3.apply(model,faction_paint_color(faction)):
                    push_warning("G16 V3 six spring packs, working ammo lids, sealed fuel services and native damage missing")
                elif not G16SculptV4.apply(model,faction_paint_color(faction)):
                    push_warning("G16 V4 sealed bevelled armor, physical faction panels or damaged vehicle fragments missing")
                elif not G16MaterialsV5.apply(model,faction_paint_color(faction)):
                    push_warning("G16 V5 opaque coated glazing, 3D surface microdetail and thermal damage missing")
                elif not G16ServiceV6.apply(model,faction_paint_color(faction)):
                    push_warning("G16 V6 physical hose, articulated coupling and service lid missing")
        "ew_mobile":
            # G15 is an art-only communications carrier; not a tactical class.
            if not G15EW.build(model,faction_paint_color(faction),
                    finish_enabled and art_level>=13):
                return null
            if not G15SculptV2.apply(model):
                push_warning("G15 V2 curved 6x6 wheel arches and mast gussets not installed")
            elif not G15ShellV3.apply(model):
                push_warning("G15 V3 closed armored EW shelters, roof and bulged tires not installed")
            elif not G15AntennaV4.apply(model,faction_paint_color(faction)):
                push_warning("G15 V4 physical antennas, bearings and moving hydraulic actuator not installed")
            elif not G15FinishDamageV5.apply(model,faction_paint_color(faction)):
                push_warning("G15 V5 panel surface finish and staged 3D damage are not installed")
            elif not G15ExteriorV6.apply(model,faction_paint_color(faction)):
                push_warning("G15 V6 native armored panels, sealed reflective windows and cooling not installed")
            elif not G15MechanicalV7.apply(model,faction_paint_color(faction)):
                push_warning("G15 V7 chassis details, 6x6 suspension and welded seams not installed")
            elif not G15ContinuityV8.apply(model,faction_paint_color(faction)):
                push_warning("G15 V8 closed armor bridges, satin metal and native 6x6 coil springs not installed")
            elif not G15SurfaceV9.apply(model,faction_paint_color(faction)):
                push_warning("G15 V9 PBR armor and rubber tread wheel machining not installed")
            elif not G15OpticalV10.apply(model,faction_paint_color(faction)):
                push_warning("G15 V10 physical curved glazing, seals and EW rear service art not installed")
            elif not G15DetailV11.apply(model,faction_paint_color(faction)):
                push_warning("G15 V11 360 wheel shoulders and true cab wipers not installed")
        "aa_mobile", "mobile_aa":
            # G13 V69 now serves Studio aa_mobile and the existing playable
            # BattleSession mobile_aa role without changing combat rules.
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
                if not G13SilhouetteV10.apply(model):
                    push_warning("G13 V10 silhouette failed to apply")
                if not G13CabRearV11.install(model):
                    push_warning("G13 V11 roof/rear finish failed to apply")
                if not G13BodyFinishV11.apply(model):
                    push_warning("G13 V11 body finish failed to apply")
                if not G13MechanicalV12.install(model):
                    push_warning("G13 V12 mechanics failed to apply")
                if not G13SurfaceV13.apply(model):
                    push_warning("G13 V13 exterior finish failed to apply")
                if not G13SensorsV14.apply(model):
                    push_warning("G13 V14 sensor sculpture failed to apply")
                if not G13TurretV15.apply(model):
                    push_warning("G13 V15 turret junction finish failed to apply")
                if not G13BatchesV16.apply(model):
                    push_warning("G13 V16 static GPU batching failed to apply")
                if not G13CannonV18.apply(model):
                    push_warning("G13 V18 cannon-only sculpt failed to apply")
                if not G13JointV19.apply(model):
                    push_warning("G13 V19 gun joint art integration failed to apply")
                if not G13ArmorV20.apply(model):
                    push_warning("G13 V20 turret-to-hull armor finishing failed to apply")
                if not G13SidesV21.apply(model):
                    push_warning("G13 V21 side armor sculpt failed to apply")
                if not G13UndersideV22.apply(model):
                    push_warning("G13 V22 360-degree underbody detail pass failed to apply")
                if not G13FrontV23.apply(model):
                    push_warning("G13 V23 recessed headlight sculpture failed to apply")
                if not G13IntakeV24.apply(model):
                    push_warning("G13 V24 frontal intake finish failed to apply")
                if not G13FactionV32.apply(model):
                    push_warning("G13 V32 faction accents failed on hero LOD13")
                if not G13ChassisV33.apply(model):
                    push_warning("G13 V33 chassis sculpt failed on hero LOD13")
                if not G13ClosureV34.apply(model):
                    push_warning("G13 V34 panel seams and bumper finish failed on hero LOD13")
                if not G13RearV35.apply(model):
                    push_warning("G13 V35 rear hatch/exhausts failed on hero LOD13")
                if not G13ProportionsV36.apply(model):
                    push_warning("G13 V36 sculpted arch/rear transitions failed on hero LOD13")
                if not G13RoofRadarV37.apply(model):
                    push_warning("G13 V37 cab roof and engine hood finish failed on hero LOD13")
                if not G13JoineryV38.apply(model):
                    push_warning("G13 V38 roof cap and side joinery failed on hero LOD13")
                if not G13UndersealV39.apply(model):
                    push_warning("G13 V39 cab underseal and bumper finish failed on hero LOD13")
                if not G13SilhouetteV40.apply(model):
                    push_warning("G13 V40 curved outboard wheel arches failed on hero LOD13")
                if not G13ContourV41.apply(model):
                    push_warning("G13 V41 sculpted wheel contours failed on hero LOD13")
                if not G13ArcEndsV42.apply(model):
                    push_warning("G13 V42 wheel-arch termination failed on hero LOD13")
                if not G13ExteriorV44.apply(model):
                    push_warning("G13 V44 real 3D exterior/faction detailing failed on hero LOD13")
                if not G13CabV45.apply(model):
                    push_warning("G13 V45 native cab and gun receiver finish failed on hero LOD13")
                if not G13WheelV46.apply(model):
                    push_warning("G13 V46 machined four-wheel sculpt failed on hero LOD13")
                if not G13SurfaceV47.apply(model):
                    push_warning("G13 V47 individual PBR surface finish failed on hero LOD13")
                if not G13SculptV48.apply(model):
                    push_warning("G13 V48 major closed cab/turret/roof sculpt failed on hero LOD13")
                if not G13SeamsV49.apply(model):
                    push_warning("G13 V49 seamless cab/window/turret loft failed on hero LOD13")
                if not G13GlazingV50.apply(model):
                    push_warning("G13 V50 native sealed side/windshield fit failed on hero LOD13")
                if not G13RoofV51.apply(model):
                    push_warning("G13 V51 native integrated roof and brow failed on hero LOD13")
                if not G13RoofRailsV52.apply(model):
                    push_warning("G13 V52 roof shoulder integration failed on hero LOD13")
                if not G13RealismV53.apply(model):
                    push_warning("G13 V53 real metal/rubber materials failed on hero LOD13")
                if not G13RubberV54.apply(model):
                    push_warning("G13 V54 rounded rubber tires failed on hero LOD13")
                if not G13MicroV55.apply(model):
                    push_warning("G13 V55 PBR paint grain and panel gaskets failed on hero LOD13")
                if not G13JointV56.apply(model):
                    push_warning("G13 V56 suspension and turret joints failed on hero LOD13")
                if not G13VisibleV57.apply(model):
                    push_warning("G13 V57 visible fender mounts failed on hero LOD13")
                if not G13VisibleV58.apply(model):
                    push_warning("G13 V58 isometric steel hardware finish failed on hero LOD13")
                if not G13PremiumV59.apply(model):
                    push_warning("G13 V59 Bastion-density rubber, reflected glass and faction paint missing on hero LOD13")
                if not G13TreadV60.apply(model):
                    push_warning("G13 V60 continuous circumferential tread and molded sidewalls missing on LOD13")
                if not G13WheelArmorV61.apply(model):
                    push_warning("G13 V61 P06-grade open machined spokes and armor PBR missing LOD13")
                if not G13GlassV62.apply(model):
                    push_warning("G13 V62 optical cab glass reflection missing on hero LOD13")
                if not G13FactionV63.apply(model):
                    push_warning("G13 V63 visible physical faction identification missing on hero LOD13")
                if not G13EdgesV64.apply(model):
                    push_warning("G13 V64 recessed hard-surface armor seams missing on hero LOD13")
                if not G13RingV65.apply(model):
                    push_warning("G13 V65 chamfered turret bearing and armored union missing on LOD13")
                if not G13MountV66.apply(model):
                    push_warning("G13 V66 machined twin cannon trunnion and barrel collars missing on LOD13")
                if not G13FeedV67.apply(model):
                    push_warning("G13 V67 closed ejection/feeder hatches missing on LOD13")
                if not G13EjectorV68.apply(model):
                    push_warning("G13 V68 physical ejection channels and machined cooling ribs missing on LOD13")
                if not G13MuzzleV69.apply(model):
                    push_warning("G13 V69 physically slotted dual muzzle brakes and moving anchor hubs missing on LOD13")
            elif art_level>=8:
                # Low-cost 3D readability: reuses existing gun/radar/faction
                # meshes, adds no draw objects, never alters V24 hero art.
                if not G13TacticalV25.apply(model):
                    push_warning("G13 V25 tactical silhouette failed to apply")
                if not G13ArmorV26.apply(model):
                    push_warning("G13 V26 faceted LOD8 armor failed to apply")
                if not G13RadarV27.apply(model):
                    push_warning("G13 V27 tactical search radar sculpture failed to apply")
                if not G13DeckV28.apply(model):
                    push_warning("G13 V28 physical radar deck support failed to apply")
                if not G13FoldV29.install(model):
                    push_warning("G13 V29 rear-facing radar hinge failed to install")
                if not G13StowageV30.apply(model):
                    push_warning("G13 V30 radar stowage cradle failed to apply")
                if not G13GunMountV31.apply(model):
                    push_warning("G13 V31 gun mount guards failed to apply")
                if not G13FactionV32.apply(model):
                    push_warning("G13 V32 gun fasteners/faction accents failed on LOD8")
                if not G13ChassisV33.apply(model):
                    push_warning("G13 V33 chassis sculpt failed on tactical LOD8")
                if not G13ClosureV34.apply(model):
                    push_warning("G13 V34 panel seams and bumper finish failed on tactical LOD8")
                if not G13RearV35.apply(model):
                    push_warning("G13 V35 rear hatch/exhausts failed on tactical LOD8")
                if not G13ProportionsV36.apply(model):
                    push_warning("G13 V36 sculpted arch/rear transitions failed on tactical LOD8")
                if not G13RoofRadarV37.apply(model):
                    push_warning("G13 V37 cab roof and radar cradle finish failed on tactical LOD8")
                if not G13JoineryV38.apply(model):
                    push_warning("G13 V38 roof cap and side joinery failed on tactical LOD8")
                if not G13UndersealV39.apply(model):
                    push_warning("G13 V39 cab underseal and bumper finish failed on tactical LOD8")
                if not G13SilhouetteV40.apply(model):
                    push_warning("G13 V40 curved outboard wheel arches failed on tactical LOD8")
                if not G13ContourV41.apply(model):
                    push_warning("G13 V41 sculpted wheel contours failed on tactical LOD8")
                if not G13ArcEndsV42.apply(model):
                    push_warning("G13 V42 wheel-arch termination failed on tactical LOD8")
                if not G13ExteriorV44.apply(model):
                    push_warning("G13 V44 real 3D exterior/faction detailing failed on tactical LOD8")
                if not G13CabV45.apply(model):
                    push_warning("G13 V45 native cab and gun receiver finish failed on tactical LOD8")
                if not G13WheelV46.apply(model):
                    push_warning("G13 V46 machined four-wheel sculpt failed on tactical LOD8")
                if not G13SurfaceV47.apply(model):
                    push_warning("G13 V47 individual PBR surface finish failed on tactical LOD8")
                if not G13SculptV48.apply(model):
                    push_warning("G13 V48 major closed cab/turret/roof sculpt failed on tactical LOD8")
                if not G13SeamsV49.apply(model):
                    push_warning("G13 V49 seamless cab/window/turret loft failed on tactical LOD8")
                if not G13GlazingV50.apply(model):
                    push_warning("G13 V50 native windshield fit failed on tactical LOD8")
                if not G13RoofV51.apply(model):
                    push_warning("G13 V51 native integrated roof and brow failed on tactical LOD8")
                if not G13RoofRailsV52.apply(model):
                    push_warning("G13 V52 roof shoulder integration failed on tactical LOD8")
                if not G13RealismV53.apply(model):
                    push_warning("G13 V53 real metal/rubber materials failed on tactical LOD8")
                if not G13VisibleV57.apply(model):
                    push_warning("G13 V57 single-batch tactical mechanical mounts failed on LOD8")
                if not G13VisibleV58.apply(model):
                    push_warning("G13 V58 isometric tactical finish failed on LOD8")
                if not G13PremiumV59.apply(model):
                    push_warning("G13 V59 optimized rubber, reflected glass and faction paint missing on Android LOD8")
                if not G13TreadV60.apply(model):
                    push_warning("G13 V60 lightweight continuous tread and molded sidewalls missing on LOD8")
                if not G13WheelArmorV61.apply(model):
                    push_warning("G13 V61 optimized open machined spokes and armor PBR missing LOD8")
                if not G13GlassV62.apply(model):
                    push_warning("G13 V62 tactical cab glass reflection missing on LOD8")
                if not G13FactionV63.apply(model):
                    push_warning("G13 V63 faction recognition badges missing on Android LOD8")
                if not G13EdgesV64.apply(model):
                    push_warning("G13 V64 beveled original steel panels and hatches missing on LOD8")
                if not G13RingV65.apply(model):
                    push_warning("G13 V65 efficient rotating turret joint sculpt missing on LOD8")
                if not G13MountV66.apply(model):
                    push_warning("G13 V66 low-draw hollow articulated cannon mount missing on LOD8")
                if not G13FeedV67.apply(model):
                    push_warning("G13 V67 integrated moving receiver feed details missing on LOD8")
                if not G13EjectorV68.apply(model):
                    push_warning("G13 V68 compact machined gun steel and mobile cheek finish missing on LOD8")
                if not G13MuzzleV69.apply(model):
                    push_warning("G13 V69 performance-scaled ported twin gun barrels missing on Android LOD8")
    if role in ["line","scout"]:
        model.scale = Vector3.ONE * 0.82
        model.position.y = -0.58
    elif role in ["attack_heli","fighter","destroyer"]:
        model.scale = Vector3.ONE * 0.77
        model.position.y = -0.11
    elif InfantryFamily.supports(role):
        # Infantry boots stay above ground, unlike legacy vehicle proxies.
        model.scale=Vector3.ONE*0.83
        model.position.y=0.0
    elif role=="ew_mobile" or role=="logistics_mobile":
        model.scale=Vector3.ONE*0.83
        model.position.y=0.0
    elif role in ["aa_mobile","mobile_aa"]:
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
                                        if AttackHelicopterFinishV10.apply(model,faction_paint_color(faction)):
                                            if AttackHelicopterTailV11.apply(model,faction_paint_color(faction)):
                                                if AttackHelicopterNoseV12.apply(model,faction_paint_color(faction)):
                                                    if AttackHelicopterDamageV13.apply(model,faction_paint_color(faction)):
                                                        if not AttackHelicopterFactionV14.apply(model,faction_paint_color(faction),faction):
                                                            push_warning("A01 V14 faction identity coat could not be applied")
                                                        if not AttackHelicopterCombatFXV14.apply(model):
                                                            push_warning("A01 V14 combat animation effects could not be applied")
                                                        if not AttackHelicopterRotorMountV145.apply(model):
                                                            push_warning("A01 V14.5 main rotor mounting did not build")
                                                        if not AttackHelicopterRotorDampersV146.apply(model):
                                                            push_warning("A01 V14.6 rotor vibration dampers did not build")
                                                        if not AttackHelicopterDamperFinishV147.apply(model):
                                                            push_warning("A01 V14.7 physical damper finish did not build")
                                                        if not AttackHelicopterPitchHingesV148.apply(model):
                                                            push_warning("A01 V14.8 mechanical blade pitch hinges did not build")
                                                        if not AttackHelicopterRotorAnchorsV149.apply(model):
                                                            push_warning("A01 V14.9 grounded rotor root seats did not build")
                                                        if not AttackHelicopterRotorContactV1410.apply(model):
                                                            push_warning("A01 V14.10 bevel/contact pass did not build")
                                                        if not AttackHelicopterBladeRootsV1411.apply(model):
                                                            push_warning("A01 V14.11 sculpted original blade roots did not build")
                                                        if not AttackHelicopterBladeSeamV1412.apply(model):
                                                            push_warning("A01 V14.12 swept aerodynamic seam did not build")
                                                        if not AttackHelicopterHubCrownV1413.apply(model):
                                                            push_warning("A01 V14.13 enclosed rotor hub crown did not build")
                                                        if not AttackHelicopterHubWreckV1414.apply(model):
                                                            push_warning("A01 V14.14 authentic crown wreck pieces did not build")
                                                        if not AttackHelicopterHubCutFinishV1415.apply(model):
                                                            push_warning("A01 V14.15 enclosed machined fracture faces did not build")
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
    if InfantryFamily.supports(role) and InfantryFamily.has_model(model):
        var posed: bool=InfantryFamily.pose(model,kind,progress,target_heading)
        if posed and InfantryFinishV2.has_model(model):
            InfantryFinishV2.pose(model,kind,progress)
        if posed and role=="infantry_engineer" and InfantryEngineerV6.has_model(model):
            InfantryEngineerV6.pose(model,kind,progress)
            if InfantryEngineerV9.has_model(model):
                InfantryEngineerV9.sync(model,kind)
        return posed
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
        "logistics_mobile":
            var g16_posed:bool=G16LogisticsV1.pose(model,kind,progress,target_heading)
            if g16_posed and G16ExteriorV2.has_model(model):
                G16ExteriorV2.sync(model)
            if g16_posed and G16MechanicsV3.has_model(model):
                G16MechanicsV3.sync(model,kind,progress)
            if g16_posed and G16SculptV4.has_model(model):
                G16SculptV4.sync(model)
            if g16_posed and G16MaterialsV5.has_model(model):
                G16MaterialsV5.sync(model)
            if g16_posed and G16ServiceV6.has_model(model):
                G16ServiceV6.sync(model,kind,progress)
            return g16_posed
        "aa_mobile", "mobile_aa":
            return G13AA.pose(model,kind,progress,target_heading)
        "ew_mobile":
            var posed:bool=G15EW.pose(model,kind,progress,target_heading)
            if posed and bool(model.get_meta(G15AntennaV4.FLAG,false)):
                G15AntennaV4.sync(model)
            if posed and kind=="damage" and bool(model.get_meta(G15FinishDamageV5.FLAG,false)):
                G15FinishDamageV5.set_damage(model,clampi(int(ceilf(progress*4.0)),0,4))
            return posed
    return false

static func restore_model_pose(role: String, model: Node3D) -> void:
    if InfantryFamily.supports(role) and InfantryFamily.has_model(model):
        InfantryFamily.restore(model)
        if InfantryFinishV2.has_model(model):
            InfantryFinishV2.restore(model)
        if role=="infantry_engineer" and InfantryEngineerV6.has_model(model):
            InfantryEngineerV6.reset(model)
            if InfantryEngineerV9.has_model(model):
                InfantryEngineerV9.sync(model,"idle")
        return
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
        "logistics_mobile":
            G16LogisticsV1.restore(model)
            if G16ExteriorV2.has_model(model):
                G16ExteriorV2.sync(model)
            if G16MechanicsV3.has_model(model):
                G16MechanicsV3.restore(model)
            if G16SculptV4.has_model(model):
                G16SculptV4.restore(model)
            if G16MaterialsV5.has_model(model):
                G16MaterialsV5.restore(model)
            if G16ServiceV6.has_model(model):
                G16ServiceV6.restore(model)
        "aa_mobile", "mobile_aa":
            G13AA.restore(model)
        "ew_mobile":
            G15EW.restore(model)
            if bool(model.get_meta(G15FinishDamageV5.FLAG,false)):
                G15FinishDamageV5.reset_damage(model)
            if bool(model.get_meta(G15AntennaV4.FLAG,false)):
                G15AntennaV4.sync(model)

static func inspect_meshes(model: Node) -> int:
    if model == null:
        return 0
    var count := 1 if model is MeshInstance3D else 0
    for child in model.get_children():
        count += inspect_meshes(child)
    return count
