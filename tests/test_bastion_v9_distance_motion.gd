extends SceneTree

const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Tactical = preload("res://scripts/ui/APCTacticalLOD8.gd")
const CameraLOD = preload("res://scripts/ui/APCDistanceLODControllerV9.gd")
const HeroRig = preload("res://scripts/ui/APCVisualRigV1.gd")
var failures: int=0

func _check(ok: bool,name: String) -> void:
    if not ok:
        failures+=1
        push_error("P06 V9: "+name)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    _check(Tactical.tier_from_pixels(165.0)==Tactical.LOD_NEAR,
        "large screen silhouette near")
    _check(Tactical.tier_from_pixels(88.0)==Tactical.LOD_MEDIUM,
        "medium projected APC")
    _check(Tactical.tier_from_pixels(28.0)==Tactical.LOD_FAR,
        "tiny projected APC far")
    _check(Tactical.tier_from_pixels(121.0,Tactical.LOD_NEAR)==Tactical.LOD_NEAR,
        "near hysteresis prevents zoom flicker")
    _check(Tactical.tier_from_pixels(59.0,Tactical.LOD_FAR)==Tactical.LOD_FAR,
        "far hysteresis prevents zoom flicker")

    var tactical: Node3D=Models.build("apc",0,false,8)
    root.add_child(tactical)
    var carcass: Node3D=tactical.find_child(
        "CascoBlindadoEsculpidoP06",true,false) as Node3D
    var wheel: MultiMeshInstance3D=tactical.find_child(
        Tactical.WHEELS,true,false) as MultiMeshInstance3D
    var hubs: MultiMeshInstance3D=tactical.find_child(
        Tactical.HUBS,true,false) as MultiMeshInstance3D
    _check(carcass!=null and wheel!=null and hubs!=null,
        "near tactical wheels and real five-ring hull")
    var counts: Array[int]=[]
    for level in range(3):
        _check(Tactical.set_detail(tactical,level),
            "switch tier %d with no mesh rebuilding" % level)
        counts.append(Tactical.visible_surfaces(tactical))
        _check(carcass.visible and wheel.visible,
            "tactical hull and wheels stay visible for tier %d" % level)
        _check(wheel.multimesh.instance_count==6,
            "all six tires stay in view")
        _check(Tactical.draw_surfaces(tactical)<=Tactical.MAX_DRAW_SURFACES,
            "draw budget unchanged across all tiers")
    _check(counts[0]>counts[1] and counts[1]>counts[2],
        "GPU-visible surfaces decrease near-to-far")
    _check(Tactical.set_detail(tactical,Tactical.LOD_NEAR),
        "return to near without rebuilding")
    var initial_tire: Transform3D=wheel.multimesh.get_instance_transform(0)
    var initial_hub: Transform3D=hubs.multimesh.get_instance_transform(0)
    _check(Models.pose_model("apc",tactical,"move_turn",0.50),
        "native tactical cornering pose")
    var turn_tire: Transform3D=wheel.multimesh.get_instance_transform(0)
    var turn_hub: Transform3D=hubs.multimesh.get_instance_transform(0)
    _check(turn_tire.basis!=initial_tire.basis,
        "front tactical tire turns and spins")
    _check(turn_hub.basis!=initial_hub.basis,
        "front steel hub rotates together with tire")
    _check(absf(tactical.rotation_degrees.z)>0.1,
        "hull leans visibly through a turn")
    Models.restore_model_pose("apc",tactical)
    _check(absf(tactical.rotation_degrees.z)<0.01,
        "hull settles after a turn")
    _check(Models.pose_model("apc",tactical,"hit_explosive",0.35),
        "strong impact suspension")
    _check(tactical.position.y<float(tactical.get_meta(
        Tactical.BASE,Vector3.ZERO).y),
        "suspension compresses on blast")
    Models.restore_model_pose("apc",tactical)

    var camera:=Camera3D.new()
    camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    root.add_child(camera)
    var ctrl: Node=CameraLOD.new()
    root.add_child(ctrl)
    ctrl.register(tactical)
    camera.size=4.0
    _check(ctrl.update_now(camera,720.0)>=0 and
        Tactical.detail_tier(tactical)==Tactical.LOD_NEAR,
        "zoomed camera keeps small optical details")
    camera.size=14.0
    _check(ctrl.update_now(camera,720.0)==1 and
        Tactical.detail_tier(tactical)==Tactical.LOD_MEDIUM,
        "medium zoom drops optional optics")
    camera.size=46.0
    _check(ctrl.update_now(camera,720.0)==1 and
        Tactical.detail_tier(tactical)==Tactical.LOD_FAR,
        "wide camera drops hub and small glass")
    camera.size=4.0
    _check(ctrl.update_now(camera,720.0)==1 and
        Tactical.detail_tier(tactical)==Tactical.LOD_NEAR,
        "close zoom restores same native geometry")
    camera.queue_free()
    ctrl.queue_free()
    tactical.queue_free()
    await process_frame

    for faction in range(8):
        var hero: Node3D=Models.build("apc",faction,true,14)
        root.add_child(hero)
        _check(HeroRig.pose(hero,"move_turn",0.50),
            "studio full-sculpt 6x6 cornering for faction %d" % faction)
        var pivot: Node3D=hero.find_child(
            "RuedaMotorizadaP06_1_0",true,false) as Node3D
        var middle: Node3D=hero.find_child(
            "RuedaMotorizadaP06_1_1",true,false) as Node3D
        _check(pivot!=null and middle!=null,
            "real front/middle wheel pivots retained")
        if pivot!=null and middle!=null:
            _check(absf(pivot.rotation_degrees.y)>8.0,
                "front axle steers during curve")
            _check(absf(middle.rotation_degrees.y)<0.01,
                "middle axle does not unrealistically steer")
            _check(pivot.position.y<=0.43,
                "front independent suspension compresses")
        HeroRig.restore(hero)
        if pivot!=null:
            _check(absf(pivot.rotation_degrees.y)<0.01 and
                absf(pivot.position.y-0.43)<0.0001,
                "hero wheel steering/suspension returns to rest")
        hero.queue_free()
        await process_frame
    if failures>0:
        push_error("P06 V9: %d failed checks" % failures)
        quit(1)
        return
    print("PASS P06 V9: 3 camera LOD tiers with hysteresis, matching silhouette, 6 spinning tires/hubs, true steering/suspension in 8 factions")
    quit(0)
