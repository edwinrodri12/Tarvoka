extends RefCounted
## Read-only geometry census for production 3D scenes. Does not mutate assets.
## Counts submitted triangles, including MultiMesh instance multiplicity.
const DEFAULT_TRIANGLE_WARNING := 12000

static func inspect(root: Node, triangle_warning: int = DEFAULT_TRIANGLE_WARNING) -> Dictionary:
	var report := {"mesh_nodes": 0, "instances": 0, "triangles": 0, "surfaces": 0, "largest_mesh_triangles": 0, "largest_mesh_path": "", "warnings": []}
	if root == null:
		report["warnings"].append("Missing scene root")
		return report
	_visit(root, report)
	if report["triangles"] > triangle_warning:
		report["warnings"].append("Triangle budget exceeded: %d > %d" % [report["triangles"], triangle_warning])
	return report

## Audits a PackedScene without attaching it to the active game tree.
## The temporary instance is always released after inspection.
static func inspect_packed_scene(scene: PackedScene, triangle_warning: int = DEFAULT_TRIANGLE_WARNING) -> Dictionary:
	if scene == null:
		return inspect(null, triangle_warning)
	var instance := scene.instantiate()
	if instance == null:
		return inspect(null, triangle_warning)
	var report := inspect(instance, triangle_warning)
	instance.free()
	return report

static func _visit(node: Node, report: Dictionary) -> void:
	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			var before: int = report["triangles"]
			_add_mesh(mesh_node.mesh, 1, report)
			_record_largest(node, report["triangles"] - before, report)
	elif node is MultiMeshInstance3D:
		var multi_node := node as MultiMeshInstance3D
		if multi_node.multimesh != null and multi_node.multimesh.mesh != null:
			var count: int = multi_node.multimesh.visible_instance_count
			if count < 0:
				count = multi_node.multimesh.instance_count
			var before: int = report["triangles"]
			_add_mesh(multi_node.multimesh.mesh, count, report)
			_record_largest(node, report["triangles"] - before, report)
	for child in node.get_children():
		_visit(child, report)

static func _add_mesh(mesh: Mesh, count: int, report: Dictionary) -> void:
	if count <= 0:
		return
	report["mesh_nodes"] += 1
	report["instances"] += count
	for surface in range(mesh.get_surface_count()):
		report["surfaces"] += count
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var indices := mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX] as PackedInt32Array
		var vertices := mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var element_count: int = indices.size() if not indices.is_empty() else vertices.size()
		report["triangles"] += (element_count / 3) * count

## Diagnostic only: identifies the most expensive node by submitted triangles.
static func _record_largest(node: Node, triangles: int, report: Dictionary) -> void:
	if triangles > report["largest_mesh_triangles"]:
		report["largest_mesh_triangles"] = triangles
		report["largest_mesh_path"] = str(node.get_path()) if node.is_inside_tree() else str(node.name)
