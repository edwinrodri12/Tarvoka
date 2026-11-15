extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/BastionDamage3D.gd")

var _failures: int = 0

func _require(ok: bool) -> void:
    if not ok:
        _failures += 1
        push_error("P06 regression failed: check %d" % _failures)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _require(Damage.stage_for_hp(100,100) == 0)
    _require(Damage.stage_for_hp(89,100) == 1)
    _require(Damage.stage_for_hp(64,100) == 2)
    _require(Damage.stage_for_hp(39,100) == 3)
    _require(Damage.stage_for_hp(0,100) == 4)
    var model: Node3D = Models.build("apc",0)
    root.add_child(model)
    _require(model.find_child("BastionP06_DanioVisual",true,false) != null)
    _require(Models.paintable_count(model) >= 7)
    var turret: Node3D = model.find_child("TorretaRemotaP06",true,false) as Node3D
    var plate: Node3D = model.find_child("BlindajeLateral1_1",true,false) as Node3D
    _require(turret != null and plate != null)
    for stage in range(5):
        _require(Damage.apply_stage(model,stage))
        _require(Damage.current_stage(model) == stage)
        _require(turret.visible == (stage < 4))
        _require(plate.visible == (stage < 3))
    _require(Damage.pose_impact(model,"bullet",0.22))
    _require((model.find_child("ImpactoP06_Balas",true,false) as Node3D).visible)
    _require(Damage.pose_impact(model,"explosive",0.25))
    _require((model.find_child("ImpactoP06_Explosivo",true,false) as Node3D).visible)
    Damage.restore(model)
    _require(not (model.find_child("ImpactoP06_Balas",true,false) as Node3D).visible)
    _require(not (model.find_child("ImpactoP06_Explosivo",true,false) as Node3D).visible)
    _require(Damage.apply_stage(model,0))
    _require(turret.visible and plate.visible)
    _require(Damage.current_stage(model) == 0)
    model.queue_free()
    await process_frame
    if _failures > 0:
        push_error("P06 validation failed: %d checks" % _failures)
        quit(1)
        return
    print("PASS Bastion P06: five reversible stages, faction paint, ballistic/explosive effects")
    quit(0)
