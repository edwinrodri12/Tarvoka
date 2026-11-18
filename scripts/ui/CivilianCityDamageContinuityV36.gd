extends RefCounted
class_name TarvokaCivilianCityDamageContinuityV36

# V36: progressive architectural weathering from D0 to D4, based on the
# already existing V15/V23/V25/V28/V29/V30 and V35 native Godot meshes.
# No new roofs, rubble meshes, building volumes, paths, hitboxes or economy.
# Keep colored faction strips, windows, civic signage and roads untouched.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V35=preload("res://scripts/ui/CivilianCityFourSideFinishV35.gd")
const STAGE_NAME="CiudadCivilV36ContinuidadAcabadosDano"

const VILLA=Color("#b58466")
const TOWN=Color("#baa994")
const METROPOLIS=Color("#82949a")
const EARTH=Color("#84766b")
const CHAR=Color("#625e59")

static func _family(name: String,damage: int) -> String:
    # Return tier-invariant physical construction categories.
    # Names are drawn from actual V15/V23/V29/V30 geometry families.
    if damage<=1:
        for prefix in [
            "TejaCaballeraV15_","V23_VillaRematePerfil_",
            "CabioGableteV15_","MaderaInclinadaVillaV15_",
            "BandaParapetoPiedraV15_","BandaLadrilloRemateV15_",
            "V23_CiudadPerfilEscalonado_",
            "CoronaEscalonadaMetroV15_","V23_MetroPerfilCorona_",
            "V29_CosturaCubiertaFachada_","V28_RemateEsquinaSuperior_"]:
            if name.begins_with(prefix):
                return "silhouette"
        return ""
    if damage==2:
        for prefix in [
            "V23_BordeTejadoPartido_","V23_CosturaFachadaRota_",
            "V23_SombraJuntaFractura_",
            "V29_TerminacionCubiertaPartida_",
            "V29_JuntaFracturaInferior_",
            "TejaSueltaFracturadaVillaV15_",
            "CornisaDesgajadaCiudadV15_",
            "PerfilCoronaMetropoliRotoV15_",
            "V30_AlfardaVillaExpuesta_",
            "V30_SillarCornisaCiudadRoto_",
            "V30_NervioCoronaMetroTorsionado_"]:
            if name.begins_with(prefix):
                return "open_roof"
        return ""
    if damage==3:
        for prefix in [
            "V23_RetornoCascaron_","V23_ForjadoArrancado_",
            "V24_FiloForjadoInterrumpido_",
            "V25_CantoForjadoVisible_",
            "V29_CantoInteriorExpuesto_",
            "V30_EntramadoVillaInterior_",
            "V30_DintelLadrilloInterior_",
            "V30_SeccionVigaMetalInterior_",
            "VigaTransversalExpuestaV12_",
            "ArmaduraPilarInteriorV12_"]:
            if name.begins_with(prefix):
                return "exposed_structure"
        return ""
    for prefix in [
        "V23_CrestaRuinaBaja_",
        "V29_FragmentoCimientoAsentado_",
        "V30_TejaVillaDerruida_",
        "V30_BloqueCiudadDerruido_",
        "V30_PerfilMetroCaido_",
        "V12_FragmentoContinuo_",
        "FragmentoContinuoV12_",
        "CascoteCostadoV12_"]:
        if name.begins_with(prefix):
            return "ground_debris"
    return ""

static func _base(level: int) -> Color:
    return VILLA if level==1 else TOWN if level==2 else METROPOLIS

static func _finish_tint(level: int,damage: int,family: String) -> Color:
    # Keep original tier identity even for D4. Damage darkens on a
    # gradual ramp rather than painting all ruins a single gray.
    var dustiness: float=0.035 if damage==0 else (
        0.09 if damage==1 else
        0.25 if damage==2 else
        0.39 if damage==3 else 0.52)
    var target: Color=_base(level).lerp(
        CHAR if damage>=4 else EARTH,dustiness)
    if family=="exposed_structure":
        target=target.darkened(0.035)
    elif family=="ground_debris":
        target=target.darkened(0.055)
    return target

static func _roughness(damage: int) -> float:
    return 0.73 if damage==0 else 0.76 if damage==1 else (
        0.81 if damage==2 else 0.86 if damage==3 else 0.90)

static func _harmonize(mesh: MeshInstance3D,level: int,
        damage: int,family: String) -> bool:
    var prior: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if prior==null:
        return false
    # Avoid changing any cached/shared material. Duplicate retains
    # albedo texture, UVs, normal/metallic maps and shader settings.
    var finish: StandardMaterial3D=prior.duplicate() as StandardMaterial3D
    if finish==null:
        return false
    var blend: float=0.045 if damage==0 else (
        0.055 if damage==1 else
        0.095 if damage==2 else
        0.12 if damage==3 else 0.15)
    finish.albedo_color=prior.albedo_color.lerp(
        _finish_tint(level,damage,family),blend)
    finish.roughness=lerpf(prior.roughness,
        _roughness(damage),0.28)
    if level==3 and damage>=2:
        # Progressively exposed/oxidized steel keeps some metallic
        # response; do not make broken edges mirror-bright.
        finish.metallic=lerpf(
            prior.metallic,0.33 if damage==2 else 0.23,0.17)
    mesh.material_override=finish
    mesh.set_meta("city_v36_damage_continuity",family)
    return true

static func _restrained_profile(mesh: MeshInstance3D,
        family: String,damage: int) -> void:
    # Do not reconstruct roofs or move broken D3-D4 fragments.
    # Only tone down isolated outline thickness on existing pieces.
    var name: String=str(mesh.name)
    if family=="open_roof":
        if name.begins_with("V23_BordeTejadoPartido_"):
            mesh.scale.y=0.95
        elif name.begins_with("V29_JuntaFracturaInferior_"):
            mesh.scale.y=0.91
    elif family=="exposed_structure":
        if name.begins_with("V29_CantoInteriorExpuesto_"):
            mesh.scale.x=0.92
        elif name.begins_with("V30_SeccionVigaMetalInterior_"):
            mesh.scale.x=0.94
    elif family=="ground_debris" and damage==4:
        if name.begins_with("V29_FragmentoCimientoAsentado_"):
            mesh.scale.y=0.92
    mesh.set_meta("city_v36_restraint_checked",true)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V35.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var material_count: int=0
    var profile_count: int=0
    var queue: Array[Node]=[model]
    while not queue.is_empty():
        var current: Node=queue.pop_back()
        for child in current.get_children():
            queue.append(child)
        if not (current is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=current as MeshInstance3D
        if (bool(mesh.get_meta("city_v22_superseded",false))
                or bool(mesh.get_meta("v11_schematic_replaced",false))):
            continue
        var family: String=_family(str(mesh.name),damage)
        if family.is_empty():
            continue
        if not _harmonize(mesh,level,damage,family):
            continue
        material_count+=1
        if family=="open_roof" or family=="exposed_structure" or (
                family=="ground_debris" and damage==4):
            _restrained_profile(mesh,family,damage)
            profile_count+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",36)
    stage.set_meta("design_focus",
        "progressive-roof-shell-rubble-material-continuity-D0-D4")
    stage.set_meta("damage_stage",damage)
    model.set_meta("city_v36_materials_harmonized",material_count)
    model.set_meta("city_v36_profiles_checked",profile_count)
    model.set_meta("city_art_work_in_progress",36)
    model.set_meta("city_model_approved_final",false)
    return true
