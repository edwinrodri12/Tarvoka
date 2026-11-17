extends "res://scripts/ui/BastionStudioAdapter.gd"
class_name TarvokaCivilianCityStudioAdapter

# ONE TARVOKA Estudio 3D scene and all existing unit/building categories.
# This additive subclass only adds the civilian income-city category.
const CivilianCity=preload("res://scripts/ui/CivilianCity3DV1.gd")
const CityV2=preload("res://scripts/ui/CivilianCityFacadeV2.gd")
const CityV3=preload("res://scripts/ui/CivilianCityPublicSpaceV3.gd")
const CityStyle=preload("res://scripts/ui/VisualStyle.gd")
var city_controls: VBoxContainer
var city_level_picker: OptionButton
var city_faction_picker: OptionButton
var city_damage_picker: OptionButton
var city_caption: Label
var city_v2_toggle: CheckButton
var city_v3_toggle: CheckButton

func _ready() -> void:
    super._ready()
    building_picker.add_item("Ciudad Civil · V1 · villa, ciudad y metrópoli")
    city_controls=VBoxContainer.new()
    city_controls.name="OpcionesCiudadCivilV1"
    city_controls.add_theme_constant_override("separation",7)
    city_controls.visible=false
    building_controls.add_child(city_controls)
    var heading:=Label.new()
    heading.text="CIUDAD CIVIL · PRIMER MODELO 3D"
    heading.add_theme_font_size_override("font_size",15)
    city_controls.add_child(heading)
    var desc:=Label.new()
    desc.text="Edificios y plaza que generan ingresos al conquistarse. No es un Cuartel General."
    desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    city_controls.add_child(desc)
    city_level_picker=OptionButton.new()
    city_level_picker.name="CiudadTipoDeBarrio"
    city_level_picker.custom_minimum_size.y=46
    for label in CivilianCity.LABELS:
        city_level_picker.add_item(str(label))
    city_level_picker.select(0)
    city_level_picker.item_selected.connect(_change_city_visual)
    city_controls.add_child(city_level_picker)
    city_faction_picker=OptionButton.new()
    city_faction_picker.name="CiudadIdentidadFaccion"
    city_faction_picker.custom_minimum_size.y=46
    city_faction_picker.add_item("Neutral · sin propietario")
    for info in CityStyle.FACTIONS:
        city_faction_picker.add_item(str(info["name"]))
    city_faction_picker.select(1)
    city_faction_picker.item_selected.connect(_change_city_visual)
    city_controls.add_child(city_faction_picker)
    city_damage_picker=OptionButton.new()
    city_damage_picker.name="CiudadDanoArquitectonico"
    city_damage_picker.custom_minimum_size.y=46
    for label in CivilianCity.DAMAGE_LABELS:
        city_damage_picker.add_item(str(label))
    city_damage_picker.select(0)
    city_damage_picker.item_selected.connect(_change_city_visual)
    city_controls.add_child(city_damage_picker)
    city_caption=Label.new()
    city_caption.name="CiudadMetadatosVisuales"
    city_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    city_controls.add_child(city_caption)
    city_v2_toggle=CheckButton.new()
    city_v2_toggle.name="CiudadCivilFachadas3DV2"
    city_v2_toggle.text="V2 · fachadas, balcones y tejados (comparar V1)"
    city_v2_toggle.button_pressed=true
    city_v2_toggle.toggled.connect(_toggle_city_v2)
    city_controls.add_child(city_v2_toggle)
    city_v3_toggle=CheckButton.new()
    city_v3_toggle.name="CiudadCivilPlazaAccesosV3"
    city_v3_toggle.text="V3 · plaza, accesos y movilidad (comparar V2)"
    city_v3_toggle.button_pressed=true
    city_v3_toggle.toggled.connect(_toggle_city_v3)
    city_controls.add_child(city_v3_toggle)
    # The parent already connected its handler to this SAME picker. Its
    # handler handles 0..3; this one enables category 4 after that cleanup.
    building_picker.item_selected.connect(_on_building_city_selected)

func _toggle_city_v2(_enabled: bool) -> void:
    city_v3_toggle.disabled=not city_v2_toggle.button_pressed
    if _role=="civilian_city":
        _display_civilian_city()

func _toggle_city_v3(_enabled: bool) -> void:
    if _role=="civilian_city":
        _display_civilian_city()

func _change_city_visual(_index: int) -> void:
    if _role=="civilian_city":
        _display_civilian_city()

func _on_building_city_selected(index: int) -> void:
    city_controls.visible=index==4
    if index==4:
        _display_civilian_city()

func _display_civilian_city() -> void:
    if preview==null:
        return
    _stop_animation()
    if model_root!=null:
        preview.remove_child(model_root)
        model_root.queue_free()
    _role="civilian_city"
    var level: int=city_level_picker.selected+1
    var faction: int=city_faction_picker.selected-1
    var damage: int=city_damage_picker.selected
    model_root=CivilianCity.build(level,faction,damage)
    if model_root==null:
        push_error("TARVOKA Ciudad Civil V1 no se pudo crear")
        return
    if city_v2_toggle.button_pressed:
        var applied: bool=CityV2.apply(model_root,level,faction,damage)
        if not applied:
            push_error("Ciudad Civil V2: no se aplicaron las fachadas 3D")
    if city_v2_toggle.button_pressed and city_v3_toggle.button_pressed:
        var public_ok: bool=CityV3.apply(model_root,level,faction,damage)
        if not public_ok:
            push_error("Ciudad Civil V3: espacio público no se aplicó")
    model_root.name="CiudadCivilVisibleEnEstudio"
    preview.add_child(model_root)
    if hq_ground!=null:
        hq_ground.visible=true
    if camera!=null:
        camera.position=Vector3(21.0,18.0,25.0)
        camera.look_at(Vector3(0,2.20,0),Vector3.UP)
    _update_camera()
    _update_details()

func _update_camera() -> void:
    super._update_camera()
    if _role=="civilian_city" and camera!=null:
        camera.size=26.0/maxf(0.38,_zoom)

func _update_details() -> void:
    if _role=="civilian_city":
        if model_root==null or detail_label==null or status_label==null:
            return
        var level: int=int(model_root.get_meta("visual_level",1))
        var damage: int=int(model_root.get_meta("visual_damage_stage",0))
        var faction: int=int(model_root.get_meta("visual_faction",-1))
        detail_label.text="Ciudad Civil %s · %s · %d mallas 3D reales" % [
            "V3" if model_root.has_node(CityV3.STAGE_NAME) else
            "V2" if model_root.has_node(CityV2.STAGE_NAME) else "V1",
            str(CivilianCity.LABELS[level-1]),
            CivilianCity.count_meshes(model_root)]
        status_label.text="%s · %s · solo apariencia visual" % [
            "Neutral" if faction<0 else str(CityStyle.FACTIONS[faction]["name"]),
            str(CivilianCity.DAMAGE_LABELS[damage])]
        city_caption.text="Ciudad civil · %s · Ayuntamiento, plaza, cruces peatonales y accesos municipales 3D. Los niveles y los daños son gráficos: no cambian ingresos ni capturas." % ("espacio público V3" if model_root.has_node(CityV3.STAGE_NAME) else "fachadas V2" if model_root.has_node(CityV2.STAGE_NAME) else "volúmenes V1")
        return
    super._update_details()
