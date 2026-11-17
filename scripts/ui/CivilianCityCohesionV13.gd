extends RefCounted
class_name TarvokaCivilianCityCohesionV13

# TARVOKA CIVILIAN CITY V13 — sculpture of physical contacts:
# shattered roof -> load-bearing wall, broken wall -> foundation,
# masonry spill -> sidewalk, and a damage-specific civic town hall.
# Visual-only additive Godot 4.3 meshes. DO NOT change game rules.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const V12=preload("res://scripts/ui/CivilianCityDamageFinishV12.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV13EncuentrosCubiertasRuinasYTejidoCivico"

const LIMESTONE=Color("#c6bca9")
const CEMENT=Color("#979187")
const BRICK=Color("#987467")
const CHAR=Color("#454a49")
const REBAR=Color("#626e70")
const OXIDE=Color("#83695b")
const DUST=Color("#aca18e")
const SHADOW=Color("#303d3f")
const TERRA=Color("#9d7360")
const SLATE=Color("#64747a")
const GOLD=Color("#b99d70")

static func _box(parent: Node3D,n: String,position: Vector3,
        dims: Vector3,color: Color,finish: String="stone") -> MeshInstance3D:
    var part: MeshInstance3D=V1._box(
        parent,n,position,dims,color)
    part.material_override=V9._finish(color,finish)
    return part

static func _bar(parent: Node3D,n: String,at: Vector3,
        radius: float,height: float,color: Color) -> MeshInstance3D:
    var bar: MeshInstance3D=V1._cylinder(
        parent,n,at,radius,height,color,8)
    bar.material_override=V9._finish(color,"steel")
    return bar

static func _poly_rubble(parent: Node3D,n: String,
        at: Vector3,scale: Vector3,color: Color) -> void:
    # Same closed triangular masonry as V12, with size-dependent contour.
    V12._rubble_wedge(parent,n,at,scale,color)

