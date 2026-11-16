extends RefCounted
class_name TarvokaInfantryBarracksFinishV2

# Native Godot 4.3 additive V2 pass. All changes remain on 3D geometry.
# Keep V1 stable for a true before/after toggle, preserve its THREE
# fundamentally different architectural silhouettes and five damage states.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV2AccesosVentanasTorresEntrenamiento"

const IRON=Color("#40545e")
const GALVANIZED=Color("#90a5a9")
const SHADOW=Color("#223740")
const ROUGH=Color("#927467")
const YELLOW=Color("#e4c16d")
const GLASS=Color("#426f7d")
const FABRIC=Color("#818c79")
const RUBBLE=Color("#82695b")

static func _modules(level: int) -> Array[Dictionary]:
    match level:
        1:
            return [{"tag":"BarracaUnPisoN1","x":-1.70,"z":1.95,
                "w":7.30,"d":4.28,"h":2.94,"floors":1,"primary":true}]
        2:
            return [
                {"tag":"BarracaPrincipalDosPisosN2","x":-2.06,
                    "z":2.03,"w":7.56,"d":4.54,"h":4.85,
                    "floors":2,"primary":true},
                {"tag":"AlaInstruccionN2","x":3.36,
                    "z":1.40,"w":3.42,"d":5.39,"h":3.09,
                    "floors":1,"primary":false}]
        3:
            return [
                {"tag":"ComandoCentralTresPisosN3","x":0.0,
                    "z":2.62,"w":8.56,"d":3.48,"h":6.88,
                    "floors":3,"primary":true},
                {"tag":"AlaOesteDosPisosN3","x":-4.58,
                    "z":-0.20,"w":3.01,"d":6.21,"h":4.86,
                    "floors":2,"primary":false},
                {"tag":"AlaEsteDosPisosN3","x":4.58,
                    "z":-0.20,"w":3.01,"d":6.21,"h":4.86,
                    "floors":2,"primary":false}]
    return []

static func _part(parent: Node3D,label: String,at: Vector3,
        dimensions: Vector3,tint: Color,metal: float=0.22) -> void:
    Base._box(parent,label,at,dimensions,tint,metal)

static func _segment(parent: Node3D,label: String,
        a: Vector3,b: Vector3,radius: float,tint: Color) -> void:
    var axis: Vector3=b-a
    if axis.length()<0.002:
        return
    var cylinder: MeshInstance3D=Base._cylinder(
        parent,label,(a+b)*0.5,radius,axis.length(),tint)
    cylinder.basis=Basis(Quaternion(Vector3.UP,axis.normalized()))

static func _access(stage: Node3D,module: Dictionary,damage: int,
        accent: Color) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var front: float=z-d*0.5
    var main: bool=bool(module["primary"])
    var doorway: float=1.70 if main else 1.30
    var frame_width: float=doorway*0.88
    var metals: Color=ROUGH if damage>=2 else IRON
    var root: Node3D=Base._group(stage,"AccesoReal_"+tag)
    if damage>=3:
        # Broken entrance stays broken; no recreated intact doors.
        _part(root,"UmbralDestrozado",
            Vector3(x,0.15,front-0.34),
            Vector3(doorway*1.22,0.20,0.55),ROUGH)
        return
    for side in [-1,1]:
        var dx: float=float(side)*frame_width*0.5
        _part(root,"JambaAcero_%d" % side,
            Vector3(x+dx,1.08,front-0.21),
            Vector3(0.09,2.14,0.16),metals,0.43)
    _part(root,"DintelMarcoAcceso",
        Vector3(x,2.17,front-0.20),
        Vector3(frame_width+0.18,0.10,0.15),metals,0.42)
    _part(root,"GuardapolvoPuerta",
        Vector3(x,0.22,front-0.26),
        Vector3(frame_width-0.16,0.13,0.09),
        GALVANIZED if damage<=1 else ROUGH)
    for side in [-1,1]:
        _part(root,"PanelBajoPuerta_%d" % side,
            Vector3(x+float(side)*doorway*0.20,0.43,front-0.058),
            Vector3(doorway*0.33,0.55,0.034),
            SHADOW if damage<=1 else ROUGH,0.38)
    # Door handles are truly visible on the exterior side.
    _part(root,"ManijaYChapa",
        Vector3(x+doorway*0.20,1.03,front-0.116),
        Vector3(0.08,0.13,0.08),YELLOW,0.47)
    # Entrance stair and threshold stop before the main formation lanes.
    _part(root,"EscalonInferior",
        Vector3(x,0.08,front-0.59),
        Vector3(doorway+0.65,0.13,0.48),Base.CONCRETE)
    _part(root,"EscalonSuperior",
        Vector3(x,0.17,front-0.32),
        Vector3(doorway+0.40,0.14,0.32),Base.PALE)
    _part(root,"PlacaIdentificacionTecnica",
        Vector3(x,2.72,front-0.22),
        Vector3(doorway+0.55,0.20,0.05),
        accent if damage==0 else ROUGH,0.16)
    if main and damage<=1:
        for side in [-1,1]:
            _part(root,"LuzMarquesina_%d" % side,
                Vector3(x+float(side)*(doorway*0.43),2.49,front-0.63),
                Vector3(0.16,0.09,0.18),YELLOW,0.10)
    if h>=4.0 and damage==0:
        _part(root,"IdentidadNivelAlto",
            Vector3(x,h-0.40,front-0.212),
            Vector3(doorway+0.85,0.12,0.045),accent)

