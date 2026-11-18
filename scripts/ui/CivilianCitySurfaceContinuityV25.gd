extends RefCounted
class_name TarvokaCivilianCitySurfaceContinuityV25

# TARVOKA cities V25: surface/material continuity, not a new city tier.
# Refinish and slightly reconcile existing V24 contact geometry; add only
# tiny cross-sectional strips where broken edges remain bare. Godot 4.3.
# Art-only — no ownership, capture, collision, economy or unit behavior.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V24=preload("res://scripts/ui/CivilianCityStructuralContactsV24.gd")
const STAGE_NAME="CiudadCivilV25ContinuidadMaterialYBordes"

const CLAY=Color("#ac7355")
const CLAY_DUST=Color("#885e4f")
const WOOD=Color("#81664d")
const CHAR_WOOD=Color("#554738")
const BRICK=Color("#a17a65")
const STONE=Color("#c0b3a0")
const STONE_AGED=Color("#968c7f")
const MORTAR=Color("#aaa08f")
const METAL=Color("#80979b")
const STEEL=Color("#566b73")
const SOOT=Color("#505050")
const DUST=Color("#80756b")
const BROKEN_GLASS=Color("#466a76")

static func _material(level: int,damage: int) -> Color:
    if level==1:
        return CLAY_DUST if damage>=2 else CLAY
    if level==2:
        return STONE_AGED if damage>=2 else STONE
    return STEEL if damage>=2 else METAL

