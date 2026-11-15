extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Damage = preload("res://scripts/ui/BastionDamage3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    assert(Damage.stage_for_hp(100,100) == 0)
    assert(Damage.stage_for_hp(89,100) == 1)
    assert(Damage.stage_for_hp(64,100) == 2)
    assert(Damage.stage_for_hp(39,100) == 3)
    assert(Damage.stage_for_hp(0,100) == 4)
    var model: Node3D = Models.build("apc",0)
    root.add_child(model)
    assert(model.find_child("BastionP06_DanioVisual",true,false) != null)
    assert(Models.paintable_count(model) >= 7)
    var turret: Node3D = model.find_child("TorretaRemotaP06",true,false) as Node3D
    var plate: Node3D = model.find_child("BlindajeLateral1_1",true,false) as Node3D
    assert(turret != null and plate != null)
    for stage in range(5):
        assert(Damage.apply_stage(model,stage))
        assert(Damage.current_stage(model) == stage)
        assert(turret.visible == (stage < 4))
        assert(plate.visible == (stage < 3))
    assert(Damage.pose_impact(model,"bullet",0.22))
    assert((model.find_child("ImpactoP06_Balas",true,false) as Node3D).visible)
    assert(Damage.pose_impact(model,"explosive",0.25))
    assert((model.find_child("ImpactoP06_Explosivo",true,false) as Node3D).visible)
    Damage.restore(model)
    assert(not (model.find_child("ImpactoP06_Balas",true,false) as Node3D).visible)
    assert(not (model.find_child("ImpactoP06_Explosivo",true,false) as Node3D).visible)
    assert(Damage.apply_stage(model,0))
    assert(turret.visible and plate.visible)
    assert(Damage.current_stage(model) == 0)
    model.queue_free()
    print("PASS Bastion P06: five reversible stages, faction paint, ballistic/explosive effects")
    quit(0)
