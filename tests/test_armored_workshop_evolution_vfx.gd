extends SceneTree

# Actual runtime tests: three evolution levels, five hit stages and visual
# repair. The animation overlay cannot grant a weapon, change HP or mutate
# gameplay data. This tests native Godot Tweens, not just metadata.
const FX=preload("res://scripts/ui/ArmoredWorkshopEvolutionVFX3D.gd")
const Hero=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var stage:=Node3D.new()
    get_root().add_child(stage)
    var fx:=FX.new()
    fx.name="PruebasEvolucionAtaquesDaño"
    stage.add_child(fx)
    assert(not fx.configure(4,0,0,false))
    assert(not fx.configure(1,9,0,false))
    assert(not fx.configure(1,0,5,false))
    assert(fx.configure(1,3,0,false))
    assert(fx.level==1 and fx.damage==0 and not fx.busy)
    assert(fx.get_meta("preview_only",false))
    assert(fx.get_meta("gameplay_unchanged",false))
    assert(fx.get_meta("no_offensive_weapon",false))
    var state:Dictionary={"level":1,"damage":0,"requested":0}
    fx.stage_requested.connect(func(level:int,damage:int):
        assert(Hero.valid(level,3,damage))
        state["requested"]=int(state["requested"])+1
        state["level"]=level
        state["damage"]=damage
    )
    var upgrades:int=0
    for next_level in [2,3]:
        fx.play_upgrade()
        assert(fx.busy)
        assert(fx.find_child("AndamioEvolución_0",true,false)!=null)
        await fx.sequence_finished
        assert(not fx.busy and fx.level==next_level)
        assert(state["level"]==next_level)
        assert(state["damage"]==0)
        assert(fx.get_child_count()==0)
        upgrades+=1
    fx.play_upgrade()
    assert(not fx.busy and fx.level==3,
        "N3 is the FINAL workshop architecture")
    var strikes:int=0
    for next_damage in [1,2,3,4]:
        fx.play_attack()
        assert(fx.busy)
        assert(fx.find_child("ProyectilEnemigoEntrante",true,false)!=null)
        # Consecutive attacks during the same explosion must not skip damage.
        fx.play_attack()
        await fx.sequence_finished
        assert(fx.damage==next_damage)
        assert(state["damage"]==next_damage)
        assert(fx.get_child_count()==0)
        assert(not fx.busy)
        assert(fx.get_meta("last_effect","")==FX.EVENT_ATTACK)
        strikes+=1
    fx.play_attack()
    assert(not fx.busy and fx.damage==4,
        "A destroyed workshop cannot keep taking visible damage")
    var repairs:int=0
    for next_damage in [3,2,1,0]:
        fx.play_repair()
        assert(fx.busy)
        assert(fx.find_child("LuzReparación_0",true,false)!=null)
        await fx.sequence_finished
        assert(fx.damage==next_damage and state["damage"]==next_damage)
        assert(fx.get_child_count()==0 and not fx.busy)
        repairs+=1
    fx.play_repair()
    assert(not fx.busy and fx.damage==0)
    assert(int(state["requested"])==upgrades+strikes+repairs)
    assert(fx.configure(1,-1,0,true),
        "Same scene should display neutral and 2.4m map context")
    assert(fx.scale.is_equal_approx(Vector3.ONE*0.12))
    assert(fx.position.is_equal_approx(Vector3(0,0.055,0)))
    fx.play_attack()
    await fx.sequence_finished
    assert(fx.damage==1)
    assert(fx.get_child_count()==0)
    assert(fx.get_meta("no_offensive_weapon",false))
    print("PASS WORKSHOP EVOLUTION VFX: N1->N2->N3; ",
        "D0->D1->D2->D3->D4; repair D4->D0; map context; ",
        int(state["requested"])," stage signals; no offensive ability")
    stage.queue_free()
    quit(0)
