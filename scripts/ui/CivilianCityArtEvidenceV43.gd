extends RefCounted
class_name TarvokaCivilianCityArtEvidenceV43

# V43: measured, non-destructive artistic review of actual Godot 4.3
# geometry/materials. No extra meshes, no cosmetics without screenshots,
# no automatic sign-off. Run AFTER V42, before applying the existing LOD.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V42=preload("res://scripts/ui/CivilianCityArtReviewV42.gd")
const STAGE_NAME="CiudadCivilV43ComprobacionEvidenciasArtisticas"

static func _box(parent: Node3D,name: String) -> MeshInstance3D:
    var child: MeshInstance3D=parent.get_node_or_null(name) as MeshInstance3D
    if child==null or not (child.mesh is BoxMesh):
        return null
    return child

static func _width_x(part: MeshInstance3D) -> float:
    var b: BoxMesh=part.mesh as BoxMesh
    return b.size.x*absf(part.scale.x) if b!=null else 0.0

static func _top_y(part: MeshInstance3D) -> float:
    var b: BoxMesh=part.mesh as BoxMesh
    return part.position.y+b.size.y*absf(part.scale.y)*0.5 if b!=null else -INF

static func _scan_roof_families(model: Node3D,level: int,
        damage: int,issues: PackedStringArray,counts: Dictionary) -> void:
    if damage>=2:
        return
    var queue: Array[Node]=[model]
    while not queue.is_empty():
        var node: Node=queue.pop_back()
        for ch in node.get_children():
            queue.append(ch)
        if not (node is Node3D):
            continue
        var g: Node3D=node as Node3D
        var gname: String=str(g.name)
        if level==1 and gname.begins_with("VillaTradicionalV15_"):
            var tiles: Array[MeshInstance3D]=[]
            for ch in g.get_children():
                if ch is MeshInstance3D and str(ch.name).begins_with(
                        "TejaCaballeraV15_"):
                    tiles.append(ch as MeshInstance3D)
            if tiles.size()>=2:
                counts["villa_roof_groups"]=int(counts["villa_roof_groups"])+1
                for tile in tiles:
                    var nearest: float=INF
                    for other in tiles:
                        if other==tile:
                            continue
                        nearest=minf(nearest,absf(
                            tile.position.z-other.position.z))
                    var b: BoxMesh=tile.mesh as BoxMesh
                    if b!=null and nearest<INF:
                        var width: float=b.size.z*absf(tile.scale.z)
                        if nearest-width>0.025:
                            issues.append("Villa: discontinuidad de cumbrera "+gname)
                            break
        elif level==2 and gname.begins_with(
                "CiudadCompactaMamposteriaV15_"):
            for ch in g.get_children():
                if not (ch is MeshInstance3D):
                    continue
                var top: MeshInstance3D=ch as MeshInstance3D
                if not str(top.name).begins_with("BandaParapetoPiedraV15_"):
                    continue
                var under: MeshInstance3D=_box(g,str(top.name).replace(
                    "BandaParapetoPiedraV15_","BandaLadrilloRemateV15_"))
                if under==null:
                    issues.append("Ciudad: falta apoyo bajo cornisa "+gname)
                    continue
                counts["town_cornices"]=int(counts["town_cornices"])+1
                if _width_x(top)+0.025<_width_x(under):
                    issues.append("Ciudad: cornisa menor al apoyo "+gname)
        elif level==3 and gname.begins_with("MetropoliVidrioYAceroV15_"):
            for ch in g.get_children():
                if not (ch is MeshInstance3D):
                    continue
                var lamp: MeshInstance3D=ch as MeshInstance3D
                if not str(lamp.name).begins_with("LuzFranjaCivicaMetroV15_"):
                    continue
                var crown: MeshInstance3D=_box(g,str(lamp.name).replace(
                    "LuzFranjaCivicaMetroV15_","CoronaEscalonadaMetroV15_"))
                if crown==null:
                    issues.append("Metropoli: falta corona de apoyo "+gname)
                    continue
                counts["metro_crowns"]=int(counts["metro_crowns"])+1
                if _top_y(lamp)-_top_y(crown)>0.025:
                    issues.append("Metropoli: franja luminosa sobresaliente "+gname)

static func _scan_base_roofs(model: Node3D,level: int,
        damage: int,issues: PackedStringArray,counts: Dictionary) -> void:
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for ch in node.get_children():
            pending.append(ch)
        if not (node is Node3D) or not str(node.name).begins_with(
                "EdificioCivil_"):
            continue
        var lot: Node3D=node as Node3D
        var roof: MeshInstance3D=_box(lot,"Cubierta")
        if damage>=2:
            if roof!=null and not bool(roof.get_meta(
                    "v11_schematic_replaced",false)):
                issues.append("Cubierta original sin reemplazar "+str(lot.name))
            continue
        if roof==null:
            issues.append("Sin cubierta original "+str(lot.name))
            continue
        counts["base_roofs"]=int(counts["base_roofs"])+1
        var finish: StandardMaterial3D=roof.material_override as StandardMaterial3D
        if finish==null:
            issues.append("Sin material PBR "+str(lot.name))
        elif level<3 and finish.metallic>0.11:
            issues.append("Metal residual en cubierta civil "+str(lot.name))

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V42.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var issues:=PackedStringArray()
    var counts: Dictionary={
        "villa_roof_groups":0,
        "town_cornices":0,
        "metro_crowns":0,
        "base_roofs":0
    }
    _scan_roof_families(model,level,damage,issues,counts)
    _scan_base_roofs(model,level,damage,issues,counts)
    if damage<=1 and int(counts["base_roofs"])!=5:
        issues.append("Cubiertas originales: cantidad diferente de cinco")
    var stage: Node3D=V1._group(model,STAGE_NAME)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("no_additional_meshes",true)
    stage.set_meta("render_signoff_required",true)
    stage.set_meta("design_stage",43)
    model.set_meta("city_v43_art_counts",counts)
    model.set_meta("city_v43_art_issues",issues)
    model.set_meta("city_v43_issue_count",issues.size())
    model.set_meta("city_v43_render_checked",false)
    model.set_meta("city_art_work_in_progress",43)
    model.set_meta("city_model_approved_final",false)
    return true
