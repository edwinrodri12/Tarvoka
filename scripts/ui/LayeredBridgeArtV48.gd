extends RefCounted
class_name TarvokaLayeredBridgeArtV48

# Read-only experimental bridge art. Never changes the tactical graph.
const CELL := 2.4
const DECK_TOP := 1.99
const DECK_BOTTOM := 1.78
const WATER_LEVEL := -0.17
const ROAD_TOP := DECK_TOP+0.04
const RAMP_HALF_WIDTH := 0.63

static func _box(parent: Node3D,label: String,dimensions: Vector3,
        at: Vector3,tint: Color) -> void:
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.92
    mesh.material = material
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.position = at
    parent.add_child(part)

static func build(axis: String) -> Node3D:
    if axis not in ["ew","ns"]:
        return null
    var root := Node3D.new()
    root.name = "PuenteElevadoExperimentalV48"
    root.rotation.y = PI*0.5 if axis=="ns" else 0.0
    var concrete := Color("#a8aaa3")
    var metal := Color("#767f81")
    _box(root,"Tablero",Vector3(CELL,DECK_TOP-DECK_BOTTOM,1.48),
        Vector3(0,(DECK_TOP+DECK_BOTTOM)*0.5,0),concrete)
    _box(root,"Calzada",Vector3(CELL,0.04,1.26),
        Vector3(0,DECK_TOP+0.02,0),Color("#4f585e"))
    for side in [-1.0,1.0]:
        var z: float = float(side)*0.70
        _box(root,"Viga",Vector3(CELL,0.16,0.12),Vector3(0,DECK_BOTTOM+0.08,z),metal)
        _box(root,"Parapeto",Vector3(CELL,0.20,0.10),Vector3(0,DECK_TOP+0.12,z),concrete)
    for x in [-0.8,0.0,0.8]:
        _box(root,"Marca",Vector3(0.36,0.008,0.035),
            Vector3(x,DECK_TOP+0.044,0),Color("#e6dfb4"))
    root.set_meta("clearance",DECK_BOTTOM-WATER_LEVEL)
    root.set_meta("prototype_only",true)
    return root

# Closed ramp wedge from the approach tile center to the elevated deck.
# Coordinates are local to the bridge; one ramp per end of a span.
static func build_ramp(axis: String,side: int,ground_y: float,reach: int = 1) -> Node3D:
    if axis not in ["ew","ns"] or side not in [-1,1] or ground_y>=ROAD_TOP or reach not in [1,2]:
        return null
    var root := Node3D.new()
    root.name = "RampaExperimentalV48"
    root.rotation.y = PI*0.5 if axis=="ns" else 0.0
    var inner: float = float(side)*CELL*0.5
    var outer: float = float(side)*CELL*float(reach)
    var points: Array[Vector3] = [
        Vector3(inner,ROAD_TOP,-RAMP_HALF_WIDTH),
        Vector3(inner,ROAD_TOP,RAMP_HALF_WIDTH),
        Vector3(outer,ground_y,RAMP_HALF_WIDTH),
        Vector3(outer,ground_y,-RAMP_HALF_WIDTH),
        Vector3(inner,ROAD_TOP-0.18,-RAMP_HALF_WIDTH),
        Vector3(inner,ROAD_TOP-0.18,RAMP_HALF_WIDTH),
        Vector3(outer,ground_y-0.18,RAMP_HALF_WIDTH),
        Vector3(outer,ground_y-0.18,-RAMP_HALF_WIDTH)]
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var faces: Array = [[0,1,2,3],[4,7,6,5],[0,4,5,1],
        [3,2,6,7],[0,3,7,4],[1,5,6,2]]
    for i in range(faces.size()):
        var q: Array = faces[i]
        var tint := Color("#535c60") if i==0 else Color("#999e97")
        for k in [q[0],q[1],q[2],q[0],q[2],q[3]]:
            tool.set_color(tint)
            tool.add_vertex(points[k])
    tool.generate_normals()
    var instance := MeshInstance3D.new()
    instance.mesh = tool.commit()
    var mat := StandardMaterial3D.new()
    mat.vertex_color_use_as_albedo = true
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    mat.roughness = 0.92
    instance.material_override = mat
    root.add_child(instance)
    root.set_meta("ground_y",ground_y)
    root.set_meta("reach",reach)
    root.set_meta("slope_degrees",rad_to_deg(atan((ROAD_TOP-ground_y)/(absf(outer-inner)))))
    root.set_meta("deck_y",ROAD_TOP)
    return root

# Bounds in the root parent's coordinate system, including root scale.
# Inspect actual visible mesh bounds rather than shrinking approved models.
static func model_bounds(root: Node3D) -> Dictionary:
    var output: Dictionary = {"valid":false,"bounds":AABB()}
    _collect_bounds(root,Transform3D.IDENTITY,output)
    return output

static func _collect_bounds(node: Node3D,parent_transform: Transform3D,output: Dictionary) -> void:
    if not node.visible:
        return
    var transform: Transform3D = parent_transform*node.transform
    if node is MeshInstance3D and node.mesh!=null:
        var box: AABB = transform*node.get_aabb()
        output["bounds"] = _merge_bounds(output["bounds"],box) if output["valid"] else box
        output["valid"] = true
    elif node is MultiMeshInstance3D and node.multimesh!=null:
        var box: AABB = transform*node.get_aabb()
        output["bounds"] = _merge_bounds(output["bounds"],box) if output["valid"] else box
        output["valid"] = true
    for child in node.get_children():
        if child is Node3D:
            _collect_bounds(child,transform,output)

static func clearance_report(bounds: AABB,domain: String) -> Dictionary:
    # Conservative vertical envelope. No collision clearance is certified.
    var top: float = bounds.end.y
    var bottom: float = bounds.position.y
    var fits: bool = top<=DECK_BOTTOM-0.05 if domain=="naval" else bottom>=ROAD_TOP-0.01
    return {"fits_vertical":fits,"bottom":bottom,"top":top,
        "available":DECK_BOTTOM-WATER_LEVEL if domain=="naval" else ROAD_TOP}

static func _merge_bounds(a: AABB,b: AABB) -> AABB:
    return a.merge(b)
