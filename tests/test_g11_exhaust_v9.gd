extends SceneTree

# V9 G11 hero QA: truly spatial, graded ArrayMesh exhaust behind the projectile,
# lingering smoke out of its own actual tube, 8 faction skins and full reset.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V8 = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
const V9 = preload("res://scripts/ui/G11ExhaustV9.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
var failures: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V9 exhaust QA: "+label)

func _node(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"native hero for faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V9.FLAG,false)),"V9 procedural exhaust applied")
        _check(int(model.get_meta("tarvoka_g11_v9_contrails",0)) == 12,
            "12 real individual engine contrails")
        _check(int(model.get_meta("tarvoka_g11_v9_residual_smoke",0)) == 12,
            "12 separate lingering smoke clouds in same tube slots")
        for tube in range(12):
            var core := _node(model,"G11V9_Nucleo_%02d" % tube) as MeshInstance3D
            var tail := _node(model,"G11V9_Estela_%02d" % tube) as MeshInstance3D
            var pressure := _node(model,"G11V9_GasesBoca_%02d" % tube) as MeshInstance3D
            var residual := _node(model,"G11V9_HumoResidual_%02d" % tube) as MeshInstance3D
            _check(core != null and tail != null and pressure != null
                and residual != null,"four 3D components in each launch tube %d" % tube)
            var flare := _node(model,
                "G11V9_FlashEsculpido_%02d" % tube) as MeshInstance3D
            _check(flare != null and flare.mesh is ArrayMesh,
                "muzzle uses short rounded 3D flame, not blocky V8 square")
            _check(not _node(model,"G11V8_AnilloPresion_%02d" % tube).visible,
                "old bright hard torus hidden behind softer sculpted flash")
            for bar in range(4):
                _check(not _node(model,
                    "G11V8_Destello_%02d_%d" % [tube,bar]).visible,
                    "V8 rectangular flame bars no longer obscure each nozzle")
            if core != null:
                _check(core.mesh is ArrayMesh,
                    "hot exhaust core uses procedural mesh with vertex color")
                _check(core.get_parent() == _node(model,"G11V8_Cohete_%02d" % tube),
                    "engine exhaust physically follows moving rocket %d" % tube)
                _check(not core.visible,"hot engine exhaust hidden at rest")
            if tail != null:
                _check(tail.mesh is ArrayMesh,
                    "trailing exhaust is authentic tapered 3D surface")
            if pressure != null and residual != null:
                _check(pressure.mesh.get_aabb().size.x < 0.46,
                    "base muzzle smoke mesh is narrow enough not to cover neighbors")
                _check(pressure.get_parent() == residual.get_parent(),
                    "pressure pulse and residual smoke align to identical tube")
                _check(pressure.get_parent() == _node(model,
                    "G11V8_Slot_%02d" % tube),
                    "no muzzle cloud detached from its actual tube %d" % tube)
            for plume in range(3):
                _check(not _node(model,"G11V8_Presion_%02d_%d" % [tube,plume]).visible,
                    "old primitive spherical launch smoke removed")
            _check(not _node(model,"G11V8_ChorroMotor_%02d" % tube).visible,
                "V8 primitive solid jet not rendered over new exhaust")
        _check(Models.pose_model("mlrs",model,"attack",0.25),
            "launcher aims ahead of ignition")
        _check(not _node(model,"G11V9_Estela_00").visible,
            "no rockets or smoke before firing")
        _check(Models.pose_model("mlrs",model,"attack",0.287),
            "first rocket accelerates with plume")
        var first := _node(model,"G11V9_Estela_00") as MeshInstance3D
        _check(first.visible,"first rocket now has visible engine contrail")
        _check(_node(model,"G11V9_GasesBoca_00").visible,
            "muzzle emits 3D pressure gases")
        _check(not _node(model,"G11V9_Estela_05").visible,
            "staggered second rocket has no premature engine wake")
        var short_trail: float = first.scale.z
        _check(Models.pose_model("mlrs",model,"attack",0.327),
            "first flight continues with growing plume")
        _check(first.scale.z > short_trail + 0.15,
            "engine exhaust stretches in physical 3D as rocket accelerates")
        _check(Models.pose_model("mlrs",model,"attack",0.410),
            "first rocket exits active flight window but leaves smoke")
        _check(not _node(model,"G11V9_Estela_00").visible,
            "engine contrail disappears when first projectile exits")
        _check(_node(model,"G11V9_HumoResidual_00").visible,
            "separate dispersing smoke remains behind first tube")
        var cloud := _node(model,"G11V9_HumoResidual_00") as MeshInstance3D
        var expanded: float = cloud.scale.x
        _check(Models.pose_model("mlrs",model,"attack",0.445),
            "residual smoke continues to dissipate after rocket departure")
        _check(cloud.visible and cloud.scale.x > expanded,
            "residual muzzle smoke expands before dispersing")
        _check(cloud.scale.x < 1.2,
            "softened exhaust never grows into an oversized gray sheet")
        _check(Models.pose_model("mlrs",model,"attack",0.550),
            "old tube clears while subsequent tubes fire")
        _check(not cloud.visible,"smoke from first shot dissipates completely")
        _check(Models.pose_model("mlrs",model,"attack",0.857),
            "latest staggered shot retains fully independent exhaust")
        _check(_node(model,"G11V9_Estela_07").visible,
            "twelfth rocket has its own attached exhaust")
        _check(_node(model,"G11V9_GasesBoca_07").visible,
            "twelfth tube emits pressure independently")
        _check(Models.pose_model("mlrs",model,"attack",0.999),
            "full volley reached end without hanging projectiles")
        _check(_node(model,"G11V9_HumoResidual_07").visible,
            "last muzzle smoke lingers after its projectile disappears")
        Models.restore_model_pose("mlrs",model)
        for tube in range(12):
            for prefix in ["G11V9_Nucleo_","G11V9_Estela_",
                    "G11V9_GasesBoca_","G11V9_HumoResidual_"]:
                _check(not _node(model,prefix+"%02d" % tube).visible,
                    "all contrail and smoke meshes restore after stopping")
        _check(Art.apply_stage(model,4),"wreck state is available")
        _check(Models.pose_model("mlrs",model,"attack",0.320),
            "destroyed vehicle never launches visible smoke or projectiles")
        _check(not _node(model,"G11V9_GasesBoca_00").visible,
            "no firing pressure while launcher is destroyed")
        _check(Art.apply_stage(model,0),"repairs restore native launch geometry")
        _check(Models.pose_model("mlrs",model,"attack",0.287),
            "repaired model can ignite new V9 exhaust again")
        _check(_node(model,"G11V9_Estela_00").visible,
            "first individual hot contrail reappears after repairs")
        Models.restore_model_pose("mlrs",model)
        model.queue_free()
        await process_frame
    if failures > 0:
        push_error("G11 V9 exhaust QA FAILED (%d checks)" % failures)
        quit(1)
        return
    print("PASS G11 EXHAUST V9: 8 factions, 12 graded 3D rocket contrails, 12 drifting muzzle clouds, lingering fades and repairs")
    quit(0)
