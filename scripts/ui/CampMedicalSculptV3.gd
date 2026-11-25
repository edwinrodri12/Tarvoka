extends RefCounted
class_name TarvokaCampMedicalSculptV3

# Native medical camp ART ONLY. No gameplay, healing or production.
const Base = preload("res://scripts/ui/CampMedicalFinishV2.gd")
const Solid = preload("res://scripts/ui/CampSupplySculptV4.gd")
const FRAME := Color("#435C60")
const ALLOY := Color("#A2B3B0")
const CANVAS := Color("#BCC9BE")
const SEAM := Color("#849A90")
const FLOOR := Color("#526D70")
const RUBBER := Color("#303D3D")
const WHITE := Color("#E5EDE5")
const TEAL := Base.TEAL

static func _mat(tint: Color, metal: float = 0.18, rough: float = 0.72) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = tint
    mat.metallic = metal
    mat.roughness = rough
    mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    mat.cull_mode = BaseMaterial3D.CULL_BACK
    var kind: String = ""
    if tint in [CANVAS, SEAM]:
        kind = "fabric"
    elif tint in [FRAME, ALLOY]:
        kind = "metal"
    elif tint in [FLOOR, RUBBER]:
        kind = "rubber"
    if not kind.is_empty():
        mat.albedo_texture = Solid._finish_map(kind)
        mat.uv1_triplanar = true
        mat.uv1_scale = Vector3(2.8, 2.8, 2.8)
    return mat

static func _group(parent: Node3D, label: String, at: Vector3 = Vector3.ZERO) -> Node3D:
    var node := Node3D.new()
    node.name = label
    node.position = at
    parent.add_child(node)
    return node

static func _part(parent: Node3D, label: String, mesh: Mesh, at: Vector3, tint: Color, metal: float = 0.18, rough: float = 0.72) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name = label
    node.mesh = mesh
    node.position = at
    node.material_override = _mat(tint, metal, rough)
    parent.add_child(node)
    return node

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, tint: Color, bevel: float = 0.035, metal: float = 0.18) -> MeshInstance3D:
    return _part(parent, label, Solid.beveled(size, bevel), at, tint, metal)

static func _replace(parent: Node3D, label: String, bevel: float, tint: Color, metal: float = 0.18) -> bool:
    var part: MeshInstance3D = parent.get_node_or_null(label) as MeshInstance3D
    if part == null or not part.mesh is BoxMesh:
        return false
    part.mesh = Solid.beveled((part.mesh as BoxMesh).size, bevel)
    part.material_override = _mat(tint, metal)
    return true

static func _bar(parent: Node3D, label: String, a: Vector3, b: Vector3, width: float, tint: Color) -> MeshInstance3D:
    var delta: Vector3 = b - a
    var item: MeshInstance3D = _box(parent, label, (a + b) * 0.5, Vector3(width, delta.length(), width), tint, width * 0.14, 0.46)
    item.quaternion = Quaternion(Vector3.UP, delta.normalized())
    return item

# Rounded, sealed roof panel, gently crowned between front and rear.
# The long axis is Z; each section is a closed convex octagon.
static func _roof_mesh(width: float, length: float) -> ArrayMesh:
    var rings: Array = []
    for i in range(5):
        var t: float = float(i) / 4.0
        var z: float = (t - 0.5) * length
        var x: float = width * 0.5 - (0.025 if i in [0, 4] else 0.0)
        var h: float = 0.088
        var y: float = 0.045 * sin(t * PI)
        var b: float = 0.035
        var ring: Array[Vector3] = [
            Vector3(x-b,y+h,z), Vector3(-x+b,y+h,z),
            Vector3(-x,y+h-b,z), Vector3(-x,y-h+b,z),
            Vector3(-x+b,y-h,z), Vector3(x-b,y-h,z),
            Vector3(x,y-h+b,z), Vector3(x,y+h-b,z)]
        rings.append(ring)
    return Solid._loft(rings)

