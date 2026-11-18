extends "res://scripts/ui/BastionStudioAdapter.gd"
class_name TarvokaCivilianCityStudioAdapter

# Add unfinished CIVILIAN CITIES to the ACTUAL unified studio's
# EDIFICIOS picker. All existing HQ, airbase, naval base, barracks and
# military units retain their original controls, models and animations.
# Native Godot meshes; no iframes, external links or screenshot proxies.
const Cities=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const CityBase=preload("res://scripts/ui/CivilianCity3DV1.gd")
const CityMaterials=preload("res://scripts/ui/CivilianCityDamageContinuityV36.gd")
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
    building_picker.add_item("Ciudades civiles · Villa / Ciudad / Metrópoli · V36")
    building_picker.set_item_metadata(CITY_BUILDING_INDEX,"civilian_city")
    _install_city_options()
    _refresh_unified_studio_navigation()

func _install_city_options() -> void:
    civilian_city_controls=VBoxContainer.new()
    civilian_city_controls.name="Edificios_Ciudades_Civiles_V31"
    civilian_city_controls.add_theme_constant_override("separation",6)
    civilian_city_controls.visible=false
    building_controls.add_child(civilian_city_controls)
    _title(civilian_city_controls,
        "CIUDAD CIVIL · V31 · MODELO 3D EN DISEÑO",14)
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
    var tier_shortcuts:=HFlowContainer.new()
    tier_shortcuts.name="Ciudades_V31_Comparar_Escalas"
    civilian_city_controls.add_child(tier_shortcuts)
    for data in [["VILLA",0],["CIUDAD",1],["METRÓPOLI",2]]:
        var shortcut:=Button.new()
        shortcut.text=str(data[0])
        shortcut.custom_minimum_size=Vector2(93,32)
        shortcut.pressed.connect(
            Callable(self,"_city_choose_tier").bind(int(data[1])))
        tier_shortcuts.add_child(shortcut)
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
        ["COSTADO",4],["POSTERIOR",5],
        ["PUERTAS",6],["VENTANAS",7],["TEJADOS",8],
        ["OESTE",9],["D2 TECHO ROTO",10],["D3 MUROS",11],["D4 ESCOMBROS",12],
        ["D2 APOYOS",13],["D3 INTERIOR",14],["D4 CIMIENTOS",15],
        ["V25 BORDES",16],["V26 MATERIALES",17],["D1 DESGASTE",18],
        ["V27 PORTALES",19],["V27 PASAJES",20],["V27 PLAZA",21],
        ["V28 NORTE",22],["V28 SUR",23],["V28 ESTE",24],["V28 OESTE",25],
        ["V29 UNIONES",26],["V29 D2 CUBIERTA",27],
        ["V29 D3 INTERIOR",28],["V29 D4 RESTOS",29],
        ["V30 VILLA",30],["V30 CIUDAD",31],["V30 METRO",32],
        ["V30 D2",33],["V30 D4",34],
        ["V31 CERCA",35],["V31 TÁCTICA",36],["V31 LEJANA",37],
        ["V32 CUBIERTA",38],["V32 FACHADA",39],
        ["V32 D2 BORDE",40],["V32 D3 INTERIOR",41],
        ["V32 D4 RESTOS",42],
        ["V33 TEJAS",43],["V33 PIEDRA",44],
        ["V33 METAL",45],["V33 D2 CORTE",46],
        ["V33 D4 RUINAS",47],
        ["V34 ENTRADAS",48],["V34 PASAJES",49],
        ["V34 PLAZA",50],["V34 MUNICIPAL",51],
        ["V34 D4 BORDES",52],
        ["V35 NORTE",53],["V35 SUR",54],
        ["V35 ESTE",55],["V35 OESTE",56],
        ["V35 D2 ESQUINA",57],["V35 D4 BASE",58],
        ["V36 D0 NUEVA",59],["V36 D1 USADA",60],
        ["V36 D2 ROTA",61],["V36 D3 ABIERTA",62],
        ["V36 D4 ESCOMBROS",63]
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
        "ARTE V36 · SOLO VISUAL · Sin modificaciones de jugabilidad",12)
    civilian_city_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _city_choose_tier(index: int) -> void:
    if civilian_city_tier==null:
        return
    civilian_city_tier.select(clampi(index,0,2))
    if _role=="civilian_city":
        _display_civilian_city()

