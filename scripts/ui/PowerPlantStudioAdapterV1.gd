extends "res://scripts/ui/CivilianCityStudioAdapter.gd"
class_name TarvokaPowerPlantStudioAdapterV1

# Preserve the four established military building models and civil cities.
# Add one new independent selectable native Power Plant, ART ONLY.
const Plant=preload("res://scripts/ui/PowerPlant3DV2.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const POWER_BUILDING_INDEX: int=5
var plant_controls: VBoxContainer
var plant_level: OptionButton
var plant_faction: OptionButton
var plant_damage: OptionButton
var plant_info: Label
var _plant_yaw: float=37.0

func _ready() -> void:
    super._ready()
    if building_picker==null or building_controls==null:
        return
    if building_picker.item_count!=POWER_BUILDING_INDEX:
        push_error("TARVOKA Central: building picker changed; preserve approved entries")
        return
    building_picker.add_item("Central eléctrica · V2 (diseño 3D)")
    building_picker.set_item_metadata(POWER_BUILDING_INDEX,"power_plant")
    _install_plant_controls()

func _install_plant_controls() -> void:
    plant_controls=VBoxContainer.new()
    plant_controls.name="CentralElectricaControles3D_V1"
    plant_controls.visible=false
    plant_controls.add_theme_constant_override("separation",6)
    building_controls.add_child(plant_controls)
    var heading:=Label.new()
    heading.text="CENTRAL ELÉCTRICA V2 · CONEXIONES INDUSTRIALES 3D"
    heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    plant_controls.add_child(heading)
    plant_level=OptionButton.new()
    for name in Plant.LEVEL_NAMES:
        plant_level.add_item(str(name))
    plant_level.select(1)
    plant_controls.add_child(plant_level)
    plant_damage=OptionButton.new()
    for label in Plant.DAMAGE_NAMES:
        plant_damage.add_item(str(label))
    plant_damage.select(0)
    plant_controls.add_child(plant_damage)
    plant_faction=OptionButton.new()
    plant_faction.add_item("Neutral")
    for faction in Style.FACTIONS:
        plant_faction.add_item(str(faction["name"]))
    plant_faction.select(0)
    plant_controls.add_child(plant_faction)
    for pick in [plant_level,plant_damage,plant_faction]:
        pick.item_selected.connect(_on_plant_change)
    var angles:=HFlowContainer.new()
    plant_controls.add_child(angles)
    for data in [["ISOMÉTRICA",37.0],["FRENTE",0.0],
            ["LATERAL",90.0],["POSTERIOR",180.0],["OTRO COSTADO",270.0]]:
        var button:=Button.new()
        button.text=str(data[0])
        button.pressed.connect(Callable(self,"_plant_angle").bind(float(data[1])))
        angles.add_child(button)
    plant_info=Label.new()
    plant_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    plant_controls.add_child(plant_info)

func _on_plant_change(_index: int) -> void:
    if _role=="power_plant":
        _display_power_plant()

func _plant_angle(yaw: float) -> void:
    _plant_yaw=fposmod(yaw,360.0)
    _yaw=_plant_yaw
    if _role=="power_plant" and model_root!=null:
        model_root.rotation_degrees.y=_plant_yaw
        _update_camera()

func _change_selected_building(index: int) -> void:
    if index==POWER_BUILDING_INDEX and plant_controls!=null:
        if civilian_city_controls!=null:
            civilian_city_controls.visible=false
        plant_controls.visible=true
        _display_power_plant()
        return
    if plant_controls!=null:
        plant_controls.visible=false
    super._change_selected_building(index)

func _switch_category(index: int) -> void:
    super._switch_category(index)
    if plant_controls==null or building_picker==null:
        return
    if index==1 and building_picker.selected==POWER_BUILDING_INDEX:
        plant_controls.visible=true
        _display_power_plant()
    else:
        plant_controls.visible=false

func _display_power_plant() -> void:
    if plant_level==null or plant_faction==null or plant_damage==null or preview==null:
        return
    _stop_animation()
    if model_root!=null:
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root=null
    _role="power_plant"
    var level: int=plant_level.selected+1
    var faction: int=plant_faction.selected-1
    var damage: int=plant_damage.selected
    model_root=Plant.build(level,faction,damage)
    if model_root==null:
        push_error("TARVOKA: central eléctrica nativa sin geometría")
        return
    preview.add_child(model_root)
    model_root.rotation_degrees.y=_plant_yaw
    if hq_ground!=null:
        hq_ground.visible=false
    if hq_climate_stage!=null:
        hq_climate_stage.visible=false
    if hq_map_lod_toggle!=null:
        hq_map_lod_toggle.visible=false
    if faction_picker!=null:
        faction_picker.visible=false
    if civilian_city_controls!=null:
        civilian_city_controls.visible=false
    plant_controls.visible=true
    _update_camera()
    _update_details()
    _refresh_unified_studio_navigation()
    plant_info.text="N%d · D%d · %d mallas · diseño V2, pendiente acabado final" % [
        level,damage,Plant.mesh_count(model_root)]
    if studio_overview_label!=null:
        studio_overview_label.text="EDIFICIOS · CENTRAL ELÉCTRICA V2 EN DISEÑO"

func _update_camera() -> void:
    if _role=="power_plant" and camera!=null and plant_level!=null:
        var level: int=plant_level.selected+1
        var height: float=2.3 if level==1 else 3.9 if level==2 else 5.9
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=17.0 if level==1 else 23.0 if level==2 else 30.0
        var azimuth: float=deg_to_rad(_plant_yaw)
        var elevation: float=deg_to_rad(43.0)
        var radius: float=34.0
        var focus:=Vector3(0,height*0.40,0)
        camera.position=focus+Vector3(
            sin(azimuth)*cos(elevation)*radius,
            sin(elevation)*radius,
            cos(azimuth)*cos(elevation)*radius)
        camera.look_at(focus,Vector3.UP)
        return
    super._update_camera()

func _update_details() -> void:
    if _role=="power_plant":
        if studio_overview_label!=null:
            studio_overview_label.text="CENTRAL ELÉCTRICA · V2 · EDIFICIO EN DISEÑO"
        if status_label!=null and plant_level!=null:
            status_label.text="Central eléctrica N%d · D%d · arte 3D, sin energía programada" % [
                plant_level.selected+1,plant_damage.selected]
        return
    super._update_details()
