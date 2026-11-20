extends "res://scripts/ui/PowerPlantStudioAdapterV1.gd"
class_name TarvokaArmoredWorkshopStudioAdapterV1

# Append the armored workshop to the existing EDIFICIOS 3D picker.
# Preserve HQ, Air Base, Naval Base, Infantry Barracks, civilian cities
# and Central Electrica. No replacement of prior approved model sources.
const WorkshopV1=preload("res://scripts/ui/ArmoredWorkshop3DV1.gd")
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")
const WorkshopMobile=preload("res://scripts/ui/ArmoredWorkshopMobileLOD3D.gd")
const WorkshopTile=preload("res://scripts/ui/ArmoredWorkshopBattleTile3D.gd")
const WorkshopFX=preload("res://scripts/ui/ArmoredWorkshopEvolutionVFX3D.gd")
const WorkshopLOD=preload("res://scripts/ui/ArmoredWorkshopLODPolicy.gd")
const WorkshopStyle=preload("res://scripts/ui/VisualStyle.gd")
const WORKSHOP_BUILDING_INDEX:int=6
var workshop_controls:VBoxContainer
var workshop_version:OptionButton
var workshop_view:OptionButton
var workshop_level:OptionButton
var workshop_faction:OptionButton
var workshop_damage:OptionButton
var workshop_info:Label
var _workshop_fx:TarvokaArmoredWorkshopEvolutionVFX3D
var _workshop_yaw:float=145.0
var _workshop_elevation:float=39.0
var _workshop_zoom:float=1.0

func _ready() -> void:
    super._ready()
    if building_picker==null or building_controls==null:
        push_error("TARVOKA: missing building selector for workshop")
        return
    if building_picker.item_count!=WORKSHOP_BUILDING_INDEX:
        push_error("TARVOKA: preserve six previous building entries")
        return
    building_picker.add_item("Taller de Blindados · V2 (diseño 3D)")
    building_picker.set_item_metadata(WORKSHOP_BUILDING_INDEX,"armored_workshop")
    _install_workshop_controls()

