extends RefCounted
class_name TarvokaUnitModels3D

# First actual editable 3D geometry for TARVOKA. These eight models are native
# Godot MeshInstance3D trees, NOT SVG sprites or AI-rendered concept images.
# Tuned to existing approved category silhouettes; no tactical stats live here.
const ROLES := ["line","scout","apc","tank","mlrs","attack_heli","fighter","destroyer","aa_mobile","mobile_aa","ew_mobile","logistics_mobile","infantry_urban","infantry_defense","infantry_antitank","infantry_engineer","infantry_sniper","infantry_logistic","infantry_medic","infantry_commando","uav_recon","fpv","patrol"]
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
const InfantryEngineerV12 = preload("res://scripts/ui/InfantryEngineerDorsalV12.gd")
const InfantryEngineerV13 = preload("res://scripts/ui/InfantryEngineerSmoothV13.gd")
const InfantryEngineerV14 = preload("res://scripts/ui/InfantryEngineerContourV14.gd")
const InfantryEngineerV15 = preload("res://scripts/ui/InfantryEngineerGearV15.gd")
const InfantryEngineerV16 = preload("res://scripts/ui/InfantryEngineerSilhouetteV16.gd")
const InfantryEngineerV17 = preload("res://scripts/ui/InfantryEngineerOuterArmorV17.gd")
const G16LogisticsV1 = preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const G16ExteriorV2 = preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const G16MechanicsV3 = preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const G16SculptV4 = preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const G16MaterialsV5 = preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const G16ServiceV6 = preload("res://scripts/ui/G16DeployableSupplyHardwareV6.gd")
const A01Recon = preload("res://scripts/ui/A01ReconDroneV1.gd")
const A02Art = preload("res://scripts/ui/A02FpvArtV1.gd")
const A01Finish = preload("res://scripts/ui/A01ReconFinishV2.gd")
const A01HardwareV3 = preload("res://scripts/ui/A01ReconFinishV3.gd")
const A01AirfoilV4 = preload("res://scripts/ui/A01ReconAirfoilV4.gd")
const A01TailV5 = preload("res://scripts/ui/A01ReconTailV5.gd")
const A01DamageV6 = preload("res://scripts/ui/A01ReconDamageV6.gd")
const A01WingletV8 = preload("res://scripts/ui/A01ReconWingletV8.gd")
const A01WingletV9 = preload("res://scripts/ui/A01ReconWingletV9.gd")
const A01NoseOpticsV10 = preload("res://scripts/ui/A01ReconNoseOpticsV10.gd")
const A01AirframeV11 = preload("res://scripts/ui/A01ReconAirframeV11.gd")
const A01WingRootV12 = preload("res://scripts/ui/A01ReconWingRootV12.gd")
const A01TailOpticsV13 = preload("res://scripts/ui/A01ReconTailOpticsV13.gd")
const A01DamageFinishV14 = preload("res://scripts/ui/A01ReconDamageFinishV14.gd")
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
    "logistics_mobile":5.0,"uav_recon":3.65,"fpv":2.85
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
    var painted: int = _paint_panels(model,faction_paint_color(faction))
    if model.has_meta("destroyer_art_revision") or model.has_meta("patrol_art_revision"):
        painted += _destroyer_repaint_hull(model,faction_paint_color(faction))
    return painted

static func paintable_count(model: Node) -> int:
    if model == null:
        return 0
    var total := 1 if model is MeshInstance3D and (model.has_meta(TANK_PAINT_META) or model.name.begins_with("Faccion") or model.has_meta("destroyer_stripe_vertices")) else 0
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

# V1 naval silhouette: joined closed transverse stations, with a separate
# conformal deck and opaque faction markings. Presentation only.
static func _destroyer_shell(root: Node3D, label: String, stations: Array,
        tint: Color, painted_hull: bool = false) -> MeshInstance3D:
    var points: Array = []
    var faces: Array = []
    # Chamfer all transverse corners with a pair of nearby points.
    # Interpolation preserves the established silhouette and contact heights.
    for station in stations:
        var z: float = station[0]
        var w: float = station[1]
        var bottom: float = station[2]
        var top: float = station[3]
        var ring: Array[Vector3] = [
            Vector3(-w*0.86,top,z),Vector3(w*0.86,top,z),
            Vector3(w,lerpf(bottom,top,0.64),z),
            Vector3(w*0.67,bottom,z),Vector3(-w*0.67,bottom,z),
            Vector3(-w,lerpf(bottom,top,0.64),z)]
        for i in range(6):
            points.append(ring[i].lerp(ring[(i+5)%6],0.10))
            points.append(ring[i].lerp(ring[(i+1)%6],0.10))
    var count: int = 12
    for ring in range(stations.size()-1):
        for i in range(count):
            var j: int = (i+1)%count
            var a: int = ring*count
            var b: int = a+count
            faces.append([a+i,a+j,b+j,b+i])
    var front: Array = []
    var rear: Array = []
    var last: int = (stations.size()-1)*count
    for i in range(count):
        front.append(count-1-i)
        rear.append(last+i)
    faces.append(front)
    faces.append(rear)
    if not painted_hull:
        # Keep chamfered volumes closed, but separate the smoothing groups
        # of each longitudinal panel and the end caps. The sides of the
        # bridge, mast and deck no longer shade like inflated plastic.
        var facets := SurfaceTool.new()
        facets.begin(Mesh.PRIMITIVE_TRIANGLES)
        for face_index in range(faces.size()):
            var face: Array = faces[face_index]
            var panel: int = face_index % count if face_index < (stations.size()-1)*count else count+face_index-(stations.size()-1)*count
            for k in range(1,face.size()-1):
                for index in [face[0],face[k],face[k+1]]:
                    var point: Vector3 = points[index]
                    facets.set_smooth_group(panel)
                    facets.set_uv(Vector2(point.x*0.34+0.5,point.z*0.30+0.5))
                    facets.add_vertex(point)
        facets.generate_normals()
        var solid := MeshInstance3D.new()
        solid.name = label
        solid.mesh = facets.commit()
        solid.material_override = _material(tint,0.20)
        solid.set_meta("destroyer_hard_panels",true)
        root.add_child(solid)
        return solid
    # One sealed exterior, with a color band embedded in the surface.
    # No second shell, polygon offset, intersecting stripe or detached badge.
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var stripe_vertices := PackedInt32Array()
    var vertex_index: int = 0
    for face_index in range(faces.size()):
        var face: Array = faces[face_index]
        var side: int = face_index % count
        var stripe: bool = face_index < (stations.size()-1)*count and side in [4,10]
        var under: bool = face_index < (stations.size()-1)*count and side in [5,6,7,8,9]
        var tone: Color = ARMOR if stripe else (Color("#465966") if under else tint)
        for k in range(1,face.size()-1):
            for index in [face[0],face[k],face[k+1]]:
                var point: Vector3 = points[index]
                surface.set_uv(Vector2(point.x*0.34+0.5,point.z*0.30+0.5))
                surface.set_color(tone)
                surface.add_vertex(point)
                if stripe:
                    stripe_vertices.append(vertex_index)
                vertex_index += 1
    surface.generate_normals()
    var item := MeshInstance3D.new()
    item.name = label
    item.mesh = surface.commit()
    var material: StandardMaterial3D = _material(Color.WHITE,0.20)
    material.vertex_color_use_as_albedo = true
    material.vertex_color_is_srgb = true
    item.material_override = material
    item.set_meta("destroyer_stripe_vertices",stripe_vertices)
    root.add_child(item)
    return item

static func _destroyer_repaint_hull(root: Node3D, paint: Color) -> int:
    var hull: MeshInstance3D = root.get_node_or_null("CascoNaval") as MeshInstance3D
    if hull == null or not hull.has_meta("destroyer_stripe_vertices"):
        return 0
    var arrays: Array = hull.mesh.surface_get_arrays(0)
    var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
    var indices: PackedInt32Array = hull.get_meta("destroyer_stripe_vertices")
    for index in indices:
        colors[index] = paint
    arrays[Mesh.ARRAY_COLOR] = colors
    var fresh := ArrayMesh.new()
    fresh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    hull.mesh = fresh
    return 1

