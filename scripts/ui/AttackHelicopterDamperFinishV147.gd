extends RefCounted
class_name TarvokaAttackHelicopterDamperFinishV147

# V14.7 HAT-29 - read actual hydraulic dampers from close-up cameras.
# Keeps the V14.6 geometry/rotor rig and its 8 faction paint schemes;
# the slight OUTBOARD displacement exposes the hardware beside the blade
# root, while short clevis arms visibly reconnect it to the original pivot.
# Hero preview only: installed by UnitModels3D at art_level >= 13.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V146=preload("res://scripts/ui/AttackHelicopterRotorDampersV146.gd")
const FLAG="tarvoka_a01_damper_finish_v147"
const ROOT="A01V147_ConectoresVisiblesAmortiguador_"
const DETAIL="A01V147_CollaresYFuelles_"
const OUTBOARD=0.075
const UP=0.025
const GRAPHITE=Color("#344249")
const STEEL=Color("#a7b8bd")
const ALLOY=Color("#73868d")
const RUBBER=Color("#273137")

static func _node(root: Node3D,name: String) -> Node3D:
    return root.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    for i in range(4):
        if _node(model,ROOT+str(i))==null or (
                _node(model,DETAIL+str(i))==null):
            return false
    return true

static func _group(parent: Node3D,name: String) -> Node3D:
    var group:=Node3D.new()
    group.name=name
    parent.add_child(group)
    return group

static func _rod(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,
        color: Color,metallic: float=0.68,
        roughness: float=0.44) -> MeshInstance3D:
    var direction: Vector3=b-a
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=direction.length()
    cylinder.radial_segments=12
    var item:=MeshInstance3D.new()
    item.name=name
    item.mesh=cylinder
    item.position=(a+b)*0.5
    item.quaternion=Quaternion(Vector3.UP,direction.normalized())
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metallic
    mat.roughness=roughness
    item.material_override=mat
    parent.add_child(item)
    return item

static func _finish_pivot(arm: Node3D,index: int) -> void:
    var damper: Node3D=_node(arm,V146.DAMPER+str(index))
    # Original V14.6 had X=0.116, partially below the V3 airfoil;
    # move its ENTIRE existing damper, not a replacement or detached copy.
    damper.position=Vector3(OUTBOARD,UP,0)
    var support:=_group(arm,ROOT+str(index))
    for joint in range(2):
        var z: float=-0.188 if joint==0 else -0.425
        var end_y: float=0.083 if joint==0 else 0.066
        _rod(support,"A01V147_HorquillaRaiz_%d_%d" % [index,joint],
            Vector3(0.109,end_y,z),
            Vector3(0.116+OUTBOARD,end_y+UP,z),
            0.012,ALLOY)
    var detail:=_group(damper,DETAIL+str(index))
    # Machined end sleeves around the unchanged V14.6 real cylinder.
    for sleeve in range(2):
        var z: float=-0.216 if sleeve==0 else -0.293
        _rod(detail,"A01V147_CollarMecanizado_%d_%d" % [index,sleeve],
            Vector3(0.116,0.081,z-0.011),
            Vector3(0.116,0.081,z+0.011),
            0.032,STEEL,0.73,0.35)
    # Three discrete elastomer ridges give an actual bellows contour,
    # rather than making the dust boot look like an untextured solid rod.
    for rib in range(3):
        var z: float=-0.306-float(rib)*0.017
        _rod(detail,"A01V147_NervioFuelle_%d_%d" % [index,rib],
            Vector3(0.116,0.076,z-0.006),
            Vector3(0.116,0.076,z+0.006),
            0.035,RUBBER,0.02,0.92)
    # Two small high-contrast nuts on the pin axes clarify the clevis.
    for nut in range(2):
        var z: float=-0.188 if nut==0 else -0.425
        var y: float=0.083 if nut==0 else 0.066
        _rod(detail,"A01V147_TuercaAnclaje_%d_%d" % [index,nut],
            Vector3(0.116,y-0.025,z),
            Vector3(0.116,y+0.025,z),
            0.017,GRAPHITE,0.55,0.48)
    var barrel: MeshInstance3D=_node(
        damper,"A01V146_CuerpoHidraulico_%d" % index) as MeshInstance3D
    if barrel!=null:
        # The old housing was nearly indistinguishable from the black blade.
        # Only this independent metal part gets a brushed gray variant;
        # no faction enamel, blade material, or texture is changed.
        var before: StandardMaterial3D=barrel.material_override as StandardMaterial3D
        if before!=null and not barrel.has_meta("v147_original_material"):
            barrel.set_meta("v147_original_material",before)
            var steel_barrel: StandardMaterial3D=before.duplicate() as StandardMaterial3D
            steel_barrel.albedo_color=Color("#677981")
            steel_barrel.metallic=0.59
            steel_barrel.roughness=0.48
            barrel.material_override=steel_barrel

static func apply(model: Node3D) -> bool:
    if not V146.has_model(model):
        return false
    if has_model(model):
        return true
    var rotor: Node3D=_node(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    for i in range(4):
        var arm: Node3D=_node(rotor,V3.LEGACY_ROTOR+str(i))
        if arm==null or _node(arm,V146.DAMPER+str(i))==null:
            return false
    for i in range(4):
        _finish_pivot(_node(rotor,V3.LEGACY_ROTOR+str(i)),i)
    model.set_meta(FLAG,true)
    return true
