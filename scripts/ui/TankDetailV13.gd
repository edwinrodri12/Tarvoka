extends RefCounted
class_name TarvokaTankDetailV13

# Optional V13 geometry on the *live* G09 V12 rig. Replaces two continuous
# side guards with five separate chamfered armor cells per side. Also closes
# the rear silhouette with an actual tapered ammunition housing. This is
# military-industrial design for TARVOKA, not a replica of a real tank.
# V10 remains the production Android default until visual approval.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const V10 = preload("res://scripts/ui/TankArmorV10.gd")
const ROOT := "G09V13EsculturaModular"
const STEEL := Color("#475B65")
const CERAMIC := Color("#667985")
const DARK := Color("#22343C")
const RECESS := Color("#172830")

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_refined_v12",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)

    # Separation is geometry, not a drawn texture: the small shadow gaps
    # produce real changes of silhouette at Android map viewing distance.
    # Lower 14 faction enamel panels remain untouched and visible.
    for side in [-1,1]:
        var previous: Node3D = model.find_child(
            "G09V12DefensaOrugaAngular_%s" % side,true,false) as Node3D
        if previous != null:
            previous.visible = false
        var sign: float = float(side)
        for segment in range(5):
            var front: float = -1.45+float(segment)*0.56
            var back: float = front+0.52
            var flare: float = 0.035 if segment == 0 else (
                0.012 if segment == 1 else -0.012*float(segment-1))
            var outline := [
                Vector2(sign*1.035,front),
                Vector2(sign*(1.190+flare),front-0.024),
                Vector2(sign*(1.308+flare),front+0.068),
                Vector2(sign*(1.302+flare),back-0.072),
                Vector2(sign*(1.190+flare),back+0.013),
                Vector2(sign*1.040,back)
            ]
            if side < 0:
                outline.reverse()
            Hero._loft(hull,
                "G09V13FaldonSegmentado_%s_%02d" % [side,segment],
                outline,[[0.772,0.934,0.0],[0.861,1.006,0.0],
                    [0.996,0.920,0.021]],
                CERAMIC if segment == 0 or segment == 4 else STEEL)
            # Upper steel gasket follows the unique edge of each panel.
            Hero._rod(hull,"G09V13RibeteFaldon_%s_%02d" % [side,segment],
                Vector3(sign*1.195,0.990,front+0.075),
                Vector3(sign*1.196,0.990,back-0.079),
                0.013,DARK)

    # Rear turret is an actual closed, tapered mesh. It is 25 cm longer
    # than V12 and visually counterbalances the pointed forward wedge.
    var previous_rear: Node3D = model.find_child(
        "G09V12AlmacenBlindadoPosterior",true,false) as Node3D
    if previous_rear != null:
        previous_rear.visible = false
    Hero._loft(turret,"G09V13BastionMunicionesContinuo",[
        Vector2(-0.56,0.865),Vector2(0.56,0.865),
        Vector2(0.87,1.160),Vector2(0.75,1.545),
        Vector2(-0.75,1.545),Vector2(-0.87,1.160)
    ],[[0.210,0.900,0.0],[0.362,1.000,0.0],
        [0.516,0.917,0.0],[0.543,0.872,0.0]],STEEL)
    # Working rear service recess and two structural tie rails. No logos.
    Hero._dark_box(turret,"G09V13RejillaPosterior",
        Vector3(0.0,0.377,1.522),Vector3(0.830,0.077,0.032),RECESS)
    for side in [-1,1]:
        var sign: float = float(side)
        Hero._rod(turret,"G09V13VigaBastion_%s" % side,
            Vector3(sign*0.785,0.482,1.197),
            Vector3(sign*0.674,0.514,1.441),0.018,DARK)
    model.set_meta("tarvoka_mbt_segmented_v13",true)
    return true

static func finish_materials(model: Node3D) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_segmented_v13",false):
        return 0
    var count: int = 0
    for node in model.find_children("G09V13*","MeshInstance3D",true,false):
        var piece: MeshInstance3D = node as MeshInstance3D
        var original: StandardMaterial3D = piece.material_override as StandardMaterial3D
        if original == null:
            continue
        var mat: StandardMaterial3D = original.duplicate(true) as StandardMaterial3D
        var metal_part: bool = "Ribete" in piece.name or "Viga" in piece.name or "Rejilla" in piece.name
        var ceramic: bool = "FaldonSegmentado" in piece.name and (
            piece.name.ends_with("_00") or piece.name.ends_with("_04"))
        mat.albedo_color = (RECESS if "Rejilla" in piece.name else (
            DARK if metal_part else (CERAMIC if ceramic else STEEL)))
        mat.albedo_texture = null if metal_part else V10._enamel_mask(ceramic)
        mat.normal_enabled = not metal_part
        mat.normal_texture = null if metal_part else Hero._army_micro_normal()
        mat.normal_scale = 0.20
        mat.roughness_texture = null if metal_part else Hero._army_micro_roughness()
        mat.roughness = 0.88 if ceramic else (0.80 if metal_part else 0.78)
        mat.metallic = 0.14 if ceramic else 0.23
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        piece.material_override = mat
        count += 1
    model.set_meta("tarvoka_mbt_segmented_v13_pbr_count",count)
    return count