static func _tent(tent: Node3D, accent: Color, lod: int, damage: int) -> void:
    _replace(tent, "ParedTraseraMaciza", 0.065, CANVAS, 0.03)
    _replace(tent, "DintelSanitario", 0.04, accent, 0.34)
    _replace(tent, "UmbralAcceso", 0.035, FRAME, 0.35)
    _replace(tent, "V2_InsigniaSanitaria_FondoFaccion", 0.045, accent, 0.28)
    _replace(tent, "V2_InsigniaSanitaria_CruzTurquesaVertical", 0.012, TEAL, 0.0)
    _replace(tent, "V2_InsigniaSanitaria_CruzTurquesaHorizontal", 0.012, TEAL, 0.0)
    for side in [-1, 1]:
        var x: float = float(side) * 1.98
        _replace(tent, "ParedLateralHermetica_%d" % side, 0.06, CANVAS, 0.03)
        _replace(tent, "MarcoAcceso_%d" % side, 0.035, FRAME, 0.42)
        _replace(tent, "JuntaLateralFaccion_%d" % side, 0.014, accent, 0.2)
        # Solid eaves are carried by posts, footplates and a lower frame.
        for z in [-0.32, 1.05, 2.35]:
            var id: String = "%d_%d" % [side, int(z * 100)]
            _box(tent, "V3_Post_" + id, Vector3(x, 1.10, z),
                Vector3(0.15, 2.02, 0.15), FRAME, 0.027, 0.48)
            _box(tent, "V3_Foot_" + id, Vector3(x, 0.12, z),
                Vector3(0.31, 0.15, 0.30), FRAME, 0.035, 0.44)
        _box(tent, "V3_EaveRail_%d" % side, Vector3(x, 2.13, 1.07),
            Vector3(0.22, 0.19, 3.12), FRAME, 0.035, 0.45)
        _box(tent, "V3_SillRail_%d" % side, Vector3(x, 0.18, 1.07),
            Vector3(0.22, 0.20, 2.73), FRAME, 0.035, 0.38)
        _box(tent, "V3_SidePanelInset_%d" % side, Vector3(x + float(side) * 0.103, 0.73, 1.10),
            Vector3(0.065, 0.72, 1.61), SEAM, 0.02, 0.03)
        if lod == 13:
            for z in [0.12, 1.95]:
                _box(tent, "V3_CanvasHem_%d_%d" % [side, int(z * 100)],
                    Vector3(x + float(side) * 0.11, 1.19, z),
                    Vector3(0.055, 1.62, 0.065), SEAM, 0.012, 0.0)
        var pivot: Node3D = tent.get_node_or_null("V2_CubiertaArticulada_%d" % side) as Node3D
        if pivot == null:
            continue
        # Eave-to-ridge distance: 1.98 / cos(23 degrees) = 2.151.
        # Half roofs end at the common ridge and do not cross each other.
        var panel: MeshInstance3D = pivot.get_node("PanelLonaRefuerzo") as MeshInstance3D
        panel.mesh = _roof_mesh(2.15, 3.19)
        panel.position.x = -float(side) * 1.075
        panel.material_override = _mat(CANVAS, 0.02, 0.90)
        _replace(pivot, "BandaSuperiorFaccion", 0.014, accent, 0.20)
        _replace(pivot, "BordeSellado", 0.016, FRAME, 0.35)
        var band: Node3D = pivot.get_node("BandaSuperiorFaccion") as Node3D
        band.position.y = 0.128
        for z in [-1.53, 1.53]:
            _box(pivot, "V3_RoofEdge_%d" % int(z * 100),
                Vector3(-float(side) * 1.075, 0.013, z),
                Vector3(2.15, 0.17, 0.12), FRAME, 0.026, 0.38)
        _box(pivot, "V3_RidgeHem", Vector3(-float(side) * 2.11, 0.015, 0),
            Vector3(0.075, 0.16, 3.08), SEAM, 0.023, 0.06)
        if lod == 13:
            for i in range(4):
                _replace(pivot, "CosturaTecho_%d" % i, 0.012, SEAM, 0.0)
                var seam: Node3D = pivot.get_node("CosturaTecho_%d" % i) as Node3D
                seam.position.y = 0.13
    # Rear and front structural crosspieces; ridge posts are only at ends,
    # so the open central access remains clear of tall obstructions.
    for z in [-0.40, 2.42]:
        var id: String = str(int(z * 100))
        _box(tent, "V3_GableTie_" + id, Vector3(0, 2.13, z),
            Vector3(3.88, 0.13, 0.15), FRAME, 0.025, 0.44)
        for side in [-1, 1]:
            if damage >= 2 and side == 1:
                continue
            _bar(tent, "V3_GableRafter_%d_%s" % [side, id],
                Vector3(float(side) * 1.98, 2.12, z), Vector3(0, 2.96, z),
                0.12, FRAME)
    if damage >= 2:
        _replace(tent, "FragmentoTechoDaniado", 0.065, SEAM, 0.03)

static func _floor(core: Node3D, accent: Color, lod: int) -> void:
    var deck: Node3D = _group(core, "V3_ClinicalDeck")
    _box(deck, "V3_SanitaryFloor", Vector3(0, 0.065, 1.02),
        Vector3(3.78, 0.09, 2.64), FLOOR, 0.025, 0.0)
    for side in [-1, 1]:
        _box(deck, "V3_FloorEdge_%d" % side, Vector3(float(side) * 1.82, 0.12, 1.02),
            Vector3(0.09, 0.045, 2.55), accent, 0.009, 0.2)
        _replace(core, "V2_GuiaLateralEntrada_%d" % side, 0.022, accent, 0.2)
        _replace(core, "V2_EstabilizadorExterior_%d" % side, 0.045, FRAME, 0.45)
    _replace(core, "V2_PadAcceso", 0.03, FLOOR, 0.05)
    _replace(core, "V2_AccesoSanitarioFaccion", 0.032, accent, 0.25)
    if lod == 13:
        for z in [0.30, 1.00, 1.70]:
            _box(deck, "V3_FloorJoint_%d" % int(z * 100), Vector3(0, 0.116, z),
                Vector3(3.45, 0.019, 0.05), RUBBER, 0.004, 0.0)

# Clinical trolley: closed padded segments on a rigid, wheeled chassis.
static func _wheel(parent: Node3D, label: String, at: Vector3, radius: float, width: float, tint: Color, lod: int) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = width
    mesh.radial_segments = 20 if lod == 13 else 12
    var item: MeshInstance3D = _part(parent, label, mesh, at, tint, 0.38 if tint == ALLOY else 0.02)
    item.rotation_degrees.z = 90.0
    return item

