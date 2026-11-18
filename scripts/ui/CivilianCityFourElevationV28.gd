extends RefCounted
class_name TarvokaCivilianCityFourElevationV28

# V28 — four-elevation architectural cohesion on the real V1..V27 city.
# Retouch existing V23/V24/V25/V27 junctions, preserving roof apertures,
# V10 street entrances and V11 jagged damage shells. No new street tiles,
# collision, ownership, capture, production or combat geometry.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const V27=preload("res://scripts/ui/CivilianCityStreetInterfaceV27.gd")
const STAGE_NAME="CiudadCivilV28CoherenciaCuatroAlzados"

const CLAY=Color("#ad785c")
const TIMBER=Color("#79614c")
const BRICK=Color("#a67e68")
const STONE=Color("#c2b49f")
const MORTAR=Color("#9c9385")
const METAL=Color("#768a90")
const STEEL=Color("#586a70")
const DUST=Color("#867b6d")
const SOOT=Color("#505050")

static func _tint(level: int,damage: int) -> Color:
    var color: Color=CLAY if level==1 else STONE if level==2 else METAL
    return color.lerp(DUST,0.24 if damage>=2 else 0.06 if damage==1 else 0.0)

static func _surface(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _part(parent: Node3D,n: String,
        at: Vector3,dimensions: Vector3,
        level: int,damage: int,
        color: Color) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,n,at,dimensions,color)
    mesh.material_override=V26._material(
        level,damage,posmod(n.hash(),5),color,_surface(level))
    return mesh

static func _retouch_existing(model: Node3D,
        level: int,damage: int) -> int:
    # Material and careful size/height adjustments on named geometry
    # only. Never reposition original V1-V19 street or V10 doorway.
    var targets: Array[String]=[
        "V23_VillaRematePerfil_",
        "V23_CiudadPerfilEscalonado_",
        "V23_MetroPerfilCorona_",
        "V23_BordeTejadoPartido_",
        "V24_PuntalDescentrado_",
        "V24_FracturaApoyada_",
        "V25_SeccionTejaPartida_",
        "V25_CantoForjadoVisible_",
        "V27_PieFachadaAcera_",
        "V27_EncuentroAdoquinPasaje_",
        "V27_UnionLosetaAcera_",
        "V27_LosetaCierrePlaza_",
        "V27_EmpalmeAccesoColapsado_",
        "V27_BordePlazaQuebrado_"
    ]
    var count: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        var n: String=str(mesh.name)
        var selected: bool=false
        for prefix in targets:
            if n.begins_with(prefix):
                selected=true
                break
        if not selected or bool(mesh.get_meta("city_v22_superseded",false)):
            continue
        var existing: StandardMaterial3D=mesh.material_override as StandardMaterial3D
        if existing==null:
            continue
        var new_tint: Color=existing.albedo_color.lerp(
            _tint(level,damage),0.17 if damage<2 else 0.28)
        mesh.material_override=V26._material(
            level,damage,posmod(n.hash(),5),new_tint,_surface(level))
        if n.begins_with("V27_LosetaCierrePlaza_"):
            # The V1 plaza is 7cm thick centered y=.042; keep these
            # finish stones seated, without a prominent floating lip.
            mesh.position.y=0.092
            mesh.scale.y=0.90
        elif n.begins_with("V27_EncuentroAdoquinPasaje_"):
            mesh.scale.y=0.86
        elif n.begins_with("V27_UnionLosetaAcera_"):
            mesh.scale.y=0.86
        elif n.begins_with("V24_FracturaApoyada_"):
            mesh.scale.x=0.92
            mesh.scale.z=0.92
        elif n.begins_with("V23_BordeTejadoPartido_"):
            mesh.scale.x=0.97
            mesh.scale.z=0.97
        mesh.set_meta("city_v28_cohesion_refinished",true)
        count+=1
    return count

