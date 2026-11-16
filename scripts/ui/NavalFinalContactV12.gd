extends RefCounted
class_name TarvokaNavalFinalContactV12

# Godot 4.3 native final close-range marine detail layer.
# V12 corrects mechanical chain sag, adds restrained seawall witness marks
# and exposes a reversible visual finish. No navigation/collision/production.
# V1-V11 unchanged; former chains are only hidden on V12 instances.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V10=preload("res://scripts/ui/NavalMooringAlignmentV10.gd")
const V11=preload("res://scripts/ui/NavalContactFinishV11.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

const STAGE_NAME: String="RevisionIntegral360ContactosNavalesV12"
const STEEL=Color("#627f83")
const RUBBER=Color("#29383b")
const SALT=Color("#82999a")
const CORRODED=Color("#936c57")
const SCRAP=Color("#665a56")
const MARK=Color("#afc1b7")
const SEA_LINE_Y: float=0.061
const MIN_CHAIN_Y: float=0.22

static func _box(parent: Node3D,name: String,position: Vector3,
        size: Vector3,color: Color,
        metal: float=0.14,rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
    return Base._box(parent,name,position,size,color,metal,rot)

static func _curve_point(a: Vector3,b: Vector3,t: float,sag: float) -> Vector3:
    # Ends remain bolted to EXACT V10 coordinates; gravity only bends midspan.
    var p: Vector3=a.lerp(b,clampf(t,0.0,1.0))
    p.y-=sag*sin(PI*clampf(t,0.0,1.0))
    return p

static func _chain_curve(parent: Node3D,label: String,
        start: Vector3,finish: Vector3,damage: int) -> MultiMeshInstance3D:
    var length: float=start.distance_to(finish)
    if length<0.035:
        return null
    var sag: float=minf(0.045,length*0.13)
    var links: int=clampi(int(ceil(length/0.11)),3,9)
    var mesh:=MultiMesh.new()
    mesh.transform_format=MultiMesh.TRANSFORM_3D
    mesh.mesh=V11._chain_link_mesh()
    mesh.instance_count=links
    for i in range(links):
        var t: float=float(i+1)/float(links+1)
        var previous: Vector3=_curve_point(start,finish,maxf(0.0,t-0.01),sag)
        var following: Vector3=_curve_point(start,finish,minf(1.0,t+0.01),sag)
        var tangent: Vector3=(following-previous).normalized()
        var pos: Vector3=_curve_point(start,finish,t,sag)
        # No chain crosses into the water; the real V10 anchors sit above it.
        pos.y=maxf(pos.y,MIN_CHAIN_Y)
        var orientation:=Basis(Quaternion(Vector3.UP,tangent))
        var alternate:=Basis(Vector3.UP,0.0 if i%2==0 else PI*0.5)
        mesh.set_instance_transform(i,Transform3D(orientation*alternate,pos))
    var chain:=MultiMeshInstance3D.new()
    chain.name=label
    chain.multimesh=mesh
    chain.material_override=V11._metal_material(damage)
    chain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    chain.set_meta("naval_v12_sag",sag)
    chain.set_meta("naval_v12_start",start)
    chain.set_meta("naval_v12_end",finish)
    chain.set_meta("naval_v12_link_count",links)
    parent.add_child(chain)
    return chain

static func _replace_chain(model: Node3D,near: Node3D,
        old_name: String,new_name: String,
        a: Vector3,b: Vector3,damage: int) -> bool:
    var old:=model.find_child(old_name,true,false) as MultiMeshInstance3D
    if old==null:
        return false
    old.visible=false
    return _chain_curve(near,new_name,a,b,damage)!=null

static func _east(model: Node3D,stage: Node3D,damage: int,
        accent: Color) -> void:
    var near: Node3D=stage.get_node("AcabadosCercanosV12")
    var far: Node3D=stage.get_node("AcabadosTacticosV12")
    stage.set_meta("naval_v12_east_assembly_verified",true)
    if damage==4:
        _box(near,"RestoJuntaMaritimaV12",
            Vector3(1.13,0.15,-3.81),
            Vector3(0.08,0.08,0.24),SCRAP,0.06,
            Vector3(7,18,17))
        return
    for i in range(7):
        if damage>=2 and i in [2,3]:
            continue
        var f: Vector3=V10.east_fender(i)
        if damage==3:
            _box(near,"CantoRotoMuelleEsteV12_%02d" % i,
                Vector3(1.131,0.20,f.z),
                Vector3(0.038,0.24,0.24),CORRODED,0.07,
                Vector3(0,10,14))
            continue
        # Existing V11 gasket and V10 plate remain in place. Thin contact
        # reveal follows the ACTUAL V2 concrete wall x=1.125.
        _box(near,"BordeCompresionEsteV12_%02d" % i,
            Vector3(1.086,0.336,f.z),
            Vector3(0.027,0.35,0.308),RUBBER,0.02)
        _box(near,"DepositoSalEnAnclajeEsteV12_%02d" % i,
            Vector3(1.075,0.127,f.z),
            Vector3(0.018,0.041,0.18),
            SALT if damage<=1 else CORRODED,0.03)
        _box(far,"ContactoLegibleEsteV12_%02d" % i,
            Vector3(1.081,0.35,f.z),
            Vector3(0.025,0.29,0.36),RUBBER,0.03)
        if damage<=1:
            _box(near,"IndicadorFaccionDiscretoEsteV12_%02d" % i,
                Vector3(1.061,0.565,f.z),
                Vector3(0.020,0.014,0.13),accent,0.10)
    if damage<=2:
        for station in range(4):
            var index: int=V10.EAST_PAIR_INDEX[station]
            var f: Vector3=V10.east_fender(index)
            var ring: Vector3=V10.quay_mooring(station)
            var mid:=Vector3(1.29,0.46,(ring.z+f.z)*0.5)
            var first: bool=_replace_chain(model,near,
                "EslabonesCadenaEste_A_%d" % station,
                "CurvaCadenaEste_A_%d" % station,
                Vector3(1.22,0.53,f.z),mid,damage)
            var second: bool=_replace_chain(model,near,
                "EslabonesCadenaEste_B_%d" % station,
                "CurvaCadenaEste_B_%d" % station,
                mid,Vector3(1.37,0.61,ring.z),damage)
            if first and second:
                _box(near,"GuardacabosCadenaEsteV12_%d" % station,
                    Vector3(1.22,0.534,f.z),
                    Vector3(0.070,0.047,0.089),
                    STEEL if damage<=1 else CORRODED,0.43)
    stage.set_meta("naval_v12_east_assembly_verified",true)

static func _piers(model: Node3D,stage: Node3D,damage: int,
        accent: Color) -> void:
    var near: Node3D=stage.get_node("AcabadosCercanosV12")
    var far: Node3D=stage.get_node("AcabadosTacticosV12")
    stage.set_meta("naval_v12_pier_assembly_verified",true)
    if damage==4:
        _box(near,"PlacaSeparadaDeEspigonV12",
            Vector3(-4.62,0.18,-4.33),
            Vector3(0.18,0.06,0.17),SCRAP,0.07,
            Vector3(9,10,23))
        return
    for side in [-1,1]:
        if damage>=3 and side==1:
            continue
        for i in range(3):
            if damage>=2 and i==1:
                continue
            var f: Vector3=V10.pier_fender(side,i)
            if damage==3:
                _box(near,"UnionEspigonDesgarradaV12_%s_%d" % [side,i],
                    Vector3(f.x,0.27,float(side)*4.30),
                    Vector3(0.30,0.19,0.048),CORRODED,0.09,
                    Vector3(8,0,16))
                continue
            _box(near,"PerfilCompresionEspigonV12_%s_%d" % [side,i],
                Vector3(f.x,0.31,float(side)*4.252),
                Vector3(0.30,0.32,0.023),RUBBER,0.02)
            _box(near,"SalpicaduraAceroEspigonV12_%s_%d" % [side,i],
                Vector3(f.x,0.149,float(side)*4.208),
                Vector3(0.18,0.036,0.017),
                SALT if damage<=1 else CORRODED,0.04)
            _box(far,"ContactoEspigonVisibleV12_%s_%d" % [side,i],
                Vector3(f.x,0.31,float(side)*4.244),
                Vector3(0.35,0.27,0.03),RUBBER,0.01)
            var b: Vector3=V10.pier_bollard(side,i)
            var mid:=Vector3((f.x+b.x)*0.5,0.50,float(side)*4.45)
            var first: bool=_replace_chain(model,near,
                "EslabonesCadenaEspigon_A_%s_%d" % [side,i],
                "CurvaCadenaEspigon_A_%s_%d" % [side,i],
                Vector3(f.x,0.54,float(side)*4.21),mid,damage)
            var second: bool=_replace_chain(model,near,
                "EslabonesCadenaEspigon_B_%s_%d" % [side,i],
                "CurvaCadenaEspigon_B_%s_%d" % [side,i],
                mid,Vector3(b.x,0.67,float(side)*4.66),damage)
            if first and second:
                _box(near,"GuardacabosEspigonV12_%s_%d" % [side,i],
                    Vector3(b.x,0.665,float(side)*4.66),
                    Vector3(0.11,0.04,0.10),
                    STEEL if damage<=1 else CORRODED,0.41)
                _box(near,"MarcaFaccionRetenedorV12_%s_%d" % [side,i],
                    Vector3(b.x,0.70,float(side)*4.66),
                    Vector3(0.075,0.012,0.06),accent,0.10)
    stage.set_meta("naval_v12_pier_assembly_verified",true)

static func set_detail(model: Node3D,near_view: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    var stage: Node3D=model.get_node(STAGE_NAME)
    (stage.get_node("AcabadosCercanosV12") as Node3D).visible=near_view
    (stage.get_node("AcabadosTacticosV12") as Node3D).visible=not near_view
    stage.set_meta("naval_v12_near",near_view)
    return true

static func set_night(model: Node3D,enabled: bool) -> bool:
    if model==null or not model.has_node(STAGE_NAME):
        return false
    # Retain genuine V6 lighting; no additional expensive light emitters.
    (model.get_node(STAGE_NAME) as Node3D).set_meta(
        "naval_v12_night",enabled)
    return true

static func apply(model: Node3D,level: int,
        faction: int,damage: int) -> bool:
    if model==null or not Base.valid_spec(level,faction,damage):
        return false
    if not bool(model.get_meta("tarvoka_naval_base_v1",false)):
        return false
    if not model.has_node(V10.STAGE_NAME) or not model.has_node(V11.STAGE_NAME):
        return false
    if model.has_node(STAGE_NAME):
        return false
    var stage:=Base._group(model,STAGE_NAME)
    Base._group(stage,"AcabadosCercanosV12")
    Base._group(stage,"AcabadosTacticosV12")
    _east(model,stage,damage,Style.faction_color(faction))
    _piers(model,stage,damage,Style.faction_color(faction))
    stage.set_meta("naval_v12_faction",faction)
    stage.set_meta("naval_v12_damage",damage)
    stage.set_meta("naval_v12_level",level)
    stage.set_meta("naval_v12_preserves_original_moorings",true)
    set_detail(model,true)
    set_night(model,false)
    return true
