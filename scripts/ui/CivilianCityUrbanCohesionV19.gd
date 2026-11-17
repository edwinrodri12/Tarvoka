extends RefCounted
class_name TarvokaCivilianCityUrbanCohesionV19

# TARVOKA CIVILIAN CITIES V19 — coherent real-mesh streetscape.
# Architectural finishing, side-parcel walkways and joined roof rhythm.
# Art-only: NO new city types, footprint, collision, income, production,
# infantry capture, faction ownership, gameplay or save-state alterations.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V18=preload("res://scripts/ui/CivilianCitySideJointsV18.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV19ContinuidadUrbanaYRemates"
const STONE=Color("#cbbfa9")
const LIME=Color("#b6aa96")
const BRICK=Color("#96705f")
const TERRACOTTA=Color("#b16e54")
const WOOD=Color("#81654e")
const GLASS=Color("#567f8a")
const ALUMINUM=Color("#80969b")
const DARK=Color("#394a51")
const GARDEN=Color("#5f856b")
const DUST=Color("#817468")
const CHAR=Color("#414747")
const RUBBLE=Color("#686260")
const ROAD_EDGE=Color("#858d87")

static func _part(parent: Node3D,label: String,
        at: Vector3,size: Vector3,tint: Color,
        surface: String="stone") -> MeshInstance3D:
    var node: MeshInstance3D=V1._box(parent,label,at,size,tint)
    node.material_override=V9._finish(tint,surface)
    return node

static func _palette(level: int) -> Dictionary:
    match level:
        1:
            return {"wall":LIME,"base":STONE,"roof":TERRACOTTA,
                "edge":WOOD,"walk":STONE,"finish":"ceramic"}
        2:
            return {"wall":BRICK,"base":STONE,"roof":STONE,
                "edge":BRICK,"walk":LIME,"finish":"stone"}
        _:
            return {"wall":ALUMINUM,"base":DARK,"roof":ALUMINUM,
                "edge":GLASS,"walk":ROAD_EDGE,"finish":"steel"}

