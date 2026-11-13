extends RefCounted
class_name TarvokaHeadquartersDetail3D

# Headquarters V3: large-scale military architecture first; microdetail second.
# Authored as native, reusable Godot 4.3 geometry for both web and Android.
# This is visual only: it does not change gameplay, tile occupancy or saves.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const STONE := Color("#c5c9c3")
const LIGHT := Color("#dce0db")
const ARMOR := Color("#435662")
const DEEP := Color("#1d303b")
const STEEL := Color("#76858b")
const GLASS := Color("#254b61")
const WARNING := Color("#e6bd62")
const CHAR := Color("#292c2b")
static var _emissive: Dictionary = {}
static var _dark_glass: StandardMaterial3D

static func _material_emission(color: Color, intensity: float = 1.8) -> StandardMaterial3D:
    var key := color.to_html(true)+str(intensity)
    if _emissive.has(key):
        return _emissive[key]
    var m := StandardMaterial3D.new()
    m.albedo_color = color.darkened(0.37)
    m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    m.emission_enabled = true
    m.emission = color
    m.emission_energy_multiplier = intensity
    m.metallic = 0.20
    m.roughness = 0.44
    _emissive[key] = m
    return m

static func _box(parent: Node3D, name: String,
        pos: Vector3, dims: Vector3, tint: Color,
        material: String = "steel", faction_panel: bool = false,
        angle: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return Finish._box(parent,name,pos,dims,tint,material,faction_panel,angle)

static func _beam(parent: Node3D, name: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> MeshInstance3D:
    return Finish._beam(parent,name,a,b,radius,color)

static func _prism(parent: Node3D, name: String, at: Vector3,
        dims: Vector3,cut: float,color: Color,
        material: String = "concrete",paint: bool = false) -> MeshInstance3D:
    return Finish._chamfer(parent,name,at,dims,cut,color,material,paint)

static func _glow(parent: Node3D, name: String,
        pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var part: MeshInstance3D = _box(parent,name,pos,size,color)
    part.material_override = _material_emission(color)
    return part

static func _count(node: Node) -> int:
    var n: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        n += _count(child)
    return n

static func _facade(parent: Node3D, level: int,
        roof: float,tint: Color) -> void:
    var shell := Finish._group(parent,"FachadaHeroV3")
    # Recessed dark gate and split diagonal armour cheek plates transform the
    # flat V2 rectangle into a recognizable command facility silhouette.
    _prism(shell,"EscudoDeAccesoBiselado",
        Vector3(0,1.42,-4.09),Vector3(2.88,2.45,0.47),0.31,ARMOR,"roof")
    _box(shell,"AberturaProfunda",Vector3(0,1.10,-4.36),
        Vector3(1.78,1.76,0.075),DEEP,"roof")
    _box(shell,"DoblePuertaAcorazadaIzquierda",
        Vector3(-0.43,0.97,-4.409),Vector3(0.76,1.42,0.055),ARMOR,"steel")
    _box(shell,"DoblePuertaAcorazadaDerecha",
        Vector3(0.43,0.97,-4.409),Vector3(0.76,1.42,0.055),ARMOR,"steel")
    _glow(shell,"LuzVerticalPuertaIzquierda",
        Vector3(-0.84,1.03,-4.43),Vector3(0.06,1.54,0.035),tint)
    _glow(shell,"LuzVerticalPuertaDerecha",
        Vector3(0.84,1.03,-4.43),Vector3(0.06,1.54,0.035),tint)
    _prism(shell,"AlfombraDeHormigonDeAcceso",
        Vector3(0,0.085,-4.69),Vector3(3.05,0.17,1.22),0.27,STONE)
    for side in [-1,1]:
        var s: float = float(side)
        _beam(shell,"ContrafuerteInclinadoV3_%s" % side,
            Vector3(s*2.80,0.28,-2.68),
            Vector3(s*3.10,roof-0.18,-2.63),0.16,ARMOR)
        _prism(shell,"TorrecillaEsquina_%s" % side,
            Vector3(s*4.82,1.39,-1.37),
            Vector3(1.36,2.75,1.68),0.24,ARMOR,"roof")
        _prism(shell,"CoronaTorrecilla_%s" % side,
            Vector3(s*4.82,2.80,-1.37),
            Vector3(1.57,0.23,1.91),0.23,DEEP,"roof")
        _box(shell,"VisorDeTorrecilla_%s" % side,
            Vector3(s*4.82,2.22,-2.26),
            Vector3(0.91,0.28,0.050),GLASS,"glass")
        _glow(shell,"TestigoTorrecilla_%s" % side,
            Vector3(s*4.82,2.88,-2.31),
            Vector3(0.54,0.07,0.045),tint)
        # Broad faction panel remains distinct from the neutral armour shell.
        _prism(shell,"PlacaFaccionTorrecilla_%s" % side,
            Vector3(s*4.82,1.07,-2.26),
            Vector3(0.60,0.30,0.075),0.07,tint,"steel",true)
    _prism(shell,"MarquesinaPrincipalV3",
        Vector3(0,2.71,-3.71),Vector3(3.67,0.32,1.94),
        0.35,DEEP,"roof")
    _box(shell,"MolduraMarquesinaColor",Vector3(0,2.71,-4.75),
        Vector3(3.06,0.12,0.05),tint,"steel",true)
    # Unique neutral insignia backing: actual official faction shield may be
    # attached later without rebuilding this geometry.
    _prism(shell,"SoporteEscudoDeFaccion",Vector3(0,2.34,-4.735),
        Vector3(0.92,0.45,0.060),0.11,ARMOR,"roof")
    _prism(shell,"MarcaDeFaccionModular",Vector3(0,2.36,-4.773),
        Vector3(0.56,0.18,0.040),0.052,tint,"steel",true)
    # Two wide technical cheek panels connect the flanking structures.
    for side in [-1,1]:
        var s: float = float(side)
        _prism(shell,"PlacaMandoFrontal_%s" % side,
            Vector3(s*2.01,roof*0.57,-2.54),
            Vector3(1.11,roof-0.84,0.29),0.14,STONE)
        for stripe in range(3):
            var sy: float = 0.72+float(stripe)*0.45
            _box(shell,"JuntaHorizontal_%s_%d" % [side,stripe],
                Vector3(s*2.01,sy,-2.715),
                Vector3(0.97,0.035,0.041),ARMOR)
    # New horizontal visual mass makes the building readable at map scale.
    _prism(shell,"VigaHorizontalDeMando",
        Vector3(0,roof-0.46,-2.55),
        Vector3(5.54,0.42,0.43),0.12,DEEP,"roof")
    _box(shell,"AcentoAltoDeFaccion",
        Vector3(0,roof-0.47,-2.82),
        Vector3(3.10,0.10,0.07),tint,"steel",true)
    if level >= 2:
        _prism(shell,"GaleriaDeMandoAvanzada",
            Vector3(0,roof-0.96,-2.69),
            Vector3(2.44,0.64,0.47),0.19,ARMOR,"roof")
        _box(shell,"PantallaPanoramicaAvanzada",
            Vector3(0,roof-0.92,-2.956),Vector3(1.98,0.33,0.039),
            GLASS,"glass")

static func _roof_crown(parent: Node3D, level: int,
        y: float,tint: Color) -> void:
    var roof := Finish._group(parent,"CoronaDeComandoV3")
    _prism(roof,"PabellonComandoElevado",
        Vector3(0,y+0.62,-0.44),
        Vector3(2.74,1.13,1.82),0.27,ARMOR,"roof")
    _prism(roof,"CubiertaPabellon",
        Vector3(0,y+1.28,-0.44),
        Vector3(3.18,0.22,2.08),0.29,DEEP,"roof")
    _box(roof,"VisorComandoPanoramico",
        Vector3(0,y+0.70,-1.39),
        Vector3(2.11,0.44,0.050),GLASS,"glass")
    for i in range(5):
        _box(roof,"DivisionVisor_%d" % i,
            Vector3(-0.86+float(i)*0.43,y+0.70,-1.435),
            Vector3(0.038,0.45,0.032),STONE)
    for side in [-1,1]:
        var s: float = float(side)
        _prism(roof,"BaseDeflector_%s" % side,
            Vector3(s*1.55,y+0.28,-0.40),
            Vector3(0.46,0.57,2.01),0.15,STEEL)
        _glow(roof,"TestigoMando_%s" % side,
            Vector3(s*1.58,y+1.19,-1.32),
            Vector3(0.22,0.11,0.045),tint)
    # Antenna height and reinforcement grow visibly with the building level.
    if level >= 2:
        for side in [-1,1]:
            var s: float = float(side)
            var bottom := Vector3(s*1.92,y+0.26,1.36)
            var top := Vector3(s*1.92,y+2.15,1.36)
            _beam(roof,"MastilNuevo_%s" % side,bottom,top,0.045,STEEL)
            _beam(roof,"VientoNuevo_%s_A" % side,
                Vector3(s*2.68,y+0.24,1.70),top,0.023,STONE)
            _beam(roof,"VientoNuevo_%s_B" % side,
                Vector3(s*1.31,y+0.24,2.04),top,0.023,STONE)
            _glow(roof,"BalizaNuevo_%s" % side,
                top,Vector3(0.15,0.15,0.15),WARNING)
    if level >= 3:
        # The third level's crown has a recognizable triangular frame.
        for side in [-1,1]:
            var s: float = float(side)
            _beam(roof,"ArcoSuperiorNivel3_%s" % side,
                Vector3(s*1.42,y+1.38,-0.65),
                Vector3(s*0.37,y+2.22,-0.65),0.085,STONE)
        _beam(roof,"VigaDeCoronaNivel3",
            Vector3(-0.37,y+2.22,-0.65),
            Vector3(0.37,y+2.22,-0.65),0.066,tint)

static func _site(parent: Node3D,level: int,tint: Color) -> void:
    var site := Finish._group(parent,"PatioOperativoV3")
    for side in [-1,1]:
        var s: float = float(side)
        _prism(site,"BarricadaCimentada_%s" % side,
            Vector3(s*2.90,0.33,-4.73),
            Vector3(0.83,0.47,1.65),0.16,STONE)
        _box(site,"MarcacionBarra_%s" % side,
            Vector3(s*2.90,0.36,-5.60),
            Vector3(0.56,0.17,0.050),tint,"steel",true)
        _beam(site,"FarolaIngreso_%s" % side,
            Vector3(s*3.51,0.17,-5.11),
            Vector3(s*3.51,2.18,-5.11),0.065,STEEL)
        _glow(site,"LuminariaEntrada_%s" % side,
            Vector3(s*3.51,2.18,-5.11),
            Vector3(0.40,0.15,0.39),WARNING)
        # Loading zones with directional painted parking numerals/lines.
        for bay in range(3):
            var z: float = 0.08+float(bay)*1.18
            _box(site,"MarcaDeBodega_%s_%d" % [side,bay],
                Vector3(s*5.55,0.12,z),
                Vector3(0.67,0.023,0.070),LIGHT,"roof")
    if level >= 2:
        for i in range(3):
            _prism(site,"PilaDeEquipos_%d" % i,
                Vector3(-4.61,0.48,2.38+float(i)*0.86),
                Vector3(1.06,0.96,0.66),0.18,ARMOR,"steel")
            _box(site,"PlacaDeServicio_%d" % i,
                Vector3(-4.61,0.72,2.02+float(i)*0.86),
                Vector3(0.56,0.21,0.044),tint,"steel",true)

static func _helipad(parent: Node3D,tint: Color) -> void:
    var node: Node = parent.find_child("Helipuerto",true,false)
    if not node is Node3D:
        return
    var pad: Node3D = node as Node3D
    var ring := Finish._group(pad,"SeguridadHelipuertoV3")
    # Welded reinforcing supports, landing strip lights and perimeter line.
    for corner in range(4):
        var sx: float = -1.0 if corner%2==0 else 1.0
        var sz: float = -1.0 if int(corner/2)==0 else 1.0
        _beam(ring,"PataAngular_%d" % corner,
            Vector3(sx*0.62,0.25,sz*0.48),
            Vector3(sx*1.31,2.13,sz*1.10),0.095,ARMOR)
        _glow(ring,"FaroCircular_%d" % corner,
            Vector3(sx*1.20,2.48,sz*1.17),
            Vector3(0.14,0.075,0.14),WARNING)
    _box(ring,"BordeFrentePista",
        Vector3(0,2.38,-1.51),Vector3(2.73,0.055,0.08),tint,"steel",true)
    _box(ring,"BordeFondoPista",
        Vector3(0,2.38,1.51),Vector3(2.73,0.055,0.08),tint,"steel",true)

static func _damage(parent: Node3D,level: int) -> void:
    var damage := Finish._group(parent,"ImpactosDeCombateV3")
    for i in range(4):
        var a := Vector3(-0.67+float(i)*0.29,1.43,-4.50)
        var b := a+Vector3(0.24,0.20-float(i%2)*0.31,-0.07)
        _beam(damage,"FisuraEnPortal_%d" % i,a,b,0.025,CHAR)
    _prism(damage,"FragmentoBlindajeDesprendido",
        Vector3(2.67,0.24,-4.51),
        Vector3(0.84,0.28,0.71),0.16,ARMOR)
    if level>=2:
        _beam(damage,"MastilRetorcidoNivelAlto",
            Vector3(-1.63,3.01+float(level)*0.9,1.50),
            Vector3(-2.92,2.55+float(level)*0.9,2.11),0.06,CHAR)

static func _ruins(parent: Node3D,tint: Color) -> void:
    var debris := Finish._group(parent,"RestosDeComandoV3")
    _prism(debris,"FachadaColapsadaHero",
        Vector3(-0.40,0.44,-3.05),
        Vector3(3.36,0.66,1.19),0.34,ARMOR,"concrete")
    for i in range(7):
        var s: float = -1.0 if i%2==0 else 1.0
        var x: float = -2.43+float(i)*0.83
        _beam(debris,"VigaSeccionada_%d" % i,
            Vector3(x,0.30,-1.82),
            Vector3(x+0.41*s,1.45+float(i%3)*0.24,-1.08),
            0.089,CHAR)
    _prism(debris,"RestoEscudoFaccion",
        Vector3(1.97,0.35,-4.15),
        Vector3(1.22,0.20,0.78),0.21,tint.darkened(0.45),
        "steel",true)

static func apply(model: Node3D, level: int, tint: Color, condition: String) -> void:
    if model == null:
        return
    var before: int = _count(model)
    if condition == "destruido":
        _ruins(model,tint)
    else:
        # Hide redundant V2 canopy so the V3 command gateway has one silhouette.
        Finish._hide(model,"ViseraDeMandoBiselada")
        Finish._hide(model,"PortalCristalBlindado")
        var structure: Node3D = model.find_child("EstructuraPrincipal",true,false) as Node3D
        if structure == null:
            return
        var y: float = 2.87+float(level-1)*0.91
        _facade(structure,level,y,tint)
        _roof_crown(structure,level,y,tint)
        _site(model,level,tint)
        _helipad(model,tint)
        if condition == "danado":
            _damage(model,level)
    model.set_meta("tarvoka_hq_visual_v3",true)
    model.set_meta("tarvoka_hq_v3_extra_meshes",_count(model)-before)
