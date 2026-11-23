extends RefCounted
class_name TarvokaCampReconFinishV2

# Native deployable optical reconnaissance CAMP, not a drone/base/new unit.
# ART ONLY: no fog of war, detection range, credits, AI or combat changes.
const CORE := "ReconV2_OpticalOutpost"
const GREY := Color("#5B6D73")
const MID := Color("#83959A")
const DARK := Color("#26383F")
const DEEP := Color("#1D2C31")
const ARMOR := Color("#A6B4AE")
const GLASS := Color("#4B8993") # Opaque optical lens material
const AMBER := Color("#E6A94E")
const CANVAS := Color("#8B9B8E")

static func _mat(tint: Color, metal: float = 0.0,
        rough: float = 0.64) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = tint
    result.metallic = metal
    result.roughness = rough
    result.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    result.cull_mode = BaseMaterial3D.CULL_BACK
    return result

static func _group(parent: Node3D, name: String,
        position: Vector3 = Vector3.ZERO) -> Node3D:
    var group := Node3D.new()
    group.name = name
    group.position = position
    parent.add_child(group)
    return group

static func _box(parent: Node3D, name: String, pos: Vector3,
        dimensions: Vector3, tint: Color, metallic: float = 0.0,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geo := BoxMesh.new()
    geo.size = dimensions
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.mesh = geo
    mesh.position = pos
    mesh.rotation_degrees = angles
    mesh.material_override = _mat(tint, metallic)
    parent.add_child(mesh)
    return mesh

static func _cylinder(parent: Node3D, name: String, pos: Vector3,
        radius: float, length: float, tint: Color, lod: int,
        angles: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var geo := CylinderMesh.new()
    geo.top_radius = radius
    geo.bottom_radius = radius
    geo.height = length
    geo.radial_segments = 16 if lod == 13 else 8
    var mesh := MeshInstance3D.new()
    mesh.name = name
    mesh.mesh = geo
    mesh.position = pos
    mesh.rotation_degrees = angles
    mesh.material_override = _mat(tint, 0.52)
    parent.add_child(mesh)
    return mesh

static func _bar(parent: Node3D, name: String,
        a: Vector3, b: Vector3,
        radius: float, tint: Color, lod: int) -> void:
    var delta: Vector3 = b - a
    if delta.length_squared() <= 0.0001:
        return
    var mesh := _cylinder(parent, name, (a+b)*0.5, radius,
        delta.length(), tint, lod)
    mesh.quaternion = Quaternion(Vector3.UP, delta.normalized())

static func _footprint(assembly: Node3D, accent: Color, lod: int) -> void:
    # Two visually distinct zones: left ground observation operations,
    # right mast/watch tower, central access remains open.
    _box(assembly, "V2_AccesoReforzado",
        Vector3(0.15, 0.09, -2.35),
        Vector3(2.85, 0.17, 0.86), DARK, 0.35)
    _box(assembly, "V2_BandaRutaFaccion",
        Vector3(0.15, 0.185, -2.35),
        Vector3(2.65, 0.035, 0.24), accent, 0.30)
    for side in [-1, 1]:
        _box(assembly, "V2_BordeFaccionLateral_%d" % side,
            Vector3(float(side) * 3.32, 0.21, 1.00),
            Vector3(0.26, 0.31, 2.50), accent, 0.29)
        _box(assembly, "V2_AnclajeLateral_%d" % side,
            Vector3(float(side) * 3.26, 0.24, 2.27),
            Vector3(0.48, 0.35, 0.48), GREY, 0.55)
    if lod == 13:
        for i in range(3):
            _box(assembly, "V2_FranjaPiso_%d" % i,
                Vector3(-0.85 + float(i) * 0.90, 0.022, -2.76),
                Vector3(0.18, 0.045, 0.50), AMBER, 0.25)

static func _control_station(assembly: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    var station := _group(assembly, "V2_CentroControl", 
        Vector3(-1.55, 0.0, 1.38))
    _box(station, "BancadaCerrada",
        Vector3(0, 0.40, 0),
        Vector3(2.22, 0.80, 1.56), GREY, 0.48)
    _box(station, "CarcasaBlindada",
        Vector3(0, 1.18, 0.27),
        Vector3(2.08, 0.84, 0.92), DARK, 0.40)
    _box(station, "PantallaTacticaOpaca",
        Vector3(0, 1.22, -0.215),
        Vector3(1.52, 0.52, 0.07), GLASS, 0.30)
    _box(station, "MarcoPantallaFaccion",
        Vector3(0, 1.63, -0.215),
        Vector3(1.88, 0.15, 0.12), accent, 0.38)
    _box(station, "MesaOperador",
        Vector3(0, 0.87, -0.85),
        Vector3(1.94, 0.14, 0.80), MID, 0.54)
    _box(station, "PanelMandos",
        Vector3(0, 0.96, -0.97),
        Vector3(1.36, 0.09, 0.43), DARK, 0.48)
    for side in [-1, 1]:
        _box(station, "EscudoLateral_%d" % side,
            Vector3(float(side) * 1.13, 0.84, 0.20),
            Vector3(0.14, 1.48, 1.24), GREY, 0.46)
        _box(station, "FranjasControlFaccion_%d" % side,
            Vector3(float(side) * 1.23, 1.20, 0.24),
            Vector3(0.075, 0.45, 1.08), accent, 0.36)
    if damage < 2:
        _box(station, "CubiertaControlMaciza",
            Vector3(0, 1.86, 0.16),
            Vector3(2.48, 0.15, 1.75), CANVAS, 0.15)
        _box(station, "ParasolFaccion",
            Vector3(0, 1.96, -0.55),
            Vector3(2.32, 0.09, 0.32), accent, 0.25)
    if lod == 13:
        for i in range(5):
            _box(station, "BotonRadio_%d" % i,
                Vector3(-0.55 + float(i) * 0.26, 1.025, -1.00),
                Vector3(0.09, 0.065, 0.13), AMBER, 0.21)
        _box(station, "UnidadesProcesamiento",
            Vector3(-0.68, 0.56, -0.803),
            Vector3(0.48, 0.44, 0.17), DEEP, 0.48)
        for i in range(3):
            _box(station, "BandejaModulos_%d" % i,
                Vector3(-0.68, 0.41 + float(i) * 0.14, -0.90),
                Vector3(0.40, 0.06, 0.07), MID, 0.34)

static func _tower(assembly: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    var tower := _group(assembly, "V2_TorreTripode", 
        Vector3(1.35, 0.0, 1.40))
    # Four legs, two crossed tiers and a secured head platform.
    for xsign in [-1, 1]:
        for zsign in [-1, 1]:
            var suffix: String = "%d_%d" % [xsign, zsign]
            _bar(tower, "PataEstructural_" + suffix,
                Vector3(float(xsign) * 1.16, 0.11,
                    float(zsign) * 1.05),
                Vector3(float(xsign) * 0.53, 2.75,
                    float(zsign) * 0.50),
                0.125, GREY, lod)
            _box(tower, "ZapataAcero_" + suffix,
                Vector3(float(xsign) * 1.16, 0.15,
                    float(zsign) * 1.05),
                Vector3(0.43, 0.24, 0.43), DEEP, 0.54)
    for side in [-1, 1]:
        _bar(tower, "ArriostreX_%d" % side,
            Vector3(float(side) * 1.05, 0.50, -0.91),
            Vector3(float(side) * 0.55, 2.47, 0.48),
            0.066, MID, lod)
        _bar(tower, "ArriostreCruz_%d" % side,
            Vector3(float(side) * 1.05, 0.50, 0.91),
            Vector3(float(side) * 0.55, 2.47, -0.48),
            0.060, MID, lod)
    _box(tower, "PlataformaCabezalMaciza",
        Vector3(0, 2.68, 0),
        Vector3(1.52, 0.19, 1.47), DEEP, 0.60)
    _box(tower, "IdentidadSuperiorFaccion",
        Vector3(0, 2.83, -0.63),
        Vector3(1.34, 0.21, 0.15), accent, 0.34)
    for side in [-1, 1]:
        _box(tower, "FranjaCabezalFaccion_%d" % side,
            Vector3(float(side) * 0.72, 2.74, 0),
            Vector3(0.12, 0.27, 1.30), accent, 0.35)
    _box(tower, "BancoTelescopico",
        Vector3(0, 2.99, 0),
        Vector3(0.90, 0.38, 0.88), GREY, 0.58)
    if damage >= 2:
        _box(tower, "MastilRotoFijo",
            Vector3(0.19, 3.18, 0.0),
            Vector3(0.25, 0.91, 0.27), DARK, 0.48,
            Vector3(0, 0, 65))
        _box(tower, "PiezaOpticaCaida",
            Vector3(-0.38, 0.19, -0.25),
            Vector3(0.73, 0.28, 0.54), MID, 0.52,
            Vector3(0, 17, 13))
        return
    mast := _group(tower, "V2_MastilDesplegable",
        Vector3(0, 3.18, 0))
    _cylinder(mast, "ActuadorCentral",
        Vector3(0, 0.54, 0), 0.19, 1.24, GREY, lod)
    _cylinder(mast, "SeccionTelescopica",
        Vector3(0, 1.18, 0), 0.115, 1.42, MID, lod)
    _cylinder(mast, "SelloArticulacion",
        Vector3(0, 1.53, 0), 0.23, 0.16, accent, lod)
    var head := _group(mast, "V2_CabezalOpticoGiratorio",
        Vector3(0, 2.05, 0))
    _box(head, "CarcasaSensorCerrada",
        Vector3(0, 0, 0),
        Vector3(1.52, 0.56, 0.94), GREY, 0.60)
    _box(head, "FrontalSensor",
        Vector3(0, 0.02, -0.50),
        Vector3(1.36, 0.46, 0.12), DEEP, 0.45)
    for side in [-1, 1]:
        _cylinder(head, "OpticaCircular_%d" % side,
            Vector3(float(side) * 0.42, 0.04, -0.584),
            0.185 if lod == 13 else 0.22, 0.15,
            GLASS, lod, Vector3(90, 0, 0))
        _box(head, "PanelColorSensor_%d" % side,
            Vector3(float(side) * 0.68, 0.0, 0),
            Vector3(0.11, 0.37, 0.80), accent, 0.38)
    _box(head, "TapaSensorBlindada",
        Vector3(0, 0.37, 0.0),
        Vector3(1.48, 0.17, 0.90), DARK, 0.46)
    _box(head, "AcopleRadioSuperior",
        Vector3(0, 0.59, 0.12),
        Vector3(0.56, 0.38, 0.45), MID, 0.58)
    if lod == 13:
        for side in [-1, 1]:
            _box(head, "LuzEstado_%d" % side,
                Vector3(float(side) * 0.52, 0.19, -0.573),
                Vector3(0.17, 0.07, 0.07), AMBER, 0.28)
    # Twin deployable solid wings on independent pivots.
    for side in [-1, 1]:
        var wing := _group(head, "V2_PanelAntenaAbatible_%d" % side,
            Vector3(float(side) * 0.76, 0.0, 0.28))
        _box(wing, "PanelActuadorFaccion",
            Vector3(float(side) * 0.62, 0.06, 0),
            Vector3(1.33, 0.12, 0.74), accent, 0.45)
        _box(wing, "EstructuraRadiadora",
            Vector3(float(side) * 0.62, 0.13, 0),
            Vector3(1.22, 0.11, 0.63), DEEP, 0.60)
        if lod == 13:
            for z in [-0.20, 0.20]:
                _box(wing, "RejillaConductor_%d" % int(z * 100),
                    Vector3(float(side) * 0.63, 0.205, z),
                    Vector3(1.07, 0.06, 0.065),
                    MID, 0.55)

static func _ground_antennas(assembly: Node3D, accent: Color,
        lod: int, damage: int) -> void:
    for side in [-1, 1]:
        var x: float = float(side) * 2.67
        var z: float = -1.45
        _box(assembly, "V2_EstabilizadorSensor_%d" % side,
            Vector3(x, 0.19, z),
            Vector3(0.85, 0.28, 0.79), DEEP, 0.52)
        _bar(assembly, "V2_AntenaBaja_%d" % side,
            Vector3(x, 0.33, z),
            Vector3(x + float(side) * 0.13,
                1.80 if damage == 0 else 1.10, z),
            0.095, GREY, lod)
        _box(assembly, "V2_PuntaFaccion_%d" % side,
            Vector3(x + float(side) * 0.13,
                1.82 if damage == 0 else 1.13, z),
            Vector3(0.38, 0.23, 0.36), accent, 0.37)
        if lod == 13:
            _cylinder(assembly, "V2_Aislador_%d" % side,
                Vector3(x, 0.54, z),
                0.17, 0.18, MID, lod)

static func apply(root: Node3D, accent: Color, lod: int,
        damage: int) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "reconocimiento":
        return false
    if lod not in [8, 13] or damage not in [0, 1, 2, 3]:
        return false
    var deployable: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable") as Node3D
    if deployable == null:
        return false
    if damage >= 3:
        root.set_meta("recon_art_v2", 2)
        root.set_meta("recon_art_only", true)
        return true
    if deployable.has_node(CORE):
        return true
    var core := _group(deployable, CORE)
    _footprint(core, accent, lod)
    _control_station(core, accent, lod, damage)
    _tower(core, accent, lod, damage)
    _ground_antennas(core, accent, lod, damage)
    root.set_meta("recon_art_v2", 2)
    root.set_meta("recon_art_only", true)
    root.set_meta("recon_no_gameplay_changes", true)
    pose(root, 1.0)
    return true

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or str(root.get_meta("camp_kind", "")) != "reconocimiento":
        return false
    var damage: int = int(root.get_meta("visual_damage", 0))
    if damage == 3:
        return true
    var core: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable/" + CORE) as Node3D
    if core == null:
        return false
    var t: float = clampf(progress, 0.0, 1.0)
    if damage < 2:
        var mast: Node3D = core.get_node_or_null(
            "V2_TorreTripode/V2_MastilDesplegable") as Node3D
        if mast == null:
            return false
        mast.scale = Vector3(1.0, lerpf(0.45, 1.0, t), 1.0)
        var head: Node3D = mast.get_node_or_null(
            "V2_CabezalOpticoGiratorio") as Node3D
        if head == null:
            return false
        for side in [-1, 1]:
            var wing: Node3D = head.get_node_or_null(
                "V2_PanelAntenaAbatible_%d" % side) as Node3D
            if wing == null:
                return false
            wing.rotation_degrees.y = lerpf(
                float(side) * 82.0, 0.0, t)
    root.set_meta("recon_v2_deploy_progress", t)
    return true

static func pose_scan(root: Node3D, angle_degrees: float) -> bool:
    # Only visual optics head yaw, DOES NOT alter tactical sensor range.
    if root == null or str(root.get_meta("camp_kind", "")) != "reconocimiento":
        return false
    if int(root.get_meta("visual_damage", 0)) >= 2:
        return false
    var head: Node3D = root.get_node_or_null(
        "EquipamientoDesplegable/" + CORE +
        "/V2_TorreTripode/V2_MastilDesplegable/" +
        "V2_CabezalOpticoGiratorio") as Node3D
    if head == null:
        return false
    var scan: float = clampf(angle_degrees, -150.0, 150.0)
    head.rotation_degrees.y = scan
    root.set_meta("recon_v2_visual_scan_degrees", scan)
    return true