func _install_workshop_controls() -> void:
    workshop_controls=VBoxContainer.new()
    workshop_controls.name="TallerBlindadosControles3DV1"
    workshop_controls.visible=false
    workshop_controls.add_theme_constant_override("separation",5)
    building_controls.add_child(workshop_controls)
    var heading:=Label.new()
    heading.text="TALLER DE BLINDADOS · DISEÑO NATIVO 3D"
    heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(heading)
    var description:=Label.new()
    description.text="Instalacion fija; no reemplaza a unidades logisticas ni campamentos."
    description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(description)
    workshop_version=OptionButton.new()
    workshop_version.add_item("V1 · geometría original")
    workshop_version.add_item("V2 · acabados industriales")
    workshop_version.add_item("Android · táctico agrupado")
    workshop_version.add_item("Android · distante agrupado")
    workshop_version.add_item("Android · AUTOMÁTICO por zoom")
    workshop_version.select(1)
    workshop_controls.add_child(workshop_version)
    workshop_view=OptionButton.new()
    workshop_view.add_item("MODELO 3D COMPLETO")
    workshop_view.add_item("PRUEBA EN CASILLA 3D · 2,4 m")
    workshop_view.select(0)
    workshop_controls.add_child(workshop_view)
    workshop_level=OptionButton.new()
    workshop_level.name="TallerBlindadosSelectorN1N2N3"
    workshop_level.tooltip_text="Selecciona N1, N2 o N3 para cargar el modelo 3D completo"
    for title in Workshop.LEVEL_NAMES:
        workshop_level.add_item(str(title))
    workshop_level.select(1)
    workshop_controls.add_child(workshop_level)
    var level_row:=HFlowContainer.new()
    level_row.name="TallerBlindadosAccesoRapidoNiveles"
    workshop_controls.add_child(level_row)
    for index in range(3):
        var level_button:=Button.new()
        level_button.name="TallerBlindadosN%d" % (index+1)
        level_button.text="N%d · %d bahía%s" % [
            index+1,index+1,"s" if index>0 else ""]
        level_button.tooltip_text="Cargar y mostrar taller nivel N%d" % (index+1)
        level_button.pressed.connect(
            Callable(self,"_workshop_select_level").bind(index))
        level_row.add_child(level_button)
    # Immediate visual acknowledgement: visible next to N1/N2/N3 instead
    # of buried underneath camera and animation controls.
    workshop_info=Label.new()
    workshop_info.name="TallerBlindadosEstadoCarga"
    workshop_info.text="Selecciona N1, N2 o N3 para visualizar el modelo."
    workshop_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(workshop_info)
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
    for selector in [workshop_version,workshop_level,workshop_damage,workshop_faction]:
        selector.item_selected.connect(_on_workshop_change)
    workshop_view.item_selected.connect(_on_workshop_view_change)
    var camera_row:=HFlowContainer.new()
    workshop_controls.add_child(camera_row)
    # Same world-space convention as the standalone camera: front = -Z.
    for preset in [
            ["ISOMÉTRICA",145.0,39.0],["FRENTE",180.0,19.0],
            ["POSTERIOR",0.0,19.0],["LATERAL",90.0,22.0],
            ["COSTADO",270.0,22.0],["TECHO",37.0,78.0]]:
        var button:=Button.new()
        button.text=str(preset[0])
        button.pressed.connect(Callable(self,"_workshop_angle").bind(
            float(preset[1]),float(preset[2])))
        camera_row.add_child(button)
    var zoom_row:=HBoxContainer.new()
    workshop_controls.add_child(zoom_row)
    for action in [["ALEJAR",1.18],["ACERCAR",0.85],["ZOOM 100%",0.0]]:
        var zoom_button:=Button.new()
        zoom_button.text=str(action[0])
        zoom_button.pressed.connect(Callable(self,"_workshop_adjust_zoom").bind(
            float(action[1])))
        zoom_row.add_child(zoom_button)
    var effects_heading:=Label.new()
    effects_heading.text="EVOLUCIÓN / ATAQUES / DESTRUCCIÓN (PRUEBA VISUAL)"
    effects_heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    workshop_controls.add_child(effects_heading)
    var action_row:=HFlowContainer.new()
    workshop_controls.add_child(action_row)
    for action in [
            ["EVOLUCIONAR N+1","upgrade"],
            ["RECIBIR ATAQUE D+1","attack"],
            ["REPARACIÓN VISUAL D-1","repair"]]:
        var effect_button:=Button.new()
        effect_button.text=str(action[0])
        effect_button.pressed.connect(
            Callable(self,"_workshop_play_effect").bind(str(action[1])))
        action_row.add_child(effect_button)

func _workshop_show_controls_first() -> void:
    # This sidebar contains dozens of historical building controls. The
    # workshop must sit directly beneath the building picker while selected.
    # Restore the approved city's position when switching back.
    if workshop_controls!=null and building_controls!=null and (
            workshop_controls.get_parent()==building_controls):
        building_controls.move_child(workshop_controls,2)

func _workshop_restore_city_controls() -> void:
    if civilian_city_controls!=null and building_controls!=null and (
            civilian_city_controls.get_parent()==building_controls):
        building_controls.move_child(civilian_city_controls,2)

func _workshop_select_level(index:int) -> void:
    if workshop_level==null or index<0 or index>=workshop_level.item_count:
        return
    workshop_level.select(index)
    _on_workshop_change(index)

func _workshop_play_effect(kind:String) -> void:
    if _role!="armored_workshop" or _workshop_fx==null or _workshop_fx.busy:
        return
    match kind:
        "upgrade":
            _workshop_fx.play_upgrade()
        "attack":
            _workshop_fx.play_attack()
        "repair":
            _workshop_fx.play_repair()

func _workshop_stage_requested(level:int,damage:int) -> void:
    if _role!="armored_workshop":
        return
    workshop_level.select(level-1)
    workshop_damage.select(damage)
    _display_workshop()

func _workshop_sequence_complete(_kind:String,_level:int,_damage:int) -> void:
    if _workshop_fx!=null and workshop_level!=null:
        _workshop_fx.configure(workshop_level.selected+1,
            workshop_faction.selected-1,workshop_damage.selected,
            workshop_view.selected==1)
    if _role=="armored_workshop":
        _workshop_refresh_info()

