extends "res://scripts/ui/CombinedArtStudioWeb.gd"
class_name TarvokaBastionStudioAdapter

# Published P06 presentation uses the sculpted V5 art, not the initial native
# prototype. Other HQ / Airbase / G09 studio categories remain unchanged.
const P06Models = preload("res://scripts/ui/UnitModels3D.gd")
const InfantryV1 = preload("res://scripts/ui/InfantryFamilyV1.gd")
const EngineerFinishV6 = preload("res://scripts/ui/InfantryEngineerFinishV6.gd")
const InfantryRoster = preload("res://scripts/ui/InfantryCampRosterV1.gd")
const P06Visual = preload("res://scripts/ui/APCVisualRigV1.gd")
const P06Finish = preload("res://scripts/ui/APCFinishV3.gd")
const P06Details = preload("res://scripts/ui/APCDetailV5.gd")
const P06V6 = preload("res://scripts/ui/APCFinishV6.gd")
const P06Burst = preload("res://scripts/ui/APCMachineGunV7.gd")
const P06Wreck = preload("res://scripts/ui/APCDamageV7.gd")
const P06RearV10 = preload("res://scripts/ui/APCRearDesignV10.gd")
const P06ExteriorV11 = preload("res://scripts/ui/APCExteriorV11.gd")
const P06TurretV12 = preload("res://scripts/ui/APCTurretV12.gd")
const P06SurfaceV13 = preload("res://scripts/ui/APCSurfaceV13.gd")
const P06WheelsV14 = preload("res://scripts/ui/APCWheelV14.gd")
const P06UnderV15 = preload("res://scripts/ui/APCUndercarriageV15.gd")
const P06JointV16 = preload("res://scripts/ui/APCJointFinishV16.gd")
const P06ContourV17 = preload("res://scripts/ui/APCContourV17.gd")
const P06WheelwellV18 = preload("res://scripts/ui/APCWheelwellV18.gd")
const P06FlankV19 = preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const P06MicroV20 = preload("res://scripts/ui/APCMicrodetailV20.gd")
const P06MaterialV21 = preload("res://scripts/ui/APCMaterialFinishV21.gd")
const P06WeatherV22 = preload("res://scripts/ui/APCWeatherFinishV22.gd")
const P06TireV23 = preload("res://scripts/ui/APCTireFinishV23.gd")
const P06RubberV24 = preload("res://scripts/ui/APCRubberArchV24.gd")
const P06ClosedV25 = preload("res://scripts/ui/APCClosedTiresV25.gd")
const P06Audio = preload("res://scripts/ui/APCWeaponAudioV8.gd")
const P06Tactical = preload("res://scripts/ui/APCTacticalLOD8.gd")
const G11Art = preload("res://scripts/ui/G11Art3D.gd")
const G11Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const G11Weather = preload("res://scripts/ui/G11SurfaceWeatherV17.gd")
const G11Atmos = preload("res://scripts/ui/G11DamageAtmosphereV7.gd")
const G11JointsV22 = preload("res://scripts/ui/G11SuspensionJointsV22.gd")
const G11JointsV23 = preload("res://scripts/ui/G11JointFinishV23.gd")
const G11TacticalV24 = preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const G11Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const HeliV1 = preload("res://scripts/ui/AttackHelicopterV1.gd")
const HeliV2 = preload("res://scripts/ui/AttackHelicopterCabinV2.gd")
const HeliV3 = preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const HeliV4 = preload("res://scripts/ui/AttackHelicopterEnginesV4.gd")
const HeliV5 = preload("res://scripts/ui/AttackHelicopterLandingV5.gd")
const HeliV6 = preload("res://scripts/ui/AttackHelicopterLandingFinishV6.gd")
const HeliV7 = preload("res://scripts/ui/AttackHelicopterReadabilityV7.gd")
const HeliV8 = preload("res://scripts/ui/AttackHelicopterSilhouetteV8.gd")
const HeliV10 = preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const HeliV11 = preload("res://scripts/ui/AttackHelicopterTailV11.gd")
const HeliV12 = preload("res://scripts/ui/AttackHelicopterNoseV12.gd")
const HeliV13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const HeliCombatV14 = preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
const HeliRotorContactV1410 = preload("res://scripts/ui/AttackHelicopterRotorContactV1410.gd")
const HeliBladeRootsV1411 = preload("res://scripts/ui/AttackHelicopterBladeRootsV1411.gd")
const HeliBladeSeamV1412 = preload("res://scripts/ui/AttackHelicopterBladeSeamV1412.gd")
const HeliHubCrownV1413 = preload("res://scripts/ui/AttackHelicopterHubCrownV1413.gd")
const HeliHubWreckV1414 = preload("res://scripts/ui/AttackHelicopterHubWreckV1414.gd")
const HeliHubCutFinishV1415 = preload("res://scripts/ui/AttackHelicopterHubCutFinishV1415.gd")
const HeliNightV144 = preload("res://scripts/ui/AttackHelicopterNightStudioV144.gd")
const G11ContextV25 = preload("res://scripts/ui/G11BattleContextV25.gd")
const G11LODDriverV25 = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const G11ActionsV29 = preload("res://scripts/ui/G11BattleActionsV29.gd")
const G11AuditV33 = preload("res://scripts/ui/G11FinalAuditV33.gd")
const G15EW=preload("res://scripts/ui/G15ElectronicWarfareV1.gd")
const G16Logistics=preload("res://scripts/ui/G16ArmoredLogisticsV1.gd")
const G16ExteriorV2=preload("res://scripts/ui/G16LogisticsExteriorV2.gd")
const G16MechanicsV3=preload("res://scripts/ui/G16LogisticsMechanicsDamageV3.gd")
const G16SculptV4=preload("res://scripts/ui/G16LogisticsSculptDamageV4.gd")
const G16MaterialsV5=preload("res://scripts/ui/G16PremiumMaterialsDamageV5.gd")
const G16ServiceV6=preload("res://scripts/ui/G16DeployableSupplyHardwareV6.gd")
const A01Recon=preload("res://scripts/ui/A01ReconDroneV1.gd")
const A01Finish=preload("res://scripts/ui/A01ReconFinishV2.gd")
const A01HardwareV3=preload("res://scripts/ui/A01ReconFinishV3.gd")
const G15SculptV2=preload("res://scripts/ui/G15ChassisAndMastFinishV2.gd")
const G15FinishV3=preload("res://scripts/ui/G15ShelterCabFinishV3.gd")
const G15AntennaV4=preload("res://scripts/ui/G15AntennaMechanicsV4.gd")
const G15FinishV5=preload("res://scripts/ui/G15AntennaFinishDamageV5.gd")
const G15ExteriorV6=preload("res://scripts/ui/G15ArmoredExteriorV6.gd")
const G15MechanicalV7=preload("res://scripts/ui/G15MechanicalExteriorV7.gd")
const G15ContinuityV8=preload("res://scripts/ui/G15ContinuitySuspensionV8.gd")
const G15SurfaceV9=preload("res://scripts/ui/G15ProductionSurfaceV9.gd")
const G15OpticalV10=preload("res://scripts/ui/G15OpticalGlazingV10.gd")
const G15DetailV11=preload("res://scripts/ui/G15Detail360V11.gd")
const G13TacticalV25=preload("res://scripts/ui/G13TacticalSilhouetteV25.gd")
const G13ArmorV26=preload("res://scripts/ui/G13TacticalArmorV26.gd")
const G13RadarV27=preload("res://scripts/ui/G13ElevatedRadarV27.gd")
const G13DeckV28=preload("res://scripts/ui/G13RadarDeckMountV28.gd")
const G13FoldV29=preload("res://scripts/ui/G13FoldingRadarV29.gd")
const G13GunMountV31=preload("res://scripts/ui/G13GunMountFinishV31.gd")
const G13FinishV32=preload("res://scripts/ui/G13FactionMountFinishV32.gd")
const G13ChassisV33=preload("res://scripts/ui/G13ChassisFinishV33.gd")
const G13ClosureV34=preload("res://scripts/ui/G13BodyClosureV34.gd")
const G13RearV35=preload("res://scripts/ui/G13RearServiceFinishV35.gd")
const G13FinishV36=preload("res://scripts/ui/G13ProportionFinishV36.gd")
const G13FinishV37=preload("res://scripts/ui/G13RoofRadarFinishV37.gd")
const G13FinishV38=preload("res://scripts/ui/G13BodyJoineryV38.gd")
const G13FinishV39=preload("res://scripts/ui/G13UndersealFinishV39.gd")
const G13FinishV40=preload("res://scripts/ui/G13SilhouetteFinishV40.gd")
const G13ContourV41=preload("res://scripts/ui/G13ContourPolishV41.gd")
const G13ArcEndsV42=preload("res://scripts/ui/G13ArcTerminationV42.gd")
const G13ExteriorV44=preload("res://scripts/ui/G13ExteriorFinishV44.gd")
const G13CabV45=preload("res://scripts/ui/G13CabServiceFinishV45.gd")
const G13WheelV46=preload("res://scripts/ui/G13WheelMachiningV46.gd")
const G13SurfaceV47=preload("res://scripts/ui/G13MaterialFinishV47.gd")
const G13SculptV48=preload("res://scripts/ui/G13SculptFinishV48.gd")
const G13SeamsV49=preload("res://scripts/ui/G13SeamlessSilhouetteV49.gd")
const G13GlazingV50=preload("res://scripts/ui/G13GlazingFitV50.gd")
const G13RoofV51=preload("res://scripts/ui/G13CabRoofIntegrationV51.gd")
const G13RoofRailsV52=preload("res://scripts/ui/G13RoofShoulderFitV52.gd")
const G13RealismV53=preload("res://scripts/ui/G13MaterialRealismV53.gd")
const G13RubberV54=preload("res://scripts/ui/G13RubberSculptV54.gd")
const G13MicroV55=preload("res://scripts/ui/G13ExteriorMicrofinishV55.gd")
const G13JointV56=preload("res://scripts/ui/G13MechanicalJointFinishV56.gd")
const G13VisibleV57=preload("res://scripts/ui/G13TacticalMountReadabilityV57.gd")
const G13IsoV58=preload("res://scripts/ui/G13IsometricMechanicalFinishV58.gd")
const G13PremiumV59=preload("res://scripts/ui/G13PremiumSurfaceV59.gd")
const G13TreadV60=preload("res://scripts/ui/G13ContinuousTreadV60.gd")
const G13WheelArmorV61=preload("res://scripts/ui/G13ProductionWheelArmorV61.gd")
const G13GlassV62=preload("res://scripts/ui/G13OpticalGlazingV62.gd")
const G13FactionV63=preload("res://scripts/ui/G13FactionReadabilityV63.gd")
const G13EdgesV64=preload("res://scripts/ui/G13ArmorEdgeFinishV64.gd")
const G13RingV65=preload("res://scripts/ui/G13TurretRingFinishV65.gd")
const G13MountV66=preload("res://scripts/ui/G13CannonMountFinishV66.gd")
const G13FeedV67=preload("res://scripts/ui/G13BreechFeedFinishV67.gd")
const G13EjectorV68=preload("res://scripts/ui/G13EjectionMechanicsV68.gd")
const G13MuzzleV69=preload("res://scripts/ui/G13MuzzleMountFinishV69.gd")
const P06Stages := [
    "Intacto","Impactos leves","Daño moderado","Daño crítico","Destruido"
]

var p06_controls: VBoxContainer
var p06_hint: Label
var p06_version_button: Button
var p06_ramp_button: Button
var _p06_show_v5: bool = true
var _p06_weather_v22: String = "clear"
var _p06_light_v22: int = 0
var _p06_night_fill_v22: OmniLight3D
var _p06_quality_verified: bool = false
var _p06_fleet: Node3D
var _p06_fleet_count: int = 0
var _p06_fleet_surfaces: int = 0
var _p06_fleet_build_ms: float = 0.0
var _p06_fleet_quality: int = -1 # -1 = camera auto, 0/1/2 = forced
var _p06_fleet_active_surfaces: int = 0
var _p06_fleet_animation: String = ""
var _p06_fleet_animation_time: float = 0.0
var _p06_fleet_update_clock: float = 0.0
var _p06_fleet_fps_sample: int = -1
var _p06_fleet_fps_clock: float = 0.0
var heli_controls: VBoxContainer
var _heli_v2_enabled: bool=true
var _heli_v7_enabled: bool=true
var _heli_v7_button: Button
var _heli_v8_enabled: bool=true
var _heli_v8_button: Button
var _heli_v10_enabled: bool=true
var _heli_v10_button: Button
var _heli_v11_enabled: bool=true
var _heli_v11_button: Button
var _heli_v12_enabled: bool=true
var _heli_v12_button: Button
var _heli_v10_rim_light: DirectionalLight3D
var _heli_night_fill_v143: OmniLight3D
var _heli_night_enabled_v143: bool=false
var _heli_night_snapshot_v143: Dictionary={}
var _heli_night_button_v143: Button
var _heli_camera_base: Vector3=Vector3.ZERO
var _heli_focus_local: Vector3=Vector3.ZERO
# True inspection camera beneath the native A01, not a tilted top view.
# Plane meshes hidden for the inspection are restored on every exit path.
var _heli_underbody_view_active: bool=false
# Side-on mechanical microscope for the fixed transmission below the blades.
var _heli_mast_view_active_v145: bool=false
var _heli_hidden_floor_meshes: Array[MeshInstance3D]=[]
var _heli_compare_button: Button
var _heli_animation: String=""
var _heli_playback_speed: float=1.0
var _heli_damage_stage: int=0
var _heli_wreck_frozen: bool=false
var _heli_damage_clock: float=0.0
var _heli_time: float=0.0
# A01 V9 — mobile landscape: quick actions near the model picker, not below
# the full technical catalogue. Other units keep their existing controls.
var heli_mobile_bar: VBoxContainer
var _heli_mobile_expand_button: Button
var _heli_mobile_hint: Label
var _heli_compact_landscape: bool=false
var _heli_mobile_expanded: bool=false
var _heli_frame_reflows: int=0
var g11_controls: VBoxContainer
var g13_controls: VBoxContainer
var _g13_preview_lod:int=13
var _g13_reflection_saved_v53: Dictionary = {}
var _g13_rim_light_v53: DirectionalLight3D = null
var _g13_v25_show_original:bool=false
var _g13_v26_show_previous:bool=false
var _g13_v27_show_previous:bool=false
var _g13_v28_show_previous:bool=false
var g13_android_probe: Node = null
var _g13_v4_tween: Tween
var _g15_tween: Tween
var _g16_tween: Tween
var _a01_tween: Tween = null
var a01_360_panel:VBoxContainer
var _a01_review_tween:Tween = null
var _a01_review_focus:String="general"
# G16 in the SAME native online Godot viewer: camera presets and persistent
# resupply inspection never affect gameplay or production stats.
var g16_360_panel: VBoxContainer
var _g16_review_tween: Tween = null
var _g16_review_focus: String = "general"
var _infantry_tween: Tween
var _engineer_v6_tween: Tween = null
var _g11_animation: String = ""
var _g11_turn_tween: Tween
var _g11_time: float = 0.0
var _g11_playback_speed: float = 1.0
var _g11_fx_clock: float = 0.0
var _g11_light_v23: int = 0
var _g11_lamps_v23: Array[OmniLight3D] = []
var _g11_preview_lod_v24: int = 13
var _g11_context_v25: Node3D = null
var _g11_context_biome_v25: String = ""
# Shared inspector UI: the actual Godot scene, not a second WebGL viewer.
var studio_quick_panel: VBoxContainer
var studio_quick_title: Label
var studio_versions_fold: VBoxContainer
var studio_versions_button: Button
var studio_versions_content: VBoxContainer
var studio_versions_expanded: bool = false
var studio_overview_label: Label
var studio_advanced_group: VBoxContainer
var studio_advanced_content: VBoxContainer
var studio_advanced_button: Button
var studio_advanced_expanded: bool = false
var studio_selector_panel: VBoxContainer
var studio_animation_panel: VBoxContainer
var studio_camera_panel: VBoxContainer
var studio_tab_animations: Button
var studio_tab_camera: Button
var studio_tab_technical: Button
var studio_active_tab: int = 0
var studio_legacy_controls: VBoxContainer
var studio_attack_button: Button
var studio_impact_button: Button
var studio_g13_ground_button: Button
var studio_animation_inventory: VBoxContainer
var studio_animation_message: Label
var studio_animation_role: String = ""
var studio_animation_rebuild_count: int = 0
# Shared-viewport V1/V2 comparison and orbit: no second viewer or scene.
var infantry_360_panel: VBoxContainer
var infantry_six_panel: VBoxContainer
var infantry_360_tween: Tween = null
var infantry_review_v2: bool = true
var infantry_review_lod: int = 13


func _ready() -> void:
    super._ready()
    _heli_camera_base=camera.position if camera!=null else Vector3(5.3,4.2,6.3)
    _install_p06_controls()
    _install_g11_controls()
    _install_g13_controls()
    _install_heli_controls()
    _install_heli_mobile_bar()
    _install_unified_studio_navigation()
    get_viewport().size_changed.connect(_heli_on_viewport_resize)
    _install_p06_lighting_v22()
    _install_g11_lighting_v23()
    _install_heli_lighting_v10()
    var g11_index: int = P06Models.ROLES.find("mlrs")
    if g11_index >= 0:
        role_picker.set_item_text(g11_index,"G11 Lanzador · V33")
    var aa_index: int=P06Models.ROLES.find("aa_mobile")
    if aa_index>=0:
        role_picker.set_item_text(aa_index,"G13 · AA V69 · bocachas y anclajes mecanizados")
    var logistics_index:int=P06Models.ROLES.find("logistics_mobile")
    if logistics_index>=0:
        role_picker.set_item_text(logistics_index,"G16 · Logística blindada 6×6 · V6 FINAL")
    var recon_index:int=P06Models.ROLES.find("uav_recon")
    if recon_index>=0 and role_picker!=null:
        # Appended role only; preserve all old picker indices and models.
        while role_picker.item_count<=recon_index:
            role_picker.add_item(P06Models.ROLES[role_picker.item_count])
        role_picker.set_item_text(recon_index,
            "A01 · Dron de reconocimiento · V3 EN DESARROLLO")
    # Preserve existing roles/indices; these are additional native 3D variants.
    for entry in [
        ["line","★ INFANTERÍA BÁSICA · Guardia"],
        ["infantry_urban","Boceto anterior · Guardia urbana"],
        ["infantry_defense","Boceto anterior · Guardia defensiva"],
        ["scout","Boceto anterior · Rastreador"],
        ["infantry_antitank","Boceto anterior · Rompedor"],
        ["infantry_engineer","★ CAMPAMENTO DEFENSIVO · Ingeniero"],
        ["infantry_sniper","★ CAMPAMENTO RECONOCIMIENTO · Francotirador"],
        ["infantry_logistic","★ CAMPAMENTO SUMINISTROS · Logístico a pie"],
        ["infantry_medic","★ CAMPAMENTO MÉDICO · Médico"],
        ["infantry_commando","★ UNIDAD ESPECIAL · Comando FS-24"]
    ]:
        var index:int=P06Models.ROLES.find(str(entry[0]))
        if index>=0:
            role_picker.set_item_text(index,str(entry[1]))
    var ew_index:int=P06Models.ROLES.find("ew_mobile")
    if ew_index>=0:
        role_picker.set_item_text(ew_index,"G15 · Guerra electrónica · V11C FINAL")
    var heli_index: int=P06Models.ROLES.find("attack_heli")
    if heli_index >= 0:
        role_picker.set_item_text(heli_index,"Helicóptero A01 HAT-29 · V14.15")
    var idx: int = P06Models.ROLES.find("apc")
    if idx >= 0:
        role_picker.set_item_text(idx,"Bastión P06 · V25")
    var tank_index: int = P06Models.ROLES.find("tank")
    if tank_index >= 0:
        role_picker.set_item_text(tank_index,"Tanque G09 · V32 FINAL")
    # A review link targets the SAME native Godot Web Studio and selector.
    # Other navigation and all Android/non-Web launches keep P06 as default.
    var launch_role: String=_studio_web_entry_role()
    var launch_index: int=P06Models.ROLES.find(launch_role)
    if launch_index>=0:
        role_picker.select(launch_index)
    _display_role(launch_role)
    _refresh_unified_studio_navigation()

func _studio_role_from_link_key(value:String) -> String:
    # Fixed allowlist: URL text never controls a scene or resource path.
    match value.strip_edges().to_lower():
        "g16", "logistics_mobile", "logistica", "logistica_6x6":
            return "logistics_mobile"
        "a01", "uav_recon", "dron_recon":
            return "uav_recon"
        _:
            return "apc"

func _studio_web_entry_role() -> String:
    if not OS.has_feature("web"):
        return "apc"
    # Only a static expression runs in the browser: no untrusted JS eval.
    var link_key:Variant=JavaScriptBridge.eval(
        "new URLSearchParams(window.location.search).get('unidad') || ''",
        true)
    return _studio_role_from_link_key(str(link_key))

func _install_unified_studio_navigation() -> void:
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    if column==null:
        return
    # One real selector: move existing connected controls, never create
    # parallel selectors that can disagree about the active native model.
    studio_selector_panel=VBoxContainer.new()
    studio_selector_panel.name="Estudio3D_SelectorPrincipal"
    studio_selector_panel.add_theme_constant_override("separation",7)
    column.add_child(studio_selector_panel)
    column.move_child(studio_selector_panel,0)
    studio_quick_title=_title(studio_selector_panel,"TARVOKA · ESTUDIO 3D",18)
    studio_quick_title.add_theme_color_override("font_color",Color("#E7BE70"))
    studio_overview_label=_title(studio_selector_panel,"Selecciona un modelo para inspeccionar.",12)
    studio_overview_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    # Keep the actual role picker parent unchanged. Existing camera,
    # responsive and animation functions depend on its original VBox.
    if category_picker!=null:
        column.move_child(category_picker,1)
    column.move_child(role_picker,2)
    column.move_child(faction_picker,3)
    role_picker.clip_text=true
    role_picker.custom_minimum_size.x=0
    if building_picker!=null:
        building_picker.clip_text=true
    # Compact, predictable sidebar width in Android landscape as well as PC.
    var frame: BoxContainer=model_holder.get_parent() as BoxContainer
    if frame!=null and frame.get_child_count()>1:
        var sidebar: Control=frame.get_child(1) as Control
        if sidebar!=null:
            sidebar.custom_minimum_size.x=306.0

    studio_quick_panel=VBoxContainer.new()
    studio_quick_panel.name="Estudio3D_MenuUnificado"
    studio_quick_panel.add_theme_constant_override("separation",7)
    column.add_child(studio_quick_panel)
    column.move_child(studio_quick_panel,4)
    var tabs:=HBoxContainer.new()
    tabs.add_theme_constant_override("separation",5)
    studio_quick_panel.add_child(tabs)
    studio_tab_animations=_button(tabs,"Animar",func(): _studio_select_tab(0))
    studio_tab_camera=_button(tabs,"Cámara",func(): _studio_select_tab(1))
    studio_tab_technical=_button(tabs,"Detalles",func(): _studio_select_tab(2))
    for button in [studio_tab_animations,studio_tab_camera,studio_tab_technical]:
        button.custom_minimum_size.x=0
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.clip_text=true

    studio_animation_panel=VBoxContainer.new()
    studio_animation_panel.name="Estudio3D_TodasLasAnimaciones"
    studio_animation_panel.add_theme_constant_override("separation",6)
    studio_quick_panel.add_child(studio_animation_panel)
    studio_animation_message=_title(studio_animation_panel,
        "Animaciones disponibles del modelo seleccionado",12)
    studio_animation_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    studio_animation_inventory=VBoxContainer.new()
    studio_animation_inventory.name="CatalogoCompletoDeAnimaciones"
    studio_animation_inventory.add_theme_constant_override("separation",5)
    studio_animation_panel.add_child(studio_animation_inventory)
    studio_camera_panel=VBoxContainer.new()
    studio_camera_panel.add_theme_constant_override("separation",6)
    studio_quick_panel.add_child(studio_camera_panel)
    _add_paired(studio_camera_panel,"↶ 45°",func(): _rotate(-45.0),
        "45° ↷",func(): _rotate(45.0))
    _add_paired(studio_camera_panel,"Alejar",func(): _change_zoom(-1),
        "Acercar",func(): _change_zoom(1))
    _button(studio_camera_panel,"Restablecer cámara",_studio_review_reset_camera)
    g16_360_panel=VBoxContainer.new()
    g16_360_panel.name="G16V6_InspeccionReal360MismoVisor"
    g16_360_panel.add_theme_constant_override("separation",6)
    studio_camera_panel.add_child(g16_360_panel)
    _title(g16_360_panel,"G16 V6 · INSPECCIÓN DE BLINDAJE Y SUMINISTROS",13)
    _add_paired(g16_360_panel,
        "Frente",func(): _g16_review_look(180.0,"general"),
        "Trasera",func(): _g16_review_look(0.0,"general"))
    _add_paired(g16_360_panel,
        "Lateral izquierdo",func(): _g16_review_look(90.0,"general"),
        "Lateral derecho",func(): _g16_review_look(270.0,"general"))
    _add_paired(g16_360_panel,
        "Manguera V6 abierta",func(): _g16_review_look(0.0,"suministros"),
        "Ruedas y bajos",func(): _g16_review_look(0.0,"bajos"))
    _add_paired(g16_360_panel,
        "Giro 360°",_g16_review_spin,
        "Vista completa",func(): _g16_review_look(35.0,"general"))
    g16_360_panel.visible=false
    infantry_six_panel=VBoxContainer.new()
    infantry_six_panel.name="InfanteriaSeisUnidadesAcordadas"
    infantry_six_panel.add_theme_constant_override("separation",6)
    studio_camera_panel.add_child(infantry_six_panel)
    _title(infantry_six_panel,"INFANTERÍA · SEIS UNIDADES DEFINIDAS",13)
    _add_paired(infantry_six_panel,"Guardia básica",
        func(): _display_role("line"),
        "Comando especial",func(): _display_role("infantry_commando"))
    _add_paired(infantry_six_panel,"Francotirador · Recon.",
        func(): _display_role("infantry_sniper"),
        "Ingeniero · Defensa",func(): _display_role("infantry_engineer"))
    _add_paired(infantry_six_panel,"Logístico · Suministros",
        func(): _display_role("infantry_logistic"),
        "Médico · Curación",func(): _display_role("infantry_medic"))
    infantry_six_panel.visible=false
    a01_360_panel=VBoxContainer.new()
    a01_360_panel.name="A01V2_InspeccionFisicaMismoVisor"
    a01_360_panel.add_theme_constant_override("separation",6)
    studio_camera_panel.add_child(a01_360_panel)
    _title(a01_360_panel,"A01 V3 · ALAS, ÓPTICA Y HÉLICE 3D",13)
    _add_paired(a01_360_panel,
        "Frente",func(): _a01_review_look(180.0,"general"),
        "Trasera",func(): _a01_review_look(0.0,"general"))
    _add_paired(a01_360_panel,
        "Lateral",func(): _a01_review_look(90.0,"general"),
        "Superior",func(): _a01_review_look(0.0,"superior"))
    _add_paired(a01_360_panel,
        "Sensor EO/IR · detalle",func(): _a01_review_look(35.0,"optica"),
        "Hélice y cola",func(): _a01_review_look(0.0,"cola"))
    _add_paired(a01_360_panel,"Giro 360°",_a01_review_spin,
        "Vista completa",func(): _a01_review_look(35.0,"general"))
    a01_360_panel.visible=false
    infantry_360_panel=VBoxContainer.new()
    infantry_360_panel.name="InfanteriaV2_InspeccionEnMismoVisor"
    infantry_360_panel.add_theme_constant_override("separation",6)
    studio_camera_panel.add_child(infantry_360_panel)
    _title(infantry_360_panel,"INFANTERÍA · REVISIÓN 360° Y DISTANCIA TÁCTICA",13)
    _add_paired(infantry_360_panel,"Frente",func(): _infantry_review_look(180.0,"frente"),
        "Perfil",func(): _infantry_review_look(90.0,"perfil"))
    _add_paired(infantry_360_panel,"Espalda",func(): _infantry_review_look(0.0,"espalda"),
        "Giro 360°",_infantry_review_spin)
    _add_paired(infantry_360_panel,"Comparar V1",func(): _infantry_review_version(false),
        "Ver V2",func(): _infantry_review_version(true))
    _add_paired(infantry_360_panel,"LOD13 · detalle",func(): _infantry_review_lod(13),
        "LOD8 · vista táctica",func(): _infantry_review_lod(8))
    infantry_360_panel.visible=false

    # Revision comparisons are kept for QA but not shown on the front page.
    studio_versions_fold=VBoxContainer.new()
    studio_versions_fold.name="G09_HistorialComparaciones"
    studio_versions_fold.add_theme_constant_override("separation",5)
    column.add_child(studio_versions_fold)
    studio_versions_button=_button(studio_versions_fold,
        "Historial de versiones G09",_studio_toggle_versions)
    studio_versions_content=VBoxContainer.new()
    studio_versions_content.name="G09_ComparacionAvanzada"
    studio_versions_fold.add_child(studio_versions_content)
    studio_versions_content.visible=false
    # OptionButton extends Button in Godot. NEVER move selectors to this
    # hidden comparison panel: doing so breaks selection and role_picker's
    # parent, which the other studio modules depend on.
    for item in column.get_children():
        if item is Button and not item is OptionButton:
            var caption: String=(item as Button).text
            if caption.begins_with("V") or caption.begins_with("NUEVO") or (
                    caption.begins_with("COMPARAR")) or caption.begins_with(
                    "MODO ARCILLA"):
                (item as Control).reparent(studio_versions_content)
    assert(role_picker.get_parent()==column)
    assert(category_picker.get_parent()==column)
    assert(faction_picker.get_parent()==column)

    studio_advanced_group=VBoxContainer.new()
    studio_advanced_group.name="Estudio3D_DetallesPorUnidad"
    studio_advanced_group.add_theme_constant_override("separation",7)
    column.add_child(studio_advanced_group)
    studio_advanced_button=_button(studio_advanced_group,
        "Inspecciones y pruebas del modelo",_studio_toggle_advanced)
    studio_advanced_content=VBoxContainer.new()
    studio_advanced_content.add_theme_constant_override("separation",7)
    studio_advanced_group.add_child(studio_advanced_content)
    # All specialized unit inspectors now live under the SAME Details tab.
    # This eliminates controls stranded below buildings or base camera tools.
    for section in [p06_controls,g11_controls,g13_controls,heli_controls]:
        if section!=null:
            section.reparent(studio_advanced_content)

    # Original inspector actions remain connected but are available only
    # under Advanced, avoiding duplicate Move/Attack/Camera toolbars.
    studio_legacy_controls=VBoxContainer.new()
    studio_legacy_controls.name="ControlesOriginalesDeInspeccion"
    studio_legacy_controls.add_theme_constant_override("separation",6)
    studio_advanced_content.add_child(studio_legacy_controls)
    var moving: bool=false
    var legacy_to_move: Array[Control]=[]
    for item in column.get_children():
        # Never sweep the category/building tools or model-specific panels.
        if item==detail_label:
            break
        if item is Label:
            var heading: String=str((item as Label).text)
            if heading in ["ROTAR Y ACERCAR","ANIMACION REAL",
                    "V30 · DOS TIPOS DE IMPACTO","CONDICION DEL TANQUE"]:
                moving=true
            elif heading in ["FACCION","MODELO"]:
                moving=false
        if moving and item is Control:
            legacy_to_move.append(item)
    for item in legacy_to_move:
        item.reparent(studio_legacy_controls)
    # Model metadata and faction emblems are optional inspection tools,
    # not permanent chrome below the main animation bar.
    if revision_label!=null:
        revision_label.reparent(studio_advanced_content)
    if detail_label!=null:
        detail_label.reparent(studio_advanced_content)
    if status_label!=null:
        status_label.reparent(studio_quick_panel)
    for item in column.get_children():
        if item is Label and str((item as Label).text)==(
                "VISTAS POR FACCIÓN · 8 ESCUDOS OFICIALES"):
            (item as Label).reparent(studio_advanced_content)
            break
    if faction_view_label!=null:
        faction_view_label.reparent(studio_advanced_content)
    if faction_view_grid!=null:
        faction_view_grid.reparent(studio_advanced_content)
    # Hide repeated introductory text; retain version/status diagnostics.
    for item in column.get_children():
        if item is Label:
            var label_text: String=str((item as Label).text)
            if label_text=="MODELO" or label_text=="FACCION" or label_text.begins_with(
                    "Visor 3D del motor Godot:") or label_text.begins_with(
                    "El mismo modelo de Godot") or label_text=="TARVOKA · ESTUDIO 3D":
                (item as Label).visible=false

    # Keep exactly one Reset Camera command in the Camera tab. The base
    # inspector's second reset button used to appear under Animar.
    for item in column.get_children():
        if item is Button and not item is OptionButton and (
                (item as Button).text=="Restablecer cámara"):
            (item as Button).visible=false
    # Put the original advanced building tools below the compact navigation.
    # They remain fully functional; the selector itself is now at the top.
    column.move_child(studio_versions_fold,5)
    column.move_child(studio_advanced_group,6)
    if building_controls!=null:
        column.move_child(building_controls,7)
    studio_advanced_expanded=false
    _studio_select_tab(0)

