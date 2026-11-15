extends RefCounted
class_name TarvokaAPCUnifiedFlankV19

# P06 V19: sculpted factory transitions between V11 wheel arches,
# V18 inter-axle skirts and V14 static suspension anchorages.
# Sculpt and progressive damage only; no change to wheel mechanics.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V18 = preload("res://scripts/ui/APCWheelwellV18.gd")
const V17 = preload("res://scripts/ui/APCContourV17.gd")
const FLAG := "tarvoka_apc_unified_flank_v19"
const ROOT := "P06V19_CostadosContinuos"
const SEAMS := "P06V19_TransicionFaldones"
const ARCHES := "P06V19_JuntasArcos6x6"
const MOUNTS := "P06V19_RefuerzosAnclajeSuspension"
const IMPACTS := "P06V19_DanosProgresivosCostado"
const WRECK := "P06V19_RestosBlindajeLateral"
const MID_RIGHT := "P06V19_RematePuente_1_0"
const REAR_RIGHT := "P06V19_RematePuente_1_1"
const FRONT_LEFT := "P06V19_SelloArco_-1_0"
const MID_TORN := "P06V19_DesgarroPuenteMedio"
const REAR_TORN := "P06V19_DesgarroPuenteTrasero"
const FRONT_TORN := "P06V19_DesgarroArcoFrontal"
const SHOW := "tarvoka_apc_v19_visible"
const STAGE := "tarvoka_apc_v19_stage"
const RING_SECTORS := 8
# V11 outer radius = .452, V18 outer liner radius = .456.
# The new fixed rubber lip starts outside both; wheel radius = .35.
const SEAL_RADIUS_INNER := 0.460
const SEAL_RADIUS_OUTER := 0.481
const STATIC_CLEARANCE := SEAL_RADIUS_INNER - V1.WHEEL_RADIUS

static func _group(parent: Node3D, label: String) -> Node3D:
    var group := Node3D.new()
    group.name = label
    parent.add_child(group)
    return group

static func _solid(parent: Node3D, label: String,
        vertices: Array[Vector3], thickness: Vector3,
        material: Material) -> MeshInstance3D:
    return V17._sealed_plate(parent,label,vertices,thickness,material)

