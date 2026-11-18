extends RefCounted
class_name TarvokaG13MaterialRealismV53

# G13 V53: final PBR material separation for the REAL 3D model.
# Existing geometry, wheel spin, faction paint, twin guns, radar and gameplay
# are untouched. Materials are copied, never modified globally for other units.
const FLAG := "tarvoka_g13_v53_metal_rubber_material_finish"
const PREVIOUS := "tarvoka_g13_v52_integrated_roof_shoulder_rails"
const SAVED := "tarvoka_g13_v53_material_before_after"
const ESSENTIAL := [
    "G13_Ruedas4x4MultiMesh",
    "G13_V7_Sidewalls",
    "G13_V7_TreadBlocks",
    "G13_V46_MachinedArmoredHubCaps",
    "G13_V46_FactionHubRings"
]
# Paint is never re-tinted to an arbitrary faction color.
const FINISHES := {
    "G13_LowerMonocoque":"armor",
    "G13_SlopedGlacis":"armor",
    "G13_EngineCover":"armor",
    "G13_V44_FacetedSideArmor":"armor",
    "G13_V45_LowerFacetedServiceHatches":"armor",
    "G13_V10_ChamferedCabShell":"armor",
    "G13_SealedCab":"armor",
    "G13_V10_ChamferedTurretShell":"armor",
    "G13_RemoteWeaponHousing":"armor",
    "G13_V11_ArmoredRoof":"roof",
    "G13_CabRoof":"roof",
    "G13_V37_SculptedRoofShoulders":"roof",
    "G13_V45_ClosedArmoredWindshieldBrow":"roof",
    "G13_RotationRing":"mechanical",
    "G13_V44_RotatingTurretJointArmor":"mechanical",
    "G13_V45_TwinReceiverCoolingFins":"mechanical",
    "G13_V44_SculptedEngineDeckVents":"mechanical",
    "G13_V15_RotatingTurretSeal":"mechanical",
    "G13_V15_FixedTurretPedestal":"mechanical",
    "G13_Autocannon_-1":"machined",
    "G13_Autocannon_1":"machined",
    "G13_V7_OuterRims":"machined",
    "G13_V46_MachinedArmoredHubCaps":"machined",
    "G13_V46_RotatingHubBolts":"machined",
    "G13_V46_FactionHubRings":"paint",
    "G13_V44_SculptedFactionFlanks":"paint",
    "G13_V44_CurvedFactionFenderBands":"paint",
    "G13_V44_FactionTurretGuards":"paint",
    "G13_V45_FactionRoofRecognitionBars":"paint",
    "G13_SideEnamel_-1":"paint",
    "G13_SideEnamel_1":"paint",
    "G13_TurretFaction_-1":"paint",
    "G13_TurretFaction_1":"paint",
    "G13_FrontGlass_-1":"glass",
    "G13_FrontGlass_1":"glass",
    "G13_V11_SideWindow_-1":"glass",
    "G13_V11_SideWindow_1":"glass",
    "G13_Ruedas4x4MultiMesh":"rubber",
    "G13_V7_Sidewalls":"sidewall",
    "G13_V7_TreadBlocks":"tread",
    "G13_V46_RadialSidewallRelief":"sidewall"
}

static func _original_material(item: GeometryInstance3D) -> StandardMaterial3D:
    if item.material_override is StandardMaterial3D:
        return item.material_override as StandardMaterial3D
    var mesh: Mesh = null
    if item is MeshInstance3D:
        mesh = (item as MeshInstance3D).mesh
    elif item is MultiMeshInstance3D:
        var batch := (item as MultiMeshInstance3D).multimesh
        if batch != null:
            mesh = batch.mesh
    if mesh != null and mesh.get_surface_count() > 0:
        return mesh.surface_get_material(0) as StandardMaterial3D
    return null

# Deterministic, small 32x32 tangent-space microtexture; its RGB is
# tangent-space normal data, NOT a glossy gray color pasted onto tire rubber.
static func _rubber_normal() -> Texture2D:
    var picture := Image.create(32, 32, false, Image.FORMAT_RGBA8)
    for y in range(32):
        for x in range(32):
            var a: float = sin(float(x)*2.37 + float(y)*1.73)
            var b: float = cos(float(y)*2.11 - float(x)*1.59)
            picture.set_pixel(x, y, Color(
                0.5 + a*0.025, 0.5 + b*0.025, 0.998, 1.0))
    return ImageTexture.create_from_image(picture)

