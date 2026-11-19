extends Node3D
## Isolated preview scene: automatically frame the asset on scene load.
## Replace SampleAsset with a production model without touching battle input.

@onready var orbit_rig = $OrbitRig
@onready var sample_asset: Node3D = $SampleAsset

func _ready() -> void:
    # Defer until all child transforms are available in the scene tree.
    call_deferred("_frame_preview")

func _frame_preview() -> void:
    if not is_instance_valid(sample_asset):
        return
    if not orbit_rig.frame_asset(sample_asset):
        push_warning("Inspection asset contains no MeshInstance3D")
