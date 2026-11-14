extends SceneTree

# Isolates GDScript import errors from heavy GPU/vehicle tests.
func _initialize() -> void:
    call_deferred("_inspect")

func _inspect() -> void:
    for path in [
            "res://scripts/ui/TerrainStudioScatter3D.gd",
            "res://scripts/ui/TerrainStudio3D.gd",
            "res://scripts/ui/TerrainVisualMapBridge3D.gd",
            "res://scripts/ui/BattleTerrain3D.gd",
            "res://scripts/ui/BattleTerrainPicker3D.gd",
            "res://scripts/ui/BattleRanges3D.gd",
            "res://scripts/ui/Battle3DOrders.gd",
            "res://scripts/ui/Battle3DMapView.gd",
            "res://scripts/ui/Main.gd",
            "res://scripts/ui/CombinedArtStudioWeb.gd"]:
        var loaded: Resource = ResourceLoader.load(path,"Script",ResourceLoader.CACHE_MODE_IGNORE)
        if loaded == null:
            push_error("TERRAIN_PREFLIGHT failed to load: "+path)
            quit(1)
            return
        var source: Script = loaded as Script
        if source == null or not source.can_instantiate():
            push_error("TERRAIN_PREFLIGHT compile failure: "+path)
            quit(1)
            return
    print("PASS TERRAIN_PREFLIGHT: scatter, terrain, tactical 3D, map and studio scripts load")
    quit(0)
