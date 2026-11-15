extends Control
class_name TarvokaArtStudioWeb

# Fast, installation-free model review. This uses the exact same models,
# faction palettes, MBT animation rig and five visual damage stages as Android.
# No duplicated Three.js meshes and no tactical game/save dependencies.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Roles = preload("res://scripts/core/UnitRoles.gd")
const Factions = preload("res://scripts/ui/VisualStyle.gd")
const TankDamage = preload("res://scripts/ui/TankDamage3D.gd")
const TankRig = preload("res://scripts/ui/TankVisualRig3D.gd")
const HitV30 = preload("res://scripts/ui/TankHitReactionV30.gd")
const APCVisual = preload("res://scripts/ui/APCVisualRigV1.gd")
const APCFinishV3 = preload("res://scripts/ui/APCFinishV3.gd")
const HQMixedStress = preload("res://scripts/ui/Headquarters3D.gd")
const HQLod = preload("res://scripts/ui/HeadquartersTacticalLOD.gd")
const PerfTelemetry=preload("res://scripts/ui/PerformanceTelemetryV1.gd")
const AndroidBenchmarkSuite=preload("res://scripts/ui/AndroidBenchmarkSuiteV2.gd")
const TankV17 = preload("res://scripts/ui/TankFXV17.gd")
const ClayV19 = preload("res://scripts/ui/TankClayV19.gd")
const BattleScenarioV26 = preload("res://scripts/ui/TankBattleScenarioV26.gd")

var model_root: Node3D
var preview: SubViewport
var camera: Camera3D
var battle_scenario: TarvokaTankBattleScenarioV26
var scenario_button: Button
var terrain_picker: OptionButton
var light_picker: OptionButton
var model_holder: SubViewportContainer
var role_picker: OptionButton
var faction_picker: OptionButton
var damage_picker: OptionButton
var revision_label: Label
var detail_label: Label
var status_label: Label
var _role := "tank"
var _final_detail := true
var _previous_version := false
var _v11_preview := false
var _v12_preview := false
var _v13_preview := false
var _v14_preview := false
var _v15_preview := false
var _v16_preview := false
var _v17_preview := false
var _v18_preview := false
var _v19_preview := false
var _v20_preview := false
var _v21_preview := false
var _v22_preview := false
var _v23_preview := false
var _v24_preview := false
var _v25_preview := false
var _v30_preview := false
var _v31_preview := false
var _apc_v1_preview := true
var _apc_v2_preview := true
var _apc_v3_preview := true
var _apc_damage_stage := 0
var _apc_tactical_lod := false
var apc_controls: VBoxContainer
var apc_compare_button: Button
var apc_v2_button: Button
var apc_v3_button: Button
var apc_damage_button: Button
var apc_lod_button: Button
var apc_stress_button: Button
var apc_mixed_button: Button
var _apc_mixed_enabled: bool=false
var _apc_mixed_group: Node3D
var apc_stress_label: Label
var apc_perf_button: Button
var _apc_perf=PerfTelemetry.new()
var _auto_benchmark=AndroidBenchmarkSuite.new()
var _auto_benchmark_button: Button
var _auto_internal_change: bool=false
var _auto_benchmark_report_path: String=""
var _apc_stress_group: Node3D
var _apc_stress_units: Array[Node3D]=[]
var _apc_stress_count: int=0
var _apc_stress_elapsed: float=0.0
var _apc_stress_sample: float=0.0
var apc_ramp_button: Button
var _tactical_view := false
var _underside_view := false
var _scenario_enabled := false
var _scenario_terrain := 0
var _scenario_light := 0
var _clay_review := false
var _v17_eco := false
var v11_button: Button
var v12_button: Button
var v13_button: Button
var v14_button: Button
var v15_button: Button
var v16_button: Button
var v17_button: Button
var v18_button: Button
var v19_button: Button
var v20_button: Button
var v21_button: Button
var v22_button: Button
var v23_button: Button
var v24_button: Button
var v25_button: Button
var v30_button: Button
var v31_button: Button
var tactical_button: Button
var underside_button: Button
var clay_button: Button
var v17_quality_button: Button
var comparison_button: Button
var previous_version_button: Button
var _faction := 0
var _yaw := -32.0
var _zoom := 1.0
var _animation := ""
var _animation_time := 0.0
var _effect_time := 0.0
var _touches: Dictionary = {}

func _ready() -> void:
    name = "TARVOKA_3D_ArtStudio"
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _construct()
    _display_role("tank")

func _title(parent: Node, content: String, font_size: int = 17) -> Label:
    var l := Label.new()
    l.text = content
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.add_theme_font_size_override("font_size",font_size)
    parent.add_child(l)
    return l

func _button(parent: Node, caption: String, action: Callable) -> Button:
    var b := Button.new()
    b.text = caption
    b.custom_minimum_size = Vector2(104,44)
    b.pressed.connect(action)
    parent.add_child(b)
    return b