static func _bed(core: Node3D, accent: Color, lod: int, damage: int) -> void:
    var bed: Node3D = core.get_node("V2_CamillaClinica") as Node3D
    # Leave clearance between the outward-folding rail and the side wall.
    bed.position.x = 1.08
    for old in bed.get_children():
        bed.remove_child(old)
        old.free()
    _box(bed, "V31_DeckFrame", Vector3(0, 0.68, 0), Vector3(1.11, 0.14, 2.04), FRAME, 0.05, 0.46)
    _box(bed, "V31_LowerChassis", Vector3(0, 0.36, 0), Vector3(0.85, 0.13, 1.63), FRAME, 0.04, 0.5)
    _box(bed, "V31_FixedMattress", Vector3(0, 0.84, -0.43), Vector3(1.01, 0.21, 1.10), WHITE, 0.075, 0.0)
    _box(bed, "V31_MattressSeam", Vector3(0, 0.918, -0.93), Vector3(0.89, 0.035, 0.044), SEAM, 0.01, 0.0)
    _box(bed, "V31_FactionFootboard", Vector3(0, 0.81, -1.045), Vector3(0.91, 0.29, 0.09), accent, 0.034, 0.24)
    _box(bed, "V31_FootboardGrip", Vector3(0, 0.966, -1.045), Vector3(0.68, 0.055, 0.08), RUBBER, 0.016, 0.0)
    for side in [-1, 1]:
        var x: float = float(side) * 0.42
        for end in [-1, 1]:
            var z: float = float(end) * 0.78
            var id: String = "%d_%d" % [side, end]
            _bar(bed, "V31_ChassisBrace_" + id, Vector3(x, 0.38, z), Vector3(x, 0.64, z * 0.62), 0.085, ALLOY)
            _box(bed, "V31_CasterFork_" + id, Vector3(x, 0.29, z), Vector3(0.18, 0.19, 0.17), FRAME, 0.027, 0.5)
            _wheel(bed, "V31_CasterTire_" + id, Vector3(x, 0.235, z), 0.125, 0.13, RUBBER, lod)
            _wheel(bed, "V31_CasterHub_" + id, Vector3(x, 0.235, z), 0.071, 0.144, ALLOY, lod)
            if lod == 13:
                _box(bed, "V31_BrakePedal_" + id, Vector3(x, 0.31, z + 0.105), Vector3(0.11, 0.045, 0.11), accent, 0.012, 0.2)
        var rail: Node3D = _group(bed, "V31_RailPivot_%d" % side, Vector3(float(side) * 0.55, 0.86, -0.30))
        for z in [-0.52, 0.52]:
            _box(rail, "V31_RailPost_%d" % int(z * 100), Vector3(0, 0.095, z), Vector3(0.055, 0.23, 0.055), ALLOY, 0.013, 0.52)
            _box(bed, "V31_RailHinge_%d_%d" % [side, int(z * 100)], rail.position + Vector3(0, -0.018, z), Vector3(0.10, 0.10, 0.10), FRAME, 0.023, 0.48)
        _box(rail, "V31_RailTop", Vector3(0, 0.205, 0), Vector3(0.065, 0.065, 1.12), ALLOY, 0.02, 0.48)
        if lod == 13:
            _box(rail, "V31_RailGrip", Vector3(0, 0.205, 0), Vector3(0.078, 0.078, 0.39), RUBBER, 0.021, 0.0)
    var back: Node3D = _group(bed, "V31_BackrestPivot", Vector3(0, 0.79, 0.14))
    _box(back, "V31_BackrestShell", Vector3(0, 0.01, 0.43), Vector3(1.05, 0.13, 0.86), FRAME, 0.047, 0.33)
    _box(back, "V31_BackrestCushion", Vector3(0, 0.14, 0.43), Vector3(1.01, 0.19, 0.86), WHITE, 0.072, 0.0)
    _box(back, "V31_HeadPillow", Vector3(0, 0.27, 0.64), Vector3(0.70, 0.12, 0.30), CANVAS, 0.045, 0.0)
    _box(back, "V31_HeadboardGrip", Vector3(0, 0.02, 0.89), Vector3(0.75, 0.07, 0.08), RUBBER, 0.02, 0.0)
    for side in [-1, 1]:
        var x: float = float(side) * 0.41
        _wheel(bed, "V31_BackrestHinge_%d" % side, Vector3(x, 0.79, 0.14), 0.087, 0.16, ALLOY, lod)
    bed.set_meta("clinical_damage", damage)
    _pose_bed(bed, 1.0)

# Visual-only rigid joints; folded/raised positions follow deployment.
static func _pose_bed(bed: Node3D, progress: float) -> void:
    var t: float = clampf(progress, 0.0, 1.0)
    var damage: int = int(bed.get_meta("clinical_damage", 0))
    if damage >= 2:
        t = minf(t, 0.35)
    var back: Node3D = bed.get_node("V31_BackrestPivot") as Node3D
    back.rotation_degrees.x = lerpf(0.0, -28.0, t)
    for side in [-1, 1]:
        var rail: Node3D = bed.get_node("V31_RailPivot_%d" % side) as Node3D
        rail.rotation_degrees.z = float(-side) * lerpf(65.0, 0.0, t)
    bed.set_meta("clinical_deploy_progress", t)

