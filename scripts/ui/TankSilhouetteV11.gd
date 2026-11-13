extends RefCounted
class_name TarvokaTankSilhouetteV11

# G09 V11: REAL structural resculpt, not additional nuts or panels.
# Shapes intentionally alter the silhouette visible at 170-250px.
# Opt-in art_level=11 until the owner approves the V10/V11 browser comparison.
# Only meshes and cosmetic damage parts change; never unit stats/HP/movement.
const V10 = preload("res://scripts/ui/TankArmorV10.gd")
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const ROOT := "G09V11EstructuraMonolitica"
const MAIN := Color("#3E535E")
const ROOF := Color("#40535D")
const FRONT := Color("#728690")
const CERAMIC := Color("#788993")
const CERAMIC_SIDE := Color("#617783")
const SHADOW := Color("#1D3039")
const TINT := Color("#99A7A8")

static func _replace_shell(parent: Node3D, original_name: String,
        outline: Array, rings: Array) -> bool:
    var original: MeshInstance3D = parent.find_child(original_name,true,false) as MeshInstance3D
    if original == null or original.mesh == null:
        return false
    var temporary: MeshInstance3D = Hero._loft(parent,"__V11_MESH_TEMP",
        outline,rings,MAIN)
    original.mesh = temporary.mesh
    temporary.free()
    return true

static func _surface(parent: Node3D, name: String, shape: Array,
        rings: Array, color: Color) -> MeshInstance3D:
    return Hero._loft(parent,name,shape,rings,color)

static func _groove(parent: Node3D, label: String, start: Vector3, end: Vector3,
        thickness: float = 0.012) -> MeshInstance3D:
    return Hero._rod(parent,label,start,end,thickness,SHADOW)

