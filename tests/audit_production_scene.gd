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
	# A malformed audit must never produce a success-shaped census in CI.
	for key in ["triangles", "instances", "mesh_nodes", "surfaces", "largest_mesh_triangles"]:
		if not report.has(key) or typeof(report[key]) != TYPE_INT or report[key] < 0:
			push_error("Invalid geometry census field: " + key)
			quit(5)
			return
	if not report.has("warnings") or not (report["warnings"] is Array):
		push_error("Invalid geometry census warnings")
		quit(5)
		return
	if report["largest_mesh_triangles"] > report["triangles"] or report["mesh_nodes"] > report["instances"]:
		push_error("Inconsistent geometry census totals")
		quit(5)
		return
	print("MESH_PRODUCTION_CENSUS " + JSON.stringify({"scene": path, "report": report}))
	quit(0)
