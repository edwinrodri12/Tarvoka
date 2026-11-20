extends SceneTree
## Run with: godot --headless --path . --script res://tests/audit_production_scene.gd -- res://scenes/UnitArtStudioWeb.tscn
## This is a diagnostic, not a device performance benchmark.
const Audit = preload("res://scripts/tools/MeshBudgetAudit.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not args[0].begins_with("res://") or not args[0].ends_with(".tscn"):
		push_error("Usage: -- res://path/to/production_scene.tscn")
		quit(2)
		return
	var path: String = args[0]
	if not ResourceLoader.exists(path, "PackedScene"):
		push_error("Production scene missing: " + path)
		quit(3)
		return
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("Cannot load PackedScene: " + path)
		quit(4)
		return
	var report: Dictionary = Audit.inspect_packed_scene(scene)
	if not Audit.is_valid_report(report):
		push_error("Invalid or inconsistent geometry census")
		quit(5)
		return
	print("MESH_PRODUCTION_CENSUS " + JSON.stringify({"scene": path, "report": report}))
	quit(0)
