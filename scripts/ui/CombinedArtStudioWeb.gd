extends "res://scripts/ui/UnitArtStudioWeb.gd"
class_name TarvokaCombinedArtStudioWeb

# Add the approved Headquarters to the existing actual Godot Web studio.
# This adapter deliberately does NOT alter the tank inspector or meshes.
const Headquarters = preload("res://scripts/ui/Headquarters3D.gd")
const AirbaseV1 = preload("res://scripts/ui/Airbase3DV1.gd")
const NavalBaseV1 = preload("res://scripts/ui/NavalBase3DV1.gd")
const NavalDetailV2 = preload("res://scripts/ui/NavalBaseDetailV2.gd")
const NavalBerthsV3 = preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const NavalMarineV4 = preload("res://scripts/ui/NavalMarineFinishV4.gd")
const NavalYardV5 = preload("res://scripts/ui/NavalYardSignalsV5.gd")
const NavalNightV6 = preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const NavalBoardingV7 = preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const NavalFendersV8 = preload("res://scripts/ui/NavalFendersV8.gd")
const NavalSculptV9 = preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const NavalMooringV10 = preload("res://scripts/ui/NavalMooringAlignmentV10.gd")
const NavalContactV11 = preload("res://scripts/ui/NavalContactFinishV11.gd")
const NavalFinalV12 = preload("res://scripts/ui/NavalFinalContactV12.gd")
const NavalAuditV13 = preload("res://scripts/ui/NavalInspectionV13.gd")
const SupplyCenterV1 = preload("res://scripts/ui/SupplyCenter3DV1.gd")
const AirbaseHangarV2 = preload("res://scripts/ui/AirbaseHangarV2.gd")
const AirbaseDoorsV2 = preload("res://scripts/ui/AirbaseDoorRigV2.gd")
const AirbaseDamageV3 = preload("res://scripts/ui/AirbaseDamageFXV3.gd")
const AirbaseDamageV4 = preload("res://scripts/ui/AirbaseDamageFXV4.gd")
const AirbaseStressV4 = preload("res://scripts/ui/AirbaseStressV4.gd")
const AirbaseExteriorV6 = preload("res://scripts/ui/AirbaseExteriorV6.gd")
const AirbaseMaterialsV7 = preload("res://scripts/ui/AirbaseMaterialsV7.gd")
const AirbaseFinishV8 = preload("res://scripts/ui/AirbaseFinishV8.gd")
const AirbaseDetailV9 = preload("res://scripts/ui/AirbaseDetailV9.gd")
const AirbaseStructureV10 = preload("res://scripts/ui/AirbaseStructureV10.gd")
const AirbaseTrussesV11 = preload("res://scripts/ui/AirbaseTrussesV11.gd")
const AirbaseFractureV12 = preload("res://scripts/ui/AirbaseFractureV12.gd")
const AirbaseImpactsV13 = preload("res://scripts/ui/AirbaseImpactsV13.gd")
const AirbaseScarsV14 = preload("res://scripts/ui/AirbaseScarsV14.gd")
const AirbaseScarFinishV15 = preload("res://scripts/ui/AirbaseScarFinishV15.gd")
const AirbaseImpactV3 = preload("res://scripts/ui/AirbaseImpactV3.gd")
const HQProduction = preload("res://scripts/ui/HeadquartersProductionV13.gd")
const HQSpriteV16 = preload("res://scripts/ui/HeadquartersSpriteStudioV16.gd")
const HQClimateV17 = preload("res://scripts/ui/HeadquartersClimateV17.gd")
const HQWayfindingV18 = preload("res://scripts/ui/HeadquartersWayfindingV18.gd")
const HQFacadeV19 = preload("res://scripts/ui/HeadquartersFacadeV19.gd")
const HQDamageV21 = preload("res://scripts/ui/HeadquartersDamageV21.gd")
const HQDamageV22 = preload("res://scripts/ui/HeadquartersDamageV22.gd")
const HQFireV22 = preload("res://scripts/ui/HeadquartersFireV22.gd")
const HQSmokeV23 = preload("res://scripts/ui/HeadquartersSmokeV23.gd")
const HQImpactV21 = preload("res://scripts/ui/HeadquartersImpactV21.gd")
const UniversalClimate = preload("res://scripts/ui/WeatherCoating3D.gd")
const HQMapLOD = preload("res://scripts/ui/HeadquartersMapLOD3D.gd")
const HQCityBatch = preload("res://scripts/ui/HeadquartersCityBatch3D.gd")
const OfficialEmblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const VisualStyle = preload("res://scripts/ui/VisualStyle.gd")
const BUILDING_STATES := ["operativo","capturado","danado","destruido"]

var category_picker: OptionButton
var building_picker: OptionButton
var level_picker: OptionButton
var building_state_picker: OptionButton
var hq_damage_stage_picker: OptionButton
var hq_bullet_test_button: Button
var hq_explosive_test_button: Button
var hq_impact_status: Label
var building_controls: VBoxContainer
var airbase_controls: VBoxContainer
var naval_controls: VBoxContainer
var supply_controls: VBoxContainer
var supply_level_picker: OptionButton
var supply_damage_picker: OptionButton
var supply_camera_picker: OptionButton
var _supply_camera_view: int=0
var naval_detail_v2_toggle: CheckButton
var naval_detail_v3_toggle: CheckButton
var naval_detail_v4_toggle: CheckButton
var naval_detail_v5_toggle: CheckButton
var naval_detail_v6_toggle: CheckButton
var naval_detail_v7_toggle: CheckButton
var naval_detail_v8_toggle: CheckButton
var naval_detail_v9_toggle: CheckButton
var naval_detail_v10_toggle: CheckButton
var naval_detail_v11_toggle: CheckButton
var naval_detail_v12_toggle: CheckButton
var naval_detail_v13_toggle: CheckButton
var naval_night_v6_toggle: CheckButton
var _naval_saved_light_preset: int=0
var naval_level_picker: OptionButton
var naval_damage_picker: OptionButton
var naval_camera_picker: OptionButton
var _naval_camera_view: int=0
var airbase_exterior_v6_toggle: CheckButton
var airbase_material_v7_toggle: CheckButton
var airbase_finish_v8_toggle: CheckButton
var airbase_detail_v9_toggle: CheckButton
var airbase_structure_v10_toggle: CheckButton
var airbase_trusses_v11_toggle: CheckButton
var airbase_fracture_v12_toggle: CheckButton
var airbase_impacts_v13_toggle: CheckButton
var airbase_scars_v14_toggle: CheckButton
var airbase_finish_v15_toggle: CheckButton
var airbase_v14_reset_button: Button
var airbase_v14_status: Label
var _airbase_v14_history: Array[Dictionary]=[]
var airbase_surface_v13_picker: OptionButton
var airbase_v13_focus_toggle: CheckButton
var airbase_missile_v13_button: Button
var airbase_bombard_v13_button: Button
var airbase_v11_cutaway_toggle: CheckButton
var airbase_v9_view_picker: OptionButton
var _airbase_v9_view := 0
var airbase_level_picker: OptionButton
var airbase_damage_picker: OptionButton
var airbase_weather_picker: OptionButton
var airbase_open_button: Button
var airbase_close_button: Button
var airbase_gate_slider: HSlider
var airbase_gate_status: Label
var airbase_impact_bullet_button: Button
var airbase_impact_explosive_button: Button
var airbase_impact_status: Label
var airbase_mobile_fx_toggle: CheckButton
var airbase_stress_toggle: CheckButton
var airbase_stress_picker: OptionButton
var airbase_stress_status: Label
var _airbase_stress_seconds := 0.0
var airbase_camera_button: Button
var _airbase_camera_interior := false
var _airbase_saved_gate_fraction := 0.0
var _hq_specific_controls: Array[Control] = []
var _unit_only_controls: Array[Control] = []
var hq_compare_button: Button
var hq_v3_compare_button: Button
var hq_version_picker: OptionButton
var hq_v7_toggle: CheckButton
var hq_v8_toggle: CheckButton
var hq_v9_toggle: CheckButton
var hq_v10_toggle: CheckButton
var hq_v11_toggle: CheckButton
var hq_v12_toggle: CheckButton
var hq_production_toggle: CheckButton
var hq_production_metric_label: Label
var hq_v15_mode_picker: OptionButton
var hq_v15_neutral_toggle: CheckButton
var hq_v15_zoom_picker: OptionButton
var hq_v15_thumbnail: TextureRect
var hq_v15_frame: CenterContainer
var hq_v15_caption: Label
var hq_weather_picker: OptionButton
var hq_terrain_picker: OptionButton
var hq_climate_stage: Node3D
var hq_climate_status: Label
var hq_wayfinding_toggle: CheckButton
var hq_facade_v19_toggle: CheckButton
var _hq_weather_time := 0.0
var hq_camera_picker: OptionButton
var _hq_camera_preset := 0
var hq_lighting_picker: OptionButton
var hq_lighting_label: Label
var hq_fill_light: DirectionalLight3D
var hq_environment: WorldEnvironment
var hq_night_lamps: Array[OmniLight3D] = []
var _hq_light_preset := 0
var faction_view_grid: GridContainer
var faction_view_label: Label
var faction_view_buttons: Array[Button] = []
var hq_map_lod_toggle: CheckButton
var hq_batch_toggle: CheckButton
var hq_stress_picker: OptionButton
var _hq_grid_dimension := 7
var hq_fps_label: Label
var _fps_refresh := 0.0
var hq_ground: MeshInstance3D
var hq_key_light: DirectionalLight3D
var _hq_show_v2 := true
var _hq_show_v3 := true
var _hq_show_v4 := true

func _ready() -> void:
    super._ready()
    _add_building_mode()
    _setup_architecture_stage()
    _add_naval_controls()
    _add_supply_controls()

func _setup_architecture_stage() -> void:
    # Only the laboratory gets a ground plane and true shadows. The actual
    # building geometry and tactical terrain remain separate.
    var ground_mesh := PlaneMesh.new()
    ground_mesh.size = Vector2(120.0,120.0)
    var ground_material := StandardMaterial3D.new()
    ground_material.albedo_color = Color("#182d32")
    ground_material.metallic = 0.04
    ground_material.roughness = 0.98
    hq_ground = MeshInstance3D.new()
    hq_ground.name = "SueloNeutroDeEstudio3D"
    hq_ground.mesh = ground_mesh
    hq_ground.material_override = ground_material
    hq_ground.position = Vector3(0,-0.28,0)
    hq_ground.visible = false
    preview.add_child(hq_ground)
    for child in preview.get_children():
        if child is DirectionalLight3D:
            if hq_key_light == null:
                hq_key_light = child as DirectionalLight3D
                hq_key_light.shadow_enabled = false
            else:
                hq_fill_light = child as DirectionalLight3D
        elif child is WorldEnvironment:
            hq_environment = child as WorldEnvironment
    for lamp_data in [
            [Vector3(0,2.65,-5.4),Color("#ffd39d"),5.0],
            [Vector3(4.8,2.5,-4.1),Color("#a4dfff"),6.3],
            [Vector3(0,7.0,-3.3),Color("#cbdfff"),7.4]]:
        var lamp := OmniLight3D.new()
        lamp.name = "BalizaNocturnaEscenarioV11"
        lamp.position = lamp_data[0] as Vector3
        lamp.light_color = lamp_data[1] as Color
        lamp.omni_range = float(lamp_data[2])*1.55
        lamp.light_energy = 1.75
        lamp.shadow_enabled = false
        lamp.visible = false
        preview.add_child(lamp)
        hq_night_lamps.append(lamp)
    hq_climate_stage = HQClimateV17.build()
    preview.add_child(hq_climate_stage)
    hq_climate_stage.visible = false
    _apply_hq_lighting(0)

func _apply_hq_lighting(index: int) -> void:
    if hq_key_light == null or hq_environment == null:
        return
    var active: bool = _role in ["headquarters","airbase","naval_base","supply_center"]
    _hq_light_preset = clampi(index,0,2)
    var preset: int = _hq_light_preset if active else 0
    # Three reproducible lighting rigs, same camera and exact 3D material.
    # Material response is measured instead of painted with false colors.
    var sun_color := [Color("#fff3e4"),Color("#ffc289"),Color("#b5d2f5")]
    var sky_color := [Color("#14232d"),Color("#493b38"),Color("#040b18")]
    var ambient_color := [Color("#c1d5de"),Color("#e1a789"),Color("#b5cbe3")]
    var key_energy := [1.65,1.23,0.61]
    var fill_energy := [0.80,0.37,0.51]
    var ambient_energy := [0.84,0.61,1.02]
    var pitch := [-46.0,-18.0,-29.0]
    if hq_key_light != null:
        hq_key_light.rotation_degrees = Vector3(float(pitch[preset]),-32.0,0)
        hq_key_light.light_color = sun_color[preset]
        hq_key_light.light_energy = float(key_energy[preset])
        hq_key_light.shadow_enabled = active
    if hq_fill_light != null:
        hq_fill_light.light_color = ambient_color[preset]
        hq_fill_light.light_energy = float(fill_energy[preset])
    var scene: Environment = hq_environment.environment
    if scene != null:
        scene.background_color = sky_color[preset]
        scene.ambient_light_color = ambient_color[preset]
        scene.ambient_light_energy = float(ambient_energy[preset])
    for lamp in hq_night_lamps:
        lamp.visible = active and preset == 2
    if hq_ground != null:
        var ground_mat: StandardMaterial3D = hq_ground.material_override as StandardMaterial3D
        if ground_mat != null:
            ground_mat.albedo_color = Color("#171f2b") if active and preset == 2 else Color("#182d32")
    # Weather is visual: lower cloud cover and cooler ambient light without
    # modifying canonical Android weather movement penalties.
    if active and hq_weather_picker != null and hq_weather_picker.selected >= 0:
        var weather: String = str(HQClimateV17.WEATHERS[hq_weather_picker.selected])
        if weather == "rain":
            hq_key_light.light_energy *= 0.64
            hq_fill_light.light_energy *= 0.78
            scene.background_color = scene.background_color.lerp(Color("#293d4c"),0.75)
            scene.ambient_light_color = scene.ambient_light_color.lerp(Color("#a3b8c8"),0.55)
        elif weather == "snow":
            hq_key_light.light_energy *= 0.72
            hq_fill_light.light_energy *= 0.90
            scene.background_color = scene.background_color.lerp(Color("#8c9da9"),0.56)
            scene.ambient_light_color = scene.ambient_light_color.lerp(Color("#dce6ec"),0.52)
    _sync_hq_wayfinding_v18()

func _sync_hq_wayfinding_v18() -> void:
    if _role != "headquarters" or model_root == null or hq_wayfinding_toggle == null:
        return
    var lamps: Node3D = model_root.get_node_or_null(HQWayfindingV18.STAGE_NAME) as Node3D
    if lamps == null:
        return
    var level: int = level_picker.selected + 1
    var condition: String = str(BUILDING_STATES[building_state_picker.selected])
    var weather: String = "clear"
    if hq_weather_picker != null and hq_weather_picker.selected >= 0:
        weather = str(HQClimateV17.WEATHERS[hq_weather_picker.selected])
    # Never hide visual side effects inside assert(): release WebGL omits
    # assertions and would otherwise leave the entire effect inactive.
    var applied: bool = HQWayfindingV18.apply(lamps,_faction,level,condition,
        _hq_light_preset,weather,hq_wayfinding_toggle.button_pressed,
        bool(model_root.get_meta("tarvoka_hq_map_distant",false)))
    assert(applied)

func _sync_hq_facade_v19() -> void:
    if _role != "headquarters" or model_root == null or hq_facade_v19_toggle == null:
        return
    var stage: Node3D = model_root.get_node_or_null(HQFacadeV19.STAGE_NAME) as Node3D
    if stage == null:
        return
    var weather: String = "clear"
    if hq_weather_picker != null and hq_weather_picker.selected >= 0:
        weather = str(HQClimateV17.WEATHERS[hq_weather_picker.selected])
    var applied: bool = HQFacadeV19.apply(stage,_faction,level_picker.selected+1,
        str(BUILDING_STATES[building_state_picker.selected]),weather,
        hq_facade_v19_toggle.button_pressed,
        bool(model_root.get_meta("tarvoka_hq_map_distant",false)))
    assert(applied)

