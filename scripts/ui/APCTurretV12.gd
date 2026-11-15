extends RefCounted
class_name TarvokaAPCTurretV12

# TARVOKA Bastion P06 - V12 unmanned turret sculpture.
# No gameplay stats, rate of fire or weapon timing changes. All added muzzle
# hardware is a child of the V1 stabilized weapon; all aiming optics are a
# child of the real traversing remote station, not of the static hull.
const V1=preload("res://scripts/ui/APCArtV1.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const FLAG := "tarvoka_apc_turret_v12"
const ROOT := "P06V12_EstacionRemotaEsculpida"
const GUN_ROOT := "P06V12_ArmaAmetralladora"
const DAMAGE := "P06V12_DesperfectosTorreta"
const WRECK := "P06V12_RestosTorreta"
const SHOW := "tarvoka_apc_turret_v12_visible"
const STAGE := "tarvoka_apc_turret_v12_stage"
const REST_HIDDEN := "tarvoka_apc_v12_replaced_turret_parts"
const REPLACED := [
    "TorretaCompacta",
    "MejillaSensorDerecha",
    "BloqueOpticoTierra",
    "LenteInfrarrojaV2",
    "TechoSensorReforzadoV2",
    "P06V5_CubiertaTermica",
    "P06V5_VidrioOpticaPrincipal",
    "FrenoBoca",
]
const RING_NAME := "P06V12_AnilloGiroBlindado"
const OPTICS := "P06V12_OpticasEstabilizadas"

static func _node(parent: Node3D,name: String) -> Node3D:
    var n:=Node3D.new()
    n.name=name
    parent.add_child(n)
    return n

static func _mat(tint: Color,metal: float=0.35,
        rough: float=0.77,emission: bool=false) -> StandardMaterial3D:
    var m:=StandardMaterial3D.new()
    m.albedo_color=tint
    m.metallic=metal
    m.roughness=rough
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    if emission:
        m.emission_enabled=true
        m.emission=tint.darkened(0.15)
        m.emission_energy_multiplier=0.24
    return m

static func _box(parent: Node3D,name: String,pos: Vector3,
        dimensions: Vector3,material: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var cube:=BoxMesh.new()
    cube.size=dimensions
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=cube
    mesh.material_override=material
    mesh.position=pos
    mesh.rotation_degrees=rotation
    parent.add_child(mesh)
    return mesh

static func _tube(parent: Node3D,name: String,
        center: Vector3,radius: float,length: float,
        paint: Material) -> MeshInstance3D:
    var cylinder:=CylinderMesh.new()
    cylinder.top_radius=radius
    cylinder.bottom_radius=radius
    cylinder.height=length
    cylinder.radial_segments=12
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=cylinder
    mesh.material_override=paint
    mesh.position=center
    mesh.rotation_degrees.x=90.0
    parent.add_child(mesh)
    return mesh

static func _ring(parent: Node3D,name: String,center: Vector3,
        inside: float,outside: float,paint: Material,
        z_aligned: bool=false) -> MeshInstance3D:
    var torus:=TorusMesh.new()
    torus.inner_radius=inside
    torus.outer_radius=outside
    torus.rings=12
    torus.ring_segments=14
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=torus
    mesh.material_override=paint
    mesh.position=center
    if z_aligned:
        mesh.rotation_degrees.x=90.0
    parent.add_child(mesh)
    return mesh

static func _quad(st: SurfaceTool,a: Vector3,b: Vector3,
        c: Vector3,d: Vector3) -> void:
    for vertex in [a,b,c,a,c,d]:
        st.add_vertex(vertex)

static func _housing(parent: Node3D,armor: Material) -> MeshInstance3D:
    # Single CLOSED octagonal hull section. Replaces the older five flat
    # V2 faceted strips with one connected welded volume, including both caps.
    var contour: Array[Vector2]=[
        Vector2(-0.177,0.082),Vector2(0.177,0.082),
        Vector2(0.291,0.175),Vector2(0.285,0.288),
        Vector2(0.161,0.410),Vector2(-0.161,0.410),
        Vector2(-0.285,0.288),Vector2(-0.291,0.175)]
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for idx in range(contour.size()):
        var nxt: int=(idx+1)%contour.size()
        var a:=contour[idx]
        var b:=contour[nxt]
        _quad(st,Vector3(a.x,a.y,-0.287),
            Vector3(b.x,b.y,-0.287),
            Vector3(b.x,b.y,0.254),
            Vector3(a.x,a.y,0.254))
        # End caps are triangular fans: no missing wall viewed from behind.
        st.add_vertex(Vector3(0,0.232,-0.287))
        st.add_vertex(Vector3(b.x,b.y,-0.287))
        st.add_vertex(Vector3(a.x,a.y,-0.287))
        st.add_vertex(Vector3(0,0.232,0.254))
        st.add_vertex(Vector3(a.x,a.y,0.254))
        st.add_vertex(Vector3(b.x,b.y,0.254))
    st.generate_normals()
    var mesh:=MeshInstance3D.new()
    mesh.name="P06V12_CarcasaOctogonalCerrada"
    mesh.mesh=st.commit()
    mesh.material_override=armor
    parent.add_child(mesh)
    return mesh

static func _perforated_barrel(gun: Node3D,
        metal: Material) -> MeshInstance3D:
    # True mesh openings in the cooling shroud; do not fake holes using dark
    # painted squares on an opaque cylinder. Original inner barrel remains
    # visible inside through the side cutouts.
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    var sections: int=9
    var around: int=16
    var z0: float=-0.48
    var z1: float=-0.12
    var radius: float=0.079
    for row in range(sections):
        var z_a: float=lerpf(z0,z1,float(row)/float(sections))
        var z_b: float=lerpf(z0,z1,float(row+1)/float(sections))
        for segment in range(around):
            # Rows 2,4,6 have four genuine open cooling ports per ring.
            if row in [2,4,6] and (segment%4)==1:
                continue
            var a: float=TAU*float(segment)/float(around)
            var b: float=TAU*float(segment+1)/float(around)
            _quad(st,
                Vector3(radius*cos(a),radius*sin(a),z_a),
                Vector3(radius*cos(b),radius*sin(b),z_a),
                Vector3(radius*cos(b),radius*sin(b),z_b),
                Vector3(radius*cos(a),radius*sin(a),z_b))
    st.generate_normals()
    var sleeve:=MeshInstance3D.new()
    sleeve.name="P06V12_CamisaCanonPerforadaReal"
    sleeve.mesh=st.commit()
    sleeve.material_override=metal
    gun.add_child(sleeve)
    return sleeve

static func _turret_details(root: Node3D,
        paint: Material,dark: Material,steel: Material,
        lens: Material,shadow: Material) -> void:
    _ring(root,RING_NAME,Vector3(0,0.027,0),
        0.271,0.321,steel)
    _housing(root,paint)
    # Two side plates share the housing slopes rather than enormous boxes
    # pasted on the same silhouette. They remain attached while traversing.
    for side in [-1,1]:
        var s: float=float(side)
        _box(root,"P06V12_RefuerzoLateral_%d" % side,
            Vector3(s*0.291,0.213,0.068),
            Vector3(0.031,0.110,0.255),paint,
            Vector3(0,0,s*-7.0))
        _box(root,"P06V12_CanalCableado_%d" % side,
            Vector3(s*0.279,0.140,0.132),
            Vector3(0.027,0.045,0.175),dark)
        _box(root,"P06V12_SelloConductor_%d" % side,
            Vector3(s*0.218,0.363,0.132),
            Vector3(0.086,0.033,0.175),steel,
            Vector3(0,0,s*17.0))
    _box(root,"P06V12_PlacaServicioSuperior",
        Vector3(0,0.417,0.086),Vector3(0.239,0.019,0.208),paint)
    for side in [-1,1]:
        _box(root,"P06V12_PestilloTecho_%d" % side,
            Vector3(float(side)*0.079,0.432,0.120),
            Vector3(0.030,0.019,0.070),steel)
    # Distinct frontal viewport for commander, but small enough not to look
    # like a human-crewed turret windshield.
    var optics:=_node(root,OPTICS)
    _box(optics,"P06V12_MarcoCamaraPrincipal",
        Vector3(0.270,0.244,-0.326),
        Vector3(0.202,0.170,0.043),dark)
    _ring(optics,"P06V12_AnilloLenteTermica",
        Vector3(0.270,0.244,-0.354),0.038,0.056,steel,true)
    _tube(optics,"P06V12_CristalTermicoEsferico",
        Vector3(0.270,0.244,-0.357),0.036,0.008,lens)
    _box(optics,"P06V12_ParasolOpticaPrincipal",
        Vector3(0.270,0.344,-0.332),
        Vector3(0.225,0.023,0.105),paint,
        Vector3(-6,0,0))
    _box(optics,"P06V12_TapaSensorZoom",
        Vector3(-0.244,0.295,-0.249),
        Vector3(0.133,0.117,0.035),dark)
    _ring(optics,"P06V12_AnilloLenteZoom",
        Vector3(-0.244,0.295,-0.277),0.017,0.031,steel,true)
    _tube(optics,"P06V12_LenteZoom",
        Vector3(-0.244,0.295,-0.279),0.017,0.008,lens)
    # Independent ranging optic on top: not on the barrel, so recoil leaves
    # the electronic camera assembly in place.
    _box(optics,"P06V12_ModuloTelemetro",
        Vector3(-0.159,0.453,-0.055),
        Vector3(0.129,0.083,0.191),paint)
    _box(optics,"P06V12_VentanaTelemetro",
        Vector3(-0.159,0.454,-0.160),
        Vector3(0.081,0.047,0.014),lens)
    _box(optics,"P06V12_EscudoSuperiorTelemetro",
        Vector3(-0.159,0.504,-0.062),
        Vector3(0.144,0.016,0.201),steel)
    # Dark joints behind the frontal shroud visually explain turret rotation.
    for side in [-1,1]:
        _box(root,"P06V12_JuntaMecanica_%d" % side,
            Vector3(float(side)*0.226,0.126,0.241),
            Vector3(0.060,0.074,0.043),shadow)

static func _gun_details(gun: Node3D,
        paint: Material,dark: Material,steel: Material) -> Node3D:
    var hardware:=_node(gun,GUN_ROOT)
    # Receiver and elevating trunnions parent to the actual recoiling gun;
    # their pose inherits the six individual V7 recoil impulses automatically.
    _box(hardware,"P06V12_CajaMecanismo",
        Vector3(-0.008,0.030,-0.035),
        Vector3(0.188,0.151,0.235),paint)
    for side in [-1,1]:
        var x: float=float(side)*0.111
        _box(hardware,"P06V12_BisagraElevacion_%d" % side,
            Vector3(x,0.016,-0.013),
            Vector3(0.038,0.093,0.126),steel)
    _perforated_barrel(hardware,dark)
    for z in [-0.490,-0.123]:
        _ring(hardware,"P06V12_AbrazaderaCanon_%d" % int(z*1000.0),
            Vector3(0,0,z),0.076,0.088,steel,true)
    _tube(hardware,"P06V12_CollarBoca",
        Vector3(0,0,-0.562),0.077,0.047,steel)
    _ring(hardware,"P06V12_BocaAbierta",
        Vector3(0,0,-0.606),0.047,0.073,dark,true)
    # Lateral brake ports, NOT an opaque muzzle block. The flash is still
    # unobstructed 0.73 m forward, and the sound/fire timings remain V7.
    for side in [-1,1]:
        _box(hardware,"P06V12_PuertoFreno_%d" % side,
            Vector3(float(side)*0.069,0.0,-0.598),
            Vector3(0.023,0.062,0.068),dark)
    # Visible brass ejection port aligns with V7 shells departing to +X.
    _box(hardware,"P06V12_CompuertaExpulsion",
        Vector3(0.117,0.077,-0.169),
        Vector3(0.021,0.067,0.125),dark)
    _box(hardware,"P06V12_DeflectorCasquillos",
        Vector3(0.149,0.047,-0.146),
        Vector3(0.065,0.023,0.118),steel,
        Vector3(0,0,-13))
    _box(hardware,"P06V12_TapaMantenimientoArma",
        Vector3(-0.013,0.117,0.014),
        Vector3(0.126,0.015,0.110),steel)
    return hardware

static func _damage_layers(turret: Node3D,
        scorch: Material,broken: Material,glass: Material) -> Node3D:
    var root:=_node(turret,DAMAGE)
    var scrape:=_node(root,"P06V12_RayadurasTorreta")
    _box(scrape,"P06V12_RasguñoFrontal",
        Vector3(-0.216,0.270,-0.294),
        Vector3(0.077,0.013,0.010),broken,
        Vector3(0,0,17))
    var dent:=_node(root,"P06V12_AblacionOptica")
    _box(dent,"P06V12_CristalTermicoAstillado",
        Vector3(0.272,0.243,-0.371),
        Vector3(0.073,0.012,0.009),scorch,
        Vector3(0,0,-24))
    _box(dent,"P06V12_AbolladuraLadoDerecho",
        Vector3(0.307,0.213,0.048),
        Vector3(0.027,0.085,0.109),broken,
        Vector3(0,0,10))
    var critical:=_node(root,"P06V12_OpticaQuebrada")
    _box(critical,"P06V12_CarcasaSensorRota",
        Vector3(0.276,0.255,-0.314),
        Vector3(0.141,0.068,0.039),scorch,
        Vector3(0,0,29))
    _box(critical,"P06V12_FragmentoCristal",
        Vector3(0.279,0.207,-0.358),
        Vector3(0.076,0.022,0.019),glass,
        Vector3(0,0,-37))
    var total:=_node(root,WRECK)
    _box(total,"P06V12_ChasisTorretaQuemado",
        Vector3(0.0,0.290,0.028),
        Vector3(0.239,0.133,0.246),scorch,
        Vector3(9,0,-18))
    _tube(total,"P06V12_CanonFragmentado",
        Vector3(-0.028,0.158,-0.382),0.051,0.36,broken)
    for layer in root.get_children():
        (layer as Node3D).visible=false
    return root

static func _legacy(model: Node3D,visible: bool) -> void:
    # Only the individual obsolete V1/V2 parts are replaced; V6 thermal
    # sensors are retained and detailed, not rebuilt as floating duplicates.
    for name in REPLACED:
        var part: Node3D=model.find_child(name,true,false) as Node3D
        if part!=null:
            part.visible=visible
    for i in range(5):
        var facet: Node3D=model.find_child(
            "CarcasaTorretaFacetaV2_%d" % i,true,false) as Node3D
        if facet!=null:
            facet.visible=visible

static func apply(model: Node3D,faction_color: Color) -> bool:
    if model==null or not bool(model.get_meta(V11.FLAG,false)):
        return false
    if model.get_meta(FLAG,false):
        return true
    var turret: Node3D=model.find_child(
        "EstacionRemotaP06",true,false) as Node3D
    var gun: Node3D=model.find_child(
        "ArmaEstabilizadaP06",true,false) as Node3D
    if turret==null or gun==null:
        return false
    var paint:=_mat(Color("#55686b").lerp(faction_color,0.56),0.34,0.79)
    var shade:=_mat(Color("#35444a").lerp(faction_color,0.33),0.38,0.83)
    var steel:=_mat(Color("#839094"),0.61,0.64)
    var deep:=_mat(Color("#1b262b"),0.18,0.93)
    var lens:=_mat(Color("#225a76"),0.07,0.19,true)
    var broken:=_mat(Color("#637178"),0.56,0.86)
    var burnt:=_mat(Color("#272c2e"),0.16,0.96)
    var body:=_node(turret,ROOT)
    _turret_details(body,paint,shade,steel,lens,deep)
    _gun_details(gun,paint,deep,steel)
    _damage_layers(turret,burnt,broken,lens)
    _legacy(model,false)
    model.set_meta(FLAG,true)
    model.set_meta(SHOW,true)
    model.set_meta(STAGE,0)
    return true

static func set_stage(model: Node3D,stage: int) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    var value: int=clampi(stage,0,4)
    var enabled: bool=bool(model.get_meta(SHOW,true))
    var body: Node3D=model.find_child(ROOT,true,false) as Node3D
    var weapon: Node3D=model.find_child(GUN_ROOT,true,false) as Node3D
    if body!=null:
        body.visible=enabled and value<4
    if weapon!=null:
        weapon.visible=enabled and value<4
    for name in ["P06V12_RayadurasTorreta","P06V12_AblacionOptica",
            "P06V12_OpticaQuebrada",WRECK]:
        var layer: Node3D=model.find_child(name,true,false) as Node3D
        var need: int=1
        if name=="P06V12_AblacionOptica":
            need=2
        elif name=="P06V12_OpticaQuebrada":
            need=3
        elif name==WRECK:
            need=4
        if layer!=null:
            layer.visible=enabled and value>=need
    # At critical damage the thermal sensors are no longer intact; at
    # destruction V7 displaces the turret and exposes its broken rotation ring.
    var optics: Node3D=model.find_child(
        OPTICS,true,false) as Node3D
    if optics!=null:
        optics.visible=enabled and value<3
    var v6_optics: Node3D=model.find_child(
        V6.TURRET,true,false) as Node3D
    if v6_optics!=null:
        v6_optics.visible=bool(model.get_meta(
            "tarvoka_apc_v6_visible",true)) and value<3
    # A destroyed turret should not look like a complete gun mounted on
    # a ruin: the outer V12 weapon housing becomes battered fragments.
    model.set_meta(STAGE,value)
    return true

static func set_enabled(model: Node3D,enabled: bool) -> bool:
    if model==null or not bool(model.get_meta(FLAG,false)):
        return false
    model.set_meta(SHOW,enabled)
    _legacy(model,not enabled)
    return set_stage(model,int(model.get_meta(STAGE,0)))
