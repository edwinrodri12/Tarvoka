extends RefCounted
class_name TarvokaAPCWheelwellV18

# Bastion P06 V18 -- genuine 3D side-wheelwell finishing and staged damage.
# Thin solid armor bridges the two gaps between the three axles on each side.
# The inner arch follows the rotating wheel with >0.05 m radial clearance,
# but is attached to the STATIC chassis, never to the spinning wheel.
# Godot 4.3 art-only: does not modify HP, navigation, wheels or combat rules.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V17 = preload("res://scripts/ui/APCContourV17.gd")
const FLAG := "tarvoka_apc_wheelwell_v18"
const BODY := "P06V18_FaldasLaterales6x6"
const ARCHES := "P06V18_InterioresSeisPasosRueda"
const DAMAGE := "P06V18_BlindajeRasgadoCritico"
const WRECK := "P06V18_RestosLateralDestruido"
const SHOW := "tarvoka_apc_v18_visible"
const STAGE := "tarvoka_apc_v18_stage"
const MID_PANEL := "P06V18_PanelPuente_1_0"
const REAR_PANEL := "P06V18_PanelPuente_1_1"
const FRONT_LINER := "P06V18_ArcoInterior_-1_0"
const MID_TORN := "P06V18_RoturaMediaDerecha"
const REAR_TORN := "P06V18_ChapaTraseraArrancada"
const FRONT_TORN := "P06V18_ArcoFrontalDesgarrado"
const ARCH_SEGMENTS := 6
const ARCH_RADIUS := 0.414
const MIN_WHEEL_CLEARANCE := ARCH_RADIUS - V1.WHEEL_RADIUS

static func _group(parent: Node3D, label: String) -> Node3D:
    var g := Node3D.new()
    g.name = label
    parent.add_child(g)
    return g

static func _closed(parent: Node3D, label: String, points: Array[Vector3],
        depth: Vector3, material: Material) -> MeshInstance3D:
    return V17._sealed_plate(parent,label,points,depth,material)

