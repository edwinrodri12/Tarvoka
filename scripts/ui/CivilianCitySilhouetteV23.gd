extends RefCounted
class_name TarvokaCivilianCitySilhouetteV23

# V23: sculpt silhouette joins on every cardinal elevation.
# Use the V11 true jagged polygon walls and V14 real sloped roof pieces,
# rather than stacking flat rectangular ruin proxies over V22.
# VISUAL ONLY: unchanged city footprint, production, capture, and gameplay.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const V22=preload("res://scripts/ui/CivilianCityCohesionV22.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV23Silueta360YRuptura"

const CLAY=Color("#b77d59")
const BURNT_CLAY=Color("#865446")
const TIMBER=Color("#77604b")
const BRICK=Color("#a27b65")
const PALE_STONE=Color("#c4b6a0")
const GREY_STONE=Color("#969187")
const METAL=Color("#718a92")
const DARK_METAL=Color("#4b6068")
const RUBBLE=Color("#70685f")
const ASH=Color("#454b4c")
const FADED_GLASS=Color("#456c79")

static func _part(parent: Node3D,name: String,where: Vector3,
        dimensions: Vector3,tint: Color,finish: String="stone"
        ) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,name,where,dimensions,tint)
    mesh.material_override=V9._finish(tint,finish)
    return mesh

static func _ridge_and_corners(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int,accent: Color) -> void:
    if damage>1:
        return
    var roof:=V1._group(parent,"EncuentroSiluetaV23_"+tag)
    var h: float=float(floors)*2.10+0.21
    var roof_tint: Color=CLAY if level==1 else PALE_STONE if level==2 else METAL
    for end in [-1,1]:
        var edge_z: float=z+float(end)*d*0.445
        if level==1:
            # Two short stepped ceramic gable-cap pieces; the V2/V8
            # pitched roof and V21 ceramic ridge remain authoritative.
            for side in [-1,1]:
                var ridge:=_part(roof,
                    "V23_VillaRematePerfil_%s_%d_%d" % [tag,end,side],
                    Vector3(x+float(side)*w*0.30,h+0.35,edge_z),
                    Vector3(0.42,0.13,0.23),
                    BURNT_CLAY if damage==1 and end==1 else roof_tint,
                    "ceramic")
                ridge.rotation_degrees.z=float(side)*8.0
        elif level==2:
            # Stone roof rhythm: short alternating blocks, not another
            # continuous cornice exactly on top of V18/V19.
            for side in [-1,1]:
                var stone:=_part(roof,
                    "V23_CiudadPerfilEscalonado_%s_%d_%d" %
                    [tag,end,side],
                    Vector3(x+float(side)*w*0.33,h+0.43,edge_z),
                    Vector3(0.33,0.19,0.26),
                    BRICK if end==1 else PALE_STONE)
                stone.rotation_degrees.y=float(side*end)*5.0
        else:
            # Metropolitan skyline with light fins; tiny faction-color
            # strip near a fin only, no whole-building repaint.
            for side in [-1,1]:
                var sx: float=x+float(side)*w*0.35
                _part(roof,"V23_MetroPerfilCorona_%s_%d_%d" %
                    [tag,end,side],
                    Vector3(sx,h+0.41,edge_z),
                    Vector3(0.11,0.34,0.16),METAL,"steel")
                if damage==0 and end==-1:
                    _part(roof,
                        "V23_MetroMarcaSilueta_%s_%d" % [tag,side],
                        Vector3(sx,h+0.63,edge_z),
                        Vector3(0.10,0.07,0.11),accent,"steel")

static func _open_roof_damage(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int) -> void:
    var edge:=V1._group(parent,"PerfilCubiertaAbiertaV23_"+tag)
    var h: float=float(floors)*2.10+0.21
    var surface: Color=BURNT_CLAY if level==1 else GREY_STONE if level==2 else DARK_METAL
    # Two asymmetrical pieces, attached to the ORIGINAL roof rim.
    # They stop well short of the existing hollow roof center.
    for side in [-1,1]:
        var sx: float=x+float(side)*w*0.375
        for face in [-1,1]:
            if side==1 and face==1:
                # One genuinely absent corner, not four symmetrical cuts.
                continue
            var zz: float=z+float(face)*d*0.405
            var roof_plate:=V14._sloped_slab(edge,
                "V23_BordeTejadoPartido_%s_%d_%d" % [tag,side,face],
                Vector3(sx,h+0.105,zz),
                w*0.20,d*0.18,
                0.06 if side==-1 else 0.24,
                0.20 if face==-1 else 0.04,
                surface)
            roof_plate.rotation_degrees.y=float(side*face)*11.0
            roof_plate.material_override=V9._finish(
                surface,"ceramic" if level==1 else "stone" if level==2 else "steel")
    # A pair of real broken upright structural contacts, NOT fake
    # crack decals over transparent windows.
    for side in [-1,1]:
        var sx: float=x+float(side)*(w*0.5-0.19)
        var broken:=V11._broken_wall(
            edge,"V23_CosturaFachadaRota_%s_%d" % [tag,side],
            Vector3(sx,h-0.78,z-d*0.29),
            Vector3(0.0,0.0,d*0.235),
            PackedFloat32Array([0.21,0.46,0.27,0.12]),
            surface,0.105)
        broken.material_override=V9._finish(surface,"stone")
    _part(edge,"V23_SombraJuntaFractura_"+tag,
        Vector3(x+w*0.29,h+0.025,z+d*0.12),
        Vector3(0.44,0.035,0.21),ASH)

