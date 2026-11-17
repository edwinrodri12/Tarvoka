extends "res://scripts/ui/BastionStudioAdapter.gd"
class_name TarvokaCivilianCityStudioAdapter

# Add unfinished CIVILIAN CITIES to the ACTUAL unified studio's
# EDIFICIOS picker. All existing HQ, airbase, naval base, barracks and
# military units retain their original controls, models and animations.
# Native Godot meshes; no iframes, external links or screenshot proxies.
const Cities=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const CityBase=preload("res://scripts/ui/CivilianCity3DV1.gd")
const CityMaterials=preload("res://scripts/ui/CivilianCityExteriorFinishV20.gd")
const CityStyle=preload("res://scripts/ui/VisualStyle.gd")

var civilian_city_controls: VBoxContainer
var civilian_city_tier: OptionButton
var civilian_city_damage: OptionButton
var civilian_city_faction: OptionButton
var civilian_city_lod: OptionButton
var civilian_city_hint: Label
var _city_view: int=0
const CITY_BUILDING_INDEX: int=4

func _ready() -> void:
    super._ready()
    if building_picker==null or building_controls==null:
        push_error("TARVOKA Edificios: no se encontró selector unificado")
        return
    if building_picker.item_count!=CITY_BUILDING_INDEX:
        push_error("TARVOKA Edificios: cambió el catálogo, evitar sobrescritura")
        return
    building_picker.add_item("Ciudades civiles · Villa / Ciudad / Metrópoli · V20")
    building_picker.set_item_metadata(CITY_BUILDING_INDEX,"civilian_city")
    _install_city_options()
    _refresh_unified_studio_navigation()

func _install_city_options() -> void:
    civilian_city_controls=VBoxContainer.new()
    civilian_city_controls.name="Edificios_Ciudades_Civiles_V20"
    civilian_city_controls.add_theme_constant_override("separation",6)
    civilian_city_controls.visible=false
    building_controls.add_child(civilian_city_controls)
    _title(civilian_city_controls,
        "CIUDAD CIVIL · V20 · MODELO 3D EN DISEÑO",14)
    _title(civilian_city_controls,
        "Elige Villa, Ciudad o Metrópoli; visualiza 5 etapas de daño.",12)
    civilian_city_tier=OptionButton.new()
    civilian_city_tier.name="Ciudades_Nivel_Arquitectonico"
    for title in ["VILLA · terracota y madera",
            "CIUDAD · piedra y ladrillo",
            "METRÓPOLI · vidrio y metal"]:
        civilian_city_tier.add_item(title)
    civilian_city_tier.select(1)
    civilian_city_tier.item_selected.connect(_on_city_option)
    civilian_city_controls.add_child(civilian_city_tier)
    civilian_city_damage=OptionButton.new()
    civilian_city_damage.name="Ciudades_Etapas_De_Dano"
    for label in CityBase.DAMAGE_LABELS:
        civilian_city_damage.add_item(str(label))
    civilian_city_damage.select(0)
    civilian_city_damage.item_selected.connect(_on_city_option)
    civilian_city_controls.add_child(civilian_city_damage)
    civilian_city_faction=OptionButton.new()
    civilian_city_faction.name="Ciudades_Facciones_Y_Neutral"
    civilian_city_faction.add_item("NEUTRAL")
    for i in range(CityStyle.FACTIONS.size()):
        civilian_city_faction.add_item(
            str(CityStyle.FACTIONS[i]["name"]))
    civilian_city_faction.select(0)
    civilian_city_faction.item_selected.connect(_on_city_option)
    civilian_city_controls.add_child(civilian_city_faction)
    civilian_city_lod=OptionButton.new()
    civilian_city_lod.name="Ciudades_Detalle_Geometrico"
    for title in ["DETALLE COMPLETO", "VISTA TÁCTICA", "SILUETA LEJANA"]:
        civilian_city_lod.add_item(title)
    civilian_city_lod.select(0)
    civilian_city_lod.item_selected.connect(_on_city_option)
    civilian_city_controls.add_child(civilian_city_lod)
    var views:=HFlowContainer.new()
    views.name="Ciudades_Camaras_3D"
    views.add_theme_constant_override("h_separation",4)
    views.add_theme_constant_override("v_separation",4)
    civilian_city_controls.add_child(views)
    for data in [
        ["360°",0],["FACHADA",1],["AZOTEA",2],["RUINAS",3],
        ["COSTADO",4],["POSTERIOR",5]
    ]:
        var b:=Button.new()
        b.text=str(data[0])
        b.custom_minimum_size=Vector2(90,35)
        var index: int=int(data[1])
        b.pressed.connect(Callable(self,"_city_camera_preset").bind(index))
        views.add_child(b)
    for config in [["GIRAR ↶",-45.0],["GIRAR ↷",45.0]]:
        var rotate_button:=Button.new()
        rotate_button.text=str(config[0])
        rotate_button.custom_minimum_size=Vector2(98,35)
        rotate_button.pressed.connect(
            Callable(self,"_city_orbit").bind(float(config[1])))
        views.add_child(rotate_button)
    civilian_city_hint=_title(civilian_city_controls,
        "ARTE V20 · SOLO VISUAL · Sin modificaciones de jugabilidad",12)
    civilian_city_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _on_city_option(_index: int) -> void:
    if _role=="civilian_city":
        _display_civilian_city()

