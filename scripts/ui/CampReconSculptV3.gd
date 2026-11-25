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
    # Reuse validated, deterministic 64px material grain, not alpha decals.
    # Faction pigments retain the exact official albedo.
    var kind: String = ""
    if tint in [GREY, FRAME, ALLOY]:
        kind = "metal"
    elif tint == PANEL:
        kind = "fabric"
    elif tint == GASKET:
        kind = "rubber"
    if not kind.is_empty():
        mat.albedo_texture = Solid._finish_map(kind)
        mat.uv1_triplanar = true
        mat.uv1_scale = Vector3(2.8, 2.8, 2.8)
        mat.set_meta("recon_v31_finish", kind)
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

# Closed swept cable: one continuous tube, no disconnected sticks or flat
# billboard. Endpoints sit on the existing control station and tower frame.
static func _cable(parent: Node3D, label: String, points: Array[Vector3], radius: float, lod: int) -> MeshInstance3D:
    var curve := Curve3D.new()
    curve.bake_interval = 0.08
    for point in points:
        curve.add_point(point)
    var rings: Array = []
    var length: float = curve.get_baked_length()
    var steps: int = 28 if lod == 13 else 14
    var sides: int = 12 if lod == 13 else 8
    for i in range(steps + 1):
        var t: float = length * float(i) / float(steps)
        var center: Vector3 = curve.sample_baked(t)
        var direction: Vector3 = (curve.sample_baked(minf(length, t + 0.03)) - curve.sample_baked(maxf(0.0, t - 0.03))).normalized()
        var reference: Vector3 = Vector3.RIGHT if absf(direction.dot(Vector3.RIGHT)) < 0.90 else Vector3.UP
        var u: Vector3 = direction.cross(reference).normalized()
        var v: Vector3 = direction.cross(u).normalized()
        var ring: Array[Vector3] = []
        for j in range(sides):
            var angle: float = TAU * float(j) / float(sides)
            ring.append(center + radius * (u * cos(angle) + v * sin(angle)))
        rings.append(ring)
    return _part(parent, label, Solid._loft(rings), Vector3.ZERO, GASKET, 0.05, 0.86)

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
    _cyl(mast, "V3_SlidingShaft", Vector3(0, 1.17, 0), 0.135, 1.12, Vector3.UP, ALLOY, lod, 0.29)
    _box(mast, "V31_ActuatorMotorHousing", Vector3(0, 0.32, 0.28),
        Vector3(0.42, 0.45, 0.23), FRAME, 0.045)
    _box(mast, "V31_ActuatorMotorPanel", Vector3(0, 0.32, 0.415),
        Vector3(0.27, 0.29, 0.05), accent, 0.018)
    for z in [-1, 1]:
        _cyl(mast, "V31_ActuatorCollar_%d" % z, Vector3(0, 0.57 + float(z) * 0.37, 0), 0.26, 0.09, Vector3.UP, FRAME, lod)
    var fixed: Array[Vector3] = [Vector3(0, 0.31, 0.41), Vector3(0.20, 0.24, 0.43),
        Vector3(0.32, 0.45, 0.33), Vector3(0.32, 0.87, 0.22), Vector3(0.18, 1.10, 0.19)]
    _cable(mast, "V31_FixedActuatorCable", fixed, 0.035, lod)
    var head: Node3D = mast.get_node("V2_CabezalOpticoGiratorio") as Node3D
    _cyl(head, "V3_YawBearing", Vector3(0, -0.35, 0), 0.32, 0.15, Vector3.UP, FRAME, lod)
    _cyl(head, "V3_BearingAccent", Vector3(0, -0.28, 0), 0.30, 0.09, Vector3.UP, accent, lod)
    _replace(head, "CarcasaSensorCerrada", 0.12, GREY, 0.54)
    _replace(head, "FrontalSensor", 0.045, FRAME, 0.48)
    _replace(head, "TapaSensorBlindada", 0.05, PANEL, 0.35)
    _replace(head, "AcopleRadioSuperior", 0.07, GREY, 0.45)
    # Distinct central electronics housing and mechanically anchored sides.
    _box(head, "V31_CentralOpticsBridge", Vector3(0, 0.02, -0.57),
        Vector3(0.24, 0.43, 0.22), GREY, 0.055)
    _box(head, "V31_RearServiceBlock", Vector3(0, -0.08, 0.51),
        Vector3(0.37, 0.28, 0.16), FRAME, 0.045)
    _cyl(head, "V31_RearConnector", Vector3(0, -0.08, 0.62), 0.085, 0.095, Vector3.BACK, ALLOY, lod)
    var wire: Array[Vector3] = [Vector3(0, -0.08, 0.67), Vector3(0, -0.20, 0.76),
        Vector3(0.10, -0.34, 0.61), Vector3(0.14, -0.35, 0.28)]
    _cable(head, "V31_OpticalHeadCable", wire, 0.032, lod)
    for side in [-1, 1]:
        _box(head, "V31_SideHingeBracket_%d" % side, Vector3(float(side) * 0.72, -0.08, 0.26),
            Vector3(0.23, 0.32, 0.43), FRAME, 0.045)
        if lod == 13:
            for i in range(3):
                _box(head, "V31_HeatSink_%d_%d" % [side, i], Vector3(float(side) * (0.22 + float(i) * 0.16), 0.485, 0.30),
                    Vector3(0.055, 0.09, 0.27), FRAME, 0.012)
    for side in [-1, 1]:
        var x: float = float(side) * 0.42
        (head.get_node("OpticaCircular_%d" % side) as Node3D).visible = false
        _cyl(head, "V3_OpticalBarrel_%d" % side, Vector3(x, 0.04, -0.59), 0.235, 0.24, Vector3.FORWARD, FRAME, lod)
        _cyl(head, "V3_LensBezel_%d" % side, Vector3(x, 0.04, -0.73), 0.205, 0.075, Vector3.FORWARD, ALLOY, lod)
        _cyl(head, "V3_OpaqueLens_%d" % side, Vector3(x, 0.04, -0.779), 0.165, 0.045, Vector3.FORWARD, OPTIC, lod, 0.22)
        _cyl(head, "V3_LensCore_%d" % side, Vector3(x, 0.04, -0.806), 0.093, 0.017, Vector3.FORWARD, OPTIC_LIGHT, lod, 0.20)
        # Opaque solid rim and hood; lenses remain readable front and side.
        _box(head, "V31_OpticBrow_%d" % side, Vector3(x, 0.27, -0.66),
            Vector3(0.49, 0.095, 0.34), FRAME, 0.028)
        if lod == 13:
            for bolt in [-1, 1]:
                _cyl(head, "V31_OpticBolt_%d_%d" % [side, bolt],
                    Vector3(x + float(bolt) * 0.18, -0.14, -0.67), 0.033, 0.04, Vector3.FORWARD, ALLOY, lod)
        _cyl(head, "V31_OpticAuxPort_%d" % side, Vector3(x * 0.38, -0.12, -0.70),
            0.045, 0.08, Vector3.FORWARD, OPTIC, lod)
        _box(head, "V3_RearFactionPlate_%d" % side, Vector3(float(side) * 0.45, 0.01, 0.48),
            Vector3(0.49, 0.27, 0.085), accent, 0.025)
        var wing: Node3D = head.get_node("V2_PanelAntenaAbatible_%d" % side) as Node3D
        _replace(wing, "PanelActuadorFaccion", 0.04, accent)
        _replace(wing, "EstructuraRadiadora", 0.035, FRAME)
        _cyl(wing, "V3_WingHinge", Vector3(0.055 * float(side), 0.05, 0), 0.11, 0.48, Vector3.BACK, ALLOY, lod)
        _box(wing, "V31_WingRootClevis", Vector3(float(side) * 0.12, -0.025, 0),
            Vector3(0.24, 0.20, 0.42), FRAME, 0.03)
        for z in [-0.25, 0.25]:
            _box(wing, "V3_WingEdge_%d" % int(z * 100), Vector3(float(side) * 0.65, 0.18, z),
                Vector3(1.08, 0.075, 0.07), GREY, 0.012)
    return true

