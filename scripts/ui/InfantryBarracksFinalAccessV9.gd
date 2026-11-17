extends RefCounted
class_name TarvokaInfantryBarracksFinalAccessV9

# TARVOKA infantry barracks: additive V9 VISUAL ONLY door, stair, window-cap
# and broken-entrance detail pass for the existing shared Godot 3D Studio.
# No new buildings, map footprint, physics, supply, capture or production.
# Existing V1-V8 silhouettes, training corridor and tower clearance remain.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V7=preload("res://scripts/ui/InfantryBarracksSideTowersV7.gd")
const V8=preload("res://scripts/ui/InfantryBarracksTowerFinishV8.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const STAGE_NAME="InfanteriaV9AccesosVentanasDanioRevisados"
const GUNMETAL=Color("#43575d")
const BLACK=Color("#25343b")
const BRIGHT_METAL=Color("#9babad")
const SAFETY=Color("#c5ac68")
const GLASS=Color("#5a7984")
const SCAR=Color("#8f6b5b")

static func _part(root: Node3D,label: String,at: Vector3,
        dimensions: Vector3,color: Color,metal: float=0.27) -> void:
    Base._box(root,label,at,dimensions,color,metal)

static func _entry(stage: Node3D,module: Dictionary,damage: int,
        accent: Color) -> void:
    var tag: String=str(module["tag"])
    var cx: float=float(module["x"])
    var front: float=float(module["z"])-float(module["d"])*0.5
    var width: float=1.70 if bool(module["primary"]) else 1.30
    var root:=Base._group(stage,"AccesoTerminadoV9_"+tag)
    if damage>=3:
        # The original V1/V2 wall is fractured. Do NOT resurrect a door.
        return
    if damage==2:
        # One short ruined metal strip on the existing V2 stair,
        # not a pristine rail or a duplicate V2 entrance threshold.
        _part(root,"BisagraDanadaV9",Vector3(cx+width*0.31,
            0.40,front-0.155),Vector3(0.09,0.34,0.06),SCAR,0.16)
        return
    # Original door panel lies at z=front+0.04. The older V2 door
    # hardware lies in front of it. These tiny pieces occupy only
    # the actual doorway, never the adjacent wall or V5 bollards.
    var tint: Color=GUNMETAL if damage==0 else SCAR
    _part(root,"JuntaCentralPuertaV9",
        Vector3(cx,1.30,front-0.135),
        Vector3(0.024,1.20,0.032),BLACK,0.20)
    for side in [-1,1]:
        for row in range(2):
            _part(root,"BisagraPuertaV9_%d_%d" % [side,row],
                Vector3(cx+float(side)*width*0.325,
                    0.74+float(row)*0.92,front-0.14),
                Vector3(0.095,0.13,0.075),tint,0.43)
    # A compact observation slot retains the imposing military door.
    _part(root,"MarcoMirillaAccesoV9",
        Vector3(cx-width*0.18,1.61,front-0.142),
        Vector3(0.42,0.24,0.048),tint,0.36)
    _part(root,"CristalMirillaAccesoV9",
        Vector3(cx-width*0.18,1.61,front-0.177),
        Vector3(0.30,0.14,0.025),GLASS if damage==0 else BLACK,0.14)
    # Thin antislip tread strips lie ABOVE pre-existing V2 steps:
    # lower top y=0.145; upper top y=0.240.
    _part(root,"BandaAntideslizanteBajaV9",
        Vector3(cx,0.154,front-0.69),
        Vector3(width+0.41,0.018,0.053),
        SAFETY if damage==0 else SCAR,0.16)
    _part(root,"BandaAntideslizanteAltaV9",
        Vector3(cx,0.249,front-0.45),
        Vector3(width+0.17,0.018,0.048),
        SAFETY if damage==0 else SCAR,0.16)
    if damage==0:
        # Small faction code, not a solid plate over the original door.
        _part(root,"MarcaAccesoFaccionV9",
            Vector3(cx+width*0.31,1.77,front-0.155),
            Vector3(0.075,0.27,0.036),accent,0.13)
    else:
        _part(root,"RasponAccesoV9",
            Vector3(cx+width*0.13,0.84,front-0.159),
            Vector3(0.10,0.31,0.037),SCAR,0.10)

static func _windows(stage: Node3D,model: Node3D,
        level: int,damage: int) -> void:
    if damage>=2:
        return
    var v7: Node3D=model.get_node(V7.STAGE_NAME) as Node3D
    if v7==null:
        return
    for lateral in v7.get_children():
        if not str(lateral.name).begins_with("FachadaLateralV7_"):
            continue
        var side: int=int(lateral.get_meta("side_direction",0))
        if side==0:
            continue
        var tag: String=str(lateral.name).trim_prefix("FachadaLateralV7_")
        var module: Dictionary={}
        for candidate in V2._modules(level):
            if str(candidate["tag"])==tag:
                module=candidate
                break
        if module.is_empty():
            continue
        var outer: float=float(module["x"])+float(side)*float(module["w"])*0.5
        var count: int=0
        for mesh in lateral.get_children():
            if not mesh is MeshInstance3D:
                continue
            if not str(mesh.name).begins_with("CristalLateralV7_"):
                continue
            var pane: MeshInstance3D=mesh as MeshInstance3D
            _part(stage,"GoteronSuperiorVentanaV9_"+tag+"_%d" % count,
                Vector3(outer+float(side)*0.21,
                    pane.position.y+0.574,pane.position.z),
                Vector3(0.108,0.062,1.10),
                BRIGHT_METAL if damage==0 else SCAR,0.40)
            count+=1

static func _broken_door(stage: Node3D,module: Dictionary,damage: int) -> void:
    if damage!=3:
        return
    var cx: float=float(module["x"])
    var front: float=float(module["z"])-float(module["d"])*0.5
    var width: float=1.70 if bool(module["primary"]) else 1.30
    # A short fallen jamb below existing V1 fractured lintel; no intact
    # doorway, glazing or steps are introduced in damaged state 3.
    _part(stage,"RestosMarcoEntradaV9_"+str(module["tag"]),
        Vector3(cx-width*0.20,0.20,front-0.37),
        Vector3(0.12,0.12,0.66),SCAR,0.24)

static func _paint(stage: Node3D,accent: Color) -> void:
    var textured: int=0
    var faction: int=0
    var pending: Array[Node]=[stage]
    while not pending.is_empty():
        var current: Node=pending.pop_back()
        for node in current.get_children():
            pending.append(node)
            if not node is MeshInstance3D:
                continue
            var mesh: MeshInstance3D=node as MeshInstance3D
            var mat: StandardMaterial3D=mesh.material_override as StandardMaterial3D
            if mat==null:
                continue
            if mat.albedo_color.is_equal_approx(accent):
                faction+=1
                continue
            var material_kind: String="steel"
            if str(mesh.name).contains("Cristal"):
                material_kind="glass"
            elif str(mesh.name).contains("Restos"):
                material_kind="rubble"
            mesh.material_override=V3._finish_material(mat,material_kind)
            textured+=1
    stage.set_meta("pbr_meshes",textured)
    stage.set_meta("faction_paint_preserved",faction)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V8.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-1))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        var accent: Color=Style.faction_color(faction)
        for module in V2._modules(level):
            _entry(stage,module,damage,accent)
            _broken_door(stage,module,damage)
        _windows(stage,model,level,damage)
        _paint(stage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("detail_version",9)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    return true