func _city_camera_preset(index: int) -> void:
    if civilian_city_tier==null:
        return
    _city_view=clampi(index,0,5)
    if _city_view==3 and civilian_city_damage!=null:
        civilian_city_damage.select(3)
    _yaw=35.0 if _city_view==0 else 0.0
    _zoom=1.35 if _city_view in [1,4,5] else 1.05
    if _role=="civilian_city":
        _display_civilian_city()

func _city_orbit(delta_degrees: float) -> void:
    if _role!="civilian_city" or model_root==null:
        return
    _yaw=fposmod(_yaw+delta_degrees,360.0)
    model_root.rotation_degrees.y=_yaw
    _update_camera()

func _change_selected_building(index: int) -> void:
    if index==CITY_BUILDING_INDEX and civilian_city_controls!=null:
        # The inherited selector hides HQ, Airbase, Naval and Infantry
        # controls, but does not know this NEW fifth building yet.
        super._change_selected_building(index)
        civilian_city_controls.visible=true
        _display_civilian_city()
        return
    if civilian_city_controls!=null:
        civilian_city_controls.visible=false
    super._change_selected_building(index)
    if faction_picker!=null:
        faction_picker.visible=true

func _switch_category(index: int) -> void:
    super._switch_category(index)
    if civilian_city_controls==null or building_picker==null:
        return
    if index==1 and building_picker.selected==CITY_BUILDING_INDEX:
        civilian_city_controls.visible=true
        _display_civilian_city()
    else:
        civilian_city_controls.visible=false
        if faction_picker!=null:
            faction_picker.visible=true

func _display_civilian_city() -> void:
    if (preview==null or civilian_city_tier==null
            or civilian_city_damage==null or civilian_city_faction==null
            or civilian_city_lod==null):
        return
    _stop_animation()
    if _p06_fleet!=null:
        _hide_p06_fleet()
    if model_root!=null:
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root=null
    _role="civilian_city"
    var level: int=civilian_city_tier.selected+1
    var damage: int=civilian_city_damage.selected
    var faction: int=civilian_city_faction.selected-1
    var lod: int=civilian_city_lod.selected
    model_root=Cities.build_tactical(level,faction,damage,lod)
    if model_root==null:
        push_error("Ciudad V20: no fue posible construir mallas de Godot")
        return
    preview.add_child(model_root)
    model_root.name="EDIFICIO_CIUDAD_CIVIL_V20_N%d_D%d" % [level,damage]
    model_root.rotation_degrees.y=_yaw
    if hq_ground!=null:
        hq_ground.visible=false
    if hq_climate_stage!=null:
        hq_climate_stage.visible=false
    if hq_map_lod_toggle!=null:
        hq_map_lod_toggle.visible=false
    if faction_picker!=null:
        # Neutral plus eight faction colors live in the city selector.
        faction_picker.visible=false
    _update_camera()
    _update_details()
    _refresh_unified_studio_navigation()
    if studio_overview_label!=null:
        studio_overview_label.text="EDIFICIOS · CIUDAD CIVIL V20 · EN DISEÑO"

func _update_camera() -> void:
    if _role=="civilian_city":
        if camera==null:
            return
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        var area: float=25.0 if _city_view==0 else (
            17.5 if _city_view==1 else 29.0 if _city_view==2 else
            23.0 if _city_view==3 else 20.0)
        camera.size=area/maxf(0.35,_zoom)
        var angle: float=deg_to_rad(
            41.0 if _city_view==0 else 0.0 if _city_view==1 else
            38.0 if _city_view==2 else 53.0 if _city_view==3 else
            90.0 if _city_view==4 else 180.0)
        var elevation: float=deg_to_rad(
            31.0 if _city_view in [1,4,5] else
            60.0 if _city_view==2 else 45.0)
        var distance: float=33.0
        var aim:=Vector3(0.0,3.85 if civilian_city_damage.selected<3
            else 1.0,0.0)
        camera.position=aim+Vector3(
            sin(angle)*cos(elevation)*distance,
            sin(elevation)*distance,
            cos(angle)*cos(elevation)*distance)
        camera.look_at(aim,Vector3.UP)
        return
    super._update_camera()

func _update_details() -> void:
    if _role=="civilian_city" and model_root!=null:
        var tier: int=int(model_root.get_meta("visual_level",1))
        var damage: int=int(model_root.get_meta("visual_damage_stage",0))
        var identity: String=(
            "Teja y madera" if tier==1 else
            "Piedra y ladrillo" if tier==2 else "Vidrio y aluminio")
        if detail_label!=null:
            detail_label.text=(
                "CIUDAD CIVIL V20 · %s · %d mallas reales" %
                [identity,Cities.drawable_count(model_root)])
        if status_label!=null:
            status_label.text=(
                "%s · daño %d/4 · facción %s · ARTE EN DISEÑO" %
                [str(CityBase.LABELS[tier-1]),damage,
                ("NEUTRAL" if civilian_city_faction.selected==0
                    else str(CityStyle.FACTIONS[
                        civilian_city_faction.selected-1]["name"]))])
        return
    super._update_details()
