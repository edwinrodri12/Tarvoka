extends SceneTree

# P06 V15 native underside art QA, never a device/FPS benchmark.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Underside=preload("res://scripts/ui/APCUndercarriageV15.gd")
const Wheel=preload("res://scripts/ui/APCWheelV14.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const V12=preload("res://scripts/ui/APCTurretV12.gd")
const V13=preload("res://scripts/ui/APCSurfaceV13.gd")
var failures: int=0

func _check(ok: bool,why: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V15 undercarriage: "+why)

func _node(car: Node3D,name: String) -> Node3D:
    return car.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var factions: Dictionary={}
    for faction in range(8):
        var car: Node3D=Models.build("apc",faction,true,14)
        _check(car!=null,"physical 3D vehicle builds for faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(Underside.FLAG,false)),
            "underside module V15 installed on actual V14 6x6 chassis")
        _check(bool(car.get_meta(Wheel.FLAG,false)),
            "all six production wheels remain intact")
        _check(int(car.get_meta("tarvoka_apc_v15_differentials",0))==3,
            "three separate axle differentials")
        _check(int(car.get_meta("tarvoka_apc_v15_drive_shafts",0))==3,
            "front/intermediate/rear Cardan shafts")
        var hull: Node3D=_node(car,Underside.ROOT)
        var belly: Node3D=_node(car,Underside.ARMOR)
        var axles: Node3D=_node(car,Underside.AXLES)
        var transmission: Node3D=_node(car,Underside.DRIVE)
        var steering: Node3D=_node(car,Underside.STEERING)
        _check(hull!=null and belly!=null and axles!=null
            and transmission!=null and steering!=null,
            "four independent native underside mechanical groups")
        var base_belly: Node3D=_node(car,"BajoCascoEnV")
        _check(base_belly!=null and base_belly.visible,
            "original blast-protected V belly stays in the scene")
        for side in [-1,1]:
            for i in range(3):
                var plate: MeshInstance3D=_node(car,
                    "P06V15_PanelV_%d_%d" % [side,i]) as MeshInstance3D
                _check(plate!=null and plate.mesh is ArrayMesh,
                    "six physically thick angular skid panels: %d/%d" %
                    [side,i])
                if plate!=null and plate.mesh is ArrayMesh:
                    _check((plate.mesh as ArrayMesh).surface_get_array_len(0)>=36,
                        "real 3D bottom/sidewalls, no painted planes")
                    if side==1 and i==0:
                        var mat: StandardMaterial3D=(
                            plate.material_override as StandardMaterial3D)
                        if mat!=null:
                            factions[mat.albedo_color.to_html()]=true
                var wheel: Node3D=_node(car,
                    "RuedaMotorizadaP06_%d_%d" % [side,i])
                _check(wheel!=null and wheel.visible,
                    "all six wheels visible below new armor")
                var rubber: Node3D=_node(wheel,"NeumaticoTodoTerreno")
                var tread: MultiMeshInstance3D=_node(wheel,
                    "APC_V2_TacosTodoTerreno") as MultiMeshInstance3D
                _check(rubber!=null and tread!=null and
                    tread.multimesh.instance_count==48,
                    "48 3D traction lugs retained on each tire")
                var differential_stub: Node3D=_node(car,
                    "P06V15_ArbolSalida_%d_%d" % [side,i])
                _check(differential_stub!=null and
                    differential_stub.get_parent()==axles,
                    "output axle actually connects differential to V14 halfshaft")
            var tie: Node3D=_node(car,
                "P06V15_TiranteDireccion_%d" % side)
            _check(tie!=null and tie.get_parent()==steering,
                "steering rods are chassis-mounted, never spinning with tire")

        for i in range(3):
            var diff: MeshInstance3D=_node(car,
                "P06V15_Diferencial_%d" % i) as MeshInstance3D
            _check(diff!=null and diff.mesh is SphereMesh,
                "axle %d has enclosed volumetric differential" % i)
            _check(diff!=null and
                absf(diff.position.z-float(Underside.ROD_POSITIONS[i]))<0.001,
                "differential aligned with wheel axle %d" % i)
            var shaft: Node3D=_node(car,Underside.SHAFT_NAMES[i])
            _check(shaft!=null and shaft.get_parent()==transmission,
                "three drive shafts actually parent to transfer gearbox")
            var tube: Node3D=shaft.find_child("P06V15_TuboTransmision",
                false,false) as Node3D if shaft!=null else null
            _check(tube!=null and tube.scale.y>0.08,
                "drive shaft real cylinder joins gearbox and differential")
            var joint: Node3D=shaft.find_child("P06V15_CrucetaCardan",
                false,false) as Node3D if shaft!=null else null
            _check(joint!=null and joint.get_child_count()==2,
                "each drive shaft has a genuine two-axis universal cross")
        _check(_node(car,"P06V15_CajaTransferencia6x6") is MeshInstance3D,
            "mechanical three-output transfer case housed under belly")

        var right: Node3D=_node(car,"P06V15_TiranteDireccion_1")
        var baseline: Transform3D=right.transform
        var cardan: Node3D=_node(car,
            "P06V15_CrucetaCardan")
        var shaft_before: float=cardan.rotation_degrees.z
        _check(Rig.pose(car,"move_turn",0.50),
            "native 6x6 steering animation drives V15 linkages")
        _check(right.transform!=baseline,
            "front steering rod moves with V14 wheel knuckle")
        _check(absf(cardan.rotation_degrees.z-shaft_before)>10.0,
            "Cardan cross rotates while wheels travel")
        var wheel_front: Node3D=_node(car,"RuedaMotorizadaP06_1_0")
        _check(absf(wheel_front.rotation_degrees.y)>7.0,
            "actual tire, knuckle and steering linkage turn together")
        _check(Rig.pose(car,"move_turn",0.70),
            "universal joints and tie rods follow continuous motion")
        Rig.restore(car)
        _check(right.transform.origin.distance_to(baseline.origin)<0.003,
            "linkage returns exactly to original wheel alignment")

        var panel: Node3D=_node(car,Underside.PANEL_BROKEN)
        var rear_cardan: Node3D=_node(car,Underside.SHAFT_BROKEN)
        var damaged: Node3D=_node(car,"P06V15_PlanchaVDesgarrada")
        var snapped: Node3D=_node(car,"P06V15_CardanQuebrado")
        var wreck: Node3D=_node(car,Underside.WRECK)
        _check(panel.visible and rear_cardan.visible and not wreck.visible,
            "factory pristine underbody has all solid protected links")
        for stage in range(5):
            _check(V3.apply_stage(car,stage),"base stage")
            _check(V6.set_stage(car,stage),"V6 stage")
            _check(V7.set_stage(car,stage),"V7 3D bend")
            _check(V10.set_stage(car,stage),"V10 rear")
            _check(V11.set_stage(car,stage),"V11 wheel guards")
            _check(V12.set_stage(car,stage),"V12 turret")
            _check(V13.set_stage(car,stage),"V13 paint wear")
            _check(Wheel.set_stage(car,stage),"V14 wheels")
            _check(Underside.set_stage(car,stage),"V15 underbody")
            _check(int(car.get_meta(Underside.STAGE,-1))==stage,
                "cosmetic underbody has exact damage state %d" % stage)
            _check(panel.visible==(stage<2),
                "underside panel becomes displaced at moderate damage")
            _check(rear_cardan.visible==(stage<3),
                "rear Cardan hides if transmission shears off")
            _check(damaged.visible==(stage>=2 and stage<4),
                "bent plate becomes exposed at medium/critical damage")
            _check(snapped.visible==(stage==3),
                "fractured shafts appear only in critical damage")
            _check(wreck.visible==(stage==4),
                "destroyed 6x6 leaves a detached differential")
            _check(hull.visible==(stage<4),
                "normal underside disappears at complete destruction")
        _check(V3.apply_stage(car,0),"repair early effects")
        _check(V6.set_stage(car,0),"repair V6")
        _check(V7.set_stage(car,0),"repair V7")
        _check(V10.set_stage(car,0),"repair V10")
        _check(V11.set_stage(car,0),"repair V11")
        _check(V12.set_stage(car,0),"repair V12")
        _check(V13.set_stage(car,0),"repair V13")
        _check(Wheel.set_stage(car,0),"repair V14")
        _check(Underside.set_stage(car,0),"repair V15")
        _check(panel.visible and rear_cardan.visible and not wreck.visible,
            "entire underside restored without recreating geometry")
        _check(Underside.set_enabled(car,false),
            "historic V3 comparison hides V15 frame")
        _check(not hull.visible and not wreck.visible,
            "both intact and wreck additions disappear in comparison")
        _check(Underside.set_enabled(car,true),
            "re-enable complete physical underbody")
        _check(hull.visible and not wreck.visible,
            "pristine 6x6 drivetrain returns correctly")
        car.queue_free()
        await process_frame
    _check(factions.size()==8,
        "all approved faction colors remain distinct on underside armor")
    if failures>0:
        push_error("P06 V15: %d physical geometry checks failed" % failures)
        quit(1)
        return
    print("PASS P06 V15: three axle differentials, transfer case, Cardan motion, six V-shaped belly plates, independent steering links, 8 paints and reversible wrecks")
    quit(0)
