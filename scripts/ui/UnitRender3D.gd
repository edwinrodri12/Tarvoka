extends Node
class_name TarvokaUnitRender3D

# Eight shared 3D-to-texture renderers for the 2D isometric tactical board.
# The models ARE real 3D meshes and the capture is done by Godot's renderer.
# Reuse textures across all armies, never instantiate per combat unit.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const TankRig = preload("res://scripts/ui/TankVisualRig3D.gd")
const SIZE := Vector2i(224,224)
const ORBIT := Vector3(5.1,4.1,6.0)

signal textures_ready

var previews: Dictionary = {} # Role -> SubViewportTexture
var viewports: Dictionary = {} # Role -> SubViewport
var prepared := false
var captures_completed := false
var baked_static_captures := 0
const MAX_LIVE_TANKS := 2
const MAX_PARKED_TANKS := 4
const LIVE_CAPTURE_SIZE := Vector2i(192,192)
var live_tank_viewports: Dictionary = {}
var live_tank_models: Dictionary = {}
var live_tank_factions: Dictionary = {}
var live_tank_tasks: Dictionary = {}
var parked_tank_viewports: Dictionary = {}
var parked_tank_models: Dictionary = {}
var parked_tank_factions: Dictionary = {}
var parked_order: Array[String] = []
var live_tank_render_updates := 0

func prepare() -> void:
    if prepared:
        return
    prepared = true
    for role in Models.ROLES:
        # A single neutral capture per regular role; the tank has eight
        # genuine per-faction painted captures, not a whole-vehicle tint.
        # Each camera renders once then is disabled to protect phone battery.
        var variants: Array = range(8) if str(role) == "tank" else [-1]
        for faction in variants:
            var id: String = str(role) + ("#%d" % faction if int(faction) >= 0 else "")
            var viewport := SubViewport.new()
            viewport.name = "3D_" + id.replace("#","_")
            viewport.size = SIZE
            viewport.transparent_bg = true
            viewport.own_world_3d = true
            viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
            viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
            add_child(viewport)
            var model: Node3D = Models.build(str(role),int(faction))
            if model == null:
                continue
            viewport.add_child(model)
            var camera := Camera3D.new()
            camera.name = "CamaraIsometrica"
            camera.projection = Camera3D.PROJECTION_ORTHOGONAL
            camera.size = Models.preview_frame_height(str(role))
            camera.near = 0.1
            camera.far = 50.0
            camera.position = ORBIT
            viewport.add_child(camera)
            camera.look_at(Vector3(0,0.30,0),Vector3.UP)
            camera.current = true
            var key := DirectionalLight3D.new()
            key.name = "LuzPrincipal"
            key.rotation_degrees = Vector3(-49,-35,0)
            key.light_energy = 1.3
            viewport.add_child(key)
            var fill := DirectionalLight3D.new()
            fill.name = "LuzRelleno"
            fill.rotation_degrees = Vector3(-20,135,0)
            fill.light_energy = 0.45
            viewport.add_child(fill)
            previews[id] = viewport.get_texture()
            viewports[id] = viewport
            if role == "tank" and int(faction) == 0:
                previews["tank"] = viewport.get_texture()
    # Captures need a couple of real graphical frames after attaching to
    # scene tree. Stop rendering afterward so Android is not driving 8 live
    # cameras in every battle frame.
    _finish_captures.call_deferred()

func _finish_captures() -> void:
    if not is_inside_tree():
        return
    await get_tree().process_frame
    await get_tree().process_frame
    for role in viewports:
        var viewport: SubViewport = viewports[role]
        viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
        # Baked static previews must not hold 15 entire 3D models and
        # cameras in Android memory for the rest of the match. One guarded
        # GPU readback per role creates a lightweight permanent ImageTexture.
        var image: Image = viewport.get_texture().get_image()
        if image != null and not image.is_empty():
            var frozen: ImageTexture = ImageTexture.create_from_image(image)
            if frozen != null:
                previews[role] = frozen
                baked_static_captures += 1
                viewport.queue_free()
    if baked_static_captures == viewports.size():
        viewports.clear()
    captures_completed = true
    textures_ready.emit()

func texture_for(role: String, faction: int = -1, unit_id: String = "") -> Texture2D:
    if not prepared or not captures_completed:
        return null
    if role == "tank" and not unit_id.is_empty() and live_tank_viewports.has(unit_id):
        if int(live_tank_factions.get(unit_id,-1)) == faction:
            var live_viewport: SubViewport = live_tank_viewports[unit_id] as SubViewport
            if live_viewport != null:
                return live_viewport.get_texture()
    if role == "tank" and parked_tank_viewports.has(unit_id):
        if int(parked_tank_factions.get(unit_id,-1)) == faction:
            var retained: SubViewport = parked_tank_viewports[unit_id] as SubViewport
            if retained != null:
                return retained.get_texture()
    var key: String = role
    if role == "tank" and faction >= 0 and faction < 8:
        key = "tank#%d" % faction
    return previews.get(key,null) as Texture2D