# Replace the inherited equipment once; all components are solid native meshes.
static func _clear_equipment(node: Node3D) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.free()

static func _round(parent: Node3D, label: String, at: Vector3, radius: float, length: float, tint: Color, lod: int) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = length
    mesh.radial_segments = 20 if lod == 13 else 12
    return _part(parent, label, mesh, at, tint, 0.38 if tint == ALLOY else 0.06)

static func _clinical_equipment(core: Node3D, accent: Color, lod: int, damage: int) -> void:
    var cabinet: Node3D = core.get_node("V2_ModuloMedicamentos") as Node3D
    _clear_equipment(cabinet)
    _box(cabinet, "V32_CabinetShell", Vector3(0, 0.96, 0), Vector3(0.84, 1.70, 0.88), WHITE, 0.072, 0.23)
    _box(cabinet, "V32_CabinetPlinth", Vector3(0, 0.075, 0), Vector3(0.78, 0.15, 0.81), FRAME, 0.03, 0.4)
    _box(cabinet, "V32_CabinetTop", Vector3(0, 1.84, 0), Vector3(0.88, 0.12, 0.94), FRAME, 0.037, 0.42)
    for i in range(3):
        var y: float = 0.36 + float(i) * 0.33
        _box(cabinet, "V32_Drawer_%d" % i, Vector3(0, y, -0.462), Vector3(0.73, 0.28, 0.10), CANVAS, 0.027, 0.14)
        _box(cabinet, "V32_DrawerGrip_%d" % i, Vector3(0, y, -0.535), Vector3(0.32, 0.065, 0.075), FRAME, 0.018, 0.42)
        if lod == 13:
            _box(cabinet, "V32_DrawerLabel_%d" % i, Vector3(-0.25, y + 0.06, -0.519), Vector3(0.11, 0.055, 0.015), WHITE, 0.004, 0.0)
    _box(cabinet, "V32_UpperDoor", Vector3(0, 1.40, -0.464), Vector3(0.73, 0.64, 0.10), accent, 0.034, 0.24)
    _box(cabinet, "V32_DoorGrip", Vector3(0.27, 1.42, -0.54), Vector3(0.062, 0.23, 0.07), FRAME, 0.018, 0.45)
    _box(cabinet, "V32_EmblemPlate", Vector3(-0.045, 1.42, -0.527), Vector3(0.42, 0.43, 0.035), WHITE, 0.017, 0.05)
    _box(cabinet, "V32_EmblemVertical", Vector3(-0.045, 1.42, -0.55), Vector3(0.09, 0.30, 0.025), TEAL, 0.008, 0.0)
    _box(cabinet, "V32_EmblemHorizontal", Vector3(-0.045, 1.42, -0.554), Vector3(0.30, 0.09, 0.025), TEAL, 0.008, 0.0)
    # IV is moved next to the foot of the trolley, clear of the entrance.
    var iv: Node3D = core.get_node("V2_SoporteSueros") as Node3D
    _clear_equipment(iv)
    iv.position = Vector3(1.39, 0, -0.95)
    _round(iv, "V32_IVBase", Vector3(0, 0.13, 0), 0.13, 0.18, FRAME, lod)
    for i in range(4):
        var angle: float = TAU * float(i) / 4.0
        var at := Vector3(cos(angle) * 0.19, 0.065, sin(angle) * 0.19)
        var leg: MeshInstance3D = _box(iv, "V32_IVFoot_%d" % i, at, Vector3(0.29, 0.13, 0.09), FRAME, 0.025, 0.4)
        leg.rotation.y = -angle
        _round(iv, "V32_IVPad_%d" % i, Vector3(cos(angle) * 0.28, 0.035, sin(angle) * 0.28), 0.062, 0.07, RUBBER, lod)
    _round(iv, "V32_IVLowerMast", Vector3(0, 0.77, 0), 0.055, 1.32, ALLOY, lod)
    _round(iv, "V32_IVLockCollar", Vector3(0, 1.41, 0), 0.075, 0.11, FRAME, lod)
    _round(iv, "V32_IVUpperMast", Vector3(0, 1.78, 0), 0.035, 0.83, ALLOY, lod)
    _box(iv, "V32_IVCrossbar", Vector3(0, 2.18, 0), Vector3(0.58, 0.075, 0.075), ALLOY, 0.018, 0.44)
    if damage < 2:
        for side in [-1, 1]:
            var x: float = float(side) * 0.23
            _box(iv, "V32_IVHook_%d" % side, Vector3(x, 2.13, 0), Vector3(0.055, 0.11, 0.055), ALLOY, 0.012, 0.43)
            _box(iv, "V32_IVPouch_%d" % side, Vector3(x, 1.93, 0), Vector3(0.20, 0.30, 0.11), CANVAS, 0.044, 0.0)
            _box(iv, "V32_IVLabel_%d" % side, Vector3(x, 1.96, -0.059), Vector3(0.13, 0.11, 0.016), WHITE, 0.008, 0.0)
            _round(iv, "V32_IVOutlet_%d" % side, Vector3(x, 1.74, 0), 0.027, 0.11, FRAME, lod)
    var monitor: Node3D = core.get_node("V2_MonitorPortatil") as Node3D
    _clear_equipment(monitor)
    _box(monitor, "V32_MonitorCart", Vector3(0, 0.49, 0), Vector3(0.76, 0.70, 0.65), FRAME, 0.06, 0.36)
    _box(monitor, "V32_CartBase", Vector3(0, 0.18, 0), Vector3(0.79, 0.14, 0.70), FRAME, 0.03, 0.36)
    for side in [-1, 1]:
        for end in [-1, 1]:
            _wheel(monitor, "V32_CartCaster_%d_%d" % [side, end], Vector3(float(side) * 0.31, 0.18, float(end) * 0.25), 0.07, 0.09, RUBBER, lod)
    _box(monitor, "V32_CartDrawer", Vector3(0, 0.61, -0.35), Vector3(0.64, 0.24, 0.075), WHITE, 0.025, 0.16)
    _box(monitor, "V32_CartGrip", Vector3(0, 0.63, -0.40), Vector3(0.30, 0.052, 0.06), ALLOY, 0.014, 0.38)
    _box(monitor, "V32_CartIdentity", Vector3(0, 0.35, -0.342), Vector3(0.55, 0.14, 0.05), accent, 0.018, 0.2)
    _box(monitor, "V32_Worktop", Vector3(0, 0.89, 0), Vector3(0.85, 0.10, 0.74), WHITE, 0.035, 0.1)
    _box(monitor, "V32_DisplayMount", Vector3(0, 0.98, 0.07), Vector3(0.42, 0.14, 0.26), FRAME, 0.026, 0.4)
    var display: Node3D = _group(monitor, "V32_DisplayPivot", Vector3(0, 1.04, 0.07))
    _box(display, "V32_DisplayHousing", Vector3(0, 0.26, 0), Vector3(0.77, 0.49, 0.26), FRAME, 0.055, 0.24)
    _box(display, "V32_OpaqueScreen", Vector3(0, 0.29, -0.142), Vector3(0.63, 0.31, 0.032), RUBBER, 0.024, 0.03)
    if damage < 2:
        # Abstract decorative status bars, no patient data or transparent glass.
        for i in range(3):
            _box(display, "V32_DisplayStatus_%d" % i, Vector3(-0.13 + float(i) * 0.13, 0.29, -0.161), Vector3(0.085, 0.055 + float(i) * 0.04, 0.012), TEAL, 0.005, 0.0)
    for i in range(3 if lod == 13 else 2):
        _box(display, "V32_Control_%d" % i, Vector3(-0.22 + float(i) * 0.22, 0.068, -0.15), Vector3(0.09, 0.045, 0.032), ALLOY, 0.009, 0.3)
    display.rotation_degrees.x = -12.0 if damage < 2 else 12.0
    _box(monitor, "V32_InstrumentTray", Vector3(-0.24, 0.97, -0.22), Vector3(0.28, 0.065, 0.24), ALLOY, 0.02, 0.42)
    if lod == 13 and damage < 2:
        for i in range(2):
            _box(monitor, "V32_SealedInstrument_%d" % i, Vector3(-0.29 + float(i) * 0.10, 1.02, -0.22), Vector3(0.073, 0.04, 0.15), CANVAS, 0.012, 0.0)
    # A retained power lead runs along the rear housing, not through walking space.
    var points: Array[Vector3] = [Vector3(0.25, 1.10, 0.20), Vector3(0.31, 1.01, 0.30), Vector3(0.31, 0.72, 0.355), Vector3(0.25, 0.61, 0.355)]
    for i in range(points.size() - 1):
        _bar(monitor, "V32_PowerLead_%d" % i, points[i], points[i + 1], 0.035, RUBBER)
    _box(monitor, "V32_PowerSocket", Vector3(0.25, 0.61, 0.34), Vector3(0.10, 0.10, 0.08), FRAME, 0.02, 0.25)

