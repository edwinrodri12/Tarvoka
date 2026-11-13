extends RefCounted
class_name TarvokaTankDetailV14

# G09 V14: a legible, distinctly sculpted hull at battle-camera scale.
# Grounded in the live V13 model, not a replacement 2D art asset.
# Every new shell stays visual-only and keeps the gun/turret/chassis pivots.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const V10 = preload("res://scripts/ui/TankArmorV10.gd")
const ROOT := "G09V14CorazaEscalonada"
const MATTE := Color("#536873")
const CERAMIC := Color("#7C909A")
const SHADE := Color("#263940")
const DARK := Color("#1A2C34")
const WHEEL_COUNT := 7
const SPOKES := 5

static func _shell(parent: Node3D,name: String,polygon: Array,
        levels: Array,paint: Color) -> MeshInstance3D:
    return Hero._loft(parent,name,polygon,levels,paint)

static func _wheel_transform(side: int, wheel: int, spoke: int,
        phase: float) -> Transform3D:
    # BoxMesh length follows the actual disk radius, rotating about the
    # axle (X) rather than counter-rotating the complete tank mesh.
    var theta: float = TAU*float(spoke)/float(SPOKES) + phase
    var z_center: float = -1.13+float(wheel)*0.377
    return Transform3D(Basis(Vector3.RIGHT,theta),
        Vector3(float(side)*1.405,
            0.290+sin(theta)*0.081,
            z_center+cos(theta)*0.081))

static func _wheels(hull: Node3D, side: int) -> void:
    # The previous solid cylinder appeared stationary while the tracks moved.
    # 35 spokes / side share ONE MultiMesh material and ONE draw submission.
    var node := MultiMeshInstance3D.new()
    node.name = "G09V14RadiosRuedas_%s" % side
    var mm := MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    var spoke := BoxMesh.new()
    spoke.size = Vector3(0.015,0.021,0.105)
    mm.mesh = spoke
    mm.instance_count = WHEEL_COUNT*SPOKES
    for wheel in range(WHEEL_COUNT):
        for i in range(SPOKES):
            mm.set_instance_transform(wheel*SPOKES+i,
                _wheel_transform(side,wheel,i,0.0))
    node.multimesh = mm
    node.material_override = Hero._army_material(Color("#8B999D"),false)
    hull.add_child(node)

