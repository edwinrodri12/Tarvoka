extends RefCounted
class_name TarvokaInfantryBarracksEntranceYardV5

# Reversible visual-only V5, native Godot 4.3 geometry.
# No extra buildings, unit production logic, collision or gameplay changes.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V4=preload("res://scripts/ui/InfantryBarracksRearFacadeV4.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV5AccesosPatioFormacion"
const STEEL=Color("#556b72")
const STONE=Color("#9aa59e")
const PAVEMENT=Color("#697c79")
const HIGHLIGHT=Color("#d0b56f")
const GLASS=Color("#aec5c2")
const RUST=Color("#8f6150")

static func _part(parent: Node3D,label: String,at: Vector3,
        dimensions: Vector3,tint: Color,metal: float=0.2) -> void:
    Base._box(parent,label,at,dimensions,tint,metal)

static func _entrance(stage: Node3D,module: Dictionary,
        damage: int,accent: Color) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])-float(module["d"])*0.5
    var main: bool=bool(module["primary"])
    var width: float=1.70 if main else 1.30
    var root:=Base._group(stage,"AccesoPatioV5_"+tag)
    if damage>=3:
        _part(root,"UmbralQuebradoV5",
            Vector3(x,0.12,z-0.81),
            Vector3(width+0.18,0.11,0.20),RUST)
        return
    # Details straddle the existing V2 stair WITHOUT covering the door.
    for side in [-1,1]:
        _part(root,"BolardoAcceso_%d" % side,
            Vector3(x+float(side)*(width*0.5+0.62),0.34,z-1.04),
            Vector3(0.15,0.68,0.15),STEEL,0.34)
        if damage<=1:
            _part(root,"CapuchonBolardo_%d" % side,
                Vector3(x+float(side)*(width*0.5+0.62),0.71,z-1.04),
                Vector3(0.20,0.07,0.20),HIGHLIGHT,0.21)
    # Ground stripes are low enough to avoid obscuring existing stair.
    for i in range(2):
        _part(root,"LineaAcceso_%d" % i,
            Vector3(x+float(i*2-1)*width*0.30,0.061,z-1.34),
            Vector3(0.065,0.012,0.42),
            RUST if damage==2 else HIGHLIGHT,0.06)
    if damage==2:
        return
    if main:
        # Slim original faction-colored chevrons, not a giant roof sign.
        for side in [-1,1]:
            _part(root,"InsigniaLateral_%d" % side,
                Vector3(x+float(side)*(width*0.5+0.20),2.23,z-0.32),
                Vector3(0.10,0.38,0.065),accent,0.14)
        _part(root,"LuzEntradaProtegida",
            Vector3(x,2.57,z-0.83),
            Vector3(0.43,0.08,0.14),GLASS,0.18)

static func _formation(stage: Node3D,level: int,damage: int) -> void:
    if damage>=3:
        return
    var yard:=Base._group(stage,"PatioFormacionV5")
    # Existing common paving spans x=-5.55..5.55, z=-5.975..-0.825.
    # Place low, narrow markings solely in front half and inside boundaries.
    if level==3:
        # N3 central U courtyard has a separate raised paving polygon:
        # avoid placing higher decorative slabs over its deployment lanes.
        for i in range(3):
            _part(yard,"MarcacionCentroU_%d" % i,
                Vector3(-1.74+float(i)*1.74,0.133,-2.91),
                Vector3(0.55,0.012,0.075),HIGHLIGHT,0.04)
        return
    for i in range(3):
        _part(yard,"MarcaPuestoFormacion_%d" % i,
            Vector3(-2.57+float(i)*2.57,0.051,-5.53),
            Vector3(0.50,0.012,0.070),
            RUST if damage==2 else HIGHLIGHT,0.06)
    if damage==0:
        _part(yard,"BandaDeSeguridadPatio",
            Vector3(0,0.051,-5.74),
            Vector3(5.50,0.012,0.060),STONE,0.04)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V4.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level or \
            int(model.get_meta("visual_faction",-1))!=faction or \
            int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        var accent: Color=Style.faction_color(faction)
        for module in V2._modules(level):
            _entrance(stage,module,damage,accent)
        _formation(stage,level,damage)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    stage.set_meta("finish_version",5)
    stage.set_meta("visual_only",true)
    stage.set_meta("training_corridor_preserved",true)
    return true

# Pixel-density driven visibility for true 3D parts. No generated sprites.
# Retain silhouette and bollards at a wide tactical view; bring back the
# small stripes, light and ornaments automatically when zooming in.
const FINE_DETAIL_PREFIXES=["CapuchonBolardo_","LineaAcceso_",
    "InsigniaLateral_","LuzEntradaProtegida","MarcaPuestoFormacion_",
    "BandaDeSeguridadPatio","MarcacionCentroU_"]

static func set_detail_lod(model: Node3D,near_view: bool) -> int:
    if model==null:
        return 0
    var stage: Node3D=model.get_node_or_null(STAGE_NAME) as Node3D
    if stage==null:
        return 0
    var affected: int=0
    var pending: Array[Node]=[stage]
    while not pending.is_empty():
        var current: Node=pending.pop_back()
        for child in current.get_children():
            pending.append(child)
            if not child is MeshInstance3D:
                continue
            var piece: MeshInstance3D=child as MeshInstance3D
            var named: String=str(piece.name)
            for prefix in FINE_DETAIL_PREFIXES:
                if named.begins_with(prefix):
                    piece.visible=near_view
                    affected+=1
                    break
    stage.set_meta("lod_near",near_view)
    stage.set_meta("lod_fine_meshes",affected)
    return affected
