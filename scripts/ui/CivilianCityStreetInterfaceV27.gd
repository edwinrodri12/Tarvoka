extends RefCounted
class_name TarvokaCivilianCityStreetInterfaceV27

# V27 ART ONLY: finish the interface between existing V10 entrances,
# V19 civic passages and V1 sidewalks/plaza. No new roads, no overlapping
# new building, no walkability/collision/combat/income/capture changes.
# Uses genuine Godot meshes, not decals or image proxies.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V10=preload("res://scripts/ui/CivilianCityGroundFrontV10.gd")
const V19=preload("res://scripts/ui/CivilianCityUrbanCohesionV19.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const STAGE_NAME="CiudadCivilV27EncuentroFachadasAcerasPlaza"

const SAND=Color("#b6aa94")
const CLAY=Color("#b18368")
const BRICK=Color("#9d7761")
const MORTAR=Color("#b4a796")
const PAVEMENT=Color("#9fa4a0")
const LIMESTONE=Color("#c7bba7")
const METAL=Color("#6d8287")
const OXIDE=Color("#625c53")
const DUST=Color("#867a6d")
const RUBBLE=Color("#6c645c")

static func _stone(level: int) -> Color:
    return CLAY if level==1 else LIMESTONE if level==2 else PAVEMENT

static func _surface(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _part(parent: Node3D,label: String,
        position: Vector3,dimensions: Vector3,color: Color,
        level: int,damage: int,finish: String="stone") -> MeshInstance3D:
    var mesh: MeshInstance3D=V1._box(parent,label,position,dimensions,color)
    mesh.material_override=V26._material(
        level,damage,posmod(label.hash(),5),color,finish)
    return mesh

static func _refinish_existing(model: Node3D,
        level: int,damage: int) -> int:
    # Only the ACTUAL pedestrian materials built by V10 and V19.
    # Never touch tactical ground dimensions, roadway, windows, signage,
    # faction stripes, vegetation, city capture/economy or other units.
    var prefixes: Array[String]=[
        "UmbralPavimentadoV10_",
        "BordilloEntradaV10_",
        "PlataformaAccesoCivilV10",
        "RampaPeatonalConectadaV10",
        "BordeRampaMunicipalV10_",
        "V19_PasajePeatonal_",
        "V19_EncuentroCallePasaje_",
        "V19_RibetePerimetralPlaza_",
        "V19_PasajeInterrumpido_",
        "V19_BordePlazaDerruido_"
    ]
    var changed: int=0
    var queue: Array[Node]=[model]
    while not queue.is_empty():
        var current: Node=queue.pop_back()
        for child in current.get_children():
            queue.append(child)
        if not (current is MeshInstance3D):
            continue
        var mesh:=current as MeshInstance3D
        var name: String=str(mesh.name)
        var selected: bool=false
        for prefix in prefixes:
            if name.begins_with(prefix):
                selected=true
                break
        if not selected:
            continue
        # Material-only replacement of existing meshes: all positions,
        # walkways and collision-free city design remain untouched.
        var previous:=mesh.material_override as StandardMaterial3D
        if previous==null:
            continue
        var tint: Color=previous.albedo_color
        var material: StandardMaterial3D=V26._material(
            level,damage,posmod(name.hash(),5),
            tint,"stone" if level<3 else "steel")
        mesh.material_override=material
        mesh.set_meta("city_v27_street_finish",true)
        changed+=1
    return changed

static func _building_threshold(stage: Node3D,tag: String,
        x: float,z: float,width: float,depth: float,
        is_south: bool,level: int,damage: int) -> void:
    var path:=V1._group(stage,"AceraPortalV27_"+tag)
    # Exact geometry from V10: north rear -2.38 -> sidewalk -1.37;
    # south front 2.22 -> sidewalk 1.37. Never enter the road
    # surface at z=-0.92..+0.92 and never place over x=0 doorway.
    var sign: float=-1.0 if is_south else 1.0
    var facade: float=z-depth*0.5 if is_south else z+depth*0.5
    var sidewalk: float=1.37 if is_south else -1.37
    var walkway_middle: float=(facade+sidewalk)*0.5
    if damage>=3:
        # Existing V10 access and V19 side paths are already ruined;
        # low ground fragments make contact, not a fresh intact ramp.
        for side in [-1,1]:
            var xx: float=x+float(side)*0.58
            var chunk:=_part(path,
                "V27_EmpalmeAccesoColapsado_%s_%d" % [tag,side],
                Vector3(xx,0.105,sidewalk-sign*0.13),
                Vector3(0.27,0.12,0.31),
                BRICK if level==1 else DUST if level==2 else OXIDE,
                level,damage)
            chunk.rotation_degrees.y=float(side)*13.0
        return
    # One modest transition seam at either shoulder of the already
    # finished V10 porch/stoop, INSIDE its existing footprint.
    for side in [-1,1]:
        var xx: float=x+float(side)*0.45
        _part(path,
            "V27_JuntaDilatacionUmbral_%s_%d" % [tag,side],
            Vector3(xx,0.165,walkway_middle+sign*0.07),
            Vector3(0.23,0.019,0.065),
            MORTAR if level==1 else PAVEMENT,
            level,damage)
        if damage==2 and side==1:
            # This D2 corner is chipped; do NOT draw a perfect
            # unbroken border across the existing V10 rubble patch.
            _part(path,"V27_MordidaZocalo_%s" % tag,
                Vector3(x+0.58,0.12,facade+sign*0.17),
                Vector3(0.21,0.10,0.19),DUST,level,damage)
            continue
        # Small footing joins touch the facade end, not the shop door
        # (the entrance occupies the x-center).
        _part(path,
            "V27_PieFachadaAcera_%s_%d" % [tag,side],
            Vector3(x+float(side)*width*0.395,0.125,
                facade+sign*0.08),
            Vector3(0.15,0.17,0.14),_stone(level),level,damage)
    # Centered existing path remains open; a narrow, ground-level
    # material transition touches sidewalk but does not cross into road.
    _part(path,"V27_UnionLosetaAcera_"+tag,
        Vector3(x,0.156,sidewalk+sign*0.065),
        Vector3(0.72,0.025,0.075),
        CLAY if level==1 else MORTAR if level==2 else METAL,
        level,damage,"steel" if level==3 else "stone")

static func _passage_edge(stage: Node3D,
        level: int,damage: int) -> void:
    var group:=V1._group(stage,"EncuentrosPasajesV27")
    # Existing V19 service paths are centered x +/-2.47 and end at
    # z +/-1.39. The original road is between -0.92 and +0.92.
    for side in [-1,1]:
        var x: float=float(side)*2.47
        for neighborhood in [-1,1]:
            var face: float=float(neighborhood)
            var terminal: float=face*1.39
            if damage>=3:
                var broken:=_part(group,
                    "V27_JuntaPasajeColapsado_%d_%d" %
                    [side,neighborhood],
                    Vector3(x+0.12,0.11,terminal+face*0.18),
                    Vector3(0.37,0.11,0.28),
                    DUST,level,damage)
                broken.rotation_degrees.y=float(side*neighborhood)*11.0
                continue
            # Lateral joint at the termination of the EXISTING walkway.
            # It deliberately does not create a second full street slab.
            for edge in [-1,1]:
                _part(group,
                    "V27_EncuentroAdoquinPasaje_%d_%d_%d" %
                    [side,neighborhood,edge],
                    Vector3(x+float(edge)*0.32,0.159,
                        terminal+face*0.065),
                    Vector3(0.18,0.025,0.075),
                    _stone(level),level,damage)
            if damage==2:
                _part(group,
                    "V27_LosetaPasajeRota_%d_%d" %
                    [side,neighborhood],
                    Vector3(x-0.18,0.13,terminal+face*0.16),
                    Vector3(0.22,0.06,0.20),DUST,level,damage)

static func _civic_square_edge(stage: Node3D,
        level: int,damage: int) -> void:
    # Plaza V1 is centered x=0,z=2, with monument at z=2.04.
    # V19 owns perimeter. Detail only rear lateral corners away from
    # benches (x +/-2.55) and beds (x +/-1.47, z=2.45).
    var square:=V1._group(stage,"TransicionPlazaCivicaV27")
    for side in [-1,1]:
        var x: float=float(side)*1.45
        if damage>=3:
            _part(square,"V27_BordePlazaQuebrado_%d" % side,
                Vector3(x,0.09,3.01),
                Vector3(0.24,0.12,0.21),
                RUBBLE if side==-1 else DUST,level,damage)
            continue
        for i in range(2):
            _part(square,
                "V27_LosetaCierrePlaza_%d_%d" % [side,i],
                Vector3(x+float(side)*0.045,0.121,
                    2.92+float(i)*0.17),
                Vector3(0.19,0.028,0.11),_stone(level),level,damage)
        if damage==2:
            _part(square,"V27_AdoquinDesportillado_%d" % side,
                Vector3(x,0.132,3.06),
                Vector3(0.21,0.045,0.19),
                DUST,level,damage)
    square.set_meta("keeps_monument_clear",true)

static func _town_hall_approach(stage: Node3D,
        level: int,damage: int) -> void:
    # Civic entrance V10 uses one existing 2.23m approach around
    # z=-1.89. Finish only two edge joints, NOT another ramp.
    var hall:=V1._group(stage,"JuntasRampaAyuntamientoV27")
    for side in [-1,1]:
        var sx: float=float(side)*0.84
        if damage>=3:
            _part(hall,
                "V27_AristaAccesoMunicipalRota_%d" % side,
                Vector3(sx,0.115,-1.63),
                Vector3(0.23,0.11,0.27),RUBBLE,level,damage)
            continue
        _part(hall,"V27_JuntaRampaMunicipal_%d" % side,
            Vector3(sx,0.143,-1.39),
            Vector3(0.16,0.024,0.085),
            CLAY if level==1 else LIMESTONE if level==2 else PAVEMENT,
            level,damage)
    hall.set_meta("no_road_crossing",true)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if (not model.has_node(V26.STAGE_NAME)
            or not model.has_node(V10.STAGE_NAME)
            or not model.has_node(V19.STAGE_NAME)
            or model.has_node(STAGE_NAME)):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var refinished: int=_refinish_existing(model,level,damage)
    var stage:=V1._group(model,STAGE_NAME)
    for side in [-1,1]:
        var x: float=float(side)*4.63
        _building_threshold(stage,"Norte_%d" % side,
            x,-3.80,2.74,2.84,false,level,damage)
        _building_threshold(stage,"Sur_%d" % side,
            x,3.62,2.77,2.80,true,level,damage)
    _passage_edge(stage,level,damage)
    _civic_square_edge(stage,level,damage)
    _town_hall_approach(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",27)
    stage.set_meta("refinished_existing_pavement",refinished)
    stage.set_meta("design_focus","facades-stoops-sidewalk-transitions-and-civic-square")
    stage.set_meta("road_geometry_unchanged",true)
    model.set_meta("city_v27_pavement_reconciled",refinished)
    model.set_meta("city_art_work_in_progress",27)
    model.set_meta("city_model_approved_final",false)
    return true