static func animate_wheels(model: Node3D, travel: float) -> void:
    if model == null or not model.get_meta("tarvoka_mbt_silhouette_v14",false):
        return
    var phase: float = travel*TAU*1.7
    for side in [-1,1]:
        var node: MultiMeshInstance3D = model.find_child(
            "G09V14RadiosRuedas_%s" % side,true,false) as MultiMeshInstance3D
        if node == null or node.multimesh == null:
            continue
        for wheel in range(WHEEL_COUNT):
            for spoke in range(SPOKES):
                node.multimesh.set_instance_transform(
                    wheel*SPOKES+spoke,
                    _wheel_transform(side,wheel,spoke,phase))

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_segmented_v13",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)

    # Raised, continuous forward shoulders visibly transform the side and
    # frontal outline even at 170 px. V13 side cells remain exposed below;
    # 14 faction-color plates remain fully independent near y=0.72.
    for side in [-1,1]:
        var sign: float = float(side)
        var front := [
            Vector2(sign*0.37,-1.73),
            Vector2(sign*0.72,-1.79),
            Vector2(sign*1.26,-1.58),
            Vector2(sign*1.50,-1.17),
            Vector2(sign*1.47,-0.64),
            Vector2(sign*0.96,-0.70),
            Vector2(sign*0.52,-1.18)
        ]
        if side < 0:
            front.reverse()
        _shell(hull,"G09V14AlaBlindadaFrontal_%s" % side,
            front,[[0.925,0.898,0.018],[1.047,1.003,0.044],
                [1.213,0.900,0.070]],CERAMIC)

        var middle := [
            Vector2(sign*0.99,-0.54),Vector2(sign*1.47,-0.54),
            Vector2(sign*1.50,0.62),Vector2(sign*1.37,0.86),
            Vector2(sign*0.91,0.84)
        ]
        if side < 0:
            middle.reverse()
        _shell(hull,"G09V14LomoBlindadoCentral_%s" % side,
            middle,[[0.907,0.945,0.0],[1.064,1.0,0.0],
                [1.202,0.863,0.0]],MATTE)
        Hero._rod(hull,"G09V14NervioLongitudinal_%s" % side,
            Vector3(sign*1.422,1.102,-0.39),
            Vector3(sign*1.432,1.092,0.56),0.023,SHADE)

        var rear := [
            Vector2(sign*0.91,0.91),Vector2(sign*1.34,0.90),
            Vector2(sign*1.36,1.29),Vector2(sign*1.22,1.53),
            Vector2(sign*0.86,1.43)
        ]
        if side < 0:
            rear.reverse()
        _shell(hull,"G09V14HombroMotorPosterior_%s" % side,
            rear,[[0.912,0.964,0.0],[1.078,1.01,0.0],
                [1.177,0.874,0.0]],MATTE)
        Hero._rod(hull,"G09V14CantoProa_%s" % side,
            Vector3(sign*1.213,1.138,-1.55),
            Vector3(sign*1.470,1.142,-1.13),0.027,SHADE)

        # Massive angled front jaw adds a distinct faceted turret profile.
        # It follows the turret yaw and never touches ElevacionCanon.
        var cheek := [
            Vector2(sign*0.28,-1.70),Vector2(sign*0.61,-1.70),
            Vector2(sign*1.17,-1.22),Vector2(sign*1.20,-0.77),
            Vector2(sign*0.88,-0.48),Vector2(sign*0.40,-0.86)
        ]
        if side < 0:
            cheek.reverse()
        _shell(turret,"G09V14CarrilleraEscalonada_%s" % side,
            cheek,[[0.286,0.880,0.010],[0.418,1.005,0.018],
                [0.609,0.944,0.040],[0.732,0.766,0.046]],CERAMIC)
        Hero._rod(turret,"G09V14JuntaCarrillera_%s" % side,
            Vector3(sign*0.89,0.618,-1.31),
            Vector3(sign*1.097,0.610,-0.88),0.023,DARK)
        _wheels(hull,side)

    # Small central angled nose plate separates the two lateral wings.
    # Neither a bright light bar nor a copied real-world vehicle emblem.
    _shell(hull,"G09V14QuillaFrontal",[
        Vector2(-0.29,-1.89),Vector2(0.29,-1.89),
        Vector2(0.47,-1.61),Vector2(-0.47,-1.61)
    ],[[0.828,0.89,0.045],[0.948,1.0,0.035],
        [1.076,0.87,0.055]],MATTE)
    model.set_meta("tarvoka_mbt_silhouette_v14",true)
    return true

static func finish_materials(model: Node3D) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_silhouette_v14",false):
        return 0
    var count: int = 0
    for item in model.find_children("G09V14*","MeshInstance3D",true,false):
        var mesh: MeshInstance3D = item as MeshInstance3D
        var origin: StandardMaterial3D = mesh.material_override as StandardMaterial3D
        if origin == null:
            continue
        var m: StandardMaterial3D = origin.duplicate(true) as StandardMaterial3D
        var edge: bool = "Nervio" in mesh.name or "Junta" in mesh.name or "Canto" in mesh.name
        var ceramic: bool = "Frontal" in mesh.name or "Carrillera" in mesh.name
        m.albedo_color = SHADE if edge else (CERAMIC if ceramic else MATTE)
        m.albedo_texture = null if edge else V10._enamel_mask(ceramic)
        m.normal_enabled = not edge
        m.normal_texture = null if edge else Hero._army_micro_normal()
        m.normal_scale = 0.18
        m.roughness_texture = null if edge else Hero._army_micro_roughness()
        m.roughness = 0.89 if ceramic else (0.80 if edge else 0.75)
        m.metallic = 0.10 if ceramic else 0.21
        m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        mesh.material_override = m
        count+=1
    model.set_meta("tarvoka_mbt_silhouette_v14_pbr_count",count)
    return count
