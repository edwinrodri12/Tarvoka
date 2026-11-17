extends RefCounted
class_name TarvokaG13FactionMountFinishV32

# G13 V32 — restrained additional faction enamel and articulated gun hardware.
# Original two-cannon vehicle only; no missiles, gameplay, shaders or new rigs.
# Applies to the LOD13 hero and the LOD8 tactical model (mechanics on LOD8).
# Small colored plates are physically placed over existing armor, not painted
# across windshields, optics, muzzle faces or radar reflector.
const FLAG := "tarvoka_g13_v32_faction_mount_finish"
const DRAW_BODY := "G13_V32_FactionBodyAccents"
const DRAW_TURRET := "G13_V32_FactionTurretAccents"
const DRAW_FIXED := "G13_V32_StationaryLockBolts"
const DRAW_PITCH := "G13_V32_MovingGuardBolts"
const OLD_CHEEK := "tarvoka_g13_v32_original_cheek_mat"
const NEW_CHEEK := "tarvoka_g13_v32_colored_cheek_mat"
const V31_FLAG := "tarvoka_g13_v31_articulated_gun_guards"
const V24_FLAG := "tarvoka_g13_v24_front_armored_intake"

static func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m

static func _plate(pos: Vector3, dimensions: Vector3) -> Transform3D:
    # The shared unit cube makes all faction panels one draw node per parent.
    return Transform3D(Basis.IDENTITY.scaled(dimensions), pos)

static func _batch(parent: Node3D, name: String, shape: Mesh,
        material: Material, poses: Array[Transform3D]) -> MultiMeshInstance3D:
    var data := MultiMesh.new()
    data.transform_format = MultiMesh.TRANSFORM_3D
    data.mesh = shape
    data.instance_count = poses.size()
    for i in range(poses.size()):
        data.set_instance_transform(i, poses[i])
    var view := MultiMeshInstance3D.new()
    view.name = name
    view.multimesh = data
    view.material_override = material
    parent.add_child(view)
    return view

static func _faction_body(hi: bool) -> Array[Transform3D]:
    var plates: Array[Transform3D] = []
    var x: float = 0.726 if hi else 0.685
    for side in [-1, 1]:
        var s: float = float(side)
        # Two small rectangular panels per flank, on existing side armor.
        plates.append(_plate(Vector3(s * x, 0.868, -0.190),
            Vector3(0.020, 0.083, 0.235)))
        plates.append(_plate(Vector3(s * x, 0.868, 0.220),
            Vector3(0.020, 0.083, 0.235)))
        # The hero model has a true service hatch on the rear. Do not put
        # rear badge patches on tactical LOD8: that model lacks the hatch.
        if hi:
            plates.append(_plate(Vector3(s * 0.306, 0.965, 1.309),
                Vector3(0.190, 0.060, 0.016)))
    return plates

static func _faction_turret() -> Array[Transform3D]:
    var plates: Array[Transform3D] = []
    for side in [-1, 1]:
        var s: float = float(side)
        # Roof shoulders sit OUTSIDE existing central V2 faction roof enamel.
        plates.append(_plate(Vector3(s * 0.336, 0.424, 0.145),
            Vector3(0.143, 0.020, 0.220)))
        # Short rear-edge identification tabs, not full armor repaint.
        plates.append(_plate(Vector3(s * 0.480, 0.343, 0.223),
            Vector3(0.021, 0.055, 0.145)))
    return plates

static func _bolt_mesh() -> CylinderMesh:
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.022
    cylinder.bottom_radius = 0.023
    cylinder.height = 0.015
    cylinder.radial_segments = 8
    return cylinder

