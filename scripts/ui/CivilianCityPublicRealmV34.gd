extends RefCounted
class_name TarvokaCivilianCityPublicRealmV34

# V34 — visual cohesion of the EXISTING civilian-city public realm:
# residential thresholds V10, side passages V19, plaza edges V19/V27,
# and the civic approach V10/V27. No new meshes, roads, doorways, hitboxes,
# paths, captures, production, faction marks, or gameplay modifications.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V33=preload("res://scripts/ui/CivilianCityMaterialContinuityV33.gd")
const STAGE_NAME="CiudadCivilV34ContinuidadEspaciosPublicos"

const CLAY=Color("#b49b84")
const STONE=Color("#beb29e")
const PAVEMENT=Color("#a2a7a3")
const DUST=Color("#877d70")
const RUIN=Color("#706b63")

static func _target(name: String,damage: int) -> String:
    # Return a structural category. Keep original public-space slabs as
    # authorities; modify tiny seams, return profiles and edge materials.
    if damage<=2:
        if name.begins_with("V27_JuntaDilatacionUmbral_"):
            return "threshold_seam"
        if name.begins_with("V27_UnionLosetaAcera_"):
            return "threshold_transition"
        if name.begins_with("V27_PieFachadaAcera_"):
            return "facade_foot"
        if name.begins_with("V27_EncuentroAdoquinPasaje_"):
            return "passage_joint"
        if name.begins_with("V27_LosetaCierrePlaza_"):
            return "square_tile"
        if name.begins_with("V27_JuntaRampaMunicipal_"):
            return "civic_joint"
        if name.begins_with("V19_RibetePerimetralPlaza_"):
            return "square_border"
        if name.begins_with("V19_EncuentroCallePasaje_"):
            return "passage_termination"
        if name.begins_with("V19_UnionPlazaComercio"):
            return "square_commerce"
        if name.begins_with("BordilloEntradaV10_"):
            return "entrance_edge"
        if name.begins_with("BordeRampaMunicipalV10_"):
            return "municipal_edge"
        if damage==2:
            if name.begins_with("V27_LosetaPasajeRota_"):
                return "chipped_passage"
            if name.begins_with("V27_AdoquinDesportillado_"):
                return "chipped_square"
    else:
        # D3/D4 MUST remain open, fractured and impassable where V11
        # has already replaced the walkway/portal with real ruin meshes.
        if name.begins_with("V27_EmpalmeAccesoColapsado_"):
            return "collapsed_entry"
        if name.begins_with("V27_JuntaPasajeColapsado_"):
            return "collapsed_passage"
        if name.begins_with("V27_BordePlazaQuebrado_"):
            return "collapsed_square"
        if name.begins_with("V27_AristaAccesoMunicipalRota_"):
            return "collapsed_hall"
        if name.begins_with("V19_BordePlazaDerruido_"):
            return "collapsed_perimeter"
    return ""

static func _scale_and_seat(mesh: MeshInstance3D,kind: String) -> void:
    # All changes are local to an existing render mesh. No x/z shifts:
    # the road boundary z=-0.92..0.92 remains untouched.
    match kind:
        "threshold_seam":
            mesh.position.y=0.145
            mesh.scale.y=0.84
        "threshold_transition":
            mesh.position.y=0.103
            mesh.scale.y=0.91
        "facade_foot":
            mesh.scale.x=0.92
            mesh.scale.z=0.88
        "passage_joint":
            mesh.position.y=0.145
            mesh.scale.y=0.89
        "square_tile":
            mesh.position.y=0.083
            mesh.scale.y=0.88
        "civic_joint":
            mesh.position.y=0.107
            mesh.scale.y=0.87
        "square_border":
            mesh.scale.x=0.93
            mesh.scale.y=0.88
        "passage_termination":
            mesh.scale.y=0.91
        "square_commerce":
            mesh.scale.y=0.89
        "entrance_edge":
            mesh.scale.y=0.94
        "municipal_edge":
            mesh.scale.y=0.94
        "chipped_passage", "chipped_square":
            mesh.scale.y=0.94
        "collapsed_entry", "collapsed_passage":
            mesh.scale.y=0.90
        "collapsed_square", "collapsed_hall", "collapsed_perimeter":
            mesh.scale.y=0.92
    mesh.set_meta("city_v34_street_contact_refined",kind)

static func _material_tint(level: int,damage: int) -> Color:
    var color: Color=CLAY if level==1 else STONE if level==2 else PAVEMENT
    return color.lerp(DUST if damage<=2 else RUIN,
        0.09 if damage==0 else
        0.13 if damage==1 else
        0.28 if damage==2 else
        0.42 if damage==3 else 0.52)

static func _finish_existing(mesh: MeshInstance3D,
        level: int,damage: int,kind: String) -> bool:
    _scale_and_seat(mesh,kind)
    var material: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if material==null:
        return false
    # Never alter globally cached V9/V26 materials: clone prior finish,
    # keep its textures and UVs, and avoid painting faction markings.
    var independent: StandardMaterial3D=material.duplicate() as StandardMaterial3D
    if independent==null:
        return false
    independent.albedo_color=material.albedo_color.lerp(
        _material_tint(level,damage),0.12 if damage<3 else 0.17)
    independent.roughness=lerpf(
        material.roughness,0.83 if damage<=1 else 0.92,0.34)
    if kind=="entrance_edge" or kind=="municipal_edge":
        independent.metallic=lerpf(material.metallic,0.0,0.19)
    mesh.material_override=independent
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V33.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var joins: int=0
    var thresholds: int=0
    var passages: int=0
    var civic: int=0
    var ruins: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if (bool(mesh.get_meta("city_v22_superseded",false))
                or bool(mesh.get_meta("v11_schematic_replaced",false))):
            continue
        var category: String=_target(str(mesh.name),damage)
        if category.is_empty():
            continue
        if not _finish_existing(mesh,level,damage,category):
            continue
        joins+=1
        if category.begins_with("collapsed_"):
            ruins+=1
        elif category in [
                "threshold_seam","threshold_transition","facade_foot",
                "entrance_edge","municipal_edge","civic_joint"]:
            thresholds+=1
        elif category in [
                "passage_joint","passage_termination","chipped_passage"]:
            passages+=1
        else:
            civic+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",34)
    stage.set_meta("road_geometry_unchanged",true)
    stage.set_meta("design_focus",
        "existing-entries-sidewalk-passages-plaza-civic-approach")
    model.set_meta("city_v34_contact_refinements",joins)
    model.set_meta("city_v34_thresholds",thresholds)
    model.set_meta("city_v34_passages",passages)
    model.set_meta("city_v34_civic",civic)
    model.set_meta("city_v34_ruin_edges",ruins)
    model.set_meta("city_art_work_in_progress",34)
    model.set_meta("city_model_approved_final",false)
    return true
