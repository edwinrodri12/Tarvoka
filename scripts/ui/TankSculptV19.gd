extends RefCounted
class_name TarvokaTankSculptV19

# G09 V19: hard-surface cleanup of the ACTUAL existing roof/optical/cannon
# housings. Replaces their original meshes in place, preserves nodes and
# transforms and limits new hardware to two short gun braces + a single
# batched hatch-fastener set + a physically attached barrel bearing ring.
# No game systems or faction identity surfaces are changed.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V19TechoMecanico"
const STEEL := Color("#40535D")
const ROOF := Color("#536670")
const COMPOSITE := Color("#667982")
const GASKET := Color("#202F36")
const TITANIUM := Color("#8A969A")
const HATCH_RADIUS := [0.255,0.190]
const TOPOLOGY := [
    "EscotillaCircularV7_00",
    "EscotillaCircularV7_01",
    "ModuloVisionIntegradoV7_-1",
    "ModuloVisionIntegradoV7_1",
    "CabezalPanoramicoG09V7",
    "EstacionRemotaBlindadaV7",
    "CollarBlindajeCanonV7",
    "CubiertaCompuestaFrontalG09_-1",
    "CubiertaCompuestaFrontalG09_1",
    "CubiertaMotorRectificadaV7",
    "EstibaBlindadaTraseraV7",
    "BancadaFumigenasV7_-1",
    "BancadaFumigenasV7_1"
]
const REPLACED := 13
const BOLT_COUNT := 16
static var _hatch_cache: Array = []
static var _housing_cache: Dictionary = {}

static func _hatch_mesh(radius: float) -> ArrayMesh:
    # Lower outer lip, flush roof surface, raised sealed rim and an INSET
    # recessed center; 24 radial facets. No giant roof-top cylinders.
    var profile := [
        Vector2(0.0,-0.022),Vector2(radius*0.88,-0.022),
        Vector2(radius,-0.010),Vector2(radius*0.985,0.012),
        Vector2(radius*0.78,0.021),Vector2(radius*0.73,0.002),
        Vector2(radius*0.11,-0.003),Vector2(0.0,-0.003)
    ]
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    const SEGMENTS := 24
    for section in range(profile.size()-1):
        var lower: Vector2 = profile[section]
        var upper: Vector2 = profile[section+1]
        for i in range(SEGMENTS):
            var a: float = TAU*float(i)/float(SEGMENTS)
            var b: float = TAU*float(i+1)/float(SEGMENTS)
            var v00 := Vector3(lower.x*cos(a),lower.y,lower.x*sin(a))
            var v01 := Vector3(lower.x*cos(b),lower.y,lower.x*sin(b))
            var v10 := Vector3(upper.x*cos(a),upper.y,upper.x*sin(a))
            var v11 := Vector3(upper.x*cos(b),upper.y,upper.x*sin(b))
            Hero._tri(tool,v00,v01,v11)
            Hero._tri(tool,v00,v11,v10)
    return tool.commit()

static func _housing_mesh(size: Vector3,corner: float,
        forward_cut: float = 0.0) -> ArrayMesh:
    # A genuine low octagonal roof housing. Four closed levels include a
    # chamfer on the FOOT and a sloped roof; all 8 long faces are connected.
    # Vertices are authored in the ORIGINAL mesh's local coordinates, so
    # optical and gun-bearing alignment is not altered.
    var hx: float = size.x*0.5
    var hz: float = size.z*0.5
    var hy: float = size.y*0.5
    var cut: float = minf(corner,minf(hx,hz)*0.52)
    var outline := [
        Vector2(-hx+cut,-hz),Vector2(hx-cut,-hz),
        Vector2(hx,-hz+cut),Vector2(hx,hz-cut),
        Vector2(hx-cut,hz),Vector2(-hx+cut,hz),
        Vector2(-hx,hz-cut),Vector2(-hx,-hz+cut)
    ]
    var sections := [
        Vector2(-hy,0.88),
        Vector2(-hy+minf(0.021,hy*0.25),1.0),
        Vector2(hy-minf(0.026,hy*0.25),0.985),
        Vector2(hy,0.79)
    ]
    var rings: Array = []
    for section in sections:
        var vertices: Array = []
        for p in outline:
            var sloped_y: float = section.x
            if section.x>0.0:
                sloped_y -= forward_cut*clampf((-p.y/maxf(hz,0.001)),0.0,1.0)
            vertices.append(Vector3(p.x*section.y,sloped_y,p.y*section.y))
        rings.append(vertices)
    var mesh_builder := SurfaceTool.new()
    mesh_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for index in range(rings.size()-1):
        var low: Array = rings[index]
        var high: Array = rings[index+1]
        for i in range(outline.size()):
            var j: int = (i+1)%outline.size()
            Hero._tri(mesh_builder,low[i],low[j],high[j])
            Hero._tri(mesh_builder,low[i],high[j],high[i])
    var bottom: Array = rings[0]
    var top: Array = rings[rings.size()-1]
    for i in range(outline.size()):
        var j: int = (i+1)%outline.size()
        Hero._tri(mesh_builder,Vector3(0.0,-hy,0.0),bottom[j],bottom[i])
        Hero._tri(mesh_builder,Vector3(0.0,hy-forward_cut*0.25,0.0),top[i],top[j])
    return mesh_builder.commit()

static func _replace(model: Node3D,label: String,shape: Mesh) -> bool:
    var original: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if original == null or original.mesh == null or shape == null:
        return false
    # This is NOT a decorative shape above the old cube. The original
    # mesh instance is preserved, which keeps the rotation and recoil rig.
    original.mesh = shape
    return true

