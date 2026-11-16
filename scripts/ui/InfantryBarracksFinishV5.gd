extends RefCounted
class_name TarvokaInfantryBarracksFinishV5

# Final architectural contact check of the real Infantry Barracks 3D model.
# Additive, reversible pass over V1 + V2 + V3 + V4 only.
# Solves two previously measurable THREE-DIMENSIONAL overlaps in tier 3:
# 1. tower roof/base touching the west and east barracks wing ends;
# 2. the training orders board standing inside the far end of the course.
# Also finishes rear masonry corners and one exterior maintenance ladder.
# Purely visual: no game economy, build, battle or saved state changes.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V4=preload("res://scripts/ui/InfantryBarracksFacadeV4.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV5CierreEsquinasUnionesSinSolapes"

const TOWER_BACK_SHIFT_Z: float=0.45
const ORDERS_BOARD_SHIFT_Z: float=0.22
const REAR_WING_END_Z: float=2.905
const TOWER_TOP_DEPTH: float=2.15
const TOWER_PAD_DEPTH: float=1.62
const TRAINING_END_Z: float=2.51
const BEFORE_TOWER_Z: float=3.65

const GALV=Color("#84979d")
const DARK=Color("#40535b")
const WEATHER=Color("#726e64")
const SAFETY=Color("#e0bc61")
const FADED=Color("#9d8170")

static func _mark(parent: Node3D,label: String,at: Vector3,
        dimensions: Vector3,color: Color,kind: String="steel") -> void:
    V4._part(parent,label,at,dimensions,color,kind,0.38)

