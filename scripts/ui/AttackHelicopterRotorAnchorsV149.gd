extends RefCounted
class_name TarvokaAttackHelicopterRotorAnchorsV149

# HAT-29 V14.9 - grounded rotor-root seats for the EXISTING V14.7
# hydraulic supports (+X) and V14.8 pitch-control clevises (-X).
# The exact V3 airfoil root is at y = +/-0.0185 and its thick bevel at
# z -0.225 reaches y = 0.035. Place all seats through these surfaces,
# not hovering above them. Geometry follows the four V1 rotor pivots.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const HINGES=preload("res://scripts/ui/AttackHelicopterPitchHingesV148.gd")
const FINISH=preload("res://scripts/ui/AttackHelicopterDamperFinishV147.gd")
const FLAG="tarvoka_a01_rotor_anchors_v149"
const ROOT="A01V149_AsientosFijacion_"
const STEEL=Color("#7c8c94")
const DARK=Color("#344149")
const BOLT=Color("#a7afb2")

static func _node(parent: Node3D,label: String) -> Node3D:
    return parent.find_child(label,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    for i in range(4):
        var pivot: Node3D=_node(rotor,V3.LEGACY_ROTOR+str(i))
        var root_part: Node3D=_node(rotor,ROOT+str(i))
        if pivot==null or root_part==null or root_part.get_parent()!=pivot:
            return false
    return true

static func _material(color: Color,metal: float,rough: float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    return mat

static func _mesh(parent: Node3D,label: String,shape: Mesh,
        position: Vector3,color: Color,metal: float=0.62,
        rough: float=0.49) -> MeshInstance3D:
    var node:=MeshInstance3D.new()
    node.name=label
    node.mesh=shape
    node.position=position
    node.material_override=_material(color,metal,rough)
    parent.add_child(node)
    return node

static func _seat(parent: Node3D,label: String,
        center: Vector3,size: Vector3) -> void:
    var box:=BoxMesh.new()
    box.size=size
    _mesh(parent,label,box,center,DARK,0.47,0.64)

static func _rod(parent: Node3D,label: String,a: Vector3,b: Vector3,
        radius: float,color: Color=STEEL) -> void:
    var diff: Vector3=b-a
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=diff.length()
    cylinder.radial_segments=12
    var item:=_mesh(parent,label,cylinder,(a+b)*0.5,color,0.67,0.43)
    item.quaternion=Quaternion(Vector3.UP,diff.normalized())

static func _bolt(parent: Node3D,label: String,at: Vector3) -> void:
    var bolt:=CylinderMesh.new()
    bolt.top_radius=0.010
    bolt.bottom_radius=0.010
    bolt.height=0.012
    bolt.radial_segments=6
    _mesh(parent,label,bolt,at,BOLT,0.71,0.42)

static func _join_pivot(pivot: Node3D,index: int) -> void:
    var layer:=Node3D.new()
    layer.name=ROOT+str(index)
    pivot.add_child(layer)
    # First pair of footplates deliberately intersects V3's EXISTING
    # beveled blade root ([-0.035,+0.035] Y), not the black 3D air above.
    _seat(layer,"A01V149_AsientoPasoInterior_%d" % index,
        Vector3(-0.096,0.038,-0.230),Vector3(0.057,0.015,0.086))
    _seat(layer,"A01V149_AsientoHidraulicoInterior_%d" % index,
        Vector3(0.098,0.038,-0.213),Vector3(0.057,0.015,0.092))
    # The far two footplates physically overlap the 0.037-thick V3
    # aerodynamic blade at z approx -0.40, not the now-ended root bevel.
    _seat(layer,"A01V149_AsientoPasoExterior_%d" % index,
        Vector3(-0.094,0.021,-0.401),Vector3(0.047,0.015,0.070))
    _seat(layer,"A01V149_AsientoHidraulicoExterior_%d" % index,
        Vector3(0.106,0.021,-0.421),Vector3(0.047,0.015,0.070))
    # All four struts terminate INSIDE existing V14.7/V14.8 clevis
    # hardware. Their lower end intersects the footplate volume.
    _rod(layer,"A01V149_PuentePasoInterior_%d" % index,
        Vector3(-0.096,0.040,-0.230),Vector3(-0.100,0.065,-0.223),0.017)
    _rod(layer,"A01V149_PuentePasoExterior_%d" % index,
        Vector3(-0.094,0.025,-0.401),Vector3(-0.096,0.078,-0.400),0.014)
    _rod(layer,"A01V149_PuenteHidraulicoInterior_%d" % index,
        Vector3(0.098,0.041,-0.213),Vector3(0.109,0.083,-0.188),0.015)
    _rod(layer,"A01V149_PuenteHidraulicoExterior_%d" % index,
        Vector3(0.106,0.026,-0.421),Vector3(0.109,0.066,-0.425),0.014)
    # Distinct actual raised heads, arranged in pairs on each footplate.
    for foot in range(4):
        var x: float=-0.096 if foot%2==0 else 0.101
        var z: float=-0.230 if foot<2 else -0.410
        var y: float=0.053 if foot<2 else 0.036
        for end in range(2):
            var delta: float=-0.020 if end==0 else 0.020
            _bolt(layer,"A01V149_PernoPie_%d_%d_%d" % [index,foot,end],
                Vector3(x,y,z+delta))

static func apply(model: Node3D) -> bool:
    if not HINGES.has_model(model) or not FINISH.has_model(model):
        return false
    if has_model(model):
        return true
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    for i in range(4):
        var pivot: Node3D=_node(rotor,V3.LEGACY_ROTOR+str(i))
        if pivot==null or _node(pivot,V3.BLADE+str(i))==null or (
                _node(pivot,HINGES.ROOT+str(i))==null or
                _node(pivot,FINISH.ROOT+str(i))==null):
            return false
    for i in range(4):
        _join_pivot(_node(rotor,V3.LEGACY_ROTOR+str(i)),i)
    model.set_meta(FLAG,true)
    return has_model(model)
