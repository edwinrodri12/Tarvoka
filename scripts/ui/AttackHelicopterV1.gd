extends RefCounted
class_name TarvokaAttackHelicopterV1

# A01 attack helicopter: native editable Godot geometry, not a 2D mockup.
# Preview-only hero sculpt. The original low-detail battle helicopter remains
# available at art_level <= 10, keeping gameplay and performance untouched.
const FLAG := "tarvoka_a01_attack_helicopter_v1"
const ROOT := "A01_HelicopteroAtaque_V1"
const MAIN_ROTOR := "A01_RotorPrincipal"
const TAIL_ROTOR := "A01_RotorCola"
const GUN := "A01_ArmaMorro"
const FLASH := "A01_DestelloCanon"
const REST_POSITION := "tarvoka_a01_rest_position"
const REST_ROTATION := "tarvoka_a01_rest_rotation"
const MOVE_DURATION := 1.10
const ATTACK_DURATION := 0.90
const HIT_DURATION := 0.62

static func _paint(color: Color, metal: float = 0.22, rough: float = 0.60) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    return mat

static func _group(parent: Node3D, label: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
    var n := Node3D.new()
    n.name = label
    n.position = pos
    parent.add_child(n)
    return n

static func _mesh(parent: Node3D, label: String, shape: Mesh,
        color: Color, pos: Vector3 = Vector3.ZERO,
        rotation: Vector3 = Vector3.ZERO,
        metal: float = 0.22, rough: float = 0.60) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    n.name = label
    n.mesh = shape
    n.material_override = _paint(color,metal,rough)
    n.position = pos
    n.rotation_degrees = rotation
    parent.add_child(n)
    return n

static func _box(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    return _mesh(parent,label,mesh,color,pos,rotation)

static func _cylinder(parent: Node3D, label: String, pos: Vector3,
        radius: float, length: float, color: Color,
        rotation: Vector3 = Vector3.ZERO, sides: int = 16) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = sides
    return _mesh(parent,label,mesh,color,pos,rotation)

static func _sphere(parent: Node3D, label: String, pos: Vector3,
        size: Vector3, color: Color, rough: float = 0.60) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 24
    mesh.rings = 12
    var part := _mesh(parent,label,mesh,color,pos,Vector3.ZERO,0.20,rough)
    part.scale = size
    return part

static func _point(station: Vector4, ring: int) -> Vector3:
    var angle: float = TAU * float(ring % 10) / 10.0
    return Vector3(cos(angle)*station.z,
        station.y+sin(angle)*station.w,station.x)

static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    st.add_vertex(a)
    st.add_vertex(b)
    st.add_vertex(c)

static func _loft(stations: Array[Vector4]) -> ArrayMesh:
    # Closed ten-sided tapered fuselage: no exposed back or paper-thin front.
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in range(stations.size()-1):
        for j in range(10):
            var a: Vector3 = _point(stations[i],j)
            var b: Vector3 = _point(stations[i],j+1)
            var c: Vector3 = _point(stations[i+1],j+1)
            var d: Vector3 = _point(stations[i+1],j)
            _triangle(st,a,b,c)
            _triangle(st,a,c,d)
    for j in range(10):
        var first: Vector4 = stations[0]
        var last: Vector4 = stations[stations.size()-1]
        _triangle(st,Vector3(0,first.y,first.x),
            _point(first,j+1),_point(first,j))
        _triangle(st,Vector3(0,last.y,last.x),
            _point(last,j),_point(last,j+1))
    st.generate_normals()
    return st.commit()

static func has_model(model: Node3D) -> bool:
    return model != null and bool(model.get_meta(FLAG,false)) and (
        model.find_child(ROOT,true,false) != null)

static func _part(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

static func build(model: Node3D, faction: Color) -> bool:
    if model == null:
        return false
    if has_model(model):
        return true
    var steel := Color("#6b777c")
    var graphite := Color("#293238")
    var dark := Color("#131e24")
    var metal := Color("#b0b9bb")
    var glass := Color("#3c7790")
    var rubber := Color("#1b252b")
    var body := _group(model,ROOT)
    _mesh(body,"A01_MonocascoFacetado",_loft([
        Vector4(-1.67,0.92,0.09,0.13),
        Vector4(-1.28,1.02,0.36,0.32),
        Vector4(-0.75,1.08,0.55,0.43),
        Vector4(0.08,1.07,0.63,0.46),
        Vector4(0.75,1.04,0.49,0.33),
        Vector4(1.16,1.03,0.23,0.20)
    ]),steel)
    _mesh(body,"A01_CarenadoCristalTandem",_loft([
        Vector4(-1.46,1.26,0.14,0.09),
        Vector4(-1.02,1.32,0.35,0.24),
        Vector4(-0.54,1.37,0.42,0.29),
        Vector4(-0.14,1.33,0.38,0.27),
        Vector4(0.04,1.30,0.14,0.12)
    ]),glass,Vector3.ZERO,Vector3.ZERO,0.04,0.19)
    _box(body,"A01_MarcoCristalMedio",
        Vector3(0,1.59,-0.53),Vector3(0.78,0.055,0.070),graphite)
    _box(body,"A01_MarcoCristalFrontal",
        Vector3(0,1.45,-1.07),Vector3(0.62,0.055,0.065),graphite)
    _sphere(body,"A01_Radomo",
        Vector3(0,0.83,-1.51),Vector3(0.49,0.35,0.40),graphite)
    _sphere(body,"A01_Optica",
        Vector3(0,0.65,-1.70),Vector3(0.19,0.17,0.17),glass,0.21)
    for side in [-1,1]:
        var sign: float = float(side)
        _box(body,"A01_PanelFaccion_%d" % side,
            Vector3(sign*0.56,1.11,0.27),
            Vector3(0.045,0.25,0.85),faction)
        _box(body,"A01_RejillaAdmisión_%d" % side,
            Vector3(sign*0.48,1.42,0.72),
            Vector3(0.17,0.12,0.48),graphite)
        _box(body,"A01_ProteccionMotor_%d" % side,
            Vector3(sign*0.29,1.57,0.55),
            Vector3(0.44,0.25,0.70),steel)
        _cylinder(body,"A01_Escape_%d" % side,
            Vector3(sign*0.53,1.47,0.98),
            0.14,0.42,dark,Vector3(0,90,90))
        _box(body,"A01_AlaRefuerzo_%d" % side,
            Vector3(sign*0.86,0.86,0.14),
            Vector3(0.95,0.12,0.38),faction,Vector3(0,0,sign*5.0))
        _box(body,"A01_SoporteMisiles_%d" % side,
            Vector3(sign*1.09,0.67,0.04),
            Vector3(0.47,0.11,0.67),graphite)
        for tube in range(4):
            var x: float = sign*(0.91+float(tube%2)*0.22)
            var y: float = 0.66-float(tube/2)*0.14
            _cylinder(body,"A01_Lanzador_%d_%d" % [side,tube],
                Vector3(x,y,-0.18),0.068,0.73,dark,Vector3(90,0,0),12)
            _cylinder(body,"A01_Boca_%d_%d" % [side,tube],
                Vector3(x,y,-0.558),0.044,0.017,metal,
                Vector3(90,0,0),12)
        _box(body,"A01_Patin_%d" % side,
            Vector3(sign*0.54,0.20,0.13),
            Vector3(0.075,0.085,2.16),rubber)
        for z in [-0.51,0.62]:
            _box(body,"A01_PilarPatin_%d_%.2f" % [side,z],
                Vector3(sign*0.54,0.46,z),
                Vector3(0.09,0.56,0.10),metal,
                Vector3(0,0,-sign*12.0))
    # Solid tapered tail, paint stripe and actual horizontal fin.
    _mesh(body,"A01_VigaColaSellada",_loft([
        Vector4(1.03,1.09,0.26,0.20),
        Vector4(1.55,1.08,0.17,0.16),
        Vector4(2.53,1.10,0.10,0.11),
        Vector4(2.70,1.11,0.10,0.12)
    ]),steel)
    _box(body,"A01_FranjaColaFaccion",
        Vector3(0,1.19,2.13),Vector3(0.12,0.035,0.60),faction)
    _box(body,"A01_AletaVertical",
        Vector3(0,1.48,2.49),Vector3(0.10,0.82,0.36),graphite,
        Vector3(-12,0,0))
    _box(body,"A01_EstabilizadorCola",
        Vector3(0,1.06,2.38),Vector3(1.18,0.075,0.33),steel)
    _cylinder(body,"A01_BaseMastil",
        Vector3(0,1.75,0.08),0.19,0.34,graphite)
    var main := _group(body,MAIN_ROTOR,Vector3(0,1.97,0.08))
    _cylinder(main,"A01_BujePrincipal",Vector3.ZERO,0.26,0.12,metal)
    for blade in range(4):
        var arm := _group(main,"A01_AspaPortante_%d" % blade)
        arm.rotation_degrees.y=float(blade)*90.0
        _box(arm,"A01_RaizAspa_%d" % blade,
            Vector3(0,0,-0.36),Vector3(0.28,0.075,0.70),graphite)
        _box(arm,"A01_Pala_%d" % blade,
            Vector3(0,0,-1.14),Vector3(0.25,0.045,1.29),rubber,
            Vector3(0,0,-2))
    _cylinder(body,"A01_CarenadoRotorCola",
        Vector3(0.17,1.38,2.62),0.15,0.20,graphite,Vector3(0,0,90))
    var tail := _group(body,TAIL_ROTOR,Vector3(0.285,1.38,2.62))
    _cylinder(tail,"A01_BujeRotorCola",
        Vector3.ZERO,0.11,0.07,metal,Vector3(0,0,90))
    for blade in range(4):
        var arm := _group(tail,"A01_AspaCola_%d" % blade)
        arm.rotation_degrees.x=float(blade)*90.0
        _box(arm,"A01_PalaCola_%d" % blade,
            Vector3(0,0,-0.24),Vector3(0.055,0.065,0.42),rubber)
    var gun := _group(body,GUN,Vector3(0,0.57,-1.33))
    _sphere(gun,"A01_CupulaCanon",Vector3.ZERO,
        Vector3(0.34,0.28,0.31),graphite)
    _cylinder(gun,"A01_Canon",
        Vector3(0,0,-0.36),0.078,0.70,metal,Vector3(90,0,0),16)
    _cylinder(gun,"A01_Bocacha",
        Vector3(0,0,-0.73),0.100,0.15,dark,Vector3(90,0,0),16)
    var flash := _sphere(gun,FLASH,Vector3(0,0,-0.82),
        Vector3(0.30,0.25,0.43),Color("#ffa23b"))
    var emissive: StandardMaterial3D=flash.material_override as StandardMaterial3D
    emissive.emission_enabled=true
    emissive.emission=Color("#ffa23b")
    emissive.emission_energy_multiplier=2.5
    flash.visible=false
    model.set_meta(FLAG,true)
    model.set_meta("tarvoka_a01_art_level",1)
    return true

static func pose(model: Node3D, kind: String, progress: float,
        _target_heading: Vector2i = Vector2i(0,-1)) -> bool:
    if not has_model(model):
        return false
    if not model.has_meta(REST_POSITION):
        model.set_meta(REST_POSITION,model.position)
        model.set_meta(REST_ROTATION,model.rotation_degrees)
    restore(model)
    var t: float=clampf(progress,0.0,1.0)
    var main: Node3D=_part(model,MAIN_ROTOR)
    var tail: Node3D=_part(model,TAIL_ROTOR)
    var gun: Node3D=_part(model,GUN)
    var flash: Node3D=_part(model,FLASH)
    main.rotation_degrees.y=360.0*8.0*t
    tail.rotation_degrees.x=360.0*15.0*t
    match kind:
        "move","fly","hover":
            model.position.y+=0.10*sin(PI*t)
            model.rotation_degrees.z+=2.5*sin(TAU*t)
            model.rotation_degrees.x+=3.0*sin(PI*t)
        "attack","fire":
            model.rotation_degrees.x-=2.0*sin(PI*t)
            gun.rotation_degrees.x=6.0*sin(PI*t)
            flash.visible=(t>=0.31 and t<0.39) or (
                t>=0.55 and t<0.63)
        "hit_bullet","bullet":
            model.rotation_degrees.z+=1.5*sin(PI*t)
        "hit_explosive","explosive":
            model.rotation_degrees.z+=5.0*sin(PI*t)
            model.position.y+=0.05*sin(PI*t)
        "idle":
            pass
        _:
            return false
    return true

static func restore(model: Node3D) -> void:
    if not has_model(model):
        return
    if model.has_meta(REST_POSITION):
        model.position=model.get_meta(REST_POSITION) as Vector3
        model.rotation_degrees=model.get_meta(REST_ROTATION) as Vector3
    var main: Node3D=_part(model,MAIN_ROTOR)
    var tail: Node3D=_part(model,TAIL_ROTOR)
    var gun: Node3D=_part(model,GUN)
    var flash: Node3D=_part(model,FLASH)
    main.rotation_degrees=Vector3.ZERO
    tail.rotation_degrees=Vector3.ZERO
    gun.rotation_degrees=Vector3.ZERO
    flash.visible=false