# Deterministic staged deployment. All moving pieces keep their native size.
static func _equipment_pose(core: Node3D, progress: float, damage: int) -> void:
    var t: float = smoothstep(0.05, 0.66, progress)
    var iv: Node3D = core.get_node("V2_SoporteSueros") as Node3D
    var lift: float = lerpf(-0.48, 0.0, t)
    if damage >= 2:
        lift = minf(lift, -0.20)
    for item in iv.get_children():
        if item is Node3D and (item.name == "V32_IVUpperMast" or item.name == "V32_IVCrossbar" or str(item.name).begins_with("V32_IVHook_") or str(item.name).begins_with("V32_IVPouch_") or str(item.name).begins_with("V32_IVLabel_") or str(item.name).begins_with("V32_IVOutlet_")):
            var part: Node3D = item as Node3D
            if not part.has_meta("v33_rest_y"):
                part.set_meta("v33_rest_y", part.position.y)
            part.position.y = float(part.get_meta("v33_rest_y")) + lift
    var monitor: Node3D = core.get_node("V2_MonitorPortatil") as Node3D
    var display: Node3D = monitor.get_node("V32_DisplayPivot") as Node3D
    display.rotation_degrees.x = lerpf(26.0, -12.0 if damage < 2 else 12.0, t)

# Decorative screen cycle, independent of game data. No damaged/packed operation.
static func monitor_frame(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("medical_art_revision", "") != "3.4" or int(root.get_meta("visual_damage", 0)) >= 2:
        return false
    if float(root.get_meta("medical_v3_deploy_progress", 0.0)) < 0.99:
        return false
    var display: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE + "/V2_MonitorPortatil/V32_DisplayPivot") as Node3D
    var t: float = clampf(progress, 0.0, 1.0)
    for i in range(3):
        var indicator: MeshInstance3D = display.get_node("V32_DisplayStatus_%d" % i) as MeshInstance3D
        var mat: StandardMaterial3D = indicator.material_override as StandardMaterial3D
        mat.albedo_color = TEAL.lerp(WHITE, 0.60 * pow(maxf(0.0, sin(t * TAU - float(i) * 1.4)), 2.0))
    root.set_meta("medical_monitor_phase", t)
    return true

