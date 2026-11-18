extends RefCounted
class_name TarvokaCivilianCityTacticalFinishV37

# TARVOKA V37: visual finishing of ALREADY MODELED roof joins, facade
# corners and ruin fragments as seen from the elevated game camera.
# D0-D1: let each tier's roof rhythm read clearly; D2: keep the real
# opening visible; D3: expose broken structure; D4: settle low rubble.
# The primary V1 facade/roof geometry, jagged V11 polygon shells,
# V10 portals, roads, collision, faction accents and gameplay are untouched.
# This stage adds no MeshInstance3D, new geometry or decorative sprites.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V36=preload("res://scripts/ui/CivilianCityDamageContinuityV36.gd")
const STAGE_NAME="CiudadCivilV37AcabadoLecturaTactica"

const VILLA=Color("#b4886e")
const TOWN=Color("#b8a996")
const METRO=Color("#7d929a")
const DUST=Color("#81786e")

static func _detail_family(name: String,damage: int) -> String:
    if damage<=1:
        if name.begins_with("V23_VillaRematePerfil_"):
            return "villa_roof"
        if name.begins_with("V23_CiudadPerfilEscalonado_"):
            return "town_parapet"
        if name.begins_with("V23_MetroPerfilCorona_"):
            return "metro_crown"
        if name.begins_with("V29_CosturaCubiertaFachada_"):
            return "roof_join"
        if name.begins_with("V28_RemateEsquinaSuperior_"):
            return "corner_trim"
    elif damage==2:
        if name.begins_with("V23_BordeTejadoPartido_"):
            return "roof_break"
        if name.begins_with("V23_CosturaFachadaRota_"):
            return "open_wall_join"
        if name.begins_with("V29_TerminacionCubiertaPartida_"):
            return "broken_roof_end"
        if name.begins_with("V30_AlfardaVillaExpuesta_"):
            return "villa_exposed"
        if name.begins_with("V30_SillarCornisaCiudadRoto_"):
            return "town_exposed"
        if name.begins_with("V30_NervioCoronaMetroTorsionado_"):
            return "metro_exposed"
    elif damage==3:
        if name.begins_with("V23_ForjadoArrancado_"):
            return "open_floor"
        if name.begins_with("V29_CantoInteriorExpuesto_"):
            return "inner_edge"
        if name.begins_with("V30_EntramadoVillaInterior_"):
            return "villa_inner"
        if name.begins_with("V30_DintelLadrilloInterior_"):
            return "town_inner"
        if name.begins_with("V30_SeccionVigaMetalInterior_"):
            return "metro_inner"
    elif damage==4:
        if name.begins_with("V23_CrestaRuinaBaja_"):
            return "ruin_crest"
        if name.begins_with("V29_FragmentoCimientoAsentado_"):
            return "foundation_fragment"
        if name.begins_with("V30_TejaVillaDerruida_"):
            return "villa_debris"
        if name.begins_with("V30_BloqueCiudadDerruido_"):
            return "town_debris"
        if name.begins_with("V30_PerfilMetroCaido_"):
            return "metro_debris"
    return ""

static func _trim_existing(mesh: MeshInstance3D,
        family: String) -> bool:
    # Absolute, very small profile edits. Never move an opening,
    # reinstate destroyed roofs or offset entire facade meshes.
    match family:
        "villa_roof":
            mesh.scale.z=0.94
        "town_parapet":
            mesh.scale.z=0.95
        "metro_crown":
            mesh.scale.z=0.93
        "roof_join":
            mesh.scale.z=0.93
        "corner_trim":
            mesh.scale.y=0.93
        "roof_break":
            mesh.scale.x=0.93
        "open_wall_join":
            mesh.scale.x=0.94
        "broken_roof_end":
            mesh.scale.z=0.93
        "villa_exposed":
            mesh.scale.x=0.96
        "town_exposed":
            mesh.scale.x=0.94
        "metro_exposed":
            mesh.scale.x=0.93
        "open_floor":
            mesh.scale.y=0.92
        "inner_edge":
            mesh.scale.z=0.92
        "villa_inner","town_inner","metro_inner":
            mesh.scale.x=0.94
        "ruin_crest":
            mesh.scale.y=0.94
        "foundation_fragment":
            mesh.scale.x=0.93
        "villa_debris","town_debris","metro_debris":
            mesh.scale.x=0.95
    mesh.set_meta("city_v37_tactical_family",family)
    return true

static func _tone(level: int,damage: int) -> Color:
    var original: Color=VILLA if level==1 else TOWN if level==2 else METRO
    var wear: float=0.04 if damage==0 else (
        0.10 if damage==1 else 0.24 if damage==2 else
        0.40 if damage==3 else 0.54)
    return original.lerp(DUST,wear)

static func _finish(mesh: MeshInstance3D,
        level: int,damage: int) -> bool:
    var old: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if old==null:
        return false
    # Duplicate cached weather materials so the rest of the district,
    # other units and faction trim retain their previous look.
    var updated: StandardMaterial3D=old.duplicate() as StandardMaterial3D
    if updated==null:
        return false
    updated.albedo_color=old.albedo_color.lerp(
        _tone(level,damage),0.04 if damage<=1 else 0.075)
    updated.roughness=lerpf(
        old.roughness,0.78 if damage<=1 else 0.88,0.16)
    mesh.material_override=updated
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V36.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var trimmed: int=0
    var finished: int=0
    var family_counts: Dictionary={}
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
        var family: String=_detail_family(str(mesh.name),damage)
        if family.is_empty():
            continue
        if not _finish(mesh,level,damage):
            continue
        _trim_existing(mesh,family)
        finished+=1
        trimmed+=1
        family_counts[family]=int(family_counts.get(family,0))+1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",37)
    stage.set_meta("design_focus",
        "existing-roof-facade-and-ruin-profile-clarity-at-tactical-angle")
    model.set_meta("city_v37_profiles_refined",trimmed)
    model.set_meta("city_v37_materials_refined",finished)
    model.set_meta("city_v37_families",family_counts)
    model.set_meta("city_art_work_in_progress",37)
    model.set_meta("city_model_approved_final",false)
    return true
