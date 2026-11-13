extends Node
class_name TarvokaUnitRender3D

# Eight shared 3D-to-texture renderers for the 2D isometric tactical board.
# The models ARE real 3D meshes and the capture is done by Godot's renderer.
# Reuse textures across all armies, never instantiate per combat unit.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const SIZE := Vector2i(224,224)
const ORBIT := Vector3(5.1,4.1,6.0)

signal textures_ready

var previews: Dictionary = {} # Role -> SubViewportTexture
var viewports: Dictionary = {} # Role -> SubViewport
var prepared := false
var captures_completed := false

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
    captures_completed = true
    textures_ready.emit()

func texture_for(role: String, faction: int = -1) -> Texture2D:
    if not prepared or not captures_completed:
        return null
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

func disable_3d_previews() -> void:
    # If device resources become constrained, the board can switch back to
    # the original validated 2D atlas without losing tactical progress.
    captures_completed = false
