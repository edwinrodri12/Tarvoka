extends SceneTree

# Godot 4.3 native visual acceptance. Verify real V4 shader materials,
# coastal geo, dynamic damage states and reversible V1/V2/V3/V4 toggles.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const V2=preload("res://scripts/ui/NavalBaseDetailV2.gd")
const V3=preload("res://scripts/ui/NavalBaseBerthsV3.gd")
const V4=preload("res://scripts/ui/NavalMarineFinishV4.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")
const Style=preload("res://scripts/ui/VisualStyle.gd")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=8) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var c: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        c+=_count(child,label)
    return c

func _capture(studio: Control,name: String) -> void:
    await _frames(7)
    var image: Image=studio.preview.get_texture().get_image()
    assert(image!=null and image.get_width()>400 and image.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(image.save_png("res://artifacts/tarvoka_naval_v4_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(not V4.apply(null,1,1,0))
    var verified: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null)
            assert(not V4.apply(model,2,faction,damage))
            assert(V2.apply(model,2,faction,damage))
            assert(not V4.apply(model,2,faction,damage))
            assert(V3.apply(model,2,faction,damage))
            assert(V4.apply(model,2,faction,damage))
            assert(not V4.apply(model,2,faction,damage))
            assert(_count(model,V4.STAGE_NAME)==1)
            var stage: Node3D=model.get_node(V4.STAGE_NAME)
            assert(int(stage.get_meta("naval_v4_coated_meshes",0))>=6)
            assert(_count(model,"MarcasMareaOxidoYSalV4")==1)
            assert(_count(model,"TransicionCostaEscolleraV4")==1)
            assert(_count(model,"LimoMareaMuelleEste_00")==1)
            assert(_count(model,"EspumaLineaContacto_10")==1)
            assert(_count(model,"RocaEscollera_1_11")==1)
            assert(_count(model,"GravaTransicion_-1_06")==1)
            var quay: MeshInstance3D=model.find_child(
                "CoronacionMuelleEste",true,false) as MeshInstance3D
            assert(quay!=null)
            assert(quay.material_override is ShaderMaterial)
            var pbr: ShaderMaterial=quay.material_override as ShaderMaterial
            assert(pbr.shader.code.contains("marine_wear"))
            assert(pbr.shader.code.contains("world_position"))
            assert(pbr.shader.code.contains("ROUGHNESS"))
            var rock: MeshInstance3D=model.find_child(
                "RocaEscollera_1_00",true,false) as MeshInstance3D
            assert(rock!=null and rock.mesh is SphereMesh)
            assert(rock.position.x>2.6 and rock.position.z>6.0)
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            if damage<3:
                assert(_count(model,"DepositoSalEspigon_1_00")==1)
                assert(_count(model,"OxidoJuntaEspigon_-1_00")==1)
            else:
                assert(_count(model,"DepositoSalEspigon_1_00")==0)
                assert(_count(model,"OxidoJuntaEspigon_1_00")==0)
                assert(_count(model,"CoronacionEspigon_1")==0)
            if damage==2:
                assert(_count(model,"NervioRealDeTecho_4_1")==0)
                assert(_count(model,"TableroAntideslizantePasarela")==1)
            if damage>=3:
                assert(_count(model,"PiedraDesplazadaPorImpacto_0")==1)
            else:
                assert(_count(model,"PiedraDesplazadaPorImpacto_0")==0)
            if damage==4:
                assert(_count(model,"ParedPosteriorHangar")==0)
                assert(_count(model,"GruaCelosiaYPolipastoV2")==0)
                assert(_count(model,"DesgasteSueloAstilleroV4")==0)
            model.free()
            verified+=1
    assert(verified==40)

    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(V2.apply(model,level,6,0))
        assert(V3.apply(model,level,6,0))
        assert(V4.apply(model,level,6,0))
        assert(_count(model,"TransicionCostaEscolleraV4")==1)
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
    await _frames(11)
    assert(studio._role=="naval_base")
    assert(studio.naval_detail_v2_toggle.button_pressed)
    assert(studio.naval_detail_v3_toggle.button_pressed)
    assert(studio.naval_detail_v4_toggle.button_pressed)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    await _capture(studio,"overview_v4")

    studio.naval_detail_v4_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v4(false)
    await _frames(9)
    assert(studio.model_root.has_node(V3.STAGE_NAME))
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    var old_quay: MeshInstance3D=studio.model_root.find_child(
        "CoronacionMuelleEste",true,false) as MeshInstance3D
    assert(old_quay!=null and old_quay.material_override is StandardMaterial3D)
    await _capture(studio,"compare_v3")
    studio.naval_detail_v3_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v3(false)
    await _frames(8)
    assert(studio.model_root.has_node(V2.STAGE_NAME))
    assert(not studio.model_root.has_node(V4.STAGE_NAME))
    await _capture(studio,"compare_v2")
    studio.naval_detail_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v2(false)
    await _frames(8)
    assert(not studio.model_root.has_node(V2.STAGE_NAME))
    await _capture(studio,"compare_v1")

    studio.naval_detail_v2_toggle.set_pressed_no_signal(true)
    studio.naval_detail_v3_toggle.set_pressed_no_signal(true)
    studio.naval_detail_v4_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v4(true)
    await _frames(9)
    assert(studio.model_root.has_node(V4.STAGE_NAME))
    for view in [1,2,3]:
        studio.naval_camera_picker.select(view)
        studio._change_naval_camera(view)
        await _frames(7)
        await _capture(studio,["","harbor_tide","yard_shore","overhead_coast"][view])
    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    studio.naval_damage_picker.select(3)
    studio._change_naval_setting(3)
    await _frames(8)
    assert(_count(studio.model_root,"DepositoSalEspigon_1_00")==0)
    await _capture(studio,"critical_damage")
    studio._change_selected_building(1)
    await _frames(5)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(5)
    assert(studio._role=="headquarters")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V4: 40 faction/damage combinations, 3 architectural tiers, real world-space marine PBR shader, shoreline/coastal sculpt, missing destroyed piers, reversible V1-V2-V3-V4 studio, 8 native captures")
    quit(0)
