extends SceneTree

# Native Godot 4.3 OpenGL acceptance. No Android FPS or game-rule claims.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const V5=preload("res://scripts/ui/NavalYardSignalsV5.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var count: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        count+=_count(child,label)
    return count

func _capture(studio: Control,name: String) -> void:
    await _frames(8)
    var shot: Image=studio.preview.get_texture().get_image()
    assert(shot!=null and shot.get_width()>400 and shot.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(shot.save_png("res://artifacts/tarvoka_naval_v5_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V5.apply(null,2,1,0))
    var combinations: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null)
            assert(not V5.apply(model,2,faction,damage))
            assert(V2.apply(model,2,faction,damage))
            assert(not V5.apply(model,2,faction,damage))
            assert(V3.apply(model,2,faction,damage))
            assert(not V5.apply(model,2,faction,damage))
            assert(V4.apply(model,2,faction,damage))
            var original_meshes: int=Base.count_meshes(model)
            assert(V5.apply(model,2,faction,damage))
            assert(not V5.apply(model,2,faction,damage))
            assert(model.has_node(V5.STAGE_NAME))
            assert(Base.count_meshes(model)>original_meshes)
            assert(_count(model,"EstructuraEscalaYSombrasAstilleroV5")==1)
            assert(_count(model,"BalizasMaritimasModeradasV5")==(
                0 if damage==4 else 1))
            assert(_count(model,"NumeracionMuellesFisicaV5")==(
                0 if damage==4 else 1))
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            var stage: Node3D=model.get_node(V5.STAGE_NAME)
            assert(int(stage.get_meta("naval_v5_damage",-1))==damage)
            if damage<=2:
                assert(_count(model,"PlacaMuelle_-1")==1)
                assert(_count(model,"PlacaMuelle_1")==1)
                assert(_count(model,"NumeroMuelle_-1_0_Tramo_0")==1)
                assert(_count(model,"NumeroMuelle_1_2_Tramo_6")==1)
                assert(_count(model,"ConoLuzServicio_0")==1)
                var lamp: SpotLight3D=model.find_child(
                    "ConoLuzServicio_0",true,false) as SpotLight3D
                assert(lamp!=null and lamp.spot_range<=3.6)
                assert(not lamp.shadow_enabled)
                assert(_count(model,"PieBancada_-1_-1")==1)
            else:
                assert(_count(model,"ConoLuzServicio_0")==0)
                assert(_count(model,"PlacaMuelle_1")==0)
                assert(_count(model,"NervioRealDeTecho_3_1")==0)
            if damage==0:
                assert(_count(model,"ConoLuzServicio_1")==1)
                var lens: MeshInstance3D=model.find_child(
                    "BalizaLente_-1",true,false) as MeshInstance3D
                assert(lens!=null)
                assert(lens.material_override is StandardMaterial3D)
                assert((lens.material_override as StandardMaterial3D).emission_enabled)
                assert(_count(model,"ArriostreBancada_-1")==1)
            if damage==1:
                assert(_count(model,"ConoLuzServicio_1")==0)
            if damage==2:
                assert(_count(model,"PlacaMuelle_1")==1)
                assert(_count(model,"ArriostreBancada_-1")==1)
                assert(_count(model,"CordónSuperiorGrua_-1")==0)
                assert(_count(model,"NervioRealDeTecho_4_1")==0)
            if damage==3:
                assert(_count(model,"PlacaMuelle_-1")==1)
                assert(_count(model,"TiranteBancadaDoblado")==1)
                assert(_count(model,"ArriostreBancada_-1")==0)
                assert(_count(model,"BalizaLente_1")==0)
            if damage==4:
                assert(_count(model,"PlacaMuelle_-1")==0)
                assert(_count(model,"VigaAstilleroDerrumbadaV5")==1)
                assert(_count(model,"ArriostreBancada_-1")==0)
                assert(_count(model,"ParedPosteriorHangar")==0)
            model.free()
            combinations+=1
    assert(combinations==40)

    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(V2.apply(model,level,6,0))
        assert(V3.apply(model,level,6,0))
        assert(V4.apply(model,level,6,0))
        assert(V5.apply(model,level,6,0))
        assert(_count(model,"PlacaMuelle_-1")==1)
        assert(_count(model,"RefuerzoPuenteGruaIzquierdoV5")==(
            1 if level==3 else 0))
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
    assert(studio.naval_detail_v2_toggle.button_pressed)
    assert(studio.naval_detail_v3_toggle.button_pressed)
    assert(studio.naval_detail_v4_toggle.button_pressed)
    assert(studio.naval_detail_v5_toggle.button_pressed)
    assert(studio.model_root.has_node(V5.STAGE_NAME))
    await _capture(studio,"overview_v5")

    studio.naval_detail_v5_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v5(false)
    await _frames(8)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    assert(not studio.model_root.has_node(V5.STAGE_NAME))
    await _capture(studio,"compare_v4")
    studio.naval_detail_v4_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v4(false)
    await _frames(8)
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(not studio.model_root.has_node(V5.STAGE_NAME))
    studio.naval_detail_v3_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v3(false)
    await _frames(6)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    studio.naval_detail_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v2(false)
    await _frames(6)
    assert(not studio.model_root.has_node(V2.STAGE_NAME))

    studio.naval_detail_v2_toggle.set_pressed_no_signal(true)
    studio.naval_detail_v3_toggle.set_pressed_no_signal(true)
    studio.naval_detail_v4_toggle.set_pressed_no_signal(true)
    studio.naval_detail_v5_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v5(true)
    await _frames(9)
    assert(studio.model_root.has_node(V5.STAGE_NAME))
    for camera in [1,2,3]:
        studio.naval_camera_picker.select(camera)
        studio._change_naval_camera(camera)
        await _frames(6)
        await _capture(studio,["","harbor_signs","yard_shadows","overhead"][camera])
    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio.naval_level_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(8)
    assert(_count(studio.model_root,"RefuerzoPuenteGruaIzquierdoV5")==1)
    await _capture(studio,"level3_yard")
    studio.naval_level_picker.select(1)
    studio._change_naval_setting(1)
    studio.naval_damage_picker.select(2)
    studio._change_naval_setting(2)
    await _frames(8)
    assert(_count(studio.model_root,"ConoLuzServicio_1")==0)
    await _capture(studio,"medium_damage")
    studio.naval_damage_picker.select(4)
    studio._change_naval_setting(4)
    await _frames(8)
    assert(_count(studio.model_root,"PlacaMuelle_-1")==0)
    await _capture(studio,"destroyed")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V5: 40 faction/damage variants, three levels, pier numbers, scaled yard shadow geometry, real dim spotlights, destructive states, V1-V5 comparison, 8 native captures")
    quit(0)