static func _hide(model: Node3D, patterns: Array) -> void:
    for name in patterns:
        var item: Node3D = model.find_child(str(name),true,false) as Node3D
        if item != null:
            item.visible = false

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_sculpted_v10",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    if hull == null or turret == null:
        return false

    # Original G09 V11 "stepped arrow" prow: the physical forward-most hull
    # comes to a distinct narrow iron wedge; shoulders broaden sharply at
    # the track line, then the stern tapers inward. Closed 9-ring surface.
    var hull_outline := [
        Vector2(-0.14,-1.86),Vector2(0.14,-1.86),
        Vector2(0.43,-1.76),Vector2(0.78,-1.48),
        Vector2(0.99,-1.06),Vector2(1.04,-0.62),
        Vector2(1.02,0.71),Vector2(0.92,1.22),
        Vector2(0.70,1.57),Vector2(-0.70,1.57),
        Vector2(-0.92,1.22),Vector2(-1.02,0.71),
        Vector2(-1.04,-0.62),Vector2(-0.99,-1.06),
        Vector2(-0.78,-1.48),Vector2(-0.43,-1.76)
    ]
    var hull_rings := [
        [0.327,0.82,0.004],
        [0.400,0.92,0.012],
        [0.530,1.00,0.050],
        [0.685,1.013,0.120],
        [0.810,0.98,0.198],
        [0.951,0.935,0.283],
        [1.027,0.875,0.304],
        [1.066,0.790,0.327],
        [1.096,0.735,0.332]
    ]
    if not _replace_shell(hull,"CorazaSoldadaHermeticaV7",hull_outline,hull_rings):
        return false

    # Low rhomboid command turret, dramatically different from V10's
    # rounded rectangle. Forward prow sticks out between opposing heavy
    # triangular cheek wedges; rear skirt has a wider ammunition bustle.
    var turret_outline := [
        Vector2(-0.17,-1.60),Vector2(0.17,-1.60),
        Vector2(0.47,-1.49),Vector2(0.84,-1.17),
        Vector2(1.07,-0.56),Vector2(1.09,-0.13),
        Vector2(1.02,0.70),Vector2(0.88,1.10),
        Vector2(0.79,1.33),Vector2(-0.79,1.33),
        Vector2(-0.88,1.10),Vector2(-1.02,0.70),
        Vector2(-1.09,-0.13),Vector2(-1.07,-0.56),
        Vector2(-0.84,-1.17),Vector2(-0.47,-1.49)
    ]
    var turret_rings := [
        [0.066,0.82,0.005],
        [0.112,0.91,0.016],
        [0.195,1.00,0.025],
        [0.314,1.035,0.047],
        [0.408,1.018,0.062],
        [0.501,0.910,0.074],
        [0.579,0.785,0.087],
        [0.637,0.695,0.100],
        [0.648,0.645,0.105]
    ]
    if not _replace_shell(turret,"TorreBajaSoldadaV7",
            turret_outline,turret_rings):
        return false

    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)
    # Remove preceding cheek shells and front plate decorations. Otherwise
    # the new sharp geometry would still read like the V10 toy rectangle.
    _hide(model,[
        "G09V10MejillaCompuesta_-1","G09V10MejillaCompuesta_1",
        "G09V10PlanchaMejillaExterior_-1","G09V10PlanchaMejillaExterior_1",
        "G09V10BlindajeLateral_-1","G09V10BlindajeLateral_1",
        "G09V10TapaEscudoPosterior_-1","G09V10TapaEscudoPosterior_1",
        # Keep the mantlet housing: it closes the central gun aperture.

        "G09V10GlacisSuperior_-1","G09V10GlacisSuperior_1",
        "G09V10GlacisInferior_-1","G09V10GlacisInferior_1",
        "G09V10EscudoProaUnificado"
    ])

    # One continuous bevelled central roof links both armored cheeks to
    # the rear ammunition bustle. V11 iteration 1 had a dark visual cavity
    # that made the turret look hollow; this is real geometry, not a decal.
    var roof_shape := [
        Vector2(-0.49,-1.01),Vector2(0.49,-1.01),
        Vector2(0.68,-0.69),Vector2(0.72,-0.12),
        Vector2(0.70,0.76),Vector2(0.53,1.05),
        Vector2(-0.53,1.05),Vector2(-0.70,0.76),
        Vector2(-0.72,-0.12),Vector2(-0.68,-0.69)
    ]
    _surface(turret,"G09V11TechoEstructuralUnificado",roof_shape,
        [[0.543,0.95,0.019],[0.616,0.992,0.034],
            [0.652,0.884,0.045]],Color("#526872"))
    _groove(turret,"G09V11JuntaCentralTecho",
        Vector3(-0.37,0.665,-0.72),
        Vector3(0.37,0.665,-0.72),0.012)

    # Two continuous wedge cheeks. These are NOT blocks; closed, tapered
    # authored eight-sided 3D surfaces with three-dimensional top contours.
    # The opening between them frames the moving cannon mantlet.
    for side in [-1,1]:
        var sign: float = float(side)
        var cheek_shape := [
            Vector2(sign*0.23,-1.58),
            Vector2(sign*0.51,-1.60),
            Vector2(sign*0.80,-1.37),
            Vector2(sign*1.08,-0.84),
            Vector2(sign*1.11,-0.35),
            Vector2(sign*0.84,-0.42),
            Vector2(sign*0.50,-0.88),
            Vector2(sign*0.24,-1.17)
        ]
        if side < 0:
            cheek_shape.reverse()
        var cheek_rings := [
            [0.157,0.82,0.010],
            [0.266,1.00,0.025],
            [0.399,1.035,0.040],
            [0.524,0.939,0.065],
            [0.592,0.825,0.077]
        ]
        _surface(turret,"G09V11MordazaAngular_%s" % side,
            cheek_shape,cheek_rings,CERAMIC)
        # Triangular dark valley between the cheek and the deck. This is
        # actual recessed silhouette depth, not a fake graphic.
        var edge := Hero._rod(turret,"G09V11LineaQuiebre_%s" % side,
            Vector3(sign*0.79,0.552,-1.21),
            Vector3(sign*1.09,0.548,-0.53),0.024,SHADOW)
        edge.material_override = Hero._army_material(SHADOW,false)
        var side_shape := [
            Vector2(sign*0.89,-0.25),Vector2(sign*1.08,-0.24),
            Vector2(sign*1.08,0.62),Vector2(sign*0.82,0.89)
        ]
        if side < 0:
            side_shape.reverse()
        _surface(turret,"G09V11HombreraFlanco_%s" % side,
            side_shape,[[0.22,0.90,0.0],[0.38,1.0,0.0],
                [0.56,0.88,0.0]],CERAMIC_SIDE)
        _groove(turret,"G09V11UnionFlanco_%s" % side,
            Vector3(sign*1.015,0.566,-0.05),
            Vector3(sign*0.985,0.559,0.55),0.017)
        # Rear armoured ammunition bustle, structural part of the top-down
        # outline and therefore visible at actual Android map size.
        _surface(turret,"G09V11BastionPosterior_%s" % side,[
            Vector2(sign*0.45,0.81),Vector2(sign*0.85,0.87),
            Vector2(sign*0.86,1.19),Vector2(sign*0.48,1.23)
        ] if side>0 else [
            Vector2(sign*0.48,1.23),Vector2(sign*0.86,1.19),
            Vector2(sign*0.85,0.87),Vector2(sign*0.45,0.81)
        ],[[0.20,0.91,0.0],[0.38,1.0,0.0],
            [0.516,0.85,0.0]],MAIN)
        # Front compound glacis armour on the ACTUAL hull, not dangling
        # ornaments on the gun assembly.
        var prow := [
            Vector2(sign*0.07,-1.81),Vector2(sign*0.38,-1.78),
            Vector2(sign*0.74,-1.47),Vector2(sign*0.65,-1.07),
            Vector2(sign*0.07,-1.32)
        ]
        if side < 0:
            prow.reverse()
        _surface(hull,"G09V11PuntaGlacis_%s" % side,prow,
            [[0.696,0.96,0.018],[0.842,1.0,0.085],
                [0.986,0.89,0.167]],FRONT)
        _groove(hull,"G09V11NervioCentralProa_%s" % side,
            Vector3(sign*0.075,1.010,-1.393),
            Vector3(sign*0.08,0.872,-1.746),0.015)

    # Signature steel undercut at the bow visually separates armor wedges
    # from the dark lower front. Preserve protected faction paint areas.
    Hero._dark_box(hull,"G09V11EntradaAireFrontocasco",
        Vector3(0,0.586,-1.677),Vector3(0.59,0.087,0.076),SHADOW)
    model.set_meta("tarvoka_mbt_structural_v11",true)
    return true