# V3.2 station: closed solid electronic equipment, front-facing screen
# instrumentation, anchored radio bays and a reinforced portable canopy.
static func _lit(part: MeshInstance3D, tint: Color, energy: float) -> void:
    var mat: StandardMaterial3D = part.material_override as StandardMaterial3D
    mat.emission_enabled = energy > 0.0
    mat.emission = tint
    mat.emission_energy_multiplier = energy

static func _station_v32(station: Node3D, accent: Color, lod: int, damage: int) -> void:
    var live: bool = damage < 2
    var ui_tint: Color = OPTIC_LIGHT if live else FRAME
    var instrument: Node3D = _group(station, "V32_InstrumentDeck")
    # Replace the older decorative bars and loose identical buttons.
    for child in station.get_children():
        if str(child.name).begins_with("V3_DisplayTrace_") or str(child.name).begins_with("BotonRadio_"):
            child.visible = false
    # Main monitor is a solid screen with a real surrounding bezel and
    # animated thin raised traces, not a transparent plane.
    for side in [-1, 1]:
        _box(instrument, "V32_ScreenSideBezel_%d" % side, Vector3(float(side) * 0.77, 1.22, -0.263),
            Vector3(0.10, 0.58, 0.09), FRAME, 0.018)
        _box(instrument, "V32_ScreenHorizontalBezel_%d" % side, Vector3(0, 1.22 + float(side) * 0.28, -0.263),
            Vector3(1.48, 0.075, 0.09), FRAME, 0.012)
    var display: Node3D = _group(instrument, "V32_Display")
    for i in range(4 if lod == 13 else 2):
        var row_y: float = 1.08 + float(i) * (0.085 if lod == 13 else 0.18)
        _box(display, "V32_TraceBackground_%d" % i, Vector3(-0.29, row_y, -0.267),
            Vector3(0.66, 0.028, 0.014), Color("#31474B"), 0.003, 0.0)
        var trace: MeshInstance3D = _box(display, "V32_Trace_%d" % i, Vector3(-0.37, row_y, -0.279),
            Vector3(0.48, 0.025, 0.012), ui_tint, 0.003, 0.0)
        _lit(trace, ui_tint, 0.24 if live else 0.0)
    var scope: MeshInstance3D = _cyl(display, "V32_ScopeFace", Vector3(0.40, 1.22, -0.275),
        0.195, 0.022, Vector3.FORWARD, Color("#29454A") if live else FRAME, lod, 0.32)
    _lit(scope, OPTIC, 0.08 if live else 0.0)
    var needle: Node3D = _group(display, "V32_ScopePivot", Vector3(0.40, 1.22, -0.292))
    var sweep: MeshInstance3D = _box(needle, "V32_ScopeSweep", Vector3(0, 0.081, 0),
        Vector3(0.023, 0.162, 0.012), ui_tint, 0.003, 0.0)
    _lit(sweep, ui_tint, 0.28 if live else 0.0)
    # Twin communication modules mounted on the monitor housing.
    for side in [-1, 1]:
        var x: float = float(side) * 0.91
        _box(instrument, "V32_RadioHousing_%d" % side, Vector3(x, 1.19, -0.21),
            Vector3(0.22, 0.52, 0.18), GREY, 0.025)
        _box(instrument, "V32_RadioFace_%d" % side, Vector3(x, 1.19, -0.315),
            Vector3(0.16, 0.43, 0.04), FRAME, 0.012)
        _cyl(instrument, "V32_RadioDial_%d" % side, Vector3(x, 1.10, -0.348),
            0.055, 0.045, Vector3.FORWARD, ALLOY, lod)
        var led: MeshInstance3D = _box(instrument, "V32_RadioLED_%d" % side,
            Vector3(x, 1.31, -0.344), Vector3(0.080, 0.044, 0.018),
            Color("#D5AE62") if live else FRAME, 0.004, 0.0)
        _lit(led, Color("#E1B765"), 0.35 if live else 0.0)
        if lod == 13:
            for i in range(2):
                _box(instrument, "V32_RadioSlot_%d_%d" % [side, i],
                    Vector3(x, 1.22 + float(i) * 0.045, -0.342),
                    Vector3(0.11, 0.016, 0.015), GREY, 0.003)
    # Solid button banks sit on top of the existing desk.
    for side in [-1, 1]:
        var x: float = float(side) * 0.43
        _box(instrument, "V32_ControlBank_%d" % side, Vector3(x, 1.025, -0.96),
            Vector3(0.40, 0.06, 0.32), GREY, 0.018)
        for i in range(3 if lod == 13 else 2):
            _box(instrument, "V32_Key_%d_%d" % [side, i],
                Vector3(x - 0.12 + float(i) * 0.12, 1.067, -1.00),
                Vector3(0.085, 0.045, 0.11), accent if i == 0 else FRAME, 0.008)
    _cyl(instrument, "V32_SelectorKnob", Vector3(0, 1.07, -0.97),
        0.075, 0.11, Vector3.UP, ALLOY, lod)
    _box(station, "V32_OperatorTread", Vector3(0, 0.07, -1.45),
        Vector3(1.72, 0.14, 0.46), GASKET, 0.025, 0.10)
    for side in [-1, 1]:
        _box(station, "V32_TreadEdge_%d" % side, Vector3(float(side) * 0.79, 0.135, -1.45),
            Vector3(0.11, 0.035, 0.38), accent, 0.008)
    if live:
        # Existing canopy becomes a raised, frame-supported enclosure.
        var roof: MeshInstance3D = station.get_node("CubiertaControlMaciza") as MeshInstance3D
        roof.position.y = 2.06
        var visor: MeshInstance3D = station.get_node("ParasolFaccion") as MeshInstance3D
        visor.position.y = 2.16
        for side in [-1, 1]:
            var support: MeshInstance3D = station.get_node("V3_CanopySupport_%d" % side) as MeshInstance3D
            support.mesh = Solid.beveled(Vector3(0.12, 1.00, 0.13), 0.025)
            support.position.y = 1.51
            _box(station, "V32_RearCanopyPost_%d" % side, Vector3(float(side) * 1.04, 1.80, 0.67),
                Vector3(0.13, 0.49, 0.13), FRAME, 0.025)
            _box(station, "V32_CanopySideRail_%d" % side, Vector3(float(side) * 1.12, 2.10, 0.15),
                Vector3(0.14, 0.16, 1.63), accent, 0.025)
        for z in [-0.39, 0.30, 0.76]:
            _box(station, "V32_CanopyRib_%d" % int(z * 100), Vector3(0, 2.15, z),
                Vector3(2.18, 0.095, 0.13), GREY, 0.022)
        _box(station, "V32_CanopyTopIdentity", Vector3(0, 2.155, 0.04),
            Vector3(1.25, 0.035, 0.38), accent, 0.008)
        _box(station, "V32_LampMount", Vector3(0, 1.96, -0.22),
            Vector3(0.94, 0.12, 0.22), FRAME, 0.022)
        var diffuser: MeshInstance3D = _box(station, "V32_LampDiffuser", Vector3(0, 1.887, -0.22),
            Vector3(0.83, 0.045, 0.14), Color("#C4D9CE"), 0.008, 0.0)
        _lit(diffuser, Color("#C4D9CE"), 0.48)
        var light := OmniLight3D.new()
        light.name = "V32_StationLight"
        light.position = Vector3(0, 1.83, -0.29)
        light.light_color = Color("#CCDED1")
        light.light_energy = 0.38
        light.omni_range = 1.65
        light.shadow_enabled = false
        light.visible = lod == 13
        station.add_child(light)
    else:
        # Broken canopy remains on the deck, no functioning light.
        _box(station, "V32_FallenCanopy", Vector3(-0.72, 0.18, -1.38),
            Vector3(0.92, 0.16, 0.55), GREY, 0.045).rotation_degrees = Vector3(12.0, -22.0, 15.0)

