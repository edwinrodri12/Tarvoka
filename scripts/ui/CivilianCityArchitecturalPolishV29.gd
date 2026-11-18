extends RefCounted
class_name TarvokaCivilianCityArchitecturalPolishV29

# V29 — last architectural joinery pass before visual-art review.
# Operates on the real V1..V28 city geometry and existing Godot materials.
# Only visual adjustments: no footprint, roads, capture, income, collisions,
# production, attack, navigation, save data, or gameplay changes.
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V26=preload("res://scripts/ui/CivilianCityWeatherFinishV26.gd")
const V28=preload("res://scripts/ui/CivilianCityFourElevationV28.gd")
const STAGE_NAME="CiudadCivilV29PulidoFinalEncuentros"

const CLAY=Color("#b07a5b")
const TIMBER=Color("#78604d")
const MORTAR=Color("#aca090")
const STONE=Color("#beb09e")
const STEEL=Color("#61767e")
const OXIDE=Color("#6d6056")
const DUST=Color("#85796c")
const ASH=Color("#565452")

static func _facing(level: int,damage: int) -> Color:
    var tint: Color=CLAY if level==1 else STONE if level==2 else STEEL
    return tint.lerp(DUST,0.0 if damage==0 else
        0.08 if damage==1 else 0.24 if damage==2 else
        0.39 if damage==3 else 0.53)

static func _core(level: int) -> Color:
    return TIMBER if level==1 else MORTAR if level==2 else OXIDE

static func _surface(level: int) -> String:
    return "ceramic" if level==1 else "stone" if level==2 else "steel"

static func _part(parent: Node3D,name: String,
        at: Vector3,dimensions: Vector3,
        level: int,damage: int,tint: Color) -> MeshInstance3D:
    var piece: MeshInstance3D=V1._box(parent,name,at,dimensions,tint)
    piece.material_override=V26._material(
        level,damage,posmod(name.hash(),5),tint,_surface(level))
    return piece

static func _reconcile_previous(model: Node3D,
        level: int,damage: int) -> int:
    # Important: only architectural pieces whose names belong to V24,
    # V25 and V28. Keep all original windows/doors/roads, V10 portals
    # and the faction-colored identity marks as they are.
    var prefixes: Array[String]=[
        "V24_ZapataApoyoRoto_",
        "V24_PuntalDescentrado_",
        "V25_SeccionTejaPartida_",
        "V25_CantoForjadoVisible_",
        "V28_EnlaceEsquinaLateral_",
        "V28_RemateEsquinaSuperior_",
        "V28_RetornoCantoRoto_",
        "V28_EncuentroBajoRuina_",
        "V28_ZocaloNorteSur_"
    ]
    var touched: int=0
    var pending: Array[Node]=[model]
    while not pending.is_empty():
        var node: Node=pending.pop_back()
        for child in node.get_children():
            pending.append(child)
        if not (node is MeshInstance3D):
            continue
        var part: MeshInstance3D=node as MeshInstance3D
        var name: String=str(part.name)
        var found: bool=false
        for prefix in prefixes:
            if name.begins_with(prefix):
                found=true
                break
        if not found or bool(part.get_meta("city_v22_superseded",false)):
            continue
        var previous: StandardMaterial3D=part.material_override as StandardMaterial3D
        if previous==null:
            continue
        # Gentle value unification, preserving the prior material grain.
        var color: Color=previous.albedo_color.lerp(
            _facing(level,damage),0.15 if damage<2 else 0.29)
        part.material_override=V26._material(
            level,damage,posmod(name.hash(),5),color,_surface(level))
        if name.begins_with("V28_RemateEsquinaSuperior_"):
            # Avoid a fat cuboid against the already stepped V23 eave.
            part.scale.x=0.89
            part.scale.z=0.92
        elif name.begins_with("V28_ZocaloNorteSur_"):
            # Keep reveal subordinate to V10 portal surrounds.
            part.scale.y=0.88
        elif name.begins_with("V24_ZapataApoyoRoto_"):
            # The broken support remains beneath, never on the roof.
            part.scale.y=0.91
        elif name.begins_with("V25_CantoForjadoVisible_"):
            part.scale.z=0.90
        part.set_meta("city_v29_polished",true)
        touched+=1
    return touched

