extends RefCounted
class_name TarvokaTankFinish3D

# Authored detail pass for TARVOKA's original G09 MBT.
# This is actual lightweight Godot geometry, never a concept image or an
# external model. Existing main hull/turret/paint zones and tactical rules
# stay untouched. All parts use neutral military finishes; paint remains
# restricted to the original fourteen replaceable faction panels.
const ROOT := "AcabadoMilitarG09"
const ARMOR := Color("#69757B")
const ARMOR_EDGE := Color("#849096")
const SHADOW := Color("#293136")
const STEEL := Color("#465158")
const BOLT := Color("#9DA6A7")
const OPTIC := Color("#38637A")
const GLASS := Color("#78ABB7")
const RUBBER := Color("#1E2529")
const SAND := Color("#887F70")

static func _mat(color: Color, metal: float = 0.22, rough: float = 0.73) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    return m

static func _box(parent: Node3D, label: String, center: Vector3,
        dimensions: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.material_override = _mat(color)
    node.position = center
    node.rotation_degrees = rotation
    parent.add_child(node)
    return node

static func _rod(parent: Node3D, label: String, start: Vector3, end: Vector3,
        radius: float, color: Color, sides: int = 8) -> MeshInstance3D:
    var delta: Vector3 = end - start
    var node := MeshInstance3D.new()
    node.name = label
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = maxf(0.01,delta.length())
    mesh.radial_segments = maxi(6,sides)
    node.mesh = mesh
    node.material_override = _mat(color,0.39,0.62)
    node.position = (start + end)*0.5
    if delta.length_squared() > 0.00001:
        node.quaternion = Quaternion(Vector3.UP,delta.normalized())
    parent.add_child(node)
    return node

static func _bevel(parent: Node3D, label: String, center: Vector3,
        dimensions: Vector3, bevel: float, color: Color) -> MeshInstance3D:
    # Actual 8-sided chamfered prism, more legible than another rectangle.
    var half_width: float = dimensions.x*0.5
    var half_height: float = dimensions.y*0.5
    var front: float = -dimensions.z*0.5
    var rear: float = dimensions.z*0.5
    var cut: float = minf(bevel,minf(half_width,half_height)*0.75)
    var outline := [
        Vector2(-half_width+cut,-half_height),
        Vector2(half_width-cut,-half_height),
        Vector2(half_width,-half_height+cut),
        Vector2(half_width,half_height-cut),
        Vector2(half_width-cut,half_height),
        Vector2(-half_width+cut,half_height),
        Vector2(-half_width,half_height-cut),
        Vector2(-half_width,-half_height+cut)
    ]
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Every panel gets UVs so future hand-painted maps can replace PBR noise.
    for n in range(outline.size()):
        var next: int = (n+1) % outline.size()
        var a: Vector2 = outline[n]
        var b: Vector2 = outline[next]
        var face := [
            Vector3(a.x,a.y,front),Vector3(b.x,b.y,front),
            Vector3(b.x,b.y,rear),Vector3(a.x,a.y,rear)
        ]
        for idx in [0,1,2,0,2,3]:
            var p: Vector3 = face[idx]
            surface.set_uv(Vector2(p.x*0.5+0.5,p.z*0.5+0.5))
            surface.add_vertex(p)
    # End-cap triangulation, counter-wound for the front and rear.
    for n in range(1,outline.size()-1):
        for side in [-1,1]:
            var z: float = front if side < 0 else rear
            var indices := [0,n+1,n] if side < 0 else [0,n,n+1]
            for idx in indices:
                var p: Vector2 = outline[idx]
                surface.set_uv(Vector2(p.x+0.5,p.y+0.5))
                surface.add_vertex(Vector3(p.x,p.y,z))
    surface.generate_normals()
    var result := MeshInstance3D.new()
    result.name = label
    result.mesh = surface.commit()
    result.material_override = _mat(color,0.25,0.76)
    result.position = center
    parent.add_child(result)
    return result

static func _fasteners(parent: Node3D, label: String, locations: Array,
        radius: float = 0.028) -> MultiMeshInstance3D:
    # Batched mesh: dozens of physical fastening heads, ONE render instance.
    var bolts := MultiMeshInstance3D.new()
    bolts.name = label
    var head := SphereMesh.new()
    head.radius = radius
    head.height = radius*1.4
    head.radial_segments = 6
    head.rings = 3
    var mesh := MultiMesh.new()
    mesh.transform_format = MultiMesh.TRANSFORM_3D
    mesh.mesh = head
    mesh.instance_count = locations.size()
    for i in range(locations.size()):
        mesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,locations[i]))
    bolts.multimesh = mesh
    bolts.material_override = _mat(BOLT,0.54,0.53)
    parent.add_child(bolts)
    return bolts

