extends RefCounted
class_name TarvokaG13BodyClosureV34

# G13 V34: real native 3D body seams, maintenance latches and bumpers.
# Both hero LOD13 and tactical LOD8 share the same original 4x4 chassis.
# ART ONLY: original twin autocannons, hinged radar and eight faction
# colors are unchanged. No lights, weapons, collider or gameplay metadata.
const FLAG := "tarvoka_g13_v34_body_closure_and_bumper_finish"
const PREVIOUS := "tarvoka_g13_v33_arch_hinge_transition"
const SEAMS := "G13_V34_ArmoredPanelSeams"
const LATCHES := "G13_V34_ServiceDoorLatches"
const BUMPERS := "G13_V34_ReinforcedBumpers"
const REAR_GUARDS := "G13_V34_RearCornerProtectors"
const DRAW_NODES := 4

static func _coat(color: Color, metal: float, rough: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough
    return mat

static func _box(at: Vector3, size: Vector3) -> Transform3D:
    # Unit cube transforms mean a complete finish shares one draw mesh
    # per material, regardless of the number of symmetric metal pieces.
    return Transform3D(Basis.IDENTITY.scaled(size), at)

static func _instance(parent: Node3D, label: String, mat: Material,
        positions: Array[Transform3D]) -> MultiMeshInstance3D:
    var box := BoxMesh.new()
    box.size = Vector3.ONE
    var multi := MultiMesh.new()
    multi.transform_format = MultiMesh.TRANSFORM_3D
    multi.mesh = box
    multi.instance_count = positions.size()
    for i in range(positions.size()):
        multi.set_instance_transform(i, positions[i])
    var out := MultiMeshInstance3D.new()
    out.name = label
    out.multimesh = multi
    out.material_override = mat
    parent.add_child(out)
    return out

static func _panel_seams(high_detail: bool) -> Array[Transform3D]:
    var pieces: Array[Transform3D] = []
    for side in [-1, 1]:
        var s: float = float(side)
        # Three slender cabin perimeter seals per side, deliberately outside
        # the V11 glass area and away from V32 faction enamel lower down.
        pieces.append(_box(Vector3(s * 0.611, 1.025, -0.488),
            Vector3(0.014, 0.214, 0.017)))
        pieces.append(_box(Vector3(s * 0.611, 1.025, -1.053),
            Vector3(0.014, 0.214, 0.017)))
        pieces.append(_box(Vector3(s * 0.609, 0.858, -0.770),
            Vector3(0.014, 0.016, 0.550)))
    if high_detail:
        # LOD13 has the real rear service door. All four strips hug its
        # existing .87m x .44m perimeter without hiding V32 rear badges.
        for side in [-1, 1]:
            pieces.append(_box(Vector3(float(side) * 0.444, 0.945, 1.306),
                Vector3(0.015, 0.408, 0.015)))
        for y in [0.714, 1.167]:
            pieces.append(_box(Vector3(0.0, y, 1.306),
                Vector3(0.887, 0.014, 0.015)))
    else:
        # LOD8: trace the fixed engine hatch on TOP of the rear deck.
        # Avoid the radar shoe at z=1.135 and its V30 guide rails.
        for side in [-1, 1]:
            pieces.append(_box(Vector3(float(side) * 0.548, 1.126, 0.700),
                Vector3(0.015, 0.012, 0.540)))
        for z in [0.430, 0.970]:
            pieces.append(_box(Vector3(0.0, 1.126, z),
                Vector3(1.098, 0.012, 0.015)))
    return pieces

static func _handles(high_detail: bool) -> Array[Transform3D]:
    var parts: Array[Transform3D] = []
    for side in [-1, 1]:
        var s: float = float(side)
        if high_detail:
            # Two low-profile pulls on the rear hatch, not across faction tags.
            parts.append(_box(Vector3(s * 0.238, 0.845, 1.322),
                Vector3(0.105, 0.031, 0.037)))
            parts.append(_box(Vector3(s * 0.238, 0.807, 1.315),
                Vector3(0.024, 0.059, 0.022)))
        else:
            # Equivalent transverse handle and pivot on the top deck hatch.
            parts.append(_box(Vector3(s * 0.236, 1.143, 0.719),
                Vector3(0.099, 0.032, 0.027)))
            parts.append(_box(Vector3(s * 0.236, 1.134, 0.743),
                Vector3(0.024, 0.033, 0.039)))
    return parts

static func _bumper_hardware() -> Array[Transform3D]:
    var parts: Array[Transform3D] = []
    # Narrow front-facing protective lip is BELOW the existing headlights,
    # V23 recessed optic faces and V24 armoured grille.
    parts.append(_box(Vector3(0.0, 0.520, -1.312),
        Vector3(1.140, 0.058, 0.071)))
    for side in [-1, 1]:
        var s: float = float(side)
        parts.append(_box(Vector3(s * 0.587, 0.505, -1.340),
            Vector3(0.116, 0.140, 0.136)))
    # Rear horizontal protector sits beyond the original 2.42-m chassis;
    # corner tabs tie it to the rear underbody, leaving the hatch unobscured.
    parts.append(_box(Vector3(0.0, 0.501, 1.333),
        Vector3(1.145, 0.126, 0.123)))
    for side in [-1, 1]:
        var s: float = float(side)
        parts.append(_box(Vector3(s * 0.538, 0.500, 1.341),
            Vector3(0.141, 0.167, 0.143)))
    return parts

static func _rear_guard_hardware() -> Array[Transform3D]:
    var parts: Array[Transform3D] = []
    for side in [-1, 1]:
        var s: float = float(side)
        # Vertical anti-scuff edges end below the rear-door faction patches.
        parts.append(_box(Vector3(s * 0.606, 0.623, 1.332),
            Vector3(0.072, 0.282, 0.080)))
    return parts

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var hull := root.find_child("G13_Casco4x4", true, false) as Node3D
    var cab := root.find_child("G13_SealedCab", true, false) as MeshInstance3D
    var front := root.find_child("G13_FrontBumper", true, false) as MeshInstance3D
    var engine := root.find_child("G13_EngineCover", true, false) as MeshInstance3D
    var high_detail: bool = bool(root.get_meta(
        "tarvoka_g13_v1_high_detail", true))
    if hull == null or cab == null or front == null or engine == null:
        return false
    if cab.get_parent() != hull or front.get_parent() != hull or (
            engine.get_parent() != hull):
        return false
    if not front.position.is_equal_approx(Vector3(0, 0.51, -1.21)) or (
            not front.mesh is BoxMesh):
        return false
    if high_detail and root.find_child(
            "G13_RearServiceDoor", true, false) == null:
        return false

    var seams := _panel_seams(high_detail)
    var latches := _handles(high_detail)
    var bumpers := _bumper_hardware()
    var guards := _rear_guard_hardware()
    if seams.size() != 10 or latches.size() != 4 or (
            bumpers.size() != 6 or guards.size() != 2):
        return false

    var gasket := _coat(Color("#2b383c"), 0.15, 0.86)
    var hardware := _coat(Color("#9ba8a9"), 0.56, 0.53)
    var steel := _coat(Color("#66777d"), 0.43, 0.68)
    var graphite := _coat(Color("#354248"), 0.36, 0.78)
    _instance(hull, SEAMS, gasket, seams)
    _instance(hull, LATCHES, hardware, latches)
    _instance(hull, BUMPERS, steel, bumpers)
    _instance(hull, REAR_GUARDS, graphite, guards)
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v34_visual_only", true)
    root.set_meta("tarvoka_g13_v34_seal_count", seams.size())
    root.set_meta("tarvoka_g13_v34_latch_pieces", latches.size())
    root.set_meta("tarvoka_g13_v34_bumper_pieces", bumpers.size())
    root.set_meta("tarvoka_g13_v34_rear_guards", guards.size())
    root.set_meta("tarvoka_g13_v34_extra_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v34_weapons", "two_autocannons_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    # V33 vs V34 in the original active 3D scene: no model reconstruction,
    # animation changes, colour override or new gameplay unit.
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var names := [SEAMS, LATCHES, BUMPERS, REAR_GUARDS]
    var nodes: Array[VisualInstance3D] = []
    for name in names:
        var node := root.find_child(name, true, false) as VisualInstance3D
        if node == null:
            return false
        nodes.append(node)
    for node in nodes:
        node.visible = enabled
    root.set_meta("tarvoka_g13_v34_preview_enabled", enabled)
    return true
