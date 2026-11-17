extends RefCounted
class_name TarvokaCivilianCitySideJointsV18

# V18 CITY ART: continuous three-dimensional SIDE elevations and physical
# joints at roof/eaves, wall corners and the existing pedestrian accesses.
# Visual only. No economy, capture, collision, site footprint or units change.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V17=preload("res://scripts/ui/CivilianCityRearFinishV17.gd")
const STAGE_NAME="CiudadCivilV18CostadosYEncuentrosCubiertaAcera"

const STONE=Color("#c4b7a2")
const MORTAR=Color("#a49b8c")
const TERRACOTTA=Color("#aa6751")
const TIMBER=Color("#80654e")
const BRICK=Color("#96715f")
const ZINC=Color("#73858a")
const GLASS=Color("#567b89")
const DARK=Color("#364951")
const ROAD_EDGE=Color("#8c928a")
const DUST=Color("#776e64")
const CHAR=Color("#464948")

static func _part(parent: Node3D,label: String,at: Vector3,
        size: Vector3,tint: Color,finish: String="stone") -> MeshInstance3D:
    var node: MeshInstance3D=V1._box(parent,label,at,size,tint)
    node.material_override=V9._finish(tint,finish)
    return node

static func _side_walls(stage: Node3D,tag: String,x: float,z: float,
        w: float,d: float,floors: int,level: int,damage: int) -> void:
    var group:=V1._group(stage,"ElevacionesLateralesV18_"+tag)
    var height: float=float(floors)*2.10+0.21
    for side in [-1,1]:
        var outward: float=float(side)
        var wall_x: float=x+outward*(w*0.5+0.068)
        if damage>=3:
            # Collapsed flank: low, physically grounded rubble only.
            for i in range(3):
                var rubble:=_part(group,
                    "V18_EscombroCostado_%s_%d_%d" % [tag,side,i],
                    Vector3(wall_x+outward*0.17,0.11+float(i%2)*0.08,
                        z+(float(i)-1.0)*d*0.27),
                    Vector3(0.38,0.22,0.49),
                    DUST if i%2==0 else CHAR)
                rubble.rotation_degrees.y=float(i)*17.0
            continue
        var edge_color: Color=TIMBER if level==1 else BRICK if level==2 else ZINC
        # End corner piers connect the north and south facades continuously.
        for end in [-1,1]:
            _part(group,"V18_CantoneraCostado_%s_%d_%d" % [tag,side,end],
                Vector3(wall_x,z*0.0+height*0.5,
                    z+float(end)*d*0.47),
                Vector3(0.15,height*0.94,0.16),edge_color,
                "steel" if level==3 else "stone")
        for floor in range(floors):
            var yy: float=1.02+float(floor)*2.10
            if yy+0.42>height:
                continue
            for window in [-1,1]:
                # Existing V1 right-side window remains; V18 provides
                # a full framed pair on each elevation, not flat decals.
                if damage==2 and (floor+window+side+9)%3==0:
                    continue
                var wz: float=z+float(window)*d*0.235
                var frame:=_part(group,
                    "V18_MarcoVentanaLateral_%s_%d_%d_%d" %
                    [tag,side,floor,window],
                    Vector3(wall_x+outward*0.054,yy,wz),
                    Vector3(0.17,0.89,0.68),edge_color,
                    "steel" if level==3 else "stone")
                frame.rotation_degrees.y=0.0
                _part(group,
                    "V18_CristalCostado_%s_%d_%d_%d" %
                    [tag,side,floor,window],
                    Vector3(wall_x+outward*0.160,yy,wz),
                    Vector3(0.035,0.64,0.48),
                    GLASS if damage<2 else CHAR,"glass")
                _part(group,
                    "V18_AlfeizarCostado_%s_%d_%d_%d" %
                    [tag,side,floor,window],
                    Vector3(wall_x+outward*0.115,yy-0.47,wz),
                    Vector3(0.33,0.085,0.77),STONE)
        if damage==2:
            _part(group,"V18_FracturaEsquina_%s_%d" % [tag,side],
                Vector3(wall_x,height*0.68,z+d*0.38),
                Vector3(0.21,0.66,0.12),CHAR)
            continue
        # Horizontal floor-band provides visible front-to-back continuity.
        if level>=2:
            for floor in range(1,floors):
                _part(group,"V18_FajaLateral_%s_%d_%d" % [tag,side,floor],
                    Vector3(wall_x+outward*0.037,float(floor)*2.10,z),
                    Vector3(0.16,0.12,d*0.88),
                    MORTAR if level==2 else ZINC,
                    "stone" if level==2 else "steel")

