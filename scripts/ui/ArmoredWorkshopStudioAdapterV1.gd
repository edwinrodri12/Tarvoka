extends "res://scripts/ui/PowerPlantStudioAdapterV1.gd"
class_name TarvokaArmoredWorkshopStudioAdapterV1

# Append the armored workshop to the existing EDIFICIOS 3D picker.
# Preserve HQ, Air Base, Naval Base, Infantry Barracks, civilian cities
# and Central Electrica. No replacement of prior approved model sources.
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const WorkshopStyle=preload("res://scripts/ui/VisualStyle.gd")
const WORKSHOP_BUILDING_INDEX:int=6
var workshop_controls:VBoxContainer
var workshop_level:OptionButton
var workshop_faction:OptionButton
var workshop_damage:OptionButton
var workshop_info:Label
var _workshop_yaw:float=37.0

func _ready() -> void:
    super._ready()
    if building_picker==null or building_controls==null:
        push_error("TARVOKA: missing building selector for workshop")
        return
    if building_picker.item_count!=WORKSHOP_BUILDING_INDEX:
        push_error("TARVOKA: preserve six previous building entries")
        return
    building_picker.add_item("Taller de Blindados · V1 (diseño 3D)")
    building_picker.set_item_metadata(WORKSHOP_BUILDING_INDEX,"armored_workshop")
    _install_workshop_controls()

func _install_workshop_controls() -> void:
    workshop_controls=VBoxContainer.new()
    workshop_controls.name="TallerBlindadosControles3DV1"
    workshop_controls.visible=false
    workshop_controls.add_theme_constant_override("separation",5)
    building_controls.add_child(workshop_controls)
    var heading:=Label.new()
    heading.text="TALLER DE BLINDADOS V1 · MODELO 3D NATIVO"
    heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(heading)
    var description:=Label.new()
    description.text="Instalacion fija; no reemplaza a unidades logisticas ni campamentos."
    description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(description)
    workshop_level=OptionButton.new()
    for title in Workshop.LEVEL_NAMES:
        workshop_level.add_item(str(title))
    workshop_level.select(1)
    workshop_controls.add_child(workshop_level)
    workshop_damage=OptionButton.new()
    for title in Workshop.DAMAGE_NAMES:
        workshop_damage.add_item(str(title))
    workshop_damage.select(0)
    workshop_controls.add_child(workshop_damage)
    workshop_faction=OptionButton.new()
    workshop_faction.add_item("Neutral")
    for info in WorkshopStyle.FACTIONS:
        workshop_faction.add_item(str(info["name"]))
    workshop_faction.select(0)
    workshop_controls.add_child(workshop_faction)
    for selector in [workshop_level,workshop_damage,workshop_faction]:
        selector.item_selected.connect(_on_workshop_change)
    var camera_row:=HFlowContainer.new()
    workshop_controls.add_child(camera_row)
    for preset in [
            ["ISOMÉTRICA",37.0],["FRENTE",0.0],["LATERAL",90.0],
            ["POSTERIOR",180.0],["OTRO LADO",270.0],["AZOTEA",45.0]]:
        var button:=Button.new()
        button.text=str(preset[0])
        button.pressed.connect(Callable(self,"_workshop_angle").bind(float(preset[1])))
        camera_row.add_child(button)
    workshop_info=Label.new()
    workshop_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(workshop_info)

func _on_workshop_change(_index:int) -> void:
    if _role=="armored_workshop":
        _display_workshop()

func _workshop_angle(degrees:float) -> void:
    _workshop_yaw=fposmod(degrees,360.0)
    if _role=="armored_workshop":
        _update_camera()

func _change_selected_building(index:int) -> void:
    if index==WORKSHOP_BUILDING_INDEX and workshop_controls!=null:
        if plant_controls!=null:
            plant_controls.visible=false
        if civilian_city_controls!=null:
            civilian_city_controls.visible=false
        workshop_controls.visible=true
        _display_workshop()
        return
    if workshop_controls!=null:
        workshop_controls.visible=false
    super._change_selected_building(index)

func _switch_category(index:int) -> void:
    super._switch_category(index)
    if workshop_controls==null or building_picker==null:
        return
    if index==1 and building_picker.selected==WORKSHOP_BUILDING_INDEX:
        if plant_controls!=null:
            plant_controls.visible=false
        if civilian_city_controls!=null:
            civilian_city_controls.visible=false
        workshop_controls.visible=true
        _display_workshop()
    else:
        workshop_controls.visible=false

func _display_workshop() -> void:
    if workshop_level==null or workshop_faction==null or workshop_damage==null or preview==null:
        return
    _stop_animation()
    if model_root!=null:
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root=null
    _role="armored_workshop"
    var level:int=workshop_level.selected+1
    var faction:int=workshop_faction.selected-1
    var damage:int=workshop_damage.selected
    model_root=Workshop.build(level,faction,damage)
    if model_root==null:
        push_error("TARVOKA: workshop native 3D geometry failed")
        return
    preview.add_child(model_root)
    if hq_ground!=null:
        hq_ground.visible=false
    if hq_climate_stage!=null:
        hq_climate_stage.visible=false
    if hq_map_lod_toggle!=null:
        hq_map_lod_toggle.visible=false
    if faction_picker!=null:
        faction_picker.visible=false
    if plant_controls!=null:
        plant_controls.visible=false
    if civilian_city_controls!=null:
        civilian_city_controls.visible=false
    workshop_controls.visible=true
    _update_camera()
    _update_details()
    _refresh_unified_studio_navigation()
    workshop_info.text="%s · D%d · %d bahías · %d mallas 3D · pendiente revisión artística" % [
        Workshop.LEVEL_NAMES[level-1],damage,int(model_root.get_meta("workshop_bays",0)),
        Workshop.mesh_count(model_root)]

func _update_camera() -> void:
    if _role=="armored_workshop" and camera!=null and workshop_level!=null:
        var level:int=workshop_level.selected+1
        var yaw:float=deg_to_rad(_workshop_yaw)
        var elevation:float=deg_to_rad(38.0)
        var distance:float=36.0 if level==1 else 45.0 if level==2 else 56.0
        var focus:=Vector3(0,2.2 if level==1 else 3.0 if level==2 else 3.5,0)
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=22.0 if level==1 else 30.0 if level==2 else 39.0
        camera.position=focus+Vector3(
            sin(yaw)*cos(elevation)*distance,
            sin(elevation)*distance,
            cos(yaw)*cos(elevation)*distance)
        camera.look_at(focus,Vector3.UP)
        return
    super._update_camera()

func _update_details() -> void:
    if _role=="armored_workshop":
        if studio_overview_label!=null:
            studio_overview_label.text="EDIFICIOS · TALLER DE BLINDADOS V1 EN DISEÑO"
        if status_label!=null and workshop_level!=null:
            status_label.text="%s · D%d · arte 3D; logistica movil independiente" % [
                Workshop.LEVEL_NAMES[workshop_level.selected],workshop_damage.selected]
        return
    super._update_details()