func _on_city_option(_index: int) -> void:
    if _role=="civilian_city":
        _display_civilian_city()

func _city_camera_preset(index: int) -> void:
    if civilian_city_tier==null:
        return
    _city_view=clampi(index,0,63)
    if civilian_city_lod!=null and _city_view in [59,60,61,62,63]:
        civilian_city_lod.select(0)
    if _city_view in [43,44,45]:
        civilian_city_tier.select(_city_view-43)
    if civilian_city_lod!=null and _city_view in [38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58]:
        civilian_city_lod.select(0)
    if civilian_city_lod!=null and _city_view in [35,36,37]:
        civilian_city_lod.select(_city_view-35)
    if _city_view in [30,31,32]:
        civilian_city_tier.select(_city_view-30)
    if civilian_city_damage!=null:
        if _city_view in [10,13,16,27,33,40,46,57,61]:
            civilian_city_damage.select(2)
        elif _city_view in [18,39,60]:
            civilian_city_damage.select(1)
        elif _city_view in [26,30,31,32,38,43,44,45,48,49,50,51,53,54,55,56,59]:
            civilian_city_damage.select(0)
        elif _city_view in [3,11,14,28,41,62]:
            civilian_city_damage.select(3)
        elif _city_view in [12,15,29,34,42,47,52,58,63]:
            civilian_city_damage.select(4)
    _yaw=35.0 if _city_view==0 else 0.0
    # Preserve the V31 zoom tiers with ordinary Godot control flow.
    # The previous multiline ternary ended after 'else' and failed to parse.
    _zoom=1.05
    if _city_view in [1,4,5,9]:
        _zoom=1.45
    elif _city_view in [19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58]:
        _zoom=1.23
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
        push_error("Ciudad V31: no fue posible construir mallas de Godot")
        return
    preview.add_child(model_root)
    model_root.name="EDIFICIO_CIUDAD_CIVIL_V31_N%d_D%d" % [level,damage]
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
        studio_overview_label.text="EDIFICIOS · CIUDAD CIVIL V36 · EN DISEÑO"

