extends SceneTree

# Quick parser gate: prevents the long GPU suite from waiting for a broken
# preload of the V4 isolated terrain module.
const Premium = preload("res://scripts/ui/TerrainStudioPremiumFinish3D.gd")
const Terrain = preload("res://scripts/ui/TerrainStudio3D.gd")

func _initialize() -> void:
    assert(Premium != null and Terrain != null)
    assert(is_finite(Premium._hash(31,7,4)))
    assert(Terrain.SCENES.size() == 3)
    print("PASS terrain premium V4 preload")
    quit(0)