static func _mat(model: Node3D,label: String,tint: Color,
        painted: bool) -> void:
    var part: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if part == null:
        return
    var material: StandardMaterial3D = Hero._army_material(tint,painted)
    material.roughness = 0.88 if painted else 0.69
    material.metallic = 0.13 if painted else 0.34
    if painted:
        material.normal_scale = 0.13
    part.material_override = material

static func _bolt_batch(turret: Node3D) -> int:
    # 8 seal fasteners per hatch. 16 transforms in ONE MultiMesh draw,
    # rather than 16 individually allocated MeshInstance3Ds.
    var node := MultiMeshInstance3D.new()
    node.name = "G09V19PernosEscotilla"
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    var bolt := BoxMesh.new()
    bolt.size = Vector3(0.018,0.010,0.023)
    mm.mesh = bolt
    mm.instance_count = BOLT_COUNT
    for hatch in range(2):
        var sign: float = -1.0 if hatch == 0 else 1.0
        var radius: float = HATCH_RADIUS[hatch]*0.82
        for i in range(8):
            var angle: float = TAU*float(i)/8.0
            mm.set_instance_transform(hatch*8+i,Transform3D(
                Basis(Vector3.UP,angle),
                Vector3(sign*0.40+radius*cos(angle),
                    0.690,0.25+radius*sin(angle))))
    node.multimesh = mm
    node.material_override = Hero._army_material(TITANIUM,false)
    turret.add_child(node)
    return mm.instance_count

static func _bearing(gun: Node3D) -> int:
    # One captured ring between mantlet and barrel, physically attached to
    # the existing ElevacionCanon pivot: no independent hovering collar.
    var bearing := MeshInstance3D.new()
    bearing.name = "G09V19SelloConjuntoCanon"
    var torus := TorusMesh.new()
    torus.inner_radius = 0.170
    torus.outer_radius = 0.221
    torus.rings = 8
    torus.ring_segments = 24
    bearing.mesh = torus
    bearing.material_override = Hero._army_material(GASKET,false)
    bearing.position = Vector3(0.0,0.0,-0.57)
    bearing.rotation_degrees.x = 90.0
    gun.add_child(bearing)
    for side in [-1,1]:
        var sign: float = float(side)
        Hero._rod(gun,"G09V19BisagraSoporte_%s" % side,
            Vector3(sign*0.263,-0.122,-0.359),
            Vector3(sign*0.185,-0.080,-0.587),0.018,STEEL)
    return 3

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_resculpt_v18",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var turret: Node3D = model.find_child(
        "TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child(
        "ElevacionCanon",true,false) as Node3D
    if turret == null or gun == null:
        return false
    for name in TOPOLOGY:
        var mesh: MeshInstance3D = model.find_child(
            name,true,false) as MeshInstance3D
        if mesh == null or mesh.mesh == null:
            return false

    if _hatch_cache.is_empty():
        for radius in HATCH_RADIUS:
            _hatch_cache.append(_hatch_mesh(radius))
    var updated: int = 0
    for i in range(2):
        if _replace(model,"EscotillaCircularV7_%02d" % i,_hatch_cache[i]):
            updated += 1
        _mat(model,"EscotillaCircularV7_%02d" % i,ROOF,true)

    # Two recessed crew optics; lower physically integrated vision heads.
    for side in [-1,1]:
        var name: String = "ModuloVisionIntegradoV7_%s" % side
        var optic_shape := _housing_mesh(
            Vector3(0.215,0.132,0.215),0.044,0.020)
        if _replace(model,name,optic_shape):
            updated+=1
        _mat(model,name,STEEL,false)

    var pieces := [
        ["CabezalPanoramicoG09V7",Vector3(0.225,0.130,0.212),0.045,0.015],
        ["EstacionRemotaBlindadaV7",Vector3(0.280,0.145,0.330),0.050,0.013],
        ["CollarBlindajeCanonV7",Vector3(0.385,0.345,0.112),0.063,0.0],
        ["CubiertaCompuestaFrontalG09_-1",Vector3(0.338,0.160,0.330),0.066,0.028],
        ["CubiertaCompuestaFrontalG09_1",Vector3(0.338,0.160,0.330),0.066,0.028],
        ["CubiertaMotorRectificadaV7",Vector3(1.390,0.066,0.790),0.061,0.0],
        ["EstibaBlindadaTraseraV7",Vector3(1.380,0.310,0.310),0.073,0.014],
        ["BancadaFumigenasV7_-1",Vector3(0.150,0.180,0.430),0.040,0.015],
        ["BancadaFumigenasV7_1",Vector3(0.150,0.180,0.430),0.040,0.015]
    ]
    for row in pieces:
        var label: String = row[0]
        var body: ArrayMesh = _housing_mesh(row[1],row[2],row[3])
        if _replace(model,label,body):
            updated+=1
        var painted: bool = label.begins_with("Cubierta") or (
            label.begins_with("Estiba"))
        _mat(model,label,COMPOSITE if painted else STEEL,painted)

    var hardware: int = _bolt_batch(turret)+_bearing(gun)
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_sculpt_v19",true)
    model.set_meta("tarvoka_mbt_sculpt_v19_replaced",updated)
    model.set_meta("tarvoka_mbt_sculpt_v19_hardware",hardware)
    return updated == REPLACED and hardware == BOLT_COUNT+3
