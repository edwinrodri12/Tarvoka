extends SceneTree

# Real Godot 4.3 OpenGL acceptance for Naval Base V6.
# Readability near/far, actual nighttime lights, 8 factions and 5 damages.
# This is 3D-art QA: NOT Android framerate, gameplay or naval navigation.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const V6=preload("res://scripts/ui/NavalNightReadabilityV6.gd")
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
    await _frames(8)
    var png: Image=studio.preview.get_texture().get_image()
    assert(png!=null and png.get_width()>400 and png.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(png.save_png("res://artifacts/tarvoka_naval_v6_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V6.apply(null,2,0,0))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null)
            assert(not V6.apply(model,2,faction,damage))
            assert(V2.apply(model,2,faction,damage))
            assert(V3.apply(model,2,faction,damage))
            assert(V4.apply(model,2,faction,damage))
            assert(not V6.apply(model,2,faction,damage))
            assert(V5.apply(model,2,faction,damage))
            var original_count: int=Base.count_meshes(model)
            assert(V6.apply(model,2,faction,damage))
            assert(not V6.apply(model,2,faction,damage))
            assert(Base.count_meshes(model)>original_count)
            assert(_count(model,V6.STAGE_NAME)==1)
            var stage: Node3D=model.get_node(V6.STAGE_NAME)
            var detail: Node3D=stage.get_node("DetallesCercanosNavalesV6")
            var far: Node3D=stage.get_node("SiluetasDeLecturaTacticaV6")
            var night: Node3D=stage.get_node("IndicadoresNocturnosV6")
            assert(detail.visible and not far.visible and not night.visible)
            assert(int(stage.get_meta("naval_v6_damage",-1))==damage)
            assert(V6.set_detail(model,false))
            assert(not detail.visible and far.visible)
            assert(V6.set_detail(model,true))
            assert(detail.visible and not far.visible)
            assert(V6.set_night(model,true))
            assert(night.visible)
            assert(V6.set_night(model,false))
            assert(not night.visible)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            if damage<3:
                assert(_count(model,"EstriaPavimentoMuelle_1_00")==1)
                assert(_count(model,"CabeceraLegibleMuelle_1")==1)
                assert(_count(model,"CabeceraLegibleMuelle_-1")==1)
                assert(_count(model,"PerfilLejanoAstillero")==1)
                assert(_count(model,"IndicadorTorreMarinaV6")==1)
            if damage>=3:
                assert(_count(model,"EstriaPavimentoMuelle_1_00")==0)
                assert(_count(model,"CabeceraLegibleMuelle_1")==0)
                assert(_count(model,"PerfilLejanoAstillero")==0)
                assert(_count(model,"CoronacionEspigon_1")==0)
                assert(_count(model,"NervioRealDeTecho_3_1")==0)
            if damage<=1:
                assert(_count(model,"LuzGuiaTorreReguladaV6")==1)
                var guide: OmniLight3D=model.find_child(
                    "LuzGuiaTorreReguladaV6",true,false) as OmniLight3D
                assert(guide!=null and not guide.shadow_enabled)
                assert(guide.omni_range<=2.55)
            if damage==2:
                assert(_count(model,"LuzGuiaTorreReguladaV6")==0)
                assert(_count(model,"IndicadorTorreMarinaV6")==1)
                assert(_count(model,"NervioRealDeTecho_4_1")==0)
            if damage==4:
                assert(_count(model,"IndicadorTorreMarinaV6")==0)
                assert(_count(model,"CabeceraLegibleMuelle_-1")==0)
                assert(_count(model,"MasaAstilleroColapsada")==1)
                assert(_count(model,"ParedPosteriorHangar")==0)
            model.free()
            variants+=1
    assert(variants==40)
    assert(not V6.set_detail(null,true))
    assert(not V6.set_night(null,true))

    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(V2.apply(model,level,6,0))
        assert(V3.apply(model,level,6,0))
        assert(V4.apply(model,level,6,0))
        assert(V5.apply(model,level,6,0))
        assert(V6.apply(model,level,6,0))
        assert(_count(model,"CabeceraLegibleMuelle_-1")==1)
        assert(_count(model,"TravesañoLegiblePuenteGrua")==(
            1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(6)
    studio._change_selected_building(2)
    await _frames(11)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v5_toggle.button_pressed)
    assert(studio.naval_detail_v6_toggle.button_pressed)
    assert(not studio.naval_night_v6_toggle.button_pressed)
    assert(studio.model_root.has_node(V6.STAGE_NAME))
    await _capture(studio,"day_overview")

    studio.naval_night_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_night_v6(true)
    await _frames(9)
    assert(bool(studio.model_root.get_node(V6.STAGE_NAME)
        .get_meta("naval_v6_night_enabled",false)))
    assert(int(studio._hq_light_preset)==2)
    await _capture(studio,"night_overview")
    studio.naval_camera_picker.select(1)
    studio._change_naval_camera(1)
    await _frames(8)
    await _capture(studio,"night_harbor")

    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio._zoom=0.63
    studio._update_camera()
    await _frames(9)
    var stage: Node3D=studio.model_root.get_node(V6.STAGE_NAME)
    assert(not (stage.get_node("DetallesCercanosNavalesV6") as Node3D).visible)
    assert((stage.get_node("SiluetasDeLecturaTacticaV6") as Node3D).visible)
    await _capture(studio,"night_tactical_far")

    studio._zoom=1.60
    studio._update_camera()
    await _frames(9)
    assert((stage.get_node("DetallesCercanosNavalesV6") as Node3D).visible)
    assert(not (stage.get_node("SiluetasDeLecturaTacticaV6") as Node3D).visible)
    await _capture(studio,"night_closeup")
    studio._zoom=1.0
    studio._update_camera()

    studio.naval_night_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_night_v6(false)
    studio.naval_detail_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v6(false)
    await _frames(8)
    assert(studio.model_root.has_node(V5.STAGE_NAME))
    assert(not studio.model_root.has_node(V6.STAGE_NAME))
    await _capture(studio,"compare_v5")
    studio.naval_detail_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v6(true)
    await _frames(8)
    assert(studio.model_root.has_node(V6.STAGE_NAME))

    studio.naval_level_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(8)
    assert(_count(studio.model_root,"TravesañoLegiblePuenteGrua")==1)
    await _capture(studio,"advanced_shipyard")
    studio.naval_level_picker.select(1)
    studio._change_naval_setting(1)
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(9)
    assert(_count(studio.model_root,"CabeceraLegibleMuelle_1")==0)
    await _capture(studio,"critical_ruins")
    studio._change_selected_building(1)
    await _frames(6)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V6: 40 faction/damage variants, 3 architecture tiers, true night lighting, near/far geometry LOD, 8 real native captures, V5/V6 Studio compare")
    quit(0)
