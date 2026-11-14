extends RefCounted
class_name TarvokaTankFactionV23

# TARVOKA G09 V23: faction recognition at gameplay camera distance.
# Enamel is applied to 11 EXISTING shaped armor meshes: no flat stickers,
# no extra polygon meshes and no new draw calls from additional geometry.
# The original 14 Faccion* paint zones remain independently addressable.
# This is opt-in (art_level=23); Android art_level=10 is untouched.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V23IdentidadBlindaje"
const BASE := Color("#536975")
const PAINTED_ARMOR_COUNT := 11
const SKIRT_SEGMENTS := [1,2,3]

static func _targets() -> Array:
    var targets: Array = []
    for side in [-1,1]:
        # Broad upper skirt modules, but the unpainted front/rear endcaps
        # still provide the visual weight of a realistic metal vehicle.
        for segment in SKIRT_SEGMENTS:
            targets.append([
                "G09V13FaldonSegmentado_%s_%02d" % [side,segment],
                0.87 if segment == 2 else 0.76
            ])
        # Major cast-armor cheek visible in diagonal / side game cameras.
        targets.append(["G09V14CarrilleraEscalonada_%s" % side,0.73])
        # Identifiable head-on, but toned down against the neutral glacis.
        targets.append(["G09V14AlaBlindadaFrontal_%s" % side,0.51])
    # One uninterrupted bustle at the rear remains a credible armored slab;
    # a muted coat gives clear rear recognition without bright bus-like strips.
    targets.append(["G09V13BastionMunicionesContinuo",0.55])
    return targets

static func _enamel(tint: Color,weight: float) -> StandardMaterial3D:
    var base: Color = BASE.lerp(tint,weight)
    var coat: StandardMaterial3D = Hero._army_material(base,true)
    coat.metallic = 0.13
    coat.roughness = 0.84
    coat.normal_scale = 0.20
    coat.emission_enabled = false
    return coat

static func apply(model: Node3D,tint: Color) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_gun_v22",false):
        return false
    if model.get_meta("tarvoka_mbt_faction_v23",false):
        return false
    var targets: Array = _targets()
    if targets.size()!=PAINTED_ARMOR_COUNT:
        return false
    for row in targets:
        var part: MeshInstance3D = model.find_child(
            str(row[0]),true,false) as MeshInstance3D
        if part == null or part.mesh == null:
            return false
    model.set_meta("tarvoka_mbt_faction_v23",true)
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    if recolor(model,tint)!=PAINTED_ARMOR_COUNT:
        model.remove_meta("tarvoka_mbt_faction_v23")
        marker.queue_free()
        return false
    model.set_meta("tarvoka_mbt_faction_v23_recolored",PAINTED_ARMOR_COUNT)
    return true

static func recolor(model: Node3D,tint: Color) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_faction_v23",false):
        return 0
    var targets: Array = _targets()
    var updated: int = 0
    # Always blend from the same NEUTRAL BASE, never from previously tinted
    # armor; repeatedly changing faction therefore cannot accumulate color.
    for row in targets:
        var panel: MeshInstance3D = model.find_child(
            str(row[0]),true,false) as MeshInstance3D
        if panel == null:
            continue
        panel.material_override = _enamel(tint,float(row[1]))
        updated += 1
    return updated