static func _monitor_reset(core: Node3D) -> void:
    var display: Node3D = core.get_node("V2_MonitorPortatil/V32_DisplayPivot") as Node3D
    for i in range(3):
        var indicator: MeshInstance3D = display.get_node_or_null("V32_DisplayStatus_%d" % i) as MeshInstance3D
        if indicator != null:
            (indicator.material_override as StandardMaterial3D).albedo_color = TEAL

static func _wreck(root: Node3D, accent: Color, lod: int) -> void:
    var wreck: Node3D = _group(root, "V3_MedicalWreck")
    for side in [-1, 1]:
        var panel: MeshInstance3D = _part(wreck, "V3_FallenRoof_%d" % side,
            _roof_mesh(1.7, 2.55), Vector3(float(side) * 1.65, 0.20, 0.53), SEAM, 0.02, 0.91)
        panel.rotation_degrees = Vector3(6.0, float(side) * 18.0, -8.0)
        _box(panel, "V3_RoofIdentity", Vector3(0, 0.13, -0.63),
            Vector3(1.38, 0.045, 0.30), accent, 0.012)
        _bar(wreck, "V3_FallenFrame_%d" % side, Vector3(float(side) * 2.9, 0.12, -0.8),
            Vector3(float(side) * 1.65, 0.19, -2.3), 0.15, FRAME)
    _box(wreck, "V3_FallenClinicalCabinet", Vector3(-1.9, 0.28, -1.42),
        Vector3(1.15, 0.47, 0.77), WHITE, 0.075).rotation_degrees.y = -24.0
    _box(wreck, "V3_FallenAidPlate", Vector3(0.23, 0.14, -1.32),
        Vector3(0.84, 0.16, 0.91), accent, 0.04).rotation_degrees.y = 17.0
    _box(wreck, "V3_FallenAidTeal", Vector3(0.23, 0.24, -1.32),
        Vector3(0.40, 0.05, 0.17), TEAL, 0.01)

# Damage uses solid, bevelled remnants, not holes made with alpha.
const SCORCH := Color("#403B35")

static func _physical_damage(core: Node3D, lod: int, damage: int) -> void:
    if damage == 0:
        return
    var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
    var marks: Node3D = _group(tent, "V34_SurfaceWear")
    for i in range(5 if lod == 13 else 3):
        var at: Vector3 = Vector3(2.075, 0.72 + float(i % 3) * 0.29, 0.28 + float(i) * 0.31)
        var mark: MeshInstance3D = _box(marks, "V34_Scorch_%d" % i, at, Vector3(0.026, 0.15, 0.19), SCORCH, 0.009, 0.0)
        mark.rotation_degrees.x = float(i) * 23.0
    if damage < 2:
        return
    var post: Node3D = tent.get_node("V3_Post_1_105") as Node3D
    post.rotation_degrees.z = -12.0
    var fallen: Node3D = tent.get_node("FragmentoTechoDaniado") as Node3D
    fallen.rotation_degrees = Vector3(12.0, -17.0, 18.0)
    _bar(tent, "V34_BentBraceLow", Vector3(2.20, 0.14, 1.45), Vector3(1.97, 0.83, 1.36), 0.13, FRAME)
    _bar(tent, "V34_BentBraceHigh", Vector3(1.97, 0.83, 1.36), Vector3(1.74, 1.25, 1.71), 0.13, FRAME)
    var cabinet: Node3D = core.get_node("V2_ModuloMedicamentos") as Node3D
    var drawer: Node3D = cabinet.get_node("V32_Drawer_1") as Node3D
    var handle: Node3D = cabinet.get_node("V32_DrawerGrip_1") as Node3D
    drawer.position.z -= 0.10
    handle.position.z -= 0.10
    if lod == 13:
        var label: Node3D = cabinet.get_node("V32_DrawerLabel_1") as Node3D
        label.position.z -= 0.10
    var monitor: Node3D = core.get_node("V2_MonitorPortatil/V32_DisplayPivot") as Node3D
    _bar(monitor, "V34_ScreenFracture", Vector3(-0.22, 0.40, -0.165), Vector3(0.11, 0.19, -0.165), 0.025, ALLOY)
    _bar(monitor, "V34_ScreenFractureBranch", Vector3(-0.04, 0.285, -0.167), Vector3(0.20, 0.37, -0.167), 0.018, ALLOY)

