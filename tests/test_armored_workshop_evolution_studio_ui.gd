extends SceneTree

# Real interactive Godot design-studio wiring: N1->N2->N3 and incoming
# attacks rebuild the exact approved workshop model at each damage stage.
const FX=preload("res://scripts/ui/ArmoredWorkshopEvolutionVFX3D.gd")
const Workshop=preload("res://scripts/ui/ArmoredWorkshop3DV2.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var scene:PackedScene=load(
        "res://scenes/ArmoredWorkshopDesignStudioV1.tscn") as PackedScene
    assert(scene!=null)
    var studio:Control=scene.instantiate() as Control
    get_root().add_child(studio)
    await process_frame
    var level:OptionButton=studio.get("_level") as OptionButton
    var damage:OptionButton=studio.get("_damage") as OptionButton
    var faction:OptionButton=studio.get("_faction") as OptionButton
    var version:OptionButton=studio.get("_version") as OptionButton
    var context:OptionButton=studio.get("_environment") as OptionButton
    var fx:Node3D=studio.get("_workshop_fx") as Node3D
    assert(level!=null and damage!=null and faction!=null and
        version!=null and context!=null and fx!=null)
    assert(fx is TarvokaArmoredWorkshopEvolutionVFX3D)
    var actions:Dictionary={}
    for button in studio.find_children("*","Button",true,false):
        var label:String=(button as Button).text
        if "EVOLUCIONAR N+1" in label or "RECIBIR ATAQUE D+1" in label or \
                "REPARACIÓN VISUAL D-1" in label:
            actions[label]=button
    assert(actions.size()==3,
        "All 3 native studio cinematic buttons must be present")
    level.select(0)
    damage.select(0)
    faction.select(4)
    version.select(1)
    context.select(0)
    studio.call("_on_change",0)
    for wanted_level in [2,3]:
        studio.call("_play_workshop_effect","upgrade")
        assert(fx.busy)
        await fx.sequence_finished
        assert(level.selected==wanted_level-1)
        assert(damage.selected==0)
        var model:Node3D=studio.get("_model") as Node3D
        assert(model!=null)
        assert(model.get_meta("workshop_art_version",0)==2)
        assert(model.find_child(
            "FrontispicioBlindadoV2",true,false)!=null)
        assert(Workshop.mesh_count(model)>100)
    for wanted_damage in [1,2,3,4]:
        studio.call("_play_workshop_effect","attack")
        assert(fx.busy)
        await fx.sequence_finished
        assert(damage.selected==wanted_damage)
        assert(fx.get_child_count()==0)
        var model:Node3D=studio.get("_model") as Node3D
        assert(model!=null and model.get_meta("workshop_art_version",0)==2)
        if wanted_damage>=3:
            assert(model.find_child(
                "FrontispicioBlindadoV2",true,false)==null,
                "Critically damaged workshop has no floating full front beam")
    studio.call("_play_workshop_effect","repair")
    await fx.sequence_finished
    assert(damage.selected==3)
    # Repeat a full attack in the real compact Android map preview.
    version.select(4)
    context.select(1)
    studio.call("_on_change",1)
    var map:Node3D=studio.get("_model") as Node3D
    assert(map!=null and map.get_meta("visual_preview_only",false))
    assert(fx.map_preview)
    assert(fx.scale.is_equal_approx(Vector3.ONE*0.12))
    studio.call("_play_workshop_effect","attack")
    await fx.sequence_finished
    assert(damage.selected==4)
    assert((studio.get("_model") as Node3D).get_meta(
        "workshop_damage",-1)==4)
    assert(fx.get_meta("no_offensive_weapon",false))
    print("PASS WORKSHOP EVOLUTION STUDIO UI: 3 real buttons, ",
        "N1->N3 upgrades, D0->D4 attack cinematic + repair, ",
        "map D4 in Android LOD with scene updates; no gameplay modifications")
    studio.queue_free()
    quit(0)
