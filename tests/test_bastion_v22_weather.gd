extends SceneTree

# V22 presentation-only climate PBR regressions (not a performance test).
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V21 = preload("res://scripts/ui/APCMaterialFinishV21.gd")
const V22 = preload("res://scripts/ui/APCWeatherFinishV22.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int=0

func _check(ok: bool, message: String) -> void:
    if not ok:
        failures+=1
        push_error("BASTION V22: "+message)

func _m(model: Node3D, name: String) -> StandardMaterial3D:
    var mesh: MeshInstance3D=model.find_child(
        name,true,false) as MeshInstance3D
    return mesh.material_override as StandardMaterial3D if mesh!=null else null

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var faction_paints: Dictionary={}
    for faction in range(8):
        var car: Node3D=Models.build("apc",faction,true,14)
        _check(car!=null,"vehicle for faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(V21.FLAG,false)) and
            bool(car.get_meta(V22.FLAG,false)),
            "V21 texture and V22 reversible weather finish installed")
        var panel: String="P06V19_ChaflanSuperior_1_0"
        var rubber: String="P06V19_LabioCurvo_1_0_0"
        var steel: String="P06V20_PernoArco_1_0_0_Hex"
        var base_paint: StandardMaterial3D=_m(car,panel)
        var base_rubber: StandardMaterial3D=_m(car,rubber)
        var base_steel: StandardMaterial3D=_m(car,steel)
        _check(base_paint!=null and base_rubber!=null and base_steel!=null,
            "PBR factory paint, steel fastener and rubber seal built")
        if base_paint==null or base_rubber==null or base_steel==null:
            car.queue_free()
            await process_frame
            continue
        faction_paints[base_paint.albedo_color.to_html()]=true
        _check(str(car.get_meta(V22.MODE,""))=="clear",
            "default studio climate does not alter V21 colors")
        _check(V22.set_weather(car,"rain"),"rain activated")
        var rainy: StandardMaterial3D=_m(car,panel)
        var wet_steel: StandardMaterial3D=_m(car,steel)
        var wet_rubber: StandardMaterial3D=_m(car,rubber)
        _check(rainy!=base_paint and rainy.roughness<base_paint.roughness
            and rainy.albedo_texture==base_paint.albedo_texture
            and rainy.uv1_triplanar,
            "rain darkens faction paint and reduces roughness but keeps texture")
        _check(wet_steel.roughness<base_steel.roughness and
            wet_rubber.metallic<0.05,
            "wet steel reflects more while rubber stays nonmetallic")
        var rain_r: float=rainy.roughness
        _check(V22.set_weather(car,"rain") and
            absf(_m(car,panel).roughness-rain_r)<0.00001,
            "reselecting rain does not compound PBR changes")
        _check(V22.set_weather(car,"snow"),"snow activated")
        var snowy: StandardMaterial3D=_m(car,panel)
        _check(snowy.roughness>base_paint.roughness and
            snowy.albedo_color.r>base_paint.albedo_color.r and
            snowy.albedo_texture==base_paint.albedo_texture,
            "frost is lighter and matte while retaining faction texture")
        _check(_m(car,rubber).roughness>base_rubber.roughness,
            "snow deposits increase seal roughness")
        _check(V22.set_weather(car,"clear"),"clear weather returns")
        _check(_m(car,panel)==base_paint and
            _m(car,steel)==base_steel and _m(car,rubber)==base_rubber,
            "clear restores ORIGINAL V21 materials by exact reference")
        _check(not V22.set_weather(car,"acid"),
            "unsupported climate never changes approved materials")
        _check(V22.set_weather(car,"rain"),"resume rain for damage")
        for stage in range(5):
            _check(V21.set_stage(car,stage) and
                V22.set_stage(car,stage),
                "wet paint follows cosmetic damage stage %d" % stage)
            _check(int(car.get_meta(V22.STAGE,-1))==stage,
                "new materials stage metadata tracks visual damage")
        _check(V21.set_stage(car,0) and V22.set_stage(car,0),
            "rain remains reversible through repair")
        _check(V22.set_weather(car,"clear") and
            _m(car,panel)==base_paint,
            "full repair returns same original V21 paint material")
        _check(V22.set_weather(car,"snow"),"snow for version comparison")
        _check(V21.set_enabled(car,false) and
            V22.set_enabled(car,false),
            "historical comparison disables paint and weather layers")
        var actual: MeshInstance3D=car.find_child(
            panel,true,false) as MeshInstance3D
        _check(actual.material_override==actual.get_meta(V21.ORIGINAL),
            "V3 old finish restored, not covered with frozen V22 paint")
        _check(V21.set_enabled(car,true) and
            V22.set_enabled(car,true),
            "return to V22 after historical comparison")
        _check(_m(car,panel).roughness>base_paint.roughness,
            "snow preset survives temporary old-version comparison")
        _check(V22.set_weather(car,"clear"),"clear after comparison")
        var wheel: Node3D=car.find_child(
            "RuedaMotorizadaP06_1_0",true,false) as Node3D
        if wheel!=null:
            var initial: Transform3D=wheel.transform
            _check(Rig.pose(car,"move_turn",0.61) and
                wheel.transform!=initial,
                "V22 does not block real six-wheel steering")
            Rig.restore(car)
        car.queue_free()
        await process_frame
    _check(faction_paints.size()==8,
        "all eight unique faction base paints retained")
    if failures>0:
        push_error("BASTION V22: %d regressions" % failures)
        quit(1)
        return
    print("PASS BASTION V22: eight faction paints, rain gloss, snow frost, clean restoration, five damage stages, reversible V3 comparison, six-wheel steering")
    quit(0)
