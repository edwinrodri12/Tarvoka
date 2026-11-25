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

static func apply(root: Node3D, accent: Color, lod: int, damage: int) -> bool:
    if root == null or root.get_meta("camp_kind", "") != "medico":
        return false
    root.set_meta("medical_art_v3", 3)
    root.set_meta("medical_art_revision", "3.1")
    _replace(root, "PlataformaDesmontable", 0.045, FLOOR, 0.06)
    if damage == 3:
        _wreck(root, accent, lod)
        return true
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
    var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
    _tent(tent, accent, lod, damage)
    _floor(core, accent, lod)
    _bed(core, accent, lod, damage)
    return pose(root, 1.0)

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("medical_art_v3", 0) != 3:
        return true
    var t: float = clampf(progress, 0.0, 1.0)
    root.set_meta("medical_v3_inspection", false)
    if int(root.get_meta("visual_damage", 0)) < 3:
        var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
        var bed: Node3D = core.get_node("V2_CamillaClinica") as Node3D
        _pose_bed(bed, t)
        var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
        for side in [-1, 1]:
            var pivot: Node3D = tent.get_node_or_null("V2_CubiertaArticulada_%d" % side) as Node3D
            if pivot != null:
                # Open upward/outward, preserving clearance above the bed.
                pivot.rotation_degrees.z = float(side) * lerpf(72.0, 23.0, t)
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