func _add_paired(parent: Node, first: String, first_action: Callable,
        second: String, second_action: Callable) -> void:
    var r := HBoxContainer.new()
    r.add_theme_constant_override("separation",6)
    parent.add_child(r)
    var a := _button(r,first,first_action)
    a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var b := _button(r,second,second_action)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _construct() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color("#0B1720")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)

    var wide: bool = get_viewport().get_visible_rect().size.x >= 770
    var frame: BoxContainer = HBoxContainer.new() if wide else VBoxContainer.new()
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame.add_theme_constant_override("separation",8)
    add_child(frame)

    model_holder = SubViewportContainer.new()
    model_holder.name = "Lienzo3DNativoGodot"
    model_holder.stretch = true
    model_holder.mouse_filter = Control.MOUSE_FILTER_STOP
    model_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    model_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
    model_holder.custom_minimum_size = Vector2(350,290)
    frame.add_child(model_holder)
    model_holder.gui_input.connect(_on_model_input)

    preview = SubViewport.new()
    preview.name = "MotorRealDeTARVOKA"
    preview.size = Vector2i(1000,680)
    preview.own_world_3d = true
    preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    preview.transparent_bg = false
    model_holder.add_child(preview)

    var environment := WorldEnvironment.new()
    var config := Environment.new()
    config.background_mode = Environment.BG_COLOR
    config.background_color = Color("#14232D")
    config.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    config.ambient_light_color = Color("#C1D5DE")
    config.ambient_light_energy = 0.84
    environment.environment = config
    preview.add_child(environment)

    camera = Camera3D.new()
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.position = Vector3(5.3,4.2,6.3)
    preview.add_child(camera)
    camera.look_at(Vector3(0,0.35,0),Vector3.UP)
    camera.current = true

    var key := DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-46,-32,0)
    key.light_energy = 1.65
    preview.add_child(key)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-25,132,0)
    fill.light_energy = 0.8
    preview.add_child(fill)

    # Native battlefield materials; kept entirely outside the tank rig so
    # it never changes the geometry used in Android sprite captures.
    battle_scenario = BattleScenarioV26.new()
    battle_scenario.name = "G09V26EscenarioDeEnsayo"
    preview.add_child(battle_scenario)
    battle_scenario.setup(environment,key,fill)

    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 306.0
    panel.size_flags_horizontal = Control.SIZE_SHRINK_END
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    frame.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    panel.add_child(scroll)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation",9)
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(column)
    _title(column,"TARVOKA · ESTUDIO 3D",21)
    revision_label = _title(column,_version_text(),12)
    _title(column,"El mismo modelo de Godot usado en Android. Arrastra para girar y acerca con dos dedos.",13)

    _title(column,"MODELO",12)
    v11_button = _button(column,"NUEVO G09 V11 · Escultura angular",_toggle_v11)
    v12_button = _button(column,"V12 · Blindaje y materiales refinados",_toggle_v12)
    v13_button = _button(column,"V13 · Faldones segmentados y torreta",_toggle_v13)
    v14_button = _button(column,"V14 · Coraza pronunciada y ruedas activas",_toggle_v14)
    v15_button = _button(column,"V15 · Blindaje integrado sin alas flotantes",_toggle_v15)
    v16_button = _button(column,"V16 · Pintura mate, acero y fuego",_toggle_v16)
    v17_button = _button(column,"V17 · Humo orgánico y rendimiento",_toggle_v17)
    v18_button = _button(column,"V18 · Reconstrucción del casco y la torreta",_toggle_v18)
    v19_button = _button(column,"V19 · Techo, sensores y mantelete",_toggle_v19)
    v20_button = _button(column,"NUEVO V20 · Blindaje integrado y suspensión",_toggle_v20)
    v21_button = _button(column,"V21 · Proa, barbeta y rodaje realista",_toggle_v21)
    v22_button = _button(column,"V22 · Cañón y sistema de retroceso",_toggle_v22)
    v23_button = _button(column,"V23 · Identificación de facción",_toggle_v23)
    v24_button = _button(column,"V24 · Pintura superior táctica",_toggle_v24)
    v25_button = _button(column,"NUEVO V25 · Esmalte, bordes y microdesgaste",_toggle_v25)
    v30_button = _button(column,"V30 · CADENAS ANCHAS Y DAÑO REALISTA",_toggle_v30)
    v31_button = _button(column,"V31 · ORUGAS ALINEADAS HACIA DENTRO",_toggle_v31)
    clay_button = _button(column,"MODO ARCILLA · Ver geometría sin materiales",_toggle_clay)
    v17_quality_button = _button(column,"V17 · Efectos completos",_toggle_v17_quality)
    comparison_button = _button(column,"COMPARAR: Ver modelo base",_toggle_details)
    previous_version_button = _button(column,"COMPARAR: V9 anterior / V10 nuevo",_toggle_previous)
    role_picker = OptionButton.new()
    role_picker.custom_minimum_size.y = 44
    for role in Models.ROLES:
        role_picker.add_item(Roles.label(str(role)))
    column.add_child(role_picker)
    role_picker.item_selected.connect(_on_role)
    _auto_benchmark_button=_button(column,
        "ANDROID · AUTOTEST 6 FASES (6 MIN)",_toggle_auto_benchmark)

    apc_controls=VBoxContainer.new()
    apc_controls.name="APCP06V1_InspeccionTecnica"
    apc_controls.add_theme_constant_override("separation",6)
    column.add_child(apc_controls)
    var apc_heading:=_title(apc_controls,
        "SIGUIENTE UNIDAD · APC P06 BASTIÓN 6×6",13)
    apc_heading.add_theme_color_override("font_color",Color("#E6C17C"))
    apc_compare_button=_button(apc_controls,
        "APC V1 · Comparar prototipo original",_toggle_apc_version)
    apc_v2_button=_button(apc_controls,
        "APC P06 V2 · ARMADURA, NEUMÁTICOS Y ACABADO",_toggle_apc_v2)
    apc_v3_button=_button(apc_controls,
        "APC V3 · TECHO, JUNTAS, TORRETA Y DAÑOS",_toggle_apc_v3)
    apc_damage_button=_button(apc_controls,
        "APC V3 · MOSTRAR DAÑO LEVE",_cycle_apc_damage)
    _add_paired(apc_controls,"APC V3 · Próximo nivel de daño",
        _cycle_apc_damage,"APC V3 · Reparar",
        func(): _set_apc_damage(0))
    _add_paired(apc_controls,"APC: Avanzar 6×6",
        func(): _play("move"),
        "APC: Girar torreta",func(): _play("turn_turret"))
    _add_paired(apc_controls,"APC: Disparar",
        func(): _play("attack"),
        "APC: Recibir balas",func(): _play("hit_bullet"))
    _add_paired(apc_controls,"APC V3: Impacto explosivo",
        func(): _play("hit_explosive"),
        "APC V3: Restaurar daños",func(): _set_apc_damage(0))
    apc_ramp_button=_button(apc_controls,
        "APC: Abrir rampa de tropas",_toggle_apc_ramp)
    apc_lod_button=_button(apc_controls,
        "APC V3 · MODO TÁCTICO: Ocultar microdetalles",_toggle_apc_lod)
    apc_stress_button=_button(apc_controls,
        "APC · PROBAR 32 VEHÍCULOS (8 FACCIONES)",_cycle_apc_stress)
    apc_mixed_button=_button(apc_controls,
        "BATALLA MIXTA · Agregar 8 G09 + 8 cuarteles",
        _toggle_apc_mixed)
    apc_stress_label=_title(apc_controls,
        "Prueba de FPS real: 32 → 64 → salir. Usa Android o el navegador.",11)
    apc_perf_button=_button(apc_controls,
        "GUARDAR / COPIAR INFORME FPS",_save_apc_perf)

    _title(column,"FACCION",12)
    faction_picker = OptionButton.new()
    faction_picker.custom_minimum_size.y = 44
    for faction in Factions.FACTIONS:
        faction_picker.add_item(str(faction["name"]))
    column.add_child(faction_picker)
    faction_picker.item_selected.connect(_on_faction)

    _title(column,"ROTAR Y ACERCAR",12)
    _add_paired(column,"↶ Girar 45°",func(): _rotate(-45.0),
        "Girar 45° ↷",func(): _rotate(45.0))
    _add_paired(column,"− Alejar",func(): _change_zoom(-1),
        "+ Acercar",func(): _change_zoom(1))
    tactical_button = _button(column,"CÁMARA: Cambiar a vista táctica",_toggle_tactical_camera)
    underside_button = _button(column,"INSPECCIONAR ORUGAS · Vista inferior V29",_toggle_underside_camera)
    _title(column,"V26 · PRUEBAS EN CAMPO DE BATALLA",12)
    scenario_button = _button(column,"ESCENARIO: Activar campo de batalla",_toggle_scenario)
    _title(column,"TERRENO DE PRUEBA",12)
    terrain_picker = OptionButton.new()
    terrain_picker.custom_minimum_size.y = 44
    for terrain_name in BattleScenarioV26.TERRAIN_NAMES:
        terrain_picker.add_item(str(terrain_name))
    column.add_child(terrain_picker)
    terrain_picker.item_selected.connect(_on_scenario_terrain)
    _title(column,"ILUMINACIÓN DE PRUEBA",12)
    light_picker = OptionButton.new()
    light_picker.custom_minimum_size.y = 44
    for period_name in BattleScenarioV26.LIGHT_NAMES:
        light_picker.add_item(str(period_name))
    column.add_child(light_picker)
    light_picker.item_selected.connect(_on_scenario_light)

    _title(column,"ANIMACION REAL",12)
    _add_paired(column,"Orugas",func(): _play("move"),
        "Disparo",func(): _play("attack"))
    _add_paired(column,"Recibir impacto",func(): _play("damaged"),
        "Detener",_stop_animation)
    _title(column,"V30 · DOS TIPOS DE IMPACTO",12)
    _add_paired(column,"RECIBIR BALAS",func(): _play(HitV30.BULLET),
        "RECIBIR EXPLOSIVO",func(): _play(HitV30.EXPLOSIVE))

    _title(column,"CONDICION DEL TANQUE",12)
    damage_picker = OptionButton.new()
    damage_picker.custom_minimum_size.y = 44
    for stage in TankDamage.STAGES:
        damage_picker.add_item(str(stage))
    column.add_child(damage_picker)
    damage_picker.item_selected.connect(_on_damage)
    _add_paired(column,"Destruir",func(): _set_damage(4),
        "Restaurar",func(): _set_damage(0))

    detail_label = _title(column,"",12)
    status_label = _title(column,"",12)
    status_label.add_theme_color_override("font_color",Color("#F7C687"))
    _button(column,"Restablecer cámara",_reset_camera)

