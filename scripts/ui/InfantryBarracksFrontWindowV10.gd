extends RefCounted
class_name TarvokaInfantryBarracksFrontWindowV10

# Additive 3D art stage. The original V1 panes and V2 central mullions
# remain visible; V10 builds only edge depth, sill noses and weathered
# fastening details. Fully destroyed geometry cannot be reconstructed.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V9=preload("res://scripts/ui/InfantryBarracksFinalAccessV9.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const STAGE_NAME="InfanteriaV10VentanasFrontalesEnProfundidad"
const FRAME=Color("#536970")
const METAL_EDGE=Color("#9cacb1")
const RECESS=Color("#293d42")
const WEAR=Color("#96715e")
const CLAMP=Color("#b2a88b")

static func _part(root: Node3D,label: String,at: Vector3,
        dims: Vector3,tint: Color,metal: float=0.30) -> void:
    Base._box(root,label,at,dims,tint,metal)

static func _module_front(stage: Node3D,module: Dictionary,
        damage: int) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])-float(module["d"])*0.5
    var w: float=float(module["w"])
    var h: float=float(module["h"])
    var floors: int=int(module["floors"])
    var door: float=1.70 if bool(module["primary"]) else 1.30
    var seg: float=(w-door)*0.5
    var pane_width: float=minf(1.0,seg*0.48)
    var node:=Base._group(stage,"MarcosFrontalesV10_"+tag)
    if damage>=3:
        return
    for floor in range(floors):
        var sill: float=0.70+float(floor)*2.22
        if sill+0.90>=h:
            continue
        var y: float=sill+0.48
        for side in [-1,1]:
            var suffix: String="%d_%d" % [floor,side]
            var pane_x: float=x+float(side)*(door*0.5+seg*0.54)
            if damage==2:
                # Damage 2 has bent original sills and charred V1 glass.
                # A physical loose clamp is added, not an intact frame.
                _part(node,"GrapaSueltaV10_"+suffix,
                    Vector3(pane_x+pane_width*0.38,
                        sill-0.040,z-0.327),
                    Vector3(0.13,0.16,0.06),WEAR,0.16)
                continue
            var edge_x: float=pane_width*0.5+0.048
            var edge_z: float=z-0.292
            var tint: Color=FRAME if damage==0 else WEAR
            # The four slim 3D perimeter rails leave the original V1
            # glass and the central V2 cross-mullion physically visible.
            _part(node,"DintelExteriorVentanaV10_"+suffix,
                Vector3(pane_x,y+0.451,edge_z),
                Vector3(pane_width+0.21,0.074,0.075),tint,0.41)
            _part(node,"PerfilInferiorVentanaV10_"+suffix,
                Vector3(pane_x,y-0.451,edge_z),
                Vector3(pane_width+0.21,0.074,0.075),tint,0.40)
            for edge in [-1,1]:
                _part(node,"JambaFrontalV10_"+suffix+"_"+str(edge),
                    Vector3(pane_x+float(edge)*edge_x,y,edge_z),
                    Vector3(0.072,0.89,0.075),tint,0.40)
            # Exterior ledge is beyond the V1 front pane and below glass,
            # while the existing V2 central mullion remains unchanged.
            _part(node,"AlfeizarEnProfundidadV10_"+suffix,
                Vector3(pane_x,y-0.535,z-0.328),
                Vector3(pane_width+0.24,0.083,0.29),
                METAL_EDGE if damage==0 else WEAR,0.32)
            if damage==1:
                _part(node,"SelloDesgastadoV10_"+suffix,
                    Vector3(pane_x+pane_width*0.19,y+0.429,z-0.333),
                    Vector3(0.19,0.038,0.045),CLAMP,0.12)

static func _finish(stage: Node3D) -> void:
    var painted: int=0
    var pending: Array[Node]=[stage]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
            if not child is MeshInstance3D:
                continue
            var mesh: MeshInstance3D=child as MeshInstance3D
            var mat: StandardMaterial3D=mesh.material_override as StandardMaterial3D
            if mat==null:
                continue
            mesh.material_override=V3._finish_material(mat,"steel")
            painted+=1
    stage.set_meta("pbr_meshes",painted)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V9.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-1))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        for module in V2._modules(level):
            _module_front(stage,module,damage)
        _finish(stage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("front_window_depth_version",10)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    return true
