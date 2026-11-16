extends "res://scripts/ui/CombinedArtStudioWeb.gd"
class_name TarvokaBastionStudioAdapter

# Published P06 presentation uses the sculpted V5 art, not the initial native
# prototype. Other HQ / Airbase / G09 studio categories remain unchanged.
const P06Models = preload("res://scripts/ui/UnitModels3D.gd")
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
const G11ContextV25 = preload("res://scripts/ui/G11BattleContextV25.gd")
const G11LODDriverV25 = preload("res://scripts/ui/G11BattleLODControllerV25.gd")
const G11ActionsV29 = preload("res://scripts/ui/G11BattleActionsV29.gd")
const G11AuditV33 = preload("res://scripts/ui/G11FinalAuditV33.gd")
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
var _heli_v10_rim_light: DirectionalLight3D
var _heli_camera_base: Vector3=Vector3.ZERO
var _heli_focus_local: Vector3=Vector3.ZERO
var _heli_compare_button: Button
var _heli_animation: String=""
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
var _g13_v4_tween: Tween
var _g11_animation: String = ""
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
        role_picker.set_item_text(aa_index,"G13 · Antiaéreo V11")
    var heli_index: int=P06Models.ROLES.find("attack_heli")
    if heli_index >= 0:
        role_picker.set_item_text(heli_index,"Helicóptero A01 · V11")
    var idx: int = P06Models.ROLES.find("apc")
    if idx >= 0:
        role_picker.set_item_text(idx,"Bastión P06 · V25")
    var tank_index: int = P06Models.ROLES.find("tank")
    if tank_index >= 0:
        role_picker.set_item_text(tank_index,"Tanque G09 · V32 FINAL")
    # The project home link now opens the model under review rather than
    # showing the old default G09 first and confusing Android users.
    _display_role("apc")
    _refresh_unified_studio_navigation()

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
    studio_animation_panel.add_theme_constant_override("separation",6)
    studio_quick_panel.add_child(studio_animation_panel)
    var action_row:=HBoxContainer.new()
    action_row.add_theme_constant_override("separation",6)
    studio_animation_panel.add_child(action_row)
    var move_button: Button=_button(action_row,"Mover",func(): _studio_quick_action("move"))
    studio_attack_button=_button(action_row,"Atacar",func(): _studio_quick_action("attack"))
    for control in [move_button,studio_attack_button]:
        control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        control.custom_minimum_size.x=0
        control.clip_text=true
    var damage_row:=HBoxContainer.new()
    damage_row.add_theme_constant_override("separation",6)
    studio_animation_panel.add_child(damage_row)
    studio_impact_button=_button(damage_row,"Impacto",func(): _studio_quick_action("hit"))
    var stop_button: Button=_button(damage_row,"Detener",_studio_quick_stop)
    for control in [studio_impact_button,stop_button]:
        control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        control.custom_minimum_size.x=0
        control.clip_text=true
    studio_g13_ground_button=_button(studio_animation_panel,
        "G13 · Disparo terrestre",func(): _studio_quick_action("attack_ground"))
    studio_g13_ground_button.visible=false
    studio_camera_panel=VBoxContainer.new()
    studio_camera_panel.add_theme_constant_override("separation",6)
    studio_quick_panel.add_child(studio_camera_panel)
    _add_paired(studio_camera_panel,"↶ 45°",func(): _rotate(-45.0),
        "45° ↷",func(): _rotate(45.0))
    _add_paired(studio_camera_panel,"Alejar",func(): _change_zoom(-1),
        "Acercar",func(): _change_zoom(1))
    _button(studio_camera_panel,"Restablecer cámara",_reset_camera)

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

func _studio_quick_action(kind: String) -> void:
    if model_root==null or category_picker==null or category_picker.selected!=0:
        return
    match _role:
        "attack_heli":
            _heli_play("hit_bullet" if kind=="hit" else kind)
        "mlrs":
            _g11_play("hit_bullet" if kind=="hit" else kind)
        "apc":
            _play("hit_bullet" if kind=="hit" else kind)
        "aa_mobile":
            var visual_kind: String=(
                "attack_ground" if kind=="attack_ground" else
                "attack_air" if kind=="attack" else
                "move" if kind=="move" else "idle")
            _g13_demo_v1(visual_kind,0.65)
        _:
            _play("damaged" if kind=="hit" else kind)

