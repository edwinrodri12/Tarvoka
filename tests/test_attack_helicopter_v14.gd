extends SceneTree

# HAT-29 V14 native Godot regression: all eight factions, staged V13 damage,
# genuinely visible bullet/missile effects and a separately flying rocket.
const Models = preload("res://scripts/ui/UnitModels3D.gd")
const V13 = preload("res://scripts/ui/AttackHelicopterDamageV13.gd")
const Coat = preload("res://scripts/ui/AttackHelicopterFactionV14.gd")
const FX = preload("res://scripts/ui/AttackHelicopterCombatFXV14.gd")
var failures: int=0

func _check(condition: bool,reason: String) -> void:
    if not condition:
        failures+=1
        push_error("HAT29 V14: "+reason)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var tactical: Node3D=Models.build("attack_heli",0,true,10)
    _check(tactical!=null and not Coat.has_model(tactical)
        and not FX.has_model(tactical),
        "Android battle LOD10 never receives hero paint or V14 particles")
    if tactical!=null:
        tactical.free()
    var colors: Array[Color]=[]
    for faction in range(8):
        var model: Node3D=Models.build("attack_heli",faction,true,14)
        _check(model!=null,"A01 hero model built for army "+str(faction))
        if model==null:
            continue
        root.add_child(model)
        _check(V13.has_model(model) and Coat.has_model(model)
            and FX.has_model(model),"all actual V13 and V14 layers coexist")
        _check(int(model.get_meta("a01_v14_faction_painted_count",0))>=9,
            "at least nine larger faction-colored parts, not tiny decals")
        var hull: MeshInstance3D=model.find_child(
            "A01_V2_Casco12CarasCerrado",true,false) as MeshInstance3D
        var main_color: Color=Color.TRANSPARENT
        if hull!=null and hull.material_override is StandardMaterial3D:
            main_color=(hull.material_override as StandardMaterial3D).albedo_color
            colors.append(main_color)
        _check(main_color.a>0.9,
            "large actual V2 hull carries enamel for army "+str(faction))
        _check(Coat.apply(model,Models.faction_paint_color(faction))
            and FX.apply(model),
            "V14 coating and effect builders are idempotent")

        var bullets: Node3D=model.find_child(FX.BULLETS,true,false) as Node3D
        var missile: Node3D=model.find_child(FX.MISSILE_HIT,true,false) as Node3D
        var rockets: Node3D=model.find_child(FX.MISSILES,true,false) as Node3D
        V13.pose(model,"hit_bullet",0.34)
        FX.pose(model,"hit_bullet",0.34)
        var sparks: int=0
        for child in bullets.get_children():
            if (child as Node3D).visible:
                sparks+=1
        _check(sparks>=1 and not missile.visible,
            "ricochets pulse without setting off missile explosion")
        V13.pose(model,"hit_explosive",0.34)
        FX.pose(model,"hit_explosive",0.34)
        var ring: Node3D=model.find_child(
            "A01V14_AnilloPresionMisil",true,false) as Node3D
        _check(missile.visible and ring!=null and ring.visible
            and ring.scale.x>1.0 and not bullets.visible,
            "missile hit shows physical pressure ring, flash and shrapnel")
        V13.pose(model,"hover",0.58)
        FX.pose(model,"fire_missiles",0.58)
        var flying: int=0
        for rocket in rockets.get_children():
            if (rocket as Node3D).visible:
                flying+=1
        _check(flying==2 and not missile.visible and not bullets.visible,
            "two staggered physical missiles detach from wing launchers")
        FX.pose(model,"idle",0.0)
        _check(not rockets.visible and not missile.visible
            and not bullets.visible,"all temporary V14 effects clear on idle")
        _check(V13.set_stage(model,3) and V13.stage(model)==3,
            "old V13 critical engine fire persists")
        V13.set_stage(model,4)
        _check(V13.pose(model,"destroy",1.0) and V13.stage(model)==4,
            "old rotor break and airborne crash remain intact")
        V13.restore(model)
        _check(V13.set_stage(model,0) and V13.stage(model)==0,
            "wreck is completely repairable after V14 effect playback")
        model.free()
    _check(colors.size()==8,"all eight aircraft have real colored hulls")
    if colors.size()==8:
        for i in range(8):
            for j in range(i+1,8):
                _check(colors[i].distance_to(colors[j])>0.04,
                    "distinct official faction hues "+str(i)+" / "+str(j))
    if failures>0:
        push_error("HAT29 V14: "+str(failures)+" failures")
        quit(1)
    else:
        print("PASS HAT29 V14: 8 vivid factions; bullets, missile blast, dual flying rockets, unchanged mobile LOD and reversible V13 destruction")
        quit(0)