static func _coating(original: StandardMaterial3D, kind: String,
        rubber_bump: Texture2D) -> StandardMaterial3D:
    var coat := original.duplicate(true) as StandardMaterial3D
    match kind:
        "armor":
            coat.metallic = 0.54
            coat.roughness = 0.48
        "roof":
            coat.metallic = 0.43
            coat.roughness = 0.55
        "mechanical":
            coat.metallic = 0.66
            coat.roughness = 0.39
        "machined":
            coat.metallic = 0.82
            coat.roughness = 0.29
        "paint":
            coat.metallic = 0.28
            coat.roughness = 0.45
            coat.clearcoat_enabled = true
            coat.clearcoat = 0.34
            coat.clearcoat_roughness = 0.32
        "glass":
            coat.metallic = 0.10
            coat.roughness = 0.13
            coat.clearcoat_enabled = true
            coat.clearcoat = 0.50
            coat.clearcoat_roughness = 0.16
        "rubber","sidewall","tread":
            # Natural near-black vulcanized rubber, not painted black metal.
            coat.albedo_color = (
                Color("#202226") if kind == "rubber" else (
                Color("#26292c") if kind == "sidewall" else
                Color("#292b2d")))
            coat.metallic = 0.0
            coat.roughness = (0.94 if kind == "sidewall" else (
                0.89 if kind == "tread" else 0.91))
            coat.clearcoat_enabled = false
            coat.normal_enabled = true
            coat.normal_texture = rubber_bump
            coat.normal_scale = 0.22
        _:
            return null
    return coat

static func apply(root: Node3D) -> bool:
    if root == null or not bool(root.get_meta(PREVIOUS, false)):
        return false
    if bool(root.get_meta(FLAG, false)):
        return true
    var nodes: Dictionary = {}
    var originals: Dictionary = {}
    var polished: Dictionary = {}
    var bump := _rubber_normal()
    for name in FINISHES.keys():
        var found := root.find_child(str(name), true, false) as GeometryInstance3D
        if found == null:
            if name in ESSENTIAL:
                return false
            continue
        var source := _original_material(found)
        if source == null:
            if name in ESSENTIAL:
                return false
            continue
        var coat := _coating(source, str(FINISHES[name]), bump)
        if coat == null:
            return false
        nodes[name] = found
        originals[name] = found.material_override
        polished[name] = coat
    for name in ESSENTIAL:
        if not nodes.has(name):
            return false
    # Atomic assignment after validation: never leave half-polished wheels.
    for name in nodes.keys():
        (nodes[name] as GeometryInstance3D).material_override = polished[name]
    root.set_meta(SAVED, {"original":originals,"finished":polished})
    root.set_meta(FLAG, true)
    root.set_meta("tarvoka_g13_v53_pbr_part_count", nodes.size())
    root.set_meta("tarvoka_g13_v53_rubber_is_nonmetallic", true)
    root.set_meta("tarvoka_g13_v53_unique_micro_normal_pixels", 1024)
    root.set_meta("tarvoka_g13_v53_no_new_draw_nodes", true)
    root.set_meta("tarvoka_g13_v53_faction_colors_unchanged", true)
    return true

static func show_finish(root: Node3D, enabled: bool) -> bool:
    if root == null or not bool(root.get_meta(FLAG, false)):
        return false
    var saved: Dictionary = root.get_meta(SAVED, {})
    if not saved.has("original") or not saved.has("finished"):
        return false
    var source: Dictionary = saved["original"]
    var polished: Dictionary = saved["finished"]
    for name in polished.keys():
        if root.find_child(str(name), true, false) == null or (
                not source.has(name)):
            return false
    for name in polished.keys():
        var item := root.find_child(
            str(name), true, false) as GeometryInstance3D
        item.material_override = polished[name] if enabled else source[name]
    root.set_meta("tarvoka_g13_v53_preview_enabled", enabled)
    return true
