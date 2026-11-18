extends RefCounted
class_name TarvokaCivilianCityFinalFitV40

# TARVOKA civilian districts V40 — final ART fit, not final approval.
# Concrete V38->V39 problem: reducing the old rectangular Cubierta's
# thickness without lowering its center leaves a narrow air gap above
# VolumenMamposteria. Fix only the existing roof-to-wall contact.
# Villa/City/Metropolis visual identity, original wall height, lot size,
# V2/V14 sloped roofs, V11 broken silhouettes, windows, portals, roads,
# faction insignia and all gameplay parameters stay unchanged.
# No new meshes, panels, decorative props, physics or collisions.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V39=preload("res://scripts/ui/CivilianCityFinishAuditV39.gd")
const STAGE_NAME="CiudadCivilV40RevisionEncuentrosFinales"

static func _original_lot(node: Node) -> bool:
    return node!=null and str(node.name).begins_with("EdificioCivil_")

static func _roof_wall_gap(mesh: MeshInstance3D) -> float:
    var lot: Node3D=mesh.get_parent() as Node3D
    if not _original_lot(lot):
        return NAN
    var wall: MeshInstance3D=lot.get_node_or_null(
        "VolumenMamposteria") as MeshInstance3D
    if wall==null or bool(wall.get_meta(
            "v11_schematic_replaced",false)):
        return NAN
    var wall_box: BoxMesh=wall.mesh as BoxMesh
    var roof_box: BoxMesh=mesh.mesh as BoxMesh
    if wall_box==null or roof_box==null:
        return NAN
    var wall_top: float=wall.position.y+(
        wall_box.size.y*absf(wall.scale.y))*0.5
    var roof_bottom: float=mesh.position.y-(
        roof_box.size.y*absf(mesh.scale.y))*0.5
    return roof_bottom-wall_top

static func _seat_existing_roof(mesh: MeshInstance3D) -> bool:
    var gap: float=_roof_wall_gap(mesh)
    if is_nan(gap) or gap<=0.004 or gap>=0.13:
        return false
    # 8mm overlap avoids light leaking through the seam without
    # changing any architectural elevation or roofing geometry.
    # V38 had narrowed only the BoxMesh's scale, not its center height.
    mesh.position.y-=gap+0.008
    mesh.set_meta("city_v40_previously_floating_roof_gap",gap)
    mesh.set_meta("city_v40_roof_wall_seated",true)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V39.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var roofs_audited: int=0
    var roofs_seated: int=0
    var remaining_visible_gaps: int=0
    var maximum_gap: float=0.0
    var stack: Array[Node]=[model]
    while not stack.is_empty():
        var node: Node=stack.pop_back()
        for child in node.get_children():
            stack.append(child)
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if (damage>1 or str(mesh.name)!="Cubierta"
                or not _original_lot(mesh.get_parent())
                or bool(mesh.get_meta("v11_schematic_replaced",false))
                or bool(mesh.get_meta("city_v22_superseded",false))):
            continue
        var original_gap: float=_roof_wall_gap(mesh)
        if is_nan(original_gap):
            continue
        roofs_audited+=1
        maximum_gap=maxf(maximum_gap,maxf(0.0,original_gap))
        if _seat_existing_roof(mesh):
            roofs_seated+=1
        var after_gap: float=_roof_wall_gap(mesh)
        if not is_nan(after_gap) and after_gap>0.006:
            remaining_visible_gaps+=1
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",40)
    stage.set_meta("design_focus",
        "original-roof-to-wall-fit-after-V38-thickness-and-V39-PBR")
    model.set_meta("city_v40_roofs_audited",roofs_audited)
    model.set_meta("city_v40_roofs_seated",roofs_seated)
    model.set_meta("city_v40_unresolved_roof_gaps",remaining_visible_gaps)
    model.set_meta("city_v40_prior_max_roof_gap",maximum_gap)
    model.set_meta("city_art_work_in_progress",40)
    # Visual sign-off must follow an actual Godot render and human review.
    model.set_meta("city_model_approved_final",false)
    return true