func _studio_quick_stop() -> void:
    if _role=="attack_heli":
        _heli_stop()
    elif _role=="mlrs":
        _g11_stop()
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
            "tank": label="G09 · Tanque · V32 final"
            "apc": label="P06 · Bastión · V25"
            "mlrs": label="G11 · Lanzador · V33"
            "attack_heli": label="A01 · Helicóptero · V11"
            "aa_mobile": label="G13 · Antiaéreo · diseño en progreso"
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
    if studio_animation_panel!=null:
        studio_animation_panel.visible=not building and studio_active_tab==0
    if studio_attack_button!=null:
        studio_attack_button.text="Disparo aéreo" if _role=="aa_mobile" else "Atacar"
    if studio_impact_button!=null:
        studio_impact_button.text="Restaurar" if _role=="aa_mobile" else "Impacto"
    if studio_g13_ground_button!=null:
        studio_g13_ground_button.visible=not building and _role=="aa_mobile" and studio_active_tab==0

func _install_heli_controls() -> void:
    var column: VBoxContainer=role_picker.get_parent() as VBoxContainer
    heli_controls=VBoxContainer.new()
    heli_controls.name="A01_HelicopteroAtaque_V2_Studio"
    heli_controls.add_theme_constant_override("separation",8)
    column.add_child(heli_controls)
    _title(heli_controls,"HELICÓPTERO A01 · V11 · TREN DE COLA Y ARMAMENTO",14)
    _add_paired(heli_controls,"Vuelo y rotores",func(): _heli_play("move"),
        "Ráfaga frontal",func(): _heli_play("attack"))
    _add_paired(heli_controls,"Impactos de bala",func(): _heli_play("hit_bullet"),
        "Impacto explosivo",func(): _heli_play("hit_explosive"))
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
    _heli_v11_button=_button(heli_controls,
        "Comparar mecánica V10 / V11",_heli_toggle_v11)
    _heli_v10_button=_button(heli_controls,"Comparar acabados V8 / V10",_heli_toggle_v10)
    _heli_v8_button=_button(heli_controls,"Comparar identidad V7 / V8",_heli_toggle_v8)
    _heli_v7_button=_button(heli_controls,"Comparar legibilidad V6 / V7",_heli_toggle_v7)
    _heli_compare_button=_button(heli_controls,"Comparar casco anterior V1",_heli_toggle_v2)
    _button(heli_controls,"Detener y restaurar hélices",_heli_stop)
    _title(heli_controls,
        "V11: transmisión real de cola, bielas de paso y collares de lanzadores; "
        + "conserva cristales V10 y mecánica original. Solo arte 3D de Estudio.",12)
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
        role_picker.set_item_text(role_index,"Helicóptero A01 · V11")
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
    _sync_p06_controls()
    _update_details()
    _update_camera()

func _heli_toggle_v11() -> void:
    if _role!="attack_heli" or model_root==null or not HeliV11.has_model(model_root):
        return
    _heli_stop()
    _heli_v11_enabled=not _heli_v11_enabled
    HeliV11.set_enabled(model_root,_heli_v2_enabled and _heli_v10_enabled and _heli_v11_enabled)
    _sync_p06_controls()
    _update_details()
    _update_camera()

func _heli_inspect(yaw: float,tilt: float,zoom_level: float) -> void:
    if _role!="attack_heli" or model_root==null:
        return
    _heli_stop()
    _heli_focus_local=Vector3.ZERO
    _yaw=yaw
    _zoom=zoom_level
    model_root.rotation_degrees=Vector3(tilt,yaw,0.0)
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
    _heli_stop()
    _yaw=yaw
    model_root.rotation_degrees=Vector3(0,yaw,0)
    _heli_focus_local=Vector3.ZERO
    _update_camera()

func _heli_top_view() -> void:
    if _role!="attack_heli" or model_root==null:
        return
    _heli_stop()
    _yaw=38.0
    model_root.rotation_degrees=Vector3(43.0,_yaw,0.0)
    _heli_focus_local=Vector3.ZERO
    _update_camera()

func _heli_play(kind: String) -> void:
    if _role!="attack_heli" or model_root==null or not HeliV1.has_model(model_root):
        return
    _heli_animation=kind
    _heli_time=0.0
    HeliV1.pose(model_root,kind,0.0)

func _heli_stop() -> void:
    _heli_animation=""
    _heli_time=0.0
    if model_root!=null and HeliV1.has_model(model_root):
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

