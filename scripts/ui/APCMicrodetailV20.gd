extends RefCounted
class_name TarvokaAPCMicrodetailV20

# P06 V20 -- physical finishing, not a texture or an engine mock-up.
# Tiny native 3D weld beads, bolt heads, washers, and fracture transitions
# on V19 skirt joints and six static wheel arches. No combat/physics edits.
const V1 = preload("res://scripts/ui/APCArtV1.gd")
const V16 = preload("res://scripts/ui/APCJointFinishV16.gd")
const V17 = preload("res://scripts/ui/APCContourV17.gd")
const V19 = preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const FLAG := "tarvoka_apc_microdetail_v20"
const ROOT := "P06V20_MicroacabadosBlindaje"
const WELDS := "P06V20_CordonesFaldones"
const FASTENERS := "P06V20_RemachesArcosYAnclajes"
const LIGHT := "P06V20_MarcasDanoLeve"
const MEDIUM := "P06V20_RoturaSoldaduraMedia"
const CRITICAL := "P06V20_FracturasCriticas"
const WRECK := "P06V20_RestosSoldaduras"
const MID_RIGHT := "P06V20_CosturaPuente_1_0"
const REAR_RIGHT := "P06V20_CosturaPuente_1_1"
const FRONT_LEFT := "P06V20_RemachesArco_-1_0"
const SHOW := "tarvoka_apc_v20_visible"
const STAGE := "tarvoka_apc_v20_stage"
const WHEEL_GROUPS := 6
const SKIRT_GROUPS := 4
const RIVETS_PER_SKIRT := 3
const RIVETS_PER_ARCH := 3

static func _group(parent: Node3D, label: String) -> Node3D:
    var group := Node3D.new()
    group.name=label
    parent.add_child(group)
    return group