# Only the naval model receives this opaque procedural surface treatment.
# No transparency or battle logic is introduced.
static var _destroyer_steel_texture: ImageTexture

static func _destroyer_grain() -> ImageTexture:
    if _destroyer_steel_texture != null:
        return _destroyer_steel_texture
    var img: Image = Image.create(64,64,false,Image.FORMAT_RGBA8)
    for y in range(64):
        for x in range(64):
            var grain: float = float((x*37+y*73+x*y*11)%31)/30.0
            var streak: float = 0.5+0.5*sin(float(x)*1.18+float(y)*0.06)
            var shade: float = 0.91+0.055*grain+0.035*streak
            img.set_pixel(x,y,Color(shade,shade,shade,1.0))
    img.generate_mipmaps()
    _destroyer_steel_texture = ImageTexture.create_from_image(img)
    return _destroyer_steel_texture

static func _destroyer_finish(node: Node, detail: bool) -> void:
    if node is MeshInstance3D:
        var part: MeshInstance3D = node as MeshInstance3D
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        if mat != null:
            var label: String = str(part.name)
            mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
            mat.cull_mode = BaseMaterial3D.CULL_BACK
            mat.metallic = 0.32
            mat.roughness = 0.58
            if label.begins_with("Cristal") or label.begins_with("Lente"):
                mat.metallic = 0.12
                mat.roughness = 0.24
            elif label.begins_with("Faccion"):
                mat.metallic = 0.13
                mat.roughness = 0.54
            elif label.contains("Pasamanos") or label.contains("Amarre") or label.contains("Tirador"):
                mat.metallic = 0.60
                mat.roughness = 0.43
            elif label.contains("Helipuerto") or label.contains("Estela") or label.begins_with("Espuma"):
                mat.metallic = 0.0
                mat.roughness = 0.88
            elif label.contains("CascoNaval"):
                mat.metallic = 0.28
                mat.roughness = 0.62
            elif label.begins_with("Humo"):
                mat.metallic = 0.0
                mat.roughness = 1.0
            elif label.begins_with("Fuego") or label.begins_with("Impacto") or label == "DestelloVisual":
                mat.metallic = 0.0
                mat.roughness = 0.75
                mat.emission_enabled = true
                mat.emission = mat.albedo_color
                mat.emission_energy_multiplier = 0.8
            if detail and (label in ["CascoNaval","Cubierta","CarcasaInferior","TechoPuente","CarcasaMastil","CarcasaTorreta"]):
                mat.albedo_texture = _destroyer_grain()
                mat.uv1_triplanar = true
                mat.uv1_triplanar_sharpness = 4.0
                mat.uv1_scale = Vector3(3.0,3.0,3.0)
            part.set_meta("destroyer_surface_v15",true)
    for child in node.get_children():
        _destroyer_finish(child,detail)

# Native solid bridge: compact footprint between existing forward deck
# equipment and aft landing area. Windows are opaque inserts, not planes.
static func _destroyer_bridge(root: Node3D, art_level: int) -> void:
    var bridge: Node3D = Node3D.new()
    bridge.name = "Superestructura"
    root.add_child(bridge)
    var foundation: Array = [
        [0.13,0.39,0.785,0.94],[0.22,0.49,0.785,0.94],
        [0.63,0.49,0.785,0.94],[0.75,0.38,0.785,0.94]]
    _destroyer_shell(bridge,"ZocaloNaval",foundation,DARK)
    var lower: Array = [
        [0.16,0.35,0.92,1.19],[0.23,0.46,0.92,1.19],
        [0.59,0.46,0.92,1.19],[0.70,0.35,0.92,1.19]]
    _destroyer_shell(bridge,"CarcasaInferior",lower,STEEL)
    var upper: Array = [
        [0.13,0.36,1.16,1.48],[0.23,0.47,1.16,1.48],
        [0.54,0.47,1.16,1.48],[0.66,0.36,1.16,1.48]]
    _destroyer_shell(bridge,"Puente",upper,ARMOR)
    var roof: Array = [
        [0.115,0.37,1.465,1.54],[0.21,0.49,1.465,1.54],
        [0.55,0.49,1.465,1.54],[0.68,0.37,1.465,1.54]]
    _destroyer_shell(bridge,"TechoPuente",roof,STEEL)
    var window_tint := Color("#38566A")
    for i in range(3):
        var x: float = float(i - 1) * 0.19
        _box(bridge,"MarcoFrontal_%d" % i,Vector3(x,1.375,0.119),
            Vector3(0.181,0.145,0.035),DARK)
        _box(bridge,"CristalFrontal_%d" % i,Vector3(x,1.375,0.099),
            Vector3(0.147,0.111,0.023),window_tint)
    for side in [-1,1]:
        var sign: float = float(side)
        for i in range(2):
            var z: float = 0.30 + float(i) * 0.16
            _box(bridge,"MarcoLateral_%d_%d" % [side,i],Vector3(sign*0.445,1.37,z),
                Vector3(0.045,0.14,0.145),DARK)
            _box(bridge,"CristalLateral_%d_%d" % [side,i],Vector3(sign*0.470,1.37,z),
                Vector3(0.026,0.107,0.113),window_tint)
        _box(bridge,"FaccionPuente_%d" % side,Vector3(sign*0.43,1.11,0.41),
            Vector3(0.07,0.085,0.29),ARMOR)
        _box(bridge,"PuertaServicio_%d" % side,Vector3(sign*0.425,1.045,0.55),
            Vector3(0.047,0.19,0.15),DARK)
        _box(bridge,"TiradorServicio_%d" % side,Vector3(sign*0.455,1.055,0.56),
            Vector3(0.021,0.055,0.025),METAL)
    _box(bridge,"ApoyoMastil",Vector3(0,1.55,0.28),
        Vector3(0.29,0.08,0.29),DARK)
    # Aft-facing inspection and service details, attached to the existing wall.
    _box(bridge,"MarcoPosterior",Vector3(0,1.045,0.702),
        Vector3(0.31,0.21,0.034),DARK)
    _box(bridge,"PuertaPosterior",Vector3(0,1.045,0.724),
        Vector3(0.25,0.17,0.019),STEEL)
    _box(bridge,"TiradorPosterior",Vector3(0.083,1.045,0.742),
        Vector3(0.025,0.060,0.019),METAL)
    if art_level >= 13:
        for side in [-1,1]:
            var sign: float = float(side)
            _box(bridge,"MarcoVentilacion_%d" % side,Vector3(sign*0.424,1.035,0.32),
                Vector3(0.036,0.115,0.16),DARK)
            for i in range(4):
                _box(bridge,"LamaVentilacion_%d_%d" % [side,i],
                    Vector3(sign*0.447,0.993+float(i)*0.027,0.32),
                    Vector3(0.020,0.012,0.13),METAL)
        for i in range(3):
            _box(bridge,"RefuerzoPosterior_%d" % i,Vector3(-0.18+float(i)*0.18,1.35,0.662),
                Vector3(0.032,0.13,0.035),STEEL)