func _install_g13_controls() -> void:
    var column:=role_picker.get_parent() as VBoxContainer
    g13_controls=VBoxContainer.new()
    g13_controls.name="G13_AntiaereoMovil_V4_DosTiposDeAtaque"
    g13_controls.add_theme_constant_override("separation",8)
    column.add_child(g13_controls)
    var title: Label=_title(g13_controls,
        "G13 ANTIAÉREO MÓVIL · ATAQUES TIERRA/AIRE V4",14)
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
    _title(g13_controls,
        "V4: el mismo G13 dispara a tierra con cañones bajos y "
        + "ráfagas más espaciadas, o al aire con elevación alta, "
        + "radar de seguimiento y cadencia más rápida. Destellos, "
        + "humo transparente y retroceso mínimo de los dos cañones. "
        + "Es una simulación visual: aún no ejecuta daño en batalla.",12)
    g13_controls.visible=false

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
    # All eight units and the buildings share the SAME viewport and camera.
    # For the native G09 V32, V25 materials + V30 damage + V31 inboard
    # geometry activate the final V32 animation rig in TankVisualRig3D.gd.
    # The current CombinedArtStudioWeb base has no _v25/_v30/_v31
    # switches: these unused legacy writes broke real Studio import.
    # Tank rendering continues through the base role-selection code.
    if _g11_context_v25!=null:
        _g11_clear_battle_context_v25()
    if _g13_v4_tween!=null and _g13_v4_tween.is_running():
        _g13_v4_tween.kill()
    if role!="mlrs":
        _g11_preview_lod_v24=13
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if role!="attack_heli" and _role=="attack_heli" and camera!=null:
        camera.position=_heli_camera_base
        _heli_focus_local=Vector3.ZERO
    super._display_role(role)
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
            preview.add_child(model_root)
            model_root.rotation_degrees.y=_yaw
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
        model_root=P06Models.build("aa_mobile",_faction,true,13)
        if model_root!=null:
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
    _sync_p06_controls()
    _update_details()
    _refresh_unified_studio_navigation()

func _switch_category(index: int) -> void:
    super._switch_category(index)
    # The parent directly chooses tank when switching to Units. Rebuild
    # the native approved art after the parent's legacy category transition.
    if index == 0 and _role == "tank":
        _display_role("tank")
    _sync_p06_controls()
    _refresh_unified_studio_navigation()

func _on_faction(index: int) -> void:
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
    if _role=="attack_heli" and not _heli_animation.is_empty() and HeliV1.has_model(model_root):
        _heli_time+=maxf(0.0,delta)
        var duration: float=HeliV1.MOVE_DURATION if _heli_animation=="move" else (
            HeliV1.ATTACK_DURATION if _heli_animation=="attack" else HeliV1.HIT_DURATION)
        var t: float=minf(1.0,_heli_time/maxf(0.01,duration))
        HeliV1.pose(model_root,_heli_animation,t)
        if t>=1.0:
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
    if _role == "attack_heli":
        if model_root == null or detail_label == null or status_label == null:
            return
        detail_label.text="Helicóptero A01 · %s · %d mallas nativas · rotor y armas 3D" % [
            "V11 cola y armamento" if HeliV11.has_model(model_root) and _heli_v2_enabled and _heli_v11_enabled and _heli_v10_enabled else (
                "V8 identidad a 320p" if HeliV8.has_model(model_root) and _heli_v2_enabled and _heli_v8_enabled else (
                "V7 identidad a 360p" if HeliV7.has_model(model_root) and _heli_v2_enabled and _heli_v7_enabled else (
                "V6 comparación táctica" if HeliV6.has_model(model_root) and _heli_v2_enabled else "V1 comparación"))),
            P06Models.inspect_meshes(model_root)]
        status_label.text="%s · %s" % [
            str(Factions.FACTIONS[_faction]["name"]),
            "escultura V11 cargada" if HeliV11.has_model(model_root) else (
                "escultura V8 cargada" if HeliV8.has_model(model_root) else (
                "escultura V7 cargada" if HeliV7.has_model(model_root) else (
                "escultura V6 cargada" if HeliV6.has_model(model_root) else (
                "escultura V5 cargada" if HeliV5.has_model(model_root) else (
                "escultura V4 cargada" if HeliV4.has_model(model_root) else (
                "escultura V3 cargada" if HeliV3.has_model(model_root) else (
                "escultura V2 cargada" if HeliV2.has_model(model_root) else (
                "escultura V1 cargada" if HeliV1.has_model(model_root) else "modelo detallado sin cargar"))))))))]
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
