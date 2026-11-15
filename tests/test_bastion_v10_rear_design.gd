extends SceneTree

# Sculpture QA, not an FPS or stress test. Validate that the V10 rear door
# is real moving 3D geometry and both hydraulic links follow its hinge.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Rear=preload("res://scripts/ui/APCRearDesignV10.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
var failures: int=0

func _check(ok: bool,reason: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V10 visual sculpt: "+reason)

func _n(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"faction %d creates sculpt" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(model.get_meta(Rear.FLAG,false),
            "V10 structural rear applied for faction %d" % faction)
        var detail: Node3D=_n(model,Rear.ROOT)
        var hinge: Node3D=_n(model,Rear.HINGE)
        var door: Node3D=_n(model,Rear.RAMP_ROOT)
        var cabin: Node3D=_n(model,Rear.INTERIOR)
        _check(detail!=null and hinge!=null and door!=null and cabin!=null,
            "all real independent structural groups exist")
        if detail==null or hinge==null or door==null or cabin==null:
            model.queue_free()
            await process_frame
            continue
        _check(door.get_parent()==hinge,
            "armored ramp finish belongs to actual V1 moving hinge")
        _check(_n(model,"P06V10_UmbralAceroEstriado")!=null,
            "real armored boarding threshold")
        _check(_n(model,"P06V10_LuzDesembarqueInterior")!=null,
            "recessed safety light installed in passenger cabin")
        _check(_n(model,"P06V10_CojinSoldado_-1_0")!=null,
            "left troop bench has sculpted seat cushions")
        _check(_n(model,"P06V10_CojinSoldado_1_2")!=null,
            "right troop bench has sculpted seat cushions")
        _check(_n(model,"P06V10_PilotoTrasero_-1")!=null and
            _n(model,"P06V10_PilotoTrasero_1")!=null,
            "red and amber taillamp assemblies built on both sides")

        var hydraulic: Node3D=_n(model,Rear.HYDRAULICS)
        var links: Array=detail.get_meta(Rear.REST,[])
        _check(hydraulic!=null and links.size()==2,
            "two articulated hydraulic assemblies exist")
        var left_body: Node3D=_n(model,"P06V10_CamisaCilindro_-1")
        var left_rod: Node3D=_n(model,"P06V10_VastagoCromado_-1")
        var left_joint: Node3D=_n(model,"P06V10_RotulaPorton_-1")
        _check(left_body!=null and left_rod!=null and left_joint!=null,
            "left-cylinder barrel and chrome extension are independent meshes")
        var closed_length: float=left_body.scale.y+left_rod.scale.y
        var barrel_length: float=left_body.scale.y
        var closed_rod: float=left_rod.scale.y
        var closed_end: Vector3=left_joint.position
        _check(absf(barrel_length-0.265)<0.001,
            "steel hydraulic barrel has fixed manufactured length")
        var old_top_hinge: Node3D=_n(model,"BisagraRampa_1")
        _check(old_top_hinge==null or not old_top_hinge.visible,
            "false V1 top hinge hidden behind correct bottom pivot")
        _check(closed_length>0.20 and closed_length<0.60,
            "closed actuator connects to back of chassis")
        _check(Rig.pose(model,"open_ramp",0.50),
            "halfway ramp opens smoothly")
        _check(absf(hinge.rotation_degrees.x-43.0)<0.05,
            "halfway ramp angle is mechanically correct")
        _check(absf(float(model.get_meta(
            "tarvoka_apc_v10_hydraulic_pose_degrees",-999))-43.0)<0.05,
            "hydraulics track same intermediate hinge angle")
        _check(left_joint.position.distance_to(closed_end)>0.12,
            "hydraulic mobile joint moves during door travel")
        _check(Rig.pose(model,"open_ramp",1.0),
            "troop ramp reaches fully open position")
        var extended_length: float=left_body.scale.y+left_rod.scale.y
        _check(extended_length>closed_length+0.15,
            "two cylinders physically extend to lowered ramp")
        _check(absf(left_body.scale.y-barrel_length)<0.001,
            "metal cylinder does NOT stretch as door moves")
        _check(left_rod.scale.y>closed_rod+0.15,
            "ONLY chrome rod extends physically during door motion")
        _check(door.visible,"boarding bars remain on the open ramp")
        _check(_n(model,"P06V10_AntideslizanteBorde_3")!=null,
            "opening the ramp reveals moving mechanical grip")
        _check(Rig.pose(model,"close_ramp",1.0),
            "ramp returns to closed position")
        _check(absf(left_body.scale.y+left_rod.scale.y-closed_length)<0.015,
            "telescopic pistons retract to their original position")
        _check(Rig.pose(model,"attack",0.50),
            "V7 automatic gun still fires with V10 hydraulic equipment")
        Rig.restore(model)
        _check(V3.apply_stage(model,4),"V3 ruined stage")
        _check(V6.set_stage(model,4),"V6 ruined stage")
        _check(V7.set_stage(model,4),"V7 ruined stage")
        _check(Rear.set_stage(model,4),"V10 ruined stage")
        _check(not cabin.visible and not door.visible,
            "pristine V10 upholstery and ramp disappear when destroyed")
        _check(not _n(model,"P06V10_PilotoTrasero_1").visible,
            "rear lights do not remain pristine in wreck")
        _check(V3.apply_stage(model,0),"repair V3")
        _check(V6.set_stage(model,0),"repair V6")
        _check(V7.set_stage(model,0),"repair V7")
        _check(Rear.set_stage(model,0),"repair V10")
        _check(cabin.visible and door.visible,
            "crew compartment and ramp are restored without rebuilding")
        _check(Rear.set_enabled(model,false),
            "old V3 comparison can hide V10 additional 3D pieces")
        _check(not detail.visible and not door.visible,
            "comparison hides both fixed and moving V10 geometry")
        _check(old_top_hinge==null or old_top_hinge.visible,
            "historical V1 hinges restore only while comparing V3")
        _check(Rear.set_enabled(model,true),
            "restore V10 for inspection")
        _check(detail.visible and door.visible,
            "rear detail and hydraulics restored in original pose")
        _check(old_top_hinge==null or not old_top_hinge.visible,
            "V10 uses only accurately bottom-mounted pivot pins")
        model.queue_free()
        await process_frame
    if failures>0:
        push_error("P06 V10: %d 3D design failures" % failures)
        quit(1)
        return
    print("PASS P06 V10: eight factions, authentic boarding bay, taillights, moving ramp armor, paired telescopic hydraulic struts and full damage restoration")
    quit(0)