func _studio_select_tab(index: int) -> void:
    studio_active_tab=clampi(index,0,2)
    if studio_animation_panel!=null:
        studio_animation_panel.visible=studio_active_tab==0
    if studio_camera_panel!=null:
        studio_camera_panel.visible=studio_active_tab==1
    if studio_advanced_group!=null:
        studio_advanced_group.visible=studio_active_tab==2
    # Open the selected tools directly: the previous extra expansion step
    # made the Details tab appear empty on first use.
    if studio_active_tab==2:
        studio_advanced_expanded=true
        if studio_advanced_button!=null:
            studio_advanced_button.text="Ocultar inspecciones"
    _refresh_unified_studio_navigation()
    for entry in [[studio_tab_animations,0],[studio_tab_camera,1],
            [studio_tab_technical,2]]:
        var button: Button=entry[0] as Button
        if button!=null:
            button.disabled=int(entry[1])==studio_active_tab

func _studio_toggle_advanced() -> void:
    studio_advanced_expanded=not studio_advanced_expanded
    studio_advanced_content.visible=studio_advanced_expanded
    studio_advanced_button.text=("Ocultar inspecciones" if studio_advanced_expanded
        else "Inspecciones y pruebas del modelo")
    _refresh_unified_studio_navigation()

func _studio_toggle_versions() -> void:
    studio_versions_expanded=not studio_versions_expanded
    studio_versions_content.visible=studio_versions_expanded
    studio_versions_button.text=("Ocultar versiones anteriores" if studio_versions_expanded
        else "Mostrar versiones anteriores del tanque")

func _studio_jump_category(index: int) -> void:
    if category_picker==null:
        return
    _switch_category(index)
    _refresh_unified_studio_navigation()

func _studio_jump_details() -> void:
    if detail_label==null:
        return
    var column: VBoxContainer=studio_quick_panel.get_parent() as VBoxContainer
    if column==null:
        return
    var scroll: ScrollContainer=column.get_parent() as ScrollContainer
    if scroll!=null:
        scroll.ensure_control_visible(detail_label)

# Complete role-specific previews: only animations and conditions actually
# supported by the current native rig. Camera angles, LOD, material audits
# and former revision buttons stay available on the separate Details tab.
func _studio_animation_specs(role: String) -> Array[Dictionary]:
    if InfantryV1.supports(role):
        var actions: Array[Dictionary] = [
            {"group":"INFANTERÍA V2 · MOVIMIENTO Y POSTURAS"},
            {"title":"Marcha con equipo","action":"move"},
            {"title":"Orientar y apuntar","action":"aim"}
        ]
        if role in ["infantry_engineer","infantry_logistic","infantry_medic"]:
            var task_name:String="Trabajo y herramientas"
            if role=="infantry_logistic":
                task_name="Organizar suministros (animación)"
            elif role=="infantry_medic":
                task_name="Asistencia médica (animación)"
            actions.append({"title":task_name,"action":"work"})
            if role=="infantry_engineer":
                actions.append_array([
                    {"group":"INGENIERO V6 · HERRAJES Y 360° · SOLO ARTE"},
                    {"title":"V6 · Girar bisagra y abrir barrera plegada (inspección)","action":"engineer_v6_inspect"},
                    {"title":"V6 · Plegar barrera y guardar equipo","action":"engineer_v6_pack"}
                ])
        else:
            actions.append({"title":"Ataque · retroceso de arma","action":"attack"})
        actions.append_array([
            {"title":"Captura · postura","action":"capture"},
            {"group":"DAÑOS VISUALES · NO ALTERAN HP"},
            {"title":"Reaccionar a un impacto","action":"hit_bullet"},
            {"title":"Daño ligero D1","action":"damage_1"},
            {"title":"Daño medio D2","action":"damage_2"},
            {"title":"Daño grave D3","action":"damage_3"},
            {"title":"Caída / destrucción D4","action":"damage_4"},
            {"title":"Restaurar D0","action":"damage_0"},
            {"title":"Detener y restablecer pose","action":"stop"}
        ])
        return actions
    match role:
        "uav_recon":
            return [
                {"group":"A01 V2 · DRON DE RECONOCIMIENTO SIN ARMAMENTO"},
                {"title":"Volar · hélice impulsora", "action":"a01_move"},
                {"title":"Explorar · girar cámara óptica", "action":"a01_scan"},
                {"title":"Simular impacto visual", "action":"a01_hit"},
                {"title":"Detener y restaurar", "action":"stop"}
            ]
        "tank":
            return [
                {"group":"G09 V32 · MOVIMIENTO Y COMBATE"},
                {"title":"Orugas y suspensión","action":"move"},
                {"title":"Apuntar, cañón y disparar","action":"attack"},
                {"group":"IMPACTOS · ANIMACIONES INDEPENDIENTES"},
                {"title":"Reacción general","action":"damaged"},
                {"title":"Impacto de bala V30","action":"hit_bullet"},
                {"title":"Explosión V30","action":"hit_explosion"},
                {"group":"ESTADOS VISUALES DE DAÑO"},
                {"title":"Impactos leves","action":"damage_1"},
                {"title":"Blindaje dañado","action":"damage_2"},
                {"title":"Daño crítico","action":"damage_3"},
                {"title":"Destrucción","action":"damage_4"},
                {"title":"Reparar por completo","action":"damage_0"},
                {"group":"REVISAR MODELO APROBADO"},
                {"title":"G09 V32 · Visor final separado","action":"tank_standalone"},
                {"title":"Detener animación","action":"stop"}
            ]
        "apc":
            return [
                {"group":"BASTIÓN P06 V25 · MOVIMIENTO Y ARMAMENTO"},
                {"title":"Movimiento 6×6","action":"move"},
                {"title":"Giro y dirección 6×6","action":"move_turn"},
                {"title":"Orientar torreta","action":"turn_turret"},
                {"title":"Ráfaga de ametralladora","action":"attack"},
                {"group":"INTERIOR Y SISTEMAS MÓVILES"},
                {"title":"Abrir rampa","action":"open_ramp"},
                {"title":"Cerrar rampa","action":"close_ramp"},
                {"group":"IMPACTOS Y ESTADOS"},
                {"title":"Impacto de balas","action":"hit_bullet"},
                {"title":"Impacto explosivo","action":"hit_explosive"},
                {"title":"Daño leve","action":"damage_1"},
                {"title":"Daño moderado","action":"damage_2"},
                {"title":"Daño crítico","action":"damage_3"},
                {"title":"Destrucción","action":"damage_4"},
                {"title":"Restaurar blindaje","action":"damage_0"},
                {"group":"SIMULACIÓN DE GRUPO"},
                {"title":"8 vehículos · marcha","action":"p06_fleet_move"},
                {"title":"8 vehículos · ráfagas","action":"p06_fleet_attack"},
                {"title":"Volver a un Bastión","action":"p06_fleet_close"},
                {"title":"Detener animación","action":"stop"}
            ]
        "mlrs":
            return [
                {"group":"LANZADOR G11 V33 · ANIMACIONES"},
                {"title":"Orugas y marcha","action":"move"},
                {"title":"Salva de cohetes","action":"attack"},
                {"title":"Salva a velocidad 0.35×","action":"g11_attack_slow"},
                {"title":"Enfriar y retraer","action":"cooldown"},
                {"title":"Giro sobre oruga izquierda","action":"g11_turn_left"},
                {"title":"Giro sobre oruga derecha","action":"g11_turn_right"},
                {"title":"Suspensión en desnivel","action":"g11_slope"},
                {"group":"IMPACTOS Y DAÑOS"},
                {"title":"Impactos de balas","action":"hit_bullet"},
                {"title":"Explosión y sacudida","action":"hit_explosive"},
                {"title":"Daño leve","action":"damage_1"},
                {"title":"Daño moderado","action":"damage_2"},
                {"title":"Daño crítico","action":"damage_3"},
                {"title":"Destrucción","action":"damage_4"},
                {"title":"Reparación completa","action":"damage_0"},
                {"group":"SIMULACIÓN DE BATALLA V29–V32"},
                {"title":"Mover en escenario","action":"g11_battle_move"},
                {"title":"Salva con humo y cohetes","action":"g11_battle_attack"},
                {"title":"Cerrar escenario de prueba","action":"g11_battle_close"},
                {"title":"Detener animación","action":"stop"}
            ]
        "logistics_mobile":
            return [
                {"group":"G16 V6 · SUMINISTROS MECÁNICOS ARTICULADOS"},
                {"title":"V6 · Mostrar manguera, conector y tapa blindada","action":"g16_v6_on"},
                {"title":"V5 · Comparar sin hardware de servicio V6","action":"g16_v6_off"},
                {"title":"V6 · Desplegar manguera para reabastecimiento visual","action":"g16_v6_connect"},
                {"group":"G16 V5 · MATERIALES PBR, CRISTALES Y DESGASTE"},
                {"title":"V5 · Mostrar metales, brillo, sellos y desgaste físico","action":"g16_v5_on"},
                {"title":"V4 · Comparar carrocería sin el acabado PBR V5","action":"g16_v5_off"},
                {"group":"G16 V4 · ESCULTURA 360°, FACCIÓN Y DESTRUCCIÓN"},
                {"title":"V4 · Mostrar blindaje biselado, faros y detalles premium","action":"g16_v4_on"},
                {"title":"V3 · Comparar sin acabados V4","action":"g16_v4_off"},
                {"title":"V4 · Destrucción progresiva animada","action":"g16_v4_wreck"},
                {"title":"V4 · Reparar carrocería visualmente","action":"g16_damage_0"},
                {"group":"G16 V3 · MECÁNICA, CARGA Y DAÑOS 3D"},
                {"title":"V3 · Mostrar suspensión, tuberías y tapas articuladas","action":"g16_v3_on"},
                {"title":"V2 · Comparar sin mecánica ni detalles V3","action":"g16_v3_off"},
                {"title":"V3 · Estado intacto","action":"g16_damage_0"},
                {"title":"V3 · Abolladuras y rayones","action":"g16_damage_1"},
                {"title":"V3 · Carrocería y cristales dañados","action":"g16_damage_2"},
                {"title":"V3 · Carga y depósitos deteriorados","action":"g16_damage_3"},
                {"title":"V3 · Destrucción visual","action":"g16_damage_4"},
                {"group":"G16 V2 · CABINA PBR, LLANTAS Y GRÚA HIDRÁULICA"},
                {"title":"V2 · Mostrar blindaje, llantas y pistón 3D","action":"g16_v2_on"},
                {"title":"V1 · Comparar sin los acabados V2","action":"g16_v2_off"},
                {"group":"G16 V1 · SUMINISTROS Y DESPLIEGUE (VISUAL)"},
                {"title":"Conducir el camión 6×6","action":"g16_move"},
                {"title":"Desplegar rampa, toldo y estabilizadores","action":"g16_deploy"},
                {"title":"Descargar caja con la grúa","action":"g16_unload"},
                {"title":"Simular abastecimiento de combustible y munición","action":"g16_resupply"},
                {"title":"Desplegar campamento temporal","action":"g16_camp"},
                {"title":"Replegar completamente el equipo","action":"g16_pack"},
                {"title":"Reacción visual de impacto","action":"g16_hit"},
                {"title":"Detener y restaurar la carga","action":"stop"}
            ]
        "ew_mobile":
            return [
                {"group":"G15 V11C · IDENTIDAD DE FACCIÓN FINAL"},
                {"title":"V11C · Color de facción reforzado y blindaje cerrado","action":"g15_v11_on"},
                {"title":"V10 · Comparar sin los nuevos detalles","action":"g15_v11_off"},
                {"group":"G15 V10 · CRISTALES CURVOS Y SERVICIO ELECTRÓNICO"},
                {"title":"V10 · Cristales PBR curvos y acabados posteriores","action":"g15_v10_on"},
                {"title":"V9 · Comparar cristales anteriores","action":"g15_v10_off"},
                {"group":"G15 V9 · SUPERFICIES PBR Y CAUCHO"},
                {"title":"V9 · Acero satinado y neumáticos labrados","action":"g15_v9_on"},
                {"title":"V8 · Comparar acabado anterior","action":"g15_v9_off"},
                {"group":"G15 V8 · BLINDAJE CONTINUO Y SUSPENSIÓN"},
                {"title":"V8 · Transición de acero y resortes 6×6","action":"g15_v8_on"},
                {"title":"V7 · Comparar carrocería y suspensión","action":"g15_v8_off"},
                {"group":"G15 V7 · MECÁNICA Y UNIONES DE BLINDAJE"},
                {"title":"V7 · Ejes, bajos y juntas mecánicas","action":"g15_v7_on"},
                {"title":"V6 · Comparar sin detalles mecánicos","action":"g15_v7_off"},
                {"group":"G15 V6 · BLINDAJE Y CRISTALES"},
                {"title":"V6 · Acabados exteriores PBR","action":"g15_v6_on"},
                {"title":"V5 · Comparar carrocería anterior","action":"g15_v6_off"},
                {"group":"G15 V5 · ACABADOS DE ANTENA Y DESTRUCCIÓN"},
                {"title":"V5 · Acabados, juntas y pernos reales","action":"g15_v5_on"},
                {"title":"V4 · Comparar acabados anteriores","action":"g15_v5_off"},
                {"title":"V5 · Antena intacta","action":"g15_damage_0"},
                {"title":"V5 · Daño leve en los paneles","action":"g15_damage_1"},
                {"title":"V5 · Daño moderado en antena","action":"g15_damage_2"},
                {"title":"V5 · Antena parcialmente fracturada","action":"g15_damage_3"},
                {"title":"V5 · Destrucción visual del conjunto","action":"g15_damage_4"},
                {"group":"G15 V4 · ANTENAS ARTICULADAS Y MECÁNICA REAL"},
                {"title":"V4 · Matrices electrónicas, mástil hidráulico","action":"g15_v4_on"},
                {"title":"V3 · Comparar antenas simples anteriores","action":"g15_v4_off"},
                {"group":"G15 V3 · CABINA Y REFUGIO 3D"},
                {"title":"V3 · Cabina y refugio blindados biselados","action":"g15_v3_on"},
                {"title":"V2 · Comparar con refugio rectangular","action":"g15_v3_off"},
                {"title":"V1 · Comparar con guardabarros originales","action":"g15_v2_off"},
                {"title":"V10 · Restaurar última versión","action":"g15_v2_on"},
                {"title":"Movimiento 6×6, antena plegada","action":"move"},
                {"title":"Desplegar mástil articulado","action":"deploy"},
                {"title":"Barrido direccional","action":"scan"},
                {"title":"Interferencia · efecto visual","action":"jam"},
                {"title":"Sacudida por impacto","action":"damage"},
                {"title":"Detener y restaurar","action":"stop"}
            ]
        "aa_mobile":
            return [
                {"group":"G13 · MOVIMIENTO, RADAR Y APUNTADO"},
                {"title":"Rodaje 4×4","action":"move"},
                {"title":"Barrido del radar","action":"g13_scan"},
                {"title":"Apuntado de barrido V1","action":"g13_aim_legacy"},
                {"title":"Apuntar a objetivo aéreo","action":"g13_aim_air"},
                {"title":"Apuntar a objetivo terrestre","action":"g13_aim_ground"},
                {"group":"G13 V4 · DOS DISPAROS VISUALES"},
                {"title":"Ráfaga antiaérea","action":"g13_attack_air"},
                {"title":"Ráfaga terrestre","action":"g13_attack_ground"},
                {"title":"Restaurar radar y cañones","action":"stop"}
            ]
        "attack_heli":
            return [
                {"group":"HELICÓPTERO HAT-29 V14.2 · VUELO Y ARMAMENTO"},
                {"title":"Vuelo y rotores en marcha","action":"move"},
                {"title":"Mantener posición / hover","action":"hover"},
                {"title":"Ráfaga de cañón frontal","action":"attack"},
                {"title":"Lanzamiento de dos misiles","action":"fire_missiles"},
                {"group":"IMPACTOS DE BALAS Y MISILES · V14"},
                {"title":"Impactos múltiples de balas / chispas","action":"hit_bullet"},
                {"title":"Impactos de balas · cámara lenta","action":"heli_bullet_slow"},
                {"title":"Impacto de misil / doble explosión","action":"hit_explosive"},
                {"title":"Impacto de misil · cámara lenta","action":"heli_missile_slow"},
                {"group":"DAÑOS ACUMULATIVOS, DESTRUCCIÓN Y REPARACIÓN"},
                {"title":"Aeronave intacta / reparar","action":"damage_0"},
                {"title":"Daño leve · perforaciones","action":"damage_1"},
                {"title":"Daño moderado · humo activo","action":"damage_2"},
                {"title":"Daño crítico · incendio activo","action":"damage_3"},
                {"title":"Destrucción · choque y rotor desprendido","action":"damage_4"},
                {"title":"Destrucción · cámara lenta","action":"heli_destroy_slow"},
                {"title":"Detener / conservar estado","action":"stop"}
            ]
    return []

func _studio_rebuild_animation_catalog() -> void:
    if studio_animation_inventory==null:
        return
    var building: bool=category_picker!=null and category_picker.selected==1
    var key: String="building" if building else _role
    if studio_animation_role==key:
        return
    studio_animation_role=key
    studio_animation_rebuild_count+=1
    for node in studio_animation_inventory.get_children():
        studio_animation_inventory.remove_child(node)
        node.queue_free()
    if building:
        studio_animation_message.text="Los edificios tienen inspección y niveles, no animaciones de unidades."
        return
    var specs: Array[Dictionary]=_studio_animation_specs(_role)
    if specs.is_empty():
        studio_animation_message.text=(
            "Este modelo aún no dispone de un rig de animaciones propio. "
            + "Puedes inspeccionarlo desde la pestaña Cámara.")
        return
    studio_animation_message.text="%d opciones disponibles · %s" % [
        specs.filter(func(item: Dictionary)->bool: return item.has("action")).size(),
        studio_overview_label.text]
    # One full-width row per unique animation: pairs clipped the labels
    # on a 306 px Android sidebar and made several actions look absent.
    for spec in specs:
        if spec.has("group"):
            var heading: Label=_title(studio_animation_inventory,
                str(spec["group"]),11)
            heading.add_theme_color_override("font_color",Color("#E7BE70"))
            heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
            continue
        var title: String=str(spec["title"])
        var action: String=str(spec["action"])
        var button: Button=_button(studio_animation_inventory,title,
            Callable(self,"_studio_run_animation").bind(action))
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        button.custom_minimum_size.x=0
        button.custom_minimum_size.y=42
        button.clip_text=true
        button.tooltip_text=title

func _studio_run_animation(action: String) -> void:
    if model_root==null or category_picker==null or category_picker.selected!=0:
        return
    if not _studio_animation_specs(_role).any(
            func(entry: Dictionary)->bool: return str(entry.get("action",""))==action):
        return
    match action:
        "stop":
            _studio_quick_stop()
        "a01_move","a01_scan","a01_hit":
            if _role=="uav_recon":
                _a01_play(action.trim_prefix("a01_"))
        "engineer_v6_inspect","engineer_v6_pack":
            if _role=="infantry_engineer":
                _engineer_v6_run(action=="engineer_v6_inspect")
        "heli_bullet_slow":
            if _role=="attack_heli":
                _heli_play("hit_bullet",0.42)
        "heli_missile_slow":
            if _role=="attack_heli":
                _heli_play("hit_explosive",0.42)
        "heli_destroy_slow":
            if _role=="attack_heli":
                _heli_destroy(0.43)
        "g16_v6_on","g16_v6_off":
            if _role=="logistics_mobile" and model_root!=null and G16ServiceV6.has_model(model_root):
                var enabled:bool=action=="g16_v6_on"
                if enabled:
                    G16ExteriorV2.show_finish(model_root,true)
                    G16MechanicsV3.show_finish(model_root,true)
                    G16SculptV4.show_finish(model_root,true)
                    G16MaterialsV5.show_finish(model_root,true)
                if G16ServiceV6.show_finish(model_root,enabled):
                    status_label.text=("G16 V6 · manguera, conector y tapa metálica visibles" if enabled else "G16 V5 · comparación sin hardware de abastecimiento V6")
        "g16_v6_connect":
            if _role=="logistics_mobile" and model_root!=null and G16ServiceV6.has_model(model_root):
                G16ServiceV6.show_finish(model_root,true)
                _g16_play("resupply")
        "g16_v5_on","g16_v5_off":
            if _role=="logistics_mobile" and model_root!=null and G16MaterialsV5.has_model(model_root):
                var latest:bool=action=="g16_v5_on"
                if latest:
                    G16ExteriorV2.show_finish(model_root,true)
                    G16MechanicsV3.show_finish(model_root,true)
                    G16SculptV4.show_finish(model_root,true)
                if not latest and G16ServiceV6.has_model(model_root):
                    G16ServiceV6.show_finish(model_root,false)
                if G16MaterialsV5.show_finish(model_root,latest):
                    if latest and G16ServiceV6.has_model(model_root):
                        G16ServiceV6.show_finish(model_root,true)
                    status_label.text=("G16 V6 · vidrio PBR opaco y hardware restaurados" if latest else "G16 V4 · comparación sin acabado V5/V6")
        "g16_v4_on","g16_v4_off":
            if _role=="logistics_mobile" and model_root!=null and G16SculptV4.has_model(model_root):
                var on:bool=action=="g16_v4_on"
                if not on and G16ServiceV6.has_model(model_root):
                    G16ServiceV6.show_finish(model_root,false)
                if not on and G16MaterialsV5.has_model(model_root):
                    G16MaterialsV5.show_finish(model_root,false)
                if on:
                    G16ExteriorV2.show_finish(model_root,true)
                    G16MechanicsV3.show_finish(model_root,true)
                if G16SculptV4.show_finish(model_root,on):
                    if on and G16MaterialsV5.has_model(model_root):
                        G16MaterialsV5.show_finish(model_root,true)
                    if on and G16ServiceV6.has_model(model_root):
                        G16ServiceV6.show_finish(model_root,true)
                    status_label.text=("G16 V5 · carrocería, cristales y materiales restaurados" if on else "G16 V3 · comparación sin acabados V4/V5")
        "g16_v4_wreck":
            if _role=="logistics_mobile" and model_root!=null and G16SculptV4.has_model(model_root):
                _g16_v4_destroy()
        "g16_damage_0","g16_damage_1","g16_damage_2","g16_damage_3","g16_damage_4":
            if _role=="logistics_mobile" and model_root!=null and G16MechanicsV3.has_model(model_root):
                if _g16_tween!=null and _g16_tween.is_running():
                    _g16_tween.kill()
                P06Models.restore_model_pose("logistics_mobile",model_root)
                G16ExteriorV2.show_finish(model_root,true)
                G16MechanicsV3.show_finish(model_root,true)
                var damage_level:int=int(action.trim_prefix("g16_damage_"))
                if G16MaterialsV5.has_model(model_root):
                    G16SculptV4.show_finish(model_root,true)
                    G16MaterialsV5.show_finish(model_root,true)
                    if G16MaterialsV5.set_damage(model_root,damage_level):
                        status_label.text="G16 V5 · daño visual %d/4 · metal, vidrio y calor; sin alterar HP" % damage_level
                elif G16SculptV4.has_model(model_root):
                    G16SculptV4.show_finish(model_root,true)
                    if G16SculptV4.set_damage(model_root,damage_level):
                        status_label.text="G16 V4 · daños físicos %d/4 · sin alterar HP ni logística" % damage_level
                elif G16MechanicsV3.set_damage(model_root,damage_level):
                    status_label.text="G16 V3 · daño visual %d/4 · sin afectar suministros, combate ni HP" % damage_level
        "g16_v3_on","g16_v3_off":
            if _role=="logistics_mobile" and model_root!=null:
                var show_v3:bool=action=="g16_v3_on"
                if show_v3:
                    G16ExteriorV2.show_finish(model_root,true)
                if not show_v3:
                    if G16ServiceV6.has_model(model_root):
                        G16ServiceV6.show_finish(model_root,false)
                    if G16MaterialsV5.has_model(model_root):
                        G16MaterialsV5.show_finish(model_root,false)
                    G16SculptV4.show_finish(model_root,false)
                if G16MechanicsV3.show_finish(model_root,show_v3):
                    if show_v3:
                        G16SculptV4.show_finish(model_root,true)
                        if G16MaterialsV5.has_model(model_root):
                            G16MaterialsV5.show_finish(model_root,true)
                        if G16ServiceV6.has_model(model_root):
                            G16ServiceV6.show_finish(model_root,true)
                    status_label.text=("G16 V6 · carrocería y seis suspensiones restauradas" if show_v3 else "G16 V2 · comparación de acabados anteriores")
        "g16_v2_on","g16_v2_off":
            if _role=="logistics_mobile" and model_root!=null:
                var finish_on:bool=action=="g16_v2_on"
                if not finish_on:
                    if G16ServiceV6.has_model(model_root):
                        G16ServiceV6.show_finish(model_root,false)
                    if G16MaterialsV5.has_model(model_root):
                        G16MaterialsV5.show_finish(model_root,false)
                    G16SculptV4.show_finish(model_root,false)
                    G16MechanicsV3.show_finish(model_root,false)
                if G16ExteriorV2.show_finish(model_root,finish_on):
                    if finish_on:
                        G16MechanicsV3.show_finish(model_root,true)
                        G16SculptV4.show_finish(model_root,true)
                        if G16MaterialsV5.has_model(model_root):
                            G16MaterialsV5.show_finish(model_root,true)
                        if G16ServiceV6.has_model(model_root):
                            G16ServiceV6.show_finish(model_root,true)
                    status_label.text=("G16 V6 · materiales, blindaje y mecánica restaurados" if finish_on else "G16 V1 · comparación sin acabados V2/V3/V4/V5")
        "g16_move","g16_deploy","g16_unload","g16_resupply","g16_camp","g16_pack","g16_hit":
            _g16_play(action.trim_prefix("g16_"))
        "g15_v11_on","g15_v11_off":
            if _role=="ew_mobile" and model_root!=null:
                var latest:bool=action=="g15_v11_on"
                if latest:
                    G15OpticalV10.show_finish(model_root,true)
                if G15DetailV11.show_finish(model_root,latest):
                    status_label.text=("G15 V11C · 14 placas de facción y 13 cierres sólidos" if latest else "G15 V10 · comparación sin acabado V11")
        "g15_v10_on","g15_v10_off":
            if _role=="ew_mobile" and model_root!=null and G15OpticalV10.show_finish(model_root,action=="g15_v10_on"):
                status_label.text=("G15 V11C · identidad de facción y carrocería restauradas" if action=="g15_v10_on" else "G15 V9 · cristales de comparación")
        "g15_v9_on","g15_v9_off":
            if _role=="ew_mobile" and model_root!=null:
                var v9_active:bool=action=="g15_v9_on"
                if not v9_active:
                    G15OpticalV10.show_finish(model_root,false)
                if G15SurfaceV9.show_finish(model_root,v9_active):
                    if v9_active:
                        G15OpticalV10.show_finish(model_root,true)
                    status_label.text=("G15 V9 · acero PBR, caucho y llantas mecanizadas" if action=="g15_v9_on" else "G15 V8 · acabados anteriores")
        "g15_v8_on","g15_v8_off":
            if _role=="ew_mobile" and model_root!=null:
                var v8_active:bool=action=="g15_v8_on"
                if v8_active:
                    G15ExteriorV6.show_finish(model_root,true)
                    G15MechanicalV7.show_finish(model_root,true)
                if not v8_active:
                    G15OpticalV10.show_finish(model_root,false)
                    G15SurfaceV9.show_finish(model_root,false)
                if G15ContinuityV8.show_finish(model_root,v8_active):
                    if v8_active:
                        G15SurfaceV9.show_finish(model_root,true)
                        G15OpticalV10.show_finish(model_root,true)
                    status_label.text=("G15 V8 · acero continuo, biseles y seis muelles" if v8_active else "G15 V7 · comparativa sin refinamiento continuo")
        "g15_v7_on","g15_v7_off":
            if _role=="ew_mobile" and model_root!=null:
                var v7_active:bool=action=="g15_v7_on"
                if not v7_active:
                    G15OpticalV10.show_finish(model_root,false)
                    G15SurfaceV9.show_finish(model_root,false)
                    G15ContinuityV8.show_finish(model_root,false)
                if G15MechanicalV7.show_finish(model_root,v7_active):
                    if v7_active:
                        G15ContinuityV8.show_finish(model_root,true)
                        G15SurfaceV9.show_finish(model_root,true)
                        G15OpticalV10.show_finish(model_root,true)
                    status_label.text=("G15 V8 · ejes, bajos, resortes y uniones" if v7_active else "G15 V6 · comparación sin detalles mecánicos")
        "g15_v6_on","g15_v6_off":
            if _role=="ew_mobile" and model_root!=null:
                var current_v6:bool=action=="g15_v6_on"
                if not current_v6:
                    G15OpticalV10.show_finish(model_root,false)
                    G15SurfaceV9.show_finish(model_root,false)
                    G15ContinuityV8.show_finish(model_root,false)
                    G15MechanicalV7.show_finish(model_root,false)
                if G15ExteriorV6.show_finish(model_root,current_v6):
                    if current_v6:
                        G15MechanicalV7.show_finish(model_root,true)
                        G15ContinuityV8.show_finish(model_root,true)
                        G15SurfaceV9.show_finish(model_root,true)
                        G15OpticalV10.show_finish(model_root,true)
                    status_label.text=("G15 V7 · carrocería, acero y uniones" if current_v6 else "G15 V5 · comparación anterior")
        "g15_v5_on","g15_v5_off":
            if _role=="ew_mobile" and model_root!=null:
                var current_v5:bool=action=="g15_v5_on"
                if current_v5:
                    G15AntennaV4.show_finish(model_root,true)
                if G15FinishV5.show_finish(model_root,current_v5):
                    status_label.text=(
                        "G15 V5: pernos, juntas, cableado protegido y acabados físicos"
                        if current_v5 else "G15 V4: comparación sin microdetalles")
        "g15_damage_0","g15_damage_1","g15_damage_2","g15_damage_3","g15_damage_4":
            if _role=="ew_mobile" and model_root!=null:
                if _g15_tween!=null and _g15_tween.is_running():
                    _g15_tween.kill()
                G15AntennaV4.show_finish(model_root,true)
                G15FinishV5.show_finish(model_root,true)
                P06Models.restore_model_pose("ew_mobile",model_root)
                var stage_g15:int=int(action.get_slice("_",2))
                if G15FinishV5.set_damage(model_root,stage_g15):
                    status_label.text="G15 V5 · daño visual %d/4 · sin efectos de combate" % stage_g15
        "g15_v4_on","g15_v4_off":
            if _role=="ew_mobile" and model_root!=null:
                var v4_active:bool=action=="g15_v4_on"
                if not v4_active:
                    G15FinishV5.show_finish(model_root,false)
                if G15AntennaV4.show_finish(model_root,v4_active):
                    if v4_active:
                        G15FinishV5.show_finish(model_root,true)
                    status_label.text=(
                        "G15 V5: matrices inclinadas, pistones, juntas y carcasa real"
                        if v4_active else "G15 V3: comparación con las antenas originales")
        "g15_v3_on","g15_v3_off":
            if _role=="ew_mobile" and model_root!=null:
                var show_v3:bool=action=="g15_v3_on"
                if not show_v3:
                    G15OpticalV10.show_finish(model_root,false)
                    G15SurfaceV9.show_finish(model_root,false)
                    G15ContinuityV8.show_finish(model_root,false)
                    G15MechanicalV7.show_finish(model_root,false)
                    G15ExteriorV6.show_finish(model_root,false)
                    G15FinishV5.show_finish(model_root,false)
                    G15AntennaV4.show_finish(model_root,false)
                if G15FinishV3.show_finish(model_root,show_v3):
                    if show_v3:
                        G15AntennaV4.show_finish(model_root,true)
                        G15FinishV5.show_finish(model_root,true)
                        G15ExteriorV6.show_finish(model_root,true)
                        G15MechanicalV7.show_finish(model_root,true)
                        G15ContinuityV8.show_finish(model_root,true)
                        G15SurfaceV9.show_finish(model_root,true)
                        G15OpticalV10.show_finish(model_root,true)
                    status_label.text=(
                        "G15 V4: blindaje biselado y conjunto electrónico mejorado"
                        if show_v3 else
                        "G15 V2: comparación de la carcasa rectangular anterior")
        "g15_v2_on","g15_v2_off":
            if _role=="ew_mobile" and model_root!=null:
                var show_current:bool=action=="g15_v2_on"
                if not show_current:
                    G15OpticalV10.show_finish(model_root,false)
                    G15SurfaceV9.show_finish(model_root,false)
                    G15ContinuityV8.show_finish(model_root,false)
                    G15MechanicalV7.show_finish(model_root,false)
                    G15ExteriorV6.show_finish(model_root,false)
                    G15FinishV5.show_finish(model_root,false)
                    G15AntennaV4.show_finish(model_root,false)
                    G15FinishV3.show_finish(model_root,false)
                if G15SculptV2.show_finish(model_root,show_current):
                    if show_current:
                        G15FinishV3.show_finish(model_root,true)
                        G15AntennaV4.show_finish(model_root,true)
                        G15FinishV5.show_finish(model_root,true)
                        G15ExteriorV6.show_finish(model_root,true)
                        G15MechanicalV7.show_finish(model_root,true)
                        G15ContinuityV8.show_finish(model_root,true)
                        G15SurfaceV9.show_finish(model_root,true)
                        G15OpticalV10.show_finish(model_root,true)
                    status_label.text=(
                        "G15 V4: superficies biseladas, pasos curvos y antenas físicas"
                        if show_current else
                        "G15 V1: comparación histórica del vehículo original")
        "tank_standalone":
            OS.shell_open("https://edwinrodri12.github.io/Tarvoka/tanque/")
        "damage_0","damage_1","damage_2","damage_3","damage_4":
            var selected_stage: int=int(action.get_slice("_",1))
            if InfantryV1.supports(_role):
                if InfantryV1.set_damage(model_root,selected_stage):
                    if selected_stage==4:
                        P06Models.pose_model(_role,model_root,"idle",1.0)
                    else:
                        P06Models.pose_model(_role,model_root,"idle",0.0)
                    status_label.text="Infantería · daños D%d · solo arte 3D" % selected_stage
            elif _role=="attack_heli":
                _heli_select_damage(selected_stage)
            else:
                _set_damage(selected_stage)
        "p06_fleet_move","p06_fleet_attack":
            if _role=="apc":
                _show_p06_fleet(8)
                _animate_p06_fleet(
                    "move_turn" if action=="p06_fleet_move" else "attack")
        "p06_fleet_close":
            if _role=="apc":
                _hide_p06_fleet()
        "g11_attack_slow":
            _g11_play("attack",0.35)
        "g11_turn_left":
            _studio_g11_animated_turn(-1)
        "g11_turn_right":
            _studio_g11_animated_turn(1)
        "g11_slope":
            if _g11_context_v25==null:
                _g11_battle_context_v25("temperate")
            _g11_battle_gear_v32("slope")
        "g11_battle_move","g11_battle_attack":
            if _g11_context_v25==null:
                _g11_battle_context_v25("temperate")
            _g11_battle_action_v29(
                "move" if action=="g11_battle_move" else "attack")
        "g11_battle_close":
            _g11_close_context_v25()
        "g13_scan","g13_aim_air","g13_aim_ground","g13_aim_legacy":
            var pose_kind: String=(
                "scan" if action=="g13_scan" else
                "aim" if action=="g13_aim_legacy" else
                "aim_air" if action=="g13_aim_air" else "aim_ground")
            _studio_g13_animated_pose(pose_kind)
        "g13_attack_air","g13_attack_ground":
            _g13_attack_v4(
                "attack_air" if action=="g13_attack_air" else "attack_ground")
        _:
            _studio_quick_action(action)

