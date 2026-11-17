extends RefCounted
class_name TarvokaCivilianCityArchitecturalDetailV21

# V21: architectural detailing on the EXISTING civilian city.
# Real volumetric joinery, openings, glazing, roof edges and damaged parts.
# This is a VISUAL-ONLY ART STAGE, not final approval or gameplay changes.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V20=preload("res://scripts/ui/CivilianCityExteriorFinishV20.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV21CarpinteriaVentanasCubiertas"

const CLAY=Color("#b57a5a")
const AGED_CLAY=Color("#8c5d4d")
const WOOD=Color("#86684f")
const DARK_WOOD=Color("#5a483c")
const BRICK=Color("#9d7665")
const STONE=Color("#cabfae")
const LIME=Color("#ded0b8")
const ALUMINUM=Color("#84979b")
const STEEL=Color("#596d73")
const COPPER=Color("#897b5b")
const GLASS=Color("#668d9a")
const BROKEN_GLASS=Color("#3c5963")
const SOOT=Color("#3f4749")
const DUST=Color("#85796c")
const RUBBLE=Color("#726860")

static func _part(parent: Node3D,n: String,at: Vector3,
        size: Vector3,color: Color,finish: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,n,at,size,color)
    mesh.material_override=V9._finish(color,finish)
    return mesh

static func _cylinder(parent: Node3D,n: String,at: Vector3,
        radius: float,height: float,color: Color) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._cylinder(parent,n,at,radius,height,color,8)
    mesh.material_override=V9._finish(color,"steel")
    return mesh

static func _palette(level: int) -> Dictionary:
    if level==1:
        return {"frame":WOOD,"trim":LIME,"roof":CLAY,
            "hardware":COPPER,"finish":"stone"}
    if level==2:
        return {"frame":STONE,"trim":BRICK,"roof":STONE,
            "hardware":STEEL,"finish":"stone"}
    return {"frame":ALUMINUM,"trim":STEEL,"roof":ALUMINUM,
        "hardware":STEEL,"finish":"steel"}

static func _door_joints(parent: Node3D,tag: String,x: float,
        z: float,w: float,d: float,level: int,damage: int) -> void:
    var door:=V1._group(parent,"V21_PuertaConVolumen_"+tag)
    var style: Dictionary=_palette(level)
    var front: float=z-d*0.5-0.24
    var back: float=z+d*0.5+0.24
    var fw: float=minf(w*0.31,0.94)
    # Work around the EXISTING V1/V10/V17 doors: only a shallow
    # extruded frame, sill, handle and a real lintel, not a second door.
    for side_face in [-1,1]:
        var face: float=float(side_face)
        var at_z: float=front if side_face==-1 else back
        if tag=="Ayuntamiento" and side_face==1:
            # South-facing public portal is already finished by V10;
            # omit V21 frame to avoid hiding its metal/glass doors.
            continue
        if damage>=3:
            var fallen:=_part(door,
                "V21_DintelCaido_%s_%d" % [tag,side_face],
                Vector3(x,0.16,at_z),
                Vector3(fw+0.28,0.19,0.29),RUBBLE)
            fallen.rotation_degrees.y=12.0*face
            continue
        var door_tint: Color=style["frame"]
        if damage==2:
            door_tint=DUST
        for edge in [-1,1]:
            var xx: float=x+float(edge)*(fw*0.5+0.065)
            var frame:=_part(door,
                "V21_JambaPuerta_%s_%d_%d" % [tag,side_face,edge],
                Vector3(xx,0.96,at_z),
                Vector3(0.12,1.91,0.22),door_tint,str(style["finish"]))
            if damage==2 and edge==1:
                frame.rotation_degrees.z=-11.0
        _part(door,"V21_DintelPuerta_%s_%d" % [tag,side_face],
            Vector3(x,1.93,at_z),
            Vector3(fw+0.24,0.15,0.25),door_tint,str(style["finish"]))
        _part(door,"V21_PeldañoPuerta_%s_%d" % [tag,side_face],
            Vector3(x,0.11,at_z+face*0.23),
            Vector3(fw+0.32,0.15,0.42),STONE)
        if damage<=1:
            _part(door,"V21_Tirador3DPuerta_%s_%d" % [tag,side_face],
                Vector3(x+fw*0.24,1.09,at_z+face*0.13),
                Vector3(0.065,0.24,0.065),
                style["hardware"],"steel")
            if level==1:
                _part(door,"V21_TravesañoMadera_%s_%d" % [tag,side_face],
                    Vector3(x,1.58,at_z+face*0.075),
                    Vector3(fw*0.75,0.07,0.075),DARK_WOOD)

