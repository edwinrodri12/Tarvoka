extends RefCounted
class_name TarvokaCivilianCityDamageFinishV12

# TARVOKA V12: true 3D side damage, visible structural interiors and
# rubble which grows outward from each building into its OWN pedestrian
# setback. Pure ART: no city placement, economy, combat or capture changes.
# Complements V11's polygonal collapsed walls; does not invent new buildings.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V10=preload("res://scripts/ui/CivilianCityGroundFrontV10.gd")
const V11=preload("res://scripts/ui/CivilianCityStructuralRuinsV11.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV12RoturasLateralesInterioresEscombros"

const STONE=Color("#b8ae9d")
const BRICK=Color("#9c7467")
const PLASTER=Color("#c8bba5")
const CHAR=Color("#3b4243")
const CONCRETE=Color("#817d76")
const REBAR=Color("#6a7475")
const RUST=Color("#825f52")
const DARK=Color("#2d393a")
const WOOD=Color("#786651")
const DUST=Color("#a29a89")
const GLASS=Color("#55727b")
const HIGHLIGHT=Color("#c2a068")

static func _box(root: Node3D,name: String,pos: Vector3,
        size: Vector3,color: Color,finish: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(root,name,pos,size,color)
    mesh.material_override=V9._finish(color,finish)
    return mesh

static func _rod(root: Node3D,name: String,pos: Vector3,
        radius: float,height: float,color: Color) -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._cylinder(
        root,name,pos,radius,height,color,8)
    mesh.material_override=V9._finish(color,"steel")
    return mesh

static func _rubble_wedge(root: Node3D,name: String,
        pos: Vector3,size: Vector3,color: Color,
        lean: float=0.0) -> MeshInstance3D:
    # A five-vertex, fully CLOSED triangular rubble mound with independent
    # roof-like faces (NOT another floating rectangular box).
    var hx: float=size.x*0.5
    var hz: float=size.z*0.5
    var a:=Vector3(-hx,0.0,-hz)
    var b:=Vector3(hx,0.0,-hz)
    var c:=Vector3(hx,0.0,hz)
    var d:=Vector3(-hx,0.0,hz)
    var peak:=Vector3(lean*hx,size.y,-0.11*hz)
    var tool:=SurfaceTool.new()
    tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    V11._tri(tool,a,b,c)
    V11._tri(tool,a,c,d)
    V11._tri(tool,a,peak,b)
    V11._tri(tool,b,peak,c)
    V11._tri(tool,c,peak,d)
    V11._tri(tool,d,peak,a)
    var mesh:=MeshInstance3D.new()
    mesh.name=name
    mesh.mesh=tool.commit()
    mesh.material_override=V9._finish(color,"stone")
    mesh.position=pos
    root.add_child(mesh)
    return mesh

static func _side_wear(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    if damage>=3:
        # V11 has physically OPEN polygonal shells at D3/D4. No untouched
        # windows, paint, original-height cornices or false outer walls.
        return
    var facade:=V1._group(root,"DesgasteCostadosV12_"+tag)
    var roof_h: float=float(floors)*2.10+0.21
    for side in [-1,1]:
        var xx: float=x+float(side)*(w*0.5+0.112)
        if damage==0:
            # A thin flush stone/metal reveal anchors the side elevation.
            _box(facade,"EsquineroVolumetricoV12_%s_%d" % [tag,side],
                Vector3(xx,0.52,z+d*0.31),
                Vector3(0.20,0.96,0.22),
                PLASTER if level<3 else REBAR,
                "stone" if level<3 else "steel")
            continue
        var step: float=1.0 if damage==1 else 1.53
        # Vertical fractures are separated physical strips, not decals.
        for index in range(2 if damage==1 else 3):
            var rz: float=z-d*0.31+float(index)*d*0.25
            var y: float=step+float(index%2)*0.41
            var fracture:=_box(
                facade,"GrietaLateralVolumetricaV12_%s_%d_%d" %
                [tag,side,index],
                Vector3(xx+float(side)*0.035,y,rz),
                Vector3(0.075,0.57 if damage==1 else 1.09,0.12),
                CHAR)
            fracture.rotation_degrees.x=14.0+float(index)*11.0
        # A small chipped corner at D1 becomes an uneven broken lintel at D2.
        if damage==1:
            _rubble_wedge(facade,
                "PiedraDesconchadaCostadoV12_%s_%d" % [tag,side],
                Vector3(xx+float(side)*0.035,0.28,z-d*0.27),
                Vector3(0.25,0.25,0.40),STONE,float(side)*0.28)
        else:
            var broken:=_box(facade,
                "VoladizoLateralImpactadoV12_%s_%d" % [tag,side],
                Vector3(xx+float(side)*0.09,roof_h-0.14,z+d*0.11),
                Vector3(0.26,0.27,d*0.30),CONCRETE)
            broken.rotation_degrees.z=float(side)*15.0
            _box(facade,
                "HuecoLateralAhumadoV12_%s_%d" % [tag,side],
                Vector3(xx+float(side)*0.063,1.33,z+d*0.23),
                Vector3(0.08,0.83,0.62),DARK)
            for bar in range(2):
                var exposed:=_rod(facade,
                    "AceroCostadoVisibleV12_%s_%d_%d" %
                    [tag,side,bar],
                    Vector3(xx+float(side)*0.19,
                        1.10+float(bar)*0.31,z+d*0.18),
                    0.035,0.58,RUST)
                exposed.rotation_degrees.x=float(side)*18.0

static func _exposed_rooms(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        level: int,damage: int) -> void:
    if damage<3:
        return
    var interior:=V1._group(root,"SeccionInteriorHabitableV12_"+tag)
    if damage==4:
        # Only the lowest footings survive. A toppled vertical column
        # stays on the floor; there is NO phantom suspended upper level.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.30
            var footing:=_box(interior,
                "ZapataCimentacionAbiertaV12_%s_%d" % [tag,side],
                Vector3(xx,0.17,z+d*0.23),
                Vector3(0.42,0.31,0.49),CONCRETE)
            footing.rotation_degrees.y=float(side)*9.0
        var fallen:=_box(interior,"VigaCaidaSueloV12_"+tag,
            Vector3(x,0.30,z-d*0.12),
            Vector3(w*0.77,0.23,0.25),REBAR,"steel")
        fallen.rotation_degrees.y=-17.0
        return
    # D3: view inside from above and behind without an artificial roof.
    # Joists visibly connect both irregular polygonal V11 side walls.
    var y: float=1.25 if level==1 else 1.48
    for beam in [-1,1]:
        var bz: float=z+float(beam)*d*0.30
        _box(interior,"VigaTransversalExpuestaV12_%s_%d" % [tag,beam],
            Vector3(x,y,bz),
            Vector3(w*0.86,0.16,0.19),
            REBAR if level==3 else WOOD,
            "steel" if level==3 else "stone")
        for side in [-1,1]:
            var px: float=x+float(side)*w*0.39
            _box(interior,
                "ApoyoVigaV12_%s_%d_%d" % [tag,beam,side],
                Vector3(px,y-0.16,bz),
                Vector3(0.23,0.36,0.29),CONCRETE)
    # A broken staircase starts on the basement slab and terminates in
    # mid-air because the upper floor collapsed (clearly visible at top view).
    for stair in range(4):
        var zz: float=z-d*0.15+float(stair)*d*0.13
        var yy: float=0.20+float(stair)*0.16
        var tread:=_box(interior,
            "EscalonInteriorRotoV12_%s_%d" % [tag,stair],
            Vector3(x+w*0.18,yy,zz),
            Vector3(w*0.38,0.13,d*0.14),
            CONCRETE if stair<3 else CHAR)
        if stair==3:
            tread.rotation_degrees.z=13.0
    # Exposed brick/steel must actually sit in the wall void.
    _box(interior,"ForroTabiqueCortadoV12_"+tag,
        Vector3(x-w*0.06,0.61,z+d*0.16),
        Vector3(0.12,1.05,d*0.37),BRICK)
    for bar in range(2):
        _rod(interior,"ArmaduraPilarInteriorV12_%s_%d" % [tag,bar],
            Vector3(x-w*0.28+float(bar)*w*0.55,
                0.83,z+d*0.24),0.045,1.31,REBAR)

static func _rubble_from_footprint(root: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        south_block: bool,damage: int) -> void:
    if damage==0:
        return
    var spill:=V1._group(root,"DerrameEscombrosConectadoV12_"+tag)
    # North buildings spill southward from their south wall (-2.38);
    # south buildings spill northward from their north wall (+2.22).
    # The outermost wedge stops before the existing road at |z|<=0.92,
    # staying within the 15.8x12.6 original city plot.
    var sign: float=-1.0 if south_block else 1.0
    var face: float=z-d*0.5 if south_block else z+d*0.5
    var count: int=2 if damage==1 else 5 if damage==2 else 8 if damage==3 else 10
    for i in range(count):
        var t: float=float(i)/float(maxi(count-1,1))
        var xx: float=x+(float(i%5)-2.0)*w*0.115
        var zz: float=face+sign*(0.12+0.54*t)
        var height: float=0.10+float((i+1)%3)*0.065
        if damage>=3:
            height+=0.09
        var stone: Color=BRICK if i%3==0 else CONCRETE if i%3==1 else CHAR
        var piece:=_rubble_wedge(spill,
            "FragmentoContinuoV12_%s_%d" % [tag,i],
            Vector3(xx,0.038,zz),
            Vector3(0.26+float(i%2)*0.18,height,
                0.30+float((i+1)%2)*0.21),
            stone,0.30 if i%2==0 else -0.26)
        piece.rotation_degrees.y=float(i*37%81)-39.0
    if damage>=2:
        # Side spill stays inside ±7.9m while keeping the main lane clear.
        for side in [-1,1]:
            var px: float=x+float(side)*(w*0.5+0.18)
            for i in range(2 if damage==2 else 3):
                var pos_z: float=z+(float(i)-1.0)*d*0.20
                _rubble_wedge(spill,
                    "CascoteCostadoV12_%s_%d_%d" % [tag,side,i],
                    Vector3(px+float(side)*0.09,0.035,pos_z),
                    Vector3(0.35,0.16+float(i)*0.04,0.39),
                    BRICK if side==-1 else DUST,float(side)*0.24)
    if damage>=3:
        # A concrete strip physically ties the larger rubble pile
        # to the missing doorway and to the fractured inner floor.
        _box(spill,"DintelDerribadoV12_"+tag,
            Vector3(x,0.16,face+sign*0.29),
            Vector3(w*0.47,0.21,0.30),CONCRETE)

static func _municipal_debris(root: Node3D,
        level: int,damage: int,accent: Color) -> void:
    if damage==0:
        return
    var hall:=V1._group(root,"DerrumbeAccesoMunicipalV12")
    var face: float=-3.75+2.74*0.5
    if damage==1:
        _rubble_wedge(hall,"PiedraDesgastadaMunicipalV12",
            Vector3(-1.04,0.06,face+0.34),
            Vector3(0.31,0.13,0.23),STONE)
        return
    if damage==2:
        var bent:=_box(hall,"BarandalDobladoMunicipalV12",
            Vector3(-0.80,0.27,face+0.48),
            Vector3(1.20,0.13,0.11),REBAR,"steel")
        bent.rotation_degrees.z=14.0
    else:
        # Real ruined municipal stairwell and fallen civic lintel.
        _box(hall,"EscaleraCivicaInterrumpidaV12",
            Vector3(-0.45,0.24,face-0.29),
            Vector3(0.75,0.42,0.48),CONCRETE)
        _box(hall,"VigaCivicaVolcadaV12",
            Vector3(0.54,0.33,face+0.30),
            Vector3(1.19,0.21,0.24),STONE)
    var count: int=3 if damage==2 else 6 if damage==3 else 9
    for index in range(count):
        var t: float=float(index)/float(maxi(count-1,1))
        var xx: float=(float(index%3)-1.0)*0.50
        var zz: float=face+0.15+0.66*t
        _rubble_wedge(hall,
            "CasquilloCivicoV12_%d" % index,
            Vector3(xx,0.04,zz),
            Vector3(0.28+0.07*float(index%2),
                0.14+0.07*float(index%3),0.35),
            CHAR if index%3==0 else STONE if index%3==1 else BRICK)
    if level==3 and damage>=3:
        _box(hall,"EscudoMunicipalSepultadoV12",
            Vector3(0.20,0.17,face+0.44),
            Vector3(0.39,0.11,0.34),accent,"steel")

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V9.STAGE_NAME)
            or not model.has_node(V10.STAGE_NAME)
            or not model.has_node(V11.STAGE_NAME)
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
        for south in [false,true]:
            var tag: String=("ResidencialSur_%d" % side
                if south else "ResidencialNorte_%d" % side)
            var z: float=3.62 if south else -3.80
            var w: float=2.77 if south else 2.74
            var d: float=2.80 if south else 2.84
            var floors: int=south_floors if south else north_floors
            _side_wear(stage,tag,x,z,w,d,floors,level,damage)
            _exposed_rooms(stage,tag,x,z,w,d,level,damage)
            _rubble_from_footprint(stage,tag,x,z,w,d,south,damage)
    var accent: Color=(Style.faction_color(faction) if faction>=0
        else V1.NEUTRAL_ACCENT)
    _municipal_debris(stage,level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",12)
    stage.set_meta("sculptural_focus",
        "broken-side-facades-open-room-cores-rubble-transition")
    stage.set_meta("damage",damage)
    model.set_meta("city_art_work_in_progress",12)
    model.set_meta("city_model_approved_final",false)
    return true
