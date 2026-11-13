extends RefCounted
class_name TarvokaTankDamage3D

# Five persistent, visually distinct MBT condition states for model QA:
# intact, marked, damaged, critical and destroyed. No combat state, saved HP,
# rules or destructive changes to the source geometry.
const STAGES := ["Intacto","Impactos leves","Daño moderado","Daño crítico","Destruido"]

# Cosmetic bridge from authoritative HP to the five art-only MBT damage layers.
# Does not alter stats, damage or save schema. A defeated unit is shown only
# in the inspector; the tactical engine removes it as before.
static func stage_for_hp(hp: int, maximum_hp: int) -> int:
    if hp <= 0:
        return 4
    if maximum_hp <= 0:
        return 0
    var fraction: float = clampf(float(hp) / float(maximum_hp),0.0,1.0)
    if fraction >= 0.90:
        return 0
    if fraction >= 0.65:
        return 1
    if fraction >= 0.40:
        return 2
    return 3
const ROOT := "EtapasDestruccion3D"
const TURRET := "TorretaGiratoria"
const GUN := "ElevacionCanon"
const STAGE_META := "tarvoka_visual_damage_stage"
const ACCENT := Color("#E8A34F")

static func _material(color: Color, emissive: bool = false) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.93
    material.metallic = 0.04
    if color.a < 1.0:
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
    if emissive:
        material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        material.emission_enabled = true
        material.emission = color.lightened(0.20)
        material.emission_energy_multiplier = 2.0
    return material