static func _window_glazing(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    if damage>=3:
        return
    var group:=V1._group(parent,"V21_BastidoresVentanas_"+tag)
    var style: Dictionary=_palette(level)
    var top_limit: float=float(floors)*2.10+0.21
    # Each opening is on the same front and rear planes as V1 and V17;
    # no larger pane covers the approved doors or existing windows.
    for floor in range(floors):
        var yy: float=0.90+float(floor)*2.10
        if yy+0.43>=top_limit:
            continue
        for face in [-1,1]:
            var signed: float=float(face)
            var outer_z: float=(z-d*0.5-0.22 if face==-1
                else z+d*0.5+0.22)
            for side in [-1,1]:
                if damage==2 and (floor+side+face+8)%3==0:
                    continue
                var sx: float=x+float(side)*w*0.23
                var tint: Color=style["frame"]
                # Glazing remains inset inside the existing pane width:
                # two narrow mullions and a single horizontal crosspiece.
                _part(group,
                    "V21_MontanteVentana_%s_%d_%d_%d" %
                    [tag,floor,face,side],
                    Vector3(sx,yy,outer_z),
                    Vector3(0.055,0.71,0.07),tint,str(style["finish"]))
                _part(group,
                    "V21_ImpostaVentana_%s_%d_%d_%d" %
                    [tag,floor,face,side],
                    Vector3(sx,yy+0.04,outer_z),
                    Vector3(0.47,0.055,0.073),tint,str(style["finish"]))
                if damage==1 and floor==floors-1:
                    _part(group,
                        "V21_VidrioOscurecido_%s_%d_%d_%d" %
                        [tag,floor,face,side],
                        Vector3(sx-0.16,yy-0.13,outer_z+signed*0.039),
                        Vector3(0.11,0.13,0.025),BROKEN_GLASS,"glass")
                if damage==2 and floor==0:
                    _part(group,
                        "V21_CristalAstillado_%s_%d_%d" % [tag,face,side],
                        Vector3(sx+0.12,0.21,outer_z+signed*0.18),
                        Vector3(0.25,0.06,0.16),BROKEN_GLASS,"glass")

static func _roof_hardware(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    var group:=V1._group(parent,"V21_UnionesTejado_"+tag)
    var h: float=float(floors)*2.10+0.21
    var style: Dictionary=_palette(level)
    if damage>=3:
        # Dry, material-specific roof debris, NO floating roof ridges.
        for i in range(3):
            var chip:=V14._sloped_slab(group,
                "V21_TejadoHundido_%s_%d" % [tag,i],
                Vector3(x+(float(i)-1.0)*w*0.24,
                    0.13,z+((float(i)%2.0)-0.5)*d*0.55),
                0.45,0.38,0.08,0.18,
                CLAY if level==1 else BRICK if level==2 else STEEL)
            chip.rotation_degrees.y=float(i)*19.0
            chip.material_override=V9._finish(
                CLAY if level==1 else BRICK if level==2 else STEEL,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
        return
    if level==1:
        # Small ridge tiles sit on the existing V2/V8 wood-and-ceramic roof.
        for i in range(4):
            if damage==2 and i in [1,3]:
                continue
            _part(group,"V21_CumbreraCeramica_%s_%d" % [tag,i],
                Vector3(x,h+0.68,z+(float(i)-1.5)*d*0.21),
                Vector3(0.18,0.10,d*0.20),
                AGED_CLAY if damage>=1 else CLAY,"ceramic")
    elif level==2:
        # Parapet cap and periodic masonry joints, not a flat fake facade.
        for side in [-1,1]:
            if damage==2 and side==1:
                continue
            _part(group,"V21_CubremuroPiedra_%s_%d" % [tag,side],
                Vector3(x+float(side)*w*0.42,h+0.43,z),
                Vector3(0.23,0.14,d*0.76),STONE)
    else:
        # Low air-handling shroud with visible louvers below an existing roof.
        var roof_unit:=V1._group(group,"V21_AireAcondicionado_"+tag)
        _part(roof_unit,"V21_EquipoClima",
            Vector3(x,h+0.40,z+d*0.15),
            Vector3(0.72,0.40,0.65),STEEL,"steel")
        if damage<2:
            for i in range(3):
                _part(roof_unit,"V21_Respiradero_%d" % i,
                    Vector3(x-0.21+float(i)*0.20,
                        h+0.63,z+d*0.15),
                    Vector3(0.095,0.055,0.49),ALUMINUM,"steel")
    # Physically attached downpipes and short gutter outlets on the
    # existing rear elevation. D2 loses the upper/downhill segment.
    for side in [-1,1]:
        if damage==2 and side==1:
            continue
        var sx: float=x+float(side)*(w*0.5+0.20)
        var pipe_height: float=h*0.72 if damage==2 else h-0.16
        _cylinder(group,"V21_BajantePluvial_%s_%d" % [tag,side],
            Vector3(sx,pipe_height*0.5,z+d*0.5+0.11),
            0.053,pipe_height,style["hardware"])
        _part(group,"V21_BocaBajante_%s_%d" % [tag,side],
            Vector3(sx,0.22,z+d*0.5+0.20),
            Vector3(0.18,0.12,0.22),style["hardware"],"steel")
    if damage==2:
        _part(group,"V21_CanalonArrancado_"+tag,
            Vector3(x+w*0.28,0.14,z-d*0.47),
            Vector3(0.72,0.12,0.17),DUST)

static func _rubble_openings(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    if damage<3:
        return
    var group:=V1._group(parent,"V21_PuertasYVentanasCaidas_"+tag)
    var material: Color=WOOD if level==1 else BRICK if level==2 else STEEL
    var count: int=2 if damage==3 else 4
    for i in range(count):
        var piece:=_part(group,"V21_MarcoCaido_%s_%d" % [tag,i],
            Vector3(x+(float(i%2)-0.5)*w*0.47,
                0.15,z+(float(i/2)-0.5)*d*0.38),
            Vector3(0.14,0.21,0.72),material,
            "steel" if level==3 else "stone")
        piece.rotation_degrees.y=float(i)*29.0
    if damage==4:
        _part(group,"V21_CristalYTabiquesRotOs_"+tag,
            Vector3(x+0.19,0.11,z+d*0.24),
            Vector3(0.42,0.10,0.45),
            DARK_WOOD if level==1 else DUST if level==2 else
            BROKEN_GLASS,"glass" if level==3 else "stone")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V20.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var north: int=1 if level==1 else 2 if level==2 else 4
    var south: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String=("Sur_" if southern else "Norte_")+str(side)
            var z: float=3.62 if southern else -3.80
            var w: float=2.77 if southern else 2.74
            var d: float=2.80 if southern else 2.84
            var floors: int=south if southern else north
            var facade:=V1._group(stage,"V21_Detallado_"+tag)
            _door_joints(facade,tag,x,z,w,d,level,damage)
            _window_glazing(facade,tag,x,z,w,d,floors,level,damage)
            _roof_hardware(facade,tag,x,z,w,d,floors,level,damage)
            _rubble_openings(facade,tag,x,z,w,d,level,damage)
    var civic_floors: int=2 if level==1 else 3 if level==2 else 4
    var hall:=V1._group(stage,"V21_DetalladoAyuntamiento")
    _door_joints(hall,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        level,damage)
    _window_glazing(hall,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        civic_floors,level,damage)
    _roof_hardware(hall,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        civic_floors,level,damage)
    _rubble_openings(hall,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",21)
    stage.set_meta("design_focus","3d-doors-window-glazing-roof-hardware-damaged-frames")
    model.set_meta("city_art_work_in_progress",21)
    model.set_meta("city_model_approved_final",false)
    return true
