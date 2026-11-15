extends SceneTree

# V17 native Godot geometry verification. No performance/stress benchmark.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V17 = preload("res://scripts/ui/APCContourV17.gd")
const V16 = preload("res://scripts/ui/APCJointFinishV16.gd")
const V15 = preload("res://scripts/ui/APCUndercarriageV15.gd")
const V11 = preload("res://scripts/ui/APCExteriorV11.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failed: int = 0

func _check(condition: bool, description: String) -> void:
    if not condition:
        failed += 1
        push_error("BASTION P06 V17: "+description)

func _find(model: Node3D, label: String) -> Node3D:
    return model.find_child(label,true,false) as Node3D

func _has_36_triangles(model: Node3D, label: String) -> bool:
    var mesh: MeshInstance3D = _find(model,label) as MeshInstance3D
    return mesh!=null and mesh.mesh is ArrayMesh and (
        mesh.mesh as ArrayMesh).surface_get_array_len(0)==36

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var faction_paints: Dictionary = {}
    for faction in range(8):
        var car: Node3D = Models.build("apc",faction,true,14)
        _check(car!=null,"P06 full-detail 3D build faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(V15.FLAG,false)) and
            bool(car.get_meta(V16.FLAG,false)) and
            bool(car.get_meta(V17.FLAG,false)),
            "V15 drive train and V16 joins remain with V17")
        var body: Node3D = _find(car,V17.BODY)
        var collar: Node3D = _find(car,V17.STATION)
        var ramp: Node3D = _find(car,V17.DOOR)
        var turret: Node3D = _find(car,"EstacionRemotaP06")
        var hinge: Node3D = _find(car,"BisagraRampaP06")
        _check(body!=null and collar!=null and ramp!=null,
            "all three native production contour groups loaded")
        if body==null or collar==null or ramp==null or turret==null or hinge==null:
            car.queue_free()
            await process_frame
            continue
        var lid: Node3D = _find(car,V17.MID_COVER)
        var arch: Node3D = _find(car,V17.FRONT_COVER)
        var right_latch: Node3D = _find(car,V17.RIGHT_LATCH)
        _check(_has_36_triangles(car,"P06V17_PiezaTransicionProa_1") and
            _has_36_triangles(car,"P06V17_CuartonTrasero_-1"),
            "frontal and rear corners have closed six-faced real meshes")
        _check(_has_36_triangles(car,"P06V17_RebordeArco_1_2"),
            "true solid wheel-arch return (not texture or line)")
        _check(_has_36_triangles(car,V17.MID_COVER),
            "right central service lid is physically sealed")
        _check(collar.get_parent()==turret and ramp.get_parent()==hinge,
            "new collar and troop-door locks follow their real pivots")
        _check(collar.get_child_count()==V17.PAD_COUNT*2,
            "eight separate solid collar segments and eight fasteners")
        var segment: MeshInstance3D = _find(car,
            "P06V17_SegmentoAnillo_0") as MeshInstance3D
        _check(segment!=null and segment.mesh is ArrayMesh and
            (segment.mesh as ArrayMesh).surface_get_array_len(0)==36,
            "collar sectors each contain top, bottom and real side faces")
        var paint: MeshInstance3D = _find(car,
            "P06V17_CuartonTrasero_1") as MeshInstance3D
        if paint!=null and paint.material_override is StandardMaterial3D:
            faction_paints[(paint.material_override as StandardMaterial3D).albedo_color.to_html()] = true
        else:
            _check(false,"painted rear armor material exists")
        var collar_rest: Transform3D = segment.global_transform
        _check(Rig.pose(car,"turn_turret",0.75),"turret 3D motion remains")
        _check(segment.global_transform!=collar_rest,
            "V17 collar follows real traversing turret")
        Rig.restore(car)
        var door_part: Node3D = _find(car,"P06V17_JuntaSuperiorRampa")
        var ramp_rest: Transform3D = door_part.global_transform
        _check(Rig.pose(car,"open_ramp",0.50),
            "troop ramp open animation remains")
        _check(door_part.global_transform!=ramp_rest,
            "V17 seals and locks rotate with live V10 hinge")
        Rig.restore(car)
        for stage in range(5):
            _check(V11.set_stage(car,stage),"V11 original stage %d" % stage)
            _check(V17.set_stage(car,stage),"V17 stage %d" % stage)
            _check(body.visible==(stage<4) and
                collar.visible==(stage<4) and ramp.visible==(stage<4),
                "production finish disappears only at total destruction")
            _check(lid.visible==(stage<2),
                "service lid never floats over V11 moderate tear")
            _check(arch.visible==(stage<3),
                "left front arch return breaks on critical damage")
            _check(right_latch.visible==(stage<3),
                "right ramp lock detaches on critical damage")
        _check(V11.set_stage(car,0) and V17.set_stage(car,0),
            "full cosmetic repair")
        _check(lid.visible and arch.visible and right_latch.visible,
            "repaired part positions restored")
        _check(V17.set_enabled(car,false),"historical comparison")
        _check(not body.visible and not collar.visible and not ramp.visible,
            "V3 comparison hides every V17 group")
        _check(V17.set_enabled(car,true),"re-enable V17 after comparison")
        _check(body.visible and collar.visible and ramp.visible,
            "V17 geometry returns without rebuilding any part")
        car.queue_free()
        await process_frame
    _check(faction_paints.size()==8,
        "eight original faction finishes are individually painted")
    if failed>0:
        push_error("BASTION P06 V17: %d native QA checks failed" % failed)
        quit(1)
        return
    print("PASS BASTION V17: closed front/rear faceted armor, real collar 8 segments, articulated ramp locks, all damage stages, eight colors and reversible repair")
    quit(0)
