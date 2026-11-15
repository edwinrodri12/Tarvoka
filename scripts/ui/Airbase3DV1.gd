extends RefCounted
class_name TarvokaAirbase3DV1

# Base aérea original de TARVOKA. Modelo 3D construido en Godot:
# hangar con volumen cerrado, cubierta curva real, torre, plataforma,
# 8 pinturas y emblemas OFICIALES y 5 estados físicos progresivos.
# Arte independiente: no añade reglas de compra, HP ni economía.
const Style = preload("res://scripts/ui/VisualStyle.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")
const CONDITIONS := ["operativo","capturado","danado","destruido"]
const DAMAGE_STAGES := ["Intacta","Daño leve · radar caído",
    "Daño medio · portones/techo", "Daño crítico · torre y hangar",
    "Destruida · ruinas"]
const ASPHALT := Color("#414c54")
const WALL := Color("#bbc5c7")
const CEMENT := Color("#808d92")
const IRON := Color("#354650")
const ROOF := Color("#536976")
const ALUMINUM := Color("#c6d3d4")
const GLASS := Color("#38677c")
const LIGHT := Color("#edebe0")
const BLACK := Color("#1b2833")
const RUST := Color("#6f6157")
const GOLD := Color("#f1bd56")
# V3: The taxiway and hangar share an exact engineering centerline.
# Coordinates are within the compact single-tile airbase foundation.
const HANGAR_CENTER_X := -1.95
const HANGAR_FRONT_Z := -4.105
const TAXIWAY_CENTER_X := HANGAR_CENTER_X
const TAXIWAY_CENTER_Z := -5.00
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}

static func valid_spec(level: int, faction: int, damage: int) -> bool:
    return level in [1,2,3] and faction >= 0 and faction < Style.FACTIONS.size() and damage >= 0 and damage <= 4

static func _mat(color: Color, metal: float = 0.10, emissive: bool = false) -> StandardMaterial3D:
    var key: String = "%s/%0.2f/%s" % [color.to_html(true),metal,str(emissive)]
    if _materials.has(key):
        return _materials[key] as StandardMaterial3D
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = 0.68 if metal >= 0.30 else 0.87
    if emissive:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = 1.45
    _materials[key] = mat
    return mat

