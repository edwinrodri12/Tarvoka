extends SceneTree

# TARVOKA Naval Base V7, native Godot 4.3 visual QA in the actual 3D Studio.
# No Android performance or gameplay validation is claimed by this test.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const V7=preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(root: Node,label: String) -> int:
    var amount: int=1 if str(root.name)==label else 0
    for child in root.get_children():
        amount+=_count(child,label)
    return amount

func _capture(studio: Control,name: String) -> void:
    await _frames(8)
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png("res://artifacts/tarvoka_naval_v7_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V7.apply(null,2,0,0))
    assert(not V7.set_night(null,true))
    assert(not V7.set_detail(null,true))
    var count: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null)
            assert(not V7.apply(model,2,faction,damage))
            assert(V2.apply(model,2,faction,damage))
            assert(V3.apply(model,2,faction,damage))
            assert(V4.apply(model,2,faction,damage))
            assert(V5.apply(model,2,faction,damage))
            assert(not V7.apply(model,2,faction,damage))
            assert(V6.apply(model,2,faction,damage))
            var before_count: int=Base.count_meshes(model)
            assert(V7.apply(model,2,faction,damage))
            assert(not V7.apply(model,2,faction,damage))
            assert(Base.count_meshes(model)>before_count)
            assert(model.has_node(V6.STAGE_NAME))
            assert(model.has_node(V7.STAGE_NAME))
            var stage: Node3D=model.get_node(V7.STAGE_NAME)
            assert(int(stage.get_meta("naval_v7_damage",-1))==damage)
            var near: Node3D=stage.get_node("MecanicaCercanaV7")
            var far: Node3D=stage.get_node("SiluetaLejanaV7")
            var night: Node3D=stage.get_node("ReflectantesNocturnosV7")
            assert(near.visible and not far.visible and not night.visible)
            assert(V7.set_detail(model,false))
            assert(not near.visible and far.visible)
            assert(V7.set_detail(model,true))
            assert(near.visible and not far.visible)
            assert(V7.set_night(model,true))
            assert(night.visible)
            assert(V7.set_night(model,false))
            assert(not night.visible)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            if damage<=1:
                assert(_count(model,"ZapataAnclajePasarelaV7")==1)
                assert(_count(model,"PlacaBisagraPasarela_-1")==1)
                assert(_count(model,"PerfilPasarelaLejanaV7")==1)
                assert(_count(model,"BancadaCabrestanteBotaduraV7")==1)
                assert(_count(model,"GrapaRielBotadura_-1_00")==1)
                assert(_count(model,"BarraSalidaEscala_0_-1")==1)
                assert(_count(model,"MarcaReflexivaPasarela_1")==1)
            if damage==2:
                assert(_count(model,"ZapataAnclajePasarelaV7")==1)
                assert(_count(model,"ConexionHidraulicaDoblada_1")==1)
                assert(_count(model,"ConectorHidraulicoPasarela_1")==0)
                assert(_count(model,"CabezaTornilloAntideslizante_02")==0)
                assert(_count(model,"GrapaRielBotadura_-1_00")==1)
                assert(_count(model,"BarraSalidaEscala_1_-1")==0)
                assert(_count(model,"MarcaReflexivaPasarela_1")==0)
            if damage==3:
                assert(_count(model,"PernoBisagraRotaEmbarqueV7")==1)
                assert(_count(model,"ZapataAnclajePasarelaV7")==0)
                assert(_count(model,"PlacaRielPartidoBotaduraV7")==1)
                assert(_count(model,"GrapaRielBotadura_-1_00")==0)
                assert(_count(model,"BarraSalidaEscala_0_-1")==1)
                assert(_count(model,"BarraSalidaEscala_2_-1")==0)
                assert(_count(model,"CabeceraLegibleMuelle_1")==0)
                assert(_count(model,"CoronacionEspigon_1")==0)
            if damage==4:
                assert(_count(model,"TornilloPasarelaEntreEscombros")==1)
                assert(_count(model,"ZapataAnclajePasarelaV7")==0)
                assert(_count(model,"BancadaCabrestanteBotaduraV7")==0)
                assert(_count(model,"MasaEscombrosBotaduraV7")==1)
                assert(_count(model,"BarraSalidaEscala_0_-1")==0)
                assert(_count(model,"RielesRampaLejanosV7")==0)
                assert(_count(model,"ParedPosteriorHangar")==0)
            model.free()
            count+=1
    assert(count==40)

    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(V2.apply(model,level,6,0))
        assert(V3.apply(model,level,6,0))
        assert(V4.apply(model,level,6,0))
        assert(V5.apply(model,level,6,0))
        assert(V6.apply(model,level,6,0))
        assert(V7.apply(model,level,6,0))
        assert(_count(model,"ZapataAnclajePasarelaV7")==1)
        assert(_count(model,"PerfilPasarelaLejanaV7")==1)
        assert(_count(model,"TraviesaPuenteGruaAstillero")==(
            1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(6)
    studio._change_selected_building(2)
    await _frames(10)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v6_toggle.button_pressed)
    assert(studio.naval_detail_v7_toggle.button_pressed)
    assert(studio.model_root.has_node(V7.STAGE_NAME))
    await _capture(studio,"overview")

    studio.naval_night_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_night_v6(true)
    await _frames(9)
    assert(bool(studio.model_root.get_node(V7.STAGE_NAME)
        .get_meta("naval_v7_night",false)))
    await _capture(studio,"night_boarding")
    studio.naval_camera_picker.select(1)
    studio._change_naval_camera(1)
    await _frames(7)
    await _capture(studio,"harbor_from_sea")

    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio._zoom=0.63
    studio._update_camera()
    await _frames(8)
    var stage: Node3D=studio.model_root.get_node(V7.STAGE_NAME)
    assert(not (stage.get_node("MecanicaCercanaV7") as Node3D).visible)
    assert((stage.get_node("SiluetaLejanaV7") as Node3D).visible)
    await _capture(studio,"tactical_far")

    studio._zoom=1.60
    studio._update_camera()
    await _frames(8)
    assert((stage.get_node("MecanicaCercanaV7") as Node3D).visible)
    assert(not (stage.get_node("SiluetaLejanaV7") as Node3D).visible)
    await _capture(studio,"boarding_close")
    studio._zoom=1.0
    studio._update_camera()

    studio.naval_night_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_night_v6(false)
    studio.naval_detail_v7_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v7(false)
    await _frames(8)
    assert(studio.model_root.has_node(V6.STAGE_NAME))
    assert(not studio.model_root.has_node(V7.STAGE_NAME))
    await _capture(studio,"compare_v6")
    studio.naval_detail_v7_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v7(true)
    await _frames(8)
    assert(studio.model_root.has_node(V7.STAGE_NAME))

    studio.naval_level_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(7)
    assert(_count(studio.model_root,"TraviesaPuenteGruaAstillero")==1)
    await _capture(studio,"shipyard_level3")
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(_count(studio.model_root,"ZapataAnclajePasarelaV7")==0)
    await _capture(studio,"critical_damage")
    studio._change_selected_building(1)
    await _frames(6)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(2)
    print("PASS NAVAL BASE V7: 40 faction/damage variants, three architecture levels, physical gangway and slipway anchors, ladder exits, damage continuity, near/far and night integration, V6 comparison, 8 native captures")
    quit(0)
