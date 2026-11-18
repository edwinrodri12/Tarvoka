extends RefCounted
class_name TarvokaCivilianCityArtReviewV42

# V42 — non-destructive ART readiness inspection for real Godot meshes.
# Records actual geometry checks instead of declaring visual approval.
# D0/D1: original wall-to-roof seating and tier-specific V41 roof joints.
# D2: broken polygon silhouette retained. D3/D4: old schematic solid
# proxies must be marked superseded by V11, leaving true broken geometry.
# This stage never changes transforms/materials or gameplay; a separate
# Godot viewport capture is needed before granting artistic approval.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V41=preload("res://scripts/ui/CivilianCityRoofJoinV41.gd")
const STAGE_NAME="CiudadCivilV42RevisionVisualPendiente"

static func _root_geometry(model: Node3D,damage: int,
        findings: PackedStringArray) -> Dictionary:
    var out: Dictionary={
        "buildings":0,"open_roofs":0,"broken_faces":0,
        "old_proxies":0,"roof_contacts":0,"roof_gaps":0,
        "intact_roofs_in_ruins":0
    }
    var nodes: Array[Node]=[model]
    while not nodes.is_empty():
        var n: Node=nodes.pop_back()
        for child in n.get_children():
            nodes.append(child)
        if not (n is MeshInstance3D):
            continue
        var m: MeshInstance3D=n as MeshInstance3D
        var key: String=str(m.name)
        var old_proxy: bool=bool(m.get_meta(
            "v11_schematic_replaced",false))
        if old_proxy:
            out["old_proxies"]=int(out["old_proxies"])+1
        if key.begins_with("V23_BordeTejadoPartido_"):
            out["open_roofs"]=int(out["open_roofs"])+1
        if (key.begins_with("FachadaNorteQuebradaV11_")
                or key.begins_with("FachadaSurQuebradaV11_")
                or key.begins_with("V23_RetornoCascaron_")
                or key.begins_with("V23_CrestaRuinaBaja_")):
            out["broken_faces"]=int(out["broken_faces"])+1
        if not key.begins_with("EdificioCivil_"):
            if damage>=2 and key=="Cubierta" and not old_proxy:
                out["intact_roofs_in_ruins"]=int(out["intact_roofs_in_ruins"])+1
            continue
        var building: Node3D=n as Node3D
        if building==null:
            continue
    # Named lot groups are Node3D, not MeshInstance3D.
    var lots: Array[Node]=[model]
    while not lots.is_empty():
        var group: Node=lots.pop_back()
        for child in group.get_children():
            lots.append(child)
        if not (group is Node3D) or not str(group.name).begins_with(
                "EdificioCivil_"):
            continue
        out["buildings"]=int(out["buildings"])+1
        if damage>1:
            continue
        var lot: Node3D=group as Node3D
        var roof: MeshInstance3D=lot.get_node_or_null(
            "Cubierta") as MeshInstance3D
        var wall: MeshInstance3D=lot.get_node_or_null(
            "VolumenMamposteria") as MeshInstance3D
        if roof==null or wall==null:
            findings.append("Falta cubierta o volumen en "+str(lot.name))
            continue
        var roof_shape: BoxMesh=roof.mesh as BoxMesh
        var wall_shape: BoxMesh=wall.mesh as BoxMesh
        if roof_shape==null or wall_shape==null:
            findings.append("Malla basica inesperada en "+str(lot.name))
            continue
        out["roof_contacts"]=int(out["roof_contacts"])+1
        var roof_bottom: float=roof.position.y-(
            roof_shape.size.y*absf(roof.scale.y))*0.5
        var wall_top: float=wall.position.y+(
            wall_shape.size.y*absf(wall.scale.y))*0.5
        if roof_bottom-wall_top>0.008:
            out["roof_gaps"]=int(out["roof_gaps"])+1
            findings.append("Junta cubierta-muro abierta en "+str(lot.name))
    return out

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V41.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var findings:=PackedStringArray()
    var stats: Dictionary=_root_geometry(model,damage,findings)
    if int(stats["buildings"])<5:
        findings.append("Numero de edificios civiles inferior al esperado")
    if damage==2 and int(stats["open_roofs"])==0:
        findings.append("Sin bordes de cubierta quebrada D2")
    if damage>=3 and int(stats["broken_faces"])==0:
        findings.append("Sin silueta quebrada D3/D4")
    if damage>=2 and int(stats["intact_roofs_in_ruins"])>0:
        findings.append("Cubierta antigua visible en ruinas")
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("design_stage",42)
    stage.set_meta("awaiting_render_review",true)
    model.set_meta("city_v42_geometry_checks",stats)
    model.set_meta("city_v42_visual_warnings",findings)
    model.set_meta("city_v42_warning_count",findings.size())
    model.set_meta("city_v42_render_approved",false)
    model.set_meta("city_art_work_in_progress",42)
    model.set_meta("city_model_approved_final",false)
    return true