func _change_hq_facade_v19(_enabled: bool) -> void:
    _sync_hq_facade_v19()

func _change_hq_wayfinding_v18(_enabled: bool) -> void:
    _sync_hq_wayfinding_v18()

func _change_hq_lighting(index: int) -> void:
    _apply_hq_lighting(index)

func _change_hq_weather_v17(index: int) -> void:
    if index < 0 or index >= HQClimateV17.WEATHERS.size():
        return
    hq_weather_picker.select(index)
    _apply_hq_climate_v17()
    _apply_hq_lighting(_hq_light_preset)
    _sync_hq_facade_v19()

func _change_hq_terrain_v17(index: int) -> void:
    if index < 0 or index >= HQClimateV17.TERRAINS.size():
        return
    hq_terrain_picker.select(index)
    _apply_hq_climate_v17()

func _apply_hq_climate_v17() -> void:
    if hq_climate_stage == null or hq_weather_picker == null or hq_terrain_picker == null:
        return
    var weather: String = str(HQClimateV17.WEATHERS[hq_weather_picker.selected])
    var terrain: String = str(HQClimateV17.TERRAINS[hq_terrain_picker.selected])
    var level: int = maxi(1,level_picker.selected+1)
    var condition: String = str(BUILDING_STATES[maxi(0,building_state_picker.selected)])
    var sprite_mode: bool = hq_v15_mode_picker.selected == 2
    # UI events MUST execute in export-release too (no side effects in assert).
    var climate_applied: bool = HQClimateV17.apply(
        hq_climate_stage,weather,terrain,level,condition,sprite_mode)
    assert(climate_applied)
    hq_climate_stage.visible = _role=="headquarters" and not hq_batch_toggle.button_pressed
    # The V17 set, puddles and precip are environment-only. The real
    # V12/V13 HQ mesh now gets the SAME reversible universal coating as G09.
    # Sprite V15 is a pre-baked PNG: NEVER reinterpret its colors/materials.
    var actual_model: bool = model_root != null and is_instance_valid(model_root) and \
        model_root.get_parent() == preview and \
        model_root.get_meta("tarvoka_building_kind","") == "headquarters" and \
        not sprite_mode and not hq_batch_toggle.button_pressed
    var model_stats: Dictionary = {}
    if actual_model:
        model_stats = model_root.get_meta("weather_coating",{})
        if str(model_stats.get("mode","")) != weather:
            model_stats = UniversalClimate.apply(model_root,weather,
                model_root.get_meta("tarvoka_hq_production_v13",false))
        # Universal roof patches follow the actual building and its rotation;
        # suppress the older standalone roof slabs to avoid duplicate snow.
        if weather == "snow" and int(model_stats.get("snow_nodes",0)) > 0:
            for i in range(3):
                var roof: MeshInstance3D = hq_climate_stage.get_node_or_null(
                    "NieveAcumuladaCubiertaV17_%d" % i) as MeshInstance3D
                if roof != null:
                    roof.visible = false
    if hq_climate_status != null:
        hq_climate_status.text = "%s · %s · máximo %d lotes 3D de clima/entorno. Sprite V15: imagen seca original." % [
            str(HQClimateV17.WEATHER_NAMES[hq_weather_picker.selected]),
            str(HQClimateV17.TERRAIN_NAMES[hq_terrain_picker.selected]),
            HQClimateV17.active_mesh_count(hq_climate_stage)]
        if hq_batch_toggle != null and hq_batch_toggle.button_pressed:
            hq_climate_status.text = "Distrito agrupado: clima visual desactivado (prueba de rendimiento)."
        elif sprite_mode:
            hq_climate_status.text += " · El sprite no se modifica; solo el entorno."
        if actual_model:
            hq_climate_status.text += " · Modelo 3D: %d materiales húmedos / %d mallas nieve." % [
                int(model_stats.get("wet",0)),int(model_stats.get("snow_nodes",0))]