func _on_workshop_change(_index:int) -> void:
    # Automatic LOD applies only to the battle-scale view, not to HERO.
    if workshop_version.selected==4 and workshop_view.selected==0:
        workshop_view.select(1)
    if workshop_view!=null and workshop_view.selected==1 and (
            workshop_version.selected<2):
        workshop_version.select(2)
    if _role=="armored_workshop":
        _display_workshop()

func _on_workshop_view_change(_index:int) -> void:
    if workshop_view.selected==1 and workshop_version.selected<2:
        workshop_version.select(2)
    if workshop_view.selected==0 and workshop_version.selected==4:
        workshop_version.select(1)
    _workshop_zoom=1.0
    if _role=="armored_workshop":
        _display_workshop()

func _workshop_angle(degrees:float,tilt:float=39.0) -> void:
    _workshop_yaw=fposmod(degrees,360.0)
    _workshop_elevation=tilt
    if _role=="armored_workshop":
        _update_camera()

func _workshop_adjust_zoom(factor:float) -> void:
    _workshop_zoom=1.0 if factor==0.0 else clampf(
        _workshop_zoom*factor,0.55,2.2)
    if _role=="armored_workshop":
        _update_camera()

func _change_selected_building(index:int) -> void:
    if index==WORKSHOP_BUILDING_INDEX and workshop_controls!=null:
        _workshop_show_controls_first()
        if plant_controls!=null:
            plant_controls.visible=false
        if civilian_city_controls!=null:
            civilian_city_controls.visible=false
        workshop_controls.visible=true
        _display_workshop()
        return
    if workshop_controls!=null:
        workshop_controls.visible=false
    _workshop_restore_city_controls()
    if _workshop_fx!=null:
        _workshop_fx.visible=false
    super._change_selected_building(index)

func _switch_category(index:int) -> void:
    super._switch_category(index)
    if workshop_controls==null or building_picker==null:
        return
    if index==1 and building_picker.selected==WORKSHOP_BUILDING_INDEX:
        _workshop_show_controls_first()
        if plant_controls!=null:
            plant_controls.visible=false
        if civilian_city_controls!=null:
            civilian_city_controls.visible=false
        workshop_controls.visible=true
        _display_workshop()
    else:
        workshop_controls.visible=false
        _workshop_restore_city_controls()
        if _workshop_fx!=null:
            _workshop_fx.visible=false

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
    if workshop_view!=null and workshop_view.selected==1:
        var profile:int=WorkshopMobile.PROFILE_DISTANT if (
            workshop_version.selected==3) else WorkshopMobile.PROFILE_TACTICAL
        model_root=WorkshopTile.build(level,faction,damage,profile)
    else:
        match workshop_version.selected:
            0:
                model_root=WorkshopV1.build(level,faction,damage)
            1:
                model_root=Workshop.build(level,faction,damage)
            2:
                model_root=WorkshopMobile.build(level,faction,damage,
                    WorkshopMobile.PROFILE_TACTICAL)
            _:
                model_root=WorkshopMobile.build(level,faction,damage,
                    WorkshopMobile.PROFILE_DISTANT)
    if model_root==null:
        push_error("TARVOKA: no se pudo cargar el Taller N%d D%d" % [
            level,damage])
        if workshop_info!=null:
            workshop_info.text="ERROR: no se pudo cargar N%d. Selecciona otro nivel." % level
        if status_label!=null:
            status_label.text="Taller N%d no disponible: error de carga 3D" % level
        return
    # The nine-tile preview has a canonical root name required by the
    # zoom/LOD policy. Never rename it or automatic detail swaps will fail.
    if workshop_view==null or workshop_view.selected==0:
        model_root.name="TallerBlindados_Visible_N%d_F%d_D%d" % [
            level,faction,damage]
    preview.add_child(model_root)
    if _workshop_fx==null:
        _workshop_fx=WorkshopFX.new()
        _workshop_fx.name="FX_EvolucionAtaquesYDestruccionTaller"
        preview.add_child(_workshop_fx)
        _workshop_fx.stage_requested.connect(_workshop_stage_requested)
        _workshop_fx.sequence_finished.connect(_workshop_sequence_complete)
    _workshop_fx.visible=true
    _workshop_fx.configure(level,faction,damage,
        workshop_view!=null and workshop_view.selected==1)
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
    _workshop_refresh_info()

