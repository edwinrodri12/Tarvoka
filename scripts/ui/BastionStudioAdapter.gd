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
const G11Art = preload("res://scripts/ui/G11Art3D.gd")
const G11Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
const P06Stages := [
    "Intacto","Impactos leves","Daño moderado","Daño crítico","Destruido"
]

var p06_controls: VBoxContainer
var p06_hint: Label
var p06_version_button: Button
var p06_ramp_button: Button
var _p06_show_v5: bool = true
var _p06_quality_verified: bool = false
var g11_controls: VBoxContainer
var _g11_animation: String = ""
var _g11_time: float = 0.0

func _ready() -> void:
    super._ready()
    _install_p06_controls()
    _install_g11_controls()
    var g11_index: int = P06Models.ROLES.find("mlrs")
    if g11_index >= 0:
        role_picker.set_item_text(g11_index,"G11 Lanzador · Acabado V3 · 12 tubos")
    var idx: int = P06Models.ROLES.find("apc")
    if idx >= 0:
        role_picker.set_item_text(idx,"Bastión P06 · V7 ráfagas y daños · 6×6")
    # The project home link now opens the model under review rather than
    # showing the old default G09 first and confusing Android users.
    _display_role("apc")

func _install_p06_controls() -> void:
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    p06_controls = VBoxContainer.new()
    p06_controls.name = "BastionP06_V7_RafagaDestrozos"
    p06_controls.add_theme_constant_override("separation",8)
    column.add_child(p06_controls)
    var heading: Label = _title(p06_controls,
        "BASTIÓN P06 · V7 · AMETRALLADORA Y DESTROZOS",14)
    heading.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(p06_controls,"Movimiento 6×6",func(): _play("move"),
        "Torreta",func(): _play("turn_turret"))
    _add_paired(p06_controls,"Ráfaga de ametralladora (6)",func(): _play("attack"),
        "Detener",_stop_animation)
    _add_paired(p06_controls,"Impacto de balas",func(): _play("hit_bullet"),
        "Explosión",func(): _play("hit_explosive"))
    p06_ramp_button = _button(p06_controls,"Abrir rampa de tropas",
        _toggle_p06_ramp)
    _add_paired(p06_controls,"Destrucción",func(): _set_damage(4),
        "Reparar completamente",func(): _set_damage(0))
    p06_version_button = _button(p06_controls,"Comparar acabado V3 / V6",
        _toggle_p06_version)
    p06_hint = _title(p06_controls,
        "V7: seis fogonazos individuales y casquillos expulsados. "
        + "Daños progresivos con placas dobladas, rueda afectada y torreta "
        + "desplazada al destruirse. Giro con un dedo y zoom con dos.",12)
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
        "G11 LANZADOR · ACABADO V3 · SUPERFICIES REALES",14)
    heading.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(g11_controls,"Orugas en movimiento",func(): _g11_play("move"),
        "Salva de cohetes",func(): _g11_play("attack"))
    _add_paired(g11_controls,"Impacto de balas",func(): _g11_play("hit_bullet"),
        "Impacto explosivo",func(): _g11_play("hit_explosive"))
    _add_paired(g11_controls,"Daño siguiente",
        func(): _set_damage(mini(4,G11Art.stage(model_root)+1)),
        "Reparación completa",func(): _set_damage(0))
    _button(g11_controls,"Detener animación",_g11_stop)
    _title(g11_controls,
        "Orugas móviles, desgaste PBR y tornillería en lote GPU, "
        + "casco biselado, 12 tubos articulados y ocho facciones. "
        + "LOD ligero separado para batallas Android.",12)
    var index: int = column.get_children().find(detail_label)
    column.move_child(g11_controls,maxi(0,index))
    g11_controls.visible = false

func _g11_play(kind: String) -> void:
    if _role != "mlrs" or not G11Rig.has_rig(model_root):
        return
    if G11Art.stage(model_root) >= 4 and kind in ["move","attack"]:
        status_label.text = "Lanzador destruido · reparar para operar"
        return
    _g11_animation = kind
    _g11_time = 0.0
    G11Rig.pose(model_root,kind,0.0)