static func _surface(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _part(parent: Node3D,name: String,
        at: Vector3,size: Vector3,tint: Color,
        surface: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,name,at,size,tint)
    mesh.material_override=V9._finish(tint,surface)
    return mesh

static func _retouch_v24(v24: Node3D,level: int,damage: int) -> int:
    # Existing V24 fragments stay the source of truth. Reduce the
    # broad cuboid end caps and harmonize their material with V23.
    var count: int=0
    var nodes: Array[Node]=[v24]
    while not nodes.is_empty():
        var node: Node=nodes.pop_back()
        for child in node.get_children():
            nodes.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh:=node as MeshInstance3D
        var name: String=str(mesh.name)
        var tint: Color=_material(level,damage)
        if name.begins_with("V24_CierreCornisa_"):
            mesh.scale=Vector3(0.90,0.86,0.89)
            mesh.position.y-=0.025
            mesh.material_override=V9._finish(tint,_surface(level))
        elif name.begins_with("V24_ZapataApoyoRoto_"):
            mesh.scale=Vector3(0.90,0.94,0.92)
            mesh.material_override=V9._finish(
                CHAR_WOOD if level==1 else STONE_AGED if level==2 else STEEL,
                "stone" if level<3 else "steel")
        elif name.begins_with("V24_FracturaApoyada_"):
            # Its jagged face now sits slightly below the V23 roof rim,
            # not visibly protruding through the intact fascia.
            mesh.scale=Vector3(0.94,0.93,0.94)
            mesh.position.y-=0.037
            mesh.material_override=V9._finish(
                tint,_surface(level))
        elif name.begins_with("V24_FiloForjadoInterrumpido_"):
            mesh.scale=Vector3(0.96,0.93,0.95)
            mesh.position.y-=0.024
            mesh.material_override=V9._finish(
                CHAR_WOOD if level==1 else STONE_AGED if level==2 else STEEL,
                "stone" if level<3 else "steel")
        elif name.begins_with("V24_VigaEntreCascotes_"):
            mesh.scale=Vector3(0.90,0.94,0.94)
            mesh.material_override=V9._finish(
                WOOD if level==1 else BRICK if level==2 else STEEL,
                "steel" if level==3 else "stone")
        elif name.begins_with("V24_ZapataCortada_"):
            mesh.material_override=V9._finish(
                tint,"stone" if level<3 else "steel")
        else:
            continue
        mesh.set_meta("city_v25_material_reconciled",true)
        count+=1
    return count

static func _roof_joinery(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    # A few physical mortar/ceramic/metal joins rather than another
    # complete fascia duplicated over V14/V18/V19/V20.
    var h: float=float(floors)*2.10+0.21
    var group:=V1._group(stage,"JuntasDeMaterialV25_"+tag)
    var tint: Color=_material(level,damage)
    for face in [-1,1]:
        var zz: float=z+float(face)*d*0.46
        if damage==1 and face==1:
            continue
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.35
            if level==1:
                _part(group,
                    "V25_JuntaCeramica_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h+0.23,zz),
                    Vector3(0.10,0.055,0.18),CLAY,"ceramic")
                _part(group,
                    "V25_CabezaMadera_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h-0.02,zz-float(face)*0.085),
                    Vector3(0.07,0.19,0.10),WOOD)
            elif level==2:
                _part(group,
                    "V25_JuntaMortero_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h+0.23,zz),
                    Vector3(0.10,0.075,0.17),MORTAR)
                _part(group,
                    "V25_RematePiedra_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h-0.01,zz-float(face)*0.08),
                    Vector3(0.11,0.17,0.13),STONE)
            else:
                _part(group,
                    "V25_SoldaduraMetal_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h+0.23,zz),
                    Vector3(0.07,0.06,0.15),METAL,"steel")
                _part(group,
                    "V25_PiezaAnclaje_%s_%d_%d" % [tag,face,side],
                    Vector3(xx,h-0.01,zz-float(face)*0.07),
                    Vector3(0.085,0.14,0.09),STEEL,"steel")
    group.set_meta("not_repeated_fascia",true)

static func _roof_fracture_seams(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int) -> void:
    var h: float=float(floors)*2.10+0.21
    var group:=V1._group(stage,"PuntasRoturaV25_"+tag)
    # The open center and the missing front-right corner from V23
    # stay uncovered. Cross-section strips are inset into remaining
    # support braces (V24) and read from both front and rear.
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.365
        var sz: float=z-d*0.39
        var tint: Color=CLAY_DUST if level==1 else STONE_AGED if level==2 else STEEL
        var seam:=V14._sloped_slab(group,
            "V25_SeccionTejaPartida_%s_%d" % [tag,side],
            Vector3(sx,h+0.10,sz),
            w*0.13,0.23,0.04,0.11,tint)
        seam.rotation_degrees.y=float(side)*9.0
        seam.material_override=V9._finish(tint,_surface(level))
        # Shadow along the exposed fracture, not a broad black roof slab.
        _part(group,"V25_SombraBordeRoto_%s_%d" % [tag,side],
            Vector3(sx,h+0.025,sz-0.04),
            Vector3(0.27,0.028,0.06),SOOT)
    # Leave the south-east gap empty to distinguish D2 from wear D1.

static func _interior_joins(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int) -> void:
    var group:=V1._group(stage,"CortesInterioresV25_"+tag)
    var base_tint: Color=CHAR_WOOD if level==1 else STONE_AGED if level==2 else STEEL
    # Finish the exposed END GRAIN at V24 floor-head locations. Do not
    # place a new high facade or replace the V11 interior rooms.
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.30
        var end_cap:=_part(group,
            "V25_CantoForjadoVisible_%s_%d" % [tag,side],
            Vector3(sx,0.755,z+d*0.22),
            Vector3(0.25,0.11,0.095),base_tint,
            "steel" if level==3 else "stone")
        end_cap.rotation_degrees.y=float(side)*6.0
        # Chipped mortar terminates at the existing 0.71m floor.
        if level==2:
            _part(group,
                "V25_MorteroAbierto_%s_%d" % [tag,side],
                Vector3(sx,0.79,z+d*0.17),
                Vector3(0.13,0.06,0.13),MORTAR)
        elif level==3:
            _part(group,
                "V25_AceroCortado_%s_%d" % [tag,side],
                Vector3(sx,0.84,z+d*0.17),
                Vector3(0.08,0.13,0.08),METAL,"steel")
        else:
            _part(group,
                "V25_FibraMaderaRota_%s_%d" % [tag,side],
                Vector3(sx,0.83,z+d*0.17),
                Vector3(0.13,0.11,0.08),WOOD)

static func _foundation_seams(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int) -> void:
    var group:=V1._group(stage,"JuntasCimentacionV25_"+tag)
    # Two low material wedges join V24's fallen beam to the V11 slab.
    # Max y is below 0.28: ruins cannot accidentally regain stories.
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.33
        var sz: float=z-d*0.22
        var tint: Color=WOOD if level==1 else BRICK if level==2 else STEEL
        var joint:=_part(group,
            "V25_AnclajeCimientoDestruido_%s_%d" % [tag,side],
            Vector3(sx,0.12,sz),
            Vector3(0.21,0.14,0.27),tint,
            "steel" if level==3 else "stone")
        joint.rotation_degrees.y=float(side)*12.0
    if level==3:
        _part(group,"V25_CristalSueltoCimentacion_"+tag,
            Vector3(x-w*0.16,0.065,z+d*0.25),
            Vector3(0.27,0.035,0.20),BROKEN_GLASS,"glass")

static func _town_hall_finish(stage: Node3D,
        level: int,damage: int) -> void:
    # Keep the V1/V14 municipality, plaza and clock untouched.
    # Only small material-specific fallen civic architectural accents.
    if damage<2:
        return
    var group:=V1._group(stage,"RemateMunicipalV25")
    var tint: Color=CLAY_DUST if level==1 else STONE_AGED if level==2 else STEEL
    if damage==2:
        _part(group,"V25_FrisoMunicipalAgrietado",
            Vector3(-0.94,0.13,-2.19),
            Vector3(0.34,0.16,0.21),tint,_surface(level))
    elif damage==3:
        _part(group,"V25_PiezaPortalMunicipalRota",
            Vector3(-0.96,0.18,-2.24),
            Vector3(0.37,0.19,0.24),tint,_surface(level))
    else:
        _part(group,"V25_RestoPlacaMunicipal",
            Vector3(-0.72,0.10,-2.31),
            Vector3(0.33,0.11,0.28),tint,_surface(level))

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V24.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var v24: Node3D=model.get_node_or_null(V24.STAGE_NAME) as Node3D
    if v24==null:
        return false
    var reconciled: int=_retouch_v24(v24,level,damage)
    var stage:=V1._group(model,STAGE_NAME)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for south in [false,true]:
            var tag: String=("Sur_" if south else "Norte_")+str(side)
            var z: float=3.62 if south else -3.80
            var w: float=2.77 if south else 2.74
            var d: float=2.80 if south else 2.84
            var floors: int=south_floors if south else north_floors
            match damage:
                0,1: _roof_joinery(stage,tag,x,z,w,d,floors,level,damage)
                2: _roof_fracture_seams(stage,tag,x,z,w,d,floors,level)
                3: _interior_joins(stage,tag,x,z,w,d,level)
                4: _foundation_seams(stage,tag,x,z,w,d,level)
    var civic_floors: int=2 if level==1 else 3 if level==2 else 4
    match damage:
        0,1: _roof_joinery(stage,"Ayuntamiento",0.0,-3.75,
            3.35,2.74,civic_floors,level,damage)
        2: _roof_fracture_seams(stage,"Ayuntamiento",0.0,-3.75,
            3.35,2.74,civic_floors,level)
        3: _interior_joins(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,level)
        4: _foundation_seams(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,level)
    _town_hall_finish(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",25)
    stage.set_meta("design_focus","material-continuity-roof-breaks-interior-exposed-edge")
    stage.set_meta("existing_v24_meshes_reconciled",reconciled)
    model.set_meta("city_v25_material_reconciled",reconciled)
    model.set_meta("city_art_work_in_progress",25)
    model.set_meta("city_model_approved_final",false)
    return true