func _version_text() -> String:
    var path := "res://assets/art_studio_revision.txt"
    if FileAccess.file_exists(path):
        return "Version de GitHub: "+FileAccess.get_file_as_string(path).strip_edges()
    return "Vista técnica local · sin instalar APK"

func _display_role(role: String) -> void:
    if not Models.supports(role):
        return
    if _auto_benchmark.active and not _auto_internal_change:
        _abort_auto_benchmark()
    _clear_apc_stress()
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = role
    var art_level: int = 10
    if _previous_version:
        art_level = 9
    if _v11_preview:
        art_level = 11
    if _v12_preview:
        art_level = 12
    if _v13_preview:
        art_level = 13
    if _v14_preview:
        art_level = 14
    if _v15_preview:
        art_level = 15
    if _v16_preview:
        art_level = 16
    if _v17_preview:
        art_level = 17
    if _v18_preview:
        art_level = 18
    if _v19_preview:
        art_level = 19
    if _v20_preview:
        art_level = 20
    if _v21_preview:
        art_level = 21
    if _v22_preview:
        art_level = 22
    if _v23_preview:
        art_level = 23
    if _v24_preview:
        art_level = 24
    if _v25_preview:
        art_level = 25
    if _v25_preview and _v30_preview:
        art_level = 30
    if _v25_preview and _v30_preview and _v31_preview:
        art_level = 31
    if _role=="apc" and _apc_v1_preview:
        art_level=(13 if _apc_v3_preview else 12) if _apc_v2_preview else 11
    model_root = Models.build(_role,_faction if _role in ["tank","apc"] else -1,
        _final_detail,art_level)
    if _v17_preview or _v18_preview or _v19_preview or _v20_preview or _v21_preview or _v22_preview or _v23_preview or _v24_preview or _v25_preview:
        TankV17.set_quality(model_root,_v17_eco)
    if _clay_review and (_v18_preview or _v19_preview or _v20_preview or _v21_preview or _v22_preview or _v23_preview or _v24_preview or _v25_preview):
        ClayV19.set_enabled(model_root,true)
    preview.add_child(model_root)
    _yaw = -32.0
    _zoom = 1.0
    _effect_time = 0.0
    model_root.rotation_degrees.y = _yaw
    role_picker.select(Models.ROLES.find(role))
    faction_picker.select(_faction)
    faction_picker.visible = (_role in ["tank","apc"])
    damage_picker.visible = (_role == "tank")
    comparison_button.visible = (_role == "tank")
    previous_version_button.visible = (_role == "tank")
    v11_button.visible = (_role == "tank")
    v12_button.visible = (_role == "tank")
    v13_button.visible = (_role == "tank")
    v14_button.visible = (_role == "tank")
    v15_button.visible = (_role == "tank")
    v16_button.visible = (_role == "tank")
    v17_button.visible = (_role == "tank")
    v18_button.visible = (_role == "tank")
    v19_button.visible = (_role == "tank")
    v20_button.visible = (_role == "tank")
    v21_button.visible = (_role == "tank")
    v22_button.visible = (_role == "tank")
    v23_button.visible = (_role == "tank")
    v24_button.visible = (_role == "tank")
    v25_button.visible = (_role == "tank")
    v30_button.visible = (_role == "tank")
    v31_button.visible = (_role == "tank")
    apc_controls.visible = (_role=="apc")
    apc_compare_button.text = ("APC P06 · Comparar con prototipo V0" if _apc_v1_preview else "APC P06 · Regresar a V1")
    apc_v2_button.text = ("APC V2/V1 · Ver versión V1 anterior" if _apc_v2_preview else "APC V2 · Ver blindaje y ruedas mejoradas")
    apc_v3_button.text = ("APC V3/V2 · Ver V2 anterior" if _apc_v3_preview else "APC V3 · Ver techo y daño realistas")
    apc_damage_button.text = "APC V3 · DAÑO %d/4 · Siguiente nivel" % _apc_damage_stage
    apc_ramp_button.text = "APC: Abrir rampa de tropas"
    if model_root.get_meta("tarvoka_apc_finish_v3",false):
        APCFinishV3.apply_stage(model_root,_apc_damage_stage)
        APCFinishV3.set_tactical_lod(model_root,_apc_tactical_lod)
    apc_lod_button.visible=(_role=="apc" and model_root.get_meta("tarvoka_apc_finish_v3",false))
    apc_stress_button.visible=apc_lod_button.visible
    apc_mixed_button.visible=apc_lod_button.visible
    apc_perf_button.visible=apc_lod_button.visible
    apc_stress_label.visible=apc_lod_button.visible
    apc_lod_button.text=("APC V3 · MODO DETALLE COMPLETO"
        if _apc_tactical_lod else "APC V3 · MODO TÁCTICO: Ocultar microdetalles")
    tactical_button.visible = (_role == "tank")
    underside_button.visible = (_role == "tank")
    scenario_button.visible = (_role == "tank")
    terrain_picker.visible = (_role == "tank")
    light_picker.visible = (_role == "tank")
    terrain_picker.select(_scenario_terrain)
    light_picker.select(_scenario_light)
    battle_scenario.set_conditions(_scenario_terrain,_scenario_light)
    battle_scenario.set_active(_scenario_enabled and _role == "tank")
    scenario_button.text = "ESCENARIO: Volver al estudio neutro" if _scenario_enabled else "ESCENARIO: Activar campo de batalla"
    v21_button.text = "COMPARAR: Volver a V20" if _v21_preview else "V21 · Proa, barbeta y rodaje realista"
    v22_button.text = "COMPARAR: Volver a V21" if _v22_preview else "V22 · Cañón y sistema de retroceso"
    v23_button.text = "COMPARAR: Volver a V22" if _v23_preview else "V23 · Identificación de facción"
    v24_button.text = "COMPARAR: Volver a V23" if _v24_preview else "V24 · Pintura superior táctica"
    v25_button.text = "COMPARAR: Volver a V24" if _v25_preview else "NUEVO V25 · Esmalte y microdesgaste"
    v30_button.text = "COMPARAR V30/V25 · Volver a V25" if _v30_preview else "V30 · CADENAS ANCHAS Y DAÑO REALISTA"
    v31_button.text = "COMPARAR V31/V30 · Volver a V30" if _v31_preview else "V31 · ORUGAS ALINEADAS HACIA DENTRO"
    tactical_button.text = "CÁMARA: Volver a vista de estudio" if _tactical_view else "CÁMARA: Cambiar a vista táctica"
    underside_button.text = "INSPECCIONAR ORUGAS · Volver a vista lateral" if _underside_view else "INSPECCIONAR ORUGAS · Vista inferior V29"
    v20_button.text = "COMPARAR: Volver a V19" if _v20_preview else "NUEVO V20 · Blindaje integrado y suspensión"
    v19_button.text = "COMPARAR: Volver a V18" if _v19_preview else "V19 · Techo, sensores y mantelete"
    clay_button.visible = (_role == "tank" and (_v18_preview or _v19_preview or _v20_preview or _v21_preview or _v22_preview or _v23_preview or _v24_preview or _v25_preview))
    clay_button.text = "MODO ARCILLA · Volver a materiales" if _clay_review else "MODO ARCILLA · Ver geometría sin materiales"
    v18_button.text = "COMPARAR: Volver a V17" if _v18_preview else "V18 · Reconstrucción del casco y la torreta"
    v17_quality_button.visible = (_role == "tank" and (_v17_preview or _v18_preview or _v19_preview or _v20_preview or _v21_preview or _v22_preview or _v23_preview or _v24_preview or _v25_preview))
    v17_button.text = "COMPARAR: Volver a V16" if _v17_preview else "V17 · Humo orgánico y rendimiento"
    v17_quality_button.text = "EFECTOS: ECO (6 planos)" if _v17_eco else "EFECTOS: COMPLETOS (11 planos)"
    v16_button.text = "COMPARAR: Volver a V15" if _v16_preview else "V16 · Pintura mate, acero y fuego"
    v15_button.text = "COMPARAR: Volver a V14" if _v15_preview else "V15 · Blindaje integrado sin alas flotantes"
    v14_button.text = "COMPARAR: Volver a V13" if _v14_preview else "V14 · Coraza pronunciada y ruedas activas"
    v13_button.text = "COMPARAR: Volver a V12" if _v13_preview else "V13 · Faldones segmentados y torreta"
    v12_button.text = "COMPARAR: Volver a V11" if _v12_preview else "V12 · Blindaje y materiales refinados"
    v11_button.text = "COMPARAR: Volver al G09 V10" if _v11_preview else "NUEVO G09 V11 · Escultura angular"
    comparison_button.text = "COMPARAR: Ver modelo base" if _final_detail else "COMPARAR: Ver acabado nuevo"
    previous_version_button.text = "COMPARAR: Volver al acabado V10" if _previous_version else "COMPARAR: Ver acabado V9 anterior"
    damage_picker.visible = (_role=="tank")
    if _role == "tank":
        damage_picker.select(0)
    _update_camera()
    _update_details()

