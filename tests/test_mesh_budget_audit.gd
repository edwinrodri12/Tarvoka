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
	# Indexed geometry must count index triangles, not the vertex buffer size.
	var indexed_mesh := ArrayMesh.new()
	var indexed_arrays := []
	indexed_arrays.resize(Mesh.ARRAY_MAX)
	indexed_arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3(1, 1, 0), Vector3.UP])
	indexed_arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	indexed_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, indexed_arrays)
	var indexed_node := MeshInstance3D.new()
	indexed_node.mesh = indexed_mesh
	root.add_child(indexed_node)
	report = Audit.inspect(root, 26)
	assert(report["triangles"] == 26)
	assert(report["instances"] == 4)
	assert(report["warnings"].is_empty())
	report = Audit.inspect(root, 25)
	assert(report["warnings"].size() == 1)
	# A MultiMesh with zero visible instances must contribute no geometry.
	mm.visible_instance_count = 0
	report = Audit.inspect(root, 14)
	assert(report["triangles"] == 14)
	assert(report["instances"] == 3)
	assert(report["mesh_nodes"] == 3)
	assert(report["warnings"].is_empty())
	# Nested scene roots must be traversed without requiring a MeshInstance root.
	var wrapper := Node3D.new()
	var nested := MeshInstance3D.new()
	nested.mesh = BoxMesh.new()
	wrapper.add_child(nested)
	report = Audit.inspect(wrapper, 12)
	assert(report["triangles"] == 12)
	assert(report["instances"] == 1)
	assert(report["warnings"].is_empty())
	wrapper.free()
	assert(Audit.inspect(null)["warnings"].size() == 1)
	root.free()
	print("MESH_BUDGET_AUDIT_PASS")
	quit(0)
