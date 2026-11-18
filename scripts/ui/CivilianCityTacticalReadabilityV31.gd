extends RefCounted
class_name TarvokaCivilianCityTacticalReadabilityV31

# TARVOKA CITY V31 — art hierarchy and tier readability at tactical zoom.
# All changes modify EXISTING native Godot city meshes from V1 through V30.
# Keep the five damage stages, original lot massing, skyline heights,
# civilian colors, original roads, entrances and gameplay unchanged.
# No extra roofs, buildings, collisions, lights, textures or mesh instances.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const V30=preload("res://scripts/ui/CivilianCityTierProportionsV30.gd")
const STAGE_NAME="CiudadCivilV31LecturaTacticaDeTresNiveles"

const CLAY=Color("#b17a5b")
const TIMBER=Color("#806e5b")
const STONE=Color("#c6b9a3")
const BRICK=Color("#a67b67")
const METAL=Color("#738993")
const STEEL=Color("#576e79")
const DUST=Color("#857a6c")

static func _base_color(level: int,damage: int) -> Color:
    var base: Color=CLAY if level==1 else STONE if level==2 else METAL
    return base.lerp(DUST,0.04 if damage==0 else
        0.11 if damage==1 else 0.29 if damage==2 else
        0.41 if damage==3 else 0.52)