static func _finish_rear_corners(stage: Node3D,module: Dictionary,
        damage: int) -> void:
    var tag: String=str(module["tag"])
    var cx: float=float(module["x"])
    var cz: float=float(module["z"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var rear: float=cz+d*0.5
    var weathered: bool=damage>=1
    var color: Color=WEATHER if weathered else GALV
    var detail: Node3D=V1._group(stage,"UnionesEsquinaTerminadas_"+tag)
    # Real thin flashings where the segmented rear facade meets its
    # lateral masonry. No thick overlapping solid corner columns.
    for side in [-1,1]:
        var x: float=cx+float(side)*(w*0.5-0.14)
        _mark(detail,"JuntaEsquinaPosterior_%d" % side,
            Vector3(x,h*0.5,rear+0.183),
            Vector3(0.075,h-0.12,0.065),color)
        var drain_x: float=cx+float(side)*(w*0.5-0.37)
        _mark(detail,"BajanteAguaPosterior_%d" % side,
            Vector3(drain_x,h*0.46,rear+0.224),
            Vector3(0.065,h*0.90,0.072),color)
        for j in range(3):
            var y: float=0.48+(h-0.95)*float(j)*0.5
            _mark(detail,"AbrazaderaBajante_%d_%d" % [side,j],
                Vector3(drain_x,y,rear+0.268),
                Vector3(0.19,0.054,0.065),
                FADED if weathered else DARK)
    detail.set_meta("sealed_rear_corners",2)

static func _roof_level_seals(stage: Node3D,module: Dictionary,
        level: int,damage: int) -> void:
    if damage!=0 or level<2:
        return
    var tag: String=str(module["tag"])
    var cx: float=float(module["x"])
    var cz: float=float(module["z"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var label: Node3D=V1._group(stage,"ServicioTechoTerminado_"+tag)
    var count: int=1 if level==2 else 2
    for i in range(count):
        var x: float=cx+(float(i)-(float(count)-1.0)*0.5)*1.03
        var roof_z: float=cz+d*0.22
        # V4 fan grille already sits at h+0.855. The cap lip sits
        # slightly higher than the existing grille and does not seal it.
        _mark(label,"MarcoRejillaVentilador_%d" % i,
            Vector3(x,h+0.902,roof_z),
            Vector3(0.58,0.030,0.47),GALV)
        for side in [-1,1]:
            _mark(label,"UnionPernoVentilador_%d_%d" % [i,side],
                Vector3(x+float(side)*0.27,h+0.913,roof_z),
                Vector3(0.055,0.035,0.052),DARK)
    label.set_meta("serviced_fans",count)

static func _outside_maintenance_ladder(stage: Node3D,
        level: int,damage: int,accent: Color) -> void:
    # A permanent ladder makes sense only on tier 3's eastern TWO-storey
    # wing, NOT tier 1 and NOT the one-floor lateral wing of tier 2.
    if level!=3 or damage>=2:
        return
    var module: Dictionary=V2._modules(level)[2]
    var facade_x: float=float(module["x"])+float(module["w"])*0.5
    var z: float=float(module["z"])+float(module["d"])*0.5-0.37
    # The last side window ends before z~1.85; this service shaft starts
    # at z>2.17, so the ladder cannot pass through any glass aperture.
    var width: float=0.60
    var wall_x: float=facade_x+0.31
    var h: float=float(module["h"])
    var rails:=V1._group(stage,"EscaleraExteriorMantenimientoN3")
    for side in [-1,1]:
        _mark(rails,"RailVerticalMantenimiento_%d" % side,
            Vector3(wall_x,h*0.48,z+float(side)*width*0.5),
            Vector3(0.075,h*0.91,0.075),
            FADED if damage==1 else GALV)
    for i in range(12):
        if damage==1 and i in [4,9]:
            continue
        var y: float=0.43+float(i)*0.345
        _mark(rails,"PeldañoMantenimiento_%d" % i,
            Vector3(wall_x,y,z),
            Vector3(0.075,0.055,width+0.02),
            FADED if damage==1 else GALV)
    for i in range(3):
        _mark(rails,"AnclajeParedEscalera_%d" % i,
            Vector3(facade_x+0.15,0.86+float(i)*1.39,z),
            Vector3(0.34,0.08,0.08),DARK)
    _mark(rails,"RemateAntideslizanteEscalera",
        Vector3(wall_x,h-0.30,z),
        Vector3(0.10,0.16,width+0.04),DARK)
    _mark(rails,"SeñalPrecaucionFaccion",
        Vector3(facade_x+0.19,0.30,z-0.53),
        Vector3(0.04,0.17,0.35),accent)
    rails.set_meta("glass_clearance",true)
    rails.set_meta("exterior_only",true)

static func _tier_three_contact(model: Node3D,stage: Node3D,
        damage: int) -> bool:
    if damage>=4:
        return true
    var moved: int=0
    for tower in ["TorreOesteNivel3","TorreEsteNivel3"]:
        var first_name: String=tower if damage<=2 else "BaseTorreCaida_"+tower
        var original: Node3D=model.find_child(
            first_name,true,false) as Node3D
        var details: Node3D=model.find_child(
            "Detalles_"+tower,true,false) as Node3D
        if original==null or details==null:
            return false
        original.position.z+=TOWER_BACK_SHIFT_Z
        details.position.z+=TOWER_BACK_SHIFT_Z
        moved+=1
    if damage<=1:
        var signage: Node3D=model.find_child(
            "SenalizacionEntrenamientoV4",true,false) as Node3D
        if signage==null:
            return false
        signage.position.z+=ORDERS_BOARD_SHIFT_Z
        signage.set_meta("outside_training_course",true)
    var platform_front: float=BEFORE_TOWER_Z+TOWER_BACK_SHIFT_Z-TOWER_TOP_DEPTH*0.5
    var base_front: float=BEFORE_TOWER_Z+TOWER_BACK_SHIFT_Z-TOWER_PAD_DEPTH*0.5
    var board_end: float=2.46+ORDERS_BOARD_SHIFT_Z+0.17*0.5
    stage.set_meta("tower_clearance_from_wing_m",platform_front-REAR_WING_END_Z)
    stage.set_meta("tower_footing_clearance_m",base_front-REAR_WING_END_Z)
    stage.set_meta("board_clearance_from_tower_m",platform_front-board_end)
    stage.set_meta("moved_tower_count",moved)
    stage.set_meta("training_end_z",TRAINING_END_Z)
    stage.set_meta("board_center_z",2.46+ORDERS_BOARD_SHIFT_Z)
    return platform_front>REAR_WING_END_Z+0.10 and         base_front>REAR_WING_END_Z+0.30 and         board_end<platform_front-0.20 and         2.46+ORDERS_BOARD_SHIFT_Z>TRAINING_END_Z+0.12

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V2.STAGE_NAME) or             not model.has_node(V3.STAGE_NAME) or             not model.has_node(V4.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level or             int(model.get_meta("visual_faction",-1))!=faction or             int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage:=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("tier",level)
    stage.set_meta("faction",faction)
    stage.set_meta("damage",damage)
    stage.set_meta("finish_version",5)
    stage.set_meta("three_architectures_preserved",true)
    stage.set_meta("economy_unchanged",true)
    if damage==4:
        stage.set_meta("ruins_only",true)
        return true
    if level==3:
        if not _tier_three_contact(model,stage,damage):
            return false
    if damage>=3:
        stage.set_meta("ruins_only",false)
        return true
    for module in V2._modules(level):
        _finish_rear_corners(stage,module,damage)
        _roof_level_seals(stage,module,level,damage)
    _outside_maintenance_ladder(stage,level,damage,
        Style.faction_color(faction))
    stage.set_meta("rear_corner_groups",V2._modules(level).size())
    stage.set_meta("ruins_only",false)
    return true

static func mesh_count(model: Node3D) -> int:
    var stage: Node3D=model.get_node_or_null(STAGE_NAME) as Node3D
    return 0 if stage==null else V1.mesh_count(stage)
