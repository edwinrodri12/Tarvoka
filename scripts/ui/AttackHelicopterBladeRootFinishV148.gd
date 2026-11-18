extends RefCounted
class_name TarvokaAttackHelicopterBladeRootFinishV148

# HAT-29 V14.8: physical blade-root fork plates, transverse hinge pins,
# and restrained fastening bands. ALL geometry is a child of the four
# original V1/V3 rotating blade pivots. Does not create another swashplate,
# hinge controller, or duplicate the V14.5 crown/V14.7 damper.
# This hero-only sculpt is not constructed for Android tactical LOD10.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V147=preload("res://scripts/ui/AttackHelicopterDamperFinishV147.gd")
const FLAG="tarvoka_a01_blade_root_finish_v148"
const ROOT="A01V148_ArticulacionRaizAspa_"
const PIN="A01V148_PasadorTransversal_"
const CHEEK="A01V148_OrejaHorquilla_"
const BAND="A01V148_AbrazaderaRaiz_"
const NUT="A01V148_TuercaRetencion_"
const BLACK=Color("#354249")
const ALLOY=Color("#829399")
const BOLT=Color("#adb8ba")

static func _part(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    for i in range(4):
        if _part(model,ROOT+str(i))==null:
            return false
    return true

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _mesh(parent: Node3D,name: String,
        shape: Mesh,position: Vector3,color: Color,
        metal: float=0.61,rough: float=0.49) -> MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=name
    item.mesh=shape
    item.position=position
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    item.material_override=mat
    parent.add_child(item)
    return item

static func _box(parent: Node3D,name: String,
        at: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
    var box:=BoxMesh.new()
    box.size=dimensions
    return _mesh(parent,name,box,at,color)

static func _axis_pin(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,color: Color,
        sides: int=12) -> MeshInstance3D:
    var axis: Vector3=b-a
    var mesh:=CylinderMesh.new()
    mesh.top_radius=radius
    mesh.bottom_radius=radius
    mesh.height=axis.length()
    mesh.radial_segments=sides
    var pin:=_mesh(parent,name,mesh,(a+b)*0.5,color)
    pin.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return pin

static func _finish_blade(pivot: Node3D,i: int) -> void:
    var finish:=_group(pivot,ROOT+str(i))
    # V3 original beveled blade root extends X +/-0.115, Z -0.105..-0.345,
    # and Y +/-0.035. Two thin fork plates hug its sides without covering
    # the airfoil or overlapping the offset V14.7 damper (X about 0.19).
    for side in [-1,1]:
        var sign: float=float(side)
        _box(finish,CHEEK+str(i)+"_"+str(side),
            Vector3(sign*0.129,0.068,-0.218),
            Vector3(0.018,0.080,0.215),BLACK)
    # One complete real crosspin through the two fork plates; visible hex
    # retaining heads. These are hardware, NOT a second rotational pivot.
    _axis_pin(finish,PIN+str(i),
        Vector3(-0.143,0.105,-0.142),
        Vector3(0.143,0.105,-0.142),0.020,ALLOY)
    for side in [-1,1]:
        var sign: float=float(side)
        _axis_pin(finish,NUT+str(i)+"_"+str(side),
            Vector3(sign*0.141,0.105,-0.142),
            Vector3(sign*0.161,0.105,-0.142),
            0.031,BOLT,6)
    # Two restrained collar bands along the near blade root. They follow
    # the original airfoil, do not repaint its surface, and expose fastening
    # at macro zoom without widening the approved rotor silhouette.
    for index in range(2):
        var z: float=-0.350-float(index)*0.078
        _box(finish,BAND+str(i)+"_"+str(index),
            Vector3(0.005,0.041,z),
            Vector3(0.184,0.016,0.021),ALLOY)
        for side in [-1,1]:
            var sign: float=float(side)
            _axis_pin(finish,"A01V148_PernoAbrazadera_%d_%d_%d" % [
                    i,index,side],
                Vector3(sign*0.067,0.053,z),
                Vector3(sign*0.067,0.071,z),
                0.013,BOLT,6)

static func apply(model: Node3D) -> bool:
    if not V147.has_model(model):
        return false
    if has_model(model):
        return true
    var rotor: Node3D=_part(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    # Prevalidate ALL four pivots before adding any geometry.
    for i in range(4):
        if _part(rotor,V3.LEGACY_ROTOR+str(i))==null:
            return false
    for i in range(4):
        _finish_blade(_part(rotor,V3.LEGACY_ROTOR+str(i)),i)
    model.set_meta(FLAG,true)
    return true