static func _damaged_low_shell(parent: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    if damage<3:
        return
    var shell:=V1._group(parent,"MurosMordidos360V23_"+tag)
    var wall: Color=BURNT_CLAY if level==1 else GREY_STONE if level==2 else DARK_METAL
    # V11 already builds a genuine irregular perimeter: close two exposed
    # INSIDE returns with short jagged polygons, not a duplicate outer wall.
    if damage==3:
        for side in [-1,1]:
            var sx: float=x+float(side)*(w*0.5-0.24)
            var inner:=V11._broken_wall(shell,
                "V23_RetornoCascaron_%s_%d" % [tag,side],
                Vector3(sx,0.11,z+d*0.26),
                Vector3(0.0,0.0,d*0.28),
                PackedFloat32Array([0.27,0.79,0.48,0.18]),
                wall,0.115)
            inner.material_override=V9._finish(
                wall,"steel" if level==3 else "stone")
        # Floor remnants lie inside the shell, on the surviving broken
        # structural plane, not floating above destroyed rooftops.
        for i in range(2):
            var slab:=V14._sloped_slab(shell,
                "V23_ForjadoArrancado_%s_%d" % [tag,i],
                Vector3(x+(float(i)-0.5)*w*0.29,
                    0.52,z+(float(i)-0.5)*d*0.24),
                w*0.28,d*0.31,0.08,0.21,wall)
            slab.rotation_degrees.y=float(i)*14.0-7.0
            slab.material_override=V9._finish(wall,"stone")
    else:
        # D4 has no standing floors, only broken low masonry and fallen
        # corner plates, physically grounded within the original lot.
        for i in range(4):
            var side: float=-1.0 if i%2==0 else 1.0
            var end: float=-1.0 if i<2 else 1.0
            var px: float=x+side*w*0.32
            var pz: float=z+end*d*0.29
            var wedge:=V14._sloped_slab(shell,
                "V23_CrestaRuinaBaja_%s_%d" % [tag,i],
                Vector3(px,0.105,pz),
                0.36,0.37,0.035,0.15+float(i%2)*0.035,
                wall if i%3!=0 else RUBBLE)
            wedge.rotation_degrees.y=float(i)*23.0
            wedge.material_override=V9._finish(
                wall if i%3!=0 else RUBBLE,
                "ceramic" if level==1 else "stone" if level==2 else "steel")

static func _town_hall_identity(parent: Node3D,
        level: int,damage: int,accent: Color) -> void:
    var town:=V1._group(parent,"AyuntamientoSiluetaV23")
    var h: float=float(2 if level==1 else 3 if level==2 else 4)*2.10+0.21
    if damage<=1:
        # Short front and rear municipal corners. The clock structure
        # remains solely owned by V1/V8 and is NOT cloned here.
        for face in [-1,1]:
            var z: float=-3.75+float(face)*1.26
            _part(town,
                "V23_RemateMunicipal360_%d" % face,
                Vector3(0.0,h+0.31,z),
                Vector3(0.46,0.12,0.16),
                CLAY if level==1 else PALE_STONE if level==2 else METAL,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
    elif damage==2:
        # A small loose sign plate makes the blown civic entrance readable
        # from the rear. Keep it at ground height, not on an intact clock.
        var sign:=_part(town,"V23_PlacaCivicaDesprendida",
            Vector3(0.68,0.16,-2.19),
            Vector3(0.48,0.11,0.38),
            GREY_STONE if level<3 else DARK_METAL)
        sign.rotation_degrees.y=-19.0
    else:
        var tint: Color=CLAY if level==1 else BRICK if level==2 else METAL
        _part(town,"V23_RestanteMunicipalSuelo",
            Vector3(0.0,0.115,-2.24),
            Vector3(0.55,0.15,0.31),tint)
    town.set_meta("art_only",true)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V22.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=Style.faction_color(faction) if faction>=0 else V1.NEUTRAL_ACCENT
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String=("Sur_" if southern else "Norte_")+str(side)
            var z: float=3.62 if southern else -3.80
            var w: float=2.77 if southern else 2.74
            var d: float=2.80 if southern else 2.84
            var floors: int=south_floors if southern else north_floors
            var group:=V1._group(stage,"V23_Modelo_"+tag)
            match damage:
                0,1: _ridge_and_corners(group,tag,x,z,w,d,
                    floors,level,damage,accent)
                2: _open_roof_damage(group,tag,x,z,w,d,floors,level)
                3,4: _damaged_low_shell(group,tag,x,z,w,d,level,damage)
    var civic_floor: int=2 if level==1 else 3 if level==2 else 4
    var civic:=V1._group(stage,"V23_Modelo_Ayuntamiento")
    match damage:
        0,1: _ridge_and_corners(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,
            civic_floor,level,damage,accent)
        2: _open_roof_damage(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,
            civic_floor,level)
        3,4: _damaged_low_shell(civic,"Ayuntamiento",0.0,-3.75,3.35,2.74,
            level,damage)
    _town_hall_identity(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",23)
    stage.set_meta("design_focus","360-silhouette-roof-rupture-irregular-low-shell")
    stage.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",23)
    model.set_meta("city_model_approved_final",false)
    return true
