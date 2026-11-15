extends SceneTree

# Native P06 V18 wheelwell geometry and reversible cosmetics; NOT FPS QA.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Wheel = preload("res://scripts/ui/APCWheelV14.gd")
const V17 = preload("res://scripts/ui/APCContourV17.gd")
const V18 = preload("res://scripts/ui/APCWheelwellV18.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failed: int = 0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failed+=1
        push_error("P06 V18 3D: "+label)

func _n(root_node: Node3D, label: String) -> Node3D:
    return root_node.find_child(label,true,false) as Node3D

func _solid(n: Node3D) -> bool:
    return n is MeshInstance3D and (n as MeshInstance3D).mesh is ArrayMesh and (
        (n as MeshInstance3D).mesh as ArrayMesh).surface_get_array_len(0)==36

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var paints: Dictionary = {}
    for faction in range(8):
        var model: Node3D=Models.build("apc",faction,true,14)
        _check(model!=null,"build P06 faction %d" % faction)
        if model==null:
            continue
        root.add_child(model)
        _check(bool(model.get_meta(V18.FLAG,false)) and
            bool(model.get_meta(V17.FLAG,false)) and
            bool(model.get_meta(Wheel.FLAG,false)),
            "V18 is attached after V14/V17 full-detail sculpt")
        var body: Node3D=_n(model,V18.BODY)
        var liners: Node3D=_n(model,V18.ARCHES)
        var damage: Node3D=_n(model,V18.DAMAGE)
        var wreck: Node3D=_n(model,V18.WRECK)
        _check(body!=null and liners!=null and damage!=null and wreck!=null,
            "two inter-axle bridges and six arc shields have own groups")
        if body==null or liners==null or damage==null or wreck==null:
            model.queue_free()
            await process_frame
            continue
        var paint_node: MeshInstance3D=_n(
            model,"P06V18_PanelPuente_-1_0") as MeshInstance3D
        if paint_node!=null and paint_node.material_override is StandardMaterial3D:
            paints[(paint_node.material_override as StandardMaterial3D).albedo_color.to_html()] = true
        else:
            _check(false,"faction-tinted inter-axle plate exists")
        for side in [-1,1]:
            for axle in range(3):
                var wheel: Node3D=_n(model,
                    "RuedaMotorizadaP06_%d_%d" % [side,axle])
                var liner: Node3D=_n(model,
                    "P06V18_ArcoInterior_%d_%d" % [side,axle])
                _check(wheel!=null and liner!=null,
                    "axle %d side %d wheel and fixed liner" % [axle,side])
                if wheel==null or liner==null:
                    continue
                _check(liner.get_parent()==liners and not wheel.is_ancestor_of(liner),
                    "fender liner is NOT a rotating/steering tire descendant")
                _check(float(liner.get_meta(
                    "tarvoka_p06_v18_radial_clearance",0.0))>=0.05,
                    "wheelwell nominal radial gap >= 50mm at axle %d" % axle)
                _check(liner.get_child_count()==V18.ARCH_SEGMENTS+1,
                    "six real curved 3D pieces and one splash shield")
                for segment in range(V18.ARCH_SEGMENTS):
                    _check(_solid(_n(liner,
                        "P06V18_CurvaGuardapolvo_%d_%d_%d" %
                        [side,axle,segment])),
                        "inner curved guard is a closed volume")
            for gap in range(2):
                _check(_solid(_n(model,
                    "P06V18_PanelPuente_%d_%d" % [side,gap])),
                    "four sealed faction-color armor skirts")
                _check(_solid(_n(model,
                    "P06V18_BiselInferior_%d_%d" % [side,gap])),
                    "four solid 3D bottom skirt bevels")
        var wheel0: Node3D=_n(model,"RuedaMotorizadaP06_1_0")
        var liner0: Node3D=_n(model,"P06V18_ArcoInterior_1_0")
        var wheel_start: Transform3D=wheel0.transform
        var liner_start: Transform3D=liner0.transform
        _check(Rig.pose(model,"move_turn",0.52),
            "V18 does not disrupt 6x6 rotating wheels and live steering")
        _check(wheel0.transform!=wheel_start,
            "right-front wheel actually turns and compresses")
        _check(liner0.transform==liner_start,
            "stationary underfender does not rotate or compress with tire")
        Rig.restore(model)
        _check(wheel0.transform.origin.distance_to(
            wheel_start.origin)<0.002,
            "V14 wheels return to centered position after restoration")
        var mid: Node3D=_n(model,V18.MID_PANEL)
        var rear: Node3D=_n(model,V18.REAR_PANEL)
        var front: Node3D=_n(model,V18.FRONT_LINER)
        var torn_mid: Node3D=_n(model,V18.MID_TORN)
        var torn_rear: Node3D=_n(model,V18.REAR_TORN)
        var torn_front: Node3D=_n(model,V18.FRONT_TORN)
        for stage in range(5):
            _check(V18.set_stage(model,stage),
                "V18 cosmetic stage %d accepted" % stage)
            var intact: bool=stage<4
            _check(body.visible==intact and liners.visible==intact
                and damage.visible==intact and wreck.visible==(stage==4),
                "proper collapse leaves wreck only on stage 4")
            _check(mid.visible==(stage<2),
                "right middle whole panel hides once torn at moderate damage")
            _check(rear.visible==(stage<3) and front.visible==(stage<3),
                "critical damaged right rear and left front disappear")
            _check(torn_mid.visible==(stage>=2 and stage<4),
                "bent medium panel replaces entire original panel")
            _check(torn_rear.visible==(stage==3) and
                torn_front.visible==(stage==3),
                "critical state produces real displaced rear/front shards")
        _check(V18.set_stage(model,0),
            "repair pristine plating")
        _check(mid.visible and rear.visible and front.visible and
            not torn_mid.visible and not torn_rear.visible and
            not torn_front.visible and not wreck.visible,
            "full repair seals all panels and removes real 3D damage")
        _check(V18.set_enabled(model,false),
            "historical V3 comparison disabled new sculpture")
        _check(not body.visible and not liners.visible and
            not damage.visible and not wreck.visible,
            "all V18 nodes hidden for authentic old version")
        _check(V18.set_enabled(model,true) and
            body.visible and liners.visible,
            "return to sculpt V18 without rebuilding")
        model.queue_free()
        await process_frame
    _check(paints.size()==8,
        "eight official faction paints remain distinct")
    if failed>0:
        push_error("P06 V18 has %d failed native model assertions" % failed)
        quit(1)
        return
    print("PASS BASTION V18: six static wheelwell volumes, 4 solid inter-axle skirts, 50mm tire clearance, moving 6x6 steering, 8 faction paints, five 3D damage stages and full repair")
    quit(0)
