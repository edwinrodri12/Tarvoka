extends RefCounted
class_name TarvokaAttackHelicopterTailV11

# A01 V11: physical tail-transmission and rocket-pylon detailing.
# A separate editable high-detail studio overlay: no combat statistics, LOD,
# original rotor pivots, V10 glass, or faction markings are replaced.
const V1=preload("res://scripts/ui/AttackHelicopterV1.gd")
const V3=preload("res://scripts/ui/AttackHelicopterRotorV3.gd")
const V10=preload("res://scripts/ui/AttackHelicopterFinishV10.gd")
const FLAG := "tarvoka_a01_tail_armament_v11"
const ENABLED := "tarvoka_a01_tail_armament_v11_enabled"
const ROOT := "A01V11_TransmisionYArmamento"
const TAIL_HUB := "A01V11_CuboRotorCola"
const PYLONS := "A01V11_AnclajesLanzadores"
const GEARBOX := "A01V11_CajaReductoraCola"
const SHAFT := "A01V11_EjeTransmisionCola"
const RETAINER := "A01V11_CollarBocaLanzador_"
const PITCH_LINK := "A01V11_BielaPasoCola_"

static func _part(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

static func has_model(model: Node3D) -> bool:
    return model!=null and bool(model.get_meta(FLAG,false)) and (
        _part(model,ROOT)!=null and _part(model,TAIL_HUB)!=null
        and _part(model,PYLONS)!=null)

static func _group(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _material(color: Color,metal: float=0.48,
        rough: float=0.41) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=color
    m.metallic=metal
    m.roughness=rough
    return m

static func _mesh(parent: Node3D,name: String,shape: Mesh,
        color: Color,pos: Vector3=Vector3.ZERO,
        metal: float=0.48) -> MeshInstance3D:
    var m:=MeshInstance3D.new()
    m.name=name
    m.mesh=shape
    m.material_override=_material(color,metal)
    m.position=pos
    parent.add_child(m)
    return m

static func _rod(parent: Node3D,name: String,a: Vector3,b: Vector3,
        radius: float,color: Color) -> MeshInstance3D:
    var axis: Vector3=b-a
    var geometry:=CylinderMesh.new()
    geometry.top_radius=radius
    geometry.bottom_radius=radius
    geometry.height=axis.length()
    geometry.radial_segments=12
    var piece:=_mesh(parent,name,geometry,color,(a+b)*0.5)
    piece.quaternion=Quaternion(Vector3.UP,axis.normalized())
    return piece

static func _ring(parent: Node3D,name: String,position: Vector3,
        inner: float,outer: float,axis: String,
        color: Color) -> MeshInstance3D:
    var torus:=TorusMesh.new()
    torus.inner_radius=inner
    torus.outer_radius=outer
    torus.rings=10
    torus.ring_segments=24
    var piece:=_mesh(parent,name,torus,color,position,0.64)
    if axis=="x":
        piece.rotation_degrees.z=90.0
    elif axis=="z":
        piece.rotation_degrees.x=90.0
    return piece

static func _fixed_tail(body: Node3D) -> void:
    var layer:=_group(body,ROOT)
    var armor:=Color("#647782")
    var graphite:=Color("#26323a")
    var steel:=Color("#b5c5ca")
    # Follows the closed V1 tail boom, above its tapered roof, and terminates
    # at the real (0.285,1.38,2.62) V1/V3 tail-rotor axle.
    _rod(layer,SHAFT,Vector3(0,1.260,1.51),
        Vector3(0,1.260,2.39),0.034,graphite)
    for i in range(3):
        var z: float=1.64+float(i)*0.325
        _ring(layer,"A01V11_CojineteTransmision_%d" % i,
            Vector3(0,1.260,z),0.029,0.056,"z",steel)
        _rod(layer,"A01V11_PernoCojinete_%d" % i,
            Vector3(-0.067,1.216,z),Vector3(0.067,1.216,z),
            0.014,armor)
    var box_mesh:=SphereMesh.new()
    box_mesh.radius=0.5
    box_mesh.height=1.0
    box_mesh.radial_segments=16
    box_mesh.rings=8
    var gearbox:=_mesh(layer,GEARBOX,box_mesh,
        armor,Vector3(0.155,1.380,2.620))
    gearbox.scale=Vector3(0.245,0.282,0.315)
    _rod(layer,"A01V11_ArbolSalidaReductora",
        Vector3(0.218,1.380,2.620),
        Vector3(0.300,1.380,2.620),0.066,graphite)
    _ring(layer,"A01V11_SelloEjeCola",
        Vector3(0.293,1.380,2.620),0.067,0.107,"x",steel)
    for i in range(4):
        var angle: float=TAU*float(i)/4.0+PI/4.0
        _rod(layer,"A01V11_PernoReductora_%d" % i,
            Vector3(0.279,1.380+sin(angle)*0.105,
                2.620+cos(angle)*0.105),
            Vector3(0.306,1.380+sin(angle)*0.105,
                2.620+cos(angle)*0.105),0.020,steel)

static func _spinning_tail(rotor: Node3D) -> void:
    var layer:=_group(rotor,TAIL_HUB)
    var steel:=Color("#a5b7c0")
    var graphite:=Color("#35444c")
    _ring(layer,"A01V11_AnilloPasoCola",Vector3(0.045,0,0),
        0.092,0.142,"x",steel)
    for i in range(4):
        var pivot: Node3D=_part(rotor,V3.LEGACY_TAIL+str(i))
        # Root's transform is the real 15-revolutions-per-pose tail rotor;
        # links are parented inside the original quarter-turn blade pivots.
        _rod(pivot,PITCH_LINK+str(i),
            Vector3(0.073,0,-0.122),
            Vector3(0.046,0,-0.258),0.014,steel)
        _rod(pivot,"A01V11_PernoBisagraCola_"+str(i),
            Vector3(0.025,0,-0.154),
            Vector3(0.076,0,-0.154),0.022,graphite)
        _ring(pivot,"A01V11_CasquilloCola_"+str(i),
            Vector3(0.077,0,-0.152),0.019,0.035,"x",steel)

static func _pylons(body: Node3D) -> void:
    var layer:=_group(body,PYLONS)
    var graphite:=Color("#35454f")
    var steel:=Color("#afc0c7")
    for side in [-1,1]:
        var s: float=float(side)
        # Two struts are tied to the existing V3 trapezoidal wing and
        # the V1 launch cradle. They do not replace the actual missile tubes.
        for i in range(2):
            var z: float=-0.135 if i==0 else 0.175
            _rod(layer,"A01V11_RefuerzoAla_%d_%d" % [side,i],
                Vector3(s*0.86,0.787,z),
                Vector3(s*1.226,0.704,z+0.037),
                0.023,graphite)
        for tube in range(4):
            var x: float=s*(0.91+float(tube%2)*0.22)
            var y: float=0.66-float(tube/2)*0.14
            # Outside the V1 frontal mouth (-0.558): distinct, solid
            # concentric retaining collars, leaving the rocket bore open.
            _ring(layer,RETAINER+"%d_%d" % [side,tube],
                Vector3(x,y,-0.575),0.044,0.063,"z",steel)
            _rod(layer,"A01V11_PernoBoca_%d_%d" % [side,tube],
                Vector3(x-0.028,y+0.051,-0.574),
                Vector3(x-0.028,y+0.051,-0.549),
                0.010,graphite)

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if not has_model(model):
        return false
    for section in [ROOT,TAIL_HUB,PYLONS]:
        var parent: Node3D=_part(model,section)
        parent.visible=enabled
    for i in range(4):
        var arm: Node3D=_part(model,V3.LEGACY_TAIL+str(i))
        for name in [PITCH_LINK+str(i),
                "A01V11_PernoBisagraCola_"+str(i),
                "A01V11_CasquilloCola_"+str(i)]:
            var part: Node3D=_part(arm,name)
            if part!=null:
                part.visible=enabled
    model.set_meta(ENABLED,enabled)
    return true

static func apply(model: Node3D,_faction: Color) -> bool:
    if not V10.has_model(model) or not V3.has_model(model):
        return false
    if has_model(model):
        return true
    var body: Node3D=_part(model,V1.ROOT)
    var rotor: Node3D=_part(model,V1.TAIL_ROTOR)
    if body==null or rotor==null:
        return false
    for i in range(4):
        if _part(rotor,V3.LEGACY_TAIL+str(i))==null:
            return false
    for side in [-1,1]:
        for i in range(4):
            if _part(model,"A01_Lanzador_%d_%d" % [side,i])==null:
                return false
    _fixed_tail(body)
    _spinning_tail(rotor)
    _pylons(body)
    model.set_meta(FLAG,true)
    model.set_meta(ENABLED,true)
    return set_enabled(model,true)
