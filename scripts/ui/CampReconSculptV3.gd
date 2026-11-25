extends RefCounted
class_name TarvokaCampReconSculptV3

# Native cosmetic upgrade; keeps V2 hierarchy and approved specialist.
# No tactical detection, combat or resource logic.
const Solid = preload("res://scripts/ui/CampSupplySculptV4.gd")
const BASE = preload("res://scripts/ui/CampReconFinishV2.gd")
const GREY := Color("#52656B")
const FRAME := Color("#293A42")
const ALLOY := Color("#A3B2B3")
const PANEL := Color("#768984")
const OPTIC := Color("#38646C")
const OPTIC_LIGHT := Color("#8DB3B1")
const GASKET := Color("#202E32")

static func _mat(tint: Color, metallic: float, rough: float = 0.55) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = metallic
    mat.roughness = rough
    mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    mat.cull_mode = BaseMaterial3D.CULL_BACK
    return mat

static func _group(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = at
    parent.add_child(node)
    return node

static func _part(parent: Node3D, label: String, mesh: Mesh, at: Vector3, tint: Color, metal: float = 0.42, rough: float = 0.55) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = at
    node.material_override = _mat(tint, metal, rough)
    node.set_meta("recon_v3_solid", true)
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, tint: Color, bevel: float = 0.035, metal: float = 0.42) -> MeshInstance3D:
    return _part(parent, label, Solid.beveled(size, bevel), at, tint, metal)

static func _cyl(parent: Node3D, label: String, at: Vector3, radius: float, length: float, axis: Vector3, tint: Color, lod: int, rough: float = 0.48) -> MeshInstance3D:
    var geo := CylinderMesh.new()
    geo.top_radius = radius
    geo.bottom_radius = radius
    geo.height = length
    geo.radial_segments = 24 if lod == 13 else 12
    var node: MeshInstance3D = _part(parent, label, geo, at, tint, 0.55, rough)
    node.quaternion = Quaternion(Vector3.UP, axis.normalized())
    return node

static func _replace(parent: Node3D, label: String, bevel: float, tint: Color, metal: float = 0.4) -> bool:
    var node: MeshInstance3D = parent.get_node_or_null(label) as MeshInstance3D
    if node == null or not node.mesh is BoxMesh:
        return false
    var size: Vector3 = (node.mesh as BoxMesh).size
    node.mesh = Solid.beveled(size, bevel)
    node.material_override = _mat(tint, metal)
    node.set_meta("recon_v3_solid", true)
    return true