func _update_details() -> void:
    if model_root == null:
        return
    var meshes: int = Models.inspect_meshes(model_root)
    detail_label.text = "Modelo activo: %s · %d mallas reales" % [Roles.label(_role),meshes]
    if _role=="apc":
        if model_root.get_meta("tarvoka_apc_finish_v3",false):
            status_label.text = ("APC P06 V3 · TECHO Y JUNTAS FÍSICAS"
                + " · TORRETA REFINADA · BALAS/EXPLOSIONES · DAÑO %d/4" % _apc_damage_stage)
            if _apc_tactical_lod:
                status_label.text+=" · LOD TÁCTICO"
        elif model_root.get_meta("tarvoka_apc_armor_v2",false):
            status_label.text = ("APC P06 BASTIÓN V2 · BLINDAJE ANGULAR"
                + " · 288 TACOS 3D COMPARTIDOS · PINTURA PBR"
                + " · RAMPA, TORRETA Y 6 RUEDAS ANIMADAS")
        elif model_root.get_meta("tarvoka_apc_sculpt_v1",false):
            status_label.text = ("APC P06 BASTIÓN V1 · CARROCERÍA 6×6"
                + " · RAMPA Y TORRETA ANIMADAS")
        else:
            status_label.text = "APC P06 · PROTOTIPO TÉCNICO ORIGINAL V0"
        return
    if _role != "tank":
        status_label.text = "Modelo técnico 3D · misma librería de TARVOKA"
        return
    var version_name := "ACABADO V10 ACTUAL"
    if _previous_version:
        version_name = "ACABADO V9 ANTERIOR"
    var stages := [
        _v11_preview,_v12_preview,_v13_preview,_v14_preview,
        _v15_preview,_v16_preview,_v17_preview,_v18_preview,
        _v19_preview,_v20_preview,_v21_preview,_v22_preview,
        _v23_preview,_v24_preview,_v25_preview
    ]
    var titles := [
        "PROPUESTA V11","REFINAMIENTO V12","ESCULTURA V13",
        "ESCULTURA V14","INTEGRACION V15","ACABADO V16",
        "EFECTOS V17","ESCULTURA V18","ESCULTURA V19",
        "INTEGRACION V20","PROA Y RODAJE V21",
        "CAÑON Y RETROCESO V22",
        "IDENTIFICACION DE FACCION V23",
        "LECTURA TACTICA V24",
        "MATERIALES PBR Y DESGASTE V25"
    ]
    for index in range(stages.size()):
        if stages[index]:
            version_name = titles[index]
    status_label.text = "G09 · %s · %s · %s" % [
        version_name if _final_detail else "MODELO BASE",
        str(Factions.FACTIONS[_faction]["name"]),
        str(TankDamage.STAGES[TankDamage.current_stage(model_root)])
    ]
    if _tactical_view:
        status_label.text += " · CÁMARA TÁCTICA"
    if _underside_view:
        status_label.text += " · VISTA INFERIOR DE ORUGAS"
    if model_root.get_meta("tarvoka_mbt_track_final_v29",false):
        status_label.text += " · RODAJE V29 CORREGIDO"
    if model_root.get_meta("tarvoka_hit_v30",false):
        status_label.text += " · V30: CADENAS ANCHAS, DAÑO PBR, BALAS/EXPLOSIVOS"
    if model_root.get_meta("tarvoka_mbt_tracks_inboard_v31",false):
        status_label.text += " · V31: CADENAS Y ENGRANAJES ALINEADOS AL INTERIOR"
    if model_root.has_meta("tarvoka_v32_hit_nodes"):
        status_label.text += " · V32 FINAL: MOVIMIENTO, TORRETA, DISPARO, IMPACTOS Y DAÑOS REVISADOS"
    if _scenario_enabled:
        status_label.text += " · %s / %s (V26)" % [
            str(BattleScenarioV26.TERRAIN_NAMES[_scenario_terrain]),
            str(BattleScenarioV26.LIGHT_NAMES[_scenario_light])]

func _toggle_details() -> void:
    if _role != "tank":
        return
    _final_detail = not _final_detail
    _display_role("tank")

