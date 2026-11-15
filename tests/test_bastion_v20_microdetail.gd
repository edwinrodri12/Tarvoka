extends SceneTree

# P06 V20 physical microdetail QA (Godot 4.3); not a performance test.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V14 = preload("res://scripts/ui/APCWheelV14.gd")
const V19 = preload("res://scripts/ui/APCUnifiedFlankV19.gd")
const V20 = preload("res://scripts/ui/APCMicrodetailV20.gd")
const Rig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failed: int=0

func _check(ok: bool, label: String) -> void:
    if not ok:
        failed+=1
        push_error("BASTION V20 MICRODETAIL: "+label)

func _find(model: Node3D,name: String) -> Node3D:
    return model.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var faction_colors: Dictionary={}
    for faction in range(8):
        var car: Node3D=Models.build("apc",faction,true,14)
        _check(car!=null,"full 6x6 model for faction %d" % faction)
        if car==null:
            continue
        root.add_child(car)
        _check(bool(car.get_meta(V19.FLAG,false)) and
            bool(car.get_meta(V20.FLAG,false)) and
            bool(car.get_meta(V14.FLAG,false)),
            "latest 3D finery sits above verified V19 and moving V14 tires")
        var welds: Node3D=_find(car,V20.WELDS)
        var fasteners: Node3D=_find(car,V20.FASTENERS)
        var light: Node3D=_find(car,V20.LIGHT)
        var medium: Node3D=_find(car,V20.MEDIUM)
        var critical: Node3D=_find(car,V20.CRITICAL)
        var wreck: Node3D=_find(car,V20.WRECK)
        _check(welds!=null and fasteners!=null and
            light!=null and medium!=null and
            critical!=null and wreck!=null,
            "six physical microfinish/damage groups present")
        if welds==null or fasteners==null or light==null or medium==null or critical==null or wreck==null:
            car.queue_free()
            await process_frame
            continue
        _check(welds.get_child_count()==V20.SKIRT_GROUPS,
            "exactly four skirt weld groups")
        _check(fasteners.get_child_count()==V20.WHEEL_GROUPS,
            "exactly six static wheel arch finish groups")
        for side in [-1,1]:
            for gap in range(2):
                var group: Node3D=_find(car,
                    "P06V20_CosturaPuente_%d_%d" % [side,gap])
                _check(group!=null and group.get_parent()==welds,
                    "skirt microdetail attached to real hull")
                if group!=null:
                    _check(group.get_child_count()==10,
                        "two sculpted weld beads, six bolt meshes and two colored returns")
                    for i in range(V20.RIVETS_PER_SKIRT):
                        var name: String="P06V20_PernoFaldon_%d_%d_%d" % [side,gap,i]
                        var head: MeshInstance3D=_find(group,name+"_Hex") as MeshInstance3D
                        var washer: MeshInstance3D=_find(group,name+"_Arandela") as MeshInstance3D
                        _check(head!=null and washer!=null and
                            head.mesh is CylinderMesh and
                            (head.mesh as CylinderMesh).radial_segments==6,
                            "each skirt fastener has hex cap and physical washer")
                        if head!=null:
                            _check(head.position.x*float(side)>0,
                                "right and left bolt heads face away from hull")
            for axle in range(3):
                var ring: Node3D=_find(car,
                    "P06V20_RemachesArco_%d_%d" % [side,axle])
                var tire: Node3D=_find(car,
                    "RuedaMotorizadaP06_%d_%d" % [side,axle])
                _check(ring!=null and tire!=null,
                    "six wheel hardware groups and rotating tires")
                if ring!=null and tire!=null:
                    _check(ring.get_child_count()==7,
                        "three washers, three hex heads and one static brace weld")
                    _check(ring.get_parent()==fasteners and
                        not tire.is_ancestor_of(ring),
                        "bolt metalwork never rotates with tire")
        var first: Node3D=_find(car,"P06V20_CosturaPuente_-1_0")
        if first!=null:
            var trim: MeshInstance3D=_find(first,
                "P06V20_RematePintado_-1_0_-1") as MeshInstance3D
            if trim!=null and trim.material_override is StandardMaterial3D:
                faction_colors[(trim.material_override as StandardMaterial3D).albedo_color.to_html()]=true
            else:
                _check(false,"faction-coated trim exists on left skirt")
        var wheel: Node3D=_find(car,"RuedaMotorizadaP06_1_0")
        var arch: Node3D=_find(car,"P06V20_RemachesArco_1_0")
        var wheel_rest: Transform3D=wheel.transform
        var arch_rest: Transform3D=arch.transform
        _check(Rig.pose(car,"move_turn",0.62),
            "6x6 tire steering still moves through full art stack")
        _check(wheel.transform!=wheel_rest and arch.transform==arch_rest,
            "wheel steers but its tiny bolts stay fixed to body")
        Rig.restore(car)
        var mid: Node3D=_find(car,V20.MID_RIGHT)
        var rear: Node3D=_find(car,V20.REAR_RIGHT)
        var front: Node3D=_find(car,V20.FRONT_LEFT)
        for stage in range(5):
            _check(V19.set_stage(car,stage) and V20.set_stage(car,stage),
                "V20 visual stage %d changes with V19 fracture" % stage)
            _check(welds.visible==(stage<4) and
                fasteners.visible==(stage<4),
                "clean welds hidden after total destruction")
            _check(mid.visible==(stage<2) and
                rear.visible==(stage<3) and front.visible==(stage<3),
                "welds disappear when their corresponding plate tears off")
            _check(light.visible==(stage>=1 and stage<4),
                "light surface chips do not appear on pristine or wrecked hull")
            _check(medium.visible==(stage>=2 and stage<4),
                "moderate broken weld appears without clean central bolts")
            _check(critical.visible==(stage==3),
                "critical side damage replaces intact front/rear details")
            _check(wreck.visible==(stage==4),
                "collapsed metal only at final damage stage")
        _check(V20.set_stage(car,0) and V19.set_stage(car,0),
            "full repair re-seals miniature geometry")
        _check(mid.visible and rear.visible and front.visible and
            not light.visible and not medium.visible and
            not critical.visible and not wreck.visible,
            "all small parts and their paints restored on repair")
        _check(V20.set_enabled(car,false),
            "historical V3 comparison can hide latest microgeometry")
        _check(not welds.visible and not fasteners.visible
            and not wreck.visible and not light.visible,
            "old-version view is clean from V20 embellishments")
        _check(V20.set_enabled(car,true) and welds.visible
            and fasteners.visible,"revert old comparison to full V20 detail")
        car.queue_free()
        await process_frame
    _check(faction_colors.size()==8,
        "eight existing faction finishes remain distinct")
    if failed>0:
        push_error("BASTION V20: %d model errors" % failed)
        quit(1)
        return
    print("PASS BASTION V20: 4 physical skirt weld groups, 6 fixed-wheel fastener assemblies, eight faction paints, five break/repair levels, real 6x6 articulation and historical comparison")
    quit(0)