static func _box(parent: Node3D, label: String, at: Vector3, size: Vector3,
        color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.name = label
    var shape := BoxMesh.new()
    shape.size = size
    piece.mesh = shape
    piece.material_override = _material(color)
    piece.position = at
    piece.rotation_degrees = rotation
    parent.add_child(piece)
    return piece

# Single shared 96-pixel soft-edge mask replaces the giant opaque spheres
# seen on Android in 242323.mp4. Only cosmetic smoke/fire uses billboards;
# all vehicle armor and wreckage remain true 3D, independently lit.
static var _smoke_mask: ImageTexture

static func _soft_cloud_mask() -> ImageTexture:
    if _smoke_mask != null:
        return _smoke_mask
    const SIZE := 96
    var image := Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
    for y in range(SIZE):
        for x in range(SIZE):
            var p := Vector2((float(x)+0.5)/float(SIZE)-0.5,
                (float(y)+0.5)/float(SIZE)-0.5)
            var theta: float = atan2(p.y,p.x)
            var edge: float = 0.425 + 0.043*sin(theta*5.0+0.6) + 0.029*cos(theta*9.0-0.8)
            var radius: float = p.length()/maxf(0.1,edge)
            var fringe: float = clampf((1.0-radius)/0.52,0.0,1.0)
            var grain: float = 0.86 + 0.14*sin(float(x)*0.43+cos(float(y)*0.24)*2.0) * cos(float(y)*0.39)
            var alpha: float = fringe*fringe*(3.0-2.0*fringe)*grain
            image.set_pixel(x,y,Color(1.0,1.0,1.0,alpha))
    _smoke_mask = ImageTexture.create_from_image(image)
    return _smoke_mask

static func _cloud(parent: Node3D, label: String, at: Vector3,
        dimensions: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
    var piece := MeshInstance3D.new()
    piece.name = label
    var shape := QuadMesh.new()
    shape.size = Vector2(dimensions.x,dimensions.y)
    piece.mesh = shape
    var material := _material(color,glow)
    material.albedo_texture = _soft_cloud_mask()
    material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    piece.material_override = material
    piece.position = at
    piece.set_meta("tarvoka_smoke_rest_y",at.y)
    parent.add_child(piece)
    return piece

static func animate_smoke(model: Node3D, elapsed: float) -> void:
    # Small floating motion is shown only by the visible Android inspector.
    # Battle HP, deterministic cached unit portraits and saves stay untouched.
    if model == null or current_stage(model) < 2:
        return
    var names := ["HumoGrisMotor","VahoMotor","HumoNegroCritico",
        "HumoElevado","ColumnaHumo","HumoSuperior"]
    for index in range(names.size()):
        var node: Node3D = model.find_child(str(names[index]),true,false) as Node3D
        if node == null or not node.visible:
            continue
        var phase: float = elapsed*1.35+float(index)*1.31
        node.position.y = float(node.get_meta("tarvoka_smoke_rest_y",node.position.y)) + 0.055*sin(phase)
        var breath: float = 1.0+0.055*sin(phase*0.64+0.5)
        node.scale = Vector3.ONE * breath
    if current_stage(model) == 4:
        # Three tapered flame tongues sway independently. Never animate the
        # structural wreck meshes: players must see exactly what broke.
        for index in range(3):
            var flame_name: String = ["LenguaFuegoIzquierda","LenguaFuegoCentro",
                "LenguaFuegoAlta"][index]
            var flame: Node3D = model.find_child(flame_name,true,false) as Node3D
            if flame == null:
                continue
            var swish: float = elapsed*3.2+float(index)*1.8
            flame.rotation_degrees.z = [-18.0,12.0,23.0][index] + 4.5*sin(swish)
            flame.scale = Vector3.ONE * (0.92 + 0.11*sin(swish*1.7))

# Angled, light-emitting flame tongues instead of a fire effect made
# entirely of round spheres. Kept under 8 segments for Android OpenGL.
static func _flame(parent: Node3D, label: String, at: Vector3,
        height: float, radius: float, color: Color, tilt: Vector3) -> MeshInstance3D:
    var item := MeshInstance3D.new()
    item.name = label
    var shape := CylinderMesh.new()
    shape.top_radius = 0.012
    shape.bottom_radius = radius
    shape.height = height
    shape.radial_segments = 7
    item.mesh = shape
    item.material_override = _material(color,true)
    item.position = at
    item.rotation_degrees = tilt
    parent.add_child(item)
    return item

static func _stage_node(root: Node3D, stage: int) -> Node3D:
    var layer := Node3D.new()
    layer.name = "DesgasteEtapa%d" % stage
    root.add_child(layer)
    layer.visible = false
    return layer

static func prepare(model: Node3D) -> bool:
    if model == null or model.find_child(ROOT,true,false) != null:
        return false
    # V13 replaces the uninterrupted V12 side plates and old bustle.
    # Enforce this across ALL five stages; legacy V12 restore code above
    # must not resurrect geometry concealed by the newer optional sculpt.
    if model.get_meta("tarvoka_mbt_segmented_v13",false):
        for old_name in ["G09V12DefensaOrugaAngular_-1",
                "G09V12DefensaOrugaAngular_1",
                "G09V12AlmacenBlindadoPosterior"]:
            var concealed: Node3D = model.find_child(old_name,true,false) as Node3D
            if concealed != null:
                concealed.visible = false
        for part in model.find_children("G09V13FaldonSegmentado_*",
                "MeshInstance3D",true,false):
            var is_rear_hit: bool = str(part.name).ends_with("_1_03") or \
                str(part.name).ends_with("_1_04")
            part.visible = stage < 4 and not (stage >= 3 and is_rear_hit)
        for seam in model.find_children("G09V13RibeteFaldon_*",
                "MeshInstance3D",true,false):
            var torn: bool = str(seam.name).ends_with("_1_03") or \
                str(seam.name).ends_with("_1_04")
            seam.visible = stage < 4 and not (stage >= 3 and torn)
        for name in ["G09V13BastionMunicionesContinuo",
                "G09V13RejillaPosterior","G09V13VigaBastion_-1",
                "G09V13VigaBastion_1"]:
            var aft: Node3D = model.find_child(name,true,false) as Node3D
            if aft != null:
                aft.visible = stage < 4
    var turret: Node3D = model.find_child(TURRET,true,false) as Node3D
    var gun: Node3D = model.find_child(GUN,true,false) as Node3D
    if turret == null or gun == null:
        return false
    var root := Node3D.new()
    root.name = ROOT
    model.add_child(root)

    # Stage 1: shell scars and exposed paint on front glacis and turret cheek.
    var light := _stage_node(root,1)
    _box(light,"CicatrizImpactoFrontal",Vector3(0.31,0.92,-1.12),
        Vector3(0.31,0.035,0.19),Color("#2F3436"),Vector3(-32,0,-15))
    _box(light,"MetalDesnudoImpacto",Vector3(0.31,0.955,-1.132),
        Vector3(0.12,0.039,0.07),Color("#5F5950"),Vector3(-32,0,-15))
    _box(light,"RozaduraFaldon",Vector3(1.224,0.72,-0.52),
        Vector3(0.039,0.12,0.26),Color("#302D2C"),Vector3(0,8,0))
    # A visible shallow hit across the right-hand identification stripe:
    # the first condition must be distinguishable even at the 224px battle
    # portrait, not only through a close-up of the nose.
    _box(light,"MarcaOblicuaFaldonDerecho",Vector3(1.258,0.735,-0.53),
        Vector3(0.026,0.132,0.18),Color("#303637"),Vector3(-9,0,22))
    _box(light,"RaspadoAceroFaldonDerecho",Vector3(1.278,0.75,-0.55),
        Vector3(0.014,0.026,0.15),Color("#A1937E"),Vector3(7,0,18))
    _box(light,"ImpactoSuperiorGlacis",Vector3(-0.23,1.13,-0.82),
        Vector3(0.28,0.045,0.22),Color("#2A2C2D"),Vector3(0,-18,9))
    _box(light,"MetalExpuestoGlacis",Vector3(-0.24,1.165,-0.85),
        Vector3(0.10,0.02,0.11),Color("#B19C7B"),Vector3(0,-18,9))
    # V5's truly sealed glacis sits slightly higher than the prototype,
    # so first-impact scrapes need to be physically visible on the new roof.
    if model.get_meta("tarvoka_mbt_silhouette_v5",false):
        _box(light,"RaspadoCorazaHermeticaV5",Vector3(-0.37,1.092,-1.12),
            Vector3(0.26,0.025,0.15),Color("#33393B"),Vector3(0,13,0))
        _box(light,"AceroDescubiertoHermeticoV5",Vector3(-0.40,1.113,-1.14),
            Vector3(0.12,0.018,0.045),Color("#A29A87"),Vector3(0,13,0))
    # The default Android camera observes the rear-right of the vehicle.
    # Include a readable but modest scuff there, otherwise stage 1 appears
    # almost identical to "intact" even when the player selects it.
    _box(light,"QuemaduraRejillaMotor",Vector3(0.36,1.083,0.97),
        Vector3(0.34,0.027,0.23),Color("#282C2C"),Vector3(0,18,0))
    _box(light,"MetalExpuestoMotor",Vector3(0.37,1.105,0.94),
        Vector3(0.16,0.024,0.062),Color("#9B8D76"),Vector3(0,15,-4))
    var on_turret_1 := Node3D.new()
    on_turret_1.name = "MarcasEnTorre"
    turret.add_child(on_turret_1)
    _box(on_turret_1,"MarcaReboteTorre",Vector3(-0.46,0.31,-0.73),
        Vector3(0.25,0.15,0.040),Color("#38342E"),Vector3(-12,14,0))
    _box(on_turret_1,"AbolladuraTechoTorre",Vector3(0.31,0.572,0.36),
        Vector3(0.27,0.033,0.19),Color("#282D30"),Vector3(0,22,0))
    _box(on_turret_1,"RayaduraMetalTecho",Vector3(0.31,0.594,0.38),
        Vector3(0.15,0.028,0.04),Color("#9D9D91"),Vector3(0,-18,4))
    on_turret_1.visible = false

    # Stage 2: damaged bolt-on armor, missing right skirt module, hot
    # engine exhaust and visible embedded fragments.
    var medium := _stage_node(root,2)
    _box(medium,"BlindajeCompuestoAbierto",Vector3(1.21,0.68,-0.01),
        Vector3(0.09,0.31,0.39),Color("#4D4943"),Vector3(0,0,13))
    _box(medium,"PlacaDesprendida",Vector3(1.38,0.39,0.46),
        Vector3(0.09,0.29,0.48),Color("#5B6468"),Vector3(13,25,27))
    _box(medium,"RejillaMotorFracturada",Vector3(0.32,1.119,0.98),
        Vector3(0.35,0.038,0.25),Color("#373939"),Vector3(-5,-12,9))
    _box(medium,"BaseExpuestaRejilla",Vector3(0.19,1.142,1.05),
        Vector3(0.16,0.029,0.11),Color("#897F70"),Vector3(0,16,0))
    if model.get_meta("tarvoka_mbt_silhouette_v5",false):
        _box(medium,"FugaSelladoTraseroV5",Vector3(-0.30,1.148,1.22),
            Vector3(0.25,0.044,0.27),Color("#30383B"),Vector3(-6,10,8))
    _cloud(medium,"HumoGrisMotor",Vector3(-0.09,1.37,1.01),
        Vector3(0.54,0.77,0.55),Color(0.25,0.28,0.29,0.26))
    _cloud(medium,"VahoMotor",Vector3(0.12,1.71,1.16),
        Vector3(0.67,0.76,0.59),Color(0.35,0.36,0.35,0.13))

    # Stage 3: broken right tread, fractured applique armor and dense
    # smoke on the turret/engine, with real separated track segment shapes.
    var critical := _stage_node(root,3)
    _box(critical,"OrugaCortadaColgante",Vector3(1.37,0.22,-0.65),
        Vector3(0.15,0.27,0.87),Color("#202529"),Vector3(0,0,-21))
    for i in range(5):
        _box(critical,"EslabonArrancado%d" % i,
            Vector3(1.49+float(i%2)*0.07,0.20+float(i%3)*0.10,
                -1.15+float(i)*0.20),
            Vector3(0.15,0.09,0.14),Color("#303538"),
            Vector3(i*10,i*17,i*23))
    _box(critical,"FragmentoBlindaje",Vector3(0.85,0.56,-1.21),
        Vector3(0.40,0.15,0.48),Color("#4C5456"),Vector3(19,25,27))
    _cloud(critical,"HumoNegroCritico",Vector3(0.07,1.79,0.74),
        Vector3(0.78,1.11,0.75),Color(0.09,0.10,0.12,0.34))
    _cloud(critical,"HumoElevado",Vector3(-0.12,2.38,0.75),
        Vector3(0.78,0.92,0.79),Color(0.12,0.14,0.16,0.23))

    # Stage 4: broken gun and slumped turret, flame/fire glow and wreck
    # debris. The neutral chassis remains to make faction/vehicle identity
    # still recognizable, but the model is clearly out of combat.
    var destroyed := _stage_node(root,4)
    _box(destroyed,"FragmentoCanonDoblado",Vector3(-0.28,0.29,-1.95),
        Vector3(0.17,0.12,0.82),Color("#23272A"),Vector3(0,-24,22))
    _box(destroyed,"PlacaFrontalArrancada",Vector3(-0.72,0.26,-1.49),
        Vector3(0.67,0.11,0.62),Color("#3B4447"),Vector3(17,23,34))
    _box(destroyed,"RestosOruga",Vector3(-1.31,0.16,0.95),
        Vector3(0.32,0.19,0.96),Color("#22272B"),Vector3(-11,-17,18))
    for i in range(4):
        _box(destroyed,"EscombroMetal%d" % i,
            Vector3(-0.87+float(i)*0.47,0.10,-1.69+float(i%2)*0.34),
            Vector3(0.28,0.11,0.37),Color("#343B3F"),Vector3(15*i,21*i,13*i))
    _cloud(destroyed,"FuegoBase",Vector3(0.22,1.24,-0.04),
        Vector3(0.65,0.93,0.61),Color(1.0,0.42,0.10,0.70),true)
    _cloud(destroyed,"FuegoNucleo",Vector3(0.17,1.26,-0.05),
        Vector3(0.34,0.68,0.35),Color(1.0,0.81,0.25,0.82),true)
    _cloud(destroyed,"ColumnaHumo",Vector3(0.28,2.13,-0.02),
        Vector3(1.04,1.45,0.92),Color(0.08,0.09,0.11,0.34))
    _cloud(destroyed,"HumoSuperior",Vector3(0.36,2.91,-0.04),
        Vector3(1.23,1.03,1.04),Color(0.13,0.14,0.17,0.20))
    # Broken hardware remains visible even when flame/smoke fades.
    _box(destroyed,"BastidorTorrePartido",Vector3(-0.83,1.04,0.68),
        Vector3(0.09,0.57,0.71),Color("#22282B"),Vector3(16,-26,42))
    _box(destroyed,"OpticaArrancada",Vector3(0.82,0.28,-0.62),
        Vector3(0.31,0.16,0.19),Color("#2C3A3D"),Vector3(25,21,-15))
    _box(destroyed,"BlindajeSeparadoProa",Vector3(0.63,0.19,-1.74),
        Vector3(0.51,0.13,0.47),Color("#4B5557"),Vector3(-8,20,27))
    _box(destroyed,"MotorCarbonizado",Vector3(0.0,1.076,0.94),
        Vector3(1.17,0.035,0.48),Color("#22272B"))
    _flame(destroyed,"LenguaFuegoIzquierda",Vector3(-0.13,1.47,0.09),
        0.87,0.19,Color(1.00,0.43,0.08,0.81),Vector3(0,0,-18))
    _flame(destroyed,"LenguaFuegoCentro",Vector3(0.17,1.58,-0.02),
        1.05,0.25,Color(1.00,0.69,0.12,0.84),Vector3(9,0,12))
    _flame(destroyed,"LenguaFuegoAlta",Vector3(0.41,1.77,0.22),
        0.90,0.14,Color(0.95,0.30,0.04,0.67),Vector3(-12,0,23))
    model.set_meta(STAGE_META,0)
    return true

static func current_stage(model: Node3D) -> int:
    return int(model.get_meta(STAGE_META,0)) if model != null else 0

static func apply_stage(model: Node3D, stage: int) -> bool:
    if model == null or stage < 0 or stage >= STAGES.size():
        return false
    var root: Node3D = model.find_child(ROOT,true,false) as Node3D
    if root == null:
        return false
    model.set_meta(STAGE_META,stage)
    for index in range(1,STAGES.size()):
        var layer: Node3D = root.find_child("DesgasteEtapa%d" % index,false,false) as Node3D
        if layer != null:
            layer.visible = stage >= index
    var cheek: Node3D = model.find_child("MarcasEnTorre",true,false) as Node3D
    if cheek != null:
        cheek.visible = stage >= 1
    # Use mesh visibility rather than deleting/copying meshes. The original
    # unit stays reusable and is restored 100% when returning to "Intacto".
    for part_name in ["FaccionFaldon1_02","FaccionFaldon1_03",
            "FaldonBase1_02","FaldonBase1_03"]:
        var plate: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if plate != null:
            plate.visible = stage < 2
    # The final state physically loses its original cannon instead of
    # simply coloring it black. Broken barrel debris is already in stage 4.
    for weapon_name in ["Canon120mm","ManguitoTermico","ExtractorGases","BocaCanon"]:
        var barrel: MeshInstance3D = model.find_child(weapon_name,true,false) as MeshInstance3D
        if barrel != null:
            barrel.visible = stage < 4
    for part_name in ["CintaSuperiorOruga1","EslabonTreadSuperior1_07",
            "EslabonTreadSuperior1_08","EslabonTreadSuperior1_09"]:
        var tread: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if tread != null:
            tread.visible = stage < 3
    # Finishing pieces become physically broken, not just hidden by smoke.
    # Every change is reversible by returning the viewer to stage 0.
    for part_name in ["MejillaCeramicaBiselada1","GuardiaOpticaLateral1",
            "LenteSensorLateral1","BlindajeRuedaExtremo1_-1",
            "ERACompuestaBiselada1_1","ERACompuestaBiselada1_2",
            "ModuloLASERBlindado1","CristalTelescopio1"]:
        var finish_piece: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if finish_piece != null:
            finish_piece.visible = stage < 3
    for part_name in ["CristalPanoramicoFrontal","ModuloVisionPanoramica",
            "CristalPanoramicoLateral","BastidorTrasero-1",
            "VisorTermicoProtegido","LenteTermicoPrincipal",
            "BarraCestaSuperior1","BolsaLonaEstiba1",
            "AroBocaPrincipal","InteriorOscuroCanon",
            "AroSelladoCanonV5"]:
        var upper_piece: MeshInstance3D = model.find_child(part_name,true,false) as MeshInstance3D
        if upper_piece != null:
            upper_piece.visible = stage < 4
    # V11 closed armored wedges physically break with critical damage.
    # The same visibility restoration works for stages 0-2 and legacy V10.
    for part_name in ["G09V11MordazaAngular_1",
            "G09V11HombreraFlanco_1","G09V11PuntaGlacis_1"]:
        var v11_piece: Node3D = model.find_child(part_name,true,false) as Node3D
        if v11_piece != null:
            v11_piece.visible = stage < 3
    for part_name in ["G09V11BastionPosterior_-1",
            "G09V11BastionPosterior_1"]:
        var v11_rear: Node3D = model.find_child(part_name,true,false) as Node3D
        if v11_rear != null:
            v11_rear.visible = stage < 4
    # Cosmetic V12 panels break independently; restoring full HP returns
    # each original transform and material without destroying scene nodes.
    for part_name in ["G09V12DefensaOrugaAngular_1",
            "G09V12RetenFaldonDelantero_1",
            "G09V12CubiertaMotorLateral_1"]:
        var v12_side: Node3D = model.find_child(part_name,true,false) as Node3D
        if v12_side != null:
            v12_side.visible = stage < 3
    for part_name in ["G09V12AlmacenBlindadoPosterior",
            "G09V12MantoTermicoIntegrado","G09V12EscudoDeReculada"]:
        var v12_upper: Node3D = model.find_child(part_name,true,false) as Node3D
        if v12_upper != null:
            v12_upper.visible = stage < 4
    var turret: Node3D = model.find_child(TURRET,true,false) as Node3D
    var gun: Node3D = model.find_child(GUN,true,false) as Node3D
    if turret != null:
        turret.rotation_degrees.z = 0.0 if stage < 3 else (6.0 if stage == 3 else 22.0)
        turret.position.y = 1.11 if stage < 4 else 0.93
    if gun != null:
        gun.rotation_degrees.x = -18.0 if stage >= 4 else (5.0 if stage == 3 else 0.0)
    # The V5 overhaul deliberately hides obsolete prototype blocks even at
    # full HP. Damage stage changes must never resurrect those old shapes.
    if model.get_meta("tarvoka_mbt_silhouette_v5",false):
        for obsolete_name in ["MejillaCeramicaBiselada1",
                "ERACompuestaBiselada1_1","ERACompuestaBiselada1_2"]:
            var obsolete: Node3D = model.find_child(obsolete_name,true,false) as Node3D
            if obsolete != null:
                obsolete.visible = false
        for wreck_name in ["MejillaPrincipalV5_1","LaminaExteriorTorreV5_1"]:
            var blown: Node3D = model.find_child(wreck_name,true,false) as Node3D
            if blown != null:
                blown.visible = stage < 3
        var grille: Node3D = model.find_child("CerrojoPortonV5_1",true,false) as Node3D
        if grille != null:
            grille.visible = stage < 4
    if model.get_meta("tarvoka_mbt_art_v6",false):
        # The V6 ceramic nose permanently replaces V5 cheek and mantlet.
        # Never resurrect the earlier pieces during a repair cycle.
        for obsolete_name in ["MejillaPrincipalV5_-1","MejillaPrincipalV5_1",
                "MantleteMonoliticoV5","AroSelladoCanonV5",
                "CristalPanoramicoFrontal","CristalPanoramicoLateral",
                "ModuloVisionPanoramica","VisorTermicoProtegido",
                "LenteTermicoPrincipal"]:
            var prototype: Node3D = model.find_child(obsolete_name,true,false) as Node3D
            if prototype != null:
                prototype.visible = false
        for armor_name in ["MejillaMonoliticaV6_1","CantoBlindajeMejillaV6_1",
                "ModuloCeramicoLateralV6_1_0","ModuloCeramicoLateralV6_1_1"]:
            var armor: Node3D = model.find_child(armor_name,true,false) as Node3D
            if armor != null:
                armor.visible = stage < 3
        for optics_name in ["ModuloOpticoPanoramicoV6",
                "VentanaOpticaPanoramicaV6","SensorDeApuntamientoV6",
                "LenteDeApuntamientoV6","BordeMantleteCeramicoV6",
                "BastidorCanonIntegradoV6"]:
            var broken: Node3D = model.find_child(optics_name,true,false) as Node3D
            if broken != null:
                broken.visible = stage < 4
    if model.get_meta("tarvoka_mbt_hero_v7",false):
        # V7 armor permanently supersedes V5/V6. Never revive the original
        # prototype on hit, destroy or repair. Keep the actual V7 model as the
        # only visible hull and turret for every hit-point band.
        for name in ["CascoHermeticoV5","TorreHermeticaV5",
                "MejillaMonoliticaV6_-1","MejillaMonoliticaV6_1",
                "BastidorCanonIntegradoV6","BordeMantleteCeramicoV6",
                "ModuloOpticoPanoramicoV6","VentanaOpticaPanoramicaV6",
                "SensorDeApuntamientoV6","LenteDeApuntamientoV6"]:
            var old_part: Node3D = model.find_child(name,true,false) as Node3D
            if old_part != null:
                old_part.visible = false
        for name in ["ModuloBlindajeCeramicoV7_1",
                "HombroBastidorV7_1","FaldonBlindadoIntegradoV7_1"]:
            var armor: Node3D = model.find_child(name,true,false) as Node3D
            if armor != null:
                armor.visible = stage < 3
        for name in ["MantleteConjuntoV7","CollarBlindajeCanonV7",
                "AnilloAceroCanonV7_0","AnilloAceroCanonV7_1",
                "AnilloAceroCanonV7_2",
                "ModuloVisionIntegradoV7_1","CristalVisionIntegradoV7_1"]:
            var destroyed: Node3D = model.find_child(name,true,false) as Node3D
            if destroyed != null:
                destroyed.visible = stage < 4
    if model.get_meta("tarvoka_mbt_production_v9",false):
        # The same authored V9 pieces must be truly damaged, and restored
        # cleanly without exposing obsolete V5/V6 geometry on repair.
        for label in ["G09PlacaCeramicaMandibulaV9_1",
                "G09PanelTechoDelanteroV9_1","G09JuntaMejillaV9_1",
                "G09FundaSensorLateralV9_1","G09LenteSensorLateralV9_1"]:
            var cheek_part: Node3D = model.find_child(label,true,false) as Node3D
            if cheek_part != null:
                cheek_part.visible = stage < 3
        for label in ["G09PanelServicioTorreV9",
                "G09PlacaCentralGlacisV9","G09NeumaticosRuedasV9",
                "G09TornillosRuedasV9","G09CabezalPanoramicoCompactoV9",
                "G09PanoramicoCristalRebajadoV9","G09EstacionArmaRasanteV9",
                "G09CamaraArmaCompactaV9"]:
            var impact_part: Node3D = model.find_child(label,true,false) as Node3D
            if impact_part != null:
                impact_part.visible = stage < 4
    if model.get_meta("tarvoka_mbt_sculpted_v10",false):
        # New cast-welded hull/turret remain sealed at all HP levels, while
        # individual ceramic modules crack/detach on the exposed right side.
        # The older V7/V9 cheeks stay retired even after full restoration.
        for old in ["ModuloBlindajeCeramicoV7_1",
                "ModuloBlindajeCeramicoV7_-1",
                "GlacisCeramicoV7_1","GlacisCeramicoV7_-1",
                "G09PlacaCeramicaMandibulaV9_1",
                "G09PlacaCeramicaMandibulaV9_-1"]:
            var retired: Node3D = model.find_child(old,true,false) as Node3D
            if retired != null:
                retired.visible = false
        for part_name in ["G09V10MejillaCompuesta_1",
                "G09V10PlanchaMejillaExterior_1",
                "G09V10BlindajeLateral_1",
                "G09V10CosturaBlindaje_1_0","G09V10CosturaBlindaje_1_1",
                "G09V10CosturaBlindaje_1_2",
                "G09V10GlacisSuperior_1"]:
            var armored_part: Node3D = model.find_child(part_name,true,false) as Node3D
            if armored_part != null:
                armored_part.visible = stage < 3
        for part_name in ["G09V10ModuloAnteriorTorre","G09V10PanelServicioTecho",
                "G09V10PanelAnteriorTecho_1","G09V10PanelPosteriorTecho_1",
                "G09V10TornillosTecho",
                "G09V10BisagraPanelTecho","G09V10CubiertaMotorBlindada",
                "G09V10RejillaRefrigeracion_02","G09V10RejillaRefrigeracion_03"]:
            var damaged_part: Node3D = model.find_child(part_name,true,false) as Node3D
            if damaged_part != null:
                damaged_part.visible = stage < 4
    return true
