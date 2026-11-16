extends RefCounted
class_name TarvokaHeadquartersReadabilityV9

# TARVOKA HQ V9 · tactical-distance architecture on top of the approved V8.
# Adds real silhouettes, cantilevers and supporting structures rather than
# painting fake shadows onto the building. Visual-only, no gameplay mutation.
const Finish = preload("res://scripts/ui/HeadquartersFinish3D.gd")
const PBR = preload("res://scripts/ui/HeadquartersFinishV8.gd")
const STEEL := Color("#7e939f")
const SHADE := Color("#233846")
const ALLOY := Color("#b7c6cc")
const LIGHT := Color("#eed29b")
const SOOT := Color("#343333")

static func _group(parent: Node3D, label: String) -> Node3D:
    return Finish._group(parent,label)

static func _box(parent: Node3D, label: String, at: Vector3,
        size: Vector3, color: Color, style: String = "brushed_alloy",
        rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
    return PBR._box(parent,label,at,size,color,style,rotation)

static func _beam(parent: Node3D, label: String, a: Vector3,
        b: Vector3, radius: float, color: Color,
        style: String = "brushed_alloy") -> MeshInstance3D:
    return PBR._beam(parent,label,a,b,radius,color,style)

static func _shell(parent: Node3D,label: String,at: Vector3,
        dims: Vector3, bevel: float,color: Color,
        style: String = "industrial_roof",
        faction_panel: bool = false) -> MeshInstance3D:
    var part: MeshInstance3D = Finish._chamfer(
        parent,label,at,dims,bevel,color,"roof",faction_panel)
    part.material_override = PBR._material(color,style)
    return part

static func _facade_strengthening(model: Node3D, level: int,tint: Color) -> void:
    var structure := _group(model,"ArmazonesLegiblesDeFachadaV9")
    var top: float = 2.87+0.91*float(level-1)
    for side in [-1,1]:
        var sign: float = float(side)
        # Two real structural mullions flank the central control block and
        # frame the approved crest without blocking its front-facing artwork.
        _shell(structure,"MachonVerticalFaccion_%s" % side,
            Vector3(sign*2.58,top*0.51,-2.87),
            Vector3(0.40,top*0.89,0.30),0.07,
            tint.darkened(0.24),"brushed_alloy",true)
        _shell(structure,"EspinaTorcidaMachon_%s" % side,
            Vector3(sign*2.72,top*0.70,-3.067),
            Vector3(0.13,top*0.52,0.09),0.035,STEEL)
        _beam(structure,"ContrafuerteDiagonalExterno_%s" % side,
            Vector3(sign*2.94,0.35,-2.87),
            Vector3(sign*3.50,2.72,-2.28),
            0.125,SHADE)
        _beam(structure,"RibeteContrafuerte_%s" % side,
            Vector3(sign*2.98,0.44,-2.987),
            Vector3(sign*3.53,2.70,-2.41),
            0.038,ALLOY)
        # Bright sloped canopy edges are legible even at a distant zoom.
        _shell(structure,"AleronAngularDeFaccion_%s" % side,
            Vector3(sign*3.97,3.11,-1.52),
            Vector3(2.20,0.19,0.65),0.12,
            tint.darkened(0.31),"industrial_roof",true)
        _box(structure,"FranjaHorizontalLuzAla_%s" % side,
            Vector3(sign*3.97,3.215,-1.85),
            Vector3(1.84,0.055,0.075),LIGHT)
        # Two deeply projecting side piers give the roof a coherent military
        # rhythm and keep clear of the official central emblem.
        for pos in [-1.0,1.0]:
            var at_x: float = sign*(3.93+pos*0.75)
            _shell(structure,"MureteTécnicoAla_%s_%s" % [side,pos],
                Vector3(at_x,3.015,1.83),
                Vector3(0.26,0.57,0.95),0.05,SHADE)
            _box(structure,"CoronaMureteFaccion_%s_%s" % [side,pos],
                Vector3(at_x,3.35,1.84),
                Vector3(0.27,0.095,0.91),tint.darkened(0.14),
                "brushed_alloy")
        _beam(structure,"TiranteDeAzoteaExterior_%s" % side,
            Vector3(sign*3.16,2.83,2.15),
            Vector3(sign*4.70,3.24,2.15),
            0.078,ALLOY)
    # Twin vertical blades directly on the command tower, without impinging
    # the radar bowl to the rear or the front faction shield.
    for side in [-1,1]:
        var sx: float = float(side)
        _shell(structure,"AletaAltaPuenteComando_%s" % side,
            Vector3(sx*1.24,top+2.08,-1.71),
            Vector3(0.21,0.88,1.06),0.08,SHADE)
        _box(structure,"RibeteDeAletaSuperior_%s" % side,
            Vector3(sx*1.24,top+2.55,-1.71),
            Vector3(0.18,0.086,0.88),tint.darkened(0.15))
        _beam(structure,"SoporteAletaTorre_%s" % side,
            Vector3(sx*1.24,top+1.72,-1.32),
            Vector3(sx*1.24,top+2.15,-1.65),0.052,ALLOY)
    _box(structure,"CintaDeCubiertaElevada",
        Vector3(0,top+1.71,-3.21),
        Vector3(2.55,0.10,0.11),LIGHT)

static func _site_finishing(model: Node3D,tint: Color) -> void:
    var site := _group(model,"InstalacionYAccesoLecturaV9")
    # Physical low retaining walls with accessible front gap; no gameplay
    # collision or passability is added by this visual-only decoration.
    for side in [-1,1]:
        var sx: float = float(side)
        _shell(site,"JardineraBlindadaDeAcceso_%s" % side,
            Vector3(sx*2.12,0.36,-5.27),
            Vector3(1.40,0.51,0.61),0.13,
            STEEL,"blast_concrete")
        _box(site,"CintaLuminosaJardinera_%s" % side,
            Vector3(sx*2.12,0.64,-5.58),
            Vector3(1.16,0.055,0.050),tint.darkened(0.14))
        _box(site,"BordeDePasoVehicular_%s" % side,
            Vector3(sx*3.12,0.13,-5.30),
            Vector3(0.095,0.08,1.35),ALLOY)
        # Corner lamp is deliberately small and stays away from rotor area.
        _beam(site,"MastilDeAcceso_%s" % side,
            Vector3(sx*5.70,0.19,-5.45),
            Vector3(sx*5.70,2.28,-5.45),
            0.062,SHADE)
        _shell(site,"LuminariaAcceso_%s" % side,
            Vector3(sx*5.70,2.35,-5.45),
            Vector3(0.31,0.16,0.33),0.045,LIGHT,"brushed_alloy")
    _box(site,"GuiaDeAproximaciónCentral",
        Vector3(0,0.120,-5.55),
        Vector3(0.13,0.026,0.72),LIGHT)

static func _near_detail(model: Node3D,level: int) -> void:
    var near := _group(model,"DetalleCercanoV9")
    var y: float = 2.87+0.91*float(level-1)
    for side in [-1,1]:
        var sx: float = float(side)
        for k in range(8):
            _box(near,"PlacaFijacionCubierta_%s_%02d" % [side,k],
                Vector3(sx*(3.03+float(k)*0.28),3.225,-1.88),
                Vector3(0.068,0.031,0.042),STEEL)
        for k in range(6):
            _box(near,"RemacheAletaComando_%s_%02d" % [side,k],
                Vector3(sx*1.25,y+1.94+float(k)*0.088,-2.253),
                Vector3(0.035,0.035,0.019),ALLOY)
    near.visible = false

static func _damaged(model: Node3D,level: int) -> void:
    var damage := _group(model,"FallasEstructuralesVisiblesV9")
    var top: float = 2.87+0.91*float(level-1)
    var fin: MeshInstance3D = model.find_child(
        "AletaAltaPuenteComando_-1",true,false) as MeshInstance3D
    if fin != null:
        fin.visible = false
    _beam(damage,"AletaDeTorreVencida",
        Vector3(-1.30,top+1.75,-1.75),
        Vector3(-2.18,top+2.17,-1.29),
        0.14,SOOT,"heat_oxidation")
    _box(damage,"PanelDeFaccionArrancado",
        Vector3(-3.84,2.51,-2.28),
        Vector3(0.83,0.11,0.40),SOOT,"heat_oxidation",
        Vector3(14,-5,19))
    _beam(damage,"CorteContrafuerte",
        Vector3(3.33,1.40,-2.57),
        Vector3(3.68,1.73,-2.36),
        0.055,SOOT,"heat_oxidation")

static func _destroyed(model: Node3D,tint: Color) -> void:
    var fragments := _group(model,"RestosDeSiluetaComandoV9")
    # Only broken recognisable roof/facade members remain on the rubble.
    _box(fragments,"AleronDeTejadoCaido",
        Vector3(-3.15,0.38,-2.82),
        Vector3(2.23,0.17,0.62),
        tint.darkened(0.50),"heat_oxidation",
        Vector3(12,-19,21))
    _box(fragments,"AletaComandoDestruida",
        Vector3(1.51,0.46,-2.98),
        Vector3(0.25,0.77,0.94),SOOT,"heat_oxidation",
        Vector3(26,38,-12))
    _beam(fragments,"RefuerzoExternoPartido",
        Vector3(2.62,0.27,-3.52),
        Vector3(3.24,0.94,-2.79),0.11,STEEL)

static func set_near_detail(model: Node3D, near: bool) -> void:
    if model == null:
        return
    var fine: Node3D = model.find_child("DetalleCercanoV9",true,false) as Node3D
    if fine != null:
        fine.visible = near

static func apply(model: Node3D,level: int,tint: Color,condition: String) -> void:
    if model == null or model.get_meta("tarvoka_hq_visual_v9",false):
        return
    if not model.get_meta("tarvoka_hq_visual_v8",false):
        return
    model.set_meta("tarvoka_hq_visual_v9",true)
    model.set_meta("tarvoka_hq_v9_architecture_only",true)
    if condition == "destruido":
        _destroyed(model,tint)
        return
    _facade_strengthening(model,level,tint)
    _site_finishing(model,tint)
    _near_detail(model,level)
    if condition == "danado":
        _damaged(model,level)
    set_near_detail(model,false)
