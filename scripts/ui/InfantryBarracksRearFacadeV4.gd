extends RefCounted
class_name TarvokaInfantryBarracksRearFacadeV4

# Additive, reversible native Godot 4.3 detail pass.
# Never alter the three architectural silhouettes, faction identifiers,
# the N3 west training corridor or any combat/production logic.
const Base=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const STAGE_NAME="InfanteriaV4FachadaPosterior"
const FRAME=Color("#52636a")
const STEEL=Color("#738b8f")
const CONCRETE=Color("#9ca8a1")
const DANGER=Color("#c9a760")
const SHADOW=Color("#263a43")
const DAMAGE=Color("#825e50")

static func _piece(stage: Node3D,name: String,position: Vector3,
        size: Vector3,color: Color,metal: float=0.2) -> void:
    Base._box(stage,name,position,size,color,metal)

static func _rear_module(stage: Node3D,module: Dictionary,
        level: int,damage: int) -> void:
    var tag: String=str(module["tag"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])+float(module["d"])*0.5
    var w: float=float(module["w"])
    var h: float=float(module["h"])
    var floors: int=int(module["floors"])
    var main: bool=bool(module["primary"])
    var rear:=Base._group(stage,"FachadaPosteriorV4_"+tag)
    # Existing rear wall centre at z; its exterior plane is z+0.12.
    # All detail is mounted on that exterior, never inside the training lane.
    var surface: float=z+0.155
    if damage>=3:
        # Ruins may receive rubble/structural remnants, not intact panels.
        _piece(rear,"PerfilPosteriorQuebrado",
            Vector3(x-w*0.29,0.68,surface),
            Vector3(0.13,1.13,0.10),DAMAGE)
        _piece(rear,"PerfilPosteriorCaido",
            Vector3(x+0.42,0.14,z+0.40),
            Vector3(1.34,0.11,0.18),DAMAGE)
        return
    # Thin corner pilasters, plus explicit joints between floor levels.
    for side in [-1,1]:
        _piece(rear,"PilastraPosterior_%d" % side,
            Vector3(x+float(side)*(w*0.5-0.21),h*0.5,surface),
            Vector3(0.18,h-0.16,0.13),CONCRETE)
    for floor in range(1,floors):
        _piece(rear,"JuntaForjadoPosterior_%d" % floor,
            Vector3(x,2.22*float(floor),surface+0.015),
            Vector3(w-0.57,0.105,0.075),STEEL)
    # Service hatch attached to solid wall: not a fictitious walk-through
    # doorway and not a replacement for the existing V1/V2 front entrance.
    var hatch_x: float=x+minf(w*0.22,1.10)
    _piece(rear,"MarcoRegistroTecnico",
        Vector3(hatch_x,1.19,surface+0.025),
        Vector3(0.98,1.28,0.085),FRAME,0.39)
    _piece(rear,"PanelRegistroTecnico",
        Vector3(hatch_x,1.19,surface+0.086),
        Vector3(0.81,1.09,0.045),SHADOW,0.30)
    _piece(rear,"ManijaRegistroTecnico",
        Vector3(hatch_x+0.28,1.16,surface+0.123),
        Vector3(0.052,0.19,0.038),DANGER,0.56)
    for rail in range(3):
        _piece(rear,"RanuraRegistroTecnico_%d" % rail,
            Vector3(hatch_x-0.09,1.48+float(rail)*0.095,surface+0.117),
            Vector3(0.37,0.035,0.035),STEEL,0.36)
    # Actual architectural windows along the large blind rear walls.
    # Low and middle floors remain well below the existing V3 high vents.
    # Keep the service hatch center clear and do not close damage openings.
    for floor in range(floors if w>=4.0 else 0):
        var window_y: float=1.45+float(floor)*2.22
        if window_y+0.44>=h-0.27:
            continue
        for side in [-1,1]:
            var wx: float=x+float(side)*w*0.275
            var wid: float=minf(0.86,w*0.20)
            _piece(rear,"MarcoVentanaPosterior_%d_%d" % [floor,side],
                Vector3(wx,window_y,surface+0.045),
                Vector3(wid+0.14,0.92,0.085),FRAME,0.41)
            _piece(rear,"CristalVentanaPosterior_%d_%d" % [floor,side],
                Vector3(wx,window_y,surface+0.105),
                Vector3(wid,0.74,0.035),
                SHADOW if damage==2 else Color("#406d7a"),0.16)
            _piece(rear,"AlfeizarVentanaPosterior_%d_%d" % [floor,side],
                Vector3(wx,window_y-0.48,surface+0.092),
                Vector3(wid+0.20,0.085,0.18),STEEL,0.38)
    # Only the EAST outer wing receives the side detail. West is kept clear
    # for the fixed N3 obstacle lane, and no element reaches a tower envelope.
    if level==3 and tag=="AlaEsteDosPisosN3" and damage<=2:
        var outer:=Base._group(stage,"FachadaExteriorAlaEsteV4")
        var outer_x: float=x+w*0.5+0.16
        var center_z: float=float(module["z"])
        for floor in range(2):
            var side_y: float=1.42+float(floor)*2.18
            for bay in range(2):
                var side_z: float=center_z-1.34+float(bay)*1.63
                _piece(outer,"MarcoVentanaLateral_%d_%d" % [floor,bay],
                    Vector3(outer_x,side_y,side_z),
                    Vector3(0.10,0.94,0.83),FRAME,0.38)
                _piece(outer,"CristalVentanaLateral_%d_%d" % [floor,bay],
                    Vector3(outer_x+0.072,side_y,side_z),
                    Vector3(0.032,0.72,0.68),
                    SHADOW if damage==2 else Color("#406d7a"),0.16)
        for floor in range(1,2):
            _piece(outer,"ForjadoLateralEste",
                Vector3(outer_x,2.25,center_z-0.20),
                Vector3(0.10,0.11,3.45),STEEL,0.32)
    # Rain drain is outside corners and kept slim; no contact with N3 track.
    _piece(rear,"BajantePosterior",
        Vector3(x-w*0.5+0.37,h*0.5,surface+0.13),
        Vector3(0.095,h-0.24,0.13),STEEL,0.39)
    _piece(rear,"AbrazaderaBajanteBaja",
        Vector3(x-w*0.5+0.37,0.60,surface+0.16),
        Vector3(0.20,0.075,0.17),FRAME,0.38)
    if damage==2:
        # Mid-damage retains structural joints but does NOT add intact
        # electrical and communication equipment.
        _piece(rear,"MarcaImpactoPosterior",
            Vector3(x-w*0.13,h*0.61,surface+0.02),
            Vector3(0.39,0.24,0.055),DAMAGE)
        return
    if level>=2:
        var vents: int=1 if floors==1 else 2
        for i in range(vents):
            var vx: float=x-w*0.24+float(i)*w*0.16
            var vy: float=h-1.46
            _piece(rear,"CajaFiltroPosterior_%d" % i,
                Vector3(vx,vy,surface+0.10),
                Vector3(0.48,0.32,0.20),FRAME,0.37)
            for slat in range(3):
                _piece(rear,"LamaFiltroPosterior_%d_%d" % [i,slat],
                    Vector3(vx,vy-0.085+float(slat)*0.085,surface+0.222),
                    Vector3(0.39,0.024,0.026),STEEL,0.42)
    if damage==0 and main and level>=2:
        # Upper command block identifiable from the back as well as front.
        _piece(rear,"LuminariaPosteriorBlindada",
            Vector3(x,h-0.52,surface+0.08),
            Vector3(0.49,0.18,0.12),DANGER,0.25)
        _piece(rear,"CanalCableadoPosterior",
            Vector3(x-w*0.13,h-0.59,surface+0.055),
            Vector3(w*0.27,0.065,0.065),FRAME,0.35)

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V3.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level or \
            int(model.get_meta("visual_faction",-1))!=faction or \
            int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage: Node3D=Base._group(model,STAGE_NAME)
    if damage<4:
        for module in V2._modules(level):
            _rear_module(stage,module,level,damage)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    stage.set_meta("facade_version",4)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_economy_or_combat_changes",true)
    return true
