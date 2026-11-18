extends RefCounted
class_name TarvokaG13MaterialFinishV47

# G13 V47: physically differentiated materials ON THE REAL GODOT 3D MESHES.
# No new geometry/draw nodes, no textures, no fake screenshot, no recoloring
# of other units. The already detailed cab, turret, plates and optics
# receive independent PBR material instances for stronger visual hierarchy.
# The complete pre-V47 material set remains available for live comparison.
const FLAG := "tarvoka_g13_v47_individual_pbr_materials"
const PREVIOUS := "tarvoka_g13_v46_machined_wheels"
const META_MATERIALS := "tarvoka_g13_v47_original_and_finished_pbr"
const DRAW_NODES := 0

static func _entries(high_detail: bool) -> Array[Dictionary]:
    var entries: Array[Dictionary] = [
        {"name":"G13_V44_FacetedSideArmor","kind":"steel"},
        {"name":"G13_V44_SculptedFactionFlanks","kind":"paint"},
        {"name":"G13_V44_CurvedFactionFenderBands","kind":"paint"},
        {"name":"G13_V44_RotatingTurretJointArmor","kind":"bearing"},
        {"name":"G13_V44_FactionTurretGuards","kind":"paint"},
        {"name":"G13_V44_SculptedEngineDeckVents","kind":"dark"},
        {"name":"G13_V45_LowerFacetedServiceHatches","kind":"steel"},
        {"name":"G13_V45_ClosedArmoredWindshieldBrow","kind":"roof"},
        {"name":"G13_V45_TwinReceiverCoolingFins","kind":"dark"},
        {"name":"G13_V45_FactionRoofRecognitionBars","kind":"paint"},
        {"name":"G13_V46_MachinedArmoredHubCaps","kind":"alloy"},
        {"name":"G13_V46_FactionHubRings","kind":"paint"},
        {"name":"G13_FrontGlass_-1","kind":"optic"},
        {"name":"G13_FrontGlass_1","kind":"optic"}
    ]
    if high_detail:
        entries.append_array([
            {"name":"G13_V10_ChamferedCabShell","kind":"cab"},
            {"name":"G13_V10_ChamferedTurretShell","kind":"turret"},
            {"name":"G13_V11_ArmoredRoof","kind":"roof"},
            {"name":"G13_V11_SideWindow_-1","kind":"optic"},
            {"name":"G13_V11_SideWindow_1","kind":"optic"},
            {"name":"G13_V15_FixedTurretPedestal","kind":"bearing"},
            {"name":"G13_V15_RotatingTurretSeal","kind":"bearing"}
        ])
    else:
        # LOD8 has no V10/V11 hero shells. Its real cab/turret meshes
        # remain visible; polish those resources instead of a phantom node.
        entries.append_array([
            {"name":"G13_SealedCab","kind":"cab"},
            {"name":"G13_RemoteWeaponHousing","kind":"turret"},
            {"name":"G13_CabRoof","kind":"roof"},
            {"name":"G13_RotationRing","kind":"bearing"}
        ])
    return entries

static func _finish(original: StandardMaterial3D,
        kind: String) -> StandardMaterial3D:
    # Preserve original faction identity, transparency mode, emission,
    # normals, culling and other artist parameters by duplicating each
    # actual original material. Only controlled PBR values are tuned.
    var updated := original.duplicate(true) as StandardMaterial3D
    match kind:
        "cab":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#7d898e"), 0.28)
            updated.metallic = 0.49
            updated.roughness = 0.56
        "turret":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#687a82"), 0.31)
            updated.metallic = 0.54
            updated.roughness = 0.51
        "steel":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#61727a"), 0.25)
            updated.metallic = 0.51
            updated.roughness = 0.57
        "roof":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#87999f"), 0.24)
            updated.metallic = 0.43
            updated.roughness = 0.60
        "bearing":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#414e54"), 0.34)
            updated.metallic = 0.52
            updated.roughness = 0.66
        "dark":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#303c42"), 0.30)
            updated.metallic = 0.37
            updated.roughness = 0.67
        "alloy":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#a9b2b2"), 0.20)
            updated.metallic = 0.69
            updated.roughness = 0.43
        "optic":
            updated.albedo_color = original.albedo_color.lerp(
                Color("#1b4358"), 0.18)
            updated.metallic = 0.11
            updated.roughness = 0.18
        "paint":
            # Existing nodes already inherit the eight real faction
            # palettes. Do not replace them with a hardcoded blue.
            updated.albedo_color = original.albedo_color.lightened(0.028)
            updated.metallic = 0.36
            updated.roughness = 0.49
        _:
            return null
    return updated

static func _nodes(root: Node3D) -> Dictionary:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return {}
    var out: Dictionary = {}
    var high: bool = bool(root.get_meta(
        "tarvoka_g13_v1_high_detail", true))
    for entry in _entries(high):
        var name: String = str(entry["name"])
        var item := root.find_child(
            name, true, false) as GeometryInstance3D
        if item == null or not item.material_override is StandardMaterial3D:
            return {}
        out[name] = item
    return out

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var parts := _nodes(root)
    var high: bool = bool(root.get_meta(
        "tarvoka_g13_v1_high_detail", true))
    var entries := _entries(high)
    if parts.size() != entries.size():
        return false

    # Validate all nodes/materials and generate all duplicates BEFORE
    # changing the scene, so there are no half-repainted G13 previews.
    var before: Dictionary = {}
    var after: Dictionary = {}
    for entry in entries:
        var name: String = str(entry["name"])
        var old := (parts[name] as GeometryInstance3D).material_override as StandardMaterial3D
        if old == null:
            return false
        var coat := _finish(old, str(entry["kind"]))
        if coat == null:
            return false
        before[name] = old
        after[name] = coat

    for name in after.keys():
        (parts[name] as GeometryInstance3D).material_override = after[name]
    root.set_meta(META_MATERIALS,
        {"original":before,"finished":after})
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v47_art_materials", entries.size())
    root.set_meta("tarvoka_g13_v47_pbr_only", true)
    root.set_meta("tarvoka_g13_v47_new_draw_nodes", DRAW_NODES)
    root.set_meta("tarvoka_g13_v47_faction_policy",
        "preserve_palette_lighten_existing_paint_2_8_percent")
    root.set_meta("tarvoka_g13_v47_armament", "dual_autocannon_no_missiles")
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var saved: Dictionary = root.get_meta(META_MATERIALS, {})
    if not saved.has("original") or not saved.has("finished"):
        return false
    var parts := _nodes(root)
    if parts.is_empty():
        return false
    var originals: Dictionary = saved["original"]
    var polished: Dictionary = saved["finished"]
    for name in parts.keys():
        if not originals.has(name) or not polished.has(name):
            return false
    for name in parts.keys():
        (parts[name] as GeometryInstance3D).material_override = (
            polished[name] if enabled else originals[name])
    root.set_meta("tarvoka_g13_v47_preview_enabled", enabled)
    return true
