extends RefCounted
class_name TarvokaInfantryBarracksFacadeV4

# TARVOKA Infantry Barracks V4. Native Godot 4.3 3D refinement.
# Physically REPLACES solid rear/exposed side walls with segmented concrete
# and true window openings; no paper windows stuck on solid faces.
# Geometry is reversible: remove this V4 scene and rebuild V1/V2/V3.
# Reuses actual PBR surfaces created by V3; game rules are untouched.
const V1=preload("res://scripts/ui/InfantryBarracks3DV1.gd")
const V2=preload("res://scripts/ui/InfantryBarracksFinishV2.gd")
const V3=preload("res://scripts/ui/InfantryBarracksMaterialsV3.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="InfanteriaV4FachadasRealesTraserasLaterales"

const WALL=Color("#afb9b3")
const FRAME=Color("#52666b")
const BEAM=Color("#75878c")
const INTERIOR=Color("#20353c")
const METAL=Color("#43575d")
const RUST=Color("#8c6254")
const GLASS=Color("#427d93")
const WEAR=Color("#767970")
const LAMP=Color("#dfba60")

static var _glass_mat: StandardMaterial3D

static func _part(parent: Node3D,name: String,at: Vector3,
        size: Vector3,color: Color,kind: String="concrete",
        metal: float=0.12) -> MeshInstance3D:
    var p: MeshInstance3D=V1._box(parent,name,at,size,color,metal)
    var old: StandardMaterial3D=p.material_override as StandardMaterial3D
    p.material_override=V3._finish_material(old,kind)
    return p

static func _glass() -> StandardMaterial3D:
    if _glass_mat!=null:
        return _glass_mat
    var m:=StandardMaterial3D.new()
    m.albedo_color=Color(0.24,0.47,0.56,0.55)
    m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    m.cull_mode=BaseMaterial3D.CULL_DISABLED
    m.metallic=0.05
    m.roughness=0.15
    _glass_mat=m
    return m

static func _pane(parent: Node3D,name: String,at: Vector3,
        dimensions: Vector3) -> void:
    var p: MeshInstance3D=V1._box(
        parent,name,at,dimensions,GLASS,0.06)
    p.material_override=_glass()

static func _rear_windows(stage: Node3D,model: Node3D,module: Dictionary,
        level: int,damage: int,accent: Color) -> bool:
    var tag: String=str(module["tag"])
    var old: MeshInstance3D=model.find_child(
        "ParedPosterior_"+tag,true,false) as MeshInstance3D
    if old==null:
        return false
    old.visible=false
    var root:=V1._group(stage,"FachadaTraseraAbierta_"+tag)
    var x: float=float(module["x"])
    var z: float=float(module["z"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var floors: int=int(module["floors"])
    var back: float=z+d*0.5
    var columns: int=3 if w>6.0 else 1
    var opening_w: float=0.91 if columns==3 else 0.84
    var pier: float=(w-float(columns)*opening_w)/float(columns+1)
    var next_x: float=x-w*0.5
    for floor in range(floors):
        var y: float=float(floor)*2.22
        _part(root,"MuroBaseTrasero_%d" % floor,
            Vector3(x,y+0.43,back),Vector3(w,0.86,0.24),WALL)
        _part(root,"DintelContinuoTrasero_%d" % floor,
            Vector3(x,y+1.99,back),Vector3(w,0.46,0.24),WALL)
        next_x=x-w*0.5
        for i in range(columns+1):
            _part(root,"PilarPanoPosterior_%d_%d" % [floor,i],
                Vector3(next_x+pier*0.5,y+1.31,back),
                Vector3(pier,0.90,0.24),WALL)
            next_x+=pier
            if i==columns:
                continue
            var window_x: float=next_x+opening_w*0.5
            var aperture:=V1._group(root,
                "HuecoVentanaPosterior_%d_%d" % [floor,i])
            _part(aperture,"JambaHuecoTraseroIzq",
                Vector3(next_x+0.028,y+1.31,back+0.134),
                Vector3(0.055,0.89,0.07),FRAME,"steel",0.4)
            _part(aperture,"JambaHuecoTraseroDer",
                Vector3(next_x+opening_w-0.028,y+1.31,back+0.134),
                Vector3(0.055,0.89,0.07),FRAME,"steel",0.4)
            _part(aperture,"AlfeizarTrasero",
                Vector3(window_x,y+0.865,back+0.19),
                Vector3(opening_w+0.10,0.08,0.20),BEAM,"steel")
            _part(aperture,"DintelHuecoTrasero",
                Vector3(window_x,y+1.78,back+0.13),
                Vector3(opening_w+0.12,0.075,0.10),FRAME,"steel",0.40)
            if damage==0 or damage==1 and not (
                    floor==0 and i==0) or damage==2 and (
                    floor+i)%2==1:
                _pane(aperture,"CristalTrasero_%d_%d" % [floor,i],
                    Vector3(window_x,y+1.30,back),
                    Vector3(opening_w-0.14,0.78,0.028))
                _part(aperture,"MontanteCristalTrasero",
                    Vector3(window_x,y+1.30,back+0.032),
                    Vector3(0.04,0.78,0.06),FRAME,"steel",0.42)
            elif damage==1:
                _pane(aperture,"CristalRotoEsquinaTrasera",
                    Vector3(window_x-0.15,y+1.00,back),
                    Vector3(opening_w*0.35,0.28,0.028))
            next_x+=opening_w
    var top: float=h-float(floors)*2.22
    if top>0.04:
        _part(root,"PetroparapetoPosterior",
            Vector3(x,h-top*0.5,back),Vector3(w,top,0.24),WALL)
    if damage==0:
        # Signage does not seal window holes or reproduce entire wall.
        _part(root,"PlacaUnidadPosterior_"+tag,
            Vector3(x,h-0.10,back+0.165),
            Vector3(minf(1.54,w*0.55),0.12,0.06),
            accent,"steel")
    root.set_meta("actual_openings",columns*floors)
    root.set_meta("original_wall_hidden",true)
    return true

static func _exterior_sides(level: int) -> Dictionary:
    # Only EXPOSED lateral walls, never inner U/L junctions.
    match level:
        1: return {"BarracaUnPisoN1":[-1,1]}
        2: return {"BarracaPrincipalDosPisosN2":[-1],
            "AlaInstruccionN2":[1]}
        3: return {"AlaOesteDosPisosN3":[-1],
            "AlaEsteDosPisosN3":[1]}
    return {}

static func _side_windows(stage: Node3D,model: Node3D,module: Dictionary,
        side: int,damage: int) -> bool:
    var tag: String=str(module["tag"])
    var old_name: String=("ParedIzquierda_" if side==-1 else
        "ParedDerecha_")+tag
    var old: MeshInstance3D=model.find_child(old_name,true,false) as MeshInstance3D
    if old==null:
        return false
    old.visible=false
    var root:=V1._group(stage,
        "FachadaLateralAbierta_"+tag+"_"+str(side))
    var x: float=float(module["x"])
    var z: float=float(module["z"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var h: float=float(module["h"])
    var floors: int=int(module["floors"])
    var wall_x: float=x+float(side)*w*0.5
    var count: int=3 if d>=5.2 else 2
    var opening_w: float=0.66
    var pier: float=(d-float(count)*opening_w)/float(count+1)
    var next_z: float=z-d*0.5
    for floor in range(floors):
        var y: float=float(floor)*2.22
        _part(root,"ZocaloLateral_%d" % floor,
            Vector3(wall_x,y+0.43,z),
            Vector3(0.25,0.86,d),WALL)
        _part(root,"DintelLateral_%d" % floor,
            Vector3(wall_x,y+1.99,z),
            Vector3(0.25,0.46,d),WALL)
        next_z=z-d*0.5
        for i in range(count+1):
            _part(root,"PilarLateral_%d_%d" % [floor,i],
                Vector3(wall_x,y+1.31,next_z+pier*0.5),
                Vector3(0.25,0.90,pier),WALL)
            next_z+=pier
            if i==count:
                continue
            var window_z: float=next_z+opening_w*0.5
            var aperture:=V1._group(root,
                "HuecoVentanaLateral_%d_%d" % [floor,i])
            _part(aperture,"MarcoLateralA",
                Vector3(wall_x+float(side)*0.13,y+1.31,
                    next_z+0.03),
                Vector3(0.08,0.88,0.055),FRAME,"steel",0.4)
            _part(aperture,"MarcoLateralB",
                Vector3(wall_x+float(side)*0.13,y+1.31,
                    next_z+opening_w-0.03),
                Vector3(0.08,0.88,0.055),FRAME,"steel",0.4)
            _part(aperture,"AlfeizarLateral",
                Vector3(wall_x+float(side)*0.17,y+0.865,window_z),
                Vector3(0.18,0.07,opening_w+0.12),BEAM,"steel")
            if damage==0 or damage==1 and i!=0 or damage==2 and (
                    floor+i)%2==0:
                _pane(aperture,"CristalLateral_%d_%d" % [floor,i],
                    Vector3(wall_x,y+1.31,window_z),
                    Vector3(0.028,0.76,opening_w-0.13))
            next_z+=opening_w
    var top: float=h-float(floors)*2.22
    if top>0.04:
        _part(root,"RemateMuroLateral",
            Vector3(wall_x,h-top*0.5,z),
            Vector3(0.25,top,d),WALL)
    root.set_meta("actual_openings",count*floors)
    root.set_meta("original_wall_hidden",true)
    return true

static func _roof_details(stage: Node3D,module: Dictionary,
        level: int,damage: int) -> void:
    if damage>1:
        return
    var tag: String=str(module["tag"])
    var w: float=float(module["w"])
    var d: float=float(module["d"])
    var x: float=float(module["x"])
    var z: float=float(module["z"])
    var h: float=float(module["h"])
    var roof:=V1._group(stage,"RematesRealesCubierta_"+tag)
    # Narrow cap sections only above surviving roof panels.
    for panel in range(4):
        if damage==1 and panel==1:
            continue
        var px: float=x-w*0.5+w*(float(panel)+0.5)*0.25
        _part(roof,"JuntaDilatacionCubierta_%d" % panel,
            Vector3(px,h+0.293,z),
            Vector3(w*0.25-0.11,0.035,0.15),METAL,"steel",0.41)
    if damage==0:
        _part(roof,"PlacaInstalacionCubierta",
            Vector3(x,h+0.29,z+d*0.22),
            Vector3(minf(1.40,w*0.32),0.09,0.98),BEAM,"roof")
        var count: int=0 if level==1 else 1 if level==2 else 2
        for i in range(count):
            var offx: float=x+(float(i)-(float(count)-1.0)*0.5)*1.03
            _part(roof,"CajaVentiladorTecho_%d" % i,
                Vector3(offx,h+0.58,z+d*0.22),
                Vector3(0.63,0.52,0.57),METAL,"steel",0.35)
            _part(roof,"RejillaSuperiorTecho_%d" % i,
                Vector3(offx,h+0.855,z+d*0.22),
                Vector3(0.48,0.045,0.39),FRAME,"steel",0.42)

static func _training_identity(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage>1:
        return
    var training:=V1._group(stage,"SenalizacionEntrenamientoV4")
    var x: float=-7.02 if level==3 else -6.02
    var z: float=2.46 if level==3 else -0.84
    # Low equipment rack is kept clear of building and training lanes.
    _part(training,"BaseTableroOrdenes",
        Vector3(x,0.26,z),Vector3(0.70,0.50,0.17),
        METAL,"steel",0.28)
    _part(training,"PlacaTableroFaccion",
        Vector3(x,0.56,z-0.10),Vector3(0.57,0.10,0.035),
        accent,"steel")

static func _critical(stage: Node3D,model: Node3D,level: int) -> void:
    # Ruined rear walls must remain broken, never build fresh glass or
    # replace them with intact concrete during damage stage 3.
    for module in V2._modules(level):
        var tag: String=str(module["tag"])
        var x: float=float(module["x"])
        var z: float=float(module["z"])
        var w: float=float(module["w"])
        var d: float=float(module["d"])
        var back: float=z+d*0.5
        _part(stage,"MarcaDerrumbePosterior_"+tag,
            Vector3(x-w*0.26,0.51,back+0.16),
            Vector3(minf(1.18,w*0.32),0.58,0.04),
            RUST,"rubble")

static func apply(model: Node3D,level: int,faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_infantry_barracks_v1",false)):
        return false
    if not model.has_node(V2.STAGE_NAME) or             not model.has_node(V3.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if int(model.get_meta("visual_level",-1))!=level or             int(model.get_meta("visual_faction",-1))!=faction or             int(model.get_meta("visual_damage_stage",-1))!=damage:
        return false
    var stage:=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("tier",level)
    stage.set_meta("damage",damage)
    stage.set_meta("facade_version",4)
    stage.set_meta("massing_unchanged",true)
    if damage==4:
        stage.set_meta("ruins_only",true)
        return true
    if damage==3:
        _critical(stage,model,level)
        stage.set_meta("ruins_only",false)
        return true
    var exposed: Dictionary=_exterior_sides(level)
    for module in V2._modules(level):
        if not _rear_windows(stage,model,module,level,damage,
                Style.faction_color(faction)):
            return false
        var tag: String=str(module["tag"])
        for side in exposed.get(tag,[]):
            if not _side_windows(stage,model,module,int(side),damage):
                return false
        _roof_details(stage,module,level,damage)
    _training_identity(stage,level,damage,Style.faction_color(faction))
    stage.set_meta("rear_open_facades",V2._modules(level).size())
    stage.set_meta("outer_side_facades",2)
    stage.set_meta("ruins_only",false)
    return true

static func mesh_count(model: Node3D) -> int:
    var stage: Node3D=model.get_node_or_null(STAGE_NAME) as Node3D
    return 0 if stage==null else V1.mesh_count(stage)
