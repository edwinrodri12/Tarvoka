extends RefCounted
class_name TarvokaNavalMooringAlignmentV10

# Native, additive Godot 4.3 detail pass. The V9 rubber skins remain the
# original mesh; V10 joins their supports to the actual V1 pier bollards and
# V3 quay mooring stations. No changes to collisions, ship movement or rules.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V8=preload("res://scripts/ui/NavalFendersV8.gd")
const V9=preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const STAGE_NAME: String="FijacionesDefensasYAmarreAlineadoV10"
const IRON=Color("#344a53")
const GALVANISED=Color("#839ba0")
const BOLTS=Color("#acb6b1")
const RUST=Color("#9a6b53")
const WARN=Color("#e4c16f")
const NIGHT=Color("#c6dad6")
const RUBBLE=Color("#41494a")
const EAST_PAIR_INDEX=[0,2,4,6]
const EAST_QUAY_FACE: float=1.125
const INNER_PIER_FACE: float=4.30
static var _night_mat: StandardMaterial3D

static func east_fender(i: int) -> Vector3:
    return Vector3(1.04,0.31,-4.10+float(i)*1.35)

static func quay_mooring(station: int) -> Vector3:
    # Real V3 "ArgollaAmarre_<station>" locations.
    return Vector3(1.70,0.73,-3.75+float(station)*2.43)

static func pier_fender(side: int,i: int) -> Vector3:
    return Vector3(-5.10+float(i)*1.83,0.31,float(side)*4.19)

static func pier_bollard(side: int,i: int) -> Vector3:
    # Real V1 "Bolardo_<side>_<i>" locations.
    return Vector3(-5.05+float(i)*1.86,0.71,float(side)*4.85)

static func _box(parent: Node3D,name: String,
        at: Vector3,size: Vector3,color: Color,
        metal: float=0.3,rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,name,at,size,color,metal,rot)

static func _beam(parent: Node3D,name: String,
        a: Vector3,b: Vector3,radius: float,color: Color) -> void:
    Base._beam(parent,name,a,b,radius,color)

static func _badge_material() -> StandardMaterial3D:
    if _night_mat==null:
        _night_mat=StandardMaterial3D.new()
        _night_mat.albedo_color=NIGHT
        _night_mat.roughness=0.68
        _night_mat.emission_enabled=true
        _night_mat.emission=NIGHT
        _night_mat.emission_energy_multiplier=0.24
    return _night_mat

static func _paired_station(i: int) -> int:
    for station in range(EAST_PAIR_INDEX.size()):
        if i==EAST_PAIR_INDEX[station]:
            return station
    return -1

