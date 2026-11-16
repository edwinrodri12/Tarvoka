extends RefCounted
class_name TarvokaInfantryBarracksSideTowersV7

# Actual Godot 4.3 3D art geometry, additive/reversible over V1-V6.
# Improve legibility of long side walls and observation-cabin structure.
# Critical N3 restriction: west OUTER wall and west training corridor stay free.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const V6=preload("res://scripts/ui/InfantryBarracksRoofCommandV6.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV7FachadasInterioresYTorres"
const FRAME=Color("#52656c")
const ALUMINUM=Color("#9cacae")
const WINDOW=Color("#466c78")
const DARK=Color("#293f47")
const MASONRY=Color("#b4b7ab")
const RUST=Color("#906c5e")
const BEACON=Color("#d0b16a")

static func _part(parent: Node3D,label: String,pos: Vector3,
        size: Vector3,tint: Color,metal: float=0.22) -> void:
    Base._box(parent,label,pos,size,tint,metal)

static func _side_face(stage: Node3D,module: Dictionary,
        side: int,bays: Array[float],damage: int,accent: Color) -> void:
    var label: String=str(module["tag"])
    var cx: float=float(module["x"])
    var w: float=float(module["w"])
    var h: float=float(module["h"])
    var floors: int=int(module["floors"])
    var outer_x: float=cx+float(side)*w*0.5
    var root:=Base._group(stage,"FachadaLateralV7_"+label)
    root.set_meta("side_direction",side)
    root.set_meta("inside_u_courtyard",
        label in ["AlaOesteDosPisosN3","AlaEsteDosPisosN3"])
    if damage==2:
        # Already damaged: mark one broken side joint, DO NOT restore glass.
        _part(root,"PerfilFracturadoLateralV7",
            Vector3(outer_x+float(side)*0.177,h*0.46,bays[0]),
            Vector3(0.075,0.53,0.13),RUST)
        return
    if damage>=3:
        return
    var front_x: float=outer_x+float(side)*0.172
    var glass_x: float=outer_x+float(side)*0.233
    var trim_x: float=outer_x+float(side)*0.264
    for floor in range(floors):
        var win_y: float=1.46+float(floor)*2.20
        if win_y+0.49>=h-0.19:
            continue
        for bay in range(bays.size()):
            var z: float=bays[bay]
            _part(root,"MarcoLateralV7_%d_%d" % [floor,bay],
                Vector3(front_x,win_y,z),
                Vector3(0.105,1.00,0.99),FRAME,0.38)
            _part(root,"CristalLateralV7_%d_%d" % [floor,bay],
                Vector3(glass_x,win_y,z),
                Vector3(0.036,0.79,0.79),
                WINDOW if damage==0 else DARK,0.12)
            _part(root,"TravesanoLateralV7_%d_%d" % [floor,bay],
                Vector3(trim_x,win_y,z),
                Vector3(0.044,0.047,0.77),ALUMINUM,0.34)
            _part(root,"AlfeizarLateralV7_%d_%d" % [floor,bay],
                Vector3(front_x,win_y-0.53,z),
                Vector3(0.17,0.090,1.07),MASONRY,0.10)
        if floor>0:
            # The real two-floor division is legible on the courtyard side.
            _part(root,"JuntaLateralV7_%d" % floor,
                Vector3(front_x,2.28*float(floor),
                    (bays[0]+bays[bays.size()-1])*0.5),
                Vector3(0.085,0.095,
                    absf(bays[bays.size()-1]-bays[0])+1.43),
                ALUMINUM if damage==0 else RUST,0.35)
    # N3 inner courtyard receives restrained faction wayfinding, not a new
    # opaque wall and not an obstruction across the training corridor.
    if label in ["AlaOesteDosPisosN3","AlaEsteDosPisosN3"]:
        _part(root,"PlacaFaccionPatioInteriorV7",
            Vector3(trim_x,2.46,bays[0]),
            Vector3(0.043,0.13,0.62),accent,0.13)

static func _faces(stage: Node3D,level: int,damage: int,
        accent: Color) -> void:
    var mods: Array[Dictionary]=V2._modules(level)
    if level==1:
        var m: Dictionary=mods[0]
        var z: float=float(m["z"])
        for side in [-1,1]:
            _side_face(stage,m,side,[z-0.82,z+0.87],damage,accent)
    elif level==2:
        var main: Dictionary=mods[0]
        var wing: Dictionary=mods[1]
        # Main block's right face adjoins the L wing; NEVER add panes there.
        _side_face(stage,main,-1,
            [float(main["z"])-0.82,float(main["z"])+0.94],
            damage,accent)
        _side_face(stage,wing,1,
            [float(wing["z"])-0.58,float(wing["z"])+1.02],
            damage,accent)
    elif level==3:
        var left: Dictionary=mods[1]
        var right: Dictionary=mods[2]
        # The U's inward faces are x=-3.075 and x=+3.075. Leave x=-6.085
        # (the west exterior) unchanged to protect the obstacle corridor.
        _side_face(stage,left,1,[-1.83,-0.27],damage,accent)
        _side_face(stage,right,-1,[-1.83,-0.27],damage,accent)

