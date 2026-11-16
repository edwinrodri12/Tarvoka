extends SceneTree

# Native Godot 4.3 acceptance for real V11 geometry and seven selectable
# cameras. Visual-only tests: not physics, combat or Android performance.
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
const V11=preload("res://scripts/ui/NavalContactFinishV11.gd")
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
    var screenshot: Image=studio.preview.get_texture().get_image()
    assert(screenshot!=null)
    assert(screenshot.get_width()>400 and screenshot.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(screenshot.save_png(
        "res://artifacts/tarvoka_naval_v11_"+name+".png")==OK)

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
    assert(V11.apply(model,level,faction,damage))
    return model

func _check_chain(model: Node3D,label: String) -> void:
    var chain: MultiMeshInstance3D=model.find_child(
        label,true,false) as MultiMeshInstance3D
    assert(chain!=null)
    assert(chain.multimesh!=null)
    assert(chain.multimesh.instance_count>=3)
    assert(chain.multimesh.instance_count<=9)
    assert(chain.multimesh.mesh is ArrayMesh)
    assert(chain.multimesh.mesh.get_surface_count()==1)
    assert(chain.material_override is StandardMaterial3D)
    assert(int(chain.get_meta("actual_chain_links",0))
        ==chain.multimesh.instance_count)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V11.apply(null,2,0,0))
    assert(not V11.set_detail(null,true))
    assert(not V11.set_night(null,true))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            var early: Node3D=Base.build(2,faction,damage)
            assert(not V11.apply(early,2,faction,damage))
            early.free()
            var model: Node3D=_build(2,faction,damage)
            assert(not V11.apply(model,2,faction,damage))
            assert(model.has_node(V10.STAGE_NAME))
            var stage: Node3D=model.get_node(V11.STAGE_NAME)
            assert(int(stage.get_meta("naval_v11_damage",-1))==damage)
            assert(int(stage.get_meta("naval_v11_faction",-1))==faction)
            assert(bool(stage.get_meta("naval_v11_chain_multimesh",false)))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            var near: Node3D=stage.get_node("JuntasDeContactoCercanasV11")
            var far: Node3D=stage.get_node("ContactosTacticosV11")
            assert(near.visible and not far.visible)
            assert(V11.set_detail(model,false))
            assert(not near.visible and far.visible)
            assert(V11.set_detail(model,true))
            assert(near.visible and not far.visible)
            assert(V11.set_night(model,true))
            assert(bool(stage.get_meta("naval_v11_night",false)))
            assert(V11.set_night(model,false))
            assert(not bool(stage.get_meta("naval_v11_night",true)))
            if damage<=1:
                assert(_count(model,"SelloCauchoHormigonEste_00")==1)
                assert(_count(model,"SelloCauchoHormigonEspigon_-1_0")==1)
                assert(_count(model,"SelloCauchoHormigonEspigon_1_2")==1)
                assert(_count(model,"OrejaGussetEste_00_-1")==1)
                assert(_count(model,"MénsulaCantoEspigon_-1_0_-1")==1)
                assert(_count(model,"FranjaPequeñaFaccionEste_00")==1)
                assert(_count(model,"PuntoRetencionDefensaEste_0")==1)
                assert(_count(model,"RetenedorCubiertaEspigon_-1_0")==1)
                _check_chain(model,"EslabonesCadenaEste_A_0")
                _check_chain(model,"EslabonesCadenaEste_B_0")
                _check_chain(model,"EslabonesCadenaEspigon_A_-1_0")
                _check_chain(model,"EslabonesCadenaEspigon_B_-1_0")
                var old_rod: Node3D=model.find_child(
                    "CableRetencionEste_A_0",true,false) as Node3D
                assert(old_rod!=null and not old_rod.visible)
                var old_pier: Node3D=model.find_child(
                    "CadenaAlineadaEspigon_A_-1_0",true,false) as Node3D
                assert(old_pier!=null and not old_pier.visible)
            if damage==2:
                assert(_count(model,"SelloCauchoHormigonEste_00")==1)
                assert(_count(model,"SelloCauchoHormigonEste_02")==0)
                assert(_count(model,"SelloCauchoHormigonEspigon_-1_1")==0)
                assert(_count(model,"FranjaPequeñaFaccionEste_00")==0)
                _check_chain(model,"EslabonesCadenaEste_A_0")
                assert(_count(model,"EslabonesCadenaEste_A_1")==0)
            if damage==3:
                assert(_count(model,"SelloCauchoHormigonEste_00")==0)
                assert(_count(model,"MarcaSoldaduraRotaEste_00")==1)
                assert(_count(model,"GussetDesgarradoEspigon_-1_0")==1)
                assert(_count(model,"GussetDesgarradoEspigon_1_0")==0)
                assert(_count(model,"EslabonesCadenaEste_A_0")==0)
                assert(_count(model,"EslabonesCadenaEspigon_A_-1_0")==0)
                assert(_count(model,"CoronacionEspigon_1")==0)
            if damage==4:
                assert(_count(model,"JuntaCauchoArrancadaEsteV11")==1)
                assert(_count(model,"ArandelaDeCadenaPerdidaV11")==1)
                assert(_count(model,"SelloCauchoHormigonEste_00")==0)
                assert(_count(model,"EslabonesCadenaEste_A_0")==0)
                assert(_count(model,"EslabonesCadenaEspigon_A_-1_0")==0)
                assert(_count(model,"ParedPosteriorHangar")==0)
            model.free()
            variants+=1
    assert(variants==40)

    for level in range(1,4):
        var model: Node3D=_build(level,6,0)
        assert(_count(model,"SelloCauchoHormigonEste_00")==1)
        assert(_count(model,"SelloCauchoHormigonEspigon_-1_0")==1)
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
    assert(studio.naval_detail_v10_toggle.button_pressed)
    assert(studio.naval_detail_v11_toggle.button_pressed)
    assert(studio.model_root.has_node(V11.STAGE_NAME))
    assert(studio.naval_camera_picker.item_count==7)
    await _capture(studio,"overview")

    studio.naval_camera_picker.select(6)
    studio._change_naval_camera(6)
    studio._zoom=1.47
    studio._update_camera()
    await _frames(10)
    assert(studio._naval_camera_view==6)
    assert(studio.camera.size<5.0)
    assert(bool(studio.model_root.get_node(V11.STAGE_NAME)
        .get_meta("naval_v11_close_mode",false)))
    await _capture(studio,"east_contact_close")
    studio.naval_camera_picker.select(5)
    studio._change_naval_camera(5)
    await _frames(8)
    await _capture(studio,"pier_chain_close")
    studio.naval_camera_picker.select(1)
    studio._change_naval_camera(1)
    await _frames(8)
    await _capture(studio,"seaside_contact")

    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio._zoom=0.62
    studio._update_camera()
    await _frames(7)
    assert(not bool(studio.model_root.get_node(V11.STAGE_NAME)
        .get_meta("naval_v11_close_mode",true)))
    await _capture(studio,"tactical_far")
    studio._zoom=1.0
    studio._update_camera()
    studio.naval_night_v6_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_night_v6(true)
    await _frames(7)
    assert(bool(studio.model_root.get_node(V11.STAGE_NAME)
        .get_meta("naval_v11_night",false)))
    await _capture(studio,"night_finish")
    studio.naval_night_v6_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_night_v6(false)

    studio.naval_detail_v11_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v11(false)
    await _frames(8)
    assert(studio.model_root.has_node(V10.STAGE_NAME))
    assert(not studio.model_root.has_node(V11.STAGE_NAME))
    await _capture(studio,"compare_v10")
    studio.naval_detail_v11_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v11(true)
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(studio.model_root.has_node(V11.STAGE_NAME))
    assert(_count(studio.model_root,"GussetDesgarradoEspigon_1_0")==0)
    await _capture(studio,"critical_ruins")
    studio._change_selected_building(1)
    await _frames(6)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(6)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V11: 40 faction/damage variants, 3 levels, true gasket contacts, low-overhead linked MultiMesh mooring chains, no reconstructed piers, seven native Studio cameras, reversible V10, eight Godot captures")
    quit(0)
