extends RefCounted
class_name TarvokaLayeredBridgeArtV48

# Standalone prototype. The gameplay renderer must not instantiate this
# until layered movement, fog, selection and saves are integrated.
const CELL := 2.4
const DECK_TOP := 1.15
const DECK_BOTTOM := 0.94
const WATER_LEVEL := 0.0

static func _box(parent: Node3D,label: String,dimensions: Vector3,
        at: Vector3,tint: Color) -> void:
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.roughness = 0.92
    mesh.material = material
    var part := MeshInstance3D.new()
    part.name = label
    part.mesh = mesh
    part.position = at
    parent.add_child(part)

static func build(axis: String) -> Node3D:
    if axis not in ["ew","ns"]:
        return null
    var root := Node3D.new()
    root.name = "PuenteElevadoExperimentalV48"
    root.rotation.y = PI*0.5 if axis=="ns" else 0.0
    var concrete := Color("#a8aaa3")
    var metal := Color("#767f81")
    _box(root,"Tablero",Vector3(CELL,DECK_TOP-DECK_BOTTOM,1.48),
        Vector3(0,(DECK_TOP+DECK_BOTTOM)*0.5,0),concrete)
    _box(root,"Calzada",Vector3(CELL,0.04,1.26),
        Vector3(0,DECK_TOP+0.02,0),Color("#4f585e"))
    for side in [-1.0,1.0]:
        var z: float = float(side)*0.70
        _box(root,"Viga",Vector3(CELL,0.16,0.12),Vector3(0,DECK_BOTTOM+0.08,z),metal)
        _box(root,"Parapeto",Vector3(CELL,0.20,0.10),Vector3(0,DECK_TOP+0.12,z),concrete)
    for x in [-0.8,0.0,0.8]:
        _box(root,"Marca",Vector3(0.36,0.008,0.035),
            Vector3(x,DECK_TOP+0.044,0),Color("#e6dfb4"))
    root.set_meta("clearance",DECK_BOTTOM-WATER_LEVEL)
    root.set_meta("prototype_only",true)
    return root
