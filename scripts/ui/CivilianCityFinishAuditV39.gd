extends RefCounted
class_name TarvokaCivilianCityFinishAuditV39

# V39 — corrective art audit. Real defects identified in V1 + V32:
# 1) original Cubierta uses the same metallic PBR for every city tier,
#    even under Villa's ceramic roof and Ciudad's stone parapet;
# 2) original foundations and a few deliberately grounded D4 fragments
#    sit slightly above BaseUrbana. Correct only those existing meshes.
# Never add geometry, restore damaged roofs, move roads or doors, alter
# faction colors, affect ownership, capture, income, collision or navigation.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V38=preload("res://scripts/ui/CivilianCityVolumeBalanceV38.gd")
const STAGE_NAME="CiudadCivilV39AuditoriaAcabadosReales"

const CLAY=Color("#b48368")
const STONE=Color("#bbb19f")
const STEEL=Color("#748891")

static func _parent_is_original_lot(mesh: MeshInstance3D) -> bool:
    var parent: Node=mesh.get_parent()
    return parent!=null and str(parent.name).begins_with("EdificioCivil_")

static func _ground_top(model: Node3D) -> float:
    # Read the actual upper face of V1's base, rather than assuming
    # a constant height if the baseline plot is ever adjusted.
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        if node is MeshInstance3D and str(node.name)=="BaseUrbana":
            var mesh: MeshInstance3D=node as MeshInstance3D
            var box_mesh: BoxMesh=mesh.mesh as BoxMesh
            if box_mesh!=null:
                return mesh.global_position.y+(
                    box_mesh.size.y*absf(mesh.global_transform.basis.get_scale().y))*0.5
        for child in node.get_children():
            pending.append(child)
    return NAN

static func _roof_substrate(mesh: MeshInstance3D,level: int) -> bool:
    var prior: StandardMaterial3D=mesh.material_override as StandardMaterial3D
    if prior==null:
        return false
    # Keep V38's thinner dimensions, base UVs/textures and tier-specific
    # roof silhouette. Modify ONLY this sub-roof material, never the
    # civic/faction color strips nor V15/V23/V30 upper sculpt.
    var finish: StandardMaterial3D=prior.duplicate() as StandardMaterial3D
    if finish==null:
        return false
    var target: Color=CLAY if level==1 else STONE if level==2 else STEEL
    finish.albedo_color=prior.albedo_color.lerp(
        target,0.24 if level==1 else 0.19 if level==2 else 0.12)
    finish.roughness=lerpf(
        prior.roughness,0.86 if level==1 else 0.84 if level==2 else 0.69,
        0.65)
    finish.metallic=lerpf(
        prior.metallic,0.04 if level==1 else 0.03 if level==2 else 0.43,
        0.72)
    mesh.material_override=finish
    mesh.set_meta("city_v39_subroof_finish",
        "ceramic" if level==1 else "stone" if level==2 else "steel")
    return true

static func _is_ground_contact(mesh: MeshInstance3D,
        damage: int) -> bool:
    var name: String=str(mesh.name)
    if name=="Cimiento" and damage<=2 and _parent_is_original_lot(mesh):
        return true
    if damage!=4:
        return false
    # ONLY decorative debris already meant to be seated on the terrain.
    # Do not disturb vertically broken walls, exposed D3 slabs, benches,
    # stairs, V11 jagged polygon mesh ruins or civic monuments.
    return (
        name.begins_with("V29_FragmentoCimientoAsentado_")
        or name.begins_with("V30_TejaVillaDerruida_")
        or name.begins_with("V30_BloqueCiudadDerruido_")
        or name.begins_with("V30_PerfilMetroCaido_")
        or name.begins_with("V28_EncuentroBajoRuina_"))

static func _seat_on_plot(mesh: MeshInstance3D,
        plot_top: float) -> bool:
    var box_mesh: BoxMesh=mesh.mesh as BoxMesh
    if box_mesh==null:
        return false
    # The authored V1 groups have identity transforms. Work in the
    # existing parent's coordinate space so no x/z movement occurs.
    var parent: Node3D=mesh.get_parent() as Node3D
    if parent==null or not is_equal_approx(parent.global_transform.basis.get_scale().y,1.0):
        return false
    var half_height: float=box_mesh.size.y*absf(mesh.scale.y)*0.5
    var desired_world_y: float=plot_top+half_height+0.002
    var parent_y: float=parent.global_position.y
    var previous_bottom: float=mesh.global_position.y-half_height
    var gap: float=previous_bottom-plot_top
    # Only correct clear, small gaps in the existing layout. Avoid moving
    # components already correctly grounded or unusually far from ground.
    if gap<=0.006 or gap>0.12:
        return false
    mesh.position.y=desired_world_y-parent_y
    mesh.set_meta("city_v39_ground_gap_before",gap)
    mesh.set_meta("city_v39_grounded",true)
    return true

static func _check_source(mesh: MeshInstance3D,
        damage: int) -> bool:
    return (not bool(mesh.get_meta("city_v22_superseded",false))
        and not bool(mesh.get_meta("v11_schematic_replaced",false))
        and not bool(mesh.get_meta("city_v39_grounded",false))
        and not (damage>=2 and str(mesh.name)=="Cubierta"))

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V38.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var plot_top: float=_ground_top(model)
    if is_nan(plot_top):
        return false
    var roofs: int=0
    var seated: int=0
    var audited: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if not _check_source(mesh,damage):
            continue
        if damage<=1 and str(mesh.name)=="Cubierta" and (
                _parent_is_original_lot(mesh)):
            audited+=1
            if _roof_substrate(mesh,level):
                roofs+=1
        elif _is_ground_contact(mesh,damage):
            audited+=1
            if _seat_on_plot(mesh,plot_top):
                seated+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",39)
    stage.set_meta("base_plot_surface_y",plot_top)
    stage.set_meta("design_focus",
        "correct-metal-roof-substrate-and-ground-floating-existing-parts")
    model.set_meta("city_v39_audited_contacts",audited)
    model.set_meta("city_v39_roof_materials_corrected",roofs)
    model.set_meta("city_v39_ground_gaps_corrected",seated)
    model.set_meta("city_art_work_in_progress",39)
    model.set_meta("city_model_approved_final",false)
    return true
