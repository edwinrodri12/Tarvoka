extends "res://scripts/ui/CombinedArtStudioWeb.gd"
class_name TarvokaBastionStudioAdapter

# Additive V6 Bastion overlay for the established HQ/Airbase/G09 web studio.
# The Pages workflow overlays the current main-branch P06 Godot sources onto
# the published feature-branch studio, preserving its existing 3D assets.
const P06Damage = preload("res://scripts/ui/BastionDamage3D.gd")
const P06Rig = preload("res://scripts/ui/BastionVisualRig3D.gd")
const P06Models = preload("res://scripts/ui/UnitModels3D.gd")

var p06_controls: VBoxContainer
var p06_hint: Label
var _p06_ready: bool = false

func _ready() -> void:
    super._ready()
    _install_p06_controls()
    var bastion_index: int = P06Models.ROLES.find("apc")
    if bastion_index >= 0:
        role_picker.set_item_text(bastion_index,"Bastión P06 · 6×6 · V6")
    _p06_ready = true
    _sync_p06_controls()

func _install_p06_controls() -> void:
    var column: VBoxContainer = role_picker.get_parent() as VBoxContainer
    p06_controls = VBoxContainer.new()
    p06_controls.name = "BastionP06_V6_Animacion3D"
    p06_controls.add_theme_constant_override("separation",8)
    column.add_child(p06_controls)
    var title := _title(p06_controls,"BASTIÓN P06 · 6×6 · ANIMACIONES V6",15)
    title.add_theme_color_override("font_color",Color("#E7BE70"))
    _add_paired(p06_controls,"Rodar / suspensión",func(): _play("move"),
        "Ametralladora",func(): _play("attack"))
    _add_paired(p06_controls,"Impacto de balas",func(): _play("bullet"),
        "Impacto explosivo",func(): _play("explosive"))
    _add_paired(p06_controls,"Destrucción",func(): _set_damage(4),
        "Reparación",func(): _set_damage(0))
    _button(p06_controls,"Detener animación P06",_stop_animation)
    p06_hint = _title(p06_controls,
        "P06 V6 · 6 ruedas articuladas, dirección, suspensión y torreta remota. "
        + "Usa los 5 estados de daño y los 8 colores oficiales.",12)
    p06_controls.visible = false
    var detail_index: int = column.get_children().find(detail_label)
    column.move_child(p06_controls,maxi(0,detail_index))

func _sync_p06_controls() -> void:
    var p06: bool = _role == "apc"
    if p06_controls != null:
        p06_controls.visible = p06
    if p06:
        faction_picker.visible = true
        damage_picker.visible = true
        comparison_button.visible = false
        previous_version_button.visible = false
        if model_root != null:
            damage_picker.select(P06Damage.current_stage(model_root))

func _display_role(role: String) -> void:
    super._display_role(role)
    if role == "apc" and model_root != null:
        P06Models.apply_faction_palette(model_root,_faction)
        P06Damage.prepare(model_root)
        model_root.set_meta(P06Rig.REST_YAW,_yaw)
        damage_picker.select(0)
    _sync_p06_controls()
    _update_details()

func _switch_category(index: int) -> void:
    super._switch_category(index)
    _sync_p06_controls()

func _on_faction(index: int) -> void:
    super._on_faction(index)
    if _role == "apc" and model_root != null:
        P06Models.apply_faction_palette(model_root,_faction)
        _update_details()

func _set_damage(stage: int) -> void:
    if _role != "apc":
        super._set_damage(stage)
        return
    if model_root == null:
        return
    _stop_animation()
    if P06Damage.apply_stage(model_root,stage):
        damage_picker.select(P06Damage.current_stage(model_root))
        _update_details()

func _play(kind: String) -> void:
    if _role != "apc":
        super._play(kind)
        return
    if model_root == null:
        return
    if P06Damage.current_stage(model_root) >= 4 and kind != "bullet" and kind != "explosive":
        status_label.text = "Bastión destruido · restáuralo antes de mover o disparar"
        return
    _animation = "explosive" if kind == "damaged" else kind
    _animation_time = 0.0
    model_root.set_meta(P06Rig.REST_YAW,_yaw)
    P06Models.pose_model("apc",model_root,_animation,0.0,Vector2i(1,-1))

func _stop_animation() -> void:
    if _role != "apc":
        super._stop_animation()
        return
    _animation = ""
    _animation_time = 0.0
    if model_root != null and P06Rig.has_rig(model_root):
        P06Models.restore_model_pose("apc",model_root)
        model_root.rotation_degrees.y = _yaw
        model_root.set_meta(P06Rig.REST_YAW,_yaw)

func _process(delta: float) -> void:
    super._process(delta)
    if _role != "apc" or model_root == null or _animation.is_empty():
        return
    _animation_time += maxf(delta,0.0)
    var duration: float = P06Rig.MOVE_DURATION
    match _animation:
        "attack":
            duration = P06Rig.ATTACK_DURATION
        "bullet":
            duration = P06Rig.HIT_BULLET_DURATION
        "explosive":
            duration = P06Rig.HIT_EXPLOSIVE_DURATION
    var ratio: float = minf(1.0,_animation_time/maxf(0.01,duration))
    P06Models.pose_model("apc",model_root,_animation,ratio,Vector2i(1,-1))
    if ratio >= 1.0:
        _stop_animation()
        _update_details()

func _rotate(degrees: float) -> void:
    super._rotate(degrees)
    if _role == "apc" and model_root != null:
        model_root.set_meta(P06Rig.REST_YAW,_yaw)

func _reset_camera() -> void:
    super._reset_camera()
    if _role == "apc" and model_root != null:
        model_root.set_meta(P06Rig.REST_YAW,_yaw)

func _update_details() -> void:
    if _role != "apc":
        super._update_details()
        return
    if model_root == null or detail_label == null:
        return
    detail_label.text = "Bastión P06 V6 · %d mallas 3D · 6 ruedas articuladas" % [
        P06Models.inspect_meshes(model_root)]
    var faction: String = str(Factions.FACTIONS[_faction]["name"])
    var stage: int = P06Damage.current_stage(model_root)
    status_label.text = "%s · %s · rig %s" % [
        faction,str(P06Damage.STAGES[stage]),
        "activo" if P06Rig.has_rig(model_root) else "no disponible"]