# Fictional game-art deck modules; no weapon specifications or game rules.
static func _destroyer_deck_equipment(root: Node3D, art_level: int) -> void:
    var detail: bool = art_level >= 13
    var sides: int = 20 if detail else 12
    _cylinder(root,"BaseTorreProa",Vector3(0,0.845,-1.14),
        0.30,0.10,DARK,Vector3.ZERO,sides)
    _cylinder(root,"AnilloTorreProa",Vector3(0,0.916,-1.14),
        0.27,0.065,STEEL,Vector3.ZERO,sides)
    var turret := Node3D.new()
    turret.name = "TorretaNavalPivot"
    turret.position = Vector3(0,0.936,-1.14)
    root.add_child(turret)
    var shell: Array = [
        [-0.24,0.16,-0.008,0.24],[-0.14,0.255,-0.008,0.34],
        [0.15,0.255,-0.008,0.34],[0.23,0.16,-0.008,0.24]]
    _destroyer_shell(turret,"CarcasaTorreta",shell,STEEL)
    _box(turret,"FaccionTorreta",Vector3(0,0.342,0.055),
        Vector3(0.28,0.038,0.19),ARMOR)
    var pivot := Node3D.new()
    pivot.name = "CanonNavalPivot"
    pivot.position = Vector3(0,0.155,-0.21)
    turret.add_child(pivot)
    _box(pivot,"UnionVisual",Vector3(0,0,-0.025),
        Vector3(0.19,0.17,0.16),DARK)
    _cylinder(pivot,"CanonNaval",Vector3(0,0,-0.30),
        0.068,0.52,METAL,Vector3(90,0,0),sides)
    if detail:
        for side in [-1,1]:
            _box(turret,"PanelServicio_%d" % side,
                Vector3(float(side)*0.219,0.16,0.055),
                Vector3(0.038,0.13,0.18),ARMOR)
    var deck := Node3D.new()
    deck.name = "ModuloCubierta"
    root.add_child(deck)
    _box(deck,"ZocaloModulo",Vector3(0,0.825,-0.34),
        Vector3(0.73,0.09,0.70),DARK)
    _box(deck,"MarcoModulo",Vector3(0,0.887,-0.34),
        Vector3(0.69,0.08,0.65),STEEL)
    for x in range(4):
        for z in range(3):
            var pos := Vector3(-0.255+float(x)*0.17,0.937,-0.55+float(z)*0.20)
            _box(deck,"TapaModulo_%d_%d" % [x,z],pos,
                Vector3(0.145,0.035,0.175),DARK)
            if detail:
                _box(deck,"BisagraTapa_%d_%d" % [x,z],pos+Vector3(0,0.024,0.061),
                    Vector3(0.10,0.027,0.035),ARMOR)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(root,"CajaServicioCubierta_%d" % side,
            Vector3(sign*0.45,0.879,-0.48),
            Vector3(0.15,0.16,0.31),STEEL)
        _box(root,"TapaServicioCubierta_%d" % side,
            Vector3(sign*0.45,0.97,-0.48),
            Vector3(0.17,0.04,0.32),ARMOR)

# Fictional navigation silhouette: rigid closed meshes, independent
# visual rotation, and detail tiers. Does not affect detection or combat.
static func _destroyer_navigation(root: Node3D, art_level: int) -> void:
    var detail: bool = art_level >= 13
    var sides: int = 20 if detail else 10
    var mast := Node3D.new()
    mast.name = "TorreMastil"
    mast.position = Vector3(0,1.585,0.28)
    root.add_child(mast)
    var sections: Array = [
        [-0.13,0.125,-0.015,0.22],[-0.075,0.14,-0.015,0.43],
        [0.075,0.14,-0.015,0.43],[0.13,0.125,-0.015,0.22]]
    _destroyer_shell(mast,"CarcasaMastil",sections,STEEL)
    _box(mast,"PlataformaSuperior",Vector3(0,0.425,0),
        Vector3(0.31,0.07,0.29),DARK)
    _cylinder(mast,"BaseSensor",Vector3(0,0.48,0),
        0.10,0.07,STEEL,Vector3.ZERO,sides)
    var rotor := Node3D.new()
    rotor.name = "RadarPivot"
    rotor.position = Vector3(0,0.52,0)
    mast.add_child(rotor)
    _box(rotor,"SoporteRadar",Vector3(0,0.04,0),
        Vector3(0.16,0.10,0.15),DARK)
    var panel: Array = [
        [-0.07,0.32,0.06,0.17],[-0.035,0.39,0.06,0.24],
        [0.035,0.39,0.06,0.24],[0.07,0.32,0.06,0.17]]
    _destroyer_shell(rotor,"Radar",panel,ARMOR)
    _box(rotor,"FrenteSensor",Vector3(0,0.148,-0.077),
        Vector3(0.56,0.105,0.024),DARK)
    if detail:
        for i in range(5):
            _box(rotor,"DetalleSensor_%d" % i,
                Vector3(-0.22+float(i)*0.11,0.148,-0.094),
                Vector3(0.068,0.074,0.014),STEEL)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(mast,"SoporteLateral_%d" % side,Vector3(sign*0.16,0.24,0.04),
            Vector3(0.15,0.065,0.15),STEEL)
        _box(mast,"SensorLateral_%d" % side,Vector3(sign*0.195,0.30,0.04),
            Vector3(0.13,0.095,0.13),DARK)
        _box(root,"BaseAntena_%d" % side,Vector3(sign*0.26,1.56,0.49),
            Vector3(0.13,0.07,0.12),STEEL)
        _antenna(root,"RadarRadio%s" % side,Vector3(sign*0.26,1.59,0.49),0.35)
        _box(root,"LuzNavegacion_%d" % side,Vector3(sign*0.37,1.53,0.30),
            Vector3(0.10,0.09,0.13),DARK)
        _box(root,"LenteNavegacion_%d" % side,Vector3(sign*0.42,1.54,0.30),
            Vector3(0.025,0.055,0.085),Color("#C94B47") if side < 0 else Color("#48AD85"))
        if detail:
            for i in range(3):
                _box(mast,"Peldano_%d_%d" % [side,i],
                    Vector3(sign*0.14,0.075+float(i)*0.09,0.09),
                    Vector3(0.07,0.022,0.09),METAL)
    root.set_meta("destroyer_navigation_revision","1.3")

