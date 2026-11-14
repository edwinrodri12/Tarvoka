extends SceneTree

const Smoke = preload("res://scripts/ui/HeadquartersSmokeV23.gd")
const Fire = preload("res://scripts/ui/HeadquartersFireV22.gd")
const Bridge = preload("res://scripts/ui/HeadquartersCombatVisualV23.gd")
const Impact = preload("res://scripts/ui/HeadquartersImpactV21.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int = 6) -> void:
    for _i in range(n):
        await process_frame

func _shot(studio: Control,filename: String) -> Image:
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and image.get_width() > 500)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts")) == OK)
    assert(image.save_png("res://artifacts/"+filename) == OK)
    return image

func _pixel_difference(a: Image,b: Image) -> int:
    var first: Image = a.duplicate()
    var second: Image = b.duplicate()
    first.resize(205,194)
    second.resize(205,194)
    var difference := 0
    for y in range(0,194,2):
        for x in range(0,205,2):
            var p: Color = first.get_pixel(x,y)
            var q: Color = second.get_pixel(x,y)
            if absf(p.r-q.r)+absf(p.g-q.g)+absf(p.b-q.b)>0.14:
                difference+=1
    return difference

func _hit(id: String,before: int,after: int,role: String) -> Dictionary:
    return {"valid":true,"target_kind":"headquarters","target_id":id,
        "max_hp":100,"hp_before":before,"hp_after":after,
        "damage":before-after,"attacker_role":role,
        "visible_to_viewer":true}

