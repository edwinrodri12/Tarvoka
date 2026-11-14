extends RefCounted
class_name TarvokaTankSculptV18

# G09 V18 -- PRIMARY STRUCTURAL RESCULPT, not another decoration pass.
# The 28 original MeshInstance3D surfaces are remodeled IN PLACE. Their node
# names, chassis / yaw turret / elevating gun pivots, faction paint, 5 HP
# states and geometry links are preserved. Default Android G09 stays V10.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V18EsculturaEstructural"
const HULL := Color("#455B66")
const TURRET := Color("#425762")
const SHOULDER := Color("#61747E")
const CERAMIC := Color("#6A7982")
const RUBBER := Color("#2B3338")
const SEAM := Color("#24343D")
const WHEEL_COUNT := 7
const SUB_ASSEMBLIES := [
    "CorazaSoldadaHermeticaV7","TorreBajaSoldadaV7",
    "MantleteConjuntoV7","FaldonBlindadoIntegradoV7_-1",
    "FaldonBlindadoIntegradoV7_1"
]
static var _shared_wheel: ArrayMesh

static func _side_polygon(side: int,points: Array) -> Array:
    var result: Array = []
    for point in points:
        result.append(Vector2(float(side)*point.x,point.y))
    if side < 0:
        result.reverse()
    return result

static func _swap_loft(model: Node3D,label: String,
        outline: Array,sections: Array) -> bool:
    var part: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if part == null or part.mesh == null:
        return false
    # Temporary mesh is discarded immediately: the actual old node and
    # material stay connected to the turret recoil/HP damage rig.
    var parent: Node3D = part.get_parent() as Node3D
    if parent == null:
        return false
    var temporary: MeshInstance3D = Hero._loft(
        parent,"__V18_REPLACEMENT",outline,sections)
    part.mesh = temporary.mesh
    temporary.free()
    return true

static func _gun_cradle_mesh() -> ArrayMesh:
    # Chamfered tapered 8-sided mechanical sleeve along the gun's local Z,
    # replacing the earlier rectangular mantlet IN PLACE.
    var outline := [
        Vector2(-0.205,-0.222),Vector2(0.205,-0.222),
        Vector2(0.362,-0.126),Vector2(0.362,0.109),
        Vector2(0.220,0.227),Vector2(-0.220,0.227),
        Vector2(-0.362,0.109),Vector2(-0.362,-0.126)
    ]
    var stations := [
        [0.188,0.80],[0.105,1.03],[-0.075,1.00],
        [-0.231,0.83],[-0.330,0.60]
    ]
    var rings: Array = []
    for row in stations:
        var ring: Array = []
        for pt in outline:
            ring.append(Vector3(pt.x*float(row[1]),
                pt.y*float(row[1]),float(row[0])))
        rings.append(ring)
    var tool := SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    for section in range(rings.size()-1):
        var a: Array = rings[section]
        var b: Array = rings[section+1]
        for i in range(outline.size()):
            var next: int = (i+1)%outline.size()
            Hero._tri(tool,a[i],a[next],b[next])
            Hero._tri(tool,a[i],b[next],b[i])
    var start: Array = rings[0]
    var end: Array = rings[rings.size()-1]
    for i in range(outline.size()):
        var next: int = (i+1)%outline.size()
        Hero._tri(tool,Vector3(0,0,0.188),start[next],start[i])
        Hero._tri(tool,Vector3(0,0,-0.330),end[i],end[next])
    return tool.commit()

static func _roadwheel_mesh() -> ArrayMesh:
    if _shared_wheel != null:
        return _shared_wheel
    # Eight axial sections create a depressed central dish, steel rim and
    # a double-sloped rubber shoulder in ONE real watertight mesh.
    # The visual wheel uses a separate unchanged cap and animated spokes.
    # Local Y is the axle (the original node rotates this geometry Z=90).
    var sections := [
        Vector2(-0.059,0.0),Vector2(-0.052,0.069),
        Vector2(-0.048,0.112),Vector2(-0.056,0.156),
        Vector2(-0.040,0.185),Vector2(0.018,0.189),
        Vector2(0.048,0.163),Vector2(0.055,0.0)
    ]
    const SIDES := 24
    var rings: Array = []
    for point in sections:
        var ring: Array = []
        for spoke in range(SIDES):
            var angle: float = TAU*float(spoke)/float(SIDES)
            ring.append(Vector3(
                point.y*cos(angle),point.x,point.y*sin(angle)))
        rings.append(ring)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for layer in range(rings.size()-1):
        var low: Array = rings[layer]
        var high: Array = rings[layer+1]
        for i in range(SIDES):
            var next: int = (i+1)%SIDES
            Hero._tri(st,low[i],low[next],high[next])
            Hero._tri(st,low[i],high[next],high[i])
    _shared_wheel = st.commit()
    return _shared_wheel

