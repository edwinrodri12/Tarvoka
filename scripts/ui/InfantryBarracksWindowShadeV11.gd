extends RefCounted
class_name TarvokaInfantryBarracksWindowShadeV11

# Architectural front-window weather shades: visual-only native 3D.
# Independent, reversible layer after V10. Do not change any playable
# construction, production, capture, health, or tactical map footprints.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V10=preload("res://scripts/ui/InfantryBarracksFrontWindowV10.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV11ViserasProtectorasVentanas"
const STEEL=Color("#566a70")
const SHADOW=Color("#273e48")
const EDGE=Color("#a7b4b4")
const OXIDE=Color("#986b5b")
const DARK=Color("#354d55")

static func _part(stage: Node3D,part_name: String,
        at: Vector3,size: Vector3,tint: Color,
        metal: float=0.34) -> void:
    Base._box(stage,part_name,at,size,tint,metal)

static func _window(stage: Node3D,module: Dictionary,
        level: int,damage: int,accent: Color) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])-float(module["d"])*0.5
    var w: float=float(module["w"])
    var h: float=float(module["h"])
    var door: float=1.70 if bool(module["primary"]) else 1.30
    var segment: float=(w-door)*0.5
    var pane_width: float=minf(1.0,segment*0.48)
    var floors: int=int(module["floors"])
    var node:=Base._group(stage,"ViserasModuloV11_"+tag)
    node.set_meta("module_tag",tag)
    var projection: float=0.29 if level==1 else 0.40 if level==2 else 0.48
    for floor in range(floors):
        var sill: float=0.70+float(floor)*2.22
        if sill+0.90>=h:
            continue
        var y: float=sill+0.48
        for side in [-1,1]:
            var suffix: String="%d_%d" % [floor,side]
            var cx: float=x+float(side)*(door*0.5+segment*0.54)
            if damage>=3:
                continue
            if damage==2:
                # Destroyed canopy: only one twisted mounting plate per pane.
                # Existing V1 glass remains dark and its V10 perimeter absent.
                _part(node,"FijacionArrancadaV11_"+suffix,
                    Vector3(cx+pane_width*0.40,y+0.61,z-0.31),
                    Vector3(0.14,0.10,0.08),OXIDE,0.20)
                continue
            var removed: bool=(damage==1 and
                (floor+(1 if side==1 else 0))%3==0)
            if removed:
                _part(node,"BisagraViseraRotaV11_"+suffix,
                    Vector3(cx-pane_width*0.32,y+0.55,z-0.34),
                    Vector3(0.15,0.11,0.07),OXIDE,0.18)
                continue
            var shade_y: float=y+0.635
            var shade_z: float=z-0.40-projection*0.38
            var canopy_width: float=pane_width+0.27
            var tint: Color=STEEL if damage==0 else OXIDE
            # A thin horizontal shade starts above the upper V10 frame.
            # Underside at y+0.592, versus V10 top frame y+0.488:
            # no intersection and original glass stays 100% visible.
            _part(node,"ViseraMetalV11_"+suffix,
                Vector3(cx,shade_y,shade_z),
                Vector3(canopy_width,0.085,projection),tint,0.40)
            _part(node,"BordeFrontalViseraV11_"+suffix,
                Vector3(cx,shade_y-0.006,shade_z-projection*0.5),
                Vector3(canopy_width+0.045,0.11,0.057),
                EDGE if damage==0 else OXIDE,0.36)
            for edge in [-1,1]:
                _part(node,"SoporteViseraV11_"+suffix+"_"+str(edge),
                    Vector3(cx+float(edge)*pane_width*0.41,
                        y+0.546,z-0.319),
                    Vector3(0.068,0.132,0.09),
                    STEEL if damage==0 else OXIDE,0.38)
            # Higher-level military wings gain a slim identification line,
            # explicitly different from N1's plain utilitarian shades.
            if level>=2 and damage==0:
                _part(node,"LineaFaccionViseraV11_"+suffix,
                    Vector3(cx,shade_y+0.010,
                        shade_z-projection*0.5-0.039),
                    Vector3(pane_width*0.48,0.050,0.035),
                    accent,0.12)
            if damage==0:
                # Discreet drainage beneath the existing V10 sill.
                _part(node,"BoquillaDrenajeV11_"+suffix,
                    Vector3(cx+pane_width*0.37,y-0.598,z-0.443),
                    Vector3(0.073,0.065,0.087),DARK,0.34)

static func _paint(stage: Node3D,accent: Color) -> void:
    var finished: int=0
    var faction_paint: int=0
    var stack: Array[Node]=[stage]
    while not stack.is_empty():
        var parent: Node=stack.pop_back()
        for child in parent.get_children():
            stack.append(child)
            if not child is MeshInstance3D:
                continue
            var mesh: MeshInstance3D=child as MeshInstance3D
            var material: StandardMaterial3D=mesh.material_override as StandardMaterial3D
            if material==null:
                continue
            if material.albedo_color.is_equal_approx(accent):
                faction_paint+=1
                continue
            mesh.material_override=V3._finish_material(material,"steel")
            finished+=1
    stage.set_meta("pbr_textured_meshes",finished)
    stage.set_meta("faction_accents_preserved",faction_paint)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V10.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-1))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        var accent: Color=Style.faction_color(faction)
        for module in V2._modules(level):
            _window(stage,module,level,damage,accent)
        _paint(stage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("shade_version",11)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    return true
