extends RefCounted
class_name TarvokaPowerPlant3DV2

# Additive V2 industrial sculpture. V1 remains intact and reusable.
# This is a native editable Godot 4.3 art pass only; electrical wires are
# real cylinders, NOT effects or a gameplay energy/supply system.
const Base=preload("res://scripts/ui/PowerPlant3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const TITLE="Central eléctrica"
const STAGE="CentralElectricaV2ConexionadoIndustrial"
const LEVEL_NAMES=["Puesto energético","Subestación regional","Central industrial"]
const DAMAGE_NAMES=["Intacta","Daños leves","Daños moderados","Daños críticos","Destruida"]
const DARK_STEEL=Color("#455760")
const STEEL=Color("#b2bdc0")
const ZINC=Color("#7c9699")
const CERAMIC=Color("#d0d9d0")
const COPPER=Color("#b87954")
const PIPING=Color("#6c8389")
const GLASS=Color("#6b98a4")
const RUST=Color("#855f52")
const CHAR=Color("#404347")
const NEUTRAL=Color("#72868e")

static func _box(parent: Node3D,label: String,pos: Vector3,
        dims: Vector3,color: Color,
        metallic: float=0.42,rough: float=0.58,
        angles: Vector3=Vector3.ZERO) -> void:
    Base._box(parent,label,pos,dims,color,metallic,rough,angles)

static func _cylinder(parent: Node3D,label: String,pos: Vector3,
        radius: float,length: float,color: Color,
        metallic: float=0.42,rough: float=0.56,
        angles: Vector3=Vector3.ZERO) -> void:
    Base._cylinder(parent,label,pos,radius,length,color,metallic,rough,angles)

static func _beam(parent: Node3D,label: String,
        a: Vector3,b: Vector3,thickness: float,color: Color) -> void:
    var delta: Vector3=b-a
    if delta.length()<0.01:
        return
    # Native 3D cylindrical connection, oriented with the true endpoints.
    var mesh:=Base._cylinder(parent,label,(a+b)*0.5,
        thickness,delta.length(),color,0.73,0.50)
    mesh.basis=Basis(Quaternion(Vector3.UP,delta.normalized()))

static func _control_room(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var width: float=3.8 if level==1 else 5.8 if level==2 else 8.0
    var depth: float=2.7 if level==1 else 3.85 if level==2 else 4.8
    var foot: float=8.0 if level==1 else 11.5 if level==2 else 15.5
    var height: float=2.22 if level==1 else 3.10 if level==2 else 4.38
    var z: float=-foot*0.22-depth*0.5-0.091
    if damage>=3:
        for side in [-1,1]:
            _box(stage,"MarcoSalaCaidoV2_%d" % side,
                Vector3(float(side)*width*0.20,0.21,z-0.36),
                Vector3(width*0.26,0.12,0.17),RUST,0.60,0.80,
                Vector3(0,float(side)*17.0,float(side)*-14.0))
        return
    # Three real recesses are visibly different from solid painted cubes.
    var panels: int=2 if level==1 else 3 if level==2 else 4
    for i in range(panels):
        var x: float=-width*0.39+(float(i)+0.5)*width*0.78/float(panels)
        if damage==2 and i==panels-1:
            _box(stage,"CubiertaControlRotaV2_%d" % i,
                Vector3(x,height*0.52,z-0.035),
                Vector3(width*0.13,0.36,0.04),RUST,0.51,0.77,
                Vector3(0,0,18))
            continue
        _box(stage,"MarcoControlV2_%d" % i,
            Vector3(x,height*0.52,z),
            Vector3(width*0.15,0.49,0.082),DARK_STEEL,0.71,0.49)
        _box(stage,"CristalInstrumentosV2_%d" % i,
            Vector3(x,height*0.52,z-0.048),
            Vector3(width*0.12,0.39,0.016),GLASS,0.05,0.20)
        _box(stage,"FranjaIdentidadV2_%d" % i,
            Vector3(x,height*0.81,z-0.034),
            Vector3(width*0.13,0.091,0.025),accent,0.26,0.41)
    _box(stage,"BandaFrenteSalaV2",
        Vector3(0,height*0.91,z-0.01),
        Vector3(width*0.87,0.11,0.10),accent,0.22,0.48)

static func _transformer_details(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>=3:
        return
    var footprint: float=8.0 if level==1 else 11.5 if level==2 else 15.5
    var number: int=1 if level==1 else 2 if level==2 else 4
    for i in range(number):
        var sx: float=(-0.65 if i%2==0 else 0.65)*(
            1.15 if level==1 else 2.02)
        var sz: float=footprint*0.17+(0.0 if i<2 else 1.9)
        var scale_factor: float=0.89 if level==1 else 1.0 if level==2 else 1.18
        var x: float=sx+0.50*scale_factor
        var y: float=0.02+1.15*scale_factor
        # Side-mounted real heat exchangers and insulated power conduit.
        for fin in range(4):
            _box(stage,"AletasLateralV2_%d_%d" % [i,fin],
                Vector3(x+0.13*scale_factor,y-0.34*scale_factor+
                    float(fin)*0.20*scale_factor,sz),
                Vector3(0.10,0.095,0.66)*scale_factor,ZINC,0.67,0.54)
        if damage<2 or i%2==0:
            _beam(stage,"ConductorBobinaV2_%d" % i,
                Vector3(sx,1.75*scale_factor,sz),
                Vector3(sx,2.32*scale_factor,sz+0.44*scale_factor),
                0.045,COPPER)
            _box(stage,"PlacaTensionV2_%d" % i,
                Vector3(sx,1.34*scale_factor,sz-0.48*scale_factor),
                Vector3(0.47,0.19,0.07)*scale_factor,accent,0.26,0.42)

static func _distribution_yard(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if level==1 or damage>=3:
        return
    var footprint: float=11.5 if level==2 else 15.5
    var gantry_height: float=3.5 if level==2 else 5.6
    var z: float=footprint*0.34
    var xs: Array[float]=[-footprint*0.30]
    if level==3:
        xs.append(footprint*0.31)
    for ix in range(xs.size()):
        var x: float=xs[ix]
        _box(stage,"PlacaPorticoColorV2_%d" % ix,
            Vector3(x,gantry_height-0.34,z-0.16),
            Vector3(0.83,0.15,0.09),accent,0.42,0.50)
        for phase in [-1,0,1]:
            var px: float=x+float(phase)*0.70
            # Phase-separated insulators; conductor itself is not painted.
            _cylinder(stage,"AisladorCeramicoV2_%d_%d" % [ix,phase],
                Vector3(px,gantry_height+0.56,z),
                0.12,0.29,CERAMIC,0.08,0.25)
            for disk in [0,1,2]:
                _cylinder(stage,
                    "AnilloAisladorV2_%d_%d_%d" % [ix,phase,disk],
                    Vector3(px,gantry_height+0.44+float(disk)*0.12,z),
                    0.145,0.042,ZINC,0.67,0.51)
            if damage<=1:
                _beam(stage,"BarraTrifasicaV2_%d_%d" % [ix,phase],
                    Vector3(px,gantry_height+0.74,z),
                    Vector3(px,gantry_height+0.74,z-1.20),
                    0.038,COPPER)
    if level==3 and damage<=1:
        for phase in [-1,0,1]:
            _beam(stage,"EnlacePorticosV2_%d" % phase,
                Vector3(xs[0]+float(phase)*0.70,gantry_height+0.78,z-1.20),
                Vector3(xs[1]+float(phase)*0.70,gantry_height+0.78,z-1.20),
                0.043,COPPER)

static func _industrial_finishes(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if level<3 or damage>=3:
        return
    var footprint: float=15.5
    for side in [-1,1]:
        var x: float=float(side)*footprint*0.31
        var z: float=-footprint*0.20
        for ring in range(4):
            _cylinder(stage,"AnilloTorreV2_%d_%d" % [side,ring],
                Vector3(x,0.64+float(ring)*0.74,z),
                1.085,0.055,ZINC,0.65,0.55)
        for fin in range(8):
            var rad: float=float(fin)*TAU/8.0
            _box(stage,"NervioTorreV2_%d_%d" % [side,fin],
                Vector3(x+cos(rad)*1.05,1.66,z+sin(rad)*1.05),
                Vector3(0.095,2.67,0.16),DARK_STEEL,0.69,0.48,
                Vector3(0,-rad_to_deg(rad),0))
        if damage<=1:
            _box(stage,"AcentoBordeTorreV2_%d" % side,
                Vector3(x,3.49,z),
                Vector3(1.22,0.12,0.095),accent,0.28,0.43)

static func _wreckage(stage: Node3D,damage: int) -> void:
    if damage<2:
        return
    for i in range(3 if damage==2 else 5 if damage==3 else 8):
        var shift: float=float(i)-3.5
        _box(stage,"ConductoRotoV2_%d" % i,
            Vector3(shift*0.48,0.17,1.8+float(i%3)*0.45),
            Vector3(0.075,0.19,0.72),CHAR if damage==4 else RUST,
            0.59,0.75,Vector3(24,float((i*41)%180),-17))
    if damage>=3:
        _box(stage,"ChapaTransformadorArrancadaV2",
            Vector3(1.34,0.16,1.02),Vector3(1.18,0.11,0.79),
            DARK_STEEL,0.60,0.73,Vector3(0,35,18))

static func build(level: int,faction: int=-1,damage: int=0) -> Node3D:
    var model: Node3D=Base.build(level,faction,damage)
    if model==null:
        return null
    var root: Node3D=Base._node(model,STAGE)
    var accent: Color=(
        Style.faction_color(faction) if faction>=0 else NEUTRAL)
    _control_room(root,level,damage,accent)
    _transformer_details(root,level,damage,accent)
    _distribution_yard(root,level,damage,accent)
    _industrial_finishes(root,level,damage,accent)
    _wreckage(root,damage)
    root.set_meta("visual_only",true)
    root.set_meta("no_gameplay_changes",true)
    model.set_meta("tarvoka_powerplant_stage",2)
    model.set_meta("tarvoka_powerplant_details_v2",true)
    model.set_meta("tarvoka_powerplant_final_approved",false)
    return model

static func mesh_count(model: Node) -> int:
    return Base.mesh_count(model)
