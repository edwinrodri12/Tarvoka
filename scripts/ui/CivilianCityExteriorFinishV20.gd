extends RefCounted
class_name TarvokaCivilianCityExteriorFinishV20

# V20 — finish the EXTERIOR from all four camera quadrants.
# Native Godot 4.3 MeshInstance3D surfaces; added onto the existing
# V1–V19 civilian city rather than creating another selectable building.
# Entirely visual: no collision, placement, income, capture or combat rules.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V19=preload("res://scripts/ui/CivilianCityUrbanCohesionV19.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV20AcabadoExteriorYRuinas360"

const CLAY=Color("#b87557")
const CLAY_SHADE=Color("#8a5546")
const WOOD=Color("#82664e")
const LIME=Color("#d2c3aa")
const LIMESTONE=Color("#c1b59d")
const BRICK=Color("#9f7661")
const MORTAR=Color("#a99d8c")
const ZINC=Color("#7b9298")
const STEEL=Color("#52666f")
const GLASS=Color("#567f8d")
const GLASS_BROKEN=Color("#355966")
const CONCRETE=Color("#a8a9a1")
const ASH=Color("#514e4b")
const DUST=Color("#898075")
const RUBBLE=Color("#75675f")

static func _part(parent: Node3D,label: String,
        position: Vector3,size: Vector3,tint: Color,
        surface: String="stone") -> MeshInstance3D:
    var node: MeshInstance3D=V1._box(
        parent,label,position,size,tint)
    node.material_override=V9._finish(tint,surface)
    return node

static func _rooftop_villa(layer: Node3D,tag: String,x: float,z: float,
        w: float,d: float,height: float,damage: int) -> void:
    # Ceramic RIDGE and two stepped eaves; do not obscure the V2 pitched roof.
    for end in [-1,1]:
        var z_edge: float=z+float(end)*d*0.39
        for ix in range(4):
            if damage==2 and (ix+end+5)%3==0:
                continue
            var px: float=x+(float(ix)-1.5)*w*0.20
            var tile:=_part(layer,
                "V20_TejaBorde360Villa_%s_%d_%d" % [tag,end,ix],
                Vector3(px,height+0.32,z_edge),
                Vector3(w*0.175,0.10,0.34),
                CLAY_SHADE if damage>=1 and ix%3==0 else CLAY,
                "ceramic")
            tile.rotation_degrees.x=float(end)*12.0
    if damage==2:
        # Exposed timber fragments never restore a fully intact ridge.
        for i in range(2):
            var beam:=_part(layer,
                "V20_CabioArrancadoVilla_%s_%d" % [tag,i],
                Vector3(x+(float(i)-0.5)*w*0.47,
                    height+0.20,z+d*0.17),
                Vector3(0.15,0.13,d*0.42),WOOD)
            beam.rotation_degrees.z=18.0 if i==0 else -11.0
        return
    for side in [-1,1]:
        # Actual short fascia fitted to the current roof-wall junction.
        _part(layer,"V20_TesteroMaderaVilla_%s_%d" % [tag,side],
            Vector3(x+float(side)*w*0.48,height+0.18,z),
            Vector3(0.12,0.16,d*0.76),WOOD)

static func _rooftop_town(layer: Node3D,tag: String,x: float,z: float,
        w: float,d: float,height: float,damage: int) -> void:
    # Masonry courses bridge visible front/rear corner joints.
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.46
        for run in range(3):
            if damage==2 and run==2:
                continue
            var sz: float=z+(float(run)-1.0)*d*0.28
            _part(layer,
                "V20_LadrilloRemateCiudad_%s_%d_%d" % [tag,side,run],
                Vector3(sx,height+0.34,sz),
                Vector3(0.28,0.13,d*0.23),
                BRICK if run%2==0 else LIMESTONE)
            _part(layer,
                "V20_JuntaMorteroCiudad_%s_%d_%d" % [tag,side,run],
                Vector3(sx,height+0.25,sz),
                Vector3(0.30,0.045,d*0.24),MORTAR)
    for end in [-1,1]:
        if damage==2 and end==1:
            continue
        _part(layer,"V20_CoronacionPiedraCiudad_%s_%d" % [tag,end],
            Vector3(x,height+0.29,z+float(end)*d*0.47),
            Vector3(w*0.73,0.15,0.20),LIMESTONE)

