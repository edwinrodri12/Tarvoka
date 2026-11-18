extends RefCounted
class_name TarvokaCivilianCitySurfaceReviewV32

# TARVOKA civilian city V32 — art-only last-mile cleanup of existing meshes.
# Keep V1 plot geometry, V10 entrances, V19 walkways, facade windows,
# civic identity/faction colors and V11 torn polygon walls authoritative.
# No new visible meshes, no gameplay, collisions, ownership or income.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const V31=preload("res://scripts/ui/CivilianCityTacticalReadabilityV31.gd")
const STAGE_NAME="CiudadCivilV32PulidoCubiertasFachadasRuinas"

const VILLA=Color("#a77960")
const TOWN=Color("#bbae99")
const METRO=Color("#728892")
const DUST=Color("#81766b")
const ASH=Color("#595654")

static func _finish(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _identity_tint(level: int,damage: int) -> Color:
    var tint: Color=VILLA if level==1 else TOWN if level==2 else METRO
    return tint.lerp(DUST,0.04 if damage==0 else
        0.10 if damage==1 else 0.24 if damage==2 else
        0.41 if damage==3 else 0.56)

static func _surface_target(name: String,damage: int) -> bool:
    if damage<=1:
        return (
            name.begins_with("V29_CosturaCubiertaFachada_")
            or name.begins_with("V29_NucleoAlfeizar_")
            or name.begins_with("V28_RemateEsquinaSuperior_")
            or name.begins_with("V28_ZocaloNorteSur_")
            or name.begins_with("V25_JuntaCeramica_")
            or name.begins_with("V25_JuntaMortero_")
            or name.begins_with("V25_SoldaduraMetal_"))
    if damage==2:
        return (
            name.begins_with("V29_TerminacionCubiertaPartida_")
            or name.begins_with("V29_JuntaFracturaInferior_")
            or name.begins_with("V30_AlfardaVillaExpuesta_")
            or name.begins_with("V30_SillarCornisaCiudadRoto_")
            or name.begins_with("V30_NervioCoronaMetroTorsionado_")
            or name.begins_with("V28_RetornoCantoRoto_"))
    if damage==3:
        return (
            name.begins_with("V29_CantoInteriorExpuesto_")
            or name.begins_with("V30_EntramadoVillaInterior_")
            or name.begins_with("V30_DintelLadrilloInterior_")
            or name.begins_with("V30_SeccionVigaMetalInterior_")
            or name.begins_with("V28_EncuentroBajoRuina_"))
    return (
        name.begins_with("V29_FragmentoCimientoAsentado_")
        or name.begins_with("V30_TejaVillaDerruida_")
        or name.begins_with("V30_BloqueCiudadDerruido_")
        or name.begins_with("V30_PerfilMetroCaido_")
        or name.begins_with("V28_EncuentroBajoRuina_"))

static func _adjust_geometry(mesh: MeshInstance3D,
        name: String,damage: int) -> bool:
    # Absolute fine adjustments. Keep the V30/V31 massing untouched.
    if damage<=1:
        if name.begins_with("V29_CosturaCubiertaFachada_"):
            mesh.scale.x=0.89
            mesh.scale.y=0.90
        elif name.begins_with("V29_NucleoAlfeizar_"):
            mesh.scale.x=0.88
            mesh.scale.z=0.90
        elif name.begins_with("V28_RemateEsquinaSuperior_"):
            mesh.scale.x=0.86
            mesh.scale.z=0.87
        elif name.begins_with("V28_ZocaloNorteSur_"):
            mesh.scale.x=0.93
            mesh.scale.y=0.83
        elif name.begins_with("V25_JuntaCeramica_"):
            mesh.scale.y=0.87
        elif name.begins_with("V25_JuntaMortero_"):
            mesh.scale.y=0.91
        elif name.begins_with("V25_SoldaduraMetal_"):
            mesh.scale.y=0.88
    elif damage==2:
        if name.begins_with("V29_TerminacionCubiertaPartida_"):
            mesh.scale.x=0.92
            mesh.scale.z=0.93
        elif name.begins_with("V29_JuntaFracturaInferior_"):
            mesh.scale.x=0.91
        elif name.begins_with("V28_RetornoCantoRoto_"):
            mesh.scale.y=0.91
        else:
            mesh.scale.x=0.95
    elif damage==3:
        if name.begins_with("V29_CantoInteriorExpuesto_"):
            # Keep fragment joined to the surviving low V23 slab,
            # rather than a slightly floating little platform.
            mesh.position.y=0.69
            mesh.scale.y=0.92
        elif name.begins_with("V28_EncuentroBajoRuina_"):
            mesh.position.y=0.18
            mesh.scale.y=0.93
        else:
            mesh.scale.x=0.92
    else:
        # These are loose decorative debris above the plot ground,
        # not collision meshes. Lower them to visibly rest on the base
        # without moving original V1 street/foundation geometry.
        if name.begins_with("V29_FragmentoCimientoAsentado_"):
            mesh.position.y=0.066
            mesh.scale.y=0.95
        elif name.begins_with("V28_EncuentroBajoRuina_"):
            mesh.position.y=0.061
        else:
            mesh.position.y=0.071
            mesh.scale.y=0.96
    mesh.set_meta("city_v32_geometry_refinished",true)
    return true

static func _new_far_cap(name: String,damage: int) -> int:
    # Additional cap on top of V31. Fine details stay in close-up and
    # the core roof/civic forms are kept in tactical/far LOD.
    if damage<=1:
        if (name.begins_with("V28_EnlaceEsquinaLateral_")
                and name.ends_with("_1_1")):
            return 1
        if (name.begins_with("V28_RemateEsquinaSuperior_")
                and name.ends_with("_-1_1")):
            return 1
    elif damage==2:
        if (name.begins_with("V28_RetornoCantoRoto_")
                and name.ends_with("_1_-1")):
            return 1
    elif damage==3:
        if (name.begins_with("V28_EncuentroBajoRuina_")
                and name.ends_with("_1")):
            return 1
    else:
        if (name.begins_with("V30_TejaVillaDerruida_")
                or name.begins_with("V30_BloqueCiudadDerruido_")
                or name.begins_with("V30_PerfilMetroCaido_")):
            return 1
    return 2

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V31.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var refined: int=0
    var grounded: int=0
    var curated: int=0
    var nodes: Array[Node]=[model]
    while not nodes.is_empty():
        var node: Node=nodes.pop_back()
        for child in node.get_children():
            nodes.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if (bool(mesh.get_meta("city_v22_superseded",false))
                or bool(mesh.get_meta("v11_schematic_replaced",false))):
            continue
        var n: String=str(mesh.name)
        if _surface_target(n,damage):
            _adjust_geometry(mesh,n,damage)
            var prev: StandardMaterial3D=mesh.material_override as StandardMaterial3D
            if prev!=null:
                # A small tier-specific tint unifies joints without
                # overwriting the original faction accent markings.
                var color: Color=prev.albedo_color.lerp(
                    _identity_tint(level,damage),0.075 if damage<2 else 0.13)
                mesh.material_override=V26._material(
                    level,damage,posmod(n.hash(),5),color,_finish(level))
            refined+=1
            if damage>=3 and (
                    n.begins_with("V29_FragmentoCimientoAsentado_")
                    or n.begins_with("V30_TejaVillaDerruida_")
                    or n.begins_with("V30_BloqueCiudadDerruido_")
                    or n.begins_with("V30_PerfilMetroCaido_")
                    or n.begins_with("V28_EncuentroBajoRuina_")):
                grounded+=1
        var max_lod: int=_new_far_cap(n,damage)
        if max_lod<2:
            mesh.set_meta("city_v32_max_lod",max_lod)
            curated+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",32)
    stage.set_meta("design_focus",
        "roof-facade-junctions-and-grounded-ruins-existing-meshes")
    model.set_meta("city_v32_refinished_pieces",refined)
    model.set_meta("city_v32_grounded_fragments",grounded)
    model.set_meta("city_v32_far_lod_curated",curated)
    model.set_meta("city_art_work_in_progress",32)
    model.set_meta("city_model_approved_final",false)
    return true
