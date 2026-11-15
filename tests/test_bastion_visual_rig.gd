extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Rig = preload("res://scripts/ui/BastionVisualRig3D.gd")
const Damage = preload("res://scripts/ui/BastionDamage3D.gd")

var _failures: int = 0

func _require(ok: bool) -> void:
    if not ok:
        _failures += 1
        push_error("P06 regression failed: check %d" % _failures)

func _initialize() -> void:
    call_deferred("_run")

func _near(a: float, b: float, eps: float = 0.001) -> bool:
    return absf(a-b) <= eps

func _visible(model: Node3D, label: String) -> bool:
    var node: Node3D = model.find_child(label,true,false) as Node3D
    return node != null and node.visible

func _run() -> void:
    # Every approved faction uses exactly the same physical running gear.
    for faction in range(8):
        var model: Node3D = Models.build("apc",faction)
        _require(model != null)
        root.add_child(model)
        _require(Rig.has_rig(model))
        _require(Models.paintable_count(model) >= 7)
        var wheel_nodes: int = 0
        for side in [-1,1]:
            for axle in range(3):
                var steer_name: String = "DireccionP06_%s_%d" % [side,axle]
                var spin_name: String = "GiroRuedaP06_%s_%d" % [side,axle]
                var pivot: Node3D = model.find_child(steer_name,true,false) as Node3D
                var spinner: Node3D = model.find_child(spin_name,true,false) as Node3D
                _require(pivot != null and spinner != null)
                _require(spinner.get_parent() == pivot)
                _require(spinner.find_child("NeumaticoBastion%s_%d" % [side,axle],true,false) != null)
                _require(spinner.find_child("Tuerca%s_%d_0" % [side,axle],true,false) != null)
                wheel_nodes += 1
        _require(wheel_nodes == 6)
        var original: Vector3 = model.position
        _require(Models.pose_model("apc",model,"move",0.375,Vector2i(1,0)))
        var spinning: Node3D = model.find_child("GiroRuedaP06_1_0",true,false) as Node3D
        var steering: Node3D = model.find_child("DireccionP06_1_0",true,false) as Node3D
        var suspension: Node3D = model.find_child("DireccionP06_-1_1",true,false) as Node3D
        _require(_near(spinning.rotation_degrees.x,270.0))
        _require(absf(steering.rotation_degrees.y) > 2.0)
        _require(absf(suspension.position.y-0.355) > 0.001)
        _require(_visible(model,"EfectoPolvoRuedasP06"))
        # The same chassis can attack without showing move dust.
        _require(Models.pose_model("apc",model,"attack",0.36,Vector2i(1,0)))
        var turret: Node3D = model.find_child("TorretaRemotaP06",true,false) as Node3D
        var gun: Node3D = model.find_child("ElevacionArmaP06",true,false) as Node3D
        _require(turret.rotation_degrees.y < -20.0)
        _require(gun.position.z > -0.06)
        _require(_visible(model,"EfectoFogonazoP06"))
        _require(not _visible(model,"EfectoPolvoRuedasP06"))
        _require(Models.pose_model("apc",model,"attack",0.52,Vector2i(0,-1)))
        _require(_visible(model,"EfectoHumoDisparoP06"))
        _require(not _visible(model,"EfectoFogonazoP06"))
        _require(Models.pose_model("apc",model,"bullet",0.18))
        _require(_visible(model,"ImpactoP06_Balas"))
        _require(Models.pose_model("apc",model,"explosive",0.25))
        _require(_visible(model,"ImpactoP06_Explosivo"))
        # Rigid meshes are never detached; critical damage hides selected
        # panels and repair restores them without resetting official paint.
        _require(Damage.apply_stage(model,3))
        var plate: Node3D = model.find_child("BlindajeLateral1_1",true,false) as Node3D
        _require(not plate.visible)
        _require(Models.pose_model("apc",model,"move",0.40))
        _require(Damage.current_stage(model) == 3)
        _require(not plate.visible)
        _require(Damage.apply_stage(model,4))
        _require(not turret.visible)
        _require(Models.pose_model("apc",model,"attack",0.35))
        _require(not _visible(model,"EfectoFogonazoP06"))
        _require(Damage.apply_stage(model,0))
        Models.restore_model_pose("apc",model)
        _require(turret.visible and plate.visible)
        _require(_near(model.position.y,original.y))
        _require(_near(spinning.rotation_degrees.x,0.0))
        _require(_near(steering.rotation_degrees.y,0.0))
        _require(_near(gun.position.z,-0.06))
        _require(not _visible(model,"ImpactoP06_Explosivo"))
        _require(not _visible(model,"EfectoHumoDisparoP06"))
        model.queue_free()
        await process_frame
    if _failures > 0:
        push_error("P06 validation failed: %d checks" % _failures)
        quit(1)
        return
    print("PASS P06 rig: eight factions, six articulated wheels, suspension, steering, remote weapon and reversible damage")
    quit(0)