static func _per_lot(stage: Node3D,tag: String,
        x: float,z: float,w: float,d: float,
        floors: int,level: int,damage: int) -> void:
    var group:=V1._group(stage,"PulidoEncuentroV29_"+tag)
    var h: float=float(floors)*2.10+0.21
    var shell: Color=_facing(level,damage)
    var core: Color=_core(level)
    if damage<=1:
        # Two short roof/facade underside returns for each elevation.
        # Off-axis placement deliberately avoids center door/window panes.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.405
            for face in [-1,1]:
                if damage==1 and side==1 and face==1:
                    continue
                var zz: float=z+float(face)*d*0.435
                _part(group,
                    "V29_CosturaCubiertaFachada_%s_%d_%d" %
                    [tag,side,face],
                    Vector3(xx,h-0.10,zz),
                    Vector3(0.12,0.10,0.15),level,damage,shell)
                # Tiny inset core read as wood join, cut mortar or steel
                # bracket, with the V28 exterior silhouette still dominant.
                _part(group,
                    "V29_NucleoAlfeizar_%s_%d_%d" %
                    [tag,side,face],
                    Vector3(xx,h-0.19,zz-float(face)*0.045),
                    Vector3(0.085,0.085,0.08),level,damage,core)
        return
    if damage==2:
        # Preserve the south-east missing V23 roof corner and open center.
        # Physically attach a shallow fracture return to the existing
        # V24 support foot near the north edge, not across the roof void.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.365
            var zz: float=z-d*0.385
            var piece:=_part(group,
                "V29_TerminacionCubiertaPartida_%s_%d" % [tag,side],
                Vector3(xx,h+0.028,zz),
                Vector3(0.20,0.10,0.14),level,damage,core)
            piece.rotation_degrees.y=float(side)*9.0
            _part(group,
                "V29_JuntaFracturaInferior_%s_%d" % [tag,side],
                Vector3(xx,h-0.090,zz+0.035),
                Vector3(0.12,0.10,0.09),level,damage,shell)
        return
    if damage==3:
        # V11/V14 own the irregular walls and floor slab. Restrict the
        # detail to the already exposed low inner floor near y=0.71.
        for side in [-1,1]:
            var xx: float=x+float(side)*w*0.29
            var zz: float=z+d*0.205
            _part(group,
                "V29_CantoInteriorExpuesto_%s_%d" % [tag,side],
                Vector3(xx,0.755,zz),
                Vector3(0.17,0.085,0.10),
                level,damage,core)
        return
    # D4: no intact wall, roof, high pillars or false rebuilt thresholds.
    # Low loose fragments, grounded within the original parcel only.
    for side in [-1,1]:
        var xx: float=x+float(side)*w*0.34
        var zz: float=z-d*0.20
        var pebble:=_part(group,
            "V29_FragmentoCimientoAsentado_%s_%d" % [tag,side],
            Vector3(xx,0.10,zz),
            Vector3(0.22,0.11,0.20),level,damage,
            core.lerp(ASH,0.34))
        pebble.rotation_degrees.y=float(side)*16.0

static func _civic_identity(stage: Node3D,
        level: int,damage: int) -> void:
    # No new clock or government facade: V1/V14/V23 already own those.
    if damage==0 or damage==1:
        return
    var civic:=V1._group(stage,"DetalleCivicoPulidoV29")
    var tint: Color=_core(level)
    if damage==2:
        _part(civic,"V29_FragmentoFrisoAyuntamiento",
            Vector3(-0.94,0.15,-2.21),
            Vector3(0.25,0.13,0.15),level,damage,tint)
    elif damage==3:
        _part(civic,"V29_CantoAccesoMunicipal",
            Vector3(-0.96,0.17,-2.24),
            Vector3(0.22,0.12,0.18),level,damage,tint)
    else:
        _part(civic,"V29_PedazoPlacaCivica",
            Vector3(-0.80,0.09,-2.29),
            Vector3(0.24,0.10,0.19),level,damage,tint)

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not V1.valid_spec(level,faction,damage):
        return false
    if not model.has_node(V28.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    if (int(model.get_meta("visual_level",-1))!=level
            or int(model.get_meta("visual_faction",-2))!=faction
            or int(model.get_meta("visual_damage_stage",-1))!=damage):
        return false
    var polished: int=_reconcile_previous(model,level,damage)
    var stage:=V1._group(model,STAGE_NAME)
    var north_floors: int=1 if level==1 else 2 if level==2 else 4
    var south_floors: int=1 if level==1 else 3 if level==2 else 5
    for side in [-1,1]:
        var x: float=float(side)*4.63
        for southern in [false,true]:
            var tag: String=("Sur_" if southern else "Norte_")+str(side)
            _per_lot(stage,tag,x,
                3.62 if southern else -3.80,
                2.77 if southern else 2.74,
                2.80 if southern else 2.84,
                south_floors if southern else north_floors,
                level,damage)
    _per_lot(stage,"Ayuntamiento",0.0,-3.75,3.35,2.74,
        2 if level==1 else 3 if level==2 else 4,level,damage)
    _civic_identity(stage,level,damage)
    stage.set_meta("visual_only",true)
    stage.set_meta("no_gameplay_changes",true)
    stage.set_meta("design_stage",29)
    stage.set_meta("architectural_details_reconciled",polished)
    stage.set_meta("design_focus","final-roof-wall-joinery-and-exposed-damage-core")
    model.set_meta("city_v29_polished_meshes",polished)
    model.set_meta("city_art_work_in_progress",29)
    model.set_meta("city_model_approved_final",false)
    return true
