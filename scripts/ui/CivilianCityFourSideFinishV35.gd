extends RefCounted
class_name TarvokaCivilianCityFourSideFinishV35

# TARVOKA V35 — balanced finishes seen from north, south, east and west.
# Modify only existing small contacts from V19/V27/V28/V29 and V34.
# V1 dimensions, V10 stairs/doors, V11 open ruins, V19 paths, faction
# markings and the original city economy remain untouched.
# No new render meshes, collisions, roads, props, roofs or gameplay logic.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V34=preload("res://scripts/ui/CivilianCityPublicRealmV34.gd")
const STAGE_NAME="CiudadCivilV35CoherenciaCuatroFachadas"

const WARM=Color("#a98871")
const STONE=Color("#b9b09c")
const COOL=Color("#84949a")
const DUST=Color("#80776d")

static func _kind(name: String,damage: int) -> String:
    if damage<=1:
        if name.begins_with("V28_EnlaceEsquinaLateral_"):
            return "side_corner_low"
        if name.begins_with("V28_RemateEsquinaSuperior_"):
            return "side_corner_high"
        if name.begins_with("V28_ZocaloNorteSur_"):
            return "front_rear_plinth"
        if name.begins_with("V19_EncuentroZocaloCostado_"):
            return "side_plinth"
        if name.begins_with("V19_AnclajeEsquinaMamposteria_"):
            return "masonry_corner"
        if name.begins_with("V27_PieFachadaAcera_"):
            return "sidewalk_foot"
        if name.begins_with("V29_CosturaCubiertaFachada_"):
            return "eave_seam"
    elif damage==2:
        if name.begins_with("V28_RetornoCantoRoto_"):
            return "broken_corner"
        if name.begins_with("V23_BordeTejadoPartido_"):
            return "broken_eave"
        if name.begins_with("V29_TerminacionCubiertaPartida_"):
            return "roof_cut"
        if name.begins_with("V27_MordidaZocalo_"):
            return "broken_plinth"
        if name.begins_with("V27_LosetaPasajeRota_"):
            return "broken_pavement"
    elif damage==3:
        if name.begins_with("V28_EncuentroBajoRuina_"):
            return "exposed_low_corner"
        if name.begins_with("V23_RetornoCascaron_"):
            return "exposed_wall"
        if name.begins_with("V27_EmpalmeAccesoColapsado_"):
            return "broken_entry"
        if name.begins_with("V27_JuntaPasajeColapsado_"):
            return "broken_path"
    else:
        if name.begins_with("V28_EncuentroBajoRuina_"):
            return "ruin_foot"
        if name.begins_with("V29_FragmentoCimientoAsentado_"):
            return "ruin_fragment"
        if name.begins_with("V27_BordePlazaQuebrado_"):
            return "ruined_square"
        if name.begins_with("V27_AristaAccesoMunicipalRota_"):
            return "ruined_civic"
    return ""

static func _rescale(mesh: MeshInstance3D,kind: String) -> void:
    # Absolute local-scale limits, not a new extension of existing
    # facade volumes. Keep their x/z placements and all entrance gaps.
    match kind:
        "side_corner_low":
            mesh.scale.x=0.91
            mesh.scale.z=0.94
        "side_corner_high":
            mesh.scale.x=0.85
            mesh.scale.z=0.88
        "front_rear_plinth":
            mesh.scale.x=0.90
            mesh.scale.y=0.88
        "side_plinth":
            mesh.scale.x=0.93
            mesh.scale.z=0.97
        "masonry_corner":
            mesh.scale.x=0.94
            mesh.scale.z=0.93
        "sidewalk_foot":
            mesh.scale.x=0.90
            mesh.scale.z=0.86
        "eave_seam":
            mesh.scale.x=0.88
        "broken_corner":
            mesh.scale.x=0.92
            mesh.scale.y=0.93
        "broken_eave":
            mesh.scale.x=0.95
            mesh.scale.z=0.95
        "roof_cut":
            mesh.scale.x=0.90
        "broken_plinth":
            mesh.scale.y=0.92
        "broken_pavement":
            mesh.scale.y=0.91
        "exposed_low_corner":
            mesh.scale.x=0.91
            mesh.scale.z=0.94
        "exposed_wall":
            mesh.scale.x=0.95
        "broken_entry","broken_path":
            mesh.scale.y=0.88
        "ruin_foot","ruin_fragment":
            mesh.scale.x=0.92
            mesh.scale.z=0.94
        "ruined_square","ruined_civic":
            mesh.scale.y=0.90
    mesh.set_meta("city_v35_refined_kind",kind)

static func _surface_color(level: int,damage: int) -> Color:
    var neutral: Color=WARM if level==1 else STONE if level==2 else COOL
    return neutral.lerp(DUST,
        0.07 if damage==0 else 0.12 if damage==1 else
        0.26 if damage==2 else 0.41 if damage==3 else 0.54)

static func _refinish(mesh: MeshInstance3D,
        level: int,damage: int,kind: String) -> bool:
    var current: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if current==null:
        return false
    var duplicate: StandardMaterial3D=current.duplicate() as StandardMaterial3D
    if duplicate==null:
        return false
    _rescale(mesh,kind)
    # Very slight lightness/roughness reconciliation with the adjacent
    # V34 paving. Preserve original textures and all faction colors.
    duplicate.albedo_color=current.albedo_color.lerp(
        _surface_color(level,damage),0.055 if damage<2 else 0.092)
    duplicate.roughness=lerpf(
        current.roughness,0.79 if damage<2 else 0.90,0.20)
    mesh.material_override=duplicate
    return true

static func _side(mesh: MeshInstance3D,kind: String) -> String:
    # Four-elevation metadata counts aid manual review without changing
    # the mesh itself. Side contacts are naturally oriented E/W,
    # while gables, plinths and eaves can be reviewed from N/S.
    if kind in ["side_corner_low","side_corner_high",
            "side_plinth","masonry_corner","broken_corner",
            "exposed_low_corner","ruin_foot","exposed_wall"]:
        return "east" if mesh.position.x>=0.0 else "west"
    return "south" if mesh.position.z>=0.0 else "north"

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V34.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var changed: int=0
    var cardinal: Dictionary={
        "north":0,"south":0,"east":0,"west":0
    }
    var queue: Array[Node]=[model]
    while not queue.is_empty():
        var node: Node=queue.pop_back()
        for child in node.get_children():
            queue.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if (bool(mesh.get_meta("city_v22_superseded",false))
                or bool(mesh.get_meta("v11_schematic_replaced",false))):
            continue
        var kind: String=_kind(str(mesh.name),damage)
        if kind.is_empty():
            continue
        if not _refinish(mesh,level,damage,kind):
            continue
        var side: String=_side(mesh,kind)
        cardinal[side]=int(cardinal[side])+1
        mesh.set_meta("city_v35_review_direction",side)
        changed+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",35)
    stage.set_meta("four_side_review",cardinal)
    stage.set_meta("design_focus",
        "all-elevations-existing-facade-corners-roof-pavement-ruins")
    model.set_meta("city_v35_refinished_meshes",changed)
    model.set_meta("city_v35_direction_counts",cardinal)
    model.set_meta("city_art_work_in_progress",35)
    model.set_meta("city_model_approved_final",false)
    return true
