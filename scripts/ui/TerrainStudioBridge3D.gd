extends RefCounted
class_name TarvokaTerrainBridge3D

# Render-only bridges: smooth ramp from the existing land road into a single
# continuous deck. The tactical board/route rules are deliberately untouched.
const ASPHALT := Color("#525a60")
const SHOULDER := Color("#9e9684")
const LINES := Color("#e8dcc1")
const STEEL := Color("#9aa9ac")
const CONCRETE := Color("#737f84")
const DECK_TOP := 0.37
const STEPS := 24

static func _smooth(value: float) -> float:
    var t: float = clampf(value,0.0,1.0)
    return t*t*(3.0-2.0*t)

static func deck_height(x: float, left_x: float, right_x: float,
        cell: float, left_y: float, right_y: float) -> float:
    # Exactly equals the adjoining road at the center of each bank cell.
    # Reaches a flat deck at each water edge (half a cell into the span).
    var half: float = cell * 0.5
    if x <= left_x:
        return left_y
    if x < left_x+half:
        return lerpf(left_y,DECK_TOP,_smooth((x-left_x)/half))
    if x > right_x-half:
        return lerpf(right_y,DECK_TOP,_smooth((right_x-x)/half))
    return DECK_TOP

static func _tri(tool: SurfaceTool, a: Vector3, b: Vector3,
        c: Vector3, tint: Color) -> void:
    for vertex in [a,b,c]:
        tool.set_color(tint)
        tool.set_uv(Vector2(vertex.x*0.16,vertex.z*0.16))
        tool.add_vertex(vertex)

static func _strip(tool: SurfaceTool, x0: float, x1: float,
        z0: float, z1: float, y0: float, y1: float,
        tint: Color) -> void:
    var nw := Vector3(x0,y0,z0)
    var ne := Vector3(x1,y1,z0)
    var se := Vector3(x1,y1,z1)
    var sw := Vector3(x0,y0,z1)
    _tri(tool,nw,sw,ne,tint)
    _tri(tool,ne,sw,se,tint)

static func _bar(tool: SurfaceTool, x0: float, x1: float,
        z: float, y0: float, y1: float, thickness: float,
        tint: Color) -> void:
    # Shallow beam with real side faces and roof, no transparent line primitive.
    var width: float = thickness*0.5
    var bottom0: float = y0-thickness*0.5
    var bottom1: float = y1-thickness*0.5
    var top0: float = y0+thickness*0.5
    var top1: float = y1+thickness*0.5
    _strip(tool,x0,x1,z-width,z+width,top0,top1,tint.lightened(0.09))
    _tri(tool,Vector3(x0,bottom0,z-width),Vector3(x1,bottom1,z-width),
        Vector3(x0,top0,z-width),tint)
    _tri(tool,Vector3(x1,bottom1,z-width),Vector3(x1,top1,z-width),
        Vector3(x0,top0,z-width),tint)
    _tri(tool,Vector3(x0,bottom0,z+width),Vector3(x0,top0,z+width),
        Vector3(x1,bottom1,z+width),tint.darkened(0.17))
    _tri(tool,Vector3(x1,bottom1,z+width),Vector3(x0,top0,z+width),
        Vector3(x1,top1,z+width),tint.darkened(0.17))

static func _finish(group: Node3D, label: String, tool: SurfaceTool,
        roughness: float) -> MeshInstance3D:
    tool.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.name = label
    mesh.mesh = tool.commit()
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.roughness = roughness
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material
    group.add_child(mesh)
    return mesh

static func build(parent: Node3D, row: int, left_bank: Vector3,
        right_bank: Vector3, left_road_y: float,
        right_road_y: float, cell: float,
        water_level: float) -> Node3D:
    var bridge := Node3D.new()
    bridge.name = "PuenteContinuoV4_%d" % row
    parent.add_child(bridge)
    bridge.set_meta("visual_only",true)
    bridge.set_meta("left_bank_road_y",left_road_y)
    bridge.set_meta("right_bank_road_y",right_road_y)
    bridge.set_meta("deck_y",DECK_TOP)
    bridge.set_meta("span_steps",STEPS)
    var left_x: float = left_bank.x
    var right_x: float = right_bank.x
    var center_z: float = left_bank.z
    var length: float = right_x-left_x

    var roadway := SurfaceTool.new()
    roadway.begin(Mesh.PRIMITIVE_TRIANGLES)
    var railing := SurfaceTool.new()
    railing.begin(Mesh.PRIMITIVE_TRIANGLES)
    for n in range(STEPS):
        var x0: float = left_x+length*float(n)/float(STEPS)
        var x1: float = left_x+length*float(n+1)/float(STEPS)
        var y0: float = deck_height(x0,left_x,right_x,cell,left_road_y,right_road_y)
        var y1: float = deck_height(x1,left_x,right_x,cell,left_road_y,right_road_y)
        # Five longitudinal bands, all part of ONE roadway mesh.
        var pavement: Color = ASPHALT.lightened(0.016 if n%4==0 else 0.0)
        _strip(roadway,x0,x1,center_z-0.82,center_z-0.68,
            y0-0.024,y1-0.024,SHOULDER)
        _strip(roadway,x0,x1,center_z-0.68,center_z+0.68,
            y0,y1,pavement)
        _strip(roadway,x0,x1,center_z+0.68,center_z+0.82,
            y0-0.024,y1-0.024,SHOULDER)
        if n%4 < 2:
            _strip(roadway,x0,x1,center_z-0.035,center_z+0.035,
                y0+0.012,y1+0.012,LINES)
        # Rail segments begin on the ramp, not on the adjoining road center.
        if n >= 2 and n < STEPS-2:
            for side in [-1.0,1.0]:
                var rail_z: float = center_z + side*0.86
                _bar(railing,x0,x1,rail_z,
                    y0+0.47,y1+0.47,0.075,STEEL)
    _finish(bridge,"TableroYRampasV4",roadway,0.88)
    _finish(bridge,"BarandasContinuasV4",railing,0.65)

    # Two columns in one MultiMesh: no per-pillar draw calls.
    var pillar_mesh := CylinderMesh.new()
    pillar_mesh.radial_segments = 8
    pillar_mesh.rings = 1
    pillar_mesh.bottom_radius = 0.21
    pillar_mesh.top_radius = 0.18
    var base_y: float = water_level-0.24
    var upper_y: float = DECK_TOP-0.08
    pillar_mesh.height = upper_y-base_y
    pillar_mesh.material = StandardMaterial3D.new()
    (pillar_mesh.material as StandardMaterial3D).albedo_color = CONCRETE
    var count: int = maxi(1,roundi(length/cell)-1)
    var piers := MultiMesh.new()
    piers.transform_format = MultiMesh.TRANSFORM_3D
    piers.mesh = pillar_mesh
    piers.instance_count = count
    for n in range(count):
        var px: float = left_x+cell*float(n+1)
        piers.set_instance_transform(n,
            Transform3D(Basis.IDENTITY,Vector3(px,
                (base_y+upper_y)*0.5,center_z)))
    var support := MultiMeshInstance3D.new()
    support.name = "PilaresAgrupadosV4"
    support.multimesh = piers
    bridge.add_child(support)
    bridge.set_meta("bridge_pillars",count)
    return bridge