func _add_building_mode() -> void:
    # Use the same SubViewport and camera that already serve the tank.
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    assert(column != null)
    for node in column.get_children():
        if node is Label and (node as Label).text.begins_with("El mismo modelo de Godot"):
            (node as Label).text = "Visor 3D del motor Godot: las unidades se usan en Android; los edificios son prototipos visuales independientes. Arrastra para girar y pellizca para acercar."
    category_picker = OptionButton.new()
    category_picker.name = "CategoriaEstudio3D"
    category_picker.custom_minimum_size.y = 52.0
    category_picker.add_item("UNIDADES 3D")
    category_picker.add_item("EDIFICIOS 3D")
    category_picker.select(0)
    category_picker.item_selected.connect(_switch_category)
    column.add_child(category_picker)
    column.move_child(category_picker,3)

    # Remember exactly which existing controls are tank/unit-specific.
    # Common faction, rotation, zoom and reset widgets remain shared.
    var unit_section := false
    for node in column.get_children():
        if node is Label:
            var label: String = (node as Label).text
            if label == "MODELO" or label == "ANIMACION REAL" or label == "CONDICION DEL TANQUE":
                unit_section = true
            elif label == "FACCION" or label == "ROTAR Y ACERCAR":
                unit_section = false
        if node == detail_label:
            unit_section = false
        if unit_section and node is Control:
            _unit_only_controls.append(node as Control)

    building_controls = VBoxContainer.new()
    building_controls.name = "OpcionesDeEdificios"
    building_controls.add_theme_constant_override("separation",8)
    column.add_child(building_controls)
    var building_heading := _title(building_controls,"EDIFICIO",14)
    building_heading.add_theme_color_override("font_color",Color("#f1c978"))
    building_picker = OptionButton.new()
    building_picker.name = "TipoDeEdificio"
    building_picker.custom_minimum_size.y = 49
    building_picker.add_item("Cuartel General")
    building_picker.add_item("Base Aérea · V16 · revisión final 360°")
    building_picker.add_item("Base Naval · V13 · inspección real de amarres")
    building_picker.add_item("Centro de Suministros · V1 · logística 3D")
    building_picker.item_selected.connect(_change_selected_building)
    building_controls.add_child(building_picker)
    _title(building_controls,"V17 · CLIMA Y TERRENO DEL CUARTEL",13)
    var climate_row := HBoxContainer.new()
    climate_row.name = "SelectorClimaYTerrenoHQV17"
    climate_row.add_theme_constant_override("separation",5)
    building_controls.add_child(climate_row)
    hq_weather_picker = OptionButton.new()
    hq_weather_picker.name = "ClimaVisualHQV17"
    hq_weather_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hq_weather_picker.custom_minimum_size = Vector2(125,45)
    for weather_name in HQClimateV17.WEATHER_NAMES:
        hq_weather_picker.add_item(str(weather_name))
    hq_weather_picker.select(0)
    hq_weather_picker.item_selected.connect(_change_hq_weather_v17)
    climate_row.add_child(hq_weather_picker)
    hq_terrain_picker = OptionButton.new()
    hq_terrain_picker.name = "TerrenoVisualHQV17"
    hq_terrain_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hq_terrain_picker.custom_minimum_size = Vector2(125,45)
    for terrain_name in HQClimateV17.TERRAIN_NAMES:
        hq_terrain_picker.add_item(str(terrain_name))
    hq_terrain_picker.select(0)
    hq_terrain_picker.item_selected.connect(_change_hq_terrain_v17)
    climate_row.add_child(hq_terrain_picker)
    _title(building_controls,"V15 · ARTE REAL UTILIZADO EN ANDROID",13)
    hq_v15_mode_picker = OptionButton.new()
    hq_v15_mode_picker.name = "ModoVisorModelo3DYSpriteV15"
    hq_v15_mode_picker.custom_minimum_size.y = 48
    hq_v15_mode_picker.add_item("3D real + sprite V15 (comparar)")
    hq_v15_mode_picker.add_item("Solo 3D real (ocultar sprite)")
    hq_v15_mode_picker.add_item("Mostrar sprite V15 en escenario 3D")
    hq_v15_mode_picker.select(0)
    hq_v15_mode_picker.item_selected.connect(_change_hq_v15_mode)
    building_controls.add_child(hq_v15_mode_picker)

    hq_v15_neutral_toggle = CheckButton.new()
    hq_v15_neutral_toggle.name = "V15NeutralNieblaSinEscudo"
    hq_v15_neutral_toggle.text = "Sprite neutral (niebla sin insignia)"
    hq_v15_neutral_toggle.toggled.connect(_change_hq_v15_neutral)
    building_controls.add_child(hq_v15_neutral_toggle)

    hq_v15_zoom_picker = OptionButton.new()
    hq_v15_zoom_picker.name = "ZoomVisualAndroidV15"
    hq_v15_zoom_picker.custom_minimum_size.y = 42
    for zoom_text in HQSpriteV16.ZOOM_LABELS:
        hq_v15_zoom_picker.add_item(str(zoom_text))
    hq_v15_zoom_picker.select(0)
    hq_v15_zoom_picker.item_selected.connect(_change_hq_v15_zoom)
    building_controls.add_child(hq_v15_zoom_picker)

    hq_v15_frame = CenterContainer.new()
    hq_v15_frame.name = "ComparacionSpriteV15EnEstudio3D"
    hq_v15_frame.custom_minimum_size = Vector2(270,198)
    hq_v15_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    building_controls.add_child(hq_v15_frame)
    hq_v15_thumbnail = TextureRect.new()
    hq_v15_thumbnail.name = "TexturaHQV15RealAndroid"
    hq_v15_thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hq_v15_thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hq_v15_thumbnail.custom_minimum_size = Vector2(188,188)
    hq_v15_thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hq_v15_frame.add_child(hq_v15_thumbnail)
    hq_v15_caption = _title(building_controls,
        "Sprite Android V15 · 384 px · exportado desde Godot V13",12)
    _refresh_hq_v15_sprite()
    hq_climate_status = _title(building_controls,
        "Comparación estética · lluvia/nieve con volúmenes 3D · sin cambios de jugabilidad",11)

    hq_compare_button = _button(building_controls,
        "Comparar con diseño anterior (V1)",_toggle_hq_finish)
    hq_compare_button.name = "CompararAcabadoDeEdificio"
    hq_compare_button.custom_minimum_size.y = 49
    hq_v3_compare_button = _button(building_controls,
        "Comparar arquitectura V2 / V3",_toggle_hq_detail)
    hq_v3_compare_button.name = "ComparadorArquitecturaV3"
    hq_v3_compare_button.custom_minimum_size.y = 49
    hq_compare_button.visible = false
    hq_v3_compare_button.visible = false
    _title(building_controls,"ACABADO VISUAL",14)
    hq_version_picker = OptionButton.new()
    hq_version_picker.name = "SelectorAcabadoCuartelGeneral"
    hq_version_picker.custom_minimum_size.y = 50
    for name_version in ["V13 · Escultura V12 + perfil optimizado opcional",
            "V3 · Arquitectura anterior",
            "V2 · Primera revisión",
            "V1 · Prototipo original"]:
        hq_version_picker.add_item(name_version)
    hq_version_picker.select(0)
    hq_version_picker.item_selected.connect(_change_hq_version)
    building_controls.add_child(hq_version_picker)
    hq_v7_toggle = CheckButton.new()
    hq_v7_toggle.name = "AcabadoArquitectonicoV7"
    hq_v7_toggle.text = "Acabado escultórico V7 (comparar con V4)"
    hq_v7_toggle.button_pressed = true
    hq_v7_toggle.toggled.connect(_change_hq_sculpt)
    building_controls.add_child(hq_v7_toggle)
    hq_v8_toggle = CheckButton.new()
    hq_v8_toggle.name = "AcabadoMaterialesYDesgasteV8"
    hq_v8_toggle.text = "Materiales PBR y daños V8 (comparar con V7)"
    hq_v8_toggle.button_pressed = true
    hq_v8_toggle.toggled.connect(_change_hq_materials_v8)
    building_controls.add_child(hq_v8_toggle)
    hq_v9_toggle = CheckButton.new()
    hq_v9_toggle.name = "SiluetaTacticaHQV9"
    hq_v9_toggle.text = "Silueta V9 visible a distancia (comparar V8)"
    hq_v9_toggle.button_pressed = true
    hq_v9_toggle.toggled.connect(_change_hq_readability_v9)
    building_controls.add_child(hq_v9_toggle)
    hq_v10_toggle = CheckButton.new()
    hq_v10_toggle.name = "TransicionesFisicasMaterialesV10"
    hq_v10_toggle.text = "Uniones y superficies V10 (comparar con V9)"
    hq_v10_toggle.button_pressed = true
    hq_v10_toggle.toggled.connect(_change_hq_surfaces_v10)
    building_controls.add_child(hq_v10_toggle)
    hq_v11_toggle = CheckButton.new()
    hq_v11_toggle.name = "EsculturaAristasRedondeadasV11"
    hq_v11_toggle.text = "Remates curvos V11 (comparar con V10)"
    hq_v11_toggle.button_pressed = true
    hq_v11_toggle.toggled.connect(_change_hq_refinement_v11)
    building_controls.add_child(hq_v11_toggle)
    hq_v12_toggle = CheckButton.new()
    hq_v12_toggle.name = "SiluetaDistanciaHQV12"
    hq_v12_toggle.text = "Silueta táctica V12 (comparar con V11)"
    hq_v12_toggle.button_pressed = true
    hq_v12_toggle.toggled.connect(_change_hq_silhouette_v12)
    building_controls.add_child(hq_v12_toggle)
    hq_production_toggle = CheckButton.new()
    hq_production_toggle.name = "PerfilComercialHQV13"
    hq_production_toggle.text = "Perfil táctico V13 (sin miles de mallas ocultas)"
    hq_production_toggle.button_pressed = false
    hq_production_toggle.toggled.connect(_change_hq_production_v13)
    building_controls.add_child(hq_production_toggle)
    hq_production_metric_label = _title(building_controls,
        "Perfil V13: 2 mallas · 10 superficies · 8 escudos oficiales",12)
    hq_production_metric_label.visible = false

    hq_lighting_label = _title(building_controls,"ILUMINACIÓN DE ESTUDIO",13)
    hq_lighting_picker = OptionButton.new()
    hq_lighting_picker.name = "IluminacionCuartelGeneral"
    hq_lighting_picker.custom_minimum_size.y = 49
    for name_preset in ["Día neutro","Atardecer cálido","Noche operativa"]:
        hq_lighting_picker.add_item(name_preset)
    hq_lighting_picker.select(0)
    hq_lighting_picker.item_selected.connect(_change_hq_lighting)
    building_controls.add_child(hq_lighting_picker)
    hq_wayfinding_toggle = CheckButton.new()
    hq_wayfinding_toggle.name = "SenalizacionArquitectonicaHQV18"
    hq_wayfinding_toggle.text = "V18 · Accesos iluminados y balizas 3D agrupadas"
    hq_wayfinding_toggle.button_pressed = true
    hq_wayfinding_toggle.toggled.connect(_change_hq_wayfinding_v18)
    building_controls.add_child(hq_wayfinding_toggle)
    hq_facade_v19_toggle = CheckButton.new()
    hq_facade_v19_toggle.name = "FachadaBiseladaEscudoOficialV19"
    hq_facade_v19_toggle.text = "V19 · Marcos biselados y contraste del escudo oficial"
    hq_facade_v19_toggle.button_pressed = true
    hq_facade_v19_toggle.toggled.connect(_change_hq_facade_v19)
    building_controls.add_child(hq_facade_v19_toggle)
    _title(building_controls,"ENCUADRE PARA REVISAR LA SILUETA",13)
    hq_camera_picker = OptionButton.new()
    hq_camera_picker.name = "EncuadreDeBatallaHQ"
    hq_camera_picker.custom_minimum_size.y = 49
    hq_camera_picker.add_item("Inspección cercana")
    hq_camera_picker.add_item("Distancia táctica real")
    hq_camera_picker.select(0)
    hq_camera_picker.item_selected.connect(_change_hq_camera)
    building_controls.add_child(hq_camera_picker)

    _title(building_controls,"NIVEL ARQUITECTONICO",13)
    level_picker = OptionButton.new()
    level_picker.name = "NivelDeEdificio"
    level_picker.custom_minimum_size.y = 49
    level_picker.add_item("Nivel 1 — Puesto de mando")
    level_picker.add_item("Nivel 2 — Centro de comunicaciones")
    level_picker.add_item("Nivel 3 — Complejo avanzado")
    level_picker.select(0)
    level_picker.item_selected.connect(_change_building_variant)
    building_controls.add_child(level_picker)

    _title(building_controls,"ESTADO DE LA INSTALACION",13)
    building_state_picker = OptionButton.new()
    building_state_picker.name = "EstadoDeEdificio"
    building_state_picker.custom_minimum_size.y = 49
    for condition in ["Operativo","Capturado","Dañado","Destruido"]:
        building_state_picker.add_item(condition)
    building_state_picker.item_selected.connect(_change_hq_installation_state)
    building_controls.add_child(building_state_picker)
    _title(building_controls,"NIVELES DE DAÑO ESTRUCTURAL · V21",13)
    hq_damage_stage_picker = OptionButton.new()
    hq_damage_stage_picker.name = "CincoNivelesDanoFisicoHQV21"
    hq_damage_stage_picker.custom_minimum_size.y = 49
    for label in HQDamageV21.STAGES:
        hq_damage_stage_picker.add_item(label)
    hq_damage_stage_picker.select(0)
    hq_damage_stage_picker.item_selected.connect(_change_hq_damage_stage)
    building_controls.add_child(hq_damage_stage_picker)
    var attacks := HBoxContainer.new()
    attacks.name = "PruebaImpactoBalasYExplosivosHQV21"
    attacks.add_theme_constant_override("separation",6)
    building_controls.add_child(attacks)
    hq_bullet_test_button = Button.new()
    hq_bullet_test_button.name = "ProbarDisparoDeBalasHQV21"
    hq_bullet_test_button.text = "Impacto de balas"
    hq_bullet_test_button.custom_minimum_size.y = 48
    hq_bullet_test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hq_bullet_test_button.pressed.connect(_play_hq_bullet_v21)
    attacks.add_child(hq_bullet_test_button)
    hq_explosive_test_button = Button.new()
    hq_explosive_test_button.name = "ProbarImpactoExplosivoHQV21"
    hq_explosive_test_button.text = "Ataque explosivo"
    hq_explosive_test_button.custom_minimum_size.y = 48
    hq_explosive_test_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hq_explosive_test_button.pressed.connect(_play_hq_explosion_v21)
    attacks.add_child(hq_explosive_test_button)
    hq_impact_status = _title(building_controls,
        "Impactos 3D de prueba · no alteran HP ni la partida.",12)
    hq_map_lod_toggle = CheckButton.new()
    hq_map_lod_toggle.name = "VistaTacticaOptimizadaHQ"
    hq_map_lod_toggle.text = "Vista lejana optimizada (mapa)"
    hq_map_lod_toggle.button_pressed = false
    hq_map_lod_toggle.toggled.connect(_set_hq_map_lod)
    building_controls.add_child(hq_map_lod_toggle)
    hq_batch_toggle = CheckButton.new()
    hq_batch_toggle.name = "Escenario49Cuarteles"
    hq_batch_toggle.text = "Prueba de rendimiento · edificios 3D agrupados"
    hq_batch_toggle.toggled.connect(_change_building_batch)
    building_controls.add_child(hq_batch_toggle)
    hq_stress_picker = OptionButton.new()
    hq_stress_picker.name = "Escenarios49_100_144CuartelesV19"
    hq_stress_picker.custom_minimum_size.y = 46
    for label in ["49 edificios (7×7)","100 edificios (10×10)","144 edificios (12×12)"]:
        hq_stress_picker.add_item(label)
    hq_stress_picker.select(0)
    hq_stress_picker.item_selected.connect(_change_hq_stress_dimension)
    building_controls.add_child(hq_stress_picker)
    hq_stress_picker.visible = false
    hq_fps_label = _title(building_controls,"FPS: — | 49 edificios | carga agrupada",12)
    hq_fps_label.visible = false
    _title(building_controls,
        "Modelo editable de prueba. La arquitectura, daños y niveles "
        + "son visuales: no cambian estadísticas, recursos ni partidas.",12)
    # Group only the HQ-specific items; shared building/faction/camera
    # selectors remain intact. This avoids hiding functional controls
    # by guessing label names when the Airbase is selected.
    for control in building_controls.get_children():
        if control != building_heading and control != building_picker and control is Control:
            _hq_specific_controls.append(control as Control)
    airbase_controls = VBoxContainer.new()
    airbase_controls.name = "OpcionesBaseAereaV1"
    airbase_controls.add_theme_constant_override("separation",8)
    building_controls.add_child(airbase_controls)
    _title(airbase_controls,"BASE AÉREA · V6 ACABADOS 3D REALES",13)
    airbase_exterior_v6_toggle = CheckButton.new()
    airbase_exterior_v6_toggle.name = "AcabadosArquitectonicosBaseAereaV6"
    airbase_exterior_v6_toggle.text = "V6 · fachadas, cubierta, torre y pavimento (comparar V4)"
    airbase_exterior_v6_toggle.button_pressed = true
    airbase_exterior_v6_toggle.toggled.connect(_toggle_airbase_exterior_v6)
    airbase_controls.add_child(airbase_exterior_v6_toggle)
    _title(airbase_controls,
        "Comparación V6/V4 con los mismos niveles, portones, clima y daños.",12)
    airbase_material_v7_toggle = CheckButton.new()
    airbase_material_v7_toggle.name = "MaterialesPBRYDesgasteFisicoBaseAereaV7"
    airbase_material_v7_toggle.text = "V7 · texturas PBR y desgaste (comparar V6)"
    airbase_material_v7_toggle.button_pressed = true
    airbase_material_v7_toggle.toggled.connect(_toggle_airbase_material_v7)
    airbase_controls.add_child(airbase_material_v7_toggle)
    _title(airbase_controls,
        "V7 · concreto, metal, techo, cristales y marcas de servicio; clima reversible.",12)
    airbase_finish_v8_toggle = CheckButton.new()
    airbase_finish_v8_toggle.name = "CristalesIluminacionYSuciedadBaseAereaV8"
    airbase_finish_v8_toggle.text = "V8 · cristales, luces y suciedad (comparar V7)"
    airbase_finish_v8_toggle.button_pressed = true
    airbase_finish_v8_toggle.toggled.connect(_toggle_airbase_finish_v8)
    airbase_controls.add_child(airbase_finish_v8_toggle)
    _title(airbase_controls,
        "V8 · reflejos del control aéreo y luz agrupada en hangar sin focos extra.",12)
    airbase_detail_v9_toggle = CheckButton.new()
    airbase_detail_v9_toggle.name = "CabinaPanoramicaRematesBaseAereaV9"
    airbase_detail_v9_toggle.text = "V9 · cristal fino, cabina real y remates (comparar V8)"
    airbase_detail_v9_toggle.button_pressed = true
    airbase_detail_v9_toggle.toggled.connect(_toggle_airbase_detail_v9)
    airbase_controls.add_child(airbase_detail_v9_toggle)
    _title(airbase_controls,
        "V9 · volumen de vidrio vaciado, interior visible y remates unidos al techo.",12)
    airbase_structure_v10_toggle = CheckButton.new()
    airbase_structure_v10_toggle.name = "CerchasCubiertaYFachadaPosteriorBaseAereaV10"
    airbase_structure_v10_toggle.text = "V10 · cerchas reales, fachada trasera y equipos alineados (comparar V9)"
    airbase_structure_v10_toggle.button_pressed = true
    airbase_structure_v10_toggle.toggled.connect(_toggle_airbase_structure_v10)
    airbase_controls.add_child(airbase_structure_v10_toggle)
    _title(airbase_controls,
        "V10 · cerchas siguiendo las 14 chapas del techo, sin cubrir daños.",12)
    airbase_trusses_v11_toggle = CheckButton.new()
    airbase_trusses_v11_toggle.name = "CerchasCruzadasYDesgarrosRealesBaseAereaV11"
    airbase_trusses_v11_toggle.text = "V11 · cerchas cruzadas, soportes y roturas (comparar V10)"
    airbase_trusses_v11_toggle.button_pressed = true
    airbase_trusses_v11_toggle.toggled.connect(_toggle_airbase_trusses_v11)
    airbase_controls.add_child(airbase_trusses_v11_toggle)
    _title(airbase_controls,
        "V11 · soportes 3D bajo cada chapa, sin atravesar huecos destruidos.",12)
    airbase_v11_cutaway_toggle = CheckButton.new()
    airbase_v11_cutaway_toggle.name = "InspeccionSinChapasTechoBaseAereaV11"
    airbase_v11_cutaway_toggle.text = "Inspeccionar cerchas: ocultar chapas del techo"
    airbase_v11_cutaway_toggle.button_pressed = false
    airbase_v11_cutaway_toggle.toggled.connect(_toggle_airbase_cutaway_v11)
    airbase_controls.add_child(airbase_v11_cutaway_toggle)
    _title(airbase_controls,
        "Vista desmontable del estudio; no modifica el modelo del juego.",12)
    airbase_fracture_v12_toggle = CheckButton.new()
    airbase_fracture_v12_toggle.name = "ExplosionQuemadurasYAceroTorcidoBaseAereaV12"
    airbase_fracture_v12_toggle.text = "V12 · bordes quemados, vigas torcidas y fragmentos (comparar V11)"
    airbase_fracture_v12_toggle.button_pressed = true
    airbase_fracture_v12_toggle.toggled.connect(_toggle_airbase_fracture_v12)
    airbase_controls.add_child(airbase_fracture_v12_toggle)
    _title(airbase_controls,
        "Al pulsar Explosión se animan seis esquirlas metálicas 3D sin cambiar HP.",12)
    _title(airbase_controls,"Nivel arquitectónico",12)
    airbase_level_picker = OptionButton.new()
    airbase_level_picker.name = "NivelBaseAereaV1"
    airbase_level_picker.custom_minimum_size.y = 49
    for label in ["Nivel 1 · Aeródromo táctico","Nivel 2 · Radar y apoyo",
            "Nivel 3 · Complejo aéreo avanzado"]:
        airbase_level_picker.add_item(label)
    airbase_level_picker.item_selected.connect(_change_airbase_level)
    airbase_controls.add_child(airbase_level_picker)
    _title(airbase_controls,"Cinco estados visuales de daño",12)
    airbase_damage_picker = OptionButton.new()
    airbase_damage_picker.name = "DanoFisicoBaseAereaV1"
    airbase_damage_picker.custom_minimum_size.y = 49
    for label in AirbaseV1.DAMAGE_STAGES:
        airbase_damage_picker.add_item(str(label))
    airbase_damage_picker.item_selected.connect(_change_airbase_damage)
    airbase_controls.add_child(airbase_damage_picker)
    _title(airbase_controls,"Clima de estudio",12)
    airbase_weather_picker = OptionButton.new()
    airbase_weather_picker.name = "ClimaBaseAereaV1"
    airbase_weather_picker.custom_minimum_size.y = 49
    for label in ["Despejado","Lluvia","Nieve"]:
        airbase_weather_picker.add_item(label)
    airbase_weather_picker.item_selected.connect(_change_airbase_weather)
    airbase_controls.add_child(airbase_weather_picker)
    _title(airbase_controls,"V2 · PORTONES MOTORIZADOS DEL HANGAR",13)
    var doors_row := HBoxContainer.new()
    doors_row.name = "ControlesPortonesRealesBaseAereaV2"
    doors_row.add_theme_constant_override("separation",6)
    airbase_controls.add_child(doors_row)
    airbase_open_button = _button(doors_row,"Abrir portones",
        func(): _play_airbase_doors(true))
    airbase_open_button.name = "AbrirPortonesHangarV2"
    airbase_open_button.custom_minimum_size.y = 45
    airbase_open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    airbase_close_button = _button(doors_row,"Cerrar portones",
        func(): _play_airbase_doors(false))
    airbase_close_button.name = "CerrarPortonesHangarV2"
    airbase_close_button.custom_minimum_size.y = 45
    airbase_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    airbase_gate_slider = HSlider.new()
    airbase_gate_slider.name = "AperturaPortonesHangarV2"
    airbase_gate_slider.min_value = 0.0
    airbase_gate_slider.max_value = 1.0
    airbase_gate_slider.step = 0.01
    airbase_gate_slider.custom_minimum_size.y = 43
    airbase_gate_slider.value_changed.connect(_scrub_airbase_doors)
    airbase_controls.add_child(airbase_gate_slider)
    airbase_gate_status = _title(airbase_controls,
        "Portones preparados · apertura: 0 %",12)
    airbase_camera_button = _button(airbase_controls,
        "Inspeccionar interior del hangar",_toggle_airbase_camera)
    airbase_camera_button.name = "InspeccionarInteriorHangarV2"
    airbase_camera_button.custom_minimum_size.y = 44
    _title(airbase_controls,"V9 · INSPECCIÓN DESDE TODOS LOS ÁNGULOS",12)
    airbase_v9_view_picker = OptionButton.new()
    airbase_v9_view_picker.name = "VistasMultiplesBaseAereaV9"
    airbase_v9_view_picker.custom_minimum_size.y = 46
    for angle_name in [
            "Frontal isométrica","Lateral izquierdo","Posterior",
            "Lateral derecho","Cubierta superior","Torre de control",
            "Interior hangar","Frontal bajo"]:
        airbase_v9_view_picker.add_item(angle_name)
    airbase_v9_view_picker.select(0)
    airbase_v9_view_picker.item_selected.connect(_change_airbase_v9_view)
    airbase_controls.add_child(airbase_v9_view_picker)
    _title(airbase_controls,"V3 · IMPACTOS Y DAÑOS ATMOSFÉRICOS",13)
    var hits := HBoxContainer.new()
    hits.name = "ImpactosBalasExplosivosBaseAereaV3"
    hits.add_theme_constant_override("separation",6)
    airbase_controls.add_child(hits)
    airbase_impact_bullet_button = _button(hits,"Impacto de bala",
        func(): _play_airbase_impact("bullet"))
    airbase_impact_bullet_button.custom_minimum_size.y = 46
    airbase_impact_bullet_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    airbase_impact_explosive_button = _button(hits,"Impacto explosivo",
        func(): _play_airbase_impact("explosive"))
    airbase_impact_explosive_button.custom_minimum_size.y = 46
    airbase_impact_explosive_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title(airbase_controls,
        "V13 · IMPACTOS SEGÚN MATERIAL Y TIPO DE ATAQUE",13)
    airbase_impacts_v13_toggle = CheckButton.new()
    airbase_impacts_v13_toggle.name = "ImpactosMaterialBalasMisilesBombardeoBaseAereaV13"
    airbase_impacts_v13_toggle.text = "V13 · efectos específicos (comparar V12)"
    airbase_impacts_v13_toggle.button_pressed = true
    airbase_impacts_v13_toggle.toggled.connect(_toggle_airbase_impacts_v13)
    airbase_controls.add_child(airbase_impacts_v13_toggle)
    airbase_surface_v13_picker = OptionButton.new()
    airbase_surface_v13_picker.name = "SuperficieObjetivoBaseAereaV13"
    airbase_surface_v13_picker.custom_minimum_size.y = 46
    for surface_name in [
            "Portón metálico · chispas y abolladuras",
            "Torre de concreto · polvo y desprendimientos",
            "Cubierta del hangar · quemaduras y fragmentos"]:
        airbase_surface_v13_picker.add_item(surface_name)
    airbase_surface_v13_picker.select(0)
    airbase_surface_v13_picker.item_selected.connect(
        _change_airbase_v13_target)
    airbase_controls.add_child(airbase_surface_v13_picker)
    airbase_v13_focus_toggle = CheckButton.new()
    airbase_v13_focus_toggle.name = "EnfoqueCercanoImpactoBaseAereaV13"
    airbase_v13_focus_toggle.text = "Enfocar objetivo para inspeccionar impactos de cerca"
    airbase_v13_focus_toggle.button_pressed = false
    airbase_v13_focus_toggle.toggled.connect(_toggle_airbase_v13_focus)
    airbase_controls.add_child(airbase_v13_focus_toggle)
    var attacks_v13 := HBoxContainer.new()
    attacks_v13.name = "AtaquesV13Diferenciados"
    attacks_v13.add_theme_constant_override("separation",6)
    airbase_controls.add_child(attacks_v13)
    airbase_missile_v13_button = _button(attacks_v13,"Misil",
        func(): _play_airbase_impact("missile"))
    airbase_missile_v13_button.name = "AtaqueMisilBaseAereaV13"
    airbase_missile_v13_button.custom_minimum_size.y = 46
    airbase_missile_v13_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    airbase_bombard_v13_button = _button(attacks_v13,"Bombardeo",
        func(): _play_airbase_impact("bombardment"))
    airbase_bombard_v13_button.name = "BombardeoSecuencialBaseAereaV13"
    airbase_bombard_v13_button.custom_minimum_size.y = 46
    airbase_bombard_v13_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _title(airbase_controls,
        "Usa Impacto de bala, Misil o Bombardeo; V12 conserva la explosión clásica.",12)
    _title(airbase_controls,
        "V14 · MARCAS QUE PERMANECEN TRAS CADA IMPACTO",13)
    airbase_scars_v14_toggle=CheckButton.new()
    airbase_scars_v14_toggle.name="HuellasPersistentesConRelieveBaseAereaV14"
    airbase_scars_v14_toggle.text="V14 · abolladuras, desconchones y carbonización (comparar V13)"
    airbase_scars_v14_toggle.button_pressed=true
    airbase_scars_v14_toggle.toggled.connect(_toggle_airbase_scars_v14)
    airbase_controls.add_child(airbase_scars_v14_toggle)
    airbase_finish_v15_toggle=CheckButton.new()
    airbase_finish_v15_toggle.name="FracturasNaturalesConcretoYMetalBaseAereaV15"
    airbase_finish_v15_toggle.text="V15 · grietas orgánicas, metal rasgado y carbonización (comparar V14)"
    airbase_finish_v15_toggle.button_pressed=true
    airbase_finish_v15_toggle.toggled.connect(_toggle_airbase_finish_v15)
    airbase_controls.add_child(airbase_finish_v15_toggle)
    _title(airbase_controls,
        "V15 · un lote de detalle por huella; comparar sin perder historial.",12)
    _title(airbase_controls,
        "V16 · inspección final de 8 vistas; ajustes mínimos de las marcas del concreto.",12)
    airbase_v14_reset_button=_button(airbase_controls,
        "Limpiar impactos acumulados",_clear_airbase_v14_marks)
    airbase_v14_reset_button.name="RepararSuperficiesEnEstudioV14"
    airbase_v14_reset_button.custom_minimum_size.y=46
    airbase_v14_status=_title(airbase_controls,
        "V14 · 0 impactos registrados · hasta 3 huellas por superficie.",12)
    airbase_mobile_fx_toggle = CheckButton.new()
    airbase_mobile_fx_toggle.name = "EfectosLivianosAndroidBaseAereaV3"
    airbase_mobile_fx_toggle.text = "Humo reducido · perfil Android"
    airbase_mobile_fx_toggle.toggled.connect(_set_airbase_mobile_vfx)
    airbase_controls.add_child(airbase_mobile_fx_toggle)
    airbase_impact_status = _title(airbase_controls,
        "V3: impactos visuales · no cambian puntos de vida.",12)
    _title(airbase_controls,
        "V4: humo suave, fuego con bordes animados y pista alineada.",12)
    _title(airbase_controls,
        "V4 · PRUEBA VISUAL DE CARGA (NO BENCHMARK ANDROID)",13)
    airbase_stress_toggle = CheckButton.new()
    airbase_stress_toggle.name = "MostrarEscenarioDeCargaBaseAereaV4"
    airbase_stress_toggle.text = "Vista de muchas bases aéreas · LOD real"
    airbase_stress_toggle.toggled.connect(_toggle_airbase_stress)
    airbase_controls.add_child(airbase_stress_toggle)
    airbase_stress_picker = OptionButton.new()
    airbase_stress_picker.name = "EscalaEdificiosBaseAereaV4"
    airbase_stress_picker.custom_minimum_size.y = 48
    for scenario in ["8 edificios · 8 facciones","32 edificios · LOD",
            "64 edificios · LOD"]:
        airbase_stress_picker.add_item(scenario)
    airbase_stress_picker.item_selected.connect(_change_airbase_stress_count)
    airbase_controls.add_child(airbase_stress_picker)
    airbase_stress_picker.visible = false
    airbase_stress_status = _title(airbase_controls,
        "Escenario inactivo · FPS reales de Android no disponibles.",12)
    airbase_stress_status.visible = false
    airbase_controls.visible = false
    building_controls.visible = false

    # Place above the shared faction selector.
    var index: int = column.get_children().find(faction_picker)
    column.move_child(building_controls,maxi(0,index-1))
    faction_picker.item_selected.connect(_refresh_building_faction)
    _install_faction_gallery(column)
    _sync_faction_gallery(_faction)