func _toggle_previous() -> void:
    if _role != "tank":
        return
    _previous_version = not _previous_version
    _v11_preview = false
    _v12_preview = false
    _v13_preview = false
    _v14_preview = false
    _v15_preview = false
    _v16_preview = false
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v11() -> void:
    if _role != "tank":
        return
    _v11_preview = not _v11_preview
    _v12_preview = false
    _v13_preview = false
    _v14_preview = false
    _v15_preview = false
    _v16_preview = false
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v12() -> void:
    if _role != "tank":
        return
    _v12_preview = not _v12_preview
    _v13_preview = false
    _v14_preview = false
    _v15_preview = false
    _v16_preview = false
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v11_preview = not _v12_preview
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v13() -> void:
    if _role != "tank":
        return
    # The V13 ↔ V12 A/B preview preserves yaw, zoom and damage; Android
    # remains on V10 until the visual design receives explicit approval.
    _v13_preview = not _v13_preview
    _v14_preview = false
    _v15_preview = false
    _v16_preview = false
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v12_preview = not _v13_preview
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v14() -> void:
    if _role != "tank":
        return
    _v14_preview = not _v14_preview
    _v15_preview = false
    _v16_preview = false
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v13_preview = not _v14_preview
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v15() -> void:
    if _role != "tank":
        return
    # Fixed-angle browser A/B, never switch the Android default artwork.
    _v15_preview = not _v15_preview
    _v16_preview = false
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v14_preview = not _v15_preview
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v16() -> void:
    if _role != "tank":
        return
    # Native V15/V16 Godot comparison: same yaw, zoom and damage stage.
    _v16_preview = not _v16_preview
    _v17_preview = false
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v15_preview = not _v16_preview
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v17() -> void:
    if _role != "tank":
        return
    _v17_preview = not _v17_preview
    _v18_preview = false
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v16_preview = not _v17_preview
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v18() -> void:
    if _role != "tank":
        return
    # Same-camera A/B of the actual V17 vs V18 meshes: no APK reinstall,
    # no combat data or Android default art-level changes.
    _v18_preview = not _v18_preview
    _v19_preview = false
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v17_preview = not _v18_preview
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v19() -> void:
    if _role != "tank":
        return
    # Preserve camera, zoom, HP stage and clay preview when alternating
    # between actual original V18 and mechanically cleaned V19 geometry.
    _v19_preview = not _v19_preview
    _v20_preview = false
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v18_preview = not _v19_preview
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v20() -> void:
    if _role != "tank":
        return
    # Real V19/V20 geometry toggle. Keep camera, zoom, five-stage HP,
    # currently selected faction and optional clay preview intact.
    _v20_preview = not _v20_preview
    _v21_preview = false
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v19_preview = not _v20_preview
    _v18_preview = false
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v21() -> void:
    if _role != "tank":
        return
    # Actual V20/V21 meshes, matched yaw / zoom / paint / HP / clay.
    # No APK installation and no gameplay balancing changes required.
    _v21_preview = not _v21_preview
    _v22_preview = false
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v20_preview = not _v21_preview
    _v19_preview = false
    _v18_preview = false
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v22() -> void:
    if _role != "tank":
        return
    # Side-by-side optical comparison is an actual mesh swap; preserve
    # native camera, HP, current faction, effect budget and clay mode.
    _v22_preview = not _v22_preview
    _v23_preview = false
    _v24_preview = false
    _v25_preview = false
    _v21_preview = not _v22_preview
    _v20_preview = false
    _v19_preview = false
    _v18_preview = false
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v23() -> void:
    if _role != "tank":
        return
    # Repaint actual armor, not stickers; compare native V22/V23 models at
    # identical camera, faction, damage state and clay preview.
    _v23_preview = not _v23_preview
    _v24_preview = false
    _v25_preview = false
    _v22_preview = not _v23_preview
    _v21_preview = false
    _v20_preview = false
    _v19_preview = false
    _v18_preview = false
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v24() -> void:
    if _role != "tank":
        return
    # Exact V23/V24 material comparison on the original meshes.
    _v24_preview = not _v24_preview
    _v25_preview = false
    _v23_preview = not _v24_preview
    _v22_preview = false
    _v21_preview = false
    _v20_preview = false
    _v19_preview = false
    _v18_preview = false
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v25() -> void:
    if _role != "tank":
        return
    # V24/V25 is a real PBR texture comparison: identical native geometry,
    # lighting, camera, faction, tactical zoom, animation and damage stage.
    _v25_preview = not _v25_preview
    _v30_preview = false
    _v31_preview = false
    _v24_preview = not _v25_preview
    _v23_preview = false
    _v22_preview = false
    _v21_preview = false
    _v20_preview = false
    _v19_preview = false
    _v18_preview = false
    _v17_preview = false
    _v16_preview = false
    _v15_preview = false
    _v14_preview = false
    _v13_preview = false
    _v12_preview = false
    _v11_preview = true
    _previous_version = false
    _final_detail = true
    _reload_tank_same_camera()

func _toggle_v30() -> void:
    if _role!="tank":
        return
    _v30_preview=not _v30_preview
    _v31_preview=false
    _v25_preview=true
    _v24_preview=false
    _previous_version=false
    _final_detail=true
    _reload_tank_same_camera()

func _toggle_v31() -> void:
    if _role!="tank":
        return
    # Native Godot V30/V31 comparison, same camera, damage state, faction,
    # real chain width and animation. Only x positioning of running gear.
    _v31_preview=not _v31_preview
    _v30_preview=true
    _v25_preview=true
    _v24_preview=false
    _previous_version=false
    _final_detail=true
    _reload_tank_same_camera()

func _toggle_tactical_camera() -> void:
    # An elevated long-distance three-quarter tactical view, with the same
    # Godot lighting and the same actual meshes. Never a fake 2D sprite.
    if _role != "tank":
        return
    _tactical_view = not _tactical_view
    _underside_view = false
    _update_camera()
    tactical_button.text = "CÁMARA: Volver a vista de estudio" if _tactical_view else "CÁMARA: Cambiar a vista táctica"
    underside_button.text = "INSPECCIONAR ORUGAS · Volver a vista lateral" if _underside_view else "INSPECCIONAR ORUGAS · Vista inferior V29"
    _update_details()

func _toggle_underside_camera() -> void:
    # Inspect the REAL underside of G09 V29, both sprockets and no prototype
    # square boxes. Never substitute a concept image for the geometry.
    if _role!="tank":
        return
    _underside_view = not _underside_view
    _tactical_view = false
    _update_camera()
    tactical_button.text = "CÁMARA: Cambiar a vista táctica"
    underside_button.text = "INSPECCIONAR ORUGAS · Volver a vista lateral" if _underside_view else "INSPECCIONAR ORUGAS · Vista inferior V29"
    _update_details()

func _toggle_scenario() -> void:
    if _role != "tank":
        return
    _scenario_enabled = not _scenario_enabled
    battle_scenario.set_active(_scenario_enabled)
    scenario_button.text = "ESCENARIO: Volver al estudio neutro" if _scenario_enabled else "ESCENARIO: Activar campo de batalla"
    _update_details()

func _on_scenario_terrain(index: int) -> void:
    if index<0 or index>=BattleScenarioV26.TERRAIN_NAMES.size():
        return
    _scenario_terrain = index
    battle_scenario.set_conditions(_scenario_terrain,_scenario_light)
    terrain_picker.select(index)
    _update_details()

func _on_scenario_light(index: int) -> void:
    if index<0 or index>=BattleScenarioV26.LIGHT_NAMES.size():
        return
    _scenario_light = index
    battle_scenario.set_conditions(_scenario_terrain,_scenario_light)
    light_picker.select(index)
    _update_details()

func _toggle_clay() -> void:
    if _role != "tank" or not (_v18_preview or _v19_preview or _v20_preview or _v21_preview or _v22_preview or _v23_preview or _v24_preview or _v25_preview) or model_root == null:
        return
    _clay_review = not _clay_review
    ClayV19.set_enabled(model_root,_clay_review)
    clay_button.text = "MODO ARCILLA · Volver a materiales" if _clay_review else "MODO ARCILLA · Ver geometría sin materiales"
    _update_details()

func _toggle_v17_quality() -> void:
    if _role != "tank" or not (_v17_preview or _v18_preview or _v19_preview or _v20_preview or _v21_preview or _v22_preview or _v23_preview or _v24_preview or _v25_preview) or model_root == null:
        return
    _v17_eco = not _v17_eco
    TankV17.set_quality(model_root,_v17_eco)
    v17_quality_button.text = "EFECTOS: ECO (6 planos)" if _v17_eco else "EFECTOS: COMPLETOS (11 planos)"
    _update_details()

func _reload_tank_same_camera() -> void:
    # Compare the actual old and new Godot meshes at exactly the same
    # phone angle/zoom and same simulated damage state.
    var angle: float = _yaw
    var zoom: float = _zoom
    var stage: int = TankDamage.current_stage(model_root) if model_root != null else 0
    _display_role("tank")
    _yaw = angle
    _zoom = zoom
    if model_root != null:
        model_root.rotation_degrees.y = _yaw
        TankDamage.apply_stage(model_root,stage)
    damage_picker.select(stage)
    _update_camera()
    _update_details()

func _toggle_apc_version() -> void:
    if _role!="apc":
        return
    _apc_v1_preview=not _apc_v1_preview
    _apc_v2_preview=false
    _apc_v3_preview=false
    var angle: float=_yaw
    var zoom: float=_zoom
    _display_role("apc")
    _yaw=angle
    _zoom=zoom
    model_root.rotation_degrees.y=angle
    _update_camera()
    _update_details()

