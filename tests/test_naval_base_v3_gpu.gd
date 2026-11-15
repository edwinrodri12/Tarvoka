extends SceneTree

# Native Godot 4.3 acceptance for Naval Base V3. Does not claim
# Android frame rates, gameplay implementation, or unexecuted QA.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const DetailV2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const BerthsV3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var found: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        found+=_count(child,label)
    return found

func _capture(studio: Control,name: String) -> void:
    await _frames(6)
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png("res://artifacts/tarvoka_naval_v3_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not BerthsV3.apply(null,1,1,0))
    var permutations: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null)
            assert(not BerthsV3.apply(model,2,faction,damage))
            assert(DetailV2.apply(model,2,faction,damage))
            var previous: int=Base.count_meshes(model)
            assert(BerthsV3.apply(model,2,faction,damage))
            assert(not BerthsV3.apply(model,2,faction,damage))
            assert(Base.count_meshes(model)>previous+6)
            assert(model.has_node(DetailV2.STAGE_NAME))
            assert(model.has_node(BerthsV3.STAGE_NAME))
            assert(_count(model,"EstacionesDeAtraqueV3")==1)
            assert(_count(model,"PasarelaEmbarqueAbatibleV3")==1)
            assert(_count(model,"RampaVaradaEmbarcacionesV3")==1)
            assert(_count(model,"EquipamientoAstilleroV3")==1)
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            if damage<=1:
                assert(_count(model,"TableroAntideslizantePasarela")==1)
                assert(_count(model,"PasamanosRampa_1")==1)
                assert(_count(model,"LosetaRampaVarada")==1)
                assert(_count(model,"RielBotadura_1")==1)
                assert(_count(model,"EscudoOficialFaccion3D")==1)
            if damage==2:
                assert(_count(model,"CilindroHidraulicoRoto")==1)
                assert(_count(model,"PasamanosRampa_1")==0)
                assert(_count(model,"LosetaRampaVarada")==1)
                assert(_count(model,"NervioRealDeTecho_4_1")==0)
            if damage==3:
                assert(_count(model,"AnclajePasarelaArrancada")==1)
                assert(_count(model,"TableroAntideslizantePasarela")==0)
                assert(_count(model,"LosetaRampaPartida")==1)
                assert(_count(model,"CoronacionEspigon_1")==0)
                assert(_count(model,"BarandalExterior_1_0")==0)
            if damage==4:
                assert(_count(model,"LosetaRampaVarada")==0)
                assert(_count(model,"EscombrosRampaDeVarada")==1)
                assert(_count(model,"BancadaAstilleroDestruida")==1)
                assert(_count(model,"TraviesaPuenteGruaAstillero")==0)
                assert(_count(model,"EscudoOficialFaccion3D")==0)
                assert(_count(model,"AstilleroTerminacionesV2")==0)
            model.free()
            permutations+=1
    assert(permutations==40)

    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(DetailV2.apply(model,level,6,0))
        assert(BerthsV3.apply(model,level,6,0))
        assert(_count(model,"ManifoldAguaCombustible_0")==(
            0 if level==1 else 1))
        assert(_count(model,"CarreteMangueraNaval")==(
            0 if level==1 else 1))
        assert(_count(model,"TraviesaPuenteGruaAstillero")==(
            1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(5)
    studio._change_selected_building(2)
    await _frames(10)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v2_toggle.button_pressed)
    assert(studio.naval_detail_v3_toggle.button_pressed)
    assert(studio.model_root.has_node(BerthsV3.STAGE_NAME))
    assert(studio.model_root.has_node(DetailV2.STAGE_NAME))
    await _capture(studio,"overview")

    studio.naval_detail_v3_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v3(false)
    await _frames(8)
    assert(studio.model_root.has_node(DetailV2.STAGE_NAME))
    assert(not studio.model_root.has_node(BerthsV3.STAGE_NAME))
    await _capture(studio,"compare_v2")
    studio.naval_detail_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v2(false)
    await _frames(8)
    assert(not studio.model_root.has_node(DetailV2.STAGE_NAME))
    assert(not studio.model_root.has_node(BerthsV3.STAGE_NAME))
    await _capture(studio,"compare_v1")
    studio.naval_detail_v2_toggle.set_pressed_no_signal(true)
    studio.naval_detail_v3_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v3(true)
    await _frames(8)
    assert(studio.model_root.has_node(DetailV2.STAGE_NAME))
    assert(studio.model_root.has_node(BerthsV3.STAGE_NAME))
    for view in [1,2,3]:
        studio.naval_camera_picker.select(view)
        studio._change_naval_camera(view)
        await _frames(5)
        await _capture(studio,["","sea_berths","rear_yard","top_ramps"][view])
    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio.naval_level_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(8)
    assert(_count(studio.model_root,"TraviesaPuenteGruaAstillero")==1)
    await _capture(studio,"advanced_yard")
    studio.naval_level_picker.select(1)
    studio._change_naval_setting(1)
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(_count(studio.model_root,"LosetaRampaPartida")==1)
    await _capture(studio,"critical_damage")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(2)
    print("PASS NAVAL BASE V3: 40 faction/damage variants, 3 architectural levels, berths/ramp/slipway/shipyard, reversible V1-V2-V3 studio toggles, 8 native Godot captures")
    quit(0)
