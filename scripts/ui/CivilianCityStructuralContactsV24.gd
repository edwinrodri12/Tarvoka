extends RefCounted
class_name TarvokaCivilianCityStructuralContactsV24

# V24: physically plausible wall/roof/inner-floor CONTACTS on the
# exact V1–V23 city. Keep V11/V14/V23 irregular silhouettes authoritative.
# ART ONLY: no ownership, combat, income, collisions or new building tiles.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V23=preload("res://scripts/ui/CivilianCitySilhouetteV23.gd")
const STAGE_NAME="CiudadCivilV24EncuentrosEstructuralesYRuinados"

const WOOD=Color("#78604c")
const BROKEN_WOOD=Color("#574739")
const TERRACOTTA=Color("#b17657")
const BRICK=Color("#9a715e")
const LIMESTONE=Color("#bdb3a2")
const MORTAR=Color("#9a9385")
const METAL=Color("#788b90")
const STEEL=Color("#566972")
const SOOT=Color("#494b4a")
const DUST=Color("#7f756a")
const GLASS=Color("#456b77")

static func _part(parent: Node3D, label: String,
        at: Vector3, size: Vector3, color: Color,
        finish: String="stone") -> MeshInstance3D:
    var node: MeshInstance3D=V1._box(parent,label,at,size,color)
    node.material_override=V9._finish(color,finish)
    return node

static func _color(level: int) -> Color:
    return TERRACOTTA if level==1 else LIMESTONE if level==2 else METAL

