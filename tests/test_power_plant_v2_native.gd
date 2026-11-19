extends SceneTree

# V2 art QA: full 3-tier / 9-palette / 5-stage native Godot geometry.
# No sprites, fake render cards, collision, income, power or game rules.
const Plant=preload("res://scripts/ui/PowerPlant3DV2.gd")
const Base=preload("res://scripts/ui/PowerPlant3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var total:int=0
    var min_count:int=100000
    var max_count:int=0
    for level in [1,2,3]:
        for faction in range(-1,8):
            for damage in range(5):
                var model:Node3D=Plant.build(level,faction,damage)
                assert(model!=null,"Power plant V2 build returned null")
                assert(model.has_node(Base.STAGE),"Base V1 architecture lost")
                assert(model.has_node(Plant.STAGE),"V2 industrial sculpture missing")
                assert(model.get_meta("tarvoka_powerplant_visual_only",false),
                    "Sculpture must not change gameplay")
                assert(model.get_meta("tarvoka_powerplant_stage",0)==2)
                assert(not model.get_meta("tarvoka_powerplant_final_approved",true))
                assert(not model.get_meta("tarvoka_powerplant_gameplay_changed",true))
                assert(model.get_meta("tarvoka_powerplant_level",-1)==level)
                assert(model.get_meta("tarvoka_powerplant_faction",-2)==faction)
                assert(model.get_meta("tarvoka_powerplant_damage",-1)==damage)
                var count:int=Plant.mesh_count(model)
                assert(count>0,"Native meshes lost")
                min_count=mini(min_count,count)
                max_count=maxi(max_count,count)
                var stage:Node3D=model.get_node(Plant.STAGE) as Node3D
                assert(stage.get_child_count()>=3,
                    "V2 industrial detail meshes not built")
                if damage==0:
                    assert(stage.get_node_or_null("BandaFrenteSalaV2")!=null,
                        "Undamaged control-room identity fascia missing")
                    assert(stage.get_node_or_null("CristalInstrumentosV2_0")!=null,
                        "Real detailed instrument glass missing")
                if damage>=3:
                    assert(stage.get_node_or_null("BandaFrenteSalaV2")==null,
                        "Critical ruins should not retain intact front stripe")
                if damage==4:
                    assert(stage.get_node_or_null("ConductoRotoV2_0")!=null,
                        "V2 destruction-state pipework missing")
                if level==3 and damage==0:
                    assert(stage.get_node_or_null("NervioTorreV2_-1_0")!=null,
                        "Metropolis tier cooling-tower mechanical finish missing")
                if level>=2 and damage==0:
                    assert(stage.get_node_or_null("AisladorCeramicoV2_0_-1")!=null,
                        "Real 3D high-voltage insulator missing")
                if damage==0:
                    var accent:Color=Style.faction_color(faction) if faction>=0 else Plant.NEUTRAL
                    var badge:MeshInstance3D=stage.get_node("BandaFrenteSalaV2") as MeshInstance3D
                    var mat:StandardMaterial3D=badge.material_override as StandardMaterial3D
                    assert(mat!=null and mat.albedo_color.is_equal_approx(accent),
                        "Eight-faction or neutral palette mismatch")
                model.free()
                total+=1
    assert(total==135)
    print("PASS POWER PLANT V2: ",total," combinations 3 tiers 9 palettes D0-D4, real meshes ",min_count,"..",max_count)
    quit(0)
