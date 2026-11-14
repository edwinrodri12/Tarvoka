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
    model_root = Models.build(_role,_faction if _role == "tank" else -1,
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
    faction_picker.visible = (_role == "tank")
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
    if _role == "tank":
        damage_picker.select(0)
    _update_camera()
    _update_details()

func _update_details() -> void:
    if model_root == null:
        return
    var meshes: int = Models.inspect_meshes(model_root)
    detail_label.text = "Modelo activo: %s · %d mallas reales" % [Roles.label(_role),meshes]
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

func _on_role(index: int) -> void:
    if index >= 0 and index < Models.ROLES.size():
        _display_role(str(Models.ROLES[index]))

func _on_faction(index: int) -> void:
    if index < 0 or index >= Factions.FACTIONS.size():
        return
    _faction = index
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
    if _role != "tank" or model_root == null:
        return
    _animation = kind
    _animation_time = 0.0
    TankRig.pose(model_root,kind,0.0,Vector2i(1,-1))
    TankDamage.apply_stage(model_root,TankDamage.current_stage(model_root))

func _stop_animation() -> void:
    _animation = ""
    _animation_time = 0.0
    if _role == "tank" and model_root != null:
        var stage: int = TankDamage.current_stage(model_root)
        TankRig.restore(model_root)
        TankDamage.apply_stage(model_root,stage)

func _process(delta: float) -> void:
    if model_root == null or _role != "tank":
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