static func _facade(stage: Node3D,module: Dictionary,damage: int) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var front: float=z-d*0.5
    var floors: int=int(module["floors"])
    var door_w: float=1.70 if bool(module["primary"]) else 1.30
    var segment: float=(w-door_w)*0.5
    var facade: Node3D=Base._group(stage,"AcabadosFachada_"+tag)
    if damage>=3:
        _part(facade,"BordeFracturaPrincipal",
            Vector3(x+w*0.18,2.15,front-0.15),
            Vector3(w*0.22,0.18,0.13),ROUGH,0.26)
        return
    var color: Color=ROUGH if damage==2 else GALVANIZED
    # Thin vertical mullions overlay genuine V1 glass; they never fill
    # missing windows or create unbroken opaque walls.
    for f in range(floors):
        var sill: float=0.70+float(f)*2.22
        if sill+0.90>=h:
            continue
        for side in [-1,1]:
            var xpos: float=x+float(side)*(door_w*0.5+segment*0.54)
            var width: float=minf(1.0,segment*0.48)
            var face_z: float=front-0.261
            if damage<=1:
                _part(facade,"MontanteVentana_%d_%d" % [f,side],
                    Vector3(xpos,sill+0.48,face_z),
                    Vector3(0.042,0.80,0.035),IRON,0.41)
                _part(facade,"TravesanoVentana_%d_%d" % [f,side],
                    Vector3(xpos,sill+0.48,face_z-0.011),
                    Vector3(width+0.05,0.036,0.04),IRON,0.39)
            if damage==2:
                _part(facade,"AlfeizarTorcido_%d_%d" % [f,side],
                    Vector3(xpos+0.08,sill-0.01,face_z),
                    Vector3(width+0.09,0.065,0.14),ROUGH)
    # Concrete corner pilasters and realistic sill strips.
    for side in [-1,1]:
        _part(facade,"PerfilEsquina_%d" % side,
            Vector3(x+float(side)*(w*0.5-0.19),h*0.5,front-0.09),
            Vector3(0.14,h-0.10,0.21),color,0.30)
    if damage<=1:
        _part(facade,"CanalonTechoFrontal",
            Vector3(x,h+0.18,front-0.19),
            Vector3(w+0.04,0.07,0.12),GALVANIZED,0.34)
        for side in [-1,1]:
            _part(facade,"Bajante_%d" % side,
                Vector3(x+float(side)*(w*0.5-0.12),h*0.48,
                    front-0.24),
                Vector3(0.065,h-0.22,0.095),STEEL_COLOR(),0.39)

static func STEEL_COLOR() -> Color:
    return IRON

static func _tower(stage: Node3D,label: String,x: float,z: float,
        height: float,damage: int,accent: Color) -> void:
    var feature: Node3D=Base._group(stage,"Detalles_"+label)
    if damage>=3:
        _part(feature,"SoporteDeTorreTorcido",
            Vector3(x+0.17,0.38,z-0.25),
            Vector3(0.17,0.73,0.28),ROUGH)
        return
    # Cross-braced actual tower stilts, not four unsupported vertical pipes.
    for side_x in [-1,1]:
        for side_z in [-1,1]:
            var x0: float=x+float(side_x)*0.56
            var z0: float=z+float(side_z)*0.56
            _segment(feature,"ArriostreTorre_%d_%d" % [side_x,side_z],
                Vector3(x0,0.64,z0),
                Vector3(x0,height*0.75,z-float(side_z)*0.56),
                0.045,ROUGH if damage==2 else IRON)
    # Actual ladder against the back face; finishes below the platform.
    for side in [-1,1]:
        _part(feature,"GuiaEscalera_%d" % side,
            Vector3(x+float(side)*0.33,height*0.47,z+0.94),
            Vector3(0.075,height*0.91,0.08),
            ROUGH if damage==2 else GALVANIZED,0.43)
    var rung_count: int=9 if height<4.0 else 12
    for i in range(rung_count):
        var rung_y: float=0.48+float(i)*(height-0.95)/float(rung_count-1)
        _part(feature,"PeldañoEscalera_%d" % i,
            Vector3(x,rung_y,z+0.955),
            Vector3(0.71,0.055,0.09),
            ROUGH if damage==2 else GALVANIZED,0.45)
    if damage<=1:
        _part(feature,"FrontalCristalCabina",
            Vector3(x,height+0.72,z-0.80),
            Vector3(1.46,0.80,0.07),GLASS,0.18)
        _part(feature,"MontanteCabina",
            Vector3(x,height+0.73,z-0.86),
            Vector3(0.065,0.82,0.11),IRON,0.37)
        _part(feature,"PlacaIdentidadTorre",
            Vector3(x,height+1.22,z-0.93),
            Vector3(1.31,0.12,0.07),accent,0.13)