static func _east_wall_supports(model: Node3D,
        stage: Node3D,damage: int,accent: Color) -> void:
    var near: Node3D=stage.get_node("AnclajesCercanosV10")
    var far: Node3D=stage.get_node("ReferenciasTacticasV10")
    var night: Node3D=stage.get_node("GuiasNocturnasV10")
    stage.set_meta("naval_v10_east_wall_face",EAST_QUAY_FACE)
    if damage==4:
        _box(near,"PernoArrancadoMuelleEsteV10",
            Vector3(1.20,0.18,-3.83),
            Vector3(0.26,0.15,0.18),RUST,0.08,
            Vector3(8,18,25))
        return
    for i in range(7):
        if damage>=2 and i in [2,3]:
            continue
        var label: String="MuelleEste_%02d" % i
        var shell:=model.find_child(label+"_Assembly",true,false) as Node3D
        if shell==null:
            continue
        var fender: Vector3=east_fender(i)
        # V9 fender projects from quay face x=1.125, its rear collar
        # penetrates the wall by a small realistic amount.
        assert(absf(fender.x-EAST_QUAY_FACE)<0.16,
            "Eastern fender must touch the real seawall")
        if damage==3:
            _box(near,"SoporteEsteDoblado_%02d" % i,
                Vector3(1.21,0.30,fender.z),
                Vector3(0.19,0.18,0.22),RUST,0.16,
                Vector3(13,4,19))
            continue
        for side in [-1,1]:
            var z: float=fender.z+float(side)*0.135
            _box(near,"PlacaAnclajeEste_%02d_%s" % [i,side],
                Vector3(1.205,0.32,z),
                Vector3(0.20,0.32,0.095),
                IRON if damage<=1 else RUST,0.36)
            _box(near,"PernoAnclajeEste_%02d_%s" % [i,side],
                Vector3(1.098,0.44,z),
                Vector3(0.031,0.038,0.041),BOLTS,0.52)
            _beam(near,"MénsulaEste_%02d_%s" % [i,side],
                Vector3(1.08,0.28,z),
                Vector3(1.23,0.43,z),
                0.032,GALVANISED if damage<=1 else RUST)
        # A simplified support silhouette at tactical zoom, while the
        # high-poly sculpture is itself controlled by V9's zoom selector.
        _box(far,"AnclajeIdentificableEste_%02d" % i,
            Vector3(1.18,0.49,fender.z),
            Vector3(0.24,0.12,0.36),
            IRON if damage<=1 else RUST,0.18)
        var station: int=_paired_station(i)
        if station<0:
            continue
        var ring: Vector3=quay_mooring(station)
        var ring_node:=model.find_child("ArgollaAmarre_%d" % station,
            true,false) as Node3D
        if ring_node==null:
            continue
        # Keep the ship's actual mooring ring FREE. The short fender
        # retention tether ends at a separate deck plate beside that ring.
        var seat:=Vector3(1.37,0.61,ring.z)
        var tether:=Vector3(1.22,0.53,fender.z)
        _box(near,"PuntoRetencionDefensaEste_%d" % station,
            seat,Vector3(0.24,0.07,0.20),
            GALVANISED if damage<=1 else RUST,0.34)
        _beam(near,"CableRetencionEste_A_%d" % station,
            tether,Vector3(1.29,0.46,(ring.z+fender.z)*0.5),
            0.023,GALVANISED if damage<=1 else RUST)
        _beam(near,"CableRetencionEste_B_%d" % station,
            Vector3(1.29,0.46,(ring.z+fender.z)*0.5),
            seat,0.023,GALVANISED if damage<=1 else RUST)
        var marker:=_box(near,"MarcaCorrelacionAmarreEste_%d" % station,
            Vector3(1.78,0.657,ring.z),
            Vector3(0.22,0.022,0.16),accent,0.12)
        marker.set_meta("mooring_station",station)
        marker.set_meta("paired_fender",i)
        if damage<=1:
            var reflective:=_box(night,"EtiquetaAmarreReflectante_%d" % station,
                Vector3(1.81,0.680,ring.z),
                Vector3(0.18,0.014,0.08),NIGHT,0.05)
            reflective.material_override=_badge_material()
    stage.set_meta("naval_v10_east_wall_face",EAST_QUAY_FACE)

