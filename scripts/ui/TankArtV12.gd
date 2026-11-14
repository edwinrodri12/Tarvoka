extends RefCounted
class_name TarvokaTankArtV12

# Visual-only refinement of TARVOKA G09 V11, deliberately NOT an independent
# concept asset. All shapes attach to the live chassis/turret/gun pivots.
# V10 Android remains the stable default; V12 is selectable in the Web studio.
const Hero = preload("res://scripts/ui/TankHeroV7.gd")
const V10 = preload("res://scripts/ui/TankArmorV10.gd")
const ROOT := "G09V12AcabadoCoherente"
const HULL := Color("#485C66")
const TURRET := Color("#455963")
const CERAMIC := Color("#73838B")
const ROOF := Color("#53656D")
const DARK := Color("#25353C")
const EDGE := Color("#394952")
const RECESS := Color("#19272E")
const OPTIC := Color("#163C4B")

static func _weld(parent: Node3D,name: String,a: Vector3,b: Vector3,
        width: float = 0.013) -> MeshInstance3D:
    return Hero._rod(parent,name,a,b,width,DARK)

static func _panel(parent: Node3D,name: String,pos: Vector3,
        size: Vector3,bevel: float,tint: Color) -> MeshInstance3D:
    return Hero._bevel(parent,name,pos,size,bevel,tint)

static func _loft(parent: Node3D,name: String,outline: Array,
        rings: Array,color: Color) -> MeshInstance3D:
    return Hero._loft(parent,name,outline,rings,color)

static func apply(model: Node3D) -> bool:
    if model == null or not model.get_meta("tarvoka_mbt_structural_v11",false):
        return false
    if model.find_child(ROOT,true,false) != null:
        return false
    var hull: Node3D = model.find_child("ChasisBlindado",true,false) as Node3D
    var turret: Node3D = model.find_child("TorretaGiratoria",true,false) as Node3D
    var gun: Node3D = model.find_child("ElevacionCanon",true,false) as Node3D
    if hull == null or turret == null or gun == null:
        return false
    var marker := Node3D.new()
    marker.name = ROOT
    model.add_child(marker)

    # The flat V10 upper guards ran the entire length without a chamfer;
    # this caused the former "armored shoebox" profile on the phone. Real
    # five-ring side shields slope from the thick prow to the narrow rear.
    # They stop ABOVE the 14 faction-color paint panels: those stay visible.
    for side in [-1,1]:
        var sign: float = float(side)
        var previous: Node3D = hull.find_child(
            "G09V10HombroFaldon_%s" % side,true,false) as Node3D
        if previous != null:
            previous.visible = false
        var contour := [
            Vector2(sign*0.94,-1.49),
            Vector2(sign*1.075,-1.57),
            Vector2(sign*1.245,-1.34),
            Vector2(sign*1.265,0.87),
            Vector2(sign*1.137,1.39),
            Vector2(sign*0.943,1.43)
        ]
        if side < 0:
            contour.reverse()
        _loft(hull,"G09V12DefensaOrugaAngular_%s" % side,contour,[
            [0.819,0.921,0.022],
            [0.901,1.012,0.029],
            [0.971,0.986,0.037],
            [1.029,0.866,0.052]
        ],HULL)
        # Deliberately recessed dark separation between steel shoulder
        # and colored identification strip (not a painted faction logo).
        _weld(hull,"G09V12UnionBlindajeRodaje_%s" % side,
            Vector3(sign*1.210,0.843,-1.235),
            Vector3(sign*1.225,0.843,1.215),0.014)
        _panel(hull,"G09V12RetenFaldonDelantero_%s" % side,
            Vector3(sign*1.168,0.830,-1.355),
            Vector3(0.096,0.045,0.240),0.017,EDGE)
        _panel(hull,"G09V12RetenFaldonPosterior_%s" % side,
            Vector3(sign*1.169,0.831,1.280),
            Vector3(0.093,0.045,0.196),0.015,EDGE)

        # Asymmetric flush service lids and shallow inset deck vents.
        # The engine roof already exists; these parts define a coherent
        # top surface rather than piling tall block details on it.
        var top_lid := [
            Vector2(sign*0.46,0.73),
            Vector2(sign*0.68,0.72),
            Vector2(sign*0.68,1.34),
            Vector2(sign*0.51,1.41),
            Vector2(sign*0.38,1.33)
        ]
        if side < 0:
            top_lid.reverse()
        _loft(hull,"G09V12CubiertaMotorLateral_%s" % side,top_lid,[
            [1.145,0.93,0.0],
            [1.163,0.995,0.0],
            [1.177,0.92,0.0]
        ],ROOF)
        _weld(hull,"G09V12CosturaMotor_%s" % side,
            Vector3(sign*0.443,1.184,0.850),
            Vector3(sign*0.437,1.184,1.290),0.010)

        # Remove a giant slab-like prow patch inherited from V10 and
        # replace it with a smaller bevelled angled access plate.
        _panel(hull,"G09V12RegistroProa_%s" % side,
            Vector3(sign*0.468,1.008,-1.012),
            Vector3(0.260,0.036,0.238),0.030,CERAMIC)
        _weld(hull,"G09V12BordeRegistroProa_%s" % side,
            Vector3(sign*0.338,1.031,-0.903),
            Vector3(sign*0.581,1.030,-0.903),0.009)

    # One integrated ammo bustle ties the angular rear silhouette to the
    # turret deck, filling the old open wedge between overhanging corners.
    _loft(turret,"G09V12AlmacenBlindadoPosterior",[
        Vector2(-0.53,0.832),Vector2(0.53,0.832),
        Vector2(0.72,1.054),Vector2(0.69,1.274),
        Vector2(-0.69,1.274),Vector2(-0.72,1.054)
    ],[
        [0.228,0.920,0.0],
        [0.333,1.005,0.0],
        [0.466,0.936,0.0],
        [0.493,0.878,0.0]
    ],TURRET)
    _weld(turret,"G09V12JuntaBastidorMuniciones",
        Vector3(-0.593,0.501,1.062),
        Vector3(0.593,0.501,1.062),0.014)

    # Broad central wedge around the firing axis is genuinely attached
    # to ElevacionCanon and retains full elevation and recoil.
    _panel(gun,"G09V12MantoTermicoIntegrado",
        Vector3(0,0.006,-0.455),
        Vector3(0.297,0.243,0.334),0.047,DARK)
    _panel(gun,"G09V12EscudoDeReculada",
        Vector3(0,0.012,-0.280),
        Vector3(0.374,0.259,0.133),0.048,CERAMIC)
    _weld(gun,"G09V12JuntaMantoTermico",
        Vector3(-0.134,0.110,-0.520),
        Vector3(0.134,0.110,-0.520),0.010)

    # Roof optics should read as integrated protected instruments, not two
    # pale boxes disconnected from the armored turret.
    for label in ["G09CabezalPanoramicoCompactoV9",
            "G09EstacionArmaRasanteV9","G09PanelServicioTorreV9",
            "G09V10PanelServicioTecho","G09V10RegistroCentralTorre"]:
        var node: MeshInstance3D = model.find_child(label,true,false) as MeshInstance3D
        if node != null and node.material_override != null:
            var original: StandardMaterial3D = node.material_override as StandardMaterial3D
            if original != null:
                var matte: StandardMaterial3D = original.duplicate(true) as StandardMaterial3D
                matte.albedo_color = ROOF if "Panel" in label or "Registro" in label else DARK
                matte.metallic = 0.16
                matte.roughness = 0.82
                node.material_override = matte
    model.set_meta("tarvoka_mbt_refined_v12",true)
    return true

