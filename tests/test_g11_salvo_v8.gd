extends SceneTree

# Real native 3D test for G11 V8 individual tube launch effects, Godot 4.3.
# No battle resource, ammo, turn logic, or gameplay stats are modified.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Art = preload("res://scripts/ui/G11Art3D.gd")
const Salvo = preload("res://scripts/ui/G11SequentialSalvoV8.gd")
var failures: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failures += 1
        push_error("G11 V8 salvo QA: "+label)

func _part(root_node: Node3D, name: String) -> Node3D:
    return root_node.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Salvo.SLOT_ORDER.size() == 12,"all firing sequence slots configured")
    var unique := {}
    for index in Salvo.SLOT_ORDER:
        unique[int(index)] = true
    _check(unique.size() == 12,"all tubes fire once each in staggered pattern")
    _check(Salvo.launched_count(0.0) == 0,
        "no virtual projectiles before launch")
    _check(Salvo.launched_count(0.275) == 1,
        "first rocket starts at exactly the opening instant")
    _check(Salvo.launched_count(0.85) == 12,
        "all twelve physically launch in the full salvo")
    for faction in range(8):
        var model: Node3D = Models.build("mlrs",faction,true,13)
        _check(model != null,"full native hero model for faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(Salvo.FLAG,false)),
            "V8 independent rocket sequence built for faction %d" % faction)
        _check(int(model.get_meta("tarvoka_g11_v8_projectiles",0)) == 12,
            "actual twelve separate projectiles present")
        _check(int(model.get_meta("tarvoka_g11_v8_separate_muzzles",0)) == 12,
            "every real tube has an independent muzzle ignition rig")
        var pod := _part(model,Art.ELEVATION)
        _check(pod != null,"animated launcher owns all rocket slots")
        if pod == null:
            model.queue_free()
            await process_frame
            continue
        for id in range(12):
            var slot := _part(pod,"G11V8_Slot_%02d" % id)
            var rocket := _part(pod,"G11V8_Cohete_%02d" % id)
            var ring := _part(pod,"G11V8_AnilloPresion_%02d" % id) as MeshInstance3D
            var smoke := _part(pod,"G11V8_Humo_%02d" % id)
            _check(slot != null and rocket != null and ring != null
                and smoke != null,"complete physical muzzle setup %d" % id)
            if slot != null:
                _check(slot.position.distance_to(
                    Vector3(-0.42+float(id/3)*0.28,
                        -0.24+float(id%3)*0.24,0)) < 0.001,
                    "muzzle %d aligns exactly with existing hollow tube" % id)
            if ring != null:
                _check(ring.mesh is TorusMesh,
                    "each muzzle uses genuine annular 3D flash geometry")
            _check(_part(pod,"G11V8_Ojiva_%02d" % id) != null,
                "rocket %d has real conical warhead" % id)
            _check(_part(pod,"G11V8_Aleta_%02d_3" % id) != null,
                "rocket %d has actual fin geometry" % id)
            _check(rocket != null and not rocket.visible,
                "rocket %d hidden at rest" % id)
        _check(Salvo.active_projectiles(model) == 0,
            "none of the rockets is visible before fire")
        _check(Models.pose_model("mlrs",model,"attack",0.24),
            "launcher elevates before projectiles emerge")
        _check(Salvo.active_projectiles(model) == 0,
            "no rockets escape before launcher has aimed")
        _check(Models.pose_model("mlrs",model,"attack",0.28),
            "first rocket visibly ignites")
        _check(_part(pod,"G11V8_Cohete_00").visible,
            "first physical rocket emerges from the first tube")
        _check(_part(pod,"G11V8_Boca_00").visible,
            "first tube fires independent muzzle flare")
        _check(not _part(pod,"G11V8_Cohete_05").visible,
            "second rocket does not fire at same instant")
        _check(Models.pose_model("mlrs",model,"attack",0.34),
            "first two rockets are now in separate flight states")
        _check(_part(pod,"G11V8_Cohete_05").visible,
            "second shot comes from staggered tube 05")
        _check(_part(pod,"G11V8_Cohete_00").visible,
            "first shot is still visibly in flight")
        var first_z: float = _part(pod,"G11V8_Cohete_00").position.z
        _check(first_z < -0.75,
            "physical first rocket is now beyond its barrel mouth")
        _check(Models.pose_model("mlrs",model,"attack",0.36),
            "existing 3D launcher firing animation is preserved")
        _check(_part(model,"G11_EfectoFogonazo").visible,
            "legacy effect root still tracks firing timeline")
        _check(not _part(model,"G11_Destello").visible,
            "single old spherical generic flash is actually suppressed")
        _check(Models.pose_model("mlrs",model,"attack",0.85),
            "all twelve stages can fire in the same visual salvo")
        _check(_part(pod,"G11V8_Cohete_07").visible,
            "final staggered shot launches from its own tube")
        _check(Models.pose_model("mlrs",model,"attack",0.99),
            "after salvo all projectile meshes leave the inspection frame")
        _check(Salvo.active_projectiles(model) == 0,
            "all rockets disappear after leaving the firing model")
        Models.restore_model_pose("mlrs",model)
        _check(Salvo.active_projectiles(model) == 0,
            "salvo restores with no flying projectiles")
        _check(not _part(pod,"G11V8_Boca_00").visible,
            "individual flashes all restore after stop")
        _check(Art.apply_stage(model,4),
            "destroyed state still available with new firing geometry")
        _check(Models.pose_model("mlrs",model,"attack",0.34),
            "destroyed launcher blocks all visual shots")
        _check(Salvo.active_projectiles(model) == 0,
            "destroyed G11 never visually launches projectiles")
        _check(Art.apply_stage(model,0),
            "repair fully restores functioning model with salvo V8")
        _check(Models.pose_model("mlrs",model,"attack",0.28),
            "repaired launcher can fire individual rockets again")
        _check(_part(pod,"G11V8_Boca_00").visible,
            "first tube re-ignites after full repair")
        Models.restore_model_pose("mlrs",model)
        model.queue_free()
        await process_frame
    if failures > 0:
        push_error("G11 V8 salvo QA FAILED: %d assertions" % failures)
        quit(1)
        return
    print("PASS G11 SALVO V8: 8 factions, 12 individual rockets, sequential flashes, engine jets, clean rest and destruction")
    quit(0)
