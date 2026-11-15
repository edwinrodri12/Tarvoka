extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V3 = preload("res://scripts/ui/APCFinishV3.gd")
const V5 = preload("res://scripts/ui/APCDetailV5.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int = 0

func _check(condition: bool, label: String) -> void:
    if not condition:
        failures += 1
        push_error("P06_V5_QA: " + label)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var prototypes: Node3D = Models.build("apc",0,false,6)
    _check(prototypes != null,"native LOD fallback")
    if prototypes != null:
        _check(prototypes.find_child("Bastion_P06_Casco",true,false) != null,
            "fallback still has its independent 6x6 mesh")
        prototypes.free()
    for faction in range(8):
        var model: Node3D = Models.build("apc",faction,true,13)
        _check(model != null,"V5 built for faction %d" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(model.get_meta("tarvoka_apc_sculpt_v1",false),
            "P06 sculpt installed")
        _check(model.get_meta("tarvoka_apc_armor_v2",false),
            "P06 real tires and armor installed")
        _check(model.get_meta("tarvoka_apc_finish_v3",false),
            "P06 five damage stages installed")
        _check(model.get_meta(V5.FLAG,false),
            "P06 V5 sculpted detail installed")
        _check(model.find_child("Bastion_P06_Casco",true,false) == null,
            "obsolete prototype not allocated in V5")
        _check(model.find_child("P06V5_TapasTechoEnrasadas",true,false) != null,
            "V5 roof topological panels present")
        _check(model.find_child("P06V5_SensoresEnTorreta",true,false) != null,
            "V5 sensor moves with weapon")
        _check(Models.inspect_meshes(model) > 50,
            "V5 is a real 3D mesh, not a badge")
        for stage in range(5):
            _check(V3.apply_stage(model,stage),"stage %d works" % stage)
            _check(int(model.get_meta("tarvoka_apc_v3_damage_stage",-1)) == stage,
                "stage index %d" % stage)
        _check(V3.apply_stage(model,0),"recover full stage")
        _check(Rig.pose(model,"move",0.5),"six-wheel moving rig")
        _check(Rig.pose(model,"turn_turret",0.7),"remote turret yaw")
        _check(Rig.pose(model,"attack",0.45),"automatic cannon flash")
        _check(Rig.pose(model,"hit_bullet",0.3),"small bullet impact")
        _check(Rig.pose(model,"hit_explosive",0.3),"larger explosive impact")
        _check(Rig.pose(model,"open_ramp",1.0),"rear troop ramp opens")
        _check(model.get_meta("tarvoka_apc_ramp_open",false),
            "boarding ramp persisted")
        _check(Rig.pose(model,"close_ramp",1.0),"rear troop ramp closes")
        _check(not model.get_meta("tarvoka_apc_ramp_open",true),
            "boarding ramp reclosed")
        _check(V5.set_enabled(model,false),"V3 comparison toggle")
        _check(V5.set_enabled(model,true),"V5 finish restored")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    if failures > 0:
        push_error("P06 V5 regression failures: %d" % failures)
        quit(1)
        return
    print("PASS P06 V5 eight factions, real sculpt, 6x6 rig, 5 damage stages, troop ramp and V3 comparison")
    quit(0)