func _studio_g13_animated_pose(kind: String) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if kind not in ["move","scan","aim","aim_air","aim_ground"]:
        return
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    var art: Node3D=model_root
    P06Models.restore_model_pose("aa_mobile",art)
    _g13_v4_tick(0.01,art,kind)
    _g13_v4_tween=art.create_tween()
    _g13_v4_tween.tween_method(
        Callable(self,"_g13_v4_tick").bind(art,kind),0.01,0.99,
        1.75 if kind=="scan" else 1.25)
    _g13_v4_tween.tween_callback(Callable(self,"_g13_v4_done").bind(art))
    status_label.text="G13 · "+kind.replace("_"," ")+" · animación completa"

func _studio_g11_animated_turn(direction: int) -> void:
    if _role!="mlrs" or model_root==null or not G11Rig.has_rig(model_root):
        return
    if _g11_turn_tween!=null and _g11_turn_tween.is_running():
        _g11_turn_tween.kill()
    _g11_animation=""
    var art: Node3D=model_root
    var heading:=Vector2i(-1 if direction<0 else 1,-1)
    G11Rig.pose(art,"move",0.01,heading)
    _g11_turn_tween=art.create_tween()
    _g11_turn_tween.tween_method(
        Callable(self,"_studio_g11_turn_tick").bind(art,heading),0.01,0.99,1.20)
    _g11_turn_tween.tween_callback(
        Callable(self,"_studio_g11_turn_done").bind(art))
    status_label.text="G11 V32 · giro diferencial de orugas en reproducción"

func _studio_g11_turn_tick(t: float,art: Node3D,heading: Vector2i) -> void:
    if is_instance_valid(art):
        G11Rig.pose(art,"move",t,heading)

func _studio_g11_turn_done(art: Node3D) -> void:
    if is_instance_valid(art):
        G11Rig.restore(art)

# Reset the original Godot camera AND any specialized G16 close-up.
# Otherwise the shared "Restablecer cámara" button did not exit hose view.
func _studio_review_reset_camera() -> void:
    if _g16_review_tween!=null and _g16_review_tween.is_running():
        _g16_review_tween.kill()
    if _a01_review_tween!=null and _a01_review_tween.is_running():
        _a01_review_tween.kill()
    _g16_review_focus="general"
    _a01_review_focus="general"
    _reset_camera()

# A01 cameras operate in the same Godot SubViewport.  No tactical fog,
# combat target acquisition or fake aircraft is introduced by this rig.
func _a01_review_look(yaw:float,focus:String)->void:
    if _role!="uav_recon" or model_root==null or not A01Finish.has_model(model_root):
        return
    if _a01_review_tween!=null and _a01_review_tween.is_running():
        _a01_review_tween.kill()
    _a01_review_focus=focus if focus in ["general","optica","cola","superior"] else "general"
    _yaw=yaw
    model_root.rotation_degrees.y=yaw
    _update_camera()
    if status_label!=null:
        status_label.text="A01 V3 · %s · mismo dron 3D sin armamento" % _a01_review_focus

func _a01_review_spin_tick(angle:float)->void:
    if _role!="uav_recon" or model_root==null:
        return
    _yaw=angle
    model_root.rotation_degrees.y=angle

func _a01_review_spin()->void:
    if _role!="uav_recon" or model_root==null or not A01Finish.has_model(model_root):
        return
    if _a01_review_tween!=null and _a01_review_tween.is_running():
        _a01_review_tween.kill()
    _a01_review_focus="general"
    _update_camera()
    _a01_review_tween=create_tween()
    _a01_review_tween.tween_method(Callable(self,"_a01_review_spin_tick"),
        _yaw,_yaw+360.0,7.0).set_trans(Tween.TRANS_LINEAR)
    if status_label!=null:
        status_label.text="A01 V2 · giro 360° · visor 3D TARVOKA"

# G16 V6 native camera presets: same SubViewport and real 3D geometry.
# These are inspection tools only; the playable logistics rules do not change.
func _g16_review_look(yaw: float, focus: String) -> void:
    if _role!="logistics_mobile" or model_root==null or not G16ServiceV6.has_model(model_root):
        return
    if _g16_review_tween!=null and _g16_review_tween.is_running():
        _g16_review_tween.kill()
    _g16_review_focus=focus if focus in ["general","suministros","bajos"] else "general"
    _yaw=yaw
    model_root.rotation_degrees.y=yaw
    if _g16_review_focus=="suministros":
        if _g16_tween!=null and _g16_tween.is_running():
            _g16_tween.kill()
        G16ServiceV6.show_finish(model_root,true)
        P06Models.restore_model_pose("logistics_mobile",model_root)
        P06Models.pose_model("logistics_mobile",model_root,"resupply",1.0)
    _update_camera()
    if status_label!=null:
        status_label.text="G16 V6 · %s · inspección real del mismo modelo 3D" % (
            "suministros desplegados" if focus=="suministros" else (
                "seis ruedas y bajos" if focus=="bajos" else "vista 360°"))

func _g16_review_spin_tick(angle:float) -> void:
    if _role!="logistics_mobile" or model_root==null:
        return
    _yaw=angle
    model_root.rotation_degrees.y=angle

func _g16_review_spin() -> void:
    if _role!="logistics_mobile" or model_root==null or not G16ServiceV6.has_model(model_root):
        return
    if _g16_review_tween!=null and _g16_review_tween.is_running():
        _g16_review_tween.kill()
    _g16_review_focus="general"
    _update_camera()
    _g16_review_tween=create_tween()
    _g16_review_tween.tween_method(
        Callable(self,"_g16_review_spin_tick"),_yaw,_yaw+360.0,7.0
    ).set_trans(Tween.TRANS_LINEAR)
    if status_label!=null:
        status_label.text="G16 V6 · giro real de 360° en visor online TARVOKA"

# The same SubViewport, camera, scene and role/faction controls are reused.
# V1 and V2 are real Godot MeshInstance3D trees, not image swaps.
func _infantry_review_look(yaw: float, perspective: String) -> void:
    if model_root==null or not InfantryV1.supports(_role):
        return
    if infantry_360_tween!=null and infantry_360_tween.is_running():
        infantry_360_tween.kill()
    _yaw=yaw
    model_root.rotation_degrees.y=yaw
    _update_camera()
    status_label.text="Infantería %s · ángulo %s · mismo visor 3D" % [
        "V2" if infantry_review_v2 else "V1",perspective]

func _infantry_review_spin_tick(angle: float) -> void:
    if model_root==null or not InfantryV1.supports(_role):
        return
    _yaw=angle
    model_root.rotation_degrees.y=angle

func _infantry_review_spin() -> void:
    if model_root==null or not InfantryV1.supports(_role):
        return
    if infantry_360_tween!=null and infantry_360_tween.is_running():
        infantry_360_tween.kill()
    infantry_360_tween=create_tween()
    infantry_360_tween.tween_method(Callable(self,"_infantry_review_spin_tick"),
        _yaw,_yaw+360.0,6.0).set_trans(Tween.TRANS_LINEAR)
    status_label.text="Infantería %s · revisión 360° real en Godot" % (
        "V2" if infantry_review_v2 else "V1")

# A01 reconnaissance V1 preview uses the same actual Godot SubViewport.
# No synthetic fog reveal and no attack capability are created by this rig.
func _a01_play(kind:String)->void:
    if _role!="uav_recon" or model_root==null or not A01Recon.has_model(model_root):
        return
    if kind not in A01Recon.VALID_POSES:
        return
    if _a01_tween!=null and _a01_tween.is_running():
        _a01_tween.kill()
    var art:Node3D=model_root
    A01Recon.restore(art)
    if kind=="idle":
        return
    _a01_tween=create_tween()
    _a01_tween.tween_method(Callable(self,"_a01_tick").bind(art,kind),
        0.0,1.0,2.8 if kind=="scan" else 1.5)
    _a01_tween.tween_callback(Callable(self,"_a01_done").bind(art))
    status_label.text="A01 V1 · %s · animación óptica 3D, sin alterar niebla" % kind

func _a01_tick(progress:float,art:Node3D,kind:String)->void:
    if is_instance_valid(art):
        A01Recon.pose(art,kind,progress)

func _a01_done(art:Node3D)->void:
    if is_instance_valid(art):
        A01Recon.restore(art)

# Rebuild the actual native Godot mesh inside the existing SubViewport.
# Preserve faction, damage, camera heading and comparison revision.
func _infantry_review_rebuild(latest: bool, lod: int) -> bool:
    if model_root==null or preview==null or not InfantryV1.supports(_role):
        return false
    if _engineer_v6_tween!=null and _engineer_v6_tween.is_running():
        _engineer_v6_tween.kill()
    if lod not in [8,13]:
        return false
    if infantry_360_tween!=null and infantry_360_tween.is_running():
        infantry_360_tween.kill()
    if _infantry_tween!=null and _infantry_tween.is_running():
        _infantry_tween.kill()
    var candidate: Node3D=null
    if latest:
        candidate=P06Models.build(_role,_faction,true,lod)
        if candidate==null or not bool(candidate.get_meta(
                "tarvoka_infantry_sculpt_finish_v2",false)):
            if candidate!=null:
                candidate.free()
            push_error("No se pudo cargar infantería 3D V2 en LOD%d"%lod)
            return false
    else:
        candidate=Node3D.new()
        if not InfantryV1.build(candidate,_role,
                P06Models.faction_paint_color(_faction),lod>=13):
            candidate.free()
            push_error("No se pudo cargar la comparación V1")
            return false
    var previous_damage:int=InfantryV1.damage_stage(model_root)
    var previous: Node3D=model_root
    preview.remove_child(previous)
    previous.queue_free()
    model_root=candidate
    preview.add_child(model_root)
    model_root.rotation_degrees.y=_yaw
    InfantryV1.set_damage(model_root,previous_damage)
    if latest:
        P06Models.pose_model(_role,model_root,"idle",0.0,Vector2i(0,-1))
    infantry_review_v2=latest
    infantry_review_lod=lod
    _update_camera()
    _update_details()
    return true

func _infantry_review_version(latest: bool) -> void:
    if _infantry_review_rebuild(latest,infantry_review_lod):
        status_label.text="Infantería %s · LOD%d · comparación en el mismo visor 3D" % [
            "V2" if latest else "V1",infantry_review_lod]

func _infantry_review_lod(lod: int) -> void:
    if _infantry_review_rebuild(infantry_review_v2,lod):
        # Orthographic preview at reduced visual size, not a separate map.
        # LOD8 uses physically rebuilt low-poly geometry; players may still
        # zoom/pan with the normal controls of the shared Godot Studio.
        _zoom=0.38 if lod==8 else 1.0
        _update_camera()
        status_label.text=("Infantería · LOD8 · prueba de distancia táctica en el visor 3D"
            if lod==8 else "Infantería · LOD13 · inspección de detalle 3D")

func _engineer_v6_tick(t: float, art: Node3D) -> void:
    if is_instance_valid(art) and EngineerFinishV6.has_model(art):
        EngineerFinishV6.pose(art,"inspect",t)

func _engineer_v6_run(opening: bool) -> void:
    if _role!="infantry_engineer" or model_root==null or \
            not EngineerFinishV6.has_model(model_root):
        return
    if _infantry_tween!=null and _infantry_tween.is_running():
        _infantry_tween.kill()
    if _engineer_v6_tween!=null and _engineer_v6_tween.is_running():
        _engineer_v6_tween.kill()
    var start: float=0.0 if opening else 1.0
    var end: float=1.0 if opening else 0.0
    _engineer_v6_tick(start,model_root)
    _engineer_v6_tween=create_tween()
    _engineer_v6_tween.tween_method(
        Callable(self,"_engineer_v6_tick").bind(model_root),start,end,1.25)
    status_label.text=(
        "Ingeniero V6 · barrera articulada abierta para inspección 360°, sin efecto táctico"
        if opening else
        "Ingeniero V6 · barrera plegada y asegurada en mochila")

func _infantry_pose_tick(t: float, kind: String) -> void:
    if model_root!=null and InfantryV1.supports(_role):
        P06Models.pose_model(_role,model_root,kind,t,Vector2i(0,-1))

func _infantry_play(kind: String) -> void:
    if not InfantryV1.supports(_role) or model_root==null:
        return
    if _engineer_v6_tween!=null and _engineer_v6_tween.is_running():
        _engineer_v6_tween.kill()
    if _infantry_tween!=null and _infantry_tween.is_running():
        _infantry_tween.kill()
    _infantry_tween=create_tween()
    _infantry_tween.tween_method(Callable(self,"_infantry_pose_tick").bind(kind),
        0.0,1.0,1.15)
    status_label.text="Infantería · animación %s · modelo %s" % [kind,
        "3D V2" if infantry_review_v2 else "3D V1"]

func _studio_quick_action(kind: String) -> void:
    if model_root==null or category_picker==null or category_picker.selected!=0:
        return
    match _role:
        "line","scout","infantry_urban","infantry_defense","infantry_antitank","infantry_engineer","infantry_sniper","infantry_logistic","infantry_medic","infantry_commando":
            _infantry_play("hit_bullet" if kind=="hit" else kind)
        "uav_recon":
            if kind in ["attack","attack_air","attack_ground"]:
                status_label.text="A01 es un dron de reconocimiento SIN armamento."
            else:
                _a01_play(kind)
        "logistics_mobile":
            if kind in ["attack","attack_air","attack_ground"]:
                status_label.text="G16 no tiene armamento. Solo logística y descarga."
            else:
                _g16_play("hit" if kind=="hit" else kind)
        "ew_mobile":
            if kind in ["attack","attack_air","attack_ground"]:
                status_label.text="G15 tiene interferencia visual, sin armamento."
            else:
                _g15_play("damage" if kind=="hit" else kind)
        "attack_heli":
            _heli_play("hit_bullet" if kind=="hit" else kind)
        "mlrs":
            _g11_play("hit_bullet" if kind=="hit" else kind)
        "apc":
            _play("hit_bullet" if kind=="hit" else kind)
        "aa_mobile":
            if kind in ["attack","attack_air","attack_ground"]:
                _g13_attack_v4("attack_ground" if kind=="attack_ground" else "attack_air")
            elif kind=="hit":
                _g13_demo_v1("idle",1.0)
            else:
                _studio_g13_animated_pose(kind)
        "tank":
            _play("hit_bullet" if kind=="hit" else kind)
        _:
            # No misleading animation button on units without a native rig.
            status_label.text="Este modelo no tiene animación propia implementada."

func _studio_quick_stop() -> void:
    if _role=="uav_recon":
        if _a01_tween!=null and _a01_tween.is_running():
            _a01_tween.kill()
        if model_root!=null:
            A01Recon.restore(model_root)
    elif InfantryV1.supports(_role):
        if _engineer_v6_tween!=null and _engineer_v6_tween.is_running():
            _engineer_v6_tween.kill()
        if _infantry_tween!=null and _infantry_tween.is_running():
            _infantry_tween.kill()
        if model_root!=null:
            P06Models.restore_model_pose(_role,model_root)
    elif _role=="logistics_mobile":
        if _g16_tween!=null and _g16_tween.is_running():
            _g16_tween.kill()
        if model_root!=null:
            P06Models.restore_model_pose("logistics_mobile",model_root)
    elif _role=="ew_mobile":
        if _g15_tween!=null and _g15_tween.is_running():
            _g15_tween.kill()
        if model_root!=null:
            P06Models.restore_model_pose("ew_mobile",model_root)
    elif _role=="attack_heli":
        _heli_stop()
    elif _role=="mlrs":
        _g11_stop()
    elif _role=="aa_mobile":
        if _g13_v4_tween!=null and _g13_v4_tween.is_running():
            _g13_v4_tween.kill()
        _g13_demo_v1("idle",1.0)
    elif _role=="apc" and _p06_fleet!=null:
        _hide_p06_fleet()
        _stop_animation()
    else:
        _stop_animation()

func _refresh_unified_studio_navigation() -> void:
    if studio_overview_label==null:
        return
    var building: bool=category_picker!=null and category_picker.selected==1
    var label: String=""
    if building:
        label="EDIFICIO · "+str(_role).replace("_"," ").to_upper()
    else:
        match _role:
            "infantry_urban": label="G01 · Guardia urbana · V2 en revisión"
            "infantry_defense": label="G01 · Guardia defensiva · V2 en revisión"
            "scout": label="G03 · Rastreador · V2 en revisión"
            "infantry_antitank": label="G04 · Rompedor · V2 en revisión"
            "infantry_engineer": label="Ingeniero · Campamento defensivo"
            "infantry_sniper": label="Francotirador · Campamento reconocimiento"
            "infantry_logistic": label="Logístico a pie · Campamento suministros"
            "infantry_medic": label="Médico · Campamento médico"
            "infantry_commando": label="Comando especial FS-24 · Infantería"
            "line": label="Infantería básica · Guardia"
            "tank": label="G09 · Tanque · V32 final"
            "apc": label="P06 · Bastión · V25"
            "mlrs": label="G11 · Lanzador · V33"
            "attack_heli": label="A01 · Helicóptero HAT-29 · V14"
            "uav_recon": label="A01 · Dron de reconocimiento · V3 EN DESARROLLO"
            "logistics_mobile": label="G16 · Logística blindada 6×6 · V6 PBR y suministros articulados"
            "ew_mobile": label="G15 · Guerra electrónica · V11 (neumáticos, óptica y electrónica 3D)"
            "aa_mobile": label="G13 · Antiaéreo · V54 caucho y rodadura 3D"
            _: label="UNIDAD · "+str(_role).replace("_"," ").to_upper()
    studio_overview_label.text=label
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    if column!=null:
        for node in column.get_children():
            if node is Label:
                var name_text: String=str((node as Label).text)
                if name_text=="MODELO" or name_text=="FACCION" or (
                        name_text.begins_with("Visor 3D del motor Godot:")) or (
                        name_text.begins_with("El mismo modelo de Godot")):
                    (node as Label).visible=false
    if building_picker!=null:
        building_picker.visible=building
    role_picker.visible=not building
    if studio_versions_fold!=null:
        studio_versions_fold.visible=studio_active_tab==2 and not building and _role=="tank"
    if studio_advanced_group!=null:
        studio_advanced_group.visible=studio_active_tab==2
    if studio_advanced_content!=null:
        studio_advanced_content.visible=studio_advanced_expanded
    var show_unit_details: bool=not building and studio_active_tab==2 and studio_advanced_expanded
    if p06_controls!=null:
        p06_controls.visible=show_unit_details and _role=="apc"
    if g11_controls!=null:
        g11_controls.visible=show_unit_details and _role=="mlrs"
    if g13_controls!=null:
        g13_controls.visible=show_unit_details and _role=="aa_mobile"
    if heli_controls!=null:
        heli_controls.visible=show_unit_details and _role=="attack_heli"
    if studio_legacy_controls!=null:
        studio_legacy_controls.visible=show_unit_details and _role=="tank"
    if infantry_six_panel!=null:
        infantry_six_panel.visible=not building and InfantryV1.supports(_role)
    if infantry_360_panel!=null:
        infantry_360_panel.visible=not building and InfantryV1.supports(_role)
    if g16_360_panel!=null:
        g16_360_panel.visible=not building and _role=="logistics_mobile"
    if a01_360_panel!=null:
        a01_360_panel.visible=not building and _role=="uav_recon"
    if studio_animation_panel!=null:
        studio_animation_panel.visible=not building and studio_active_tab==0
    _studio_rebuild_animation_catalog()

func _install_heli_controls() -> void:
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    heli_controls=VBoxContainer.new()
    heli_controls.name="A01_HelicopteroAtaque_V2_Studio"
    heli_controls.add_theme_constant_override("separation",8)
    column.add_child(heli_controls)
    _title(heli_controls,"HELICÓPTERO HAT-29 · V14.15 · CORTES DE ROTURA SELLADOS",14)
    _add_paired(heli_controls,"Vuelo y rotores",func(): _heli_play("move"),
        "Ráfaga frontal",func(): _heli_play("attack"))
    _add_paired(heli_controls,"Impactos de bala",func(): _heli_play("hit_bullet"),
        "Impacto explosivo",func(): _heli_play("hit_explosive"))
    _add_paired(heli_controls,"V14: siguiente nivel de daño",_heli_next_damage,
        "V14: reparar helicóptero",_heli_repair)
    _add_paired(heli_controls,"V14: animar destrucción",_heli_destroy,
        "V14: detalle humo e impactos",
        func(): _heli_inspect_focus(62.0,14.0,2.35,Vector3(0.45,1.55,0.72)))
    _add_paired(heli_controls,"Vista frontal",func(): _heli_view(0.0),
        "Vista 3/4 delantera",func(): _heli_view(40.0))
    _add_paired(heli_controls,"Ver armamento lateral",func(): _heli_view(90.0),
        "Vista trasera y rotor de cola",func(): _heli_view(180.0))
    _add_paired(heli_controls,"Lateral contrario",func(): _heli_view(270.0),
        "Vista superior",_heli_top_view)
    _add_paired(heli_controls,"V2: inspeccionar cabina",func(): _heli_inspect(40.0,0.0,1.55),
        "V2: motores y registros",func(): _heli_inspect(90.0,0.0,1.52))
    _add_paired(heli_controls,"V2: casco y laterales",func(): _heli_inspect(145.0,0.0,1.30),
        "V2: marcos superiores",func(): _heli_inspect(30.0,34.0,1.50))
    _add_paired(heli_controls,"V3: perfil del rotor principal",func(): _heli_inspect(40.0,40.0,1.55),
        "V3: rotor de cola y aro",func(): _heli_inspect(215.0,12.0,1.55))
    _add_paired(heli_controls,"V3: ala y anclajes",func(): _heli_inspect(90.0,7.0,1.66),
        "V3: simetría de las dos alas",func(): _heli_inspect(0.0,31.0,1.44))
    _add_paired(heli_controls,"V4: toma de aire del motor",func(): _heli_inspect(48.0,20.0,1.75),
        "V4: escape y turbina",func(): _heli_inspect(136.0,15.0,1.70))
    _add_paired(heli_controls,"V4: panel blindado lateral",func(): _heli_inspect(89.0,0.0,1.78),
        "V4: transmisión y cubierta",func(): _heli_inspect(29.0,45.0,1.70))
    _add_paired(heli_controls,"V5: patín lateral",func(): _heli_inspect(96.0,-9.0,1.72),
        "V5: vista inferior y soportes",func(): _heli_inspect(36.0,-30.0,1.64))
    _add_paired(heli_controls,"V5: uniones de motores",func(): _heli_inspect(44.0,34.0,1.75),
        "V5: simetría del tren",func(): _heli_inspect(0.0,-12.0,1.48))
    _add_paired(heli_controls,"V6: amortiguadores",func(): _heli_inspect(88.0,-10.0,1.93),
        "V6: collar y bisagra inferior",func(): _heli_inspect(49.0,-21.0,1.86))
    _add_paired(heli_controls,"V6: protección de patines",func(): _heli_inspect(99.0,-9.0,1.88),
        "V6: sellado de los motores",func(): _heli_inspect(52.0,29.0,1.88))
    _add_paired(heli_controls,"V7: cámara de batalla 360p",func(): _heli_inspect(36.0,19.0,0.66),
        "V7: identidad lateral 360p",func(): _heli_inspect(90.0,17.0,0.62))
    _add_paired(heli_controls,"V7: marquesinas y lanzadores",func(): _heli_inspect(44.0,10.0,1.72),
        "V7: puntas de rotores",func(): _heli_inspect(38.0,35.0,1.64))
    _add_paired(heli_controls,"V8: identificación a 320p",func(): _heli_inspect(36.0,20.0,0.68),
        "V8: alas y motor dorsal",func(): _heli_inspect(82.0,27.0,1.68))
    _add_paired(heli_controls,"V8: aleta de cola",func(): _heli_inspect(132.0,14.0,1.70),
        "V8: simetría desde arriba",func(): _heli_inspect(28.0,43.0,1.57))
    _add_paired(heli_controls,"V10: cristal tándem",
        func(): _heli_inspect_focus(34.0,12.0,2.26,Vector3(0,1.53,-0.76)),
        "V10: corona de rotor",
        func(): _heli_inspect_focus(38.0,48.0,2.30,Vector3(0,1.97,0.08)))
    _add_paired(heli_controls,"V10: motor y escape",
        func(): _heli_inspect_focus(130.0,24.0,2.04,Vector3(0.37,1.58,0.77)),
        "V10: cañón y soporte",
        func(): _heli_inspect_focus(25.0,-13.0,2.26,Vector3(0,0.59,-1.49)))
    _add_paired(heli_controls,"V11: transmisión y rotor de cola",
        func(): _heli_inspect_focus(153.0,20.0,2.48,Vector3(0.15,1.39,2.60)),
        "V11: soportes y lanzadores",
        func(): _heli_inspect_focus(63.0,-13.0,2.37,Vector3(1.05,0.68,-0.38)))
    _add_paired(heli_controls,"V12: casco y blindajes del morro",
        func(): _heli_inspect_focus(24.0,-11.0,2.55,Vector3(0,0.90,-1.40)),
        "V12: soporte articulado del cañón",
        func(): _heli_inspect_focus(54.0,-14.0,2.72,Vector3(0.19,0.57,-1.38)))
    # V14.2: real geometry closeups within the unified Studio.
    _add_paired(heli_controls,"V14.2: escotilla inferior",
        _heli_underbody_inspect,
        "V14.2: lamas de motor",
        func(): _heli_inspect_focus(92.0,10.0,2.20,Vector3(0.62,1.61,1.01)))
    _add_paired(heli_controls,"V14.2: registros de cola",
        func(): _heli_inspect_focus(130.0,8.0,2.25,Vector3(0.16,1.10,1.97)),
        "V14.2: posterior completa",
        func(): _heli_inspect(180.0,-6.0,1.30))
    _add_paired(heli_controls,"V14.3: acabado de motores",
        func(): _heli_inspect_focus(90.0,12.0,2.16,Vector3(0.64,1.61,1.08)),
        "V14.3: sellos de cola",
        func(): _heli_inspect_focus(132.0,8.0,2.18,Vector3(0.18,1.10,1.97)))
    _add_paired(heli_controls,"V14.5: anclajes fijos del mástil",
        _heli_mast_inspect_v145,
        "V14.5: corona y bisagras del rotor",
        func(): _heli_inspect_focus(31.0,61.0,2.70,Vector3(0,2.01,0.08)))
    _add_paired(heli_controls,"V14.6: amortiguadores de palas",
        func(): _heli_inspect_focus(42.0,55.0,3.05,Vector3(0,2.04,-0.22)),
        "V14.6: aisladores de mástil",
        _heli_mast_inspect_v145)
    _add_paired(heli_controls,"V14.7: cilindros hidráulicos",
        func(): _heli_inspect_focus(40.0,27.0,3.75,Vector3(0.17,2.07,-0.29)),
        "V14.7: fuelles y anclajes",
        func(): _heli_inspect_focus(40.0,58.0,3.68,Vector3(0.18,2.04,-0.34)))
    _add_paired(heli_controls,"V14.8: horquillas de paso",
        func(): _heli_inspect_focus(310.0,30.0,3.78,Vector3(-0.16,2.06,-0.29)),
        "V14.8: pasadores y bieletas",
        func(): _heli_inspect_focus(315.0,59.0,3.72,Vector3(-0.16,2.07,-0.35)))
    _add_paired(heli_controls,"V14.9: asiento de bieleta",
        func(): _heli_inspect_focus(306.0,18.0,4.14,Vector3(-0.098,2.01,-0.23)),
        "V14.9: anclaje hidráulico",
        func(): _heli_inspect_focus(50.0,18.0,4.12,Vector3(0.108,2.02,-0.42)))
    _add_paired(heli_controls,"V14.10: placas biseladas",
        func(): _heli_inspect_focus(307.0,20.0,4.35,Vector3(-0.094,2.02,-0.28)),
        "V14.10: pernos asentados",
        func(): _heli_inspect_focus(53.0,22.0,4.28,Vector3(0.106,2.02,-0.42)))
    _button(heli_controls,"Comparar rotor V14.9 / V14.10",_heli_toggle_v1410)
    _add_paired(heli_controls,"V14.11: transición aerodinámica",
        func(): _heli_inspect_focus(305.0,36.0,4.06,Vector3(-0.01,2.01,-0.24)),
        "V14.11: perfil y biseles",
        func(): _heli_inspect_focus(125.0,13.0,4.12,Vector3(0,2.02,-0.33)))
    _button(heli_controls,"Comparar raíz V3 / V14.11",_heli_toggle_v1411)
    _add_paired(heli_controls,"V14.12: transición de borde",
        func(): _heli_inspect_focus(311.0,17.0,4.28,Vector3(0.014,2.01,-0.33)),
        "V14.12: perfil desde abajo",
        func(): _heli_inspect_focus(143.0,-17.0,4.20,Vector3(0.020,2.01,-0.42)))
    _button(heli_controls,"Comparar unión V14.11 / V14.12",_heli_toggle_v1412)
    _add_paired(heli_controls,"V14.13: cubierta superior",
        func(): _heli_inspect_focus(30.0,62.0,4.10,Vector3(0,2.07,0.08)),
        "V14.13: perfil de buje",
        func(): _heli_inspect_focus(140.0,14.0,4.06,Vector3(0,2.05,0.08)))
    _button(heli_controls,"Comparar corona V10 / V14.13",_heli_toggle_v1413)
    _button(heli_controls,"V14.13: giro lento de inspección",
        func(): _heli_play("move",0.25))
    _button(heli_controls,"V14.14: desprendimiento del buje",
        func(): _heli_destroy(0.50))
    _button(heli_controls,"Comparar restos V13 / V14.14",_heli_toggle_v1414)
    _add_paired(heli_controls,"V14.15: inspeccionar corte izquierdo",
        func(): _heli_fragment_focus_v1415(1),
        "V14.15: inspeccionar corte derecho",
        func(): _heli_fragment_focus_v1415(0))
    _button(heli_controls,"Comparar corte abierto V14.14 / sellado V14.15",
        _heli_toggle_v1415)
    _heli_night_button_v143=_button(heli_controls,
        "V14.4: activar noche táctica",_heli_toggle_night_v143)
    _heli_v12_button=_button(heli_controls,
        "Comparar morro V11 / V12",_heli_toggle_v12)
    _heli_v11_button=_button(heli_controls,
        "Comparar mecánica V10 / V11",_heli_toggle_v11)
    _heli_v10_button=_button(heli_controls,"Comparar acabados V8 / V10",_heli_toggle_v10)
    _heli_v8_button=_button(heli_controls,"Comparar identidad V7 / V8",_heli_toggle_v8)
    _heli_v7_button=_button(heli_controls,"Comparar legibilidad V6 / V7",_heli_toggle_v7)
    _heli_compare_button=_button(heli_controls,"Comparar casco anterior V1",_heli_toggle_v2)
    _button(heli_controls,"Detener (para reparar: botón V13)",_heli_stop)
    _title(heli_controls,
        "V12: blindaje frontal cerrado, óptica y montura móvil del cañón; "
        + "conserva V10/V11 y animaciones del original. V13 agrega 4 daños y destrucción 3D.",12)
    var index: int=column.get_children().find(detail_label)
    column.move_child(heli_controls,maxi(0,index))
    heli_controls.visible=false

