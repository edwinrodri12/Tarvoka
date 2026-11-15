extends SceneTree

# Native Godot 4.3 V10 QA. Actual concrete seawall/fender contact, pier
# bollards, mooring-ring pairing, six Studio cameras and 8 real screenshots.
# Visual only — not physics, navigation, combat or Android FPS.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
const V7=preload("res://scripts/ui/NavalBoardingDetailV7.gd")
const V8=preload("res://scripts/ui/NavalFendersV8.gd")
const V9=preload("res://scripts/ui/NavalSculptedFendersV9.gd")
const V10=preload("res://scripts/ui/NavalMooringAlignmentV10.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var amount: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        amount+=_count(child,label)
    return amount

func _capture(studio: Control,name: String) -> void:
    await _frames(8)
    var screenshot: Image=studio.preview.get_texture().get_image()
    assert(screenshot!=null)
    assert(screenshot.get_width()>400 and screenshot.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(screenshot.save_png(
        "res://artifacts/tarvoka_naval_v10_"+name+".png")==OK)

func _build(level: int,faction: int,damage: int) -> Node3D:
    var model: Node3D=Base.build(level,faction,damage)
    assert(model!=null)
    assert(V2.apply(model,level,faction,damage))
    assert(V3.apply(model,level,faction,damage))
    assert(V4.apply(model,level,faction,damage))
    assert(V5.apply(model,level,faction,damage))
    assert(V6.apply(model,level,faction,damage))
    assert(V7.apply(model,level,faction,damage))
    assert(V8.apply(model,level,faction,damage))
    assert(V9.apply(model,level,faction,damage))
    assert(V10.apply(model,level,faction,damage))
    return model

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V10.apply(null,2,0,0))
    assert(not V10.set_detail(null,true))
    assert(not V10.set_night(null,true))
    assert(absf(V10.east_fender(0).x-1.125)<0.16)
    assert(absf(V10.quay_mooring(0).z+3.75)<0.001)
    assert(absf(V10.pier_bollard(-1,1).x+3.19)<0.001)
    assert(absf(V10.pier_fender(-1,1).x+3.27)<0.001)
    var verified: int=0
    for faction in range(8):
        for damage in range(5):
            var early: Node3D=Base.build(2,faction,damage)
            assert(not V10.apply(early,2,faction,damage))
            early.free()
            var model: Node3D=_build(2,faction,damage)
            assert(not V10.apply(model,2,faction,damage))
            var stage: Node3D=model.get_node(V10.STAGE_NAME)
            assert(int(stage.get_meta("naval_v10_damage",-1))==damage)
            assert(bool(stage.get_meta("naval_v10_bollards_remain_usable",false)))
            assert(is_equal_approx(float(stage.get_meta(
                "naval_v10_east_wall_face",0)),1.125))
            assert(is_equal_approx(float(stage.get_meta(
                "naval_v10_pier_wall_face",0)),4.30))
            assert(model.has_node(V9.STAGE_NAME))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            var near: Node3D=stage.get_node("AnclajesCercanosV10")
            var far: Node3D=stage.get_node("ReferenciasTacticasV10")
            var night: Node3D=stage.get_node("GuiasNocturnasV10")
            assert(near.visible and not far.visible and not night.visible)
            assert(V10.set_detail(model,false))
            assert(not near.visible and far.visible)
            assert(V10.set_detail(model,true))
            assert(near.visible and not far.visible)
            assert(V10.set_night(model,true))
            assert(night.visible)
            assert(V10.set_night(model,false))
            assert(not night.visible)
            if damage<=1:
                assert(_count(model,"PlacaAnclajeEste_00_-1")==1)
                assert(_count(model,"PernoAnclajeEste_00_1")==1)
                assert(_count(model,"PuntoRetencionDefensaEste_0")==1)
                assert(_count(model,"PuntoRetencionDefensaEste_1")==1)
                assert(_count(model,"MarcaCorrelacionAmarreEste_2")==1)
                assert(_count(model,"EtiquetaAmarreReflectante_3")==1)
                assert(_count(model,"PlacaMuroEspigon_-1_0")==1)
                assert(_count(model,"PlacaMuroEspigon_1_2")==1)
                assert(_count(model,"CadenaAlineadaEspigon_A_-1_0")==1)
                assert(_count(model,"RetenedorCubiertaEspigon_-1_0")==1)
                var bollard: Node3D=model.find_child("Bolardo_-1_0",
                    true,false) as Node3D
                assert(bollard!=null)
                var retainer: Node3D=model.find_child(
                    "RetenedorCubiertaEspigon_-1_0",
                    true,false) as Node3D
                assert(retainer!=null)
                assert(str(retainer.get_meta("mooring_bollard_reference",""))
                    =="Bolardo_-1_0")
                var old_chain: Node3D=model.find_child(
                    "CadenaDefensa_-1_0",true,false) as Node3D
                assert(old_chain!=null and not old_chain.visible)
            if damage==2:
                assert(_count(model,"PlacaAnclajeEste_00_-1")==1)
                assert(_count(model,"PlacaAnclajeEste_02_-1")==0)
                assert(_count(model,"PuntoRetencionDefensaEste_1")==0)
                assert(_count(model,"PuntoRetencionDefensaEste_3")==1)
                assert(_count(model,"PlacaMuroEspigon_-1_1")==0)
                assert(_count(model,"PlacaMuroEspigon_1_0")==1)
            if damage==3:
                assert(_count(model,"PlacaAnclajeEste_00_-1")==0)
                assert(_count(model,"SoporteEsteDoblado_00")==1)
                assert(_count(model,"PuntoRetencionDefensaEste_0")==0)
                assert(_count(model,"FijacionEspigonRota_-1_0")==1)
                assert(_count(model,"PlacaMuroEspigon_1_0")==0)
                assert(_count(model,"FijacionEspigonRota_1_0")==0)
                assert(_count(model,"Bolardo_1_0")==0)
            if damage==4:
                assert(_count(model,"PlacaAnclajeEste_00_-1")==0)
                assert(_count(model,"PernoArrancadoMuelleEsteV10")==1)
                assert(_count(model,"CadenaSueltaEspigonV10")==1)
                assert(_count(model,"Bolardo_-1_0")==0)
                assert(_count(model,"RetenedorCubiertaEspigon_-1_0")==0)
            model.free()
            verified+=1
    assert(verified==40)
    for level in range(1,4):
        var model: Node3D=_build(level,6,0)
        assert(_count(model,"PlacaMuroEspigon_-1_0")==1)
        assert(_count(model,"PuntoRetencionDefensaEste_3")==1)
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
    assert(studio.naval_detail_v9_toggle.button_pressed)
    assert(studio.naval_detail_v10_toggle.button_pressed)
    assert(studio.model_root.has_node(V10.STAGE_NAME))
    assert(studio.naval_camera_picker.item_count==6)
    await _capture(studio,"overview")
    studio.naval_camera_picker.select(5)
    studio._change_naval_camera(5)
    studio._zoom=1.38
    studio._update_camera()
    await _frames(8)
    assert(studio._naval_camera_view==5 and studio.camera.size<7.0)
    assert(bool(studio.model_root.get_node(V10.STAGE_NAME).get_meta(
        "naval_v10_close_mode",false)))
    await _capture(studio,"bolardos_pier")
    studio.naval_camera_picker.select(4)
    studio._change_naval_camera(4)
    await _frames(8)
    await _capture(studio,"east_retention")
    studio.naval_camera_picker.select(1)
    studio._change_naval_camera(1)
    await _frames(7)
    await _capture(studio,"seaside_profile")
    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio._zoom=0.62
    studio._update_camera()
    await _frames(8)
    assert(not bool(studio.model_root.get_node(V10.STAGE_NAME).get_meta(
        "naval_v10_close_mode",true)))
    await _capture(studio,"tactical_far")
    studio._zoom=1.0
    studio._update_camera()
    studio.naval_night_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_night_v6(true)
    await _frames(8)
    assert(bool(studio.model_root.get_node(V10.STAGE_NAME).get_meta(
        "naval_v10_night_enabled",false)))
    await _capture(studio,"night_guides")
    studio.naval_night_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_night_v6(false)

    studio.naval_detail_v10_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v10(false)
    await _frames(8)
    assert(studio.model_root.has_node(V9.STAGE_NAME))
    assert(not studio.model_root.has_node(V10.STAGE_NAME))
    await _capture(studio,"compare_v9")
    studio.naval_detail_v10_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v10(true)
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(studio.model_root.has_node(V10.STAGE_NAME))
    assert(_count(studio.model_root,"PlacaMuroEspigon_1_0")==0)
    await _capture(studio,"critical_ruins")
    studio._change_selected_building(1)
    await _frames(6)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V10: 40 faction/damage variants, 3 tiers, aligned V1 pier bollards and V3 mooring rings, independently mounted fender chains, six Studio cameras, zoom/night, eight native Godot captures")
    quit(0)
