extends RefCounted
class_name TarvokaCivilianCityRoofJoinV41

# V41 — measured 3D art joins, not unverified final approval.
# Uses the ORIGINAL V15 BoxMesh widths/positions in existing roof
# signature groups to repair three concrete fit issues:
# Villa: ridge tiles separated by their own center-to-center spacing.
# Ciudad: the stone parapet cap narrower than the brick band below.
# Metropolis: top civic accent protruding above the steel crown.
# Only current MeshInstance3D transforms are updated; no new meshes,
# changed faction hues, footprints, heights, hitboxes or gameplay data.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V40=preload("res://scripts/ui/CivilianCityFinalFitV40.gd")
const STAGE_NAME="CiudadCivilV41EncuentrosArquitectonicosMedidos"

static func _find_box(parent: Node3D,name: String) -> MeshInstance3D:
    var child: MeshInstance3D=parent.get_node_or_null(name) as MeshInstance3D
    if child==null or not (child.mesh is BoxMesh):
        return null
    if (bool(child.get_meta("city_v22_superseded",false))
            or bool(child.get_meta("v11_schematic_replaced",false))):
        return null
    return child

static func _villa_ridge(parent: Node3D) -> int:
    var tiles: Array[MeshInstance3D]=[]
    for node in parent.get_children():
        if not (node is MeshInstance3D):
            continue
        var mesh: MeshInstance3D=node as MeshInstance3D
        if str(mesh.name).begins_with("TejaCaballeraV15_"):
            var box_mesh: BoxMesh=mesh.mesh as BoxMesh
            if box_mesh!=null and box_mesh.size.z>0.01:
                tiles.append(mesh)
    if tiles.size()<2:
        return 0
    var corrected: int=0
    for tile in tiles:
        var nearest: float=INF
        for other in tiles:
            if other==tile:
                continue
            var spacing: float=absf(tile.position.z-other.position.z)
            if spacing>0.001:
                nearest=minf(nearest,spacing)
        if nearest==INF:
            continue
        var body: BoxMesh=tile.mesh as BoxMesh
        var old_width: float=body.size.z*absf(tile.scale.z)
        # The target overlaps the next tile by just 5 mm. Leave the
        # ceramic texture and all pitched V2 roof geometry unchanged.
        var new_scale: float=(nearest+0.005)/body.size.z
        if new_scale>tile.scale.z+0.008 and new_scale<=1.30:
            tile.scale.z=new_scale
            tile.set_meta("city_v41_ridge_gap_closed",
                maxf(0.0,nearest-old_width))
            corrected+=1
    return corrected

static func _town_parapet(parent: Node3D) -> int:
    var corrected: int=0
    for node in parent.get_children():
        if not (node is MeshInstance3D):
            continue
        var cap: MeshInstance3D=node as MeshInstance3D
        var n: String=str(cap.name)
        if not n.begins_with("BandaParapetoPiedraV15_"):
            continue
        var lower_name: String=n.replace(
            "BandaParapetoPiedraV15_","BandaLadrilloRemateV15_")
        var lower: MeshInstance3D=_find_box(parent,lower_name)
        var cap_box: BoxMesh=cap.mesh as BoxMesh
        if lower==null or cap_box==null or cap_box.size.x<=0.01:
            continue
        var lower_box: BoxMesh=lower.mesh as BoxMesh
        var lower_width: float=lower_box.size.x*absf(lower.scale.x)
        var top_width: float=cap_box.size.x*absf(cap.scale.x)
        # Traditional cornice hierarchy: 12 mm larger than its
        # underlying brick band, never a floating/oversized cornice.
        var required: float=lower_width+0.012
        var proposed: float=required/cap_box.size.x
        if top_width+0.002<required and proposed<=1.10:
            cap.scale.x=proposed
            cap.set_meta("city_v41_parapet_cap_overhang_m",
                required-lower_width)
            corrected+=1
    return corrected

static func _metro_crown(parent: Node3D) -> int:
    var corrected: int=0
    for node in parent.get_children():
        if not (node is MeshInstance3D):
            continue
        var accent: MeshInstance3D=node as MeshInstance3D
        var n: String=str(accent.name)
        if not n.begins_with("LuzFranjaCivicaMetroV15_"):
            continue
        var crown_name: String=n.replace(
            "LuzFranjaCivicaMetroV15_",
            "CoronaEscalonadaMetroV15_")
        var crown: MeshInstance3D=_find_box(parent,crown_name)
        var accent_box: BoxMesh=accent.mesh as BoxMesh
        if crown==null or accent_box==null:
            continue
        var crown_box: BoxMesh=crown.mesh as BoxMesh
        var crown_top: float=crown.position.y+(
            crown_box.size.y*absf(crown.scale.y))*0.5
        var accent_top: float=accent.position.y+(
            accent_box.size.y*absf(accent.scale.y))*0.5
        # The decorative light stays near the crown top but never
        # protrudes above its metal cap in the tactical silhouette.
        var desired_top: float=crown_top-0.006
        if accent_top>desired_top+0.002 and (
                accent_top-desired_top)<0.08:
            accent.position.y-=accent_top-desired_top
            accent.set_meta("city_v41_crown_light_seated",true)
            corrected+=1
    return corrected

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V40.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var ridge: int=0
    var parapet: int=0
    var crown: int=0
    # D2-D4 must NOT have any intact roof trim resurrected.
    if damage<=1:
        var nodes: Array[Node]=[model]
        while not nodes.is_empty():
            var node: Node=nodes.pop_back()
            for child in node.get_children():
                nodes.append(child)
            if not (node is Node3D):
                continue
            var group: Node3D=node as Node3D
            var name: String=str(group.name)
            if level==1 and name.begins_with("VillaTradicionalV15_"):
                ridge+=_villa_ridge(group)
            elif level==2 and name.begins_with(
                    "CiudadCompactaMamposteriaV15_"):
                parapet+=_town_parapet(group)
            elif level==3 and name.begins_with(
                    "MetropoliVidrioYAceroV15_"):
                crown+=_metro_crown(group)
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",41)
    stage.set_meta("design_focus",
        "villa-ceramic-ridge-town-stone-cap-metropolis-steel-crown")
    model.set_meta("city_v41_villa_ridge_joins",ridge)
    model.set_meta("city_v41_town_parapet_joins",parapet)
    model.set_meta("city_v41_metropolis_crown_joins",crown)
    model.set_meta("city_art_work_in_progress",41)
    model.set_meta("city_model_approved_final",false)
    return true