static func _training(stage: Node3D,level: int,damage: int) -> void:
    var field: Node3D=Base._group(stage,"InstruccionTacticaV2")
    if damage>=3:
        for i in range(2):
            _part(field,"RuinaPistaInstruccion_%d" % i,
                Vector3(-6.56+float(i)*0.67,0.20,-3.8),
                Vector3(0.55,0.22,0.28),RUBBLE)
        return
    # Lane markings consistent across all tiers.
    for side in [-1,1]:
        _part(field,"BandaLateralPista_%d" % side,
            Vector3(-6.0+float(side)*1.23,0.091,-3.55),
            Vector3(0.075,0.014,4.01),YELLOW,0.1)
    var obstacle_count: int=2 if level==1 else 4 if level==2 else 6
    for i in range(obstacle_count):
        var z: float=-5.11+float(i)*0.7
        var x: float=-6.60+float(i%2)*1.22
        # Wooden-looking top guard on each V1 low training barrier.
        if damage<=1:
            _part(field,"BarandillaObstaculo_%d" % i,
                Vector3(x,0.56,z),
                Vector3(0.72,0.11,0.30),FABRIC)
    if level>=2:
        # A more advanced obstacle group differentiates N2 from N1.
        for i in range(2):
            var z: float=-4.25+float(i)*1.40
            for side in [-1,1]:
                _part(field,"PilarSalto_%d_%d" % [i,side],
                    Vector3(-6.03+float(side)*0.72,0.43,z),
                    Vector3(0.12,0.83,0.12),ROUGH if damage==2 else IRON)
            _part(field,"ListonSalto_%d" % i,
                Vector3(-6.03,0.83,z),
                Vector3(1.62,0.09,0.16),
                ROUGH if damage==2 else GALVANIZED,0.42)
    if level==3 and damage<=1:
        # Distinct urban cover course—not a new producing installation.
        for i in range(2):
            _part(field,"CoberturaPracticaN3_%d" % i,
                Vector3(-7.0+float(i)*1.63,0.66,-0.66),
                Vector3(0.67,1.25,0.28),Base.CONCRETE)
        _part(field,"TarimaInstruccionSuperiorN3",
            Vector3(-6.07,0.20,-0.50),
            Vector3(2.36,0.18,0.38),Base.STEEL,0.33)

static func _rubble(stage: Node3D,damage: int) -> void:
    if damage<2:
        return
    var fragments: Node3D=Base._group(stage,"RestosEstructuralesIntegradosV2")
    var amount: int=3 if damage==2 else 8 if damage==3 else 0
    for i in range(amount):
        # Add modest broken pieces to roofs/courtyard, never intact elements.
        _part(fragments,"FragmentoDanio_%d" % i,
            Vector3(-3.75+float(i%4)*2.2,0.16,
                -0.75+float(i/4)*2.1),
            Vector3(0.36+float(i%2)*0.14,0.17,0.53),
            RUBBLE if i%2==0 else ROUGH)

static func apply(model: Node3D,level: int,faction: int,
        damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if int(model.get_meta("visual_level",-1))!=level or             int(model.get_meta("visual_faction",-1))!=faction or             int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    if model.has_node(STAGE_NAME):
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    var accent: Color=Style.faction_color(faction)
    if damage==4:
        # Fully destroyed V1 has ONLY foundation/debris. V2 cannot rebuild it.
        stage.set_meta("infantry_v2_ruins_only",true)
        stage.set_meta("infantry_v2_modules",0)
        return true
    for module in _modules(level):
        _access(stage,module,damage,accent)
        _facade(stage,module,damage)
    if level==2:
        _tower(stage,"TorreSupervisionNivel2",
            5.67,-2.77,3.72,damage,accent)
    elif level==3:
        _tower(stage,"TorreOesteNivel3",
            -6.47,3.65,4.93,damage,accent)
        _tower(stage,"TorreEsteNivel3",
            6.47,3.65,4.93,damage,accent)
    _training(stage,level,damage)
    _rubble(stage,damage)
    stage.set_meta("infantry_v2_ruins_only",false)
    stage.set_meta("infantry_v2_modules",_modules(level).size())
    stage.set_meta("infantry_v2_level",level)
    stage.set_meta("infantry_v2_damage",damage)
    stage.set_meta("infantry_v2_preserves_v1_massing",true)
    return true

static func added_meshes(model: Node3D) -> int:
    var stage: Node3D=model.get_node_or_null(STAGE_NAME) as Node3D
    return 0 if stage==null else Base.mesh_count(stage)