static func _pier_supports(model: Node3D,
        stage: Node3D,damage: int,accent: Color) -> void:
    var near: Node3D=stage.get_node("AnclajesCercanosV10")
    var far: Node3D=stage.get_node("ReferenciasTacticasV10")
    stage.set_meta("naval_v10_pier_wall_face",INNER_PIER_FACE)
    if damage==4:
        _box(near,"CadenaSueltaEspigonV10",
            Vector3(-4.71,0.18,-4.34),
            Vector3(0.38,0.10,0.08),RUST,0.19,
            Vector3(0,0,24))
        return
    for side in [-1,1]:
        if damage>=3 and side==1:
            continue
        for i in range(3):
            if damage>=2 and i==1:
                continue
            var body:=model.find_child(
                "Espigon_%s_%d_Assembly" % [side,i],
                true,false) as Node3D
            if body==null:
                continue
            var fender: Vector3=pier_fender(side,i)
            var bollard: Vector3=pier_bollard(side,i)
            var v8_chain:=model.find_child(
                "CadenaDefensa_%s_%d" % [side,i],
                true,false) as Node3D
            if v8_chain!=null:
                v8_chain.visible=false
            assert(absf(absf(fender.z)-INNER_PIER_FACE)<0.16,
                "Pier fender must meet its real inside seawall")
            assert(absf(fender.x-bollard.x)<0.14,
                "Pier fender must be centered under a real bollard")
            if damage==3:
                _box(near,"FijacionEspigonRota_%s_%d" % [side,i],
                    Vector3(fender.x,0.32,float(side)*4.31),
                    Vector3(0.30,0.20,0.16),RUST,0.13,
                    Vector3(0,0,17))
                continue
            # Steel anchor plates and multiple independent fasteners are
            # in the face of the actual V1 pier, never in open water.
            _box(near,"PlacaMuroEspigon_%s_%d" % [side,i],
                Vector3(fender.x,0.36,float(side)*4.33),
                Vector3(0.35,0.40,0.105),
                IRON if damage<=1 else RUST,0.36)
            for bolt in [-1,1]:
                _box(near,"PernoMuroEspigon_%s_%d_%s" % [side,i,bolt],
                    Vector3(fender.x+float(bolt)*0.12,0.45,
                        float(side)*4.269),
                    Vector3(0.042,0.04,0.026),BOLTS,0.46)
            var retain:=Vector3(bollard.x,0.67,float(side)*4.66)
            var mid:=Vector3((fender.x+bollard.x)*0.5,0.50,
                float(side)*4.45)
            var start:=Vector3(fender.x,0.54,float(side)*4.21)
            _beam(near,"CadenaAlineadaEspigon_A_%s_%d" % [side,i],
                start,mid,0.025,
                GALVANISED if damage<=1 else RUST)
            _beam(near,"CadenaAlineadaEspigon_B_%s_%d" % [side,i],
                mid,retain,0.025,
                GALVANISED if damage<=1 else RUST)
            _box(near,"RetenedorCubiertaEspigon_%s_%d" % [side,i],
                retain,Vector3(0.20,0.055,0.18),
                GALVANISED if damage<=1 else RUST,0.30)
            # The bollard at z=+/-4.85 stays intact and freely usable.
            _box(far,"GuiaRelacionBollardo_%s_%d" % [side,i],
                Vector3(bollard.x,0.650,float(side)*4.64),
                Vector3(0.22,0.021,0.20),accent,0.12)
            near.get_node("RetenedorCubiertaEspigon_%s_%d" % [side,i]).set_meta(
                "mooring_bollard_reference",
                "Bolardo_%s_%d" % [side,i])
    stage.set_meta("naval_v10_pier_wall_face",INNER_PIER_FACE)

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var layer: Node3D=model.get_node(STAGE_NAME)
    (layer.get_node("AnclajesCercanosV10") as Node3D).visible=near_view
    (layer.get_node("ReferenciasTacticasV10") as Node3D).visible=not near_view
    layer.set_meta("naval_v10_close_mode",near_view)
    return true

static func set_night(model: Node3D,enabled: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var layer: Node3D=model.get_node(STAGE_NAME)
    (layer.get_node("GuiasNocturnasV10") as Node3D).visible=enabled
    layer.set_meta("naval_v10_night_enabled",enabled)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V3.STAGE_NAME) or not model.has_node(V8.STAGE_NAME):
        return false
    if not model.has_node(V9.STAGE_NAME) or model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    Base._group(stage,"AnclajesCercanosV10")
    Base._group(stage,"ReferenciasTacticasV10")
    Base._group(stage,"GuiasNocturnasV10")
    _east_wall_supports(model,stage,damage,Style.faction_color(faction))
    _pier_supports(model,stage,damage,Style.faction_color(faction))
    stage.set_meta("naval_v10_level",level)
    stage.set_meta("naval_v10_faction",faction)
    stage.set_meta("naval_v10_damage",damage)
    stage.set_meta("naval_v10_bollards_remain_usable",true)
    set_detail(model,true)
    set_night(model,false)
    return true