func _update_camera() -> void:
    if _role=="civilian_city":
        if camera==null:
            return
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        var area: float=25.0 if _city_view==0 else (
            17.5 if _city_view==1 else 29.0 if _city_view==2 else
            23.0 if _city_view in [3,11,12] else
            20.0 if _city_view in [4,5,9] else
            12.5 if _city_view in [13,16,17,18] else
            9.8 if _city_view==19 else 11.0 if _city_view==20 else
            11.7 if _city_view==21 else
            11.9 if _city_view in [22,23,24,25] else
            9.6 if _city_view in [26,27] else
            10.5 if _city_view in [28,29] else
            14.5 if _city_view in [30,31,32] else
            10.8 if _city_view in [33,34] else
            12.5 if _city_view in [38,39] else
            11.2 if _city_view in [40,41,42] else
            12.0 if _city_view in [43,44,45,46] else
            11.4 if _city_view==47 else
            10.6 if _city_view in [48,49,50,51] else
            12.2 if _city_view==52 else
            22.0 if _city_view in [53,54,55,56] else
            12.5 if _city_view in [57,58] else
            18.0 if _city_view in [59,60,61,62,63] else
            24.0 if _city_view==35 else
            27.0 if _city_view==36 else
            30.0 if _city_view==37 else
            10.0 if _city_view in [14,15] else
            8.2 if _city_view==6 else 10.0 if _city_view==7 else
            13.0 if _city_view==8 else 24.0)
        camera.size=area/maxf(0.35,_zoom)
        var angle: float=deg_to_rad(
            41.0 if _city_view==0 else 0.0 if _city_view in [1,6,7] else
            38.0 if _city_view in [2,8] else
            53.0 if _city_view in [3,10,11,12,15] else
            42.0 if _city_view in [13,16,17,18] else
            38.0 if _city_view==19 else 112.0 if _city_view==20 else
            -40.0 if _city_view==21 else
            180.0 if _city_view==22 else
            0.0 if _city_view==23 else
            90.0 if _city_view==24 else
            -90.0 if _city_view==25 else
            -35.0 if _city_view==26 else
            47.0 if _city_view==27 else
            130.0 if _city_view==28 else
            -117.0 if _city_view==29 else
            36.0 if _city_view in [30,31,32] else
            -33.0 if _city_view==33 else
            133.0 if _city_view==34 else
            38.0 if _city_view in [35,36,37] else
            -38.0 if _city_view in [38,40] else
            20.0 if _city_view==39 else
            135.0 if _city_view==41 else
            -116.0 if _city_view==42 else
            -36.0 if _city_view in [43,44,45,46] else
            128.0 if _city_view==47 else
            0.0 if _city_view==48 else
            42.0 if _city_view==49 else
            -36.0 if _city_view==50 else
            0.0 if _city_view==51 else
            137.0 if _city_view==52 else
            180.0 if _city_view==53 else
            0.0 if _city_view==54 else
            90.0 if _city_view==55 else
            -90.0 if _city_view==56 else
            47.0 if _city_view==57 else
            -113.0 if _city_view==58 else
            35.0 if _city_view in [59,60,61,62,63] else
            128.0 if _city_view==14 else
            90.0 if _city_view==4 else -90.0 if _city_view==9 else 180.0)
        var elevation: float=deg_to_rad(
            25.0 if _city_view==6 else 32.0 if _city_view==7 else
            63.0 if _city_view in [2,8] else
            56.0 if _city_view==10 else 52.0 if _city_view in [13,16,17] else
            39.0 if _city_view==18 else
            32.0 if _city_view==19 else
            46.0 if _city_view==20 else
            43.0 if _city_view==21 else
            30.0 if _city_view in [22,23,24,25] else
            44.0 if _city_view==26 else
            56.0 if _city_view==27 else
            48.0 if _city_view==28 else
            36.0 if _city_view==29 else
            51.0 if _city_view in [30,31,32] else
            58.0 if _city_view==33 else
            36.0 if _city_view==34 else
            55.0 if _city_view in [35,36,37] else
            56.0 if _city_view in [38,40] else
            27.0 if _city_view==39 else
            46.0 if _city_view==41 else
            35.0 if _city_view==42 else
            52.0 if _city_view in [43,44,45] else
            62.0 if _city_view==46 else
            39.0 if _city_view==47 else
            27.0 if _city_view==48 else
            45.0 if _city_view in [49,50] else
            31.0 if _city_view==51 else
            38.0 if _city_view==52 else
            34.0 if _city_view in [53,54,55,56] else
            57.0 if _city_view==57 else
            37.0 if _city_view==58 else
            45.0 if _city_view in [59,60,61,62,63] else
            43.0 if _city_view==14 else 50.0 if _city_view==15 else
            31.0 if _city_view in [1,4,5,9] else 45.0)
        var distance: float=33.0
        var city_tier: int=civilian_city_tier.selected+1
        var roof_height: float=(2.31 if city_tier==1 else
            6.51 if city_tier==2 else 10.71)
        var aim:=Vector3(
            4.63 if _city_view in [6,7,8,13,14,15,16,17,18] else 0.0,
            (roof_height-0.20 if _city_view in [13,16,17] else
            1.50 if _city_view==18 else
            0.86 if _city_view==14 else 0.20 if _city_view==15 else
            1.1 if _city_view==6 else
            3.05 if _city_view==7 else
            roof_height if _city_view==8 else
            3.85 if civilian_city_damage.selected<3 else 1.0),
            2.24 if _city_view==6 else
            3.62 if _city_view in [7,8,13,14,15,16,17,18] else 0.0)
        if _city_view==19:
            aim=Vector3(4.63,0.46,-1.79)
        elif _city_view==20:
            aim=Vector3(2.47,0.31,1.46)
        elif _city_view==21:
            aim=Vector3(0.0,0.34,2.80)
        if _city_view==22:
            aim=Vector3(4.63,roof_height*0.48,-3.80)
        elif _city_view==23:
            aim=Vector3(4.63,roof_height*0.48,3.62)
        elif _city_view==24:
            aim=Vector3(4.63,roof_height*0.48,3.62)
        elif _city_view==25:
            aim=Vector3(-4.63,roof_height*0.48,-3.80)
        elif _city_view==26:
            aim=Vector3(4.63,roof_height*0.74,3.62)
        elif _city_view==27:
            aim=Vector3(4.63,roof_height*0.86,3.62)
        elif _city_view==28:
            aim=Vector3(4.63,0.80,3.62)
        elif _city_view==29:
            aim=Vector3(4.63,0.18,3.62)
        elif _city_view in [30,31,32]:
            aim=Vector3(4.63,roof_height*0.74,3.62)
        elif _city_view==33:
            aim=Vector3(4.63,roof_height*0.85,3.62)
        elif _city_view==34:
            aim=Vector3(4.63,0.18,3.62)
        elif _city_view in [35,36,37]:
            aim=Vector3(0.0,2.0 if civilian_city_damage.selected<3 else 0.55,0.0)
        elif _city_view in [38,40]:
            aim=Vector3(4.63,roof_height*0.84,3.62)
        elif _city_view==39:
            aim=Vector3(4.63,roof_height*0.49,3.62)
        elif _city_view==41:
            aim=Vector3(4.63,0.68,3.62)
        elif _city_view==42:
            aim=Vector3(4.63,0.18,3.62)
        elif _city_view in [43,44,45,46]:
            aim=Vector3(4.63,roof_height*0.85,3.62)
        elif _city_view==47:
            aim=Vector3(4.63,0.16,3.62)
        elif _city_view==48:
            aim=Vector3(4.63,0.20,-1.82)
        elif _city_view==49:
            aim=Vector3(2.47,0.15,1.39)
        elif _city_view==50:
            aim=Vector3(0.0,0.16,2.79)
        elif _city_view==51:
            aim=Vector3(0.0,0.16,-1.55)
        elif _city_view==52:
            aim=Vector3(2.47,0.16,1.39)
        elif _city_view in [53,54,55,56]:
            aim=Vector3(0.0,2.7 if civilian_city_damage.selected<3 else 0.63,0.0)
        elif _city_view==57:
            aim=Vector3(4.63,roof_height*0.78,3.62)
        elif _city_view==58:
            aim=Vector3(4.63,0.20,3.62)
        elif _city_view in [59,60,61,62,63]:
            # Exactly the same position/size for D0-D4 comparison.
            aim=Vector3(4.63,roof_height*0.38,3.62)
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
                "CIUDAD CIVIL V36 · %s · %d mallas · %d acabados progresivos D%d" %
                [identity,Cities.drawable_count(model_root),
                    int(model_root.get_meta("city_v36_materials_harmonized",0)),
                    damage])
        if status_label!=null:
            status_label.text=(
                "%s · daño %d/4 · facción %s · ARTE EN DISEÑO" %
                [str(CityBase.LABELS[tier-1]),damage,
                ("NEUTRAL" if civilian_city_faction.selected==0
                    else str(CityStyle.FACTIONS[
                        civilian_city_faction.selected-1]["name"]))])
        return
    super._update_details()