func completed_roles() -> Array:
    return Models.ROLES.duplicate() if captures_completed else []

func is_ready_for(role: String, faction: int = -1) -> bool:
    if not captures_completed:
        return false
    var key: String = "tank#%d" % faction if role == "tank" and faction >= 0 and faction < 8 else role
    return previews.has(key)

func live_tank_count() -> int:
    return live_tank_viewports.size()

func _create_live_tank(unit_id: String, faction: int) -> void:
    if live_tank_viewports.has(unit_id) or live_tank_viewports.size() >= MAX_LIVE_TANKS:
        return
    # Reuse the last camera and mesh if this unit moves/attacks again.
    if parked_tank_viewports.has(unit_id) and int(parked_tank_factions.get(unit_id,-1)) == faction:
        live_tank_viewports[unit_id] = parked_tank_viewports[unit_id]
        live_tank_models[unit_id] = parked_tank_models[unit_id]
        live_tank_factions[unit_id] = faction
        parked_tank_viewports.erase(unit_id)
        parked_tank_models.erase(unit_id)
        parked_tank_factions.erase(unit_id)
        parked_order.erase(unit_id)
        return
    var viewport := SubViewport.new()
    viewport.name = "LiveMBT_" + unit_id
    viewport.size = LIVE_CAPTURE_SIZE
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
    add_child(viewport)
    var model: Node3D = Models.build("tank",faction)
    viewport.add_child(model)
    var camera := Camera3D.new()
    camera.name = "LiveMBTCamera"
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = Models.preview_frame_height("tank")
    camera.near = 0.1
    camera.far = 50.0
    camera.position = ORBIT
    viewport.add_child(camera)
    camera.look_at(Vector3(0,0.30,0),Vector3.UP)
    camera.current = true
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-49,-35,0)
    light.light_energy = 1.3
    viewport.add_child(light)
    var fill := DirectionalLight3D.new()
    fill.rotation_degrees = Vector3(-20,135,0)
    fill.light_energy = 0.45
    viewport.add_child(fill)
    live_tank_viewports[unit_id] = viewport
    live_tank_models[unit_id] = model
    live_tank_factions[unit_id] = faction

func clear_live_tanks() -> void:
    for unit_id in live_tank_viewports.keys():
        var viewport: SubViewport = live_tank_viewports[unit_id] as SubViewport
        if viewport != null:
            viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
            viewport.queue_free()
    for unit_id in parked_tank_viewports.keys():
        var retained: SubViewport = parked_tank_viewports[unit_id] as SubViewport
        if retained != null:
            retained.render_target_update_mode = SubViewport.UPDATE_DISABLED
            retained.queue_free()
    live_tank_viewports.clear()
    live_tank_models.clear()
    live_tank_factions.clear()
    live_tank_tasks.clear()
    parked_tank_viewports.clear()
    parked_tank_models.clear()
    parked_tank_factions.clear()
    parked_order.clear()

func _expire_parked(unit_id: String) -> void:
    if parked_tank_viewports.has(unit_id):
        var retained: SubViewport = parked_tank_viewports[unit_id] as SubViewport
        if retained != null:
            retained.render_target_update_mode = SubViewport.UPDATE_DISABLED
            retained.queue_free()
    parked_tank_viewports.erase(unit_id)
    parked_tank_models.erase(unit_id)
    parked_tank_factions.erase(unit_id)
    parked_order.erase(unit_id)

func _park_live_tank(unit_id: String, keep: bool) -> void:
    var viewport: SubViewport = live_tank_viewports.get(unit_id,null) as SubViewport
    var model: Node3D = live_tank_models.get(unit_id,null) as Node3D
    if viewport != null and model != null and keep:
        var last: Dictionary = live_tank_tasks.get(unit_id,{})
        var original_yaw: float = model.rotation_degrees.y
        TankRig.restore(model)
        model.rotation_degrees.y = original_yaw
        if str(last.get("kind","")) == "attack":
            var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
            if turret != null:
                var heading: Vector2i = last.get("heading",Vector2i.ZERO)
                turret.rotation_degrees.y = wrapf(TankRig.heading_yaw(heading)-original_yaw,-180.0,180.0)
        # A single final GPU frame locks a real 3D heading (no flat sprite
        # rotation). Keep at most four; all others use neutral cached texture.
        viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
        parked_tank_viewports[unit_id] = viewport
        parked_tank_models[unit_id] = model
        parked_tank_factions[unit_id] = live_tank_factions.get(unit_id,-1)
        parked_order.append(unit_id)
        while parked_order.size() > MAX_PARKED_TANKS:
            _expire_parked(parked_order[0])
    elif viewport != null:
        viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
        viewport.queue_free()
    live_tank_viewports.erase(unit_id)
    live_tank_models.erase(unit_id)
    live_tank_factions.erase(unit_id)
    live_tank_tasks.erase(unit_id)