static func _rooftop_metro(layer: Node3D,tag: String,x: float,z: float,
        w: float,d: float,height: float,damage: int,
        accent: Color) -> void:
    # Low metal flashing, narrow air vents and glazed returns: no
    # additional tower, height upgrade or buildable infrastructure.
    for end in [-1,1]:
        if damage==2 and end==1:
            continue
        _part(layer,"V20_PerfilTapajuntasMetro_%s_%d" % [tag,end],
            Vector3(x,height+0.30,z+float(end)*d*0.49),
            Vector3(w*0.73,0.12,0.24),ZINC,"steel")
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.42
        if damage==2 and side==1:
            var bent:=_part(layer,
                "V20_PerfilDobladoMetro_%s_%d" % [tag,side],
                Vector3(sx,height+0.21,z+0.20),
                Vector3(0.14,0.10,d*0.49),STEEL,"steel")
            bent.rotation_degrees.x=22.0
            continue
        _part(layer,"V20_MontanteAzoteaMetro_%s_%d" % [tag,side],
            Vector3(sx,height+0.30,z),
            Vector3(0.12,0.19,d*0.62),STEEL,"steel")
        for vent in range(3):
            _part(layer,
                "V20_RejillaAzoteaMetro_%s_%d_%d" % [tag,side,vent],
                Vector3(sx,height+0.41,
                    z+(float(vent)-1.0)*d*0.19),
                Vector3(0.15,0.035,d*0.13),GLASS,"steel")
    if damage==0:
        # Controlled faction hue on a structural piece, not a recolored city.
        _part(layer,"V20_LineaIdentidadMetro_"+tag,
            Vector3(x,height+0.28,z-d*0.44),
            Vector3(w*0.43,0.09,0.12),accent,"steel")

