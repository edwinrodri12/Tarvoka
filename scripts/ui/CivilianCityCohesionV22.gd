extends RefCounted
class_name TarvokaCivilianCityCohesionV22

# V22 ART ONLY: resolve V21 duplicate front/rear trim and preserve the
# distinct silhouettes of villa, town, metropolis at all zoom levels.
# Do not change gameplay sites, street footprint, ownership or capture.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V9=preload("res://scripts/ui/CivilianCityFinishV9.gd")
const V21=preload("res://scripts/ui/CivilianCityArchitecturalDetailV21.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const STAGE_NAME="CiudadCivilV22CoherenciaYSolapes"

const CERAMIC=Color("#b87b59")
const WOOD=Color("#846b55")
const STONE=Color("#cbbca3")
const BRICK=Color("#a07863")
const METAL=Color("#6f858d")
const GLASS=Color("#547f8a")
const DUST=Color("#786e63")
const CHAR=Color("#414a4c")

static func _part(parent: Node3D,name: String,
        at: Vector3,size: Vector3,color: Color,
        finish: String="stone") -> MeshInstance3D:
    var m: MeshInstance3D=V1._box(parent,name,at,size,color)
    m.material_override=V9._finish(color,finish)
    return m

static func _mark_hidden(mesh: MeshInstance3D) -> void:
    # Shared LOD builder checks this flag when changing distance and
    # when physically pruning meshes in compact mobile mode.
    mesh.set_meta("city_v22_superseded",true)
    mesh.visible=false

static func _face_from_name(name: String,suffix_count: int) -> int:
    var fields: PackedStringArray=name.split("_")
    var target: int=fields.size()-suffix_count
    if target<0:
        return 0
    var str_face: String=str(fields[target])
    if str_face=="-1":
        return -1
    if str_face=="1":
        return 1
    return 0

static func _is_frontage(tag: String,face: int) -> bool:
    # V10 road-facing residential doors live on:
    # North residence south/rear (+Z) and South residence north/front (-Z).
    return ((tag.begins_with("Norte_") and face==1)
        or (tag.begins_with("Sur_") and face==-1))

static func _resolve_v21_lot(stage: Node3D,
        tag: String,damage: int) -> int:
    var group: Node=stage.get_node_or_null("V21_Detallado_"+tag)
    if group==null:
        return 0
    var hidden: int=0
    var pending: Array[Node]=[group]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not node is MeshInstance3D:
            continue
        var mesh:=node as MeshInstance3D
        var n: String=str(mesh.name)
        # V8 has complete rear windows and mullions at the same Z depth
        # as V21; drawing both causes flicker / Z-fighting.
        var is_window: bool=(n.begins_with("V21_MontanteVentana_")
            or n.begins_with("V21_ImpostaVentana_")
            or n.begins_with("V21_VidrioOscurecido_"))
        if is_window:
            var face: int=_face_from_name(n,2)
            if face==1 or damage>=2:
                _mark_hidden(mesh)
                hidden+=1
            elif face==-1:
                # Move close-only mullions inward toward the V1 front glass
                # rather than leaving them 10cm proud of their frame.
                mesh.position.z+=0.071
            continue
        if n.begins_with("V21_CristalAstillado_"):
            if _face_from_name(n,2)==1:
                _mark_hidden(mesh)
                hidden+=1
            continue
        # V9 already supplies full rainpipes and downspouts. Avoid a
        # second pipe running through the same rear facade.
        if (n.begins_with("V21_BajantePluvial_")
                or n.begins_with("V21_BocaBajante_")):
            _mark_hidden(mesh)
            hidden+=1
            continue
        # V8/V10 already supplies the metropolitan rooftop HVAC volume.
        if (n=="V21_EquipoClima"
                or n.begins_with("V21_Respiradero_")):
            _mark_hidden(mesh)
            hidden+=1
            continue
        # Residential V10 entrances occupy the V21 road-facing door
        # jamb plane. Keep the established V10 entrance and only the
        # opposite, quiet service-door trim from V21.
        var door_detail: bool=(n.begins_with("V21_JambaPuerta_")
            or n.begins_with("V21_DintelPuerta_")
            or n.begins_with("V21_PeldañoPuerta_")
            or n.begins_with("V21_Tirador3DPuerta_")
            or n.begins_with("V21_TravesañoMadera_")
            or n.begins_with("V21_DintelCaido_"))
        if door_detail:
            var face_index: int=(2 if n.begins_with("V21_JambaPuerta_")
                else 1)
            var face: int=_face_from_name(n,face_index)
            if _is_frontage(tag,face):
                _mark_hidden(mesh)
                hidden+=1
    return hidden

static func _tier_signature(stage: Node3D,
        tag: String,x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int,
        accent: Color) -> void:
    var group:=V1._group(stage,"PerfilIdentidadV22_"+tag)
    var h: float=float(floors)*2.10+0.21
    if damage>=3:
        # The district is destroyed: small low fragments are all that
        # remain; do NOT restore whole parapets or a tall metro crown.
        var tint: Color=CERAMIC if level==1 else BRICK if level==2 else METAL
        for i in range(2):
            var shard:=_part(group,
                "V22_FragmentoReconocible_%s_%d" % [tag,i],
                Vector3(x+(float(i)-0.5)*w*0.43,
                    0.11,z+d*(0.24 if i==0 else -0.23)),
                Vector3(0.40,0.16,0.36),tint,
                "ceramic" if level==1 else "stone" if level==2 else "steel")
            shard.rotation_degrees.y=float(i)*23.0
        return
    # Front left/right edge: clear of the V1 windows at x=+/-0.23w,
    # and clear of the V10 central doorway at x=0.
    for side in [-1,1]:
        if damage==2 and side==1:
            continue
        var xx: float=x+float(side)*w*0.42
        var front: float=z-d*0.5-0.16
        if level==1:
            # Warm ceramic/masonry makes a one-floor villa unmistakable.
            _part(group,"V22_VillaCeramicaPedestal_%s_%d" % [tag,side],
                Vector3(xx,0.27,front),
                Vector3(0.21,0.33,0.15),CERAMIC,"ceramic")
            if damage<=1:
                _part(group,"V22_VillaMaderaResalte_%s_%d" % [tag,side],
                    Vector3(xx,h-0.27,front),
                    Vector3(0.12,0.26,0.11),WOOD)
        elif level==2:
            # Urban stone pier and a shallow brick band per storey.
            _part(group,"V22_CiudadPilastraEsquina_%s_%d" % [tag,side],
                Vector3(xx,h*0.48,front),
                Vector3(0.17,h*0.75,0.13),STONE)
            for floor in range(1,floors):
                _part(group,"V22_CiudadFrisoPiso_%s_%d_%d" %
                    [tag,side,floor],
                    Vector3(xx,float(floor)*2.10,front-0.02),
                    Vector3(0.27,0.11,0.18),BRICK)
        else:
            # Metallic modular setback; faction hue is a SMALL inset,
            # not solid faction paint across the entire facade.
            _part(group,"V22_MetroNervioVertical_%s_%d" % [tag,side],
                Vector3(xx,h*0.51,front),
                Vector3(0.12,h*0.80,0.15),METAL,"steel")
            if damage<=1:
                _part(group,"V22_MetroVidrioCantonera_%s_%d" %
                    [tag,side],
                    Vector3(xx,h*0.71,front-0.09),
                    Vector3(0.085,0.49,0.028),GLASS,"glass")
                _part(group,"V22_MetroIdentidadDiscreta_%s_%d" %
                    [tag,side],
                    Vector3(xx,h-0.20,front-0.10),
                    Vector3(0.11,0.13,0.055),accent,"steel")
    if damage==2:
        _part(group,"V22_FinRemateRoto_"+tag,
            Vector3(x+w*0.30,0.17,z-d*0.50-0.20),
            Vector3(0.38,0.16,0.28),DUST)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V21.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var v21: Node3D=model.get_node_or_null(V21.STAGE_NAME) as Node3D
    if v21==null:
        return false
    var stage:=V1._group(model,STAGE_NAME)
    var accent: Color=(Style.faction_color(faction)
        if faction>=0 else V1.NEUTRAL_ACCENT)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    var hidden: int=0
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String=("Sur_" if southern else "Norte_")+str(side)
            hidden+=_resolve_v21_lot(v21,tag,damage)
            _tier_signature(stage,tag,x,
                3.62 if southern else -3.80,
                2.77 if southern else 2.74,
                2.80 if southern else 2.84,
                south_floors if southern else north_floors,
                level,damage,accent)
    hidden+=_resolve_v21_lot(v21,"Ayuntamiento",damage)
    _tier_signature(stage,"Ayuntamiento",0.0,-3.75,
        3.35,2.74,2 if level==1 else 3 if level==2 else 4,
        level,damage,accent)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",22)
    stage.set_meta("superseded_v21_overlaps",hidden)
    stage.set_meta("focus","facade-overlap-correction-and-tier-identity")
    model.set_meta("city_v22_hidden_overlaps",hidden)
    model.set_meta("city_art_work_in_progress",22)
    model.set_meta("city_model_approved_final",false)
    return true
