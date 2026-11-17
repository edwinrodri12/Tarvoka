extends RefCounted
class_name TarvokaCivilianCityIdentityV15

# TARVOKA civil-city architecture V15. ART ONLY, not final approval.
# Strongly different read at tactical zoom for villa/town/metropolis.
# A level's identity survives D0 intact through D4 total destruction.
# Real PBR MeshInstance3D geometry: no decals and no gameplay changes.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const V12=preload("res://scripts/ui/CivilianCityDamageFinishV12.gd")
const V14=preload("res://scripts/ui/CivilianCitySilhouetteV14.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV15IdentidadMaterialYTipologias"

const TERRACOTTA=Color("#af6850")
const TILE_SHADE=Color("#7f5247")
const PLASTER=Color("#d5c6a9")
const TIMBER=Color("#7b5e45")
const BURNT_TIMBER=Color("#534642")
const LIMESTONE=Color("#c0b49b")
const BRICK=Color("#946c5b")
const MORTAR=Color("#b3a38d")
const CONCRETE=Color("#8e918d")
const GRAPHITE=Color("#424e52")
const ALUMINUM=Color("#728b91")
const BLUE_GLASS=Color("#5d8793")
const DARK_GLASS=Color("#354f58")
const OXIDE=Color("#81665a")
const RUIN_STONE=Color("#827b70")

static func _box(parent: Node3D,n: String,pos: Vector3,
        dims: Vector3,c: Color,surface: String="stone") -> MeshInstance3D:
    var node: MeshInstance3D=V1._box(parent,n,pos,dims,c)
    node.material_override=V9._finish(c,surface)
    return node

static func _rod(parent: Node3D,n: String,pos: Vector3,
        radius: float,height: float,c: Color,
        surface: String="steel") -> MeshInstance3D:
    var node: MeshInstance3D=V1._cylinder(
        parent,n,pos,radius,height,c,8)
    node.material_override=V9._finish(c,surface)
    return node

static func _villa_signature(layer: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int) -> void:
    var villa:=V1._group(layer,"VillaTradicionalV15_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # The previous pitched V2 roofs remain in place. Add a clear
        # terracotta ridge and visible timber/stone gable cap at BOTH ends.
        for facing in [-1,1]:
            var zface: float=z+float(facing)*d*0.5
            _box(villa,"CabioGableteV15_%s_%d" % [tag,facing],
                Vector3(x,h+0.37,zface+float(facing)*0.08),
                Vector3(w*0.73,0.18,0.18),TIMBER)
            for edge in [-1,1]:
                var brace:=_box(villa,
                    "MaderaInclinadaVillaV15_%s_%d_%d" %
                    [tag,facing,edge],
                    Vector3(x+float(edge)*w*0.27,h+0.42,
                        zface+float(facing)*0.04),
                    Vector3(w*0.41,0.16,0.15),TIMBER)
                brace.rotation_degrees.z=float(edge)*-21.0
        for i in range(3):
            _box(villa,"TejaCaballeraV15_%s_%d" % [tag,i],
                Vector3(x,h+0.71,
                    z-d*0.32+float(i)*d*0.32),
                Vector3(0.23,0.16,d*0.26),
                TILE_SHADE if damage==1 else TERRACOTTA,"ceramic")
        for side in [-1,1]:
            var xp: float=x+float(side)*(w*0.5+0.09)
            _box(villa,"ZocaloRusticoVillaV15_%s_%d" % [tag,side],
                Vector3(xp,0.23,z),
                Vector3(0.18,0.36,d*0.71),LIMESTONE)
            _box(villa,"AleroMaderaVillaV15_%s_%d" % [tag,side],
                Vector3(xp,h+0.16,z),
                Vector3(0.28,0.13,d*0.86),TIMBER)
        return
    if damage==2:
        # No intact ridge at D2; split short ceramic remnants sit ON
        # V11/V14 fractured roof fragments, keeping the villa recognizable.
        for side in [-1,1]:
            var roof:=_box(villa,"TejaSueltaFracturadaVillaV15_%s_%d" %
                [tag,side],
                Vector3(x+float(side)*w*0.31,h+0.34,
                    z+float(side)*d*0.12),
                Vector3(w*0.33,0.10,d*0.45),TERRACOTTA,"ceramic")
            roof.rotation_degrees.z=float(side)*9.0
            _box(villa,"CabioRotoVillaV15_%s_%d" % [tag,side],
                Vector3(x+float(side)*w*0.41,h+0.15,z-d*0.29),
                Vector3(0.13,0.28,d*0.55),BURNT_TIMBER)
        return
    # D3-D4: no high roof or upper-floor detail; recognizable wood
    # framing embedded in low rubble, charred pitched roof fragments.
    for side in [-1,1]:
        var xx: float=x+float(side)*w*0.29
        var y: float=0.44 if damage==3 else 0.22
        var fallen:=_box(villa,"VigaVernacularCaidaV15_%s_%d" % [tag,side],
            Vector3(xx,y,z+float(side)*d*0.21),
            Vector3(w*0.55,0.15,0.21),BURNT_TIMBER)
        fallen.rotation_degrees.y=float(side)*27.0
        V12._rubble_wedge(villa,
            "TejaDerruidaVillaV15_%s_%d" % [tag,side],
            Vector3(xx,0.04,z+d*0.28),
            Vector3(0.46,0.22 if damage==3 else 0.13,0.43),
            TERRACOTTA)
    if damage==3:
        # A short half-timber gable stump against one V11 irregular wall.
        V11._broken_wall(villa,"MuroVillaEntramadoV15_"+tag,
            Vector3(x,0.09,z-d*0.5+0.09),Vector3(w*0.56,0,0),
            PackedFloat32Array([0.37,0.82,0.62,0.29]),
            BRICK,0.18)

static func _town_signature(layer: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int) -> void:
    var town:=V1._group(layer,"CiudadCompactaMamposteriaV15_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # A middle-tier brick facade with stone parapet and regular
        # horizontal masonry bands. Services on the roof remain V8.
        for face in [-1,1]:
            var zz: float=z+float(face)*(d*0.5+0.10)
            _box(town,"BandaParapetoPiedraV15_%s_%d" % [tag,face],
                Vector3(x,h+0.34,zz),
                Vector3(w*0.84,0.28,0.23),LIMESTONE)
            _box(town,"BandaLadrilloRemateV15_%s_%d" % [tag,face],
                Vector3(x,h+0.18,zz+float(face)*0.025),
                Vector3(w*0.91,0.10,0.20),BRICK)
            for floor in range(floors):
                var yy: float=0.39+float(floor)*2.10
                if yy>=h-0.3:
                    continue
                _box(town,"HileraMamposteriaV15_%s_%d_%d" %
                    [tag,face,floor],
                    Vector3(x,yy,zz),
                    Vector3(w*0.82,0.10,0.12),
                    BRICK if damage==0 else MORTAR)
        for side in [-1,1]:
            _box(town,"PilastraEsquinaCiudadV15_%s_%d" % [tag,side],
                Vector3(x+float(side)*(w*0.5+0.06),
                    h*0.50,z+d*0.28),
                Vector3(0.17,h*0.91,0.24),LIMESTONE)
        return
    if damage==2:
        for face in [-1,1]:
            var zz: float=z+float(face)*(d*0.5+0.04)
            # Split municipal-type cornice, never a continuous intact roof.
            var part:=_box(town,
                "CornisaDesgajadaCiudadV15_%s_%d" % [tag,face],
                Vector3(x-0.34,h+0.21,zz),
                Vector3(w*0.42,0.16,0.21),BRICK)
            part.rotation_degrees.z=11.0 if face==-1 else -9.0
            _box(town,"SillaresEnCornisaV15_%s_%d" % [tag,face],
                Vector3(x+0.30,h-0.15,zz),
                Vector3(w*0.32,0.34,0.24),LIMESTONE)
        return
    # Damaged old town still reads as BRICK AND STONE rather than the
    # timber villa or the steel/concrete metropolitan district.
    var shell_h: float=0.92 if damage==3 else 0.35
    for side in [-1,1]:
        var xx: float=x+float(side)*w*0.27
        _box(town,"PilastraMamposteriaTruncadaV15_%s_%d" % [tag,side],
            Vector3(xx,0.09+shell_h*0.5,z-d*0.32),
            Vector3(0.32,shell_h,0.32),LIMESTONE)
        V12._rubble_wedge(town,
            "BloquesMamposteriaCiudadV15_%s_%d" % [tag,side],
            Vector3(xx,0.04,z+d*0.38),
            Vector3(0.51,0.31 if damage==3 else 0.17,0.42),
            BRICK)
    if damage==3:
        # Low irregular brick spandrel preserves the town's facade style.
        V11._broken_wall(town,"CornisaMamposteriaBajaV15_"+tag,
            Vector3(x,0.10,z+d*0.5-0.12),
            Vector3(w*0.64,0,0),
            PackedFloat32Array([0.35,0.63,0.37,0.22]),
            BRICK,0.23)

static func _metro_signature(layer: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,damage: int,accent: Color) -> void:
    var metro:=V1._group(layer,"MetropoliVidrioYAceroV15_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # Multiple staggered roof parapets keep this tier unmistakable
        # from far away; supports are seated on the roof V8/V9.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.29
            _box(metro,"CoronaEscalonadaMetroV15_%s_%d" % [tag,side],
                Vector3(xx,h+0.55,z+d*0.44),
                Vector3(w*0.39,0.35,0.22),GRAPHITE,"steel")
            _box(metro,"LuzFranjaCivicaMetroV15_%s_%d" % [tag,side],
                Vector3(xx,h+0.73,z+d*0.53),
                Vector3(w*0.32,0.07,0.10),accent,"steel")
            # Piercing through every floor would overlap existing glazing;
            # these narrow mullions remain at outer facade corners.
            for face in [-1,1]:
                var zz: float=z+float(face)*(d*0.5+0.10)
                _box(metro,"NervaduraAluminioAltaV15_%s_%d_%d" %
                    [tag,side,face],
                    Vector3(xx+float(side)*0.30,h*0.51,zz),
                    Vector3(0.13,h*0.90,0.12),ALUMINUM,"steel")
        for floor in range(1,floors):
            var y: float=float(floor)*2.10+0.13
            _box(metro,"CintaVidrioTacticaV15_%s_%d" % [tag,floor],
                Vector3(x,y,z+d*0.5+0.16),
                Vector3(w*0.68,0.17,0.10),BLUE_GLASS,"glass")
        return
    if damage==2:
        # Bent aluminium parapet and one angular glazing fragment remain
        # anchored on the broken roof; no full uninterrupted crown.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.32
            var rail:=_box(metro,
                "PerfilCoronaMetropoliRotoV15_%s_%d" % [tag,side],
                Vector3(xx,h+0.29,z+d*0.45),
                Vector3(w*0.33,0.13,0.14),ALUMINUM,"steel")
            rail.rotation_degrees.z=float(side)*15.0
            var pane:=_box(metro,
                "VidrioEstructuralImpactadoV15_%s_%d" % [tag,side],
                Vector3(xx,h+0.19,z-d*0.46),
                Vector3(w*0.24,0.20,0.10),DARK_GLASS,"glass")
            pane.rotation_degrees.y=float(side)*19.0
        return
    # D3: exposed fractured concrete piers; D4: only grounded steel
    # frame and glass rubble. Always lower than V11 remaining wall.
    var height: float=1.10 if damage==3 else 0.28
    for side in [-1,1]:
        var xx: float=x+float(side)*w*0.29
        _box(metro,"PilarMetropoliAbiertoV15_%s_%d" % [tag,side],
            Vector3(xx,0.10+height*0.5,z-d*0.25),
            Vector3(0.28,height,0.28),CONCRETE)
        _rod(metro,"AceroArmaduraMetroV15_%s_%d" % [tag,side],
            Vector3(xx,0.24+height*0.28,z-d*0.25),
            0.044,height*0.56,OXIDE)
        var shard: MeshInstance3D=V12._rubble_wedge(metro,
            "VidrioRestosMetroV15_%s_%d" % [tag,side],
            Vector3(xx,0.04,z+d*0.29),
            Vector3(0.52,0.20,0.42),DARK_GLASS)
        shard.material_override=V9._finish(DARK_GLASS,"glass")
    if damage==3:
        _box(metro,"LosaMiradorTorcidaMetroV15_"+tag,
            Vector3(x,0.83,z+d*0.12),
            Vector3(w*0.55,0.16,d*0.28),GRAPHITE,"steel")

static func _municipal_identity(layer: Node3D,level: int,
        damage: int,accent: Color) -> void:
    var civic:=V1._group(layer,"MunicipalPorNivelV15")
    var z: float=-3.75
    var front: float=z-2.74*0.5
    var rear: float=z+2.74*0.5
    var floors: int=2 if level==1 else 3 if level==2 else 4
    var h: float=float(floors)*2.10+0.21
    if damage<=1:
        # A common municipal landmark built of three very different
        # palettes: villa stone, town brick, metropolitan metal/glass.
        var tint: Color=(
            LIMESTONE if level==1 else BRICK if level==2 else GRAPHITE)
        for face in [-1,1]:
            var zz: float=front if face==-1 else rear
            _box(civic,"RemateInstitucionalNivelV15_%d" % face,
                Vector3(0.0,h+0.24,zz+float(face)*0.09),
                Vector3(2.13,0.18,0.23),tint,
                "steel" if level==3 else "stone")
        if level==1:
            _box(civic,"RelievePiedraAyuntamientoVillaV15",
                Vector3(0,2.48,front-0.18),
                Vector3(0.80,0.21,0.16),LIMESTONE)
        elif level==2:
            for side in [-1,1]:
                _box(civic,"EscalonCornisaAytoCiudadV15_%d" % side,
                    Vector3(float(side)*0.77,h+0.42,front-0.12),
                    Vector3(0.47,0.32,0.20),BRICK)
        else:
            _box(civic,"AleroMetalicoAytoMetropoliV15",
                Vector3(0,h+0.44,front-0.11),
                Vector3(1.95,0.32,0.24),GRAPHITE,"steel")
            _box(civic,"FrisoLuminosoAytoMetropoliV15",
                Vector3(0,h+0.58,front-0.25),
                Vector3(1.51,0.10,0.10),accent,"steel")
        return
    # The emblem survives only as grounded fragments: tier identity
    # remains visible even after the hall is fully destroyed.
    if level==1:
        V12._rubble_wedge(civic,"MolduraVillaCivicaCaidaV15",
            Vector3(-0.48,0.04,rear+0.22),
            Vector3(0.53,0.22 if damage<4 else 0.14,0.47),
            LIMESTONE)
    elif level==2:
        for side in [-1,1]:
            V12._rubble_wedge(civic,
                "LadrilloCornisaCiudadCaidoV15_%d" % side,
                Vector3(float(side)*0.39,0.04,rear+0.28),
                Vector3(0.49,0.27 if damage<4 else 0.16,0.42),
                BRICK)
    else:
        var beam:=_box(civic,"VigaAceroAytoDestruidaV15",
            Vector3(0.41,0.20,rear+0.28),
            Vector3(1.21,0.16,0.25),ALUMINUM,"steel")
        beam.rotation_degrees.y=16.0
        var glass: MeshInstance3D=V12._rubble_wedge(
            civic,"VidrioMunicipalDerruidoV15",
            Vector3(-0.65,0.04,rear+0.24),
            Vector3(0.46,0.22 if damage<4 else 0.13,0.38),
            BLUE_GLASS)
        glass.material_override=V9._finish(BLUE_GLASS,"glass")
    if damage==2:
        # Just a small split strip at D2. Do not draw intact crown above
        # a torn city hall roof.
        _box(civic,"SillarAytoIdentidadD2V15",
            Vector3(-0.66,0.17,rear+0.50),
            Vector3(0.37,0.19,0.31),accent,"stone")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V14.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var layer:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for south in [false,true]:
            var tag: String=("ResidencialSur_%d" % side
                if south else "ResidencialNorte_%d" % side)
            var z: float=3.62 if south else -3.80
            var w: float=2.77 if south else 2.74
            var d: float=2.80 if south else 2.84
            var floors: int=south_floors if south else north_floors
            match level:
                1:
                    _villa_signature(layer,tag,x,z,w,d,floors,damage)
                2:
                    _town_signature(layer,tag,x,z,w,d,floors,damage)
                3:
                    _metro_signature(layer,tag,x,z,w,d,floors,damage,accent)
    _municipal_identity(layer,level,damage,accent)
    layer.set_meta("visual_only",true)
    layer.set_meta("no_gameplay_changes",true)
    layer.set_meta("design_stage",15)
    layer.set_meta("tier_identity",
        "villa-terracotta-timber" if level==1 else
        "town-masonry-stone" if level==2 else
        "metropolis-steel-glass")
    layer.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",15)
    model.set_meta("city_model_approved_final",false)
    return true
