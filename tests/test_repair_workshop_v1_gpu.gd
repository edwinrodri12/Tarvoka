extends SceneTree

# Godot 4.3 native workshop-first architectural acceptance.
# Model V1 is intentionally art-only and does NOT imply the game has
# implemented building health, repairs or production in this model.
const Workshop=preload("res://scripts/ui/RepairWorkshop3DV1.gd")
const Style=preload("res://scripts/ui/VisualStyle.gd")
const Studio=preload("res://scenes/UnitArtStudioWeb.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _frames(n: int=7) -> void:
    for _i in range(n):
        await process_frame

func _count(node: Node,label: String) -> int:
    var count: int=1 if str(node.name)==label else 0
    for child in node.get_children():
        count+=_count(child,label)
    return count

func _capture(studio: Control,label: String) -> void:
    await _frames(7)
    var img: Image=studio.preview.get_texture().get_image()
    assert(img!=null and img.get_width()>400 and img.get_height()>300)
    assert(DirAccess.make_dir_recursive_absolute(
        ProjectSettings.globalize_path("res://artifacts"))==OK)
    assert(img.save_png(
        "res://artifacts/tarvoka_workshop_v1_"+label+".png")==OK)

func _run() -> void:
    assert(Style.FACTIONS.size()==8)
    assert(Workshop.DAMAGE_STAGES.size()==5)
    assert(not Workshop.valid_spec(4,0,0))
    assert(not Workshop.valid_spec(2,8,0))
    assert(not Workshop.valid_spec(2,0,5))
    var variants: int=0
    for faction in range(8):
        for damage in range(5):
            var model: Node3D=Workshop.build(2,faction,damage)
            assert(model!=null)
            assert(bool(model.get_meta("tarvoka_workshop_v1",false)))
            assert(str(model.get_meta("tarvoka_building_kind",""))=="repair_workshop")
            assert(int(model.get_meta("visual_level",-1))==2)
            assert(int(model.get_meta("visual_faction",-1))==faction)
            assert(int(model.get_meta("visual_damage_stage",-1))==damage)
            assert(_count(model,"CimentacionCompleta")==1)
            assert(_count(model,"PavimentoOperativo")==1)
            assert(_count(model,"ParedPosteriorCerrada")==(0 if damage==4 else 1))
            assert(_count(model,"PanelTecho_00")==(1 if damage<=1 else 0))
            assert(_count(model,"PanelTecho_02")==(0 if damage==4 else 1))
            assert(_count(model,"PortonSeccional_0_0")==(1 if damage<=2 else 0))
            assert(_count(model,"PortonSeccional_1_0")==(1 if damage<=1 else 0))
            assert(_count(model,"PortonColapsado_1")==(1 if damage in [2,3] else 0))
            assert(_count(model,"OficinaSegundoNivel")==(1 if damage<=2 else 0))
            assert(_count(model,"ArmarioHerramientas")==(1 if damage<=2 else 0))
            assert(_count(model,"PuenteGruaDeTaller")==0)
            assert(_count(model,"MarcaFaccionPavimento")==(0 if damage==4 else 1))
            if damage==3:
                assert(_count(model,"DintelFracturado")==1)
                assert(_count(model,"ParedLateralDerechaRota")==1)
                assert(_count(model,"PlataformaHidraulica_0_-1")==1)
            if damage==4:
                assert(_count(model,"FragmentoCimiento_0")==1)
                assert(_count(model,"ParedLateralIzquierda")==0)
                assert(_count(model,"ExtractorAire_0")==0)
                assert(_count(model,"PortonSeccional_0_0")==0)
            assert(Workshop.count_meshes(model)>7)
            model.free()
            variants+=1
    assert(variants==40)
    for level in range(1,4):
        var model: Node3D=Workshop.build(level,6,0)
        assert(model!=null)
        assert(_count(model,"OficinaSegundoNivel")==(0 if level==1 else 1))
        assert(_count(model,"PuenteGruaDeTaller")==(1 if level==3 else 0))
        assert(_count(model,"ExtractorAire_0")==(1 if level==3 else 0))
        assert(_count(model,"ArmarioHerramientas")==(0 if level==1 else 1))
        assert(_count(model,"PortonSeccional_0_0")==1)
        model.free()

    root.content_scale_size=Vector2i(1280,800)
    var studio: Control=Studio.instantiate()
    root.add_child(studio)
    await _frames(16)
    studio._switch_category(1)
    await _frames(6)
    assert(studio.building_picker.item_count==4)
    studio._change_selected_building(3)
    await _frames(10)
    assert(studio._role=="repair_workshop")
    assert(studio.workshop_controls.visible)
    assert(not studio.naval_controls.visible)
    assert(not studio.airbase_controls.visible)
    assert(studio.workshop_level_picker.item_count==3)
    assert(studio.workshop_damage_picker.item_count==5)
    assert(studio.workshop_camera_picker.item_count==4)
    for view in range(4):
        studio.workshop_camera_picker.select(view)
        studio._change_workshop_camera(view)
        await _frames(6)
        assert(studio._workshop_camera_view==view)
        await _capture(studio,["overview","service_bays","rear","roof"][view])
    for level in [2,3]:
        studio.workshop_level_picker.select(level-1)
        studio._change_workshop_setting(level-1)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_level",-1))==level)
        await _capture(studio,"level_%d" % level)
    for damage in [1,2,3,4]:
        studio.workshop_damage_picker.select(damage)
        studio._change_workshop_setting(damage)
        await _frames(7)
        assert(int(studio.model_root.get_meta("visual_damage_stage",-1))==damage)
        await _capture(studio,"damage_%d" % damage)
    studio.workshop_damage_picker.select(0)
    studio._change_workshop_setting(0)
    await _frames(6)
    studio._select_faction_view(6)
    await _frames(7)
    assert(int(studio.model_root.get_meta("visual_faction",-1))==6)
    assert(_count(studio.model_root,"PlacaFaccionFachada")==1)
    await _capture(studio,"faction_6")
    studio._change_selected_building(2)
    await _frames(7)
    assert(studio._role=="naval_base")
    studio._change_selected_building(1)
    await _frames(7)
    assert(studio._role=="airbase")
    studio._change_selected_building(0)
    await _frames(7)
    assert(studio._role=="headquarters")
    studio._change_selected_building(3)
    await _frames(7)
    assert(studio._role=="repair_workshop")
    studio.queue_free()
    await _frames(3)
    print("PASS WORKSHOP V1: 40 faction/damage models, 3 levels, 2 actual service bays, three-tier workshop architecture, proper 5-stage damage, 4 studio cameras, 11 real Godot screenshots, previous three buildings unaffected")
    quit(0)