func _toggle_apc_v2() -> void:
    if _role!="apc":
        return
    var angle: float=_yaw
    var zoom: float=_zoom
    var opened: bool=bool(model_root.get_meta(
        "tarvoka_apc_ramp_open",false)) if model_root!=null else false
    _apc_v1_preview=true
    _apc_v2_preview=not _apc_v2_preview
    _apc_v3_preview=false
    _display_role("apc")
    _yaw=angle
    _zoom=zoom
    if model_root!=null:
        model_root.rotation_degrees.y=angle
        if opened:
            APCVisual.pose(model_root,"open_ramp",1.0)
            APCVisual.restore(model_root)
            apc_ramp_button.text="APC: Cerrar rampa de tropas"
    _update_camera()
    _update_details()

func _toggle_apc_v3() -> void:
    if _role!="apc":
        return
    var angle: float=_yaw
    var zoom: float=_zoom
    var opened: bool=bool(model_root.get_meta(
        "tarvoka_apc_ramp_open",false)) if model_root!=null else false
    _stop_animation()
    _apc_v1_preview=true
    _apc_v2_preview=true
    _apc_v3_preview=not _apc_v3_preview
    _display_role("apc")
    _yaw=angle
    _zoom=zoom
    if model_root!=null:
        model_root.rotation_degrees.y=angle
        if opened:
            APCVisual.pose(model_root,"open_ramp",1.0)
            APCVisual.restore(model_root)
            apc_ramp_button.text="APC: Cerrar rampa de tropas"
        if _apc_v3_preview:
            APCFinishV3.apply_stage(model_root,_apc_damage_stage)
    _update_camera()
    _update_details()

func _toggle_apc_lod() -> void:
    if _auto_benchmark.active and not _auto_internal_change:
        return
    if _role!="apc" or model_root==null or (
            not model_root.get_meta("tarvoka_apc_finish_v3",false)):
        return
    _apc_tactical_lod=not _apc_tactical_lod
    APCFinishV3.set_tactical_lod(model_root,_apc_tactical_lod)
    for unit in _apc_stress_units:
        APCFinishV3.set_tactical_lod(unit,_apc_tactical_lod)
    if _apc_mixed_enabled and _apc_mixed_group!=null:
        for part in _apc_mixed_group.get_children():
            var building: Node3D=part as Node3D
            if building!=null and building.get_meta(
                    "tarvoka_building_kind","")=="headquarters":
                HQLod.set_reduced(building,_apc_tactical_lod)
    _reset_apc_perf()
    apc_lod_button.text=("APC V3 · MODO DETALLE COMPLETO"
        if _apc_tactical_lod else "APC V3 · MODO TÁCTICO: Ocultar microdetalles")
    _update_details()

func _clear_apc_stress() -> void:
    # Preserve the previous measured scenario before freeing the stress scene.
    if _apc_stress_count>0 and not _auto_benchmark.active and (
            not _auto_internal_change) and int(
            _apc_perf.report()["sample_count"])>0:
        _archive_apc_perf()
    # The mixed scene hangs off the stress group and is freed alongside it.
    _apc_mixed_enabled=false
    _apc_mixed_group=null
    if _apc_stress_group!=null and is_instance_valid(_apc_stress_group):
        if _apc_stress_group.get_parent()!=null:
            _apc_stress_group.get_parent().remove_child(_apc_stress_group)
        _apc_stress_group.free()
    _apc_stress_group=null
    _apc_stress_units.clear()
    _apc_stress_count=0
    _apc_stress_elapsed=0.0
    _apc_stress_sample=0.0
    if model_root!=null and is_instance_valid(model_root):
        model_root.visible=true

func _cycle_apc_stress() -> void:
    if _auto_benchmark.active and not _auto_internal_change:
        return
    if _apc_stress_count==0:
        _set_apc_stress(32)
    elif _apc_stress_count==32:
        _set_apc_stress(64)
    else:
        _set_apc_stress(0)

func _set_apc_stress(count: int) -> void:
    if _auto_benchmark.active and not _auto_internal_change:
        return
    if _role!="apc" or model_root==null or (
            not model_root.get_meta("tarvoka_apc_finish_v3",false)):
        return
    _clear_apc_stress()
    if count==0:
        apc_stress_button.text="APC · PROBAR 32 VEHÍCULOS (8 FACCIONES)"
        apc_stress_label.text="Prueba finalizada · modelo normal restaurado"
        _update_camera()
        return
    var per_faction: int=4 if count<=32 else 8
    var group:=Node3D.new()
    group.name="APC_P06_PruebaFPS_%d" % (8*per_faction)
    _apc_stress_group=group
    preview.add_child(group)
    for faction in range(8):
        for index in range(per_faction):
            var unit: Node3D=Models.build("apc",faction,true,13)
            assert(unit!=null and unit.get_meta("tarvoka_apc_finish_v3",false))
            unit.position=Vector3(
                (float(index)-0.5*float(per_faction-1))*3.2,0,
                (float(faction)-3.5)*3.3)
            unit.rotation_degrees.y=float((faction*31+index*17)%360)
            group.add_child(unit)
            APCFinishV3.apply_stage(unit,(faction+index)%5)
            APCFinishV3.set_tactical_lod(unit,_apc_tactical_lod)
            _apc_stress_units.append(unit)
    _apc_stress_count=_apc_stress_units.size()
    model_root.visible=false
    _update_camera()
    apc_stress_button.text=("APC · PROBAR 64 VEHÍCULOS"
        if _apc_stress_count==32 else "APC · TERMINAR PRUEBA")
    apc_stress_label.text="Prueba de %d APC · calculando FPS..." % _apc_stress_count
    apc_mixed_button.text="BATALLA MIXTA · Agregar 8 G09 + 8 cuarteles"
    _reset_apc_perf()

func _toggle_apc_mixed() -> void:
    if _auto_benchmark.active and not _auto_internal_change:
        return
    if _role!="apc" or model_root==null or not model_root.get_meta(
            "tarvoka_apc_finish_v3",false):
        return
    if _apc_stress_count==0:
        _set_apc_stress(32)
    if _apc_mixed_enabled:
        if _apc_mixed_group!=null and is_instance_valid(_apc_mixed_group):
            _apc_stress_group.remove_child(_apc_mixed_group)
            _apc_mixed_group.free()
        _apc_mixed_group=null
        _apc_mixed_enabled=false
        var per_faction: int=int(_apc_stress_count/8)
        for i in range(_apc_stress_units.size()):
            var unit: Node3D=_apc_stress_units[i]
            unit.position=Vector3(
                (float(i%per_faction)-0.5*float(per_faction-1))*3.2,0,
                (float(int(i/per_faction))-3.5)*3.3)
        apc_mixed_button.text="BATALLA MIXTA · Agregar 8 G09 + 8 cuarteles"
        _reset_apc_perf()
        _update_camera()
        return
    var mixed:=Node3D.new()
    mixed.name="TARVOKA_BatallaMixta_8Facciones"
    _apc_stress_group.add_child(mixed)
    _apc_mixed_group=mixed
    # Match the lab's original native Godot V26 terrain material. A large
    # benchmark plane is representative only, not the full battle-map mesh.
    var terrain:=MeshInstance3D.new()
    terrain.name="TARVOKA_TerrenoV26_Referencia"
    var ground:=PlaneMesh.new()
    ground.size=Vector2(192,150)
    terrain.mesh=ground
    terrain.material_override=BattleScenarioV26._material(1)
    mixed.add_child(terrain)
    var per_faction: int=int(_apc_stress_count/8)
    for faction in range(8):
        var home:=Vector3((float(faction%4)-1.5)*39.0,0,
            (float(int(faction/4))-0.5)*78.0)
        var condition: String=HQMixedStress.CONDITIONS[faction%4]
        var hq: Node3D=HQMixedStress.build(
            1+(faction%3),faction,condition,true,true)
        assert(hq!=null)
        hq.position=home
        mixed.add_child(hq)
        HQLod.set_reduced(hq,_apc_tactical_lod)
        var g09: Node3D=Models.build("tank",faction,true,31)
        assert(g09!=null)
        g09.position=home+Vector3(0,0,-12)
        mixed.add_child(g09)
        for index in range(per_faction):
            var apc: Node3D=_apc_stress_units[faction*per_faction+index]
            apc.position=home+Vector3(
                (float(index%4)-1.5)*3.4,0,
                12.0+float(int(index/4))*4.0)
    _apc_mixed_enabled=true
    apc_mixed_button.text="BATALLA MIXTA · Volver a solo APC"
    _reset_apc_perf()
    _update_camera()

