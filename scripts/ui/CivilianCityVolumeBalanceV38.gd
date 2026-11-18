extends RefCounted
class_name TarvokaCivilianCityVolumeBalanceV38

# V38 — volumetric balance of the EXISTING native city district.
# Make Villa read as pitched/low, Ciudad as masonry/horizontal,
# and Metropoli as stepped/vertical from the gameplay camera.
# Fine-tune original roof-mass visibility instead of adding a new roof.
# Never change lot footprint, wall volume/floor height, doors/windows,
# V11 damage holes, faction colors, navigation, collision or economy.
# This stage creates NO additional MeshInstance3D objects.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V37=preload("res://scripts/ui/CivilianCityTacticalFinishV37.gd")
const STAGE_NAME="CiudadCivilV38BalanceVolumenTresNiveles"

static func _role(mesh: MeshInstance3D,level: int,
        damage: int) -> String:
    var n: String=str(mesh.name)
    if damage<=1:
        # V1 authored one low horizontal roof box per EdificioCivil;
        # later V2/V14 actual roof sculpture remains untouched.
        if (n=="Cubierta" and mesh.get_parent()!=null
                and str(mesh.get_parent().name).begins_with("EdificioCivil_")):
            return "base_roof"
        if level==1:
            if n.begins_with("TejaCaballeraV15_"):
                return "villa_ridge"
            if n.begins_with("CabioGableteV15_"):
                return "villa_gable"
            if n.begins_with("MaderaInclinadaVillaV15_"):
                return "villa_brace"
            if n.begins_with("AleroMaderaVillaV15_"):
                return "villa_eave"
            if n.begins_with("V23_VillaRematePerfil_"):
                return "villa_profile"
        elif level==2:
            if n.begins_with("BandaParapetoPiedraV15_"):
                return "town_parapet"
            if n.begins_with("BandaLadrilloRemateV15_"):
                return "town_cornice"
            if n.begins_with("HileraMamposteriaV15_"):
                return "town_band"
            if n.begins_with("V23_CiudadPerfilEscalonado_"):
                return "town_step"
        else:
            if n.begins_with("CoronaEscalonadaMetroV15_"):
                return "metro_crown"
            if n.begins_with("NervaduraAluminioAltaV15_"):
                return "metro_mullion"
            if n.begins_with("V23_MetroPerfilCorona_"):
                return "metro_fin"
            if n.begins_with("AletaCoronaMetropoliV4_"):
                return "metro_fascia"
        return ""
    if damage==2:
        if level==1 and n.begins_with("TejaSueltaFracturadaVillaV15_"):
            return "d2_villa"
        if level==2 and n.begins_with("CornisaDesgajadaCiudadV15_"):
            return "d2_town"
        if level==3 and n.begins_with("PerfilCoronaMetropoliRotoV15_"):
            return "d2_metro"
        # Prevent small D2 edges from looking like another intact roof.
        if n.begins_with("V23_BordeTejadoPartido_"):
            return "d2_roof_edge"
    elif damage==3:
        if level==1 and n.begins_with("VigaVernacularCaidaV15_"):
            return "d3_villa"
        if level==2 and n.begins_with("PilastraMamposteriaTruncadaV15_"):
            return "d3_town"
        if level==3 and n.begins_with("PilarMetropoliAbiertoV15_"):
            return "d3_metro"
        if n.begins_with("V23_ForjadoArrancado_"):
            return "d3_floor"
    else:
        if level==1 and n.begins_with("V30_TejaVillaDerruida_"):
            return "d4_villa"
        if level==2 and n.begins_with("V30_BloqueCiudadDerruido_"):
            return "d4_town"
        if level==3 and n.begins_with("V30_PerfilMetroCaido_"):
            return "d4_metro"
        if n.begins_with("V23_CrestaRuinaBaja_"):
            return "d4_ruin_base"
    return ""

static func _retune(mesh: MeshInstance3D,level: int,
        role: String) -> bool:
    # Targeted absolute local scales avoid cumulative distortion across
    # V30–V37. Only small profile widths/depths/heights change.
    match role:
        "base_roof":
            # Reveal the pitched/stepped roof designs already above it.
            mesh.scale.y=0.74 if level==1 else 0.83 if level==2 else 0.80
            mesh.scale.x=0.98 if level==1 else 0.97 if level==2 else 0.96
            mesh.scale.z=0.98
        "villa_ridge":
            mesh.scale.x=0.81
            mesh.scale.z=1.08
        "villa_gable":
            mesh.scale.x=0.92
            mesh.scale.y=0.94
        "villa_brace":
            mesh.scale.x=0.90
            mesh.scale.y=1.04
        "villa_eave":
            mesh.scale.y=0.88
        "villa_profile":
            mesh.scale.y=0.94
            mesh.scale.z=0.96
        "town_parapet":
            mesh.scale.x=0.98
            mesh.scale.y=0.94
        "town_cornice":
            mesh.scale.x=0.97
            mesh.scale.y=0.99
        "town_band":
            mesh.scale.y=0.79
        "town_step":
            mesh.scale.x=0.94
            mesh.scale.y=0.94
        "metro_crown":
            mesh.scale.x=0.88
            mesh.scale.y=1.20
        "metro_mullion":
            mesh.scale.x=0.86
        "metro_fin":
            mesh.scale.x=0.82
            mesh.scale.y=1.21
        "metro_fascia":
            mesh.scale.x=0.90
        "d2_villa":
            mesh.scale.x=0.91
            mesh.scale.z=0.93
        "d2_town":
            mesh.scale.x=0.88
            mesh.scale.y=0.95
        "d2_metro":
            mesh.scale.x=0.89
            mesh.scale.y=0.97
        "d2_roof_edge":
            mesh.scale.x=0.94
            mesh.scale.y=0.94
        "d3_villa":
            mesh.scale.y=0.91
        "d3_town":
            mesh.scale.x=0.90
        "d3_metro":
            mesh.scale.x=0.90
        "d3_floor":
            mesh.scale.y=0.93
        "d4_villa","d4_town","d4_metro":
            mesh.scale.x=0.94
        "d4_ruin_base":
            mesh.scale.y=0.94
        _:
            return false
    mesh.set_meta("city_v38_volume_role",role)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V37.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var roof_mass: int=0
    var tier_shape: int=0
    var broken_shape: int=0
    var by_role: Dictionary={}
    var nodes: Array[Node]=[model]
    while not nodes.is_empty():
        var node: Node=nodes.pop_back()
        for child in node.get_children():
            nodes.append(child)
        if not (node is MeshInstance3D):
            continue
        var piece: MeshInstance3D=node as MeshInstance3D
        if (bool(piece.get_meta("city_v22_superseded",false))
                or bool(piece.get_meta("v11_schematic_replaced",false))):
            continue
        var role: String=_role(piece,level,damage)
        if role.is_empty() or not _retune(piece,level,role):
            continue
        if role=="base_roof":
            roof_mass+=1
        elif damage<=1:
            tier_shape+=1
        else:
            broken_shape+=1
        by_role[role]=int(by_role.get(role,0))+1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",38)
    stage.set_meta("design_focus",
        "villa-pitched-town-horizontal-metropolis-vertical-volume-balance")
    model.set_meta("city_v38_roof_mass_balanced",roof_mass)
    model.set_meta("city_v38_tier_profiles_balanced",tier_shape)
    model.set_meta("city_v38_damaged_profiles_balanced",broken_shape)
    model.set_meta("city_v38_volume_role_counts",by_role)
    model.set_meta("city_art_work_in_progress",38)
    model.set_meta("city_model_approved_final",false)
    return true
