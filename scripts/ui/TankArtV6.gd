extends RefCounted
class_name TarvokaTankArtV6

# G09 hard-surface art pass: substantial integrated shapes rather than more
# decorative cubes. Composes on top of watertight V5 without changing combat.
# The 8 faction palettes and exactly 14 replaceable paint meshes remain intact.
const V5 = preload("res://scripts/ui/TankSilhouetteV5.gd")
const Finish = preload("res://scripts/ui/TankFinish3D.gd")
const ROOT := "G09ArteDeSuperficiesV6"
const MAIN := Color("#526260") # matte, slightly olive military enamel
const CERAMIC := Color("#79837D")
const BEVEL := Color("#929892")
const SHADE := Color("#2A3638")
const MATTE := Color("#3D4E4C")
const JOINT := Color("#1B272C")
const METAL := Color("#6A7774")
const GLASS := Color("#1B4E5E")
const CLAY := Color("#69695B")

static func _plate(parent: Node3D, label: String, at: Vector3,
        size: Vector3, radius: float, color: Color,
        turn: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var piece := Finish._bevel(parent,label,at,size,radius,color)
    piece.rotation_degrees = turn
    return piece

static func _line(parent: Node3D, label: String, from: Vector3,
        to: Vector3, thickness: float = 0.017,
        color: Color = SHADE) -> MeshInstance3D:
    return Finish._rod(parent,label,from,to,thickness,color,8)

static func _shade(node: Node, color: Color, metallic: float = 0.18,
        roughness: float = 0.80) -> void:
    if node is MeshInstance3D:
        var mesh := node as MeshInstance3D
        var previous := mesh.material_override as StandardMaterial3D
        var next: StandardMaterial3D = previous.duplicate(true) as StandardMaterial3D if previous != null else StandardMaterial3D.new()
        next.albedo_color = color
        next.metallic = metallic
        next.roughness = roughness
        mesh.material_override = next

static func _invisible(root: Node3D, names: Array) -> void:
    for label in names:
        var part: Node3D = root.find_child(str(label),true,false) as Node3D
        if part != null:
            part.visible = false

static func _morph(parent: Node3D, name: String, lower: Array,
        upper: Array, tint: Color) -> MeshInstance3D:
    return V5._solid_ring(parent,name,lower,upper,tint)

static func apply(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    if hull == null or turret == null or gun == null or not model.get_meta("tarvoka_mbt_silhouette_v5",false):
        return false
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)

    # The main V5 bodies stay physically sealed and get a distinct military
    # matte coat, instead of an even, light bluish toy plastic material.
    for label in ["CascoHermeticoV5","TorreHermeticaV5",
            "BastidorTraseroIntegradoV5","PortonTraseroHermeticoV5"]:
        var piece := model.find_child(label,true,false)
        if piece != null:
            _shade(piece,MAIN)
    for label in ["FaldonContinuoV5_-1","FaldonContinuoV5_1",
            "LaminaExteriorTorreV5_-1","LaminaExteriorTorreV5_1",
            "CubiertaMotorSelladaV5","TapaCestaBlindadaV5"]:
        var piece := model.find_child(label,true,false)
        if piece != null:
            _shade(piece,MATTE)

    # Replace cluttered toy-style rooftop towers/rails and V5 cheeks. The
    # thick V6 cheek becomes a contiguous wedge bonded to the turret shell.
    _invisible(turret,[
        "MejillaPrincipalV5_-1","MejillaPrincipalV5_1",
        "CristalTermico","PantallaTermica",
        "ModuloVisionPanoramica","CristalPanoramicoFrontal",
        "CristalPanoramicoLateral","VisorTermicoProtegido","LenteTermicoPrincipal",
        "ModuloLASERBlindado-1","ModuloLASERBlindado1",
        "CristalTelescopio-1","CristalTelescopio1",
        "EstibaAntideslizante-1","EstibaAntideslizante1",
        "BolsaLonaEstiba-1","BolsaLonaEstiba1",
        "BarandaPosterior-1","BarandaPosterior1",
        "BarraCestaSuperior-1","BarraCestaSuperior1",
        "BarraCestaInferior-1","BarraCestaInferior1",
        "CruzCestaPosterior-1","CruzCestaPosterior1"])
    _invisible(gun,["MantleteMonoliticoV5","AroSelladoCanonV5"])
    _invisible(hull,["TapaConductor","PeriscopioConductor",
        "LomasBlindajeChasis","LamasRefrigeracion_00",
        "LamasRefrigeracion_01","LamasRefrigeracion_02"])

    # 1) Low turret: coherent wedge-shaped composite cheek armor from cast
    # upper nose to sidewall. Closed mesh, not a floating BoxMesh.
    for side in [-1,1]:
        var sign: float = float(side)
        var low := [
            Vector3(sign*0.19,0.145,-1.20),
            Vector3(sign*0.48,0.145,-1.17),
            Vector3(sign*0.79,0.14,-0.83),
            Vector3(sign*0.89,0.13,-0.40),
            Vector3(sign*0.77,0.15,-0.22),
            Vector3(sign*0.38,0.16,-0.39)
        ]
        var high := [
            Vector3(sign*0.18,0.49,-1.17),
            Vector3(sign*0.43,0.51,-1.13),
            Vector3(sign*0.68,0.66,-0.76),
            Vector3(sign*0.76,0.59,-0.39),
            Vector3(sign*0.66,0.55,-0.20),
            Vector3(sign*0.38,0.55,-0.40)
        ]
        _morph(turret,"MejillaMonoliticaV6_%s" % side,low,high,CERAMIC)
        _plate(turret,"CantoBlindajeMejillaV6_%s" % side,
            Vector3(sign*0.715,0.397,-0.46),
            Vector3(0.075,0.13,0.54),0.027,MATTE,
            Vector3(0,sign*18.0,sign*6.0))
        _line(turret,"SoldaduraMejillaV6_%s" % side,
            Vector3(sign*0.68,0.599,-0.68),
            Vector3(sign*0.70,0.554,-0.26),0.017,JOINT)

        # Two broad, slanted, low-profile protection panels. More durable
        # visually than the previous isolated ERA cuboids.
        for idx in range(2):
            _plate(turret,"ModuloCeramicoLateralV6_%s_%d" % [side,idx],
                Vector3(sign*0.805,0.335,-0.08+float(idx)*0.41),
                Vector3(0.073,0.245,0.355),0.038,MATTE,
                Vector3(0,sign*9.0,sign*5.0))
            _line(turret,"JuntaLateralV6_%s_%d" % [side,idx],
                Vector3(sign*0.855,0.244,-0.26+float(idx)*0.41),
                Vector3(sign*0.857,0.455,-0.26+float(idx)*0.41),
                0.012,JOINT)

    # 2) Angled gun housing that closes the seam between turret and barrel.
    # It stays on ElevacionCanon, preserving recoil/elevation and muzzle VFX.
    _plate(gun,"BastidorCanonIntegradoV6",
        Vector3(0,0.01,-0.34),Vector3(0.72,0.37,0.38),
        0.115,MAIN,Vector3(-3,0,0))
    _plate(gun,"BordeMantleteCeramicoV6",
        Vector3(0,0.02,-0.535),Vector3(0.445,0.28,0.09),
        0.077,SHADE)
    _line(gun,"JuntaMantleteV6L",Vector3(-0.23,0.125,-0.53),
        Vector3(-0.23,-0.10,-0.53),0.016,JOINT)
    _line(gun,"JuntaMantleteV6R",Vector3(0.23,0.125,-0.53),
        Vector3(0.23,-0.10,-0.53),0.016,JOINT)

    # 3) Reduced-height asymmetric sensor housing with integrated dark optics
    # instead of pale-blue cubic housings hovering over the turret.
    _plate(turret,"ModuloOpticoPanoramicoV6",
        Vector3(0.44,0.690,-0.29),
        Vector3(0.28,0.135,0.29),0.058,MATTE,
        Vector3(-9,0,0))
    _plate(turret,"VentanaOpticaPanoramicaV6",
        Vector3(0.44,0.702,-0.445),
        Vector3(0.18,0.082,0.020),0.015,GLASS)
    _plate(turret,"SensorDeApuntamientoV6",
        Vector3(-0.40,0.696,-0.37),
        Vector3(0.20,0.105,0.23),0.048,MATTE)
    _plate(turret,"LenteDeApuntamientoV6",
        Vector3(-0.40,0.701,-0.495),
        Vector3(0.13,0.067,0.017),0.012,GLASS)
    # Compact commander's hatch ring. No enormous protruding toy block.
    _plate(turret,"TapaComandanteBlindadaV6",
        Vector3(-0.35,0.657,0.15),
        Vector3(0.46,0.035,0.43),0.148,MAIN)
    _line(turret,"BisagraEscotillaV6",
        Vector3(-0.52,0.678,0.33),
        Vector3(-0.19,0.678,0.33),0.015,METAL)

    # 4) Distinctive rear armor instead of scaffolding: sloped bustle flanks,
    # maintenance hatches and actual visible roof seams.
    _plate(turret,"TapaBlindadaEstibaV6",
        Vector3(0,0.557,0.92),
        Vector3(0.95,0.045,0.39),0.059,MAIN)
    _line(turret,"SoldaduraCestaPosteriorV6",
        Vector3(-0.45,0.591,0.74),
        Vector3(0.45,0.591,0.74),0.014,JOINT)
    for side in [-1,1]:
        var sign: float = float(side)
        _plate(turret,"DeflectorPosteriorV6_%s" % side,
            Vector3(sign*0.535,0.36,0.91),
            Vector3(0.155,0.27,0.38),0.052,MATTE,
            Vector3(0,sign*15.0,-sign*5.0))
        _line(turret,"JuntaTechoV6_%s" % side,
            Vector3(sign*0.51,0.653,-0.32),
            Vector3(sign*0.50,0.626,0.56),0.013,JOINT)

    # 5) Finished hull with shallow sloped driver hatch and tightly spaced
    # engine panels. Changes surface read at normal battle scale.
    _plate(hull,"TapaConductorRebajadaV6",
        Vector3(-0.39,1.098,-0.76),
        Vector3(0.39,0.038,0.43),0.087,MAIN,
        Vector3(-12,0,0))
    _plate(hull,"PeriscopioConductorEncastreV6",
        Vector3(-0.39,1.135,-1.025),
        Vector3(0.28,0.095,0.10),0.044,MATTE)
    _plate(hull,"CristalPeriscopioConductorV6",
        Vector3(-0.39,1.144,-1.082),
        Vector3(0.22,0.066,0.015),0.013,GLASS)
    for idx in range(3):
        _plate(hull,"TapaRejillaMotorV6_%d" % idx,
            Vector3(-0.36+float(idx)*0.36,1.135,1.10),
            Vector3(0.31,0.031,0.47),0.054,SHADE)
        for slat in range(4):
            _line(hull,"AletaEscapeV6_%d_%d" % [idx,slat],
                Vector3(-0.49+float(idx)*0.36,1.156,0.91+float(slat)*0.11),
                Vector3(-0.23+float(idx)*0.36,1.156,0.91+float(slat)*0.11),
                0.011,METAL)

    # 6) Modular skirts are no longer a continuous neon strip. Preserve all
    # 10 existing FaccionFaldon meshes for instant faction recoloring but
    # shrink/seat their painted inserts into small ID recesses.
    for side in [-1,1]:
        var sign: float = float(side)
        for n in range(5):
            var name: String = "FaccionFaldon%s_%02d" % [side,n]
            var insert: MeshInstance3D = model.find_child(name,true,false) as MeshInstance3D
            if insert != null:
                insert.scale.y = 0.58
                insert.scale.z = 0.79
                insert.position.y = 0.748
                insert.position.x = sign*1.255
            _plate(hull,"MarcoInsertoFaldonV6_%s_%d" % [side,n],
                Vector3(sign*1.236,0.747,-1.07+float(n)*0.54),
                Vector3(0.023,0.15,0.46),0.024,JOINT)
        _line(hull,"CantoSuspensionV6_%s" % side,
            Vector3(sign*1.255,0.905,-1.35),
            Vector3(sign*1.255,0.905,1.35),0.016,METAL)

    model.set_meta("tarvoka_mbt_art_v6",true)
    return true