static func _eave_to_wall(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    if damage==0 or damage>=3:
        return
    var group:=V1._group(stage,"UnionFisicaTejadoMuroV13_"+tag)
    var height: float=float(floors)*2.10+0.21
    var surface: Color=(
        TERRA if level==1 else CEMENT if level==2 else SLATE)
    # A quiet weathered eave joint at D1, NOT a destroyed roof.
    if damage==1:
        for edge in [-1,1]:
            var face: float=z+float(edge)*d*0.5
            _box(group,"FajaUnionTejadoV13_%s_%d" % [tag,edge],
                Vector3(x,height+0.075,face+float(edge)*0.125),
                Vector3(w*0.74,0.105,0.24),OXIDE,"steel")
        _poly_rubble(group,"AdoquinTejadoLeveV13_"+tag,
            Vector3(x+w*0.43,0.04,z+d*0.52+0.12),
            Vector3(0.25,0.12,0.22),DUST)
        return
    # D2: roof shards in V11 touch physically modeled wall brackets.
    # Two ties are rooted in the wall under both separated roof plates.
    for side in [-1,1]:
        var xx: float=x+float(side)*w*0.31
        for face in [-1,1]:
            var zz: float=z+float(face)*(d*0.48)
            _box(group,"MensulaTejadoFracturadoV13_%s_%d_%d" %
                [tag,side,face],
                Vector3(xx,height-0.035,zz),
                Vector3(w*0.22,0.29,0.27),CEMENT)
            _box(group,"NervioConectorV13_%s_%d_%d" %
                [tag,side,face],
                Vector3(xx,height+0.125,zz+float(face)*0.18),
                Vector3(w*0.20,0.09,0.30),REBAR,"steel")
        var exposed:=_bar(group,"ArmaduraTejadoRotaV13_%s_%d" %
            [tag,side],
            Vector3(xx,height+0.14,z+d*0.28),
            0.045,0.43,OXIDE)
        exposed.rotation_degrees.z=float(side)*42.0
    # Jagged eave segment, aligned with the surviving facade above
    # the V1 wall and below the displaced V11 plate.
    var front_z: float=z-d*0.5-0.095
    V11._broken_wall(group,"CornisaMordidaV13_"+tag,
        Vector3(x,height-0.22,front_z),
        Vector3(w*0.88,0.0,0.0),
        PackedFloat32Array([0.17,0.34,0.14,0.31,0.08]),
        surface,0.20)
    # Chipped slab edge has an independent exposed material.
    var flap:=_box(group,"AleroRetorcidoV13_"+tag,
        Vector3(x-w*0.18,height+0.20,z+d*0.50),
        Vector3(w*0.39,0.12,0.21),CHAR)
    flap.rotation_degrees.z=-13.0

static func _foundation_to_pavement(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        south: bool,damage: int) -> void:
    if damage==0:
        return
    var group:=V1._group(stage,"EncuentroCimentacionPavimentoV13_"+tag)
    var face: float=z-d*0.5 if south else z+d*0.5
    var direction: float=-1.0 if south else 1.0
    if damage==1:
        var point:=_box(group,"JuntaAdoquinConFisuraV13_"+tag,
            Vector3(x+w*0.31,0.106,face+direction*0.22),
            Vector3(0.49,0.045,0.14),DUST)
        point.rotation_degrees.y=14.0
        return
    # Continuity is a continuous irregular masonry skirt embedded in the
    # ground. No slabs are placed on the central drivable road.
    var breadth: float=w*0.73 if damage==2 else w*0.87
    var profile:=PackedFloat32Array(
        [0.09,0.23,0.10,0.19,0.05]
        if damage==2 else
        [0.18,0.37,0.15,0.32,0.12] if damage==3 else
        [0.22,0.42,0.17,0.36,0.09])
    V11._broken_wall(group,"PiedraCimentacionPartidaV13_"+tag,
        Vector3(x,0.045,face+direction*0.14),
        Vector3(breadth,0.0,0.0),profile,CEMENT,0.31)
    # These two wedges continue the V12 debris physically from the split
    # foundation into the setback, ending before |z|=1.13 sidewalk.
    for i in range(2):
        var distance: float=0.23+float(i)*0.30
        var zz: float=face+direction*distance
        _poly_rubble(group,"EncuentroEscombroV13_%s_%d" % [tag,i],
            Vector3(x-w*0.21+float(i)*w*0.40,0.045,zz),
            Vector3(0.49,0.21+float(i)*0.10,0.33),
            BRICK if i==0 else CEMENT)
    if damage>=3:
        # One fallen lintel touches the ground via a grounded broken wall
        # stump rather than floating above the V12 rubble field.
        var fallen:=_box(group,"UmbralColapsadoV13_"+tag,
            Vector3(x-w*0.13,0.18,face+direction*0.43),
            Vector3(w*0.56,0.23,0.25),CHAR)
        fallen.rotation_degrees.y=12.0

static func _civic_eave(stage: Node3D,level: int,
        damage: int,accent: Color) -> void:
    if damage==0:
        return
    var civic:=V1._group(stage,"ConexionRoofHallPublicoV13")
    var height: float=float(
        2 if level==1 else 3 if level==2 else 4)*2.10+0.21
    var z: float=-3.75
    var south: float=z+2.74*0.5
    if damage==1:
        var crack:=_box(civic,"MolduraAytoFisuradaV13",
            Vector3(-1.07,2.55,south+0.27),
            Vector3(0.31,0.17,0.22),DUST)
        crack.rotation_degrees.z=-12.0
        _box(civic,"PatinaCornisaCivilV13",
            Vector3(0.0,height+0.12,south+0.11),
            Vector3(2.75,0.085,0.22),OXIDE,"steel")
        return
    if damage==2:
        # Match V11's divided roof with municipal stone corbels physically
        # seated against the hall's surviving wall and roof fragments.
        for side in [-1,1]:
            var px: float=float(side)*0.93
            _box(civic,"MensulaTechoMunicipalV13_%d" % side,
                Vector3(px,height-0.08,south-0.05),
                Vector3(0.53,0.37,0.38),LIMESTONE)
            var bracket:=_box(civic,"DintelAytoTorsionadoV13_%d" % side,
                Vector3(px,height+0.17,south+0.15),
                Vector3(0.69,0.17,0.26),CHAR)
            bracket.rotation_degrees.z=float(side)*13.0
            _bar(civic,"AnclajeTechoAytoV13_%d" % side,
                Vector3(px,height+0.20,south+0.11),
                0.055,0.33,REBAR)
        _box(civic,"BocelPortalCivilDesprendidoV13",
            Vector3(-0.36,2.48,south+0.29),
            Vector3(0.78,0.20,0.29),DUST)
        if level>=2:
            # The clock tower's face does not survive D2 as a floating
            # disk; one face segment is physically attached near the sill.
            _box(civic,"CuadranteRelojAstilladoV13",
                Vector3(0.27,0.17,south+0.48),
                Vector3(0.41,0.11,0.30),CHAR,"steel")
        return
    # D3: broken inner fronton inset behind V11's street facade.
    # D4: keep only ground-height fragments; never a phantom upper tower.
    V11._broken_wall(civic,"FrontonMunicipalTruncadoV13",
        Vector3(0.0,0.08,south-0.24),
        Vector3(2.89,0.0,0.0),
        PackedFloat32Array(
            [0.55,0.92,1.34,0.83,0.37]
            if damage==3 else
            [0.22,0.31,0.44,0.23,0.15]),
        DUST,0.34)
    if damage==3:
        for i in range(3):
            _box(civic,"TramoEscaleraMunicipalV13_%d" % i,
                Vector3(-0.41,0.16+float(i)*0.16,
                    south-0.51+float(i)*0.20),
                Vector3(0.74,0.24,0.28),CEMENT)
        for edge in [-1,1]:
            var pillar:=_box(civic,
                "PilarTruncadoMunicipalV13_%d" % edge,
                Vector3(float(edge)*1.24,0.62,south-0.14),
                Vector3(0.28,1.03,0.28),LIMESTONE)
            pillar.rotation_degrees.z=float(edge)*5.0
    else:
        _box(civic,"FragmentoFrisoCivilV13",
            Vector3(0.46,0.17,south+0.40),
            Vector3(0.65,0.19,0.29),DUST)
    # Fallen stone and clockwork sit on the same setback as V12 debris.
    for i in range(4 if damage==3 else 6):
        var xx: float=(float(i%3)-1.0)*0.53
        var zz: float=south+0.28+float(i/3)*0.23
        _poly_rubble(civic,"MamposteriaCivilSueloV13_%d" % i,
            Vector3(xx,0.045,zz),
            Vector3(0.36,0.15+float(i%3)*0.06,0.35),
            BRICK if i%2==0 else CHAR)
    if level>=2:
        var fallen_hand:=_box(civic,"AgujaRelojCivilCaidaV13",
            Vector3(0.71,0.12,south+0.61),
            Vector3(0.44,0.055,0.055),accent,"steel")
        fallen_hand.rotation_degrees.y=37.0

static func _civic_walkway(stage: Node3D,damage: int) -> void:
    if damage<2:
        return
    var group:=V1._group(stage,"EmpalmeAndenCiudadV13")
    # Civic doorway z≈-2.38. Debris reaches its own paved approach
    # at z=-1.73 but never the traffic lane (-0.92..+0.92).
    var z: float=-2.38
    for i in range(3 if damage==2 else 5):
        var t: float=float(i)/float(2 if damage==2 else 4)
        _poly_rubble(group,"BordilloDesmoronadoV13_%d" % i,
            Vector3(-0.81+float(i%3)*0.79,0.038,
                z+0.20+0.39*t),
            Vector3(0.39,0.13+0.07*float(i%2),0.31),
            CHAR if i%2==0 else CEMENT)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V11.STAGE_NAME)
            or not model.has_node(V12.STAGE_NAME)
            or model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for is_south in [false,true]:
            var tag: String=("ResidencialSur_%d" % side
                if is_south else "ResidencialNorte_%d" % side)
            var z: float=3.62 if is_south else -3.80
            var w: float=2.77 if is_south else 2.74
            var d: float=2.80 if is_south else 2.84
            var floors: int=south_floors if is_south else north_floors
            _eave_to_wall(stage,tag,x,z,w,d,floors,level,damage)
            _foundation_to_pavement(stage,tag,
                x,z,w,d,is_south,damage)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    _civic_eave(stage,level,damage,accent)
    _civic_walkway(stage,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",13)
    stage.set_meta("damage",damage)
    stage.set_meta("finish",
        "torn-roof-bearing-masonry-foundation-civic-approach")
    model.set_meta("city_art_work_in_progress",13)
    model.set_meta("city_model_approved_final",false)
    return true
