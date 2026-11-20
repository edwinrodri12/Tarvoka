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
	assert(report["largest_mesh_triangles"] == 12)
	assert(report["largest_mesh_path"] == str(root.name) + "/" + str(box.name))
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
	assert(report["largest_mesh_triangles"] == 36)
	assert(report["largest_mesh_path"] == str(root.name) + "/" + str(multi.name))
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
	assert(report["largest_mesh_triangles"] == 12)
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
	assert(report["largest_mesh_path"] == str(wrapper.name) + "/" + str(nested.name))
	assert(report["warnings"].is_empty())
	wrapper.free()
	assert(Audit.inspect(null)["warnings"].size() == 1)
	# PackedScene audit must not attach nodes to the active scene tree.
	var packed_root := Node3D.new()
	var packed_mesh := MeshInstance3D.new()
	packed_mesh.mesh = BoxMesh.new()
	packed_mesh.name = "AuditMesh"
	packed_root.add_child(packed_mesh)
	packed_mesh.owner = packed_root
	var packed := PackedScene.new()
	assert(packed.pack(packed_root) == OK)
	var before_children := root.get_child_count()
	var packed_report: Dictionary = Audit.inspect_packed_scene(packed, 11)
	assert(packed_report["triangles"] == 12)
	assert(packed_report["instances"] == 1)
	assert(packed_report["largest_mesh_path"] == str(packed_root.name) + "/AuditMesh")
	assert(packed_report["warnings"].size() == 1)
	assert(root.get_child_count() == before_children)
	assert(Audit.inspect_packed_scene(null)["warnings"].size() == 1)
	# Repeated packed-scene audits must be deterministic and never retain an instance.
	for audit_iteration in range(3):
		var repeat_report: Dictionary = Audit.inspect_packed_scene(packed, 12)
		assert(repeat_report["triangles"] == 12)
		assert(repeat_report["instances"] == 1)
		assert(repeat_report["warnings"].is_empty())
		assert(root.get_child_count() == before_children)
	# Report validator guards CI against malformed and contradictory output.
	assert(Audit.is_valid_report(packed_report))
	var invalid_report: Dictionary = packed_report.duplicate(true)
	invalid_report["triangles"] = -1
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report["largest_mesh_triangles"] = 13
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report["mesh_nodes"] = 2
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report.erase("warnings")
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report["largest_mesh_path"] = 7
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report["instances"] = 0
	invalid_report["mesh_nodes"] = 0
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report["largest_mesh_path"] = ""
	assert(not Audit.is_valid_report(invalid_report))
	invalid_report = packed_report.duplicate(true)
	invalid_report["warnings"] = [42]
	assert(not Audit.is_valid_report(invalid_report))
	# A positive triangle count requires a nonzero largest contributor.
	invalid_report = packed_report.duplicate(true)
	invalid_report["largest_mesh_triangles"] = 0
	invalid_report["largest_mesh_path"] = ""
	assert(not Audit.is_valid_report(invalid_report))
	# A zero-triangle report cannot identify a positive-cost largest mesh.
	invalid_report = packed_report.duplicate(true)
	invalid_report["triangles"] = 0
	invalid_report["largest_mesh_triangles"] = 0
	assert(not Audit.is_valid_report(invalid_report))
	packed_root.free()
	root.free()
	print("MESH_BUDGET_AUDIT_PASS")
	quit(0)