static func finish_materials(model: Node3D) -> int:
    # Must execute after the existing PBR material classification.
    if model == null or not model.get_meta("tarvoka_mbt_structural_v11",false):
        return 0
    var textured: int = 0
    for node in model.find_children("G09V11*","MeshInstance3D",true,false):
        var piece: MeshInstance3D = node as MeshInstance3D
        if piece == null or piece.material_override == null:
            continue
        var mat: StandardMaterial3D = piece.material_override.duplicate(true) as StandardMaterial3D
        var part_name: String = str(piece.name)
        var armor: bool = "Mordaza" in part_name or "Glacis" in part_name
        var black: bool = "Linea" in part_name or "Union" in part_name or "Nervio" in part_name or "Entrada" in part_name
        mat.albedo_color = SHADOW if black else (CERAMIC if "Mordaza" in part_name else
            (FRONT if "Glacis" in part_name else
                (CERAMIC_SIDE if "Hombrera" in part_name else
                    (Color("#526872") if "TechoEstructural" in part_name else MAIN))))
        mat.albedo_texture = null if black else V10._enamel_mask(armor)
        mat.normal_enabled = not black
        mat.normal_texture = Hero._army_micro_normal() if not black else null
        mat.normal_scale = 0.24
        mat.roughness_texture = Hero._army_micro_roughness() if not black else null
        mat.roughness = 0.84 if armor else 0.74
        mat.metallic = 0.14 if armor else 0.23
        mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        piece.material_override = mat
        textured += 1
    # Change two actual core solids (not a paint overlay).
    for record in [
        ["CorazaSoldadaHermeticaV7",MAIN],
        ["TorreBajaSoldadaV7",ROOF]
    ]:
        var solid: MeshInstance3D = model.find_child(
            str(record[0]),true,false) as MeshInstance3D
        if solid == null or solid.material_override == null:
            continue
        var coat: StandardMaterial3D = solid.material_override.duplicate(true) as StandardMaterial3D
        coat.albedo_color = record[1]
        coat.albedo_texture = V10._enamel_mask(false)
        coat.roughness = 0.76
        coat.metallic = 0.23
        coat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        solid.material_override = coat
        textured += 1
    model.set_meta("tarvoka_mbt_structural_v11_pbr_count",textured)
    return textured