func _install_faction_gallery(column: VBoxContainer) -> void:
    # Restore the eight *visible*, officially approved faction views.
    # Keep the original full-name dropdown intact for accessibility.
    var gallery_heading := _title(column,"VISTAS POR FACCIÓN · 8 ESCUDOS OFICIALES",12)
    faction_view_label = _title(column,"",12)
    faction_view_label.name = "NombreFaccionEnEstudio"
    faction_view_grid = GridContainer.new()
    faction_view_grid.name = "GaleriaOchoFacciones"
    faction_view_grid.columns = 2
    faction_view_grid.add_theme_constant_override("h_separation",6)
    faction_view_grid.add_theme_constant_override("v_separation",6)
    column.add_child(faction_view_grid)
    for faction in range(VisualStyle.FACTIONS.size()):
        var record: Dictionary = VisualStyle.FACTIONS[faction]
        var button := Button.new()
        button.name = "FaccionOficial_%d" % faction
        # Compact labels fit the 306px scroll panel; tooltip and selected
        # label always show the full, approved faction name.
        var short_names := ["NORTE","ESCARLATA","VERDE","SOLAR",
            "VIOLETA","ÁMBAR","TURQUESA","ÓNIX"]
        button.text = str(short_names[faction])
        button.tooltip_text = str(record["name"])
        button.icon = OfficialEmblems.emblem_texture(faction)
        button.expand_icon = true
        button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.custom_minimum_size = Vector2(143,52)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.toggle_mode = true
        button.pressed.connect(_select_faction_view.bind(faction))
        faction_view_grid.add_child(button)
        faction_view_buttons.append(button)
    # The entire gallery must remain visible for Units and Buildings;
    # it is deliberately NOT in _unit_only_controls / building_controls.
    var at: int = column.get_children().find(faction_picker)
    column.move_child(gallery_heading,at+1)
    column.move_child(faction_view_label,at+2)
    column.move_child(faction_view_grid,at+3)

func _select_faction_view(faction: int) -> void:
    if faction < 0 or faction >= VisualStyle.FACTIONS.size():
        return
    faction_picker.select(faction)
    # OptionButton.select() does not emit item_selected in Godot.
    _on_faction(faction)
    _refresh_building_faction(faction)

func _sync_faction_gallery(index: int) -> void:
    if faction_view_label == null:
        return
    if index < 0 or index >= VisualStyle.FACTIONS.size():
        return
    faction_view_label.text = "Mostrando: %s" % str(VisualStyle.FACTIONS[index]["name"])
    for i in range(faction_view_buttons.size()):
        var button: Button = faction_view_buttons[i]
        button.set_pressed_no_signal(i == index)
        button.modulate = Color.WHITE if i == index else Color(0.79,0.81,0.85,0.88)

func _add_naval_controls() -> void:
    naval_controls=VBoxContainer.new()
    naval_controls.name="OpcionesBaseNavalV1"
    naval_controls.add_theme_constant_override("separation",8)
    building_controls.add_child(naval_controls)
    _title(naval_controls,"BASE NAVAL V13 · INSPECCIÓN VISUAL 360°",14)
    _title(naval_controls,
        "Dársena en U, espigones, grúa, hangar marítimo, torre y servicios.",12)
    naval_detail_v2_toggle=CheckButton.new()
    naval_detail_v2_toggle.name="DetallesEsculpidosMuellesGruaYAguaNavalV2"
    naval_detail_v2_toggle.text="V2 · muelles, techo, grúa y olas (comparar V1)"
    naval_detail_v2_toggle.button_pressed=true
    naval_detail_v2_toggle.toggled.connect(_toggle_naval_detail_v2)
    naval_controls.add_child(naval_detail_v2_toggle)
    naval_detail_v3_toggle=CheckButton.new()
    naval_detail_v3_toggle.name="AtraqueRampasAstilleroNavalV3"
    naval_detail_v3_toggle.text="V3 · atraque, rampas y astillero (comparar V2)"
    naval_detail_v3_toggle.button_pressed=true
    naval_detail_v3_toggle.toggled.connect(_toggle_naval_detail_v3)
    naval_controls.add_child(naval_detail_v3_toggle)
    naval_detail_v4_toggle=CheckButton.new()
    naval_detail_v4_toggle.name="DesgasteMaritimoYCostaNavalV4"
    naval_detail_v4_toggle.text="V4 · corrosión, mareas y costa (comparar V3)"
    naval_detail_v4_toggle.button_pressed=true
    naval_detail_v4_toggle.toggled.connect(_toggle_naval_detail_v4)
    naval_controls.add_child(naval_detail_v4_toggle)
    naval_detail_v5_toggle=CheckButton.new()
    naval_detail_v5_toggle.name="EstructuraSenalesIluminacionNavalV5"
    naval_detail_v5_toggle.text="V5 · escala, números de muelle y luces (comparar V4)"
    naval_detail_v5_toggle.button_pressed=true
    naval_detail_v5_toggle.toggled.connect(_toggle_naval_detail_v5)
    naval_controls.add_child(naval_detail_v5_toggle)
    naval_detail_v6_toggle=CheckButton.new()
    naval_detail_v6_toggle.name="AcabadosNocheYZoomNavalV6"
    naval_detail_v6_toggle.text="V6 · señalización distante y acabados (comparar V5)"
    naval_detail_v6_toggle.button_pressed=true
    naval_detail_v6_toggle.toggled.connect(_toggle_naval_detail_v6)
    naval_controls.add_child(naval_detail_v6_toggle)
    naval_detail_v7_toggle=CheckButton.new()
    naval_detail_v7_toggle.name="AcabadosEmbarqueRealNavalV7"
    naval_detail_v7_toggle.text="V7 · uniones, escaleras y rampa (comparar V6)"
    naval_detail_v7_toggle.button_pressed=true
    naval_detail_v7_toggle.toggled.connect(_toggle_naval_detail_v7)
    naval_controls.add_child(naval_detail_v7_toggle)
    naval_detail_v8_toggle=CheckButton.new()
    naval_detail_v8_toggle.name="DefensasContactoAguaNavalV8"
    naval_detail_v8_toggle.text="V8 · defensas, espuma y drenajes (comparar V7)"
    naval_detail_v8_toggle.button_pressed=true
    naval_detail_v8_toggle.toggled.connect(_toggle_naval_detail_v8)
    naval_controls.add_child(naval_detail_v8_toggle)
    naval_detail_v9_toggle=CheckButton.new()
    naval_detail_v9_toggle.name="DefensasAcanaladasMaterialPBRV9"
    naval_detail_v9_toggle.text="V9 · defensas esculpidas y caucho PBR (comparar V8)"
    naval_detail_v9_toggle.button_pressed=true
    naval_detail_v9_toggle.toggled.connect(_toggle_naval_detail_v9)
    naval_controls.add_child(naval_detail_v9_toggle)
    naval_detail_v10_toggle=CheckButton.new()
    naval_detail_v10_toggle.name="AnclajesFenderYAmarresAlineadosV10"
    naval_detail_v10_toggle.text="V10 · anclajes, bolardos y soportes (comparar V9)"
    naval_detail_v10_toggle.button_pressed=true
    naval_detail_v10_toggle.toggled.connect(_toggle_naval_detail_v10)
    naval_controls.add_child(naval_detail_v10_toggle)
    naval_detail_v11_toggle=CheckButton.new()
    naval_detail_v11_toggle.name="ContactosSellosYCadenaNavalV11"
    naval_detail_v11_toggle.text="V11 · sellos, herrajes y eslabones (comparar V10)"
    naval_detail_v11_toggle.button_pressed=true
    naval_detail_v11_toggle.toggled.connect(_toggle_naval_detail_v11)
    naval_controls.add_child(naval_detail_v11_toggle)
    naval_detail_v12_toggle=CheckButton.new()
    naval_detail_v12_toggle.name="Revision360CadenasYContactosNavalesV12"
    naval_detail_v12_toggle.text="V12 · cadenas curvas y remates (comparar V11)"
    naval_detail_v12_toggle.button_pressed=true
    naval_detail_v12_toggle.toggled.connect(_toggle_naval_detail_v12)
    naval_controls.add_child(naval_detail_v12_toggle)
    naval_detail_v13_toggle=CheckButton.new()
    naval_detail_v13_toggle.name="MaterialesLegiblesYCamaraAmarresV13"
    naval_detail_v13_toggle.text="V13 · materiales y cadenas corregidos (comparar V12)"
    naval_detail_v13_toggle.button_pressed=true
    naval_detail_v13_toggle.toggled.connect(_toggle_naval_detail_v13)
    naval_controls.add_child(naval_detail_v13_toggle)
    naval_night_v6_toggle=CheckButton.new()
    naval_night_v6_toggle.name="VistaNocturnaBaseNavalV6"
    naval_night_v6_toggle.text="Vista nocturna · reflectores y balizas reales"
    naval_night_v6_toggle.button_pressed=false
    naval_night_v6_toggle.toggled.connect(_toggle_naval_night_v6)
    naval_controls.add_child(naval_night_v6_toggle)
    _title(naval_controls,"NIVEL ARQUITECTÓNICO",12)
    naval_level_picker=OptionButton.new()
    naval_level_picker.name="NivelBaseNavalV1"
    naval_level_picker.custom_minimum_size.y=48
    for label in ["Nivel 1 · muelle militar","Nivel 2 · abastecimiento naval",
            "Nivel 3 · astillero avanzado"]:
        naval_level_picker.add_item(label)
    naval_level_picker.item_selected.connect(_change_naval_setting)
    naval_controls.add_child(naval_level_picker)
    _title(naval_controls,"ESTADO DE DAÑO VISUAL",12)
    naval_damage_picker=OptionButton.new()
    naval_damage_picker.name="EstadoDañoBaseNavalV1"
    naval_damage_picker.custom_minimum_size.y=48
    for label in NavalBaseV1.DAMAGE_STAGES:
        naval_damage_picker.add_item(str(label))
    naval_damage_picker.item_selected.connect(_change_naval_setting)
    naval_controls.add_child(naval_damage_picker)
    _title(naval_controls,"CÁMARA DE INSPECCIÓN",12)
    naval_camera_picker=OptionButton.new()
    naval_camera_picker.name="CamaraBaseNavalV1"
    naval_camera_picker.custom_minimum_size.y=48
    for label in ["Puerto completo","Vista desde el mar",
            "Parte posterior","Vista superior","Detalle defensas y rampa",
            "Anclajes y bolardos","Unión caucho y hormigón",
            "Perfil bajo desde el mar"]:
        naval_camera_picker.add_item(label)
    naval_camera_picker.item_selected.connect(_change_naval_camera)
    naval_controls.add_child(naval_camera_picker)
    _button(naval_controls,"Restablecer vista naval",_reset_camera)
    _title(naval_controls,
        "Geometría original Godot 4.3 · arte provisional. No APK ni FPS Android.",12)
    naval_controls.visible=false

