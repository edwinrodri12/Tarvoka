extends SceneTree

# HQ V21 GPU QA: no hollow rear geometry, five real destruction states,
# two live impact animations and explicitly operable studio controls.
const HQ = preload("res://scripts/ui/Headquarters3D.gd")
const Damage = preload("res://scripts/ui/HeadquartersDamageV21.gd")
const Impact = preload("res://scripts/ui/HeadquartersImpactV21.gd")
const Emblems = preload("res://scripts/ui/HeadquartersEmblems3D.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int = 7) -> void:
    for _i in range(count):
        await process_frame

func _shot(studio: Control,path: String) -> void:
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts")) == OK)
    var image: Image = studio.preview.get_texture().get_image()
    assert(image != null and image.get_width() >= 600)
    assert(image.save_png("res://artifacts/"+path)==OK)

func _inspect_walls(model: Node3D,level: int) -> void:
    var central: MeshInstance3D = model.find_child(
        "MuroPosteriorCentralContinuoV21",true,false) as MeshInstance3D
    assert(central != null and central.mesh is BoxMesh)
    assert(is_equal_approx((central.mesh as BoxMesh).size.y,
        2.87+0.91*float(level-1)))
    assert((central.mesh as BoxMesh).size.x > 5.8)
    assert(central.position.z > 2.80)
    for side in [-1,1]:
        var wall: MeshInstance3D = model.find_child(
            "MuroPosteriorAlaV21_%s" % side,true,false) as MeshInstance3D
        var join: MeshInstance3D = model.find_child(
            "RetornoUnionPosteriorV21_%s" % side,true,false) as MeshInstance3D
        assert(wall != null and wall.mesh is BoxMesh)
        assert(wall.visible and join != null)
        assert((wall.mesh as BoxMesh).size.x > 2.2)
        assert((wall.mesh as BoxMesh).size.y > 2.2)
        assert((wall.mesh as BoxMesh).size.z >= 0.25)

func _run() -> void:
    assert(Damage.STAGES.size()==5)
    for level in range(1,4):
        var model: Node3D = HQ.build(level,0,"operativo")
        _inspect_walls(model,level)
        assert(Damage.apply(model,0,level))
        assert(model.get_meta("tarvoka_hq_damage_stage",-1)==0)
        assert(model.find_child("EscudoOficialFaccion3D",true,false)!=null)
        model.free()
    for faction in range(8):
        var emblem: Texture2D = Emblems.emblem_texture(faction)
        assert(emblem != null and emblem.get_width()==160)

    for stage in range(1,5):
        var model: Node3D = HQ.build(2,5,"destruido" if stage==4 else "operativo")
        assert(model != null)
        assert(Damage.apply(model,stage,2))
        var details: Node3D = model.get_node_or_null(Damage.STAGE_NAME)
        assert(details != null and details.get_meta("tarvoka_hq_damage_v21",-1)==stage)
        if stage < 3:
            _inspect_walls(model,2)
        if stage < 4:
            assert(model.find_child("MuroPosteriorCentralContinuoV21",true,false)!=null)
            assert(model.find_child("AnilloMetalImpactoHQV21_0",true,false)!=null)
        if stage>=2 and stage<4:
            assert(model.find_child("CristaleriaAbiertaYFragmentosHQV21",true,false)!=null)
            var glazing: MeshInstance3D = model.find_child(
                "HojaCristalBlindado_-1",true,false) as MeshInstance3D
            assert(glazing != null and not glazing.visible)
        if stage==3:
            var rear_wall: MeshInstance3D = model.find_child(
                "MuroPosteriorAlaV21_-1",true,false) as MeshInstance3D
            assert(rear_wall != null and not rear_wall.visible)
            assert(model.find_child("AlaTraseraRotaYAceroExpuestoV21",true,false)!=null)
        if stage==4:
            assert(model.find_child("MuroPosteriorCentralContinuoV21",true,false)==null)
            assert(model.find_child("RestosMuroPosteriorHQV21_0",true,false)!=null)
        model.free()

    # Native time-dependent FX; no fake still decals.
    var fx: TarvokaHeadquartersImpactV21 = Impact.new()
    root.add_child(fx)
    await _frames()
    assert(fx.trigger(Impact.BULLET))
    assert(fx.current_kind()==Impact.BULLET and fx.active_mesh_batches()==1)
    assert(fx.get_node("ChispasBalasUnLoteV21").visible)
    assert(not fx.get_node("FragmentosExplosionUnLoteV21").visible)
    fx._process(0.19)
    assert(fx.is_running())
    fx._process(Impact.BULLET_DURATION)
    assert(not fx.is_running() and fx.active_mesh_batches()==0)
    assert(fx.trigger(Impact.EXPLOSIVE))
    assert(fx.active_mesh_batches()==6)
    assert(fx.get_node("FragmentosExplosionUnLoteV21").visible)
    assert(fx.get_node("OndaDeChoqueVisibleHQV21").visible)
    fx._process(0.23)
    assert(fx.is_running())
    assert(fx.get_node("VolutaHumoExplosionV21_0").visible)
    fx._process(Impact.EXPLOSIVE_DURATION)
    assert(not fx.is_running())
    assert(not fx.trigger("alien_weapon"))
    fx.queue_free()
    await _frames()

    root.content_scale_size = Vector2i(1280,800)
    var packed: PackedScene = load("res://scenes/UnitArtStudioWeb.tscn")
    var studio: Control = packed.instantiate()
    root.add_child(studio)
    await _frames(9)
    studio._switch_category(1)
    await _frames(7)
    assert(studio.hq_damage_stage_picker.item_count==5)
    assert(studio.hq_damage_stage_picker.selected==0)
    assert(not studio.hq_bullet_test_button.disabled)
    assert(not studio.hq_explosive_test_button.disabled)
    _inspect_walls(studio.model_root,1)
    # Rear camera, actual 3D reverse viewing, no image retouch.
    studio.model_root.rotation_degrees.y = 0.0
    studio.camera.position = Vector3(15.0,11.0,19.0)
    studio.camera.look_at(Vector3(0,2.0,0),Vector3.UP)
    await _frames()
    _shot(studio,"tarvoka_hq_v21_rear_fully_enclosed.png")

    studio._change_hq_damage_stage(1)
    await _frames()
    assert(studio.model_root.get_meta("tarvoka_hq_damage_stage",-1)==1)
    studio._change_hq_damage_stage(2)
    await _frames()
    assert(studio.model_root.get_meta("tarvoka_hq_damage_stage",-1)==2)
    assert(studio.building_state_picker.selected==2)
    _shot(studio,"tarvoka_hq_v21_damage_moderate.png")
    studio._change_hq_damage_stage(3)
    await _frames()
    assert(studio.model_root.get_meta("tarvoka_hq_damage_stage",-1)==3)
    _shot(studio,"tarvoka_hq_v21_damage_critical.png")
    studio._change_hq_damage_stage(4)
    await _frames()
    assert(studio.building_state_picker.selected==3)
    assert(studio.model_root.get_meta("tarvoka_hq_damage_stage",-1)==4)
    _shot(studio,"tarvoka_hq_v21_damage_destroyed.png")
    studio._change_hq_damage_stage(0)
    await _frames()
    assert(studio.building_state_picker.selected==0)
    studio._play_hq_bullet_v21()
    var current: TarvokaHeadquartersImpactV21 = studio.model_root.get_node(
        Impact.STAGE_NAME) as TarvokaHeadquartersImpactV21
    assert(current.current_kind()==Impact.BULLET)
    await _frames()
    _shot(studio,"tarvoka_hq_v21_bullet_impact.png")
    studio._play_hq_explosion_v21()
    assert(current.current_kind()==Impact.EXPLOSIVE)
    await _frames()
    _shot(studio,"tarvoka_hq_v21_explosive_impact.png")
    studio._set_hq_map_lod(true)
    assert(not current.visible and not current.is_running())
    studio._set_hq_map_lod(false)
    assert(current.visible)
    studio._change_hq_v15_mode(2)
    await _frames()
    assert(studio.model_root.get_node_or_null(Impact.STAGE_NAME)==null)
    assert(studio.hq_bullet_test_button.disabled)
    studio.queue_free()
    await _frames()
    print("PASS HQ V21: sealed rear 3 levels, 8 official emblems, five true damage levels, native bullet/explosive animation, studio controls and LOD")
    quit(0)