static func _suspension(hull: Node3D) -> void:
    # 14 coherent steel rocker links are batched into ONE MultiMesh draw
    # submission, not fourteen individual accessory blocks.
    var rig := MultiMeshInstance3D.new()
    rig.name = "G09V18BrazosSuspension"
    var batch := MultiMesh.new()
    batch.transform_format = MultiMesh.TRANSFORM_3D
    var arm := BoxMesh.new()
    arm.size = Vector3(0.32,0.072,0.10)
    batch.mesh = arm
    batch.instance_count = 2*WHEEL_COUNT
    for index in range(WHEEL_COUNT):
        for side_i in range(2):
            var sign: float = -1.0 if side_i == 0 else 1.0
            var pos := Vector3(sign*1.125,0.365,-1.13+float(index)*0.377)
            var angle: float = -0.18 if (index%2)==0 else 0.16
            var basis := Basis(Vector3.FORWARD,sign*angle)
            batch.set_instance_transform(index*2+side_i,
                Transform3D(basis,pos))
    rig.multimesh = batch
    rig.material_override = Hero._army_material(SEAM,false)
    hull.add_child(rig)

static func _material(model: Node3D, label: String,
        color: Color,metallic: float,roughness: float) -> bool:
    var piece: MeshInstance3D = model.find_child(
        label,true,false) as MeshInstance3D
    if piece == null:
        return false
    # Use the same authored shared 256px grain/normal in existing Hero
    # layers; don't allocate unique maps for each hard-surface segment.
    var material := Hero._army_material(color,true)
    material.metallic = metallic
    material.roughness = roughness
    material.normal_scale = 0.17
    piece.material_override = material
    return true

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_fx_v17",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child(
        "ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child(
        "TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    var expected: Array = SUB_ASSEMBLIES.duplicate()
    expected.append("G09V14QuillaFrontal")
    for side in [-1,1]:
        for name in ["G09V14AlaBlindadaFrontal_",
                "G09V14LomoBlindadoCentral_",
                "G09V14HombroMotorPosterior_",
                "G09V14CarrilleraEscalonada_"]:
            expected.append(name+str(side))
        for index in range(WHEEL_COUNT):
            expected.append("RuedaG09V7_%s_%02d" % [side,index])
    for label in expected:
        var item: MeshInstance3D = model.find_child(
            label,true,false) as MeshInstance3D
        if item == null or item.mesh == null:
            return false

    var replacements: int = 0
    # Re-cut the load-bearing armored shell itself: pointed welded glacis,
    # true taper through the shoulders and clipped engine stern. It is the
    # same primary G09 chassis node, NOT a new slab over the old surface.
    if _swap_loft(model,"CorazaSoldadaHermeticaV7",[
        Vector2(-0.22,-2.04),Vector2(0.22,-2.04),
        Vector2(0.66,-1.72),Vector2(0.97,-1.30),
        Vector2(1.12,-0.82),Vector2(1.14,0.82),
        Vector2(0.89,1.37),Vector2(0.64,1.60),
        Vector2(-0.64,1.60),Vector2(-0.89,1.37),
        Vector2(-1.14,0.82),Vector2(-1.12,-0.82),
        Vector2(-0.97,-1.30),Vector2(-0.70,-1.61)
    ],[[0.38,0.90,0.025],[0.49,0.994,0.058],
        [0.89,1.0,0.105],[1.045,0.94,0.194],
        [1.103,0.835,0.217]]):
        replacements+=1

    # Turret is a single sharp-nose, rear-heavy armored polygon, not an
    # old rectangular box hidden by cheek modules. Y levels are LOCAL to
    # the current yaw pivot and cannot alter gun recoil/elevation.
    if _swap_loft(model,"TorreBajaSoldadaV7",[
        Vector2(-0.165,-1.78),Vector2(0.165,-1.78),
        Vector2(0.49,-1.53),Vector2(0.88,-0.91),
        Vector2(1.01,-0.39),Vector2(0.97,0.43),
        Vector2(0.83,0.99),Vector2(0.57,1.25),
        Vector2(-0.57,1.25),Vector2(-0.83,0.99),
        Vector2(-0.97,0.43),Vector2(-1.01,-0.39),
        Vector2(-0.88,-0.91),Vector2(-0.56,-1.21)
    ],[[0.065,0.858,0.016],[0.154,0.998,0.026],
        [0.385,1.005,0.047],[0.603,0.906,0.062],
        [0.667,0.787,0.071]]):
        replacements+=1

    var mantlet: MeshInstance3D = model.find_child(
        "MantleteConjuntoV7",true,false) as MeshInstance3D
    mantlet.mesh = _gun_cradle_mesh()
    replacements+=1

    # Refit the authentic broad skirt *under* the ten thin faction stripes.
    # Side identification remains separated from the neutral armored shell.
    for side in [-1,1]:
        var key: String = str(side)
        if _swap_loft(model,"FaldonBlindadoIntegradoV7_"+key,[
            Vector2(-0.071,-1.31),Vector2(0.075,-1.31),
            Vector2(0.079,-1.10),Vector2(0.079,0.91),
            Vector2(0.048,1.31),Vector2(-0.070,1.31)
        ],[[-0.177,0.91,0.0],[-0.085,0.992,0.0],
            [0.085,1.005,0.0],[0.170,0.916,0.0]]):
            replacements+=1

        if _swap_loft(model,"G09V14AlaBlindadaFrontal_"+key,
                _side_polygon(side,[
            Vector2(0.46,-1.70),Vector2(0.77,-1.78),
            Vector2(1.13,-1.54),Vector2(1.32,-1.23),
            Vector2(1.33,-0.82),Vector2(1.12,-0.73),
            Vector2(0.62,-1.17)
        ]),[[0.813,0.889,0.025],[1.006,0.999,0.064],
            [1.124,0.872,0.101]]):
            replacements+=1
        if _swap_loft(model,"G09V14LomoBlindadoCentral_"+key,
                _side_polygon(side,[
            Vector2(0.96,-0.69),Vector2(1.32,-0.69),
            Vector2(1.35,0.66),Vector2(1.20,0.83),
            Vector2(0.89,0.82)
        ]),[[0.805,0.918,0.0],[1.012,1.001,0.0],
            [1.135,0.850,0.0]]):
            replacements+=1
        if _swap_loft(model,"G09V14HombroMotorPosterior_"+key,
                _side_polygon(side,[
            Vector2(0.90,0.80),Vector2(1.23,0.82),
            Vector2(1.31,1.26),Vector2(1.12,1.52),
            Vector2(0.83,1.49)
        ]),[[0.807,0.926,0.0],[1.004,1.005,0.0],
            [1.130,0.855,0.0]]):
            replacements+=1
        if _swap_loft(model,"G09V14CarrilleraEscalonada_"+key,
                _side_polygon(side,[
            Vector2(0.31,-1.66),Vector2(0.56,-1.63),
            Vector2(0.89,-1.43),Vector2(1.078,-0.94),
            Vector2(0.98,-0.54),Vector2(0.70,-0.48),
            Vector2(0.36,-0.94)
        ]),[[0.150,0.866,0.025],[0.347,1.005,0.035],
            [0.515,0.936,0.046],[0.635,0.771,0.069]]):
            replacements+=1

    if _swap_loft(model,"G09V14QuillaFrontal",[
        Vector2(-0.19,-1.97),Vector2(0.19,-1.97),
        Vector2(0.40,-1.70),Vector2(-0.40,-1.70)
    ],[[0.783,0.88,0.038],[0.930,1.008,0.061],
        [1.056,0.845,0.104]]):
        replacements+=1

    # Same 14 road-wheel nodes and original spoke animation. Reuse ONE
    # dished wheel mesh for both sides, all seven axles.
    for side in [-1,1]:
        for index in range(WHEEL_COUNT):
            var wheel: MeshInstance3D = model.find_child(
                "RuedaG09V7_%s_%02d" % [side,index],true,false) as MeshInstance3D
            wheel.mesh = _roadwheel_mesh()
            replacements+=1
        var spokes: MultiMeshInstance3D = model.find_child(
            "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
        if spokes != null and spokes.multimesh != null:
            var rib := BoxMesh.new()
            rib.size = Vector3(0.009,0.014,0.081)
            spokes.multimesh.mesh = rib
            spokes.material_override = Hero._army_material(SEAM,false)

    _suspension(hull)
    _material(model,"CorazaSoldadaHermeticaV7",HULL,0.21,0.83)
    _material(model,"TorreBajaSoldadaV7",TURRET,0.18,0.87)
    _material(model,"MantleteConjuntoV7",SHOULDER,0.25,0.79)
    for side in [-1,1]:
        var key: String = str(side)
        _material(model,"FaldonBlindadoIntegradoV7_"+key,HULL,0.17,0.88)
        _material(model,"G09V14AlaBlindadaFrontal_"+key,CERAMIC,0.11,0.92)
        _material(model,"G09V14LomoBlindadoCentral_"+key,SHOULDER,0.18,0.87)
        _material(model,"G09V14HombroMotorPosterior_"+key,SHOULDER,0.18,0.89)
        _material(model,"G09V14CarrilleraEscalonada_"+key,CERAMIC,0.13,0.90)
        for index in range(WHEEL_COUNT):
            _material(model,"RuedaG09V7_%s_%02d" % [side,index],
                RUBBER,0.20,0.79)
    _material(model,"G09V14QuillaFrontal",SHOULDER,0.19,0.85)
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    model.set_meta("tarvoka_mbt_resculpt_v18",true)
    model.set_meta("tarvoka_mbt_resculpt_v18_replaced",replacements)
    return replacements == 28