static func _facade_returns(layer: Node3D,tag: String,x: float,z: float,
        w: float,d: float,floors: int,level: int,damage: int) -> void:
    # Four genuine 3D facade corners, consistent for rear/left/right/front.
    # Keep transparent windows and doors from V1–V19 unobstructed.
    if damage>=3:
        return
    var h: float=float(floors)*2.10+0.21
    for side in [-1,1]:
        for end in [-1,1]:
            if damage==2 and side==1 and end==1:
                # A missing upper corner where the existing ruin tears away.
                continue
            var sx: float=x+float(side)*(w*0.5+0.055)
            var sz: float=z+float(end)*(d*0.5+0.056)
            var corner_color: Color=WOOD if level==1 else (
                LIMESTONE if level==2 else ZINC)
            var upper: float=h-0.37 if damage<2 else h*0.55
            _part(layer,
                "V20_EncuentroCuatroFachadas_%s_%d_%d" % [tag,side,end],
                Vector3(sx,upper,sz),Vector3(0.16,0.17,0.18),
                corner_color,
                "steel" if level==3 else "stone")
            if damage==0:
                _part(layer,
                    "V20_CantoneraInferior_%s_%d_%d" % [tag,side,end],
                    Vector3(sx,0.35,sz),
                    Vector3(0.18,0.37,0.21),
                    corner_color,
                    "steel" if level==3 else "stone")
    if damage==1:
        # Wear belongs to contact points, not fresh intact wall planes.
        for side in [-1,1]:
            _part(layer,"V20_PicadoRevestimiento_%s_%d" % [tag,side],
                Vector3(x+float(side)*(w*0.5+0.138),0.82,z+d*0.29),
                Vector3(0.08,0.28,0.35),
                DUST if level<3 else STEEL)
    elif damage==2:
        for side in [-1,1]:
            var sx: float=x+float(side)*(w*0.5+0.18)
            var shard:=_part(layer,
                "V20_PiezaMuroCaida_%s_%d" % [tag,side],
                Vector3(sx,0.16,z+d*0.40),
                Vector3(0.39,0.16,0.52),
                CLAY_SHADE if level==1 else BRICK if level==2 else ZINC,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
            shard.rotation_degrees.y=float(side)*20.0

static func _ruin_edges(layer: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    if damage<3:
        return
    # Remove skyline ornament and rebuild only fallen/sagging pieces
    # anchored in the original lot, seen in true 360-degree geometry.
    var roof_color: Color=CLAY if level==1 else BRICK if level==2 else ZINC
    var floor_height: float=0.21 if damage==3 else 0.10
    var count: int=4 if damage==3 else 5
    for i in range(count):
        var px: float=x+(float(i%3)-1.0)*w*0.31
        var pz: float=z+(0.31 if i%2==0 else -0.29)*d
        var piece:=V14._sloped_slab(
            layer,"V20_LosaFracturada360_%s_%d" % [tag,i],
            Vector3(px,0.12,pz),
            0.48,0.43,floor_height,
            floor_height+0.13 if damage==3 else floor_height+0.06,
            roof_color if i%2==0 else DUST)
        piece.rotation_degrees.y=float(i)*23.0
        piece.material_override=V9._finish(
            roof_color if i%2==0 else DUST,
            "ceramic" if level==1 else "stone" if level==2 else "steel")
    # Scarred corner profiles are just fragments; no standing intact roof.
    for side in [-1,1]:
        var beam:=_part(layer,
            "V20_PerfilDerrumbe360_%s_%d" % [tag,side],
            Vector3(x+float(side)*w*0.36,
                0.19,z-d*0.34),
            Vector3(0.16,0.20,d*0.35),
            WOOD if level==1 else ASH if level==2 else STEEL,
            "steel" if level==3 else "stone")
        beam.rotation_degrees.z=float(side)*13.0
    if damage==4:
        for i in range(2):
            _part(layer,"V20_CascoteIdentidadTotal_%s_%d" % [tag,i],
                Vector3(x+(float(i)-0.5)*w*0.52,0.10,z+d*0.16),
                Vector3(0.45,0.16,0.33),
                CLAY_SHADE if level==1 else LIMESTONE if level==2
                else GLASS_BROKEN,
                "ceramic" if level==1 else "stone" if level==2 else "glass")

static func _city_edge_finish(stage: Node3D,
        level: int,damage: int) -> void:
    var edge:=V1._group(stage,"TransicionAcerasConjuntoV20")
    # Finish the two existing V19 alley-to-sidewalk contacts only;
    # keep all pieces outside z=-0.92..0.92 vehicle lane.
    for side in [-1,1]:
        for neighborhood in [-1,1]:
            var x: float=float(side)*2.47
            var z: float=float(neighborhood)*1.45
            if damage>=3:
                _part(edge,"V20_EnlaceAdoquinRoto_%d_%d" %
                    [side,neighborhood],
                    Vector3(x,0.096,z),
                    Vector3(0.49,0.17,0.25),RUBBLE)
                continue
            _part(edge,"V20_RemateBordillo_%d_%d" %
                [side,neighborhood],
                Vector3(x,0.142,z),
                Vector3(0.96,0.095,0.16),
                LIMESTONE if level<3 else CONCRETE)
            if damage==0 and level==3:
                _part(edge,"V20_JuntaMetalPasaje_%d_%d" %
                    [side,neighborhood],
                    Vector3(x,0.195,z),
                    Vector3(0.42,0.017,0.14),ZINC,"steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V19.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=Style.faction_color(faction) if faction>=0 else V1.NEUTRAL_ACCENT
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String="Sur_%d" % side if southern else "Norte_%d" % side
            var z: float=3.62 if southern else -3.80
            var w: float=2.77 if southern else 2.74
            var d: float=2.80 if southern else 2.84
            var floors: int=south_floors if southern else north_floors
            var part_group:=V1._group(stage,"AcabadosV20_"+tag)
            if damage<=2:
                var height: float=float(floors)*2.10+0.21
                match level:
                    1: _rooftop_villa(part_group,tag,x,z,w,d,height,damage)
                    2: _rooftop_town(part_group,tag,x,z,w,d,height,damage)
                    3: _rooftop_metro(part_group,tag,x,z,w,d,height,damage,accent)
                _facade_returns(part_group,tag,x,z,w,d,floors,level,damage)
            else:
                _ruin_edges(part_group,tag,x,z,w,d,level,damage)
    var civic_floor: int=2 if level==1 else 3 if level==2 else 4
    var civic_h: float=float(civic_floor)*2.10+0.21
    var civic:=V1._group(stage,"AcabadosV20_Ayuntamiento")
    if damage<=2:
        match level:
            1: _rooftop_villa(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,civic_h,damage)
            2: _rooftop_town(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,civic_h,damage)
            3: _rooftop_metro(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,civic_h,damage,accent)
        _facade_returns(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,civic_floor,level,damage)
    else:
        _ruin_edges(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,level,damage)
    _city_edge_finish(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",20)
    stage.set_meta("design_focus","four-facade-finishes-and-material-ruins")
    stage.set_meta("faction",faction)
    stage.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",20)
    model.set_meta("city_model_approved_final",false)
    return true
