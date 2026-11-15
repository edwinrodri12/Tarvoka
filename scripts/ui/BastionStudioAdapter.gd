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
const P06Audio = preload("res://scripts/ui/APCWeaponAudioV8.gd")
const P06Tactical = preload("res://scripts/ui/APCTacticalLOD8.gd")
const G11Art = preload("res://scripts/ui/G11Art3D.gd")
const G11Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const G11Atmos = preload("res://scripts/ui/G11DamageAtmosphereV7.gd")
const P06Stages := [
    "Intacto","Impactos leves","Daño moderado","Daño crítico","Destruido"
]

var p06_controls: VBoxContainer
var p06_hint: Label
var p06_version_button: Button
var p06_ramp_button: Button
var _p06_show_v5: bool = true
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
var g11_controls: VBoxContainer
var _g11_animation: String = ""
var _g11_time: float = 0.0
var _g11_playback_speed: float = 1.0
var _g11_fx_clock: float = 0.0

func _ready() -> void:
    super._ready()
    _install_p06_controls()
    _install_g11_controls()
    var g11_index: int = P06Models.ROLES.find("mlrs")
    if g11_index >= 0:
        role_picker.set_item_text(g11_index,"G11 Lanzador · V15 bastidor y paneles traseros")
    var idx: int = P06Models.ROLES.find("apc")
    if idx >= 0:
        role_picker.set_item_text(idx,"Bastión P06 · V18 pasos de rueda y daños · 6×6")
    # The project home link now opens the model under review rather than
    # showing the old default G09 first and confusing Android users.
    _display_role("apc")

func _install_p06_controls() -> void:
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    p06_controls = VBoxContainer.new()
    p06_controls.name = "BastionP06_V18_PasosRueda"
    p06_controls.add_theme_constant_override("separation",8)
    column.add_child(p06_controls)
    var heading: Label = _title(p06_controls,
        "BASTIÓN P06 · V18 · PASOS RUEDA Y BLINDAJE DAÑADO",14)
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
    _add_paired(p06_controls,"Vista inferior completa",_inspect_p06_underside,
        "Acercamiento a transmisión",_inspect_p06_transfer)
    _add_paired(p06_controls,"Vista 3/4 trasera",func(): _view_p06_angle(145.0),
        "Rampa y compartimento",func(): _view_p06_angle(180.0))
    p06_ramp_button = _button(p06_controls,"Abrir rampa de tropas",
        _toggle_p06_ramp)
    _add_paired(p06_controls,"Destrucción",func(): _set_damage(4),
        "Reparar completamente",func(): _set_damage(0))
    p06_version_button = _button(p06_controls,"Comparar acabado V3 / V18",
        _toggle_p06_version)
    _add_paired(p06_controls,
        "Prueba 8 vehículos",func(): _show_p06_fleet(8),
        "Prueba 32 vehículos",func(): _show_p06_fleet(32))
    _add_paired(p06_controls,
        "Prueba 64 vehículos",func(): _show_p06_fleet(64),
        "Volver al Bastión V18",_hide_p06_fleet)
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
        "V18: faldones 3D entre los tres ejes, guardapolvos interiores separados "
        + "de las seis ruedas móviles y blindaje lateral que se rompe por etapas. "
        + "Conserva transmisión V15, cierres V16/V17 y reparación completa.",12)
    var index: int = column.get_children().find(detail_label)
    column.move_child(p06_controls,maxi(0,index))
    p06_controls.visible = false

func _install_g11_controls() -> void:
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    g11_controls = VBoxContainer.new()
    g11_controls.name = "G11_Lanzador_V1_EstudioReal"
    g11_controls.add_theme_constant_override("separation",8)
    column.add_child(g11_controls)
    var heading: Label = _title(g11_controls,
        "G11 LANZADOR · ESCULTURA POSTERIOR V15",14)
    heading.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(g11_controls,"Orugas en movimiento",func(): _g11_play("move"),
        "Salva de cohetes",func(): _g11_play("attack"))
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
    _add_paired(g11_controls,"Vista frontal",func(): _g11_view(0.0),
        "Ver orugas y suspensión",func(): _g11_view(90.0))
    _add_paired(g11_controls,"Vista posterior",func(): _g11_view(180.0),
        "Lateral opuesto",func(): _g11_view(270.0))
    _add_paired(g11_controls,"V15: trasera en 3/4",func(): _g11_view(145.0),
        "V15: blindaje opuesto",func(): _g11_view(215.0))
    _title(g11_controls,
        "V15: inspecciona las dos cubiertas traseras biseladas, el bastidor "
        + "reforzado y seis lamas 3D. Durante la salva verás los hidráulicos V14; "
        + "las diez puntas del engrane V13 y la pintura siguen intactas.",12)
    var index: int = column.get_children().find(detail_label)
    column.move_child(g11_controls,maxi(0,index))
    g11_controls.visible = false

func _g11_view(yaw: float) -> void:
    if _role != "mlrs" or model_root == null:
        return
    _g11_stop()
    _yaw = yaw
    model_root.rotation_degrees.y = yaw
    _update_camera()

func _g11_play(kind: String, speed: float = 1.0) -> void:
    if _role != "mlrs" or not G11Rig.has_rig(model_root):
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
                if _p06_show_v5 else "Volver al acabado completo V18")
        if p06_ramp_button != null:
            p06_ramp_button.text = ("Cerrar rampa de tropas"
                if model_root != null and model_root.get_meta(
                    "tarvoka_apc_ramp_open",false) else "Abrir rampa de tropas")
    elif damage_picker != null and _role != "mlrs":
        for i in range(TankDamage.STAGES.size()):
            damage_picker.set_item_text(i,str(TankDamage.STAGES[i]))
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
    if _p06_fleet!=null:
        _hide_p06_fleet()
    super._display_role(role)
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
        else:
            push_error("TARVOKA P06 V18 wheelwell model was not built; do not label it final")
        _update_camera()
    if role == "mlrs" and model_root != null:
        # Studio only: override the low-poly proxy with the complete V1 sculpt.
        preview.remove_child(model_root)
        model_root.queue_free()
        model_root = P06Models.build("mlrs",_faction,true,13)
        if model_root != null:
            preview.add_child(model_root)
            model_root.rotation_degrees.y = _yaw
            _update_camera()
        _g11_animation = ""
    _sync_p06_controls()
    _update_details()

func _switch_category(index: int) -> void:
    super._switch_category(index)
    _sync_p06_controls()

func _on_faction(index: int) -> void:
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
        if built and bool(model_root.get_meta("tarvoka_g11_aft_pod_finish_v15",false)):
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
        mesh_count,"V18 completo" if true_v5 and _p06_show_v5 else
        "V3 de comparación"]
    var faction_name: String = str(Factions.FACTIONS[_faction]["name"])
    status_label.text = "%s · %s · %s" % [
        faction_name,P06Stages[_stage_p06()],
        "acabado V18 cargado" if _p06_quality_verified else
        "ERROR: modelo final no cargado"]