static func _wreck_detail(wreck: Node3D, accent: Color, lod: int) -> void:
    var trolley: Node3D = _group(wreck, "V34_CollapsedTrolley", Vector3(1.20, 0.19, -0.83))
    trolley.rotation_degrees.y = -31.0
    _box(trolley, "V34_TwistedChassis", Vector3.ZERO, Vector3(1.00, 0.22, 1.65), FRAME, 0.055, 0.42)
    _box(trolley, "V34_CrushedMattress", Vector3(0.03, 0.18, -0.18), Vector3(0.82, 0.16, 1.08), SEAM, 0.06, 0.0).rotation_degrees.z = 12.0
    _box(trolley, "V34_Footboard", Vector3(0, 0.13, -0.85), Vector3(0.78, 0.20, 0.08), accent, 0.02)
    _wheel(trolley, "V34_DetachedCaster", Vector3(0.60, -0.05, 0.37), 0.125, 0.13, RUBBER, lod)
    _box(wreck, "V34_BrokenMonitor", Vector3(-0.84, 0.28, 1.30), Vector3(0.75, 0.38, 0.57), FRAME, 0.06, 0.24).rotation_degrees = Vector3(8.0, 23.0, 15.0)
    _bar(wreck, "V34_FallenIV", Vector3(1.75, 0.12, -2.40), Vector3(2.65, 0.17, -1.22), 0.08, ALLOY)
    for i in range(4 if lod == 13 else 2):
        _box(wreck, "V34_Debris_%d" % i, Vector3(-1.05 + float(i) * 0.46, 0.09, -2.13), Vector3(0.28, 0.16, 0.39), SCORCH, 0.035, 0.1).rotation_degrees.y = float(i) * 37.0

const FX_ROOT := "V34_MedicalDamageFX"

static func _fx(root: Node3D) -> Node3D:
    var existing: Node3D = root.get_node_or_null(FX_ROOT) as Node3D
    if existing != null:
        return existing
    var lod: int = int(root.get_meta("visual_lod", 13))
    var rig: Node3D = _group(root, FX_ROOT)
    rig.set_meta("presentation_only", true)
    var smoke: Node3D = _group(rig, "Smoke")
    var fire: Node3D = _group(rig, "Fire")
    var sparks: Node3D = _group(rig, "Sparks")
    var chips: Node3D = _group(rig, "Chips")
    for i in range(8 if lod == 13 else 4):
        Solid._fx_blob(smoke, "Puff_%d" % i, Color("#455054").lerp(Color("#89928F"), float(i % 3) * 0.24), 0.0, lod)
    for i in range(5 if lod == 13 else 3):
        Solid._fx_blob(fire, "Flame_%d" % i, Color("#E37C31") if i % 2 == 0 else Color("#F6C36D"), 0.8, lod)
    for i in range(8 if lod == 13 else 4):
        Solid._fx_blob(sparks, "Spark_%d" % i, Color("#F5D08A"), 0.9, lod)
    for i in range(4 if lod == 13 else 2):
        _box(chips, "Chip_%d" % i, Vector3.ZERO, Vector3(0.12, 0.065, 0.15), FRAME, 0.012).visible = false
    Solid._fx_blob(rig, "Flash", Color("#FFE2A6"), 1.2, lod)
    return rig

