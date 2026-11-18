extends RefCounted
class_name TarvokaCivilianCityTierProportionsV30

# V30: art-only tier silhouette/proportion study on EXISTING V1..V29 city.
# Villa = sloped terracotta and small timber gables.
# Ciudad = terraced masonry parapets and deliberate horizontal bands.
# Metropoli = narrow, vertical steel crown and staggered setbacks.
# Keep each original lot width/depth, floor count, neutral/faction accents,
# doors, windows, roads, gameplay, navigation and collision unchanged.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const V29=preload("res://scripts/ui/CivilianCityArchitecturalPolishV29.gd")
const STAGE_NAME="CiudadCivilV30ProporcionesVillaCiudadMetropoli"

const CLAY=Color("#a86b50")
const CLAY_DARK=Color("#875743")
const TIMBER=Color("#73604e")
const LIMESTONE=Color("#bbae98")
const BRICK=Color("#9e7863")
const STEEL=Color("#677f85")
const DARK_STEEL=Color("#4b616b")
const DUST=Color("#81766d")
const ASH=Color("#54514f")

static func _surface(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _edge_color(level: int,damage: int) -> Color:
    var base: Color=CLAY if level==1 else LIMESTONE if level==2 else STEEL
    return base.lerp(DUST,0.06 if damage<=1 else
        0.25 if damage==2 else 0.42 if damage==3 else 0.52)

static func _part(stage: Node3D,n: String,position: Vector3,
        size: Vector3,color: Color,level: int,
        damage: int) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(stage,n,position,size,color)
    mesh.material_override=V26._material(
        level,damage,posmod(n.hash(),5),color,_surface(level))
    return mesh

static func _adjust_existing(model: Node3D,
        level: int,damage: int) -> int:
    # Deliberately target exact prefixes for a single tier. Keep
    # previous dimensions available through metadata for future edits.
    var touched: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var part: MeshInstance3D=node as MeshInstance3D
        var n: String=str(part.name)
        if bool(part.get_meta("city_v22_superseded",false)):
            continue
        var target: bool=false
        if damage<=1:
            if level==1:
                if n.begins_with("TejaCaballeraV15_"):
                    part.scale.x=0.82
                    part.scale.y=1.10
                    target=true
                elif n.begins_with("CabioGableteV15_"):
                    part.scale.x=0.94
                    part.scale.y=0.89
                    target=true
                elif n.begins_with("MaderaInclinadaVillaV15_"):
                    part.scale.x=0.92
                    target=true
                elif n.begins_with("V23_VillaRematePerfil_"):
                    part.scale.y=0.90
                    target=true
            elif level==2:
                if n.begins_with("BandaParapetoPiedraV15_"):
                    part.scale.y=0.85
                    part.scale.z=1.07
                    target=true
                elif n.begins_with("BandaLadrilloRemateV15_"):
                    part.scale.y=1.09
                    target=true
                elif n.begins_with("V23_CiudadPerfilEscalonado_"):
                    part.scale.x=0.91
                    part.scale.y=0.91
                    target=true
            else:
                if n.begins_with("CoronaEscalonadaMetroV15_"):
                    part.scale.x=0.91
                    part.scale.y=1.15
                    target=true
                elif n.begins_with("V23_MetroPerfilCorona_"):
                    part.scale.x=0.82
                    part.scale.y=1.17
                    target=true
                elif n.begins_with("AletaCoronaMetropoliV4_"):
                    part.scale.x=0.90
                    target=true
        elif damage==2:
            if level==1 and n.begins_with("TejaSueltaFracturadaVillaV15_"):
                part.scale.x=0.91
                part.scale.z=0.92
                target=true
            elif level==2 and n.begins_with("CornisaDesgajadaCiudadV15_"):
                part.scale.x=0.88
                target=true
            elif level==3 and n.begins_with("PerfilCoronaMetropoliRotoV15_"):
                part.scale.x=0.90
                target=true
        elif damage>=3:
            if level==1 and n.begins_with("VigaVernacularCaidaV15_"):
                part.scale.y=0.91
                target=true
            elif level==2 and n.begins_with("PilastraMamposteriaTruncadaV15_"):
                part.scale.x=0.91
                target=true
            elif level==3 and n.begins_with("PilarMetropoliAbiertoV15_"):
                part.scale.x=0.91
                target=true
        if not target:
            continue
        var existing: StandardMaterial3D=part.material_override as StandardMaterial3D
        if existing!=null:
            var harmonized: Color=existing.albedo_color.lerp(
                _edge_color(level,damage),0.12 if damage<=1 else 0.26)
            part.material_override=V26._material(
                level,damage,posmod(n.hash(),5),harmonized,_surface(level))
        part.set_meta("city_v30_proportion_tuned",true)
        touched+=1
    return touched

static func _tier_signature(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,floors: int,
        level: int,damage: int) -> void:
    # One or two very small physical signatures per existing lot.
    # D0/D1 use existing V15/V23 crowns ONLY: avoid fifth roof layer.
    if damage<=1:
        return
    var signature:=V1._group(stage,"ProporcionPorNivelV30_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage==2:
        # Partial ruins visibly inherit their exact architectural type.
        # No pieces across the central V23 roof gap or destroyed SE edge.
        var sx: float=x-w*0.34
        var zz: float=z-d*0.375
        if level==1:
            var timber:=_part(signature,"V30_AlfardaVillaExpuesta_"+tag,
                Vector3(sx,h+0.04,zz),
                Vector3(0.105,0.17,0.22),TIMBER,level,damage)
            timber.rotation_degrees.z=-12.0
        elif level==2:
            var stone:=_part(signature,"V30_SillarCornisaCiudadRoto_"+tag,
                Vector3(sx,h+0.055,zz),
                Vector3(0.23,0.12,0.16),BRICK,level,damage)
            stone.rotation_degrees.y=-9.0
        else:
            var fin:=_part(signature,"V30_NervioCoronaMetroTorsionado_"+tag,
                Vector3(sx,h+0.04,zz),
                Vector3(0.075,0.20,0.12),DARK_STEEL,level,damage)
            fin.rotation_degrees.z=-15.0
        return
    if damage==3:
        # Interior is already exposed in V11. These grounded/low wall
        # accents do NOT reconstruct a floor or a tall new building.
        var sx: float=x-w*0.22
        var sz: float=z+d*0.22
        if level==1:
            _part(signature,"V30_EntramadoVillaInterior_"+tag,
                Vector3(sx,0.42,sz),
                Vector3(0.10,0.30,0.14),TIMBER,level,damage)
        elif level==2:
            _part(signature,"V30_DintelLadrilloInterior_"+tag,
                Vector3(sx,0.44,sz),
                Vector3(0.28,0.12,0.14),BRICK,level,damage)
        else:
            _part(signature,"V30_SeccionVigaMetalInterior_"+tag,
                Vector3(sx,0.43,sz),
                Vector3(0.10,0.26,0.12),DARK_STEEL,level,damage)
        return
    # D4: signature stays below 0.24 metres above ground, retaining
    # a visual distinction from villa timber to town stone to metro steel.
    var sx: float=x+w*0.18
    var sz: float=z-d*0.15
    var color: Color=CLAY_DARK if level==1 else BRICK if level==2 else STEEL
    var chunk:=_part(signature,
        ("V30_TejaVillaDerruida_" if level==1 else
         "V30_BloqueCiudadDerruido_" if level==2 else
         "V30_PerfilMetroCaido_")+tag,
        Vector3(sx,0.104,sz),
        Vector3(0.29,0.13,0.23),color,level,damage)
    chunk.rotation_degrees.y=(18.0 if level==1 else
        -11.0 if level==2 else 28.0)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V29.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var tuned: int=_adjust_existing(model,level,damage)
    var stage:=V1._group(model,STAGE_NAME)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for is_south in [false,true]:
            var tag: String=("Sur_" if is_south else "Norte_")+str(side)
            _tier_signature(stage,tag,x,
                3.62 if is_south else -3.80,
                2.77 if is_south else 2.74,
                2.80 if is_south else 2.84,
                south_floors if is_south else north_floors,
                level,damage)
    _tier_signature(stage,"Ayuntamiento",0.0,-3.75,
        3.35,2.74,2 if level==1 else 3 if level==2 else 4,
        level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",30)
    stage.set_meta("existing_silhouettes_reproportioned",tuned)
    stage.set_meta("design_focus","villa-slope-town-parapet-metropolis-vertical-crown")
    model.set_meta("city_v30_tuned_silhouette_meshes",tuned)
    model.set_meta("city_art_work_in_progress",30)
    model.set_meta("city_model_approved_final",false)
    return true