func _heli_is_compact_landscape(view_size: Vector2) -> bool:
    # Screen coordinates from the real browser viewport, not guessed dpi.
    return view_size.x>=770.0 and view_size.y<=740.0 and (
        view_size.x<=1600.0 and view_size.x>=view_size.y*1.30)

func _install_heli_mobile_bar() -> void:
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    heli_mobile_bar=VBoxContainer.new()
    heli_mobile_bar.name="A01V9_AccesoHorizontalAndroid"
    heli_mobile_bar.add_theme_constant_override("separation",5)
    column.add_child(heli_mobile_bar)
    column.move_child(heli_mobile_bar,column.get_children().find(role_picker)+1)
    _title(heli_mobile_bar,"A01 · HERRAMIENTAS RÁPIDAS",13)
    _add_paired(heli_mobile_bar,"Vista general",_heli_mobile_home,
        "Alas / motores",func(): _heli_inspect(58.0,26.0,1.36))
    _add_paired(heli_mobile_bar,"Patines y soportes",
        func(): _heli_inspect(90.0,-15.0,1.54),
        "Probar disparo",func(): _heli_play("attack"))
    _add_paired(heli_mobile_bar,"Comparar V7 / V8",_heli_toggle_v8,
        "Girar 45°",func(): _heli_view(fposmod(_yaw+45.0,360.0)))
    _heli_mobile_expand_button=_button(heli_mobile_bar,
        "Mostrar inspecciones técnicas",_heli_mobile_toggle_advanced)
    _heli_mobile_expand_button.custom_minimum_size.y=44
    _heli_mobile_hint=_title(heli_mobile_bar,
        "Arrastra el helicóptero para girarlo. Pellizca para acercar.",11)
    heli_mobile_bar.visible=false

func _heli_mobile_home() -> void:
    _heli_inspect(35.0,17.0,1.0)

func _heli_mobile_toggle_advanced() -> void:
    if _role!="attack_heli":
        return
    _heli_mobile_expanded=not _heli_mobile_expanded
    _heli_refresh_mobile_layout(get_viewport().get_visible_rect().size)

func _heli_reflow_frame(view_size: Vector2) -> void:
    # The base Studio chooses HBox/VBox only on startup. Rebuild just the
    # container on orientation change; preserve the EXISTING viewport, camera
    # and sidebar instances, so the model/animation does not get recreated.
    if model_holder==null:
        return
    var old: BoxContainer=model_holder.get_parent() as BoxContainer
    if old==null:
        return
    var wide: bool=view_size.x>=770.0
    if (old is HBoxContainer)==wide:
        return
    var replacement: BoxContainer=HBoxContainer.new() if wide else VBoxContainer.new()
    replacement.name="A01V9_ResponsiveFrame"
    replacement.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    replacement.add_theme_constant_override("separation",8)
    var owner_node: Node=old.get_parent()
    var previous_index: int=old.get_index()
    owner_node.add_child(replacement)
    owner_node.move_child(replacement,previous_index)
    for child in old.get_children():
        child.reparent(replacement,false)
    old.queue_free()
    _heli_frame_reflows+=1

func _heli_limit_sidebar_width(compact: bool) -> void:
    # The legacy full role name (and dozens of hidden buttons) used to force
    # a 472px sidebar inside a 960px Android viewport. Actual V9 Godot
    # captures confirmed only 488px remained for the 3D helicopter.
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    if column==null:
        return
    var role_index: int=P06Models.ROLES.find("attack_heli")
    if role_index>=0:
        role_picker.set_item_text(role_index,"Helicóptero A01 HAT-29 · V14.15")
    # Godot Button.clip_text participates in minimum-size computation.
    # Keep buttons touch-friendly (44px high) instead of truncating canvas.
    for node in column.find_children("*","Button",true,false):
        # All roles, not only the helicopter, must keep long revision and
        # G13/APC names from forcing a 470px sidebar in Android landscape.
        (node as Button).clip_text=true
    # The base Studio's long introduction occupied 130px of a 540px screen.
    # Quick instructions are already repeated in the A01 toolbar.
    for node in column.get_children():
        if node is Label and str((node as Label).text).begins_with(
                "Visor 3D del motor Godot:"):
            (node as Label).visible=false
    if model_holder==null:
        return
    var frame: BoxContainer=model_holder.get_parent() as BoxContainer
    if frame==null or frame.get_child_count()<2:
        return
    var sidebar: Control=frame.get_child(1) as Control
    if sidebar!=null:
        sidebar.custom_minimum_size.x=318.0 if compact else 306.0
        sidebar.size_flags_horizontal=Control.SIZE_SHRINK_END
    var scroll: ScrollContainer=sidebar.get_child(0) as ScrollContainer if (
        sidebar!=null and sidebar.get_child_count()>0) else null
    if scroll!=null:
        scroll.custom_minimum_size.x=318.0 if compact else 0.0

func _heli_refresh_mobile_layout(view_size: Vector2) -> void:
    if heli_mobile_bar==null or heli_controls==null:
        return
    var compact: bool=_heli_is_compact_landscape(view_size)
    if compact!=_heli_compact_landscape:
        _heli_compact_landscape=compact
        _heli_mobile_expanded=false
    var active: bool=_role=="attack_heli" and (
        category_picker==null or category_picker.selected==0)
    # Restore the full shared controls when leaving A01. The compact label,
    # clipped buttons and forced sidebar width must never leak to Bastion,
    # G11, tanks, buildings or naval/air-base inspect modes.
    _heli_limit_sidebar_width(compact if active else false)
    # This compact toolbar predated the unified tabs. Keep its actions
    # wired for compatibility, but never show a second control surface.
    heli_mobile_bar.visible=false
    heli_controls.visible=active and studio_active_tab==2 and studio_advanced_expanded
    if _heli_mobile_expand_button!=null:
        _heli_mobile_expand_button.text=(
            "Ocultar inspecciones técnicas" if _heli_mobile_expanded else
            "Mostrar inspecciones técnicas")
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    # In the unified studio, helicopter controls are children of Details,
    # not the original column. Do not reparent them during viewport resize.
    if heli_controls.get_parent()==column:
        if compact:
            column.move_child(heli_controls,
                column.get_children().find(heli_mobile_bar)+1)
        else:
            column.move_child(heli_controls,
                maxi(0,column.get_children().find(detail_label)))
    if active:
        _heli_reflow_frame(view_size)

func _heli_on_viewport_resize() -> void:
    _heli_refresh_mobile_layout(get_viewport().get_visible_rect().size)
    if _role=="attack_heli" and model_root!=null:
        _update_camera()

func _install_heli_lighting_v10() -> void:
    # Single cool reflection with no extra WebGL shadows; disabled for other roles.
    if preview==null:
        return
    _heli_v10_rim_light=DirectionalLight3D.new()
    _heli_v10_rim_light.name="A01V10_LuzRasanteEstudio"
    _heli_v10_rim_light.rotation_degrees=Vector3(-23.0,137.0,0.0)
    _heli_v10_rim_light.light_color=Color("#c8e1ef")
    _heli_v10_rim_light.light_energy=0.50
    _heli_v10_rim_light.shadow_enabled=false
    _heli_v10_rim_light.visible=false
    preview.add_child(_heli_v10_rim_light)
    # Second independent no-shadow fill, night-only. Battle lights unchanged.
    _heli_night_fill_v143=OmniLight3D.new()
    _heli_night_fill_v143.name="A01V143_LuzTacticaDeInspeccionNocturna"
    _heli_night_fill_v143.position=Vector3(-2.6,2.8,0.65)
    _heli_night_fill_v143.omni_range=7.0
    _heli_night_fill_v143.light_color=Color("#a2c4dc")
    _heli_night_fill_v143.light_energy=0.66
    _heli_night_fill_v143.shadow_enabled=false
    _heli_night_fill_v143.visible=false
    preview.add_child(_heli_night_fill_v143)

# V14.3 night inspection shares the original Studio environment rather than
# adding a second viewer. Snapshot + restore all changed light/sky properties,
# so exiting A01 does not recolor Bastion, tank, buildings or the battlefield.
func _heli_set_night_v143(enabled: bool) -> void:
    if enabled==_heli_night_enabled_v143:
        return
    if hq_key_light==null or hq_fill_light==null or hq_environment==null:
        return
    var scene: Environment=hq_environment.environment
    if scene==null:
        return
    if enabled:
        if _role!="attack_heli" or model_root==null:
            return
        _heli_night_snapshot_v143={
            "key_color":hq_key_light.light_color,
            "key_energy":hq_key_light.light_energy,
            "key_rotation":hq_key_light.rotation_degrees,
            "fill_color":hq_fill_light.light_color,
            "fill_energy":hq_fill_light.light_energy,
            "sky":scene.background_color,
            "ambient_color":scene.ambient_light_color,
            "ambient_energy":scene.ambient_light_energy
        }
        hq_key_light.rotation_degrees=Vector3(-18.0,61.0,0)
        hq_key_light.light_color=Color("#b6cbe2")
        hq_key_light.light_energy=0.22
        hq_fill_light.light_color=Color("#86afce")
        hq_fill_light.light_energy=0.24
        scene.background_color=Color("#0c1622")
        scene.ambient_light_color=Color("#819bb5")
        scene.ambient_light_energy=0.23
    else:
        var day: Dictionary=_heli_night_snapshot_v143
        if not day.is_empty():
            hq_key_light.light_color=day["key_color"]
            hq_key_light.light_energy=day["key_energy"]
            hq_key_light.rotation_degrees=day["key_rotation"]
            hq_fill_light.light_color=day["fill_color"]
            hq_fill_light.light_energy=day["fill_energy"]
            scene.background_color=day["sky"]
            scene.ambient_light_color=day["ambient_color"]
            scene.ambient_light_energy=day["ambient_energy"]
        _heli_night_snapshot_v143.clear()
    _heli_night_enabled_v143=enabled
    if _heli_night_fill_v143!=null:
        _heli_night_fill_v143.visible=enabled
    # Three narrow no-shadow lamps ride with the real high-detail airframe.
    # They illuminate only the old physical metal engine and tail hardware.
    if _role=="attack_heli" and model_root!=null:
        if enabled and not HeliNightV144.has_lights(model_root):
            HeliNightV144.install(model_root)
        HeliNightV144.set_enabled(model_root,enabled)
    if _heli_night_button_v143!=null:
        _heli_night_button_v143.text=(
            "V14.4: volver a iluminación diurna" if enabled
            else "V14.4: activar noche táctica")

func _heli_toggle_night_v143() -> void:
    if _role=="attack_heli":
        _heli_set_night_v143(not _heli_night_enabled_v143)

# Inspection-only camera mode; does not rotate a destroyed helicopter or
# change its fuselage, gear, flight rig or stage. The floor is hidden only
# while looking upward at the octagonal belly panel.
func _heli_underbody_restore_floor() -> void:
    _heli_underbody_view_active=false
    for plane in _heli_hidden_floor_meshes:
        if is_instance_valid(plane):
            plane.visible=true
    _heli_hidden_floor_meshes.clear()

func _heli_underbody_inspect() -> void:
    if _role!="attack_heli" or model_root==null or camera==null:
        return
    _heli_inspect(36.0,0.0,2.08)
    _heli_focus_local=Vector3(0.0,0.605,0.06)
    _heli_underbody_view_active=true
    _heli_hidden_floor_meshes.clear()
    if preview!=null:
        for candidate in preview.find_children("*","MeshInstance3D",true,false):
            var plane: MeshInstance3D=candidate as MeshInstance3D
            if plane==null or model_root.is_ancestor_of(plane):
                continue
            var label: String=str(plane.name).to_lower()
            var ground: bool=plane.mesh is PlaneMesh or (
                label.contains("suelo") or label.contains("floor")
                or label.contains("ground"))
            if ground and plane.visible:
                _heli_hidden_floor_meshes.append(plane)
                plane.visible=false
    _update_camera()

func _heli_mast_inspect_v145() -> void:
    if _role!="attack_heli" or model_root==null or camera==null:
        return
    _heli_inspect(50.0,0.0,2.67)
    _heli_focus_local=Vector3(0,1.72,0.08)
    _heli_mast_view_active_v145=true
    _update_camera()

func _heli_inspect_focus(yaw: float,tilt: float,zoom_level: float,
        local_point: Vector3) -> void:
    _heli_inspect(yaw,tilt,zoom_level)
    if _role!="attack_heli" or model_root==null:
        return
    _heli_focus_local=local_point
    _update_camera()

func _heli_toggle_v10() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV10.has_model(model_root):
        return
    _heli_stop()
    _heli_v10_enabled=not _heli_v10_enabled
    HeliV10.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled)
    HeliV11.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled)
    HeliV12.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled and _heli_v12_enabled)
    _sync_p06_controls()
    _update_details()
    _update_camera()

func _heli_fragment_focus_v1415(index: int) -> void:
    if _role!="attack_heli" or model_root==null or not HeliHubCutFinishV1415.has_model(model_root):
        return
    if HeliV13.stage(model_root)<4:
        _heli_stop(true)
        _heli_damage_stage=4
        HeliV13.set_stage(model_root,4)
    _heli_animation=""
    _heli_time=0.0
    HeliV13.pose(model_root,"destroy",1.0)
    _heli_wreck_frozen=true
    var debris: Node3D=model_root.find_child(HeliV13.WRECK,true,false) as Node3D
    if debris==null:
        return
    var point: Vector3=debris.to_global(HeliHubWreckV1414.REST_POINTS[index])
    _heli_focus_local=model_root.to_local(point)
    _zoom=4.5
    _update_details()
    _update_camera()

func _heli_toggle_v1415() -> void:
    if _role!="attack_heli" or model_root==null or not HeliHubCutFinishV1415.has_model(model_root):
        return
    var current: bool=bool(model_root.get_meta(HeliHubCutFinishV1415.ENABLED,true))
    HeliHubCutFinishV1415.set_enabled(model_root,not current)
    _update_details()
    _update_camera()

func _heli_toggle_v1414() -> void:
    if _role!="attack_heli" or model_root==null or not HeliHubWreckV1414.has_model(model_root):
        return
    var rendered: bool=bool(model_root.get_meta(HeliHubWreckV1414.ENABLED,true))
    HeliHubWreckV1414.set_enabled(model_root,not rendered)
    if HeliV13.stage(model_root)<4:
        _heli_destroy(0.50)
    _update_details()
    _update_camera()

func _heli_toggle_v1413() -> void:
    if _role!="attack_heli" or model_root==null or not HeliHubCrownV1413.has_model(model_root):
        return
    _heli_stop()
    var polished: bool=bool(model_root.get_meta(HeliHubCrownV1413.ENABLED,true))
    HeliHubCrownV1413.set_enabled(model_root,not polished)
    _update_details()
    _update_camera()

func _heli_toggle_v1412() -> void:
    if _role!="attack_heli" or model_root==null or not HeliBladeSeamV1412.has_model(model_root):
        return
    if not bool(model_root.get_meta(HeliBladeRootsV1411.ENABLED,false)):
        return
    _heli_stop()
    var refined: bool=bool(model_root.get_meta(HeliBladeSeamV1412.ENABLED,true))
    HeliBladeSeamV1412.set_enabled(model_root,not refined)
    _update_details()
    _update_camera()

func _heli_toggle_v1411() -> void:
    if _role!="attack_heli" or model_root==null or not HeliBladeRootsV1411.has_model(model_root):
        return
    _heli_stop()
    var refined: bool=bool(model_root.get_meta(HeliBladeRootsV1411.ENABLED,true))
    if refined:
        var preserve: bool=bool(model_root.get_meta(HeliBladeSeamV1412.ENABLED,false))
        model_root.set_meta("a01_v1412_before_v3_compare",preserve)
        if preserve:
            HeliBladeSeamV1412.set_enabled(model_root,false)
        HeliBladeRootsV1411.set_enabled(model_root,false)
    else:
        HeliBladeRootsV1411.set_enabled(model_root,true)
        if bool(model_root.get_meta("a01_v1412_before_v3_compare",false)):
            HeliBladeSeamV1412.set_enabled(model_root,true)
    _update_details()
    _update_camera()

func _heli_toggle_v1410() -> void:
    if _role!="attack_heli" or model_root==null or not HeliRotorContactV1410.has_model(model_root):
        return
    _heli_stop()
    var refined: bool=bool(model_root.get_meta(HeliRotorContactV1410.ENABLED,true))
    HeliRotorContactV1410.set_enabled(model_root,not refined)
    _update_details()
    _update_camera()

func _heli_toggle_v12() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV12.has_model(model_root):
        return
    _heli_stop()
    _heli_v12_enabled=not _heli_v12_enabled
    HeliV12.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled and _heli_v12_enabled)
    _sync_p06_controls()
    _update_details()
    _update_camera()

func _heli_toggle_v11() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV11.has_model(model_root):
        return
    _heli_stop()
    _heli_v11_enabled=not _heli_v11_enabled
    HeliV11.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled)
    HeliV12.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled and _heli_v12_enabled)
    _sync_p06_controls()
    _update_details()
    _update_camera()

func _heli_inspect(yaw: float,tilt: float,zoom_level: float) -> void:
    if _role!="attack_heli" or model_root==null:
        return
    _heli_underbody_restore_floor()
    _heli_mast_view_active_v145=false
    _heli_stop()
    _heli_focus_local=Vector3.ZERO
    _yaw=yaw
    _zoom=zoom_level
    # A completed crash stays banked and grounded while inspecting it.
    # Only the orbit/tilt changes, never the 70-degree wreck roll.
    var wreck_roll: float=model_root.rotation_degrees.z if _heli_wreck_frozen else 0.0
    model_root.rotation_degrees=Vector3(tilt,yaw,wreck_roll)
    _update_camera()

func _heli_toggle_v2() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV2.has_model(model_root):
        return
    _heli_stop()
    _heli_v2_enabled=not _heli_v2_enabled
    HeliV2.set_enabled(model_root,_heli_v2_enabled)
    HeliV3.set_enabled(model_root,_heli_v2_enabled)
    HeliV4.set_enabled(model_root,_heli_v2_enabled)
    HeliV5.set_enabled(model_root,_heli_v2_enabled)
    HeliV6.set_enabled(model_root,_heli_v2_enabled)
    HeliV7.set_enabled(model_root,_heli_v2_enabled and _heli_v7_enabled)
    HeliV8.set_enabled(model_root,_heli_v2_enabled and _heli_v8_enabled)
    HeliV10.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled)
    HeliV11.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled)
    HeliV12.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled and _heli_v12_enabled)
    _update_details()
    _update_camera()
    _sync_p06_controls()

func _heli_toggle_v7() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV7.has_model(model_root):
        return
    _heli_stop()
    _heli_v7_enabled=not _heli_v7_enabled
    HeliV7.set_enabled(model_root,_heli_v2_enabled and _heli_v7_enabled)
    _update_details()
    _update_camera()
    _sync_p06_controls()

func _heli_toggle_v8() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV8.has_model(model_root):
        return
    _heli_stop()
    _heli_v8_enabled=not _heli_v8_enabled
    HeliV8.set_enabled(model_root,_heli_v2_enabled and _heli_v8_enabled)
    _update_details()
    _update_camera()
    _sync_p06_controls()

func _heli_view(yaw: float) -> void:
    if _role!="attack_heli" or model_root==null:
        return
    _heli_mast_view_active_v145=false
    _heli_underbody_restore_floor()
    _heli_stop()
    _yaw=yaw
    var wreck_roll: float=model_root.rotation_degrees.z if _heli_wreck_frozen else 0.0
    model_root.rotation_degrees=Vector3(0,yaw,wreck_roll)
    _heli_focus_local=Vector3.ZERO
    _update_camera()

func _heli_top_view() -> void:
    if _role!="attack_heli" or model_root==null:
        return
    _heli_mast_view_active_v145=false
    _heli_underbody_restore_floor()
    _heli_stop()
    _yaw=38.0
    var wreck_roll: float=model_root.rotation_degrees.z if _heli_wreck_frozen else 0.0
    model_root.rotation_degrees=Vector3(43.0,_yaw,wreck_roll)
    _heli_focus_local=Vector3.ZERO
    _update_camera()

func _heli_select_damage(level: int) -> void:
    if _role!="attack_heli" or model_root==null or not HeliV13.has_model(model_root):
        return
    var next_level: int=clampi(level,0,HeliV13.MAX_STAGE)
    if next_level==0:
        _heli_repair()
    elif next_level>=HeliV13.MAX_STAGE:
        _heli_destroy()
    else:
        # If coming back from a wreck, restore the original flight transform
        # before previewing lesser damage stages.
        if _heli_wreck_frozen:
            _heli_repair()
        else:
            _heli_stop(true)
        _heli_damage_stage=next_level
        HeliV13.set_stage(model_root,next_level)
        _update_details()

func _heli_next_damage() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV13.has_model(model_root):
        return
    _heli_stop()
    _heli_damage_stage=mini(HeliV13.stage(model_root)+1,HeliV13.MAX_STAGE)
    if _heli_damage_stage==4 and not _heli_wreck_frozen:
        _heli_destroy()
        return
    HeliV13.set_stage(model_root,_heli_damage_stage)
    _update_details()

func _heli_repair() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV13.has_model(model_root):
        return
    _heli_stop(true)
    _heli_wreck_frozen=false
    _heli_damage_stage=0
    _heli_damage_clock=0.0
    HeliV13.set_stage(model_root,0)
    _update_details()

func _heli_destroy(speed: float=1.0) -> void:
    if _role!="attack_heli" or model_root==null or not HeliV13.has_model(model_root):
        return
    _heli_stop(true)
    _heli_wreck_frozen=false
    _heli_damage_stage=4
    HeliV13.set_stage(model_root,4)
    _heli_play("destroy",speed)

func _heli_play(kind: String,speed: float=1.0) -> void:
    if _role!="attack_heli" or model_root==null or not HeliV1.has_model(model_root):
        return
    if HeliV13.has_model(model_root):
        if kind!="destroy" and HeliV13.stage(model_root)>=4:
            return
        if kind=="hit_bullet":
            _heli_damage_stage=maxi(1,HeliV13.stage(model_root))
            HeliV13.set_stage(model_root,_heli_damage_stage)
        elif kind=="hit_explosive":
            _heli_damage_stage=maxi(2,HeliV13.stage(model_root))
            HeliV13.set_stage(model_root,_heli_damage_stage)
    _heli_animation=kind
    _heli_playback_speed=clampf(speed,0.25,2.0)
    _heli_time=0.0
    var native_kind: String="hover" if kind=="fire_missiles" else kind
    if HeliV13.has_model(model_root):
        HeliV13.pose(model_root,native_kind,0.0)
        if HeliCombatV14.has_model(model_root):
            HeliCombatV14.pose(model_root,kind,0.0)
    else:
        HeliV1.pose(model_root,native_kind,0.0)
    _update_details()

func _heli_stop(force_restore: bool=false) -> void:
    _heli_animation=""
    _heli_time=0.0
    _heli_playback_speed=1.0
    if model_root!=null and HeliCombatV14.has_model(model_root):
        HeliCombatV14.pose(model_root,"idle",0.0)
    # Ending preview must NOT magically levitate a destroyed helicopter.
    if _heli_wreck_frozen and not force_restore:
        return
    if model_root!=null and HeliV13.has_model(model_root):
        HeliV13.restore(model_root)
    elif model_root!=null and HeliV1.has_model(model_root):
        HeliV1.restore(model_root)

func _install_p06_controls() -> void:
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    p06_controls = VBoxContainer.new()
    p06_controls.name = "BastionP06_V25_CarcasasCerradas"
    p06_controls.add_theme_constant_override("separation",8)
    column.add_child(p06_controls)
    var heading: Label = _title(p06_controls,
        "BASTIÓN P06 · V25 · CARCASA CERRADA Y RIN",14)
    heading.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(p06_controls,"Movimiento 6×6",func(): _play("move"),
        "Torreta",func(): _play("turn_turret"))
    _add_paired(p06_controls,"Giro con dirección 6×6",
        func(): _play("move_turn"),"Movimiento recto",func(): _play("move"))
    _add_paired(p06_controls,"Ráfaga de ametralladora (6)",func(): _play("attack"),
        "Detener",_stop_animation)
    _add_paired(p06_controls,"Impacto de balas",func(): _play("hit_bullet"),
        "Explosión",func(): _play("hit_explosive"))
    _add_paired(p06_controls,"Vista frontal",func(): _view_p06_angle(0.0),
        "Vista 3/4 delantera",func(): _view_p06_angle(38.0))
    _add_paired(p06_controls,"Acercamiento a la torreta",_inspect_p06_turret,
        "Vista óptica opuesta",func(): _view_p06_angle(-42.0))
    _add_paired(p06_controls,"Inspeccionar junta frontal",_inspect_p06_front_joint,
        "Inspeccionar junta trasera",_inspect_p06_rear_joint)
    _add_paired(p06_controls,"Ver unión superior V17",_inspect_p06_roof_v17,
        "Ver cierres rampa V17",_inspect_p06_ramp_v17)
    _add_paired(p06_controls,"Vista lateral",func(): _view_p06_angle(90.0),
        "Vista trasera",func(): _view_p06_angle(180.0))
    _add_paired(p06_controls,"Examinar ruedas 6×6",_inspect_p06_wheels,
        "Examinar suspensión",_inspect_p06_suspension)
    _add_paired(p06_controls,"V18: faldones entre ejes",_inspect_p06_skirts_v18,
        "V18: daño lateral crítico",_inspect_p06_critical_v18)
    _add_paired(p06_controls,"V19: uniones entre faldones",_inspect_p06_seams_v19,
        "V19: sellos de rueda",_inspect_p06_seals_v19)
    _add_paired(p06_controls,"V19: anclajes suspensión",_inspect_p06_mounts_v19,
        "V19: daño lateral",_inspect_p06_damage_v19)
    _add_paired(p06_controls,"V20: inspeccionar soldaduras",_inspect_p06_welds_v20,
        "V20: tornillos y arandelas",_inspect_p06_bolts_v20)
    _add_paired(p06_controls,"V20: daño medio y costuras",_inspect_p06_medium_v20,
        "V20: fracturas críticas",_inspect_p06_critical_v20)
    _add_paired(p06_controls,"V21: pintura y acero",_inspect_p06_paint_v21,
        "V21: caucho y metal",_inspect_p06_rubber_v21)
    _add_paired(p06_controls,"V21: pintura desgastada",_inspect_p06_wear_v21,
        "V21: metal quemado",_inspect_p06_burnt_v21)
    _add_paired(p06_controls,"V22: clima despejado",func(): _set_p06_weather_v22("clear"),
        "V22: lluvia húmeda",func(): _set_p06_weather_v22("rain"))
    _add_paired(p06_controls,"V22: nieve y escarcha",func(): _set_p06_weather_v22("snow"),
        "V22: luz de día",func(): _set_p06_light_v22(0))
    _add_paired(p06_controls,"V22: atardecer",func(): _set_p06_light_v22(1),
        "V22: noche",func(): _set_p06_light_v22(2))
    _add_paired(p06_controls,"V23: dibujo de neumáticos",_inspect_p06_tread_v23,
        "V23: flanco y talón",_inspect_p06_sidewall_v23)
    _add_paired(p06_controls,"V23: ruedas lado opuesto",_inspect_p06_opposite_v23,
        "V23: nieve en neumáticos",_inspect_p06_snow_v23)
    _add_paired(p06_controls,"V24: transición de hombros",_inspect_p06_shoulders_v24,
        "V24: microsurcos flancos",_inspect_p06_sidegrooves_v24)
    _add_paired(p06_controls,"V24: guardabarros estancos",_inspect_p06_arch_lips_v24,
        "V24: juntas con lluvia",_inspect_p06_wet_lips_v24)
    _add_paired(p06_controls,"V25: ambos flancos cerrados",_inspect_p06_sealed_v25,
        "V25: cara interna y freno",_inspect_p06_inside_v25)
    _add_paired(p06_controls,"V25: seis ruedas completas",_inspect_p06_six_v25,
        "V25: huecos resueltos",_inspect_p06_gap_v25)
    _add_paired(p06_controls,"Vista inferior completa",_inspect_p06_underside,
        "Acercamiento a transmisión",_inspect_p06_transfer)
    _add_paired(p06_controls,"Vista 3/4 trasera",func(): _view_p06_angle(145.0),
        "Rampa y compartimento",func(): _view_p06_angle(180.0))
    p06_ramp_button = _button(p06_controls,"Abrir rampa de tropas",
        _toggle_p06_ramp)
    _add_paired(p06_controls,"Destrucción",func(): _set_damage(4),
        "Reparar completamente",func(): _set_damage(0))
    p06_version_button = _button(p06_controls,"Comparar acabado V3 / V25",
        _toggle_p06_version)
    _add_paired(p06_controls,
        "Prueba 8 vehículos",func(): _show_p06_fleet(8),
        "Prueba 32 vehículos",func(): _show_p06_fleet(32))
    _add_paired(p06_controls,
        "Prueba 64 vehículos",func(): _show_p06_fleet(64),
        "Volver al Bastión V25",_hide_p06_fleet)
    _add_paired(p06_controls,
        "LOD cerca",func(): _set_p06_fleet_quality(0),
        "LOD medio",func(): _set_p06_fleet_quality(1))
    _add_paired(p06_controls,
        "LOD lejos",func(): _set_p06_fleet_quality(2),
        "LOD automático",func(): _set_p06_fleet_quality(-1))
    _add_paired(p06_controls,
        "Flota en marcha",func(): _animate_p06_fleet("move_turn"),
        "Flota disparando",func(): _animate_p06_fleet("attack"))
    p06_hint = _title(p06_controls,
        "V25: reconstrucción cerrada de las seis carcasas sobre el eje correcto X; "
        + "flancos sellados con los rines y respaldo oscuro de frenos. "
        + "Desaparecen los huecos del neumático desalineado V2.",12)
    var index: int = column.get_children().find(detail_label)
    column.move_child(p06_controls,maxi(0,index))
    p06_controls.visible = false