static func finish_materials(model: Node3D) -> int:
    if model == null or not model.get_meta("tarvoka_mbt_refined_v12",false):
        return 0
    var count: int = 0
    for node in model.find_children("G09V12*","MeshInstance3D",true,false):
        var part: MeshInstance3D = node as MeshInstance3D
        if part == null or part.material_override == null:
            continue
        var material: StandardMaterial3D = part.material_override.duplicate(true) as StandardMaterial3D
        var dark: bool = "Union" in part.name or "Junta" in part.name or \
            "Costura" in part.name or "Borde" in part.name
        var ceramic: bool = "Registro" in part.name or "Escudo" in part.name
        material.albedo_color = RECESS if dark else (CERAMIC if ceramic else
            (ROOF if "Motor" in part.name else (TURRET if "Almacen" in part.name else HULL)))
        material.albedo_texture = null if dark else V10._enamel_mask(ceramic)
        material.normal_enabled = not dark
        material.normal_texture = Hero._army_micro_normal() if not dark else null
        material.normal_scale = 0.22
        material.roughness_texture = Hero._army_micro_roughness() if not dark else null
        material.roughness = 0.85 if ceramic else 0.77
        material.metallic = 0.13 if ceramic else 0.22
        material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        part.material_override = material
        count+=1
    model.set_meta("tarvoka_mbt_refined_v12_pbr_count",count)
    return count

static func refine_faction_paint(model: Node3D) -> int:
    # Called again on every browser faction change. Keep ALL 14 paint
    # nodes, but recess the broad side stripe into military enamel.
    if model == null or not model.get_meta("tarvoka_mbt_refined_v12",false):
        return 0
    var count: int = 0
    for part in model.find_children("FaccionFaldon*","MeshInstance3D",true,false):
        var plate: MeshInstance3D = part as MeshInstance3D
        var mat: StandardMaterial3D = plate.material_override as StandardMaterial3D
        if mat == null:
            continue
        var new_finish: StandardMaterial3D = mat.duplicate(true) as StandardMaterial3D
        new_finish.albedo_color = new_finish.albedo_color.darkened(0.22)
        new_finish.metallic = 0.18
        new_finish.roughness = 0.76
        plate.material_override = new_finish
        count+=1
    model.set_meta("tarvoka_mbt_refined_v12_paint_count",count)
    return count
