extends SceneTree

# Exact diagnostics for combined V3.1 + PBR + V4 loader dependencies.
func _initialize() -> void:
    call_deferred("_probe")

func _probe() -> void:
    for path in [
        "res://scripts/ui/TerrainSurfaceSampler3D.gd",
        "res://scripts/ui/TerrainStudioScatter3D.gd",
        "res://scripts/ui/TerrainStudioRoadShore3D.gd",
        "res://scripts/ui/TerrainTextures3D.gd",
        "res://scripts/ui/TerrainStudio3D.gd",
        "res://scripts/ui/TerrainStudioPremiumFinish3D.gd",
        "res://scripts/ui/CombinedArtStudioWeb.gd"]:
        print("PROBE_TERRAIN ",path)
        var source: Script = load(path) as Script
        if source == null or not source.can_instantiate():
            push_error("FAILED_TO_LOAD_TERRAIN "+path)
            quit(1)
            return
    print("PASS integrated terrain preflight: V3.1, PBR and V4")
    quit(0)
