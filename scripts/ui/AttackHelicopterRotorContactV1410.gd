extends RefCounted
class_name TarvokaAttackHelicopterRotorContactV1410

# A01 HAT-29 V14.10 - polish the EXISTING V14.9 footplates in place.
# No extra rotors, extra parts, or changes to flight, damage or faction coats.
# V14.9 plate tops were y=0.0455/0.0285 but all bolt bottoms were 0.0015
# higher than those surfaces. Fit each real bolt into the underlying plate.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V149=preload("res://scripts/ui/AttackHelicopterRotorAnchorsV149.gd")
const FLAG="tarvoka_a01_rotor_contact_v1410"
const ENABLED="tarvoka_a01_v1410_enabled"
const ORIGINAL_MESH="a01_v1410_original_mesh"
const ORIGINAL_MATERIAL="a01_v1410_original_material"
const ORIGINAL_BOLT_Y="a01_v1410_original_bolt_y"
const CONTACT_PENETRATION=0.0015
const SEATS=[
    "A01V149_AsientoPasoInterior_",
    "A01V149_AsientoHidraulicoInterior_",
    "A01V149_AsientoPasoExterior_",
    "A01V149_AsientoHidraulicoExterior_"
]

static func _node(parent: Node3D,name: String) -> MeshInstance3D:
    return parent.find_child(name,true,false) as MeshInstance3D

static func has_model(model: Node3D) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    if not V149.has_model(model):
        return false
    for i in range(4):
        for foot in range(4):
            var seat: MeshInstance3D=_node(model,SEATS[foot]+str(i))
            if seat==null or not seat.has_meta(ORIGINAL_MESH):
                return false
            for end in range(2):
                var pin: MeshInstance3D=_node(model,
                    "A01V149_PernoPie_%d_%d_%d" % [i,foot,end])
                if pin==null or not pin.has_meta(ORIGINAL_BOLT_Y):
                    return false
    return true

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)
    st.add_vertex(a)
    st.add_vertex(c)
    st.add_vertex(d)

static func _corners(x: float,z: float,y: float) -> Array[Vector3]:
    # CCW when viewed from above in Godot's XZ coordinates.
    return [
        Vector3(-x,y,-z),Vector3(-x,y,z),
        Vector3(x,y,z),Vector3(x,y,-z)
    ]

static func _chamfered_seat(size: Vector3) -> ArrayMesh:
    # True solid prism with bevelled top perimeter, not a decal or a
    # box duplicate; one mesh replaces exactly one original V14.9 box.
    var hx: float=size.x*0.5
    var hy: float=size.y*0.5
    var hz: float=size.z*0.5
    var inset: float=minf(0.004,minf(hx,hz)*0.25)
    var base: Array[Vector3]=_corners(hx,hz,-hy)
    var shoulder: Array[Vector3]=_corners(hx,hz,hy-inset)
    var top: Array[Vector3]=_corners(hx-inset,hz-inset,hy)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    _quad(st,top[0],top[1],top[2],top[3])
    _quad(st,base[3],base[2],base[1],base[0])
    for edge in range(4):
        var next: int=(edge+1)%4
        _quad(st,base[edge],base[next],shoulder[next],shoulder[edge])
        _quad(st,shoulder[edge],shoulder[next],top[next],top[edge])
    st.generate_normals()
    return st.commit()

static func _replace_one(seat: MeshInstance3D,
        first: bool) -> bool:
    if first:
        if not (seat.mesh is BoxMesh):
            return false
        seat.set_meta(ORIGINAL_MESH,seat.mesh)
        seat.set_meta(ORIGINAL_MATERIAL,seat.material_override)
    var before: Mesh=seat.get_meta(ORIGINAL_MESH) as Mesh
    if not (before is BoxMesh):
        return false
    var source: BoxMesh=before as BoxMesh
    seat.mesh=_chamfered_seat(source.size)
    var prior: StandardMaterial3D=seat.get_meta(
        ORIGINAL_MATERIAL) as StandardMaterial3D
    if prior!=null:
        var polished: StandardMaterial3D=prior.duplicate() as StandardMaterial3D
        # Retain neutral graphite; refine only reflectance of plate material.
        polished.metallic=0.55
        polished.roughness=0.52
        seat.material_override=polished
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    for i in range(4):
        for foot in range(4):
            var seat: MeshInstance3D=_node(model,SEATS[foot]+str(i))
            if enabled:
                if not _replace_one(seat,false):
                    return false
            else:
                seat.mesh=seat.get_meta(ORIGINAL_MESH) as Mesh
                seat.material_override=seat.get_meta(
                    ORIGINAL_MATERIAL) as Material
            var source: BoxMesh=seat.get_meta(ORIGINAL_MESH) as BoxMesh
            var plate_top: float=seat.position.y+source.size.y*0.5
            for end in range(2):
                var pin: MeshInstance3D=_node(model,
                    "A01V149_PernoPie_%d_%d_%d" % [i,foot,end])
                var cylinder: CylinderMesh=pin.mesh as CylinderMesh
                if enabled:
                    # A slight physical overlap prevents daylight under the
                    # pin but avoids hiding its visible top face.
                    pin.position.y=plate_top+cylinder.height*0.5-CONTACT_PENETRATION
                else:
                    pin.position.y=float(pin.get_meta(ORIGINAL_BOLT_Y))
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D) -> bool:
    if not V149.has_model(model):
        return false
    if has_model(model):
        return set_enabled(model,true)
    # Preflight the entire assembly before changing a single mesh.
    for i in range(4):
        for foot in range(4):
            var seat: MeshInstance3D=_node(model,SEATS[foot]+str(i))
            if seat==null or not (seat.mesh is BoxMesh):
                return false
            for end in range(2):
                var pin: MeshInstance3D=_node(model,
                    "A01V149_PernoPie_%d_%d_%d" % [i,foot,end])
                if pin==null or not (pin.mesh is CylinderMesh):
                    return false
    for i in range(4):
        for foot in range(4):
            var seat: MeshInstance3D=_node(model,SEATS[foot]+str(i))
            if not _replace_one(seat,true):
                return false
            for end in range(2):
                var pin: MeshInstance3D=_node(model,
                    "A01V149_PernoPie_%d_%d_%d" % [i,foot,end])
                pin.set_meta(ORIGINAL_BOLT_Y,pin.position.y)
    model.set_meta(FLAG,true)
    return set_enabled(model,true)