static func damage_fx_pose(root: Node3D, kind: String, progress: float) -> bool:
    if root == null or root.get_meta("medical_art_v3", 0) != 3 or kind not in ["idle", "bullet", "blast", "clear"]:
        return false
    var damage: int = int(root.get_meta("visual_damage", 0))
    if damage == 3 and kind in ["bullet", "blast"]:
        return false
    var rig: Node3D = _fx(root)
    var t: float = clampf(progress, 0.0, 1.0)
    for key in ["Smoke", "Fire", "Sparks", "Chips"]:
        for child in rig.get_node(key).get_children():
            child.visible = false
    var flash: Node3D = rig.get_node("Flash") as Node3D
    flash.visible = false
    root.set_meta("medical_v34_fx_kind", kind)
    root.set_meta("medical_v34_fx_phase", t)
    if kind == "clear" or (kind == "idle" and damage == 0):
        return true
    var idle: bool = kind == "idle"
    var blast: bool = kind == "blast"
    if not idle and t >= 1.0:
        return damage_fx_pose(root, "idle", 0.34)
    var origin: Vector3 = Vector3(1.95, 1.95, 0.65) if damage == 1 else Vector3(1.52, 0.65, 1.57)
    if damage == 3:
        origin = Vector3(-0.85, 0.38, 1.28)
    if not idle:
        origin = Vector3(2.10, 1.55, 0.65) if not blast else Vector3(1.92, 0.85, 1.30)
    var smoke: Node3D = rig.get_node("Smoke") as Node3D
    for i in range(smoke.get_child_count()):
        var puff: Node3D = smoke.get_child(i) as Node3D
        var p: float = fposmod(t + float(i) / float(smoke.get_child_count()), 1.0) if idle else clampf(t * 1.4 - float(i) * 0.035, 0.0, 1.0)
        var size: float = (0.18 + p * 0.62) * sin(PI * p) * (1.0 if blast or damage >= 2 else 0.48)
        puff.visible = p > 0.04 and p < 0.96 and (idle or t > 0.11) and (blast or damage >= 2 or i < 3)
        puff.position = origin + Vector3(p * 0.46 + sin(float(i) * 2.4) * size * 0.54, p * 1.67, cos(float(i) * 1.8) * size * 0.6)
        puff.scale = Vector3(size * 1.6, size * 1.35, size * 1.55)
    var fire: Node3D = rig.get_node("Fire") as Node3D
    for i in range(fire.get_child_count()):
        var flame: Node3D = fire.get_child(i) as Node3D
        var size: float = (0.65 + 0.22 * sin(t * TAU * 3.0 + float(i))) * (0.88 if idle else maxf(0.0, 1.38 - t * 1.6))
        flame.visible = (idle and damage >= 2) or (blast and t > 0.06 and t < 0.62)
        flame.position = origin + Vector3(sin(float(i) * 2.4) * 0.23, size * 0.35, cos(float(i) * 2.4) * 0.19)
        flame.scale = Vector3(size * 0.47, size * 1.22, size * 0.43)
        flame.rotation_degrees.z = sin(t * TAU + float(i)) * 18.0
    if idle:
        return true
    flash.visible = t > 0.0 and t < (0.18 if blast else 0.12)
    flash.position = origin
    flash.scale = Vector3.ONE * maxf(0.025, (1.18 if blast else 0.34) * sin(PI * clampf(t / (0.18 if blast else 0.12), 0.0, 1.0)))
    var sparks: Node3D = rig.get_node("Sparks") as Node3D
    for i in range(sparks.get_child_count()):
        var spark: Node3D = sparks.get_child(i) as Node3D
        spark.visible = t > 0.02 and t < (0.65 if blast else 0.43)
        spark.position = origin + Vector3(cos(float(i) * 2.4), 0.55, sin(float(i) * 2.4)) * t * (1.7 if blast else 0.65) - Vector3.UP * t * t * 0.48
        spark.scale = Vector3(0.045, 0.15 if blast else 0.09, 0.045) * (1.0 - t * 0.7)
    var chips: Node3D = rig.get_node("Chips") as Node3D
    for i in range(chips.get_child_count()):
        var chip: Node3D = chips.get_child(i) as Node3D
        chip.visible = blast and t > 0.08 and t < 0.82
        chip.position = origin + Vector3(cos(float(i) * 2.1) * t * 1.55, sin(PI * t) * 0.95 - t * 0.58, sin(float(i) * 2.1) * t * 1.3)
        chip.rotation_degrees = Vector3(t * 280.0, float(i) * 37.0 + t * 190.0, t * 210.0)
    return true

static func apply(root: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if root == null or root.get_meta("camp_kind", "") != "medico":
        return false
    root.set_meta("medical_art_v3", 3)
    root.set_meta("medical_art_revision", "3.4")
    _replace(root, "PlataformaDesmontable", 0.045, FLOOR, 0.06)
    if damage == 3:
        _wreck(root, accent, lod)
        _wreck_detail(root.get_node("V3_MedicalWreck") as Node3D, accent, lod)
        return damage_fx_pose(root, "idle", 0.34)
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
    var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
    _tent(tent, accent, lod, damage)
    _floor(core, accent, lod)
    _bed(core, accent, lod, damage)
    _clinical_equipment(core, accent, lod, damage)
    _physical_damage(core, lod, damage)
    return pose(root, 1.0) and damage_fx_pose(root, "idle", 0.34)

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("medical_art_v3", 0) != 3:
        return true
    var t: float = clampf(progress, 0.0, 1.0)
    root.set_meta("medical_v3_inspection", false)
    if int(root.get_meta("visual_damage", 0)) < 3:
        var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
        var bed: Node3D = core.get_node("V2_CamillaClinica") as Node3D
        _pose_bed(bed, smoothstep(0.20, 0.78, t))
        _equipment_pose(core, t, int(root.get_meta("visual_damage", 0)))
        _monitor_reset(core)
        root.set_meta("medical_monitor_phase", 0.0)
        var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
        for side in [-1, 1]:
            var pivot: Node3D = tent.get_node_or_null("V2_CubiertaArticulada_%d" % side) as Node3D
            if pivot != null:
                # Open upward/outward, preserving clearance above the bed.
                pivot.rotation_degrees.z = float(side) * lerpf(72.0, 23.0, smoothstep(0.66, 1.0, t))
                # Positive rotation of the left-to-right roof vector raises
                # its inner edge; signs are mirrored for the opposite leaf.
                pivot.rotation_degrees.z *= -1.0
    root.set_meta("medical_v3_deploy_progress", t)
    return true

static func inspect_interior(root: Node3D, enabled: bool) -> bool:
    if root == null or root.get_meta("medical_art_v3", 0) != 3 or int(root.get_meta("visual_damage", 0)) >= 2:
        return false
    var t: float = float(root.get_meta("medical_v3_deploy_progress", 1.0))
    if not enabled:
        return pose(root, t)
    var tent: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE + "/V2_CarpaDesmontable") as Node3D
    for side in [-1, 1]:
        var pivot: Node3D = tent.get_node("V2_CubiertaArticulada_%d" % side) as Node3D
        pivot.rotation_degrees.z = float(-side) * 112.0
    root.set_meta("medical_v3_inspection", true)
    return true