static func _intact_contacts(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    # Do not clone V18's full eaves. Just physically terminate the
    # short ends where horizontal fascia meets vertical corner pier.
    var contacts:=V1._group(parent,"V24_UnionesDeEsquina_"+tag)
    var h: float=float(floors)*2.10+0.21
    var tint: Color=_color(level)
    for side in [-1,1]:
        for face in [-1,1]:
            if damage==1 and side==1 and face==1:
                # A chipped corner on D1, no floating immaculate cap.
                continue
            var cx: float=x+float(side)*(w*0.5+0.075)
            var cz: float=z+float(face)*(d*0.5+0.07)
            _part(contacts,
                "V24_CierreCornisa_%s_%d_%d" % [tag,side,face],
                Vector3(cx,h+0.10,cz),
                Vector3(0.17,0.13,0.21),tint,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
            if level==1:
                _part(contacts,
                    "V24_EscuadraMadera_%s_%d_%d" % [tag,side,face],
                    Vector3(cx-float(side)*0.085,h-0.12,
                        cz-float(face)*0.10),
                    Vector3(0.09,0.28,0.08),WOOD)
            elif level==2:
                _part(contacts,
                    "V24_ClaveMortero_%s_%d_%d" % [tag,side,face],
                    Vector3(cx-float(side)*0.10,h-0.07,cz),
                    Vector3(0.11,0.15,0.10),MORTAR)
            else:
                _part(contacts,
                    "V24_AnclajeAluminio_%s_%d_%d" % [tag,side,face],
                    Vector3(cx-float(side)*0.075,h-0.07,
                        cz-float(face)*0.055),
                    Vector3(0.075,0.20,0.075),STEEL,"steel")
    if damage==1:
        _part(contacts,"V24_AcaboDespostillado_"+tag,
            Vector3(x+w*0.38,0.125,z+d*0.44),
            Vector3(0.25,0.11,0.29),DUST)

static func _cracked_eave_contacts(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int) -> void:
    # V23 owns the 3-D detached edges. These short braces START inside
    # the existing V11 wall/crown and end beneath V23's edge fragments.
    # An intentionally vacant fourth corner stays visibly blown away.
    var group:=V1._group(parent,"V24_ApoyosCubiertaRota_"+tag)
    var h: float=float(floors)*2.10+0.21
    var material: Color=WOOD if level==1 else MORTAR if level==2 else STEEL
    for side in [-1,1]:
        for face in [-1,1]:
            if side==1 and face==1:
                continue
            var sx: float=x+float(side)*w*0.365
            var sz: float=z+float(face)*d*0.385
            _part(group,
                "V24_ZapataApoyoRoto_%s_%d_%d" % [tag,side,face],
                Vector3(sx,h-0.12,sz),
                Vector3(0.28,0.18,0.25),material,
                "steel" if level==3 else "stone")
            var brace:=_part(group,
                "V24_PuntalDescentrado_%s_%d_%d" % [tag,side,face],
                Vector3(sx-float(side)*0.085,h+0.04,sz),
                Vector3(0.12,0.39,0.11),material,
                "steel" if level==3 else "stone")
            brace.rotation_degrees.z=float(side)*14.0
            var cap:=V14._sloped_slab(group,
                "V24_FracturaApoyada_%s_%d_%d" % [tag,side,face],
                Vector3(sx,h+0.21,sz),
                0.29,0.30,0.05,0.16,
                TERRACOTTA if level==1 else BRICK if level==2 else METAL)
            cap.rotation_degrees.y=float(face)*10.0
            cap.material_override=V9._finish(
                TERRACOTTA if level==1 else BRICK if level==2 else METAL,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
    # A tiny collapsed lintel stays on the pavement and does not
    # disguise V23's open central roof gap.
    var fallen:=_part(group,"V24_DintelDeCornisaDesprendido_"+tag,
        Vector3(x+w*0.27,0.13,z+d*0.29),
        Vector3(0.65,0.15,0.26),material,
        "steel" if level==3 else "stone")
    fallen.rotation_degrees.y=17.0

static func _damaged_room_connections(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,level: int) -> void:
    var interior:=V1._group(parent,"V24_InterioresDescubiertos_"+tag)
    # V11 already has floors at y=0.71 and open partitions at y=1.03.
    # These contacts attach to its broken floor, not to nonexistent roofs.
    var slab_tint: Color=WOOD if level==1 else LIMESTONE if level==2 else STEEL
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.30
        _part(interior,"V24_CabezaVigaPiso_%s_%d" % [tag,side],
            Vector3(sx,0.74,z+d*0.12),
            Vector3(0.28,0.16,d*0.22),slab_tint,
            "steel" if level==3 else "stone")
        var broken:=V14._sloped_slab(interior,
            "V24_FiloForjadoInterrumpido_%s_%d" % [tag,side],
            Vector3(sx,0.72,z-d*0.05),
            w*0.23,d*0.23,0.035,0.20,
            LIMESTONE if level<=2 else METAL)
        broken.rotation_degrees.y=float(side)*13.0
        broken.material_override=V9._finish(
            LIMESTONE if level<=2 else METAL,
            "steel" if level==3 else "stone")
        # Short visible bent rebar is anchored at the beam-to-floor
        # joint and never recreates an intact wall in D3.
        if level>=2:
            var rod:=V1._cylinder(interior,
                "V24_ArmaduraDesdeForjado_%s_%d" % [tag,side],
                Vector3(sx+float(side)*0.15,0.91,z+d*0.09),
                0.034,0.38,STEEL,8)
            rod.material_override=V9._finish(STEEL,"steel")
            rod.rotation_degrees.z=float(side)*28.0
    # An interior face cut along the real V11 tabique:
    # low broken masonry rather than covering an existing window plane.
    _part(interior,"V24_PiezaTabiqueAbierta_"+tag,
        Vector3(x+w*0.23,0.35,z+d*0.15),
        Vector3(0.15,0.33,d*0.27),
        BRICK if level==1 else MORTAR if level==2 else SOOT)

static func _collapsed_foundation_contacts(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,level: int) -> void:
    var debris:=V1._group(parent,"V24_EncuentroCimentacionCaida_"+tag)
    # Only ground-contact fragments: D4 already has a rubble field in
    # V11/V14/V20/V23 and must remain a low profile at every angle.
    var tint: Color=WOOD if level==1 else LIMESTONE if level==2 else METAL
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.38
        var shard:=V14._sloped_slab(debris,
            "V24_ZapataCortada_%s_%d" % [tag,side],
            Vector3(sx,0.10,z+d*0.30),
            0.44,0.38,0.025,0.12,tint)
        shard.rotation_degrees.y=float(side)*16.0
        shard.material_override=V9._finish(
            tint,"steel" if level==3 else "stone")
        var bracket:=_part(debris,
            "V24_VigaEntreCascotes_%s_%d" % [tag,side],
            Vector3(sx,0.14,z-d*0.22),
            Vector3(0.14,0.12,d*0.22),
            TIMBER if level==1 else BRICK if level==2 else STEEL,
            "steel" if level==3 else "stone")
        bracket.rotation_degrees.y=float(side)*21.0
    if level==3:
        _part(debris,"V24_VidrioEnForjadoCaido_"+tag,
            Vector3(x,0.10,z+d*0.18),
            Vector3(0.36,0.04,0.23),GLASS,"glass")

static func _civic_contact(parent: Node3D,level: int,damage: int) -> void:
    # Civic footprint is unchanged. Restore no tall clock / towers after D2.
    var group:=V1._group(parent,"V24_EncuentrosMunicipales")
    if damage==2:
        _part(group,"V24_ApoyoAccesoMunicipalRoto",
            Vector3(-0.92,0.19,-2.24),
            Vector3(0.31,0.25,0.24),
            TERRACOTTA if level==1 else LIMESTONE if level==2 else METAL)
    elif damage==3:
        _part(group,"V24_VigaAccesoMunicipalBaja",
            Vector3(0.85,0.28,-2.31),
            Vector3(0.78,0.18,0.20),
            WOOD if level==1 else BRICK if level==2 else STEEL)
    elif damage==4:
        _part(group,"V24_PiedrasPlacaMunicipalCaida",
            Vector3(0.28,0.12,-2.35),
            Vector3(0.39,0.11,0.35),DUST)

static func _lot(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    var section:=V1._group(parent,"V24_Lote_"+tag)
    match damage:
        0,1:
            _intact_contacts(section,tag,x,z,w,d,floors,level,damage)
        2:
            _cracked_eave_contacts(section,tag,x,z,w,d,floors,level)
        3:
            _damaged_room_connections(section,tag,x,z,w,d,level)
        4:
            _collapsed_foundation_contacts(section,tag,x,z,w,d,level)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V23.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for south in [false,true]:
            _lot(stage,("Sur_" if south else "Norte_")+str(side),
                x,3.62 if south else -3.80,
                2.77 if south else 2.74,
                2.80 if south else 2.84,
                south_floors if south else north_floors,
                level,damage)
    _lot(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        2 if level==1 else 3 if level==2 else 4,level,damage)
    _civic_contact(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",24)
    stage.set_meta("design_focus","roof-wall-floor-foundation-contact-and-broken-joinery")
    stage.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",24)
    model.set_meta("city_model_approved_final",false)
    return true