func _toggle_naval_detail_v2(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v3(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v4(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v5(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v6(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v7(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v8(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v9(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v10(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v11(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v12(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_detail_v13(_enabled: bool) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _toggle_naval_night_v6(_enabled: bool) -> void:
    if _role!="naval_base" or model_root==null:
        return
    var active: bool=model_root.has_node(NavalNightV6.STAGE_NAME)
    NavalNightV6.set_night(model_root,active and naval_night_v6_toggle.button_pressed)
    NavalBoardingV7.set_night(model_root,
        active and naval_night_v6_toggle.button_pressed)
    NavalFendersV8.set_night(model_root,
        active and naval_night_v6_toggle.button_pressed)
    NavalMooringV10.set_night(model_root,
        active and naval_night_v6_toggle.button_pressed)
    NavalContactV11.set_night(model_root,
        active and naval_night_v6_toggle.button_pressed)
    NavalFinalV12.set_night(model_root,
        active and naval_night_v6_toggle.button_pressed)
    _apply_hq_lighting(2 if active and naval_night_v6_toggle.button_pressed else _naval_saved_light_preset)

func _change_naval_setting(_index: int) -> void:
    if _role=="naval_base":
        _display_naval_base()

func _change_naval_camera(index: int) -> void:
    _naval_camera_view=clampi(index,0,7)
    if _role=="naval_base":
        _apply_naval_camera()

func _apply_naval_camera() -> void:
    if _role!="naval_base" or camera==null:
        return
    # Global cameras remain unchanged for the overview/sea/back/top.
    # Dedicated inspection cameras use MODEL-LOCAL anchors, then rotate
    # with the chosen model yaw so the bollards do not drift out of frame.
    if _naval_camera_view<=3:
        var global_spots: Array[Vector3]=[
            Vector3(-19.0,17.5,-18.0),Vector3(-23.0,11.5,0.5),
            Vector3(19.0,13.5,16.0),Vector3(-0.01,31.0,9.0)]
        camera.position=global_spots[_naval_camera_view]
        camera.look_at(Vector3(0,1.65,0),Vector3.UP)
    else:
        var local_target: Vector3=Vector3(1.06,0.40,1.36)
        var local_offset: Vector3=Vector3(-3.8,2.2,2.3)
        match _naval_camera_view:
            5:
                local_target=Vector3(-3.27,0.40,-4.22)
                local_offset=Vector3(-2.45,1.65,3.70)
            6:
                local_target=Vector3(1.06,0.34,-2.72)
                local_offset=Vector3(-3.25,1.85,0.15)
            7:
                local_target=Vector3(-3.27,0.28,-4.19)
                local_offset=Vector3(-2.75,0.90,3.65)
        var yaw: float=deg_to_rad(_yaw)
        var model_basis:=Basis(Vector3.UP,yaw)
        var target_world: Vector3=model_basis*local_target
        camera.position=model_basis*(local_target+local_offset)
        camera.look_at(target_world,Vector3.UP)
    _update_camera()

func _display_naval_base() -> void:
    if preview==null:
        return
    var first: bool=_role!="naval_base"
    if first:
        _naval_saved_light_preset=_hq_light_preset
    _stop_animation()
    if model_root!=null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role="naval_base"
    model_root=NavalBaseV1.build(
        naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
    if model_root==null:
        push_error("Base Naval V1: no fue posible crear el modelo 3D")
        return
    if naval_detail_v2_toggle.button_pressed:
        var ok: bool=NavalDetailV2.apply(model_root,
            naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
        if not ok:
            push_error("Base Naval V2: no se pudo añadir la geometría de muelles y astillero")
        elif naval_detail_v3_toggle.button_pressed:
            var ok_v3: bool=NavalBerthsV3.apply(model_root,
                naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
            if not ok_v3:
                push_error("Base Naval V3: no se pudo añadir atraque, rampas y astillero")
            elif naval_detail_v4_toggle.button_pressed:
                var ok_v4: bool=NavalMarineV4.apply(model_root,
                    naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                if not ok_v4:
                    push_error("Base Naval V4: no se pudieron aplicar acabados marítimos")
                elif naval_detail_v5_toggle.button_pressed:
                    var ok_v5: bool=NavalYardV5.apply(model_root,
                        naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                    if not ok_v5:
                        push_error("Base Naval V5: no se pudo completar señalización ni astillero")
                    elif naval_detail_v6_toggle.button_pressed:
                        var ok_v6: bool=NavalNightV6.apply(model_root,
                            naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                        if not ok_v6:
                            push_error("Base Naval V6: fallaron los acabados de noche y zoom")
                        else:
                            NavalNightV6.set_night(model_root,naval_night_v6_toggle.button_pressed)
                            if naval_detail_v7_toggle.button_pressed:
                                var ok_v7: bool=NavalBoardingV7.apply(model_root,
                                    naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                if not ok_v7:
                                    push_error("Base Naval V7: no se añadieron las uniones de embarque")
                                else:
                                    NavalBoardingV7.set_night(model_root,
                                        naval_night_v6_toggle.button_pressed)
                                    if naval_detail_v8_toggle.button_pressed:
                                        var ok_v8: bool=NavalFendersV8.apply(model_root,
                                            naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                        if not ok_v8:
                                            push_error("Base Naval V8: fallaron defensas y contacto costero")
                                        else:
                                            NavalFendersV8.set_night(model_root,
                                                naval_night_v6_toggle.button_pressed)
                                            if naval_detail_v9_toggle.button_pressed:
                                                var ok_v9: bool=NavalSculptV9.apply(model_root,
                                                    naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                                if not ok_v9:
                                                    push_error("Base Naval V9: fallaron las defensas 3D de caucho PBR")
                                                elif naval_detail_v10_toggle.button_pressed:
                                                    var ok_v10: bool=NavalMooringV10.apply(model_root,
                                                        naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                                    if not ok_v10:
                                                        push_error("Base Naval V10: anclajes no alineados con bolardos")
                                                    else:
                                                        NavalMooringV10.set_night(model_root,
                                                            naval_night_v6_toggle.button_pressed)
                                                        if naval_detail_v11_toggle.button_pressed:
                                                            var ok_v11: bool=NavalContactV11.apply(model_root,
                                                                naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                                            if not ok_v11:
                                                                push_error("Base Naval V11: fallaron sellos de contacto y cadenas")
                                                            else:
                                                                NavalContactV11.set_night(model_root,
                                                                    naval_night_v6_toggle.button_pressed)
                                                                if naval_detail_v12_toggle.button_pressed:
                                                                    var ok_v12: bool=NavalFinalV12.apply(model_root,
                                                                        naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                                                    if not ok_v12:
                                                                        push_error("Base Naval V12: no se aplicaron los ajustes de contacto")
                                                                    else:
                                                                        NavalFinalV12.set_night(model_root,
                                                                            naval_night_v6_toggle.button_pressed)
                                                                        if naval_detail_v13_toggle.button_pressed:
                                                                            var ok_v13: bool=NavalAuditV13.apply(model_root,
                                                                                naval_level_picker.selected+1,_faction,naval_damage_picker.selected)
                                                                            if not ok_v13:
                                                                                push_error("Base Naval V13: no se corrigió la geometría visible de cadenas")
    preview.add_child(model_root)
    if hq_climate_stage!=null:
        hq_climate_stage.visible=false
    if hq_map_lod_toggle!=null:
        hq_map_lod_toggle.visible=false
    faction_picker.visible=true
    if first:
        _yaw=26.0
        _zoom=1.0
        _naval_camera_view=0
        naval_camera_picker.select(0)
    model_root.rotation_degrees.y=_yaw
    _apply_naval_camera()
    var show_night: bool=model_root.has_node(NavalNightV6.STAGE_NAME) and naval_night_v6_toggle.button_pressed
    _apply_hq_lighting(2 if show_night else _naval_saved_light_preset)
    _update_details()

func _add_supply_controls() -> void:
    supply_controls=VBoxContainer.new()
    supply_controls.name="OpcionesCentroSuministrosV1"
    supply_controls.add_theme_constant_override("separation",8)
    building_controls.add_child(supply_controls)
    _title(supply_controls,"CENTRO DE SUMINISTROS V1 · LOGÍSTICA",14)
    _title(supply_controls,"NIVEL ARQUITECTÓNICO",12)
    supply_level_picker=OptionButton.new()
    supply_level_picker.name="NivelCentroSuministrosV1"
    supply_level_picker.custom_minimum_size.y=49
    for name in ["Nivel 1 · almacén, combustible y municiones",
            "Nivel 2 · control logístico y carga",
            "Nivel 3 · puente de distribución y extractores"]:
        supply_level_picker.add_item(name)
    supply_level_picker.select(0)
    supply_level_picker.item_selected.connect(_change_supply_setting)
    supply_controls.add_child(supply_level_picker)
    _title(supply_controls,"DAÑO VISUAL · NO ALTERA SALUD O PRODUCCIÓN",12)
    supply_damage_picker=OptionButton.new()
    supply_damage_picker.name="DanoCentroSuministrosV1"
    supply_damage_picker.custom_minimum_size.y=49
    for name in SupplyCenterV1.DAMAGE_STAGES:
        supply_damage_picker.add_item(str(name))
    supply_damage_picker.select(0)
    supply_damage_picker.item_selected.connect(_change_supply_setting)
    supply_controls.add_child(supply_damage_picker)
    _title(supply_controls,"CÁMARAS DE INSPECCIÓN",12)
    supply_camera_picker=OptionButton.new()
    supply_camera_picker.name="CamaraCentroSuministrosV1"
    supply_camera_picker.custom_minimum_size.y=49
    for name in ["Complejo logístico completo","Andenes para camiones",
            "Tanques y búnker de municiones","Cubiertas y distribución"]:
        supply_camera_picker.add_item(name)
    supply_camera_picker.select(0)
    supply_camera_picker.item_selected.connect(_change_supply_camera)
    supply_controls.add_child(supply_camera_picker)
    _title(supply_controls,
        "Arquitectura 3D Godot 4.3 · no altera la logística jugable ni el balance.",11)
    supply_controls.visible=false

func _change_supply_setting(_index: int) -> void:
    if _role=="supply_center":
        _display_supply_center()

func _change_supply_camera(index: int) -> void:
    _supply_camera_view=clampi(index,0,3)
    if _role=="supply_center":
        _apply_supply_camera()

func _apply_supply_camera() -> void:
    if _role!="supply_center" or camera==null:
        return
    var targets: Array[Vector3]=[
        Vector3(0,1.70,0.30),Vector3(0,1.43,-2.25),
        Vector3(0,1.55,0.54),Vector3(0,1.25,0)]
    var offsets: Array[Vector3]=[
        Vector3(-12.5,9.2,-14.5),Vector3(-6.8,4.5,-9.4),
        Vector3(13.1,8.8,11.5),Vector3(-0.01,23.2,-0.01)]
    var rotate:=Basis(Vector3.UP,deg_to_rad(_yaw))
    var look: Vector3=rotate*targets[_supply_camera_view]
    camera.position=rotate*(targets[_supply_camera_view]+offsets[_supply_camera_view])
    camera.look_at(look,Vector3.UP)
    _update_camera()

func _display_supply_center() -> void:
    if preview==null:
        return
    var initial: bool=_role!="supply_center"
    _stop_animation()
    if model_root!=null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role="supply_center"
    var level: int=supply_level_picker.selected+1
    var damage: int=supply_damage_picker.selected
    model_root=SupplyCenterV1.build(level,_faction,damage)
    if model_root==null:
        push_error("Centro de Suministros V1: combinación de nivel, facción o daño inválida")
        return
    preview.add_child(model_root)
    if hq_climate_stage!=null:
        hq_climate_stage.visible=false
    if hq_map_lod_toggle!=null:
        hq_map_lod_toggle.visible=false
    faction_picker.visible=true
    if initial:
        _yaw=28.0
        _zoom=1.0
        _supply_camera_view=0
        supply_camera_picker.select(0)
    model_root.rotation_degrees.y=_yaw
    _apply_supply_camera()
    _apply_hq_lighting(0)
    _update_details()

func _change_selected_building(index: int) -> void:
    if index < 0 or index >= building_picker.item_count:
        return
    if _role=="naval_base" and index!=2:
        _apply_hq_lighting(_naval_saved_light_preset)
    building_picker.select(index)
    for control in _hq_specific_controls:
        control.visible = index == 0
    airbase_controls.visible = index == 1
    if naval_controls!=null:
        naval_controls.visible=index==2
    if supply_controls!=null:
        supply_controls.visible=index==3
    match index:
        0: _display_headquarters()
        1: _display_airbase()
        2: _display_naval_base()
        3: _display_supply_center()

func _airbase_gate_rig() -> TarvokaAirbaseDoorRigV2:
    if _role != "airbase" or model_root == null:
        return null
    return model_root.get_node_or_null(
        AirbaseDoorsV2.STAGE_NAME) as TarvokaAirbaseDoorRigV2

func _play_airbase_doors(opened: bool) -> void:
    var gate: TarvokaAirbaseDoorRigV2 = _airbase_gate_rig()
    if gate == null or not gate.is_operational():
        _refresh_airbase_door_ui()
        return
    if opened:
        gate.play_open()
    else:
        gate.play_close()
    _refresh_airbase_door_ui()

func _scrub_airbase_doors(value: float) -> void:
    var gate: TarvokaAirbaseDoorRigV2 = _airbase_gate_rig()
    if gate == null or not gate.is_operational():
        return
    gate.set_open_fraction(value)
    _airbase_saved_gate_fraction = gate.open_fraction()
    _refresh_airbase_door_ui()

func _refresh_airbase_door_ui() -> void:
    if airbase_open_button == null:
        return
    var gate: TarvokaAirbaseDoorRigV2 = _airbase_gate_rig()
    var ready: bool = gate != null and gate.is_operational()
    airbase_open_button.disabled = not ready
    airbase_close_button.disabled = not ready
    airbase_gate_slider.editable = ready
    if not ready:
        airbase_gate_status.text = (
            "Portones inutilizados por daño estructural; no se anima la compuerta."
            if _role == "airbase" else "Portones disponibles en Base Aérea")
        return
    var fraction: float = gate.open_fraction()
    _airbase_saved_gate_fraction = fraction
    airbase_gate_slider.set_value_no_signal(fraction)
    airbase_gate_status.text = "Portones %s · apertura: %d%% · 20 mallas sincronizadas" % [
        "en movimiento" if gate.is_moving() else "abiertos" if fraction>0.995
        else "cerrados" if fraction<0.005 else "parciales",
        int(round(fraction*100.0))]

func _toggle_airbase_camera() -> void:
    if _role != "airbase" or _airbase_is_stress():
        return
    # Keep legacy button fully functional with the new eight-angle selector.
    _change_airbase_v9_view(0 if _airbase_camera_interior else 6)
    if airbase_v9_view_picker!=null:
        airbase_v9_view_picker.select(_airbase_v9_view)

func _apply_airbase_camera() -> void:
    if camera == null or _role != "airbase":
        return
    # Optional orthographic close-up; focus the transformed physical
    # impact anchor so it keeps working after rotating the model.
    if model_root!=null and not _airbase_is_stress() and \
            airbase_v13_focus_toggle!=null and \
            airbase_v13_focus_toggle.button_pressed and \
            airbase_impacts_v13_toggle.button_pressed:
        var surface: String=AirbaseImpactsV13.TARGETS[
            airbase_surface_v13_picker.selected]
        var point: Vector3=model_root.transform*AirbaseImpactsV13.surface_position(
            surface)
        camera.position=point+(
            Vector3(-3.1,6.1,-4.3) if surface=="hangar_roof" else
            Vector3(3.8,2.8,-5.8))
        camera.look_at(point,Vector3.UP)
        _update_camera()
        return
    var target:=Vector3(0,2.25,0)
    if airbase_detail_v9_toggle!=null and airbase_detail_v9_toggle.button_pressed:
        match _airbase_v9_view:
            1:
                camera.position=Vector3(-21,9,1)
            2:
                camera.position=Vector3(0,12,22)
            3:
                camera.position=Vector3(21,9,1)
            4:
                camera.position=Vector3(-7,27,7)
            5:
                # The model itself rotates in the studio. Focus the REAL
                # transformed tower position, not the unrotated V1 anchor.
                var tier_offset: float=float(airbase_level_picker.selected)*0.62
                var local_tower:=Vector3(4.17,4.12+tier_offset,-2.17)
                target=model_root.transform*local_tower
                camera.position=target+Vector3(4.7,2.2,-5.9)
            6:
                camera.position=Vector3(-8.6,5,-13.1)
                target=Vector3(-1.95,1.33,0.04)
            7:
                camera.position=Vector3(-1.95,5.0,-17)
            _:
                camera.position=Vector3(-17.5,16.0,-19.0)
    elif _airbase_camera_interior:
        camera.position=Vector3(-8.6,5,-13.1)
        target=Vector3(-1.95,1.33,0.04)
    else:
        camera.position=Vector3(-17.5,16.0,-19.0)
    camera.look_at(target,Vector3.UP)
    if airbase_camera_button != null:
        airbase_camera_button.text = (
            "Volver a vista exterior" if _airbase_camera_interior
            else "Inspeccionar interior del hangar")
    _update_camera()

func _airbase_impact_rig() -> TarvokaAirbaseImpactV3:
    if _role != "airbase" or model_root == null:
        return null
    return model_root.get_node_or_null(
        AirbaseImpactV3.AIRBASE_NAME) as TarvokaAirbaseImpactV3

func _play_airbase_impact(kind: String) -> void:
    if _role!="airbase" or model_root==null or _airbase_is_stress():
        return
    if airbase_impacts_v13_toggle!=null and airbase_impacts_v13_toggle.button_pressed and \
            kind in AirbaseImpactsV13.KINDS:
        var v13: TarvokaAirbaseImpactsV13=model_root.get_node_or_null(
            AirbaseImpactsV13.STAGE_NAME) as TarvokaAirbaseImpactsV13
        var target: String=AirbaseImpactsV13.TARGETS[
            airbase_surface_v13_picker.selected]
        if v13!=null and v13.trigger(kind,target):
            var scars: TarvokaAirbaseScarsV14=model_root.get_node_or_null(
                AirbaseScarsV14.STAGE_NAME) as TarvokaAirbaseScarsV14
            if scars!=null and scars.add_mark(kind,target):
                _airbase_v14_history.append({"attack":kind,"surface":target})
                if _airbase_v14_history.size()>12:
                    _airbase_v14_history.pop_front()
                _refresh_airbase_v14_status()
            var names: Dictionary={"bullet":"Bala","missile":"Misil",
                "bombardment":"Bombardeo"}
            airbase_impact_status.text=(
                "V13 · %s sobre %s · efectos 3D sin cambios de HP." %
                [names[kind],airbase_surface_v13_picker.get_item_text(
                    airbase_surface_v13_picker.selected)])
        return
    if kind in ["missile","bombardment"]:
        return
    var rig: TarvokaAirbaseImpactV3 = _airbase_impact_rig()
    if rig == null:
        return
    if rig.trigger_airbase(kind):
        if kind=="explosive" and airbase_fracture_v12_toggle!=null and \
                airbase_fracture_v12_toggle.button_pressed:
            AirbaseFractureV12.trigger_explosion(model_root)
        airbase_impact_status.text = (
            "Disparo: chispas y desconchones 3D de la puerta · simulación visual."
            if kind=="bullet" else
            "Explosión: fogonazo, onda de choque, escombros y humo 3D."
            )

func _toggle_airbase_impacts_v13(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_scars_v14(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_finish_v15(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _clear_airbase_v14_marks() -> void:
    _airbase_v14_history.clear()
    if model_root!=null:
        var scars: TarvokaAirbaseScarsV14=model_root.get_node_or_null(
            AirbaseScarsV14.STAGE_NAME) as TarvokaAirbaseScarsV14
        if scars!=null:
            scars.clear_marks()
    _refresh_airbase_v14_status()

func _refresh_airbase_v14_status() -> void:
    if airbase_v14_status==null:
        return
    var scars: TarvokaAirbaseScarsV14=null
    if _role=="airbase" and model_root!=null:
        scars=model_root.get_node_or_null(
            AirbaseScarsV14.STAGE_NAME) as TarvokaAirbaseScarsV14
    var visible_count: int=0
    if scars!=null:
        for surface in AirbaseScarsV14.SURFACES:
            visible_count+=scars.visible_marks(surface)
    airbase_v14_status.text=(
        "V14 · %d impactos en historial · %d huellas visibles (máx. 9)" %
        [_airbase_v14_history.size(),visible_count])

func _toggle_airbase_v13_focus(_enabled: bool) -> void:
    if _role=="airbase" and not _airbase_is_stress():
        _apply_airbase_camera()

func _change_airbase_v13_target(_index: int) -> void:
    if _role=="airbase" and not _airbase_is_stress() and \
            airbase_v13_focus_toggle.button_pressed:
        _apply_airbase_camera()

func _set_airbase_mobile_vfx(enabled: bool) -> void:
    if _role != "airbase" or model_root == null:
        return
    var smoke: TarvokaAirbaseDamageFXV3 = model_root.get_node_or_null(
        AirbaseDamageV3.STAGE_NAME) as TarvokaAirbaseDamageFXV3
    if smoke != null:
        smoke.set_mobile_quality(enabled)
    _refresh_airbase_damage_ui()

func _refresh_airbase_damage_ui() -> void:
    if airbase_impact_bullet_button == null:
        return
    var active: bool = _role=="airbase" and model_root!=null and \
        int(model_root.get_meta("visual_damage_stage",4))<4
    airbase_impact_bullet_button.disabled = not active
    airbase_impact_explosive_button.disabled = not active
    if airbase_missile_v13_button!=null:
        airbase_missile_v13_button.disabled=not active or not \
            airbase_impacts_v13_toggle.button_pressed
    if airbase_bombard_v13_button!=null:
        airbase_bombard_v13_button.disabled=not active or not \
            airbase_impacts_v13_toggle.button_pressed
    if not active:
        airbase_impact_status.text = (
            "Escenario de carga · FX de unidades lejanas desactivados."
            if _airbase_is_stress() else
            "Base completamente destruida; no hay objetivos intactos de impacto."
            if _role=="airbase" else "Impactos disponibles en Base Aérea")
        return
    var smoke: TarvokaAirbaseDamageFXV3 = model_root.get_node_or_null(
        AirbaseDamageV3.STAGE_NAME) as TarvokaAirbaseDamageFXV3
    var smoke_count: int = smoke.smoke_instance_count() if smoke!=null else 0
    var fire_batches: int = smoke.flame_batch_count() if smoke!=null else 0
    airbase_impact_status.text = (
        "V3 · %d volutas / %d lote de llamas · impactos de prueba sin HP" %
        [smoke_count,fire_batches])

func _airbase_is_stress() -> bool:
    return _role=="airbase" and model_root!=null and \
        model_root.get_meta("tarvoka_building_kind","")=="airbase_stress"

func _toggle_airbase_stress(enabled: bool) -> void:
    if airbase_stress_picker!=null:
        airbase_stress_picker.visible = enabled
    if airbase_stress_status!=null:
        airbase_stress_status.visible = enabled
    if _role=="airbase":
        _display_airbase()

func _change_airbase_stress_count(_index: int) -> void:
    if _role=="airbase" and airbase_stress_toggle.button_pressed:
        _display_airbase()

func _display_airbase_stress(first: bool) -> void:
    var count: int = [8,32,64][airbase_stress_picker.selected]
    model_root = AirbaseStressV4.build_grid(
        count,AirbaseStressV4.MAX_NEAR,airbase_exterior_v6_toggle.button_pressed,
        airbase_material_v7_toggle.button_pressed,
        airbase_finish_v8_toggle.button_pressed,
        airbase_detail_v9_toggle.button_pressed,
        airbase_structure_v10_toggle.button_pressed,
        airbase_trusses_v11_toggle.button_pressed and airbase_structure_v10_toggle.button_pressed,
        airbase_fracture_v12_toggle.button_pressed and airbase_trusses_v11_toggle.button_pressed and \
            airbase_structure_v10_toggle.button_pressed)
    if model_root==null:
        push_error("Base Aerea V4: no se pudo crear escenario LOD")
        return
    preview.add_child(model_root)
    if hq_climate_stage!=null:
        hq_climate_stage.visible=false
    hq_map_lod_toggle.visible=false
    faction_picker.visible=true
    airbase_camera_button.disabled=true
    if first:
        _yaw=32.0
        _zoom=1.0
    _airbase_camera_interior=false
    model_root.rotation_degrees.y=_yaw
    camera.position=Vector3(-95.0,108.0,-101.0) * \
        float(int(model_root.get_meta("tarvoka_stress_grid_cols",4)))/8.0
    camera.look_at(Vector3(0,1.5,0),Vector3.UP)
    _update_camera()
    _refresh_airbase_door_ui()
    _refresh_airbase_damage_ui()
    _airbase_stress_seconds=0.0
    _update_details()

func _toggle_airbase_exterior_v6(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_material_v7(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_finish_v8(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_detail_v9(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_structure_v10(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _toggle_airbase_trusses_v11(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _is_airbase_v11_roof_shell(node: Node) -> bool:
    var label: String=str(node.name)
    return label.begins_with("CubiertaCurva3D_") or label.begins_with(
        "NervaduraCubierta_") or label.begins_with(
        "ExtractorCubierta_") or label.begins_with(
        "RejillaExtractor_") or label.begins_with(
        "PanelFotovoltaico_") or label=="CostillasCubiertaCurvaV6" or \
        label=="RematePerimetralCurvoV9"

func _walk_airbase_v11_cutaway(node: Node, enabled: bool) -> void:
    if node is Node3D and _is_airbase_v11_roof_shell(node):
        var body: Node3D=node as Node3D
        if enabled:
            if not body.has_meta("tarvoka_v11_cutaway_was_visible"):
                body.set_meta("tarvoka_v11_cutaway_was_visible",body.visible)
            body.visible=false
        elif body.has_meta("tarvoka_v11_cutaway_was_visible"):
            body.visible=bool(body.get_meta("tarvoka_v11_cutaway_was_visible"))
            body.remove_meta("tarvoka_v11_cutaway_was_visible")
    for child in node.get_children():
        _walk_airbase_v11_cutaway(child,enabled)

func _apply_airbase_v11_cutaway() -> void:
    if _role!="airbase" or _airbase_is_stress() or model_root==null:
        return
    var visible_cutaway: bool=airbase_v11_cutaway_toggle!=null and \
        airbase_v11_cutaway_toggle.button_pressed
    _walk_airbase_v11_cutaway(model_root,visible_cutaway)
    model_root.set_meta("tarvoka_airbase_v11_cutaway",visible_cutaway)

func _toggle_airbase_cutaway_v11(_enabled: bool) -> void:
    _apply_airbase_v11_cutaway()

func _toggle_airbase_fracture_v12(_enabled: bool) -> void:
    if _role=="airbase":
        _display_airbase()

func _change_airbase_v9_view(index: int) -> void:
    if _role != "airbase" or _airbase_is_stress():
        return
    _airbase_v9_view=clampi(index,0,7)
    _airbase_camera_interior=_airbase_v9_view==6
    if _airbase_camera_interior:
        var rig: TarvokaAirbaseDoorRigV2 = _airbase_gate_rig()
        if rig!=null and rig.is_operational():
            rig.set_open_fraction(1.0)
            _airbase_saved_gate_fraction=1.0
            _refresh_airbase_door_ui()
    _apply_airbase_camera()

func _change_airbase_level(_index: int) -> void:
    if _role == "airbase":
        _airbase_v14_history.clear()
        _display_airbase()

func _change_airbase_damage(_index: int) -> void:
    if _role == "airbase":
        _display_airbase()

func _change_airbase_weather(_index: int) -> void:
    if _role == "airbase":
        _display_airbase()

func _display_airbase() -> void:
    if preview == null:
        return
    var first: bool = _role != "airbase"
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "airbase"
    var tier: int = airbase_level_picker.selected+1
    var stage: int = airbase_damage_picker.selected
    if airbase_stress_toggle != null and airbase_stress_toggle.button_pressed:
        _display_airbase_stress(first)
        return
    airbase_camera_button.disabled=false
    model_root = AirbaseV1.build(tier,_faction,stage)
    if model_root == null:
        push_error("Base Aerea V1: especificacion no valida")
        return
    var hangar_added: bool = AirbaseHangarV2.apply(model_root,tier,_faction,stage)
    if not hangar_added:
        push_error("Base Aerea V2: fallo al instalar arquitectura")
    if airbase_exterior_v6_toggle.button_pressed:
        if not AirbaseExteriorV6.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V6: acabado arquitectonico no instalado")
    if airbase_material_v7_toggle.button_pressed:
        if not AirbaseMaterialsV7.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V7: materiales y desgaste no instalados")
    if airbase_finish_v8_toggle.button_pressed:
        if not AirbaseFinishV8.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V8: cristales y luz no instalados")
    if airbase_detail_v9_toggle.button_pressed:
        if not AirbaseDetailV9.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V9: cristal panoramico y cubierta no instalados")
    if airbase_structure_v10_toggle.button_pressed:
        if not AirbaseStructureV10.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V10: cerchas y fachada posterior no instaladas")
    if airbase_trusses_v11_toggle.button_pressed and airbase_structure_v10_toggle.button_pressed:
        if not AirbaseTrussesV11.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V11: arriostramiento y roturas no instalados")
    if airbase_fracture_v12_toggle.button_pressed and airbase_trusses_v11_toggle.button_pressed and \
            airbase_structure_v10_toggle.button_pressed:
        if not AirbaseFractureV12.apply(model_root,tier,_faction,stage):
            push_error("Base Aerea V12: fracturas y metal quemado no instalados")
    if stage <= 1:
        model_root.add_child(AirbaseDoorsV2.build(stage))
    if stage in [2,3]:
        var ambience: TarvokaAirbaseDamageFXV4 = AirbaseDamageV4.build(stage)
        model_root.add_child(ambience)
    if stage < 4:
        var impacts := TarvokaAirbaseImpactV3.new()
        impacts.name = AirbaseImpactV3.AIRBASE_NAME
        model_root.add_child(impacts)
        if airbase_impacts_v13_toggle.button_pressed:
            var surface_rig := TarvokaAirbaseImpactsV13.new()
            surface_rig.name=AirbaseImpactsV13.STAGE_NAME
            surface_rig.damage_stage=stage
            model_root.add_child(surface_rig)
            if airbase_scars_v14_toggle.button_pressed:
                var surface_marks:=TarvokaAirbaseScarsV14.new()
                surface_marks.name=AirbaseScarsV14.STAGE_NAME
                surface_marks.damage_stage=stage
                model_root.add_child(surface_marks)
    preview.add_child(model_root)
    var persistent_marks: TarvokaAirbaseScarsV14=model_root.get_node_or_null(
        AirbaseScarsV14.STAGE_NAME) as TarvokaAirbaseScarsV14
    if persistent_marks!=null:
        if airbase_finish_v15_toggle.button_pressed:
            var organic_finish:=TarvokaAirbaseScarFinishV15.new()
            organic_finish.name=AirbaseScarFinishV15.STAGE_NAME
            model_root.add_child(organic_finish)
            if not organic_finish.bind_to_scars(persistent_marks):
                push_error("Base Aerea V15: acentos organicos no enlazados")
        persistent_marks.restore(_airbase_v14_history)
    if stage in [2,3]:
        var smoke: TarvokaAirbaseDamageFXV3 = model_root.get_node_or_null(
            AirbaseDamageV3.STAGE_NAME) as TarvokaAirbaseDamageFXV3
        if smoke != null:
            smoke.set_mobile_quality(airbase_mobile_fx_toggle.button_pressed)
    var rig: TarvokaAirbaseDoorRigV2 = _airbase_gate_rig()
    if rig != null and rig.is_operational():
        rig.set_open_fraction(_airbase_saved_gate_fraction)
    var weather: String = ["clear","rain","snow"][airbase_weather_picker.selected]
    var coating: Dictionary = UniversalClimate.apply(model_root,weather)
    if not bool(coating.get("valid",false)):
        push_error("Base Aerea V1: clima no aplicado")
    _apply_airbase_v11_cutaway()
    # Reuse V17 environmental precipitation, but not its old HQ snow caps.
    var climate_ready: bool = HQClimateV17.apply(hq_climate_stage,
        weather,"asphalt",tier,"operativo",false)
    if not climate_ready:
        push_error("Base Aerea V1: precipitacion ambiental no disponible")
    hq_climate_stage.visible = true
    for i in range(3):
        var old_cap: Node3D = hq_climate_stage.get_node_or_null(
            "NieveAcumuladaCubiertaV17_%d" % i) as Node3D
        if old_cap != null:
            old_cap.visible = false
    hq_map_lod_toggle.visible = false
    faction_picker.visible = true
    if first:
        _yaw = 32.0
        _zoom = 1.0
        _airbase_camera_interior = false
        _airbase_v9_view = 0
        if airbase_v9_view_picker!=null:
            airbase_v9_view_picker.select(0)
    model_root.rotation_degrees.y = _yaw
    _apply_airbase_camera()
    _apply_hq_lighting(_hq_light_preset)
    _refresh_airbase_door_ui()
    _refresh_airbase_damage_ui()
    _refresh_airbase_v14_status()
    _update_details()

func _change_hq_version(index: int) -> void:
    if index < 0 or index > 3:
        return
    _hq_show_v2 = index <= 2
    _hq_show_v3 = index <= 1
    _hq_show_v4 = index == 0
    if index != 0 and hq_batch_toggle != null:
        hq_batch_toggle.set_pressed_no_signal(false)
    hq_version_picker.select(index)
    if _role == "headquarters":
        _display_headquarters()

func _toggle_hq_detail() -> void:
    _hq_show_v2 = true
    _hq_show_v4 = false
    _hq_show_v3 = not _hq_show_v3
    if hq_version_picker != null:
        hq_version_picker.select(1 if _hq_show_v3 else 2)
    hq_v3_compare_button.text = (
        "Volver al diseño V3 mejorado" if not _hq_show_v3
        else "Comparar arquitectura V2 / V3")
    hq_compare_button.text = "Comparar con diseño anterior (V1)"
    if _role == "headquarters":
        _display_headquarters()

func _toggle_hq_finish() -> void:
    _hq_show_v2 = not _hq_show_v2
    _hq_show_v3 = false
    _hq_show_v4 = false
    if hq_version_picker != null:
        hq_version_picker.select(2 if _hq_show_v2 else 3)
    hq_compare_button.text = (
        "Volver al diseño arquitectónico V2" if not _hq_show_v2
        else "Comparar con diseño anterior (V1)")
    if _role == "headquarters":
        _display_headquarters()

func _switch_category(index: int) -> void:
    if index < 0 or index > 1:
        return
    var building: bool = index == 1
    building_controls.visible = building
    if hq_ground != null:
        hq_ground.visible = building
    if hq_climate_stage != null:
        hq_climate_stage.visible = building and not hq_batch_toggle.button_pressed
    if hq_key_light != null:
        hq_key_light.shadow_enabled = building
    _apply_hq_lighting(_hq_light_preset)
    for widget in _unit_only_controls:
        widget.visible = not building
    if building:
        faction_picker.visible = true
        match building_picker.selected:
            0: _display_headquarters()
            1: _display_airbase()
            2: _display_naval_base()
            3: _display_supply_center()
    else:
        camera.position = Vector3(5.3,4.2,6.3)
        camera.look_at(Vector3(0,0.35,0),Vector3.UP)
        super._display_role("tank")
    category_picker.select(index)
    _apply_hq_lighting(_hq_light_preset)

func _change_building_variant(_index: int) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _change_hq_installation_state(index: int) -> void:
    if index < 0 or index >= BUILDING_STATES.size():
        return
    # Keep the historical 4-state selector compatible with V17 tests.
    # The full 5-stage damage readout is a separate, explicit 3D choice.
    var stage: int = 2 if index == 2 else 4 if index == 3 else 0
    hq_damage_stage_picker.select(stage)
    if _role == "headquarters":
        _display_headquarters()

func _change_hq_damage_stage(index: int) -> void:
    if index < 0 or index >= HQDamageV21.STAGES.size():
        return
    hq_damage_stage_picker.select(index)
    if index == 4:
        building_state_picker.select(3)
    elif index > 0:
        building_state_picker.select(2)
    elif building_state_picker.selected >= 2:
        building_state_picker.select(0)
    if _role == "headquarters":
        _display_headquarters()

func _play_hq_bullet_v21() -> void:
    _play_hq_impact_v21(HQImpactV21.BULLET)

func _play_hq_explosion_v21() -> void:
    _play_hq_impact_v21(HQImpactV21.EXPLOSIVE)

func _play_hq_impact_v21(kind: String) -> void:
    if model_root == null or _role != "headquarters":
        return
    var fx: TarvokaHeadquartersImpactV21 = model_root.get_node_or_null(
        HQImpactV21.STAGE_NAME) as TarvokaHeadquartersImpactV21
    if fx == null or not fx.visible:
        return
    var started: bool = fx.trigger(kind)
    if started and hq_impact_status != null:
        hq_impact_status.text = (
            "Balas: chispas y metralla fina · 0,62 s" if kind == HQImpactV21.BULLET
            else "Explosivo: onda de choque, mampostería y humo · 1,75 s")
    # Attack VFX are visual only: no HP or structural damage is applied
    # unless the user explicitly chooses a new damage stage.

func _change_hq_sculpt(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4:
        _display_headquarters()

func _change_hq_materials_v8(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v7_toggle.button_pressed:
        _display_headquarters()

func _change_hq_readability_v9(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v7_toggle.button_pressed and hq_v8_toggle.button_pressed:
        _display_headquarters()

func _change_hq_surfaces_v10(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v9_toggle.button_pressed:
        _display_headquarters()

func _change_hq_refinement_v11(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v10_toggle.button_pressed:
        _display_headquarters()

func _change_hq_silhouette_v12(_enabled: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and hq_v11_toggle.button_pressed:
        _display_headquarters()

func _change_hq_camera(index: int) -> void:
    if index < 0 or index > 1:
        return
    _hq_camera_preset = index
    if _role != "headquarters" or hq_batch_toggle.button_pressed:
        return
    _zoom = 0.69 if index == 1 else 1.0
    if camera != null:
        camera.position = _hq_camera_position()
        camera.look_at(Vector3(0,2.3,0),Vector3.UP)
    _update_camera()

func _hq_camera_position() -> Vector3:
    return Vector3(-17.5,22.0,-19.5) if _hq_camera_preset == 1 else Vector3(-18.0,16.5,-19.0)

func _change_hq_v15_mode(index: int) -> void:
    if index < 0 or index > 2:
        return
    hq_v15_mode_picker.select(index)
    _refresh_hq_v15_sprite()
    if _role == "headquarters":
        _display_headquarters()

func _change_hq_v15_neutral(_enabled: bool) -> void:
    _refresh_hq_v15_sprite()
    if _role == "headquarters" and hq_v15_mode_picker.selected == 2:
        _display_headquarters()

func _change_hq_v15_zoom(index: int) -> void:
    if index < 0 or index >= HQSpriteV16.ZOOM_PIXELS.size():
        return
    hq_v15_zoom_picker.select(index)
    _refresh_hq_v15_sprite()

func _refresh_hq_v15_sprite() -> void:
    if hq_v15_thumbnail == null:
        return
    var faction: int = -1 if hq_v15_neutral_toggle.button_pressed else _faction
    var texture: Texture2D = HQSpriteV16.texture_for(faction)
    hq_v15_thumbnail.texture = texture
    var index: int = clampi(hq_v15_zoom_picker.selected,0,HQSpriteV16.ZOOM_PIXELS.size()-1)
    var dimension: int = int(HQSpriteV16.ZOOM_PIXELS[index])
    hq_v15_thumbnail.custom_minimum_size = Vector2(dimension,dimension)
    var display_sprite: bool = hq_v15_mode_picker.selected != 1
    hq_v15_frame.visible = display_sprite
    hq_v15_zoom_picker.visible = display_sprite
    hq_v15_caption.visible = display_sprite
    if texture == null:
        hq_v15_caption.text = "Sprite V15 no importado · conservando el modelo 3D."
    elif faction < 0:
        hq_v15_caption.text = "V15 neutral · niebla sin insignia · 384 px"
    elif index == 2:
        hq_v15_caption.text = "Zoom lejano: TARVOKA Android usa dibujo vectorial V14"
    else:
        hq_v15_caption.text = "V15 desde modelo V13 · %s · 384 px (nivel 2 operativo)" % str(VisualStyle.FACTIONS[faction]["name"])

func _change_hq_production_v13(_enabled: bool) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _change_building_batch(_enabled: bool) -> void:
    if _role == "headquarters":
        _display_headquarters()

func _change_hq_stress_dimension(index: int) -> void:
    if index < 0 or index >= 3:
        return
    _hq_grid_dimension = [7,10,12][index]
    hq_stress_picker.select(index)
    if _role == "headquarters" and hq_batch_toggle.button_pressed:
        _display_headquarters()

func _set_hq_map_lod(distant: bool) -> void:
    if _role == "headquarters" and _hq_show_v4 and model_root != null:
        HQMapLOD.set_distant(model_root,distant)
        _sync_hq_wayfinding_v18()
        _sync_hq_facade_v19()
        var impact_fx: TarvokaHeadquartersImpactV21 = model_root.get_node_or_null(
            HQImpactV21.STAGE_NAME) as TarvokaHeadquartersImpactV21
        if impact_fx != null:
            impact_fx.visible = not distant
            if distant:
                impact_fx.stop()
        # V22 permanent flames and smoke must stop processing when the
        # tactical distant LOD hides high-poly building detail.
        var ambient: TarvokaHeadquartersFireV22 = model_root.get_node_or_null(
            HQFireV22.STAGE_NAME) as TarvokaHeadquartersFireV22
        if ambient != null:
            ambient.set_distant(distant)
        var volume: TarvokaHeadquartersSmokeV23 = model_root.get_node_or_null(
            HQSmokeV23.STAGE_NAME) as TarvokaHeadquartersSmokeV23
        if volume != null:
            volume.set_distant(distant)
        var debris_layer: Node3D = model_root.get_node_or_null(
            HQDamageV22.STAGE_NAME) as Node3D
        if debris_layer != null:
            debris_layer.visible = not distant
        if hq_bullet_test_button != null:
            hq_bullet_test_button.disabled = distant
            hq_explosive_test_button.disabled = distant
        _update_details()

func _refresh_building_faction(_index: int) -> void:
    _sync_faction_gallery(_faction)
    _refresh_hq_v15_sprite()
    # UnitArtStudioWeb's handler owns _faction; we rebuild using that
    # selected paint colour rather than tinting an entire concrete building.
    if _role == "headquarters":
        _display_headquarters()
    elif _role == "airbase":
        _airbase_v14_history.clear()
        _display_airbase()
    elif _role == "naval_base":
        _display_naval_base()
    elif _role == "supply_center":
        _display_supply_center()

func _display_headquarters() -> void:
    if preview == null:
        return
    var initial: bool = _role != "headquarters"
    _stop_animation()
    if model_root != null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role = "headquarters"
    _refresh_hq_v15_sprite()
    var showing_batch: bool = hq_batch_toggle.button_pressed and _hq_show_v4
    _apply_hq_climate_v17()
    hq_batch_toggle.visible = _hq_show_v4
    hq_v7_toggle.visible = _hq_show_v4 and not showing_batch
    hq_v8_toggle.visible = _hq_show_v4 and hq_v7_toggle.button_pressed and not showing_batch
    hq_v9_toggle.visible = _hq_show_v4 and hq_v7_toggle.button_pressed and hq_v8_toggle.button_pressed and not showing_batch
    hq_v10_toggle.visible = _hq_show_v4 and hq_v7_toggle.button_pressed and hq_v8_toggle.button_pressed and hq_v9_toggle.button_pressed and not showing_batch
    hq_v11_toggle.visible = hq_v10_toggle.visible and hq_v10_toggle.button_pressed
    hq_v12_toggle.visible = hq_v11_toggle.visible and hq_v11_toggle.button_pressed
    hq_camera_picker.visible = not showing_batch
    hq_v15_mode_picker.visible = not showing_batch
    hq_v15_neutral_toggle.visible = not showing_batch
    hq_v15_frame.visible = not showing_batch and hq_v15_mode_picker.selected != 1
    hq_v15_zoom_picker.visible = hq_v15_frame.visible
    hq_v15_caption.visible = hq_v15_frame.visible
    hq_production_toggle.visible = _hq_show_v4 and not showing_batch
    hq_production_metric_label.visible = hq_production_toggle.button_pressed and not showing_batch
    hq_fps_label.visible = showing_batch
    hq_stress_picker.visible = showing_batch
    var hero_mode: bool = not showing_batch and hq_v15_mode_picker.selected != 2 and not hq_production_toggle.button_pressed
    hq_damage_stage_picker.disabled = not hero_mode
    hq_bullet_test_button.disabled = not hero_mode or hq_map_lod_toggle.button_pressed
    hq_explosive_test_button.disabled = not hero_mode or hq_map_lod_toggle.button_pressed
    # Large districts are deliberately batched dry map proxies; disable
    # climate selectors there instead of silently ignoring user clicks.
    hq_weather_picker.disabled = showing_batch
    hq_terrain_picker.disabled = showing_batch
    if showing_batch:
        model_root = HQCityBatch.build_grid(_hq_grid_dimension,_hq_grid_dimension,15.5)
        assert(model_root != null)
        hq_map_lod_toggle.visible = false
        preview.add_child(model_root)
        if initial:
            _yaw = 32.0
            _zoom = 1.0
        model_root.rotation_degrees.y = _yaw
        camera.position = Vector3(-125.0,100.0,-125.0) * float(_hq_grid_dimension)/7.0
        camera.look_at(Vector3(0,2.3,0),Vector3.UP)
        _update_camera()
        _update_details()
        return
    var level: int = level_picker.selected + 1
    var condition: String = str(BUILDING_STATES[building_state_picker.selected])
    var damage_stage: int = hq_damage_stage_picker.selected
    # HQ V21 stages 1..3 build a sound structural baseline so damage is
    # physically progressive, not old V8 rubble piled on each stage.
    var construction_condition: String = "operativo" if condition == "danado" and damage_stage in [1,2,3] else condition
    if hq_v15_mode_picker.selected == 2 and _hq_show_v4:
        var sprite_faction: int = -1 if hq_v15_neutral_toggle.button_pressed else _faction
        model_root = HQSpriteV16.build_billboard(sprite_faction,_faction)
        if model_root == null:
            # Do not hide the architectural 3D model when PNGs are absent.
            model_root = HQProduction.build(level,_faction,condition,
                HQProduction.QUALITY_TACTICAL,false)
        hq_map_lod_toggle.visible = false
    elif hq_production_toggle.button_pressed and _hq_show_v4:
        model_root = HQProduction.build(level,_faction,condition,
            HQProduction.QUALITY_TACTICAL,true)
        hq_map_lod_toggle.visible = false
    else:
        model_root = Headquarters.build(level,_faction,construction_condition,
            _hq_show_v2,_hq_show_v3,_hq_show_v4,
            hq_v7_toggle.button_pressed,hq_v8_toggle.button_pressed,
            hq_v9_toggle.button_pressed,hq_v10_toggle.button_pressed,
            hq_v11_toggle.button_pressed,hq_v12_toggle.button_pressed)
        hq_map_lod_toggle.visible = _hq_show_v4
        if _hq_show_v4:
            HQMapLOD.install(model_root,level,_faction,condition)
            HQMapLOD.set_distant(model_root,hq_map_lod_toggle.button_pressed)
    assert(model_root != null)
    preview.add_child(model_root)
    if model_root.get_meta("tarvoka_hq_visual_v12",false):
        model_root.add_child(HQWayfindingV18.build())
        model_root.add_child(HQFacadeV19.build())
        var added: bool = HQDamageV21.apply(model_root,damage_stage,level)
        assert(added)
        # Apply V22 structural changes on top of the existing V21 scene.
        # Do not run these in assert(): WebGL release must render them too.
        var v22_added: bool = HQDamageV22.apply(model_root,damage_stage,level)
        assert(v22_added)
        if damage_stage in [2,3]:
            var persistent: TarvokaHeadquartersFireV22 = HQFireV22.build(damage_stage)
            model_root.add_child(persistent)
            persistent.set_smoke_replaced(true)
            persistent.set_distant(hq_map_lod_toggle.button_pressed)
            var volume: TarvokaHeadquartersSmokeV23 = HQSmokeV23.build(damage_stage)
            model_root.add_child(volume)
            volume.set_distant(hq_map_lod_toggle.button_pressed)
        var structural: Node3D = model_root.get_node_or_null(
            HQDamageV22.STAGE_NAME) as Node3D
        if structural != null:
            structural.visible = not hq_map_lod_toggle.button_pressed
        model_root.set_meta("visual_condition",condition)
        var impact_fx := HQImpactV21.new()
        model_root.add_child(impact_fx)
        impact_fx.visible = not hq_map_lod_toggle.button_pressed
        if hq_impact_status != null:
            var detail: String = [
                "Sin daños estructurales",
                "Antenas superiores derribadas",
                "Cristales y techos rotos · humo volumétrico V23",
                "Ala colapsada · fuego y humo volumétrico V23",
                "Ruinas estructurales sin edificio intacto"
            ][damage_stage]
            hq_impact_status.text = "V22 · %s · %s · impactos de bala y explosión" % [
                str(HQDamageV21.STAGES[damage_stage]),detail]
    _apply_hq_climate_v17()
    _sync_hq_wayfinding_v18()
    _sync_hq_facade_v19()
    if initial:
        _yaw = 32.0
        _zoom = 0.69 if _hq_camera_preset == 1 else 1.0
    model_root.rotation_degrees.y = _yaw
    # Front-right camera reveals the command entrance, insignia, and helipad.
    camera.position = _hq_camera_position()
    camera.look_at(Vector3(0,2.3,0),Vector3.UP)
    _update_camera()
    _update_details()

func _reset_camera() -> void:
    if _role=="supply_center":
        _yaw=28.0
        _zoom=1.0
        if model_root!=null:
            model_root.rotation_degrees.y=_yaw
        _apply_supply_camera()
        return
    if _role == "naval_base":
        _yaw=26.0
        _zoom=1.0
        if model_root!=null:
            model_root.rotation_degrees.y=_yaw
        _apply_naval_camera()
        return
    if _role == "airbase":
        _yaw = 32.0
        _zoom = 1.0
        _airbase_camera_interior = false
        if model_root != null:
            model_root.rotation_degrees.y = _yaw
        if _airbase_is_stress():
            camera.position=Vector3(-95.0,108.0,-101.0) * \
                float(int(model_root.get_meta("tarvoka_stress_grid_cols",4)))/8.0
            camera.look_at(Vector3(0,1.5,0),Vector3.UP)
            _update_camera()
        else:
            _apply_airbase_camera()
        return
    if _role == "headquarters":
        _yaw = 32.0
        _zoom = 0.69 if _hq_camera_preset == 1 else 1.0
        if camera != null:
            camera.position = _hq_camera_position()
            camera.look_at(Vector3(0,2.3,0),Vector3.UP)
        if model_root != null:
            model_root.rotation_degrees.y = _yaw
        _update_camera()
        return
    super._reset_camera()

func _update_camera() -> void:
    if _role=="supply_center":
        if camera!=null:
            camera.size=(11.4 if _supply_camera_view==1 else
                17.0 if _supply_camera_view==2 else
                19.8 if _supply_camera_view==3 else
                22.0)/maxf(0.35,_zoom)
        return
    if _role=="naval_base":
        if camera!=null:
            camera.size=(8.0 if _naval_camera_view==7 else
                6.2 if _naval_camera_view==6 else
                8.4 if _naval_camera_view==5 else
                9.4 if _naval_camera_view==4 else 20.9)/maxf(0.35,_zoom)
        if model_root!=null and model_root.has_node(NavalNightV6.STAGE_NAME):
            NavalNightV6.set_detail(model_root,_zoom>=0.85)
        if model_root!=null and model_root.has_node(NavalBoardingV7.STAGE_NAME):
            NavalBoardingV7.set_detail(model_root,_zoom>=0.85)
        if model_root!=null and model_root.has_node(NavalFendersV8.STAGE_NAME):
            NavalFendersV8.set_detail(model_root,_zoom>=0.85)
        if model_root!=null and model_root.has_node(NavalSculptV9.STAGE_NAME):
            NavalSculptV9.set_detail(model_root,_zoom>=0.85)
        if model_root!=null and model_root.has_node(NavalMooringV10.STAGE_NAME):
            NavalMooringV10.set_detail(model_root,_zoom>=0.85)
        if model_root!=null and model_root.has_node(NavalContactV11.STAGE_NAME):
            NavalContactV11.set_detail(model_root,_zoom>=0.85)
        if model_root!=null and model_root.has_node(NavalFinalV12.STAGE_NAME):
            NavalFinalV12.set_detail(model_root,_zoom>=0.85)
        return
    if _role == "airbase":
        if camera != null:
            if _airbase_is_stress():
                var cols: int = int(model_root.get_meta("tarvoka_stress_grid_cols",4))
                camera.size=(18.0+float(cols)*16.5)/maxf(0.35,_zoom)
            else:
                # In an orthographic camera, changing distance does NOT
                # zoom in: the inspection lens needs its own frustum size.
                var focus_close: bool=airbase_v13_focus_toggle!=null and \
                    airbase_v13_focus_toggle.button_pressed and \
                    airbase_impacts_v13_toggle.button_pressed
                var tower_close: bool = airbase_detail_v9_toggle != null and \
                    airbase_detail_v9_toggle.button_pressed and _airbase_v9_view==5
                camera.size = (
                    5.6 if focus_close else 6.4 if tower_close else
                    10.5 if _airbase_camera_interior else 18.8
                    )/maxf(0.35,_zoom)
        return
    if _role == "headquarters":
        if camera != null:
            camera.size = (153.0 * float(_hq_grid_dimension)/7.0 if hq_batch_toggle.button_pressed and _hq_show_v4 else 18.6) / _zoom
            if model_root != null and not hq_batch_toggle.button_pressed:
                Headquarters.set_render_detail(model_root,_zoom >= 1.24)
        return
    super._update_camera()

func _update_details() -> void:
    if _role=="supply_center" and model_root!=null:
        detail_label.text="Centro de Suministros V1 · Nivel %d · %d mallas 3D" % [
            int(model_root.get_meta("visual_level",1)),
            SupplyCenterV1.count_meshes(model_root)]
        status_label.text="%s · %s · logística de combustible y municiones (solo arte)" % [
            str(VisualStyle.FACTIONS[_faction]["name"]),
            str(SupplyCenterV1.DAMAGE_STAGES[int(model_root.get_meta("visual_damage_stage",0))])]
        return
    if _role=="naval_base" and model_root!=null:
        var naval_version: String="V1"
        for spec in [
            [NavalDetailV2.STAGE_NAME,"V2"],
            [NavalBerthsV3.STAGE_NAME,"V3"],
            [NavalMarineV4.STAGE_NAME,"V4"],
            [NavalYardV5.STAGE_NAME,"V5"],
            [NavalNightV6.STAGE_NAME,"V6"],
            [NavalBoardingV7.STAGE_NAME,"V7"],
            [NavalFendersV8.STAGE_NAME,"V8"],
            [NavalSculptV9.STAGE_NAME,"V9"],
            [NavalMooringV10.STAGE_NAME,"V10"],
            [NavalContactV11.STAGE_NAME,"V11"],
            [NavalFinalV12.STAGE_NAME,"V12"],
            [NavalAuditV13.STAGE_NAME,"V13"]
        ]:
            if model_root.has_node(str(spec[0])):
                naval_version=str(spec[1])
        detail_label.text="Base Naval %s · Nivel %d · %d mallas reales" % [
            naval_version,int(model_root.get_meta("visual_level",1)),
            NavalBaseV1.count_meshes(model_root)]
        status_label.text="%s · %s · encuadres corregidos y cadenas verificadas 3D" % [
            str(VisualStyle.FACTIONS[_faction]["name"]),
            str(NavalBaseV1.DAMAGE_STAGES[int(model_root.get_meta(
                "visual_damage_stage",0))])]
        return
    if _role == "airbase":
        if model_root == null:
            return
        if _airbase_is_stress():
            var count: int = int(model_root.get_meta("tarvoka_stress_count",0))
            var close: int = int(model_root.get_meta("tarvoka_stress_near_count",0))
            var far: int = int(model_root.get_meta("tarvoka_stress_proxy_count",0))
            var meshes: int = int(model_root.get_meta("tarvoka_stress_mesh_nodes",0))
            detail_label.text = "Base Aérea V4 · %d edificios · %d detallados / %d LOD" % [
                count,close,far]
            status_label.text = "%d nodos de malla · estimación de %d superficies (NO FPS Android)" % [
                meshes,int(model_root.get_meta("tarvoka_stress_estimated_surfaces",0))]
            return
        var tier: int = int(model_root.get_meta("visual_level",1))
        var stage: int = int(model_root.get_meta("visual_damage_stage",0))
        detail_label.text = "Base Aérea · V4 HUMO / FUEGO SUAVES · Nivel %d · %d mallas 3D" % [
            tier,AirbaseV1.mesh_count(model_root)]
        status_label.text = "%s · %s · %d piezas de facción · casco cerrado" % [
            str(Factions.FACTIONS[_faction]["name"]),
            str(AirbaseV1.DAMAGE_STAGES[stage]),
            AirbaseV1.count_faction_panels(model_root)]
        return
    if _role != "headquarters":
        super._update_details()
        return
    if model_root == null:
        return
    if model_root.get_meta("tarvoka_hq_v15_sprite_card",false):
        detail_label.text = "V15 · Sprite Android real de 384 px dentro del escenario Godot 3D"
        status_label.text = "Imagen horneada desde HQ V13 · NO es una malla 3D; girar no cambia la vista impresa"
        return
    if model_root.get_meta("tarvoka_building_kind","") == "headquarters_city":
        var buildings: int = int(model_root.get_meta("tarvoka_studio_building_count",0))
        var batches: int = int(model_root.get_meta("tarvoka_studio_batch_count",0))
        detail_label.text = "Distrito 3D · %d cuarteles · %d lotes MultiMesh" % [buildings,batches]
        status_label.text = "Geometrías compartidas · %d variantes en caché" % HQMapLOD.cached_variant_count()
        return
    var level: int = int(model_root.get_meta("visual_level",1))
    var faction: int = int(model_root.get_meta("visual_faction",0))
    var condition: String = str(model_root.get_meta("visual_condition","operativo"))
    var meshes: int = Models.inspect_meshes(model_root)
    detail_label.text = "Cuartel General · %s · Nivel %d · %d mallas 3D" % [
        ("ARQUITECTURA V4" if _hq_show_v4 else ("ARQUITECTURA V3" if _hq_show_v3 else "ARQUITECTURA V2")) if _hq_show_v2 else "PROTOTIPO V1",level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v7",false):
        detail_label.text = "Cuartel General · ACABADO ESCULPIDO V7 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v8",false):
        detail_label.text = "Cuartel General · ACABADO PBR Y DAÑOS V8 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v9",false):
        detail_label.text = "Cuartel General · SILUETA V9 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v10",false):
        detail_label.text = "Cuartel General · SUPERFICIES V10 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v11",false):
        detail_label.text = "Cuartel General · REMATES CURVOS V11 · Nivel %d · %d mallas 3D" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_visual_v12",false):
        detail_label.text = "Cuartel General · V21 CERRAMIENTO TOTAL + DAÑO 3D · Nivel %d · %d mallas" % [level,meshes]
    if model_root.get_meta("tarvoka_hq_production_v13",false):
        var budget: Dictionary = HQProduction.render_budget(model_root)
        detail_label.text = "Cuartel General · PERFIL V13 · Nivel %d · %d mallas / %d superficies" % [
            level,int(budget["meshes"]),int(budget["surfaces"])]
        hq_production_metric_label.text = "Modelo Android: %d mallas · %d superficies · sin modelo completo oculto" % [
            int(budget["meshes"]),int(budget["surfaces"])]
    if model_root.get_meta("tarvoka_hq_map_distant",false):
        detail_label.text = "Cuartel General · VISTA DE MAPA V5 · Nivel %d · 1 malla 3D / 6 superficies" % level
    status_label.text = "%s · %s · Piezas de color: %d" % [
        str(Factions.FACTIONS[faction]["name"]),
        condition.capitalize(),
        Headquarters.paintable_count(model_root)]

func _process(delta: float) -> void:
    super._process(delta)
    if _role == "airbase":
        var door_rig: TarvokaAirbaseDoorRigV2 = _airbase_gate_rig()
        if door_rig != null and door_rig.is_moving():
            _refresh_airbase_door_ui()
    if _airbase_is_stress():
        _airbase_stress_seconds += delta
        if _airbase_stress_seconds >= 0.75:
            _airbase_stress_seconds=0.0
            if airbase_stress_status!=null:
                airbase_stress_status.text="Visor Godot: %d FPS · %d edificios · %d LOD · no medido en Android" % [
                    Engine.get_frames_per_second(),
                    int(model_root.get_meta("tarvoka_stress_count",0)),
                    int(model_root.get_meta("tarvoka_stress_proxy_count",0))]
    if _role in ["headquarters","airbase"] and hq_climate_stage != null and hq_climate_stage.visible:
        _hq_weather_time += delta
        if model_root != null and _role == "headquarters":
            HQClimateV17.orient_roof_caps(hq_climate_stage,model_root.rotation.y)
        HQClimateV17.animate(hq_climate_stage,_hq_weather_time)
    if _role != "headquarters" or hq_batch_toggle == null or not hq_batch_toggle.button_pressed:
        return
    _fps_refresh += delta
    if _fps_refresh < 0.75:
        return
    _fps_refresh = 0.0
    if hq_fps_label != null and model_root != null:
        hq_fps_label.text = "FPS visor: %d | %d edificios | %d lotes de dibujo" % [
            Engine.get_frames_per_second(),
            int(model_root.get_meta("tarvoka_studio_building_count",0)),
            int(model_root.get_meta("tarvoka_studio_batch_count",0))]