func _reset_apc_perf() -> void:
    if _apc_stress_count<=0:
        return
    var label_text: String=("MIXTO" if _apc_mixed_enabled else "SOLO_APC")
    _apc_perf.reset(label_text,_apc_stress_count,_apc_tactical_lod)

func _archive_apc_perf() -> String:
    if int(_apc_perf.report()["sample_count"])==0:
        return ""
    var report_data: Dictionary=_apc_perf.report()
    var path: String="user://tarvoka_perf_%s_%d_%s_%d.json" % [
        str(report_data["label"]),int(report_data["units"]),
        "lod" if bool(report_data["tactical_lod"]) else "full",
        int(Time.get_unix_time_from_system())]
    if _apc_perf.save(path):
        print("TARVOKA FPS BENCHMARK: %s | %s" % [path,_apc_perf.as_json()])
        return path
    return ""

func _toggle_auto_benchmark() -> void:
    if _auto_benchmark.active:
        _abort_auto_benchmark()
        return
    _auto_benchmark.begin()
    _auto_benchmark_report_path=""
    _auto_benchmark_button.text="DETENER AUTOTEST · Guardar parcial"
    _auto_internal_change=true
    if _role!="apc" or model_root==null or not model_root.get_meta(
            "tarvoka_apc_finish_v3",false):
        _display_role("apc")
    _auto_internal_change=false
    _begin_auto_benchmark_phase()

func _begin_auto_benchmark_phase() -> void:
    var phase: Dictionary=_auto_benchmark.phase()
    if phase.is_empty():
        return
    _auto_internal_change=true
    _set_apc_stress(int(phase["count"]))
    if bool(phase["mixed"]):
        _toggle_apc_mixed()
    if _apc_tactical_lod!=bool(phase["lod"]):
        _toggle_apc_lod()
    _reset_apc_perf()
    _auto_internal_change=false
    apc_stress_label.text=("AUTOTEST %d/6 · Preparando %s · 6s de calentamiento"
        % [_auto_benchmark.phase_index+1,str(phase["label"])])

func _tick_auto_benchmark(delta: float) -> void:
    if not _auto_benchmark.active:
        return
    var done: bool=_auto_benchmark.advance_clock(delta)
    if not done:
        var phase: Dictionary=_auto_benchmark.phase()
        var stage: String=("Calentando" if not _auto_benchmark.is_measuring()
            else "Midiendo")
        var count: int=int(maxf(0.0,
            ceilf(_auto_benchmark.warmup_seconds+
                _auto_benchmark.measure_seconds-
                _auto_benchmark.phase_elapsed)))
        apc_stress_label.text=(
            "AUTOTEST %d/6 · %s · %s · restan %ds · %.0f FPS"
            % [_auto_benchmark.phase_index+1,str(phase["label"]),stage,
                count,Engine.get_frames_per_second()])
        return
    # Do not save the transition frames into either phase. Sample after
    # the same six-second warmup for every model/LOD configuration.
    var stats: Dictionary=_apc_perf.report()
    var has_more: bool=_auto_benchmark.finish_phase(stats)
    if has_more:
        _begin_auto_benchmark_phase()
        return
    _auto_benchmark_report_path=_save_auto_benchmark_report()
    _auto_benchmark_button.text="ANDROID · AUTOTEST 6 FASES (6 MIN)"
    _auto_internal_change=true
    _set_apc_stress(0)
    _auto_internal_change=false
    apc_stress_label.text=(
        "AUTOTEST COMPLETO · 6/6 fases · Toca GUARDAR/COPIAR INFORME FPS")

func _save_auto_benchmark_report() -> String:
    if _auto_benchmark.reports.is_empty():
        return ""
    var path: String="user://tarvoka_android_suite_v2_%d.json" % int(
        Time.get_unix_time_from_system())
    if not _auto_benchmark.save(path):
        return ""
    print("TARVOKA ANDROID SUITE V2: %s | %s" % [
        path,JSON.stringify(_auto_benchmark.summary())])
    return path

func _abort_auto_benchmark() -> void:
    if not _auto_benchmark.active:
        return
    if int(_apc_perf.report()["sample_count"])>0:
        # Partial results are deliberately marked cancelled, never passed.
        _auto_benchmark.finish_phase(_apc_perf.report())
    _auto_benchmark.abort()
    _auto_benchmark_report_path=_save_auto_benchmark_report()
    _auto_benchmark_button.text="ANDROID · AUTOTEST 6 FASES (6 MIN)"
    _auto_internal_change=true
    _set_apc_stress(0)
    _auto_internal_change=false
    apc_stress_label.text=(
        "Autotest detenido · informe parcial guardado (si hubo muestras)")

func _save_apc_perf() -> void:
    if not _auto_benchmark.active and (
            _auto_benchmark.reports.size()>0):
        # Export the complete native Android A/B series by explicit tap.
        DisplayServer.clipboard_set(JSON.stringify(
            _auto_benchmark.summary(),"  "))
        apc_stress_label.text=("Serie de %d/6 fases copiada · informe %s"
            % [_auto_benchmark.reports.size(),_auto_benchmark_report_path])
        return
    var path: String=_archive_apc_perf()
    if path.is_empty():
        apc_stress_label.text="Primero ejecuta la prueba durante al menos 0,5 segundos"
        return
    DisplayServer.clipboard_set(_apc_perf.as_json())
    apc_stress_label.text=("Informe guardado en %s · JSON enviado al portapapeles"
        % path)

