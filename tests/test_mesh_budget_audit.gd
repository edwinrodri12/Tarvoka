extends SceneTree
const Audit = preload("res://scripts/tools/MeshBudgetAudit.gd")

func _initialize() -> void:
	var root := Node3D.new()
	var box := MeshInstance3D.new()
	box.mesh = BoxMesh.new()
	root.add_child(box)
	var report: Dictionary = Audit.inspect(root, 11)
	assert(report["mesh_nodes"] == 1)
	assert(report["instances"] == 1)
	assert(report["triangles"] == 12)
	assert(report["warnings"].size() == 1)
	var multi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = 3
	multi.multimesh = mm
	root.add_child(multi)
	report = Audit.inspect(root, 48)
	assert(report["triangles"] == 48)
	assert(report["instances"] == 4)
	assert(report["warnings"].is_empty())
	mm.visible_instance_count = 1
	report = Audit.inspect(root, 24)
	assert(report["triangles"] == 24)
	assert(report["instances"] == 2)
	assert(report["warnings"].is_empty())
	assert(Audit.inspect(null)["warnings"].size() == 1)
	root.free()
	print("MESH_BUDGET_AUDIT_PASS")
	quit(0)