# Only the G13 Studio preview receives reflection radiance. A built-in
# procedural sky lights real metallic StandardMaterial3D surfaces without
# changing the visible neutral background, any battle scene or other units.
func _g13_v53_set_reflections(enabled: bool) -> void:
    if preview==null or hq_environment==null or (
            hq_environment.environment==null):
        return
    var env: Environment = hq_environment.environment
    if enabled:
        if _role!="aa_mobile" or model_root==null or (
                not bool(model_root.get_meta(G13RealismV53.FLAG,false))):
            return
        if _g13_reflection_saved_v53.is_empty():
            _g13_reflection_saved_v53={
                "sky":env.sky,
                "source":env.reflected_light_source
            }
        var sky:=Sky.new()
        var gradient:=ProceduralSkyMaterial.new()
        gradient.sky_top_color=Color("#89acc5")
        gradient.sky_horizon_color=Color("#e1e9ed")
        gradient.ground_bottom_color=Color("#29343b")
        gradient.ground_horizon_color=Color("#9fb2bc")
        gradient.use_debanding=true
        sky.sky_material=gradient
        env.sky=sky
        env.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
        if _g13_rim_light_v53==null:
            _g13_rim_light_v53=DirectionalLight3D.new()
            _g13_rim_light_v53.name="G13V53_LuzRasantePBR"
            _g13_rim_light_v53.rotation_degrees=Vector3(-26.0,122.0,0.0)
            _g13_rim_light_v53.light_color=Color("#c4dce9")
            _g13_rim_light_v53.light_energy=0.54
            _g13_rim_light_v53.shadow_enabled=false
            preview.add_child(_g13_rim_light_v53)
        _g13_rim_light_v53.visible=true
    else:
        if not _g13_reflection_saved_v53.is_empty():
            env.sky=_g13_reflection_saved_v53["sky"]
            env.reflected_light_source=_g13_reflection_saved_v53["source"]
            _g13_reflection_saved_v53.clear()
        if _g13_rim_light_v53!=null:
            _g13_rim_light_v53.visible=false

func _g13_v69_show_muzzle(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V69: bocachas y anclajes todavía no cargados."
        return
    if G13MuzzleV69.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V69 · bocachas abiertas, cañones escalonados y pernos exteriores"
                if enabled else
                "G13 V68 · comparación con bocachas y cañones anteriores")

func _g13_v68_show_ejection(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13EjectorV68.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V68: guías de expulsión sin cargar."
        return
    # V69 replaces the same gun surfaces first refinished by V68.
    if bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
        G13MuzzleV69.show_finish(model_root,false)
    if G13EjectorV68.show_finish(model_root,enabled):
        if enabled and bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
            G13MuzzleV69.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V68 · guías de casquillos, nervios biselados y acero mecanizado"
                if enabled else
                "G13 V67 · comparar expulsión de casquillos anterior")

func _g13_v67_show_feed(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13FeedV67.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V67: recámara y tapas de alimentación sin cargar."
        return
    # V69 changes the twin gun steel; remove the latest pass first.
    if bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
        G13MuzzleV69.show_finish(model_root,false)
    # V68 also owns the top ejection covers and Android moving cheek.
    # Remove that coat before showing the previous V67 geometry.
    if bool(model_root.get_meta(G13EjectorV68.FLAG,false)):
        G13EjectorV68.show_finish(model_root,false)
    if G13FeedV67.show_finish(model_root,enabled):
        if enabled and bool(model_root.get_meta(G13EjectorV68.FLAG,false)):
            G13EjectorV68.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
            G13MuzzleV69.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V67 · recámara y registros de alimentación biselados"
                if enabled else
                "G13 V66 · comparar tapas y registros de alimentación anteriores")

func _g13_v66_show_mount(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13MountV66.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V66: soportes de cañones no cargados."
        return
    # V69, V68 and V67 layered materials must be undone in reverse.
    if bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
        G13MuzzleV69.show_finish(model_root,false)
    # V68 and V67 share the existing moving cheek; compare V66 only
    # after removing both later layers in reverse build order.
    if bool(model_root.get_meta(G13EjectorV68.FLAG,false)):
        G13EjectorV68.show_finish(model_root,false)
    if bool(model_root.get_meta(G13FeedV67.FLAG,false)):
        G13FeedV67.show_finish(model_root,false)
    if G13MountV66.show_finish(model_root,enabled):
        if enabled and bool(model_root.get_meta(G13FeedV67.FLAG,false)):
            G13FeedV67.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13EjectorV68.FLAG,false)):
            G13EjectorV68.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13MuzzleV69.FLAG,false)):
            G13MuzzleV69.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V66 · rodamientos abiertos y collares de acero mecanizado"
                if enabled else
                "G13 V65 · comparación con soportes anteriores")

func _g13_v65_show_ring(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13RingV65.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V65: anillo de giro no cargado."
        return
    if G13RingV65.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V65 · anillo segmentado con 12 biseles de acero"
                if enabled else
                "G13 V64 · comparar unión de torreta anterior")

func _g13_v64_show_edges(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13EdgesV64.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V64: juntas blindadas no cargadas."
        return
    if G13EdgesV64.show_finish(model_root,enabled):
        # V64 owns the same original V44 rotating ring material.
        # Restore the later V65 on top after historical comparisons.
        if bool(model_root.get_meta(G13RingV65.FLAG,false)):
            G13RingV65.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V64 · biseles reales en placas y escotillas, pernos asentados"
                if enabled else
                "G13 V63 · comparación antes del remate de bordes")

func _g13_v63_show_faction(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13FactionV63.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V63: placas de facción sin cargar."
        return
    if G13FactionV63.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V63 · placas visibles sobre blindaje, torreta y techo"
                if enabled else
                "G13 V59 · comparación con identificación de facción anterior")

func _g13_v62_show_glass(enabled:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13GlassV62.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V62: reflejos del cristal todavía no cargados."
        return
    if G13GlassV62.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V62 · vidrios de seguridad con reflejos ópticos direccionales"
                if enabled else
                "G13 V59 · comparación con reflejo de cristal anterior")

func _g13_v61_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13WheelArmorV61.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V61: rines mecanizados no cargados."
        return
    if G13WheelArmorV61.show_finish(model_root,enabled):
        # Preserve the later faceted V64 armor treatment when comparing
        # the older V61 rotating hubs in the shared studio.
        if bool(model_root.get_meta(G13EdgesV64.FLAG,false)):
            G13EdgesV64.show_finish(model_root,true)
        if bool(model_root.get_meta(G13RingV65.FLAG,false)):
            G13RingV65.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V61 · ocho radios realmente abiertos, 32 pernos y blindaje PBR"
                if enabled else
                "G13 V60 · comparación con discos macizos anteriores")

func _g13_v60_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13TreadV60.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V60: banda continua no cargada."
        return
    if G13TreadV60.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V60 · 160 tacos distribuidos por rueda y flancos moldeados"
                if enabled else
                "G13 V59 · comparación con los tacos agrupados anteriores")

func _g13_v59_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13PremiumV59.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V59: neumáticos y cristales no cargados."
        return
    # V64 owns the latest V44/V45 steel geometry, coatings and fittings.
    if not enabled and bool(model_root.get_meta(G13EdgesV64.FLAG,false)):
        G13EdgesV64.show_finish(model_root,false)
    # V63 owns V32/V44/V45 existing enamel surfaces and badge positions.
    if not enabled and bool(model_root.get_meta(G13FactionV63.FLAG,false)):
        G13FactionV63.show_finish(model_root,false)
    # V62 owns the newest pane finish: hide it before historical V59.
    if not enabled and bool(model_root.get_meta(G13GlassV62.FLAG,false)):
        G13GlassV62.show_finish(model_root,false)
    # V61 also owns the latest machined hub. Restore all comparison
    # layers in historical sequence to prevent mixed older materials.
    if not enabled and bool(model_root.get_meta(G13WheelArmorV61.FLAG,false)):
        G13WheelArmorV61.show_finish(model_root,false)
    # V60 owns the final tire mesh. Expose V59 before V58, and restore
    # V60 AFTER V59 so switching old comparisons never destroys the wheel.
    if not enabled and bool(model_root.get_meta(G13TreadV60.FLAG,false)):
        G13TreadV60.show_finish(model_root,false)
    if G13PremiumV59.show_finish(model_root,enabled):
        if enabled and bool(model_root.get_meta(G13TreadV60.FLAG,false)):
            G13TreadV60.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13WheelArmorV61.FLAG,false)):
            G13WheelArmorV61.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13GlassV62.FLAG,false)):
            G13GlassV62.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13FactionV63.FLAG,false)):
            G13FactionV63.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13EdgesV64.FLAG,false)):
            G13EdgesV64.show_finish(model_root,true)
        if enabled and bool(model_root.get_meta(G13RingV65.FLAG,false)):
            G13RingV65.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V59 · neumáticos esculpidos, cristales reflectantes y facción"
                if enabled else
                "G13 V58 · comparación de malla y acabados anteriores")

func _g13_v58_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13IsoV58.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V58: acabado isométrico solo para la G13."
        return
    if G13IsoV58.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V58 · acero y uniones mates; reflejos coherentes en vista isométrica"
                if enabled else
                "G13 V57 · materiales mecánicos originales para comparar")

func _g13_v57_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13VisibleV57.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V57: soportes exteriores no disponibles."
        return
    if G13VisibleV57.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V57 · soportes visibles en ambas calidades; LOD8 agrupado"
                if enabled else
                "G13 V56 · comparación con los soportes exteriores ocultos")

func _g13_v56_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13JointV56.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V56: disponible solo en detalle LOD13."
        return
    if G13JointV56.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V56 · amortiguadores, bulones y aro giratorio integrados"
                if enabled else
                "G13 V55 · comparación con articulaciones mecánicas anteriores")

func _g13_v55_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13MicroV55.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V55: disponible en el modelo 3D detallado LOD13."
        return
    if G13MicroV55.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V55 · acabado físico del acero, pintura y juntas de panel"
                if enabled else
                "G13 V54 · materiales anteriores y juntas ocultas")

func _g13_v54_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if not bool(model_root.get_meta(G13RubberV54.FLAG,false)):
        if status_label!=null:
            status_label.text="G13 V54 solo disponible en detalle LOD13."
        return
    if G13RubberV54.show_finish(model_root,enabled):
        if status_label!=null:
            status_label.text=(
                "G13 V54 · caucho redondeado y tacos 3D auténticos"
                if enabled else
                "G13 V53 · ruedas anteriores, misma cámara y animación")