static func _surface(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _is_detail_target(name: String,
        level: int,damage: int) -> bool:
    # Reshape only geometry from the already-modeled tier signatures.
    # Do not touch V1 walls/windows, V10 access, V19 sidewalks or any
    # named faction trim. V30 remains authoritative for proportions.
    if damage<=1:
        if level==1:
            return (name.begins_with("TejaCaballeraV15_")
                or name.begins_with("AleroMaderaVillaV15_")
                or name.begins_with("V23_VillaRematePerfil_"))
        if level==2:
            return (name.begins_with("BandaParapetoPiedraV15_")
                or name.begins_with("BandaLadrilloRemateV15_")
                or name.begins_with("V23_CiudadPerfilEscalonado_"))
        return (name.begins_with("CoronaEscalonadaMetroV15_")
            or name.begins_with("V23_MetroPerfilCorona_")
            or name.begins_with("AletaCoronaMetropoliV4_"))
    if damage==2:
        return (
            (level==1 and name.begins_with(
                "TejaSueltaFracturadaVillaV15_"))
            or (level==2 and name.begins_with(
                "CornisaDesgajadaCiudadV15_"))
            or (level==3 and name.begins_with(
                "PerfilCoronaMetropoliRotoV15_")))
    return (
        (level==1 and name.begins_with("VigaVernacularCaidaV15_"))
        or (level==2 and name.begins_with(
            "PilastraMamposteriaTruncadaV15_"))
        or (level==3 and name.begins_with("PilarMetropoliAbiertoV15_")))

static func _reshape_piece(mesh: MeshInstance3D,
        name: String,level: int,damage: int) -> void:
    # Absolute, restrained edits — no cumulative scale drift
    # when changing tier or damage in the actual viewer.
    if damage<=1:
        if level==1:
            if name.begins_with("TejaCaballeraV15_"):
                mesh.scale.x=0.84
                mesh.scale.y=1.08
            elif name.begins_with("AleroMaderaVillaV15_"):
                mesh.scale.y=0.93
                mesh.scale.z=0.96
            elif name.begins_with("V23_VillaRematePerfil_"):
                mesh.scale.x=0.94
                mesh.scale.y=0.90
        elif level==2:
            if name.begins_with("BandaParapetoPiedraV15_"):
                mesh.scale.x=0.96
                mesh.scale.y=0.87
                mesh.scale.z=1.03
            elif name.begins_with("BandaLadrilloRemateV15_"):
                mesh.scale.y=0.97
            elif name.begins_with("V23_CiudadPerfilEscalonado_"):
                mesh.scale.x=0.89
                mesh.scale.y=0.92
        else:
            if name.begins_with("CoronaEscalonadaMetroV15_"):
                mesh.scale.x=0.87
                mesh.scale.y=1.12
            elif name.begins_with("V23_MetroPerfilCorona_"):
                mesh.scale.x=0.79
                mesh.scale.y=1.16
            elif name.begins_with("AletaCoronaMetropoliV4_"):
                mesh.scale.x=0.88
    elif damage==2:
        if level==1:
            mesh.scale.x=0.89
        elif level==2:
            mesh.scale.x=0.86
        else:
            mesh.scale.x=0.88
    else:
        # D3/D4 remain broken and grounded. Slightly reduce bulky
        # fragments; never restore an intact wall or roof.
        mesh.scale.x=0.89 if level==2 else mesh.scale.x
        mesh.scale.y=0.90 if level==1 else mesh.scale.y
    var prior: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if prior!=null:
        var base_color: Color=_base_color(level,damage)
        var tint: Color=prior.albedo_color.lerp(
            base_color,0.10 if damage<=1 else 0.19)
        mesh.material_override=V26._material(
            level,damage,posmod(name.hash(),5),tint,_surface(level))
    mesh.set_meta("city_v31_tactical_rebalanced",true)

static func _far_detail_limit(name: String,
        level: int,damage: int) -> int:
    # 0=close only, 1=close+medium, 2=all existing LODs. The
    # existing LOD rules still apply; this adds a selective upper bound.
    # Never suppress the unique faction accent or a whole roof,
    # civic hall, sidewalk, door, window or foundation.
    if damage<=1:
        # V15 primary skyline stays. Only one of the four extra V23
        # crown studs per lot is removed from far zoom.
        if level==1 and name.begins_with("V23_VillaRematePerfil_"):
            return 1 if name.ends_with("_1_1") else 2
        if level==2 and name.begins_with(
                "V23_CiudadPerfilEscalonado_"):
            return 1 if name.ends_with("_1_1") else 2
        if level==3 and name.begins_with("V23_MetroPerfilCorona_"):
            return 1 if name.ends_with("_1_1") else 2
        # Each side still retains three V28 corner contacts, while
        # the close viewer can inspect the full set.
        if name.begins_with("V28_RemateEsquinaSuperior_"):
            return 1 if name.ends_with("_1_1") else 2
    if damage==2:
        # One broken-rim return stays visible with the V30 tier sign,
        # instead of two identical bright accents at LOD2.
        if name.begins_with("V29_TerminacionCubiertaPartida_"):
            return 1 if name.ends_with("_1") else 2
    elif damage==3:
        if name.begins_with("V23_ForjadoArrancado_"):
            return 1 if name.ends_with("_1") else 2
    elif damage==4:
        if name.begins_with("V29_FragmentoCimientoAsentado_"):
            return 1 if name.ends_with("_1") else 2
    return 2

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V30.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var retuned: int=0
    var curated: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var current: Node=pending.pop_back()
        for child in current.get_children():
            pending.append(child)
        if not (current is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=current as MeshInstance3D
        if bool(mesh.get_meta("city_v22_superseded",false)):
            continue
        var mesh_name: String=str(mesh.name)
        if _is_detail_target(mesh_name,level,damage):
            _reshape_piece(mesh,mesh_name,level,damage)
            retuned+=1
        var max_lod: int=_far_detail_limit(mesh_name,level,damage)
        if max_lod<2:
            mesh.set_meta("city_v31_max_lod",max_lod)
            curated+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",31)
    stage.set_meta("design_focus",
        "tactical-tier-readability-without-extra-geometry")
    stage.set_meta("retuned_existing_pieces",retuned)
    stage.set_meta("far_lod_deemphasized_pieces",curated)
    model.set_meta("city_v31_rebalanced_pieces",retuned)
    model.set_meta("city_v31_far_lod_curated",curated)
    model.set_meta("city_art_work_in_progress",31)
    model.set_meta("city_model_approved_final",false)
    return true