static func _box(parent: Node3D, label: String, where: Vector3,
        dimensions: Vector3, material: Material,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return V17._box(parent,label,where,dimensions,material,angles)

static func _bridges(parent: Node3D, enamel: Material, metal: Material,
        shadow: Material) -> void:
    # At y=.67, the +/- .20 m span is outside the .35 m tire radius
    # of each wheel centre; ends at z midpoint +/- .19, so the tires
    # still steer, rotate and vertically oscillate under the armor.
    for side in [-1,1]:
        var s: float = float(side)
        for gap in range(2):
            var center: float = (
                float(V1.WHEEL_Z[gap])+float(V1.WHEEL_Z[gap+1]))*0.5
            _closed(parent,"P06V18_PanelPuente_%d_%d" % [side,gap],[
                Vector3(s*0.852,1.056,center-0.233),
                Vector3(s*0.852,1.056,center+0.233),
                Vector3(s*0.903,0.682,center+0.185),
                Vector3(s*0.903,0.682,center-0.185)
            ],Vector3(s*0.020,0.0,0.0),enamel)
            _closed(parent,"P06V18_BiselInferior_%d_%d" % [side,gap],[
                Vector3(s*0.901,0.699,center-0.188),
                Vector3(s*0.901,0.699,center+0.188),
                Vector3(s*0.862,0.665,center+0.163),
                Vector3(s*0.862,0.665,center-0.163)
            ],Vector3(0.0,-0.014,0.0),metal)
            # Real inset repair channel: two short metal brackets sit above
            # the bottom line, not as large opaque boxes between the tires.
            for end in [-1,1]:
                var z: float = center+float(end)*0.158
                _box(parent,"P06V18_CartelaUnion_%d_%d_%d" %
                    [side,gap,end],Vector3(s*0.911,0.783,z),
                    Vector3(0.022,0.125,0.027),metal,
                    Vector3(0,0,s*7.0))
            _box(parent,"P06V18_SelloInterior_%d_%d" % [side,gap],
                Vector3(s*0.837,0.781,center),
                Vector3(0.013,0.100,0.294),shadow)

static func _wheelwell(parent: Node3D, enamel: Material,
        iron: Material) -> void:
    for side in [-1,1]:
        var s: float = float(side)
        for axle in range(3):
            var center: float = float(V1.WHEEL_Z[axle])
            # Fixed inner liners are ring-shaped real strips behind V11's
            # outer arch. The inner radius .414 is larger than the .35 tire.
            # These are *not* children of wheel transforms.
            var group: Node3D = _group(parent,
                "P06V18_ArcoInterior_%d_%d" % [side,axle])
            group.set_meta("tarvoka_p06_v18_radial_clearance",
                MIN_WHEEL_CLEARANCE)
            for segment in range(ARCH_SEGMENTS):
                var a: float = deg_to_rad(
                    35.0+110.0*float(segment)/float(ARCH_SEGMENTS))
                var b: float = deg_to_rad(
                    35.0+110.0*float(segment+1)/float(ARCH_SEGMENTS))
                var z: float = center
                _closed(group,"P06V18_CurvaGuardapolvo_%d_%d_%d" %
                    [side,axle,segment],[
                    Vector3(s*0.916,0.430+ARCH_RADIUS*sin(a),
                        z+ARCH_RADIUS*cos(a)),
                    Vector3(s*0.916,0.430+ARCH_RADIUS*sin(b),
                        z+ARCH_RADIUS*cos(b)),
                    Vector3(s*0.923,0.430+(ARCH_RADIUS+0.042)*sin(b),
                        z+(ARCH_RADIUS+0.042)*cos(b)),
                    Vector3(s*0.923,0.430+(ARCH_RADIUS+0.042)*sin(a),
                        z+(ARCH_RADIUS+0.042)*cos(a))
                ],Vector3(s*0.017,0.0,0.0),
                iron if segment%2==0 else enamel)
            # Narrow lower inner splash shield follows the body, not tires.
            _box(group,"P06V18_AletasAntisalpicadura_%d_%d" %
                [side,axle],Vector3(s*0.821,0.677,center+0.326),
                Vector3(0.026,0.085,0.073),iron,
                Vector3(0,0,s*5.0))

static func _damaged(parent: Node3D, hot: Material,
        dark: Material, iron: Material) -> void:
    # Right side armor bridge opens at moderate damage; the original
    # intact bridge is hidden, replaced with a distinct folded solid plate.
    var middle: Node3D = _group(parent,MID_TORN)
    _closed(middle,"P06V18_BordeAbiertoDerecho",[
        Vector3(0.868,1.038,-0.701),
        Vector3(0.918,0.970,-0.537),
        Vector3(0.959,0.686,-0.486),
        Vector3(0.883,0.721,-0.714)
    ],Vector3(0.028,-0.012,0.014),hot)
    _box(middle,"P06V18_RefuerzoRetorcidoDerecho",
        Vector3(0.931,0.731,-0.602),
        Vector3(0.049,0.093,0.223),iron,
        Vector3(0.0,-13.0,19.0))
    var rear: Node3D = _group(parent,REAR_TORN)
    _closed(rear,"P06V18_PanelDerechoDesprendido",[
        Vector3(0.878,1.039,0.379),
        Vector3(0.934,0.974,0.610),
        Vector3(0.997,0.718,0.552),
        Vector3(0.914,0.738,0.367)
    ],Vector3(0.026,0.006,-0.021),hot)
    _box(rear,"P06V18_CostillaFracturada",
        Vector3(0.947,0.736,0.480),
        Vector3(0.066,0.058,0.170),dark,
        Vector3(14,0,11))
    var front: Node3D = _group(parent,FRONT_TORN)
    _closed(front,"P06V18_ProtectorIzquierdoTorcido",[
        Vector3(-0.918,0.775,-1.336),
        Vector3(-0.915,0.817,-1.167),
        Vector3(-0.982,0.901,-1.115),
        Vector3(-0.957,0.733,-1.333)
    ],Vector3(-0.036,-0.019,0.014),hot)

static func _destroyed(parent: Node3D, black: Material,
        iron: Material) -> void:
    # Remnants on the real hull, only when completely destroyed.
    # No duplicated pristine panels remain below them.
    var wreck := _group(parent,WRECK)
    _closed(wreck,"P06V18_FaldaDerechaColapsada",[
        Vector3(0.851,0.906,-0.686),
        Vector3(0.935,0.778,-0.490),
        Vector3(1.016,0.565,-0.421),
        Vector3(0.826,0.651,-0.700)
    ],Vector3(0.026,0.012,0.020),black)
    _box(wreck,"P06V18_RielCostadoCizallado",
        Vector3(-0.883,0.683,0.504),
        Vector3(0.064,0.068,0.401),iron,
        Vector3(7,13,-17))
    wreck.visible=false

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V17.FLAG,false)) or not (
            bool(model.get_meta(V14.FLAG,false))):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if hull==null:
        return false
    var paint: StandardMaterial3D=V17._mat(
        Color("#596b6b").lerp(faction_color,0.62),0.34,0.76)
    var steel: StandardMaterial3D=V17._mat(
        Color("#818d91"),0.63,0.61)
    var shadow: StandardMaterial3D=V17._mat(
        Color("#273037"),0.15,0.95)
    var burn: StandardMaterial3D=V17._mat(
        Color("#34312e"),0.23,0.91)
    var body: Node3D=_group(hull,BODY)
    _bridges(body,paint,steel,shadow)
    var arches: Node3D=_group(hull,ARCHES)
    _wheelwell(arches,paint,shadow)
    var damaged: Node3D=_group(hull,DAMAGE)
    _damaged(damaged,burn,shadow,steel)
    _destroyed(hull,burn,steel)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    set_stage(model,0)
    return true

static func set_stage(model: Node3D, value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int=clampi(value,0,4)
    var shown: bool=bool(model.get_meta(SHOW,true))
    var intact: bool=shown and stage<4
    for label in [BODY,ARCHES]:
        var root: Node3D=model.find_child(label,true,false) as Node3D
        if root!=null:
            root.visible=intact
    for label in [MID_PANEL,REAR_PANEL,FRONT_LINER]:
        var piece: Node3D=model.find_child(label,true,false) as Node3D
        if piece!=null:
            var breaks: bool=(
                stage>=2 if label==MID_PANEL else
                (stage>=3))
            piece.visible=intact and not breaks
    var effects: Node3D=model.find_child(DAMAGE,true,false) as Node3D
    if effects!=null:
        effects.visible=intact
    for label in [MID_TORN,REAR_TORN,FRONT_TORN]:
        var torn: Node3D=model.find_child(label,true,false) as Node3D
        if torn!=null:
            torn.visible=intact and (
                stage>=2 if label==MID_TORN else stage>=3)
    var wreck: Node3D=model.find_child(WRECK,true,false) as Node3D
    if wreck!=null:
        wreck.visible=shown and stage==4
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D, shown: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,shown)
    return set_stage(model,int(model.get_meta(STAGE,0)))
