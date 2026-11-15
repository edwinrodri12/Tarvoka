extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V3 = preload("res://scripts/ui/APCFinishV3.gd")
const V5 = preload("res://scripts/ui/APCDetailV5.gd")
const V6 = preload("res://scripts/ui/APCFinishV6.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var errors: int = 0

func _check(ok: bool, msg: String) -> void:
    if not ok:
        errors += 1
        push_error("P06 V6 FINISH: "+msg)

func _initialize() -> void:
    call_deferred("_run")

func _visible(model: Node3D,label: String) -> bool:
    var node: Node3D = model.find_child(label,true,false) as Node3D
    return node != null and node.visible

func _run() -> void:
    for faction in range(8):
        var model: Node3D = Models.build("apc",faction,true,14)
        _check(model != null,"faction %d builds V6" % faction)
        if model == null:
            continue
        root.add_child(model)
        _check(model.get_meta(V5.FLAG,false),"V5 source preserved")
        _check(model.get_meta(V6.FLAG,false),"V6 finish installed")
        _check(model.find_child("Bastion_P06_Casco",true,false) == null,
            "no old blockout hidden in production model")
        var facade: Node3D = model.find_child(
            "P06V6_Remates3DIntegrados",true,false) as Node3D
        _check(facade != null,"integrated exterior root")
        _check(model.find_child("CincoAletasVentilacion",true,false) != null,
            "front grille is real 3D geometry")
        _check(model.find_child("SeisBordesGuardabarro",true,false) != null,
            "integrated wheel fenders")
        _check(model.find_child("VidrioSensorSecundario",true,false) != null,
            "secondary turret glass")
        _check(model.find_child("OchoFranjasAntideslizantes",true,false) != null,
            "troop-bay floor")
        var fasteners: MultiMeshInstance3D = model.find_child(
            "VeinticuatroPernosBlindaje",true,false) as MultiMeshInstance3D
        _check(fasteners != null and fasteners.multimesh.instance_count == 24,
            "24 panel fasteners in one batched draw")
        _check(int(model.get_meta("tarvoka_apc_v6_armored_rivets",0)) == 24,
            "V6 hardware count")
        var hinge: Node3D = model.find_child(
            "BisagraRampaP06",true,false) as Node3D
        var tread: Node3D = model.find_child(
            "NuevePeldañosRampa",true,false) as Node3D
        _check(hinge != null and tread != null,"real articulated ramp grip")
        if hinge != null and tread != null:
            _check(tread.get_parent().get_parent() == hinge,
                "ramp treads attached to moving hinge")
        var old_grip: Node3D = model.find_child(
            "PeliculaAntideslizanteRampa",true,false) as Node3D
        _check(old_grip == null or not old_grip.visible,
            "old static ramp grip hidden")
        _check(Rig.pose(model,"open_ramp",1.0),"ramp opens")
        if hinge != null:
            _check(absf(hinge.rotation_degrees.x-78.0) < 0.01,
                "ramp and grip actually rotate")
        _check(Rig.pose(model,"close_ramp",1.0),"ramp closes")
        for stage in range(5):
            _check(V3.apply_stage(model,stage),"V3 stage %d" % stage)
            _check(V6.set_stage(model,stage),"V6 stage %d" % stage)
            _check(int(model.get_meta(V6.STAGE,-1)) == stage,
                "V6 damage index")
            _check(_visible(model,V6.ROOF) == (stage < 4),
                "V6 roof disappears at destruction")
            _check(_visible(model,V6.TURRET) == (stage < 4),
                "V6 turret optics disappear with destruction")
        _check(V3.apply_stage(model,0),"V3 repair")
        _check(V6.set_stage(model,0),"V6 repair")
        _check(_visible(model,V6.ROOF),"V6 repaired roof")
        _check(V5.set_enabled(model,false),"V5 comparison")
        _check(V6.set_enabled(model,false),"V6 comparison")
        _check(not _visible(model,V6.RAMP),"V6 ramp details hidden in comparison")
        _check(not _visible(model,V6.TURRET),"V6 sensors hidden in comparison")
        _check(V5.set_enabled(model,true),"restore V5")
        _check(V6.set_enabled(model,true),"restore V6")
        _check(_visible(model,V6.RAMP),"V6 ramp details restored")
        _check(_visible(model,V6.TURRET),"V6 sensors restored")
        _check(Rig.pose(model,"move",0.4),"six-wheel drive still animates")
        _check(Rig.pose(model,"attack",0.45),"remote turret still fires")
        Rig.restore(model)
        model.queue_free()
        await process_frame
    if errors > 0:
        push_error("P06 V6 failed: %d checks" % errors)
        quit(1)
        return
    print("PASS P06 V6: 8 factions, integrated 3D finish, batched hardware, dynamic ramp and reversible damage")
    quit(0)
