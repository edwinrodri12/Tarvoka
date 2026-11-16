extends SceneTree

# Native Godot 4.3 V32: existing twelve wheel pivots and two track belts
# react to turns and bounded artificial terrain slopes, while battle state,
# hull rest pose, LOD and approved mesh counts remain unchanged.
const Models=preload("res://scripts/ui/UnitModels3D.gd")
const Gear=preload("res://scripts/ui/G11RunningGearV32.gd")
const Rig=preload("res://scripts/ui/G11VisualRig3D.gd")
const Mobile=preload("res://scripts/ui/G11MobileLOD.gd")
const Tactical=preload("res://scripts/ui/G11TacticalReadabilityV24.gd")
const Context=preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes=preload("res://scripts/ui/WinterBattleBiome.gd")
const Actions=preload("res://scripts/ui/G11BattleActionsV29.gd")
var fails: int=0

func _check(ok: bool,description: String)->void:
    if not ok:
        fails+=1
        push_error("G11 V32 genuine wheels/track/slope QA: "+description)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    _check(Gear.wheel_safe() and
        Gear.MOBILE_BELT_CLEARANCE>=0.014,
        "wheel bounce never reaches the inner track radius")
    _check(Gear.turn_ratio(Vector2i(0,-1))==0.0 and
        Gear.turn_ratio(Vector2i(1,-1))>0 and
        Gear.turn_ratio(Vector2i(-1,-1))<0,
        "left/straight/right pose has deterministic opposite track speeds")
    for faction in range(8):
        var hero:=Models.build("mlrs",faction,true,13)
        _check(hero!=null and Rig.has_rig(hero),
            "approved hero V23 sculpture remains in each faction")
        if hero==null:
            continue
        var count_before: int=Models.inspect_meshes(hero)
        _check(Rig.pose(hero,"move",0.50,Vector2i(0,-1)),
            "original V23 track and wheel straight animation remains available")
        var left:=hero.find_child(
            "G11V2_OrugaAnimada_-1",true,false) as MultiMeshInstance3D
        var right:=hero.find_child(
            "G11V2_OrugaAnimada_1",true,false) as MultiMeshInstance3D
        var original_left: Transform3D=left.multimesh.get_instance_transform(0)
        var original_right: Transform3D=right.multimesh.get_instance_transform(0)
        _check(Rig.pose(hero,"move",0.50,Vector2i(1,-1)),
            "turn pose retains the authentic 92 animated individual tread shoes")
        var pivot_left:=hero.find_child(
            "G11_RuedaPivot_-1_0",true,false) as Node3D
        var pivot_right:=hero.find_child(
            "G11_RuedaPivot_1_0",true,false) as Node3D
        _check(pivot_left!=null and pivot_right!=null and
            pivot_left.rotation_degrees.x!=pivot_right.rotation_degrees.x,
            "left and right road wheels have different turning speeds")
        _check(left.multimesh.get_instance_transform(0)!=original_left and
            right.multimesh.get_instance_transform(0)!=original_right,
            "both tread belts flow differentially rather than sliding through wheels")
        _check(Models.inspect_meshes(hero)==count_before,
            "no new or duplicated wheel, chain or suspension geometry")
        _check(bool(hero.get_meta("tarvoka_g11_v30_redundant_rear_square_removed",
            false)),"approved V30 rear overlap removal is preserved")
        _check(Rig.pose(hero,"idle",1.0),
            "rest pose stops wheel spinning and restores suspension")
        _check(pivot_left.rotation_degrees.is_equal_approx(Vector3.ZERO) and
            pivot_right.rotation_degrees.is_equal_approx(Vector3.ZERO),
            "V23 wheel hubs restore the exact original angle after turning")
        hero.free()
        for lod in [8,10]:
            var tactical:=Models.build("mlrs",faction,false,lod)
            _check(tactical!=null and Mobile.has_model(tactical),
                "real LOD8 and LOD10 battle model remain available")
            if tactical==null:
                continue
            var original_count: int=Models.inspect_meshes(tactical)
            var base_rotation: Vector3=tactical.rotation_degrees
            _check(Gear.pose_mobile(tactical,0.46,Vector2i(1,-1),0.22),
                "one moving G11 rotates existing wheels and tilts within limits")
            var wheels:=tactical.find_child(
                Gear.WHEEL_BATCH,true,false) as MultiMeshInstance3D
            if lod==10:
                _check(wheels!=null and wheels.multimesh!=null and
                    wheels.multimesh.instance_count==12,
                    "near LOD drives the same existing batch of 12 wheels")
                if wheels!=null:
                    var a: Transform3D=wheels.multimesh.get_instance_transform(0)
                    var b: Transform3D=wheels.multimesh.get_instance_transform(6)
                    _check(not a.basis.is_equal_approx(b.basis),
                        "near left/right side differential rotation is visible")
                    _check(absf(a.origin.y-Gear.MOBILE_WHEEL_Y)<=
                        Gear.BOUNCE_LIMIT+0.0001,
                        "near suspension never exits original wheel aperture")
            else:
                _check(wheels==null,
                    "far LOD8 creates no invisible wheel batch or draw call")
            _check(absf(tactical.rotation_degrees.x-base_rotation.x)<=
                Gear.MAX_PITCH_DEG+0.0001,
                "slope pitch remains inside safe chassis angle")
            _check(absf(tactical.rotation_degrees.z-base_rotation.z)<=
                Gear.MAX_ROLL_DEG+0.0001,
                "bounce roll remains limited to prevent belt/body clipping")
            _check(Models.inspect_meshes(tactical)==original_count,
                "tactical animated wheels add no extra MeshInstance nodes")
            _check(Mobile.pose(tactical,"idle",1.0),
                "official G11 mobile idle restores all wheel poses")
            _check(tactical.rotation_degrees.is_equal_approx(base_rotation) and
                not tactical.has_meta(Gear.REST_ANGLE),
                "rest state cleans temporary model rotation and meta")
            tactical.free()
    for biome in Biomes.CHOICES:
        var scene:=Context.build_scene(0,biome)
        _check(scene!=null,"production four-biome battle test scene built")
        if scene==null:
            continue
        root.add_child(scene)
        await process_frame
        var controller:=scene.find_child(
            "G11V29_AccionesBatalla",true,false) as Actions
        var g11:=scene.find_child("Unidad3D_G11-H",true,false) as Node3D
        var neighbor:=scene.find_child("Unidad3D_Tank-H",
            true,false) as Node3D
        var opponent:=scene.find_child("Unidad3D_G11-E",
            true,false) as Node3D
        _check(controller!=null and g11!=null and neighbor!=null
            and opponent!=null,"original real battle units remain visible")
        if controller==null or g11==null or neighbor==null or opponent==null:
            scene.queue_free()
            await process_frame
            continue
        var authoritative: Dictionary=scene.get_meta("original_state",{})
        var unchanged: Dictionary=authoritative.duplicate(true)
        var neighbor_at: Transform3D=neighbor.transform
        var opponent_at: Transform3D=opponent.transform
        var final_at: Vector3=g11.position
        var rotation_at: Vector3=g11.rotation_degrees
        _check(controller.play("G11-H","move",
            final_at+Vector3(-1.5,0.22,-1.8),Vector2i(1,1)),
            "post-confirmation presentation supports inclined diagonal turns")
        controller.set_process(false)
        controller.advance(Actions.MOVE_TIME*0.49)
        _check(bool(g11.get_meta(Gear.FLAG,false)) and
            g11.rotation_degrees!=rotation_at,
            "real battle slope turn animates chassis and existing track hubs")
        controller.advance(Actions.MOVE_TIME*0.52)
        _check(not controller.active() and
            g11.position.is_equal_approx(final_at) and
            g11.rotation_degrees.is_equal_approx(rotation_at),
            "end-of-turn battle cell and complete resting pose restored")
        _check(neighbor.transform==neighbor_at and
            opponent.transform==opponent_at,
            "suspension motion never affects neighboring units")
        _check(authoritative==unchanged,
            "no stats, fog, HP, ammo, orders, tile heights or save writes")
        scene.queue_free()
        await process_frame
    if fails>0:
        push_error("G11 V32 wheel suspension movement validation FAILED: %d" % fails)
        quit(1)
        return
    print("PASS G11 V32: 8 faction hero x 92 animated links, 16 authentic LOD8/LOD10 models x 12 original wheels, 4 live battle slope turns, track clearances and unchanged game state")
    quit(0)