static func _tower(tower: Node3D, accent: Color, lod: int, damage: int) -> bool:
    # Replace cylinders with chamfered rigid struts, preserving attachment points.
    for xs in [-1, 1]:
        for zs in [-1, 1]:
            var suffix: String = "%d_%d" % [xs, zs]
            var leg: MeshInstance3D = tower.get_node("PataEstructural_" + suffix) as MeshInstance3D
            var length: float = (leg.mesh as CylinderMesh).height
            leg.mesh = Solid.beveled(Vector3(0.24, length, 0.24), 0.035)
            leg.material_override = _mat(GREY, 0.52)
            leg.set_meta("recon_v3_solid", true)
            _replace(tower, "ZapataAcero_" + suffix, 0.065, FRAME, 0.55)
            var foot := Vector3(float(xs) * 1.16, 0.30, float(zs) * 1.05)
            _box(tower, "V3_FootSocket_" + suffix, foot, Vector3(0.33, 0.30, 0.33), accent, 0.045)
            if lod == 13:
                for side in [-1, 1]:
                    _cyl(tower, "V3_FootPin_%s_%d" % [suffix, side],
                        foot + Vector3(float(side) * 0.19, 0.0, 0.0), 0.055, 0.07, Vector3.RIGHT, ALLOY, lod)
    _replace(tower, "PlataformaCabezalMaciza", 0.06, FRAME, 0.57)
    _replace(tower, "BancoTelescopico", 0.075, GREY, 0.54)
    for side in [-1, 1]:
        _box(tower, "V3_HeadFrame_%d" % side, Vector3(float(side) * 0.66, 2.62, 0),
            Vector3(0.17, 0.28, 1.38), accent, 0.03)
        _box(tower, "V3_TierRail_%d" % side, Vector3(float(side) * 0.82, 1.48, 0),
            Vector3(0.15, 0.17, 1.55), FRAME, 0.035)
        _box(tower, "V3_TierCrossbeam_%d" % side, Vector3(0, 1.48, float(side) * 0.78),
            Vector3(1.66, 0.17, 0.15), FRAME, 0.035)
    if damage >= 2:
        _replace(tower, "MastilRotoFijo", 0.045, FRAME, 0.48)
        _replace(tower, "PiezaOpticaCaida", 0.075, GREY, 0.44)
        _box(tower, "V3_BrokenHeadShroud", Vector3(-0.38, 0.36, -0.25),
            Vector3(0.66, 0.18, 0.46), GASKET, 0.035).rotation_degrees = Vector3(0, 17, 13)
        return true
    var mast: Node3D = tower.get_node("V2_MastilDesplegable") as Node3D
    for key in ["ActuadorCentral", "SeccionTelescopica", "SelloArticulacion"]:
        (mast.get_node(key) as Node3D).visible = false
    _cyl(mast, "V3_OuterMast", Vector3(0, 0.53, 0), 0.245, 1.12, Vector3.UP, GREY, lod)
    _cyl(mast, "V3_FixedUpperCollar", Vector3(0, 1.10, 0), 0.29, 0.19, Vector3.UP, accent, lod)
    _cyl(mast, "V3_FixedSeal", Vector3(0, 1.205, 0), 0.205, 0.07, Vector3.UP, GASKET, lod)
    _cyl(mast, "V3_SlidingShaft", Vector3(0, 1.52, 0), 0.135, 1.25, Vector3.UP, ALLOY, lod, 0.29)
    var head: Node3D = mast.get_node("V2_CabezalOpticoGiratorio") as Node3D
    _cyl(head, "V3_YawBearing", Vector3(0, -0.35, 0), 0.32, 0.15, Vector3.UP, FRAME, lod)
    _cyl(head, "V3_BearingAccent", Vector3(0, -0.28, 0), 0.30, 0.09, Vector3.UP, accent, lod)
    _replace(head, "CarcasaSensorCerrada", 0.12, GREY, 0.54)
    _replace(head, "FrontalSensor", 0.045, FRAME, 0.48)
    _replace(head, "TapaSensorBlindada", 0.05, PANEL, 0.35)
    _replace(head, "AcopleRadioSuperior", 0.07, GREY, 0.45)
    for side in [-1, 1]:
        var x: float = float(side) * 0.42
        (head.get_node("OpticaCircular_%d" % side) as Node3D).visible = false
        _cyl(head, "V3_OpticalBarrel_%d" % side, Vector3(x, 0.04, -0.59), 0.235, 0.24, Vector3.FORWARD, FRAME, lod)
        _cyl(head, "V3_LensBezel_%d" % side, Vector3(x, 0.04, -0.73), 0.205, 0.075, Vector3.FORWARD, ALLOY, lod)
        _cyl(head, "V3_OpaqueLens_%d" % side, Vector3(x, 0.04, -0.779), 0.165, 0.045, Vector3.FORWARD, OPTIC, lod, 0.22)
        _cyl(head, "V3_LensCore_%d" % side, Vector3(x, 0.04, -0.806), 0.093, 0.017, Vector3.FORWARD, OPTIC_LIGHT, lod, 0.20)
        _box(head, "V3_RearFactionPlate_%d" % side, Vector3(float(side) * 0.45, 0.01, 0.48),
            Vector3(0.49, 0.27, 0.085), accent, 0.025)
        var wing: Node3D = head.get_node("V2_PanelAntenaAbatible_%d" % side) as Node3D
        _replace(wing, "PanelActuadorFaccion", 0.04, accent)
        _replace(wing, "EstructuraRadiadora", 0.035, FRAME)
        _cyl(wing, "V3_WingHinge", Vector3(0.055 * float(side), 0.05, 0), 0.11, 0.48, Vector3.BACK, ALLOY, lod)
        for z in [-0.25, 0.25]:
            _box(wing, "V3_WingEdge_%d" % int(z * 100), Vector3(float(side) * 0.65, 0.18, z),
                Vector3(1.08, 0.075, 0.07), GREY, 0.012)
    return true