static func _building_seams(stage: Node3D,tag: String,x: float,z: float,
        w: float,d: float,floors: int,level: int,
        damage: int,accent: Color) -> void:
    var group:=V1._group(stage,"JuntasDeConjuntoV19_"+tag)
    var palette: Dictionary=_palette(level)
    var h: float=float(floors)*2.10+0.21
    if damage>=3:
        # Each district keeps a recognisable tier-specific fallen crown,
        # never an intact facade over collapsed V11-V18 foundations.
        for i in range(4):
            var sx: float=x+(float(i%2)-0.5)*w*0.47
            var sz: float=z+(float(i/2)-0.5)*d*0.51
            var piece:=_part(group,
                "V19_DerrumbeMaterial_%s_%d" % [tag,i],
                Vector3(sx,0.105+float(i%2)*0.04,sz),
                Vector3(0.62,0.16,0.42),
                palette["roof"] if i%2==0 else RUBBLE,
                str(palette["finish"]) if i%2==0 else "stone")
            piece.rotation_degrees.y=float(i)*19.0
        return
    # Repeated stone/concrete foundation joints are small enough not to
    # overwrite existing access doors, but visibly connect all elevations.
    for side in [-1,1]:
        var sx: float=x+float(side)*(w*0.5+0.105)
        _part(group,"V19_EncuentroZocaloCostado_%s_%d" % [tag,side],
            Vector3(sx,0.23,z),Vector3(0.13,0.28,d*0.82),
            palette["base"])
        for end in [-1,1]:
            _part(group,
                "V19_AnclajeEsquinaMamposteria_%s_%d_%d" % [tag,side,end],
                Vector3(sx,0.38,z+float(end)*d*0.44),
                Vector3(0.18,0.24,0.16),
                palette["edge"],"steel" if level==3 else "stone")
    # The V18 roof planes stay untouched. Add a compact architectural
    # shadow-gap/termination so the levels share a coherent street rhythm.
    for end in [-1,1]:
        if damage==2 and end==1:
            continue
        var roof_z: float=z+float(end)*(d*0.5+0.13)
        var trim_w: float=w*0.65 if damage==2 else w+0.20
        var trim_x: float=x-w*0.14 if damage==2 else x
        _part(group,"V19_SombraCornisa_%s_%d" % [tag,end],
            Vector3(trim_x,h-0.045,roof_z),
            Vector3(trim_w,0.09,0.11),DARK,"steel")
        _part(group,"V19_RibeteCubierta_%s_%d" % [tag,end],
            Vector3(trim_x,h+0.19,roof_z),
            Vector3(trim_w,0.11,0.17),palette["roof"],
            str(palette["finish"]))
    if damage==2:
        _part(group,"V19_MaterialDesprendido_"+tag,
            Vector3(x+w*0.28,0.16,z-d*0.50-0.18),
            Vector3(0.53,0.21,0.42),DUST)
        return
    # Unique tier identities on the same massing, never an extra floor:
    # villa: timber fascia, city: alternating masonry, metro: steel/glass.
    for side in [-1,1]:
        var sx: float=x+float(side)*(w*0.5+0.24)
        if level==1:
            _part(group,"V19_TablonRemateVilla_%s_%d" % [tag,side],
                Vector3(sx,h+0.055,z),
                Vector3(0.12,0.17,d*0.76),WOOD)
        elif level==2:
            for segment in range(3):
                _part(group,
                    "V19_DintelLadrilloUrbano_%s_%d_%d" % [tag,side,segment],
                    Vector3(sx,h+0.06,z+(float(segment)-1.0)*d*0.30),
                    Vector3(0.16,0.15,d*0.23),
                    BRICK if segment%2==0 else LIME)
        else:
            _part(group,"V19_PerfilAluminioUrbano_%s_%d" % [tag,side],
                Vector3(sx,h+0.06,z),
                Vector3(0.13,0.18,d*0.77),ALUMINUM,"steel")
            _part(group,"V19_CintaCristalUrbana_%s_%d" % [tag,side],
                Vector3(sx+float(side)*0.07,h-0.18,z),
                Vector3(0.045,0.13,d*0.51),
                GLASS,"glass")
    if tag=="Ayuntamiento":
        # A civic identity line echoes existing facade colors without
        # creating a second HQ, military installation or production site.
        _part(group,"V19_LecturaCivica_"+tag,
            Vector3(0.0,h-0.36,-2.22),
            Vector3(1.12,0.13,0.095),
            accent if damage==0 else DUST,"steel")