func _workshop_refresh_info() -> void:
    if model_root==null or workshop_info==null or workshop_level==null:
        return
    var mobile_profile:int=int(model_root.get_meta("workshop_lod_profile",0))
    var geometry_info:String="%d lotes GPU · %d cajas agrupadas" % [
        int(model_root.get_meta("workshop_batches",0)),
        int(model_root.get_meta("workshop_instances",0))
    ] if mobile_profile>0 else "%d mallas 3D HERO" % Workshop.mesh_count(model_root)
    var map_view:bool=workshop_view!=null and workshop_view.selected==1
    var context:String=" · casilla 2,4 m · 9 piezas de terreno" if map_view else ""
    if map_view and workshop_version.selected==4:
        var px:float=WorkshopLOD.projected_width(
            camera,Vector3(0,0.3,0),2.17)
        var detail:String="TÁCTICO" if mobile_profile==WorkshopMobile.PROFILE_TACTICAL else "DISTANTE"
        context+=" · AUTO %d px → %s" % [int(roundf(px)),detail]
    workshop_info.text="MODELO 3D CARGADO · N%d · %s · D%d · %d bahías · %s%s" % [
        workshop_level.selected+1,
        Workshop.LEVEL_NAMES[workshop_level.selected],
        workshop_damage.selected,
        int(model_root.get_meta("workshop_bays",0)),geometry_info,context]

func _workshop_auto_lod() -> void:
    if model_root==null or workshop_view==null or workshop_version==null:
        return
    if workshop_view.selected!=1 or workshop_version.selected!=4:
        return
    var projected_px:float=WorkshopLOD.projected_width(
        camera,Vector3(0,0.3,0),2.17)
    var previous:int=int(model_root.get_meta("workshop_lod_profile",
        WorkshopMobile.PROFILE_TACTICAL))
    var next_profile:int=WorkshopLOD.choose_mobile(projected_px,previous)
    if next_profile!=previous:
        if not WorkshopTile.set_preview_detail(model_root,next_profile):
            push_error("TARVOKA: automated workshop zoom LOD swap failed")
            return
    _workshop_refresh_info()

func _update_camera() -> void:
    if _role=="armored_workshop" and camera!=null and workshop_level!=null:
        var level:int=workshop_level.selected+1
        var yaw:float=deg_to_rad(_workshop_yaw)
        var elevation:float=deg_to_rad(_workshop_elevation)
        if workshop_view!=null and workshop_view.selected==1:
            var center:=Vector3(0,0.32,0)
            var mobile_distance:float=19.0
            camera.projection=Camera3D.PROJECTION_ORTHOGONAL
            camera.size=9.60*_workshop_zoom
            camera.position=center+Vector3(
                sin(yaw)*cos(elevation)*mobile_distance,
                sin(elevation)*mobile_distance,
                cos(yaw)*cos(elevation)*mobile_distance)
            camera.look_at(center,Vector3.UP)
            _workshop_auto_lod()
            return
        var distance:float=36.0 if level==1 else 45.0 if level==2 else 56.0
        var focus:=Vector3(0,2.2 if level==1 else 3.0 if level==2 else 3.5,0)
        camera.projection=Camera3D.PROJECTION_ORTHOGONAL
        camera.size=(22.0 if level==1 else 30.0 if level==2 else 39.0)*_workshop_zoom
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
            studio_overview_label.text="EDIFICIOS · TALLER DE BLINDADOS · PRUEBA DE MAPA 3D" if (
                workshop_view!=null and workshop_view.selected==1) else (
                "EDIFICIOS · TALLER DE BLINDADOS V1 / V2 EN DISEÑO")
        if status_label!=null and workshop_level!=null:
            status_label.text="%s · D%d · arte 3D; logistica movil independiente" % [
                Workshop.LEVEL_NAMES[workshop_level.selected],workshop_damage.selected]
        return
    super._update_details()
