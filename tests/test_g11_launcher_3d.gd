extends SceneTree

# G11 renderer regression: real editable meshes, eight faction palettes,
# reversible visual damage and motion independent from game-state logic.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Rig = preload("res://scripts/ui/G11VisualRig3D.gd")
var failed: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failed += 1
        push_error("G11 3D QA: " + label)

func _find(model: Node3D, name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    # Existing battle LOD must not allocate the heavy showroom geometry.
    var battle: Node3D = Models.build("mlrs",0,true,10)
    _check(battle != null,"low-detail battle proxy exists")
    if battle != null:
        _check(not Art.has_model(battle),"battle doesn't allocate studio sculpt")
        _check(_find(battle,"CestaLanzacohetesElevada") != null,
            "battle retains original launch pod")
        battle.free()
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"studio model faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(Art.has_model(model),"complete G11 mesh in faction %d" % faction)
        _check(Rig.has_rig(model),"G11 moving articulated rig")
        _check(Models.inspect_meshes(model) > 80,"more than 80 real 3D meshes")
        for row in range(3):
            for column in range(4):
                _check(_find(model,"G11_Tubo_%d_%d" % [column,row]) != null,
                    "tube %d/%d" % [column,row])
                _check(_find(model,"G11_BocaInterior_%d_%d" % [column,row]) != null,
                    "real dark tube opening")
        for side in [-1,1]:
            for axle in range(6):
                _check(_find(model,"G11_RuedaPivot_%d_%d" % [side,axle]) != null,
                    "12 articulated roadwheel pivots")
        var paint := _find(model,"G11_PinturaLateral_1_0") as MeshInstance3D
        _check(paint != null and paint.material_override != null,
            "faction color on actual mesh")
        var start: Vector3 = model.position
        _check(Models.pose_model("mlrs",model,"move",0.25),"moving tracks")
        _check(absf(_find(model,"G11_RuedaPivot_1_0").rotation_degrees.x) > 1.0,
            "roadwheels rotate during movement")
        _check(Models.pose_model("mlrs",model,"attack",0.35,Vector2i(1,0)),
            "launcher aims and fires")
        _check(_find(model,"G11_GiroPlataforma").rotation_degrees.y < -20.0,
            "azimuth rotation")
        _check(_find(model,"G11_ElevacionLanzador").rotation_degrees.x > 20.0,
            "launch elevation")
        _check(_find(model,"G11_EfectoFogonazo").visible,"rocket muzzle flash")
        _check(Models.pose_model("mlrs",model,"hit_bullet",0.15),
            "small-arms impact reaction")
        _check(_find(model,"G11_ImpactoBalas").visible,"bullet impact VFX")
        _check(Models.pose_model("mlrs",model,"hit_explosive",0.30),
            "explosive impact reaction")
        _check(_find(model,"G11_ImpactoExplosivo").visible,"explosion VFX")
        for level in range(5):
            _check(Art.apply_stage(model,level),"damage stage %d" % level)
            _check(Art.stage(model) == level,"persist damage stage")
            _check(_find(model,"G11_ElevacionLanzador").visible == (level < 4),
                "destruction toggles launcher")
        _check(Models.pose_model("mlrs",model,"attack",0.30),
            "destroyed rocket unit safely ignores fire")
        _check(not _find(model,"G11_EfectoFogonazo").visible,
            "destroyed G11 cannot show live salvo")
        _check(Art.apply_stage(model,0),"complete repair")
        Models.restore_model_pose("mlrs",model)
        _check(model.position.distance_to(start) < 0.001,
            "restore starting model transform")
        _check(not _find(model,"G11_ImpactoExplosivo").visible,
            "impact is reversible")
        model.queue_free()
        await process_frame
    if failed > 0:
        push_error("G11 3D QA FAILED (%d checks)" % failed)
        quit(1)
        return
    print("PASS G11 3D: 8 factions, 12 launch tubes, 12 roadwheels, LOD, firing, hits and 5 damage stages")
    quit(0)
