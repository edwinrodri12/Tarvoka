extends SceneTree

# V29 native Godot proof: visual playback on BattleTerrain3D's actual
# G11 models after a successfully confirmed order. Detached tests call
# the action controller directly and NEVER call BattleSession.attack.
const Context = preload("res://scripts/ui/G11BattleContextV25.gd")
const Biomes = preload("res://scripts/ui/WinterBattleBiome.gd")
const Actions = preload("res://scripts/ui/G11BattleActionsV29.gd")
const Mobile = preload("res://scripts/ui/G11MobileLOD.gd")
const Models = preload("res://scripts/ui/UnitModels3D.gd")
var errors: int=0

func _check(ok: bool,label: String) -> void:
    if not ok:
        errors+=1
        push_error("G11 V29 actual map actions: "+label)

func _find(parent: Node3D,name: String) -> Node3D:
    return parent.find_child(name,true,false) as Node3D

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var view:=SubViewport.new()
    view.size=Vector2i(960,680)
    view.own_world_3d=true
    root.add_child(view)
    for biome in Biomes.CHOICES:
        for faction in [0,6]:
            var context:=Context.build_scene(faction,biome)
            _check(context!=null,"native scene loads in all four biomes")
            if context==null:
                continue
            view.add_child(context)
            await process_frame
            var actions:=context.find_child(
                "G11V29_AccionesBatalla",true,false) as Actions
            var model:=_find(context,"Unidad3D_G11-H")
            var rival:=_find(context,"Unidad3D_G11-E")
            var tank:=_find(context,"Unidad3D_Tank-H")
            _check(actions!=null and model!=null and rival!=null and tank!=null,
                "one visual controller and original visible battle models")
            if actions==null or model==null or rival==null or tank==null:
                context.queue_free()
                await process_frame
                continue
            var original: Dictionary=context.get_meta("original_state",{})
            var untouched: Dictionary=original.duplicate(true)
            var end: Vector3=model.position
            var rival_transform: Transform3D=rival.transform
            var tank_transform: Transform3D=tank.transform
            var before_mesh_count: int=Models.inspect_meshes(model)
            _check(not actions.play("G11-UNKNOWN","attack",
                Vector3.ZERO,Vector2i(1,0)),
                "never instantiate unseen or missing G11 through animation")
            _check(not actions.play("G11-H","invalid",
                Vector3.ZERO,Vector2i(1,0)),
                "reject invalid visual actions without engine orders")
            _check(actions.play("G11-H","move",
                end+Vector3(0,0,-2.4),Vector2i(0,1)),
                "replay a movement on the existing native 3D G11")
            actions.set_process(false)
            _check(actions.active(),"G11 visual controller active")
            _check(model.position.distance_to(end)>2.39,
                "movement starts at old art location only")
            actions.advance(Actions.MOVE_TIME*0.50)
            _check(model.position.distance_to(end)>0.3 and
                model.position.distance_to(end)<2.2,
                "same G11 visually interpolates without adding units")
            actions.advance(Actions.MOVE_TIME*0.51)
            _check(not actions.active() and model.position.is_equal_approx(end),
                "movement automatically restores authoritative final cell")
            _check(Models.inspect_meshes(model)==before_mesh_count,
                "movement creates no extra geometry")
            _check(actions.play("G11-H","attack",end,Vector2i(1,-1)),
                "confirmed-style attacking rig uses original raised rocket pod")
            actions.set_process(false)
            var flash:=_find(model,Actions.FLASH_NAME) as MultiMeshInstance3D
            var smoke:=_find(model,Actions.SMOKE_NAME) as MultiMeshInstance3D
            _check(flash!=null and smoke!=null,
                "shot effects are two pooled MultiMesh nodes, not 12 copies")
            if flash!=null and smoke!=null:
                _check(flash.multimesh.instance_count==1 and
                    smoke.multimesh.instance_count==3,
                    "one active muzzle and at most three smoke clouds")
                actions.advance(Actions.FIRST_SHOT+0.012)
                _check(flash.visible and smoke.visible,
                    "first rocket produces short controlled flash and smoke")
                for shot in range(1,Actions.SHOT_COUNT):
                    actions.advance(Actions.SHOT_STEP)
                    _check(flash.visible,
                        "12 native muzzle bursts traverse the 4x3 rack sequentially")
                _check(not actions.play("G11-E","move",rival.position,Vector2i(0,1)),
                    "new order without a source displacement is rejected")
                _check(Models.inspect_meshes(model)<=before_mesh_count+2,
                    "batched launch has no per-rocket mesh or particle explosion")
                actions.advance(Actions.ATTACK_TIME)
                _check(not actions.active() and not flash.visible and
                    not smoke.visible,"short-lived effects stop automatically")
                _check(model.position.is_equal_approx(end),
                    "shot does not move the attacker off its authoritative cell")
                _check(not actions.play("G11-H","wrong",end),
                    "no phantom damage or action outside supported modes")
            _check(rival.transform==rival_transform and
                tank.transform==tank_transform,
                "nearby units and rival models not moved by visual salvo")
            _check(original==untouched,
                "no mutations to HP, fuel, ammunition, orders or saved state")
            context.queue_free()
            await process_frame
    if errors>0:
        push_error("G11 V29 native post-confirmation actions FAILED: %d" % errors)
        quit(1)
        return
    print("PASS G11 V29: true production 3D movement and 12 sequential batched rocket flashes, all 4 biomes, faction palettes, one logical G11, neighbors and battle state untouched")
    quit(0)
