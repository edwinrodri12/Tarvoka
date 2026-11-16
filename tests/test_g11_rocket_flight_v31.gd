extends SceneTree

# G11 V31 checks the real BattleTerrain3D renderer, not a concept image:
# 4 native biomes x two approved faction colors, 12 real nozzles,
# exactly 2 batches for body+smoke, reversible pod recoil and 0 gameplay writes.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const Actions = preload("res://scripts/ui/G11BattleActionsV29.gd")
const Trails = preload("res://scripts/ui/G11RocketTrailsV30.gd")
const Art = preload("res://scripts/ui/G11RocketFlightV31.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
var failures: int=0

func _check(ok: bool,why: String)->void:
    if not ok:
        failures+=1
        push_error("G11 V31 actual salvo QA: "+why)

func _initialize()->void:
    call_deferred("_run")

func _run()->void:
    var view:=SubViewport.new()
    view.size=Vector2i(960,680)
    view.own_world_3d=true
    root.add_child(view)
    var rocket:=Art.rocket_mesh()
    var bounds:=rocket.get_aabb().size
    _check(bounds.z>0.42 and bounds.z>bounds.x*1.5,
        "V31 has elongated 3D rocket nose/body/fins instead of V30 sphere")
    _check(rocket.get_surface_count()==1,
        "all metal rocket faces/fins remain one mesh surface")
    _check(Art.smoke_color(0.018).a>Art.smoke_color(0.28).a and
        Art.smoke_color(Art.SMOKE_FADE_TIME).a<0.001,
        "smoke fades gradually instead of staying opaque")
    _check(Art.recoil(0.0,Actions.SHOT_STEP,Actions.SHOT_COUNT)>0.019 and
        Art.recoil(-0.02,Actions.SHOT_STEP,Actions.SHOT_COUNT)==0.0,
        "recoil is small and only active after launch")
    for biome in Biomes.CHOICES:
        for faction in [0,6]:
            var battle:=Context.build_scene(faction,biome)
            _check(battle!=null,"real four-biome mixed-unit 3D scene")
            if battle==null:
                continue
            view.add_child(battle)
            await process_frame
            var actions:=battle.find_child(
                "G11V29_AccionesBatalla",true,false) as Actions
            var shooter:=battle.find_child(
                "Unidad3D_G11-H",true,false) as Node3D
            var nearby:=battle.find_child(
                "Unidad3D_Tank-H",true,false) as Node3D
            var rival:=battle.find_child(
                "Unidad3D_G11-E",true,false) as Node3D
            _check(actions!=null and shooter!=null and
                nearby!=null and rival!=null,"all authentic existing units visible")
            if actions==null or shooter==null or nearby==null or rival==null:
                battle.queue_free()
                await process_frame
                continue
            var original: Dictionary=battle.get_meta("original_state",{})
            var snapshot: Dictionary=original.duplicate(true)
            var neighbor_pose: Transform3D=nearby.transform
            var enemy_pose: Transform3D=rival.transform
            var shooter_at: Vector3=shooter.position
            var rack:=shooter.find_child(Mobile.POD,true,false) as Node3D
            var rack_at: Vector3=rack.position
            var before_meshes: int=Models.inspect_meshes(shooter)
            _check(not actions.play("UNKNOWN-G11","attack",shooter_at),
                "no fog-hidden or phantom missiles can be spawned")
            _check(actions.play("G11-H","attack",shooter_at,
                Vector2i(1,-1)),"visual salvo starts on same real G11 model")
            actions.set_process(false)
            var heads:=rack.find_child(
                Trails.HEADS,false,false) as MultiMeshInstance3D
            var smoke:=rack.find_child(
                Trails.TRAILS,false,false) as MultiMeshInstance3D
            _check(heads!=null and smoke!=null,
                "same original 2 pooled G11 V30 effects reused by V31")
            if heads!=null and smoke!=null:
                _check(heads.multimesh.instance_count==Trails.SLOTS and
                    smoke.multimesh.instance_count==Trails.SLOTS,
                    "five rocket bodies and five smoke instances, no extra draw batches")
                _check(heads.multimesh.mesh is ArrayMesh and
                    smoke.multimesh.mesh is SphereMesh and
                    smoke.multimesh.use_colors,
                    "3D finned missiles and per-instance evolving translucent smoke")
                actions.advance(Actions.FIRST_SHOT+0.020)
                _check(heads.visible and smoke.visible,
                    "first fired rocket and its smoke visible at correct muzzle")
                _check(rack.position.z<rack_at.z and
                    rack_at.z-rack.position.z<=Art.RECOIL_MAX_M+0.0001,
                    "subtle rearward rack-only recoil does not displace entire G11")
                var shade_start: Color=smoke.multimesh.get_instance_color(0)
                _check(shade_start.a>0.15,
                    "immediate plume opacity is visible at tactical camera scale")
                actions.advance(Actions.SHOT_STEP*3.1)
                _check(heads.visible and smoke.visible,
                    "four simultaneous rockets remain pooled during salvo")
                _check(int(rack.get_meta(
                    "tarvoka_g11_v30_active_rocket_count",-1))>=3,
                    "five-slot trail system can show multiple consecutive flights")
                var first_move: Vector3=heads.multimesh.get_instance_transform(0).origin
                _check(first_move.z>0.05,
                    "live rocket extends from the actual 12-tube 3D launcher")
                _check(Models.inspect_meshes(shooter)==before_meshes,
                    "new missile fins and smoke never add independent MeshInstances")
            actions.advance(Actions.ATTACK_TIME)
            _check(not actions.active() and rack.position.is_equal_approx(
                rack_at),"every pod-recoil displacement restored after salvo")
            if heads!=null and smoke!=null:
                _check(not heads.visible and not smoke.visible,
                    "pooled rocket effects fully hidden after last shot")
            _check(shooter.position.is_equal_approx(shooter_at) and
                nearby.transform==neighbor_pose and rival.transform==enemy_pose,
                "vehicles and neighboring units are not displaced by launch visuals")
            _check(original==snapshot,
                "no fog, HP, fuel, ammunition, attack or game state writes")
            view.remove_child(battle)
            battle.queue_free()
            await process_frame
    if failures>0:
        push_error("G11 V31 original 3D rocket QA FAILED: %d" % failures)
        quit(1)
        return
    print("PASS G11 V31: finned 3D rockets, translucent staged smoke and 22mm restored launcher recoil, 4 biomes x 2 factions, 2 pooled batches, 12 mouths and all combat stats unchanged")
    quit(0)
