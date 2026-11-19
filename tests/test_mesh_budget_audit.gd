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
	var line_mesh := ArrayMesh.new()
	var line_arrays := []
	line_arrays.resize(Mesh.ARRAY_MAX)
	line_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.ONE])
	line_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, line_arrays)
	var line_node := MeshInstance3D.new()
	line_node.mesh = line_mesh
	root.add_child(line_node)
	report = Audit.inspect(root, 48)
	assert(report["triangles"] == 24)
	assert(report["mesh_nodes"] == 3)
	assert(Audit.inspect(null)["warnings"].size() == 1)
	root.free()
	print("MESH_BUDGET_AUDIT_PASS")
	quit(0)