static func _group(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = at
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, center: Vector3,
        size: Vector3, tint: Color, metal: float = 0.10,
        faction_panel: bool = false, angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var box: MeshInstance3D = MeshInstance3D.new()
    box.name = label
    var key: String = "box/%0.3f/%0.3f/%0.3f" % [size.x,size.y,size.z]
    if not _meshes.has(key):
        var mesh := BoxMesh.new()
        mesh.size = size
        _meshes[key] = mesh
    box.mesh = _meshes[key] as Mesh
    box.position = center
    box.rotation_degrees = angles
    box.material_override = _mat(tint,metal)
    box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    if faction_panel:
        box.set_meta("tarvoka_faction_panel",true)
    parent.add_child(box)
    return box

static func _cylinder(parent: Node3D, label: String, center: Vector3,
        radius: float, depth: float, tint: Color, metal: float = 0.20,
        segments: int = 20, angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    var key: String = "cyl/%0.3f/%0.3f/%d" % [radius,depth,segments]
    if not _meshes.has(key):
        var mesh := CylinderMesh.new()
        mesh.top_radius = radius
        mesh.bottom_radius = radius
        mesh.height = depth
        mesh.radial_segments = segments
        _meshes[key] = mesh
    node.mesh = _meshes[key] as Mesh
    node.material_override = _mat(tint,metal)
    node.position = center
    node.rotation_degrees = angles
    parent.add_child(node)
    return node

static func _roof_piece(parent: Node3D, label: String, x0: float,
        x1: float, z0: float, z1: float, tint: Color) -> void:
    # Native 3D triangulated barrel roof, closed from above and below.
    # Each section has real curvature instead of a floating flat rectangle.
    var y0: float = 2.80 + 0.73 * sin(PI*(x0+3.65)/7.30)
    var y1: float = 2.80 + 0.73 * sin(PI*(x1+3.65)/7.30)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for thickness in [0.0,-0.13]:
        var p := [
            Vector3(x0,y0+thickness,z0),Vector3(x1,y1+thickness,z0),
            Vector3(x1,y1+thickness,z1),Vector3(x0,y0+thickness,z1)]
        for idx in [0,1,2,0,2,3]:
            st.set_uv(Vector2(float(idx%3)*0.4,thickness))
            st.add_vertex(p[idx])
    st.generate_normals()
    var mesh: ArrayMesh = st.commit()
    var segment := MeshInstance3D.new()
    segment.name = label
    segment.mesh = mesh
    segment.material_override = _mat(tint,0.32)
    parent.add_child(segment)

static func _ground(parent: Node3D, accent: Color) -> void:
    var apron := _group(parent,"PlataformaYRodaduras")
    _box(apron,"BaseCompacta",Vector3(0,-0.13,0),Vector3(13.4,0.23,12.8),ASPHALT,0.02)
    _box(apron,"LosasHormigonHangar",Vector3(-1.92,0.015,-0.45),
        Vector3(8.45,0.08,8.15),CEMENT)
    _box(apron,"LosaPlataformaDeVuelo",Vector3(3.55,0.025,2.75),
        Vector3(5.6,0.085,5.25),Color("#5b676b"))
    # V3 realignment: previously the road center was x=+0.80, a
    # 2.75 m lateral error relative to the hangar at x=-1.95.
    # The 6.4 m-wide paved taxiway now joins the gate at z=-4.105.
    _box(apron,"CarrilRodaje",Vector3(
        TAXIWAY_CENTER_X,0.075,TAXIWAY_CENTER_Z),
        Vector3(6.40,0.080,2.63),IRON,0.14)
    # Dash direction is longitudinal (-Z), not across the taxiway.
    for i in range(4):
        _box(apron,"RayaDiscontinuaRodaje_%d" % i,
            Vector3(TAXIWAY_CENTER_X,0.123,-5.84+float(i)*0.49),
            Vector3(0.11,0.014,0.27),GOLD)
    # Gate threshold, aligned and centred with the sliding doors.
    _box(apron,"LineaUmbralHangarV3",Vector3(
        TAXIWAY_CENTER_X,0.123,HANGAR_FRONT_Z-0.13),
        Vector3(6.15,0.014,0.095),LIGHT)
    for side in [-1,1]:
        var edge_x: float = TAXIWAY_CENTER_X+float(side)*3.04
        _box(apron,"LineaSeguridadLateral_%s" % side,
            Vector3(edge_x,0.123,TAXIWAY_CENTER_Z),
            Vector3(0.09,0.014,2.55),accent,0.04,true)
        _box(apron,"BandaAdvertenciaPortonV3_%s" % side,
            Vector3(TAXIWAY_CENTER_X+float(side)*2.69,
                0.123,HANGAR_FRONT_Z-0.31),
            Vector3(0.44,0.014,0.095),GOLD)
    apron.set_meta("tarvoka_airbase_v3_taxiway_aligned",true)
    apron.set_meta("taxiway_center_x",TAXIWAY_CENTER_X)
    apron.set_meta("hangar_center_x",HANGAR_CENTER_X)
    apron.set_meta("hangar_front_z",HANGAR_FRONT_Z)
    # Parking blocks, hazard zones, and clear silhouette at tactical distance.
    for i in range(5):
        _box(apron,"BordePavimento_%d" % i,
            Vector3(-5.85+float(i)*1.65,0.062,4.20),
            Vector3(0.92,0.012,0.075),LIGHT)

static func _hangar(parent: Node3D, accent: Color,
        level: int, damage: int) -> void:
    var hangar := _group(parent,"HangarPrincipalV1",Vector3(HANGAR_CENTER_X,0,-0.76))
    _box(hangar,"MuroTraseroCerrado",Vector3(0,1.43,3.19),
        Vector3(7.18,2.86,0.25),WALL)
    for s in [-1,1]:
        var side: float = float(s)
        _box(hangar,"MuroLateralCerrado_%s" % s,
            Vector3(side*3.57,1.42,0),
            Vector3(0.24,2.85,6.29),WALL)
        _box(hangar,"PilastraFrontal_%s" % s,
            Vector3(side*3.44,1.54,-3.22),
            Vector3(0.36,3.08,0.37),CEMENT,0.26)
        _box(hangar,"MarcoMetalicoEntrada_%s" % s,
            Vector3(side*3.05,1.45,-3.43),
            Vector3(0.16,2.81,0.17),IRON,0.44)
        _box(hangar,"CanalonLateral_%s" % s,
            Vector3(side*3.59,2.80,0.01),
            Vector3(0.16,0.13,6.60),IRON,0.35)
        for i in range(4):
            _box(hangar,"ContrafuerteLateral_%s_%d" % [s,i],
                Vector3(side*3.55,1.16,-2.37+float(i)*1.67),
                Vector3(0.14,2.17,0.17),CEMENT,0.25)
    _box(hangar,"DintelPorton",Vector3(0,2.88,-3.26),
        Vector3(7.05,0.20,0.25),IRON,0.35)
    _box(hangar,"FranjaSuperiorFaccion",Vector3(0,2.99,-3.45),
        Vector3(6.55,0.18,0.10),accent,0.27,true)
    # Each roof strip can be omitted for visible physical damage.
    for i in range(14):
        if damage == 4 or (damage == 3 and i in [2,3,4,5,6,7]) or (damage == 2 and i in [6,7]):
            continue
        var x0: float = -3.65 + float(i)*7.30/14.0
        var x1: float = -3.65 + float(i+1)*7.30/14.0
        _roof_piece(hangar,"CubiertaCurva3D_%02d" % i,x0,x1,
            -3.26,3.30,ROOF if i%3!=0 else Color("#62737a"))
        if i % 3 == 0:
            var mid: float = (x0+x1)*0.5
            var y: float = 2.82+0.73*sin(PI*(mid+3.65)/7.30)
            _box(hangar,"NervaduraCubierta_%02d" % i,
                Vector3(mid,y+0.055,0.01),Vector3(0.065,0.085,6.65),ALUMINUM,0.50)
    # Recessed 4-panel front hangar gate, not a painted picture.
    for i in range(4):
        if damage >= 3 and i in [1,2]:
            continue
        var gate: float = -2.57+float(i)*1.72
        var tilt: Vector3 = Vector3(0,0,0)
        if damage == 2 and i==2:
            tilt = Vector3(0,0,14)
        _box(hangar,"CompuertaPrincipal_%d" % i,
            Vector3(gate,1.28,-3.345),
            Vector3(1.62,2.39,0.09),IRON,0.29,false,tilt)
        _box(hangar,"FranjaVerticalPorton_%d" % i,
            Vector3(gate+0.69,1.30,-3.40),
            Vector3(0.066,2.36,0.045),ALUMINUM,0.38,false,tilt)
        for rib in range(3):
            _box(hangar,"RefuerzoPorton_%d_%d" % [i,rib],
                Vector3(gate,0.54+float(rib)*0.69,-3.407),
                Vector3(1.53,0.045,0.045),CEMENT,0.25,false,tilt)
    _box(hangar,"UmbralPorton",Vector3(0,0.11,-3.54),
        Vector3(6.93,0.15,0.32),GOLD,0.10)
    for side in [-1,1]:
        _box(hangar,"CristalTecnicoLateral_%s" % side,
            Vector3(float(side)*3.69,1.87,0.58),
            Vector3(0.045,0.43,1.08),GLASS,0.32)
    # Operational roof exhausts and low polygon ventilation.
    if damage < 3:
        for i in range(3):
            _box(hangar,"ExtractorCubierta_%d" % i,
                Vector3(-1.7+float(i)*1.7,3.42,1.71),
                Vector3(0.62,0.22,0.66),IRON,0.43)
            _box(hangar,"RejillaExtractor_%d" % i,
                Vector3(-1.7+float(i)*1.7,3.55,1.71),
                Vector3(0.45,0.04,0.43),ALUMINUM,0.46)
    if level>=2:
        for i in range(3):
            _box(hangar,"PanelFotovoltaico_%d" % i,
                Vector3(-2.25+float(i)*1.53,3.44,2.48),
                Vector3(1.07,0.07,0.75),Color("#244e69"),0.52)
    if damage==3:
        _box(hangar,"VigaDesprendidaSobrePorton",
            Vector3(0.12,1.15,-3.70),Vector3(3.0,0.18,0.19),IRON,0.3,false,Vector3(0,0,29))
    if damage==4:
        # Ruins, not an intact sealed hangar under decals.
        for part in hangar.get_children():
            if part is Node3D and (str(part.name).begins_with("Muro") or
                    str(part.name).begins_with("Compuerta") or
                    str(part.name).begins_with("Dintel") or str(part.name).begins_with("Pil") or
                    str(part.name).begins_with("Marco") or str(part.name).begins_with("Canalon") or
                    str(part.name).begins_with("Contrafuerte")):
                (part as Node3D).visible = false

static func _tower(parent: Node3D, accent: Color, level: int, damage: int) -> void:
    if damage==4:
        return
    var tower := _group(parent,"TorreControlAereoV1",Vector3(4.17,0,-2.17))
    var tall: float = 3.33+float(level-1)*0.62
    _box(tower,"FusteHormigonTorre",Vector3(0,tall*0.5,0),
        Vector3(1.32,tall,1.38),CEMENT,0.10)
    for i in range(3):
        _box(tower,"LineaVerticalTorre_%d" % i,
            Vector3(-0.49+float(i)*0.49,tall*0.55,-0.735),
            Vector3(0.075,tall*0.66,0.058),IRON,0.34)
    _box(tower,"CornisaTorre",Vector3(0,tall+0.06,0),
        Vector3(2.33,0.22,2.17),IRON,0.41)
    if damage<3:
        var cabin := _group(tower,"CabinaControlAerodromo",Vector3(0,tall+0.71,0))
        _box(cabin,"CristalPerimetral",Vector3.ZERO,Vector3(2.00,0.90,1.86),GLASS,0.29)
        _box(cabin,"MarcoSuperior",Vector3(0,0.51,0),
            Vector3(2.34,0.16,2.18),accent,0.30,true)
        _box(cabin,"TechoCabina",Vector3(0,0.66,0),
            Vector3(2.42,0.17,2.26),IRON,0.38)
        for s in [-1,1]:
            _box(cabin,"PuntalVertical_%s" % s,
                Vector3(float(s)*0.88,0,-0.963),
                Vector3(0.075,0.90,0.055),ALUMINUM,0.42)
            _box(cabin,"VentanaLateral_%s" % s,
                Vector3(float(s)*1.008,0,0.0),
                Vector3(0.045,0.78,1.40),GLASS,0.34)
        _box(cabin,"TirasBaliza",Vector3(0,0.76,-1.11),
            Vector3(1.55,0.05,0.07),GOLD,0.08)
    else:
        _box(tower,"CabinaControlColapsada",
            Vector3(0.51,tall+0.04,0.24),
            Vector3(1.59,0.19,1.58),IRON,0.29,false,Vector3(0,0,24))
        _box(tower,"CristalFracturado",
            Vector3(-0.49,tall+0.22,-0.61),
            Vector3(0.69,0.54,0.06),GLASS,0.24,false,Vector3(0,0,-31))
    if level>=2 and damage<3:
        _box(tower,"CentroRadar",Vector3(0,tall+1.54,0.0),
            Vector3(0.22,0.76,0.21),IRON,0.45)
        _cylinder(tower,"RadomoTorre",
            Vector3(0,tall+1.88,0.0),0.58,0.18,LIGHT,0.22,18,
            Vector3(0,0,18))
    if damage==1:
        _box(tower,"AntenaDerribada",
            Vector3(0.63,tall+0.91,0.04),Vector3(1.25,0.09,0.10),IRON,0.45,
            false,Vector3(0,0,17))
    elif damage==0 or damage==2:
        _cylinder(tower,"AntenaControlVertical",
            Vector3(0,tall+1.64,0),0.055,1.34,ALUMINUM,0.44,10)
        _cylinder(tower,"BalizaSuperior",
            Vector3(0,tall+2.36,0),0.105,0.12,GOLD,0.05,10)

static func _flight_deck(parent: Node3D, accent: Color, level: int) -> void:
    var pad := _group(parent,"HelipuertoDespliegue",
        Vector3(3.63,0.11,2.74))
    _cylinder(pad,"PlataformaCircularAeronaves",
        Vector3(0,0.10,0),1.75,0.21,IRON,0.18,32)
    _cylinder(pad,"AnilloBlancoSeguridad",Vector3(0,0.219,0),
        1.62,0.018,LIGHT,0.05,36)
    _cylinder(pad,"DiscoInterior",Vector3(0,0.235,0),
        1.43,0.027,ASPHALT,0.07,36)
    for side in [-1,1]:
        _box(pad,"HelipuertoH_Raya_%s" % side,
            Vector3(float(side)*0.24,0.259,0),
            Vector3(0.12,0.012,0.97),LIGHT,0.05)
    _box(pad,"HelipuertoH_Travesano",Vector3(0,0.259,0),
        Vector3(0.59,0.012,0.12),LIGHT,0.05)
    for i in range(8):
        var angle: float = TAU*float(i)/8.0
        _cylinder(pad,"LuzAproximacion_%d" % i,
            Vector3(cos(angle)*1.52,0.275,sin(angle)*1.52),
            0.075,0.048,GOLD if i%2==0 else accent,0.05,8)
    if level>=2:
        _box(pad,"ArmarioServicioHelipuerto",
            Vector3(2.20,0.50,0.92),Vector3(0.66,0.88,0.58),CEMENT)
        _box(pad,"PantallaEstadoAeronautico",
            Vector3(2.20,0.63,0.60),Vector3(0.45,0.25,0.03),accent,0.27,true)

static func _service(parent: Node3D, accent: Color, level: int,
        damage: int) -> void:
    var service := _group(parent,"SoporteTecnicoV1")
    _box(service,"ModuloCombustible",
        Vector3(4.36,0.42,0.07),Vector3(1.90,0.75,1.48),CEMENT,0.20)
    for i in range(2):
        _cylinder(service,"TanqueCombustible_%d" % i,
            Vector3(3.91+float(i)*0.74,0.91,0.07),0.31,1.10,ALUMINUM,0.42,12,
            Vector3(0,0,90))
    _box(service,"BandaPeligroCombustible",Vector3(4.34,0.90,-0.75),
        Vector3(1.73,0.12,0.08),GOLD)
    _box(service,"UnidadMantenimiento",
        Vector3(-4.99,0.57,3.65),Vector3(1.49,1.05,1.29),WALL,0.12)
    _box(service,"TechoUnidadMantenimiento",
        Vector3(-4.99,1.17,3.65),Vector3(1.60,0.15,1.48),IRON,0.30)
    _box(service,"PortonUnidadMantenimiento",
        Vector3(-4.99,0.53,2.97),Vector3(1.04,0.85,0.07),BLACK,0.34)
    _box(service,"BandaMantenimiento",
        Vector3(-4.99,1.06,2.91),Vector3(1.19,0.12,0.06),accent,0.17,true)
    if level>=3:
        for i in range(4):
            _box(service,"ArmarioElectronico_%d" % i,
                Vector3(-5.55+float(i)*0.39,0.35,5.14),
                Vector3(0.30,0.68,0.53),IRON,0.35)
            _box(service,"BalizaArmario_%d" % i,
                Vector3(-5.55+float(i)*0.39,0.73,4.85),
                Vector3(0.19,0.05,0.03),accent,0.15,true)
    if damage>=2:
        _box(service,"ChapaArrancada",
            Vector3(4.31,0.43,-0.89),Vector3(1.14,0.10,0.58),RUST,0.27,
            false,Vector3(12,0,-19))

static func _damage(parent: Node3D, damage: int) -> void:
    if damage==0:
        return
    var debris := _group(parent,"DanosFisicosBaseAereaV1")
    if damage==1:
        _box(debris,"RadomoDerribado",
            Vector3(4.85,4.06,-2.04),Vector3(0.92,0.14,0.66),IRON,0.29,
            false,Vector3(14,0,22))
    if damage>=2:
        for i in range(10 if damage==2 else 19):
            var x: float = -4.95+float(i%6)*1.24
            var z: float = -3.85+float(int(i/6))*1.37
            _box(debris,"FragmentoHangar_%02d" % i,
                Vector3(x,0.12+float(i%3)*0.05,z),
                Vector3(0.53+float(i%2)*0.24,0.19,0.34),CEMENT if i%3 else RUST,
                0.12,false,Vector3(0,float(i*37),float(i%4)*-8))
    if damage>=3:
        _box(debris,"CerchaMetalicaRetorcida",
            Vector3(-2.0,1.09,-2.45),Vector3(4.0,0.14,0.13),IRON,0.42,
            false,Vector3(13,0,-31))
        _box(debris,"CubiertaDesplomada",
            Vector3(-3.29,0.47,0.06),Vector3(2.44,0.17,1.79),ROOF,0.32,
            false,Vector3(0,10,24))
        for k in range(3):
            _box(debris,"VigaRotaEnSuelo_%d" % k,
                Vector3(-4.3+float(k)*1.49,0.27,2.1),
                Vector3(1.24,0.13,0.12),IRON,0.44,
                false,Vector3(0,float(k)*25,float(k)*-6))
    if damage==4:
        _box(debris,"PlacaHangarHundida",
            Vector3(-1.9,0.37,0),Vector3(6.54,0.22,3.76),RUST,0.27,
            false,Vector3(2,0,-9))
        _box(debris,"TorreDerribada",
            Vector3(3.44,0.46,-1.61),Vector3(3.70,0.57,1.42),CEMENT,0.15,
            false,Vector3(0,35,15))

static func _emblem(parent: Node3D, faction: int, damage: int) -> void:
    if damage==4:
        return
    var atlas: Texture2D = Emblems.emblem_texture(faction)
    if atlas == null:
        return
    var plaque := _group(parent,"PlacaFaccionOficialBaseAerea",
        Vector3(-1.95,2.17,-4.19))
    _box(plaque,"FondoPlacaEscudo",Vector3.ZERO,
        Vector3(0.86,0.87,0.08),BLACK,0.19)
    var quad := QuadMesh.new()
    quad.size = Vector2(0.76,0.77)
    var image := MeshInstance3D.new()
    image.name = "EmblemaOficialAtlasBaseAerea"
    image.mesh = quad
    image.position = Vector3(0,0,-0.054)
    image.rotation_degrees.y = 180.0
    var material := StandardMaterial3D.new()
    material.albedo_color = Color.WHITE
    material.albedo_texture = atlas
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    image.material_override = material
    image.set_meta("tarvoka_official_emblem_index",faction)
    image.set_meta("tarvoka_weather_protect",true)
    plaque.add_child(image)

static func build(level: int = 1,faction: int = 0,
        damage: int = 0) -> Node3D:
    if not valid_spec(level,faction,damage):
        return null
    var root := Node3D.new()
    root.name = "BaseAerea3DV1"
    root.set_meta("tarvoka_building_kind","airbase")
    root.set_meta("tarvoka_airbase_v1",true)
    root.set_meta("visual_level",level)
    root.set_meta("visual_faction",faction)
    root.set_meta("visual_damage_stage",damage)
    root.set_meta("visual_only",true)
    var accent: Color = Style.faction_color(faction)
    _ground(root,accent)
    if damage<4:
        _hangar(root,accent,level,damage)
        _tower(root,accent,level,damage)
        _flight_deck(root,accent,level)
        _service(root,accent,level,damage)
    else:
        # Ruins keep the map tile and hardstand but not intact facilities.
        _box(root,"MurosRestantesDestruccion",Vector3(-5.08,0.63,0.22),
            Vector3(0.34,1.20,6.15),CEMENT,0.15)
        _box(root,"MuroPosteriorCaido",Vector3(-2.02,0.45,2.72),
            Vector3(5.48,0.81,0.36),WALL,0.10,false,Vector3(0,0,8))
    _damage(root,damage)
    _emblem(root,faction,damage)
    return root

static func mesh_count(root: Node) -> int:
    var count := 1 if root is MeshInstance3D else 0
    for child in root.get_children():
        count += mesh_count(child)
    return count

static func count_faction_panels(root: Node) -> int:
    var count := 1 if root.has_meta("tarvoka_faction_panel") else 0
    for child in root.get_children():
        count += count_faction_panels(child)
    return count