static func _parcel_walkways(stage: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var group:=V1._group(stage,"PasajesEntreManzanasV19")
    var palette: Dictionary=_palette(level)
    # Two continuous service passages in the gap between the
    # central civic building and both residential blocks.
    # They approach but NEVER cover the avenue at z=-0.92..+0.92.
    for side in [-1,1]:
        var x: float=float(side)*2.47
        for neighborhood in [-1,1]:
            var z: float=-3.67 if neighborhood==-1 else 3.57
            var length: float=3.04 if neighborhood==-1 else 3.09
            if damage>=3:
                # Visible broken urban connections, not fresh pavement.
                for segment in range(3):
                    _part(group,
                        "V19_PasajeInterrumpido_%d_%d_%d" %
                        [side,neighborhood,segment],
                        Vector3(x+float(segment%2)*0.14,0.09,
                            z+(float(segment)-1.0)*0.68),
                        Vector3(0.77,0.14,0.58),
                        RUBBLE if segment%2==0 else DUST)
                continue
            _part(group,"V19_PasajePeatonal_%d_%d" % [side,neighborhood],
                Vector3(x,0.09,z),Vector3(0.94,0.12,length),
                palette["walk"])
            for curb in [-1,1]:
                var cx: float=x+float(curb)*0.49
                _part(group,
                    "V19_BordilloDePasaje_%d_%d_%d" %
                    [side,neighborhood,curb],
                    Vector3(cx,0.13,z),Vector3(0.11,0.19,length),
                    palette["base"])
            var curb_z: float=-1.39 if neighborhood==-1 else 1.39
            _part(group,
                "V19_EncuentroCallePasaje_%d_%d" % [side,neighborhood],
                Vector3(x,0.106,curb_z),Vector3(0.93,0.085,0.20),
                ROAD_EDGE if damage==2 else palette["walk"])
            if damage==2:
                _part(group,
                    "V19_LosaHundidaPasaje_%d_%d" % [side,neighborhood],
                    Vector3(x+0.14,0.155,z-0.58),
                    Vector3(0.36,0.10,0.48),DUST)
                continue
            if level==1:
                # Low planted borders keep the villa's residential scale.
                _part(group,
                    "V19_ParterreVilla_%d_%d" % [side,neighborhood],
                    Vector3(x,0.18,z+0.83),
                    Vector3(0.37,0.17,0.44),GARDEN)
            elif level==2:
                _part(group,
                    "V19_MureteLadrilloCiudad_%d_%d" % [side,neighborhood],
                    Vector3(x,0.24,z+0.89),
                    Vector3(0.46,0.32,0.17),BRICK)
            else:
                _part(group,
                    "V19_MaceteroMetropolitano_%d_%d" % [side,neighborhood],
                    Vector3(x,0.27,z+0.89),
                    Vector3(0.53,0.31,0.31),ALUMINUM,"steel")
                _part(group,
                    "V19_JardinMetropolitano_%d_%d" % [side,neighborhood],
                    Vector3(x,0.45,z+0.89),
                    Vector3(0.40,0.055,0.22),GARDEN)

static func _civic_square_finish(stage: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var group:=V1._group(stage,"BordePlazaCompartidaV19")
    if damage>=3:
        for side in [-1,1]:
            _part(group,"V19_BordePlazaDerruido_%d" % side,
                Vector3(float(side)*1.48,0.095,2.70),
                Vector3(0.58,0.16,0.24),RUBBLE)
        return
    # Existing fountain, monument and plaza V1/V3 remain untouched.
    # Add shallow perimeter pieces outside the existing central monument.
    for side in [-1,1]:
        var x: float=float(side)*1.72
        _part(group,"V19_RibetePerimetralPlaza_%d" % side,
            Vector3(x,0.119,2.14),Vector3(0.13,0.09,1.59),
            STONE if level<=2 else ALUMINUM,
            "stone" if level<=2 else "steel")
        if damage==0:
            _part(group,"V19_PuntoIdentidadBarrio_%d" % side,
                Vector3(x,0.182,2.38),
                Vector3(0.13,0.11,0.37),accent,"steel")
    if level>=2 and damage<2:
        _part(group,"V19_UnionPlazaComercio",
            Vector3(0.0,0.118,3.10),Vector3(2.42,0.07,0.15),
            LIME if level==2 else ALUMINUM,
            "stone" if level==2 else "steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V18.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        _building_seams(stage,"Norte_%d" % side,x,-3.80,2.74,2.84,
            north_floors,level,damage,accent)
        _building_seams(stage,"Sur_%d" % side,x,3.62,2.77,2.80,
            south_floors,level,damage,accent)
    var civic_floors: int=2 if level==1 else 3 if level==2 else 4
    _building_seams(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        civic_floors,level,damage,accent)
    _parcel_walkways(stage,level,damage,accent)
    _civic_square_finish(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",19)
    stage.set_meta("design_focus","coherent-rooflines-parcel-walkways-civic-square")
    model.set_meta("city_art_work_in_progress",19)
    model.set_meta("city_model_approved_final",false)
    return true