static func _eave_and_roof(stage: Node3D,tag: String,x: float,z: float,
        w: float,d: float,floors: int,level: int,damage: int) -> void:
    var group:=V1._group(stage,"EncuentroCubiertaMuroV18_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage>=3:
        # Do not reconstruct a roof over destroyed foundations.
        for edge in [-1,1]:
            var tile:=_part(group,
                "V18_RestoCubiertaCaida_%s_%d" % [tag,edge],
                Vector3(x+float(edge)*w*0.25,0.14,z+d*0.29),
                Vector3(w*0.24,0.16,d*0.22),
                TERRACOTTA if level==1 else BRICK if level==2 else ZINC,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
            tile.rotation_degrees.z=float(edge)*12.0
        return
    var trim: Color=TERRACOTTA if level==1 else STONE if level==2 else ZINC
    for edge in [-1,1]:
        # A shallow overhang connects each real wall face to the roof edge.
        var sx: float=x+float(edge)*w*0.49
        var slab:=_part(group,"V18_AleroLateral_%s_%d" % [tag,edge],
            Vector3(sx,h+0.13,z),Vector3(0.37,0.15,d+0.24),
            trim,"ceramic" if level==1 else "stone" if level==2 else "steel")
        if damage==2:
            slab.scale.z=0.59
            slab.position.z=z-d*0.19
        if damage==0:
            # Small vertical fascia is only needed at intimate camera zoom.
            _part(group,"V18_FasciaAlero_%s_%d" % [tag,edge],
                Vector3(sx+float(edge)*0.14,h+0.03,z),
                Vector3(0.10,0.17,d*0.88),TIMBER if level==1 else MORTAR)
    # Front / back roof seams stop at the real masonry outline.
    for end in [-1,1]:
        if damage==2 and end==1:
            continue
        _part(group,"V18_EncuentroTejadoFachada_%s_%d" % [tag,end],
            Vector3(x,h+0.13,z+float(end)*d*0.48),
            Vector3(w+0.13,0.15,0.18),trim,
            "ceramic" if level==1 else "stone" if level==2 else "steel")
    if damage==2:
        _part(group,"V18_FragmentoCanalonDesprendido_"+tag,
            Vector3(x+w*0.27,0.18,z-d*0.54),
            Vector3(0.91,0.13,0.25),DUST)

static func _pavement_contact(stage: Node3D,level: int,damage: int) -> void:
    var group:=V1._group(stage,"EncuentrosPeatonalesV18")
    if damage>=3:
        # A damaged street retains depressed/broken edges.
        for side in [-1,1]:
            _part(group,"V18_BordilloPartido_%d" % side,
                Vector3(float(side)*4.63,0.10,1.32),
                Vector3(0.83,0.13,0.19),DUST)
        return
    # Existing V10 paths already connect houses + town hall to the road.
    # Sculpt their narrow contact seams only: no duplicate paving blocks.
    for zsign in [-1,1]:
        var s: float=float(zsign)
        for side in [-1,0,1]:
            if side==0 and zsign>0:
                # The municipal rear door is on the northern roadside.
                continue
            if side!=0 and zsign<0:
                # South-side housing has the front path to the south.
                continue
            var x: float=float(side)*4.63
            var width: float=1.78 if side==0 else 1.39
            _part(group,
                "V18_JuntaAdoquinAcceso_%d_%d" % [side,zsign],
                Vector3(x,0.137,s*1.36),
                Vector3(width,0.055,0.14),
                STONE if damage==0 else DUST)
            if damage==0 and level>=2:
                for edge in [-1,1]:
                    _part(group,
                        "V18_DrenajeUmbral_%d_%d_%d" % [side,zsign,edge],
                        Vector3(x+float(edge)*width*0.38,
                            0.146,s*1.46),
                        Vector3(0.10,0.025,0.27),ROAD_EDGE,"steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V17.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var rear_floors: int=1 if level==1 else 2 if level==2 else 4
    var front_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String="Sur_%d" % side if southern else "Norte_%d" % side
            var z: float=3.62 if southern else -3.80
            var w: float=2.77 if southern else 2.74
            var d: float=2.80 if southern else 2.84
            var floors: int=front_floors if southern else rear_floors
            _side_walls(stage,tag,x,z,w,d,floors,level,damage)
            _eave_and_roof(stage,tag,x,z,w,d,floors,level,damage)
    var civic_floors: int=2 if level==1 else 3 if level==2 else 4
    _side_walls(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        civic_floors,level,damage)
    _eave_and_roof(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        civic_floors,level,damage)
    _pavement_contact(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",18)
    stage.set_meta("style","side-elevations/roof-to-wall/pedestrian-contacts")
    model.set_meta("city_art_work_in_progress",18)
    model.set_meta("city_model_approved_final",false)
    return true
