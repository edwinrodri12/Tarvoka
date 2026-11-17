extends SceneTree

# Executed on the same Godot 4.3 scene that is exported at the Pages root,
# after the G09 V32 overlay. Do not test an HTML mock or isolated proxy.
const EXPECTED := {
    "tank":["move","attack","damaged","hit_bullet","hit_explosion",
        "damage_1","damage_2","damage_3","damage_4","damage_0",
        "tank_standalone","stop"],
    "apc":["move","move_turn","turn_turret","attack","open_ramp",
        "close_ramp","hit_bullet","hit_explosive","damage_1",
        "damage_2","damage_3","damage_4","damage_0","p06_fleet_move",
        "p06_fleet_attack","p06_fleet_close","stop"],
    "mlrs":["move","attack","g11_attack_slow","cooldown","g11_turn_left",
        "g11_turn_right","g11_slope","hit_bullet","hit_explosive",
        "damage_1","damage_2","damage_3","damage_4","damage_0",
        "g11_battle_move","g11_battle_attack","g11_battle_close","stop"],
    "aa_mobile":["move","g13_scan","g13_aim_legacy","g13_aim_air",
        "g13_aim_ground","g13_attack_air","g13_attack_ground","stop"],
    "attack_heli":["move","hover","attack","hit_bullet","hit_explosive",
        "damage_1","damage_2","damage_3","damage_4","damage_0","stop"]
}
var failures: int=0

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures+=1
        push_error("ALL STUDIO ANIMATIONS: "+message)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size=Vector2i(960,540)
    var scene: PackedScene=load("res://scenes/UnitArtStudioWeb.tscn") as PackedScene
    _check(scene!=null,"actual Godot scene loads")
    if scene==null:
        quit(1)
        return
    var studio: Control=scene.instantiate() as Control
    root.add_child(studio)
    await process_frame
    var inventory: VBoxContainer=studio.get("studio_animation_inventory") as VBoxContainer
    _check(inventory!=null,"native complete animation inventory exists")
    if inventory==null:
        studio.queue_free()
        quit(1)
        return
    for role in EXPECTED:
        var specs: Array=studio.call("_studio_animation_specs",role)
        var actions: Array[String]=[]
        for spec in specs:
            if spec is Dictionary and spec.has("action"):
                actions.append(str(spec["action"]))
        var unique: Dictionary={}
        for action in actions:
            unique[action]=true
        _check(unique.size()==actions.size(),
            "%s has no repeated animation actions" % role)
        for action in EXPECTED[role]:
            _check(action in actions,
                "%s publicly exposes %s" % [role,action])
        _check(actions.size()==EXPECTED[role].size(),
            "%s does not omit or invent animation choices" % role)
        studio.call("_display_role",role)
        await process_frame
        _check(str(studio.get("_role"))==role,"%s is selected in one Godot scene" % role)
        _check(inventory.is_visible_in_tree(),"%s animation menu visible" % role)
        var button_count: int=0
        for button in inventory.find_children("*","Button",true,false):
            if button is Button:
                button_count+=1
                _check(button.is_visible_in_tree(),
                    "%s has no animations hidden by technical folds" % role)
                _check((button as Button).custom_minimum_size.y>=40,
                    "%s buttons meet 40 px minimum touch height" % role)
        _check(button_count==actions.size(),
            "%s has %d actionable buttons for %d animations" %
            [role,button_count,actions.size()])
        _check(studio.get("studio_animation_role")==role,
            "%s auto refreshes its own animation inventory" % role)
        var model: Node3D=studio.get("model_root") as Node3D
        _check(model!=null,"%s has a real native 3D model" % role)
        if model==null:
            continue
        match role:
            "tank":
                _check(bool(model.get_meta("tarvoka_mbt_tracks_inboard_v31",false)),
                    "central tank retains final inboard V31 tracks")
                _check(bool(model.get_meta("tarvoka_hit_v30",false)),
                    "central tank retains distinct V30 impact rig")
                studio.call("_studio_run_animation","hit_explosion")
                _check(str(studio.get("_animation"))=="hit_explosion",
                    "G09 explosion is native V32, not generic hit")
                studio.call("_studio_run_animation","attack")
                _check(str(studio.get("_animation"))=="attack",
                    "G09 final turret aim and recoil plays")
                studio.call("_studio_run_animation","stop")
            "apc":
                studio.call("_studio_run_animation","open_ramp")
                _check(str(studio.get("_animation"))=="open_ramp",
                    "P06 troop ramp opens from Animar tab")
                studio.call("_studio_run_animation","move_turn")
                _check(str(studio.get("_animation"))=="move_turn",
                    "P06 steering animation exists")
                studio.call("_studio_run_animation","stop")
            "mlrs":
                studio.call("_studio_run_animation","g11_turn_left")
                _check(studio.get("_g11_turn_tween")!=null,
                    "G11 differential turn has a real timed playback")
                studio.call("_studio_run_animation","g11_attack_slow")
                _check(str(studio.get("_g11_animation"))=="attack",
                    "G11 slow rocket salvo activates real native rig")
                _check(float(studio.get("_g11_playback_speed"))<=0.35,
                    "G11 rocket playback speed is actually reduced")
                studio.call("_studio_run_animation","cooldown")
                _check(str(studio.get("_g11_animation"))=="cooldown",
                    "G11 independently accessible cooldown runs")
                studio.call("_studio_run_animation","stop")
            "aa_mobile":
                studio.call("_studio_run_animation","g13_scan")
                _check(str(model.get_meta("tarvoka_g13_v1_pose",""))=="scan",
                    "G13 scans with its native radar")
                _check(studio.get("_g13_v4_tween")!=null,
                    "G13 radar is a timed animation, not a frozen pose")
                studio.call("_studio_run_animation","g13_aim_ground")
                _check(str(model.get_meta("tarvoka_g13_v1_pose",""))=="aim_ground",
                    "G13 terrestrial targeting uses a separate aim pose")
                studio.call("_studio_run_animation","g13_attack_air")
                _check(str(model.get_meta("tarvoka_g13_v1_pose",""))=="attack_air",
                    "G13 animated antiair firing works")
                studio.call("_studio_run_animation","g13_attack_ground")
                _check(str(model.get_meta("tarvoka_g13_v1_pose",""))=="attack_ground",
                    "G13 animated ground firing works")
                studio.call("_studio_run_animation","stop")
            "attack_heli":
                studio.call("_studio_run_animation","hover")
                _check(str(studio.get("_heli_animation"))=="hover",
                    "A01 hover works independently from forward flight")
                studio.call("_studio_run_animation","hit_explosive")
                _check(str(studio.get("_heli_animation"))=="hit_explosive",
                    "A01 heavy-impact playback works")
                studio.call("_studio_run_animation","stop")
    for role in ["line","scout","fighter","destroyer"]:
        _check((studio.call("_studio_animation_specs",role) as Array).is_empty(),
            "%s honestly reports no dedicated animation rig" % role)
    # Single real studio, also keeps full HQ/building catalogue intact.
    studio.call("_studio_jump_category",1)
    await process_frame
    _check(not inventory.visible or not inventory.is_visible_in_tree(),
        "the unit animation list hides while inspecting buildings")
    studio.queue_free()
    await process_frame
    if failures!=0:
        quit(1)
        return
    print("PASS ALL STUDIO ANIMATIONS: G09 V32, P06 V25, G11 V33, G13 and A01 complete native rigs")
    quit(0)