func parked_tank_count() -> int:
    return parked_tank_viewports.size()

func update_tank_actions(units: Array, motion: Array, combat: Array,
        fog_enabled: bool, visible_cells: Dictionary, battery_saver: bool = false) -> void:
    # Only animate actually visible MBTs. Fog never reveals a hidden enemy
    # by allocating its model or updating the texture cache.
    if not captures_completed or battery_saver:
        clear_live_tanks()
        return
    var desired: Dictionary = {}
    for effect in motion:
        var unit_id: String = str(effect.get("id",""))
        for unit in units:
            if str(unit.get("id","")) != unit_id or str(unit.get("role","")) != "tank":
                continue
            if fog_enabled and int(unit.get("faction",1)) != 0 and not visible_cells.has(unit.get("pos")):
                break
            desired[unit_id] = {
                "faction": int(unit["faction"]), "kind":"move",
                "progress":float(effect.get("elapsed",0))/TankRig.MOVE_DURATION,
                "heading":effect.get("to",Vector2i.ZERO)-effect.get("from",Vector2i.ZERO)
            }
            break
    for effect in combat:
        if str(effect.get("attacker_role","")) != "tank":
            continue
        var origin: Vector2i = effect.get("origin",Vector2i(-1,-1))
        var target: Vector2i = effect.get("target",Vector2i(-1,-1))
        if origin.x < 0 or target.x < 0:
            continue
        for unit in units:
            if str(unit.get("role","")) != "tank" or unit.get("pos") != origin:
                continue
            if fog_enabled and int(unit.get("faction",1)) != 0 and not visible_cells.has(origin):
                break
            desired[str(unit["id"])] = {
                "faction":int(unit["faction"]), "kind":"attack",
                "progress":float(effect.get("elapsed",0))/TankRig.SHOT_DURATION,
                "heading":target-origin
            }
            break
    # Damage to a surviving MBT also animates its soot and chassis shake.
    # Defeated/removed targets use BattleVFX destruction, never a ghost unit.
    for effect in combat:
        if str(effect.get("defender_role","")) != "tank":
            continue
        var target: Vector2i = effect.get("target",Vector2i(-1,-1))
        if target.x < 0:
            continue
        for unit in units:
            if str(unit.get("role","")) != "tank" or unit.get("pos") != target:
                continue
            if fog_enabled and int(unit.get("faction",1)) != 0 and not visible_cells.has(target):
                break
            var victim_id: String = str(unit["id"])
            if not desired.has(victim_id):
                desired[victim_id] = {
                    "faction":int(unit["faction"]), "kind":"damaged",
                    "progress":float(effect.get("elapsed",0))/TankRig.SHOT_DURATION,
                    "heading":Vector2i.ZERO
                }
            break
    for unit_id in live_tank_viewports.keys():
        if not desired.has(unit_id):
            var retain_snapshot := false
            for unit in units:
                if str(unit.get("id","")) != str(unit_id) or int(unit.get("hp",0)) <= 0:
                    continue
                # A tank that disappears under fog must not retain a hidden
                # unit-specific preview in memory.
                var own: bool = int(unit.get("faction",-1)) == 0
                retain_snapshot = own or not fog_enabled or visible_cells.has(unit.get("pos"))
                break
            _park_live_tank(str(unit_id),retain_snapshot)
    for unit_id in desired:
        var task: Dictionary = desired[unit_id]
        var faction: int = int(task["faction"])
        if not live_tank_viewports.has(unit_id):
            _create_live_tank(str(unit_id),faction)
        if not live_tank_models.has(unit_id):
            continue
        var model: Node3D = live_tank_models[unit_id] as Node3D
        var heading: Vector2i = task["heading"]
        var kind: String = str(task["kind"])
        if kind == "move":
            model.rotation_degrees.y = TankRig.heading_yaw(heading)
        else:
            model.rotation_degrees.y = 0.0
        if TankRig.pose(model,kind,float(task["progress"]),heading):
            live_tank_tasks[unit_id] = task.duplicate(true)
            var active_view: SubViewport = live_tank_viewports[unit_id] as SubViewport
            active_view.render_target_update_mode = SubViewport.UPDATE_ONCE
            live_tank_render_updates += 1

func disable_3d_previews() -> void:
    # If device resources become constrained, the board can switch back to
    # the original validated 2D atlas without losing tactical progress.
    captures_completed = false
    clear_live_tanks()