static func _mechanical_bolts() -> Dictionary:
    # Both bolt groups follow their ORIGINAL rotation parent.
    var fixed: Array[Transform3D] = []
    var moving: Array[Transform3D] = []
    var axis: Basis = Basis(Vector3.FORWARD, PI * 0.5)
    for side in [-1, 1]:
        var s: float = float(side)
        fixed.append(Transform3D(axis, Vector3(s * 0.553, 0.337, -0.253)))
        fixed.append(Transform3D(axis, Vector3(s * 0.553, 0.232, -0.151)))
        moving.append(Transform3D(axis, Vector3(s * 0.533, 0.065, -0.303)))
        moving.append(Transform3D(axis, Vector3(s * 0.533, -0.039, -0.418)))
        moving.append(Transform3D(axis, Vector3(s * 0.533, 0.058, -0.490)))
    return {"fixed": fixed, "moving": moving}

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(
            "tarvoka_g13_mobile_aa_visual_v1", false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hi: bool = bool(root.get_meta("tarvoka_g13_v1_high_detail", true))
    if hi and not bool(root.get_meta(V24_FLAG, false)):
        return false
    if not hi and not bool(root.get_meta(V31_FLAG, false)):
        return false
    var body := root.find_child("G13_Casco4x4", true, false) as Node3D
    var turret := root.find_child("G13_TorretaAzimut", true, false) as Node3D
    var pitch := root.find_child("G13_ElevacionCanones", true, false) as Node3D
    var faction_stripe := root.find_child(
        "G13_TurretFaction_1", true, false) as MeshInstance3D
    if body == null or turret == null or pitch == null or (
            turret.get_parent() != body) or (
            pitch.get_parent() != turret) or faction_stripe == null or (
            not faction_stripe.material_override is StandardMaterial3D):
        return false
    var cheek: MeshInstance3D = null
    if not hi:
        cheek = pitch.find_child(
            "G13_V31_PitchArmoredCheeks", false, false) as MeshInstance3D
        if cheek == null or not cheek.material_override is StandardMaterial3D:
            return false

    var paint: Color = (
        faction_stripe.material_override as StandardMaterial3D).albedo_color
    # Use the OFFICIAL faction tint; only the new small panels get more color.
    var accent := _material(paint, 0.25, 0.64)
    var plate_geometry := BoxMesh.new()
    plate_geometry.size = Vector3.ONE
    var body_places := _faction_body(hi)
    var turret_places := _faction_turret()
    if body_places.size() != (6 if hi else 4) or turret_places.size() != 4:
        return false

    # Create color additions only after validating both rig parents and
    # native paint; avoid touching original faction strips or roof badges.
    _batch(body, DRAW_BODY, plate_geometry, accent, body_places)
    _batch(turret, DRAW_TURRET, plate_geometry, accent, turret_places)

    if not hi:
        # Finish existing V31 receiver cheeks: visible faction hue is modestly
        # stronger (0.47 vs 0.34), while the majority stays dark metal.
        var original_mat: Material = cheek.material_override
        var cheek_color := Color("#617378").lerp(paint, 0.47)
        var new_mat := _material(cheek_color, 0.36, 0.67)
        root.set_meta(OLD_CHEEK, original_mat)
        root.set_meta(NEW_CHEEK, new_mat)
        cheek.material_override = new_mat

        var bolts := _mechanical_bolts()
        var fastener_coat := _material(Color("#a1aaa6"), 0.58, 0.49)
        var fastener_shape := _bolt_mesh()
        _batch(turret, DRAW_FIXED, fastener_shape, fastener_coat, bolts["fixed"])
        _batch(pitch, DRAW_PITCH, fastener_shape, fastener_coat, bolts["moving"])

    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v32_visual_only", true)
    root.set_meta("tarvoka_g13_v32_faction_color", paint.to_html())
    root.set_meta("tarvoka_g13_v32_color_accent_count",
        body_places.size() + turret_places.size())
    root.set_meta("tarvoka_g13_v32_mechanical_bolts", 0 if hi else 10)
    root.set_meta("tarvoka_g13_v32_new_draw_nodes", 2 if hi else 4)
    root.set_meta("tarvoka_g13_v32_weapons", "twin_autocannons_only")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    # Same live Studio 3D object, camera and faction. This is an inspection
    # toggle, not a second model or a conversion of existing animations.
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var hi: bool = bool(root.get_meta("tarvoka_g13_v1_high_detail", true))
    var labels := [DRAW_BODY, DRAW_TURRET]
    if not hi:
        labels.append(DRAW_FIXED)
        labels.append(DRAW_PITCH)
    var nodes: Array[VisualInstance3D] = []
    for label in labels:
        var item := root.find_child(label, true, false) as VisualInstance3D
        if item == null:
            return false
        nodes.append(item)
    var cheek: MeshInstance3D = null
    if not hi:
        cheek = root.find_child(
            "G13_V31_PitchArmoredCheeks", true, false) as MeshInstance3D
        if cheek == null or root.get_meta(OLD_CHEEK, null) == null or (
                root.get_meta(NEW_CHEEK, null) == null):
            return false
    for node in nodes:
        node.visible = enabled
    if cheek != null:
        cheek.material_override = root.get_meta(
            NEW_CHEEK if enabled else OLD_CHEEK)
    root.set_meta("tarvoka_g13_v32_preview_enabled", enabled)
    return true
