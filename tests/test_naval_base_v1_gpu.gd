extends SceneTree

# QA for the first native Godot Naval Base V1. This proves source mesh
# geometry, faction atlas reuse and studio navigation, not mobile FPS.
const Base=preload("res://scripts/ui/NavalBase3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(count: int=7) -> void:
    for _i in range(count):
        await process_frame

func _count(node: Node,label: String) -> int:
    var value: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        value+=_count(child,label)
    return value

func _shot(studio: Control,label: String) -> void:
    await _frames(7)
    var frame: Image=studio.preview.get_texture().get_image()
    assert(frame!=null and frame.get_width()>400 and frame.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(frame.save_png(
        "res://artifacts/tarvoka_naval_v1_"+label+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(Base.DAMAGE_STAGES.size()==5)
    assert(not Base.valid_spec(4,0,0))
    assert(not Base.valid_spec(2,8,0))
    assert(not Base.valid_spec(1,0,5))
    var variants: int=0
    var official: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Base.build(2,faction,damage)
            assert(model!=null and model.get_meta("tarvoka_naval_base_v1",false))
            assert(model.get_meta("tarvoka_building_kind","")=="naval_base")
            assert(int(model.get_meta("visual_damage_stage",-1))==damage)
            assert(_count(model,"AguaDarsenaConectadaAlMar")==1)
            assert(_count(model,"MuelleEsteDeCarga")==1)
            assert(_count(model,"EspigonDeAtraque_-1")==1)
            assert(_count(model,"GruaPortuariaDeCarga")==(0 if damage==4 else 1))
            assert(_count(model,"TorreControlMaritimo")==(0 if damage==4 else 1))
            assert(_count(model,"HangarNavalTallerDeBuques")==(0 if damage==4 else 1))
            if damage<4:
                assert(_count(model,"ParedPosteriorHangar")==1)
                assert(_count(model,"EscudoDeFaccionModular")==1)
                assert(_count(model,"EscudoOficialFaccion3D")==1)
                var logo: MeshInstance3D=model.find_child(
                    "EscudoOficialFaccion3D",true,false) as MeshInstance3D
                assert(logo!=null and int(logo.get_meta(
                    "tarvoka_official_emblem_index",-1))==faction)
                official+=1
            else:
                assert(_count(model,"EscudoOficialFaccion3D")==0)
                assert(_count(model,"TorreDerruida")==1)
            if damage==2:
                assert(_count(model,"PlumaDeGruaCaida")==1)
                assert(_count(model,"ChapaTejado_4_-1")==0)
                assert(_count(model,"ChapaTejado_9_1")==1)
            if damage==3:
                assert(_count(model,"MuellePartido_1")==1)
                assert(_count(model,"CabinaRotaControl")==1)
                assert(_count(model,"ChapaTejado_3_1")==0)
            assert(Base.count_meshes(model)>(25 if damage==4 else 35))
            model.free()
            variants+=1
    assert(variants==40 and official==32)
    for level in range(1,4):
        var model: Node3D=Base.build(level,6,0)
        assert(model!=null and int(model.get_meta("visual_level",-1))==level)
        assert(_count(model,"DepositoCombustibleNaval_0")==(0 if level==1 else 1))
        assert(_count(model,"CentroLogisticoAvanzado")==(1 if level==3 else 0))
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(15)
    studio._switch_category(1)
    await _frames(5)
    assert(studio.building_picker.item_count==3)
    studio._change_selected_building(2)
    await _frames(11)
    assert(studio._role=="naval_base")
    assert(studio.naval_controls.visible)
    assert(not studio.airbase_controls.visible)
    assert(studio.naval_level_picker.item_count==3)
    assert(studio.naval_damage_picker.item_count==5)
    assert(studio.naval_camera_picker.item_count==4)
    assert(_count(studio.model_root,"AguaDarsenaConectadaAlMar")==1)
    for index in range(4):
        studio.naval_camera_picker.select(index)
        studio._change_naval_camera(index)
        await _frames(5)
        assert(studio._naval_camera_view==index)
        var labels: Array[String]=["overview","harbor","rear","top"]
        await _shot(studio,"camera_"+labels[index])

    for level in [2,3]:
        studio.naval_level_picker.select(level-1)
        studio._change_naval_setting(level-1)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        await _shot(studio,"level_%d" % level)

    studio.naval_level_picker.select(1)
    studio._change_naval_setting(1)
    await _frames(6)
    for damage in [1,2,3,4]:
        studio.naval_damage_picker.select(damage)
        studio._change_naval_setting(damage)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _shot(studio,"damage_%d" % damage)

    studio.naval_damage_picker.select(0)
    studio._change_naval_setting(0)
    await _frames(5)
    studio._select_faction_view(6)
    await _frames(6)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    assert(_count(studio.model_root,"EscudoOficialFaccion3D")==1)
    await _shot(studio,"faction_turquesa")

    studio._change_selected_building(1)
    await _frames(8)
    assert(studio._role=="airbase" and studio.airbase_controls.visible)
    studio._change_selected_building(0)
    await _frames(8)
    assert(studio._role=="headquarters")
    studio._change_selected_building(2)
    await _frames(8)
    assert(studio._role=="naval_base")
    studio.queue_free()
    await _frames(4)
    print("PASS NAVAL BASE V1: 40 faction/damage models, 3 levels, official shields, functional harbour quays/crane, proper ruin geometry, four studio cameras, 11 native Godot preview frames, HQ/Airbase navigation unchanged")
    quit(0)
