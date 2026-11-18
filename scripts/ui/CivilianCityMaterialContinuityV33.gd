extends RefCounted
class_name TarvokaCivilianCityMaterialContinuityV33

# V33 — restore coherent physical materials at architectural junctions.
# Refinishes existing V23-V32 meshes, never creating render geometry.
# Keep V1 urban footprints, V10 doors, glazing, faction strips,
# V11 damage geometry, V19 paths, clock and civic markers unchanged.
# Preserve each source albedo texture, UV scale, normal settings and
# weathering; only gently tune material color/roughness/metalness.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V32=preload("res://scripts/ui/CivilianCitySurfaceReviewV32.gd")
const STAGE_NAME="CiudadCivilV33ContinuidadDeMateriales"

const CERAMIC=Color("#b07b5e")
const OLD_TIMBER=Color("#816d5a")
const MASONRY=Color("#bcae98")
const BRICK=Color("#ab826c")
const METAL=Color("#718791")
const EXPOSED=Color("#8c8073")
const ASH=Color("#6e6962")

static func _architectural_target(name: String,
        damage: int) -> bool:
    var prefixes: Array[String]=[]
    if damage<=1:
        prefixes=[
            "V23_VillaRematePerfil_","V23_CiudadPerfilEscalonado_",
            "V23_MetroPerfilCorona_","V24_CierreCornisa_",
            "V25_JuntaCeramica_","V25_JuntaMortero_",
            "V25_SoldaduraMetal_","V28_RemateEsquinaSuperior_",
            "V28_ZocaloNorteSur_","V29_CosturaCubiertaFachada_",
            "V29_NucleoAlfeizar_"
        ]
    elif damage==2:
        prefixes=[
            "V23_BordeTejadoPartido_","V24_FracturaApoyada_",
            "V25_SeccionTejaPartida_","V25_CantoForjadoVisible_",
            "V28_RetornoCantoRoto_",
            "V29_TerminacionCubiertaPartida_",
            "V29_JuntaFracturaInferior_",
            "V30_AlfardaVillaExpuesta_",
            "V30_SillarCornisaCiudadRoto_",
            "V30_NervioCoronaMetroTorsionado_"
        ]
    elif damage==3:
        prefixes=[
            "V23_RetornoCascaron_","V24_FiloForjadoInterrumpido_",
            "V25_CantoForjadoVisible_","V28_EncuentroBajoRuina_",
            "V29_CantoInteriorExpuesto_",
            "V30_EntramadoVillaInterior_",
            "V30_DintelLadrilloInterior_",
            "V30_SeccionVigaMetalInterior_"
        ]
    else:
        prefixes=[
            "V23_CrestaRuinaBaja_","V24_ZapataCortada_",
            "V25_AnclajeCimientoDestruido_",
            "V28_EncuentroBajoRuina_",
            "V29_FragmentoCimientoAsentado_",
            "V30_TejaVillaDerruida_",
            "V30_BloqueCiudadDerruido_",
            "V30_PerfilMetroCaido_"
        ]
    for prefix in prefixes:
        if name.begins_with(prefix):
            return true
    return false

static func _material_family(name: String,level: int) -> String:
    # Select only intrinsic construction material, not visual faction
    # emblems, windows, asphalt, doors or glass.
    if (name.contains("Madera") or name.contains("Alfarda")
            or name.contains("EntramadoVilla")
            or name.contains("NucleoAlfeizar") and level==1):
        return "timber"
    if (name.contains("Teja") or name.contains("Ceramica")
            or name.contains("VillaRemate")
            or name.contains("TejaVilla")):
        return "ceramic"
    if (name.contains("Soldadura") or name.contains("Metro")
            or name.contains("Acero") or name.contains("Metal")):
        return "steel"
    if (name.contains("Ladrillo") or name.contains("Sillar")
            or name.contains("Mamposteria")):
        return "brick"
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _color(family: String,damage: int) -> Color:
    var color: Color=CERAMIC
    if family=="timber":
        color=OLD_TIMBER
    elif family=="stone":
        color=MASONRY
    elif family=="brick":
        color=BRICK
    elif family=="steel":
        color=METAL
    if damage>=2:
        color=color.lerp(
            ASH if damage==4 else EXPOSED,
            0.16 if damage==2 else 0.24 if damage==3 else 0.32)
    return color

static func _roughness(family: String,damage: int) -> float:
    var base: float=0.77
    if family=="timber":
        base=0.87
    elif family=="stone":
        base=0.82
    elif family=="brick":
        base=0.83
    elif family=="steel":
        base=0.60
    return clampf(base+0.025*float(damage),0.45,0.96)

static func _harmonize(mesh: MeshInstance3D,
        level: int,damage: int) -> bool:
    var existing: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if existing==null:
        return false
    var family: String=_material_family(str(mesh.name),level)
    # Duplicate prevents changing shared weathering caches or other
    # buildings which reference the old StandardMaterial3D.
    var finish: StandardMaterial3D=existing.duplicate() as StandardMaterial3D
    if finish==null:
        return false
    finish.albedo_color=existing.albedo_color.lerp(
        _color(family,damage),0.055 if damage<=1 else 0.085)
    finish.roughness=lerpf(
        existing.roughness,_roughness(family,damage),0.35)
    if family=="steel":
        finish.metallic=lerpf(existing.metallic,
            0.51 if damage<2 else 0.31,0.27)
    # Ceramic / mortar / timber / brick are not given fake metallic gloss.
    # Albedo texture is deliberately inherited rather than recreated.
    mesh.material_override=finish
    mesh.set_meta("city_v33_material_family",family)
    mesh.set_meta("city_v33_material_harmonized",true)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V32.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var harmonized: int=0
    var ceramics: int=0
    var masonry: int=0
    var metals: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if (bool(mesh.get_meta("city_v22_superseded",false))
                or bool(mesh.get_meta("v11_schematic_replaced",false))
                or not _architectural_target(str(mesh.name),damage)):
            continue
        if not _harmonize(mesh,level,damage):
            continue
        harmonized+=1
        var family: String=str(mesh.get_meta("city_v33_material_family",""))
        if family=="ceramic" or family=="timber":
            ceramics+=1
        elif family=="steel":
            metals+=1
        else:
            masonry+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",33)
    stage.set_meta("design_focus",
        "material-continuity-roughness-no-duplicate-roofs-or-faction-repaint")
    stage.set_meta("materials_refinished",harmonized)
    model.set_meta("city_v33_materials_refinished",harmonized)
    model.set_meta("city_v33_ceramic_timber",ceramics)
    model.set_meta("city_v33_stone_brick",masonry)
    model.set_meta("city_v33_steel",metals)
    model.set_meta("city_art_work_in_progress",33)
    model.set_meta("city_model_approved_final",false)
    return true
