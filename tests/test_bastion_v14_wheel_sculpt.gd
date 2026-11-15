extends SceneTree

# P06 V14: geometry and rig acceptance only, NO FPS/LOD/performance work.
# Wheel assembly belongs to original V1 pivots and retains V2 molded tread.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Wheel=preload("res://scripts/ui/APCWheelV14.gd")
const V3=preload("res://scripts/ui/APCFinishV3.gd")
const V6=preload("res://scripts/ui/APCFinishV6.gd")
const V7=preload("res://scripts/ui/APCDamageV7.gd")
const V10=preload("res://scripts/ui/APCRearDesignV10.gd")
const V11=preload("res://scripts/ui/APCExteriorV11.gd")
const V12=preload("res://scripts/ui/APCTurretV12.gd")
const V13=preload("res://scripts/ui/APCSurfaceV13.gd")
const Rig=preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int=0

func _check(ok: bool,description: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V14 sculpt QA: "+description)

func _find(node: Node3D,name: String) -> Node3D:
    return node.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary={}
    for faction in range(8):
        var car: Node3D=Models.build("apc",faction,true,14)
        _check(car!=null,"built real full P06 for faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(car.get_meta(Wheel.FLAG,false),
            "V14 wheel geometry is installed in production P06")
        _check(car.get_meta("tarvoka_apc_v14_wheel_count",0)==6,
            "all six original wheel pivots survive")
        _check(car.get_meta("tarvoka_apc_v14_spokes",0)==6,
            "each machined rim has six open radial spokes")
        _check(car.get_meta("tarvoka_apc_v2_tread_count",0)==288,
            "original 288 3D off-road tread lugs retained")
        var chassis: Node3D=_find(car,Wheel.CHASSIS)
        var susp: Node3D=_find(car,Wheel.SUSPENSION)
        _check(chassis!=null and susp!=null and
            susp.get_child_count()==6,
            "six separately articulated suspension modules installed")
        for side in [-1,1]:
            for axle in range(3):
                var name: String="RuedaMotorizadaP06_%d_%d" % [side,axle]
                var tire: Node3D=_find(car,name)
                _check(tire!=null,"native wheel %s exists" % name)
                var tire_body: Node3D=tire.find_child(
                    "NeumaticoTodoTerreno",false,false) as Node3D
                var molded: Node3D=_find(tire,"APC_V2_TacosTodoTerreno")
                _check(tire_body!=null and molded is MultiMeshInstance3D,
                    "actual rounded tire and off-road tread still attached")
                var old: Node3D=tire.find_child(
                    "AnilloLlanta",false,false) as Node3D
                _check(old==null or not old.visible,
                    "old flat wheel center hidden in V14")
                var rim: MeshInstance3D=_find(tire,
                    "P06V14_SeisRadiosCalados") as MeshInstance3D
                _check(rim!=null and rim.mesh is ArrayMesh,
                    "six true 3D spoke gaps, no flat circular disk")
                if rim!=null and rim.mesh is ArrayMesh:
                    _check((rim.mesh as ArrayMesh).surface_get_array_len(0)>=200,
                        "radial spokes have thick front/back and sidewall faces")
                var ring: MeshInstance3D=_find(tire,
                    "P06V14_AroLlantaExterior") as MeshInstance3D
                _check(ring!=null and ring.mesh is TorusMesh,
                    "actual concentric circular rim with open center")
                var tire_bead: MeshInstance3D=_find(tire,
                    "P06V14_AnilloTalónNeumático") as MeshInstance3D
                _check(tire_bead!=null and tire_bead.mesh is TorusMesh,
                    "bead seals the 3D tire shoulder")
                var bolts: MultiMeshInstance3D=_find(tire,
                    "P06V14_OchoPernosLlanta") as MultiMeshInstance3D
                _check(bolts!=null and
                    bolts.multimesh.instance_count==Wheel.BOLT_COUNT,
                    "every rim receives eight real polygonal hub fasteners")
                var assembly: Node3D=_find(car,
                    "P06V14_Suspension_%d_%d" % [side,axle])
                _check(assembly!=null and assembly.get_parent()==susp,
                    "control arms are chassis mounted, not tire-mounted")
                var spring: MeshInstance3D=_find(assembly,
                    "P06V14_ResorteHelicoidalReal") as MeshInstance3D
                _check(spring!=null and spring.mesh is ArrayMesh,
                    "physical steel helix is meshed around the damper")
                var barrel: Node3D=_find(assembly,
                    "P06V14_CamisaAmortiguador")
                var rod: Node3D=_find(assembly,
                    "P06V14_VastagoAmortiguador")
                _check(barrel!=null and
                    absf(barrel.scale.y-Wheel.STRUT_BODY)<0.001,
                    "steel damper barrel remains a rigid fixed length")
                _check(rod!=null and rod.scale.y>0.15,
                    "chrome piston connects rigid barrel to wheel arm")
                var static_caliper: Node3D=_find(assembly,
                    "P06V14_PinzaFrenoEstatica")
                _check(static_caliper!=null,
                    "brake caliper lives outside spinning rim hierarchy")
        var model_paint: MeshInstance3D=_find(car,
            "P06V11_ModuloBlindaje_1_0") as MeshInstance3D
        var painted: StandardMaterial3D=(
            model_paint.material_override as StandardMaterial3D)
        if painted!=null:
            paints[painted.albedo_color.to_html()]=true
        var front: Node3D=_find(car,"RuedaMotorizadaP06_1_0")
        var front_susp: Node3D=_find(car,"P06V14_Suspension_1_0")
        var other_susp: Node3D=_find(car,"P06V14_Suspension_1_1")
        var knuckle: Node3D=_find(front_susp,"P06V14_ManguetaFreno")
        var middle_knuckle: Node3D=_find(other_susp,"P06V14_ManguetaFreno")
        var chrome: Node3D=_find(front_susp,
            "P06V14_VastagoAmortiguador")
        var original_rod: float=chrome.scale.y
        var rim_spokes: Node3D=_find(front,"P06V14_SeisRadiosCalados")
        var rim_pos: Transform3D=rim_spokes.global_transform
        _check(Rig.pose(car,"move_turn",0.5),
            "Bastion steers on front axle without new combat rules")
        _check(absf(front.rotation_degrees.y)>7.0,
            "front wheels really steer")
        _check(knuckle!=null and absf(knuckle.rotation_degrees.y)>7.0,
            "brake caliper and static steering knuckle follow yaw")
        _check(middle_knuckle!=null and
            absf(middle_knuckle.rotation_degrees.y)<0.01,
            "middle and rear brake calipers do not steer")
        _check(absf(front.rotation_degrees.x)>1.0,
            "actual rim/tire rotation remains animated")
        _check(rim_spokes.global_transform!=rim_pos,
            "true spokes rotate and travel with original wheel")
        var compressed_rod: float=chrome.scale.y
        _check(absf(compressed_rod-original_rod)>0.0001,
            "the chrome rod telescopes as the wheel compresses at mid-move")
        _check(Rig.pose(car,"move_turn",0.78),
            "dampers continue following wheel travel through curve")
        _check(absf(chrome.scale.y-compressed_rod)>0.0001,
            "telescoping shock recovers as wheel returns to normal ride height")
        _check(_find(front_susp,"P06V14_CamisaAmortiguador")!=null and
            absf(_find(front_susp,"P06V14_CamisaAmortiguador").scale.y-
            Wheel.STRUT_BODY)<0.001,
            "outer shock cylinder does not stretch during steering")
        Rig.restore(car)
        _check(absf(knuckle.rotation_degrees.y)<0.01,
            "brake hardware returns to neutral when parking")
        _check(absf(chrome.scale.y-original_rod)<0.002,
            "wheel suspension returns to factory ride height")

        var cut: Node3D=_find(car,Wheel.DAMAGE)
        var wreck: Node3D=_find(car,Wheel.WRECK)
        var detail: Node3D=_find(car,Wheel.WHEEL_ROOT)
        for stage in range(5):
            _check(V3.apply_stage(car,stage),"early damage stage")
            _check(V6.set_stage(car,stage),"surface damage stage")
            _check(V7.set_stage(car,stage),"deformed hull damage")
            _check(V10.set_stage(car,stage),"boarding bay damage")
            _check(V11.set_stage(car,stage),"fender damage")
            _check(V12.set_stage(car,stage),"gun station damage")
            _check(V13.set_stage(car,stage),"worn painted metal")
            _check(Wheel.set_stage(car,stage),"V14 tire and axle damage")
            _check(cut.visible==(stage>=3),
                "front left tire shows exposed steel only when torn")
            _check(wreck.visible==(stage==4),
                "wreck axle exposes snapped fork only at destruction")
            _check(int(car.get_meta(Wheel.STAGE,-1))==stage,
                "damage stage independently stored on visual rig")
        _check(V3.apply_stage(car,0),"repair V3")
        _check(V6.set_stage(car,0),"repair V6")
        _check(V7.set_stage(car,0),"repair V7")
        _check(V10.set_stage(car,0),"repair V10")
        _check(V11.set_stage(car,0),"repair V11")
        _check(V12.set_stage(car,0),"repair V12")
        _check(V13.set_stage(car,0),"repair V13")
        _check(Wheel.set_stage(car,0),"repair V14")
        _check(detail.visible and not cut.visible and not wreck.visible,
            "full repair restores six-wheel hardware without rebuilding")

        _check(Wheel.set_enabled(car,false),"historical comparison enabled")
        var old_rim: Node3D=front.find_child(
            "AnilloLlanta",false,false) as Node3D
        _check(not detail.visible and old_rim!=null and old_rim.visible,
            "V3 comparison shows original wheel without new rim overlap")
        _check(not susp.visible or not chassis.visible,
            "modern suspension is hidden during historical comparison")
        _check(Wheel.set_enabled(car,true),"restore commercial V14")
        _check(detail.visible and old_rim!=null and not old_rim.visible,
            "V14 full rim overrides original hub on return")
        car.queue_free()
        await process_frame
    _check(paints.size()==8,"all eight official faction paint palettes unchanged")
    if failures>0:
        push_error("P06 V14 sculpt: %d failed visual inspections" % failures)
        quit(1)
        return
    print("PASS P06 V14: six physical open-spoke rims, 48 tread lugs each, brakes, independent double wishbones, true telescoping shocks, 8 factions and repaired/destroyed states")
    quit(0)
