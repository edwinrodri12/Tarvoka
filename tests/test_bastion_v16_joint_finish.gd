extends SceneTree

# Bastion V16 true 360-degree production joints. Cosmetic QA only.
# Not a benchmark: verify geometry, moving parents, five damage states,
# repair, faction palettes and historical V3 comparison.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Finish = preload("res://scripts/ui/APCJointFinishV16.gd")
const V15 = preload("res://scripts/ui/APCUndercarriageV15.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int = 0

func _check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("BASTION V16: " + reason)

func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var colors: Dictionary = {}
    for faction in range(8):
        var car: Node3D = Models.build("apc",faction,true,14)
        _check(car != null,"P06 built for faction %d" % faction)
        if car == null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(V15.FLAG,false)),"V15 retained")
        _check(bool(car.get_meta(Finish.FLAG,false)),"V16 loaded")
        var hull: Node3D = _find(car,Finish.ROOT)
        var tower: Node3D = _find(car,Finish.TURRET)
        var door: Node3D = _find(car,Finish.RAMP)
        var turret: Node3D = _find(car,"EstacionRemotaP06")
        var hinge: Node3D = _find(car,"BisagraRampaP06")
        _check(hull!=null and tower!=null and door!=null,
            "three physical 3D finishing groups")
        if hull==null or tower==null or door==null:
            car.queue_free()
            await process_frame
            continue
        _check(tower.get_parent()==turret,
            "bearing seal traverses with actual remote station")
        _check(door.get_parent()==hinge,
            "door edge seals follow the actual troop ramp hinge")
        var front: Node3D = _find(car,"P06V16_TransicionProa_1")
        var rear: Node3D = _find(car,"P06V16_UnionCuartoTrasero_-1")
        var arch: Node3D = _find(car,Finish.FRONT_BREAK)
        var middle: Node3D = _find(car,Finish.SIDE_BREAK)
        var plate: Node3D = _find(car,"P06V16_RetornoPanelV_1_0")
        var ring: MeshInstance3D = _find(car,"P06V16_SelloAnilloGiro") as MeshInstance3D
        _check(front is MeshInstance3D and rear is MeshInstance3D
            and arch is MeshInstance3D and plate is MeshInstance3D,
            "nose, rear, arch and belly junctions are real 3D")
        _check(ring!=null and ring.mesh is TorusMesh,
            "closed turret traversing gasket has true 3D ring")
        if front is MeshInstance3D:
            var mat: StandardMaterial3D = (front as MeshInstance3D).material_override as StandardMaterial3D
            # Nose seam is neutral steel; faction colors live on roof strip.
        var paint: MeshInstance3D = _find(car,"P06V16_BordeTechoCostado_1") as MeshInstance3D
        if paint!=null and paint.material_override is StandardMaterial3D:
            colors[(paint.material_override as StandardMaterial3D).albedo_color.to_html()]=true
        else:
            _check(false,"factory-coated faction roof finishing exists")
        _check(Rig.pose(car,"turn_turret",0.70),
            "rotation animation remains functional")
        _check(absf(turret.rotation_degrees.y)>10.0,
            "real bearing parent rotates, not a disconnected ornament")
        _check(Rig.pose(car,"open_ramp",0.50),
            "ramp hinge animation still functions")
        _check(absf(hinge.rotation_degrees.x)>20.0,
            "moving edge guards inherit opening hinge motion")
        Rig.restore(car)
        for stage in range(5):
            _check(Finish.set_stage(car,stage),
                "damage stage %d accepted" % stage)
            _check(int(car.get_meta(Finish.STAGE,-1))==stage,
                "damage stage metadata matches %d" % stage)
            _check(hull.visible==(stage<4) and
                tower.visible==(stage<4) and door.visible==(stage<4),
                "all three finish groups hidden on total destruction")
            _check(middle.visible==(stage<2),
                "right mid seam does not float over damaged V11 panel")
            _check(arch.visible==(stage<3),
                "front arch return breaks away on critical damage")
        _check(Finish.set_stage(car,0),"restore pristine state")
        _check(hull.visible and tower.visible and door.visible
            and middle.visible and arch.visible,"all joints repaired")
        _check(Finish.set_enabled(car,false),"V3 comparison toggles off")
        _check(not hull.visible and not tower.visible and not door.visible,
            "old version shows none of V16 additions")
        _check(Finish.set_enabled(car,true),"V16 returns from comparison")
        _check(hull.visible and tower.visible and door.visible,
            "production geometry returns without re-instantiation")
        car.queue_free()
        await process_frame
    _check(colors.size()==8,"eight approved faction palettes stay unique")
    if failures>0:
        push_error("BASTION V16: %d checks failed" % failures)
        quit(1)
        return
    print("PASS BASTION V16: 360 degree native geometry, rotating turret joint, ramp fittings, eight paints, five damage states, repairs and comparisons")
    quit(0)