func _update_apc_stress(delta: float) -> void:
    _apc_stress_elapsed+=maxf(delta,0.0)
    _apc_stress_sample+=maxf(delta,0.0)
    if not _auto_benchmark.active or _auto_benchmark.is_measuring():
        _apc_perf.add(delta,float(Engine.get_frames_per_second()),
            Performance.get_monitor(
                Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
            Performance.get_monitor(Performance.MEMORY_STATIC))
    # A real moving subset plus smoke/fire on damaged units: no stand-ins.
    var progress: float=fposmod(_apc_stress_elapsed,APCVisual.MOVE_DURATION) / APCVisual.MOVE_DURATION
    for i in range(_apc_stress_units.size()):
        var unit: Node3D=_apc_stress_units[i]
        if i%3==0:
            APCVisual.pose(unit,"move",progress)
        if int(unit.get_meta("tarvoka_apc_v3_damage_stage",0))>=2:
            APCFinishV3.animate_damage(unit,_apc_stress_elapsed)
    if _apc_stress_sample>=0.70:
        _apc_stress_sample=0.0
        var draws: float=Performance.get_monitor(
            Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
        var scenario: String=(
            " + 8 G09 + 8 HQ" if _apc_mixed_enabled else "")
        var data: Dictionary=_apc_perf.report()
        apc_stress_label.text=(
            "%d APC%s · %.0f FPS · p10 %.0f · %.0f dibujos · memoria Godot %.0f MiB · %s"
            % [_apc_stress_count,scenario,Engine.get_frames_per_second(),
                float(data["fps_p10"]),draws,float(data["memory_mib_peak"]),
                "LOD TÁCTICO" if _apc_tactical_lod else "DETALLE COMPLETO"])

func _set_apc_damage(stage: int) -> void:
    if _role!="apc" or model_root==null or (
            not model_root.get_meta("tarvoka_apc_finish_v3",false)):
        return
    _apc_damage_stage=clampi(stage,0,4)
    if APCFinishV3.apply_stage(model_root,_apc_damage_stage):
        apc_damage_button.text="APC V3 · DAÑO %d/4 · Siguiente nivel" % _apc_damage_stage
        _update_details()

func _cycle_apc_damage() -> void:
    _set_apc_damage((_apc_damage_stage+1)%5)

func _toggle_apc_ramp() -> void:
    if _role!="apc" or model_root==null or (
            not model_root.get_meta("tarvoka_apc_sculpt_v1",false)):
        return
    var opened: bool=bool(model_root.get_meta("tarvoka_apc_ramp_open",false))
    _play("close_ramp" if opened else "open_ramp")
    apc_ramp_button.text=("APC: Abrir rampa de tropas" if opened
        else "APC: Cerrar rampa de tropas")

func _on_role(index: int) -> void:
    if index >= 0 and index < Models.ROLES.size():
        _display_role(str(Models.ROLES[index]))

func _on_faction(index: int) -> void:
    if index < 0 or index >= Factions.FACTIONS.size():
        return
    _faction = index
    if _role=="apc" and model_root!=null:
        Models.apply_faction_palette(model_root,index)
    if _role == "tank" and model_root != null:
        var clay_was_on: bool = ClayV19.is_enabled(model_root)
        if clay_was_on:
            ClayV19.set_enabled(model_root,false)
        Models.apply_faction_palette(model_root,index)
        if clay_was_on:
            ClayV19.set_enabled(model_root,true)
    _update_details()

func _on_damage(index: int) -> void:
    _set_damage(index)

func _set_damage(stage: int) -> void:
    if _role != "tank" or model_root == null:
        return
    _stop_animation()
    if TankDamage.apply_stage(model_root,stage):
        damage_picker.select(stage)
        _update_details()

func _play(kind: String) -> void:
    if _role not in ["tank","apc"] or model_root==null:
        return
    if _role=="apc" and not model_root.get_meta("tarvoka_apc_sculpt_v1",false):
        return
    _animation=kind
    _animation_time=0.0
    if _role=="apc":
        APCVisual.pose(model_root,kind,0.0)
        if model_root.get_meta("tarvoka_apc_finish_v3",false):
            APCFinishV3.animate_impact(model_root,kind,0.0)
    else:
        TankRig.pose(model_root,kind,0.0,Vector2i(1,-1))
        TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))

func _stop_animation() -> void:
    _animation = ""
    _animation_time = 0.0
    if _role=="apc" and model_root!=null:
        APCVisual.restore(model_root)
        if model_root.get_meta("tarvoka_apc_finish_v3",false):
            APCFinishV3.animate_impact(model_root,"",1.0)
    elif _role == "tank" and model_root != null:
        var stage: int = TankDamage.current_stage(model_root)
        TankRig.restore(model_root)
        TankDamage.apply_stage(model_root,stage)

func _process(delta: float) -> void:
    if model_root==null:
        return
    if _apc_stress_count>0:
        _update_apc_stress(delta)
        if _auto_benchmark.active:
            _tick_auto_benchmark(delta)
        return
    if _role=="apc":
        if model_root.get_meta("tarvoka_apc_finish_v3",false) and _apc_damage_stage>=2:
            _effect_time+=delta
            APCFinishV3.animate_damage(model_root,_effect_time)
        if not _animation.is_empty():
            _animation_time+=maxf(delta,0.0)
            var duration: float=(APCVisual.MOVE_DURATION if _animation=="move"
                else APCVisual.RAMP_DURATION if _animation in ["open_ramp","close_ramp"]
                else APCVisual.SHOT_DURATION)
            var t: float=minf(_animation_time/maxf(duration,0.01),1.0)
            APCVisual.pose(model_root,_animation,t)
            if model_root.get_meta("tarvoka_apc_finish_v3",false):
                APCFinishV3.animate_impact(model_root,_animation,t)
            if t>=1.0:
                _stop_animation()
        return
    if _role!="tank":
        return
    if TankDamage.current_stage(model_root) >= 2:
        _effect_time += delta
        TankDamage.animate_smoke(model_root,_effect_time)
    if _animation.is_empty():
        return
    _animation_time += maxf(delta,0.0)
    var duration: float = TankRig.MOVE_DURATION if _animation=="move" else (
        HitV30.duration(_animation) if _animation in [HitV30.BULLET,HitV30.EXPLOSIVE]
        else TankRig.SHOT_DURATION)
    var ratio: float = minf(_animation_time/maxf(0.01,duration),1.0)
    TankRig.pose(model_root,_animation,ratio,Vector2i(1,-1))
    TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))
    if ratio >= 1.0:
        _stop_animation()

func _rotate(degrees: float) -> void:
    if model_root == null:
        return
    _yaw = fposmod(_yaw+degrees,360.0)
    model_root.rotation_degrees.y = _yaw

func _change_zoom(direction: int) -> void:
    _zoom = clampf(_zoom * (1.20 if direction > 0 else 1.0/1.20),0.65,2.8)
    _update_camera()

func _update_camera() -> void:
    if camera != null:
        if _apc_stress_count>0:
            camera.size=(167.0 if _apc_mixed_enabled else
                33.0 if _apc_stress_count==32 else 49.0)
            camera.position=(Vector3(78,122,115) if _apc_mixed_enabled else
                Vector3(27,32,39) if _apc_stress_count==32 else
                Vector3(35,41,49))
            camera.look_at(Vector3(0,0.50,0),Vector3.UP)
            return
        if _role=="tank" and _underside_view:
            camera.size = Models.preview_frame_height(_role)*1.26/_zoom
            camera.position = Vector3(6.0,-1.75,2.1)
            camera.look_at(Vector3(0,0.32,0),Vector3.UP)
        else:
            camera.size = Models.preview_frame_height(_role)*(2.35 if _tactical_view and _role=="tank" else 1.10)/_zoom
            camera.position = Vector3(5.2,10.6,6.4) if _tactical_view and _role=="tank" else Vector3(5.3,4.2,6.3)
            camera.look_at(Vector3(0,0.35,0),Vector3.UP)

func _reset_camera() -> void:
    _yaw = -32.0
    _zoom = 1.0
    if model_root != null:
        model_root.rotation_degrees.y = _yaw
    _update_camera()

func _on_model_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
        _rotate(event.relative.x*0.43)
        accept_event()
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            _change_zoom(1)
            accept_event()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            _change_zoom(-1)
            accept_event()
    elif event is InputEventScreenTouch:
        if event.pressed:
            _touches[event.index] = event.position
        else:
            _touches.erase(event.index)
        accept_event()
    elif event is InputEventScreenDrag:
        if not _touches.has(event.index):
            _touches[event.index] = event.position-event.relative
        if _touches.size() < 2:
            _rotate(event.relative.x*0.42)
        else:
            var previous: Dictionary = _touches.duplicate()
            var keys: Array = _touches.keys()
            _touches[event.index] = event.position
            var before: float = (previous[keys[0]] as Vector2).distance_to(previous[keys[1]] as Vector2)
            var after: float = (_touches[keys[0]] as Vector2).distance_to(_touches[keys[1]] as Vector2)
            if before > 10.0 and after > 10.0:
                _zoom = clampf(_zoom*after/before,0.65,2.8)
                _update_camera()
        _touches[event.index] = event.position
        accept_event()
