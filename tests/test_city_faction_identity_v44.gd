extends SceneTree

const City=preload("res://scripts/ui/CivilianCityTacticalLOD4.gd")
const V1=preload("res://scripts/ui/CivilianCity3DV1.gd")
const V44=preload("res://scripts/ui/CivilianCityFactionIdentityV44.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _verify(level: int,faction: int,damage: int,lod: int) -> void:
    var model: Node3D=City.build_tactical(level,faction,damage,lod)
    assert(model!=null,"Could not build city")
    assert(model.has_node(V44.STAGE_NAME),"V44 stage missing")
    assert(int(model.get_meta("city_faction_identity_version",-1))==44)
    assert(int(model.get_meta("city_art_work_in_progress",-1))==43)
    assert(int(model.get_meta("visual_faction",-2))==faction)
    assert(int(model.get_meta("visual_damage_stage",-1))==damage)
    var stage: Node3D=model.get_node(V44.STAGE_NAME) as Node3D
    var expected: Color=(
        Style.faction_color(faction) if faction>=0 else V44.NEUTRAL_SLATE)
    if damage==2:
        expected=expected.darkened(0.10)
    elif damage>=3:
        expected=expected.darkened(0.28)
    var identified: int=0
    for child in stage.get_children():
        assert(child is MeshInstance3D,"Every V44 identity must be a native 3D mesh")
        var part: MeshInstance3D=child as MeshInstance3D
        var material: StandardMaterial3D=part.material_override as StandardMaterial3D
        assert(material!=null and material.albedo_color.is_equal_approx(expected),
            "Faction identity material lost official or neutral slate color")
        assert(part.visible,"V44 trim was culled in one of the 3 LODs")
        assert(part.mesh!=null,"Empty identity mesh")
        identified+=1
    assert(identified>=2,"Damage-aware faction identity missing")
    assert(City.drawable_count(model)>50,"Real city geometry missing")
    model.free()

func _run() -> void:
    assert(V1.NEUTRAL_ACCENT==V44.NEUTRAL_SLATE,
        "Neutral source must no longer use the old golden tint")
    var neutral: Color=V44.NEUTRAL_SLATE
    var yellow: Color=Style.faction_color(3)
    var onyx: Color=Style.faction_color(7)
    var yellow_difference:=Vector3(
        neutral.r-yellow.r,neutral.g-yellow.g,
        neutral.b-yellow.b).length()
    var onyx_difference:=Vector3(
        neutral.r-onyx.r,neutral.g-onyx.g,
        neutral.b-onyx.b).length()
    assert(yellow_difference>0.5 and onyx_difference>0.30,
        "Neutral should be visibly different from Solar and Onyx")
    var cases: int=0
    for faction in range(-1,8):
        for level in [1,2,3]:
            for lod in [0,1,2]:
                _verify(level,faction,0,lod)
                cases+=1
    for damage in [2,3,4]:
        for level in [1,2,3]:
            _verify(level,3,damage,0)
            _verify(level,-1,damage,2)
            cases+=2
    print("PASS CITY V44 FACTION IDENTITY: ",cases,
        " native city variants, 9 palettes, 3 tiers, LOD0-2, D0-4, neutral slate")
    quit(0)