static func station_pose(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("recon_art_v3", 0) != 3 or int(root.get_meta("visual_damage", 0)) >= 2:
        return false
    var display: Node3D = root.get_node_or_null("EquipamientoDesplegable/" + BASE.CORE + "/V2_CentroControl/V32_InstrumentDeck/V32_Display") as Node3D
    if display == null:
        return false
    var t: float = clampf(progress, 0.0, 1.0)
    var scope: Node3D = display.get_node("V32_ScopePivot") as Node3D
    scope.rotation_degrees.z = -360.0 * t
    for child in display.get_children():
        if str(child.name).begins_with("V32_Trace_"):
            var index: int = int(str(child.name).get_slice("_", 2))
            child.scale.x = 0.75 + 0.24 * sin(t * TAU + float(index) * 1.7)
    var instrument: Node3D = display.get_parent() as Node3D
    for side in [-1, 1]:
        var led: MeshInstance3D = instrument.get_node("V32_RadioLED_%d" % side) as MeshInstance3D
        var mat: StandardMaterial3D = led.material_override as StandardMaterial3D
        mat.emission_energy_multiplier = 0.18 + 0.42 * (0.5 + 0.5 * sin(t * TAU * 2.0 + float(side)))
    root.set_meta("recon_v32_station_phase", t)
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
    root.set_meta("recon_art_revision", "3.2")
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
    _station_v32(station, accent, lod, damage)
    if not _tower(tower, accent, lod, damage):
        return false
    # Low conduit from control housing to the rear leg; fixed wiring stays
    # attached as the sensor telescopes and rotates.
    var cable_points: Array[Vector3] = [Vector3(-0.53, 0.39, 2.10), Vector3(-0.49, 0.17, 2.23),
        Vector3(-0.15, 0.12, 2.42), Vector3(0.19, 0.21, 2.45), Vector3(0.35, 0.80, 2.31),
        Vector3(0.61, 1.70, 2.11), Vector3(0.82, 2.70, 1.90)]
    _cable(core, "V31_StationTowerConduit", cable_points, 0.055, lod)
    _box(station, "V31_CableJunction", Vector3(1.02, 0.39, 0.72), Vector3(0.24, 0.28, 0.20), FRAME, 0.045)
    for i in range(3 if lod == 13 else 1):
        _box(core, "V31_DeckConduitClamp_%d" % i, Vector3(-0.43 + float(i) * 0.27, 0.135, 2.32 + float(i) * 0.055),
            Vector3(0.12, 0.16, 0.20), ALLOY, 0.022)
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
    shaft.position.y = lerpf(0.56, 1.17, t)
    head.position.y = lerpf(1.46, 2.07, t)
    root.set_meta("recon_v3_deploy_progress", t)
    return true