static func _corner_profiles(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    var corner:=V1._group(stage,"EncuentrosAlzadosV28_"+tag)
    var h: float=float(floors)*2.10+0.21
    var tint: Color=_tint(level,damage)
    # Four sides, with short, inset material joins rather than another
    # continuous facade strip that covers the existing V8 windows.
    if damage<=1:
        for side in [-1,1]:
            var sx: float=x+float(side)*(w*0.5+0.045)
            for face in [-1,1]:
                # Each north/south corner receives a small side-wall
                # footing and an upper handoff, both attached to V1 wall.
                var sz: float=z+float(face)*(d*0.5-0.17)
                _part(corner,
                    "V28_EnlaceEsquinaLateral_%s_%d_%d" % [tag,side,face],
                    Vector3(sx,0.38,sz),
                    Vector3(0.065,0.43,0.20),level,damage,tint)
                if damage==1 and side==1 and face==1:
                    # Chipped corner: do not recreate an immaculate cap.
                    continue
                _part(corner,
                    "V28_RemateEsquinaSuperior_%s_%d_%d" %
                    [tag,side,face],
                    Vector3(sx,h-0.27,sz),
                    Vector3(0.07,0.22,0.20),level,damage,tint)
        return
    if damage==2:
        # Preserve V23 missing south-east roof corner; small strips stop
        # BELOW its broken eave. No slabs spanning the D2 roof opening.
        for side in [-1,1]:
            var sx: float=x+float(side)*(w*0.50-0.07)
            for face in [-1,1]:
                if side==1 and face==1:
                    continue
                var sz: float=z+float(face)*(d*0.50-0.17)
                _part(corner,
                    "V28_RetornoCantoRoto_%s_%d_%d" % [tag,side,face],
                    Vector3(sx,h-0.38,sz),
                    Vector3(0.12,0.26,0.18),level,damage,tint)
        return
    # V11/V23 have actual jagged D3 shells and D4 collapsed bases.
    # Finish only two LOW surviving construction contacts per building.
    var y: float=0.24 if damage==3 else 0.105
    var height: float=0.21 if damage==3 else 0.10
    for side in [-1,1]:
        var sx: float=x+float(side)*(w*0.50-0.18)
        var sz: float=z+d*(0.31 if side==-1 else -0.30)
        _part(corner,
            "V28_EncuentroBajoRuina_%s_%d" % [tag,side],
            Vector3(sx,y,sz),
            Vector3(0.15,height,0.22),
            level,damage,tint)

static func _front_back_reveals(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    if damage>=3:
        return
    var group:=V1._group(stage,"DetallesNorteSurV28_"+tag)
    # Tiny base-side reveals away from center doorways and glass.
    # South (+Z) and north (-Z) elevations are given the same material
    # identity while V10/V22 remain sole owners of the actual portals.
    for face in [-1,1]:
        var sz: float=z+float(face)*(d*0.5+0.065)
        for side in [-1,1]:
            if damage==2 and face==1 and side==1:
                continue
            var sx: float=x+float(side)*w*0.42
            _part(group,
                "V28_ZocaloNorteSur_%s_%d_%d" % [tag,face,side],
                Vector3(sx,0.22,sz),
                Vector3(0.16,0.20,0.068),
                level,damage,_tint(level,damage))

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V27.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var changed: int=_retouch_existing(model,level,damage)
    var stage:=V1._group(model,STAGE_NAME)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String=("Sur_" if southern else "Norte_")+str(side)
            var z: float=3.62 if southern else -3.80
            var w: float=2.77 if southern else 2.74
            var d: float=2.80 if southern else 2.84
            _corner_profiles(stage,tag,x,z,w,d,
                south_floors if southern else north_floors,
                level,damage)
            _front_back_reveals(stage,tag,x,z,w,d,level,damage)
    _corner_profiles(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        2 if level==1 else 3 if level==2 else 4,level,damage)
    _front_back_reveals(stage,"Ayuntamiento",
        0.0,-3.75,3.35,2.74,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",28)
    stage.set_meta("design_focus","north-south-east-west-material-corners-entrances-roof")
    stage.set_meta("existing_meshes_harmonized",changed)
    model.set_meta("city_v28_harmonized_meshes",changed)
    model.set_meta("city_art_work_in_progress",28)
    model.set_meta("city_model_approved_final",false)
    return true