static func apply(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)
    var lower := Node3D.new()
    lower.name = "AcabadoChasis"
    hull.add_child(lower)
    var crown := Node3D.new()
    crown.name = "AcabadoTorreta"
    turret.add_child(crown)

    # Angled split frontal applique: the wedge silhouette and border seams
    # remain visibly distinct from the broad glacis at 224px and at 3D zoom.
    for side in [-1,1]:
        var sign: float = float(side)
        var fore: MeshInstance3D = _bevel(lower,"ModuloGlacisBiselado%s" % side,
            Vector3(sign*0.39,1.006,-1.07),Vector3(0.62,0.10,0.49),0.045,ARMOR)
        fore.rotation_degrees.x = -18.0
        fore.rotation_degrees.y = sign*7.0
        _box(lower,"AristaGlacis%s" % side,
            Vector3(sign*0.39,1.055,-0.90),Vector3(0.58,0.018,0.018),ARMOR_EDGE)
        _rod(lower,"CableRemolque%s_A" % side,
            Vector3(sign*0.64,1.043,-0.63),
            Vector3(sign*0.69,1.062,0.18),0.025,SHADOW)
        _rod(lower,"CableRemolque%s_B" % side,
            Vector3(sign*0.69,1.062,0.18),
            Vector3(sign*0.62,1.048,0.62),0.025,SHADOW)
        # Hanging front tow eye, protected between chassis and skirt.
        _rod(lower,"ArgollaRemolque%s" % side,
            Vector3(sign*0.56,0.44,-1.39),
            Vector3(sign*0.56,0.33,-1.50),0.055,STEEL)
        _box(lower,"FaroBlindado%s" % side,
            Vector3(sign*0.69,0.86,-1.435),
            Vector3(0.19,0.17,0.13),SHADOW)
        _box(lower,"LenteFaro%s" % side,
            Vector3(sign*0.69,0.86,-1.506),
            Vector3(0.11,0.095,0.017),GLASS)

        # Outer track drive/idler wheels and suspension guards; do not
        # replace moving mesh names used by the original TankVisualRig3D.
        for end in [-1,1]:
            var z: float = float(end)*1.24
            var wheel := _bevel(lower,"BlindajeRuedaExtremo%s_%s" % [side,end],
                Vector3(sign*1.305,0.285,z),Vector3(0.075,0.36,0.32),0.025,STEEL)
            wheel.rotation_degrees.x = 0.0
        _box(lower,"BarraAntisalpique%s" % side,
            Vector3(sign*1.23,0.865,-0.04),
            Vector3(0.037,0.055,2.70),SHADOW)

        # Composite turret cheeks with angled armor edges, neutral tint.
        var cheek := _bevel(crown,"MejillaCeramicaBiselada%s" % side,
            Vector3(sign*0.46,0.30,-0.71),Vector3(0.39,0.27,0.34),
            0.095,ARMOR_EDGE)
        cheek.rotation_degrees.y = sign*22.0
        cheek.rotation_degrees.x = -9.0
        _rod(crown,"SoldaduraMejilla%s" % side,
            Vector3(sign*0.68,0.16,-0.60),
            Vector3(sign*0.68,0.44,-0.43),0.019,SHADOW)
        # Gridded rear bustle stowage rack with no logos or emblems.
        _rod(crown,"BastidorTrasero%s" % side,
            Vector3(sign*0.54,0.28,0.68),
            Vector3(sign*0.73,0.29,0.94),0.034,STEEL)
        _rod(crown,"BarandaPosterior%s" % side,
            Vector3(sign*0.71,0.46,0.59),
            Vector3(sign*0.74,0.46,0.91),0.025,STEEL)
        _box(crown,"EstibaAntideslizante%s" % side,
            Vector3(sign*0.60,0.22,0.80),
            Vector3(0.20,0.11,0.24),SAND)
        # Optic/smoke cowl: colored enamel would look toy-like here.
        _box(crown,"GuardiaOpticaLateral%s" % side,
            Vector3(sign*0.67,0.46,-0.35),
            Vector3(0.12,0.13,0.19),STEEL)
        _box(crown,"LenteSensorLateral%s" % side,
            Vector3(sign*0.735,0.47,-0.37),
            Vector3(0.020,0.068,0.10),OPTIC)

    # Roof and driver's vision system: asymmetric, recognizable modern MBT.
    _bevel(crown,"ModuloVisionPanoramica",Vector3(0.34,0.673,0.19),
        Vector3(0.31,0.20,0.31),0.055,SHADOW)
    _box(crown,"CristalPanoramicoFrontal",Vector3(0.34,0.68,0.020),
        Vector3(0.22,0.11,0.023),GLASS)
    _box(crown,"CristalPanoramicoLateral",Vector3(0.51,0.68,0.19),
        Vector3(0.018,0.09,0.19),OPTIC)
    _box(crown,"PanelServicioTorre",Vector3(0.0,0.552,0.39),
        Vector3(0.27,0.021,0.22),STEEL)
    _rod(crown,"SoldaduraTechoFrontal",Vector3(-0.28,0.548,-0.41),
        Vector3(0.28,0.548,-0.41),0.013,SHADOW)
    _rod(lower,"BordeTapaMotor",Vector3(-0.62,1.07,0.50),
        Vector3(0.62,1.07,0.50),0.016,ARMOR_EDGE)
    _rod(lower,"BordeTapaMotorPosterior",Vector3(-0.62,1.07,1.32),
        Vector3(0.62,1.07,1.32),0.016,ARMOR_EDGE)

    # Hinges and ventilation above the engine are attached to the hull, not
    # to the turret (they therefore do not rotate during target tracking).
    for n in range(5):
        var x: float = -0.50 + float(n)*0.25
        _box(lower,"PersianaMotorDetalle_%02d" % n,
            Vector3(x,1.077,1.04),Vector3(0.13,0.014,0.19),
            STEEL,Vector3(0,0,0))
        _box(lower,"BisagraMantenimiento_%02d" % n,
            Vector3(x,1.08,0.54),Vector3(0.07,0.022,0.055),SHADOW)

    # Real fastening details, batched as exactly two MultiMesh nodes.
    var fasten_turret: Array = []
    for side in [-1,1]:
        for n in range(6):
            fasten_turret.append(Vector3(float(side)*0.56,0.47,
                -0.56+float(n)*0.20))
    _fasteners(crown,"PernosCorazaTorre",fasten_turret,0.024)
    var fasten_skirt: Array = []
    for side in [-1,1]:
        for n in range(5):
            for z_offset in [-0.13,0.13]:
                fasten_skirt.append(Vector3(float(side)*1.219,0.72,
                    -1.07+float(n)*0.54+z_offset))
    _fasteners(lower,"PernosFaldones",fasten_skirt,0.026)
    model.set_meta("tarvoka_mbt_finish_v3",true)
    return true
