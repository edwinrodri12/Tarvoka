extends RefCounted
class_name TarvokaAttackHelicopterPitchHingesV148

# HAT-29 A01 V14.8: actual 3D pitch-control hinge finish, on the V1/V3
# blade pivots. These are not independent rotors or duplicated dampers.
# The V14.7 hydraulic piston remains on +X; these real links use -X.
# High-detail hero model only (UnitModels3D art_level >= 13).
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const Finish147=preload("res://scripts/ui/AttackHelicopterDamperFinishV147.gd")
const FLAG="tarvoka_a01_pitch_hinges_v148"
const ROOT="A01V148_ArticulacionPasoAspa_"
const STEEL=Color("#8e9da2")
const GRAPHITE=Color("#344047")
const RUBBER=Color("#263237")
const BRONZE=Color("#6c6860")

static func _find(parent: Node3D,label: String) -> Node3D:
    return parent.find_child(label,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var rotor: Node3D=_find(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    for i in range(4):
        var pivot: Node3D=_find(rotor,V3.LEGACY_ROTOR+str(i))
        var hinge: Node3D=_find(rotor,ROOT+str(i))
        if pivot==null or hinge==null or hinge.get_parent()!=pivot:
            return false
    return true

static func _material(color: Color,metal: float,rough: float) -> StandardMaterial3D:
    var mat:=StandardMaterial3D.new()
    mat.albedo_color=color
    mat.metallic=metal
    mat.roughness=rough
    return mat

static func _piece(parent: Node3D,label: String,shape: Mesh,
        position: Vector3,color: Color,metal: float=0.65,
        rough: float=0.45) -> MeshInstance3D:
    var item:=MeshInstance3D.new()
    item.name=label
    item.mesh=shape
    item.position=position
    item.material_override=_material(color,metal,rough)
    parent.add_child(item)
    return item

static func _bar(parent: Node3D,label: String,a: Vector3,b: Vector3,
        radius: float,color: Color,metal: float=0.67,
        rough: float=0.44) -> MeshInstance3D:
    var direction: Vector3=b-a
    var pipe:=CylinderMesh.new()
    pipe.top_radius=radius
    pipe.bottom_radius=radius
    pipe.height=direction.length()
    pipe.radial_segments=12
    var item:=_piece(parent,label,pipe,(a+b)*0.5,color,metal,rough)
    item.quaternion=Quaternion(Vector3.UP,direction.normalized())
    return item

static func _box(parent: Node3D,label: String,pos: Vector3,
        size: Vector3,color: Color,metal: float=0.57,
        rough: float=0.51) -> void:
    var cuboid:=BoxMesh.new()
    cuboid.size=size
    _piece(parent,label,cuboid,pos,color,metal,rough)

static func _pin(parent: Node3D,label: String,pos: Vector3,
        radius: float,color: Color) -> void:
    var pin:=CylinderMesh.new()
    pin.top_radius=radius
    pin.bottom_radius=radius
    pin.height=0.060
    pin.radial_segments=12
    _piece(parent,label,pin,pos,color,0.71,0.39)

static func _finish_pivot(pivot: Node3D,index: int) -> void:
    var layer:=Node3D.new()
    layer.name=ROOT+str(index)
    pivot.add_child(layer)
    # All coordinates are within the ORIGINAL V3 blade-root pivot.
    # The outboard side is the opposite (-X) of the V14.7 damper.
    # Each of the two small clevises actually touches a blade-root saddle.
    _box(layer,"A01V148_BaseBisagra_%d" % index,
        Vector3(-0.100,0.078,-0.223),
        Vector3(0.067,0.046,0.100),GRAPHITE)
    _bar(layer,"A01V148_HorquillaInterior_%d" % index,
        Vector3(-0.090,0.102,-0.217),
        Vector3(-0.152,0.098,-0.230),0.013,STEEL)
    _bar(layer,"A01V148_HorquillaExterior_%d" % index,
        Vector3(-0.096,0.075,-0.400),
        Vector3(-0.161,0.088,-0.399),0.013,STEEL)
    # Continuous mechanical pitch-control link outside the blade surface.
    _bar(layer,"A01V148_BieletaControlPaso_%d" % index,
        Vector3(-0.152,0.098,-0.230),
        Vector3(-0.161,0.088,-0.399),0.014,STEEL)
    _bar(layer,"A01V148_ManguitoRegulacion_%d" % index,
        Vector3(-0.155,0.095,-0.293),
        Vector3(-0.157,0.093,-0.336),0.022,GRAPHITE,0.49,0.61)
    # Raised pin heads, retaining washers and a separate rubber dust guard.
    for end in range(2):
        var x: float=-0.152 if end==0 else -0.161
        var y: float=0.098 if end==0 else 0.088
        var z: float=-0.230 if end==0 else -0.399
        _pin(layer,"A01V148_Pasador_%d_%d" % [index,end],
            Vector3(x,y,z),0.024,STEEL)
        _bar(layer,"A01V148_Arandela_%d_%d" % [index,end],
            Vector3(x,y+0.030,z),Vector3(x,y+0.040,z),
            0.033,BRONZE,0.63,0.47)
    _bar(layer,"A01V148_FundaProteccion_%d" % index,
        Vector3(-0.157,0.093,-0.339),
        Vector3(-0.159,0.091,-0.360),
        0.024,RUBBER,0.02,0.90)

static func apply(model: Node3D) -> bool:
    if not Finish147.has_model(model):
        return false
    if has_model(model):
        return true
    var rotor: Node3D=_find(model,V1.MAIN_ROTOR)
    if rotor==null:
        return false
    # Validate ALL pivots first; never leave a partially built helicopter.
    for i in range(4):
        if _find(rotor,V3.LEGACY_ROTOR+str(i))==null:
            return false
    for i in range(4):
        _finish_pivot(_find(rotor,V3.LEGACY_ROTOR+str(i)),i)
    model.set_meta(FLAG,true)
    return has_model(model)