# Studio-only pose; rotation is independent of the mast and all game data.
static func pose_destroyer_radar(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("destroyer_navigation_revision","") != "1.3":
        return false
    var pivot: Node3D = root.get_node_or_null("TorreMastil/RadarPivot") as Node3D
    if pivot == null:
        return false
    pivot.rotation_degrees.y = fposmod(progress,1.0)*360.0
    return true

# Aft deck and stylized propulsion silhouettes for the fictional game model.
# Dimensions below are artistic scene units, not real ship specifications.
static func _destroyer_aft(root: Node3D, art_level: int) -> void:
    var detail: bool = art_level >= 13
    var sides: int = 20 if detail else 10
    var aft := Node3D.new()
    aft.name = "ConjuntoPopa"
    root.add_child(aft)
    var landing: Array = [
        [0.79,0.49,0.784,0.836],[0.86,0.63,0.784,0.836],
        [1.32,0.57,0.784,0.836],[1.44,0.46,0.784,0.836]]
    _destroyer_shell(aft,"Helipuerto",landing,DARK)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(aft,"MarcaHelipuerto_%d" % side,Vector3(sign*0.15,0.842,1.11),
            Vector3(0.055,0.014,0.36),METAL)
        _box(aft,"BordeHelipuerto_%d" % side,Vector3(sign*0.41,0.846,1.11),
            Vector3(0.035,0.020,0.35),ARMOR)
        _box(aft,"BaseAmarre_%d" % side,Vector3(sign*0.32,0.824,1.49),
            Vector3(0.17,0.065,0.13),STEEL)
        _cylinder(aft,"Amarre_%d" % side,Vector3(sign*0.32,0.904,1.49),
            0.048,0.105,DARK,Vector3.ZERO,sides)
        _box(aft,"LuzPopa_%d" % side,Vector3(sign*0.38,0.855,1.40),
            Vector3(0.07,0.055,0.075),METAL)
        if detail:
            for i in range(3):
                var z: float = 0.86 + float(i)*0.16
                _box(aft,"PostePopa_%d_%d" % [side,i],Vector3(sign*0.49,0.914,z),
                    Vector3(0.035,0.18,0.035),STEEL)
            _box(aft,"PasamanosPopa_%d" % side,Vector3(sign*0.49,0.997,1.02),
                Vector3(0.035,0.035,0.35),STEEL)
        var group := Node3D.new()
        group.name = "Propulsion_%d" % side
        group.position = Vector3(sign*0.31,0.18,1.34)
        aft.add_child(group)
        _cylinder(group,"CarcasaVisual",Vector3(0,0.04,-0.09),
            0.105,0.30,STEEL,Vector3(90,0,0),sides)
        var rotor := Node3D.new()
        rotor.name = "HelicePivot"
        rotor.position = Vector3(0,0.02,0.10)
        group.add_child(rotor)
        _cylinder(rotor,"Cubo",Vector3.ZERO,0.061,0.12,METAL,Vector3(90,0,0),sides)
        # Three abstract rounded lobes; only a visible rotation effect.
        for i in range(3):
            var blade := Node3D.new()
            blade.name = "Lobulo_%d" % i
            blade.rotation.z = float(i)*TAU/3.0
            rotor.add_child(blade)
            _sphere(blade,"PalaVisual",Vector3(0,0.081,0),
                Vector3(0.085,0.16,0.045),ARMOR)
        _box(group,"SoporteInferior",Vector3(0,0.07,-0.18),
            Vector3(0.14,0.19,0.14),STEEL)
        var rudder := Node3D.new()
        rudder.name = "TimonPivot"
        rudder.position = Vector3(0,0.09,0.23)
        group.add_child(rudder)
        _destroyer_shell(rudder,"TimonVisual",
            [[-0.02,0.048,-0.13,0.15],[0.07,0.052,-0.14,0.15],
             [0.16,0.032,-0.08,0.11]],DARK)
    _box(aft,"MarcaHelipuertoCentro",Vector3(0,0.842,1.11),
        Vector3(0.30,0.014,0.06),METAL)
    if detail:
        for side in [-1,1]:
            var sign: float = float(side)
            for i in range(3):
                _box(aft,"AnclajeCubierta_%d_%d" % [side,i],
                    Vector3(sign*0.32,0.842,0.92+float(i)*0.17),
                    Vector3(0.034,0.014,0.034),METAL)
            _box(aft,"RegistroPopa_%d" % side,Vector3(sign*0.20,0.826,1.51),
                Vector3(0.14,0.035,0.10),STEEL)
    # Static wake is purely decorative and may be hidden for inspection.
    var wake := Node3D.new()
    wake.name = "EstelaEspuma"
    wake.position = Vector3(0,0.07,1.66)
    root.add_child(wake)
    root.set_meta("destroyer_aft_revision","1.4")

static func pose_destroyer_aft(root: Node3D, progress: float, steering: float = 0.0) -> bool:
    if root == null or root.get_meta("destroyer_aft_revision","") != "1.4":
        return false
    for side in [-1,1]:
        var group: Node3D = root.get_node_or_null("ConjuntoPopa/Propulsion_%d" % side) as Node3D
        if group == null:
            return false
        var rotor: Node3D = group.get_node("HelicePivot") as Node3D
        var rudder: Node3D = group.get_node("TimonPivot") as Node3D
        rotor.rotation.z = float(side)*fposmod(progress,1.0)*TAU
        rudder.rotation_degrees.y = clampf(steering,-1.0,1.0)*25.0
    return true

# Extra closed cosmetic deck surfaces, readably attached at both detail tiers.
static func _destroyer_trim(root: Node3D, art_level: int) -> void:
    var trim := Node3D.new()
    trim.name = "AcabadoNavalV18"
    root.add_child(trim)
    for side in [-1,1]:
        var sign: float = float(side)
        var points: Array[Vector3] = [
            Vector3(sign*0.19,0.812,-2.10),Vector3(sign*0.43,0.812,-1.54),
            Vector3(sign*0.59,0.812,-0.91),Vector3(sign*0.65,0.812,0.0),
            Vector3(sign*0.61,0.812,0.89),Vector3(sign*0.44,0.812,1.48)]
        for i in range(points.size()-1):
            var v: Vector3 = points[i+1]-points[i]
            var rim: MeshInstance3D = _box(trim,"BordeCubierta_%d_%d" % [side,i],
                (points[i]+points[i+1])*0.5,Vector3(0.026,0.037,v.length()+0.025),DARK)
            rim.rotation.y = atan2(v.x,v.z)
        for i in range(3 if art_level >= 13 else 1):
            var z: float = -0.77+float(i)*0.28
            _box(trim,"RegistroServicio_%d_%d" % [side,i],
                Vector3(sign*0.55,0.822,z),Vector3(0.105,0.032,0.11),STEEL)
        if art_level >= 13:
            for i in range(3):
                var z: float = 0.15+float(i)*0.22
                _box(trim,"PostePasillo_%d_%d" % [side,i],
                    Vector3(sign*0.62,0.887,z),Vector3(0.026,0.17,0.026),STEEL)
            _box(trim,"BarandaPasillo_%d" % side,Vector3(sign*0.62,0.963,0.37),
                Vector3(0.023,0.027,0.47),STEEL)
    _box(trim,"RegistroProa",Vector3(0,0.819,-1.91),
        Vector3(0.20,0.035,0.16),STEEL)
    root.set_meta("destroyer_visual_review_v18",true)

static func _destroyer(root: Node3D, art_level: int = 10) -> void:
    var stations: Array = [
        [-2.46,0.045,0.36,0.76],[-2.15,0.24,0.18,0.76],
        [-1.56,0.62,0.15,0.76],[-0.92,0.82,0.14,0.76],
        [0.0,0.90,0.14,0.76],[0.90,0.85,0.14,0.76],
        [1.51,0.66,0.17,0.76],[1.72,0.48,0.22,0.76]]
    _destroyer_shell(root,"CascoNaval",stations,STEEL,true)
    var deck_stations: Array = []
    for station in stations:
        deck_stations.append([station[0],station[1]*0.86,0.738,0.802])
    _destroyer_shell(root,"Cubierta",deck_stations,ARMOR)
    root.set_meta("destroyer_art_revision","1.12")
    _destroyer_bridge(root,art_level)
    _destroyer_navigation(root,art_level)
    _destroyer_deck_equipment(root,art_level)
    _destroyer_aft(root,art_level)
    _destroyer_trim(root,art_level)
    _destroyer_motion_setup(root,art_level)
    _destroyer_damage_setup(root,art_level)

# Purely cosmetic game animation, independent of tactical simulation.
static func _destroyer_motion_setup(root: Node3D, art_level: int) -> void:
    var pivot: Node3D = root.get_node("TorretaNavalPivot/CanonNavalPivot") as Node3D
    var flash: MeshInstance3D = _sphere(pivot,"DestelloVisual",Vector3(0,0,-0.60),
        Vector3(0.19,0.19,0.23),Color("#FFD18A"))
    flash.hide()
    var wake: Node3D = root.get_node("EstelaEspuma") as Node3D
    var count: int = 5 if art_level >= 13 else 2
    for i in range(count):
        var patch: MeshInstance3D = _sphere(wake,"EspumaVisual_%d" % i,
            Vector3(0,0.015,0.13+float(i)*0.12),
            Vector3(0.27+float(i)*0.15,0.022,0.17),Color("#C6E1DF"))
        patch.hide()
    root.set_meta("destroyer_motion_v16",true)

# Reversible stylized game damage. All effects are preallocated, opaque,
# and independent of the simulation. Root transforms remain caller-owned.
static func _destroyer_damage_setup(root: Node3D, art_level: int) -> void:
    var fx := Node3D.new()
    fx.name = "DanoNavalVisual"
    root.add_child(fx)
    for i in range(5):
        _box(fx,"Marca_%d" % i,Vector3(-0.34+float(i)*0.17,0.817,-0.83+float(i%2)*0.15),
            Vector3(0.14,0.028,0.18),BLACK,Vector3(0,float(i)*17,0)).hide()
    for i in range(5 if art_level >= 13 else 3):
        var step: float = float(i)
        var smoke: MeshInstance3D = _sphere(fx,"Humo_%d" % i,
            Vector3(0.23+0.085*step,1.36+0.23*step,0.50+0.045*step),
            Vector3(0.27+0.095*step,0.31+0.075*step,0.29+0.075*step),
            Color("#303840").lerp(Color("#737A7E"),step/5.0))
        smoke.set_meta("destroyer_fx_rest",smoke.transform)
        smoke.hide()
    for i in range(4 if art_level >= 13 else 2):
        var flame: MeshInstance3D = _sphere(fx,"Fuego_%d" % i,
            Vector3(-0.24+float(i%2)*0.17,1.10+float(i/2)*0.14,0.72),
            Vector3(0.17,0.34+float(i%2)*0.11,0.18),Color("#FF9435"))
        flame.rotation_degrees.z = -16.0+float(i)*9.0
        flame.set_meta("destroyer_fx_rest",flame.transform)
        flame.hide()
    _box(fx,"FragmentoCubierta",Vector3(0.35,0.87,0.84),
        Vector3(0.22,0.06,0.25),STEEL,Vector3(15,20,18)).hide()
    _sphere(fx,"ImpactoBreve",Vector3(0.42,0.86,-0.72),
        Vector3(0.14,0.16,0.14),Color("#FFD9A1")).hide()
    _sphere(fx,"ImpactoAmplio",Vector3(0.39,0.91,-0.72),
        Vector3(0.36,0.31,0.34),Color("#F19456")).hide()
    # Marks on the exposed walkways, rather than underneath deck equipment.
    for side in [-1,1]:
        var sign: float = float(side)
        _box(fx,"MarcaCostado_%d" % side,Vector3(sign*0.60,0.824,-0.65),
            Vector3(0.10,0.018,0.21),Color("#30363B"),Vector3(0,side*22,0)).hide()
        _box(fx,"Quemadura_%d" % side,Vector3(sign*0.24,0.86,1.18),
            Vector3(0.22,0.018,0.23),Color("#393031"),Vector3(0,side*16,0)).hide()
    var lid: Node3D = root.get_node("ModuloCubierta/TapaModulo_3_2") as Node3D
    lid.set_meta("naval_rest_transform",lid.transform)
    for child in root.get_children():
        if child is Node3D:
            child.set_meta("naval_rest_transform",child.transform)
    root.set_meta("destroyer_damage_stage",0)

static func set_destroyer_damage(root: Node3D, stage: int, progress: float = 0.0) -> bool:
    if root == null or not root.has_node("DanoNavalVisual"):
        return false
    var d: int = clampi(stage,0,4)
    var t: float = clampf(progress,0.0,1.0)
    # Reset from stored transforms rather than accumulating offsets.
    root.set_meta("destroyer_damage_stage",0)
    restore_destroyer_pose(root)
    var fx: Node3D = root.get_node("DanoNavalVisual") as Node3D
    for child in root.get_children():
        if child is Node3D and child.has_meta("naval_rest_transform"):
            child.transform = child.get_meta("naval_rest_transform")
    for child in fx.get_children():
        var label: String = str(child.name)
        if child.has_meta("destroyer_fx_rest"):
            (child as Node3D).transform = child.get_meta("destroyer_fx_rest")
        (child as Node3D).visible = (label.begins_with("Marca") and d>=1) or (label.begins_with("Humo") and d>=2) or (label.begins_with("Fuego") and d>=3) or (label=="FragmentoCubierta" and d>=3) or (label.begins_with("Quemadura") and d>=3)
    var mast: Node3D = root.get_node("TorreMastil") as Node3D
    var bridge: Node3D = root.get_node("Superestructura") as Node3D
    var lid: Node3D = root.get_node("ModuloCubierta/TapaModulo_3_2") as Node3D
    lid.transform = lid.get_meta("naval_rest_transform")
    if d >= 2:
        mast.rotation_degrees.z = 12.0
        lid.rotation_degrees.z = -12.0
        lid.position.y += 0.015
    if d >= 3:
        mast.rotation_degrees.z = 28.0
        var hinge := Vector3(0,0.80,0.41)
        var lean := Basis(Vector3.BACK,deg_to_rad(-5.0))
        bridge.transform = Transform3D(lean,hinge-lean*hinge)
        lid.rotation_degrees.z = -28.0
        lid.position += Vector3(0.025,0.025,0.0)
    if d == 4:
        var tilt := Basis(Vector3.BACK,deg_to_rad(22.0*t))
        for child in root.get_children():
            if child is Node3D:
                var initial: Transform3D = child.transform
                child.transform = Transform3D(tilt*initial.basis,tilt*initial.origin+Vector3(0,-2.85*t,0))
    var wake: Node3D = root.get_node("EstelaEspuma") as Node3D
    wake.visible = d < 3
    root.set_meta("destroyer_damage_stage",d)
    return true

# Periodic cosmetic motion: deterministic from rest, never affects combat.
static func animate_destroyer_damage(root: Node3D, phase: float) -> bool:
    if root == null or not root.has_node("DanoNavalVisual"):
        return false
    var stage: int = int(root.get_meta("destroyer_damage_stage",0))
    if stage < 2 or stage >= 4:
        return false
    var fx: Node3D = root.get_node("DanoNavalVisual") as Node3D
    for child in fx.get_children():
        if not child is Node3D or not child.has_meta("destroyer_fx_rest"):
            continue
        var item: Node3D = child as Node3D
        var label: String = str(item.name)
        var i: float = float(int(label.get_slice("_",1)))
        var rest: Transform3D = item.get_meta("destroyer_fx_rest")
        var wave: float = sin(phase*TAU+i*0.82)
        item.transform = rest
        if label.begins_with("Humo"):
            item.position += Vector3(0.032*wave,0.045*wave,0.024*cos(phase*TAU+i))
            item.scale *= 1.0+0.085*wave
        elif label.begins_with("Fuego"):
            item.scale *= Vector3(1.0-0.06*wave,1.0+0.18*wave,1.0-0.06*wave)
    return true

static func pose_destroyer(root: Node3D, kind: String, progress: float,
        target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if root == null or not root.get_meta("destroyer_motion_v16",false):
        return false
    if kind not in ["idle","move","attack","fire","aim","hit","hit_bullet","hit_blast"]:
        return false
    if int(root.get_meta("destroyer_damage_stage",0)) >= 3:
        return false
    var t: float = clampf(progress,0.0,1.0)
    var turret: Node3D = root.get_node("TorretaNavalPivot") as Node3D
    var pivot: Node3D = turret.get_node("CanonNavalPivot") as Node3D
    var barrel: Node3D = pivot.get_node("CanonNaval") as Node3D
    var flash: Node3D = pivot.get_node("DestelloVisual") as Node3D
    var wake: Node3D = root.get_node("EstelaEspuma") as Node3D
    var moving: bool = kind == "move"
    var firing: bool = kind in ["attack","fire"]
    var aiming: bool = firing or kind == "aim"
    var pulse: float = sin(t*TAU)
    var impact: float = sin(t*PI) if kind in ["hit","hit_bullet","hit_blast"] else 0.0
    var recoil: float = sin(clampf(t/0.38,0.0,1.0)*PI) if firing else 0.0
    turret.rotation.y = atan2(-float(target_heading.x),-float(target_heading.y)) if aiming and target_heading != Vector2i.ZERO else 0.0
    pivot.rotation_degrees.x = -4.0*recoil
    barrel.position.z = -0.30+0.065*recoil
    flash.visible = firing and t > 0.01 and t < 0.18
    var small_hit: Node3D = root.get_node("DanoNavalVisual/ImpactoBreve") as Node3D
    var big_hit: Node3D = root.get_node("DanoNavalVisual/ImpactoAmplio") as Node3D
    small_hit.visible = kind in ["hit","hit_bullet"] and t > 0.0 and t < 0.27
    big_hit.visible = kind == "hit_blast" and t > 0.0 and t < 0.42
    pose_destroyer_radar(root,t)
    pose_destroyer_aft(root,t*2.0 if moving else t*0.25,0.4*pulse if moving else 0.0)
    # Preserve the map heading, scale and position owned by the caller.
    root.rotation_degrees.x = (1.8 if moving else 0.7)*pulse
    root.rotation_degrees.z = (2.0 if moving else 0.8)*sin(t*TAU) + 2.0*impact
    for child in wake.get_children():
        if child is MeshInstance3D:
            var patch: MeshInstance3D = child as MeshInstance3D
            var index: int = int(str(patch.name).get_slice("_",1))
            patch.visible = moving and t > 0.0 and t < 1.0
            patch.position.z = 0.13+float(index)*0.12+0.08*pulse
    return true

static func restore_destroyer_pose(root: Node3D) -> void:
    if root == null or not root.get_meta("destroyer_motion_v16",false):
        return
    if int(root.get_meta("destroyer_damage_stage",0)) < 3:
        pose_destroyer(root,"idle",0.0)


# M01: original fictional coastal patrol silhouette. Reuses only the
# verified closed-shell geometry helper, not the destroyer's model or rules.
static func _patrol(root: Node3D, detail: int) -> void:
    var stations: Array = [[-1.72,0.045,0.30,0.59],[-1.47,0.20,0.18,0.57],
        [-1.08,0.37,0.105,0.55],[-0.76,0.47,0.09,0.53],
        [0.0,0.55,0.08,0.53],[0.72,0.52,0.09,0.53],
        [1.20,0.43,0.14,0.53]]
    _destroyer_shell(root,"CascoNaval",stations,STEEL,true)
    var deck: Array = []
    for p in stations:
        deck.append([p[0],float(p[1])*0.94,float(p[3])-0.015,float(p[3])+0.035])
    _destroyer_shell(root,"CubiertaPatrulla",deck,DARK)
    var bridge := Node3D.new()
    bridge.name = "CabinaPatrulla"
    root.add_child(bridge)
    _destroyer_shell(bridge,"ZocaloCabina",[[-0.56,0.24,0.55,0.68],[-0.39,0.36,0.55,0.68],[0.35,0.36,0.55,0.68],[0.49,0.27,0.55,0.68]],STEEL)
    _destroyer_shell(bridge,"CarcasaCabina",[[-0.44,0.24,0.66,1.05],[-0.29,0.33,0.66,1.05],[0.27,0.33,0.66,1.05],[0.40,0.26,0.66,1.05]],STEEL)
    _destroyer_shell(bridge,"FaccionTechoCabina",[[-0.46,0.25,1.03,1.10],[-0.28,0.36,1.03,1.10],[0.28,0.36,1.03,1.10],[0.43,0.27,1.03,1.10]],ARMOR)
    for side in [-1,1]:
        var sign: float = float(side)
        for i in range(2):
            _box(bridge,"MarcoPatrulla_%d_%d" % [side,i],Vector3(sign*0.307,0.91,-0.13+float(i)*0.22),Vector3(0.048,0.16,0.19),DARK)
            _box(bridge,"CristalPatrulla_%d_%d" % [side,i],Vector3(sign*0.335,0.91,-0.13+float(i)*0.22),Vector3(0.020,0.124,0.15),Color("#38596C"))
        _box(bridge,"PuertaPatrulla_%d" % side,Vector3(sign*0.295,0.77,0.29),Vector3(0.040,0.18,0.13),DARK)
        _box(root,"FaccionBandaCubierta_%d" % side,Vector3(sign*0.32,0.571,0.74),Vector3(0.08,0.022,0.35),ARMOR)
        _box(root,"DefensaLateral_%d" % side,Vector3(sign*0.46,0.47,0.47),Vector3(0.11,0.11,0.39),RUBBER)
        if detail >= 13:
            for i in range(3):
                _box(root,"PostePatrulla_%d_%d" % [side,i],Vector3(sign*0.34,0.65,0.57+float(i)*0.17),Vector3(0.025,0.19,0.025),STEEL)
            _box(root,"BarandaPatrulla_%d" % side,Vector3(sign*0.34,0.736,0.74),Vector3(0.025,0.026,0.37),STEEL)
    for i in range(2):
        _box(bridge,"MarcoFrontalPatrulla_%d" % i,Vector3(-0.10+float(i)*0.20,0.92,-0.448),Vector3(0.195,0.155,0.030),DARK)
        _box(bridge,"CristalFrontalPatrulla_%d" % i,Vector3(-0.10+float(i)*0.20,0.92,-0.47),Vector3(0.16,0.12,0.020),Color("#38596C"))
    _box(root,"AmarreProa",Vector3(0,0.603,-1.28),Vector3(0.14,0.06,0.07),METAL)
    if detail >= 13:
        for side in [-1,1]:
            var sign: float = float(side)
            var points: Array[Vector3] = [Vector3(sign*0.13,0.602,-1.47),
                Vector3(sign*0.27,0.582,-1.08),Vector3(sign*0.35,0.566,-0.76),
                Vector3(sign*0.43,0.566,0.0),Vector3(sign*0.40,0.566,0.72),
                Vector3(sign*0.32,0.566,1.20)]
            for i in range(points.size()-1):
                var v: Vector3 = points[i+1]-points[i]
                var rim: MeshInstance3D = _box(root,"BordePatrulla_%d_%d" % [side,i],
                    (points[i]+points[i+1])*0.5,Vector3(0.024,0.030,v.length()+0.014),STEEL)
                rim.rotation.y = atan2(v.x,v.z)
    _box(root,"RegistroPopaPatrulla",Vector3(0,0.58,0.82),Vector3(0.36,0.04,0.37),STEEL)
    _box(root,"BaseProaPatrulla",Vector3(0,0.58,-0.91),Vector3(0.30,0.06,0.32),DARK)
    var turret := Node3D.new()
    turret.name = "ModuloVisualPatrulla"
    turret.position = Vector3(0,0.61,-0.91)
    root.add_child(turret)
    _cylinder(turret,"AsientoModulo",Vector3(0,0.035,0),0.12,0.07,STEEL)
    _destroyer_shell(turret,"CarcasaModulo",[[-0.14,0.08,0.065,0.20],[-0.07,0.12,0.065,0.20],[0.10,0.12,0.065,0.20],[0.14,0.09,0.065,0.20]],ARMOR)
    _box(turret,"DetalleFrontal",Vector3(0,0.145,-0.18),Vector3(0.055,0.055,0.18),DARK)
    _sphere(turret,"DestelloVisual",Vector3(0,0.145,-0.29),Vector3(0.16,0.16,0.20),Color("#FFCA77")).hide()
    for side in [-1,1]:
        var sign: float = float(side)
        _cylinder(root,"PropulsionEstilizada_%d" % side,Vector3(sign*0.22,0.19,1.07),0.08,0.24,DARK,Vector3(90,0,0))
        _box(root,"SoportePopa_%d" % side,Vector3(sign*0.22,0.29,1.04),Vector3(0.10,0.19,0.18),STEEL)
        _box(root,"AmarrePatrulla_%d" % side,Vector3(sign*0.26,0.59,1.01),Vector3(0.10,0.055,0.065),METAL)
    var mast := Node3D.new()
    mast.name = "MastilPatrulla"
    mast.position = Vector3(0,1.10,0.11)
    root.add_child(mast)
    _box(mast,"SoporteMastil",Vector3(0,0.16,0),Vector3(0.10,0.34,0.12),STEEL)
    var radar := Node3D.new()
    radar.name = "RadarPatrulla"
    radar.position.y = 0.34
    mast.add_child(radar)
    _box(radar,"SensorOpaco",Vector3(0,0.046,0),Vector3(0.34,0.09,0.11),DARK)
    # Independent sealed relief pieces, with a recognizable cabin and deck.
    _box(bridge,"MarcoTrasero",Vector3(0,0.85,0.407),Vector3(0.24,0.29,0.032),DARK)
    _box(bridge,"PuertaTrasera",Vector3(0,0.85,0.430),Vector3(0.19,0.23,0.022),STEEL)
    _box(bridge,"TiradorTrasero",Vector3(0.065,0.84,0.446),Vector3(0.022,0.058,0.025),METAL)
    _box(bridge,"ViseraFrontal",Vector3(0,1.025,-0.46),Vector3(0.46,0.045,0.16),DARK)
    _box(mast,"FaccionPanelMastil",Vector3(0,0.19,0.065),Vector3(0.085,0.20,0.025),ARMOR)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(bridge,"LuzNavegacion_%d" % side,Vector3(sign*0.32,1.105,0.12),Vector3(0.075,0.056,0.075),Color("#E87D49") if side < 0 else Color("#58C5A4"))
        _box(root,"EscalonPopa_%d" % side,Vector3(sign*0.27,0.575,0.49),Vector3(0.12,0.045,0.16),STEEL)
        var rotor := Node3D.new()
        rotor.name = "RotorPatrulla_%d" % side
        rotor.position = Vector3(sign*0.22,0.13,1.18)
        root.add_child(rotor)
        _cylinder(rotor,"CentroRotor",Vector3.ZERO,0.045,0.09,STEEL,Vector3(90,0,0))
        for blade in range(3):
            var pivot := Node3D.new()
            pivot.rotation.z = float(blade)*TAU/3.0
            rotor.add_child(pivot)
            _sphere(pivot,"PalaVisual",Vector3(0,0.075,0),Vector3(0.055,0.13,0.035),METAL)
        if detail >= 13:
            for i in range(3):
                _box(bridge,"RelieveVentilacion_%d_%d" % [side,i],Vector3(sign*0.351,0.73+float(i)*0.034,0.17),Vector3(0.025,0.015,0.10),METAL)
            for i in range(3):
                _box(root,"RegistroPasillo_%d_%d" % [side,i],Vector3(sign*0.36,0.574,-0.35+float(i)*0.25),Vector3(0.08,0.018,0.12),STEEL)
    var wake := Node3D.new()
    wake.name = "EstelaPatrulla"
    root.add_child(wake)
    for i in range(4 if detail >= 13 else 2):
        _sphere(wake,"Espuma_%d" % i,Vector3(0,0.14,1.28+float(i)*0.13),Vector3(0.25+float(i)*0.12,0.025,0.18),Color("#C5E3E4")).hide()
    var fx := Node3D.new()
    fx.name = "DanoPatrulla"
    root.add_child(fx)
    _box(fx,"Marca",Vector3(0.22,0.58,-0.73),Vector3(0.14,0.025,0.16),DARK).hide()
    _sphere(fx,"Humo",Vector3(0.15,1.12,0.29),Vector3(0.32,0.45,0.31),Color("#555B62")).hide()
    _sphere(fx,"Fuego",Vector3(-0.25,1.10,0.46),Vector3(0.24,0.38,0.22),Color("#F49138")).hide()
    _sphere(fx,"HumoSuperior",Vector3(0.22,1.48,0.38),Vector3(0.39,0.43,0.36),Color("#737B80")).hide()
    _sphere(fx,"FuegoSecundario",Vector3(0.19,0.94,0.51),Vector3(0.21,0.33,0.20),Color("#FFAD54")).hide()
    _box(fx,"MarcaPasillo",Vector3(0.36,0.578,-0.22),Vector3(0.11,0.024,0.17),Color("#252B30")).hide()
    _box(fx,"Fragmento",Vector3(0.21,0.66,0.82),Vector3(0.18,0.055,0.18),STEEL,Vector3(15,22,30)).hide()
    for child in fx.get_children():
        if child is Node3D and (str(child.name).begins_with("Humo") or str(child.name).begins_with("Fuego")):
            child.set_meta("patrol_effect_rest",child.transform)
    for child in root.get_children():
        if child is Node3D:
            child.set_meta("patrol_rest",child.transform)
    root.set_meta("patrol_art_revision","1.3")
    root.set_meta("patrol_damage",0)

static func set_patrol_damage(root: Node3D, stage: int, phase: float = 0.0) -> bool:
    if root == null or not root.has_meta("patrol_art_revision"):
        return false
    var d: int = clampi(stage,0,4)
    root.set_meta("patrol_damage",d)
    root.rotation_degrees.x = 0.0
    root.rotation_degrees.z = 0.0
    for child in root.get_children():
        if child is Node3D and child.has_meta("patrol_rest"):
            child.transform = child.get_meta("patrol_rest")
    for foam in root.get_node("EstelaPatrulla").get_children():
        (foam as Node3D).hide()
    (root.get_node("ModuloVisualPatrulla/DestelloVisual") as Node3D).hide()
    (root.get_node("MastilPatrulla/RadarPatrulla") as Node3D).rotation.y = 0.0
    var effects: Node3D = root.get_node("DanoPatrulla") as Node3D
    for child in effects.get_children():
        if child is Node3D and child.has_meta("patrol_effect_rest"):
            child.transform = child.get_meta("patrol_effect_rest")
    (effects.get_node("Marca") as Node3D).visible = d >= 1
    (effects.get_node("Humo") as Node3D).visible = d >= 2
    (effects.get_node("Fuego") as Node3D).visible = d >= 3
    (effects.get_node("HumoSuperior") as Node3D).visible = d >= 2
    (effects.get_node("FuegoSecundario") as Node3D).visible = d >= 3
    (effects.get_node("MarcaPasillo") as Node3D).visible = d >= 1
    (effects.get_node("Fragmento") as Node3D).visible = d >= 3
    var hatch: Node3D = root.get_node("RegistroPopaPatrulla") as Node3D
    if d >= 2:
        hatch.rotation_degrees.z = -14.0 if d == 2 else -28.0
        hatch.position.y += 0.025 if d == 2 else 0.055
    var mast: Node3D = root.get_node("MastilPatrulla") as Node3D
    mast.rotation_degrees.z = 0.0 if d < 2 else (13.0 if d == 2 else 30.0)
    if d == 4:
        var t: float = clampf(phase,0.0,1.0)
        var tilt := Basis(Vector3.BACK,deg_to_rad(25.0*t))
        for child in root.get_children():
            if child is Node3D:
                var rest: Transform3D = child.transform
                child.transform = Transform3D(tilt*rest.basis,tilt*rest.origin+Vector3(0,-2.2*t,0))
    return true

static func animate_patrol_damage(root: Node3D, phase: float) -> bool:
    if root == null or not root.has_meta("patrol_art_revision"):
        return false
    var stage: int = int(root.get_meta("patrol_damage",0))
    if stage < 2 or stage >= 4:
        return false
    var effects: Node3D = root.get_node("DanoPatrulla") as Node3D
    var i: int = 0
    for child in effects.get_children():
        if child is Node3D and child.has_meta("patrol_effect_rest"):
            var effect: Node3D = child as Node3D
            effect.transform = effect.get_meta("patrol_effect_rest")
            var wave: float = sin(phase*TAU+float(i)*0.9)
            if str(effect.name).begins_with("Humo"):
                effect.position += Vector3(0.035*wave,0.05*wave,0.02*cos(phase*TAU))
                effect.scale *= 1.0+0.08*wave
            else:
                effect.scale *= Vector3(1.0,1.0+0.16*wave,1.0)
            i += 1
    return true

static func pose_patrol(root: Node3D, kind: String, phase: float, heading: Vector2i = Vector2i(0,-1)) -> bool:
    if root == null or not root.has_meta("patrol_art_revision") or int(root.get_meta("patrol_damage",0)) >= 4:
        return false
    if kind not in ["idle","move","hit","damage","damaged","attack","fire","aim"]:
        return false
    var t: float = clampf(phase,0.0,1.0)
    var wave: float = sin(t*TAU)
    root.rotation_degrees.x = wave*(1.8 if kind == "move" else 0.5)
    root.rotation_degrees.z = wave*(2.5 if kind == "move" else 0.7)
    var radar: Node3D = root.get_node("MastilPatrulla/RadarPatrulla") as Node3D
    radar.rotation.y = t*TAU
    for side in [-1,1]:
        var rotor: Node3D = root.get_node("RotorPatrulla_%d" % side) as Node3D
        rotor.rotation.z = float(side)*t*TAU if kind == "move" else 0.0
    var module: Node3D = root.get_node("ModuloVisualPatrulla") as Node3D
    var action: bool = kind in ["attack","fire","aim"]
    module.rotation.y = atan2(-float(heading.x),-float(heading.y)) if action and heading != Vector2i.ZERO else 0.0
    (module.get_node("DestelloVisual") as Node3D).visible = kind in ["attack","fire"] and t > 0.02 and t < 0.20
    for foam in root.get_node("EstelaPatrulla").get_children():
        (foam as Node3D).visible = kind == "move" and t > 0.0 and t < 1.0
    return true

# Patrol-only opaque material finish. The validated destroyer stays untouched.
static func _patrol_finish(node: Node, detail: bool) -> void:
    if node is MeshInstance3D:
        var part: MeshInstance3D = node as MeshInstance3D
        var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
        if mat != null:
            var label: String = str(part.name)
            mat.metallic = 0.12
            mat.roughness = 0.65
            if label.begins_with("Cristal"):
                mat.metallic = 0.03
                mat.roughness = 0.34
                mat.albedo_color = Color("#597C91")
            elif label.begins_with("Humo") or label.begins_with("Espuma"):
                mat.metallic = 0.0
                mat.roughness = 1.0
            elif label.begins_with("Fuego") or label == "DestelloVisual" or label.begins_with("LuzNavegacion"):
                mat.metallic = 0.0
                mat.emission_enabled = true
                mat.emission = mat.albedo_color
                mat.emission_energy_multiplier = 0.75
            elif label.begins_with("DefensaLateral"):
                mat.metallic = 0.0
                mat.roughness = 0.94
            elif detail and label in ["CarcasaCabina","CubiertaPatrulla","ZocaloCabina"]:
                mat.albedo_texture = _destroyer_grain()
                mat.uv1_triplanar = true
                mat.uv1_scale = Vector3(3,3,3)
    for child in node.get_children():
        _patrol_finish(child,detail)

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
                    elif not InfantryEngineerV12.apply(model,
                            faction_paint_color(faction),art_level>=13):
                        push_warning("Engineer V12 sculpted dorsal pouches and sealed exterior shield layers missing")
                    elif not InfantryEngineerV13.apply(model,art_level>=13):
                        push_warning("Engineer V13 smooth and sealed rounded surfaces missing")
                    elif not InfantryEngineerV14.apply(model,art_level>=13):
                        push_warning("Engineer V14 anatomical helmet/shoulder/neck/chest contours missing")
                    elif not InfantryEngineerV15.apply(model,art_level>=13):
                        push_warning("Engineer V15 rounded rifle, straps and shield-edge art missing")
                    elif not InfantryEngineerV16.apply(model,art_level>=13):
                        push_warning("Engineer V16 unified torso, pelvis and leg silhouette missing")
                    elif not InfantryEngineerV17.apply(model,art_level>=13):
                        push_warning("Engineer V17 organic outer armor silhouette and closed knee pads missing")
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
        "uav_recon":
            # A01 is an original unarmed fixed-wing drone; do not reuse
            # the A05 HAT-29 attack helicopter or expose its weapons.
            if not A01Recon.build(model,faction_paint_color(faction),
                    finish_enabled and art_level>=13):
                return null
            # V2 is an additive, opaque physical finish, including Android
            # LOD8 high-contrast faction markings and rotating EO/IR glass.
            if finish_enabled and art_level>=8:
                if not A01Finish.apply(model,faction_paint_color(faction),
                        art_level>=13):
                    push_warning("A01 V2 wing edge, faction paint or gimbal PBR failed")
                elif not A01HardwareV3.apply(model,faction_paint_color(faction),
                        art_level>=13):
                    push_warning("A01 V3 propeller, winglet or camera bearings failed")
                elif not A01AirfoilV4.apply(model,art_level>=13):
                    push_warning("A01 V4 closed aerofoil and root fairings failed")
                elif not A01TailV5.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("A01 V5 closed V-tail sculpt and boom fairings failed")
                elif not A01DamageV6.prepare(model,art_level>=13):
                    push_warning("A01 V6 reversible native visual damage rig missing")
                elif not A01WingletV8.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("A01 V8 swept closed wingtip fins failed")
                elif not A01WingletV9.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("A01 V9 conformal winglet enamel or root fairings failed")
                elif not A01NoseOpticsV10.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("A01 V10 sealed sculpt nose or moving gimbal optics failed")
                elif not A01AirframeV11.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("A01 V11 sealed tapered body and conformal faction panels failed")
                elif not A01WingRootV12.apply(model,art_level>=13):
                    push_warning("A01 V12 closed sculpted wing shoulders failed")
                elif not A01TailOpticsV13.apply(model,faction_paint_color(faction),art_level>=13):
                    push_warning("A01 V13 conformal V-tail and moving EOIR guard failed")
                elif not A01DamageFinishV14.apply(model,art_level>=13):
                    push_warning("A01 V14 sealed aircraft scars or real D4 fractured wing failed")
        "fpv":
            if not A02Art.build(model,faction_paint_color(faction),finish_enabled and art_level>=13):
                return null
        "fighter":
            _fighter(model)
        "patrol":
            _patrol(model,art_level)
            apply_faction_palette(model,faction)
            _destroyer_finish(model,art_level >= 13)
            _patrol_finish(model,art_level >= 13)
        "destroyer":
            _destroyer(model,art_level)
            apply_faction_palette(model,faction)
            _destroyer_finish(model,art_level >= 13)
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
    elif role in ["attack_heli","fighter","destroyer","patrol"]:
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
            var engineer_v17: bool=InfantryEngineerV17.has_model(model) and bool(
                model.get_meta("tarvoka_engineer_v17_visible",true))
            var destroyed: bool=engineer_v17 and InfantryFamily.damage_stage(model)>=4
            var visual_kind: String="idle" if destroyed else kind
            if destroyed and InfantryFinishV2.has_model(model):
                InfantryFinishV2.pose(model,"idle",0.0)
            InfantryEngineerV6.pose(model,visual_kind,0.0 if destroyed else progress)
            # Finish the visual pose before solving physical hand contacts.
            if engineer_v17:
                InfantryEngineerV17.polish_pose(model,kind,progress)
                InfantryEngineerV17.sync_damage_visuals(model,visual_kind,progress)
            if InfantryEngineerV9.has_model(model):
                InfantryEngineerV9.sync(model,visual_kind)
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
        "patrol":
            if kind in ["sink","destroy"]:
                return set_patrol_damage(model,4,progress)
            return pose_patrol(model,kind,progress,target_heading)
        "destroyer":
            if kind in ["damage","damaged","hit"]:
                return pose_destroyer(model,"hit",progress,target_heading)
            if kind == "sink" or kind == "destroy":
                return set_destroyer_damage(model,4,progress)
            return pose_destroyer(model,kind,progress,target_heading)
        "uav_recon":
            return A01Recon.pose(model,kind,progress)
        "fpv":
            return A02Art.pose(model,kind,progress)
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
            if InfantryEngineerV17.has_model(model):
                InfantryEngineerV17.sync_damage_visuals(model,"idle",0.0,true)
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
        "patrol":
            pose_patrol(model,"idle",0.0)
        "destroyer":
            restore_destroyer_pose(model)
        "uav_recon":
            A01Recon.restore(model)
        "fpv":
            A02Art.restore(model)
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
