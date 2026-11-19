extends Node3D
## Isolated 3D preview; the selected asset can be replaced without touching battle input.
## Asset path is relative to this scene. Keep it independent from tactical controls.

@export var asset_path: NodePath = ^"SampleAsset"

@onready var orbit_rig = $OrbitRig

func _ready() -> void:
    # Defer until children and their global transforms are ready.
    call_deferred("_frame_preview")

func _frame_preview() -> void:
    frame_selected_asset()

## Returns false for an invalid path or an asset without renderable meshes.
## On failure, the camera's previous target and distance are preserved.
func frame_selected_asset() -> bool:
    var asset: Node3D = get_node_or_null(asset_path) as Node3D
    if asset == null:
        push_warning("Inspection asset path does not resolve to Node3D")
        return false
    return orbit_rig.frame_asset(asset)

## Allow the isolated studio to select another model at runtime.
## Does not mutate the model or install any input handlers.
func select_asset(new_path: NodePath) -> bool:
    var candidate: Node3D = get_node_or_null(new_path) as Node3D
    if candidate == null:
        return false
    if not orbit_rig.frame_asset(candidate):
        return false
    asset_path = new_path
    return true

## Load a PackedScene in the isolated preview without changing the battle scene.
## The previous loaded model is retained when the replacement has no meshes.
## Existing scene children (including SampleAsset) are never deleted.
var _loaded_asset: Node3D

func load_asset_scene(packed: PackedScene) -> bool:
    if packed == null:
        return false
    var candidate: Node = packed.instantiate()
    if not candidate is Node3D:
        candidate.free()
        return false
    var model: Node3D = candidate as Node3D
    model.name = "InspectionLoadedAsset"
    add_child(model)
    if not orbit_rig.frame_asset(model):
        remove_child(model)
        model.free()
        return false
    if _loaded_asset != null and is_instance_valid(_loaded_asset):
        remove_child(_loaded_asset)
        _loaded_asset.queue_free()
    _loaded_asset = model
    asset_path = get_path_to(model)
    return true