static func _box(parent: Node3D, label: String, at: Vector3,
        dims: Vector3, material: Material,
        orientation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return V17._box(parent,label,at,dims,material,orientation)

static func _skirts(parent: Node3D, paint: Material,
        steel: Material, gasket: Material) -> void:
    for side in [-1,1]:
        var s: float=float(side)
        for gap in range(2):
            var middle: float=0.5*(
                float(V1.WHEEL_Z[gap])+float(V1.WHEEL_Z[gap+1]))
            var segment: Node3D=_group(parent,
                "P06V19_RematePuente_%d_%d" % [side,gap])
            # Closed chamfer blends the lower V11 flank at x=.856,y=1.07
            # into the top of V18's actual x=.852,y=1.056 skirt.
            _solid(segment,"P06V19_ChaflanSuperior_%d_%d" % [side,gap],[
                Vector3(s*0.852,1.081,middle-0.216),
                Vector3(s*0.852,1.081,middle+0.216),
                Vector3(s*0.890,1.027,middle+0.204),
                Vector3(s*0.890,1.027,middle-0.204)
            ],Vector3(s*0.012,0.004,0),paint)
            # The lower sealed heel returns inside the original skirt.
            _solid(segment,"P06V19_TalonInferior_%d_%d" % [side,gap],[
                Vector3(s*0.901,0.716,middle-0.169),
                Vector3(s*0.901,0.716,middle+0.169),
                Vector3(s*0.858,0.660,middle+0.151),
                Vector3(s*0.858,0.660,middle-0.151)
            ],Vector3(s*0.015,-0.007,0),steel)
            # Narrow inset relief follows the side wall without obscuring
            # the faction paint. End caps sit above the tire envelope.
            _box(segment,"P06V19_CanalSombra_%d_%d" % [side,gap],
                Vector3(s*0.896,0.990,middle),
                Vector3(0.008,0.016,0.320),gasket)
            for end in [-1,1]:
                var at: float=middle+float(end)*0.151
                _solid(segment,"P06V19_CartelaEscalonada_%d_%d_%d" %
                    [side,gap,end],[
                    Vector3(s*0.891,0.944,at-0.024),
                    Vector3(s*0.903,0.834,at-0.014),
                    Vector3(s*0.893,0.801,at+0.016),
                    Vector3(s*0.877,0.926,at+0.028)
                ],Vector3(s*0.012,0.0,0.0),steel)

static func _arc_seals(parent: Node3D,
        rubber: Material, bolts: Material) -> void:
    for side in [-1,1]:
        var s: float=float(side)
        for axle in range(3):
            var center: float=float(V1.WHEEL_Z[axle])
            # Segmented physical radial seal lies OUTSIDE V18 liner and
            # V11 arch. Attached only to the hull, not the turning wheel.
            var ring: Node3D=_group(parent,
                "P06V19_SelloArco_%d_%d" % [side,axle])
            ring.set_meta("tarvoka_p06_v19_clearance",STATIC_CLEARANCE)
            for sector in range(RING_SECTORS):
                var a: float=deg_to_rad(
                    25.0+130.0*float(sector)/float(RING_SECTORS))
                var b: float=deg_to_rad(
                    25.0+130.0*float(sector+1)/float(RING_SECTORS))
                _solid(ring,
                    "P06V19_LabioCurvo_%d_%d_%d" % [side,axle,sector],[
                        Vector3(s*0.944,0.430+SEAL_RADIUS_INNER*sin(a),
                            center+SEAL_RADIUS_INNER*cos(a)),
                        Vector3(s*0.944,0.430+SEAL_RADIUS_INNER*sin(b),
                            center+SEAL_RADIUS_INNER*cos(b)),
                        Vector3(s*0.948,0.430+SEAL_RADIUS_OUTER*sin(b),
                            center+SEAL_RADIUS_OUTER*cos(b)),
                        Vector3(s*0.948,0.430+SEAL_RADIUS_OUTER*sin(a),
                            center+SEAL_RADIUS_OUTER*cos(a))
                    ],Vector3(s*0.012,0,0),rubber)
            # Little service screws located on the top arc and separated
            # from the V14 tire and V11 curved outer wheel guard.
            for index in range(3):
                var angle: float=deg_to_rad(57.0+33.0*float(index))
                _box(ring,"P06V19_PernoGuardapolvo_%d_%d_%d" %
                    [side,axle,index],
                    Vector3(s*0.965,
                        0.430+0.487*sin(angle),
                        center+0.487*cos(angle)),
                    Vector3(0.012,0.017,0.017),bolts)

static func _mounts(parent: Node3D, steel: Material,
        dark: Material) -> void:
    for side in [-1,1]:
        var s: float=float(side)
        for axle in range(3):
            var center: float=float(V1.WHEEL_Z[axle])
            # Tied to the static chassis assembly behind the liner.
            # x=.75-.83 is at the inner suspension mount; no control arms
            # are re-parented and none of the six wheel pivots are touched.
            var mount: Node3D=_group(parent,
                "P06V19_AnclajeVisible_%d_%d" % [side,axle])
            _solid(mount,
                "P06V19_CartelaSuspension_%d_%d" % [side,axle],[
                Vector3(s*0.739,0.851,center-0.119),
                Vector3(s*0.812,0.799,center-0.102),
                Vector3(s*0.821,0.711,center+0.041),
                Vector3(s*0.754,0.761,center+0.084)
            ],Vector3(s*0.016,0,0),steel)
            _box(mount,
                "P06V19_FijacionSuspension_%d_%d" % [side,axle],
                Vector3(s*0.814,0.792,center+0.021),
                Vector3(0.025,0.052,0.039),dark)

static func _damage(parent: Node3D,
        charred: Material, steel: Material,
        dark: Material) -> void:
    # Genuine separate fracture volumes, not an image/decals.
    var group: Node3D=_group(parent,IMPACTS)
    var medium: Node3D=_group(group,MID_TORN)
    _solid(medium,"P06V19_MuescaOxidadaPuente",[
        Vector3(0.902,1.023,-0.710),
        Vector3(0.928,0.961,-0.601),
        Vector3(0.951,0.809,-0.529),
        Vector3(0.891,0.823,-0.707)
    ],Vector3(0.019,0,-0.013),charred)
    _box(medium,"P06V19_PernoDesprendido",
        Vector3(0.935,0.855,-0.611),
        Vector3(0.036,0.044,0.058),steel,
        Vector3(0,-13.0,12.0))
    var severe: Node3D=_group(group,REAR_TORN)
    _solid(severe,"P06V19_CantoneraCizallada",[
        Vector3(0.895,1.045,0.303),
        Vector3(0.937,0.928,0.449),
        Vector3(0.986,0.727,0.539),
        Vector3(0.918,0.745,0.316)
    ],Vector3(0.022,-0.014,0.013),charred)
    _box(severe,"P06V19_CostillaSinCubierta",
        Vector3(0.928,0.760,0.433),
        Vector3(0.031,0.157,0.105),steel,
        Vector3(0,8,14))
    var front: Node3D=_group(group,FRONT_TORN)
    _solid(front,"P06V19_ArcoFrontalAplastado",[
        Vector3(-0.943,0.832,-1.355),
        Vector3(-0.954,0.909,-1.241),
        Vector3(-1.006,0.842,-1.181),
        Vector3(-0.971,0.742,-1.346)
    ],Vector3(-0.019,0.003,0.014),charred)
    _box(front,"P06V19_CorteCantonera",
        Vector3(-0.970,0.824,-1.270),
        Vector3(0.020,0.033,0.093),dark,
        Vector3(0,-8,14))
    var ruin: Node3D=_group(parent,WRECK)
    _solid(ruin,"P06V19_LaminaColapsada",[
        Vector3(0.851,0.850,0.345),
        Vector3(0.943,0.725,0.501),
        Vector3(0.991,0.539,0.548),
        Vector3(0.810,0.585,0.359)
    ],Vector3(0.030,0.013,0),charred)

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V18.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if hull==null:
        return false
    var paint: StandardMaterial3D=V17._mat(
        Color("#566869").lerp(faction_color,0.59),0.40,0.73)
    var steel: StandardMaterial3D=V17._mat(Color("#828c90"),0.64,0.61)
    var rubber: StandardMaterial3D=V17._mat(Color("#272d30"),0.10,0.94)
    var burn: StandardMaterial3D=V17._mat(Color("#332c29"),0.27,0.89)
    var root_group: Node3D=_group(hull,ROOT)
    var seams: Node3D=_group(root_group,SEAMS)
    _skirts(seams,paint,steel,rubber)
    var arch_group: Node3D=_group(root_group,ARCHES)
    _arc_seals(arch_group,rubber,steel)
    var supports: Node3D=_group(root_group,MOUNTS)
    _mounts(supports,steel,rubber)
    _damage(root_group,burn,steel,rubber)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    set_stage(model,0)
    return true

static func set_stage(model: Node3D, value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage: int=clampi(value,0,4)
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var intact: bool=enabled and stage<4
    for label in [SEAMS,ARCHES,MOUNTS]:
        var group: Node3D=model.find_child(label,true,false) as Node3D
        if group!=null:
            group.visible=intact
    for label in [MID_RIGHT,REAR_RIGHT,FRONT_LEFT]:
        var detail: Node3D=model.find_child(label,true,false) as Node3D
        if detail!=null:
            detail.visible=intact and (
                stage<2 if label==MID_RIGHT else stage<3)
    var damage_group: Node3D=model.find_child(IMPACTS,true,false) as Node3D
    if damage_group!=null:
        damage_group.visible=intact
    for label in [MID_TORN,REAR_TORN,FRONT_TORN]:
        var broken: Node3D=model.find_child(label,true,false) as Node3D
        if broken!=null:
            broken.visible=intact and (
                stage>=2 if label==MID_TORN else stage>=3)
    var ruins: Node3D=model.find_child(WRECK,true,false) as Node3D
    if ruins!=null:
        ruins.visible=enabled and stage==4
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D, enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