func _g13_v53_show_finish(enabled: bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    # Prevent the older V53 button from leaving the V55 panel finish
    # painted over its own historical V47/V52 reference materials.
    var has_v55:bool=bool(model_root.get_meta(G13MicroV55.FLAG,false))
    if has_v55:
        G13MicroV55.show_finish(model_root,false)
    if G13RealismV53.show_finish(model_root,enabled):
        if enabled and has_v55:
            G13MicroV55.show_finish(model_root,true)
        if status_label!=null:
            status_label.text=(
                "G13 V55 · metal y pintura PBR, juntas y microacabados"
                if enabled else
                "G13 V52 · comparación histórica de materiales")
        _update_details()

func _install_g13_controls() -> void:
    var column:=role_picker.get_parent() as VBoxContainer
    g13_controls=VBoxContainer.new()
    g13_controls.name="G13_AntiaereoMovil_V4_DosTiposDeAtaque"
    g13_controls.add_theme_constant_override("separation",8)
    column.add_child(g13_controls)
    var title: Label=_title(g13_controls,
        "G13 V69 · BOCACHAS Y ANCLAJES MECANIZADOS",14)
    title.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(g13_controls,"Barrido del radar",
        func(): _g13_demo_v1("scan",0.78),
        "Orientación de cañones",
        func(): _g13_demo_v1("aim",0.72))
    _add_paired(g13_controls,"Rodaje 4×4",
        func(): _g13_demo_v1("move",0.46),
        "Restaurar posición",
        func(): _g13_demo_v1("idle",1.0))
    _add_paired(g13_controls,"V4 · Ataque terrestre",
        func(): _g13_attack_v4("attack_ground"),
        "V4 · Ataque antiaéreo",
        func(): _g13_attack_v4("attack_air"))
    _add_paired(g13_controls,"V23 · Mostrar faros nuevos",
        func(): _g13_v23_show_lights(false),
        "V23 · Comparar con V22",
        func(): _g13_v23_show_lights(true))
    _add_paired(g13_controls,"V24 · Rejilla frontal 3D",
        func(): _g13_v24_show_intake(),
        "V24 · Comparar frontal V23",
        func(): _g13_v23_show_lights(false))
    _add_paired(g13_controls,"V52 · Ver modelo táctico LOD8",
        func(): _g13_show_tactical_lod(8),
        "V24 · Volver al detalle LOD13",
        func(): _g13_show_tactical_lod(13))
    _add_paired(g13_controls,"LOD8 · Mostrar V26 completa",
        func(): _g13_v25_compare(false),
        "LOD8 · Comparar con original",
        func(): _g13_v25_compare(true))
    _add_paired(g13_controls,"V26 · Blindaje táctico angular",
        func(): _g13_v26_compare(false),
        "V26 · Comparar blindaje V25",
        func(): _g13_v26_compare(true))
    _add_paired(g13_controls,"V27 · Mostrar radar alto 3D",
        func(): _g13_v27_compare(false),
        "V27 · Comparar radar V26",
        func(): _g13_v27_compare(true))
    _add_paired(g13_controls,"V28 · Soporte de radar al techo",
        func(): _g13_v28_compare(false),
        "V28 · Comparar soporte V27",
        func(): _g13_v28_compare(true))
    _add_paired(g13_controls,"V29 · Ataque terrestre hacia atrás",
        func(): _g13_v29_rear_attack("attack_ground"),
        "V29 · Ataque aéreo hacia atrás",
        func(): _g13_v29_rear_attack("attack_air"))
    _add_paired(g13_controls,"V69 · Bocachas y soportes exteriores 3D",
        func(): _g13_v69_show_muzzle(true),
        "V69 · Comparar bocachas anteriores",
        func(): _g13_v69_show_muzzle(false))
    _add_paired(g13_controls,"V68 · Guías de expulsión y acero de cañones",
        func(): _g13_v68_show_ejection(true),
        "V68 · Comparar acabado anterior",
        func(): _g13_v68_show_ejection(false))
    _add_paired(g13_controls,"V67 · Tapas y acceso de recámara",
        func(): _g13_v67_show_feed(true),
        "V67 · Comparar con recámara anterior",
        func(): _g13_v67_show_feed(false))
    _add_paired(g13_controls,"V66 · Soportes de cañones mecanizados",
        func(): _g13_v66_show_mount(true),
        "V66 · Comparar soportes anteriores",
        func(): _g13_v66_show_mount(false))
    _add_paired(g13_controls,"V65 · Anillo giratorio mecanizado",
        func(): _g13_v65_show_ring(true),
        "V65 · Comparar unión anterior",
        func(): _g13_v65_show_ring(false))
    _add_paired(g13_controls,"V64 · Juntas y biseles de acero",
        func(): _g13_v64_show_edges(true),
        "V64 · Comparar blindaje anterior",
        func(): _g13_v64_show_edges(false))
    _add_paired(g13_controls,"V63 · Placas de facción visibles",
        func(): _g13_v63_show_faction(true),
        "V63 · Comparar identificación anterior",
        func(): _g13_v63_show_faction(false))
    _add_paired(g13_controls,"V62 · Cristal óptico y reflejo angular",
        func(): _g13_v62_show_glass(true),
        "V62 · Comparar con cristal anterior",
        func(): _g13_v62_show_glass(false))
    _add_paired(g13_controls,"V61 · Ocho radios abiertos y acero real",
        func(): _g13_v61_show_finish(true),
        "V61 · Comparar con centro plano V60",
        func(): _g13_v61_show_finish(false))
    _add_paired(g13_controls,"V60 · Banda continua real (160 tacos)",
        func(): _g13_v60_show_finish(true),
        "V60 · Comparar con tacos separados V59",
        func(): _g13_v60_show_finish(false))
    _add_paired(g13_controls,"V59 · Caucho, cristal y facción reales",
        func(): _g13_v59_show_finish(true),
        "V59 · Comparar neumáticos y vidrios V58",
        func(): _g13_v59_show_finish(false))
    _add_paired(g13_controls,"V58 · Metales mecánicos unificados",
        func(): _g13_v58_show_finish(true),
        "V58 · Comparar con V57",
        func(): _g13_v58_show_finish(false))
    _add_paired(g13_controls,"V57 · Soportes exteriores integrados",
        func(): _g13_v57_show_finish(true),
        "V57 · Comparar con V56",
        func(): _g13_v57_show_finish(false))
    _add_paired(g13_controls,"V56 · Uniones mecánicas completas",
        func(): _g13_v56_show_finish(true),
        "V56 · Comparar con V55",
        func(): _g13_v56_show_finish(false))
    _add_paired(g13_controls,"V55 · Metales, pintura y juntas",
        func(): _g13_v55_show_finish(true),
        "V55 · Comparar acabado V54",
        func(): _g13_v55_show_finish(false))
    _add_paired(g13_controls,"V54 · Neumáticos esculpidos",
        func(): _g13_v54_show_finish(true),
        "V54 · Comparar ruedas V53",
        func(): _g13_v54_show_finish(false))
    _add_paired(g13_controls,"V53 · Materiales y neumáticos",
        func(): _g13_v53_show_finish(true),
        "V53 · Comparar acabado V52",
        func(): _g13_v53_show_finish(false))
    _add_paired(g13_controls,"V52 · Hombros del techo integrados",
        func(): _g13_v52_compare(true),
        "V52 · Comparar con V51",
        func(): _g13_v52_compare(false))
    _add_paired(g13_controls,"V51 · Techo y visera integrados",
        func(): _g13_v51_compare(true),
        "V51 · Comparar con V50",
        func(): _g13_v51_compare(false))
    _add_paired(g13_controls,"V50 · Cristales integrados 3D",
        func(): _g13_v50_compare(true),
        "V50 · Comparar con V49",
        func(): _g13_v50_compare(false))
    _add_paired(g13_controls,"V49 · Contornos integrados 3D",
        func(): _g13_v49_compare(true),
        "V49 · Comparar con V48",
        func(): _g13_v49_compare(false))
    _add_paired(g13_controls,"V48 · Silueta blindada refinada",
        func(): _g13_v48_compare(true),
        "V48 · Comparar con V47",
        func(): _g13_v48_compare(false))
    _add_paired(g13_controls,"V47 · Materiales PBR refinados",
        func(): _g13_v47_compare(true),
        "V47 · Comparar con V46",
        func(): _g13_v47_compare(false))
    _add_paired(g13_controls,"V46 · Llantas mecanizadas 3D",
        func(): _g13_v46_compare(true),
        "V46 · Comparar con V45",
        func(): _g13_v46_compare(false))
    _add_paired(g13_controls,"V45 · Cabina y puertas 3D",
        func(): _g13_v45_compare(true),
        "V45 · Comparar con V44",
        func(): _g13_v45_compare(false))
    _add_paired(g13_controls,"V44 · Blindaje y pintura real 3D",
        func(): _g13_v44_compare(true),
        "V44 · Comparar con V43",
        func(): _g13_v44_compare(false))
    _add_paired(g13_controls,"V42 · Puntas curvas integradas",
        func(): _g13_v42_compare(true),
        "V42 · Comparar con V41",
        func(): _g13_v42_compare(false))
    _add_paired(g13_controls,"V41 · Perfil de ruedas afinado",
        func(): _g13_v41_compare(true),
        "V41 · Comparar con V40",
        func(): _g13_v41_compare(false))
    _add_paired(g13_controls,"V43 · Frente",func(): _g13_v41_view(0.0),
        "V43 · 3/4 delantero",func(): _g13_v41_view(38.0))
    _add_paired(g13_controls,"V43 · Costado izquierdo",func(): _g13_v41_view(90.0),
        "V43 · 3/4 trasero",func(): _g13_v41_view(145.0))
    _add_paired(g13_controls,"V43 · Parte trasera",func(): _g13_v41_view(180.0),
        "V43 · Costado derecho",func(): _g13_v41_view(270.0))
    # Verified against V51 native PNGs: the old tilt signs were reversed,
    # showing the undercarriage under "Ver techo" and vice versa.
    _add_paired(g13_controls,"V52 · Ver techo",func(): _g13_v41_view(42.0,58.0),
        "V52 · Ver bajos",func(): _g13_v41_view(132.0,-55.0))
    _add_paired(g13_controls,"V40 · Guardabarros curvos",
        func(): _g13_v40_compare(true),
        "V40 · Comparar con V39",
        func(): _g13_v40_compare(false))
    _add_paired(g13_controls,"V39 · Sellos y herrajes exteriores",
        func(): _g13_v39_compare(true),
        "V39 · Comparar con V38",
        func(): _g13_v39_compare(false))
    _add_paired(g13_controls,"V38 · Uniones exteriores de blindaje",
        func(): _g13_v38_compare(true),
        "V38 · Comparar con V37",
        func(): _g13_v38_compare(false))
    _add_paired(g13_controls,"V37 · Mostrar techo, capó y radar",
        func(): _g13_v37_compare(true),
        "V37 · Comparar con V36",
        func(): _g13_v37_compare(false))
    _add_paired(g13_controls,"V36 · Uniones de arcos y zaga",
        func(): _g13_v36_compare(true),
        "V36 · Comparar con V35",
        func(): _g13_v36_compare(false))
    _add_paired(g13_controls,"V35 · Mostrar escapes y compuertas",
        func(): _g13_v35_compare(true),
        "V35 · Comparar con V34",
        func(): _g13_v35_compare(false))
    _add_paired(g13_controls,"V34 · Mostrar acabados del chasis",
        func(): _g13_v34_compare(true),
        "V34 · Comparar con V33",
        func(): _g13_v34_compare(false))
    _add_paired(g13_controls,"V33 · Mostrar pasos de rueda y bisagras",
        func(): _g13_v33_compare(true),
        "V33 · Comparar con V32",
        func(): _g13_v33_compare(false))
    _add_paired(g13_controls,"V32 · Más color de facción",
        func(): _g13_v32_compare(true),
        "V32 · Comparar acabado anterior",
        func(): _g13_v32_compare(false))
    _add_paired(g13_controls,"V31 · Mostrar soportes de cañones",
        func(): _g13_v31_compare(true),
        "V31 · Comparar con V30",
        func(): _g13_v31_compare(false))
    _add_paired(g13_controls,"V29 · Plegar radar para inspección",
        func(): _g13_v29_fold(true),
        "V29 · Desplegar radar",
        func(): _g13_v29_fold(false))
    _add_paired(g13_controls,"V17 · Medir FPS en Android",
        func(): _g13_start_android_test(),
        "V17 · Ver política LOD",
        func(): _g13_lod_status())
    _title(g13_controls,
        "V4: el mismo G13 dispara a tierra con cañones bajos y "
        + "ráfagas más espaciadas, o al aire con elevación alta, "
        + "radar de seguimiento y cadencia más rápida. Destellos, "
        + "humo transparente y retroceso mínimo de los dos cañones. "
        + "Es una simulación visual: aún no ejecuta daño en batalla.",12)
    g13_controls.visible=false

func _g13_show_tactical_lod(art_level:int)->void:
    if _role!="aa_mobile" or art_level not in [8,13]:
        return
    _g13_preview_lod=art_level
    _g13_v25_show_original=false
    _g13_v26_show_previous=false
    _g13_v27_show_previous=false
    _g13_v28_show_previous=false
    _display_role("aa_mobile")
    if status_label!=null:
        status_label.text=(
            "G13 V61 LOD8: rines abiertos optimizados; banda V60 intacta. "
            + "Capturas reales pendientes de verificar."
            if art_level==8 else
            "G13 V61 LOD13: radios abiertos, PBR real y caucho V60 intacto.")

func _g13_v25_compare(show_v1:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    # The original LOD8 comparison removes BOTH V25 paint/barrel tweaks
    # and V26 faceted shapes while keeping camera, faction and pose fixed.
    var guns:bool=false
    var armor:bool=false
    var radar:bool=false
    var deck:bool=G13DeckV28.show_v27_reference(model_root,true)
    if show_v1:
        # Undo newest-to-oldest geometry, preserving true original dish.
        radar=G13RadarV27.show_v26_reference(model_root,true)
        armor=G13ArmorV26.show_v25_reference(model_root,true)
        guns=G13TacticalV25.show_v1_reference(model_root,true)
    else:
        # Restore original-to-latest order so V27 keeps its actual .445 dish.
        guns=G13TacticalV25.show_v1_reference(model_root,false)
        armor=G13ArmorV26.show_v25_reference(model_root,false)
        radar=G13RadarV27.show_v26_reference(model_root,false)
        deck=G13DeckV28.show_v27_reference(model_root,false)
    if guns and armor and radar and deck:
        _g13_v25_show_original=show_v1
        _g13_v26_show_previous=show_v1
        _g13_v27_show_previous=show_v1
        _g13_v28_show_previous=show_v1
        status_label.text=(
            "G13 LOD8 original: mismas ruedas, cámara y poses."
            if show_v1 else
            "G13 V28 LOD8: blindaje, cañones y radar anclado al techo.")
    else:
        status_label.text="Selecciona primero vista táctica LOD8."

func _g13_v26_compare(show_v25:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    # Always compare two complete LOD8 stages with original paint,
    # camera, faction, radar and gun pose held constant.
    if G13DeckV28.show_v27_reference(model_root,true) and (
            G13TacticalV25.show_v1_reference(model_root,false)) and (
            G13ArmorV26.show_v25_reference(model_root,show_v25)) and (
            G13RadarV27.show_v26_reference(model_root,true)):
        _g13_v25_show_original=false
        _g13_v26_show_previous=show_v25
        _g13_v27_show_previous=true
        _g13_v28_show_previous=true
        status_label.text=(
            "G13 V25 LOD8: cabina y torreta rectangulares originales."
            if show_v25 else
            "G13 V26 LOD8: 3 piezas de blindaje biselado, sin nuevos nodos.")
    else:
        status_label.text="Selecciona antes el G13 táctico LOD8."

func _g13_v27_compare(show_v26:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    # Physical same-camera comparison of full V26 vs V27, retaining the
    # unchanged original twin gun rig, faction and all existing poses.
    var deck:bool=G13DeckV28.show_v27_reference(model_root,true)
    var guns:bool=G13TacticalV25.show_v1_reference(model_root,false)
    var armor:bool=G13ArmorV26.show_v25_reference(model_root,false)
    var radar:bool=G13RadarV27.show_v26_reference(model_root,show_v26)
    if guns and armor and radar and deck:
        _g13_v25_show_original=false
        _g13_v26_show_previous=false
        _g13_v27_show_previous=show_v26
        _g13_v28_show_previous=true
        status_label.text=(
            "G13 V26: radar original, mismo blindaje y misma cámara."
            if show_v26 else
            "G13 V27: radar elevado y plato 3D ancho; 0 nodos adicionales.")
    else:
        status_label.text="Selecciona primero el G13 táctico LOD8."

func _g13_v28_compare(show_v27:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    var guns:bool=G13TacticalV25.show_v1_reference(model_root,false)
    var armor:bool=G13ArmorV26.show_v25_reference(model_root,false)
    var radar:bool=G13RadarV27.show_v26_reference(model_root,false)
    var deck:bool=G13DeckV28.show_v27_reference(model_root,show_v27)
    if guns and armor and radar and deck:
        _g13_v25_show_original=false
        _g13_v26_show_previous=false
        _g13_v27_show_previous=false
        _g13_v28_show_previous=show_v27
        status_label.text=(
            "G13 V27: mástil elevado sin soporte anclado al techo."
            if show_v27 else
            "G13 V28: mástil blindado con base apoyada en cubierta trasera.")
    else:
        status_label.text="Selecciona primero el G13 táctico LOD8."

func _g13_v41_view(yaw:float, tilt:float=0.0)->void:
    if _role!="aa_mobile" or model_root==null:
        return
    _yaw=yaw
    model_root.rotation_degrees=Vector3(tilt,yaw,0.0)
    _update_camera()
    if status_label!=null:
        status_label.text="G13 V43: vista %.0f° / inclinación %.0f°; inspección manual." % [yaw,tilt]

func _g13_v52_compare(show_v52:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V52: selecciona primero el vehículo antiaéreo."
        return
    var ok:bool=G13RoofRailsV52.show_finish(model_root,show_v52)
    if status_label!=null:
        status_label.text=(
            ("G13 V52: perfiles de los dos hombros del techo integrados."
            if show_v52 else
            "G13 V51: perfiles anteriores restaurados sin tocar las armas.")
            if ok else "G13 V52: esta versión no está disponible.")

func _g13_v51_compare(show_v51:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V51: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13RoofV51.show_finish(model_root,show_v51)
    if status_label!=null:
        status_label.text=(
            ("G13 V51: cubierta acortada y visera integrada al parabrisas."
            if show_v51 else
            "G13 V50: cubierta y visera anteriores restauradas.")
            if ok else "G13 V51: acabado no disponible en esta vista.")

func _g13_v50_compare(show_v50:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V50: selecciona primero el vehículo antiaéreo."
        return
    var ok:bool=G13GlazingV50.show_finish(model_root,show_v50)
    if status_label!=null:
        status_label.text=(
            ("G13 V50: cristales cerrados con biseles y juntas de cabina."
            if show_v50 else
            "G13 V49: cristales originales restaurados en la misma escena.")
            if ok else "G13 V50: acabado no disponible en este modelo.")

func _g13_v49_compare(show_v49:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V49: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13SeamsV49.show_finish(model_root,show_v49)
    if status_label!=null:
        status_label.text=(
            ("G13 V49: ocho niveles de cabina y torreta, techo de cinco."
            if show_v49 else
            "G13 V48: formas originales restauradas sin cambiar materiales.")
            if ok else "G13 V49: perfiles no disponibles en esta vista.")

func _g13_v48_compare(show_v48:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V48: selecciona primero el antiaéreo."
        return
    var ok:bool=G13SculptV48.show_finish(model_root,show_v48)
    if status_label!=null:
        status_label.text=(
            ("G13 V48: cabina, techo y torreta esculpidos con pintura integrada."
            if show_v48 else
            "G13 V47: mallas previas recuperadas, misma cámara y facción.")
            if ok else "G13 V48: esta reforma no se encuentra disponible.")

func _g13_v47_compare(show_v47:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V47: selecciona primero el antiaéreo."
        return
    var ok:bool=G13SurfaceV47.show_finish(model_root,show_v47)
    if status_label!=null:
        status_label.text=(
            ("G13 V47: PBR individual en blindajes, torreta, cabina y cristales."
            if show_v47 else
            "G13 V46: materiales anteriores; misma geometría y cámara.")
            if ok else "G13 V47: no hay materiales disponibles en esta vista.")

func _g13_v46_compare(show_v46:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V46: selecciona primero el antiaéreo."
        return
    var ok:bool=G13WheelV46.show_finish(model_root,show_v46)
    if status_label!=null:
        status_label.text=(
            ("G13 V46: 4 cubos mecanizados, aros de facción y pernos móviles."
            if show_v46 else
            "G13 V45: ruedas anteriores sin el refinamiento V46.")
            if ok else "G13 V46: piezas no disponibles en esta vista.")

func _g13_v45_compare(show_v45:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V45: selecciona primero el antiaéreo."
        return
    var changed:bool=G13CabV45.show_finish(model_root,show_v45)
    if status_label!=null:
        status_label.text=(
            ("G13 V45: cabina biselada, portezuelas y enfriamiento móvil reales."
            if show_v45 else
            "G13 V44: vuelve al blindaje anterior sin detalles V45.")
            if changed else "G13 V45: piezas no disponibles en esta vista.")

func _g13_v44_compare(show_v44:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V44: selecciona primero la unidad antiaérea."
        return
    var changed:bool=G13ExteriorV44.show_finish(model_root,show_v44)
    if status_label!=null:
        status_label.text=(
            ("G13 V44: escudos 3D, arcos pintados, torreta detallada y respiraderos."
            if show_v44 else
            "G13 V43: acabado anterior, sin los seis conjuntos de geometría V44.")
            if changed else
            "G13 V44: acabado no disponible en este modelo.")

func _g13_v42_compare(show_v42:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V42: selecciona primero el vehículo antiaéreo."
        return
    var ok:bool=G13ArcEndsV42.show_finish(model_root,show_v42)
    if status_label!=null:
        status_label.text=(
            ("G13 V42: arcos completos y puntas integradas al guardabarros V33."
            if show_v42 else
            "G13 V41: arcos anteriores con extremos cortados.")
            if ok else "G13 V42: esta revisión no está disponible.")

func _g13_v41_compare(show_v41:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V41: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13ContourV41.show_finish(model_root,show_v41)
    if status_label!=null:
        status_label.text=(
            ("G13 V41: guardabarros afinados y sellos biselados, mismas piezas."
            if show_v41 else
            "G13 V40: perfil radial original, misma cámara y facción.")
            if ok else "G13 V41: esta revisión no está disponible.")

func _g13_v40_compare(show_v40:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V40: selecciona primero el vehículo antiaéreo."
        return
    var ok:bool=G13FinishV40.show_finish(model_root,show_v40)
    if status_label!=null:
        status_label.text=(
            ("G13 V40: nuevos guardabarros curvos y uniones delanteras."
            if show_v40 else
            "G13 V39: referencia anterior; piezas cuadradas recuperadas en LOD13.")
            if ok else "G13 V40: acabado no disponible en esta vista.")

func _g13_v39_compare(show_v39:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V39: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13FinishV39.show_finish(model_root,show_v39)
    if status_label!=null:
        status_label.text=(
            ("G13 V39: sellos de cabina, placas delanteras y herrajes visibles."
            if show_v39 else
            "G13 V38: referencia sin las nuevas piezas V39; mismo modelo.")
            if ok else "G13 V39: acabados no disponibles en esta vista.")

func _g13_v38_compare(show_v38:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V38: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13FinishV38.show_finish(model_root,show_v38)
    if status_label!=null:
        status_label.text=(
            ("G13 V38: remates de techo, juntas blindadas y fijaciones visibles."
            if show_v38 else
            "G13 V37: comparación sin acabados V38; misma facción y rig.")
            if ok else "G13 V38: detalles no disponibles en esta vista.")

func _g13_v37_compare(show_v37:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V37: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13FinishV37.show_finish(model_root,show_v37)
    if status_label!=null:
        status_label.text=(
            ("G13 V37: remates de techo/capó y soporte fijo del radar visibles."
            if show_v37 else
            "G13 V36: comparación sin las nuevas piezas V37, misma facción.")
            if ok else "G13 V37: detalles no disponibles en esta vista.")

func _g13_v36_compare(show_v36:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V36: selecciona primero la unidad antiaérea."
        return
    var ok:bool=G13FinishV36.show_finish(model_root,show_v36)
    if status_label!=null:
        status_label.text=(
            ("G13 V36: arcos unidos al chasis, zaga afinada y escapes anclados."
            if show_v36 else
            "G13 V35: vista sin uniones V36; conserva armas, radar y facción.")
            if ok else "G13 V36: detalles no disponibles en esta vista.")

func _g13_v35_compare(show_v35:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V35: selecciona primero el modelo antiaéreo."
        return
    var ok:bool=G13RearV35.show_finish(model_root,show_v35)
    if status_label!=null:
        status_label.text=(
            ("G13 V35: tapa trasera, escapes huecos y refuerzos del eje."
            if show_v35 else
            "G13 V34: referencia anterior, misma cámara y color de facción.")
            if ok else "G13 V35: detalles no disponibles en este modelo.")

func _g13_v34_compare(show_v34:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="G13 V34: selecciona primero el antiaéreo G13."
        return
    var ok:bool=G13ClosureV34.show_finish(model_root,show_v34)
    if status_label!=null:
        status_label.text=(
            ("G13 V34: juntas, cierres, parachoques y guardas traseras visibles."
            if show_v34 else
            "G13 V33: referencia sin V34, mismas ruedas, radar y colores.")
            if ok else "G13 V34: acabado no disponible en esta vista.")

func _g13_v33_compare(show_v33:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        if status_label!=null:
            status_label.text="Selecciona primero la unidad antiaérea G13."
        return
    var ok:bool=G13ChassisV33.show_finish(model_root,show_v33)
    if status_label!=null:
        status_label.text=(
            ("G13 V33: arcos 4×4, bisagras y unión blindada de cabina visibles."
            if show_v33 else
            "G13 V32: la escultura V33 está oculta; color y cañones conservados.")
            if ok else "G13 V33: selecciona un modelo con acabado V33.")

func _g13_v32_compare(show_v32:bool)->void:
    if _role!="aa_mobile" or model_root==null:
        status_label.text="G13 V32: selecciona la unidad G13."
        return
    var ok:bool=G13FinishV32.show_finish(model_root,show_v32)
    status_label.text=(
        ("G13 V32: paneles de facción y fijaciones metálicas visibles."
        if show_v32 else
        "G13 V31/V24: vista sin nuevos detalles V32; mismo modelo y cámara.")
        if ok else "G13 V32: cambios no disponibles en este nivel de detalle.")

func _g13_v31_compare(show_v31:bool)->void:
    if _role!="aa_mobile" or model_root==null or _g13_preview_lod!=8:
        status_label.text="G13 V31: abre primero el modelo táctico LOD8."
        return
    var ok:bool=G13GunMountV31.set_detail_visible(model_root,show_v31)
    status_label.text=(
        ("G13 V31: los refuerzos giran con la elevación; dos cañones."
        if show_v31 else
        "G13 V30: referencia sin los nuevos soportes V31, mismo modelo y cámara.")
        if ok else "G13 V31: las piezas articuladas no están disponibles.")

func _g13_v29_fold(folded:bool)->void:
    if _role!="aa_mobile" or model_root==null or (
            _g13_preview_lod!=8):
        status_label.text="G13 V29: selecciona primero la vista táctico LOD8."
        return
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    P06Models.restore_model_pose("aa_mobile",model_root)
    var ok:bool=G13FoldV29.set_fold(model_root,1.0 if folded else 0.0)
    status_label.text=(
        ("G13 V29: mástil abatido desde el pie fijo en cubierta."
        if folded else "G13 V29: mástil erguido y radar de búsqueda.")
        if ok else "G13 V29: activa antes la versión táctica LOD8.")

func _g13_v29_rear_attack(kind:String)->void:
    if _role!="aa_mobile" or model_root==null or (
            _g13_preview_lod!=8) or (
            kind not in ["attack_ground","attack_air"]):
        status_label.text="Selecciona G13 en la vista táctica LOD8."
        return
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    var art:Node3D=model_root
    P06Models.restore_model_pose("aa_mobile",art)
    _g13_v29_rear_tick(0.02,art,kind)
    _g13_v4_tween=art.create_tween()
    _g13_v4_tween.tween_method(
        Callable(self,"_g13_v29_rear_tick").bind(art,kind),
        0.0,0.99,1.72)
    _g13_v4_tween.tween_callback(
        Callable(self,"_g13_v4_done").bind(art))
    status_label.text=(
        "G13 V29: giro 180°, dos cañones en ataque a tierra y radar plegado."
        if kind=="attack_ground" else
        "G13 V29: giro 180°, ataque antiaéreo y radar plegado.")

func _g13_v29_rear_tick(progress:float,art:Node3D,kind:String)->void:
    if is_instance_valid(art):
        P06Models.pose_model("aa_mobile",art,kind,progress,Vector2i(0,1))

func _g13_v23_show_lights(show_v22:bool) -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    # A V22/V23 reference must also hide the *newer* V24 intake,
    # otherwise this is no longer an honest same-model comparison.
    var previous:bool=preload(
        "res://scripts/ui/G13ArmoredIntakeV24.gd").show_v23_reference(
            model_root,true)
    var finished:bool=preload(
        "res://scripts/ui/G13FrontLightingV23.gd").compare_v22(
            model_root,show_v22)
    status_label.text=(
        ("G13 V22: frontal original y faros originales."
        if show_v22 else
        "G13 V23: biseles y lentes 3D; sin rejilla V24.")
        if finished and previous else
        "G13: selecciona vista detalle LOD13 para comparar.")

func _g13_v24_show_intake()->void:
    if _role!="aa_mobile" or model_root==null:
        return
    var lights:bool=preload(
        "res://scripts/ui/G13FrontLightingV23.gd").compare_v22(
            model_root,false)
    var intake:bool=preload(
        "res://scripts/ui/G13ArmoredIntakeV24.gd").show_v23_reference(
            model_root,false)
    status_label.text=(
        "G13 V24: cuatro lamas 3D protegidas dentro del frontal blindado."
        if lights and intake else
        "G13 V24: inspección disponible solo en detalle LOD13.")

func _g13_lod_status() -> void:
    if _role!="aa_mobile":
        return
    var mobile:bool=OS.get_name()=="Android"
    var detail:int=P06Models.recommend_g13_art_level(4.0,1,
        mobile,true,13)
    status_label.text=("G13 V17: Android LOD8 obligatorio; "
        if mobile else
        "G13 V17: vista de estudio LOD13; ")
    status_label.text+=(
        "distancia de campo + 3 unidades fuerzan LOD8. "
        + "Este G13 todavía es arte de estudio, no unidad de batalla.")

func _g13_start_android_test() -> void:
    if _role!="aa_mobile" or model_root==null:
        return
    if OS.get_name()!="Android":
        status_label.text=(
            "G13 V17: medición real de FPS solo dentro de una "
            + "compilación nativa Android; GitHub Pages utiliza Web.")
        return
    if g13_android_probe!=null and is_instance_valid(g13_android_probe):
        status_label.text="G13 V17: prueba de rendimiento ya iniciada."
        return
    var profiler:=preload("res://scripts/ui/G13AndroidPerfV17.gd").new()
    g13_android_probe=profiler
    add_child(profiler)
    profiler.finished.connect(Callable(self,"_g13_device_test_finished"))
    profiler.start_test("G13 3D Studio V17 - 1 unit",1,45,180)
    status_label.text="G13 V17: midiendo FPS reales en Android (180 fotogramas)..."

func _g13_device_test_finished(file_path:String,stats:Dictionary)->void:
    status_label.text=("G13 V17 Android: FPS medio %.1f; "
        + "frame p95 %.1f ms. Archivo: %s") % [
        float(stats.get("estimated_mean_fps",0.0)),
        float(stats.get("p95_frame_ms",0.0)),file_path]
    if g13_android_probe!=null and is_instance_valid(g13_android_probe):
        g13_android_probe.queue_free()
    g13_android_probe=null

func _g13_attack_v4(kind: String) -> void:
    if _role!="aa_mobile" or model_root==null or (
            kind not in ["attack_ground","attack_air"]):
        return
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    var art: Node3D=model_root
    P06Models.restore_model_pose("aa_mobile",art)
    # Apply the first firing pose immediately. Under llvmpipe/WebGL load,
    # the first Tween tick can arrive late and briefly show the idle 12°
    # cannon instead of the requested low 7°/high 42° firing elevation.
    _g13_v4_tick(0.01,art,kind)
    _g13_v4_tween=art.create_tween()
    _g13_v4_tween.tween_method(
        Callable(self,"_g13_v4_tick").bind(art,kind),0.0,0.99,1.60)
    _g13_v4_tween.tween_callback(
        Callable(self,"_g13_v4_done").bind(art))
    status_label.text=(
        "G13 V4 · simulación de ataque terrestre: cañones a baja elevación"
        if kind=="attack_ground" else
        "G13 V4 · simulación antiaérea: radar y cañones elevados")

func _g13_v4_tick(progress: float,art: Node3D,kind: String) -> void:
    if is_instance_valid(art):
        P06Models.pose_model("aa_mobile",art,kind,progress)

func _g13_v4_done(art: Node3D) -> void:
    if is_instance_valid(art):
        P06Models.restore_model_pose("aa_mobile",art)

func _g13_demo_v1(kind: String,progress: float) -> void:
    if _role!="aa_mobile" or model_root==null or (
            not P06Models.supports("aa_mobile")):
        return
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    if kind=="idle":
        P06Models.restore_model_pose("aa_mobile",model_root)
    elif not P06Models.pose_model("aa_mobile",model_root,kind,progress,
            Vector2i(1,-1)):
        status_label.text="G13 V1 · no se pudo aplicar la pose"
        return
    status_label.text="G13 V1 · "+(
        "radar en barrido" if kind=="scan" else
        "torreta y cañones orientados" if kind=="aim" else
        "ruedas 4×4 en movimiento" if kind=="move" else
        "disparo aéreo · demostración visual" if kind=="attack_air" else
        "disparo terrestre · demostración visual" if kind=="attack_ground" else
        "pose original restaurada"
    )+" · solo demostración 3D"

func _install_g11_controls() -> void:
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    g11_controls = VBoxContainer.new()
    g11_controls.name = "G11_Lanzador_V1_EstudioReal"
    g11_controls.add_theme_constant_override("separation",8)
    column.add_child(g11_controls)
    var heading: Label = _title(g11_controls,
        "G11 LANZADOR · V33 · REVISIÓN FINAL",14)
    heading.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(g11_controls,"Orugas en movimiento",func(): _g11_play("move"),
        "Salva de cohetes",func(): _g11_play("attack"))
    _add_paired(g11_controls,"V32: oruga izquierda en giro",
        func(): _g11_hero_turn_v32(-1),
        "V32: oruga derecha en giro",func(): _g11_hero_turn_v32(1))
    _add_paired(g11_controls,"Salva lenta x0.35",func(): _g11_play("attack",0.35),
        "Salva normal",func(): _g11_play("attack",1.0))
    _add_paired(g11_controls,"Ver enfriamiento",func(): _g11_play("cooldown",0.50),
        "Volver a reposo",_g11_stop)
    _add_paired(g11_controls,"Impacto de balas",func(): _g11_play("hit_bullet"),
        "Impacto explosivo",func(): _g11_play("hit_explosive"))
    _add_paired(g11_controls,"Daño siguiente",
        func(): _set_damage(mini(4,G11Art.stage(model_root)+1)),
        "Reparación completa",func(): _set_damage(0))
    _add_paired(g11_controls,"Daño leve · impactos",func(): _set_damage(1),
        "Daño medio · blindaje",func(): _set_damage(2))
    _add_paired(g11_controls,"Daño crítico · motor",func(): _set_damage(3),
        "Destrucción · restos",func(): _set_damage(4))
    _button(g11_controls,"Detener animación",_g11_stop)
    _button(g11_controls,"V33: comprobar acabados y trasera",_g11_final_audit_v33)
    _add_paired(g11_controls,"Vista frontal",func(): _g11_view(0.0),
        "Ver orugas y suspensión",func(): _g11_view(90.0))
    _add_paired(g11_controls,"Vista posterior",func(): _g11_view(180.0),
        "Lateral opuesto",func(): _g11_view(270.0))
    _add_paired(g11_controls,
        "V30: revisar debajo de la trasera",func(): _g11_rear_under_v30(false),
        "V30: trasera inferior 3/4",func(): _g11_rear_under_v30(true))
    _add_paired(g11_controls,"V15: trasera en 3/4",func(): _g11_view(145.0),
        "V15: blindaje opuesto",func(): _g11_view(215.0))
    _add_paired(g11_controls,"V16: frente en 3/4",func(): _g11_view(38.0),
        "V16: frente opuesto",func(): _g11_view(322.0))
    _add_paired(g11_controls,"V17: acero de las bocas",func(): _g11_view(18.0),
        "V17: pintura del techo",func(): _g11_view(70.0))
    _add_paired(g11_controls,"V17: desgaste operativo",func(): _g11_set_wear(true),
        "V17: pintura limpia",func(): _g11_set_wear(false))
    _add_paired(g11_controls,"V18: oruga izquierda",func(): _g11_track_closeup(90.0),
        "V18: oruga derecha",func(): _g11_track_closeup(270.0))
    _add_paired(g11_controls,"V18: engranaje trasero",func(): _g11_track_closeup(115.0),
        "V18: tensor delantero",func(): _g11_track_closeup(65.0))
    _add_paired(g11_controls,"V19: 3/4 izquierdo",func(): _g11_track_closeup(125.0),
        "V19: 3/4 derecho",func(): _g11_track_closeup(235.0))
    _add_paired(g11_controls,"V19: zapatas delanteras",func(): _g11_track_closeup(55.0),
        "V19: zapatas posteriores",func(): _g11_track_closeup(305.0))
    _add_paired(g11_controls,"V20: ruedas lado A",func(): _g11_track_closeup(90.0),
        "V20: ruedas lado B",func(): _g11_track_closeup(270.0))
    _add_paired(g11_controls,"V20: muelles y soportes",func(): _g11_track_closeup(105.0),
        "V20: bujes y radios",func(): _g11_track_closeup(255.0))
    _add_paired(g11_controls,"V21: anclajes lado A",func(): _g11_mount_inspect(90.0,false),
        "V21: anclajes lado B",func(): _g11_mount_inspect(270.0,false))
    _add_paired(g11_controls,"V21: suspensión inferior A",func(): _g11_mount_inspect(90.0,true),
        "V21: suspensión inferior B",func(): _g11_mount_inspect(270.0,true))
    _add_paired(g11_controls,"V22: interior lado A",func(): _g11_cutaway(1),
        "V22: interior lado B",func(): _g11_cutaway(-1))
    _add_paired(g11_controls,"V22: restaurar blindaje",func(): _g11_cutaway(0),
        "V22: anclajes con marcha",func(): _g11_play("move"))
    _add_paired(g11_controls,"V23: luz de día",func(): _set_g11_light_v23(0),
        "V23: atardecer",func(): _set_g11_light_v23(1))
    _add_paired(g11_controls,"V23: noche técnica",func(): _set_g11_light_v23(2),
        "V23: inspección pasador A",func(): _g11_joint_macro_v23(1))
    _add_paired(g11_controls,"V23: inspección pasador B",func(): _g11_joint_macro_v23(-1),
        "V23: restablecer luz",func(): _set_g11_light_v23(0))
    _add_paired(g11_controls,"V24: escala juego cercana",func(): _g11_preview_v24(10),
        "V24: escala juego lejana",func(): _g11_preview_v24(8))
    _button(g11_controls,"V24: volver a escultura 3D",func(): _g11_preview_v24(13))
    _add_paired(g11_controls,"V25: valle con unidades",func(): _g11_battle_context_v25("temperate"),
        "V25: nieve con unidades",func(): _g11_battle_context_v25("winter"))
    _add_paired(g11_controls,"V25: cañón rocoso",func(): _g11_battle_context_v25("canyon"),
        "V25: delta costero",func(): _g11_battle_context_v25("coastal"))
    _add_paired(g11_controls,"V25: acercar batalla",func(): _g11_battle_zoom_v25(true),
        "V25: alejar batalla",func(): _g11_battle_zoom_v25(false))
    _button(g11_controls,"V28: zoom intermedio de batalla",_g11_battle_mid_zoom_v28)
    _add_paired(g11_controls,
        "V29: mover G11 en batalla",func(): _g11_battle_action_v29("move"),
        "V31: salva con cohetes y humo",func(): _g11_battle_action_v29("attack"))
    _add_paired(g11_controls,"V32: giro táctico",
        func(): _g11_battle_gear_v32("turn"),
        "V32: desnivel y suspensión",
        func(): _g11_battle_gear_v32("slope"))
    _button(g11_controls,"V25: cerrar mapa de prueba",_g11_close_context_v25)
    _title(g11_controls,
        "V33: diseño principal congelado tras auditar el casco cerrado, "
        + "dos placas traseras retiradas, 92 zapatas, 12 ruedas, "
        + "pintura de facción y materiales de acero, goma y cristal. "
        + "El laboratorio Android usa por fin los LOD8/LOD10 reales "
        + "con 8, 32 y 64 unidades; el rendimiento final requiere "
        + "medición en el teléfono. Sin geometría ni shaders añadidos.",12)
    var index: int = column.get_children().find(detail_label)
    column.move_child(g11_controls,maxi(0,index))
    g11_controls.visible = false

func _g11_clear_battle_context_v25() -> void:
    if _g11_context_v25!=null and is_instance_valid(_g11_context_v25):
        if _g11_context_v25.get_parent()!=null:
            _g11_context_v25.get_parent().remove_child(_g11_context_v25)
        _g11_context_v25.queue_free()
    _g11_context_v25=null
    _g11_context_biome_v25=""
    if model_root!=null and is_instance_valid(model_root):
        model_root.visible=true

func _g11_battle_context_v25(biome: String) -> void:
    if _role!="mlrs" or not biome in [
            "temperate","winter","canyon","coastal"]:
        return
    _g11_animation=""
    _g11_clear_battle_context_v25()
    var context: Node3D=G11ContextV25.build_scene(_faction,biome)
    if context==null:
        status_label.text="G11 V25 · no se pudo cargar el mapa de batalla"
        return
    _g11_context_v25=context
    _g11_context_biome_v25=biome
    if model_root!=null:
        model_root.visible=false
    preview.add_child(context)
    _zoom=0.85
    _yaw=55.0
    _update_camera()
    status_label.text="G11 V28 · visibilidad de facción "+str(_faction+1)+"/8 · "+biome

func _g11_battle_zoom_v25(near: bool) -> void:
    if _role!="mlrs" or _g11_context_v25==null:
        return
    _zoom=2.35 if near else 0.85
    _update_camera()
    var driver := _g11_context_v25.find_child(
        "G11V25_LOD_Camara",true,false) as G11LODDriverV25
    if driver!=null and camera!=null:
        driver.update_now(camera,float(preview.size.y))
    status_label.text=("G11 V25 · batalla cercana, orugas con ruedas"
        if near else "G11 V25 · mapa alejado, silueta optimizada")

func _g11_battle_mid_zoom_v28() -> void:
    if _role!="mlrs" or _g11_context_v25==null:
        return
    _zoom=1.80
    _update_camera()
    var driver := _g11_context_v25.find_child(
        "G11V25_LOD_Camara",true,false) as G11LODDriverV25
    if driver!=null and camera!=null:
        driver.update_now(camera,float(preview.size.y))
    status_label.text="G11 V28 · zoom intermedio: acabado adaptado a cámara"

func _g11_final_audit_v33() -> void:
    if not _g11_require_hero_v24():
        return
    _g11_stop()
    var inspection: Dictionary=G11AuditV33.inspect(model_root,13)
    status_label.text=("G11 V33 · 92 zapatas, 12 ruedas, casco cerrado, "
        + "dos placas traseras eliminadas; acabado aprobado"
        if bool(inspection.get("passed",false)) else
        "G11 V33 · revisión fallida: comprobar geometría y materiales")

func _g11_hero_turn_v32(direction: int) -> void:
    if not _g11_require_hero_v24() or not G11Rig.has_rig(model_root):
        return
    _g11_animation=""
    G11Rig.pose(model_root,"move",0.47,Vector2i(
        -1 if direction<0 else 1,-1))
    status_label.text=("G11 V32 · giro: orugas a velocidades diferentes")

func _g11_battle_gear_v32(kind: String) -> void:
    if _role!="mlrs" or _g11_context_v25==null or (
            kind not in ["turn","slope"]):
        if _role=="mlrs":
            status_label.text="G11 V32 · abre un bioma para revisar el tren de rodaje"
        return
    var controller:=_g11_context_v25.find_child(
        "G11V29_AccionesBatalla",true,false) as G11ActionsV29
    var model:=_g11_context_v25.find_child(
        "Unidad3D_G11-H",true,false) as Node3D
    if controller==null or model==null:
        return
    var source: Vector3=model.position+(
        Vector3(-1.8,0.0,-1.4) if kind=="turn" else
        Vector3(1.8,0.24,-1.5))
    var heading: Vector2i=(
        Vector2i(1,-1) if kind=="turn" else Vector2i(-1,-1))
    if controller.play("G11-H","move",source,heading):
        status_label.text=("G11 V32 · giro diferencial de orugas" if
            kind=="turn" else
            "G11 V32 · inclinación y ruedas en terreno desigual")

func _g11_battle_action_v29(kind: String) -> void:
    if _role!="mlrs" or _g11_context_v25==null or (
            kind not in ["move","attack"]):
        if _role=="mlrs":
            status_label.text="G11 V29 · abre primero un bioma para probar la animación"
        return
    var actions:=_g11_context_v25.find_child(
        "G11V29_AccionesBatalla",true,false) as G11ActionsV29
    var model:=_g11_context_v25.find_child(
        "Unidad3D_G11-H",true,false) as Node3D
    if actions==null or model==null:
        status_label.text="G11 V29 · escena 3D sin lanzador disponible"
        return
    var origin: Vector3=model.position
    if kind=="move":
        origin+=Vector3(0,0,-2.4)
    if not actions.play("G11-H",kind,origin,Vector2i(2,-1)):
        status_label.text="G11 V29 · no se pudo reproducir la acción"
        return
    status_label.text=("G11 V31 · movimiento visual sin órdenes"
        if kind=="move" else
        "G11 V31 · 12 cohetes 3D, humo gradual y retroceso sin daño")

func _g11_close_context_v25() -> void:
    if _role!="mlrs":
        return
    _g11_clear_battle_context_v25()
    _g11_preview_v24(13)

func _g11_preview_v24(level: int) -> void:
    if _role!="mlrs" or (level!=8 and level!=10 and level!=13):
        return
    _g11_animation=""
    _g11_preview_lod_v24=level
    _display_role("mlrs")
    _zoom=0.86 if level==10 else (0.59 if level==8 else 1.34)
    _yaw=65.0
    if model_root!=null:
        model_root.rotation_degrees.y=_yaw
    _update_camera()
    status_label.text=("G11 · escultura V23 restaurada" if level==13
        else "G11 V24 · LOD %d real de batalla, no proxy del Estudio" % level)

func _g11_require_hero_v24() -> bool:
    if _role!="mlrs":
        return false
    if _g11_context_v25!=null:
        _g11_clear_battle_context_v25()
    if _g11_preview_lod_v24!=13:
        _g11_preview_lod_v24=13
        _display_role("mlrs")
    return model_root!=null and G11Art.has_model(model_root)

func _install_g11_lighting_v23() -> void:
    if preview==null or not _g11_lamps_v23.is_empty():
        return
    for side in [-1,1]:
        var lamp := OmniLight3D.new()
        lamp.name = "G11V23_LuzInspeccion_%d" % side
        lamp.position = Vector3(float(side)*1.72,0.75,0.20)
        lamp.omni_range = 4.6
        lamp.light_color = Color("#b5d5e6")
        lamp.light_energy = 0.90
        lamp.shadow_enabled = false
        lamp.visible = false
        preview.add_child(lamp)
        _g11_lamps_v23.append(lamp)

func _set_g11_light_v23(preset: int) -> void:
    if _role != "mlrs" or model_root == null:
        return
    _g11_light_v23 = clampi(preset,0,2)
    _apply_g11_light_v23()
    status_label.text = [
        "G11 V23 · luz diurna",
        "G11 V23 · inspección al atardecer",
        "G11 V23 · inspección nocturna con luces laterales"
    ][_g11_light_v23]

func _apply_g11_light_v23() -> void:
    if _role != "mlrs" or hq_key_light==null or hq_fill_light==null:
        return
    var i: int = clampi(_g11_light_v23,0,2)
    var colors: Array[Color] = [
        Color("#fff1db"),Color("#efb87d"),Color("#accce8")]
    var ambient: Array[Color] = [
        Color("#cedce7"),Color("#c4acaa"),Color("#9bb6d2")]
    var energies: Array[float] = [1.54,0.88,0.28]
    hq_key_light.rotation_degrees = Vector3(
        [-51.0,-27.0,-14.0][i],-33.0,0)
    hq_key_light.light_color = colors[i]
    hq_key_light.light_energy = energies[i]
    hq_key_light.shadow_enabled = true
    hq_fill_light.light_color = ambient[i]
    hq_fill_light.light_energy = [0.72,0.48,0.29][i]
    if hq_environment!=null and hq_environment.environment!=null:
        var env: Environment = hq_environment.environment
        env.background_color = [
            Color("#283b46"),Color("#413340"),Color("#101a2a")][i]
        env.ambient_light_color = ambient[i]
        env.ambient_light_energy = [0.78,0.59,0.47][i]
    for lamp in hq_night_lamps:
        lamp.visible = false
    for lamp in _g11_lamps_v23:
        lamp.visible = i>0
        lamp.light_color = (Color("#ffce9e") if i==1
            else Color("#a9d4f5"))
        lamp.light_energy = (0.42 if i==1 else 1.05)

func _g11_joint_macro_v23(side: int) -> void:
    if _role!="mlrs" or model_root==null:
        return
    _set_g11_light_v23(2)
    _g11_cutaway(side)
    _zoom=2.72
    _update_camera()
    if camera!=null:
        camera.position.y=0.36
        camera.look_at(Vector3(0,0.34,0),Vector3.UP)

func _g11_cutaway(side: int) -> void:
    if not _g11_require_hero_v24():
        return
    if not G11JointsV22.set_inspection(model_root,side):
        return
    if side == 0:
        _g11_view(90.0)
        _zoom = 1.48
        _update_camera()
    else:
        _g11_mount_inspect(90.0 if side > 0 else 270.0,true)
        if camera != null:
            camera.position.y = 0.34
            camera.look_at(Vector3(0,0.37,0),Vector3.UP)
    status_label.text = ("G11 V22 · blindaje completo" if side == 0
        else "G11 V22 · interior real visible, lado %s" % ("A" if side > 0 else "B"))

func _g11_mount_inspect(yaw: float, low: bool) -> void:
    if not _g11_require_hero_v24():
        return
    _g11_stop()
    _yaw = yaw
    _zoom = 2.35 if low else 2.05
    model_root.rotation_degrees.y = yaw
    _update_camera()
    if low and camera != null:
        camera.position.y = 0.45
        camera.look_at(Vector3(0,0.48,0),Vector3.UP)

func _g11_rear_under_v30(three_quarter: bool) -> void:
    if not _g11_require_hero_v24():
        return
    G11JointsV22.set_inspection(model_root,0)
    _g11_stop()
    _yaw=0.0
    model_root.rotation_degrees.y=0.0
    _zoom=2.28
    _update_camera()
    if camera!=null:
        camera.position=(
            Vector3(2.35,0.10,2.88) if three_quarter else
            Vector3(0.88,0.06,3.55))
        camera.look_at(Vector3(0,0.42,0.82),Vector3.UP)
    status_label.text=("G11 V30 · trasera inferior en tres cuartos" if
        three_quarter else "G11 V30 · vista bajo la trasera y orugas")

func _g11_track_closeup(yaw: float) -> void:
    if not _g11_require_hero_v24():
        return
    G11JointsV22.set_inspection(model_root,0)
    _g11_stop()
    _yaw = yaw
    _zoom = 1.94
    model_root.rotation_degrees.y = yaw
    _update_camera()

func _g11_set_wear(enabled: bool) -> void:
    if not _g11_require_hero_v24():
        return
    if G11Weather.set_wear(model_root,enabled):
        status_label.text = ("G11 V17 · desgaste operativo" if enabled
            else "G11 V17 · pintura limpia")

func _g11_view(yaw: float) -> void:
    if not _g11_require_hero_v24():
        return
    G11JointsV22.set_inspection(model_root,0)
    _g11_stop()
    _yaw = yaw
    model_root.rotation_degrees.y = yaw
    _update_camera()

func _g11_play(kind: String, speed: float = 1.0) -> void:
    if _g11_turn_tween!=null and _g11_turn_tween.is_running():
        _g11_turn_tween.kill()
    if not _g11_require_hero_v24() or not G11Rig.has_rig(model_root):
        return
    if G11Art.stage(model_root) >= 4 and kind in ["move","attack"]:
        status_label.text = "Lanzador destruido · reparar para operar"
        return
    _g11_animation = kind
    _g11_time = 0.0
    _g11_playback_speed = clampf(speed,0.20,2.0)
    G11Rig.pose(model_root,kind,0.0)

func _g11_stop() -> void:
    if _g11_turn_tween!=null and _g11_turn_tween.is_running():
        _g11_turn_tween.kill()
    _g11_animation = ""
    _g11_time = 0.0
    _g11_playback_speed = 1.0
    if G11Rig.has_rig(model_root):
        G11Rig.restore(model_root)

func _set_p06_fleet_quality(tier: int) -> void:
    _p06_fleet_quality=clampi(tier,-1,2)
    _refresh_p06_fleet_quality()
    if _role=="apc":
        _update_details()

func _refresh_p06_fleet_quality() -> void:
    if _p06_fleet==null or not is_instance_valid(_p06_fleet):
        return
    var samples: float=720.0
    if camera!=null and camera.get_viewport()!=null:
        samples=float(camera.get_viewport().get_visible_rect().size.y)
    var count: int=0
    for node in _p06_fleet.get_children():
        var apc: Node3D=node as Node3D
        if apc==null or not P06Tactical.has_model(apc):
            continue
        if _p06_fleet_quality<0:
            var projected: float=(P06Tactical.VISUAL_HEIGHT*samples*
                apc.scale.y/maxf(0.05,camera.size)) if camera!=null else 160.0
            P06Tactical.set_detail_from_pixels(apc,projected)
        else:
            P06Tactical.set_detail(apc,_p06_fleet_quality)
        count+=P06Tactical.visible_surfaces(apc)
    _p06_fleet_active_surfaces=count

func _animate_p06_fleet(kind: String) -> void:
    if _p06_fleet==null or kind not in ["move_turn","attack"]:
        return
    _p06_fleet_animation=kind
    _p06_fleet_animation_time=0.0
    for node in _p06_fleet.get_children():
        var model: Node3D=node as Node3D
        if model!=null:
            P06Tactical.restore(model)

func _hide_p06_fleet() -> void:
    if _p06_fleet != null and is_instance_valid(_p06_fleet):
        var parent: Node=_p06_fleet.get_parent()
        if parent != null:
            parent.remove_child(_p06_fleet)
        _p06_fleet.queue_free()
    _p06_fleet=null
    _p06_fleet_count=0
    _p06_fleet_surfaces=0
    _p06_fleet_active_surfaces=0
    _p06_fleet_fps_sample=-1
    _p06_fleet_fps_clock=0.0
    _p06_fleet_animation=""
    _p06_fleet_animation_time=0.0
    if model_root != null and is_instance_valid(model_root):
        model_root.visible=true
    if _role=="apc":
        _update_camera()
        _update_details()

func _show_p06_fleet(count: int) -> void:
    if not _studio_p06() or count not in [8,32,64]:
        return
    _stop_animation()
    _hide_p06_fleet()
    var fleet:=Node3D.new()
    fleet.name="P06V8_FlotaTactica_%d" % count
    var cols: int=8
    var rows: int=int(ceil(float(count)/float(cols)))
    var started: int=Time.get_ticks_usec()
    var surfaces: int=0
    for i in range(count):
        var vehicle: Node3D=P06Models.build("apc",i%8,false,8)
        if vehicle==null or not P06Tactical.has_model(vehicle):
            fleet.free()
            status_label.text="Error construyendo flota P06 V8"
            return
        vehicle.name="P06V8_Faccion_%d_Unidad_%d" % [i%8,i]
        vehicle.scale=Vector3.ONE*0.34
        vehicle.position=Vector3(
            (float(i%cols)-3.5)*0.91,0,
            (float(int(i/cols))-float(rows-1)*0.5)*0.98)
        P06Tactical.rebase(vehicle)
        fleet.add_child(vehicle)
        surfaces+=P06Tactical.draw_surfaces(vehicle)
    _p06_fleet_build_ms=float(Time.get_ticks_usec()-started)/1000.0
    _p06_fleet_count=count
    _p06_fleet_surfaces=surfaces
    _p06_fleet=fleet
    _p06_fleet_fps_sample=-1
    _p06_fleet_fps_clock=0.0
    model_root.visible=false
    preview.add_child(fleet)
    _update_camera()
    _refresh_p06_fleet_quality()
    _update_details()

func _update_camera() -> void:
    super._update_camera()
    if _role=="uav_recon" and model_root!=null and camera!=null:
        if _a01_review_focus=="optica":
            var optics:=model_root.find_child(A01Recon.SENSOR,true,false) as Node3D
            var target:Vector3=optics.global_position if optics!=null else Vector3(0,0.65,-0.60)
            camera.position=target+Vector3(2.5,1.4,-2.9)
            camera.look_at(target,Vector3.UP)
            camera.size=2.05/maxf(0.65,_zoom)
        elif _a01_review_focus=="cola":
            var target:=model_root.to_global(Vector3(0,1.02,1.14))
            camera.position=target+Vector3(3.3,1.9,2.5)
            camera.look_at(target,Vector3.UP)
            camera.size=2.85/maxf(0.65,_zoom)
        elif _a01_review_focus=="superior":
            var target:=model_root.to_global(Vector3(0,1.04,-0.10))
            camera.position=target+Vector3(0.35,5.7,0.25)
            camera.look_at(target,Vector3(0,0,-1))
            camera.size=4.1/maxf(0.65,_zoom)
    if _role=="logistics_mobile" and model_root!=null and camera!=null:
        # The only camera that changes is the existing unified viewer.
        # Keep close-ups stable during faction/color and zoom rebuilds.
        if _g16_review_focus=="suministros":
            var coupling:=model_root.find_child(G16ServiceV6.COUPLING,true,false) as Node3D
            var target:Vector3=coupling.global_position if coupling!=null else Vector3(-2.1,1.3,0)
            camera.position=target+Vector3(-4.6,2.6,3.1)
            camera.look_at(target,Vector3.UP)
            camera.size=3.65/maxf(0.65,_zoom)
        elif _g16_review_focus=="bajos":
            var target:=model_root.to_global(Vector3(-0.55,0.42,0))
            camera.position=target+Vector3(-4.4,0.85,4.2)
            camera.look_at(target,Vector3.UP)
            camera.size=3.9/maxf(0.65,_zoom)
    if _role=="mlrs" and _g11_context_v25!=null and camera!=null:
        var center := Vector3(0,0.8,0)
        var facing: Vector3=(camera.position-center).normalized()
        if facing.length()<0.1:
            facing=Vector3(0.65,0.65,0.4).normalized()
        camera.position=center+facing*43.0
        camera.look_at(center,Vector3.UP)
        camera.size=28.0/maxf(0.60,_zoom)
    if _role=="attack_heli" and model_root!=null and camera!=null:
        # Fit both the four-metre main rotor and the long tail in the actual
        # visible 3D canvas, not the 1000x680 default render resolution.
        # Camera.size in orthographic mode is VERTICAL world-space coverage.
        var size: Vector2=model_holder.size if model_holder!=null else Vector2(680,480)
        var aspect: float=maxf(0.75,size.x/maxf(220.0,size.y))
        var normal: float=P06Models.preview_frame_height("attack_heli")*1.10/maxf(0.65,_zoom)
        var width_limit: float=6.5/aspect/maxf(0.65,_zoom)
        camera.size=maxf(normal,width_limit)
        var home:=Vector3(0,0.98,0.12)
        var target: Vector3=(model_root.to_global(_heli_focus_local)
            if _heli_focus_local!=Vector3.ZERO else home)
        camera.position=_heli_camera_base+(target-home)
        camera.look_at(target,Vector3.UP)
        if _heli_underbody_view_active:
            camera.position=target+Vector3(2.45,-2.65,-2.65)
            camera.look_at(target,Vector3.UP)
        elif _heli_mast_view_active_v145:
            # The original elevated camera hides the new fixed tie rods
            # behind the rotating V1 blades. This is a real SIDE camera.
            camera.position=target+Vector3(1.75,-0.11,-2.25)
            camera.look_at(target,Vector3.UP)
    if _role=="apc" and _p06_fleet!=null and camera!=null:
        # Orthographic view needs size rather than moving the camera closer.
        var full: float=13.4 if _p06_fleet_count<=8 else (
            15.0 if _p06_fleet_count<=32 else 18.2)
        camera.size=full/maxf(0.35,_zoom)
        _refresh_p06_fleet_quality()

func _studio_p06() -> bool:
    return _role == "apc" and model_root != null and \
        bool(model_root.get_meta("tarvoka_apc_finish_v3",false))

func _sync_p06_controls() -> void:
    var p06: bool = _role == "apc"
    if heli_controls != null:
        _heli_refresh_mobile_layout(get_viewport().get_visible_rect().size)
    if _heli_v10_rim_light!=null:
        _heli_v10_rim_light.visible=_role=="attack_heli"
    if _role == "attack_heli" and damage_picker != null:
        if _heli_v12_button!=null:
            _heli_v12_button.text=("Comparar morro V11" if _heli_v12_enabled
                else "Activar carenado V12")
        if _heli_v11_button!=null:
            _heli_v11_button.text=("Comparar mecánica V10" if _heli_v11_enabled
                else "Activar transmisión V11")
        if _heli_v10_button!=null:
            _heli_v10_button.text=("Comparar acabado anterior V8" if _heli_v10_enabled
                else "Activar acabado V10")
        damage_picker.visible=false
        faction_picker.visible=true
        if _heli_v8_button != null:
            _heli_v8_button.text=("Comparar sin identidad V8" if _heli_v8_enabled
                else "Activar paneles de facción V8")
        if _heli_v7_button != null:
            _heli_v7_button.text=("Comparar sin acabado V7" if _heli_v7_enabled
                else "Activar identidad V7 a distancia")
        if _heli_compare_button != null:
            _heli_compare_button.text=("Comparar casco anterior V1" if _heli_v2_enabled
                else "Volver a cabina y casco V2")
    if p06_controls != null:
        p06_controls.visible = p06 and \
            (category_picker == null or category_picker.selected == 0)
    if p06 and damage_picker != null:
        faction_picker.visible = true
        damage_picker.visible = true
        comparison_button.visible = false
        previous_version_button.visible = false
        for i in range(P06Stages.size()):
            damage_picker.set_item_text(i,str(P06Stages[i]))
        damage_picker.select(_stage_p06())
        if p06_version_button != null:
            p06_version_button.text = ("Ver acabado anterior V3"
                if _p06_show_v5 else "Volver al acabado completo V25")
        if p06_ramp_button != null:
            p06_ramp_button.text = ("Cerrar rampa de tropas"
                if model_root != null and model_root.get_meta(
                    "tarvoka_apc_ramp_open",false) else "Abrir rampa de tropas")
    elif damage_picker != null and _role != "mlrs":
        for i in range(TankDamage.STAGES.size()):
            damage_picker.set_item_text(i,str(TankDamage.STAGES[i]))
    if g13_controls!=null:
        g13_controls.visible=_role=="aa_mobile" and (
            category_picker==null or category_picker.selected==0)
    if _role=="aa_mobile" and damage_picker!=null:
        damage_picker.visible=false
        faction_picker.visible=true
    if g11_controls != null:
        g11_controls.visible = _role == "mlrs" and (
            category_picker == null or category_picker.selected == 0)
    if _role == "mlrs" and damage_picker != null:
        damage_picker.visible = true
        faction_picker.visible = true
        for i in range(G11Art.STAGES.size()):
            damage_picker.set_item_text(i,str(G11Art.STAGES[i]))
        damage_picker.select(G11Art.stage(model_root))

func _stage_p06() -> int:
    if model_root == null:
        return 0
    return clampi(int(model_root.get_meta(
        "tarvoka_apc_v3_damage_stage",0)),0,4)

func _display_role(role: String) -> void:
    if _a01_tween!=null and _a01_tween.is_running():
        _a01_tween.kill()
    if _a01_review_tween!=null and _a01_review_tween.is_running():
        _a01_review_tween.kill()
    _a01_review_focus="general"
    if role!="logistics_mobile":
        _g16_review_focus="general"
    if _g16_review_tween!=null and _g16_review_tween.is_running():
        _g16_review_tween.kill()
    var retain_night_v143: bool=(_heli_night_enabled_v143 and role=="attack_heli")
    if _heli_night_enabled_v143:
        _heli_set_night_v143(false)
    # All eight units and the buildings share the SAME viewport and camera.
    # For the native G09 V32, V25 materials + V30 damage + V31 inboard
    # geometry activate the final V32 animation rig in TankVisualRig3D.gd.
    # The current CombinedArtStudioWeb base has no _v25/_v30/_v31
    # switches: these unused legacy writes broke real Studio import.
    # Tank rendering continues through the base role-selection code.
    if _g11_context_v25!=null:
        _g11_clear_battle_context_v25()
    if _g11_turn_tween!=null and _g11_turn_tween.is_running():
        _g11_turn_tween.kill()
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    if _g15_tween!=null and _g15_tween.is_running():
        _g15_tween.kill()
    if _g16_tween!=null and _g16_tween.is_running():
        _g16_tween.kill()
    if _infantry_tween!=null and _infantry_tween.is_running():
        _infantry_tween.kill()
    if _engineer_v6_tween!=null and _engineer_v6_tween.is_running():
        _engineer_v6_tween.kill()
    if role!="mlrs":
        _g11_preview_lod_v24=13
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if role!="attack_heli" and _role=="attack_heli" and camera!=null:
        _heli_mast_view_active_v145=false
        _heli_underbody_restore_floor()
        camera.position=_heli_camera_base
        _heli_focus_local=Vector3.ZERO
    if not _g13_reflection_saved_v53.is_empty():
        _g13_v53_set_reflections(false)
    super._display_role(role)
    if role=="uav_recon":
        # The legacy Studio hides factions for unrecognized new roles.
        # A01 shares the ORIGINAL selector and eight official paint choices.
        if model_root==null or not A01HardwareV3.has_model(model_root):
            push_error("A01 V3 physical UAV is missing from shared Studio")
            return
        faction_picker.visible=true
        _update_camera()
    if InfantryV1.supports(role):
        if infantry_360_tween!=null and infantry_360_tween.is_running():
            infantry_360_tween.kill()
        infantry_review_v2=true
        infantry_review_lod=13
        # Swap the base low-detail preview for the hero-grade native geometry
        # in the SAME shared Studio viewport; battle LOD stays lightweight.
        if model_root!=null:
            preview.remove_child(model_root)
            model_root.queue_free()
        model_root=P06Models.build(role,_faction,true,13)
        if model_root==null or not InfantryV1.has_model(model_root) or not bool(model_root.get_meta("tarvoka_infantry_sculpt_finish_v2",false)):
            push_error("Infantry V2 organic native 3D finish missing in unified Studio")
            return
        preview.add_child(model_root)
        model_root.rotation_degrees.y=_yaw
        faction_picker.visible=true
        _update_camera()
    if role=="logistics_mobile":
        if model_root!=null:
            preview.remove_child(model_root)
            model_root.queue_free()
        model_root=P06Models.build("logistics_mobile",_faction,true,13)
        if model_root==null or not G16Logistics.has_model(model_root) or not G16ExteriorV2.has_model(model_root) or not G16MechanicsV3.has_model(model_root) or not G16SculptV4.has_model(model_root) or not G16MaterialsV5.has_model(model_root) or not G16ServiceV6.has_model(model_root):
            push_error("G16 V6 physical supply hose, V5 PBR glazing or prior 6×6 mechanics missing in unified Studio")
            return
        preview.add_child(model_root)
        model_root.rotation_degrees.y=_yaw
        faction_picker.visible=true
        _update_camera()
    if role=="ew_mobile":
        if model_root!=null:
            preview.remove_child(model_root)
            model_root.queue_free()
        model_root=P06Models.build("ew_mobile",_faction,true,13)
        if model_root==null or not G15EW.has_model(model_root):
            push_error("G15 native 3D model absent in unified Studio")
            return
        preview.add_child(model_root)
        model_root.rotation_degrees.y=_yaw
        faction_picker.visible=true
        _update_camera()
    if role == "tank" and model_root != null:
        # The unified Studio navigation QA expects the approved G09 V31
        # track geometry by default. UnitArtStudioWeb's base selector starts
        # at art_level=10 until its legacy V25/V30/V31 comparison flags are
        # enabled; previously this showed a proxy despite the V32 label.
        # Replace ONLY the Studio instance with the already-approved V31
        # native geometry. Do not touch game/battle roles, G13 or G11.
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root=P06Models.build("tank",_faction,true,31)
        if model_root==null:
            push_error("Studio G09 V31 final model was not built")
            return
        preview.add_child(model_root)
        model_root.rotation_degrees.y=_yaw
        _update_camera()
    if role == "attack_heli" and model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root=P06Models.build("attack_heli",_faction,true,14)
        if model_root != null:
            HeliV2.set_enabled(model_root,_heli_v2_enabled)
            HeliV3.set_enabled(model_root,_heli_v2_enabled)
            HeliV4.set_enabled(model_root,_heli_v2_enabled)
            HeliV5.set_enabled(model_root,_heli_v2_enabled)
            HeliV6.set_enabled(model_root,_heli_v2_enabled)
            HeliV7.set_enabled(model_root,_heli_v2_enabled and _heli_v7_enabled)
            HeliV8.set_enabled(model_root,_heli_v2_enabled and _heli_v8_enabled)
            HeliV10.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled)
            HeliV11.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled)
            HeliV12.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled and _heli_v12_enabled)
            preview.add_child(model_root)
            model_root.rotation_degrees.y=_yaw
            # Studio-only, never in build("attack_heli") or Android battle LOD.
            HeliNightV144.install(model_root)
            # World-anchored wreckage MUST spawn after the recolored helicopter
            # is inside the real viewport, with its final faction/yaw transform.
            # Otherwise the launch hub and detached debris get stale globals.
            if HeliV13.has_model(model_root):
                HeliV13.set_stage(model_root,_heli_damage_stage)
                if _heli_wreck_frozen and _heli_damage_stage>=4:
                    HeliV13.pose(model_root,"destroy",1.0)
            _update_camera()
        _heli_animation=""
    if role == "apc" and model_root != null:
        # Replace the proxy outright: leaving hundreds of invisible meshes
        # in the render tree wastes RAM and obscures model QA on mobile.
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root = P06Models.build("apc",_faction,true,14)
        if model_root == null:
            return
        preview.add_child(model_root)
        model_root.rotation_degrees.y = _yaw
        _p06_quality_verified = bool(model_root.get_meta(
            "tarvoka_apc_finish_v3",false)) and bool(model_root.get_meta(
            P06Details.FLAG,false)) and bool(model_root.get_meta(
            P06V6.FLAG,false)) and bool(model_root.get_meta(
            P06Burst.FLAG,false)) and bool(model_root.get_meta(
            P06Wreck.FLAG,false)) and bool(model_root.get_meta(
            P06RearV10.FLAG,false)) and bool(model_root.get_meta(
            P06ExteriorV11.FLAG,false)) and bool(model_root.get_meta(
            P06TurretV12.FLAG,false)) and bool(model_root.get_meta(
            P06SurfaceV13.FLAG,false)) and bool(model_root.get_meta(
            P06WheelsV14.FLAG,false)) and bool(model_root.get_meta(
            P06UnderV15.FLAG,false)) and bool(model_root.get_meta(
            P06JointV16.FLAG,false)) and bool(model_root.get_meta(
            P06ContourV17.FLAG,false)) and bool(model_root.get_meta(
            P06WheelwellV18.FLAG,false)) and bool(model_root.get_meta(
            P06FlankV19.FLAG,false)) and bool(model_root.get_meta(
            P06MicroV20.FLAG,false)) and bool(model_root.get_meta(
            P06MaterialV21.FLAG,false)) and bool(model_root.get_meta(
            P06WeatherV22.FLAG,false)) and bool(model_root.get_meta(
            P06TireV23.FLAG,false)) and bool(model_root.get_meta(
            P06RubberV24.FLAG,false)) and bool(model_root.get_meta(
            P06ClosedV25.FLAG,false)) and bool(model_root.get_meta(
            P06Audio.FLAG,false))
        if _p06_quality_verified:
            P06Details.set_enabled(model_root,_p06_show_v5)
            P06V6.set_enabled(model_root,_p06_show_v5)
            P06Finish.apply_stage(model_root,0)
            P06V6.set_stage(model_root,0)
            P06Wreck.set_stage(model_root,0)
            P06RearV10.set_stage(model_root,0)
            P06ExteriorV11.set_stage(model_root,0)
            P06TurretV12.set_stage(model_root,0)
            P06SurfaceV13.set_stage(model_root,0)
            P06WheelsV14.set_stage(model_root,0)
            P06UnderV15.set_stage(model_root,0)
            P06JointV16.set_stage(model_root,0)
            P06ContourV17.set_stage(model_root,0)
            P06WheelwellV18.set_stage(model_root,0)
            P06FlankV19.set_stage(model_root,0)
            P06MicroV20.set_stage(model_root,0)
            P06MaterialV21.set_stage(model_root,0)
            P06WeatherV22.set_stage(model_root,0)
            P06WeatherV22.set_weather(model_root,_p06_weather_v22)
            P06TireV23.set_stage(model_root,0)
            P06TireV23.set_weather(model_root,_p06_weather_v22)
            P06RubberV24.set_stage(model_root,0)
            P06RubberV24.set_weather(model_root,_p06_weather_v22)
            P06ClosedV25.set_stage(model_root,0)
            P06ClosedV25.set_weather(model_root,_p06_weather_v22)
        else:
            push_error("TARVOKA P06 V25 sealed tire casings were not built; do not label it final")
        _update_camera()
    if role=="aa_mobile" and model_root!=null:
        # Studio only: the new G13 role is a visual-only prototype;
        # keep complete 3D detailing out of the battle renderer.
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root=P06Models.build("aa_mobile",_faction,true,_g13_preview_lod)
        if model_root!=null:
            if _g13_preview_lod==8:
                # Compare versions newest-to-oldest. V25 V1 restoration
                # must win over the V26 previous-radar resource.
                if _g13_v28_show_previous:
                    G13DeckV28.show_v27_reference(model_root,true)
                if _g13_v27_show_previous:
                    G13RadarV27.show_v26_reference(model_root,true)
                if _g13_v26_show_previous:
                    G13ArmorV26.show_v25_reference(model_root,true)
                if _g13_v25_show_original:
                    G13TacticalV25.show_v1_reference(model_root,true)
            preview.add_child(model_root)
            model_root.rotation_degrees.y=_yaw
            _update_camera()
    if role == "mlrs" and model_root != null:
        # Studio only: override the low-poly proxy with the complete V1 sculpt.
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root = P06Models.build("mlrs",_faction,true,_g11_preview_lod_v24)
        if model_root != null:
            preview.add_child(model_root)
            model_root.rotation_degrees.y = _yaw
            _update_camera()
        _g11_animation = ""
    for lamp in _g11_lamps_v23:
        lamp.visible = false
    if role=="apc":
        _apply_p06_lighting_v22()
    else:
        if _p06_night_fill_v22!=null:
            _p06_night_fill_v22.visible=false
        _apply_hq_lighting(_hq_light_preset)
        if role=="mlrs":
            _apply_g11_light_v23()
    if role=="aa_mobile" and model_root!=null:
        _g13_v53_set_reflections(true)
    if retain_night_v143 and role=="attack_heli":
        _heli_set_night_v143(true)
    _sync_p06_controls()
    _update_details()
    _refresh_unified_studio_navigation()

func _switch_category(index: int) -> void:
    if index!=0:
        _heli_mast_view_active_v145=false
    if index!=0 and _heli_night_enabled_v143:
        _heli_set_night_v143(false)
    super._switch_category(index)
    # The parent directly chooses tank when switching to Units. Rebuild
    # the native approved art after the parent's legacy category transition.
    if index == 0 and _role == "tank":
        _display_role("tank")
    _sync_p06_controls()
    _refresh_unified_studio_navigation()

func _on_faction(index: int) -> void:
    if InfantryV1.supports(_role):
        if index<0 or index>=Factions.FACTIONS.size():
            return
        # Base Studio only repaints G09; V2 infantry needs brand-new
        # physical 3D armor with the selected palette, including at LOD8.
        _faction=index
        if _infantry_review_rebuild(infantry_review_v2,infantry_review_lod):
            faction_picker.select(index)
            status_label.text="Infantería · facción %d · LOD%d · pintura 3D actualizada"%[
                index,infantry_review_lod]
        return
    if _role=="logistics_mobile":
        if index<0 or index>=Factions.FACTIONS.size():
            return
        var saved_yaw:float=_yaw
        var saved_zoom:float=_zoom
        _faction=index
        _display_role("logistics_mobile")
        _yaw=saved_yaw
        _zoom=saved_zoom
        if model_root!=null:
            model_root.rotation_degrees.y=_yaw
        _update_camera()
        return
    if _role=="uav_recon":
        if index<0 or index>=Factions.FACTIONS.size():
            return
        var keep_yaw:float=_yaw
        var keep_zoom:float=_zoom
        _faction=index
        _display_role("uav_recon")
        faction_picker.select(index)
        _yaw=keep_yaw
        _zoom=keep_zoom
        if model_root!=null:
            model_root.rotation_degrees.y=_yaw
        _update_camera()
        return
    if _role=="ew_mobile":
        if index<0 or index>=Factions.FACTIONS.size():
            return
        var old_yaw:float=_yaw
        var old_zoom:float=_zoom
        _faction=index
        _display_role("ew_mobile")
        _yaw=old_yaw
        _zoom=old_zoom
        if model_root!=null:
            model_root.rotation_degrees.y=_yaw
        _update_camera()
        return
    if _role == "attack_heli":
        if index < 0 or index >= Factions.FACTIONS.size():
            return
        var last_yaw: float=_yaw
        var last_zoom: float=_zoom
        _heli_stop()
        _faction=index
        _display_role("attack_heli")
        _yaw=last_yaw
        _zoom=last_zoom
        if model_root != null:
            model_root.rotation_degrees.y=_yaw
        _update_camera()
        return
    if _role == "mlrs":
        if index < 0 or index >= Factions.FACTIONS.size():
            return
        var previous_stage: int = G11Art.stage(model_root)
        var previous_yaw: float = _yaw
        var previous_zoom: float = _zoom
        _faction = index
        _display_role("mlrs")
        _yaw = previous_yaw
        _zoom = previous_zoom
        if model_root != null:
            model_root.rotation_degrees.y = _yaw
        _update_camera()
        _set_damage(previous_stage)
        return
    if _role != "apc":
        super._on_faction(index)
        return
    if index < 0 or index >= Factions.FACTIONS.size():
        return
    var last_stage: int = _stage_p06()
    var last_yaw: float = _yaw
    var last_zoom: float = _zoom
    _faction = index
    # Rebuild once on a faction change, so V5 sculpt materials as well as
    # the chassis and roof match the selected official enamel.
    _display_role("apc")
    _yaw = last_yaw
    _zoom = last_zoom
    if model_root != null:
        model_root.rotation_degrees.y = _yaw
    _update_camera()
    _set_damage(last_stage)

func _on_damage(index: int) -> void:
    _set_damage(index)

func _set_damage(stage: int) -> void:
    if _role == "mlrs":
        _g11_stop()
        if G11Art.apply_stage(model_root,stage):
            if damage_picker != null:
                damage_picker.select(G11Art.stage(model_root))
            _update_details()
        return
    if _role != "apc":
        super._set_damage(stage)
        return
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if not _studio_p06():
        return
    _stop_animation()
    if P06Finish.apply_stage(model_root,stage):
        P06V6.set_stage(model_root,stage)
        P06Wreck.set_stage(model_root,stage)
        P06RearV10.set_stage(model_root,stage)
        P06ExteriorV11.set_stage(model_root,stage)
        P06TurretV12.set_stage(model_root,stage)
        P06SurfaceV13.set_stage(model_root,stage)
        P06WheelsV14.set_stage(model_root,stage)
        P06UnderV15.set_stage(model_root,stage)
        P06JointV16.set_stage(model_root,stage)
        P06ContourV17.set_stage(model_root,stage)
        P06WheelwellV18.set_stage(model_root,stage)
        P06FlankV19.set_stage(model_root,stage)
        P06MicroV20.set_stage(model_root,stage)
        P06MaterialV21.set_stage(model_root,stage)
        P06WeatherV22.set_stage(model_root,stage)
        P06TireV23.set_stage(model_root,stage)
        P06RubberV24.set_stage(model_root,stage)
        P06ClosedV25.set_stage(model_root,stage)
        damage_picker.select(_stage_p06())
        _update_details()

func _toggle_p06_version() -> void:
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if not _studio_p06():
        return
    _p06_show_v5 = not _p06_show_v5
    P06Details.set_enabled(model_root,_p06_show_v5)
    P06V6.set_enabled(model_root,_p06_show_v5)
    P06Wreck.set_enabled(model_root,_p06_show_v5)
    P06RearV10.set_enabled(model_root,_p06_show_v5)
    P06ExteriorV11.set_enabled(model_root,_p06_show_v5)
    P06TurretV12.set_enabled(model_root,_p06_show_v5)
    P06SurfaceV13.set_enabled(model_root,_p06_show_v5)
    P06WheelsV14.set_enabled(model_root,_p06_show_v5)
    P06UnderV15.set_enabled(model_root,_p06_show_v5)
    P06JointV16.set_enabled(model_root,_p06_show_v5)
    P06ContourV17.set_enabled(model_root,_p06_show_v5)
    P06WheelwellV18.set_enabled(model_root,_p06_show_v5)
    P06FlankV19.set_enabled(model_root,_p06_show_v5)
    P06MicroV20.set_enabled(model_root,_p06_show_v5)
    P06MaterialV21.set_enabled(model_root,_p06_show_v5)
    P06WeatherV22.set_enabled(model_root,_p06_show_v5)
    P06TireV23.set_enabled(model_root,_p06_show_v5)
    P06RubberV24.set_enabled(model_root,_p06_show_v5)
    P06ClosedV25.set_enabled(model_root,_p06_show_v5)
    _sync_p06_controls()
    _update_details()

func _view_p06_angle(angle: float) -> void:
    if _role!="apc":
        return
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if model_root==null:
        return
    _yaw=angle
    # After viewing the underside, restore the original upright chassis.
    model_root.rotation_degrees.x=0.0
    model_root.rotation_degrees.y=angle
    _update_camera()

func _inspect_p06_front_joint() -> void:
    if _role!="apc":
        return
    _view_p06_angle(47.0)
    _zoom=1.82
    _update_camera()

func _inspect_p06_rear_joint() -> void:
    if _role!="apc":
        return
    _view_p06_angle(153.0)
    _zoom=1.72
    _update_camera()

func _inspect_p06_roof_v17() -> void:
    if _role!="apc":
        return
    _view_p06_angle(42.0)
    if model_root!=null:
        model_root.rotation_degrees.x=-24.0
    _zoom=1.65
    _update_camera()

func _inspect_p06_ramp_v17() -> void:
    if _role!="apc":
        return
    _view_p06_angle(176.0)
    _zoom=1.83
    _update_camera()

func _inspect_p06_skirts_v18() -> void:
    if _role!="apc":
        return
    _view_p06_angle(91.0)
    _zoom=1.88
    _update_camera()

func _inspect_p06_critical_v18() -> void:
    if _role!="apc":
        return
    _set_damage(3)
    _view_p06_angle(108.0)
    _zoom=1.84
    _update_camera()

func _inspect_p06_seams_v19() -> void:
    if _role!="apc":
        return
    _view_p06_angle(90.0)
    _zoom=1.94
    _update_camera()

func _inspect_p06_seals_v19() -> void:
    if _role!="apc":
        return
    _view_p06_angle(-82.0)
    _zoom=2.06
    _update_camera()

func _inspect_p06_mounts_v19() -> void:
    if _role!="apc":
        return
    _view_p06_angle(124.0)
    _zoom=1.92
    _update_camera()

func _inspect_p06_damage_v19() -> void:
    if _role!="apc":
        return
    _set_damage(3)
    _view_p06_angle(104.0)
    _zoom=1.89
    _update_camera()

func _inspect_p06_welds_v20() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(91.0)
    _zoom=2.08
    _update_camera()

func _inspect_p06_bolts_v20() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(-76.0)
    _zoom=2.17
    _update_camera()

func _inspect_p06_medium_v20() -> void:
    if _role!="apc":
        return
    _set_damage(2)
    _view_p06_angle(97.0)
    _zoom=2.10
    _update_camera()

func _inspect_p06_critical_v20() -> void:
    if _role!="apc":
        return
    _set_damage(3)
    _view_p06_angle(125.0)
    _zoom=1.95
    _update_camera()

func _inspect_p06_paint_v21() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(86.0)
    _zoom=2.12
    _update_camera()

func _inspect_p06_rubber_v21() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(-77.0)
    _zoom=2.10
    _update_camera()

func _inspect_p06_wear_v21() -> void:
    if _role!="apc":
        return
    _set_damage(1)
    _view_p06_angle(92.0)
    _zoom=2.06
    _update_camera()

func _inspect_p06_burnt_v21() -> void:
    if _role!="apc":
        return
    _set_damage(3)
    _view_p06_angle(114.0)
    _zoom=2.01
    _update_camera()

func _install_p06_lighting_v22() -> void:
    if preview==null or _p06_night_fill_v22!=null:
        return
    _p06_night_fill_v22=OmniLight3D.new()
    _p06_night_fill_v22.name="P06V22_RefuerzoDeLecturaNocturna"
    _p06_night_fill_v22.position=Vector3(2.6,3.2,-2.1)
    _p06_night_fill_v22.omni_range=8.2
    _p06_night_fill_v22.light_energy=1.1
    _p06_night_fill_v22.light_color=Color("#a4c8ea")
    _p06_night_fill_v22.shadow_enabled=false
    _p06_night_fill_v22.visible=false
    preview.add_child(_p06_night_fill_v22)

func _set_p06_weather_v22(mode: String) -> void:
    if _role!="apc" or not mode in P06WeatherV22.WEATHERS:
        return
    _p06_weather_v22=mode
    if model_root!=null:
        P06WeatherV22.set_weather(model_root,mode)
        P06TireV23.set_weather(model_root,mode)
        P06RubberV24.set_weather(model_root,mode)
        P06ClosedV25.set_weather(model_root,mode)
    _apply_p06_lighting_v22()
    _update_details()

func _set_p06_light_v22(preset: int) -> void:
    if _role!="apc":
        return
    _p06_light_v22=clampi(preset,0,2)
    _apply_p06_lighting_v22()
    _update_details()

func _apply_p06_lighting_v22() -> void:
    if _role!="apc" or hq_key_light==null or hq_fill_light==null:
        return
    # Dedicated studio lighting, not the weather rules in the battle map.
    var palette: Array[Color]=[
        Color("#fff2de"),Color("#ffb675"),Color("#b4cbeb")]
    var ambient: Array[Color]=[
        Color("#c8d9e8"),Color("#dfae92"),Color("#a1bbd8")]
    var key: Array[float]=[1.60,1.13,0.43]
    var fill: Array[float]=[0.74,0.53,0.31]
    var sky: Array[Color]=[
        Color("#253945"),Color("#3d3037"),Color("#101724")]
    var n: int=clampi(_p06_light_v22,0,2)
    var cloud: float=1.0
    if _p06_weather_v22=="rain":
        cloud=0.61
    elif _p06_weather_v22=="snow":
        cloud=0.77
    hq_key_light.rotation_degrees=Vector3(
        [-49.0,-17.0,-27.0][n],-32.0,0)
    hq_key_light.light_color=palette[n]
    hq_key_light.light_energy=key[n]*cloud
    hq_key_light.shadow_enabled=true
    hq_fill_light.light_color=ambient[n]
    hq_fill_light.light_energy=fill[n]*(
        0.82 if _p06_weather_v22=="rain" else 1.0)
    if hq_environment!=null and hq_environment.environment!=null:
        var scene: Environment=hq_environment.environment
        scene.background_color=sky[n]
        scene.ambient_light_color=ambient[n]
        scene.ambient_light_energy=(
            0.78 if n==0 else (0.59 if n==1 else 0.46))
        if _p06_weather_v22=="rain":
            scene.background_color=scene.background_color.lerp(
                Color("#253645"),0.67)
            scene.ambient_light_color=scene.ambient_light_color.lerp(
                Color("#97b3ca"),0.48)
        elif _p06_weather_v22=="snow":
            scene.background_color=scene.background_color.lerp(
                Color("#8499ab"),0.48)
            scene.ambient_light_color=scene.ambient_light_color.lerp(
                Color("#dae5f0"),0.54)
    for lamp in hq_night_lamps:
        lamp.visible=false
    if _p06_night_fill_v22!=null:
        _p06_night_fill_v22.visible=(n==2)
        _p06_night_fill_v22.light_energy=(
            0.96 if _p06_weather_v22=="clear" else 1.16)

func _inspect_p06_turret() -> void:
    if _role!="apc":
        return
    _view_p06_angle(34.0)
    # The orthographic camera zooms by adjusting its frustum, not distance.
    _zoom=2.05
    _update_camera()

func _inspect_p06_wheels() -> void:
    if _role!="apc":
        return
    _view_p06_angle(90.0)
    # Keep all three axles in view; no misleading 2D model rendering.
    _zoom=1.43
    _update_camera()

func _inspect_p06_tread_v23() -> void:
    if _role!="apc":
        return
    _view_p06_angle(96.0)
    _zoom=2.08
    _update_camera()

func _inspect_p06_sidewall_v23() -> void:
    if _role!="apc":
        return
    _view_p06_angle(81.0)
    _zoom=2.16
    _update_camera()

func _inspect_p06_opposite_v23() -> void:
    if _role!="apc":
        return
    _view_p06_angle(-94.0)
    _zoom=1.85
    _update_camera()

func _inspect_p06_snow_v23() -> void:
    if _role!="apc":
        return
    _set_p06_weather_v22("snow")
    _view_p06_angle(106.0)
    _zoom=1.94
    _update_camera()

func _inspect_p06_shoulders_v24() -> void:
    if _role!="apc":
        return
    _view_p06_angle(102.0)
    _zoom=2.16
    _update_camera()

func _inspect_p06_sidegrooves_v24() -> void:
    if _role!="apc":
        return
    _view_p06_angle(-84.0)
    _zoom=2.22
    _update_camera()

func _inspect_p06_arch_lips_v24() -> void:
    if _role!="apc":
        return
    _view_p06_angle(91.0)
    _zoom=2.00
    _update_camera()

func _inspect_p06_wet_lips_v24() -> void:
    if _role!="apc":
        return
    _set_p06_weather_v22("rain")
    _view_p06_angle(104.0)
    _zoom=2.02
    _update_camera()

func _inspect_p06_sealed_v25() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(89.0)
    _zoom=2.18
    _update_camera()

func _inspect_p06_inside_v25() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(-89.0)
    _zoom=2.20
    _update_camera()

func _inspect_p06_six_v25() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(98.0)
    _zoom=1.36
    _update_camera()

func _inspect_p06_gap_v25() -> void:
    if _role!="apc":
        return
    _set_damage(0)
    _view_p06_angle(122.0)
    _zoom=2.16
    _update_camera()

func _inspect_p06_suspension() -> void:
    if _role!="apc":
        return
    _view_p06_angle(69.0)
    _zoom=1.63
    _update_camera()

func _inspect_p06_underside() -> void:
    if _role!="apc":
        return
    _view_p06_angle(24.0)
    if model_root!=null:
        # Rotate real mesh to reveal the blast belly from the normal fixed
        # studio camera; do not generate a fake 2D underside illustration.
        model_root.rotation_degrees.x=165.0
        _zoom=1.36
        _update_camera()

func _inspect_p06_transfer() -> void:
    if _role!="apc":
        return
    _view_p06_angle(-18.0)
    if model_root!=null:
        model_root.rotation_degrees.x=157.0
        _zoom=1.96
        _update_camera()

func _toggle_p06_ramp() -> void:
    if not _studio_p06() or _stage_p06() >= 4:
        return
    var opened: bool = bool(model_root.get_meta(
        "tarvoka_apc_ramp_open",false))
    _play("close_ramp" if opened else "open_ramp")

func _play(kind: String) -> void:
    if _role != "apc":
        super._play(kind)
        return
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if not _studio_p06():
        return
    if _stage_p06() >= 4 and kind not in ["hit_bullet","hit_explosive"]:
        status_label.text = "Bastión destruido · reparar antes de mover o disparar"
        return
    P06Audio.stop(model_root)
    _animation = kind
    _animation_time = 0.0
    P06Visual.pose(model_root,kind,0.0,42.0)
    P06Finish.animate_impact(model_root,kind,0.0)
    if kind=="attack":
        P06Audio.play(model_root)

func _stop_animation() -> void:
    if _role == "attack_heli":
        _heli_stop()
        return
    if _role == "mlrs":
        _g11_stop()
        return
    if _role != "apc":
        super._stop_animation()
        return
    _animation = ""
    _animation_time = 0.0
    if _studio_p06():
        P06Audio.stop(model_root)
        P06Visual.restore(model_root)
        P06Finish.animate_impact(model_root,"",1.0)
        _sync_p06_controls()

func _process(delta: float) -> void:
    super._process(delta)
    if _role=="attack_heli" and HeliV13.has_model(model_root):
        _heli_damage_clock+=maxf(0.0,delta)
        if _heli_animation.is_empty():
            HeliV13.animate_ambient(model_root,_heli_damage_clock)
    if _role=="attack_heli" and not _heli_animation.is_empty() and HeliV1.has_model(model_root):
        _heli_time+=maxf(0.0,delta)*_heli_playback_speed
        var duration: float=(HeliV13.DESTROY_DURATION if _heli_animation=="destroy" else (
            HeliV1.MOVE_DURATION if _heli_animation=="move" else (
            HeliV1.ATTACK_DURATION if _heli_animation in ["attack","fire_missiles"] else HeliV1.HIT_DURATION)))
        var t: float=minf(1.0,_heli_time/maxf(0.01,duration))
        var native_kind: String="hover" if _heli_animation=="fire_missiles" else _heli_animation
        if HeliV13.has_model(model_root):
            HeliV13.pose(model_root,native_kind,t)
            if HeliCombatV14.has_model(model_root):
                HeliCombatV14.pose(model_root,_heli_animation,t)
        else:
            HeliV1.pose(model_root,native_kind,t)
        if t>=1.0:
            if _heli_animation=="destroy":
                _heli_wreck_frozen=true
                _heli_animation=""
                _heli_time=0.0
            else:
                _heli_stop()
            _update_details()
    if _role == "mlrs" and model_root != null and _g11_animation.is_empty() and G11Art.stage(model_root) >= 2:
        _g11_fx_clock += maxf(0.0,delta)
        G11Atmos.animate(model_root,"idle",fmod(_g11_fx_clock/2.2,1.0))
    if _role == "mlrs" and not _g11_animation.is_empty() and G11Rig.has_rig(model_root):
        _g11_time += maxf(0.0,delta)*_g11_playback_speed
        var duration: float = G11Rig.MOVE_DURATION if _g11_animation == "move" else (
            G11Rig.SHOT_DURATION if _g11_animation == "attack" else (
            G11Rig.COOLDOWN_DURATION if _g11_animation == "cooldown" else G11Rig.IMPACT_DURATION))
        var t: float = minf(1.0,_g11_time/maxf(duration,0.01))
        G11Rig.pose(model_root,_g11_animation,t)
        if t >= 1.0:
            if _g11_animation == "attack" and G11Art.stage(model_root) < 4:
                # Preserve the end of the rocket salvo and continue directly
                # with a separate slow mechanical return to the home pose.
                _g11_animation = "cooldown"
                _g11_time = 0.0
                G11Rig.pose(model_root,"cooldown",0.0)
            else:
                _g11_stop()
                _update_details()
    if _p06_fleet!=null:
        if not _p06_fleet_animation.is_empty():
            _p06_fleet_animation_time+=maxf(0.0,delta)
            var fleet_duration: float=P06Visual.MOVE_DURATION if (
                _p06_fleet_animation=="move_turn") else P06Visual.SHOT_DURATION
            var fleet_progress: float=minf(1.0,
                _p06_fleet_animation_time/maxf(0.01,fleet_duration))
            for node in _p06_fleet.get_children():
                var unit: Node3D=node as Node3D
                if unit!=null:
                    P06Tactical.pose(unit,_p06_fleet_animation,
                        fleet_progress,Vector2i(1,-1))
            if fleet_progress>=1.0:
                _p06_fleet_animation=""
                for node in _p06_fleet.get_children():
                    var unit: Node3D=node as Node3D
                    if unit!=null:
                        P06Tactical.restore(unit)
        _p06_fleet_update_clock+=maxf(0.0,delta)
        if _p06_fleet_update_clock>=0.25:
            _p06_fleet_update_clock=0.0
            if _p06_fleet_quality<0:
                _refresh_p06_fleet_quality()
        # Collect actual in-viewport FPS on the user device (mobile WebGL
        # if opened in Android Chrome); never present it as native APK FPS.
        _p06_fleet_fps_clock+=maxf(0.0,delta)
        if _p06_fleet_fps_clock>=1.0:
            _p06_fleet_fps_clock=0.0
            _p06_fleet_fps_sample=Engine.get_frames_per_second()
            _update_details()
        return
    if not _studio_p06():
        return
    if _stage_p06() >= 2:
        _effect_time += maxf(0.0,delta)
        P06Finish.animate_damage(model_root,_effect_time)
    if _animation.is_empty():
        return
    _animation_time += maxf(0.0,delta)
    var duration: float = P06Visual.MOVE_DURATION
    if _animation in ["open_ramp","close_ramp"]:
        duration = P06Visual.RAMP_DURATION
    elif _animation not in ["move","move_turn"]:
        duration = P06Visual.SHOT_DURATION
    var t: float = minf(1.0,_animation_time/maxf(duration,0.01))
    P06Visual.pose(model_root,_animation,t,42.0)
    P06Finish.animate_impact(model_root,_animation,t)
    if t >= 1.0:
        _stop_animation()
        _update_details()

func _update_details() -> void:
    if _role=="uav_recon" and model_root!=null and detail_label!=null and status_label!=null:
        var built:bool=A01Recon.has_model(model_root) and A01Finish.has_model(model_root)
        detail_label.text="A01 V3 EN DESARROLLO · UAV de reconocimiento sin armas · %d mallas 3D" % P06Models.inspect_meshes(model_root)
        status_label.text="A01 · %s · %s" % [
            str(Factions.FACTIONS[_faction]["name"]),
            "V2 · alas PBR, óptica EO/IR móvil y marcas de facción LOD8/13" if built else "modelo incompleto"]
        return
    if _role=="logistics_mobile" and model_root!=null and detail_label!=null and status_label!=null:
        var ready_g16:bool=G16Logistics.has_model(model_root) and G16ExteriorV2.has_model(model_root) and G16MechanicsV3.has_model(model_root) and G16SculptV4.has_model(model_root) and G16MaterialsV5.has_model(model_root) and G16ServiceV6.has_model(model_root)
        var stage:int=G16MechanicsV3.stage(model_root) if G16MechanicsV3.has_model(model_root) else 0
        detail_label.text="G16 V6 FINAL · Logística blindada 6×6 · %d mallas · daño %d/4" % [
            P06Models.inspect_meshes(model_root),stage]
        status_label.text="G16 · %s · %s" % [
            str(Factions.FACTIONS[_faction]["name"]),
            "V6 · manguera articulada PBR y 4 etapas de daño (vista sin consumo de recursos)" if ready_g16 else "acabado V6 incompleto"]
        return
    if _role=="ew_mobile" and model_root!=null and detail_label!=null and status_label!=null:
        var ready:bool=bool(model_root.get_meta(G15DetailV11.FLAG,false))
        detail_label.text="G15 V11C FINAL · Guerra electrónica · 6×6 · %d mallas nativas" % P06Models.inspect_meshes(model_root)
        status_label.text="G15 · %s · %s" % [str(Factions.FACTIONS[_faction]["name"]),"V11C · ocho colores de facción reforzados, blindaje cerrado" if ready else "acabado incompleto"]
        return
    if _role == "attack_heli":
        if model_root == null or detail_label == null or status_label == null:
            return
        # Report the VISIBLE sculpt stage. An installed but hidden V12 root
        # must never be described as active after the V11 comparison toggle.
        var current_stage: String="V1 · casco básico"
        if HeliV2.has_model(model_root) and _heli_v2_enabled:
            current_stage="V2 · cabina y casco"
        if HeliV6.has_model(model_root) and _heli_v2_enabled:
            current_stage="V6 · tren y motores"
        if HeliV7.has_model(model_root) and _heli_v2_enabled and _heli_v7_enabled:
            current_stage="V7 · identidad a 360p"
        if HeliV8.has_model(model_root) and _heli_v2_enabled and _heli_v8_enabled:
            current_stage="V8 · identidad a 320p"
        if HeliV10.has_model(model_root) and bool(model_root.get_meta(HeliV10.ENABLED,false)):
            current_stage="V10 · acabados ópticos"
        if HeliV11.has_model(model_root) and bool(model_root.get_meta(HeliV11.ENABLED,false)):
            current_stage="V11 · transmisión y lanzadores"
        if HeliV12.has_model(model_root) and bool(model_root.get_meta(HeliV12.ENABLED,false)):
            current_stage="V12 · morro y cañón articulado"
        var damage_text: String=""
        if HeliV13.has_model(model_root):
            damage_text=" · daño: %s" % HeliV13.STAGE_LABELS[HeliV13.stage(model_root)]
        detail_label.text="Helicóptero A01 · %s · %d mallas nativas · rotor y armas 3D%s" % [
            current_stage,P06Models.inspect_meshes(model_root),damage_text]
        status_label.text="%s · escultura %s cargada%s" % [
            str(Factions.FACTIONS[_faction]["name"]),current_stage,damage_text]
        return
    if _role == "mlrs":
        if model_root == null or detail_label == null or status_label == null:
            return
        var built: bool = G11Art.has_model(model_root)
        detail_label.text = "G11 Lanzador · 12 tubos · %d mallas 3D · %s" % [
            P06Models.inspect_meshes(model_root),
            "salva V8" if built and bool(model_root.get_meta(
                "tarvoka_g11_salvo_v8",false)) else (
                "escultura V7" if built and bool(model_root.get_meta(
                    "tarvoka_g11_atmosphere_v7",false)) else (
                "escultura V6" if built and bool(model_root.get_meta(
                    "tarvoka_g11_damage_v6",false)) else (
                "escultura V5" if built and bool(model_root.get_meta(
                    "tarvoka_g11_mechanics_v5",false)) else (
                "escultura V4" if built and bool(model_root.get_meta(
                    "tarvoka_g11_geometry_v4",false)) else (
                "acabado V3" if built and bool(model_root.get_meta(
                    "tarvoka_g11_surface_v3",false)) else (
                "acabado V2" if built and bool(model_root.get_meta(
                    "tarvoka_g11_finish_v2",false)) else (
                    "escultura V1" if built else "LOD provisional")))))))]
        if model_root!=null and G11Mobile.has_model(model_root):
            detail_label.text="G11 V24 · representación táctica LOD %d · 12 tubos · dos orugas" % _g11_preview_lod_v24
        elif built and bool(model_root.get_meta("tarvoka_g11_joint_finish_v23",false)):
            detail_label.text = detail_label.text.replace("salva V8","pasadores y retenes PBR V23")
        elif built and bool(model_root.get_meta("tarvoka_g11_suspension_joints_v22",false)):
            detail_label.text = detail_label.text.replace("salva V8","articulaciones reales V22")
        elif built and bool(model_root.get_meta("tarvoka_g11_shock_mount_finish_v21",false)):
            detail_label.text = detail_label.text.replace("salva V8","anclajes y muelles V21")
        elif built and bool(model_root.get_meta("tarvoka_g11_wheel_suspension_v20",false)):
            detail_label.text = detail_label.text.replace("salva V8","llantas y suspensión V20")
        elif built and bool(model_root.get_meta("tarvoka_g11_track_finish_v19",false)):
            detail_label.text = detail_label.text.replace("salva V8","acabado real de orugas V19")
        elif built and bool(model_root.get_meta("tarvoka_g11_track_clearance_v18",false)):
            detail_label.text = detail_label.text.replace("salva V8","orugas integradas V18")
        elif built and bool(model_root.get_meta("tarvoka_g11_surface_weather_v17",false)):
            detail_label.text = detail_label.text.replace("salva V8","acabados y pintura V17")
        elif built and bool(model_root.get_meta("tarvoka_g11_front_frame_v16",false)):
            detail_label.text = detail_label.text.replace("salva V8","acabados V16")
        elif built and bool(model_root.get_meta("tarvoka_g11_aft_pod_finish_v15",false)):
            detail_label.text = detail_label.text.replace("salva V8","bastidor y acabados V15")
        elif built and bool(model_root.get_meta("tarvoka_g11_mechanical_detail_v14",false)):
            detail_label.text = detail_label.text.replace("salva V8","hidráulicos V14")
        elif built and bool(model_root.get_meta("tarvoka_g11_tracks_faction_v13",false)):
            detail_label.text = detail_label.text.replace("salva V8","engranes y facción V13")
        elif built and bool(model_root.get_meta("tarvoka_g11_cab_chassis_v12",false)):
            detail_label.text = detail_label.text.replace("salva V8","cabina V12")
        elif built and bool(model_root.get_meta("tarvoka_g11_armor_finish_v11",false)):
            detail_label.text = detail_label.text.replace("salva V8","acabados V11")
        elif built and bool(model_root.get_meta("tarvoka_g11_cooldown_v10",false)):
            detail_label.text = detail_label.text.replace("salva V8","enfriamiento V10")
        elif built and bool(model_root.get_meta("tarvoka_g11_exhaust_v9",false)):
            detail_label.text = detail_label.text.replace("salva V8","estelas V9")
        status_label.text = "%s · %s · %s" % [
            str(Factions.FACTIONS[_faction]["name"]),
            G11Art.STAGES[G11Art.stage(model_root)],
            "modelo real cargado" if built else "sin modelo de estudio"]
        return
    if _role != "apc":
        super._update_details()
        return
    if _p06_fleet!=null and detail_label!=null and status_label!=null:
        detail_label.text="Bastión V9 · %d vehículos · %d/%d superficies visibles" % [
            _p06_fleet_count,_p06_fleet_active_surfaces,_p06_fleet_surfaces]
        var tier_name: String=(
            "automático" if _p06_fleet_quality<0 else
            ["cerca","media","lejos"][_p06_fleet_quality])
        var fps_text: String=("muestreando" if _p06_fleet_fps_sample<0
            else str(_p06_fleet_fps_sample))
        status_label.text="LOD %s · FPS del visor %s · carga %.1f ms · NO FPS APK" % [
            tier_name,fps_text,_p06_fleet_build_ms]
        return
    if model_root == null or detail_label == null or status_label == null:
        return
    var mesh_count: int = P06Models.inspect_meshes(model_root)
    var true_v5: bool = bool(model_root.get_meta(P06Details.FLAG,false))
    detail_label.text = "Bastión P06 · %d mallas 3D · 6 ruedas · %s" % [
        mesh_count,"V25 completo" if true_v5 and _p06_show_v5 else
        "V3 de comparación"]
    var faction_name: String = str(Factions.FACTIONS[_faction]["name"])
    status_label.text = "%s · %s · %s" % [
        faction_name,P06Stages[_stage_p06()],
        "acabado V25 cargado" if _p06_quality_verified else
        "ERROR: modelo final no cargado"]

# G15 visual-only rig: same shared native 3D viewport as all other units.
# No BattleSession ability is invoked by these previews.
func _g15_play(kind: String) -> void:
    if _role!="ew_mobile" or model_root==null or not G15EW.has_model(model_root):
        return
    if kind not in ["move","deploy","scan","jam","damage","idle"]:
        return
    if _g15_tween!=null and _g15_tween.is_running():
        _g15_tween.kill()
    var art:Node3D=model_root
    P06Models.restore_model_pose("ew_mobile",art)
    if kind=="idle":
        return
    _g15_tick(0.0,art,kind)
    _g15_tween=art.create_tween()
    _g15_tween.tween_method(
        Callable(self,"_g15_tick").bind(art,kind),0.0,1.0,
        1.9 if kind in ["deploy","scan"] else 1.2)
    _g15_tween.tween_callback(Callable(self,"_g15_finish").bind(art))
    status_label.text="G15 · "+kind+" · demostración visual sin combate"

func _g15_tick(t: float,art: Node3D,kind: String) -> void:
    if is_instance_valid(art):
        P06Models.pose_model("ew_mobile",art,kind,t)

func _g15_finish(art: Node3D) -> void:
    if is_instance_valid(art):
        P06Models.restore_model_pose("ew_mobile",art)

# Original shared Godot 3D Studio: G16 previews only, NEVER tactical resupply.
func _g16_play(kind: String) -> void:
    if _role!="logistics_mobile" or model_root==null or not G16Logistics.has_model(model_root):
        return
    if kind not in G16Logistics.VALID_POSES:
        return
    if _g16_tween!=null and _g16_tween.is_running():
        _g16_tween.kill()
    var art:Node3D=model_root
    P06Models.restore_model_pose("logistics_mobile",art)
    if kind=="idle":
        return
    P06Models.pose_model("logistics_mobile",art,kind,0.02)
    _g16_tween=art.create_tween()
    _g16_tween.tween_method(
        Callable(self,"_g16_tick").bind(art,kind),0.02,0.98,
        2.10 if kind in ["camp","unload","resupply"] else 1.30)
    _g16_tween.tween_callback(Callable(self,"_g16_done").bind(art,kind))
    status_label.text="G16 V6 · "+kind+" · simulación 3D de suministros, sin aplicar recursos"

func _g16_tick(t:float,art:Node3D,kind:String)->void:
    if is_instance_valid(art):
        P06Models.pose_model("logistics_mobile",art,kind,t)

func _g16_done(art:Node3D,kind:String)->void:
    if not is_instance_valid(art):
        return
    # The deployed hose/crane used to disappear after 2.1 seconds, making
    # 360-degree visual review impossible. Keep service and unload poses
    # fully open until the actual Stop/Pack action is requested.
    if kind in ["deploy","camp","resupply","unload"]:
        P06Models.pose_model("logistics_mobile",art,kind,1.0)
    else:
        P06Models.restore_model_pose("logistics_mobile",art)


# V4 native physical wreck sequence: the exact rig shown in the same
# unified Godot Studio moves torn armor fragments and exhaust plumes.
# Never touches HP or writes tactical economy data.
func _g16_v4_destroy() -> void:
    if _role!="logistics_mobile" or model_root==null or not G16SculptV4.has_model(model_root):
        return
    if _g16_tween!=null and _g16_tween.is_running():
        _g16_tween.kill()
    var art:Node3D=model_root
    P06Models.restore_model_pose("logistics_mobile",art)
    G16ExteriorV2.show_finish(art,true)
    G16MechanicsV3.show_finish(art,true)
    G16SculptV4.show_finish(art,true)
    if G16MaterialsV5.has_model(art):
        G16MaterialsV5.show_finish(art,true)
        G16MaterialsV5.set_damage(art,0)
    else:
        G16SculptV4.set_damage(art,0)
    _g16_tween=art.create_tween()
    _g16_tween.tween_method(Callable(self,"_g16_v4_tick").bind(art),
        0.0,1.0,2.80)
    _g16_tween.tween_callback(Callable(self,"_g16_v4_done").bind(art))
    status_label.text="G16 V4 · destrucción física 3D en curso · simulación visual"

func _g16_v4_tick(t:float,art:Node3D)->void:
    if is_instance_valid(art) and G16SculptV4.has_model(art):
        if G16MaterialsV5.has_model(art):
            G16MaterialsV5.pose_wreck(art,t)
        else:
            G16SculptV4.pose_wreck(art,t)
        # Existing closed cab stays at every stage; shake the whole model.
        art.rotation_degrees.z=sin(t*TAU*6.0)*1.2*(1.0-t)

func _g16_v4_done(art:Node3D)->void:
    if not is_instance_valid(art):
        return
    art.rotation_degrees.z=0
    if G16MaterialsV5.has_model(art):
        G16MaterialsV5.pose_wreck(art,1.0)
    else:
        G16SculptV4.pose_wreck(art,1.0)
    status_label.text="G16 V5 · destrucción 4/4 finalizada; Reparar restaura el modelo"