static func _material(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    return V17._mat(color,metal,rough)

static func _weld(parent: Node3D, label: String,
        point_a: Vector3, point_b: Vector3,
        material: Material, radius: float=0.006) -> MeshInstance3D:
    return V16._seam(parent,label,point_a,point_b,radius,material)

static func _bolt(parent: Node3D, label: String, at: Vector3,
        metal: Material, washer: Material) -> void:
    # A closed hexagonal cap and a physical washer on a common axis.
    # Both are fixed to the hull, never to a wheel rotation pivot.
    for layer in range(2):
        var head := CylinderMesh.new()
        head.top_radius=0.013 if layer==0 else 0.019
        head.bottom_radius=head.top_radius
        head.height=0.011 if layer==0 else 0.006
        head.radial_segments=6 if layer==0 else 12
        var mesh:=MeshInstance3D.new()
        mesh.name="%s_%s" % [label,"Hex" if layer==0 else "Arandela"]
        mesh.mesh=head
        mesh.material_override=metal if layer==0 else washer
        mesh.position=at+Vector3((0.011 if at.x>=0 else -0.011) if layer==0 else 0,0,0)
        mesh.rotation_degrees.z=90
        parent.add_child(mesh)

static func _skirt_finish(parent: Node3D, paint: Material,
        weldmat: Material, steel: Material, gasket: Material) -> void:
    for side in [-1,1]:
        var s: float=float(side)
        for gap in range(2):
            var z: float=0.5*(
                float(V1.WHEEL_Z[gap])+float(V1.WHEEL_Z[gap+1]))
            var group: Node3D=_group(parent,
                "P06V20_CosturaPuente_%d_%d" % [side,gap])
            # Continuous but narrow weld from the V19 upper bevel to V18
            # skirt; it does not cross any wheel's radial sweep envelope.
            _weld(group,"P06V20_CordonSuperior_%d_%d" % [side,gap],
                Vector3(s*0.906,1.023,z-0.183),
                Vector3(s*0.906,1.023,z+0.183),weldmat,0.006)
            _weld(group,"P06V20_CordonTalón_%d_%d" % [side,gap],
                Vector3(s*0.915,0.707,z-0.151),
                Vector3(s*0.915,0.707,z+0.151),steel,0.005)
            # The three small paired heads sit on the fixed skirt panel.
            for screw in range(RIVETS_PER_SKIRT):
                _bolt(group,
                    "P06V20_PernoFaldon_%d_%d_%d" % [side,gap,screw],
                    Vector3(s*0.916,0.946,z-0.137+0.137*float(screw)),
                    steel,gasket)
            # Narrow enamel-painted end returns make bolts appear inset.
            for direction in [-1,1]:
                var zz: float=z+float(direction)*0.158
                V17._box(group,
                    "P06V20_RematePintado_%d_%d_%d" % [side,gap,direction],
                    Vector3(s*0.897,0.850,zz),
                    Vector3(0.013,0.077,0.018),paint)

static func _arch_finish(parent: Node3D, steel: Material,
        gasket: Material) -> void:
    for side in [-1,1]:
        var s: float=float(side)
        for axle in range(3):
            var z: float=float(V1.WHEEL_Z[axle])
            var group: Node3D=_group(parent,
                "P06V20_RemachesArco_%d_%d" % [side,axle])
            # Hardware is outside the physical tire radius (0.35m).
            # No existing wheel/suspension node is replaced or reparented.
            for index in range(RIVETS_PER_ARCH):
                var angle: float=deg_to_rad(57.0+32.0*float(index))
                _bolt(group,
                    "P06V20_PernoArco_%d_%d_%d" % [side,axle,index],
                    Vector3(s*0.964,0.430+0.505*sin(angle),
                        z+0.505*cos(angle)),steel,gasket)
            _weld(group,
                "P06V20_UnionFijaSuspension_%d_%d" % [side,axle],
                Vector3(s*0.806,0.844,z-0.085),
                Vector3(s*0.826,0.788,z+0.073),
                steel,0.006)

static func _damage_meshes(parent: Node3D, metal: Material,
        scar: Material, soot: Material) -> void:
    var light: Node3D=_group(parent,LIGHT)
    # Short depressions and a loosened bolt are visible already at stage 1.
    _weld(light,"P06V20_RayaSuperficial",
        Vector3(0.926,0.969,-0.667),
        Vector3(0.931,0.908,-0.604),scar,0.004)
    V17._box(light,"P06V20_CabezaRemacheGolpeado",
        Vector3(0.947,0.929,-0.582),
        Vector3(0.020,0.012,0.024),metal,
        Vector3(0,0,22))
    var medium: Node3D=_group(parent,MEDIUM)
    V17._sealed_plate(medium,
        "P06V20_SoldaduraAbierta",[
            Vector3(0.908,1.023,-0.685),
            Vector3(0.941,0.983,-0.635),
            Vector3(0.965,0.843,-0.574),
            Vector3(0.918,0.864,-0.698)
        ],Vector3(0.016,0.005,-0.014),scar)
    _weld(medium,"P06V20_AristaMetalExpuesta",
        Vector3(0.944,0.978,-0.641),
        Vector3(0.961,0.852,-0.575),metal,0.007)
    var critical: Node3D=_group(parent,CRITICAL)
    V17._sealed_plate(critical,
        "P06V20_DesgarroTrasero",[
            Vector3(0.921,1.041,0.354),
            Vector3(0.965,0.945,0.458),
            Vector3(1.005,0.741,0.514),
            Vector3(0.937,0.773,0.328)
        ],Vector3(0.020,-0.008,0.011),soot)
    V17._sealed_plate(critical,
        "P06V20_BordeArcoFrontalPartido",[
            Vector3(-0.942,0.873,-1.332),
            Vector3(-0.970,0.924,-1.236),
            Vector3(-1.012,0.839,-1.169),
            Vector3(-0.953,0.787,-1.344)
        ],Vector3(-0.019,0.001,0.013),scar)
    _weld(critical,"P06V20_CableFijacionExpuesto",
        Vector3(0.975,0.943,0.452),
        Vector3(0.933,0.809,0.338),metal,0.008)
    var wreck: Node3D=_group(parent,WRECK)
    V17._sealed_plate(wreck,
        "P06V20_CordonSeparadoRuina",[
            Vector3(0.844,0.843,-0.677),
            Vector3(0.946,0.745,-0.531),
            Vector3(1.009,0.565,-0.438),
            Vector3(0.836,0.616,-0.681)
        ],Vector3(0.021,0.012,0.013),soot)

static func apply(model: Node3D, faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V19.FLAG,false)):
        return false
    if bool(model.get_meta(FLAG,false)):
        return true
    var hull: Node3D=model.find_child(V1.ROOT,true,false) as Node3D
    if hull==null:
        return false
    var paint:=_material(Color("#57696a").lerp(faction_color,0.63),0.43,0.75)
    var steel:=_material(Color("#899498"),0.69,0.62)
    var gasket:=_material(Color("#2b3032"),0.15,0.93)
    var dark:=_material(Color("#3d3935"),0.32,0.86)
    var soot:=_material(Color("#252423"),0.17,0.96)
    var root_node: Node3D=_group(hull,ROOT)
    _skirt_finish(_group(root_node,WELDS),paint,steel,steel,gasket)
    _arch_finish(_group(root_node,FASTENERS),steel,gasket)
    _damage_meshes(root_node,steel,dark,soot)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    set_stage(model,0)
    return true

static func set_stage(model: Node3D, value: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var stage:int=clampi(value,0,4)
    var shown:bool=bool(model.get_meta(SHOW,true))
    var intact:bool=shown and stage<4
    for group_name in [WELDS,FASTENERS]:
        var group:Node3D=model.find_child(group_name,true,false) as Node3D
        if group!=null:
            group.visible=intact
    for label in [MID_RIGHT,REAR_RIGHT,FRONT_LEFT]:
        var part:Node3D=model.find_child(label,true,false) as Node3D
        if part!=null:
            part.visible=intact and (
                stage<2 if label==MID_RIGHT else stage<3)
    var light:Node3D=model.find_child(LIGHT,true,false) as Node3D
    if light!=null:
        light.visible=intact and stage>=1
    var medium:Node3D=model.find_child(MEDIUM,true,false) as Node3D
    if medium!=null:
        medium.visible=intact and stage>=2
    var critical:Node3D=model.find_child(CRITICAL,true,false) as Node3D
    if critical!=null:
        critical.visible=intact and stage>=3
    var wreck:Node3D=model.find_child(WRECK,true,false) as Node3D
    if wreck!=null:
        wreck.visible=shown and stage==4
    model.set_meta(STAGE,stage)
    return true

static func set_enabled(model: Node3D, shown: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,shown)
    return set_stage(model,int(model.get_meta(STAGE,0)))