func _run() -> void:
    assert(Bridge.stage_from_hp(100,100)==0)
    assert(Bridge.stage_from_hp(75,100)==1)
    assert(Bridge.stage_from_hp(50,100)==2)
    assert(Bridge.stage_from_hp(25,100)==3)
    assert(Bridge.stage_from_hp(0,100)==4)
    assert(Bridge.stage_from_hp(110,100)==-1)
    assert(Bridge.weapon_impact("assault")==Impact.BULLET)
    assert(Bridge.weapon_impact("tank")==Impact.EXPLOSIVE)
    assert(Bridge.weapon_impact("bomber")==Impact.EXPLOSIVE)
    assert(Bridge.weapon_impact("unknown")=="")
    var bridge: TarvokaHeadquartersCombatVisualV23 = Bridge.new()
    root.add_child(bridge)
    assert(bridge.configure("hq-qa",3,2,100,100))
    var bad: Dictionary = _hit("hq-qa",100,62,"tank")
    bad["target_kind"]="unit"
    assert(not bridge.accept_confirmed_structure_hit(bad))
    bad["target_kind"]="headquarters"
    bad["visible_to_viewer"]=false
    assert(not bridge.accept_confirmed_structure_hit(bad))
    bad["visible_to_viewer"]=true
    bad["damage"]=200
    assert(not bridge.accept_confirmed_structure_hit(bad))
    assert(bridge.current_hp==100)
    assert(bridge.accept_confirmed_structure_hit(_hit("hq-qa",100,62,"tank")))
    assert(bridge.visual_stage==1 and bridge.current_hp==62)
    var impact: TarvokaHeadquartersImpactV21 = bridge.visual_model().get_node(
        Impact.STAGE_NAME) as TarvokaHeadquartersImpactV21
    assert(impact.is_running() and impact.current_kind()==Impact.EXPLOSIVE)
    var prior: Node3D = bridge.visual_model()
    assert(bridge.accept_confirmed_structure_hit(_hit("hq-qa",62,58,"assault")))
    assert(prior==bridge.visual_model())
    assert(impact.current_kind()==Impact.BULLET)
    assert(bridge.accept_confirmed_structure_hit(_hit("hq-qa",58,45,"tank")))
    assert(bridge.visual_stage==2)
    var volume: TarvokaHeadquartersSmokeV23 = bridge.visual_model().get_node(
        Smoke.STAGE_NAME) as TarvokaHeadquartersSmokeV23
    assert(volume.source_count()==3 and volume.current_instance_count()==9)
    assert(volume.active_draw_batches()==1)
    var fire: TarvokaHeadquartersFireV22 = bridge.visual_model().get_node(
        Fire.STAGE_NAME) as TarvokaHeadquartersFireV22
    assert(not fire.get_node("HumoAnimadoV22_0").visible)
    var a: Transform3D = volume.get_node(
        "VolutasHumoEnUnLoteV23").multimesh.get_instance_transform(0)
    volume.advance(0.65)
    assert(a != volume.get_node(
        "VolutasHumoEnUnLoteV23").multimesh.get_instance_transform(0))
    volume.set_mobile_quality(true)
    assert(volume.current_instance_count()==6)
    volume.set_mobile_quality(false)
    assert(volume.current_instance_count()==9)
    assert(bridge.accept_confirmed_structure_hit(_hit("hq-qa",45,16,"bomber")))
    assert(bridge.visual_stage==3)
    volume = bridge.visual_model().get_node(Smoke.STAGE_NAME)
    assert(volume.source_count()==5 and volume.current_instance_count()==15)
    bridge.set_distant(true)
    assert(not volume.is_animating())
    bridge.set_distant(false)
    assert(volume.is_animating())
    assert(bridge.accept_confirmed_structure_hit(_hit("hq-qa",16,0,"mlrs")))
    assert(bridge.visual_stage==4)
    assert(bridge.visual_model().get_node_or_null(Smoke.STAGE_NAME)==null)
    assert(bridge.sync_authoritative_health(100))
    assert(bridge.visual_stage==0)
    bridge.queue_free()
    await _frames()

    root.content_scale_size = Vector2i(1280,800)
    var scene: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = scene.instantiate()
    root.add_child(studio)
    await _frames(10)
    studio._switch_category(1)
    await _frames(8)
    studio._change_hq_damage_stage(1)
    await _frames(6)
    _shot(studio,"tarvoka_hq_v23_1_fallen_antennas.png")
    studio._change_hq_damage_stage(2)
    await _frames(12)
    var medium: TarvokaHeadquartersSmokeV23 = studio.model_root.get_node(
        Smoke.STAGE_NAME) as TarvokaHeadquartersSmokeV23
    assert(medium.is_animating() and medium.source_count()==3)
    var with_smoke: Image = _shot(studio,"tarvoka_hq_v23_2_soft_smoke.png")
    medium.visible = false
    await _frames(4)
    var without_smoke: Image = _shot(studio,"tarvoka_hq_v23_2_no_smoke_reference.png")
    medium.visible = true
    assert(_pixel_difference(with_smoke,without_smoke)>5)
    studio._change_hq_damage_stage(3)
    await _frames(12)
    var smoke: TarvokaHeadquartersSmokeV23 = studio.model_root.get_node(
        Smoke.STAGE_NAME) as TarvokaHeadquartersSmokeV23
    assert(smoke.is_animating() and smoke.source_count()==5)
    fire = studio.model_root.get_node(Fire.STAGE_NAME)
    assert(fire.flame_batches()==1 and not fire.get_node("HumoAnimadoV22_0").visible)
    _shot(studio,"tarvoka_hq_v23_3_fire_volumetric_smoke.png")
    studio._play_hq_bullet_v21()
    var attack: TarvokaHeadquartersImpactV21 = studio.model_root.get_node(
        Impact.STAGE_NAME) as TarvokaHeadquartersImpactV21
    assert(attack.current_kind()==Impact.BULLET)
    studio._play_hq_explosion_v21()
    assert(attack.current_kind()==Impact.EXPLOSIVE)
    _shot(studio,"tarvoka_hq_v23_3_explosion_and_fire.png")
    studio._set_hq_map_lod(true)
    assert(not smoke.is_animating() and not attack.is_running())
    studio._set_hq_map_lod(false)
    assert(smoke.is_animating())
    studio.queue_free()
    await _frames()
    print("PASS HQ V23: soft 3D smoke in one batch, mobile budget, confirmed HP bridge, bullet/explosive, fog and LOD")
    quit(0)