static func _station(station: Node3D, accent: Color, lod: int, damage: int) -> void:
    _replace(station, "BancadaCerrada", 0.12, GREY, 0.43)
    _replace(station, "CarcasaBlindada", 0.13, FRAME, 0.52)
    _replace(station, "PantallaTacticaOpaca", 0.028, OPTIC, 0.30)
    _replace(station, "MesaOperador", 0.05, ALLOY, 0.43)
    _replace(station, "PanelMandos", 0.03, FRAME, 0.38)
    for side in [-1, 1]:
        _replace(station, "EscudoLateral_%d" % side, 0.05, GREY)
        _replace(station, "FranjasControlFaccion_%d" % side, 0.025, accent)
        _box(station, "V3_StationSideRail_%d" % side, Vector3(float(side) * 1.15, 0.35, 0.14),
            Vector3(0.12, 0.18, 1.22), FRAME, 0.025)
        _box(station, "V3_RearHatch_%d" % side, Vector3(float(side) * 0.53, 1.12, 0.755),
            Vector3(0.92, 0.62, 0.09), PANEL, 0.035)
        _box(station, "V3_RearHatchHandle_%d" % side, Vector3(float(side) * 0.53, 1.15, 0.82),
            Vector3(0.31, 0.065, 0.085), FRAME, 0.014)
        if lod == 13:
            for i in range(4):
                _box(station, "V3_RearVent_%d_%d" % [side, i], Vector3(float(side) * 0.53, 0.30 + float(i) * 0.105, 0.805),
                    Vector3(0.69, 0.045, 0.095), FRAME, 0.008)
    if damage < 2:
        _replace(station, "CubiertaControlMaciza", 0.045, PANEL, 0.16)
        _replace(station, "ParasolFaccion", 0.025, accent)
        for side in [-1, 1]:
            _box(station, "V3_CanopySupport_%d" % side, Vector3(float(side) * 1.04, 1.45, -0.51),
                Vector3(0.12, 0.76, 0.13), FRAME, 0.025)
    for i in range(3 if lod == 13 else 2):
        _box(station, "V3_DisplayTrace_%d" % i, Vector3(-0.30, 1.10 + float(i) * 0.10, -0.263),
            Vector3(0.54 - float(i) * 0.08, 0.035, 0.014), OPTIC_LIGHT if damage < 2 else FRAME, 0.003, 0.1)
    if damage >= 1:
        _box(station, "V3_AbradedRearPanel", Vector3(0.57, 1.36, 0.81), Vector3(0.30, 0.045, 0.035), ALLOY, 0.005).rotation_degrees.z = 24.0

static func apply(root: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if root == null or root.get_meta("camp_kind", "") != "reconocimiento":
        return false
    root.set_meta("recon_art_v3", 3)
    root.set_meta("recon_v3_art_only", true)
    _replace(root, "PlataformaDesmontable", 0.045, PANEL, 0.12)
    if damage == 3:
        var wreck: Node3D = _group(root, "V3_ReconWreck")
        for i in range(4 if lod == 13 else 2):
            _box(wreck, "V3_CollapsedStrut_%d" % i, Vector3(-1.65 + float(i) * 1.12, 0.18, 0.10 + float(i % 2) * 0.7),
                Vector3(0.19, 0.23, 1.72), FRAME, 0.035).rotation_degrees.y = float(i) * 32.0 + 17.0
        _box(wreck, "V3_CollapsedOptic", Vector3(1.35, 0.22, -1.36),
            Vector3(0.93, 0.34, 0.65), GREY, 0.075).rotation_degrees = Vector3(9, 24, 12)
        return true
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + BASE.CORE) as Node3D
    var station: Node3D = core.get_node("V2_CentroControl") as Node3D
    var tower: Node3D = core.get_node("V2_TorreTripode") as Node3D
    _station(station, accent, lod, damage)
    if not _tower(tower, accent, lod, damage):
        return false
    for side in [-1, 1]:
        _replace(core, "V2_EstabilizadorSensor_%d" % side, 0.07, FRAME)
        _replace(core, "V2_PuntaFaccion_%d" % side, 0.05, accent)
    return pose(root, 1.0)

static func pose(root: Node3D, progress: float) -> bool:
    if root.get_meta("recon_art_v3", 0) != 3 or int(root.get_meta("visual_damage", 0)) >= 2:
        return true
    var mast: Node3D = root.get_node("EquipamientoDesplegable/" + BASE.CORE + "/V2_TorreTripode/V2_MastilDesplegable") as Node3D
    # V2 applied a scale transform. V3 cancels it and translates rigid
    # pieces instead. Head and wings retain the same dimensions at all t.
    mast.scale = Vector3.ONE
    var t: float = clampf(progress, 0.0, 1.0)
    var shaft: Node3D = mast.get_node("V3_SlidingShaft") as Node3D
    var head: Node3D = mast.get_node("V2_CabezalOpticoGiratorio") as Node3D
    shaft.position.y = lerpf(0.91, 1.52, t)
    head.position.y = lerpf(1.46, 2.07, t)
    root.set_meta("recon_v3_deploy_progress", t)
    return true