static func _tower(stage: Node3D,tag: String,
        x: float,z: float,height: float,damage: int,
        accent: Color) -> void:
    var cabin:=Base._group(stage,"CabinaVigilanciaV7_"+tag)
    if damage>=2:
        # V1/V2 already handle broken towers. No intact roof or panes added.
        return
    # Respect V2 front glass z=-0.80, whose upper edge is y=h+1.12.
    # Thin guard/fascia stays BELOW the original glazing.
    _part(cabin,"BarraInferiorFrontalTorreV7",
        Vector3(x,height+0.265,z-0.89),
        Vector3(1.63,0.085,0.11),FRAME,0.45)
    _part(cabin,"MarcoSuperiorFrontalTorreV7",
        Vector3(x,height+1.185,z-0.885),
        Vector3(1.67,0.091,0.11),ALUMINUM,0.42)
    for side in [-1,1]:
        _part(cabin,"JambaFrontalTorreV7_%d" % side,
            Vector3(x+float(side)*0.798,height+0.756,z-0.88),
            Vector3(0.082,0.84,0.11),FRAME,0.43)
        # Side panels float outside V1's glass (x=+/-0.70), below the
        # observation glazing. They must not obstruct the rear ladder.
        _part(cabin,"BarraInferiorLateralTorreV7_%d" % side,
            Vector3(x+float(side)*0.863,height+0.260,z),
            Vector3(0.10,0.082,1.42),FRAME,0.41)
        for edge in [-1,1]:
            _part(cabin,
                "MontanteLateralTorreV7_%d_%d" % [side,edge],
                Vector3(x+float(side)*0.864,height+0.74,
                    z+float(edge)*0.695),
                Vector3(0.088,0.84,0.082),ALUMINUM,0.42)
    if damage==0:
        # Roof corner hazard lights support military readability; no moving
        # lights or performance-heavy dynamic shadow-casting fixtures.
        for side in [-1,1]:
            var bx: float=x+float(side)*0.71
            var bz: float=z-0.73
            Base._cylinder(cabin,"BalizaTechoTorreV7_%d" % side,
                Vector3(bx,height+1.57,bz),
                0.065,0.19,BEACON)
            _part(cabin,"SoporteBalizaV7_%d" % side,
                Vector3(bx,height+1.485,bz),
                Vector3(0.20,0.07,0.20),DARK,0.37)
        # Colored strip sits ABOVE V1 tower glass, not on the front pane.
        _part(cabin,"CodigoFaccionCabinaV7",
            Vector3(x,height+1.397,z-1.087),
            Vector3(0.67,0.077,0.035),accent,0.11)

static func _towers(stage: Node3D,level: int,damage: int,
        accent: Color) -> void:
    if level==2:
        _tower(stage,"TorreSupervisionNivel2",
            5.67,-2.77,3.72,damage,accent)
    elif level==3:
        _tower(stage,"TorreOesteNivel3",
            -6.47,3.65,4.93,damage,accent)
        _tower(stage,"TorreEsteNivel3",
            6.47,3.65,4.93,damage,accent)

static func _finish_pbr(stage: Node3D,accent: Color) -> void:
    var pbr: int=0
    var faction_pieces: int=0
    var pending: Array[Node]=[stage]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
            if not child is MeshInstance3D:
                continue
            var part: MeshInstance3D=child as MeshInstance3D
            var mat: StandardMaterial3D=part.material_override as StandardMaterial3D
            if mat==null:
                continue
            if mat.albedo_color.is_equal_approx(accent):
                faction_pieces+=1
                continue
            var title: String=str(part.name).to_lower()
            var kind: String="steel"
            if title.contains("cristal"):
                kind="glass"
            elif title.contains("alfeizar"):
                kind="concrete"
            part.material_override=V3._finish_material(mat,kind)
            pbr+=1
    stage.set_meta("pbr_surfaces",pbr)
    stage.set_meta("faction_preserved",faction_pieces)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V6.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level or
            int(model.get_meta("visual_faction",-1))!=faction or
            int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        var accent: Color=Style.faction_color(faction)
        _faces(stage,level,damage,accent)
        _towers(stage,level,damage,accent)
        _finish_pbr(stage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("side_facing_windows_version",7)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    return true
