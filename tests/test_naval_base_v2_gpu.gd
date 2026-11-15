extends SceneTree

# Godot 4.3 OpenGL art QA: real mesh additions, 8 original factions,
# distinct damage states, reversible V1/V2 compare and native captures.
# No simulated Android FPS or gameplay claims.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const Detail=preload("res://scripts/ui/NavalBaseDetailV2.gd")
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
    await _frames(7)
    var snap: Image=studio.preview.get_texture().get_image()
    assert(snap!=null and snap.get_width()>400 and snap.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(snap.save_png("res://artifacts/tarvoka_naval_v2_"+name+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(Detail.STAGE_NAME!="")
    assert(not Detail.apply(null,2,1,0))
    var variants: int=0
    var extras: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null and not model.has_node(Detail.STAGE_NAME))
            var first_meshes: int=Base.count_meshes(model)
            assert(Detail.apply(model,2,faction,damage))
            assert(not Detail.apply(model,2,faction,damage))
            assert(model.has_node(Detail.STAGE_NAME))
            assert(_count(model,"SuperficieAguaShaderMaritimoV2")==1)
            var water: MeshInstance3D=model.find_child(
                "SuperficieAguaShaderMaritimoV2",true,false) as MeshInstance3D
            assert(water!=null and water.material_override is ShaderMaterial)
            var shader: ShaderMaterial=water.material_override as ShaderMaterial
            assert(shader.shader.code.contains("wave_speed"))
            assert(_count(model,"CoronacionMuelleEste")==1)
            assert(_count(model,"GomaVerticalMuelle_00")==1)
            assert(_count(model,"PuntoAmarre_00")==1)
            assert(Base.count_meshes(model)>first_meshes+30)
            if damage<=1:
                assert(_count(model,"CordónSuperiorGrua_-1")==1)
                assert(_count(model,"DiagonalCelosia_1_3")==1)
                assert(_count(model,"CompuertaTaller_0")==1)
                assert(_count(model,"NervioRealDeTecho_4_1")==1)
                extras+=1
            if damage==2:
                assert(_count(model,"RefuerzoVigaDesplomada_1")==1)
                assert(_count(model,"CordónSuperiorGrua_-1")==0)
                assert(_count(model,"NervioRealDeTecho_4_1")==0)
                assert(_count(model,"NervioRealDeTecho_9_1")==1)
            if damage==3:
                assert(_count(model,"RemateMuelleRotoV2")==1)
                assert(_count(model,"CoronacionEspigon_1")==0)
                assert(_count(model,"CoronacionEspigon_-1")==1)
                assert(_count(model,"NervioRealDeTecho_3_1")==0)
            if damage==4:
                assert(_count(model,"AstilleroTerminacionesV2")==0)
                assert(_count(model,"GruaCelosiaYPolipastoV2")==0)
                assert(_count(model,"BalizasYControlMaritimoV2")==0)
                assert(_count(model,"RemateMuelleRotoV2")==1)
            # Retain the original faction-specific official emblem.
            assert(_count(model,"EscudoOficialFaccion3D")==(
                0 if damage==4 else 1))
            model.free()
            variants+=1
    assert(variants==40 and extras==16)
    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(Detail.apply(model,level,6,0))
        assert(_count(model,"CajaSuministroMuelle_0")==(
            0 if level==1 else 1))
        assert(_count(model,"CentroLogisticoAvanzado")==(
            1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(14)
    studio._switch_category(1)
    await _frames(6)
    studio._change_selected_building(2)
    await _frames(10)
    assert(studio._role=="naval_base")
    assert(studio.building_picker.get_item_text(2).contains("V2"))
    assert(studio.naval_detail_v2_toggle.button_pressed)
    assert(studio.model_root.has_node(Detail.STAGE_NAME))
    assert(studio.naval_controls.visible and not studio.airbase_controls.visible)
    await _capture(studio,"overview_v2")

    studio.naval_detail_v2_toggle.set_pressed_no_signal(false)
    studio._toggle_naval_detail_v2(false)
    await _frames(9)
    assert(not studio.model_root.has_node(Detail.STAGE_NAME))
    await _capture(studio,"overview_v1_compare")
    studio.naval_detail_v2_toggle.set_pressed_no_signal(true)
    studio._toggle_naval_detail_v2(true)
    await _frames(9)
    assert(studio.model_root.has_node(Detail.STAGE_NAME))
    for i in [1,2,3]:
        studio.naval_camera_picker.select(i)
        studio._change_naval_camera(i)
        await _frames(5)
        await _capture(studio,["","harbor","rear","top"][i])

    studio.naval_camera_picker.select(0)
    studio._change_naval_camera(0)
    for tier in [2,3]:
        studio.naval_level_picker.select(tier-1)
        studio._change_naval_setting(tier-1)
        await _frames(7)
        assert(studio.model_root.has_node(Detail.STAGE_NAME))
        await _capture(studio,"level_%d" % tier)
    studio.naval_level_picker.select(1)
    studio._change_naval_setting(1)
    await _frames(5)
    for damage in [1,2,3,4]:
        studio.naval_damage_picker.select(damage)
        studio._change_naval_setting(damage)
        await _frames(7)
        assert(studio.model_root.has_node(Detail.STAGE_NAME))
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _capture(studio,"damage_%d" % damage)
    studio.naval_damage_picker.select(0)
    studio._change_naval_setting(0)
    await _frames(6)
    studio._select_faction_view(6)
    await _frames(7)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    assert(_count(studio.model_root,"EscudoOficialFaccion3D")==1)
    await _capture(studio,"faction_turquesa")
    studio._change_selected_building(1)
    await _frames(7)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(7)
    assert(studio._role=="headquarters")
    studio._change_selected_building(2)
    await _frames(7)
    assert(studio._role=="naval_base")
    studio.queue_free()
    await _frames(3)
    print("PASS NAVAL BASE V2: 40 faction/damage models, 3 architecture tiers, native animated shader, carved quay layers, braced crane, roof respecting destruction, V1/V2 toggle, official emblems, 12 Godot captures")
    quit(0)