func _g11_stop() -> void:
    _g11_animation = ""
    _g11_time = 0.0
    if G11Rig.has_rig(model_root):
        G11Rig.restore(model_root)

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
                if _p06_show_v5 else "Volver al acabado completo V7")
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
            P06Wreck.FLAG,false))
        if _p06_quality_verified:
            P06Details.set_enabled(model_root,_p06_show_v5)
            P06V6.set_enabled(model_root,_p06_show_v5)
            P06Finish.apply_stage(model_root,0)
            P06V6.set_stage(model_root,0)
            P06Wreck.set_stage(model_root,0)
        else:
            push_error("TARVOKA P06 V6 sculpt was not built; do not label it final")
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
    if not _studio_p06():
        return
    _stop_animation()
    if P06Finish.apply_stage(model_root,stage):
        P06V6.set_stage(model_root,stage)
        P06Wreck.set_stage(model_root,stage)
        damage_picker.select(_stage_p06())
        _update_details()

func _toggle_p06_version() -> void:
    if not _studio_p06():
        return
    _p06_show_v5 = not _p06_show_v5
    P06Details.set_enabled(model_root,_p06_show_v5)
    P06V6.set_enabled(model_root,_p06_show_v5)
    P06Wreck.set_enabled(model_root,_p06_show_v5)
    _sync_p06_controls()
    _update_details()

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
    if not _studio_p06():
        return
    if _stage_p06() >= 4 and kind not in ["hit_bullet","hit_explosive"]:
        status_label.text = "Bastión destruido · reparar antes de mover o disparar"
        return
    _animation = kind
    _animation_time = 0.0
    P06Visual.pose(model_root,kind,0.0,42.0)
    P06Finish.animate_impact(model_root,kind,0.0)

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
        P06Visual.restore(model_root)
        P06Finish.animate_impact(model_root,"",1.0)
        _sync_p06_controls()

func _process(delta: float) -> void:
    super._process(delta)
    if _role == "mlrs" and not _g11_animation.is_empty() and G11Rig.has_rig(model_root):
        _g11_time += maxf(0.0,delta)
        var duration: float = G11Rig.MOVE_DURATION if _g11_animation == "move" else (
            G11Rig.SHOT_DURATION if _g11_animation == "attack" else G11Rig.IMPACT_DURATION)
        var t: float = minf(1.0,_g11_time/maxf(duration,0.01))
        G11Rig.pose(model_root,_g11_animation,t)
        if t >= 1.0:
            _g11_stop()
            _update_details()
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
    elif _animation != "move":
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
            "acabado V3" if built and bool(model_root.get_meta(
                "tarvoka_g11_surface_v3",false)) else (
                "acabado V2" if built and bool(model_root.get_meta(
                    "tarvoka_g11_finish_v2",false)) else (
                    "escultura V1" if built else "LOD provisional"))]
        status_label.text = "%s · %s · %s" % [
            str(Factions.FACTIONS[_faction]["name"]),
            G11Art.STAGES[G11Art.stage(model_root)],
            "modelo real cargado" if built else "sin modelo de estudio"]
        return
    if _role != "apc":
        super._update_details()
        return
    if model_root == null or detail_label == null or status_label == null:
        return
    var mesh_count: int = P06Models.inspect_meshes(model_root)
    var true_v5: bool = bool(model_root.get_meta(P06Details.FLAG,false))
    detail_label.text = "Bastión P06 · %d mallas 3D · 6 ruedas · %s" % [
        mesh_count,"V7 completo" if true_v5 and _p06_show_v5 else
        "V3 de comparación"]
    var faction_name: String = str(Factions.FACTIONS[_faction]["name"])
    status_label.text = "%s · %s · %s" % [
        faction_name,P06Stages[_stage_p06()],
        "acabado V7 cargado" if _p06_quality_verified else
        "ERROR: modelo final no cargado"]
