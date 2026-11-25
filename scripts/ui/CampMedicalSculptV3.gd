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
    root.set_meta("medical_art_revision", "3.0")
    _replace(root, "PlataformaDesmontable", 0.045, FLOOR, 0.06)
    if damage == 3:
        _wreck(root, accent, lod)
        return true
    var core: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE) as Node3D
    var tent: Node3D = core.get_node("V2_CarpaDesmontable") as Node3D
    _tent(tent, accent, lod, damage)
    _floor(core, accent, lod)
    return pose(root, 1.0)

static func pose(root: Node3D, progress: float) -> bool:
    if root == null or root.get_meta("medical_art_v3", 0) != 3:
        return true
    var t: float = clampf(progress, 0.0, 1.0)
    root.set_meta("medical_v3_inspection", false)
    if int(root.get_meta("visual_damage", 0)) < 3:
        var tent: Node3D = root.get_node("EquipamientoDesplegable/" + Base.CORE + "/V2_CarpaDesmontable") as Node3D
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
